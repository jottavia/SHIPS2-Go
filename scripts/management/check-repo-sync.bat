@echo off
echo Checking repository sync status...
echo Date: %date% %time%

echo.
echo ===== Current Branch Status =====
git branch -v

echo.
echo ===== Remote Status =====
git remote -v

echo.
echo ===== Fetch Latest from GitHub =====
git fetch origin

echo.
echo ===== Check for Differences =====
git status

echo.
echo ===== Compare with Remote =====
git log --oneline origin/main..HEAD
if %ERRORLEVEL% equ 0 (
    echo No local commits ahead of remote
) else (
    echo Local commits found ahead of remote
)

echo.
echo ===== Compare Remote with Local =====
git log --oneline HEAD..origin/main
if %ERRORLEVEL% equ 0 (
    echo No remote commits ahead of local
) else (
    echo Remote commits found ahead of local - need to pull
)

echo.
echo ===== Repository Sync Analysis =====
echo Analyzing sync status...

for /f %%i in ('git rev-parse HEAD') do set LOCAL_SHA=%%i
for /f %%i in ('git rev-parse origin/main') do set REMOTE_SHA=%%i

echo Local HEAD:  %LOCAL_SHA%
echo Remote HEAD: %REMOTE_SHA%

if "%LOCAL_SHA%"=="%REMOTE_SHA%" (
    echo ✅ Repository is PERFECTLY SYNCED
) else (
    echo ⚠️  Repository sync required
    echo.
    echo Recommendations:
    echo 1. If behind: git pull origin main
    echo 2. If ahead: git push origin main  
    echo 3. If diverged: resolve conflicts
)

echo.
echo Sync check completed at %date% %time%
pause
