@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Building SHIPS2-Go with full paths...
echo.
echo Building server...
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
if errorlevel 1 (
    echo Server build failed!
    exit /b 1
)
echo.
echo Building client...
"C:\Program Files\Go\bin\go.exe" build -v -o bin\shipsc.exe .\cmd\client
if errorlevel 1 (
    echo Client build failed!
    exit /b 1
)
echo.
echo Running tests...
"C:\Program Files\Go\bin\go.exe" test -v .\...
echo.
echo Build complete. Checking binaries:
if exist bin\ships-server.exe (
    echo ✓ ships-server.exe created
    dir bin\ships-server.exe
) else (
    echo ✗ ships-server.exe not found
)
if exist bin\shipsc.exe (
    echo ✓ shipsc.exe created  
    dir bin\shipsc.exe
) else (
    echo ✗ shipsc.exe not found
)
