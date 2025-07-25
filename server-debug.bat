@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Checking server build error...
echo.
set GOCACHE=%TEMP%\go-cache
set GOPATH=%USERPROFILE%\go
set GO111MODULE=on
echo.
echo Building server with detailed output:
"C:\Program Files\Go\bin\go.exe" build -v .\cmd\server > server-error.log 2>&1
echo Build result: %errorlevel%
echo.
echo Error details:
type server-error.log
