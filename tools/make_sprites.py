#!/usr/bin/env python
"""用 Pillow 生成像素精灵 PNG。"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "game" / "art" / "sprites"
ROOT.mkdir(parents=True, exist_ok=True)


def save(name: str, w: int, h: int, paint) -> None:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    paint(d, w, h)
    path = ROOT / name
    img.save(path, "PNG")
    print("wrote", path.name, img.size)


def player(d, w, h):
    d.rectangle([4, 10, 11, 19], fill=(91, 143, 168, 255))
    d.ellipse([4, 3, 12, 11], fill=(240, 208, 176, 255))
    d.rectangle([4, 3, 11, 5], fill=(80, 60, 40, 255))
    d.rectangle([4, 20, 6, 22], fill=(50, 40, 30, 255))
    d.rectangle([9, 20, 11, 22], fill=(50, 40, 30, 255))


def crop_turnip(d, w, h):
    d.ellipse([4, 6, 12, 14], fill=(245, 240, 225, 255))
    d.rectangle([7, 3, 8, 9], fill=(143, 188, 107, 255))
    d.ellipse([4, 2, 8, 6], fill=(143, 188, 107, 255))
    d.ellipse([8, 2, 12, 6], fill=(143, 188, 107, 255))


def crop_tomato(d, w, h):
    d.ellipse([3, 5, 13, 15], fill=(224, 85, 85, 255))
    d.rectangle([7, 2, 8, 6], fill=(107, 155, 74, 255))


def crop_berry(d, w, h):
    d.ellipse([3, 5, 13, 15], fill=(224, 96, 144, 255))
    d.ellipse([2, 7, 6, 11], fill=(200, 70, 120, 255))
    d.ellipse([10, 7, 14, 11], fill=(200, 70, 120, 255))


def item_bell(d, w, h):
    d.ellipse([3, 3, 13, 13], fill=(232, 200, 122, 255))
    d.rectangle([7, 1, 8, 4], fill=(139, 105, 20, 255))
    d.rectangle([7, 12, 8, 14], fill=(139, 105, 20, 255))


def item_wood(d, w, h):
    d.rectangle([2, 6, 13, 10], fill=(184, 149, 108, 255))
    d.line([2, 6, 13, 6], fill=(220, 190, 150, 255))


def tile_grass(d, w, h):
    d.rectangle([0, 0, w, h], fill=(143, 181, 111, 255))
    for x, y in [(4, 6), (12, 2), (20, 14), (26, 22), (8, 24)]:
        d.rectangle([x, y, x + 1, y + 2], fill=(127, 163, 106, 255))


def tile_soil(d, w, h):
    d.rectangle([0, 0, w, h], fill=(92, 64, 48, 255))
    d.rectangle([0, 0, w, 1], fill=(70, 48, 34, 255))


def tile_path(d, w, h):
    d.rectangle([0, 0, w, h], fill=(210, 180, 140, 255))


if __name__ == "__main__":
    save("player.png", 16, 24, player)
    save("crop_turnip.png", 16, 16, crop_turnip)
    save("crop_tomato.png", 16, 16, crop_tomato)
    save("crop_berry.png", 16, 16, crop_berry)
    save("item_bell.png", 16, 16, item_bell)
    save("item_wood.png", 16, 16, item_wood)
    save("tile_grass.png", 32, 32, tile_grass)
    save("tile_soil.png", 32, 32, tile_soil)
    save("tile_path.png", 32, 32, tile_path)
    print("ok", ROOT)
