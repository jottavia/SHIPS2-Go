#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy_wazuh_local_rules.sh – Install Wazuh local rules for SHIPS2-Go
# ---------------------------------------------------------------------------
# Adds rule 91000 to detect SHIPS2-Go password/key access events
# ---------------------------------------------------------------------------

set -euo pipefail

WAZUH_RULES_DIR="/var/ossec/etc/rules"
LOCAL_RULES_FILE="${WAZUH_RULES_DIR}/local_rules.xml"
BACKUP_FILE="${LOCAL_RULES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# --- helpers -----------------------------------------------------------
info() { printf "\e[32m[INFO]\e[0m %s\n" "$*"; }
warn() { printf "\e[33m[WARN]\e[0m %s\n" "$*"; }
err()  { printf "\e[31m[ERROR]\e[0m %s\n" "$*" >&2; exit 1; }

# --- ensure root -------------------------------------------------------
[[ $EUID -eq 0 ]] || err "Run as root or with sudo"

# --- check prerequisites -----------------------------------------------
if [[ ! -d "$WAZUH_RULES_DIR" ]]; then
    err "Wazuh rules directory not found: $WAZUH_RULES_DIR"
fi

if ! command -v /var/ossec/bin/ossec-control >/dev/null; then
    err "Wazuh not found. Ensure Wazuh agent/manager is installed."
fi

# --- backup existing rules ---------------------------------------------
if [[ -f "$LOCAL_RULES_FILE" ]]; then
    info "Backing up existing local rules to $BACKUP_FILE"
    cp "$LOCAL_RULES_FILE" "$BACKUP_FILE"
fi

# --- create/update local rules -----------------------------------------
info "Creating SHIPS2-Go Wazuh rules..."

# Check if our rule already exists
if [[ -f "$LOCAL_RULES_FILE" ]] && grep -q "SHIPS2-Go" "$LOCAL_RULES_FILE"; then
    warn "SHIPS2-Go rules already exist in $LOCAL_RULES_FILE"
    warn "Manual review recommended - not modifying existing rules"
    exit 0
fi

# Create the local rules file with our SHIPS2-Go rules
cat > "$LOCAL_RULES_FILE" <<'EOF'
<!-- SHIPS2-Go Local Rules -->
<group name="ships2go,">

  <!-- Rule 91000: SHIPS2-Go password/key access events -->
  <rule id="91000" level="3">
    <decoded_as>json</decoded_as>
    <program_name>shipsc-wrapper</program_name>
    <description>SHIPS2-Go: Password or BitLocker key access</description>
  </rule>

  <!-- Rule 91001: SHIPS2-Go denied access attempts -->
  <rule id="91001" level="8">
    <if_sid>91000</if_sid>
    <field name="action">DENIED</field>
    <description>SHIPS2-Go: Access denied - unauthorized command</description>
  </rule>

  <!-- Rule 91002: SHIPS2-Go password fetch -->
  <rule id="91002" level="5">
    <if_sid>91000</if_sid>
    <field name="verb">fetch</field>
    <description>SHIPS2-Go: Administrator password retrieved for $(hostname)</description>
  </rule>

  <!-- Rule 91003: SHIPS2-Go BitLocker key fetch -->
  <rule id="91003" level="5">
    <if_sid>91000</if_sid>
    <field name="verb">bde</field>
    <description>SHIPS2-Go: BitLocker key retrieved for $(hostname)</description>
  </rule>

  <!-- Rule 91004: SHIPS2-Go password rotation -->
  <rule id="91004" level="3">
    <if_sid>91000</if_sid>
    <field name="verb">rotate</field>
    <description>SHIPS2-Go: Password rotated for $(hostname)</description>
  </rule>

  <!-- Rule 91005: Multiple access attempts (rate limiting) -->
  <rule id="91005" level="10" frequency="5" timeframe="300">
    <if_matched_sid>91002</if_matched_sid>
    <same_source_ip />
    <description>SHIPS2-Go: Multiple password fetch attempts from same IP</description>
  </rule>

</group>
EOF

chown root:ossec "$LOCAL_RULES_FILE"
chmod 640 "$LOCAL_RULES_FILE"

info "SHIPS2-Go rules added to $LOCAL_RULES_FILE"

# --- test rule syntax --------------------------------------------------
info "Testing Wazuh rule syntax..."
if /var/ossec/bin/ossec-logtest -f "$LOCAL_RULES_FILE" >/dev/null 2>&1; then
    info "✅ Rule syntax validation passed"
else
    warn "⚠️  Rule syntax validation failed - check configuration"
fi

# --- restart wazuh -----------------------------------------------------
info "Restarting Wazuh to load new rules..."
if systemctl is-active --quiet wazuh-manager; then
    systemctl restart wazuh-manager
    sleep 3
    if systemctl is-active --quiet wazuh-manager; then
        info "✅ Wazuh manager restarted successfully"
    else
        err "❌ Wazuh manager failed to restart"
    fi
elif systemctl is-active --quiet wazuh-agent; then
    systemctl restart wazuh-agent
    sleep 3
    if systemctl is-active --quiet wazuh-agent; then
        info "✅ Wazuh agent restarted successfully"
    else
        err "❌ Wazuh agent failed to restart"
    fi
else
    warn "⚠️  No active Wazuh service found to restart"
fi

# --- final instructions ------------------------------------------------
cat <<MSG

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHIPS2-Go Wazuh rules deployed successfully!

Rules added:
  91000 - Base SHIPS2-Go events
  91001 - Access denied (level 8)
  91002 - Password fetch (level 5)
  91003 - BitLocker key fetch (level 5)
  91004 - Password rotation (level 3)
  91005 - Rate limiting alert (level 10)

Configuration file: $LOCAL_RULES_FILE
Backup saved as:    $BACKUP_FILE

To test the rules, generate a test event:
  logger -t shipsc-wrapper 'ALLOW: testuser executed: fetch TESTHOST'

Then check alerts in: /var/ossec/logs/alerts/alerts.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG