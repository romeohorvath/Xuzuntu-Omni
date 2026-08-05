#!/bin/bash
# Shared helpers for Xuzuntu Omni build scripts.
# Source this after config/xuzuntu.conf.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WORK_DIR="${WORK_DIR:-$REPO_ROOT/work}"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/out}"
ROOTFS="$WORK_DIR/rootfs"
# shellcheck disable=SC2034 # live/*.sh használja
STAGE="$WORK_DIR/iso"

log() { echo "[$(date +%H:%M:%S)] $*"; }

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Hiba: root jogosultság szükséges (debootstrap/chroot miatt)." >&2
        exit 1
    fi
}

mirror_for_arch() {
    case "${1:-$ARCH}" in
        amd64|i386) echo "http://archive.ubuntu.com/ubuntu/" ;;
        *)          echo "http://ports.ubuntu.com/ubuntu-ports/" ;;
    esac
}

# Run a command inside the target root filesystem.
chroot_exec() {
    chroot "$ROOTFS" /usr/bin/env \
        DEBIAN_FRONTEND=noninteractive \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        "$@"
}

# True if the package is installable in the target rootfs.
available() {
    local c
    c="$(chroot_exec apt-cache policy "$1" 2>/dev/null | awk -F': ' '/Candidate/{print $2}')"
    [ -n "$c" ] && [ "$c" != "(none)" ]
}

# Install packages, skipping any that do not exist for this architecture.
install_packages() {
    local avail=() p
    for p in "$@"; do
        if available "$p"; then
            avail+=("$p")
        else
            log "    kihagyva (nem elérhető ezen az architektúrán): $p"
        fi
    done
    if [ "${#avail[@]}" -gt 0 ]; then
        chroot_exec apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confold "${avail[@]}"
    elif [ $# -gt 0 ]; then
        echo "FIGYELEM: egyetlen csomag sem telepíthető ($*)" >&2
        echo "         (hiányoznak az apt listák? futtasd: chroot_exec apt-get update)" >&2
    fi
}
