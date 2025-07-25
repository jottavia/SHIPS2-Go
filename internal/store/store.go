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

// Store wraps a SQLite database that holds machine passwords, 
// BitLocker keys and an audit log.
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

// defaultUnknownActor is used when no actor is provided.
const defaultUnknownActor = "unknown"

// New opens (or creates) the database file at path and ensures the schema exists.
func New(path string) (*Store, error) {
	database, err := sql.Open("sqlite", path+"?_busy_timeout=10000&_journal_mode=WAL")
	if err != nil {
		return nil, err
	}
	storeInstance := &Store{db: database}
	if err := storeInstance.initSchema(); err != nil {
		database.Close()
		return nil, err
	}
	return storeInstance, nil
}

// Close closes the underlying DB connection.
func (storeInstance *Store) Close() error { return storeInstance.db.Close() }

// initSchema creates tables if they do not yet exist.
func (storeInstance *Store) initSchema() error {
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
	_, err := storeInstance.db.Exec(schema)
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
func (storeInstance *Store) getMachineID(
	ctx context.Context,
	host string,
) (int64, error) {
	if err := validateHostname(host); err != nil {
		return 0, err
	}

	var machineID int64
	err := storeInstance.db.QueryRowContext(
		ctx,
		`SELECT id FROM machines WHERE hostname = ?`,
		host,
	).Scan(&machineID)
	if errors.Is(err, sql.ErrNoRows) {
		result, insertErr := storeInstance.db.ExecContext(
			ctx,
			`INSERT INTO machines(hostname) VALUES (?)`,
			host,
		)
		if insertErr != nil {
			return 0, insertErr
		}
		machineID, err = result.LastInsertId()
	}
	return machineID, err
}

// RotatePassword saves a new Administrator password for host and writes an audit entry.
func (storeInstance *Store) RotatePassword(
	ctx context.Context,
	host, password, actor, remoteAddr string,
) error {
	if password == "" {
		return errors.New("password cannot be empty")
	}
	if actor == "" {
		actor = defaultUnknownActor
	}
	machineID, err := storeInstance.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	transaction, err := storeInstance.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	now := time.Now().Unix()
	if _, err = transaction.ExecContext(ctx,
		`REPLACE INTO passwords(machine_id, password, updated_at, actor) VALUES (?,?,?,?)`,
		machineID, password, now, actor); err != nil {
		// Roll back the transaction and return rollback error if any.
		if rbErr := transaction.Rollback(); rbErr != nil {
			return rbErr
		}
		return err
	}
	if _, err = transaction.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) 
         VALUES (?,?,?,?,?)`,
		machineID, "rotate_password", actor, remoteAddr, now); err != nil {
		if rbErr := transaction.Rollback(); rbErr != nil {
			return rbErr
		}
		return err
	}
	return transaction.Commit()
}

// GetPassword returns the latest password info for host and logs the access.
// nolint:dupl // similar structure to GetBDEKey is intentional
func (storeInstance *Store) GetPassword(
	ctx context.Context,
	host, actor, remoteAddr string,
) (*PasswordInfo, error) {
	machineID, err := storeInstance.getMachineID(ctx, host)
	if err != nil {
		return nil, err
	}

	var password string
	var updatedAt int64
	var pwActor string
	err = storeInstance.db.QueryRowContext(ctx,
		`SELECT p.password, p.updated_at, p.actor
           FROM passwords p
           JOIN machines m ON p.machine_id = m.id
          WHERE m.hostname = ?`,
		host).Scan(&password, &updatedAt, &pwActor)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("no password recorded for host %s", host)
	}
	if err != nil {
		return nil, err
	}

	// Log the password retrieval
	if actor == "" {
		actor = defaultUnknownActor
	}
	_, err = storeInstance.db.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) 
         VALUES (?,?,?,?,?)`,
		machineID, "fetch_password", actor, remoteAddr, time.Now().Unix())
	if err != nil {
		return nil, err
	}

	return &PasswordInfo{
		Password:  password,
		RotatedAt: time.Unix(updatedAt, 0),
		Actor:     pwActor,
	}, nil
}

// UpdateBDEKey stores or updates the BitLocker key for host and audits the event.
func (storeInstance *Store) UpdateBDEKey(
	ctx context.Context,
	host, keyText, actor, remoteAddr string,
) error {
	if keyText == "" {
		return errors.New("recovery key cannot be empty")
	}
	if actor == "" {
		actor = defaultUnknownActor
	}
	machineID, err := storeInstance.getMachineID(ctx, host)
	if err != nil {
		return err
	}

	transaction, err := storeInstance.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	now := time.Now().Unix()
	if _, err = transaction.ExecContext(ctx,
		`REPLACE INTO bitlocker_keys(machine_id, key_text, updated_at, actor) 
         VALUES (?,?,?,?)`,
		machineID, keyText, now, actor); err != nil {
		if rbErr := transaction.Rollback(); rbErr != nil {
			return rbErr
		}
		return err
	}
	if _, err = transaction.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) 
         VALUES (?,?,?,?,?)`,
		machineID, "update_key", actor, remoteAddr, now); err != nil {
		if rbErr := transaction.Rollback(); rbErr != nil {
			return rbErr
		}
		return err
	}
	return transaction.Commit()
}

// GetBDEKey returns the BitLocker recovery key info for host and logs the access.
// nolint:dupl // similar structure to GetPassword is intentional
func (storeInstance *Store) GetBDEKey(
	ctx context.Context,
	host, actor, remoteAddr string,
) (*BitLockerKeyInfo, error) {
	machineID, err := storeInstance.getMachineID(ctx, host)
	if err != nil {
		return nil, err
	}

	var key string
	var updatedAt int64
	var keyActor string
	err = storeInstance.db.QueryRowContext(ctx,
		`SELECT k.key_text, k.updated_at, k.actor
           FROM bitlocker_keys k
           JOIN machines m ON k.machine_id = m.id
          WHERE m.hostname = ?`,
		host).Scan(&key, &updatedAt, &keyActor)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("no recovery key for host %s", host)
	}
	if err != nil {
		return nil, err
	}

	// Log the key retrieval
	if actor == "" {
		actor = defaultUnknownActor
	}
	_, err = storeInstance.db.ExecContext(ctx,
		`INSERT INTO audit_logs(machine_id, action, actor, remote_addr, timestamp) 
         VALUES (?,?,?,?,?)`,
		machineID, "fetch_bde_key", actor, remoteAddr, time.Now().Unix())
	if err != nil {
		return nil, err
	}

	return &BitLockerKeyInfo{
		Key:       key,
		UpdatedAt: time.Unix(updatedAt, 0),
		Actor:     keyActor,
	}, nil
}
