#!/bin/bash
# Module: desktop — EVERY existing desktop environment in ONE system (Omni).
# Works immediately after login: LightDM automatic login,
# every desktop and app available. No choice — everything included.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

DESKTOPS="${DESKTOPS-gnome,kde,xfce,lxqt,cinnamon,mate,budgie,i3}"
if [ -z "$DESKTOPS" ] || [ "$DESKTOPS" = "none" ]; then
    log "Module: desktop skipped (DESKTOPS=none)"
    exit 0
fi

log "Module: desktop — all desktop worlds: $DESKTOPS"

install_de() {
    local name="$1" pkgs=""
    case "$name" in
        gnome)    pkgs="ubuntu-desktop-minimal" ;;
        kde)      pkgs="kde-plasma-desktop" ;;
        xfce)     pkgs="xubuntu-desktop" ;;
        lxqt)     pkgs="lxqt" ;;
        cinnamon) pkgs="cinnamon-desktop-environment" ;;
        mate)     pkgs="mate-desktop-environment" ;;
        budgie)   pkgs="budgie-desktop" ;;
        i3)       pkgs="i3 i3blocks" ;;
        *) log "    unknown desktop skipped: $name"; return 0 ;;
    esac
    log "    installing: $name ($pkgs)"
    # shellcheck disable=SC2086
    install_packages_recommends $pkgs
}

IFS=',' read -ra DE_LIST <<< "$DESKTOPS"
for d in "${DE_LIST[@]}"; do
    [ -n "$d" ] || continue
    install_de "$d"
done

# X server + display manager (lightdm + autologin)
install_packages_recommends xserver-xorg lightdm lightdm-gtk-greeter xdg-utils dbus-x11

# Universal apps — every world usable immediately
if [ "${OMNI_APPS:-1}" = "1" ]; then
    log "    universal apps (browser, office, media, dev)"
    install_packages_recommends firefox libreoffice gimp vlc htop git tmux xterm curl
else
    log "    universal apps skipped (OMNI_APPS=0)"
fi

# LightDM as default + automatic login
echo "lightdm shared/default-x-display-manager select lightdm" | chroot_exec debconf-set-selections 2>/dev/null || true
mkdir -p "$ROOTFS/etc/lightdm"
DEFAULT_SESSION="xfce"
for cand in xfce gnome plasma lxqt cinnamon mate budgie-desktop i3; do
    if [ -f "$ROOTFS/usr/share/xsessions/$cand.desktop" ]; then
        DEFAULT_SESSION="$cand"
        break
    fi
done
cat > "$ROOTFS/etc/lightdm/lightdm.conf" <<CFG
[Seat:*]
autologin-user=xuzuntu
autologin-session=$DEFAULT_SESSION
user-session=$DEFAULT_SESSION
greeter-session=lightdm-gtk-greeter
CFG
echo "/usr/sbin/lightdm" > "$ROOTFS/etc/X11/default-display-manager"
chroot_exec systemctl enable lightdm >/dev/null 2>&1 || true
chroot_exec systemctl disable gdm gdm3 sddm >/dev/null 2>&1 || true

log "Module: desktop ready — autologin: $DEFAULT_SESSION, all desktops installed"
