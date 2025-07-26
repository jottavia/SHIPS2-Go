# Repository Cleanup Plan

This document outlines all the files and directories that should be removed from the SHIPS2-Go repository to clean up unnecessary development artifacts, tracking files, and temporary build files.

## Files to Remove

### Handoff and Status Tracking Documents
- CI_DISABLED_COMPLETE_2025-07-22.md
- CLAUDE.md
- CRITICAL_VERSION_FIX_HANDOFF_2025-07-21.md
- CURRENT_HANDOFF_2025-07-21.md
- FINAL_SQLITE_FIX_HANDOFF_2025-07-21.md
- FINAL_V2_MIGRATION_COMPLETE_2025-07-21.md
- GITHUB_PUSH_READY_2025-07-21.md
- GOLANGCI_V2_CLEAN_WORKFLOW_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_EXCLUSIONS_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_FINAL_SQLITE_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_LINTERS_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_OUTPUT_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_PANIC_FIX_COMPLETE_2025-07-22.md
- GOLANGCI_V2_PANIC_RESOLUTION_COMPLETE_2025-07-22.md
- SQLite_CGO_FIX_HANDOFF_2025-07-21.md

### Build Logs and Error Files
- build-error.log
- build-latest.log
- build.log
- server-error.log

### Batch/Shell Build and Utility Scripts
- build-final.bat
- build.bat
- build2.bat
- check-latest.bat
- check.bat
- debug.bat
- deploy-ci-fixes.bat
- diagnose-build-issue.bat
- diagnose.bat
- final-build.bat
- final-test.bat
- fix-ci-dependencies.bat
- fix-deps.bat
- fix-sqlite-cgo-issues.bat
- fix-version-compatibility.bat
- fix.bat
- fresh-start.bat
- get-error.bat
- migrate-to-v2-config.bat
- secure-push.sh
- server-debug.bat
- simple-deps.bat
- test-build.bat
- test-final.bat
- test-local-build.bat
- test-simple-fix.bat
- test_readiness.sh
- validate_fixes.sh
- verify-output-format-fix.bat
- verify-project-status.bat

### Setup Scripts
- github-setup.ps1
- github-setup.sh
- make-executable.sh

### Temporary and Miscellaneous Files
- apiInstance (empty file)
- makefile.txt
- quick-push.ps1.DELETE
- quick-push.sh.DELETE

### Directories to Remove
- tracking/ (entire directory with all subdirectories and files)
- memory-bank/ (entire directory with all files)

## Files to Keep (Essential for Building)

### Core Application Files
- cmd/ (directory with application entry points)
- internal/ (directory with internal packages)
- go.mod
- go.sum
- Makefile
- readme.md
- LICENSE

### Configuration Files
- .golangci.yml (Go linting configuration)
- .github/ (CI/CD workflows)

### Build and Deployment
- bin/ (directory for built binaries)
- deploy/ (deployment configurations)
- installer/ (installation scripts)
- scripts/ (essential build scripts)
- docs/ (documentation)
- tests/ (test files)

## Summary

After cleanup, the repository will contain only the essential files needed to:
1. Build the Go application
2. Run tests
3. Deploy the application
4. Understand how to use it (documentation)
5. Contribute to development (CI/CD, linting)

All development tracking, temporary build artifacts, and utility scripts that were created during development iterations will be removed.
