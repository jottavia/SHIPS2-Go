@echo off
echo Testing current build status...
echo Date: %date% %time%

echo.
echo ===== Go Version =====
go version

echo.
echo ===== Module Verification =====
go mod verify

echo.
echo ===== Building Server =====
go build -v ./cmd/server
if %ERRORLEVEL% equ 0 (
    echo Server build: SUCCESS
) else (
    echo Server build: FAILED with error %ERRORLEVEL%
)

echo.
echo ===== Building Client =====
go build -v ./cmd/client  
if %ERRORLEVEL% equ 0 (
    echo Client build: SUCCESS
) else (
    echo Client build: FAILED with error %ERRORLEVEL%
)

echo.
echo ===== Running Tests =====
go test ./...
if %ERRORLEVEL% equ 0 (
    echo Tests: PASSED
) else (
    echo Tests: FAILED with error %ERRORLEVEL%
)

echo.
echo ===== Running Go Vet =====
go vet ./...
if %ERRORLEVEL% equ 0 (
    echo Go vet: PASSED
) else (
    echo Go vet: FAILED with error %ERRORLEVEL%
)

echo.
echo Build test completed at %date% %time%
pause
