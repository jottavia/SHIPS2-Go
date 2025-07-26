@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Downloading missing dependencies...
echo.
echo Getting server dependencies:
"C:\Program Files\Go\bin\go.exe" get github.com/jottavia/SHIPS2-Go/cmd/server
echo.
echo Getting store dependencies:
"C:\Program Files\Go\bin\go.exe" get github.com/jottavia/SHIPS2-Go/internal/store
echo.
echo Running go mod tidy:
"C:\Program Files\Go\bin\go.exe" mod tidy
echo.
echo Attempting build:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
echo Server build result: %errorlevel%
echo.
"C:\Program Files\Go\bin\go.exe" build -v -o bin\shipsc.exe .\cmd\client  
echo Client build result: %errorlevel%
echo.
echo Checking results:
if exist bin\ships-server.exe echo ✓ Server built successfully
if exist bin\shipsc.exe echo ✓ Client built successfully
