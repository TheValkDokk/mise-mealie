#!/usr/bin/env python3
"""Generates Mise's app icon: a serif monogram on ember, nothing else."""
import json
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APPICON = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
ANDROID = os.path.join(ROOT, "android/app/src/main/res")
S = 1024
EMBER = (188, 63, 27)
EMBER_DARK = (150, 45, 18)
CREAM = (251, 246, 238)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/System/Library/Fonts/NewYork.ttf",
    "/Library/Fonts/Georgia.ttf",
]


def gradient(size, top, bottom):
    img = Image.new("RGB", (1, size), top)
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return img.resize((size, size))


def font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw():
    img = gradient(S, (206, 74, 34), EMBER_DARK).convert("RGBA")

    # soft warm light from the top-left, so the square is not flat
    glow = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-S * 0.2, -S * 0.35, S * 0.85, S * 0.6], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.12))
    img = Image.composite(Image.new("RGBA", (S, S), (232, 120, 78, 255)), img, glow)

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # serif monogram, optically centred
    f = font(int(S * 0.62))
    text = "M"
    box = d.textbbox((0, 0), text, font=f)
    w = box[2] - box[0]
    h = box[3] - box[1]
    d.text(((S - w) / 2 - box[0], (S - h) / 2 - box[1] - S * 0.02),
           text, font=f, fill=CREAM)

    img = Image.alpha_composite(img, layer)
    return img.convert("RGB")


def main():
    master = draw()
    master.save(os.path.join(APPICON, "icon-1024.png"))
    with open(os.path.join(APPICON, "Contents.json")) as f:
        contents = json.load(f)
    for entry in contents["images"]:
        name = entry.get("filename")
        if not name:
            continue
        px = int(round(float(entry["size"].split("x")[0]) *
                       int(entry["scale"].rstrip("x"))))
        master.resize((px, px), Image.LANCZOS).save(os.path.join(APPICON, name))

    for bucket, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                       "xxhdpi": 144, "xxxhdpi": 192}.items():
        master.resize((px, px), Image.LANCZOS).save(
            os.path.join(ANDROID, f"mipmap-{bucket}", "ic_launcher.png"))

    os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
    master.save(os.path.join(ROOT, "assets", "icon-1024.png"))
    print("icon written")


if __name__ == "__main__":
    main()
