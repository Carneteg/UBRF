#!/usr/bin/env python3
"""Vaktar referenssamlingens integritet.

Tre saker kan gå sönder tyst i `references/`, och alla tre har hänt:

1. en bild ändras eller skrivs över utan att någon märker det,
2. en ny bild läggs till utan att komma med i checksummorna, så spegeln till
   Supabase blir ofullständig utan att något säger ifrån,
3. en bild tas bort men står kvar i listan.

`references/CHECKSUMS.sha256` är GitHub-sidans facit. Den här kontrollen
jämför listan mot verkligheten åt BÅDA hållen — en lista som bara kollas
uppifrån och ner missar exakt det fall den finns till för.

    python3 tools/kolla-referenser.py
"""

import hashlib
import pathlib
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
LISTA = ROT / "references" / "CHECKSUMS.sha256"
KALLOR = [
    ("references/buildings", ("*.jpg", "*.jpeg", "*.png")),
    ("references/plans",     ("*.jpg", "*.jpeg", "*.png")),
    ("references/video",     ("*.mov", "*.mp4")),
]


def summa(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for bit in iter(lambda: f.read(1 << 20), b""):
            h.update(bit)
    return h.hexdigest()


def main() -> int:
    if not LISTA.exists():
        print(f"FEL  {LISTA.relative_to(ROT)} saknas")
        return 1

    listad: dict[str, str] = {}
    for rad in LISTA.read_text(encoding="utf-8").splitlines():
        if not rad.strip() or rad.lstrip().startswith("#"):
            continue
        sha, _, vag = rad.partition("  ")
        listad[vag.strip()] = sha.strip()

    pa_disk: set[str] = set()
    for katalog, monster in KALLOR:
        bas = ROT / katalog
        if not bas.is_dir():
            continue
        for m in monster:
            for f in bas.rglob(m):
                pa_disk.add(f.relative_to(ROT).as_posix())

    fel = 0

    saknas_i_listan = sorted(pa_disk - listad.keys())
    for v in saknas_i_listan:
        print(f"FEL  {v} finns pa disk men saknas i CHECKSUMS.sha256")
        fel += 1

    saknas_pa_disk = sorted(listad.keys() - pa_disk)
    for v in saknas_pa_disk:
        print(f"FEL  {v} star i CHECKSUMS.sha256 men finns inte pa disk")
        fel += 1

    andrade = 0
    for v in sorted(pa_disk & listad.keys()):
        if summa(ROT / v) != listad[v]:
            print(f"FEL  {v} har andrats sedan checksumman skrevs")
            fel += 1
            andrade += 1

    if fel:
        print(f"\n{fel} fel. Kor 'python3 tools/spegla-referenser.py --lista --json' "
              "och skriv om listan om andringen ar avsiktlig.")
        return 1

    print(f"OK   {len(listad)} referensfiler, checksummor stammer at bada hallen")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
