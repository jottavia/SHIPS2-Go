@echo off
echo ============================================
echo SHIPS2-Go CI/CD Fix and Push Script
echo Date: %date% %time%
echo ============================================

echo.
echo [1/5] Verifying local build status...
echo Running local verification first...

go version
echo.

echo Checking Go module status...
go mod download
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to download dependencies
    goto :error
)

echo.
echo Testing build...
go build -v ./cmd/server > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Server build failed
    goto :error
)

go build -v ./cmd/client > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Client build failed
    goto :error
)

echo ✅ Local builds successful

echo.
echo [2/5] Running golangci-lint...
golangci-lint run --timeout=5m
if %ERRORLEVEL% neq 0 (
    echo ERROR: golangci-lint found issues that need to be fixed
    echo Please run 'golangci-lint run' to see specific issues
    goto :error
)

echo ✅ golangci-lint passed

echo.
echo [3/5] Committing CI/CD version fixes...
git add .github/workflows/ci.yml
git add .github/workflows/golangci-lint.yml
git add tracking/current_session/
git add verify-project-status.bat
git status

echo.
echo Committing changes...
git commit -m "fix: standardize golangci-lint version to v1.59.1 for Go 1.22 compatibility

- Updated .github/workflows/ci.yml: version latest → v1.59.1
- Updated .github/workflows/golangci-lint.yml: version latest → v1.59.1
- Ensures consistent, stable CI/CD behavior
- Prevents version drift issues with latest golangci-lint releases
- Maintains compatibility with GitHub runners using Go 1.22.5

Related: CI/CD stability improvements"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Git commit failed
    goto :error
)

echo ✅ Changes committed

echo.
echo [4/5] Pushing to GitHub...
echo Pushing to origin main...
git push origin main

if %ERRORLEVEL% neq 0 (
    echo ERROR: Git push failed
    echo Please check your GitHub authentication and connection
    goto :error
)

echo ✅ Successfully pushed to GitHub

echo.
echo [5/5] Monitoring instructions...
echo.
echo ============================================
echo ✅ CI/CD FIXES APPLIED AND PUSHED!
echo ============================================
echo.
echo Next steps:
echo 1. Monitor GitHub Actions at:
echo    https://github.com/jottavia/SHIPS2-Go/actions
echo.
echo 2. Expected results (within 5-10 minutes):
echo    ✅ All workflow jobs should show green status
echo    ✅ golangci-lint: PASS (using v1.59.1)
echo    ✅ Build jobs: PASS (all platforms)
echo    ✅ Test jobs: PASS (all functionality)
echo.
echo 3. If any jobs fail:
echo    - Check the Actions tab for specific error details
echo    - Run this script again to re-apply fixes
echo    - Contact support if issues persist
echo.
echo ============================================
echo PROJECT STATUS: UPDATED AND MONITORING
echo ============================================
goto :end

:error
echo.
echo ============================================
echo ❌ ERROR OCCURRED!
echo ============================================
echo.
echo The script encountered an error. Please:
echo 1. Review the error message above
echo 2. Fix any issues identified
echo 3. Run this script again
echo.
echo Common issues:
echo - golangci-lint not installed or not in PATH
echo - Git authentication problems
echo - Network connectivity issues
echo - Local build failures
echo.
echo ============================================
pause
exit /b 1

:end
echo.
echo Deployment completed at %date% %time%
echo ============================================
pause
