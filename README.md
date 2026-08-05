# Xuzuntu Omni

**Xuzuntu Omni** egy valódi, Ubuntu-alapú Linux disztribúció: a build rendszer valódi csomagokból (debootstrap + Ubuntu archivum) épít egy bootolható live ISO-t — nem szimuláció.

## Mi ez valójában?

- **Valódi bázis:** Ubuntu 24.04 LTS (Noble) rendszertöltés `debootstrap`-tal, a hivatalos Ubuntu mirrorokról.
- **Valódi live rendszer:** kernel + initramfs (`live-boot`, `live-config-systemd`), a teljes rootfs squashfs-ban, GRUB bootolással.
- **Valódi ISO:** `grub-mkrescue` — amd64-en BIOS+UEFI hibrid, arm64-en UEFI ISO.
- **Valódi modulok:** az „Omni" rétegek nem szövegek, hanem ténylegesen telepített csomagok + konfigurációk.
- **Valódi CI:** GitHub Actions építi az ISO-t minden push után, QEMU boot teszttel.

## Építés helyben

```bash
sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin
sudo ./build.sh --arch=amd64
```

Az eredmény: `out/xuzuntu-omni-1.0-amd64.iso` (x86_64, XFCE asztallal).
A GitHub CI ugyanezt a teljes asztali x86_64 ISO-t építi és artifact/release formájában letölthető.

### Opciók

| Opció | Leírás | Alapértelmezés |
|---|---|---|
| `--arch=amd64\|arm64` | Cél architektúra | gazdagép architektúrája |
| `--suite=noble` | Ubuntu bázis kiadás | `noble` |
| `--desktop=xfce\|gnome\|kde\|none` | Asztali környezet | `xfce` |
| `--modules=storage,cloud,...` | Modulok (lásd `modules/`) | mind |
| `--minimal` | CLI-only, gyors build | — |
| `--clean` | `work/` törlése és teljes újraépítés | — |
| `--skip-base` | Meglévő rootfs újrahasználata | — |
| `--skip-iso` | Squashfs után megáll | — |

## Modulok (valós csomagok)

| Modul | Mit telepít valójában |
|---|---|
| `storage` | `btrfs-progs`, `snapper` (btrfs snapshot politika), `zram-tools` (zstd tömörített RAM swap) |
| `cloud` | `rclone`, `sshfs`, `rsync`, `curl`, `wget` |
| `ai-ml` | `python3-pip/venv`, `numpy`, `pandas`, `scikit-learn` + `omni-ai` venv helper |
| `gaming` | Mesa/Vulkan driverek, `gamemode`, `mangohud`, `lutris`, `steam-installer`, `gamescope` |
| `network-security` | `nmap`, `wireshark`, `aircrack-ng`, `tcpdump`, `firewalld`, `openvpn`, `wireguard-tools`, `ufw` |
| `webui` | Cockpit rendszerkonzol (`cockpit`, `cockpit-storaged`, `cockpit-packagekit`, `cockpit-networkmanager`) |
| `desktop` | `xubuntu-desktop` / `ubuntu-desktop-minimal` / KDE Plasma a `DESKTOP` választás szerint |

Az architektúrán nem elérhető csomagokat a build automatikusan kihagyja (pl. `steam-installer` arm64-en).

## Bootolás

1. Írd az ISO-t USB-re: `sudo dd if=xuzuntu-omni-1.0-amd64.iso of=/dev/sdX bs=4M status=progress`
2. Bootolj róla (UEFI vagy Legacy BIOS — amd64-en mindkettő).
3. Live bejelentkezés: felhasználó `xuzuntu`, jelszó `xuzuntu` (root is `xuzuntu`).
4. Hálózat: NetworkManager automatikusan indul; `cockpit` elérhető `http://<gép>:9090` címen.

> A jelszavak fejlesztői/live buildhez valók — telepítés után azonnal változtasd meg.

## CI (GitHub Actions)

Minden `main` push-ra a CI **valódi asztali x86_64 ISO-t** épít (`--arch=amd64 --desktop=xfce`, minden modullal):

1. `debootstrap` + live rendszer + `grub-mkrescue` (BIOS+UEFI hibrid ISO),
2. ellenőrzi: ISO struktúra (`xorriso`), XFCE/LightDM jelenlét a squashfs-ben,
3. feltölti artifact-ként (`xuzuntu-omni-desktop-x86_64`),
4. QEMU-ban boot teszt (login prompt elérése, best-effort),
5. `v*` tag-eknél GitHub Release-t hoz létre a letölthető ISO-val.

## Projektstruktúra

```
build.sh                 # orchestrator
config/xuzuntu.conf       # build konfiguráció
scripts/common.sh         # közös segédfüggvények (chroot, apt, mirror)
base/01-debootstrap.sh    # valódi bázis rendszer
modules/*.sh              # valódi modulok (csomagok + konfig)
live/*.sh                 # kernel, squashfs, GRUB, ISO
.github/workflows/build.yml
```

## Állapot

- [x] Valódi debootstrap bázis (amd64 + arm64)
- [x] Live rendszer (kernel, initramfs, squashfs)
- [x] Bootolható ISO (BIOS+UEFI / UEFI)
- [x] Modulok valós csomagokkal
- [x] CI build + QEMU boot teszt
- [ ] Telepítő (Calamares) — roadmap
- [ ] Xuzuntu csomagarchívum / saját repo
