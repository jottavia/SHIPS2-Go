@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Running the exact commands suggested by Go...
echo.
echo Getting server package:
"C:\Program Files\Go\bin\go.exe" get github.com/jottavia/SHIPS2-Go/cmd/server
echo Result: %errorlevel%
echo.
echo Getting store package:
"C:\Program Files\Go\bin\go.exe" get github.com/jottavia/SHIPS2-Go/internal/store
echo Result: %errorlevel%
echo.
echo Running mod tidy:
"C:\Program Files\Go\bin\go.exe" mod tidy
echo Result: %errorlevel%
echo.
echo Attempting build again:
"C:\Program Files\Go\bin\go.exe" build .\cmd\server
echo Build result: %errorlevel%
