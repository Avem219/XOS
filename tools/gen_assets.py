#!/usr/bin/env python3
"""Generate XOS raster assets (wallpaper, boot splash, Plymouth images).
Requires Pillow. Output is committed so the ISO build needs no image tooling."""
from PIL import Image, ImageDraw
import os
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORC, GRAPH, CRIM, STEEL, WHITE = "#F2F3F5", "#252932", "#D9233F", "#65758D", "#FFFFFF"
S = 2  # supersample

def x_mark(d, cx, cy, size, fill_a, fill_b):
    w = size * 0.22
    h = size / 2
    # two crossing parallelogram bars forming an X
    d.polygon([(cx-h, cy-h), (cx-h+w*1.5, cy-h), (cx+h, cy+h), (cx+h-w*1.5, cy+h)], fill=fill_a)
    d.polygon([(cx+h-w*1.5, cy-h), (cx+h, cy-h), (cx-h+w*1.5, cy+h), (cx-h, cy+h)], fill=fill_b)

def scene(w, h, graphite_band=True):
    img = Image.new("RGB", (w*S, h*S), PORC)
    d = ImageDraw.Draw(img)
    W, H = w*S, h*S
    d.polygon([(W*0.58, 0), (W, 0), (W, H), (W*0.36, H)], fill=GRAPH)
    d.polygon([(W*0.55, 0), (W*0.575, 0), (W*0.355, H), (W*0.33, H)], fill=CRIM)
    for i in range(6):
        o = W*(0.60+0.035*i)
        d.line([(o, 0), (o-W*0.22, H)], fill=STEEL, width=max(1, int(S*1.2)))
    x_mark(d, W*0.78, H*0.46, H*0.34, WHITE, CRIM)
    return img.resize((w, h), Image.LANCZOS)

out = os.path.join(R, "live/includes.chroot/usr/share/backgrounds/xos")
os.makedirs(out, exist_ok=True)
scene(1920, 1080).save(os.path.join(out, "xos-wallpaper.png"))

# boot splash used by GRUB and syslinux (4:3 safe, 640x480 minimum for syslinux)
bl = os.path.join(R, "live/bootloaders")
os.makedirs(bl, exist_ok=True)
scene(1024, 768).save(os.path.join(bl, "splash.png"))
scene(640, 480).save(os.path.join(bl, "splash-640x480.png"))

# Plymouth images
pl = os.path.join(R, "live/includes.chroot/usr/share/plymouth/themes/xos")
os.makedirs(pl, exist_ok=True)
lg = Image.new("RGBA", (240*S, 240*S), (0, 0, 0, 0))
x_mark(ImageDraw.Draw(lg), 120*S, 120*S, 200*S, GRAPH, CRIM)
lg.resize((240, 240), Image.LANCZOS).save(os.path.join(pl, "logo.png"))
Image.new("RGB", (360, 4), STEEL).save(os.path.join(pl, "track.png"))
Image.new("RGB", (360, 4), CRIM).save(os.path.join(pl, "fill.png"))
print("assets generated")

# --- additions: GRUB selection pixmap and Openbox titlebar glyphs (XBM, 8x8) ---
Image.new("RGBA", (8, 8), CRIM).save(os.path.join(bl, "select_c.png"))
def _xbm(name, rows):
    vals = []
    for r in rows:
        v = 0
        for i, ch in enumerate(r):
            if ch == "#": v |= 1 << i
        vals.append("0x%02x" % v)
    return "#define %s_width 8\n#define %s_height 8\nstatic unsigned char %s_bits[] = { %s };\n" % (name, name, name, ", ".join(vals))
_G = {
 "close": ["#......#", ".#....#.", "..#..#..", "...##...", "...##...", "..#..#..", ".#....#.", "#......#"],
 "max": ["########", "#......#", "#......#", "#......#", "#......#", "#......#", "#......#", "########"],
 "max_toggled": ["..######", "..#....#", "######.#", "#....#.#", "#....###", "#....#..", "#....#..", "######.."],
 "iconify": ["........"]*6 + ["########", "########"],
 "desk": ["........", ".##.##..", ".##.##..", "........", ".##.##..", ".##.##..", "........", "........"],
 "desk_toggled": ["........"] + ["######.."]*5 + ["........"]*2,
 "shade": ["########", "########"] + ["........"]*6,
 "shade_toggled": ["........"]*6 + ["########", "########"],
}
ob = os.path.join(R, "live/includes.chroot/usr/share/themes/XOS/openbox-3")
os.makedirs(ob, exist_ok=True)
for _n, _r in _G.items():
    open(os.path.join(ob, _n + ".xbm"), "w").write(_xbm(_n, _r))
print("extra assets generated")
