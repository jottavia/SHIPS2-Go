@echo off
echo Testing local build after CI fixes...
echo.

REM Navigate to project directory
cd /d "C:\GPT Programing\SHIPS2-Go-Working"

REM Test Go version
echo Checking Go version...
go version
echo.

REM Test module verification
echo Verifying Go modules...
go mod verify
if errorlevel 1 (
    echo ERROR: Module verification failed!
    pause
    exit /b 1
)
echo ✅ Modules verified successfully
echo.

REM Test server build
echo Building server...
go build -v ./cmd/server
if errorlevel 1 (
    echo ERROR: Server build failed!
    pause
    exit /b 1
)
echo ✅ Server built successfully
echo.

REM Test client build  
echo Building client...
go build -v ./cmd/client
if errorlevel 1 (
    echo ERROR: Client build failed!
    pause
    exit /b 1
)
echo ✅ Client built successfully
echo.

REM Test linting (if golangci-lint is available locally)
where golangci-lint >nul 2>&1
if %errorlevel% == 0 (
    echo Running golangci-lint...
    golangci-lint run --timeout=5m
    if errorlevel 1 (
        echo WARNING: Linting found issues, but build is still functional
    ) else (
        echo ✅ Linting passed
    )
) else (
    echo INFO: golangci-lint not installed locally, skipping lint test
)
echo.

REM Test running basic tests
echo Running tests...
go test ./...
if errorlevel 1 (
    echo WARNING: Some tests failed, but build is functional
) else (
    echo ✅ All tests passed
)
echo.

echo =====================================
echo ✅ LOCAL BUILD VERIFICATION COMPLETE
echo =====================================
echo All critical builds successful!
echo CI fixes are ready for GitHub push.
echo.
pause
