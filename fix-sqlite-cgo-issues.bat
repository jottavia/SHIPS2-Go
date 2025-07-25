@echo off
echo ============================================
echo SHIPS2-Go SQLite CGO Fix Script
echo Date: %date% %time%
echo ============================================

echo.
echo [1/6] Setting up CGO environment...
set CGO_ENABLED=1
echo CGO_ENABLED=%CGO_ENABLED%

echo.
echo [2/6] Downloading dependencies with CGO...
go mod download
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to download dependencies
    goto :error
)

echo.
echo [3/6] Pre-building packages to generate export data...
echo Building server...
go build -v -tags sqlite_omit_load_extension ./cmd/server
if %ERRORLEVEL% neq 0 (
    echo ERROR: Server build failed
    goto :error
)

echo Building client...
go build -v -tags sqlite_omit_load_extension ./cmd/client  
if %ERRORLEVEL% neq 0 (
    echo ERROR: Client build failed
    goto :error
)

echo ✅ Pre-build successful

echo.
echo [4/6] Running golangci-lint with CGO support...
golangci-lint run --timeout=5m --build-tags=sqlite_omit_load_extension
if %ERRORLEVEL% neq 0 (
    echo ERROR: golangci-lint found issues
    goto :error
)

echo ✅ golangci-lint passed

echo.
echo [5/6] Running comprehensive tests...
go test ./... -tags sqlite_omit_load_extension
if %ERRORLEVEL% neq 0 (
    echo ERROR: Tests failed
    goto :error
)

echo ✅ Tests passed

echo.
echo [6/6] Verifying cross-compilation...
set GOOS=linux
set GOARCH=amd64
go build -tags sqlite_omit_load_extension -o ships-server-linux ./cmd/server
if %ERRORLEVEL% neq 0 (
    echo ERROR: Linux build failed
    goto :error
)

echo ✅ Cross-compilation verified

echo.
echo ============================================
echo ✅ ALL CGO/SQLite FIXES VERIFIED!
echo ============================================
echo - CGO environment: CONFIGURED
echo - Export data: GENERATED  
echo - golangci-lint: PASSING
echo - Tests: PASSING
echo - Cross-platform: WORKING
echo.
echo Ready for GitHub deployment
echo ============================================
goto :end

:error
echo.
echo ============================================
echo ❌ CGO/SQLite FIX FAILED!
echo ============================================
echo.
echo Common solutions:
echo 1. Ensure gcc/build tools are installed
echo 2. Verify CGO_ENABLED=1 is set
echo 3. Check modernc.org/sqlite version compatibility
echo 4. Ensure proper build tags are used
echo.
echo ============================================
pause
exit /b 1

:end
echo CGO/SQLite verification completed at %date% %time%
pause
