#!/bin/bash
# Module: desktop — EVERY existing desktop environment and window manager
# in the Ubuntu universe, all in ONE system (Omni). No choice, everything
# included: LightDM automatic login puts you straight into the desktop,
# every session is already installed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

if [ -z "$DESKTOPS" ] || [ "$DESKTOPS" = "none" ]; then
    log "Module: desktop skipped (DESKTOPS=none)"
    exit 0
fi

# "all" expands to the complete desktop universe (config ALL_DESKTOPS).
if [ "$DESKTOPS" = "all" ]; then
    DESKTOPS="$ALL_DESKTOPS"
fi

log "Module: desktop — every desktop world: $DESKTOPS"

# Install one desktop world; a single conflicting/unavailable desktop must
# not kill the whole build (each attempt is a separate apt transaction).
try_install() {
    local name="$1"; shift
    log "    installing: $name ($*)"
    if apt_retry install -y -o Dpkg::Options::=--force-confold "$@"; then
        log "      $name: OK"
    else
        log "      $name: SKIPPED (unavailable or conflicting here)"
    fi
}

install_de() {
    local name="$1"
    case "$name" in
        gnome)          try_install gnome ubuntu-desktop-minimal ;;
        kde)            try_install kde kde-plasma-desktop ;;
        xfce)           try_install xfce xubuntu-desktop ;;
        lxqt)           try_install lxqt lubuntu-desktop ;;
        lxde)           try_install lxde lxde ;;
        mate)           try_install mate ubuntu-mate-desktop ;;
        budgie)         try_install budgie ubuntu-budgie-desktop ;;
        cinnamon)       try_install cinnamon cinnamon-desktop-environment ;;
        unity)          try_install unity ubuntu-unity-desktop unity-session ;;
        sugar)          try_install sugar sugar-session sucrose ;;
        i3)             try_install i3 i3 i3blocks i3status ;;
        sway)           try_install sway sway ;;
        openbox)        try_install openbox openbox ;;
        fluxbox)        try_install fluxbox fluxbox ;;
        icewm)          try_install icewm icewm ;;
        awesome)        try_install awesome awesome ;;
        dwm)            try_install dwm dwm ;;
        xmonad)         try_install xmonad xmonad ;;
        enlightenment)  try_install enlightenment enlightenment ;;
        
        bspwm)          try_install bspwm bspwm ;;
        herbstluftwm)   try_install herbstluftwm herbstluftwm ;;
        ratpoison)      try_install ratpoison ratpoison ;;
        twm)            try_install twm twm ;;
        fvwm)           try_install fvwm fvwm ;;
        jwm)            try_install jwm jwm ;;
        pekwm)          try_install pekwm pekwm ;;
        afterstep)      try_install afterstep afterstep ;;
        spectrwm)       try_install spectrwm spectrwm ;;
        matchbox)       try_install matchbox matchbox-window-manager ;;
        weston)         try_install weston weston ;;
        labwc)          try_install labwc labwc ;;
        wayfire)        try_install wayfire wayfire ;;
        *) log "    unknown desktop skipped: $name"; return 0 ;;
    esac
}

IFS=',' read -ra DE_LIST <<< "$DESKTOPS"
for d in "${DE_LIST[@]}"; do
    [ -n "$d" ] || continue
    install_de "$d"
done

# Every window manager gets a login-screen session entry, even those whose
# upstream ships none (dwm, twm, ...), so the whole universe is selectable.
mkdir -p "$ROOTFS/usr/share/xsessions" "$ROOTFS/usr/share/wayland-sessions"
gen_session() {
    local id="$1" exec_cmd="$2" dir="$3"
    if [ -f "$ROOTFS/$dir/$id.desktop" ]; then return 0; fi
    cat > "$ROOTFS/$dir/$id.desktop" <<EOF
[Desktop Entry]
Name=$id
Comment=$id session (Xuzuntu Omni)
Exec=$exec_cmd
Type=Application
EOF
}
# xsessions entries for window managers that do not ship one.
for spec in \
    "cinnamon:cinnamon-session" "icewm:icewm-session" \
    "dwm:dwm" "twm:twm" "fvwm:fvwm" "ratpoison:ratpoison" \
    "bspwm:bspwm" "herbstluftwm:herbstluftwm" \
    "jwm:jwm" "pekwm:pekwm" "afterstep:afterstep" \
    "spectrwm:spectrwm" "matchbox:matchbox-window-manager"; do
    id="${spec%%:*}"; bin="${spec##*:}"
    if chroot_exec command -v "$bin" >/dev/null 2>&1; then
        gen_session "$id" "$bin" usr/share/xsessions
    fi
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
for cand in xfce gnome plasma lxqt cinnamon mate budgie-desktop unity i3 openbox; do
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

N_SESSIONS="$(ls "$ROOTFS/usr/share/xsessions/"*.desktop 2>/dev/null | wc -l)"
N_WAY="$(ls "$ROOTFS/usr/share/wayland-sessions/"*.desktop 2>/dev/null | wc -l)"
log "Module: desktop ready — $N_SESSIONS X sessions + $N_WAY Wayland sessions, autologin: $DEFAULT_SESSION"
