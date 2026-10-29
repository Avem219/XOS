
#!/usr/bin/env bash
# XOS Alpha - Debian Trixie amd64 live ISO builder
set -Eeuo pipefail
trap 'rc=$?; echo "BUILD FAILED (exit $rc) at line $LINENO" >&2; exit "$rc"' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/out"
WORK="$ROOT/build"
ISO_NAME="XOS-Alpha-amd64.iso"
DIST="${XOS_DIST:-trixie}"
MIRROR="${XOS_MIRROR:-https://deb.debian.org/debian/}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Run this script as root inside the Linux build environment." >&2
  exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
  echo "ERROR: live-build is not installed." >&2
  exit 1
fi

for tool in bash cp install mkdir rm tee sha256sum find; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: Required tool missing: $tool" >&2
    exit 1
  }
done

mkdir -p "$OUT"
exec > >(tee -a "$OUT/build.log") 2>&1

echo "== XOS Alpha build started: $(date -u +%FT%TZ) =="
echo "Distribution: $DIST"
echo "Mirror: $MIRROR"
echo "Repository: $ROOT"
df -h "$ROOT"

# Validate the existing XOS desktop configuration and required assets.
bash "$ROOT/scripts/validate.sh"

for asset in \
  "$ROOT/live/bootloaders/splash.png" \
  "$ROOT/live/bootloaders/select_c.png" \
  "$ROOT/live/package-lists/xos.list.chroot"
do
  if [ ! -s "$asset" ]; then
    echo "ERROR: Required XOS asset is missing or empty: $asset" >&2
    exit 1
  fi
done

# Build from a clean work directory; preserve source files and previous output.
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

# Use live-build's supported configuration options.
lb config noauto \
  --mode debian \
  --distribution "$DIST" \
  --architectures amd64 \
  --linux-flavours amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --mirror-bootstrap "$MIRROR" \
  --mirror-chroot "$MIRROR" \
  --mirror-binary "$MIRROR" \
  --security true \
  --apt-recommends false \
  --binary-image iso-hybrid \
  --debian-installer none \
  --memtest none \
  --checksums sha256 \
  --cache false \
  --iso-application "XOS Alpha" \
  --iso-volume "XOS_ALPHA" \
  --iso-publisher "XOS project" \
  --bootappend-live "boot=live components quiet splash username=xos hostname=xos locales=en_US.UTF-8 keyboard-layouts=us"

# Add the repository's XOS configuration to the generated live-build tree.
mkdir -p \
  config/package-lists \
  config/includes.chroot \
  config/hooks/live \
  config/xos-boot

cp -a "$ROOT/live/package-lists/." config/package-lists/
cp -a "$ROOT/live/includes.chroot/." config/includes.chroot/
cp -a "$ROOT/live/hooks/." config/hooks/live/
cp -a "$ROOT/live/bootloaders/." config/xos-boot/

install -m 0644 \
  "$ROOT/live/bootloaders/splash.png" \
  config/xos-boot/splash.png

install -m 0644 \
  "$ROOT/live/bootloaders/select_c.png" \
  config/xos-boot/select_c.png

test -s config/xos-boot/splash.png
test -s config/xos-boot/select_c.png

echo "== Starting live-build =="
lb build

# Find the generated ISO without accidentally accepting an empty output.
ISO=""
while IFS= read -r candidate; do
  if [ -s "$candidate" ]; then
    ISO="$candidate"
    break
  fi
done < <(find "$WORK" -maxdepth 1 -type f -name '*.iso' -print)

if [ -z "$ISO" ]; then
  echo "ERROR: live-build finished without producing a non-empty ISO." >&2
  exit 1
fi

install -m 0644 "$ISO" "$OUT/$ISO_NAME"
(
  cd "$OUT"
  sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
  sha256sum --check "$ISO_NAME.sha256"
)

echo "== Build output =="
ls -lh "$OUT/$ISO_NAME" "$OUT/$ISO_NAME.sha256"
echo "== XOS Alpha build finished: $(date -u +%FT%TZ) =="
