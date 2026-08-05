#!/bin/bash
# Module: finalize — identity, users, locales, cleanup.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Modul: finalize"

# Distro identity.
cat > "$ROOTFS/etc/os-release" <<OSEOF
PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)"
NAME="$DISTRO_NAME"
VERSION_ID="$DISTRO_VERSION"
VERSION="$DISTRO_VERSION ($DISTRO_CODENAME)"
VERSION_CODENAME=$DISTRO_CODENAME
ID=xuzuntu
ID_LIKE=ubuntu debian
HOME_URL="https://github.com/romeohorvath/Xuzuntu-Omni"
SUPPORT_URL="https://github.com/romeohorvath/Xuzuntu-Omni"
BUG_REPORT_URL="https://github.com/romeohorvath/Xuzuntu-Omni/issues"
UBUNTU_CODENAME=$SUITE
OSEOF

# Hostname + hosts.
echo "xuzuntu" > "$ROOTFS/etc/hostname"
cat > "$ROOTFS/etc/hosts" <<'HOSTS'
127.0.0.1 localhost
127.0.1.1 xuzuntu

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HOSTS

# Default user + passwords (live/fejlesztői build; éles rendszeren állítsd át).
chroot_exec useradd -m -s /bin/bash -G sudo,adm,audio,video,cdrom,plugdev xuzuntu || true
echo "root:xuzuntu" | chroot_exec chpasswd
echo "xuzuntu:xuzuntu" | chroot_exec chpasswd

# Locale + timezone.
chroot_exec locale-gen en_US.UTF-8 >/dev/null 2>&1 || true
chroot_exec update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo "Etc/UTC" > "$ROOTFS/etc/timezone"
chroot_exec ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Services expected in the live system.
chroot_exec systemctl enable NetworkManager >/dev/null 2>&1 || true
chroot_exec systemctl enable ssh >/dev/null 2>&1 || true

# MOTD.
cat > "$ROOTFS/etc/motd" <<'MOTD'
Xuzuntu Omni 1.0
Ez egy valódi, Ubuntu-alapú live disztribúció.
Bejelentkezés: xuzuntu / xuzuntu
MOTD

# Machine id (fresh per boot).
rm -f "$ROOTFS/etc/machine-id"
: > "$ROOTFS/etc/machine-id"

# Cleanup so the squashfs stays small.
chroot_exec apt-get clean >/dev/null 2>&1 || true
rm -rf "$ROOTFS"/var/lib/apt/lists/* "$ROOTFS"/var/log/* "$ROOTFS"/tmp/* \
       "$ROOTFS"/var/cache/apt/archives/*.deb 2>/dev/null || true

log "Modul: finalize kész"
