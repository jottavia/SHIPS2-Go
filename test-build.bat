@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Building with corrected module imports...
echo.
echo Cleaning up and refreshing modules:
del go.sum 2>nul
"C:\Program Files\Go\bin\go.exe" mod tidy
echo.
echo Building server:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
echo Server build result: %errorlevel%
echo.
echo Building client:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\shipsc.exe .\cmd\client
echo Client build result: %errorlevel%
echo.
echo Checking results:
if exist bin\ships-server.exe (
    echo ✓ Server built successfully
    bin\ships-server.exe --help 2>nul || echo Server executable exists
) else (
    echo ✗ Server build failed
)
if exist bin\shipsc.exe (
    echo ✓ Client built successfully  
    bin\shipsc.exe version
) else (
    echo ✗ Client build failed
)
