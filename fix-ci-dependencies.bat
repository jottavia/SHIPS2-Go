@echo off
echo Fixing SHIPS2-Go Dependencies for Go 1.22...
echo.

REM Clean module cache to ensure fresh dependencies
echo Cleaning module cache...
go clean -modcache

REM Download dependencies
echo Downloading dependencies...
go mod download

REM Verify modules
echo Verifying modules...
go mod verify

REM Tidy modules to ensure consistency
echo Tidying modules...
go mod tidy

REM Test build
echo Testing build...
go build -v ./cmd/server
if errorlevel 1 (
    echo ERROR: Server build failed!
    pause
    exit /b 1
)

go build -v ./cmd/client
if errorlevel 1 (
    echo ERROR: Client build failed!
    pause
    exit /b 1
)

echo.
echo SUCCESS: All dependencies resolved and builds completed!
echo Local environment is ready for CI/CD.
pause
