@echo off
echo Testing golangci-lint fixes...
echo Date: %date% %time%

echo.
echo ===== Running golangci-lint =====
golangci-lint run --timeout=5m
if %ERRORLEVEL% equ 0 (
    echo golangci-lint: PASSED
) else (
    echo golangci-lint: FAILED with error %ERRORLEVEL%
    echo.
    echo Please fix the issues above before pushing
    pause
    exit /b 1
)

echo.
echo ===== Building Server =====
go build -v ./cmd/server
if %ERRORLEVEL% equ 0 (
    echo Server build: SUCCESS
) else (
    echo Server build: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Building Client =====
go build -v ./cmd/client  
if %ERRORLEVEL% equ 0 (
    echo Client build: SUCCESS
) else (
    echo Client build: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Running Tests =====
go test ./...
if %ERRORLEVEL% equ 0 (
    echo Tests: PASSED
) else (
    echo Tests: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo ===== Running Go Vet =====
go vet ./...
if %ERRORLEVEL% equ 0 (
    echo Go vet: PASSED
) else (
    echo Go vet: FAILED with error %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo All checks passed! Ready to commit and push.
echo Lint test completed at %date% %time%
pause
