#!/usr/bin/env bash
# XOS repository validation. Prints PASS / FAIL per check. Exit 1 if any FAIL.
# Optional: --packages  also checks every package name exists in the configured apt archive (needs apt metadata).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
FAILS=0
ok(){ echo "PASS  $1"; }
bad(){ echo "FAIL  $1"; FAILS=$((FAILS+1)); }
skip(){ echo "NOT RUN  $1"; }

# 1. shell syntax
for f in build-xos.sh scripts/*.sh tests/*.sh live/hooks/* live/includes.chroot/usr/local/bin/*; do
  [ -f "$f" ] || continue
  if sh -c "head -1 '$f'" | grep -q 'bash'; then sh_cmd=bash; else sh_cmd=sh; fi
  if $sh_cmd -n "$f" 2>/dev/null; then ok "shell syntax: $f"; else bad "shell syntax: $f"; fi
done

# 2. XML well-formedness
if command -v xmllint >/dev/null; then
  for f in $(find live -name '*.xml'); do xmllint --noout "$f" 2>/dev/null && ok "xml: $f" || bad "xml: $f"; done
else skip "xml checks (xmllint missing)"; fi

# 3. workflow YAML
if command -v python3 >/dev/null && python3 -c 'import yaml' 2>/dev/null; then
  for f in .github/workflows/*.yml; do python3 -c "import yaml,sys;yaml.safe_load(open('$f'))" 2>/dev/null && ok "yaml: $f" || bad "yaml: $f"; done
else skip "workflow YAML (PyYAML missing)"; fi

# 4. required assets
for f in live/bootloaders/splash.png live/bootloaders/select_c.png \
  live/includes.chroot/usr/share/backgrounds/xos/xos-wallpaper.png \
  live/includes.chroot/usr/share/plymouth/themes/xos/{logo,track,fill}.png \
  live/includes.chroot/usr/share/plymouth/themes/xos/xos.plymouth live/includes.chroot/usr/share/plymouth/themes/xos/xos.script \
  live/includes.chroot/usr/share/themes/XOS/openbox-3/{themerc,close.xbm,max.xbm,max_toggled.xbm,iconify.xbm,desk.xbm,shade.xbm} \
  live/includes.chroot/etc/skel/.config/{openbox/rc.xml,openbox/menu.xml,openbox/autostart,tint2/tint2rc,rofi/config.rasi} \
  live/includes.chroot/etc/lightdm/lightdm.conf.d/50-xos.conf live/package-lists/xos.list.chroot; do
  [ -s "$f" ] && ok "asset present: $f" || bad "asset missing: $f"
done

# 5. images referenced by the Plymouth script exist
for img in $(grep -o 'Image("[^"]*")' live/includes.chroot/usr/share/plymouth/themes/xos/xos.script | sed 's/Image("\(.*\)")/\1/'); do
  [ -f "live/includes.chroot/usr/share/plymouth/themes/xos/$img" ] && ok "plymouth image: $img" || bad "plymouth image missing: $img"
done

# 6. wallpaper path used by autostart matches the shipped file
grep -q '/usr/share/backgrounds/xos/xos-wallpaper.png' live/includes.chroot/etc/skel/.config/openbox/autostart \
  && ok "autostart wallpaper path" || bad "autostart wallpaper path"

# 7. package list sanity
PL=live/package-lists/xos.list.chroot
pk=$(grep -vE '^\s*(#|$)' "$PL")
dups=$(echo "$pk" | sort | uniq -d)
[ -z "$dups" ] && ok "package list: no duplicates" || bad "package list duplicates: $dups"
echo "$pk" | grep -qE '\s' && bad "package list: whitespace in names" || ok "package list: format"
for need in openbox tint2 rofi pcmanfm plymouth lightdm network-manager firefox-esr; do
  echo "$pk" | grep -qx "$need" && ok "package listed: $need" || bad "package missing from list: $need"
done

# 8. safety: no destructive disk commands in image-side scripts
if grep -RInE '\b(mkfs|parted|sfdisk|wipefs|dd +if=|fdisk)\b' live/hooks live/includes.chroot/usr/local/bin build-xos.sh >/dev/null 2>&1; then
  bad "destructive disk command found in image scripts"; else ok "no destructive disk commands in image scripts"; fi

# 9. required keyboard shortcuts present in rc.xml
for k in W-space W-e W-t W-d A-F4 A-Tab; do
  grep -q "key=\"$k\"" live/includes.chroot/etc/skel/.config/openbox/rc.xml && ok "shortcut: $k" || bad "shortcut missing: $k"
done

# 10. optional apt package availability
if [ "${1:-}" = "--packages" ]; then
  if command -v apt-cache >/dev/null; then
    for p in $pk; do apt-cache show "$p" >/dev/null 2>&1 && ok "apt has: $p" || bad "apt cannot find: $p"; done
  else skip "apt package availability (apt-cache missing)"; fi
else skip "apt package availability (run with --packages on Debian)"; fi

echo; [ "$FAILS" -eq 0 ] && echo "VALIDATION: all executed checks passed" || echo "VALIDATION: $FAILS check(s) FAILED"
[ "$FAILS" -eq 0 ]
