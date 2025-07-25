@echo off
echo Synchronizing local repository with GitHub...
echo Date: %date% %time%

echo.
echo ===== Fetching Latest from GitHub =====
git fetch origin

echo.
echo ===== Checking Current Status =====
git status

echo.
echo ===== Merging any Remote Changes =====
git pull origin main
if %ERRORLEVEL% neq 0 (
    echo ⚠️ Pull failed - may need conflict resolution
    echo Please resolve any conflicts manually
    pause
    exit /b 1
)

echo.
echo ===== Adding New Tracking Files =====
git add tracking/github_runner_specifications.md
git add check-repo-sync.bat
git add sync-with-github.bat

echo.
echo ===== Committing Sync and Management Updates =====
git commit -m "Add GitHub runner specifications and sync management tools

- Add comprehensive GitHub runner environment specifications
- Document Go 1.22.5 versions across all runner types (ubuntu/windows/macos)
- Create CI/CD compatibility matrix for future reference
- Add repository sync checking and management scripts
- Establish maintenance schedule for runner version monitoring
- Provide reference links for ongoing maintenance

Supports proper CI/CD environment management and version alignment."

if %ERRORLEVEL% neq 0 (
    echo No changes to commit or commit failed
)

echo.
echo ===== Pushing to GitHub =====
git push origin main

if %ERRORLEVEL% equ 0 (
    echo ✅ Repository successfully synchronized with GitHub!
    echo.
    echo Added management files:
    echo - tracking/github_runner_specifications.md
    echo - check-repo-sync.bat
    echo - sync-with-github.bat
    echo.
    echo Repository status: FULLY SYNCED
) else (
    echo ❌ Push failed with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Final Sync Verification =====
git fetch origin
for /f %%i in ('git rev-parse HEAD') do set LOCAL_SHA=%%i
for /f %%i in ('git rev-parse origin/main') do set REMOTE_SHA=%%i

if "%LOCAL_SHA%"=="%REMOTE_SHA%" (
    echo ✅ PERFECT SYNC CONFIRMED
    echo Local and remote repositories are identical
) else (
    echo ⚠️ Sync verification failed
    echo Manual review may be required
)

echo.
echo Synchronization completed at %date% %time%
pause
