@echo off
echo ============================================
echo SHIPS2-Go Build Diagnostic and Fix Script
echo Date: %date% %time%
echo ============================================

echo.
echo [STEP 1] Basic Go environment check...
go version
echo Go module status:
go env GOMOD
echo Go cache status:
go env GOCACHE

echo.
echo [STEP 2] Clean go module cache and rebuild...
go clean -modcache
go mod download
if %ERRORLEVEL% neq 0 (
    echo ERROR: go mod download failed
    goto :error
)

echo.
echo [STEP 3] Verify basic build works...
go build ./cmd/server
if %ERRORLEVEL% neq 0 (
    echo ERROR: Server build failed - this is the root cause!
    echo.
    echo Running detailed build to see error:
    go build -v ./cmd/server
    goto :error
)

go build ./cmd/client  
if %ERRORLEVEL% neq 0 (
    echo ERROR: Client build failed - this is the root cause!
    echo.
    echo Running detailed build to see error:
    go build -v ./cmd/client
    goto :error
)

echo ✅ Basic builds successful

echo.
echo [STEP 4] Test if golangci-lint can run at all...
echo Testing basic golangci-lint execution...
golangci-lint run --disable-all --enable=gofmt --timeout=1m
if %ERRORLEVEL% neq 0 (
    echo ERROR: Even basic golangci-lint fails
    goto :error
)

echo ✅ Basic golangci-lint works

echo.
echo [STEP 5] Test with limited linters (no goanalysis_metalinter)...
golangci-lint run --disable=goanalysis_metalinter --timeout=2m
if %ERRORLEVEL% equ 0 (
    echo ✅ SUCCESS: Works without goanalysis_metalinter
    echo.
    echo SOLUTION: The problem is specifically with goanalysis_metalinter
    echo This confirms we need to disable it permanently.
) else (
    echo ERROR: Still failing even without goanalysis_metalinter
    echo This suggests a deeper build issue
)

echo.
echo [STEP 6] Generate detailed diagnostic info...
echo Go modules:
go list -m all | head -10

echo.
echo Dependencies causing issues:
go list -deps ./... | findstr sqlite

echo.
echo Build info:
go list -f "{{.ImportPath}}: {{.GoFiles}}" ./...

echo.
echo ============================================
echo DIAGNOSTIC COMPLETE
echo ============================================
goto :end

:error
echo.
echo ============================================
echo DIAGNOSTIC FAILED
echo ============================================
echo The root cause is likely a basic build issue.
echo Check the error messages above.
echo ============================================
pause
exit /b 1

:end
echo.
echo Diagnostic completed at %date% %time%
echo Check results above to determine next steps.
pause
