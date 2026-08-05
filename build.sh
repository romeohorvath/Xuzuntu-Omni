#!/bin/bash
# Xuzuntu Omni — valódi, Ubuntu-alapú live disztribúció építő.
# Használat: sudo ./build.sh [opciók]
set -euo pipefail
cd "$(dirname "$0")"

usage() {
    cat <<'HELP'
Használat: sudo ./build.sh [opciók]

Opciók:
  --arch=amd64|arm64      Cél architektúra (alapértelmezés: gazdagép architektúrája)
  --suite=noble           Ubuntu bázis kiadás
  --desktop=xfce|gnome|kde|none
                          Asztali környezet (alapértelmezés: xfce)
  --modules=a,b,c         Modulok listája (lásd modules/), üres = nincs
  --minimal               Gyors CLI build: modulok nélkül, desktop nélkül
  --out=DIR               Kimeneti könyvtár (alapértelmezés: ./out)
  --work=DIR              Munkakönyvtár (alapértelmezés: ./work)
  --clean                 Törli a work/ könyvtárat és újraépít
  --skip-base             Újrahasználja a meglévő rootfs-t (gyors iteráció)
  --skip-iso              Squashfs után megáll (nem készít ISO-t)
HELP
}

# --- Argumentumok ---
while [ $# -gt 0 ]; do
    case "$1" in
        --arch=*)      export ARCH="${1#*=}" ;;
        --suite=*)     export SUITE="${1#*=}" ;;
        --desktop=*)   export DESKTOP="${1#*=}" ;;
        --modules=*)   export MODULES="${1#*=}" ;;
        --minimal)     export MODULES="" DESKTOP=none ;;
        --out=*)       export OUT_DIR="${1#*=}" ;;
        --work=*)      export WORK_DIR="${1#*=}" ;;
        --clean)       CLEAN=1 ;;
        --skip-base)   SKIP_BASE=1 ;;
        --skip-iso)    SKIP_ISO=1 ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Ismeretlen opció: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

source config/xuzuntu.conf
source scripts/common.sh
require_root

log "=== Xuzuntu Omni $DISTRO_VERSION build ==="
log "arch=$ARCH suite=$SUITE desktop=$DESKTOP"
log "modules=${MODULES:-<nincs>}"
log "work=$WORK_DIR out=$OUT_DIR"

if [ -n "${CLEAN:-}" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi
mkdir -p "$WORK_DIR" "$OUT_DIR"

# 1) Base rendszer
if [ -n "${SKIP_BASE:-}" ] && [ -d "$ROOTFS" ]; then
    log "base kihagyva (--skip-base)"
else
    bash base/01-debootstrap.sh
fi

# 1.5) apt listák a modulokhoz
log "apt listák frissítése (chroot)"
chroot_exec apt-get update -qq

# 2) Modulok
for f in modules/*.sh; do
    name="$(basename "$f" .sh | sed 's/^[0-9]*-//')"
    case ",${MODULES}," in
        *",$name,"*) bash "$f" ;;
    esac
done

# 2.5) Mindig finalize (os-release, felhasználó, tisztítás)
bash modules/99-finalize.sh

# 3) Live rendszer
bash live/01-kernel.sh
bash live/02-squashfs.sh
bash live/03-bootfiles.sh
if [ -z "${SKIP_ISO:-}" ]; then
    bash live/04-iso.sh
else
    log "ISO kihagyva (--skip-iso)"
fi

log "=== Build befejezve ==="
