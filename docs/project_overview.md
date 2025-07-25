# SHIPS2‑Go Project Overview
*A zero‑cost, self‑hosted replacement for Microsoft LAPS / SHIPS, written entirely in Go.*

> **Status:** Production Ready ✅  |  **Version:** 1.0+

---

## 0. TL;DR – One‑line Install

```bash
# On a fresh Debian 12 server (root):
curl -fsSL https://raw.githubusercontent.com/your‑org/ships-go/main/deploy/deploy_ships_server.sh | bash -s -- --with‑wazuh --auth admin:SecurePass123
```
*Result: systemd service running, SSH wrapper in place, rsyslog/Wazuh forwarding configured, HTTP Basic Auth enabled.*  
Now copy **`shipsc.exe`** to each Windows PC and import **`docs/client_task.xml`**. Done.

---

## 1. What Problem Does SHIPS2‑Go Solve?

| Traditional solution | Why it falls short for small IT shops |
| -------------------- | ------------------------------------ |
| **Microsoft LAPS** (AD‑only) | Requires an AD domain; you just have a work‑group. |
| **SHIPS (Ruby)** | Feature‑rich but heavy; dependencies, certificates, Docker, Ruby… |
| **Do nothing** | Local *Administrator* passwords diverge → nobody can log in when needed. |

**SHIPS2‑Go** is a **single‑binary** service + **single‑binary** client that:
1. **Rotates** & escrows the local *Administrator* password every 24 h.
2. **Escrows** the BitLocker 48‑digit recovery key.
3. Lets authorised operators **retrieve** either over **SSH (port 22 only)**.
4. **Audits** every retrieval to syslog → Wazuh (rules 91000-91005).
5. **Authenticates** API access with HTTP Basic Auth (optional).

No domain. No Docker. No external DB. Just Go + SQLite + Security.

---

## 2. High‑Level Architecture

```
┌──────────────────── Windows Client ───────────────────┐
│  shipsc.exe (rotate + update‑key)   Scheduled Task    │
└───────────────────────────────────────────────────────┘
           ▲ HTTPS (loopback → server)   
           │ + Optional HTTP Basic Auth
           │      (no open 8080 to LAN)  
           ▼
┌──────────────────── Linux Server ─────────────────────┐
│ ships‑server (127.0.0.1:8080)  │  SQLite DB          │
│ + HTTP Basic Auth (optional)   │  + Complete Audit   │
│ shipsc_wrapper.sh  (SSH ForceCommand)                │
│ + Input Validation             │  + JSON Logging     │
│ rsyslog  →  Wazuh rules 91000-91005                  │
└───────────────────────────────────────────────────────┘
```

* **ships‑server** never listens on external interfaces by default.  
* **Operators** SSH as `shipscmd` ➜ forced into `bin/shipsc_wrapper.sh`.  
* Wrapper validates inputs and calls local CLI which calls `http://127.0.0.1:8080/api/v1/...`.
* **Optional HTTP Basic Auth** protects API endpoints.
* **Complete audit trail** for compliance and security monitoring.

---

## 3. File/Directory Layout

| Path | Purpose |
| ---- | ------- |
| `cmd/server/main.go`     | HTTP API + graceful shutdown + authentication |
| `cmd/client/main.go`     | Cross‑platform CLI (`shipsc`) with enhanced error handling |
| `internal/store/`        | SQLite access layer with audit logging |
| `internal/api/`          | Gin‑based handlers with proper JSON responses |
| `bin/shipsc_wrapper.sh`  | Enhanced SSH command wrapper with input validation |
| `deploy/`                | Production deployment scripts with auth support |
| `docs/`                  | Project overview, Scheduled Task, Wazuh guide |
| `tracking/`              | Project tracking and status files |
| `Makefile`               | `make build`, `make lint`, `make windows`, `make release` |

---

## 4. Security Features

### Authentication & Authorization
- **HTTP Basic Auth**: Optional username/password protection for API
- **SSH-only Access**: All operator access through restricted SSH wrapper
- **Input Validation**: Comprehensive validation of hostnames, passwords
- **Command Restrictions**: SSH wrapper only allows `fetch`, `rotate`, `bde`

### Audit & Monitoring
- **Complete Audit Trail**: Every password/key access logged with:
  - Timestamp (UTC)
  - Actor (who performed the action)
  - Remote IP address
  - Action type (fetch/rotate/update)
  - Hostname affected
- **Structured Logging**: JSON format for easy parsing
- **Wazuh Integration**: Real-time security monitoring with rules:
  - 91000: Base SHIPS2-Go events
  - 91001: Access denied (level 8)
  - 91002: Password fetch (level 5)  
  - 91003: BitLocker key fetch (level 5)
  - 91004: Password rotation (level 3)
  - 91005: Rate limiting alert (level 10)

### Network Security
- **Localhost Binding**: API only accessible from 127.0.0.1
- **No Direct API Access**: All remote access through SSH wrapper
- **Single Port Exposure**: Only SSH (port 22) exposed to network

---

## 5. Production Deployment

### Automated Deployment

```bash
# Basic deployment (no auth)
sudo ./deploy/deploy_ships_server.sh

# With HTTP Basic Auth
sudo ./deploy/deploy_ships_server.sh --auth username:password

# With Wazuh integration
sudo ./deploy/deploy_ships_server.sh --with-wazuh

# Full production setup
sudo ./deploy/deploy_ships_server.sh \
  --auth admin:SecurePass123 \
  --with-wazuh \
  --release-url https://your-server.com/releases
```

### Manual Configuration

1. **Server Setup**:
   ```bash
   # Environment variables in /etc/systemd/system/ships-server.service
   Environment=SHIPS_AUTH_USER=admin
   Environment=SHIPS_AUTH_PASS=SecurePass123
   Environment=SHIPS_ADDR=127.0.0.1:8080
   Environment=SHIPS_DB=/var/lib/ships/ships.db
   ```

2. **SSH Operator Access**:
   ```bash
   # Add to /home/shipscmd/.ssh/authorized_keys
   command="/opt/ships/bin/shipsc_wrapper.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAA...
   ```

3. **Client Configuration**:
   ```powershell
   # Set environment variable on Windows clients if using auth
   [Environment]::SetEnvironmentVariable("SHIPS_AUTH", "admin:SecurePass123", "Machine")
   ```

---

## 6. Windows Client Deployment

### Automated Setup (PowerShell)

```powershell
# Create directory
New-Item -Path "C:\Program Files\Ships" -ItemType Directory -Force

# Download client
Invoke-WebRequest -Uri "https://your-server.com/releases/shipsc.exe" -OutFile "C:\Program Files\Ships\shipsc.exe"

# Import scheduled task
Register-ScheduledTask -Xml (Get-Content "client_task.xml" | Out-String) -TaskName "SHIPS2-Go Daily Rotation"

# Test configuration
& "C:\Program Files\Ships\shipsc.exe" rotate $env:COMPUTERNAME -actor TestSetup
```

### Manual Setup

1. Copy `shipsc.exe` to `C:\Program Files\Ships\`
2. Import `docs/client_task.xml` via Task Scheduler
3. Verify in Event Viewer → Applications and Services Logs → Ships
4. Test with: `shipsc.exe fetch %COMPUTERNAME%`

---

## 7. API Reference (v1)

### Authentication
If `SHIPS_AUTH_USER` and `SHIPS_AUTH_PASS` are configured, all API endpoints require HTTP Basic Authentication.

### Endpoints

| Method | Endpoint | Payload | Response | Auth Required |
| ------ | -------- | ------- | -------- | ------------- |
| `POST` | `/api/v1/rotate` | `{host, password, actor}` | `{status, hostname, actor}` | Optional |
| `POST` | `/api/v1/update_key` | `{host, key, actor}` | `{status, hostname, actor}` | Optional |
| `GET`  | `/api/v1/password/:h` | – | `{password, rotated_at, actor}` | Optional |
| `GET`  | `/api/v1/bde/:h` | – | `{key, updated_at, actor}` | Optional |
| `GET`  | `/healthz` | – | `ok` (text/plain) | No |
| `GET`  | `/version` | – | `{version, service}` | No |

### Headers
- `X-Actor`: Override the actor for audit logging
- `Authorization`: HTTP Basic Auth (if enabled)

---

## 8. Database Schema (SQLite)

```sql
-- Updated schema with audit enhancements
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
    action     TEXT    NOT NULL,        -- fetch_password, rotate_password, etc.
    actor      TEXT    NOT NULL,        -- who performed the action
    remote_addr TEXT   NOT NULL,        -- IP address of requester
    timestamp  INTEGER NOT NULL         -- Unix timestamp
);
```

---

## 9. Monitoring & Alerting

### Wazuh Rules (91000-91005)

- **91000**: Base SHIPS2-Go events (level 3)
- **91001**: Access denied attempts (level 8) 
- **91002**: Password retrievals (level 5)
- **91003**: BitLocker key retrievals (level 5)
- **91004**: Password rotations (level 3)
- **91005**: Rate limiting - multiple fetches from same IP (level 10)

### Log Locations

- **Application Logs**: `journalctl -u ships-server`
- **SSH Wrapper Logs**: `/var/log/syslog` (tag: shipsc-wrapper)
- **SHIPS2-Go Events**: `/var/ossec/logs/shipsc.log`
- **Wazuh Alerts**: `/var/ossec/logs/alerts/alerts.json`

### Health Monitoring

```bash
# Service health
systemctl status ships-server

# API health
curl http://127.0.0.1:8080/healthz

# Database connectivity
sudo -u ships sqlite3 /var/lib/ships/ships.db ".tables"

# Recent audit events
sudo -u ships sqlite3 /var/lib/ships/ships.db "SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 10;"
```

---

## 10. Troubleshooting

### Common Issues

| Symptom | Diagnosis | Resolution |
|---------|-----------|------------|
| `shipsc rotate` returns 500 | Database permissions | `chown ships:ships /var/lib/ships/ships.db` |
| SSH wrapper denies command | Invalid hostname | Check hostname contains only `[a-zA-Z0-9.-]` |
| No Wazuh alerts | rsyslog config | Check `/etc/rsyslog.d/30-shipsc.conf` |
| Authentication failed | Wrong credentials | Verify `SHIPS_AUTH_USER`/`SHIPS_AUTH_PASS` |
| Client can't connect | Firewall/network | Ensure SSH port 22 accessible |

### Debug Commands

```bash
# Test SSH wrapper manually
sudo -u shipscmd bash -c 'SSH_ORIGINAL_COMMAND="fetch TESTHOST" /opt/ships/bin/shipsc_wrapper.sh'

# Test API directly (with auth)
curl -u admin:password http://127.0.0.1:8080/api/v1/password/TESTHOST

# Trace database operations
sudo -u ships strace -e trace=file sqlite3 /var/lib/ships/ships.db ".tables"

# Monitor real-time logs
journalctl -u ships-server -f

# Test Wazuh rule
logger -t shipsc-wrapper 'ALLOW: testuser executed: fetch TESTHOST'
```

---

## 11. Development & Contribution

### Development Setup

```bash
# Install development tools
make dev-setup

# Run tests and build
make all

# Cross-compile for Windows
make windows

# Create release
make release
```

### Code Quality Standards

- **Go 1.22+** with modules
- **golangci-lint** for linting
- **staticcheck** for static analysis
- **gofmt** for code formatting
- **Test coverage** >80% target

### Contributing

1. Open an issue for substantial changes
2. Follow existing code style and patterns
3. Add tests for new functionality
4. Update documentation
5. Ensure `make all` passes

---

## 12. License

```
MIT License
Copyright (c) 2025 Joseph V. Ottaviano

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Release Notes

### Version 1.0 (Current)

**🎉 Production Ready Release**

**New Features:**
- HTTP Basic Authentication support for API security
- Enhanced audit logging with remote IP tracking
- Comprehensive input validation and security hardening
- Wazuh integration with 5 monitoring rules (91000-91005)
- Structured JSON logging for better log parsing
- Automated production deployment scripts
- Version tracking and build information

**Bug Fixes:**
- Fixed client/server API compatibility (JSON field mapping)
- Corrected database schema inconsistencies
- Fixed deployment scripts with working URLs
- Standardized file naming (Makefile)

**Security Improvements:**
- Added hostname and password validation
- Enhanced SSH wrapper with input sanitization
- Rate limiting detection and alerting
- Complete audit trail for all operations
- Protection against timing attacks in authentication

**Developer Experience:**
- Improved error messages and debugging
- Better documentation with troubleshooting guides
- Enhanced Makefile with development tools
- Project tracking files for maintenance
- Comprehensive test coverage

This release represents a complete, production-ready solution for password escrow and BitLocker key management in workgroup environments.
