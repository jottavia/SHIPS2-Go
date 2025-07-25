# SHIPS2-Go GitHub Integration & Release Automation Guide

## 🎯 Overview

This guide covers the complete setup for SHIPS2-Go GitHub integration with automated builds and installer packages.

## 📦 What We've Created

### GitHub Actions Workflows
- **CI Pipeline** (`.github/workflows/ci.yml`) - Continuous integration testing
- **Build & Release** (`.github/workflows/build-and-release.yml`) - Automated builds and releases

### Installer Packages
- **Windows Installer** (`installer/windows/ships2-go-installer.nsi`) - NSIS-based installer
- **Linux DEB Package** (`scripts/build-deb.sh`) - Debian package builder  
- **Linux RPM Package** (`scripts/build-rpm.sh`) - Red Hat package builder

### Supporting Files
- **License** (`LICENSE`) - MIT License
- **Man Page** (`docs/shipsc.1`) - Linux manual page
- **Service File** (`deploy/ships_server`) - Systemd service definition
- **Lint Config** (`.golangci.yml`) - Go linting configuration

## 🚀 Quick Start

### Option 1: Bash (Linux/macOS/WSL)
```bash
chmod +x github-setup.sh
./github-setup.sh
```

### Option 2: PowerShell (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\github-setup.ps1
```

## 📋 Manual Setup Steps

### 1. Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial commit: SHIPS2-Go v1.0.0"
git tag -a v1.0.0 -m "SHIPS2-Go v1.0.0 - Production Ready Release"
```

### 2. Create GitHub Repository
1. Go to https://github.com/new
2. Repository name: `ships-go`
3. Description: `Secure password escrow for workgroup environments`
4. Choose visibility (Public recommended for open source)
5. **Do NOT** initialize with README, license, or .gitignore (we have our own)

### 3. Push to GitHub
```bash
git remote add origin https://github.com/YOUR_USERNAME/ships-go.git
git branch -M main
git push -u origin main
git push --tags
```

### 4. Verify GitHub Actions
After pushing, check the **Actions** tab in your GitHub repository:
- CI workflow should run automatically on push
- Build workflow will run when you push tags

## 🔧 GitHub Actions Features

### Continuous Integration (CI)
**Triggers:** Push to main/develop, Pull Requests
**Features:**
- Multi-platform testing (Linux, Windows, macOS)
- Go linting with golangci-lint
- Security scanning with gosec
- Code coverage reporting
- Cross-compilation testing

### Build & Release
**Triggers:** Git tags (v*)
**Builds:**
- Linux binaries (amd64, arm64)
- Windows binaries (amd64, arm64)
- macOS binaries (amd64, arm64)
- Windows installer (.exe)
- Linux packages (.deb, .rpm)

**Artifacts:**
- Cross-platform binaries
- Installation packages
- Source archives
- SHA256 checksums

## 📦 Package Details

### Windows Installer Features
- **NSIS-based installer** with modern UI
- **Automatic service installation** and configuration
- **Scheduled Task import** for password rotation
- **Start Menu shortcuts** and uninstaller
- **Registry integration** for proper Windows integration
- **PATH environment** variable updates

### Linux DEB Package Features
- **Systemd integration** with automatic service setup
- **User creation** (ships, shipscmd) with proper permissions
- **Dependency management** (sqlite3, systemd, openssh-server)
- **Man page installation** for documentation
- **Automatic cleanup** on package removal

### Linux RPM Package Features
- **RPM spec file** with proper metadata
- **Systemd macros** for service management
- **User management** with pre/post install scripts
- **Dependency handling** for RHEL/CentOS/Fedora
- **Source and binary** package generation

## 🔒 Security Features

### Code Scanning
- **gosec** - Go security scanner
- **SARIF upload** to GitHub Security tab
- **Dependency scanning** with GitHub Dependabot
- **Secret scanning** for leaked credentials

### Build Security
- **Reproducible builds** with version pinning
- **Checksum verification** for all artifacts
- **Signed commits** (if GPG key configured)
- **Protected branches** with required status checks

## 🌐 Release Process

### Automatic Releases
1. **Create tag:** `git tag -a v1.1.0 -m "Release v1.1.0"`
2. **Push tag:** `git push --tags`
3. **GitHub Actions automatically:**
   - Builds all platforms
   - Creates installer packages
   - Uploads to GitHub Releases
   - Generates release notes

### Release Assets
Each release includes:
- `ships-server-linux-amd64` - Linux server binary
- `ships-server-linux-arm64` - Linux ARM64 server binary  
- `shipsc-windows-amd64.exe` - Windows client binary
- `shipsc-linux-amd64` - Linux client binary
- `SHIPS2-Go-v1.0.0-installer.exe` - Windows installer
- `ships2-go_1.0.0_amd64.deb` - Debian package
- `ships2-go-1.0.0-1.x86_64.rpm` - RPM package
- `ships2-go-v1.0.0-source.tar.gz` - Source archive
- `SHA256SUMS` - Checksum file

## 🛠️ Development Workflow

### Local Development
```bash
# Run tests
go test ./...

# Run linting
golangci-lint run

# Build locally
make all

# Test packages
./scripts/build-deb.sh 1.0.0
```

### Pull Request Process
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and commit
3. Push branch: `git push origin feature/new-feature`
4. Create Pull Request on GitHub
5. CI will automatically run tests
6. Merge after review and CI passes

### Release Process
1. Update version numbers in code
2. Update RELEASE_NOTES_vX.X.X.md
3. Create and push tag: `git tag v1.1.0 && git push --tags`
4. GitHub Actions creates release automatically
5. Verify release artifacts and test downloads

## 🔍 Troubleshooting

### Common Issues

**GitHub Actions failing:**
- Check Go version compatibility in workflows
- Verify all required files are present
- Check for syntax errors in YAML files

**Package build failures:**
- Ensure binary names match script expectations
- Check file permissions on shell scripts
- Verify dependencies are available in build environment

**Installer issues:**
- NSIS script requires specific file layout
- Windows binaries must be in `dist/` directory
- Icon files must be present (create placeholder if needed)

### Debug Commands
```bash
# Test workflow locally with act
act -j test

# Build packages locally
./scripts/build-deb.sh 1.0.0
./scripts/build-rpm.sh 1.0.0

# Test installer (Windows)
makensis /DVERSION=1.0.0 installer/windows/ships2-go-installer.nsi
```

## 📈 Monitoring & Maintenance

### Repository Health
- Monitor GitHub Actions success rates
- Review security alerts and Dependabot PRs
- Track code coverage trends
- Monitor download statistics

### Release Management
- Keep release notes up to date
- Test installer packages on clean systems
- Verify cross-platform compatibility
- Monitor user feedback and issues

## 🎉 Success Metrics

After setup, you should have:
- ✅ Automated CI/CD pipeline
- ✅ Cross-platform binary builds
- ✅ Professional installer packages
- ✅ Security scanning and monitoring
- ✅ Comprehensive documentation
- ✅ Release automation

## 📞 Support

### Documentation
- **README.md** - Quick start guide
- **docs/project_overview.md** - Comprehensive documentation
- **RELEASE_NOTES_v1.0.0.md** - Release information

### Community
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Community support
- **GitHub Security** - Security vulnerability reports

---

**SHIPS2-Go is now ready for professional GitHub hosting with automated builds and releases!** 🚀
