"""Décline le logo rouge/anthracite transparent fourni pour Petit Filet.

Usage : python3 tool/branding/petit_filet_assets.py
La source détourage reste intacte. Seuls recadrages et réductions sont faits.
"""
import base64
import io
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/branding/petit-filet/logo_red_transparent.png"
img = Image.open(SRC).convert("RGBA")
W, H = img.size

# Logo complet, sans tuile de fond : le contour argenté assure la lisibilité.
logo = img.resize((720, 480), Image.Resampling.LANCZOS)
for destination in ["web/petit_filet_logo.webp", "assets/images/petit_filet_logo.webp"]:
    logo.save(ROOT / destination, lossless=True, quality=100)

# En petit, le monogramme PF/ballon/filet se lit mieux que le nom complet.
# Extraction dédiée, sans aucun fragment du mot « Petit Filet ».
mark = Image.open(ROOT / "docs/branding/petit-filet/monogram_red_transparent.png").convert("RGBA")
mark = mark.crop(mark.getbbox())


def square(size, margin=.08):
    """Icône opaque anthracite ; le logo lui-même conserve son alpha."""
    canvas = Image.new("RGBA", (size, size), "#101418")
    scaled = mark.copy()
    inner = round(size * (1 - 2 * margin))
    scaled.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    canvas.alpha_composite(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2))
    return canvas.convert("RGB")


square(512).save(ROOT / "web/icons/Icon-512.png", optimize=True)
square(192).save(ROOT / "web/icons/Icon-192.png", optimize=True)
# Le monogramme entier tient dans le cercle sûr central (diamètre 80 %).
square(512, margin=.20).save(ROOT / "web/icons/Icon-maskable-512.png", optimize=True)
square(64, margin=.04).save(ROOT / "web/favicon.png", optimize=True)

buf = io.BytesIO()
square(256).save(buf, "PNG", optimize=True)
(ROOT / "web/favicon.svg").write_text(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">'
    '<image width="256" height="256" href="data:image/png;base64,'
    + base64.b64encode(buf.getvalue()).decode() + '"/></svg>\n'
)

# Android ne lit que l'alpha : les faces claires du ballon deviennent blanches.
ball = np.asarray(img.crop((int(W * .315), int(H * .323), int(W * .513), int(H * .625))))
whiteness = np.clip((ball[..., :3].min(axis=2).astype(float) - 150) * 255 / 80, 0, 255)
alpha = whiteness * np.clip(ball[..., 3] / 250, 0, 1)
badge = np.zeros((*alpha.shape, 4), np.uint8)
badge[..., :3] = 255
badge[..., 3] = alpha.round().astype(np.uint8)
b = Image.fromarray(badge).resize((88, 88), Image.Resampling.LANCZOS)
out = Image.new("RGBA", (96, 96))
out.alpha_composite(b, (4, 4))
out.save(ROOT / "web/icons/notification-badge-96.png", optimize=True)
print("Logo, icônes, favicon et badge régénérés.")
