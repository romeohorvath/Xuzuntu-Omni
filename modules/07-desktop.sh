#!/bin/bash
# Module: desktop environment selection (xfce | gnome | kde | none).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

if [ "$DESKTOP" = "none" ]; then
    log "Modul: desktop kihagyva (DESKTOP=none)"
    exit 0
fi

log "Modul: desktop ($DESKTOP)"
case "$DESKTOP" in
    xfce)
        chroot_exec apt-get install -y xubuntu-desktop
        ;;
    gnome)
        chroot_exec apt-get install -y ubuntu-desktop-minimal
        ;;
    kde)
        chroot_exec apt-get install -y kde-plasma-desktop sddm
        ;;
    *)
        echo "Ismeretlen DESKTOP: $DESKTOP (xfce|gnome|kde|none)" >&2
        exit 1
        ;;
esac

log "Modul: desktop kész"
