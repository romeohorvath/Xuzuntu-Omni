#!/bin/bash
# Xuzuntu Omni — real, Ubuntu-based live distribution builder.
# Usage: sudo ./build.sh [options]
set -euo pipefail
cd "$(dirname "$0")"

usage() {
    cat <<'HELP'
Usage: sudo ./build.sh [options]

Options:
  --arch=amd64|arm64      Target architecture (default: host architecture)
  --suite=noble           Ubuntu base release
  --desktops=all|none|a,b,c
                          Desktop environments: all = every existing
                          desktop/window manager (default), none = CLI only
  --modules=a,b,c         Modules (see modules/), empty = none
  --minimal               Fast CLI build: no modules, no desktop
  --out=DIR               Output directory (default: ./out)
  --work=DIR              Working directory (default: ./work)
  --clean                 Wipe work/ and rebuild
  --skip-base             Reuse existing rootfs (fast iteration)
  --skip-iso              Stop after squashfs (no ISO)
HELP
}

# --- Arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --arch=*)      export ARCH="${1#*=}" ;;
        --suite=*)     export SUITE="${1#*=}" ;;
        --desktops=*)  export DESKTOPS="${1#*=}" ;;
        --desktop=*)   export DESKTOPS="${1#*=}" ;;
        --modules=*)   export MODULES="${1#*=}" ;;
        --minimal)     export MODULES="" DESKTOPS=none ;;
        --out=*)       export OUT_DIR="${1#*=}" ;;
        --work=*)      export WORK_DIR="${1#*=}" ;;
        --clean)       CLEAN=1 ;;
        --skip-base)   SKIP_BASE=1 ;;
        --skip-iso)    SKIP_ISO=1 ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

source config/xuzuntu.conf
source scripts/common.sh
require_root

log "=== Xuzuntu Omni $DISTRO_VERSION build ==="
log "arch=$ARCH suite=$SUITE desktops=${DESKTOPS:-<none>}"
log "modules=${MODULES:-<none>}"
log "work=$WORK_DIR out=$OUT_DIR"

if [ -n "${CLEAN:-}" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi
mkdir -p "$WORK_DIR" "$OUT_DIR"

# 1) Base system
if [ -n "${SKIP_BASE:-}" ] && [ -d "$ROOTFS" ]; then
    log "base skipped (--skip-base)"
else
    bash base/01-debootstrap.sh
fi

# 1.5) Mount /proc /sys /dev for package postinst scripts,
#      then refresh the apt lists for the modules.
mount_essential
apt_retry update -qq

# 2) Modules
for f in modules/*.sh; do
    name="$(basename "$f" .sh | sed 's/^[0-9]*-//')"
    case ",${MODULES}," in
        *",$name,"*) bash "$f" ;;
    esac
done

# 2.5) Always finalize (os-release, user, cleanup), then unmount the
#      chroot filesystems so the squashfs does not capture them.
bash modules/99-finalize.sh
umount_essential

# 3) Live system
bash live/01-kernel.sh
bash live/02-squashfs.sh
bash live/03-bootfiles.sh
if [ -z "${SKIP_ISO:-}" ]; then
    bash live/04-iso.sh
else
    log "ISO skipped (--skip-iso)"
fi

log "=== Build finished ==="
