#!/usr/bin/env python3
"""Grind: referensbiblioteket och Drive-manifestet säger samma sak som filerna.

`references/CHECKSUMS.sha256` har länge hänvisat till det här verktyget i sin
rubrik utan att det fanns. Följden var att åtta bilder under
`references/omnejd/` aldrig kom med i listan — `sha256sum -c` kontrollerar
bara de rader som står där, inte att alla filer har en rad.

Kontrollerar:

  1. CHECKSUMS.sha256 täcker VARJE mediafil under references/ och ingen fil
     som inte finns, och varje kontrollsumma stämmer.
  2. Drive-manifestet (references/DRIVE-MANIFEST-*.tsv, det senaste):
       · varje IN_REPO-rad pekar på en fil som finns, med rätt sha256,
       · en DRIVE-ONLY-rad pekar inte på någon repo-fil,
       · inget foto med person, registreringsskylt eller läsbara personnamn
         har fått ett NYTT derivat (Batch 0.13; klubbens samtycke från
         2026-11-28 täcker inte personerna i bild, så regeln står kvar),
       · ingen film är migrerad av den här batchen,
       · varje bildfil i en drive-<datum>-mapp har en manifestrad.
  3. De nya derivaten bär ingen EXIF eller XMP (plats, tid, telefonmodell).

Kör:  python3 tools/kolla-referenser.py
      python3 tools/kolla-referenser.py --skriv     (skriv om CHECKSUMS.sha256)

`--manifest FIL` och `--checksums FIL` pekar ut andra filer att läsa; de finns
för att grinden ska gå att falsifiera mot en manipulerad kopia utan att röra
de riktiga filerna.
"""
import hashlib
import sys
from pathlib import Path

ROT = Path(__file__).resolve().parent.parent
REF = ROT / "references"
MEDIA = {".jpg", ".jpeg", ".png", ".mov", ".mp4"}
RUBRIK = """# sha256 for allt referensmedia i references/.
# Sokvagarna ar relativa den har katalogen, sa listan gar att kora
# med:  cd references && sha256sum -c CHECKSUMS.sha256
# Skriv om den med:  python3 tools/kolla-referenser.py --skriv
"""


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for b in iter(lambda: fh.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def mediafiler():
    return sorted(p.relative_to(REF).as_posix() for p in REF.rglob("*")
                  if p.is_file() and p.suffix.lower() in MEDIA)


def arg(namn, forval):
    if namn in sys.argv:
        return Path(sys.argv[sys.argv.index(namn) + 1])
    return forval


def main():
    checks = arg("--checksums", REF / "CHECKSUMS.sha256")
    if "--skriv" in sys.argv:
        rader = ["%s  %s" % (sha(REF / f), f) for f in mediafiler()]
        checks.write_text(RUBRIK + "\n".join(rader) + "\n", encoding="utf-8")
        print("skrev %s: %d filer" % (checks.relative_to(ROT), len(rader)))
        return 0

    fel = []

    # ── 1. CHECKSUMS.sha256 ────────────────────────────────────────
    listad = {}
    for rad in checks.read_text(encoding="utf-8").splitlines():
        if not rad.strip() or rad.startswith("#"):
            continue
        summa, _, fil = rad.partition("  ")
        listad[fil.strip()] = summa.strip()
    finns = set(mediafiler())
    for f in sorted(finns - set(listad)):
        fel.append("CHECKSUMS saknar rad för %s" % f)
    for f in sorted(set(listad) - finns):
        fel.append("CHECKSUMS listar en fil som inte finns: %s" % f)
    for f in sorted(finns & set(listad)):
        if sha(REF / f) != listad[f]:
            fel.append("fel kontrollsumma: %s" % f)
    print("  CHECKSUMS: %d filer på disk, %d rader" % (len(finns), len(listad)))

    # ── 2. Drive-manifestet ────────────────────────────────────────
    kandidater = sorted(REF.glob("DRIVE-MANIFEST-*.tsv"))
    manifest = arg("--manifest", kandidater[-1] if kandidater else None)
    if manifest is None:
        fel.append("inget references/DRIVE-MANIFEST-*.tsv")
    else:
        rader = manifest.read_text(encoding="utf-8").splitlines()
        kol = rader[0].split("\t")
        poster = [dict(zip(kol, r.split("\t"))) for r in rader[1:] if r.strip()]
        foto = [p for p in poster if p["slag"] == "foto"]
        film = [p for p in poster if p["slag"] == "film"]
        i_manifest = set()
        nya = 0
        for p in poster:
            namn = p["drive_sokvag"]
            if p["status"] == "IN_REPO":
                fil = ROT / p["repo_sokvag"]
                i_manifest.add(p["repo_sokvag"])
                if not p["repo_sokvag"] or not fil.is_file():
                    fel.append("%s: IN_REPO men filen finns inte (%s)" % (namn, p["repo_sokvag"]))
                elif sha(fil) != p["repo_sha256"]:
                    fel.append("%s: repo-filens sha256 stämmer inte med manifestet" % namn)
            elif p["status"] == "DRIVE-ONLY":
                if p["repo_sokvag"]:
                    fel.append("%s: DRIVE-ONLY men pekar på %s" % (namn, p["repo_sokvag"]))
            else:
                fel.append("%s: okänd status %r" % (namn, p["status"]))
            ny = "kvalitet 85" in p["derivat"]
            nya += ny
            if ny and "ja" in (p["personer"], p["skyltar"], p["lasbara_namn"]):
                fel.append("%s: nytt derivat fast person/skylt/läsbara namn är markerat" % namn)
            if ny and p["slag"] != "foto":
                fel.append("%s: nytt derivat av något som inte är ett foto" % namn)
            if ny:
                data = (ROT / p["repo_sokvag"]).read_bytes() if (ROT / p["repo_sokvag"]).is_file() else b""
                if b"Exif\x00\x00" in data[:65536] or b"http://ns.adobe.com/xap/" in data[:65536]:
                    fel.append("%s: derivatet bär EXIF eller XMP" % namn)
        for f in sorted(finns):
            if "/drive-" in "/" + f and ("references/" + f) not in i_manifest:
                fel.append("%s ligger i en drive-mapp utan manifestrad" % f)
        print("  manifest %s: %d foton, %d filmer, %d nya derivat"
              % (manifest.name, len(foto), len(film), nya))

    for f in fel:
        print("  FEL  " + f)
    if fel:
        print("KOLLA-REFERENSER: %d FEL" % len(fel))
        return 1
    print("OK   referenserna, kontrollsummorna och Drive-manifestet stämmer med filerna")
    return 0


if __name__ == "__main__":
    sys.exit(main())
