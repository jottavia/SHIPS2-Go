@echo off
echo Committing and pushing lint fixes...
echo Date: %date% %time%

echo.
echo ===== Git Status =====
git status

echo.
echo ===== Adding Changes =====
git add -A

echo.
echo ===== Committing Changes =====
git commit -m "Fix golangci-lint issues: improve variable naming, line length, and function complexity

- Rename short variable names to be more descriptive (s->storeInstance, c->ctx, a->apiInstance)
- Break long lines to stay within 120 character limit  
- Extract command dispatch logic from main() to reduce cyclomatic complexity
- Improve function parameter formatting for better readability
- Maintain all existing functionality while fixing lint violations

Resolves remaining golangci-lint issues for production deployment."

if %ERRORLEVEL% neq 0 (
    echo Commit failed with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Pushing to GitHub =====
git push origin main

if %ERRORLEVEL% equ 0 (
    echo Successfully pushed lint fixes to GitHub!
    echo.
    echo Monitor CI at: https://github.com/jottavia/SHIPS2-Go/actions
) else (
    echo Push failed with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Lint fixes deployed at %date% %time%
pause
