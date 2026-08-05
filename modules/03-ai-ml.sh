#!/bin/bash
# Module: AI/ML — Python toolchain and local inference helpers.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Modul: ai-ml"
install_packages python3 python3-pip python3-venv python3-numpy python3-pandas python3-scikit-learn

# Real helper: create the omni AI/ML virtualenv on first run.
cat > "$ROOTFS/usr/local/sbin/omni-ai" <<'SH'
#!/bin/bash
set -euo pipefail
VENV="${VENV:-$HOME/.omni-ai}"
if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
fi
# shellcheck disable=SC1090
source "$VENV/bin/activate"
pip install --upgrade pip
if [ $# -eq 0 ]; then
    echo "omni-ai: aktív venv: $VENV. Futtasd: omni-ai install torch"
    exit 0
fi
case "$1" in
    install) shift; pip install "$@" ;;
    *) exec "$@" ;;
esac
SH
chroot_exec chmod +x /usr/local/sbin/omni-ai

log "Modul: ai-ml kész"
