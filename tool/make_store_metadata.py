#!/usr/bin/env python3
"""Build and validate the F-Droid / IzzyOnDroid fastlane metadata for Mise.

Writes text files and images under fastlane/metadata/android/en-US/ and fails
loudly if any store constraint is broken, so CI can run it before a release.

Constraints enforced (F-Droid + IzzyOnDroid docs, checked Oct 2026):
  title.txt             <= 30 chars, plain text
  short_description.txt <= 80 chars, plain text, no trailing dot
  full_description.txt  <= 3700 chars (F-Droid allows 4000; Izzy converts to HTML)
  changelogs/<code>.txt <= 500 bytes, plain ASCII
  images/icon.png       48..512 px square
  images/featureGraphic 1024x500 or 512x250
  phoneScreenshots/*    height/width <= 2.0
"""
from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
META = os.path.join(ROOT, "fastlane/metadata/android/en-US")
IMAGES = os.path.join(META, "images")
SHOTS_SRC = os.path.join(ROOT, "docs/screenshots")
ICON_SRC = os.path.join(ROOT, "assets/icon-1024.png")

VERSION_CODE = 1
VERSION_NAME = "1.0.0"

TITLE = "Mise — Mealie recipe planner"
SHORT = "Tonight's dinner, cook mode and shopping for your self-hosted Mealie server"

FULL = """<p><b>Mise</b> is a mobile client for <b>Mealie</b>, the self-hosted recipe manager and meal planner. It covers the parts of Mealie you actually use standing up: tonight's dinner, the cookbook, cook mode, and the shopping list.</p>
<p>It talks only to the Mealie server you give it. No account, no analytics, no service of ours in the middle.</p>
<p><b>Tonight</b><br>Today's plan with tonight's dinner as a full-bleed photo card, the next few days underneath, and the state of the shopping list.</p>
<p><b>Cookbook</b><br>Search and category filters over your recipes, two per row, photography first. Open one for time, servings, method, and an ingredient list you can tick off as you go.</p>
<p><b>Cook mode</b><br>One step at a time in large type on a black screen, with the whole screen as a tap target - so you can advance it with the back of a knuckle when your hands are covered in flour.</p>
<p><b>Shopping</b><br>Unchecked items first, then what is already in the basket; swipe to remove. One button pulls the ingredients of every recipe on the next seven days of your plan into the list.</p>
<p><b>Where your data lives</b><br>Recipes, plan and list are cached on the phone, so the app opens to content instead of a spinner. Your password is used once to obtain a token and is never stored. There is no telemetry and no third-party SDK.</p>
<p><b>What you need</b><br>Your own Mealie instance (2.x or 3.x) reachable from the phone, on your LAN or behind a reverse proxy. A demo mode with six recipes lets you look around before connecting to anything.</p>
<p><b>Honest limits</b><br>The cookbook is read-only: recipes cannot be created or edited in the app. Writes need a network connection. One shopping list for now. The token expires after about two days, and then you sign in again.</p>
<p><b>Free software</b><br>GPL-3.0, source and issues on GitHub. Not affiliated with the Mealie project.</p>"""

CHANGELOG = """First release.

- Tonight: today's meal plan, with dinner as a full-bleed card
- Cookbook: search, category filters, recipe pages with ingredients
- Cook mode: one step at a time, large type, tap anywhere to advance
- Shopping list: check off, swipe to remove, add this week's ingredients
- Sign in with your own Mealie server; no account with us, no tracking

Requires Mealie 2.x or 3.x. Read-only cookbook for now."""

CREAM = (251, 246, 238)
INK = (25, 21, 18)
EMBER = (188, 63, 27)
MUTED = (110, 101, 92)

FONTS = [
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/System/Library/Fonts/NewYork.ttf",
]


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONTS:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def check_text() -> list[str]:
    errors = []
    if len(TITLE) > 30:
        errors.append(f"title is {len(TITLE)} chars (max 30)")
    if len(SHORT) > 80:
        errors.append(f"short description is {len(SHORT)} chars (max 80)")
    if SHORT.rstrip().endswith("."):
        errors.append("short description must not end with a dot")
    if len(FULL) > 3700:
        errors.append(f"full description is {len(FULL)} chars (max 3700 safe)")
    if len(CHANGELOG.encode()) > 500:
        errors.append(f"changelog is {len(CHANGELOG.encode())} bytes (max 500)")
    try:
        CHANGELOG.encode("ascii")
    except UnicodeEncodeError:
        errors.append("changelog must be plain ASCII")
    return errors


def write_text() -> None:
    os.makedirs(os.path.join(META, "changelogs"), exist_ok=True)
    files = {
        "title.txt": TITLE + "\n",
        "short_description.txt": SHORT + "\n",
        "full_description.txt": FULL + "\n",
        f"changelogs/{VERSION_CODE}.txt": CHANGELOG.rstrip() + "\n",
    }
    for name, body in files.items():
        with open(os.path.join(META, name), "w", encoding="utf-8") as f:
            f.write(body)


def write_icon() -> None:
    os.makedirs(IMAGES, exist_ok=True)
    icon = Image.open(ICON_SRC).convert("RGB").resize((512, 512), Image.Resampling.LANCZOS)
    icon.save(os.path.join(IMAGES, "icon.png"), optimize=True)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def write_feature_graphic() -> None:
    W, H = 1024, 500
    canvas = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(canvas)

    # faint ember disc behind the phone, so the banner is not a flat rectangle
    disc = Image.new("L", (W, H), 0)
    ImageDraw.Draw(disc).ellipse([W - 470, -160, W + 60, 390], fill=26)
    disc = disc.filter(ImageFilter.GaussianBlur(60))
    canvas.paste(Image.new("RGB", (W, H), EMBER), (0, 0), disc)

    d = ImageDraw.Draw(canvas)
    d.text((64, 86), "SELF-HOSTED RECIPE CLIENT", font=font(19), fill=MUTED)
    d.text((58, 118), "Mise", font=font(150), fill=INK)
    d.text((64, 292), "Dinner, decided.", font=font(46), fill=EMBER)
    d.rounded_rectangle([64, 366, 176, 372], radius=3, fill=EMBER)
    d.text((64, 392), "Mealie recipes, cook mode and shopping",
           font=font(23), fill=MUTED)

    shot_path = os.path.join(SHOTS_SRC, "today.png")
    if os.path.exists(shot_path):
        shot = Image.open(shot_path).convert("RGB")
        target_h = 430
        target_w = int(shot.width * target_h / shot.height)
        shot = shot.resize((target_w, target_h), Image.Resampling.LANCZOS)
        shot = rounded(shot, 26)

        shadow = Image.new("RGBA", (target_w + 80, target_h + 80), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            [40, 40, target_w + 40, target_h + 40], radius=26, fill=(90, 60, 40, 70))
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        canvas.paste(Image.new("RGB", shadow.size, CREAM),
                     (W - target_w - 96, 26), shadow.split()[3])
        canvas.paste(shot, (W - target_w - 56, 20), shot)

    canvas.save(os.path.join(IMAGES, "featureGraphic.png"), optimize=True)


def write_screenshots() -> None:
    out = os.path.join(IMAGES, "phoneScreenshots")
    os.makedirs(out, exist_ok=True)
    order = ["today", "recipe", "cook", "list", "recipes"]
    for i, name in enumerate(order, start=1):
        src = os.path.join(SHOTS_SRC, f"{name}.png")
        if not os.path.exists(src):
            print(f"  missing screenshot {src}")
            continue
        im = Image.open(src).convert("RGB")
        # store rule: height/width <= 2.0 — pad, never crop, so nothing is lost
        target_w = max(im.width, math.ceil(im.height / 2.0))
        if target_w != im.width:
            bg = im.getpixel((2, 2))
            canvas = Image.new("RGB", (target_w, im.height), bg)
            canvas.paste(im, ((target_w - im.width) // 2, 0))
            im = canvas
        im.save(os.path.join(out, f"{i}.png"), optimize=True)


def check_images() -> list[str]:
    errors = []
    icon = Image.open(os.path.join(IMAGES, "icon.png"))
    if icon.width != icon.height or not (48 <= icon.width <= 512):
        errors.append(f"icon is {icon.size} (must be square, 48..512)")

    fg = Image.open(os.path.join(IMAGES, "featureGraphic.png"))
    if fg.size not in {(1024, 500), (512, 250)}:
        errors.append(f"feature graphic is {fg.size} (need 1024x500 or 512x250)")

    shot_dir = os.path.join(IMAGES, "phoneScreenshots")
    shots = sorted(os.listdir(shot_dir))
    if len(shots) < 2:
        errors.append("need at least 2 phone screenshots")
    for name in shots:
        im = Image.open(os.path.join(shot_dir, name))
        ratio = im.height / im.width
        if ratio > 2.0:
            errors.append(f"{name} ratio {ratio:.3f} > 2.0")
    return errors


def main() -> int:
    errors = check_text()
    if errors:
        for e in errors:
            print("FAIL", e)
        return 1

    write_text()
    write_icon()
    write_feature_graphic()
    write_screenshots()

    img_errors = check_images()
    if img_errors:
        for e in img_errors:
            print("FAIL", e)
        return 1

    print(f"title              {len(TITLE):3}/30   {TITLE}")
    print(f"short description  {len(SHORT):3}/80   {SHORT}")
    print(f"full description   {len(FULL):4}/3700")
    print(f"changelog {VERSION_CODE:<8} {len(CHANGELOG.encode()):3}/500  bytes")
    print(f"icon               {Image.open(os.path.join(IMAGES, 'icon.png')).size}")
    print(f"feature graphic    {Image.open(os.path.join(IMAGES, 'featureGraphic.png')).size}")
    print(f"screenshots        {len(os.listdir(os.path.join(IMAGES, 'phoneScreenshots')))}")
    print("all store constraints pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
