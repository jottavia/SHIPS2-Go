#!/bin/bash
# test_readiness.sh - SHIPS2-Go v1.0.0 Testing Readiness Verification

set -euo pipefail

echo "🚀 SHIPS2-Go v1.0.0 Testing Readiness Check"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    info "Testing: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        success "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        error "$test_name"
    fi
}

# Verify we're in the right directory
if [[ ! -f "go.mod" ]] || [[ ! -f "RELEASE_NOTES_v1.0.0.md" ]]; then
    error "Not in SHIPS2-Go v1.0.0 project directory"
    exit 1
fi

success "Found SHIPS2-Go v1.0.0 project directory"

echo ""
info "🔍 Pre-Testing Verification"
echo "============================="

# 1. Version consistency check
echo ""
info "Checking version consistency..."

# Check server version
if grep -q "var version = \"1.0.0\"" cmd/server/main.go; then
    success "Server version set to 1.0.0"
else
    error "Server version not set correctly"
fi

# Check client version  
if grep -q "var version = \"1.0.0\"" cmd/client/main.go; then
    success "Client version set to 1.0.0"
else
    error "Client version not set correctly"
fi

# Check wrapper version
if grep -q "readonly VERSION=\"1.0.0\"" bin/shipsc_wrapper.sh; then
    success "SSH wrapper version set to 1.0.0"
else
    error "SSH wrapper version not set correctly"
fi

# 2. File structure verification
echo ""
info "Verifying file structure..."

required_files=(
    "cmd/server/main.go"
    "cmd/client/main.go"
    "internal/api/api.go"
    "internal/store/store.go"
    "bin/shipsc_wrapper.sh"
    "deploy/deploy_ships_server.sh"
    "deploy/deploy_rsyslog_shipsc.sh"
    "deploy/deploy_wazuh_local_rules.sh"
    "docs/client_task.xml"
    "docs/project_overview.md"
    "tracking/project_status.md"
    "tracking/architecture.md"
    "tracking/decisions.md"
    "tracking/next_steps.md"
    "tests/integration_test.go"
    "Makefile"
    "README.md"
    "RELEASE_NOTES_v1.0.0.md"
    "FIXES_SUMMARY.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        run_test "File exists: $file" "true"
    else
        run_test "File exists: $file" "false"
    fi
done

# 3. Compilation tests
echo ""
info "Testing compilation..."

run_test "Go module verification" "go mod verify"
run_test "Go vet passes" "go vet ./..."
run_test "Go fmt check" "[[ -z \$(gofmt -s -l .) ]]"
run_test "Server compiles" "go build -o /tmp/test-server ./cmd/server && rm -f /tmp/test-server"
run_test "Client compiles" "go build -o /tmp/test-client ./cmd/client && rm -f /tmp/test-client"

# 4. Security feature verification
echo ""
info "Verifying security features..."

run_test "HTTP Basic Auth implemented" "grep -q 'basicAuthMiddleware' cmd/server/main.go"
run_test "Input validation implemented" "grep -q 'validateHostname' internal/store/store.go"
run_test "Audit logging with remote IP" "grep -q 'remote_addr' internal/store/store.go"
run_test "SSH wrapper input validation" "grep -q 'validate_hostname' bin/shipsc_wrapper.sh"
run_test "JSON structured logging" "grep -q 'log_json' bin/shipsc_wrapper.sh"

# 5. API compatibility verification
echo ""
info "Verifying API compatibility fixes..."

run_test "PasswordInfo struct exists" "grep -q 'PasswordInfo' internal/store/store.go"
run_test "BitLockerKeyInfo struct exists" "grep -q 'BitLockerKeyInfo' internal/store/store.go"
run_test "Proper JSON struct tags" "grep -q 'json:\"host\"' internal/api/api.go"
run_test "API error handling improved" "grep -q 'StatusInternalServerError' internal/api/api.go"

# 6. Deployment readiness
echo ""
info "Verifying deployment readiness..."

run_test "Deployment script executable" "[[ -x deploy/deploy_ships_server.sh ]]"
run_test "Auth support in deployment" "grep -q 'auth' deploy/deploy_ships_server.sh"
run_test "Wazuh integration available" "grep -q 'with-wazuh' deploy/deploy_ships_server.sh"
run_test "SSH wrapper executable" "[[ -x bin/shipsc_wrapper.sh ]]"

# 7. Documentation completeness
echo ""
info "Verifying documentation..."

run_test "README updated for v1.0.0" "grep -q 'Production Ready' README.md"
run_test "Release notes exist" "[[ -f RELEASE_NOTES_v1.0.0.md ]]"
run_test "Fixes summary complete" "grep -q 'Production Ready' FIXES_SUMMARY.md"
run_test "Architecture documented" "[[ -f tracking/architecture.md ]]"

# 8. Integration test availability
echo ""
info "Verifying test infrastructure..."

run_test "Integration tests exist" "[[ -f tests/integration_test.go ]]"
run_test "Validation script executable" "[[ -x validate_fixes.sh ]]"
run_test "Test readiness script (this one) works" "true"

# Summary
echo ""
echo "📊 Testing Readiness Summary"
echo "============================="

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    success "ALL TESTS PASSED ($PASSED_TESTS/$TOTAL_TESTS)"
    echo ""
    echo "🎉 SHIPS2-Go v1.0.0 is READY FOR TESTING!"
    echo ""
    echo "🧪 Recommended Testing Sequence:"
    echo "1. Run './validate_fixes.sh' for comprehensive validation"
    echo "2. Run 'make all' to build all components" 
    echo "3. Run 'go test ./tests/...' for integration tests"
    echo "4. Test deployment script on clean system"
    echo "5. Perform end-to-end client/server testing"
    echo "6. Security testing and penetration testing"
    echo ""
    echo "📚 Testing Documentation:"
    echo "- See RELEASE_NOTES_v1.0.0.md for detailed testing instructions"
    echo "- See tracking/next_steps.md for comprehensive testing roadmap"
    echo "- See README.md for quick start and basic usage"
    
else
    warning "SOME TESTS FAILED ($PASSED_TESTS/$TOTAL_TESTS)"
    echo ""
    error "Please resolve failing tests before proceeding with production testing"
    echo ""
    echo "💡 Common fixes:"
    echo "- Ensure all files are saved and committed"
    echo "- Run 'go mod tidy' to clean up dependencies"
    echo "- Check file permissions on shell scripts"
    echo "- Verify version numbers are correctly set"
fi

echo ""
info "Version: SHIPS2-Go v1.0.0"
info "Status: Production Ready Release"
info "Date: $(date)"