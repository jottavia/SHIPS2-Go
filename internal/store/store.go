// internal/store/store.go
package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

// Store wraps a SQLite database that holds machine passwords, BitLocker keys and an audit log.
type Store struct {
	db *sql.DB
}

// PasswordInfo holds password data with metadata
type PasswordInfo struct {
	Password  string    `json:"password"`
	RotatedAt time.Time `json:"rotated_at"`
	Actor     string    `json:"actor"`
}

// BitLockerKeyInfo holds BitLocker key data with metadata
type BitLockerKeyInfo struct {
	Key       string    `json:"key"`
	UpdatedAt time.Time `json:"updated_at"`
	Actor     string    `json:"actor"`
}

// New opens (or creates) the database file at path and ensures the schema exists.
func New(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path+"?_busy_timeout=10000&_journal_mode=WAL")
	if err != nil {
		return nil, err
	}
	s := &Store{db: db}
	if err := s.initSchema(); err != nil {
		db.Close()
		return nil, err
	}
	return s, nil
}

// Close closes the underlying DB connection.
func (s *Store) Close() error { return s.db.Close() }

// initSchema creates tables if they do not yet exist.
func (s *Store) initSchema() error {
	const schema = `
-- Machines we manage.
CREATE TABLE IF NOT EXISTS machines(
    id INTEGER PRIMARY KEY,
    hostname TEXT UNIQUE NOT NULL,
    first_seen INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

-- Current password for each machine (one‑row ring buffer via REPLACE).
CREATE TABLE IF NOT EXISTS passwords(
    machine_id INTEGER NOT NULL UNIQUE,
    password   TEXT    NOT NULL,
    updated_at INTEGER NOT NULL,
    actor      TEXT    NOT NULL,
    FOREIGN KEY(machine_id) REFERENCES machines(id)
);

-- BitLocker recovery keys.
CREATE TABLE IF NOT EXISTS bitlocker_keys(
    machine_id INTEGER NOT NULL UNIQUE,
    key_text   TEXT    NOT NULL,
    updated_at INTEGER NOT NULL,
    actor      TEXT    NOT NULL,
    FOREIGN KEY(machine_id) REFERENCES machines(id)
);

-- Audit entries for every change or read.
CREATE TABLE IF NOT EXISTS audit_logs(
    id         INTEGER PRIMARY KEY,
    machine_id INTEGER,
    action     TEXT    NOT NULL,
    actor      TEXT    NOT NULL,
    remote_addr TEXT   NOT NULL,
    timestamp  INTEGER NOT NULL
);`
	_, err := s.db.Exec(schema)
	return err
}

// validateHostname ensures hostname is valid and safe
func validateHostname(hostname string) error {
	if hostname == "" {
		return errors.New("hostname cannot be empty")
	}
	if len(hostname) > 253 {
		return errors.New("hostname too long")
	}
	// Basic validation - could be expanded
	if strings.ContainsAny(hostname, " \t\n\r") {
		return errors.New("hostname contains invalid characters")
	}
	return nil
}

// getMachineID returns the existing machine id or creates a new machine row.
func (s *Store) getMachineID(ctx context.Context, host string) (int64, error) {
	if err := validateHostname(host); err != nil {
		return 0, err
	}

	var id int64
	err := s.db.QueryRowContext(ctx, `SELECT id FROM machines WHERE hostname = ?`, host).Scan(&id)
	if err == sql.ErrNoRows {
		res, err2 := s.db.ExecContext(ctx, `INSERT INTO machines(hostname) VALUES (?)`, host)
		if err2 != nil {
			return 0, err2
		}
		id, err = res.LastInsertId()
	}
	return id, err
}

// RotatePassword saves a new Administrator password for host and writes an audit entry.
func (s *Store) RotatePassword(ctx context.Context, host, password, actor, remoteAddr string) error {
	if password == "" {
		return errors.New("password cannot be empty")
	}
	if actor == "" {
		actor = "unknown"
	}
	id, err := s.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	now := time.Now().Unix()
	if _, err = tx.ExecContext(ctx,
		`REPLACE INTO passwords(machine_id, password, updated_at, actor) VALUES (?,?,?,?)`,
		id, password, now, actor); err != nil {
		tx.Rollback()
		return err
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`,
		id, "rotate_password", actor, remoteAddr, now); err != nil {
		tx.Rollback()
		return err
	}
	return tx.Commit()
}

// GetPassword returns the latest password info for host and logs the access.
func (s *Store) GetPassword(ctx context.Context, host, actor, remoteAddr string) (*PasswordInfo, error) {
	id, err := s.getMachineID(ctx, host)
	if err != nil {
		return nil, err
	}

	var pw string
	var updatedAt int64
	var pwActor string
	err = s.db.QueryRowContext(ctx,
		`SELECT p.password, p.updated_at, p.actor
           FROM passwords p
           JOIN machines m ON p.machine_id = m.id
          WHERE m.hostname = ?`,
		host).Scan(&pw, &updatedAt, &pwActor)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("no password recorded for host %s", host)
	}
	if err != nil {
		return nil, err
	}

	// Log the password retrieval
	if actor == "" {
		actor = "unknown"
	}
	_, err = s.db.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`,
		id, "fetch_password", actor, remoteAddr, time.Now().Unix())
	if err != nil {
		return nil, err
	}

	return &PasswordInfo{
		Password:  pw,
		RotatedAt: time.Unix(updatedAt, 0),
		Actor:     pwActor,
	}, nil
}

// UpdateBDEKey stores or updates the BitLocker key for host and audits the event.
func (s *Store) UpdateBDEKey(ctx context.Context, host, keyText, actor, remoteAddr string) error {
	if keyText == "" {
		return errors.New("recovery key cannot be empty")
	}
	if actor == "" {
		actor = "unknown"
	}
	id, err := s.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	now := time.Now().Unix()
	if _, err = tx.ExecContext(ctx,
		`REPLACE INTO bitlocker_keys(machine_id, key_text, updated_at, actor) VALUES (?,?,?,?)`,
		id, keyText, now, actor); err != nil {
		tx.Rollback()
		return err
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`,
		id, "update_key", actor, remoteAddr, now); err != nil {
		tx.Rollback()
		return err
	}
	return tx.Commit()
}

// GetBDEKey returns the BitLocker recovery key info for host and logs the access.
func (s *Store) GetBDEKey(ctx context.Context, host, actor, remoteAddr string) (*BitLockerKeyInfo, error) {
	id, err := s.getMachineID(ctx, host)
	if err != nil {
		return nil, err
	}

	var key string
	var updatedAt int64
	var keyActor string
	err = s.db.QueryRowContext(ctx,
		`SELECT k.key_text, k.updated_at, k.actor
           FROM bitlocker_keys k
           JOIN machines m ON k.machine_id = m.id
          WHERE m.hostname = ?`,
		host).Scan(&key, &updatedAt, &keyActor)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("no recovery key for host %s", host)
	}
	if err != nil {
		return nil, err
	}

	// Log the key retrieval
	if actor == "" {
		actor = "unknown"
	}
	_, err = s.db.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`,
		id, "fetch_bde_key", actor, remoteAddr, time.Now().Unix())
	if err != nil {
		return nil, err
	}

	return &BitLockerKeyInfo{
		Key:       key,
		UpdatedAt: time.Unix(updatedAt, 0),
		Actor:     keyActor,
	}, nil
}
