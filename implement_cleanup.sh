#!/bin/bash

# SHIPS2-Go Repository Cleanup Implementation
# This script removes all unnecessary development artifacts identified in CLEANUP_PLAN.md

set -e  # Exit on error

echo "🧹 Starting SHIPS2-Go Repository Cleanup..."
echo "This will remove 50+ unnecessary development files and directories."
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo "🗑️ Removing handoff and status tracking documents..."

# Remove handoff and status tracking files
rm -f CI_DISABLED_COMPLETE_2025-07-22.md
rm -f CLAUDE.md
rm -f CRITICAL_VERSION_FIX_HANDOFF_2025-07-21.md
rm -f CURRENT_HANDOFF_2025-07-21.md
rm -f FINAL_SQLITE_FIX_HANDOFF_2025-07-21.md
rm -f FINAL_V2_MIGRATION_COMPLETE_2025-07-21.md
rm -f GITHUB_PUSH_READY_2025-07-21.md
rm -f GOLANGCI_V2_CLEAN_WORKFLOW_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_EXCLUSIONS_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_FINAL_SQLITE_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_LINTERS_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_OUTPUT_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_PANIC_FIX_COMPLETE_2025-07-22.md
rm -f GOLANGCI_V2_PANIC_RESOLUTION_COMPLETE_2025-07-22.md
rm -f SQLite_CGO_FIX_HANDOFF_2025-07-21.md

echo "📊 Removing build logs and error files..."

# Remove build logs and error files
rm -f build-error.log
rm -f build-latest.log
rm -f build.log
rm -f server-error.log

echo "🔧 Removing batch/shell build and utility scripts..."

# Remove all batch and shell utility scripts
rm -f build-final.bat
rm -f build.bat
rm -f build2.bat
rm -f check-latest.bat
rm -f check.bat
rm -f debug.bat
rm -f deploy-ci-fixes.bat
rm -f diagnose-build-issue.bat
rm -f diagnose.bat
rm -f final-build.bat
rm -f final-test.bat
rm -f fix-ci-dependencies.bat
rm -f fix-deps.bat
rm -f fix-sqlite-cgo-issues.bat
rm -f fix-version-compatibility.bat
rm -f fix.bat
rm -f fresh-start.bat
rm -f get-error.bat
rm -f migrate-to-v2-config.bat
rm -f secure-push.sh
rm -f server-debug.bat
rm -f simple-deps.bat
rm -f test-build.bat
rm -f test-final.bat
rm -f test-local-build.bat
rm -f test-simple-fix.bat
rm -f test_readiness.sh
rm -f validate_fixes.sh
rm -f verify-output-format-fix.bat
rm -f verify-project-status.bat

echo "⚙️ Removing setup and configuration scripts..."

# Remove setup scripts
rm -f github-setup.ps1
rm -f github-setup.sh
rm -f make-executable.sh

echo "🧹 Removing temporary and miscellaneous files..."

# Remove temporary and misc files
rm -f apiInstance
rm -f makefile.txt
rm -f quick-push.ps1.DELETE
rm -f quick-push.sh.DELETE

echo "📂 Removing tracking and memory-bank directories..."

# Remove directories
rm -rf tracking/
rm -rf memory-bank/

echo ""
echo "✅ Repository cleanup completed successfully!"
echo ""
echo "📈 Summary of changes:"
echo "   - Removed 16+ handoff and status documents"
echo "   - Removed 35+ build scripts and logs"
echo "   - Removed 2 directories (tracking/, memory-bank/)"
echo "   - Removed temporary and setup files"
echo ""
echo "🎯 Your repository now contains only essential files needed to:"
echo "   - Build the Go application (go.mod, Makefile, cmd/, internal/)"
echo "   - Deploy and configure (deploy/, installer/, scripts/)"
echo "   - Document and test (readme.md, docs/, tests/)"
echo "   - Maintain code quality (.golangci.yml, .github/)"
echo ""
echo "🚀 The repository is now clean and ready for production use!"

# Optional: Show remaining files
echo ""
read -p "Show remaining files in repository? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📋 Remaining files and directories:"
    find . -maxdepth 2 -type f -not -path './.git/*' | sort
    echo ""
    echo "📁 Remaining directories:"
    find . -maxdepth 2 -type d -not -path './.git*' -not -path '.' | sort
fi