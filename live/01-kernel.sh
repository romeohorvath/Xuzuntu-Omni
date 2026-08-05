#!/bin/bash
# Live step 1: kernel + initramfs + live-boot tooling inside the rootfs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Live: kernel + live-boot"
chroot_exec apt-get install -y \
    linux-image-generic initramfs-tools \
    live-boot live-config-systemd \
    network-manager openssh-server sudo

# Regenerate initramfs so live-boot scripts are included.
chroot_exec update-initramfs -u -k all >/dev/null 2>&1 || true

mkdir -p "$STAGE/live"
VMLINUZ="$(find "$ROOTFS/boot" -maxdepth 1 -name "vmlinuz-*" 2>/dev/null | sort -V | tail -1 || true)"
INITRD="$(find "$ROOTFS/boot" -maxdepth 1 -name "initrd.img-*" ! -name "*.dpkg-bak" 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$VMLINUZ" ] || [ -z "$INITRD" ]; then
    echo "Error: kernel/initrd not found in the rootfs" >&2
    exit 1
fi

cp -vL "$VMLINUZ" "$STAGE/live/vmlinuz"
cp -vL "$INITRD" "$STAGE/live/initrd.img"
log "Live: kernel + initramfs a stage-ben"
