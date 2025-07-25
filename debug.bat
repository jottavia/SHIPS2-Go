@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Detailed error checking...
echo.
echo Building with verbose output:
"C:\Program Files\Go\bin\go.exe" build -v .\cmd\server > build.log 2>&1
echo Build result: %errorlevel%
echo.
echo Build log contents:
type build.log
