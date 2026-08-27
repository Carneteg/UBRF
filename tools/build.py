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

ut = re.sub(r'<script src="([^"]+)"></script>', bädda_in, html)
(ROT / "dist").mkdir(exist_ok=True)
(ROT / "dist" / "ridskolan.html").write_text(ut, encoding="utf-8")
print("dist/ridskolan.html:", len(ut), "tecken")
