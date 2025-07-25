# GitHub Runner Environment Specifications
**Last Updated**: 2025-07-21  
**Source**: GitHub Actions Runner Images Documentation  
**Purpose**: Reference for CI/CD compatibility and version alignment

---

## 🐧 **ubuntu-latest (Ubuntu 22.04)**

### **Core Development Tools:**
- **Go**: 1.22.5
- **Node.js**: 20.15.1
- **Python**: 3.12.4
- **Ruby**: 3.3.3
- **Java (OpenJDK)**: 11.0.23

### **Build & Deployment:**
- **Docker**: 26.1.4
- **Git**: 2.45.2
- **GCC**: 11.4.0
- **curl**: 7.81.0

---

## 🪟 **windows-latest (Windows Server 2022)**

### **Core Development Tools:**
- **Go**: 1.22.5
- **Node.js**: 20.15.1
- **Python**: 3.12.4
- **Ruby**: 3.3.3
- **Java (Microsoft OpenJDK)**: 11.0.23

### **Build & Deployment:**
- **Docker**: 26.1.4
- **Git**: 2.45.2
- **.NET SDK**: 6.0.424, 7.0.410, 8.0.303 (8.0.x on PATH)

---

## 🍎 **macos-latest (macOS 12)**

### **Core Development Tools:**
- **Go**: 1.22.5
- **Node.js**: 20.15.1
- **Python**: 3.12.4
- **Ruby**: 3.3.3
- **Java (Zulu OpenJDK)**: 11.0.23

### **Build & Deployment:**
- **Git**: 2.45.2
- **Xcode**: 14.2

---

## 🎯 **SHIPS2-Go Compatibility Matrix**

| Component | All Runners | Project Config | Status |
|-----------|-------------|----------------|--------|
| **Go Version** | 1.22.5 | 1.22 | ✅ **COMPATIBLE** |
| **Git** | 2.45.2 | Any | ✅ **COMPATIBLE** |
| **Docker** | 26.1.4 | N/A | ✅ **AVAILABLE** |

---

## 📋 **CI/CD Implications**

### **Go Toolchain:**
- **Maximum Go Version**: 1.22.x (runner limitation)
- **golangci-lint**: Must use versions compatible with Go 1.22
- **Dependencies**: Must support Go 1.22 minimum requirements

### **Build Matrix Support:**
- **Cross-compilation**: All GOOS/GOARCH combinations supported
- **Testing**: Full test suite runs on all three platforms
- **Artifacts**: Native builds available for Linux, Windows, macOS

### **Version Update Strategy:**
- **Monitor**: actions/runner-images repository for updates
- **Align**: Project Go version with runner capabilities
- **Test**: Compatibility before upgrading project dependencies

---

## 🔄 **Maintenance Schedule**

### **Runner Image Updates:**
Runner images are updated regularly by GitHub. Check for updates:
- **Frequency**: Monitor monthly for major version changes
- **Source**: https://github.com/actions/runner-images
- **Impact**: May require project configuration updates

### **Version Alignment Checklist:**
- [ ] Verify Go version compatibility
- [ ] Update golangci-lint version if needed
- [ ] Test cross-platform builds
- [ ] Update workflow files if required
- [ ] Document any breaking changes

---

## 📚 **Reference Links**

- **Official Documentation**: https://docs.github.com/en/actions/using-github-hosted-runners
- **Runner Images Repository**: https://github.com/actions/runner-images
- **Ubuntu 22.04 Specs**: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2204-Readme.md
- **Windows 2022 Specs**: https://github.com/actions/runner-images/blob/main/images/windows/Windows2022-Readme.md
- **macOS 12 Specs**: https://github.com/actions/runner-images/blob/main/images/macos/macos-12-Readme.md

---

## ⚠️ **Critical Notes**

### **Version Constraints:**
These versions are subject to change with each new runner image release. Always verify compatibility when:
- Upgrading Go version in project
- Adding new dependencies
- Updating CI/CD workflows
- Planning major releases

### **Breaking Changes:**
Major version updates to runner images may require:
- Project configuration updates
- Dependency version bumps
- Workflow file modifications
- Compatibility testing

---

**Document Version**: 1.0  
**Last Verified**: 2025-07-21  
**Next Review**: 2025-08-21 (monthly)  
**Responsible**: Development Team
