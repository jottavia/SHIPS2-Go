@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Setting up Go environment properly...
echo.
echo Setting environment variables:
set GOCACHE=%TEMP%\go-cache
set GOPATH=%USERPROFILE%\go
set GO111MODULE=on
echo GOCACHE=%GOCACHE%
echo GOPATH=%GOPATH%
echo.
echo Creating cache directory:
mkdir "%GOCACHE%" 2>nul
echo.
echo Building server:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
echo Server result: %errorlevel%
echo.
echo Building client:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\shipsc.exe .\cmd\client
echo Client result: %errorlevel%
echo.
echo Checking results:
if exist bin\ships-server.exe (
    echo ✓ Server built successfully!
    dir bin\ships-server.exe
) else (
    echo ✗ Server build failed
)
if exist bin\shipsc.exe (
    echo ✓ Client built successfully!
    dir bin\shipsc.exe
) else (
    echo ✗ Client build failed
)
