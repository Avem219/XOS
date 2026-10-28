# Writing XOS to a USB drive with Rufus (Windows)

**WARNING: writing the image ERASES everything on the selected USB drive.** Back it up first. Double-check the drive letter and size in Rufus. Use a USB stick of 8 GB or more.

1. Download and extract `XOS-Alpha-amd64-ISO` from the GitHub Actions run. You need `XOS-Alpha-amd64.iso` and `XOS-Alpha-amd64.iso.sha256`.
2. Verify (PowerShell, in the folder):
   `Get-FileHash .\XOS-Alpha-amd64.iso -Algorithm SHA256`
   The Hash must equal the value in the `.sha256` file. If not, download again.
3. Open Rufus (rufus.ie). **Device**: choose your USB stick. **Boot selection**: SELECT > the ISO.
4. Partition scheme: GPT for UEFI PCs (most computers since ~2012); MBR for old BIOS PCs. Leave the rest default, press START.
5. If Rufus asks "ISO Image mode or DD Image mode": **choose DD Image mode** (recommended for Debian hybrid ISOs). *Untested: neither mode has been verified by the project yet.* If one fails to boot, rewrite with the other.
6. Wait for READY. Shut down the PC.
7. Plug the USB into the target PC, power on and tap the one-time boot menu key (commonly F12, F9, F8, Esc, or F10 depending on maker). Pick the entry named like your USB, with "UEFI" if listed.
8. In the XOS boot menu press Enter on **XOS Alpha - Live session**. The desktop starts automatically, no password.

Troubleshooting
- Not listed in boot menu: try another USB port (prefer USB 2.0), re-write in the other Rufus mode, check GPT vs MBR.
- Secure Boot: **not supported/verified**. The image is not signed with a Microsoft-trusted key. Disable Secure Boot in firmware setup to boot.
- Black screen or no desktop: reboot and choose **safe graphics (nomodeset)**; or **verbose boot** to see messages.
- Wi-Fi missing: common firmware (Intel, Realtek, Atheros, Broadcom) is included; other adapters may need packages added later. Use Ethernet or phone USB tethering.
- Legacy BIOS boot is configured (syslinux) but not verified.

XOS Alpha runs as a **non-persistent live session**: files and settings are lost at shutdown unless saved to another drive. Persistence is not implemented.
