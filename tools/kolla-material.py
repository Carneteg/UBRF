#!/usr/bin/env python3
"""Fäller Enum.Material-namn som inte finns i Roblox.

Varför skriptet finns: teststubbarnas Enum.Material svarade på vilket namn som
helst, så Enum.Material.CorrugatedMetal passerade hela Linux-sviten och sprack
först när en människa körde bygget i Studio:

    CorrugatedMetal is not a valid member of "Enum.Material"
    Script 'CommandBar', Line 3568 - function byggStallInre

Bygget avbröts där, och allt efter det (låsta Parent-egenskaper) var följdfel.

Listan över tillåtna namn ligger i roblox/tests/roblox-material.txt och läses
också av teststubbarna, så det finns bara en sanning.

    python3 tools/kolla-material.py            kollar källan
    python3 tools/kolla-material.py --paket    kollar även genererat paket
"""
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
LISTA = ROT / "roblox" / "tests" / "roblox-material.txt"
PAKET = ROT / "roblox" / "buildings" / ".studio" / "UBRF-klistra-in.luau"
MONSTER = re.compile(r"Enum\.Material\.([A-Za-z0-9_]+)")


def tillatna() -> set:
    rader = LISTA.read_text(encoding="utf-8").splitlines()
    return {r.strip() for r in rader if r.strip() and not r.startswith("#")}


def kolla(filer, tillat) -> list:
    fel = []
    for fil in filer:
        for n, rad in enumerate(fil.read_text(encoding="utf-8").splitlines(), 1):
            for namn in MONSTER.findall(rad):
                if namn not in tillat:
                    fel.append((fil.relative_to(ROT), n, namn))
    return fel


def main() -> int:
    tillat = tillatna()
    filer = sorted(
        f for f in ROT.joinpath("roblox").rglob("*.luau")
        # .build/ och .studio/ är genererade; .studio kollas separat med --paket
        if ".build" not in f.parts and ".studio" not in f.parts
    )
    fel = kolla(filer, tillat)

    if "--paket" in sys.argv and PAKET.exists():
        fel += kolla([PAKET], tillat)

    if fel:
        print("FEL  ogiltigt Enum.Material — Studio vägrar bygga:")
        for fil, n, namn in fel:
            print(f"     {fil}:{n}  Enum.Material.{namn}")
        print(f"\n     Tillåtna: {', '.join(sorted(tillat))}")
        print("     Lägg till i roblox/tests/roblox-material.txt om namnet"
              " FAKTISKT finns i Roblox.")
        return 1

    print(f"OK   {len(filer)} Luau-filer, inga ogiltiga Enum.Material"
          f" ({len(tillat)} tillåtna)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
