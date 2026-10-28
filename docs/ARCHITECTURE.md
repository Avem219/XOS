# Architecture

| Layer | Implementation |
|---|---|
| Base | Debian trixie amd64 via `live-build`, `live-boot`, `live-config` (live user `xos`, no password prompt) |
| Boot | GRUB (UEFI) + syslinux (legacy BIOS) in one hybrid ISO; XOS menus written by `live/hooks/0100-xos-bootloader.hook.binary` |
| Splash | Plymouth script theme `xos` (`live/includes.chroot/usr/share/plymouth/themes/xos`) |
| Session | LightDM autologin into Openbox (X11) |
| Desktop | Openbox (windows, XOS theme), Tint2 (panel, tray, taskbar, clock), Rofi (launcher), PCManFM (files), picom, dunst (notifications) |
| Services | NetworkManager, PipeWire/WirePlumber, BlueZ, udisks2/gvfs (USB drives), polkit via lxpolkit |
| Apps | Firefox ESR, Mousepad, Xarchiver, Evince, Xfce Terminal, Xfce Task Manager, GParted, scrot |
| XOS helpers | `xos-settings` (opens real tools), `xos-power` (logout/restart/shutdown) |
| Build | `build-xos.sh` -> `lb config` + overlay of `live/` -> `lb build`; CI in `.github/workflows/build-xos.yml` |
| Assets | `tools/gen_assets.py` regenerates all images (original artwork) |

Layout: `live/` is the overlay copied into live-build's `config/` at build time (`bootloaders/` is copied to `config/xos-boot/` so live-build does not treat it as a replacement template).
