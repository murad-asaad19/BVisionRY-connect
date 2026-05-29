"""Generate PLACEHOLDER brand artwork for launcher icons + native splash.

These are intentional stand-ins so the app stops shipping the default Flutter
"F" and the icon/splash pipeline can be exercised. Replace the three output
PNGs with final brand artwork (same paths/sizes) and re-run:

    py tool/gen_placeholder_icons.py        # regenerate sources (optional)
    dart run flutter_launcher_icons         # -> android/ios/web launcher icons
    dart run flutter_native_splash:create   # -> native splash screens

Brand palette (already referenced in pubspec): navy #0F3460, gold #FFC107.
The mark is a simple two-node "connection" glyph evoking the product name.

Requires Pillow (`py -m pip install Pillow`).
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

NAVY = (15, 52, 96, 255)        # #0F3460
GOLD = (255, 193, 7, 255)       # #FFC107
TRANSPARENT = (0, 0, 0, 0)

SS = 4                          # supersampling factor for crisp anti-aliasing
SIZE = 1024                     # final canvas size (px)

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
ICON_DIR = os.path.join(APP, "assets", "icon")
SPLASH_DIR = os.path.join(APP, "assets", "splash")


def _draw_mark(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float) -> None:
    """Two gold nodes joined by a link — a minimal 'connect' glyph."""
    node_r = 78 * scale
    small_r = 52 * scale
    link_w = int(round(46 * scale))

    # endpoints on a diagonal
    ax, ay = cx - 168 * scale, cy + 150 * scale
    bx, by = cx + 168 * scale, cy - 150 * scale

    # connecting link
    draw.line([(ax, ay), (bx, by)], fill=GOLD, width=link_w)

    # nodes (ring + solid) so the mark reads at small sizes
    draw.ellipse([ax - node_r, ay - node_r, ax + node_r, ay + node_r], fill=GOLD)
    draw.ellipse([bx - small_r, by - small_r, bx + small_r, by + small_r], fill=GOLD)

    # a third accent node to suggest a network, not just a pair
    mx, my = cx - 150 * scale, cy - 150 * scale
    ms = 40 * scale
    draw.line([(mx, my), (cx + 10 * scale, cy + 10 * scale)], fill=GOLD, width=int(round(34 * scale)))
    draw.ellipse([mx - ms, my - ms, mx + ms, my + ms], fill=GOLD)


def _canvas(bg=TRANSPARENT) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE * SS, SIZE * SS), bg)
    return img, ImageDraw.Draw(img)


def _save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((SIZE, SIZE), Image.LANCZOS).save(path)
    print(f"wrote {os.path.relpath(path, APP)}")


def main() -> None:
    c = (SIZE * SS) / 2

    # 1) icon.png — full-bleed navy background + gold mark (iOS/web master).
    img, draw = _canvas(NAVY)
    _draw_mark(draw, c, c, SS * 1.15)
    _save(img, os.path.join(ICON_DIR, "icon.png"))

    # 2) icon_foreground.png — transparent; mark sits inside the Android
    #    adaptive safe zone (~66%) so masking never clips it.
    img, draw = _canvas(TRANSPARENT)
    _draw_mark(draw, c, c, SS * 0.78)
    _save(img, os.path.join(ICON_DIR, "icon_foreground.png"))

    # 3) splash_logo.png — transparent; native splash centers it on navy.
    img, draw = _canvas(TRANSPARENT)
    _draw_mark(draw, c, c, SS * 0.95)
    _save(img, os.path.join(SPLASH_DIR, "splash_logo.png"))


if __name__ == "__main__":
    main()
