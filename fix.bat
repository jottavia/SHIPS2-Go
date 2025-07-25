@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Fixing go.sum checksum issues...
echo.
echo Removing go.sum and regenerating:
del go.sum
"C:\Program Files\Go\bin\go.exe" mod tidy
echo.
echo Attempting build again:
"C:\Program Files\Go\bin\go.exe" build -v -o bin\ships-server.exe .\cmd\server
echo Build result: %errorlevel%
