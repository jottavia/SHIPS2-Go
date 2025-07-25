#!/bin/bash
# github-setup.sh - Initialize SHIPS2-Go GitHub repository

set -euo pipefail

echo "🚀 SHIPS2-Go GitHub Repository Setup"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    info "Initializing Git repository..."
    git init
    success "Git repository initialized"
else
    success "Git repository already exists"
fi

# Check if we have the required files
required_files=(
    "go.mod"
    "README.md"
    "LICENSE"
    ".github/workflows/build-and-release.yml"
    ".github/workflows/ci.yml"
    ".golangci.yml"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    error "Missing required files:"
    printf '%s\n' "${missing_files[@]}"
    exit 1
fi

success "All required files present"

# Create .gitignore if it doesn't exist
if [[ ! -f ".gitignore" ]]; then
    info "Creating .gitignore..."
    cat > .gitignore <<'EOF'
# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with `go test -c`
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
# vendor/

# Go workspace file
go.work

# Build artifacts
/bin/
/dist/
/build/
/release-assets/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Local test files
/tmp/
*.tmp
*.temp

# Database files
*.db
*.sqlite
*.sqlite3

# Log files
*.log

# Installer build artifacts
/installer/windows/*.exe
/debian-build/
/rpm-build/
*.deb
*.rpm

# Coverage files
coverage.out
coverage.html

# Local configuration
.env
.env.local
local_config.yml

# Backup files
*.backup
*.bak
EOF
    success ".gitignore created"
else
    success ".gitignore already exists"
fi

# Add all files to git
info "Adding files to Git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    warning "No changes to commit"
else
    info "Committing initial version..."
    git commit -m "Initial commit: SHIPS2-Go v1.0.0

- Complete password escrow and BitLocker key management solution
- Production-ready with security controls and audit logging  
- Automated deployment and monitoring integration
- Cross-platform support (Windows/Linux)
- Comprehensive documentation and testing infrastructure"
    success "Initial commit created"
fi

# Tag the release
if ! git tag | grep -q "v1.0.0"; then
    info "Creating v1.0.0 tag..."
    git tag -a v1.0.0 -m "SHIPS2-Go v1.0.0 - Production Ready Release

This is the first production-ready release of SHIPS2-Go with all critical 
issues resolved and comprehensive security features implemented.

New Features:
- HTTP Basic Authentication for API security
- Complete audit logging with remote IP tracking
- Enhanced input validation and security controls
- Wazuh integration for security monitoring
- Production-ready deployment automation
- Windows installer and Linux packages

Security Improvements:
- Multi-layered security with authentication and validation
- Protection against injection attacks and timing attacks
- Complete audit trail for compliance requirements
- SSH-only external access with command restrictions

Operational Improvements:
- Automated deployment scripts with error handling
- Comprehensive monitoring and alerting integration
- Health checks and graceful error handling
- Professional documentation and troubleshooting guides"

    success "v1.0.0 tag created"
else
    warning "v1.0.0 tag already exists"
fi

echo ""
info "📋 Next Steps for GitHub Setup:"
echo ""
echo "1. Create GitHub repository:"
echo "   - Go to https://github.com/new"
echo "   - Repository name: ships-go"
echo "   - Description: Secure password escrow for workgroup environments"
echo "   - Choose Public or Private"
echo "   - Do NOT initialize with README (we have our own)"
echo ""
echo "2. Add GitHub remote:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/ships-go.git"
echo ""
echo "3. Push to GitHub:"
echo "   git push -u origin main"
echo "   git push --tags"
echo ""
echo "4. Configure GitHub repository settings:"
echo "   - Enable GitHub Actions (should be automatic)"
echo "   - Set up branch protection rules for main branch"
echo "   - Configure repository secrets if needed"
echo ""
echo "5. Verify GitHub Actions:"
echo "   - Check the Actions tab after pushing"
echo "   - CI workflow should run on push"
echo "   - Release workflow will run when you push tags"
echo ""

info "🔧 Optional: Configure repository secrets for enhanced functionality:"
echo ""
echo "Repository Settings → Secrets and variables → Actions:"
echo "- CODECOV_TOKEN: For code coverage reporting"
echo "- SLACK_WEBHOOK: For build notifications"
echo "- SECURITY_EMAIL: For security alert notifications"
echo ""

info "📦 GitHub Actions will automatically:"
echo "- Run tests on all platforms (Linux, Windows, macOS)"
echo "- Build binaries for all supported architectures"
echo "- Create Windows installer packages"
echo "- Build Linux DEB and RPM packages"
echo "- Create GitHub releases with all artifacts"
echo "- Run security scans and linting"
echo ""

success "GitHub repository setup completed!"
success "Ready to push SHIPS2-Go v1.0.0 to GitHub!"

echo ""
warning "⚠️  Remember to:"
echo "1. Replace YOUR_USERNAME with your actual GitHub username"
echo "2. Test the GitHub Actions workflows after initial push"
echo "3. Update any placeholder URLs in deployment scripts"
echo "4. Consider setting up GitHub Pages for documentation"
