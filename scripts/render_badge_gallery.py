#!/usr/bin/env python3
"""Contact sheet of the 14 approved Petit Filet JPEG backgrounds.

This previews packaged assets, not complete Flutter widgets or players' portraits.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    ('GRIS', 'gris.jpg'), ('BRONZE', 'bronze.jpg'), ('ARGENT', 'argent.jpg'),
    ('OR', 'or.jpg'), ('BLEU CLAIR', 'bleu_clair.jpg'), ('BLEU', 'bleu.jpg'),
    ('BLEU FONCÉ', 'bleu_fonce.jpg'), ('NOIR', 'noir.jpg'),
    ('ORANGE', 'orange.jpg'), ('RUBIS', 'rubis.jpg'), ('GRENAT', 'grenat.jpg'),
    ('DIAMANT', 'diamant.jpg'), ('ÉMERAUDE', 'emeraude.jpg'),
    ('VIOLET', 'violet.jpg'),
]

def generate(asset_dir: Path, output: Path) -> None:
    missing = [name for _, name in ASSETS if not (asset_dir / name).is_file()]
    if missing:
        raise FileNotFoundError('Missing assets: ' + ', '.join(missing))
    image = Image.new('RGB', (1050, 1380), '#101624')
    draw = ImageDraw.Draw(image)
    fontfile = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
    font = ImageFont.truetype(fontfile, 30) if Path(fontfile).exists() else ImageFont.load_default()
    label_font = ImageFont.truetype(fontfile, 20) if Path(fontfile).exists() else ImageFont.load_default()
    draw.text((38, 24), 'PETIT FILET  /  14 FONDS PREMIUM', fill='#f7fafc', font=font)
    for i, (label, filename) in enumerate(ASSETS):
        col, row = i % 4, i // 4
        x, y = 30 + col * 250, 125 + row * 320
        with Image.open(asset_dir / filename) as source:
            if source.format != 'JPEG' or source.size != (180, 240):
                raise ValueError(f'Invalid badge artwork: {filename}')
            tile = source.convert('RGB').resize((192, 256), Image.Resampling.LANCZOS)
        image.paste(tile, (x + 24, y))
        left, upper, right, lower = draw.textbbox((0, 0), label, font=label_font)
        draw.text((x + (250 - (right - left))/2, y + 269), label,
                  font=label_font, fill='#f7fafc')
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, 'PNG', optimize=True)
    print(f'14 backgrounds validated for gallery: {output}')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets', type=Path,
                        default=Path('assets/images/badge_backgrounds'))
    parser.add_argument('--output', type=Path,
                        default=Path('badge-previews/quatorze_fonds_premium.png'))
    args = parser.parse_args()
    generate(args.assets, args.output)
