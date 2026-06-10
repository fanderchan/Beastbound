#!/usr/bin/env python3
"""图像规格化工具：cover 缩放 + 居中裁剪到目标尺寸。"""
import sys
from PIL import Image


def normalize(src: str, dst: str, w: int, h: int) -> None:
    img = Image.open(src).convert("RGBA")
    sw, sh = img.size
    scale = max(w / sw, h / sh)
    nw, nh = round(sw * scale), round(sh * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    img = img.crop((x, y, x + w, y + h))
    img.save(dst)
    print(f"normalize {src} {sw}x{sh} -> {dst} {w}x{h}")


if __name__ == "__main__":
    if sys.argv[1] == "normalize":
        normalize(sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]))
    else:
        raise SystemExit("usage: img.py normalize <src> <dst> <w> <h>")
