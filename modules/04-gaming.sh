#!/bin/bash
# Module: gaming — Vulkan/Mesa drivers, GameMode, Lutris, Steam.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Module: gaming"
install_packages \
    mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
    vulkan-tools gamemode mangohud lutris steam-installer gamescope

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
