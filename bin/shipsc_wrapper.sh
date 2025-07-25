#!/usr/bin/env bash
# shipsc_wrapper.sh – forced‑command wrapper for restricted SSH operators
#
# This script is set as the ForceCommand in the authorized_keys file of the
# dedicated SSH user (e.g. 'shipscmd'). It allows the operator to execute only
# three safe verbs of the shipsc CLI:
#   • fetch   – retrieve the current Administrator password for a host
#   • rotate  – rotate the Administrator password for a host (optional NEWPW)
#   • bde     – retrieve the BitLocker recovery key for a host
#
# All actions are logged via syslog so that rsyslog ➜ Wazuh rule 91000 can
# generate alerts. Any attempt to use an unsupported verb is denied and logged.
#
# Example ForceCommand line in /home/shipscmd/.ssh/authorized_keys:
#   command="/opt/ships/bin/shipsc_wrapper.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAA…
#
# Place this file at /opt/ships/bin/shipsc_wrapper.sh and chmod +x it.

set -euo pipefail

readonly LOGGER_TAG="shipsc-wrapper"
readonly SHIPSC_BIN="/opt/ships/bin/shipsc"  # adjust if you install elsewhere
readonly VERSION="1.0.0"

# --- logging functions -------------------------------------------------
log() {
    logger -t "${LOGGER_TAG}" -- "$*"
}

log_json() {
    local action="$1"
    local verb="${2:-unknown}"
    local hostname="${3:-unknown}"
    local user="${USER:-unknown}"
    local remote_addr="${SSH_CLIENT%% *}"  # Extract IP from SSH_CLIENT
    
    # Create JSON log entry for structured logging
    local json_log
    json_log=$(cat <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)","action":"$action","verb":"$verb","hostname":"$hostname","user":"$user","remote_addr":"$remote_addr","ssh_original_command":"${SSH_ORIGINAL_COMMAND:-}"}
EOF
)
    logger -t "${LOGGER_TAG}" -- "$json_log"
}

denied() {
    local reason="${1:-unauthorized command}"
    log_json "DENIED" "unknown" "unknown"
    log "DENIED: $USER from ${SSH_CLIENT%% *} attempted: ${SSH_ORIGINAL_COMMAND:-interactive}"
    echo "Error: $reason" >&2
    exit 1
}

# --- input validation --------------------------------------------------
validate_hostname() {
    local hostname="$1"
    
    # Basic hostname validation
    if [[ -z "$hostname" ]]; then
        denied "hostname cannot be empty"
    fi
    
    if [[ ${#hostname} -gt 253 ]]; then
        denied "hostname too long"
    fi
    
    # Check for dangerous characters
    if [[ "$hostname" =~ [[:space:]\;\|\&\$\`\\] ]]; then
        denied "hostname contains invalid characters"
    fi
    
    # Must contain only valid hostname characters
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        denied "hostname format invalid"
    fi
}

validate_password() {
    local password="$1"
    
    if [[ -z "$password" ]]; then
        denied "password cannot be empty"
    fi
    
    if [[ ${#password} -lt 8 ]]; then
        denied "password too short (minimum 8 characters)"
    fi
    
    if [[ ${#password} -gt 128 ]]; then
        denied "password too long (maximum 128 characters)"
    fi
}

# --- main logic --------------------------------------------------------

# If invoked interactively (no SSH_ORIGINAL_COMMAND), show basic help.
if [[ -z "${SSH_ORIGINAL_COMMAND:-}" ]]; then
    cat <<EOF
SHIPS2-Go Restricted Operator Shell v${VERSION}

Allowed commands:
  fetch   HOSTNAME                    - Retrieve administrator password
  rotate  HOSTNAME [NEWPASSWORD]     - Rotate administrator password
  bde     HOSTNAME                    - Retrieve BitLocker recovery key

Examples:
  fetch WINBOX01
  rotate WINBOX01 NewSecurePass123!
  bde WINBOX01

Environment:
  User: ${USER:-unknown}
  SSH Client: ${SSH_CLIENT:-unknown}
EOF
    exit 0
fi

# Parse command safely using array
IFS=' ' read -ra cmd_array <<< "$SSH_ORIGINAL_COMMAND"
verb="${cmd_array[0]:-}"
hostname="${cmd_array[1]:-}"

# Validate and execute based on verb
case "$verb" in
    fetch)
        if [[ ${#cmd_array[@]} -ne 2 ]]; then
            denied "fetch requires exactly one argument: HOSTNAME"
        fi
        validate_hostname "$hostname"
        log_json "ALLOW" "$verb" "$hostname"
        log "ALLOW: $USER from ${SSH_CLIENT%% *} executed: fetch $hostname"
        exec "${SHIPSC_BIN}" fetch "$hostname"
        ;;
        
    bde)
        if [[ ${#cmd_array[@]} -ne 2 ]]; then
            denied "bde requires exactly one argument: HOSTNAME"
        fi
        validate_hostname "$hostname"
        log_json "ALLOW" "$verb" "$hostname"
        log "ALLOW: $USER from ${SSH_CLIENT%% *} executed: bde $hostname"
        exec "${SHIPSC_BIN}" bde "$hostname"
        ;;
        
    rotate)
        if [[ ${#cmd_array[@]} -lt 2 || ${#cmd_array[@]} -gt 3 ]]; then
            denied "rotate requires 1-2 arguments: HOSTNAME [PASSWORD]"
        fi
        validate_hostname "$hostname"
        
        if [[ ${#cmd_array[@]} -eq 3 ]]; then
            # Password provided - validate it
            password="${cmd_array[2]}"
            validate_password "$password"
            log_json "ALLOW" "$verb" "$hostname"
            log "ALLOW: $USER from ${SSH_CLIENT%% *} executed: rotate $hostname [password provided]"
            exec "${SHIPSC_BIN}" rotate "$hostname" "$password" -actor "ssh:$USER"
        else
            # No password provided - shipsc will generate one
            log_json "ALLOW" "$verb" "$hostname"
            log "ALLOW: $USER from ${SSH_CLIENT%% *} executed: rotate $hostname [auto-generate]"
            exec "${SHIPSC_BIN}" rotate "$hostname" -actor "ssh:$USER"
        fi
        ;;
        
    help|--help|-h)
        cat <<EOF
SHIPS2-Go SSH Wrapper Help

Allowed commands:
  fetch HOSTNAME                 - Get current admin password
  rotate HOSTNAME [PASSWORD]     - Rotate admin password (auto-gen if not provided)
  bde HOSTNAME                   - Get BitLocker recovery key

Security: All commands are logged and audited.
EOF
        exit 0
        ;;
        
    "")
        denied "empty command"
        ;;
        
    *)
        denied "command not allowed: $verb"
        ;;
esac
