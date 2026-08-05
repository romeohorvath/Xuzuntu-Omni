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
grub-mkrescue -o "$OUT_DIR/$ISO_NAME" "$STAGE" -- -volid "XUZUNTU"

ls -lh "$OUT_DIR/$ISO_NAME"
sha256sum "$OUT_DIR/$ISO_NAME"
log "Ready: $OUT_DIR/$ISO_NAME"
