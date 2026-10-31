#!/usr/bin/env python3
"""Generate the social cards for the Mise launch.

Every card is built from real simulator screenshots on the app's own palette, so
there is no mockup in the set:

  og-1200x630.png    link preview for X / Mastodon / LinkedIn, GitHub social preview
  x-1200x675.png     16:9 for X (slightly taller, safe under the crop)
  square-1080.png    1:1 for Instagram / Threads
  thread-1200x900.png  three-up strip for a Mastodon post

Run: python3 tool/make_social_cards.py
"""
from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "docs/screenshots")
OUT = os.path.join(ROOT, "docs/social")

CREAM = (251, 246, 238)
INK = (25, 21, 18)
EMBER = (188, 63, 27)
MUTED = (110, 101, 92)
DARK = (14, 12, 10)

FONTS = [
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/System/Library/Fonts/NewYork.ttf",
]


def font(size: int):
    for path in FONTS:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def shot(name: str) -> Image.Image:
    return Image.open(os.path.join(SHOTS, f"{name}.png")).convert("RGB")


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def paste_phone(canvas: Image.Image, img: Image.Image, box, radius=28, shadow=True):
    """Paste a screenshot with a soft shadow, top-left anchored at box."""
    w, h = img.size
    if shadow:
        pad = 60
        s = Image.new("RGBA", (w + pad, h + pad), (0, 0, 0, 0))
        ImageDraw.Draw(s).rounded_rectangle(
            [pad // 2, pad // 2, w + pad // 2, h + pad // 2],
            radius=radius, fill=(70, 45, 30, 90))
        s = s.filter(ImageFilter.GaussianBlur(22))
        canvas.paste(Image.new("RGB", s.size, canvas.getpixel((2, 2))),
                     (box[0] - pad // 2 + 6, box[1] - pad // 2 + 10), s)
    layer = rounded(img, radius)
    canvas.paste(layer, box, layer)
    # cream screens on a cream canvas need an edge, or they float
    ImageDraw.Draw(canvas).rounded_rectangle(
        [box[0], box[1], box[0] + w - 1, box[1] + h - 1],
        radius=radius, outline=(226, 216, 203), width=1)


def disc(canvas: Image.Image, cx, cy, r, colour, alpha=24, blur=80):
    layer = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(layer).ellipse([cx - r, cy - r, cx + r, cy + r], fill=alpha)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    canvas.paste(Image.new("RGB", canvas.size, colour), (0, 0), layer)


def text_block(c: ImageDraw.ImageDraw, x, y, scale=1.0, sub=True):
    c.text((x, y), "SELF-HOSTED RECIPE CLIENT",
           font=font(int(19 * scale)), fill=MUTED)
    c.text((x - 6, y + int(28 * scale)), "Mise",
           font=font(int(150 * scale)), fill=INK)
    ty = y + int(198 * scale)
    c.text((x, ty), "Dinner, decided.", font=font(int(46 * scale)), fill=EMBER)
    c.rounded_rectangle([x, ty + int(72 * scale), x + int(112 * scale),
                         ty + int(78 * scale)], radius=3, fill=EMBER)
    if sub:
        c.text((x, ty + int(98 * scale)), "Recipes, cook mode and the list",
               font=font(int(25 * scale)), fill=MUTED)


def og() -> Image.Image:
    W, H = 1200, 630
    c = Image.new("RGB", (W, H), CREAM)
    disc(c, W - 250, 120, 420, EMBER, alpha=22)
    d = ImageDraw.Draw(c)
    text_block(d, 72, 118)

    d.text((72, 548), "GPL-3.0  ·  Android + iOS  ·  no account, no tracking",
           font=font(21), fill=MUTED)

    big = shot("today")
    big_h = 470
    big = big.resize((int(big.width * big_h / big.height), big_h), Image.Resampling.LANCZOS)
    paste_phone(c, big, (W - big.width - 200, 92))

    small = shot("cook")
    small_h = 330
    small = small.resize((int(small.width * small_h / small.height), small_h),
                         Image.Resampling.LANCZOS)
    paste_phone(c, small, (W - 300, 262))
    return c


def x_card() -> Image.Image:
    W, H = 1200, 675
    c = Image.new("RGB", (W, H), CREAM)
    disc(c, W - 300, 90, 430, EMBER, alpha=22)
    d = ImageDraw.Draw(c)
    text_block(d, 72, 140)
    d.text((72, 580), "GPL-3.0  ·  github.com/TheValkDokk/mise-mealie",
           font=font(22), fill=MUTED)
    big = shot("today")
    big_h = 500
    big = big.resize((int(big.width * big_h / big.height), big_h), Image.Resampling.LANCZOS)
    paste_phone(c, big, (W - big.width - 210, 110))
    return c


def square() -> Image.Image:
    W = H = 1080
    c = Image.new("RGB", (W, H), CREAM)
    disc(c, W - 100, 180, 420, EMBER, alpha=22)
    d = ImageDraw.Draw(c)
    d.text((80, 96), "SELF-HOSTED RECIPE CLIENT", font=font(22), fill=MUTED)
    d.text((70, 130), "Mise", font=font(210), fill=INK)
    d.text((80, 388), "Dinner, decided.", font=font(62), fill=EMBER)
    d.text((80, 470), "Recipes, cook mode and the shopping",
           font=font(28), fill=MUTED)
    d.text((80, 508), "list, on your own Mealie server.", font=font(28), fill=MUTED)

    cook = shot("cook")
    ch = 470
    cook = cook.resize((int(cook.width * ch / cook.height), ch), Image.Resampling.LANCZOS)
    paste_phone(c, cook, (W - cook.width - 90, 560))

    today = shot("today")
    th = 430
    today = today.resize((int(today.width * th / today.height), th),
                         Image.Resampling.LANCZOS)
    paste_phone(c, today, (86, 600))
    return c


def thread_strip() -> Image.Image:
    W, H = 1200, 900
    c = Image.new("RGB", (W, H), CREAM)
    disc(c, 620, 40, 380, EMBER, alpha=18)
    d = ImageDraw.Draw(c)

    d.text((60, 54), "Mise — a Mealie client for the stove", font=font(44), fill=INK)
    d.text((60, 108), "Tonight · cook mode · the shopping list",
           font=font(24), fill=MUTED)

    panels = [("today", "Tonight"), ("cook", "Cook mode"), ("list", "The list")]
    ph = 640
    gap = 28
    widths = []
    for name, _ in panels:
        im = shot(name)
        w = int(im.width * ph / im.height)
        widths.append(w)
    total = sum(widths) + gap * (len(panels) - 1)
    x = (W - total) // 2
    for (name, label), w in zip(panels, widths):
        im = shot(name).resize((w, ph), Image.Resampling.LANCZOS)
        paste_phone(c, im, (x, 156), radius=22, shadow=True)
        d.text((x, 156 + ph + 14), label, font=font(22), fill=MUTED)
        x += w + gap
    return c


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    cards = {
        "og-1200x630.png": og(),
        "x-1200x675.png": x_card(),
        "square-1080.png": square(),
        "thread-1200x900.png": thread_strip(),
    }
    for name, img in cards.items():
        path = os.path.join(OUT, name)
        img.save(path, optimize=True)
        print(f"{name:22} {img.size}  {os.path.getsize(path)//1024} KB")


if __name__ == "__main__":
    main()
