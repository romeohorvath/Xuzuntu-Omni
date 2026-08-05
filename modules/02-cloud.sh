#!/bin/bash
# Module: cloud integration — rclone, sshfs, sync tooling.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Module: cloud"
install_packages rclone sshfs rsync curl wget

# Sensible defaults for remote sync tooling.
cat > "$ROOTFS/etc/rclone.conf" <<'CFG'
# Xuzuntu Omni default rclone config.
# Add remotes with: rclone config
[omni]
type = local
CFG

log "Module: cloud ready"
