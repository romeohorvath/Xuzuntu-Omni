#!/bin/bash
# Live step 1: kernel + initramfs + live-boot tooling inside the rootfs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Live: kernel + live-boot"
# The finalize module cleans the apt lists; refresh them before installing.
apt_retry update -o Acquire::Retries=5 -qq
apt_retry install -y \
    linux-image-generic initramfs-tools \
    live-boot live-config-systemd \
    network-manager openssh-server sudo
# Keep the squashfs small: drop the freshly downloaded lists and caches.
chroot_exec apt-get clean >/dev/null 2>&1 || true
rm -rf "$ROOTFS"/var/lib/apt/lists/* 2>/dev/null || true

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
log "Live: kernel + initramfs staged"
