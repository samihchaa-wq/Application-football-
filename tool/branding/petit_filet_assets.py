"""Génère les images de l'appli à partir du logo Petit Filet fourni par Samih.

Le logo n'est pas redessiné ni retouché : c'est l'image d'origine
(docs/branding/petit-filet/logo_original.png, fond transparent), utilisée
- telle quelle (avec sa transparence) pour l'écran de démarrage et l'écran
  de connexion, où elle est posée sur une tuile blanche ;
- posée sur un carré blanc pour les icônes et le favicon ;
- réduite au ballon blanc pour le badge des notifications Android.

Usage : python3 tool/branding/petit_filet_assets.py
"""
import base64
import io
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/branding/petit-filet/logo_original.png"
img = Image.open(SRC).convert("RGBA")
W, H = img.size

# Écran de démarrage et connexion : l'image d'origine, transparence comprise.
logo = img.resize((720, 480), Image.LANCZOS)
logo.save(ROOT / "web/petit_filet_logo.webp", lossless=True, quality=100)
logo.save(ROOT / "assets/images/petit_filet_logo.webp", lossless=True, quality=100)


def square(size, margin=0.04):
    """Le logo entier, centré sur un carré blanc."""
    canvas = Image.new("RGBA", (W, W), (255, 255, 255, 255))
    inner = int(W * (1 - 2 * margin))
    scaled = img.resize((inner, int(H * inner / W)), Image.LANCZOS)
    canvas.alpha_composite(scaled, ((W - inner) // 2, (W - scaled.height) // 2))
    return canvas.convert("RGB").resize((size, size), Image.LANCZOS)


square(512).save(ROOT / "web/icons/Icon-512.png", optimize=True)
square(192).save(ROOT / "web/icons/Icon-192.png", optimize=True)
square(512, margin=0.12).save(ROOT / "web/icons/Icon-maskable-512.png", optimize=True)
square(64).save(ROOT / "web/favicon.png", optimize=True)

# favicon.svg (exigé par les contrôles de publication) : même image, intégrée.
buf = io.BytesIO()
square(256).save(buf, "PNG", optimize=True)
(ROOT / "web/favicon.svg").write_text(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">'
    '<image width="256" height="256" href="data:image/png;base64,'
    + base64.b64encode(buf.getvalue()).decode() + '"/></svg>\n'
)

# Badge : les parties blanches du ballon (cercle et faces), en silhouette.
ball = np.asarray(img.crop((500, 325, 805, 630))).astype(np.float64)
whiteness = np.clip((ball[..., :3].min(axis=2) - 150) * 255.0 / 80, 0, 255)
alpha = whiteness * np.clip(ball[..., 3] / 250.0, 0, 1)  # l'original plafonne à 254
badge = np.zeros((*alpha.shape, 4), np.uint8)
badge[..., :3] = 255
badge[..., 3] = alpha.round().astype(np.uint8)
b = Image.fromarray(badge, "RGBA").resize((88, 88), Image.LANCZOS)
out = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
out.paste(b, (4, 4))
out.save(ROOT / "web/icons/notification-badge-96.png", optimize=True)
print("ok")
