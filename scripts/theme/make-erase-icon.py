#!/usr/bin/env python3
"""Generate the trash-can icon that replaces ota_icon.png on the wipe screen.

Style follows the stock asset in the OrangeFox theme
(portrait_hdpi/images/<variant>/FullscreenIcons/ota_icon.png): 428x428,
transparent background, one solid colour, ~44 px stroke weight. Shapes are
drawn at 4x and downscaled with LANCZOS for antialiasing.

Output (written next to this file):
    ota_icon_white.png  -> Default theme variant  (pure white)
    ota_icon_dark.png   -> Light theme variant    (#202124)

Requires Pillow. Re-run only when the artwork should change; the PNGs are
committed so the CI build needs no image tooling.
"""
import os

from PIL import Image, ImageDraw

S = 4                 # supersampling factor
N = 428               # final edge length, same as the stock asset
UP = N * S
HERE = os.path.dirname(os.path.abspath(__file__))

WHITE = (255, 255, 255)
DARK = (32, 33, 36)   # #202124, same colour as the stock Light variant


def mask():
    m = Image.new("L", (UP, UP), 0)
    d = ImageDraw.Draw(m)

    def box(b, r, fill):
        d.rounded_rectangle([v * S for v in b], radius=r * S, fill=fill)

    # bin body silhouette (tapered)
    d.polygon([(132 * S, 176 * S), (296 * S, 176 * S),
               (274 * S, 366 * S), (154 * S, 366 * S)], fill=255)
    box((132, 330, 296, 366), 20, 255)        # round the bottom corners a bit
    # dark slots ("data" going away)
    for cx in (178, 214, 250):
        box((cx - 11, 216, cx + 11, 330), 11, 0)
    # lid
    box((88, 122, 340, 168), 23, 255)
    # handle
    box((172, 82, 256, 130), 24, 255)

    return m.resize((N, N), Image.LANCZOS)


def colourise(m, rgb):
    im = Image.new("RGBA", (N, N), rgb + (0,))
    im.putalpha(m)
    return im


def main():
    m = mask()
    for name, rgb in (("ota_icon_white.png", WHITE), ("ota_icon_dark.png", DARK)):
        im = colourise(m, rgb)
        out = os.path.join(HERE, name)
        im.save(out)
        print("%s: %dx%d, %d opaque px"
              % (out, im.size[0], im.size[1], sum(1 for a in m.getdata() if a > 8)))


if __name__ == "__main__":
    main()
