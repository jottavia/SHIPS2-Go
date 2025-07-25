@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Getting exact error messages...
echo.
echo Building server with full error output:
"C:\Program Files\Go\bin\go.exe" build -v .\cmd\server > build-error.log 2>&1
echo.
echo Error log contents:
type build-error.log
