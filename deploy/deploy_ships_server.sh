#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy_ships_server.sh – Production installer for SHIPS2-Go server
# ---------------------------------------------------------------------------
# * Installs ships-server binary & shipsc_wrapper.sh under /opt/ships
# * Creates dedicated system user/group 'ships'
# * Creates restricted SSH operator user 'shipscmd' with ForceCommand wrapper
# * Sets up state dir /var/lib/ships and systemd service ships-server
#
# Usage:
#   ./deploy_ships_server.sh [--release-url URL] [--with-wazuh] [--auth user:pass]
#
# Tested on Debian / Ubuntu. Requires: curl, sudo, useradd, systemd.
# ---------------------------------------------------------------------------
set -euo pipefail

# --- vars --------------------------------------------------------------
DEFAULT_RELEASE_URL="https://github.com/jottavia/ships-go/releases/latest/download"
BIN_URL="${RELEASE_URL:-$DEFAULT_RELEASE_URL}/ships-server"
WRAPPER_URL="${RELEASE_URL:-$DEFAULT_RELEASE_URL}/shipsc_wrapper.sh"
CLIENT_URL="${RELEASE_URL:-$DEFAULT_RELEASE_URL}/shipsc"

INSTALL_DIR=/opt/ships
BIN_DIR="${INSTALL_DIR}/bin"
STATE_DIR=/var/lib/ships
SERVICE_FILE=/etc/systemd/system/ships-server.service
SSH_USER=shipscmd
SSH_GROUP=ships
FORCE_COMMAND="${BIN_DIR}/shipsc_wrapper.sh"

WITH_WAZUH=false
AUTH_USER=""
AUTH_PASS=""

# --- helpers -----------------------------------------------------------
info() { printf "\e[32m[INFO]\e[0m %s\n" "$*"; }
warn() { printf "\e[33m[WARN]\e[0m %s\n" "$*"; }
err()  { printf "\e[31m[ERROR]\e[0m %s\n" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --release-url URL    Base URL for downloading binaries (default: GitHub releases)
  --with-wazuh        Also configure rsyslog and Wazuh integration
  --auth user:pass    Enable HTTP Basic Auth with username:password
  --help              Show this help

Example:
  $0 --with-wazuh --auth admin:secret123
EOF
    exit 0
}

# --- parse arguments ---------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        --release-url)
            RELEASE_URL="$2"
            BIN_URL="${RELEASE_URL}/ships-server"
            WRAPPER_URL="${RELEASE_URL}/shipsc_wrapper.sh"
            CLIENT_URL="${RELEASE_URL}/shipsc"
            shift 2
            ;;
        --with-wazuh)
            WITH_WAZUH=true
            shift
            ;;
        --auth)
            if [[ "$2" =~ ^([^:]+):(.+)$ ]]; then
                AUTH_USER="${BASH_REMATCH[1]}"
                AUTH_PASS="${BASH_REMATCH[2]}"
            else
                err "Invalid auth format. Use: user:password"
            fi
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            err "Unknown option: $1"
            ;;
    esac
done

# --- ensure root -------------------------------------------------------
[[ $EUID -eq 0 ]] || err "Run as root or with sudo"

# --- install system user & group --------------------------------------
if ! id -u ships >/dev/null 2>&1; then
    info "Creating system group '$SSH_GROUP' and user 'ships'..."
    groupadd --system "$SSH_GROUP"
    useradd --system --home "$INSTALL_DIR" --shell /usr/sbin/nologin \
            --gid "$SSH_GROUP" ships
fi

if ! id -u "$SSH_USER" >/dev/null 2>&1; then
    info "Creating SSH operator user '$SSH_USER'..."
    useradd --system --home "$INSTALL_DIR" --shell /bin/bash \
            --gid "$SSH_GROUP" --comment "SHIPS2-Go operator" "$SSH_USER"
fi

# --- directories -------------------------------------------------------
info "Creating directories..."
install -d -o ships -g "$SSH_GROUP" "$INSTALL_DIR" "$BIN_DIR" "$STATE_DIR"

# --- download binaries -------------------------------------------------
info "Downloading SHIPS2-Go server binary..."
if ! curl -fsSL "$BIN_URL" -o "$BIN_DIR/ships-server.tmp"; then
    err "Failed to download server binary from $BIN_URL"
fi
install -m 0755 "$BIN_DIR/ships-server.tmp" "$BIN_DIR/ships-server"
rm "$BIN_DIR/ships-server.tmp"

info "Downloading shipsc client binary..."
if ! curl -fsSL "$CLIENT_URL" -o "$BIN_DIR/shipsc.tmp"; then
    err "Failed to download client binary from $CLIENT_URL"
fi
install -m 0755 "$BIN_DIR/shipsc.tmp" "$BIN_DIR/shipsc"
rm "$BIN_DIR/shipsc.tmp"

info "Downloading shipsc_wrapper.sh..."
if ! curl -fsSL "$WRAPPER_URL" -o "$FORCE_COMMAND.tmp"; then
    err "Failed to download wrapper script from $WRAPPER_URL"
fi
install -m 0755 "$FORCE_COMMAND.tmp" "$FORCE_COMMAND"
rm "$FORCE_COMMAND.tmp"
chown ships:"$SSH_GROUP" "$FORCE_COMMAND"

# --- systemd service ---------------------------------------------------
info "Installing systemd unit..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SHIPS2-Go password escrow server
After=network.target

[Service]
User=ships
Group=$SSH_GROUP
ExecStart=${BIN_DIR}/ships-server
Restart=on-failure
RestartSec=5
Environment=SHIPS_ADDR=127.0.0.1:8080
Environment=SHIPS_DB=${STATE_DIR}/ships.db
EOF

# Add auth environment variables if configured
if [[ -n "$AUTH_USER" && -n "$AUTH_PASS" ]]; then
    cat >> "$SERVICE_FILE" <<EOF
Environment=SHIPS_AUTH_USER=${AUTH_USER}
Environment=SHIPS_AUTH_PASS=${AUTH_PASS}
EOF
fi

cat >> "$SERVICE_FILE" <<EOF

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ships-server

# Wait for service to start
sleep 2
if systemctl is-active --quiet ships-server; then
    info "SHIPS2-Go server started successfully"
else
    warn "SHIPS2-Go server failed to start. Check: journalctl -u ships-server"
fi

# --- configure SSH wrapper --------------------------------------------
info "Setting up SSH access for $SSH_USER..."
SSH_DIR="/home/${SSH_USER}/.ssh"
install -d -m 0700 -o "$SSH_USER" -g "$SSH_GROUP" "$SSH_DIR"
AUTH_KEYS="$SSH_DIR/authorized_keys"

if [[ ! -f "$AUTH_KEYS" ]]; then
    touch "$AUTH_KEYS"
    chown "$SSH_USER:$SSH_GROUP" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
fi

# --- optional wazuh integration ---------------------------------------
if [[ "$WITH_WAZUH" == "true" ]]; then
    info "Configuring Wazuh integration..."
    if [[ -f "${INSTALL_DIR}/deploy/deploy_rsyslog_shipsc.sh" ]]; then
        bash "${INSTALL_DIR}/deploy/deploy_rsyslog_shipsc.sh"
        bash "${INSTALL_DIR}/deploy/deploy_wazuh_local_rules.sh"
    else
        warn "Wazuh deployment scripts not found, skipping integration"
    fi
fi

# --- final instructions -----------------------------------------------
info "Deployment completed successfully!"
echo ""
echo "Next steps:"
echo "1. Add your SSH public key to $AUTH_KEYS with ForceCommand:"
echo "   command=\"$FORCE_COMMAND\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAA..."
echo ""
echo "2. Test SSH access:"
echo "   ssh $SSH_USER@localhost fetch TESTHOST"
echo ""
echo "3. Deploy shipsc.exe to Windows clients at C:\\Program Files\\Ships\\"
echo ""
if [[ -n "$AUTH_USER" ]]; then
    echo "HTTP Basic Auth enabled - use $AUTH_USER:$AUTH_PASS for API access"
else
    echo "HTTP Basic Auth disabled - consider enabling with --auth for production"
fi
echo ""
echo "Health check: curl http://127.0.0.1:8080/healthz"
