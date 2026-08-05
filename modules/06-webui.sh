#!/bin/bash
# Module: web UI management — Cockpit system console.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Modul: webui"
install_packages cockpit cockpit-storaged cockpit-packagekit cockpit-networkmanager
chroot_exec systemctl enable cockpit.socket >/dev/null 2>&1 || true

log "Modul: webui kész"
