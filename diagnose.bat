@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Diagnosing build issues...
echo.
echo Current directory:
cd
echo.
echo Go module info:
"C:\Program Files\Go\bin\go.exe" mod verify
echo.
echo Dependencies:
"C:\Program Files\Go\bin\go.exe" mod tidy
echo.
echo Building server with error output:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server 2>&1
echo Build result: %errorlevel%
echo.
echo Checking if internal modules exist:
if exist internal\api\api.go (
    echo ✓ internal\api\api.go exists
) else (
    echo ✗ internal\api\api.go missing
)
if exist internal\store\store.go (
    echo ✓ internal\store\store.go exists  
) else (
    echo ✗ internal\store\store.go missing
)
