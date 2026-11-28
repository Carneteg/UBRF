#!/usr/bin/env python3
"""Prov: bildtexturernas väg genom bygget (Batch 1.3).

Bygger till en tillfällig katalog med testbilder som provet skriver självt —
ingen bildfil ligger i repot och varken assets/ eller dist/ rörs.

Det som provas:
  1. tom texturmapp ger ett tomt manifest, och bygget är byte för byte lika
     med ett bygge utan flaggor;
  2. en bild bakas in med rätt mått och en data-URI som avkodas till samma byte;
  3. måtten läses rätt ur PNG, JPEG och WebP (tre varianter);
  4. bygget AVBRYTS — och skriver ingen fil — för: fil över taket 4 MB,
     sidor som inte är tvåpotenser, en textur över 256 kB, textur utan rad i
     KALLOR.tsv, okänd rättighet, kvarglömd rad, oläsbart filhuvud, och en
     ruta ur ett UBRF-foto utan klubbens sparade svar (utkastet räknas inte);
  5. med ett sparat svar på plats går samma UBRF-ruta igenom.

Kör:  python3 tools/testa-texturbygge.py

Falsifiering (ska ge RÖTT prov — annars bevisar provet ingenting):
      --muter-tak     storlekstaket bortkopplat i en KOPIA av build.py
      --muter-kalla   källkontrollen bortkopplad i en KOPIA av build.py
"""
import base64
import json
import pathlib
import random
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ROT = pathlib.Path(__file__).resolve().parent.parent
BYGG = ROT / "tools" / "build.py"
RUBRIK = "fil\tkalla\trattighet\tsamtycke\n"
resultat = []


def prova(namn, ok, detalj=""):
    resultat.append(ok)
    print(("  OK   " if ok else "  FEL  ") + namn + (" — " + detalj if detalj else ""))


def png(b, h, pixel):
    """Skriver en RGB-PNG för hand. pixel(x, y) → (r, g, b)."""
    rader = b"".join(b"\x00" + b"".join(bytes(pixel(x, y)) for x in range(b)) for y in range(h))

    def bit(slag, data):
        return struct.pack(">I", len(data)) + slag + data + struct.pack(">I", zlib.crc32(slag + data))
    return (b"\x89PNG\r\n\x1a\n" + bit(b"IHDR", struct.pack(">IIBBBBB", b, h, 8, 2, 0, 0, 0))
            + bit(b"IDAT", zlib.compress(rader, 9)) + bit(b"IEND", b""))


def fyrfalt(b=64, h=64):
    """Rött uppe till vänster, grönt uppe till höger, blått nere till vänster, vitt nere till höger."""
    return png(b, h, lambda x, y: ((255, 0, 0) if x < b // 2 else (0, 255, 0)) if y < h // 2
               else ((0, 0, 255) if x < b // 2 else (255, 255, 255)))


def brus(b, h, fro):
    r = random.Random(fro)
    data = r.randbytes(b * h * 3)
    return png(b, h, lambda x, y: data[(y * b + x) * 3:(y * b + x) * 3 + 3])


def jpeg_huvud(b, h, sof=0xC0):
    """Ett JPEG-huvud med APP0 och en SOF-markör. Går inte att avkoda — bygget
    läser bara måtten."""
    app0 = b"\xff\xe0" + struct.pack(">H", 16) + b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    sofn = bytes([0xFF, sof]) + struct.pack(">HBHHB", 11, 8, h, b, 1) + b"\x01\x11\x00"
    return b"\xff\xd8" + app0 + sofn + b"\xff\xd9"


def webp_vp8x(b, h):
    kropp = b"VP8X" + struct.pack("<I", 10) + b"\x00\x00\x00\x00" + (b - 1).to_bytes(3, "little") + (h - 1).to_bytes(3, "little")
    return b"RIFF" + struct.pack("<I", 4 + len(kropp)) + b"WEBP" + kropp


def webp_vp8(b, h):
    kropp = b"VP8 " + struct.pack("<I", 10) + b"\x00\x00\x00" + b"\x9d\x01\x2a" + struct.pack("<HH", b, h)
    return b"RIFF" + struct.pack("<I", 4 + len(kropp)) + b"WEBP" + kropp


def webp_vp8l(b, h):
    v = (b - 1) | ((h - 1) << 14)
    kropp = b"VP8L" + struct.pack("<I", 5) + b"\x2f" + v.to_bytes(4, "little")
    return b"RIFF" + struct.pack("<I", 4 + len(kropp)) + b"WEBP" + kropp


def bygg(skript, rot, texturer, ut):
    return subprocess.run([sys.executable, str(skript), "--rot", str(rot), "--texturer", str(texturer),
                           "--ut", str(ut)], capture_output=True, text=True)


def manifest(fil):
    m = re.search(r"<script>window\.TEXTUR_DATA=(\{.*?\});</script>", fil.read_text(encoding="utf-8"), re.S)
    return json.loads(m.group(1)) if m else None


def main():
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="texturbygge-"))
    skript = BYGG
    kalla = BYGG.read_text(encoding="utf-8")
    if "--muter-tak" in sys.argv:
        gammal = "if storlek > TAK_BYTE:"
        assert kalla.count(gammal) == 1, "mutationens ankare finns inte i build.py"
        skript = tmp / "build_mut.py"
        skript.write_text(kalla.replace(gammal, "if False:"), encoding="utf-8")
        print("MUTATION: storlekstaket bortkopplat")
    if "--muter-kalla" in sys.argv:
        gammal = "k = kallor.get(namn)"
        assert kalla.count(gammal) == 1, "mutationens ankare finns inte i build.py"
        skript = tmp / "build_mut.py"
        skript.write_text(kalla.replace(gammal, gammal + ' or {"kalla": "x", "rattighet": "egen-syntetisk", '
                                        '"samtycke": "", "rad": 0}'), encoding="utf-8")
        print("MUTATION: källkontrollen bortkopplad")

    # En liten låtsasrot: provet ska inte bero på hur stort spelet råkar vara.
    rot = tmp / "rot"
    (rot / "src").mkdir(parents=True)
    (rot / "references" / "licenses").mkdir(parents=True)
    (rot / "index.html").write_text('<!doctype html><html><body><script src="src/a.js"></script></body></html>',
                                    encoding="utf-8")
    (rot / "src" / "a.js").write_text("var A=1;\n", encoding="utf-8")
    # Ett UTKAST till förfrågan (så hette det i Batch 0.14) ska aldrig räknas som samtycke.
    (rot / "references" / "licenses" / "SAMTYCKE-FORFRAGAN-UTKAST.md").write_text("utkast\n", encoding="utf-8")

    nr = [0]

    def fall(filer, rader):
        """Skriver en texturmapp och bygger. Returnerar (process, utfil)."""
        nr[0] += 1
        d = tmp / ("t%d" % nr[0])
        d.mkdir()
        for namn, data in filer.items():
            (d / namn).write_bytes(data)
        if rader is not None:
            (d / "KALLOR.tsv").write_text(RUBRIK + "".join(r + "\n" for r in rader), encoding="utf-8")
        ut = tmp / ("ut%d.html" % nr[0])
        return bygg(skript, rot, d, ut), ut

    def ska_falla(namn, filer, rader, ord_i_felet):
        p, ut = fall(filer, rader)
        prova(namn, p.returncode != 0 and ord_i_felet in p.stderr and not ut.exists(),
              "avslutskod %d · fil skriven: %s · %s" % (p.returncode, ut.exists(),
                                                         (p.stderr.strip().splitlines() or ["(tyst)"])[0][:110]))

    egen = "\tprovbild skriven av tools/testa-texturbygge.py\tegen-syntetisk\t"

    # ── 1. Tom mapp ───────────────────────────────────────────────
    p, ut = fall({}, [])
    prova("tom texturmapp: bygget går igenom med ett tomt manifest",
          p.returncode == 0 and ut.exists() and manifest(ut) == {}, p.stdout.strip().splitlines()[0] if p.stdout else p.stderr[:100])
    # Det riktiga spelet: bygget med en tom mapp är byte för byte bygget utan flaggor.
    a, b = tmp / "riktig-a.html", tmp / "riktig-b.html"
    tom = tmp / "tom"
    tom.mkdir()
    (tom / "KALLOR.tsv").write_text(RUBRIK, encoding="utf-8")
    pa = subprocess.run([sys.executable, str(skript), "--rot", str(ROT), "--ut", str(a)], capture_output=True, text=True)
    pb = subprocess.run([sys.executable, str(skript), "--rot", str(ROT), "--texturer", str(tom), "--ut", str(b)],
                        capture_output=True, text=True)
    # Sedan Batch 1.4 har det riktiga spelet fem fotorutor. Utan dem är bygget
    # byte för byte samma som med en tom provmapp, så när som på manifestet:
    # texturerna lägger till data, aldrig kod.
    def utan_manifest(f):
        return re.sub(r"<script>window\.TEXTUR_DATA=\{.*?\};</script>", "", f.read_text(encoding="utf-8"), flags=re.S)
    lika = pa.returncode == 0 and pb.returncode == 0 and utan_manifest(a) == utan_manifest(b) and manifest(b) == {}
    prova("det riktiga spelet: bygget skiljer sig från ett med tom texturmapp bara i manifestet",
          lika and sorted(manifest(a) or {}) == sorted(f.name for f in (ROT / "assets" / "textures").iterdir()
                                                    if f.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")),
          "%d byte · %s" % (a.stat().st_size if a.exists() else -1,
                            (pa.stdout.strip().splitlines() or [pa.stderr[:100]])[1 if pa.stdout else 0].strip()))
    prova("och det riktiga spelet ligger under taket 4 MB", a.exists() and a.stat().st_size <= 4 * 1024 * 1024,
          "%d byte" % (a.stat().st_size if a.exists() else -1))

    # ── 2. En bild bakas in ───────────────────────────────────────
    bild = fyrfalt()
    p, ut = fall({"prov.png": bild}, ["prov.png" + egen])
    m = manifest(ut) if ut.exists() else None
    ok = bool(m) and list(m) == ["prov.png"] and (m["prov.png"]["b"], m["prov.png"]["h"]) == (64, 64)
    samma = ok and m["prov.png"]["uri"].startswith("data:image/png;base64,") and \
        base64.b64decode(m["prov.png"]["uri"].split(",", 1)[1]) == bild
    prova("en 64×64-bild hamnar i manifestet med rätt mått", ok, json.dumps({k: (v["b"], v["h"]) for k, v in (m or {}).items()}))
    prova("och data-URI:n avkodas till exakt filens byte", bool(samma), "%d byte" % len(bild))
    inga_nat = ut.exists() and "assets/textures/prov.png" not in ut.read_text(encoding="utf-8").replace('"assets/textures/"+namn', "")
    prova("den byggda filen hänvisar inte till texturfilen på disk — den ligger i filen", inga_nat)

    # ── 3. Måtten ur tre format ───────────────────────────────────
    filer = {"a.jpg": jpeg_huvud(128, 256), "b.jpeg": jpeg_huvud(512, 64, sof=0xC2),
             "c.webp": webp_vp8x(256, 128), "d.webp": webp_vp8(64, 32), "e.webp": webp_vp8l(32, 1024)}
    p, ut = fall(filer, [n + egen for n in filer])
    m = manifest(ut) if ut.exists() else {}
    fatt = {k: (v["b"], v["h"]) for k, v in (m or {}).items()}
    vantat = {"a.jpg": (128, 256), "b.jpeg": (512, 64), "c.webp": (256, 128), "d.webp": (64, 32), "e.webp": (32, 1024)}
    prova("måtten läses rätt ur JPEG (baseline, progressiv) och WebP (VP8X, VP8, VP8L)", fatt == vantat, str(fatt))
    mime = {k: v["uri"].split(";")[0] for k, v in (m or {}).items()}
    prova("och varje format får rätt medietyp", mime == {"a.jpg": "data:image/jpeg", "b.jpeg": "data:image/jpeg",
                                                           "c.webp": "data:image/webp", "d.webp": "data:image/webp",
                                                           "e.webp": "data:image/webp"}, str(sorted(set(mime.values()))))

    # ── 4. Bygget avbryts ─────────────────────────────────────────
    stora = {"s%02d.png" % i: brus(256, 256, i) for i in range(22)}       # 22 × ~197 kB → över 4 MB som base64
    storlek = sum(len(v) for v in stora.values())
    assert all(len(v) <= 256 * 1024 for v in stora.values()), "provbilderna ska klara gränsen per fil"
    p, ut = fall(stora, [n + egen for n in stora])
    prova("över taket 4 MB: bygget avbryts och skriver ingen fil",
          p.returncode != 0 and "taket är" in p.stderr and not ut.exists(),
          "%d byte texturer i %d filer · avslutskod %d · fil skriven: %s" % (storlek, len(stora), p.returncode, ut.exists()))
    ska_falla("sidor som inte är tvåpotenser (100×64) avbryter bygget", {"n.png": fyrfalt(100, 64)}, ["n.png" + egen], "tvåpotenser")
    ska_falla("en textur över 256 kB avbryter bygget", {"tung.png": brus(512, 512, 99)}, ["tung.png" + egen], "får vara högst")
    ska_falla("en textur utan rad i KALLOR.tsv avbryter bygget", {"prov.png": bild}, [], "saknar rad i KALLOR.tsv")
    ska_falla("…och likaså när KALLOR.tsv saknas helt", {"prov.png": bild}, None, "saknar rad i KALLOR.tsv")
    ska_falla("okänd rättighet avbryter bygget", {"prov.png": bild}, ["prov.png\tnågonstans\tlånad\t"], "okänd rättighet")
    ska_falla("tom källa avbryter bygget", {"prov.png": bild}, ["prov.png\t\tegen-syntetisk\t"], "saknar källa")
    ska_falla("en kvarglömd rad (filen finns inte) avbryter bygget", {"prov.png": bild},
              ["prov.png" + egen, "borta.png" + egen], "finns inte")
    ska_falla("ett oläsbart filhuvud avbryter bygget", {"skrap.png": b"inte en bild"}, ["skrap.png" + egen], "bildens mått")
    foto = "prov.png\treferences/buildings/stall/stall-inne-05-stallgangen.jpg\tubrf-foto\t"
    ska_falla("en ruta ur ett UBRF-foto utan samtycke avbryter bygget", {"prov.png": bild}, [foto], "klubbens sparade svar")
    ska_falla("…och UTKASTET till förfrågan räknas inte som samtycke", {"prov.png": bild},
              [foto + "references/licenses/SAMTYCKE-FORFRAGAN-UTKAST.md"], "klubbens sparade svar")
    ska_falla("…och inte ett svar som inte finns på disk", {"prov.png": bild},
              [foto + "references/licenses/SAMTYCKE-UBRF-2026-12-01.md"], "klubbens sparade svar")

    # ── 5. Med svaret på plats går samma ruta igenom ──────────────
    (rot / "references" / "licenses" / "SAMTYCKE-UBRF-2026-12-01.md").write_text("ja\n", encoding="utf-8")
    p, ut = fall({"prov.png": bild}, [foto + "references/licenses/SAMTYCKE-UBRF-2026-12-01.md"])
    prova("med klubbens sparade svar på plats går samma UBRF-ruta igenom", p.returncode == 0 and ut.exists(),
          "avslutskod %d" % p.returncode)

    # Det riktiga repot. Sedan Batch 1.4 ligger stallgångens fotorutor där.
    # Varje bildfil ska ha en källrad; en UBRF-fotoruta ska peka på ett foto
    # som finns i repot och som Drive-manifestet säger är utan personer,
    # registreringsskyltar och läsbara namn.
    textmapp = ROT / "assets" / "textures"
    riktiga = sorted(f.name for f in textmapp.iterdir() if f.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp"))
    kallrader = (textmapp / "KALLOR.tsv").read_text(encoding="utf-8").splitlines()
    prova("repot: assets/textures/KALLOR.tsv finns och har rätt rubrikrad", kallrader[:1] == [RUBRIK.strip("\n")])
    kallor = {r.split("\t")[0]: r.split("\t") for r in kallrader[1:] if r.strip()}
    prova("repot: varje bildfil i assets/textures/ har en källrad, och varje källrad en fil",
          sorted(kallor) == riktiga, "%d filer · %d rader" % (len(riktiga), len(kallor)))
    drive = sorted(ROT.glob("references/DRIVE-MANIFEST-*.tsv"))[-1].read_text(encoding="utf-8").splitlines()
    kol = drive[0].split("\t")
    rena = {dict(zip(kol, r.split("\t")))["repo_sokvag"] for r in drive[1:] if r.strip()
            and dict(zip(kol, r.split("\t")))["personer"] == "nej" and dict(zip(kol, r.split("\t")))["skyltar"] == "nej"
            and dict(zip(kol, r.split("\t")))["lasbara_namn"] != "ja"}
    smutsiga = []
    for namn, r in kallor.items():
        if r[2] != "ubrf-foto":
            continue
        foto = r[1].split(",")[0].strip()
        if not (ROT / foto).is_file() or foto not in rena:
            smutsiga.append("%s ← %s" % (namn, foto))
    prova("repot: varje UBRF-fotoruta kommer ur ett foto i repot utan personer, skyltar eller läsbara namn",
          not smutsiga, "; ".join(smutsiga) or "%d rutor kontrollerade" % sum(1 for r in kallor.values() if r[2] == "ubrf-foto"))
    pb = subprocess.run([sys.executable, str(skript), "--rot", str(ROT), "--ut", str(tmp / "repo.html")], capture_output=True, text=True)
    prova("repot: bygget går igenom sin egen källkontroll med de riktiga texturerna", pb.returncode == 0,
          (pb.stdout.strip().splitlines() or [pb.stderr.strip()[:200]])[0])

    shutil.rmtree(tmp, ignore_errors=True)
    fel = resultat.count(False)
    if fel:
        print("%d FEL av %d" % (fel, len(resultat)))
        return 1
    print("ALLA OK (%d mätningar)" % len(resultat))
    return 0


if __name__ == "__main__":
    sys.exit(main())
