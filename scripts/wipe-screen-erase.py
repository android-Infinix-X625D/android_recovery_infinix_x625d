#!/usr/bin/env python3
"""Make the "OTA-style" progress screen say "Erasing..." with an erase icon.

Why
---
When the bootloader hands recovery a BCB command (e.g. Settings -> Factory
data reset, or an OTA), OrangeFox runs it through the OpenRecoveryScript
engine. The theme then swaps the console for the compact "ota_simple" overlay
(portrait_hdpi/pages/universal.xml -> <action function="overlay">ota_simple</action>,
gated on tw_action=openrecoveryscript + ota_new_screen=1).

That overlay renders three theme resources:

    <image resource="ota_icon"/>          twres/images/<variant>/FullscreenIcons/ota_icon.png
    <text>{@ota_simple_title}</text>      twres/languages/<lang>.xml
    <progressbar .../>

i.e. a round "download" arrow and the label "Updating...". A factory reset is
not an update, so this script rewrites the label to "Erasing..." ("Menghapus..."
in Indonesian) and replaces the icon with a trash can, keeping the exact
geometry of the stock asset (428x428, transparent background, single solid
colour: white for the Default theme, #202124 for the Light theme).

Note: the overlay is shared, so a real OTA will also read "Erasing...". That is
the accepted trade-off for not patching the theme's page XML.

The script is idempotent, verifies every change and exits non-zero when the
theme layout is not what it expects, so a build never silently ships the old
screen.

Usage: wipe-screen-erase.py <path/to/gui/theme> [--assets <dir with ota_icon_white.png / ota_icon_dark.png>]
"""
import argparse
import os
import re
import struct
import sys

LANGUAGES = {
    "en": "Erasing...",
    "id": "Menghapus...",
}

STRING_RE = re.compile(
    r'(<string name="ota_simple_title">)(.*?)(</string>)', re.S)

ICON_NAME = "ota_icon.png"
PNG_SIG = b"\x89PNG\r\n\x1a\n"
EXPECTED_SIZE = (428, 428)


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    if not head.startswith(PNG_SIG):
        raise SystemExit("%s: not a PNG file" % path)
    return struct.unpack(">II", head[16:24])


def preflight(theme):
    """Fail before touching anything if the theme does not look as expected."""
    lang_dir = os.path.join(theme, "common", "languages")
    if not os.path.isdir(lang_dir):
        raise SystemExit("%s: no common/languages directory" % theme)
    seen = False
    for lang in LANGUAGES:
        path = os.path.join(lang_dir, lang + ".xml")
        if not os.path.exists(path):
            continue
        seen = True
        with open(path, "r", encoding="utf-8") as fh:
            count = len(STRING_RE.findall(fh.read()))
        if count != 1:
            raise SystemExit(
                "%s: expected exactly one ota_simple_title string, found %d"
                % (path, count))
    if not seen:
        raise SystemExit(
            "%s: no en.xml/id.xml in common/languages - theme layout changed?"
            % theme)
    if not find_icons(theme):
        raise SystemExit(
            "%s: no <variant>/images/*/FullscreenIcons/%s found - theme layout changed?"
            % (theme, ICON_NAME))


def patch_languages(theme, changed):
    lang_dir = os.path.join(theme, "common", "languages")
    for lang, text in LANGUAGES.items():
        path = os.path.join(lang_dir, lang + ".xml")
        if not os.path.exists(path):
            print("skip %s: not present in this theme" % path)
            continue
        with open(path, "r", encoding="utf-8") as fh:
            src = fh.read()
        matches = STRING_RE.findall(src)
        if len(matches) != 1:
            raise SystemExit(
                "%s: expected exactly one ota_simple_title string, found %d"
                % (path, len(matches)))
        old = matches[0][1]
        if old == text:
            print("%s: already %r" % (path, text))
            continue
        new = STRING_RE.sub(lambda m: m.group(1) + text + m.group(3), src, count=1)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
        changed.append("%s: ota_simple_title %r -> %r" % (path, old, text))


def find_icons(theme):
    found = []
    for root, _dirs, files in os.walk(theme):
        parts = os.path.relpath(root, theme).split(os.sep)
        if ICON_NAME in files and "FullscreenIcons" in parts:
            found.append((root, parts))
    return found


def patch_icons(theme, assets, changed):
    icons = find_icons(theme)
    if not icons:
        raise SystemExit(
            "%s: no <variant>/images/*/FullscreenIcons/%s found - theme layout changed?"
            % (theme, ICON_NAME))
    for root, parts in icons:
        variant = "Light" if "Light" in parts else "Default"
        src = os.path.join(assets, "ota_icon_dark.png" if variant == "Light"
                           else "ota_icon_white.png")
        if not os.path.exists(src):
            raise SystemExit("%s: missing icon asset" % src)
        dst = os.path.join(root, ICON_NAME)
        size = png_size(src)
        if size != EXPECTED_SIZE:
            raise SystemExit("%s: unexpected size %dx%d (want %dx%d)"
                             % (src, size[0], size[1], *EXPECTED_SIZE))
        with open(src, "rb") as fh:
            blob = fh.read()
        with open(dst, "rb") as fh:
            current = fh.read()
        if current == blob:
            print("%s: already the erase icon" % dst)
            continue
        with open(dst, "wb") as fh:
            fh.write(blob)
        changed.append("%s: replaced with %s" % (dst, os.path.basename(src)))

    if not any("Light" in parts for _root, parts in icons):
        print("note: no Light variant in this theme, only Default was patched")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("theme", help="path to gui/theme checkout")
    ap.add_argument("--assets", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "theme"),
        help="directory holding ota_icon_white.png / ota_icon_dark.png")
    args = ap.parse_args()

    theme = args.theme
    if not os.path.isdir(theme):
        raise SystemExit("%s: not a directory" % theme)

    preflight(theme)

    changed = []
    patch_languages(theme, changed)
    patch_icons(theme, args.assets, changed)

    if changed:
        print("\nwipe screen: %d change(s)" % len(changed))
        for line in changed:
            print("  " + line)
    else:
        print("\nwipe screen: nothing to do")
    return 0


if __name__ == "__main__":
    sys.exit(main())
