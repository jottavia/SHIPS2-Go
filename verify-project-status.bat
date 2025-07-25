@echo off
echo ============================================
echo SHIPS2-Go Lint and CI Verification Script
echo Date: %date% %time%
echo ============================================

echo.
echo [1/6] Checking Go version compatibility...
go version
echo Project go.mod version:
findstr "go " go.mod

echo.
echo [2/6] Downloading dependencies...
go mod download
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to download dependencies
    goto :error
)

echo.
echo [3/6] Running golangci-lint...
golangci-lint --version
golangci-lint run --timeout=5m --verbose
if %ERRORLEVEL% neq 0 (
    echo ERROR: golangci-lint found issues
    goto :error
)

echo.
echo [4/6] Building server...
go build -v -o bin/ships-server.exe ./cmd/server
if %ERRORLEVEL% neq 0 (
    echo ERROR: Server build failed
    goto :error
)

echo.
echo [5/6] Building client...
go build -v -o bin/shipsc.exe ./cmd/client
if %ERRORLEVEL% neq 0 (
    echo ERROR: Client build failed
    goto :error
)

echo.
echo [6/6] Running tests...
go test ./... -v
if %ERRORLEVEL% neq 0 (
    echo ERROR: Tests failed
    goto :error
)

echo.
echo ============================================
echo ✅ ALL CHECKS PASSED!
echo ============================================
echo - golangci-lint: CLEAN
echo - Server build: SUCCESS
echo - Client build: SUCCESS  
echo - Tests: PASSING
echo.
echo The project is ready for GitHub CI/CD
echo ============================================
goto :end

:error
echo.
echo ============================================
echo ❌ CHECKS FAILED!
echo ============================================
echo Please fix the issues above before pushing to GitHub
echo ============================================
pause
exit /b 1

:end
echo Verification completed at %date% %time%
pause
