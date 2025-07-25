#!/bin/bash
# make-executable.sh - Make all scripts executable

set -euo pipefail

echo "🔧 Making SHIPS2-Go scripts executable..."

# Scripts to make executable
scripts=(
    "github-setup.sh"
    "test_readiness.sh"
    "validate_fixes.sh"
    "scripts/build-deb.sh"
    "scripts/build-rpm.sh"
    "bin/shipsc_wrapper.sh"
    "deploy/deploy_ships_server.sh"
    "deploy/deploy_rsyslog_shipsc.sh"
    "deploy/deploy_wazuh_local_rules.sh"
)

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo "✅ Made executable: $script"
    else
        echo "❌ Not found: $script"
    fi
done

echo "🎉 All scripts are now executable!"
