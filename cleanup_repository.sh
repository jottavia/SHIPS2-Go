#!/bin/bash

# SHIPS2-Go Repository Cleanup Script
# This script removes all development artifacts, tracking files, and temporary build files
# that are not necessary for building the project.

echo "Starting repository cleanup..."

# Remove all handoff and status tracking files
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

# Remove build logs and error files
rm -f build-error.log
rm -f build-latest.log
rm -f build.log
rm -f server-error.log

# Remove all batch/shell build and utility scripts
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

# Remove setup scripts
rm -f github-setup.ps1
rm -f github-setup.sh
rm -f make-executable.sh

# Remove temporary and misc files
rm -f apiInstance
rm -f makefile.txt
rm -f quick-push.ps1.DELETE
rm -f quick-push.sh.DELETE

# Remove tracking and memory-bank directories
rm -rf tracking/
rm -rf memory-bank/

echo "Repository cleanup completed!"
echo "Removed:"
echo "- All handoff and tracking documents"
echo "- Build logs and error files" 
echo "- Batch/shell utility scripts"
echo "- Setup scripts"
echo "- Temporary files"
echo "- tracking/ directory"
echo "- memory-bank/ directory"
echo ""
echo "Remaining files are essential for building and running the project."
