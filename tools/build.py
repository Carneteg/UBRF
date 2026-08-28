#!/usr/bin/env python3
"""Bygger dist/ridskolan.html — en enda HTML-fil av index.html + src/*.js.

Artefakt-versionen av spelet är en fil utan externa beroenden
(förutom Google Fonts som är tillåtet). Skriptordningen tas från
index.html så den inte kan glida ur synk med utvecklingsversionen.
"""
import re, pathlib

ROT = pathlib.Path(__file__).resolve().parent.parent
html = (ROT / "index.html").read_text(encoding="utf-8")

def bädda_in(m):
    js = (ROT / m.group(1)).read_text(encoding="utf-8")
    return "<script>\n" + js + "</script>"

def bädda_css(m):
    """Lokala stilmallar bakas in. Google Fonts lämnas som länk."""
    sökväg = m.group(1)
    if sökväg.startswith("http"):
        return m.group(0)
    css = (ROT / sökväg).read_text(encoding="utf-8")
    return "<style>\n" + css + "</style>"

def sprite_data():
    """Bakar in assets/*.png som data-URI:er, så att den byggda filen
    fortfarande är en enda fil utan nätverk."""
    import base64, json
    katalog = ROT / "assets"
    if not katalog.is_dir():
        return ""
    poster = {}
    for fil in sorted(katalog.glob("*.png")):
        rå = fil.read_bytes()
        poster[fil.stem] = "data:image/png;base64," + base64.b64encode(rå).decode("ascii")
    if not poster:
        return ""
    kb = sum(len(v) for v in poster.values()) // 1024
    print(f"  sprites: {len(poster)} st, {kb} kB inbakade")
    return "<script>window.SPRITE_DATA=" + json.dumps(poster) + ";</script>\n"

html = html.replace("<script src=", sprite_data() + "<script src=", 1)

ut = re.sub(r'<script src="([^"]+)"></script>', bädda_in, html)
ut = re.sub(r'<link rel="stylesheet" href="([^"]+)">', bädda_css, ut)
(ROT / "dist").mkdir(exist_ok=True)
(ROT / "dist" / "ridskolan.html").write_text(ut, encoding="utf-8")
print("dist/ridskolan.html:", len(ut), "tecken")
