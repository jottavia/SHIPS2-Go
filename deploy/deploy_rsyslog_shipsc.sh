#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy_rsyslog_shipsc.sh – Install rsyslog drop‑in to forward SHIPS2-Go wrapper
# logs to Wazuh (rule 91000) and reload rsyslog safely.
# ---------------------------------------------------------------------------
#
# Usage (as root):
#   ./deploy_rsyslog_shipsc.sh
#
# What it does:
#   1. Creates /etc/rsyslog.d/30-shipsc.conf with a program‑name filter
#      matching the tag "shipsc-wrapper" emitted by bin/shipsc_wrapper.sh.
#   2. Writes the log line to /var/ossec/logs/shipsc.log where the
#      Wazuh local_rules.xml entry 91000 picks it up.
#   3. Validates the rsyslog configuration and reloads the daemon.
#   4. Prints status so you can confirm everything is wired.
# ---------------------------------------------------------------------------

set -euo pipefail

CONF_PATH="/etc/rsyslog.d/30-shipsc.conf"
LOG_PATH="/var/ossec/logs/shipsc.log"

# --- helpers -----------------------------------------------------------
info() { printf "\e[32m[INFO]\e[0m %s\n" "$*"; }
warn() { printf "\e[33m[WARN]\e[0m %s\n" "$*"; }
err()  { printf "\e[31m[ERROR]\e[0m %s\n" "$*" >&2; exit 1; }

# --- ensure root -------------------------------------------------------
[[ $EUID -eq 0 ]] || err "Run as root or with sudo"

# --- check prerequisites -----------------------------------------------
if ! command -v rsyslogd >/dev/null; then
    err "rsyslog not found. Install with: apt install rsyslog"
fi

if ! systemctl is-active --quiet rsyslog; then
    warn "rsyslog service is not running, starting it..."
    systemctl start rsyslog
fi

# --- create rsyslog configuration --------------------------------------
info "Creating rsyslog configuration..."
cat >"${CONF_PATH}" <<'EOF'
# SHIPS2-Go integration – forward privileged wrapper audit lines to Wazuh
# Match logs from shipsc_wrapper.sh (tagged as "shipsc-wrapper")
if ($programname == "shipsc-wrapper") then {
    action(type="omfile" file="/var/ossec/logs/shipsc.log")
    stop
}
EOF

chmod 644 "${CONF_PATH}"
info "Installed ${CONF_PATH}"

# --- prepare log file ---------------------------------------------------
info "Preparing log file..."
if [[ ! -e "${LOG_PATH}" ]]; then
    touch "${LOG_PATH}"
fi

# Check if ossec user exists, otherwise use syslog
if id -u ossec >/dev/null 2>&1; then
    chown ossec:ossec "${LOG_PATH}"
    chmod 640 "${LOG_PATH}"
    info "Set ownership to ossec:ossec for ${LOG_PATH}"
elif id -u syslog >/dev/null 2>&1; then
    chown syslog:syslog "${LOG_PATH}"
    chmod 640 "${LOG_PATH}"
    info "Set ownership to syslog:syslog for ${LOG_PATH}"
else
    warn "Neither ossec nor syslog user found, using root ownership"
    chown root:root "${LOG_PATH}"
    chmod 644 "${LOG_PATH}"
fi

# --- validate and reload rsyslog ---------------------------------------
info "Validating rsyslog configuration..."
if ! rsyslogd -N1; then
    err "rsyslog configuration test failed – check syntax"
fi

info "Reloading rsyslog..."
systemctl reload rsyslog

# Wait a moment for reload
sleep 1

if systemctl is-active --quiet rsyslog; then
    info "rsyslog reloaded successfully"
else
    err "rsyslog failed to reload properly"
fi

# --- test the configuration --------------------------------------------
info "Testing configuration..."
logger -t shipsc-wrapper "TEST: SHIPS2-Go rsyslog integration deployed"

# Wait for log to be written
sleep 1

if [[ -f "${LOG_PATH}" ]] && grep -q "TEST: SHIPS2-Go rsyslog integration deployed" "${LOG_PATH}"; then
    info "✅ Test log entry found in ${LOG_PATH}"
else
    warn "⚠️  Test log entry not found - check rsyslog configuration"
fi

# --- final instructions ------------------------------------------------
cat <<MSG

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHIPS2-Go rsyslog integration configured successfully!

Configuration file: ${CONF_PATH}
Log destination:     ${LOG_PATH}

SHIPS2-Go wrapper audit lines will now be forwarded to Wazuh for processing
by local rule ID 91000. 

To test manually:
  logger -t shipsc-wrapper "test-event host=WINBOX01 verb=fetch actor=admin"

Then check ${LOG_PATH} and /var/ossec/logs/alerts/alerts.json for events.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG