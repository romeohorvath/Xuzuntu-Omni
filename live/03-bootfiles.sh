#!/bin/bash
# Live step 3: GRUB boot configuration for BIOS+UEFI (grub-mkrescue).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Live: boot configuration"
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

menuentry "Xuzuntu Omni $DISTRO_VERSION - Live (basic)" {
    linux /live/vmlinuz boot=live components quiet splash locales=en_US.UTF-8 keyboard-layouts=us
    initrd /live/initrd.img
}
GRUB
# Generate GRUB BIOS boot image (eltorito.img)
grub-mkimage     -O i386-pc     -o "$STAGE/boot/grub/eltorito.img"     -p "/boot/grub"     biosdisk part_gpt part_msdos fat iso9660 linux normal configfile loopback search

# Generate GRUB UEFI boot image (efiboot.img)
grub-mkimage     -O x86_64-efi     -o "$STAGE/boot/grub/efiboot.img"     -p "/boot/grub"     fat iso9660 part_gpt part_msdos linux normal configfile loopback search efi_gop efi_uga

log "Live: boot configuration ready"
