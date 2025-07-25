@echo off
cd "C:\GPT Programing\SHIPS2-Go-Working"
set PATH=%PATH%;C:\Program Files\Go\bin;C:\Program Files (x86)\GnuWin32\bin
echo Current PATH:
echo %PATH%
echo.
echo Checking if go.exe exists:
where go
echo.
echo Checking Go installation:
"C:\Program Files\Go\bin\go.exe" version
echo.
echo Checking make installation:
"C:\Program Files (x86)\GnuWin32\bin\make.exe" --version
