@echo off
echo Cleaning up temporary development files...
echo Date: %date% %time%

echo.
echo ===== Removing Build Logs =====
del /q build-error.log 2>nul
del /q build-latest.log 2>nul  
del /q build.log 2>nul
del /q server-error.log 2>nul

echo.
echo ===== Removing Old Development Scripts =====
del /q build-final.bat 2>nul
del /q build.bat 2>nul
del /q build2.bat 2>nul
del /q check-latest.bat 2>nul
del /q check.bat 2>nul
del /q debug.bat 2>nul
del /q diagnose.bat 2>nul
del /q final-build.bat 2>nul
del /q final-test.bat 2>nul
del /q fix-ci-dependencies.bat 2>nul
del /q fix-deps.bat 2>nul
del /q fix.bat 2>nul
del /q fresh-start.bat 2>nul
del /q get-error.bat 2>nul
del /q server-debug.bat 2>nul
del /q simple-deps.bat 2>nul
del /q test-build.bat 2>nul
del /q test-final.bat 2>nul

echo.
echo ===== Removing Obsolete Files =====
del /q makefile.txt 2>nul
del /q CLAUDE.md 2>nul
del /q quick-push.ps1.DELETE 2>nul
del /q quick-push.sh.DELETE 2>nul

echo.
echo ===== Removing Accidentally Created Files =====
del /q apiInstance 2>nul

echo.
echo ===== Current Root Directory Status =====
dir /b | findstr /v /i "^\.github$ ^bin$ ^cmd$ ^deploy$ ^docs$ ^installer$ ^internal$ ^scripts$ ^tests$ ^tracking$ ^\.golangci\.yml$ ^go\.mod$ ^go\.sum$ ^LICENSE$ ^Makefile$ ^readme\.md$"

echo.
echo Cleanup completed at %date% %time%
echo Root directory is now organized and clean!
pause
