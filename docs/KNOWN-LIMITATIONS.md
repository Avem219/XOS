# Known limitations (Alpha)

- Not yet built or boot-tested; configs (Openbox, Tint2, Plymouth, GRUB hook) were written without running them. Expect first-build fixes.
- Secure Boot unsupported. Legacy BIOS unverified. No persistence. No installer: live session only (by design for this alpha).
- Debian archive and live-build version are not pinned (see BUILD.md).
- X11 desktop, not Wayland. Screen lock uses `xdg-screensaver` and may report "not available" until a locker is added.
- `xos-settings` is a menu that opens real tools (display, network, sound, appearance, disks); it is not a unified settings app.
- No X-Suite office apps yet; Evince views PDFs. LibreOffice not bundled to keep the image small.
- Wi-Fi/GPU support depends on the bundled Debian firmware; NVIDIA proprietary drivers not included.
