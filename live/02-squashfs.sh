#!/bin/bash
# Live step 2: compress the whole rootfs into a squashfs image.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Live: compressing squashfs"
mkdir -p "$STAGE/live"
rm -f "$STAGE/live/filesystem.squashfs"
mksquashfs "$ROOTFS" "$STAGE/live/filesystem.squashfs" \
    -comp xz -noappend -no-progress \
    -e boot var/cache/apt/archives
log "Live: squashfs ready"
