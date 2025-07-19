#!/bin/bash
# build-rpm.sh - Build RPM package for SHIPS2-Go

set -euo pipefail

VERSION=${1:-"1.0.0"}
PACKAGE_NAME="ships2-go"
ARCH="x86_64"

echo "Building RPM package for SHIPS2-Go v${VERSION}"

# Clean up any previous builds
rm -rf rpm-build
mkdir -p rpm-build/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create RPM spec file
cat > rpm-build/SPECS/${PACKAGE_NAME}.spec <<EOF
Name:           ${PACKAGE_NAME}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Secure password escrow for workgroup environments
License:        MIT
URL:            https://github.com/jottavia/ships-go
Source0:        %{name}-%{version}.tar.gz
BuildArch:      ${ARCH}

Requires:       sqlite, systemd, openssh-server
Recommends:     rsyslog

%description
SHIPS2-Go provides secure password rotation and escrow for Windows
workstations in environments without Active Directory. It includes
BitLocker recovery key management and comprehensive audit logging.

This package contains the server components for Linux systems.

%prep
%setup -q

%build
# No build needed - binaries are pre-built

%install
rm -rf %{buildroot}

# Create directory structure
mkdir -p %{buildroot}/opt/ships/bin
mkdir -p %{buildroot}/opt/ships/deploy
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}%{_docdir}/%{name}
mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}/var/lib/ships

# Install binaries
install -m 755 dist/ships-server-linux-amd64 %{buildroot}/opt/ships/bin/ships-server
install -m 755 dist/shipsc-linux-amd64 %{buildroot}/opt/ships/bin/shipsc
install -m 755 bin/shipsc_wrapper.sh %{buildroot}/opt/ships/bin/

# Install deployment scripts
install -m 755 deploy/*.sh %{buildroot}/opt/ships/deploy/
install -m 644 deploy/ships_server %{buildroot}/etc/systemd/system/ships-server.service

# Install documentation
install -m 644 README.md %{buildroot}%{_docdir}/%{name}/
install -m 644 RELEASE_NOTES_v1.0.0.md %{buildroot}%{_docdir}/%{name}/
install -m 644 docs/*.md %{buildroot}%{_docdir}/%{name}/

%files
%defattr(-,root,root,-)
%{_docdir}/%{name}/
/opt/ships/bin/ships-server
/opt/ships/bin/shipsc
/opt/ships/bin/shipsc_wrapper.sh
/opt/ships/deploy/
/etc/systemd/system/ships-server.service
%attr(755,ships,ships) /var/lib/ships

%pre
# Create ships user
if ! getent passwd ships >/dev/null; then
    useradd --system --home /opt/ships --shell /usr/sbin/nologin ships
fi

# Create shipscmd user for SSH access
if ! getent passwd shipscmd >/dev/null; then
    useradd --system --home /opt/ships --shell /bin/bash --comment "SHIPS2-Go operator" shipscmd
fi

%post
# Set up data directory
mkdir -p /var/lib/ships
chown ships:ships /var/lib/ships

# Set up SSH directory
mkdir -p /home/shipscmd/.ssh
chown shipscmd:shipscmd /home/shipscmd/.ssh
chmod 700 /home/shipscmd/.ssh

# Enable service
%systemd_post ships-server.service

echo "SHIPS2-Go installed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure authentication: export SHIPS_AUTH_USER=admin SHIPS_AUTH_PASS=yourpassword"
echo "2. Add SSH keys to /home/shipscmd/.ssh/authorized_keys"
echo "3. Start the service: systemctl start ships-server"
echo ""
echo "For complete setup, run: /opt/ships/deploy/deploy_ships_server.sh"

%preun
%systemd_preun ships-server.service

%postun
%systemd_postun_with_restart ships-server.service

# On complete removal, clean up users and data
if [ \$1 -eq 0 ]; then
    if getent passwd ships >/dev/null; then
        userdel ships || true
    fi
    if getent passwd shipscmd >/dev/null; then
        userdel shipscmd || true
    fi
    rm -rf /var/lib/ships
    rm -rf /home/shipscmd
fi

%changelog
* $(date '+%a %b %d %Y') SHIPS2-Go Project <ships-go@example.com> - ${VERSION}-1
- Initial RPM release
- Secure password escrow and BitLocker key management
- Complete audit logging and monitoring integration
- Production-ready deployment automation

EOF

# Create source tarball
mkdir -p rpm-build/SOURCES
tar -czf rpm-build/SOURCES/${PACKAGE_NAME}-${VERSION}.tar.gz \
    --transform "s,^,${PACKAGE_NAME}-${VERSION}/," \
    dist/ bin/ deploy/ docs/ README.md RELEASE_NOTES_v1.0.0.md

# Build RPM
rpmbuild --define "_topdir $(pwd)/rpm-build" -ba rpm-build/SPECS/${PACKAGE_NAME}.spec

# Copy built packages
cp rpm-build/RPMS/${ARCH}/${PACKAGE_NAME}-${VERSION}-1.*.${ARCH}.rpm .
cp rpm-build/SRPMS/${PACKAGE_NAME}-${VERSION}-1.*.src.rpm .

echo "RPM packages built:"
echo "  Binary: ${PACKAGE_NAME}-${VERSION}-1.*.${ARCH}.rpm"
echo "  Source: ${PACKAGE_NAME}-${VERSION}-1.*.src.rpm"

# Verify package
rpm -qip ${PACKAGE_NAME}-${VERSION}-1.*.${ARCH}.rpm
rpm -qlp ${PACKAGE_NAME}-${VERSION}-1.*.${ARCH}.rpm