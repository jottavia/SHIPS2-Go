#!/bin/bash
# build-deb.sh - Build Debian package for SHIPS2-Go

set -euo pipefail

VERSION=${1:-"1.0.0"}
PACKAGE_NAME="ships2-go"
ARCH="amd64"

echo "Building Debian package for SHIPS2-Go v${VERSION}"

# Clean up any previous builds
rm -rf debian-build
mkdir -p debian-build

# Create package directory structure
PACKAGE_DIR="debian-build/${PACKAGE_NAME}_${VERSION}_${ARCH}"
mkdir -p "${PACKAGE_DIR}/DEBIAN"
mkdir -p "${PACKAGE_DIR}/opt/ships/bin"
mkdir -p "${PACKAGE_DIR}/opt/ships/deploy"
mkdir -p "${PACKAGE_DIR}/etc/systemd/system"
mkdir -p "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}"
mkdir -p "${PACKAGE_DIR}/usr/share/man/man1"

# Copy binaries
cp dist/ships-server-linux-amd64 "${PACKAGE_DIR}/opt/ships/bin/ships-server"
cp dist/shipsc-linux-amd64 "${PACKAGE_DIR}/opt/ships/bin/shipsc"
cp bin/shipsc_wrapper.sh "${PACKAGE_DIR}/opt/ships/bin/"
chmod +x "${PACKAGE_DIR}/opt/ships/bin/"*

# Copy deployment scripts
cp deploy/*.sh "${PACKAGE_DIR}/opt/ships/deploy/"
cp deploy/ships_server "${PACKAGE_DIR}/etc/systemd/system/ships-server.service"
chmod +x "${PACKAGE_DIR}/opt/ships/deploy/"*.sh

# Copy documentation
cp README.md "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/"
cp RELEASE_NOTES_v1.0.0.md "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/"
cp docs/*.md "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/"
gzip -c docs/shipsc.1 > "${PACKAGE_DIR}/usr/share/man/man1/shipsc.1.gz" 2>/dev/null || echo "No man page found, skipping"

# Create control file
cat > "${PACKAGE_DIR}/DEBIAN/control" <<EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: admin
Priority: optional
Architecture: ${ARCH}
Depends: sqlite3, systemd, openssh-server
Recommends: rsyslog
Suggests: wazuh-agent
Maintainer: SHIPS2-Go Project <ships-go@example.com>
Homepage: https://github.com/jottavia/ships-go
Description: Secure password escrow for workgroup environments
 SHIPS2-Go provides secure password rotation and escrow for Windows
 workstations in environments without Active Directory. It includes
 BitLocker recovery key management and comprehensive audit logging.
 .
 This package contains the server components for Linux systems.
EOF

# Create postinst script
cat > "${PACKAGE_DIR}/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e

# Create ships user if it doesn't exist
if ! id -u ships >/dev/null 2>&1; then
    useradd --system --home /opt/ships --shell /usr/sbin/nologin ships
fi

# Create data directory
mkdir -p /var/lib/ships
chown ships:ships /var/lib/ships

# Create shipscmd user for SSH access
if ! id -u shipscmd >/dev/null 2>&1; then
    useradd --system --home /opt/ships --shell /bin/bash --comment "SHIPS2-Go operator" shipscmd
fi

# Set up SSH directory
mkdir -p /home/shipscmd/.ssh
chown shipscmd:shipscmd /home/shipscmd/.ssh
chmod 700 /home/shipscmd/.ssh

# Enable and start service
systemctl daemon-reload
systemctl enable ships-server.service

echo "SHIPS2-Go installed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure authentication: export SHIPS_AUTH_USER=admin SHIPS_AUTH_PASS=yourpassword"
echo "2. Add SSH keys to /home/shipscmd/.ssh/authorized_keys"
echo "3. Start the service: systemctl start ships-server"
echo ""
echo "For complete setup, run: /opt/ships/deploy/deploy_ships_server.sh"
EOF

# Create prerm script
cat > "${PACKAGE_DIR}/DEBIAN/prerm" <<'EOF'
#!/bin/bash
set -e

# Stop service if running
if systemctl is-active --quiet ships-server; then
    systemctl stop ships-server
fi
EOF

# Create postrm script
cat > "${PACKAGE_DIR}/DEBIAN/postrm" <<'EOF'
#!/bin/bash
set -e

case "$1" in
    purge)
        # Remove users and data on purge
        if id -u ships >/dev/null 2>&1; then
            userdel ships || true
        fi
        if id -u shipscmd >/dev/null 2>&1; then
            userdel shipscmd || true
        fi
        
        # Remove data directory
        rm -rf /var/lib/ships
        
        # Remove home directory
        rm -rf /home/shipscmd
        ;;
esac

# Reload systemd
systemctl daemon-reload || true
EOF

# Make scripts executable
chmod +x "${PACKAGE_DIR}/DEBIAN/postinst"
chmod +x "${PACKAGE_DIR}/DEBIAN/prerm"
chmod +x "${PACKAGE_DIR}/DEBIAN/postrm"

# Calculate package size
INSTALLED_SIZE=$(du -sk "${PACKAGE_DIR}" | cut -f1)
echo "Installed-Size: ${INSTALLED_SIZE}" >> "${PACKAGE_DIR}/DEBIAN/control"

# Build package
dpkg-deb --build "${PACKAGE_DIR}" "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo "Debian package built: ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

# Verify package
dpkg-deb --info "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
dpkg-deb --contents "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"