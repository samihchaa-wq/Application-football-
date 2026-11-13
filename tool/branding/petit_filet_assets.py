"""Génère les images de l'appli à partir du logo Petit Filet fourni par Samih.

Le logo n'est pas redessiné : c'est l'image d'origine
(docs/branding/petit-filet/logo_original.png), simplement
- posée sur un carré noir pour les icônes ;
- rendue transparente là où elle est noire (opération exacte « couleur vers
  transparence » : reposée sur du noir, elle redonne l'image d'origine) pour
  l'écran de démarrage et l'écran de connexion (halo estompé sur les bords) ;
- réduite au ballon blanc pour le badge des notifications Android.

Usage : python3 tool/branding/petit_filet_assets.py
"""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/branding/petit-filet/logo_original.png"
img = Image.open(SRC).convert("RGB")
W, H = img.size


# Transparence exacte : alpha = canal le plus lumineux, couleur dé-mélangée du noir.
a = np.asarray(img).astype(np.float64)
alpha = a.max(axis=2)
rgb = np.where(alpha[..., None] > 0, a * 255.0 / np.maximum(alpha, 1)[..., None], 0)
# Le halo de l'image d'origine touche ses bords : on l'estompe sur les
# 60 derniers pixels pour éviter une arête nette sur le fond de l'appli.
ramp = 60.0
yy, xx = np.mgrid[0:H, 0:W]
edge = np.minimum.reduce([xx, W - 1 - xx, yy, H - 1 - yy]) / ramp
alpha = alpha * np.clip(edge, 0, 1)
rgba = np.dstack([np.clip(rgb, 0, 255), alpha]).round().astype(np.uint8)
faded = Image.fromarray(rgba, "RGBA")
trans = faded.resize((720, 480), Image.LANCZOS)
trans.save(ROOT / "web/petit_filet_logo.webp", lossless=True, quality=100)
trans.save(ROOT / "assets/images/petit_filet_logo.webp", lossless=True, quality=100)

def square(size, margin=0.0):
    # Logo au halo estompé, reposé sur du noir : pas de rectangle visible.
    canvas = Image.new("RGB", (W, W), (0, 0, 0))
    inner = int(W * (1 - 2 * margin))
    logo = faded.resize((inner, int(H * inner / W)), Image.LANCZOS)
    canvas.paste(logo, ((W - inner) // 2, (W - logo.height) // 2), logo)
    return canvas.resize((size, size), Image.LANCZOS)


square(512).save(ROOT / "web/icons/Icon-512.png", optimize=True)
square(192).save(ROOT / "web/icons/Icon-192.png", optimize=True)
square(512, margin=0.1).save(ROOT / "web/icons/Icon-maskable-512.png", optimize=True)
square(64).save(ROOT / "web/favicon.png", optimize=True)

# favicon.svg (exigé par les contrôles de publication) : même image, intégrée.
import base64, io
buf = io.BytesIO()
square(256).save(buf, "PNG", optimize=True)
(ROOT / "web/favicon.svg").write_text(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">'
    '<image width="256" height="256" href="data:image/png;base64,'
    + base64.b64encode(buf.getvalue()).decode() + '"/></svg>\n'
)

# Badge : le ballon du logo (cercle, ballon et traînée), en silhouette.
ball = np.asarray(img.crop((500, 325, 805, 630))).astype(np.float64)
white = np.clip((ball.max(axis=2) - 120) * 255.0 / 80, 0, 255)
badge = np.zeros((*white.shape, 4), np.uint8)
badge[..., :3] = 255
badge[..., 3] = white.round().astype(np.uint8)
b = Image.fromarray(badge, "RGBA").resize((88, 88), Image.LANCZOS)
out = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
out.paste(b, (4, 4))
out.save(ROOT / "web/icons/notification-badge-96.png", optimize=True)
print("ok")
