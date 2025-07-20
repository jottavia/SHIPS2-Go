#!/usr/bin/env bash
# deploy_ships_server.sh - Deploy SHIPS2-Go server, systemd service and wrapper
#
# Installs binaries to /opt/ships/bin, configures the systemd service, and
# optionally enables HTTP Basic authentication and Wazuh integration.

set -euo pipefail

DEFAULT_RELEASE_URL="https://github.com/jottavia/ships-go/releases/latest/download"
RELEASE_URL="$DEFAULT_RELEASE_URL"
AUTH=""
WITH_WAZUH=0

usage() {
    cat <<USAGE
Usage: $0 [--auth USER:PASS] [--with-wazuh] [--release-url URL]

  --auth USER:PASS    Configure HTTP Basic Auth for ships-server
  --with-wazuh       Deploy rsyslog and Wazuh integration
  --release-url URL  Alternate URL for binary downloads
  -h, --help         Show this help
USAGE
}

info() { printf '\e[32m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }
err()  { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auth)
            [[ $# -ge 2 ]] || err "--auth requires USER:PASS"
            AUTH="$2"; shift 2;;
        --with-wazuh)
            WITH_WAZUH=1; shift;;
        --release-url)
            [[ $# -ge 2 ]] || err "--release-url requires URL"
            RELEASE_URL="$2"; shift 2;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done

[[ $EUID -eq 0 ]] || err "Run as root or with sudo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/opt/ships/bin"
SERVICE_FILE="/etc/systemd/system/ships-server.service"
DATA_DIR="/var/lib/ships"

install -d -m 755 "$BIN_DIR" "$DATA_DIR"

# create system users
if ! id -u ships >/dev/null 2>&1; then
    info "Creating system user 'ships'"
    useradd --system --home /opt/ships --shell /usr/sbin/nologin ships
fi
if ! id -u shipscmd >/dev/null 2>&1; then
    info "Creating operator user 'shipscmd'"
    useradd --system --home /opt/ships --shell /bin/bash --comment "SHIPS2-Go operator" shipscmd
fi
mkdir -p /home/shipscmd/.ssh
chown shipscmd:shipscmd /home/shipscmd/.ssh
chmod 700 /home/shipscmd/.ssh
chown ships:ships "$DATA_DIR"

fetch_binary() {
    local name="$1"
    local dest="$2"
    if [[ -f "$SCRIPT_DIR/../dist/${name}-linux-amd64" ]]; then
        cp "$SCRIPT_DIR/../dist/${name}-linux-amd64" "$dest"
    else
        info "Downloading ${name} from ${RELEASE_URL}"
        curl -fsSL "${RELEASE_URL}/${name}-linux-amd64" -o "$dest"
    fi
    chmod 755 "$dest"
}

if [[ ! -x "$BIN_DIR/ships-server" ]]; then
    info "Installing ships-server binary"
    fetch_binary "ships-server" "$BIN_DIR/ships-server"
fi
if [[ ! -x "$BIN_DIR/shipsc" ]]; then
    info "Installing shipsc binary"
    fetch_binary "shipsc" "$BIN_DIR/shipsc"
fi

if [[ -f "$SCRIPT_DIR/../bin/shipsc_wrapper.sh" ]]; then
    cp "$SCRIPT_DIR/../bin/shipsc_wrapper.sh" "$BIN_DIR/"
    chmod 755 "$BIN_DIR/shipsc_wrapper.sh"
fi

if [[ -f "$SCRIPT_DIR/ships_server" ]]; then
    cp "$SCRIPT_DIR/ships_server" "$SERVICE_FILE"
fi

if [[ -n "$AUTH" ]]; then
    AUTH_USER="${AUTH%%:*}"
    AUTH_PASS="${AUTH#*:}"
    mkdir -p /etc/systemd/system/ships-server.service.d
    cat > /etc/systemd/system/ships-server.service.d/auth.conf <<EOC
[Service]
Environment=SHIPS_AUTH_USER=${AUTH_USER}
Environment=SHIPS_AUTH_PASS=${AUTH_PASS}
EOC
    info "Configured HTTP Basic Auth"
fi

systemctl daemon-reload || true
systemctl enable ships-server.service || true
systemctl restart ships-server.service || true

if [[ $WITH_WAZUH -eq 1 ]]; then
    if [[ -x "$SCRIPT_DIR/deploy_rsyslog_shipsc.sh" ]]; then
        "$SCRIPT_DIR/deploy_rsyslog_shipsc.sh"
    fi
    if [[ -x "$SCRIPT_DIR/deploy_wazuh_local_rules.sh" ]]; then
        "$SCRIPT_DIR/deploy_wazuh_local_rules.sh"
    fi
fi

info "Deployment complete"

cat <<MSG
Next steps:
  1. Add SSH keys to /home/shipscmd/.ssh/authorized_keys
  2. Verify service with: systemctl status ships-server
MSG
