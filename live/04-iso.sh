#!/bin/bash
# Live step 4: build the final bootable ISO with grub-mkrescue.
# amd64: BIOS+UEFI hibrid ISO | arm64: UEFI ISO.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

ISO_NAME="xuzuntu-omni-$DISTRO_VERSION-$ARCH.iso"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/$ISO_NAME"

log "Live: creating ISO ($ISO_NAME)"
# Use xorriso directly in mkisofs emulation mode with ISO 9660:1999 (level 3)
# to support files >4 GiB (the squashfs). grub-mkrescue passes args in native
# xorriso mode where -file_size_limit off does not take effect in time.
xorriso -as mkisofs \
    -iso-level 3 \
    -volid "XUZUNTU" \
    -eltorito-boot boot/grub/eltorito.img \
    -eltorito-catalog boot/grub/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efiboot.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -o "$OUT_DIR/$ISO_NAME" "$STAGE"

ls -lh "$OUT_DIR/$ISO_NAME"
sha256sum "$OUT_DIR/$ISO_NAME"
log "Ready: $OUT_DIR/$ISO_NAME"
