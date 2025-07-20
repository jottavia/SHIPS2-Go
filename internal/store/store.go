// internal/store/store.go
package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	_ "modernc.org/sqlite" // justify: sqlite driver
)

const (
	actorUnknown = "unknown"
)

// Store wraps a SQLite database that holds machine passwords, BitLocker keys and an audit log.
type Store struct {
	db *sql.DB
}

// PasswordInfo holds password data with metadata.
type PasswordInfo struct {
	Password  string    `json:"password"`
	RotatedAt time.Time `json:"rotated_at"`
	Actor     string    `json:"actor"`
}

// BitLockerKeyInfo holds BitLocker key data with metadata.
type BitLockerKeyInfo struct {
	Key       string    `json:"key"`
	UpdatedAt time.Time `json:"updated_at"`
	Actor     string    `json:"actor"`
}

// New opens (or creates) the database file at path and ensures the schema exists.
func New(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path+"?_busy_timeout=10000&_journal_mode=WAL")
	if err != nil {
		return nil, fmt.Errorf("failed to open sqlite database: %w", err)
	}
	s := &Store{db: db}
	if err := s.initSchema(); err != nil {
		//nolint:errcheck // fine to ignore error on failed init
		s.Close()
		return nil, err
	}
	return s, nil
}

// Close closes the underlying DB connection.
func (s *Store) Close() error {
	if err := s.db.Close(); err != nil {
		return fmt.Errorf("failed to close database: %w", err)
	}
	return nil
}

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
	if _, err := s.db.Exec(schema); err != nil {
		return fmt.Errorf("failed to init schema: %w", err)
	}
	return nil
}

// validateHostname ensures hostname is valid and safe.
func validateHostname(hostname string) error {
	if hostname == "" {
		return errors.New("hostname cannot be empty")
	}
	if len(hostname) > 253 {
		return errors.New("hostname too long")
	}
	// Basic validation - could be expanded.
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

	var machineID int64
	err := s.db.QueryRowContext(ctx, `SELECT id FROM machines WHERE hostname = ?`, host).Scan(&machineID)
	if errors.Is(err, sql.ErrNoRows) {
		res, err2 := s.db.ExecContext(ctx, `INSERT INTO machines(hostname) VALUES (?)`, host)
		if err2 != nil {
			return 0, fmt.Errorf("failed to insert new machine: %w", err2)
		}
		machineID, err = res.LastInsertId()
		if err != nil {
			return 0, fmt.Errorf("failed to get last insert id: %w", err)
		}
	} else if err != nil {
		return 0, fmt.Errorf("failed to query machine id: %w", err)
	}
	return machineID, nil
}

// RotatePassword saves a new Administrator password for host and writes an audit entry.
func (s *Store) RotatePassword(ctx context.Context, host, password, actor, remoteAddr string) error {
	if password == "" {
		return errors.New("password cannot be empty")
	}
	query := `REPLACE INTO passwords(machine_id, password, updated_at, actor) VALUES (?,?,?,?)`
	return s.updateAndAudit(ctx, host, actor, remoteAddr, "rotate_password", query, password)
}

// GetPassword returns the latest password info for host and logs the access.
func (s *Store) GetPassword(ctx context.Context, host, actor, remoteAddr string) (*PasswordInfo, error) {
	info := &PasswordInfo{}
	var unixTime int64
	query := `SELECT p.password, p.updated_at, p.actor
		FROM passwords p
		JOIN machines m ON p.machine_id = m.id
		WHERE m.hostname = ?`

	err := s.getAndAudit(ctx, host, actor, remoteAddr, "fetch_password", query, &info.Password, &unixTime, &info.Actor)
	if err != nil {
		return nil, err
	}
	info.RotatedAt = time.Unix(unixTime, 0)
	return info, nil
}

// UpdateBDEKey stores or updates the BitLocker key for host and audits the event.
func (s *Store) UpdateBDEKey(ctx context.Context, host, keyText, actor, remoteAddr string) error {
	if keyText == "" {
		return errors.New("recovery key cannot be empty")
	}
	query := `REPLACE INTO bitlocker_keys(machine_id, key_text, updated_at, actor) VALUES (?,?,?,?)`
	return s.updateAndAudit(ctx, host, actor, remoteAddr, "update_key", query, keyText)
}

// GetBDEKey returns the BitLocker recovery key info for host and logs the access.
func (s *Store) GetBDEKey(ctx context.Context, host, actor, remoteAddr string) (*BitLockerKeyInfo, error) {
	info := &BitLockerKeyInfo{}
	var unixTime int64
	query := `SELECT k.key_text, k.updated_at, k.actor
		FROM bitlocker_keys k
		JOIN machines m ON k.machine_id = m.id
		WHERE m.hostname = ?`

	err := s.getAndAudit(ctx, host, actor, remoteAddr, "fetch_bde_key", query, &info.Key, &unixTime, &info.Actor)
	if err != nil {
		return nil, err
	}
	info.UpdatedAt = time.Unix(unixTime, 0)
	return info, nil
}

// updateAndAudit is a private helper to reduce duplication for update operations.
func (s *Store) updateAndAudit(ctx context.Context, host, actor, remoteAddr, auditAction, query string, val string) error {
	if actor == "" {
		actor = actorUnknown
	}
	machineID, err := s.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
			log.Printf("failed to rollback transaction: %v", err)
		}
	}()

	now := time.Now().Unix()
	if _, err = tx.ExecContext(ctx, query, machineID, val, now, actor); err != nil {
		return fmt.Errorf("failed to execute update: %w", err)
	}

	auditQuery := `INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`
	if _, err = tx.ExecContext(ctx, auditQuery, machineID, auditAction, actor, remoteAddr, now); err != nil {
		return fmt.Errorf("failed to insert audit log for %s: %w", auditAction, err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}
	return nil
}

// getAndAudit is a private helper to reduce duplication for get operations.
func (s *Store) getAndAudit(ctx context.Context, host, actor, remoteAddr, auditAction, query string, dest ...interface{}) error {
	if actor == "" {
		actor = actorUnknown
	}

	machineID, err := s.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	err = s.db.QueryRowContext(ctx, query, host).Scan(dest...)
	if errors.Is(err, sql.ErrNoRows) {
		return fmt.Errorf("no record found for host %s", host)
	}
	if err != nil {
		return fmt.Errorf("failed to scan row: %w", err)
	}

	// Log the retrieval
	auditQuery := `INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) VALUES (?,?,?,?,?)`
	_, err = s.db.ExecContext(ctx, auditQuery, machineID, auditAction, actor, remoteAddr, time.Now().Unix())
	if err != nil {
		return fmt.Errorf("failed to insert audit log for %s: %w", auditAction, err)
	}

	return nil
}
