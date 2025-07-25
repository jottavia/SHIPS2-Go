@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
set PATH=%PATH%;C:\Program Files\Go\bin;C:\Program Files (x86)\GnuWin32\bin
echo Building SHIPS2-Go...
echo.
echo Go version:
go version
echo.
echo Building server...
go build -v -o bin\ships-server.exe .\cmd\server
echo.
echo Building client...
go build -v -o bin\shipsc.exe .\cmd\client
echo.
echo Running tests...
go test -v .\...
echo.
echo Build complete. Checking binaries:
dir bin\*.exe
