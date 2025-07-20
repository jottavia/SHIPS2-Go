#!/usr/bin/env bash
# filename: shipsc_wrapper.sh
# SHIPS2-Go SSH ForceCommand wrapper for secure client execution

set -euo pipefail

# Configuration
CLIENT_PATH="/opt/ships/bin/shipsc"
LOG_TAG="shipsc-wrapper"

# Logging function
log_event() {
    local action="$1"
    local details="$2"
    local timestamp=$(date -Iseconds)
    
    # JSON structured logging for Wazuh
    printf '{"timestamp":"%s","action":"%s","details":"%s","user":"%s","ssh_client":"%s"}\n' \
        "$timestamp" "$action" "$details" "${USER:-unknown}" "${SSH_CLIENT:-local}" | \
        logger -t "$LOG_TAG"
}

# Validate client exists
if [[ ! -x "$CLIENT_PATH" ]]; then
    log_event "ERROR" "Client binary not found: $CLIENT_PATH"
    echo "Error: SHIPS2-Go client not available" >&2
    exit 1
fi

# Get original SSH command
SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND:-}"

if [[ -z "$SSH_ORIGINAL_COMMAND" ]]; then
    log_event "DENIED" "Interactive session attempted"
    echo "Error: Interactive sessions not allowed" >&2
    exit 1
fi

# Parse and validate command
read -ra ARGS <<< "$SSH_ORIGINAL_COMMAND"

if [[ ${#ARGS[@]} -lt 2 ]]; then
    log_event "DENIED" "Invalid command format: $SSH_ORIGINAL_COMMAND"
    echo "Usage: fetch|rotate|bde HOSTNAME" >&2
    exit 1
fi

VERB="${ARGS[0]}"
HOSTNAME="${ARGS[1]}"

# Validate verb
case "$VERB" in
    fetch|rotate|bde)
        ;;
    *)
        log_event "DENIED" "Invalid verb: $VERB"
        echo "Error: Invalid operation '$VERB'. Use: fetch, rotate, or bde" >&2
        exit 1
        ;;
esac

# Validate hostname
if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
    log_event "DENIED" "Invalid hostname: $HOSTNAME"
    echo "Error: Invalid hostname format" >&2
    exit 1
fi

# Log allowed action
log_event "ALLOW" "$VERB $HOSTNAME"

# Execute client with validated arguments
exec "$CLIENT_PATH" "$VERB" "$HOSTNAME"
