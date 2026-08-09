# Xuzuntu Omni

**Xuzuntu Omni** is a real, Ubuntu-based Linux distribution where **the entire Linux universe lives in a single system**: every existing desktop environment and window manager in the Ubuntu archive (GNOME, KDE, XFCE, LXQt, LXDE, MATE, Budgie, Cinnamon, Unity, Sugar, i3, Sway, Openbox, Fluxbox, IceWM, Awesome, dwm, xmonad, Enlightenment, bspwm, herbstluftwm, JWM, fvwm, twm, ratpoison, Weston, Labwc, Wayfire and more), every package ecosystem (APT, Flatpak, Snap), and any other distribution (via Distrobox/Podman) — all at once, working immediately after login. Not a choice, everything included.

## What this really is

- **Real base:** Ubuntu 24.04 LTS (Noble) bootstrapped with `debootstrap` from the official Ubuntu mirrors.
- **Real live system:** kernel + initramfs (`live-boot`, `live-config-systemd`), the whole rootfs in a squashfs, GRUB boot.
- **Real ISO:** `grub-mkrescue` — BIOS+UEFI hybrid on amd64, UEFI on arm64.
- **Every desktop at once:** all desktop environments and window managers that exist in the Ubuntu archive — GNOME, KDE Plasma, XFCE, LXQt, LXDE, MATE, Budgie, Cinnamon, Unity, Sugar, i3, Sway, Openbox, Fluxbox, IceWM, Awesome, dwm, xmonad, Enlightenment, bspwm, herbstluftwm, JWM, fvwm, twm, ratpoison, Weston, Labwc, Wayfire and more — all installed; automatic login (LightDM autologin) puts you straight into the system.
- **Every distro world:** APT (Debian/Ubuntu) + Flatpak (Flathub) + Snap (Canonical) + Podman/Docker + Distrobox (Arch, Fedora, Alpine... any distro in containers, integrated into the system).
- **Real modules:** the "Omni" layers are actually installed packages and configuration, not placeholder text.
- **Real CI:** GitHub Actions builds the ISO on every push and runs a QEMU boot test.

## Build locally

```bash
sudo apt-get install -y debootstrap squashfs-tools xorriso mtools grub-pc-bin grub-efi-amd64-bin
sudo ./build.sh --arch=amd64
```

Result: `out/xuzuntu-omni-1.0-amd64.iso` — with **every desktop environment and window manager** (the complete `ALL_DESKTOPS` universe) and every package world.
The GitHub CI builds the same full Omni x86_64 ISO and makes it available as an artifact/release.

### Options

| Option | Description | Default |
|---|---|---|
| `--arch=amd64\|arm64` | Target architecture | host architecture |
| `--suite=noble` | Ubuntu base release | `noble` |
| `--desktops=all\|none\|a,b,c` | Desktop worlds: `all` = every existing desktop/window manager (default), `none` = CLI only | `all` |
| `--modules=storage,cloud,...` | Modules (see `modules/`) | all |
| `--minimal` | CLI-only fast build | — |
| `--clean` | Wipe `work/` and rebuild from scratch | — |
| `--skip-base` | Reuse an existing rootfs | — |
| `--skip-iso` | Stop after the squashfs | — |

## Modules (real packages)

| Module | What it actually installs |
|---|---|
| `storage` | `btrfs-progs`, `snapper` (btrfs snapshot policy), `zram-tools` (zstd compressed RAM swap) |
| `cloud` | `rclone`, `sshfs`, `rsync`, `curl`, `wget` |
| `ai-ml` | `python3-pip/venv`, `numpy`, `pandas`, `scikit-learn` + `omni-ai` venv helper |
| `gaming` | Mesa/Vulkan drivers, `gamemode`, `mangohud`, `lutris`, `steam-installer`, `gamescope` |
| `network-security` | `nmap`, `wireshark`, `aircrack-ng`, `tcpdump`, `firewalld`, `openvpn`, `wireguard-tools`, `ufw` |
| `webui` | Cockpit system console (`cockpit`, `cockpit-storaged`, `cockpit-packagekit`, `cockpit-networkmanager`) |
| `desktop` | **Every existing desktop at once** (full `ALL_DESKTOPS`: GNOME, KDE, XFCE, LXQt, LXDE, MATE, Budgie, Cinnamon, Unity, Sugar, i3, Sway, Openbox, Fluxbox, IceWM, Awesome, dwm, xmonad, Enlightenment, bspwm, herbstluftwm, JWM, fvwm, twm, ratpoison, Weston, Labwc, Wayfire, ...) + LightDM autologin + universal apps (Firefox, LibreOffice, GIMP, VLC) |
| `omniverse` | Every distro world: `flatpak` (Flathub), `snapd`, `podman`, `docker.io`, `distrobox` (any distro in containers) + the `omni` command |

Packages unavailable on a given architecture are skipped automatically (e.g. `steam-installer` on arm64).

## Boot

1. Write the ISO to USB: `sudo dd if=xuzuntu-omni-1.0-amd64.iso of=/dev/sdX bs=4M status=progress`
2. Boot from it (UEFI or Legacy BIOS — amd64 supports both).
3. **Automatic login** as `xuzuntu` — you land directly in the desktop with the whole universe available.
4. Network: NetworkManager starts automatically; Cockpit is at `http://<host>:9090`.
5. Run `omni` to see every installed desktop and package world.
6. Want another desktop? Log out and pick a session — but they are all **already installed** in the same system.

> The passwords are for development/live builds — change them immediately after installing.

## CI (GitHub Actions)

On every push to `main`, the CI builds the **full Omni x86_64 ISO** (`--arch=amd64 --desktops=all`, all modules — every existing desktop environment):

1. `debootstrap` + live system + `grub-mkrescue` (BIOS+UEFI hybrid ISO),
2. verifies: ISO structure (`xorriso`), all desktop sessions + LightDM autologin in the squashfs, omniverse tools,
3. uploads it as an artifact (`xuzuntu-omni-desktop-x86_64`),
4. runs a QEMU boot test (reaches the login prompt, best-effort),
5. on `v*` tags it creates a GitHub Release with the downloadable ISO.

## Project layout

```
build.sh                 # orchestrator
config/xuzuntu.conf      # build configuration
scripts/common.sh        # shared helpers (chroot, apt, mirror)
base/01-debootstrap.sh   # real base system
modules/*.sh             # real modules (packages + config)
live/*.sh                # kernel, squashfs, GRUB, ISO
.github/workflows/build.yml
```

## Status

- [x] Real debootstrap base (amd64 + arm64)
- [x] Live system (kernel, initramfs, squashfs)
- [x] Bootable ISO (BIOS+UEFI / UEFI)
- [x] Every existing desktop environment + window manager in one system (full `ALL_DESKTOPS`)
- [x] Every package world (APT, Flatpak, Snap, Podman/Docker, Distrobox)
- [x] CI build + QEMU boot test
- [ ] Installer (Calamares) — roadmap
- [ ] Xuzuntu package archive / own repo

## Contact

- Email: [horvathromeo59@gmail.com](mailto:horvathromeo59@gmail.com)
- Telegram: [@botbite6](https://t.me/botbite6)
- Author: [Horváth Rómeó (romeohorvath)](https://github.com/romeohorvath)
