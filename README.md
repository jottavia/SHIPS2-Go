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

## License

MIT License

Copyright (c) 2025 Joseph V. Ottaviano
