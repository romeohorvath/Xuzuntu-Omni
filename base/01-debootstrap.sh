#!/bin/bash
# Step 1: build the real base system from Ubuntu packages with debootstrap.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

require_root
MIRROR="${MIRROR:-$(mirror_for_arch "$ARCH")}"

log "Base system: debootstrap $SUITE ($ARCH) from $MIRROR"
if [ -f "$ROOTFS/etc/os-release" ]; then
    log "Rootfs already exists, skipping debootstrap (use --clean to rebuild)."
    exit 0
fi

mkdir -p "$ROOTFS"
debootstrap \
    --arch="$ARCH" \
    --variant=minbase \
    --include=systemd,udev,systemd-sysv,dbus,locales,ca-certificates,apt-utils,iproute2,iputils-ping,less,vim-tiny,whiptail \
    "$SUITE" "$ROOTFS" "$MIRROR"

log "Setting up sources (main/universe/restricted/multiverse + updates/security)"
cat > "$ROOTFS/etc/apt/sources.list" <<APT_EOF
deb $(mirror_for_arch "$ARCH") $SUITE main universe restricted multiverse
deb $(mirror_for_arch "$ARCH") $SUITE-updates main universe restricted multiverse
deb $(mirror_for_arch "$ARCH") $SUITE-security main universe restricted multiverse
APT_EOF

apt_retry update -qq
log "Base system ready: $ROOTFS"
