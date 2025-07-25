# github-setup.ps1 - Initialize SHIPS2-Go GitHub repository (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "🚀 SHIPS2-Go GitHub Repository Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor Blue
}

# Check if we're in a git repository
try {
    git rev-parse --git-dir | Out-Null
    Write-Success "Git repository already exists"
} catch {
    Write-Info "Initializing Git repository..."
    git init
    Write-Success "Git repository initialized"
}

# Check if we have the required files
$requiredFiles = @(
    "go.mod",
    "README.md", 
    "LICENSE",
    ".github/workflows/build-and-release.yml",
    ".github/workflows/ci.yml",
    ".golangci.yml"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (!(Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Missing required files:"
    $missingFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Success "All required files present"

# Create .gitignore if it doesn't exist
if (!(Test-Path ".gitignore")) {
    Write-Info "Creating .gitignore..."
    
    $gitignoreContent = @'
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
'@
    
    $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding utf8
    Write-Success ".gitignore created"
} else {
    Write-Success ".gitignore already exists"
}

# Add all files to git
Write-Info "Adding files to Git..."
git add .

# Check if there are changes to commit
$status = git status --porcelain
if ([string]::IsNullOrEmpty($status)) {
    Write-Warning "No changes to commit"
} else {
    Write-Info "Committing initial version..."
    
    $commitMessage = @"
Initial commit: SHIPS2-Go v1.0.0

- Complete password escrow and BitLocker key management solution
- Production-ready with security controls and audit logging  
- Automated deployment and monitoring integration
- Cross-platform support (Windows/Linux)
- Comprehensive documentation and testing infrastructure
"@
    
    git commit -m $commitMessage
    Write-Success "Initial commit created"
}

# Tag the release
$existingTags = git tag
if ($existingTags -notcontains "v1.0.0") {
    Write-Info "Creating v1.0.0 tag..."
    
    $tagMessage = @"
SHIPS2-Go v1.0.0 - Production Ready Release

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
- Professional documentation and troubleshooting guides
"@
    
    git tag -a v1.0.0 -m $tagMessage
    Write-Success "v1.0.0 tag created"
} else {
    Write-Warning "v1.0.0 tag already exists"
}

Write-Host ""
Write-Info "📋 Next Steps for GitHub Setup:"
Write-Host ""
Write-Host "1. Create GitHub repository:" -ForegroundColor White
Write-Host "   - Go to https://github.com/new" -ForegroundColor Gray
Write-Host "   - Repository name: ships-go" -ForegroundColor Gray
Write-Host "   - Description: Secure password escrow for workgroup environments" -ForegroundColor Gray
Write-Host "   - Choose Public or Private" -ForegroundColor Gray
Write-Host "   - Do NOT initialize with README (we have our own)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Add GitHub remote:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/ships-go.git" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Push to GitHub:" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor Yellow
Write-Host "   git push --tags" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Configure GitHub repository settings:" -ForegroundColor White
Write-Host "   - Enable GitHub Actions (should be automatic)" -ForegroundColor Gray
Write-Host "   - Set up branch protection rules for main branch" -ForegroundColor Gray
Write-Host "   - Configure repository secrets if needed" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Verify GitHub Actions:" -ForegroundColor White
Write-Host "   - Check the Actions tab after pushing" -ForegroundColor Gray
Write-Host "   - CI workflow should run on push" -ForegroundColor Gray
Write-Host "   - Release workflow will run when you push tags" -ForegroundColor Gray
Write-Host ""

Write-Info "🔧 Optional: Configure repository secrets for enhanced functionality:"
Write-Host ""
Write-Host "Repository Settings → Secrets and variables → Actions:" -ForegroundColor White
Write-Host "- CODECOV_TOKEN: For code coverage reporting" -ForegroundColor Gray
Write-Host "- SLACK_WEBHOOK: For build notifications" -ForegroundColor Gray
Write-Host "- SECURITY_EMAIL: For security alert notifications" -ForegroundColor Gray
Write-Host ""

Write-Info "📦 GitHub Actions will automatically:"
Write-Host "- Run tests on all platforms (Linux, Windows, macOS)" -ForegroundColor Gray
Write-Host "- Build binaries for all supported architectures" -ForegroundColor Gray
Write-Host "- Create Windows installer packages" -ForegroundColor Gray
Write-Host "- Build Linux DEB and RPM packages" -ForegroundColor Gray
Write-Host "- Create GitHub releases with all artifacts" -ForegroundColor Gray
Write-Host "- Run security scans and linting" -ForegroundColor Gray
Write-Host ""

Write-Success "GitHub repository setup completed!"
Write-Success "Ready to push SHIPS2-Go v1.0.0 to GitHub!"

Write-Host ""
Write-Warning "⚠️  Remember to:"
Write-Host "1. Replace YOUR_USERNAME with your actual GitHub username" -ForegroundColor Gray
Write-Host "2. Test the GitHub Actions workflows after initial push" -ForegroundColor Gray
Write-Host "3. Update any placeholder URLs in deployment scripts" -ForegroundColor Gray
Write-Host "4. Consider setting up GitHub Pages for documentation" -ForegroundColor Gray
