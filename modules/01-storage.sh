#!/bin/bash
# Module: persistent storage — btrfs, snapshots, zram swap.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Modul: storage"
install_packages btrfs-progs snapper zram-tools

# Real zram swap config (compressed RAM swap).
cat > "$ROOTFS/etc/default/zramswap" <<'CFG'
ALGO=zstd
SIZE=1024
PRIORITY=100
CFG

# Example btrfs snapshot policy used by snapper.
mkdir -p "$ROOTFS/etc/snapper/configs"
cat > "$ROOTFS/etc/snapper/configs/xuzuntu" <<'CFG'
SUBVOLUME="/"
FSTYPE=btrfs
ALLOW_GROUPS=
ALLOW_USERS=
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="10"
CFG

log "Modul: storage kész"
