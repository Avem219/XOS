# Building on Linux

Requires Debian 12+/Ubuntu 22.04+ (or a Debian container with `--privileged`), root, ~15 GB free disk, internet.

```
sudo apt-get install live-build debootstrap xorriso squashfs-tools mtools dosfstools \
  grub-common grub-efi-amd64-bin grub-pc-bin syslinux syslinux-common isolinux libxml2-utils
sudo ./build-xos.sh
```
Output: `out/XOS-Alpha-amd64.iso`, `out/XOS-Alpha-amd64.iso.sha256`, `out/build.log`.

Moving dependencies (not pinned): the Debian archive (`XOS_DIST`, `XOS_MIRROR` override), the `live-build` version in the build image, and GitHub Action major versions (`@v4`). A fully reproducible build would need a Debian snapshot mirror; not done yet.

Regenerate artwork: `python3 tools/gen_assets.py` (needs Pillow). Validate: `tests/run-tests.sh [--packages]`.
