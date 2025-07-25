# SHIPS2-Go

A minimal, self-contained Go rewrite of **SHIPS2** for workgroup Windows 11 systems (with optional Linux support).

SHIPS2-Go provides secure password escrow and BitLocker key management without requiring Active Directory.

---

## Quick start (Debian 12)

```bash
# Install Go 1.22 and clone the repo
sudo apt install -y golang-go git
git clone https://github.com/jottavia/ships-go.git && cd ships-go

# Build static binary
make linux

# Deploy with authentication and Wazuh integration
sudo ./deploy/deploy_ships_server.sh --with-wazuh --auth admin:SecurePass123
```

The API is now available at `http://127.0.0.1:8080`. Health check:

```bash
curl http://127.0.0.1:8080/healthz
```

## Windows 11 client setup

1. Build the client (or download from Releases):
   ```bash
   make windows
   # Creates bin/shipsc.exe
   ```

2. Copy `shipsc.exe` to `C:\Program Files\Ships\` on each Windows client.

3. Import the Scheduled Task from `docs/client_task.xml`:
   - Open Task Scheduler as Administrator
   - Action → Import Task...
   - Select `client_task.xml`
   - Modify server URL if needed

4. Test the setup:
   ```powershell
   # Test manual rotation
   & "C:\Program Files\Ships\shipsc.exe" rotate $env:COMPUTERNAME -actor TestUser
   
   # Fetch password (from Linux server)
   ssh shipscmd@server fetch WINBOX01
   ```

## Security Features

- **HTTP Basic Auth**: Optional authentication for API access
- **SSH-only Access**: Operators connect via SSH with restricted commands
- **Comprehensive Audit Logging**: All access events logged to syslog
- **Wazuh Integration**: Real-time security monitoring and alerting
- **Input Validation**: Hostname and password validation on all inputs
- **Rate Limiting Detection**: Alerts on suspicious access patterns

## File layout

```
cmd/
  server/     → ships-server main program with auth & logging
  client/     → shipsc CLI with improved error handling
internal/
  api/        → HTTP handlers with proper JSON responses
  store/      → SQLite store with audit logging
deploy/
  *.sh        → Production deployment scripts
bin/
  shipsc_wrapper.sh → Enhanced SSH wrapper with validation
tracking/
  *.md        → Project tracking and status files
```

## Configuration

### Server Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SHIPS_DB` | `/var/lib/ships/ships.db` | SQLite database path |
| `SHIPS_ADDR` | `127.0.0.1:8080` | Server listen address |
| `SHIPS_AUTH_USER` | _(none)_ | HTTP Basic Auth username |
| `SHIPS_AUTH_PASS` | _(none)_ | HTTP Basic Auth password |

### Client Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SHIPS_SERVER` | `http://localhost:8080` | Server base URL |

## API Reference (v1)

All endpoints require HTTP Basic Auth if configured.

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| `GET` | `/api/v1/password/:host` | Get password info | `{password, rotated_at, actor}` |
| `POST` | `/api/v1/rotate` | Rotate password | `{status, hostname, actor}` |
| `GET` | `/api/v1/bde/:host` | Get BitLocker key | `{key, updated_at, actor}` |
| `POST` | `/api/v1/update_key` | Update BitLocker key | `{status, hostname, actor}` |
| `GET` | `/healthz` | Health check | `ok` |
| `GET` | `/version` | Version info | `{version, service}` |

### Request Formats

**Rotate Password:**
```json
{
  "host": "WINBOX01",
  "password": "NewSecurePass123!",
  "actor": "admin"
}
```

**Update BitLocker Key:**
```json
{
  "host": "WINBOX01", 
  "key": "123456-123456-123456-123456-123456-123456-123456-123456",
  "actor": "admin"
}
```

## Database Schema (SQLite)

```sql
CREATE TABLE machines (
    id INTEGER PRIMARY KEY,
    hostname TEXT UNIQUE NOT NULL,
    first_seen INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE passwords (
    machine_id INTEGER NOT NULL UNIQUE,
    password   TEXT    NOT NULL,
    updated_at INTEGER NOT NULL,
    actor      TEXT    NOT NULL,
    FOREIGN KEY(machine_id) REFERENCES machines(id)
);

CREATE TABLE bitlocker_keys (
    machine_id INTEGER NOT NULL UNIQUE,
    key_text   TEXT    NOT NULL,
    updated_at INTEGER NOT NULL,
    actor      TEXT    NOT NULL,
    FOREIGN KEY(machine_id) REFERENCES machines(id)
);

CREATE TABLE audit_logs (
    id         INTEGER PRIMARY KEY,
    machine_id INTEGER,
    action     TEXT    NOT NULL,
    actor      TEXT    NOT NULL,
    remote_addr TEXT   NOT NULL,
    timestamp  INTEGER NOT NULL
);
```

## Security Model

- **Localhost-only API**: Server binds to 127.0.0.1 by default
- **SSH-based Access**: Operators use SSH with ForceCommand wrapper
- **Input Validation**: All hostnames and passwords validated
- **Comprehensive Auditing**: Every read/write operation logged
- **Wazuh Integration**: Real-time monitoring with rule 91000-91005
- **Optional HTTP Auth**: Basic authentication for API endpoints

## Build Commands

```bash
make                    # Lint, test, build for current platform
make windows           # Cross-compile Windows client
make linux             # Build Linux server (static)
make release           # Create release archive
make dev-setup         # Install development tools
make clean             # Remove build artifacts
```

## Deployment

### Production Server

Use the automated deployment script:

```bash
# Basic deployment
sudo ./deploy/deploy_ships_server.sh

# With authentication and Wazuh
sudo ./deploy/deploy_ships_server.sh --auth admin:SecurePass123 --with-wazuh

# Custom release URL
sudo ./deploy/deploy_ships_server.sh --release-url https://your-server.com/releases
```

### Manual SSH Setup

Add operator SSH keys to `/home/shipscmd/.ssh/authorized_keys`:

```
command="/opt/ships/bin/shipsc_wrapper.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAA...
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `shipsc rotate` returns 500 | Check server logs: `journalctl -u ships-server` |
| Wrapper says "command not allowed" | Ensure you typed `fetch`, `rotate`, or `bde` exactly |
| No Wazuh alerts | Confirm rsyslog forwarding: `tail -f /var/ossec/logs/shipsc.log` |
| SQLite locked | Check file permissions on `/var/lib/ships/ships.db` |
| Authentication failed | Verify `SHIPS_AUTH_USER`/`SHIPS_AUTH_PASS` environment variables |

## License

MIT License

Copyright (c) 2025 Joseph V. Ottaviano

---

### Recent Changes (v1.0)

- ✅ Fixed client/server API compatibility issues
- ✅ Added comprehensive error handling and validation
- ✅ Implemented HTTP Basic Authentication support
- ✅ Enhanced audit logging with remote address tracking
- ✅ Updated deployment scripts with proper configuration
- ✅ Added Wazuh integration with structured logging
- ✅ Improved SSH wrapper with input validation
- ✅ Added version endpoints and build versioning
- ✅ Standardized file naming (Makefile)
- ✅ Updated all documentation for accuracy
