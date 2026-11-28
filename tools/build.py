#!/usr/bin/env python3
"""Bygger dist/ridskolan.html — en enda HTML-fil av index.html + src/*.js.

Artefakt-versionen av spelet är en fil utan externa beroenden och utan
nätanrop vid körning. Skriptordningen tas från index.html så den inte
kan glida ur synk med utvecklingsversionen.

BILDFILER (produktbeslut 2026-11-26, Batch 1.3). Regeln «inga bildfiler»
gäller inte längre: texturer i assets/textures/ bakas in som data-URI:er i
window.TEXTUR_DATA. Det som gäller i stället:

  * inget nätverk vid körning — bilderna ligger I filen,
  * den byggda filen får vara högst TAK_BYTE (4 MB); annars avbryts bygget,
  * varje textur har sidor som är tvåpotenser (WebGL1 kräver det för
    mipmaps och upprepning) och är högst TAK_TEXTUR byte,
  * varje textur har en rad i assets/textures/KALLOR.tsv som säger var den
    kommer ifrån. En ruta ur ett UBRF-foto kräver klubbens sparade svar
    (references/licenses/SAMTYCKE-UBRF-<datum>.md) — utkastet räknas inte.

Kör:  python3 tools/build.py
      python3 tools/build.py --texturer KATALOG --ut FIL   (prov: bygg en
          kopia med egna testbilder utan att röra assets/ eller dist/)
      --rot KATALOG pekar ut repots rot när skriptet körs från en kopia.
"""
import base64, json, re, pathlib, struct, sys


def arg(namn, forval):
    if namn in sys.argv:
        return pathlib.Path(sys.argv[sys.argv.index(namn) + 1])
    return forval


ROT = arg("--rot", pathlib.Path(__file__).resolve().parent.parent).resolve()
TEXTURER = arg("--texturer", ROT / "assets" / "textures")
UT = arg("--ut", ROT / "dist" / "ridskolan.html")

TAK_BYTE = 4 * 1024 * 1024        # hela den byggda filen (Tobias, 2026-11-26)
TAK_TEXTUR = 256 * 1024           # en enskild texturfil [antagande]
STORSTA_SIDA = 2048
MIME = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
        ".webp": "image/webp"}
RATTIGHETER = ("egen-syntetisk", "cc0", "ubrf-foto")

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


def bildmatt(rå):
    """(bredd, höjd) ur filhuvudet — PNG, JPEG eller WebP. None om okänt.
    Ren Python: bygget ska inte kräva ett bildbibliotek."""
    if rå[:8] == b"\x89PNG\r\n\x1a\n" and rå[12:16] == b"IHDR":
        return struct.unpack(">II", rå[16:24])
    if rå[:2] == b"\xff\xd8":                                  # JPEG
        i = 2
        while i + 9 < len(rå):
            if rå[i] != 0xFF:
                return None
            m = rå[i + 1]
            if m == 0xFF:                                      # utfyllnad
                i += 1
                continue
            if 0xD0 <= m <= 0xD9 or m == 0x01:                 # utan längd
                i += 2
                continue
            langd = struct.unpack(">H", rå[i + 2:i + 4])[0]
            if 0xC0 <= m <= 0xCF and m not in (0xC4, 0xC8, 0xCC):   # SOFn
                h, b = struct.unpack(">HH", rå[i + 5:i + 9])
                return (b, h)
            i += 2 + langd
        return None
    if rå[:4] == b"RIFF" and rå[8:12] == b"WEBP":
        slag = rå[12:16]
        if slag == b"VP8X":
            b = 1 + int.from_bytes(rå[24:27], "little")
            h = 1 + int.from_bytes(rå[27:30], "little")
            return (b, h)
        if slag == b"VP8 " and rå[23:26] == b"\x9d\x01\x2a":
            b, h = struct.unpack("<HH", rå[26:30])
            return (b & 0x3FFF, h & 0x3FFF)
        if slag == b"VP8L" and rå[20] == 0x2F:
            v = int.from_bytes(rå[21:25], "little")
            return ((v & 0x3FFF) + 1, ((v >> 14) & 0x3FFF) + 1)
    return None


def tvapotens(n):
    return n > 0 and (n & (n - 1)) == 0


def las_kallor(katalog, fel):
    """KALLOR.tsv: fil, kalla, rattighet, samtycke. En rad per textur."""
    tsv = katalog / "KALLOR.tsv"
    rader = {}
    if not tsv.is_file():
        return rader
    innehall = tsv.read_text(encoding="utf-8").splitlines()
    kol = innehall[0].split("\t") if innehall else []
    if kol != ["fil", "kalla", "rattighet", "samtycke"]:
        fel.append("KALLOR.tsv: rubrikraden ska vara fil, kalla, rattighet, samtycke (tabbavgränsat)")
        return rader
    for nr, rad in enumerate(innehall[1:], start=2):
        if not rad.strip() or rad.startswith("#"):
            continue
        falt = (rad.split("\t") + ["", "", "", ""])[:4]
        rader[falt[0].strip()] = dict(zip(kol, (f.strip() for f in falt)), rad=nr)
    return rader


def textur_data():
    """Bakar in texturerna. Returnerar (skripttagg, antal, byte, fel)."""
    fel = []
    poster = {}
    byte = 0
    kallor = las_kallor(TEXTURER, fel) if TEXTURER.is_dir() else {}
    filer = sorted(f for f in TEXTURER.iterdir()
                   if f.is_file() and f.suffix.lower() in MIME) if TEXTURER.is_dir() else []
    for fil in filer:
        rå = fil.read_bytes()
        namn = fil.name
        matt = bildmatt(rå)
        if matt is None:
            fel.append(f"{namn}: går inte att läsa bildens mått ur filhuvudet")
            continue
        b, h = matt
        if not (tvapotens(b) and tvapotens(h)):
            fel.append(f"{namn}: {b}×{h} — sidorna måste vara tvåpotenser (64, 128, 256, 512 …)")
        if max(b, h) > STORSTA_SIDA:
            fel.append(f"{namn}: {b}×{h} — största sida är {STORSTA_SIDA}")
        if len(rå) > TAK_TEXTUR:
            fel.append(f"{namn}: {len(rå)} byte — en textur får vara högst {TAK_TEXTUR}")
        k = kallor.get(namn)
        if k is None:                                           # KÄLLKONTROLL
            fel.append(f"{namn}: saknar rad i KALLOR.tsv — varje textur ska ha en angiven källa")
        else:
            if not k["kalla"]:
                fel.append(f"{namn}: KALLOR.tsv rad {k['rad']} saknar källa")
            if k["rattighet"] not in RATTIGHETER:
                fel.append(f"{namn}: okänd rättighet {k['rattighet']!r} — tillåtna: {', '.join(RATTIGHETER)}")
            if k["rattighet"] == "ubrf-foto":
                s = k["samtycke"]
                svar = (ROT / s) if s else None
                if not (s and re.fullmatch(r"references/licenses/SAMTYCKE-UBRF-[0-9-]+\.md", s)
                        and svar.is_file()):
                    fel.append(f"{namn}: en ruta ur ett UBRF-foto kräver klubbens sparade svar "
                               f"(references/licenses/SAMTYCKE-UBRF-<datum>.md); angivet: {s or 'inget'}")
        poster[namn] = {"uri": "data:%s;base64,%s" % (MIME[fil.suffix.lower()],
                                                        base64.b64encode(rå).decode("ascii")),
                        "b": b, "h": h}
        byte += len(rå)
    for namn in sorted(set(kallor) - {f.name for f in filer}):
        fel.append(f"KALLOR.tsv rad {kallor[namn]['rad']}: {namn} finns inte i {TEXTURER.name}/")
    # Manifestet skrivs ALLTID, också tomt: en byggd fil ska veta att den är
    # byggd, så att motorn aldrig försöker hämta en textur över nätet.
    tagg = "<script>window.TEXTUR_DATA=" + json.dumps(poster, sort_keys=True) + ";</script>\n"
    return tagg, len(poster), byte, fel


tagg, antal, tex_byte, fel = textur_data()
html = html.replace("<script src=", sprite_data() + tagg + "<script src=", 1)

ut = re.sub(r'<script src="([^"]+)"></script>', bädda_in, html)
ut = re.sub(r'<link rel="stylesheet" href="([^"]+)">', bädda_css, ut)
storlek = len(ut.encode("utf-8"))
if storlek > TAK_BYTE:                                          # STORLEKSTAK
    fel.append(f"den byggda filen är {storlek} byte — taket är {TAK_BYTE} (4 MB)")
if fel:
    for f in fel:
        print("  FEL  " + f, file=sys.stderr)
    print(f"BYGGET AVBRUTET: {len(fel)} fel — ingen fil skriven", file=sys.stderr)
    sys.exit(1)
UT.parent.mkdir(parents=True, exist_ok=True)
UT.write_text(ut, encoding="utf-8")
print(f"  texturer: {antal} st, {tex_byte} byte i källfilerna")
print(f"  storlek: {storlek} byte av {TAK_BYTE} ({100 * storlek // TAK_BYTE} % av taket)")
try:                      # relativ sökväg när filen ligger i repot (som förut)
    visa = UT.resolve().relative_to(ROT)
except ValueError:
    visa = UT
print(f"{visa}:", len(ut), "tecken")
