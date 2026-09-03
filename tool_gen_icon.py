# -*- coding: utf-8 -*-
"""Генератор иконки Max Vektor (буква V).

Самостоятельная иконка, не использует логотип/брендинг официального MAX.
Запуск:  python tool_gen_icon.py
"""
import os
from PIL import Image, ImageDraw

SS = 8  # supersampling

BG_TOP = (16, 20, 28)
BG_BOTTOM = (26, 33, 48)
V_TOP = (86, 205, 255)
V_BOTTOM = (37, 99, 235)

# Полигон буквы V в нормализованных координатах.
V_POLY = [
    (0.185, 0.255),
    (0.350, 0.255),
    (0.500, 0.605),
    (0.650, 0.255),
    (0.815, 0.255),
    (0.500, 0.775),
]


def _vgrad(size, c0, c1):
    img = Image.new("RGB", (1, size))
    px = img.load()
    for y in range(size):
        t = y / max(1, size - 1)
        px[0, y] = tuple(round(c0[i] + (c1[i] - c0[i]) * t) for i in range(3))
    return img.resize((size, size), Image.NEAREST)


def render(size, rounded=False, radius_ratio=0.2237):
    s = size * SS
    base = _vgrad(s, BG_TOP, BG_BOTTOM)

    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).polygon([(x * s, y * s) for x, y in V_POLY], fill=255)
    base.paste(_vgrad(s, V_TOP, V_BOTTOM), (0, 0), mask)

    img = base.convert("RGBA")
    if rounded:
        corner = Image.new("L", (s, s), 0)
        ImageDraw.Draw(corner).rounded_rectangle(
            [0, 0, s - 1, s - 1], radius=int(s * radius_ratio), fill=255
        )
        img.putalpha(corner)
    return img.resize((size, size), Image.LANCZOS)


IOS_DIR = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
IOS = [
    ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

ANDROID = [
    ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
    ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
    ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
    ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
    ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
]

if __name__ == "__main__":
    for name, sz in IOS:
        # iOS AppIcon не допускает альфа-канал.
        render(sz).convert("RGB").save(os.path.join(IOS_DIR, name), "PNG")
        print("ios", name, sz)
    for path, sz in ANDROID:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        render(sz, rounded=True).save(path, "PNG")
        print("android", path, sz)
    render(1024, rounded=True).save("docs/max_vektor_icon.png", "PNG")
    print("done")
