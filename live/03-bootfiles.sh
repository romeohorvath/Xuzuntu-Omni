#!/bin/bash
# Live step 3: GRUB boot configuration for BIOS+UEFI (grub-mkrescue).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Live: boot konfiguráció"
mkdir -p "$STAGE/boot/grub"
cat > "$STAGE/boot/grub/grub.cfg" <<GRUB
set default=0
set timeout=5
set color_normal=white/black
set color_highlight=green/black

menuentry "Xuzuntu Omni $DISTRO_VERSION - Live" {
    linux /live/vmlinuz boot=live components quiet splash console=ttyS0
    initrd /live/initrd.img
}

menuentry "Xuzuntu Omni $DISTRO_VERSION - Live (nomodeset)" {
    linux /live/vmlinuz boot=live components quiet splash nomodeset
    initrd /live/initrd.img
}

menuentry "Xuzuntu Omni $DISTRO_VERSION - Live (alap, angol)" {
    linux /live/vmlinuz boot=live components quiet splash locales=en_US.UTF-8 keyboard-layouts=us
    initrd /live/initrd.img
}
GRUB
log "Live: boot konfiguráció kész"
