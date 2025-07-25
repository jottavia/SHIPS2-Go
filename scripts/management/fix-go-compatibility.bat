@echo off
echo Fixing Go version compatibility for GitHub runners...
echo Date: %date% %time%

echo.
echo ===== Cleaning Go modules =====
go clean -modcache

echo.
echo ===== Updating dependencies for Go 1.22 =====
go mod tidy

echo.
echo ===== Verifying dependencies =====
go mod verify

echo.
echo ===== Testing build with Go 1.22 =====
go build -v ./cmd/server
if %ERRORLEVEL% equ 0 (
    echo Server build: SUCCESS
) else (
    echo Server build: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

go build -v ./cmd/client  
if %ERRORLEVEL% equ 0 (
    echo Client build: SUCCESS
) else (
    echo Client build: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Running tests =====
go test ./...
if %ERRORLEVEL% equ 0 (
    echo Tests: PASSED
) else (
    echo Tests: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Go 1.22 compatibility verified! Ready for GitHub CI.
echo Compatibility test completed at %date% %time%
pause
