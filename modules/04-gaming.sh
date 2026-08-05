#!/bin/bash
# Module: gaming — Vulkan/Mesa drivers, GameMode, Lutris, Steam.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Module: gaming"
install_packages \
    mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
    vulkan-tools gamemode mangohud lutris gamescope

# Steam needs the 32-bit (i386) library world — enable the multiarch
# universe on amd64, then install it as a separate step so any failure
# (mirror flake, missing index, conflict) just skips Steam, not the build.
if [ "$ARCH" = "amd64" ]; then
    chroot_exec dpkg --add-architecture i386
    if apt_retry update -o Acquire::Retries=5 -qq && available libc6:i386 && available steam-installer; then
        if apt_retry install -y --no-install-recommends -o Dpkg::Options::=--force-confold steam-installer; then
            log "    steam-installer: OK (i386 multiarch enabled)"
        else
            log "    steam-installer: skipped (i386 dependencies unavailable)"
        fi
    else
        log "    steam-installer: skipped (i386 index/package unavailable)"
    fi
else
    log "    steam-installer: skipped (not available on $ARCH)"
fi

# Real GameMode configuration.
cat > "$ROOTFS/etc/gamemode.ini" <<'CFG'
[general]
reaper_freq=5
desiredgov=performance

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0

[custom]
start=notify-send "GameMode active" &
end=notify-send "GameMode stopped" &
CFG

log "Module: gaming ready"
