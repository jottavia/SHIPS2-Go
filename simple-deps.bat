@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Trying without specific versions...
echo.
echo Removing old module files:
del go.mod go.sum 2>nul
echo.
echo Initializing new module:
"C:\Program Files\Go\bin\go.exe" mod init github.com/jottavia/SHIPS2-Go
echo.
echo Getting latest dependencies without versions:
"C:\Program Files\Go\bin\go.exe" get github.com/gin-gonic/gin
echo Gin result: %errorlevel%
echo.
"C:\Program Files\Go\bin\go.exe" get modernc.org/sqlite
echo SQLite result: %errorlevel%
echo.
echo Checking what we got:
"C:\Program Files\Go\bin\go.exe" list -m all
echo.
echo Attempting build without tidy:
"C:\Program Files\Go\bin\go.exe" build .\cmd\server
echo Build result: %errorlevel%
