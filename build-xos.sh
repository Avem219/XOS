#!/usr/bin/env bash
# Build the XOS Alpha live ISO (Debian trixie, amd64). Must run as root on Debian/Ubuntu/Linux with live-build.
# Usage: sudo ./build-xos.sh        Output: out/XOS-Alpha-amd64.iso (+ .sha256, build.log)
set -Eeuo pipefail
trap 'echo "BUILD FAILED at line $LINENO (see out/build.log)" >&2' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/out"; WORK="$ROOT/build"
ISO_NAME="XOS-Alpha-amd64.iso"
DIST="${XOS_DIST:-trixie}"
MIRROR="${XOS_MIRROR:-http://deb.debian.org/debian/}"

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo ./build-xos.sh" >&2; exit 1; }
command -v lb >/dev/null || { echo "live-build is not installed (apt install live-build)" >&2; exit 1; }

mkdir -p "$OUT"
exec > >(tee -a "$OUT/build.log") 2>&1
echo "== XOS build started $(date -u +%FT%TZ) =="
echo "live-build: $(dpkg-query -W -f='${Version}' live-build 2>/dev/null || echo unknown)  dist=$DIST  mirror=$MIRROR"
df -h "$ROOT" | tail -1

"$ROOT/scripts/validate.sh"

rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
lb config noauto \
  --mode debian \
  --distribution "$DIST" \
  --architectures amd64 \
  --linux-flavours amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --mirror-bootstrap "$MIRROR" --mirror-chroot "$MIRROR" --mirror-binary "$MIRROR" \
  --security true --updates true \
  --apt-recommends false \
  --binary-image iso-hybrid \
  --bootloaders "grub-efi,syslinux" \
  --debian-installer none \
  --memtest none \
  --checksums none \
  --cache false \
  --iso-application "XOS Alpha" \
  --iso-volume "XOS_ALPHA" \
  --iso-publisher "XOS project" \
  --image-name "XOS-Alpha" \
  --bootappend-live "boot=live components quiet splash username=xos hostname=xos locales=en_US.UTF-8 keyboard-layouts=us"

# Overlay the XOS configuration (the repo's live/ directory) onto live-build's config/ tree.
cp -a "$ROOT/live/package-lists/." config/package-lists/
mkdir -p config/includes.chroot config/hooks/live config/xos-boot
cp -a "$ROOT/live/includes.chroot/." config/includes.chroot/
cp -a "$ROOT/live/hooks/." config/hooks/live/
cp -a "$ROOT/live/bootloaders/." config/xos-boot/   # not named "bootloaders": live-build would treat that as a full template
# Explicitly install the required boot assets and fail here, before live-build hooks run,
# if the source archive/repository is incomplete.
install -d -m 0755 config/xos-boot
[ -s "$ROOT/live/bootloaders/splash.png" ] || { echo "Missing source asset: $ROOT/live/bootloaders/splash.png" >&2; exit 1; }
install -m 0644 "$ROOT/live/bootloaders/splash.png" config/xos-boot/splash.png
[ -s "$ROOT/live/bootloaders/select_c.png" ] || { echo "Missing source asset: $ROOT/live/bootloaders/select_c.png" >&2; exit 1; }
install -m 0644 "$ROOT/live/bootloaders/select_c.png" config/xos-boot/select_c.png
[ -s config/xos-boot/splash.png ] || { echo "Boot splash staging failed" >&2; exit 1; }

lb build

ISO="$(ls -1 ./*.iso 2>/dev/null | head -n1 || true)"
[ -n "$ISO" ] && [ -s "$ISO" ] || { echo "No ISO produced" >&2; exit 1; }
mv "$ISO" "$OUT/$ISO_NAME"
( cd "$OUT" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" && sha256sum -c "$ISO_NAME.sha256" )
ls -l "$OUT/$ISO_NAME"
echo "== XOS build finished $(date -u +%FT%TZ) =="
