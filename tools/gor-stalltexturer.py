#!/usr/bin/env python3
"""Gör stallgångens fototexturer (Batch 1.4) ur fotona i references/.

Varje material tas ur ETT foto i repot, ur ett parti som ligger så nära rakt
framifrån som möjligt, och görs till en sömlös ruta:

  1. utsnitt ur en fyrhörning i originalet (perspektivet rätas upp grovt),
  2. ljusfallet i fotot tas bort (bilden delas med en kraftigt suddad kopia
     av sig själv — kvar blir strukturen, inte var lampan stod),
  3. kanterna görs sömlösa: först i sidled, sedan i höjdled, genom att
     blanda med en halvvägs förskjuten kopia nära kanterna,
  4. medelfärgen sätts till kortets uppmätta värde (IDENTITET i src/site.js,
     STALLINNE.gangSten) — kortet är facit för färgen, fotot för strukturen.

Källorna är foton UTAN personer, registreringsskyltar eller läsbara namn
(se references/DRIVE-MANIFEST-2026-11-26.tsv). Klubbens samtycke:
references/licenses/SAMTYCKE-UBRF-2026-11-28.md.

Kör (en Python med Pillow):
    python3 tools/gor-stalltexturer.py            skriver assets/textures/
    python3 tools/gor-stalltexturer.py --ark DIR  skriver också ett
        kontaktark per material: utsnittet i originalet bredvid rutan.
"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

ROT = pathlib.Path(__file__).resolve().parent.parent
STALL = "references/buildings/stall/"
UT = ROT / "assets" / "textures"
SAMTYCKE = "references/licenses/SAMTYCKE-UBRF-2026-11-28.md"

# Fyrhörningarna i ORIGINALETS pixlar, i ordningen uppe-vänster, uppe-höger,
# nere-höger, nere-vänster. `meter` är rutans storlek i världen (bredd, höjd)
# — skuggaren lägger den efter läget i meter. Alla mått är [antagande],
# lästa ur bilderna (räknade plattor, brädor och korrugeringar).
MATERIAL = [
    {"fil": "stall-marksten.jpg", "kalla": STALL + "stall-inne-05-stallgangen.jpg",
     # Gångens marksten nära kameran, där plattraderna är minst förkortade:
     # fyra plattor i bredd, fyra rader i höjd (plattan ≈ 0,22 × 0,11 m).
     "quad": [(600, 1280), (1040, 1280), (1040, 1500), (600, 1500)],
     "storlek": (512, 256), "meter": (0.90, 0.45), "kort": "#867D6C",
     "vad": "markstensgången (STALLINNE.gangSten)"},
    {"fil": "stall-boxpanel.jpg", "kalla": STALL + "drive-2026-11-26/IMG_0153-stall-boxgangar.jpg",
     # Den täta panelen under kappregeln, rakt framifrån: sex brädor i bredd.
     "quad": [(1150, 880), (1958, 880), (1958, 1530), (1150, 1530)],
     "storlek": (256, 256), "meter": (0.72, 0.72), "kort": "#454A4F",
     "vad": "boxfrontens täta panel (IDENTITET.stall.boxfront.heldel)"},
    {"fil": "stall-galv.jpg", "kalla": STALL + "drive-2026-11-26/IMG_0153-stall-boxgangar.jpg",
     # Mittpartiet av en galvad stolpe — kanterna, där röret böjer av
     # och mörknar, är bortskurna.
     "quad": [(1062, 880), (1118, 880), (1118, 1500), (1062, 1500)],
     "storlek": (64, 512), "meter": (0.12, 0.48), "kort": "#9A9B93",
     "vad": "boxfrontens galvade ram, stolpar och reglar (IDENTITET.stall.boxfront.ram)"},
    {"fil": "stall-takplat.jpg", "kalla": STALL + "drive-2026-11-26/IMG_0153-stall-boxgangar.jpg",
     # Takplåten mellan två rör, sedd underifrån nästan rakt.
     "quad": [(676, 4), (1003, 4), (1003, 248), (676, 248)],
     "storlek": (256, 256), "meter": (3.0, 3.0), "kort": "#70716E",
     "vad": "takplåten (IDENTITET.stall.stallgang.takplat)"},
    {"fil": "stall-limtra.jpg", "kalla": STALL + "stall-inne-05-stallgangen.jpg",
     # En sparre längs sin sida: fyrhörningen följer balken, så att
     # fibrerna blir vågräta i rutan.
     "quad": [(1367, 111), (1622, 211), (1622, 283), (1367, 194)],
     "storlek": (512, 128), "meter": (1.6, 0.4), "kort": "#AD8A70",
     "vad": "limträsparrarna (IDENTITET.stall.stallgang.limtra)"},
]


def los(a, b):
    """Löser a·x = b (8×8) med Gauss-elimination — inget numpy behövs."""
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(m[r][k]))
        m[k], m[p] = m[p], m[k]
        for r in range(k + 1, n):
            f = m[r][k] / m[k][k]
            for c in range(k, n + 1):
                m[r][c] -= f * m[k][c]
    x = [0.0] * n
    for k in range(n - 1, -1, -1):
        x[k] = (m[k][n] - sum(m[k][c] * x[c] for c in range(k + 1, n))) / m[k][k]
    return x


def perspektiv(bild, quad, storlek):
    """Utsnitt ur en fyrhörning, uträtat till en rektangel."""
    w, h = storlek
    mal = [(0, 0), (w, 0), (w, h), (0, h)]
    a, b = [], []
    for (x, y), (u, v) in zip(mal, quad):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.append(u)
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y]); b.append(v)
    return bild.transform((w, h), Image.PERSPECTIVE, los(a, b), Image.BICUBIC)


def utjamna(bild):
    """Tar bort ljusfallet: dela med en kraftigt suddad kopia, behåll medel."""
    r = max(bild.size) // 3
    sudd = bild.filter(ImageFilter.GaussianBlur(r))
    pb, ps = bild.load(), sudd.load()
    w, h = bild.size
    medel = [sum(ps[x, y][c] for x in range(w) for y in range(h)) / (w * h) for c in range(3)]
    ut = Image.new("RGB", bild.size)
    pu = ut.load()
    for y in range(h):
        for x in range(w):
            pu[x, y] = tuple(min(255, int(pb[x, y][c] * medel[c] / max(ps[x, y][c], 1) + 0.5)) for c in range(3))
    return ut


def somlos(bild):
    """Sömlösa kanter: först i sidled, sedan i höjdled. I varje pass blandas
    bilden med en halvvägs förskjuten kopia av sig själv nära kanterna —
    kopians kanter är originalets mitt, och den möter sig själv."""
    def pass_(b, axel):
        w, h = b.size
        forsk = Image.new("RGB", b.size)
        if axel == 0:
            forsk.paste(b.crop((w // 2, 0, w, h)), (0, 0)); forsk.paste(b.crop((0, 0, w // 2, h)), (w - w // 2, 0))
        else:
            forsk.paste(b.crop((0, h // 2, w, h)), (0, 0)); forsk.paste(b.crop((0, 0, w, h // 2)), (0, h - h // 2))
        mask = Image.new("L", b.size)
        pm = mask.load()
        n = w if axel == 0 else h
        band = max(2, n // 4)
        for y in range(h):
            for x in range(w):
                t = x if axel == 0 else y
                d = min(t, n - 1 - t)                       # avstånd till närmaste kant
                s = min(1.0, d / band)
                pm[x, y] = int(255 * s * s * (3 - 2 * s))   # 0 vid kanten, 1 inåt
        return Image.composite(b, forsk, mask)
    return pass_(pass_(bild, 0), 1)


def till_kort(bild, kort):
    """Sätter medelfärgen till kortets värde, kanal för kanal."""
    mal = [int(kort[i:i + 2], 16) for i in (1, 3, 5)]
    w, h = bild.size
    p = bild.load()
    medel = [sum(p[x, y][c] for x in range(w) for y in range(h)) / (w * h) for c in range(3)]
    fakt = [mal[c] / max(medel[c], 1) for c in range(3)]
    ut = bild.copy()
    pu = ut.load()
    for y in range(h):
        for x in range(w):
            pu[x, y] = tuple(min(255, int(p[x, y][c] * fakt[c] + 0.5)) for c in range(3))
    return ut, medel


def main():
    ark = pathlib.Path(sys.argv[sys.argv.index("--ark") + 1]) if "--ark" in sys.argv else None
    UT.mkdir(parents=True, exist_ok=True)
    rader = []
    for m in MATERIAL:
        orig = Image.open(ROT / m["kalla"]).convert("RGB")
        r = somlos(utjamna(perspektiv(orig, m["quad"], m["storlek"])))
        r, fotomedel = till_kort(r, m["kort"])
        mal = UT / m["fil"]
        r.save(mal, "JPEG", quality=85, optimize=True)
        storlek = mal.stat().st_size
        rader.append("%s\t%s, fyrhörning %s; %s\tubrf-foto\t%s" % (
            m["fil"], m["kalla"], " ".join("%d,%d" % p for p in m["quad"]), m["vad"], SAMTYCKE))
        print("  %-20s %4d×%-4d %6d byte · fotots medel %s → kortets %s" % (
            m["fil"], r.size[0], r.size[1], storlek, "/".join("%d" % v for v in fotomedel), m["kort"]))
        if ark:
            ark.mkdir(parents=True, exist_ok=True)
            vis = orig.copy()
            ImageDraw.Draw(vis).polygon(m["quad"], outline=(255, 220, 0), width=6)
            vis.thumbnail((900, 900))
            tre = Image.new("RGB", (r.size[0] * 3, r.size[1] * 2))
            for i in range(3):
                for j in range(2):
                    tre.paste(r, (i * r.size[0], j * r.size[1]))
            tre.thumbnail((900, 600))
            sida = Image.new("RGB", (vis.size[0] + tre.size[0] + 20, max(vis.size[1], tre.size[1])), (32, 32, 32))
            sida.paste(vis, (0, 0)); sida.paste(tre, (vis.size[0] + 20, 0))
            sida.save(ark / ("ark-" + m["fil"]), "JPEG", quality=85)
    kallor = UT / "KALLOR.tsv"
    befintliga = [r for r in kallor.read_text(encoding="utf-8").splitlines()[1:]
                  if r.strip() and r.split("\t")[0] not in {m["fil"] for m in MATERIAL}]
    kallor.write_text("fil\tkalla\trattighet\tsamtycke\n" + "".join(x + "\n" for x in befintliga + rader), encoding="utf-8")
    print("  KALLOR.tsv: %d rader" % (len(befintliga) + len(rader)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
