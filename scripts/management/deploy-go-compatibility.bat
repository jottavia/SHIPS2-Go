@echo off
echo Deploying Go 1.22 compatibility fixes...
echo Date: %date% %time%

echo.
echo ===== Git Status =====
git status

echo.
echo ===== Adding Changes =====
git add -A

echo.
echo ===== Committing Changes =====
git commit -m "Fix CI compatibility: downgrade to Go 1.22 to match GitHub runners

- Change go.mod from Go 1.23 to Go 1.22 (matches GitHub runner version 1.22.5)
- Update all workflow files to use Go 1.22 consistently  
- Downgrade golangci-lint to v1.59.1 (compatible with Go 1.22)
- Maintain all lint fixes from previous session
- Ensure compatibility across all GitHub-hosted runners (ubuntu/windows/macos)

Resolves CI failures caused by Go version mismatch between local (1.23) and GitHub runners (1.22.5).
All lint improvements are preserved while ensuring CI compatibility."

if %ERRORLEVEL% neq 0 (
    echo Commit failed with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Pushing to GitHub =====
git push origin main

if %ERRORLEVEL% equ 0 (
    echo Successfully pushed Go 1.22 compatibility fixes to GitHub!
    echo.
    echo Monitor CI at: https://github.com/jottavia/SHIPS2-Go/actions
    echo.
    echo Expected results:
    echo - Ubuntu runners: GO 1.22.5 ^(matches^)
    echo - Windows runners: GO 1.22.5 ^(matches^)  
    echo - macOS runners: GO 1.22.5 ^(matches^)
    echo - golangci-lint: v1.59.1 ^(compatible^)
) else (
    echo Push failed with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Compatibility fixes deployed at %date% %time%
pause
