@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Reinitializing Go module...
echo.
echo Removing old module files:
del go.mod go.sum 2>nul
echo.
echo Initializing new module:
"C:\Program Files\Go\bin\go.exe" mod init github.com/jottavia/SHIPS2-Go
echo Init result: %errorlevel%
echo.
echo Getting dependencies:
"C:\Program Files\Go\bin\go.exe" get github.com/gin-gonic/gin@v1.10.1
echo Gin result: %errorlevel%
echo.
"C:\Program Files\Go\bin\go.exe" get modernc.org/sqlite@v1.25.0
echo SQLite result: %errorlevel%
echo.
echo Running mod tidy:
"C:\Program Files\Go\bin\go.exe" mod tidy
echo Tidy result: %errorlevel%
echo.
echo Attempting build:
"C:\Program Files\Go\bin\go.exe" build .\cmd\server
echo Build result: %errorlevel%
