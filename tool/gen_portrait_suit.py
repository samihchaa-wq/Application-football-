#!/usr/bin/env python3
"""Génère assets/composition/portrait_suit.png : le costume du coach.

Même silhouette (alpha) et mêmes plis d'épaules que le maillot validé
(portrait_jersey_luma.png), sans la maille du maillot ; ajoute la chemise,
les revers, la cravate et un tissu de laine. Couleurs cuites dans l'image.
Usage : python3 tool/gen_portrait_suit.py
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = 'assets/composition/'
S = 3  # sur-échantillonnage des formes
W, H = 720, 288

luma = Image.open(SRC + 'portrait_jersey_luma.png').convert('RGBA')
collar = Image.open(SRC + 'portrait_jersey_collar.png').convert('RGBA')
sil = np.array(luma)[..., 3].astype(np.float32) / 255
ring = np.array(collar)[..., 3].astype(np.float32) / 255

# Plis seuls : on lisse la maille du maillot.
gray = luma.convert('L').filter(ImageFilter.GaussianBlur(2.4))
fold = np.array(gray).astype(np.float32) / 255
fold = np.clip((fold - fold.min()) / (fold.max() - fold.min()), 0, 1)


def mask(polys, blur=0.9):
    im = Image.new('L', (W * S, H * S), 0)
    d = ImageDraw.Draw(im)
    for p in polys:
        d.polygon([(x * S, y * S) for x, y in p], fill=255)
    im = im.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(blur))
    return np.array(im).astype(np.float32) / 255


def lerp_color(c, lo, hi):
    return np.array(c, np.float32)


yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
cx = 360.0

# --- Tissu de la veste : laine bleu nuit, sergé fin ---
rng = np.random.default_rng(7)
twill = 0.5 + 0.5 * np.sin((xx + yy * 1.0) * 2.1)
grain = rng.normal(0, 1, (H, W)).astype(np.float32)
grain = np.array(Image.fromarray(((grain - grain.min()) / (grain.max() - grain.min()) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))).astype(np.float32) / 255
cloth = 0.80 + 0.12 * twill + 0.14 * (grain - 0.5)
light = (fold ** 1.9) * 1.25 + 0.22
base = np.array([30, 41, 70], np.float32)
jacket = base[None, None, :] * (light * cloth)[..., None]
# reflets doux sur les épaules
shoulder_hi = np.exp(-(((np.abs(xx - cx) - 215) / 85) ** 2) - (((yy - 120) / 60) ** 2))
jacket += (shoulder_hi[..., None] * np.array([20, 26, 40], np.float32))

img = jacket.copy()

# --- Chemise ---
shirt_poly = [[(272, 92), (448, 92), (372, 262), (348, 262)]]
shirt = mask(shirt_poly)
shirt_col = np.array([244, 246, 250], np.float32)
shirt_light = 0.80 + 0.20 * np.clip((yy - 90) / 170, 0, 1)
shirt_light *= 0.88 + 0.12 * (fold ** 1.2)
# ombre portée par les revers (bords de la chemise plus sombres)
edge = np.minimum(np.abs(xx - cx) / 70.0, 1.0)
shirt_light *= 0.62 + 0.38 * edge ** 0.6
shirt_img = shirt_col[None, None, :] * shirt_light[..., None]
img = img * (1 - shirt[..., None]) + shirt_img * shirt[..., None]

# --- Revers ---
for side in (-1, 1):
    pts = [(cx + side * 128, 58), (cx + side * 88, 98), (cx + side * 10, 252),
           (cx + side * 22, 290), (cx + side * 98, 290), (cx + side * 108, 178),
           (cx + side * 132, 150)]
    lap = mask([pts])
    lapel_light = 0.95 + 0.35 * np.clip(1 - np.abs(yy - 170) / 140, 0, 1)
    lapel_col = np.array([40, 53, 88], np.float32)[None, None, :] * (lapel_light * cloth * (0.7 + 0.5 * fold ** 1.5))[..., None]
    img = img * (1 - lap[..., None]) + lapel_col * lap[..., None]
    # liseré cousu le long du bord intérieur
    edge_line = mask([[(cx + side * 88, 98), (cx + side * 84, 98), (cx + side * 6, 252), (cx + side * 10, 252)]], 0.7)
    img = img * (1 - 0.55 * edge_line[..., None])
    outer_edge = mask([[(cx + side * 132, 150), (cx + side * 108, 178), (cx + side * 98, 290), (cx + side * 102, 290), (cx + side * 113, 180), (cx + side * 136, 150)]], 1.4)
    img = img * (1 - 0.5 * outer_edge[..., None])
    # ombre du revers sur la chemise
    sh = mask([[(cx + side * 88, 98), (cx + side * 68, 100), (cx + side * 4, 252), (cx + side * 10, 252)]], 5)
    img = img * (1 - 0.30 * (sh * shirt)[..., None])

# --- Cravate ---
knot = mask([[(337, 100), (383, 100), (376, 150), (344, 150)]], 0.7)
blade = mask([[(343, 148), (377, 148), (394, 238), (360, 266), (326, 238)]], 0.7)
tie = np.clip(knot + blade, 0, 1)
silk = 0.62 + 0.55 * np.exp(-(((xx - cx + 6) / 11) ** 2))   # reflet de soie
silk *= 0.85 + 0.15 * np.sin((xx - yy * 0.6) * 0.55)          # fines rayures en biais
tie_img = np.array([158, 26, 42], np.float32)[None, None, :] * silk[..., None]
# nœud plus sombre en dessous, pli au centre
tie_img *= (1 - 0.35 * np.exp(-(((yy - 152) / 7) ** 2)))[..., None]
img = img * (1 - tie[..., None]) + tie_img * tie[..., None]

# --- Col : bande intérieure = col de chemise blanc, bande extérieure = col de veste ---
opening = np.zeros((H, W), np.float32)
opening[20:140, 236:488] = 1 - sil[20:140, 236:488]
opening_blur = np.array(Image.fromarray((opening * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5.5))).astype(np.float32) / 255
inner = np.clip((opening_blur - 0.22) * 6, 0, 1) * ring          # fine bande blanche
outer = ring * (1 - inner)
ring_light = 0.78 + 0.30 * (np.array(luma.convert('L')).astype(np.float32) / 255)
white_img = shirt_col[None, None, :] * ring_light[..., None]
collar_navy = np.array([46, 60, 98], np.float32)[None, None, :] * (ring_light * (0.95 + 0.1 * grain))[..., None]
img = img * (1 - outer[..., None]) + collar_navy * outer[..., None]
img = img * (1 - inner[..., None]) + white_img * inner[..., None]
# pointes du col de chemise, par-dessus les revers
for side in (-1, 1):
    pts = [(cx + side * 62, 108), (cx + side * 14, 120), (cx + side * 40, 178)]
    pt = mask([pts], 0.7)
    flap = shirt_col[None, None, :] * (0.78 + 0.22 * np.clip((yy - 105) / 80, 0, 1))[..., None]
    img = img * (1 - pt[..., None]) + flap * pt[..., None]
    shadow = mask([[(cx + side * 62, 108), (cx + side * 70, 112), (cx + side * 44, 184), (cx + side * 40, 178)]], 3)
    img = img * (1 - 0.35 * (shadow * (1 - pt))[..., None])

# --- Ombre sous le menton / col ---
under = np.exp(-(((yy - 138) / 14) ** 2)) * np.exp(-(((xx - cx) / 120) ** 2))
img *= (1 - 0.25 * under)[..., None]

out = np.dstack([np.clip(img, 0, 255).astype(np.uint8), (sil * 255).astype(np.uint8)])
Image.fromarray(out, 'RGBA').save(SRC + 'portrait_suit.png', optimize=True)
print('ok', out.shape)
