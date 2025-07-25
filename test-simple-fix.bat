@echo off
echo ============================================
echo SHIPS2-Go Simple Fix Test
echo Date: %date% %time%
echo ============================================

echo.
echo [1/4] Basic build test...
go build ./cmd/server
if %ERRORLEVEL% neq 0 (
    echo ERROR: Server build failed
    goto :error
)

go build ./cmd/client
if %ERRORLEVEL% neq 0 (
    echo ERROR: Client build failed  
    goto :error
)

echo ✅ Builds successful

echo.
echo [2/4] Simple lint test (no goanalysis_metalinter)...
golangci-lint run --disable=goanalysis_metalinter --timeout=5m
if %ERRORLEVEL% neq 0 (
    echo ERROR: Linting failed even without goanalysis_metalinter
    goto :error
)

echo ✅ Lint successful

echo.
echo [3/4] Test comprehensive linting with new config...
golangci-lint run --timeout=10m
if %ERRORLEVEL% neq 0 (
    echo ERROR: Comprehensive linting failed
    goto :error
)

echo ✅ Comprehensive lint successful

echo.
echo [4/4] Running tests...
go test ./...
if %ERRORLEVEL% neq 0 (
    echo ERROR: Tests failed
    goto :error
)

echo ✅ Tests successful

echo.
echo ============================================
echo ✅ SIMPLE FIX WORKS!
echo ============================================
echo - Builds: SUCCESS
echo - Lint (no goanalysis_metalinter): SUCCESS  
echo - Comprehensive lint: SUCCESS
echo - Tests: SUCCESS
echo.
echo Ready for GitHub deployment!
echo ============================================
goto :end

:error
echo.
echo ============================================
echo ❌ SIMPLE FIX FAILED
echo ============================================
echo Run diagnose-build-issue.bat for detailed analysis
echo ============================================
pause
exit /b 1

:end
echo Simple fix test completed at %date% %time%
pause
