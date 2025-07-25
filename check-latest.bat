@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
echo Getting build error with fresh dependencies...
echo.
echo Building with error output:
"C:\Program Files\Go\bin\go.exe" build -v .\cmd\server > build-latest.log 2>&1
echo.
echo Error contents:
type build-latest.log
