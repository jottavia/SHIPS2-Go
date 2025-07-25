# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Building and Testing
```bash
# Full development cycle (lint, test, build)
make all

# Build for current platform
make build

# Cross-compile Windows client from Linux/macOS
make windows

# Build Linux server binary (static)
make linux

# Run tests
make test

# Run linting (go vet, staticcheck, golangci-lint, gofmt)
make lint

# Clean build artifacts
make clean

# Create release package
make release

# Install development tools
make dev-setup
```

### Testing and Validation
```bash
# Run integration tests
go test -v ./tests/

# Test API endpoints manually
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/version

# Test with authentication (if configured)
curl -u username:password http://127.0.0.1:8080/api/v1/password/TESTHOST
```

### Deployment Commands
```bash
# Basic deployment
sudo ./deploy/deploy_ships_server.sh

# Deployment with auth and Wazuh
sudo ./deploy/deploy_ships_server.sh --auth admin:password --with-wazuh

# Test SSH wrapper
sudo -u shipscmd bash -c 'SSH_ORIGINAL_COMMAND="fetch TESTHOST" /opt/ships/bin/shipsc_wrapper.sh'
```

## Architecture Overview

This is a Go-based password escrow system (SHIPS2-Go) that replaces Microsoft LAPS for workgroup environments. The system consists of:

### Core Components
- **Server** (`cmd/server/main.go`): HTTP API server with Gin framework, provides REST endpoints for password/key management
- **Client** (`cmd/client/main.go`): CLI tool (`shipsc`) for rotating passwords and managing BitLocker keys
- **API Layer** (`internal/api/api.go`): HTTP handlers with JSON request/response handling and input validation
- **Storage Layer** (`internal/store/store.go`): SQLite database operations with audit logging

### Key Architecture Patterns
- **Client-Server Architecture**: Windows clients communicate with Linux server via HTTP API
- **Security Model**: 
  - Server binds to localhost (127.0.0.1:8080) by default
  - Optional HTTP Basic Authentication via environment variables
  - SSH-only remote access through restricted wrapper script
  - Complete audit trail for all operations
- **Database**: SQLite with tables for machines, passwords, bitlocker_keys, and audit_logs
- **Authentication**: Constant-time comparison for HTTP Basic Auth to prevent timing attacks

### Security Features
- Input validation for hostnames and passwords
- Comprehensive audit logging with remote IP tracking
- SSH wrapper with command restrictions (only allows fetch, rotate, bde commands)
- Wazuh integration for security monitoring
- Rate limiting detection and alerting

### Environment Configuration
- `SHIPS_DB`: SQLite database path (default: `/var/lib/ships/ships.db`)
- `SHIPS_ADDR`: Server listen address (default: `127.0.0.1:8080`)
- `SHIPS_AUTH_USER`: HTTP Basic Auth username (optional)
- `SHIPS_AUTH_PASS`: HTTP Basic Auth password (optional)
- `SHIPS_SERVER`: Client server URL (default: `http://localhost:8080`)

### API Endpoints (v1)
- `POST /api/v1/rotate`: Rotate machine password
- `GET /api/v1/password/:host`: Fetch machine password
- `POST /api/v1/update_key`: Update BitLocker recovery key
- `GET /api/v1/bde/:host`: Fetch BitLocker recovery key
- `GET /healthz`: Health check
- `GET /version`: Version information

### Database Schema
- `machines`: Store hostname and first_seen timestamp
- `passwords`: Current passwords with metadata (actor, updated_at)
- `bitlocker_keys`: BitLocker recovery keys with metadata
- `audit_logs`: Complete audit trail of all operations

### Dependencies
- **Gin** (`github.com/gin-gonic/gin`): HTTP web framework
- **SQLite** (`modernc.org/sqlite`): Pure Go SQLite driver
- **Standard Library**: Crypto, HTTP, time handling

### Testing
- Integration tests in `tests/integration_test.go`
- Tests cover API compatibility, input validation, and audit logging
- Uses `httptest` for HTTP testing and temporary SQLite databases

### Deployment
- Production deployment scripts in `deploy/` directory
- systemd service configuration
- SSH wrapper for secure remote access
- Wazuh integration with custom rules (91000-91005)
- rsyslog configuration for structured logging

### Build System
- Go 1.24+ required
- Cross-compilation support for Windows clients
- Static binary builds for Linux deployment
- Version embedding via build flags
- Development tools integration (staticcheck, golangci-lint)

### Code Quality Standards
- gofmt for formatting
- golangci-lint for comprehensive linting
- staticcheck for static analysis
- Input validation throughout
- Comprehensive error handling
- Structured logging with JSON format