#!/bin/bash
# secure-push.sh - Push SHIPS2-Go to GitHub (no embedded tokens)

set -e

echo "🚀 Pushing SHIPS2-Go v1.0.0 to GitHub..."
echo "⚠️  You will need to provide your GitHub credentials when prompted"

# Configure git if needed
git config --global user.name "SHIPS2-Go" 2>/dev/null || true
git config --global user.email "ships-go@example.com" 2>/dev/null || true

# Initialize if needed
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Add GitHub remote (without token)
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/jottavia/ships-go.git

# Create .gitignore
cat > .gitignore << 'EOF'
*.exe
*.dll
*.so
*.dylib
*.test
*.out
vendor/
go.work
/bin/
/dist/
/build/
.vscode/
.idea/
*.swp
.DS_Store
Thumbs.db
*.log
*.db
coverage.out
.env
*.backup
# Security - never commit tokens
*.DELETE
*token*
.env*
EOF

# Make scripts executable
find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Remove any files with tokens
rm -f *.DELETE 2>/dev/null || true

# Add, commit and push
git add .
git commit -m "Initial release: SHIPS2-Go v1.0.0

Production-ready password escrow solution with:
- HTTP Basic Authentication
- Complete audit logging  
- Wazuh integration
- Windows/Linux installers
- Automated CI/CD pipeline"

git tag -a v1.0.0 -m "SHIPS2-Go v1.0.0 - Production Ready Release"

echo "📤 Pushing to GitHub..."
echo "🔐 You will be prompted for GitHub credentials..."
git push -u origin main
git push --tags

echo "✅ Successfully pushed SHIPS2-Go v1.0.0 to GitHub!"
echo "🔗 Repository: https://github.com/jottavia/ships-go"
echo "🎯 GitHub Actions will now build releases automatically"
