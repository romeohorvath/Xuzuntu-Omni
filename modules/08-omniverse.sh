#!/bin/bash
# Module: omniverse — every distribution world in ONE system.
# APT (Debian/Ubuntu) + Flatpak (universal) + Snap (Canonical)
# + Podman/Docker containers + Distrobox (Arch, Fedora, Alpine... any distro).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Module: omniverse — every distro world"
install_packages_recommends flatpak snapd podman docker.io distrobox fuse3

# Flatpak: Flathub (universal app world)
chroot_exec flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || \
    log "    (adding Flathub remote skipped — on first boot of the live system run: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo)"

# Snap: enable the service
chroot_exec systemctl enable snapd >/dev/null 2>&1 || true

# Enable the Docker daemon (podman is the base, docker.io optional)
chroot_exec systemctl enable docker >/dev/null 2>&1 || true

# Distrobox: user in docker/podman group (rootless containers)
chroot_exec usermod -aG docker xuzuntu >/dev/null 2>&1 || true

# omni — the entire Linux universe in a single command
cat > "$ROOTFS/usr/local/bin/omni" <<'SH'
#!/bin/bash
# omni — Xuzuntu Omni: the whole Linux universe in one system.
echo "═ Xuzuntu Omni — the Linux universe in one system ═"
echo
echo "Desktop worlds — every X session, all installed, available immediately:"
for s in /usr/share/xsessions/*.desktop; do
    [ -f "$s" ] || continue
    name="$(basename "$s" .desktop)"
    desc="$(sed -n 's/^Name=//p' "$s" | head -1)"
    printf "  • %-16s %s\n" "$name" "$desc"
done
echo "Wayland sessions:"
for s in /usr/share/wayland-sessions/*.desktop; do
    [ -f "$s" ] || continue
    name="$(basename "$s" .desktop)"
    desc="$(sed -n 's/^Name=//p' "$s" | head -1)"
    printf "  • %-16s %s\n" "$name" "$desc"
done
echo
echo "Package worlds:"
printf "  • APT (Debian/Ubuntu) — %s packages\n" "$(dpkg -l 2>/dev/null | grep -c '^ii')"
flatpak --version >/dev/null 2>&1 && echo "  • Flatpak (Flathub, universal) — $(flatpak --version)"
snap version >/dev/null 2>&1 && echo "  • Snap (Canonical) — $(snap version 2>/dev/null | head -1)"
podman --version >/dev/null 2>&1 && echo "  • Podman — $(podman --version)"
docker --version >/dev/null 2>&1 && echo "  • Docker — $(docker --version)"
distrobox --version >/dev/null 2>&1 && echo "  • Distrobox — any distro in containers: $(distrobox --version | head -1)"
echo
echo "Any distro immediately (Arch, Fedora, Debian, Alpine...):"
echo "  distrobox-create --name arch --image archlinux:latest"
echo "  distrobox-enter arch"
echo
echo "Desktop worlds are also listed on the login screen (after logging out)."
SH
chroot_exec chmod +x /usr/local/bin/omni

log "Module: omniverse ready — APT + Flatpak + Snap + Podman/Docker + Distrobox"
