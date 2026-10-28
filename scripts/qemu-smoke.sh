#!/usr/bin/env bash
# Boot the ISO headless in QEMU (UEFI, software emulation) and capture a screenshot.
# PASS only if the VM stays running and the screenshot is not a blank single-colour frame.
# Usage: scripts/qemu-smoke.sh out/XOS-Alpha-amd64.iso [wait-seconds] [outdir]
set -u
ISO="${1:?iso path}"; WAIT="${2:-300}"; OUTD="${3:-out}"; mkdir -p "$OUTD"
CODE=""; for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF.fd; do [ -f "$c" ] && CODE="$c" && break; done
[ -n "$CODE" ] || { echo "NOT RUN  OVMF firmware not found"; exit 2; }
SOCK="$(mktemp -u)"; 
qemu-system-x86_64 -m 3072 -smp 2 -machine q35 -cpu max -bios "$CODE" -cdrom "$ISO" -boot d \
  -display none -vga std -monitor "unix:$SOCK,server,nowait" -serial "file:$OUTD/qemu-serial.log" -no-reboot &
QPID=$!
for t in 60 "$((WAIT-60))"; do
  sleep "$t"
  kill -0 "$QPID" 2>/dev/null || { echo "FAIL  QEMU exited early"; exit 1; }
  echo "screendump $OUTD/shot-$t.ppm" | socat - "UNIX-CONNECT:$SOCK" >/dev/null 2>&1
done
echo "quit" | socat - "UNIX-CONNECT:$SOCK" >/dev/null 2>&1; sleep 2; kill "$QPID" 2>/dev/null
for p in "$OUTD"/shot-*.ppm; do convert "$p" "${p%.ppm}.png" 2>/dev/null; done
python3 - "$OUTD" <<'PY'
import sys,glob
from PIL import Image
for f in sorted(glob.glob(sys.argv[1]+"/shot-*.png")):
    im=Image.open(f).convert("RGB").resize((64,48)); cols=len(set(im.getdata()))
    print(f, "distinct colours:", cols)
    last=cols
print("PASS  VM booted and rendered a non-blank frame (inspect screenshots to confirm it is the XOS desktop)" if last>8 else "FAIL  final frame looks blank")
sys.exit(0 if last>8 else 1)
PY
