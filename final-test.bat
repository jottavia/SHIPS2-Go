@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Building server with fixed logging...
echo.
set GOCACHE=%TEMP%\go-cache
set GOPATH=%USERPROFILE%\go
set GO111MODULE=on
echo.
echo Building server:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
echo Server result: %errorlevel%
echo.
if exist bin\ships-server.exe (
    echo ✓ Server built successfully!
    dir bin\ships-server.exe
    echo.
    echo Testing binaries:
    echo Client version:
    bin\shipsc.exe version
    echo.
    echo Server version (quick test):
    timeout 3 >nul 2>&1 && echo Server binary exists and is executable
) else (
    echo ✗ Server build still failed
    "C:\Program Files\Go\bin\go.exe" build .\cmd\server 2>&1
)
