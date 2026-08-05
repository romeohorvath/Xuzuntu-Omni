#!/bin/bash
# Shared helpers for Xuzuntu Omni build scripts.
# Source this after config/xuzuntu.conf.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WORK_DIR="${WORK_DIR:-$REPO_ROOT/work}"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/out}"
ROOTFS="$WORK_DIR/rootfs"
# shellcheck disable=SC2034 # used by live/*.sh
STAGE="$WORK_DIR/iso"

log() { echo "[$(date +%H:%M:%S)] $*"; }

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: root privileges required (debootstrap/chroot)." >&2
        exit 1
    fi
}

mirror_for_arch() {
    case "${1:-$ARCH}" in
        amd64|i386) echo "http://archive.ubuntu.com/ubuntu/" ;;
        *)          echo "http://ports.ubuntu.com/ubuntu-ports/" ;;
    esac
}

# Mount /proc, /sys and /dev into the rootfs so package postinst scripts
# (e.g. OpenJDK, LibreOffice) work inside the chroot.
mount_essential() {
    mkdir -p "$ROOTFS/proc" "$ROOTFS/dev/pts" "$ROOTFS/sys"
    mount -t proc proc "$ROOTFS/proc" >/dev/null 2>&1 || true
    mount --bind /sys "$ROOTFS/sys" >/dev/null 2>&1 || true
    mount --bind /dev "$ROOTFS/dev" >/dev/null 2>&1 || true
    mount --bind /dev/pts "$ROOTFS/dev/pts" >/dev/null 2>&1 || true
}

# Unmount before the live image steps so the squashfs stays clean.
umount_essential() {
    umount "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/sys" "$ROOTFS/proc" >/dev/null 2>&1 || true
}

# Run apt-get inside the chroot with retries (Ubuntu mirrors occasionally
# serve a mid-sync index; a quick retry fixes it).
apt_retry() {
    local n=0
    until chroot_exec apt-get "$@"; do
        n=$((n+1))
        if [ "$n" -ge 3 ]; then
            echo "ERROR: apt-get $* failed 3 times" >&2
            return 1
        fi
        log "    apt retry $n/3 after failure: apt-get $*"
        sleep 5
    done
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

# Install packages WITH recommends (desktop metapackages need them).
install_packages_recommends() {
    local avail=() p
    for p in "$@"; do
        if available "$p"; then
            avail+=("$p")
        else
            log "    skipped (not available on this architecture): $p"
        fi
    done
    if [ "${#avail[@]}" -gt 0 ]; then
        apt_retry install -y -o Dpkg::Options::=--force-confold "${avail[@]}"
    fi
}

# Install packages, skipping any that do not exist for this architecture.
install_packages() {
    local avail=() p
    for p in "$@"; do
        if available "$p"; then
            avail+=("$p")
        else
            log "    skipped (not available on this architecture): $p"
        fi
    done
    if [ "${#avail[@]}" -gt 0 ]; then
        apt_retry install -y --no-install-recommends -o Dpkg::Options::=--force-confold "${avail[@]}"
    elif [ $# -gt 0 ]; then
        echo "WARNING: no packages could be installed ($*)" >&2
        echo "         (missing apt lists? run: chroot_exec apt-get update)" >&2
    fi
}
