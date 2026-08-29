#!/usr/bin/env python3
"""Ett HEIC (eller vilket bildformat Pillow läser) → JPG, max 2000 px.

Reservvägen i convert-photos.sh när varken sips, ImageMagick eller
heif-convert finns. Behöver `pip install pillow pillow-heif`.

Anledningen att den finns: HEIC går inte att öppna med Read, och i en
miljö utan systemverktyg fanns förut ingen väg alls. Med pillow-heif
finns den, och då ska skriptet använda den i stället för att ge upp.
"""
import sys
from PIL import Image, ImageOps

try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    sys.exit("pillow-heif saknas: pip install pillow pillow-heif")

if len(sys.argv) != 3:
    sys.exit("användning: heic2jpg.py <in> <ut.jpg>")

kalla, mal = sys.argv[1], sys.argv[2]
bild = ImageOps.exif_transpose(Image.open(kalla))   # respektera rotationen
if bild.mode not in ("RGB", "L"):
    bild = bild.convert("RGB")
bild.thumbnail((2000, 2000), Image.LANCZOS)         # skalar bara ner
bild.save(mal, "JPEG", quality=88, optimize=True)
