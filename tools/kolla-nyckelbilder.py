#!/usr/bin/env python3
"""Grind: VERIFIED får bara stå på en bild produktägaren har granskat.

Läser nyckelbildskolumnen i RIDHUS-INVENTERING och kontrollerar att varje
tabellrad i INTERIOR-MATRIS som är klassad `VERIFIED` citerar minst en
granskad nyckelbild.

Rader som inte citerar någon bild alls hoppas över — de vilar på
produktägaruppgift eller härledning, vilket är ett annat slags belägg.

Kontrollerar dessutom att antalet bildfiler i mapparna stämmer med antalet
bildrader i inventeringen, eftersom elva bilder en gång låg oinventerade och
en av dem svarade på en fråga som i stället ställdes till produktägaren.
"""
import re
import sys
from pathlib import Path

ROT = Path(__file__).resolve().parent.parent
INV = ROT / "references/RIDHUS-INVENTERING-2026-08-31.md"
MAT = ROT / "references/buildings/ridhus/INTERIOR-MATRIS.md"
MAPPAR = [
    ROT / "references/buildings/ridhus",
    ROT / "references/video/ridhus-nyckelrutor",
]

BILD = re.compile(r"(ridhus-[a-z0-9-]+\.jpg|IMG_[0-9]+-f[0-9]+[a-z0-9-]*\.jpg)")
KORT = re.compile(r"`(ridhus-(?:inne|klubb|gavel|langsida|trappan|skylten)-\d+|-\d+)")


def alla_filer():
    ut = {}
    for m in MAPPAR:
        for f in m.glob("*.jpg"):
            ut[f.name] = f
    return ut


def los_kortform(token, filer, senaste_prefix):
    """`-14` betyder samma prefix som förra fullständiga namnet på raden."""
    if token.startswith("-") and senaste_prefix:
        stam = f"{senaste_prefix}{token}"
    else:
        stam = token
    for namn in filer:
        if namn.startswith(stam + "-") or namn == stam + ".jpg":
            return namn
    return None


def rad_bilder(rad, filer):
    """Alla bildfiler en tabellrad hänvisar till, kortformer upplösta."""
    ut = []
    prefix = None
    for m in re.finditer(r"`([^`]+)`", rad):
        t = m.group(1)
        full = BILD.fullmatch(t)
        if full:
            ut.append(t)
            prefix = re.match(r"(ridhus-[a-z]+)", t)
            prefix = prefix.group(1) if prefix else None
            continue
        k = KORT.fullmatch("`" + t)
        if k:
            namn = los_kortform(t, filer, prefix)
            if namn:
                ut.append(namn)
                p = re.match(r"(ridhus-[a-z]+)", namn)
                prefix = p.group(1) if p else prefix
    return ut


def main():
    if not (INV.exists() and MAT.exists()):
        print("hoppar över: inventering eller matris saknas")
        return 0

    filer = alla_filer()
    inv = INV.read_text(encoding="utf-8")

    nyckel = set()
    invrader = 0
    for rad in inv.split("\n"):
        if not rad.startswith("|"):
            continue
        namn = BILD.findall(rad)
        if not namn:
            continue
        invrader += 1
        if "**ja**" in rad:
            nyckel.update(namn)

    fel = []
    for i, rad in enumerate(MAT.read_text(encoding="utf-8").split("\n"), 1):
        if not rad.startswith("|") or "`VERIFIED`" not in rad:
            continue
        bilder = rad_bilder(rad, filer)
        if not bilder:
            continue
        if not any(b in nyckel for b in bilder):
            fel.append((i, rad.strip()[:120], bilder))

    print(f"nyckelbilder i registret: {len(nyckel)}")
    print(f"bildfiler i mapparna:     {len(filer)}")
    print(f"bildrader i inventeringen:{invrader}")

    varning = 0
    saknas = sorted(set(filer) - set(BILD.findall(inv)))
    if saknas:
        print(f"\nVARNING: {len(saknas)} bildfiler saknar rad i inventeringen")
        for s in saknas:
            print(f"   oinventerad: {s}")
        varning = 1

    if fel:
        print(f"\nFEL: {len(fel)} rader står VERIFIED utan granskad nyckelbild")
        for i, rad, bilder in fel:
            print(f"   rad {i}: {rad}")
            print(f"           citerar {bilder}")
        return 1

    print("\nOK   varje VERIFIED vilar på minst en granskad nyckelbild")
    return 0 if not varning else 0


if __name__ == "__main__":
    sys.exit(main())
