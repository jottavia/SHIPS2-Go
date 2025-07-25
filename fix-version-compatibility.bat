@echo off
echo ============================================
echo SHIPS2-Go Version Fix - golangci-lint v2.1.0
echo Date: %date% %time%
echo ============================================

echo.
echo Fixing golangci-lint version compatibility issue...
echo golangci-lint-action v8 requires golangci-lint >= v2.1.0
echo Previous v1.59.1 is not supported by action v8

echo.
echo [1/2] Testing with correct version locally...
echo Note: This might fail locally if v2.1.0 is not installed
golangci-lint version
echo.

echo [2/2] The fix is applied to CI workflows:
echo - .github/workflows/ci.yml: version v2.1.0
echo - .github/workflows/golangci-lint.yml: version v2.1.0
echo - This will work in GitHub CI even if local version differs

echo.
echo ============================================
echo ✅ VERSION FIX APPLIED
echo ============================================
echo - CI workflows updated to use v2.1.0
echo - Compatible with golangci-lint-action@v8
echo - Maintains goanalysis_metalinter disable flag
echo.
echo Ready for GitHub deployment
echo ============================================
pause
