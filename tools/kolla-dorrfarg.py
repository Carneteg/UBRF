#!/usr/bin/env python3
"""Håller dörrfärgerna i takt mellan webben, Roblox och byggnadskorten.

Webben målade ridhusets gaveldörr svart, Roblox nästan vit — samma dörr, två
ytor, och ingenting som sa ifrån. Den syntes i `ankomsten`, som en generisk
ljus rektangel där kortet säger (24, 24, 26).

Skriptet läser Roblox-paletten ur Anlaggningen, webbens ur varld3d.js, och
faller om en typ som finns på båda ytorna har olika färg.
"""

import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
ROBLOX = ROT / "roblox" / "buildings" / "Anlaggningen.luau"
WEBB = ROT / "src" / "varld3d.js"

# Kortens mätta värden. Ändras en av dem ska BÅDA ytorna följa med.
KORT = {
    "dorr": ((24, 24, 26), "references/buildings/ridhus/KORT.md"),
    "dorrgul": ((168, 118, 80), "references/buildings/stall/KORT.md"),
}

# Hur nära webben måste ligga kortet. Webbens hex är satta för hand och
# ligger inom ett par steg; det är under vad ögat skiljer och inte värt att
# tvinga till exakt likhet.
TOLERANS = 4


def las_roblox() -> dict:
    t = ROBLOX.read_text(encoding="utf-8")
    block = re.search(r"local OPPNINGSFARG.*?\n\}", t, re.S)
    if not block:
        sys.exit("FEL  hittar inte OPPNINGSFARG i Anlaggningen.luau")
    ut = {}
    for namn, r, g, b in re.findall(
            r"(\w+)\s*=\s*Color3\.fromRGB\((\d+),\s*(\d+),\s*(\d+)\)", block.group(0)):
        ut[namn] = (int(r), int(g), int(b))
    return ut


def las_webb() -> dict:
    t = WEBB.read_text(encoding="utf-8")
    block = re.search(r"const FARG=\{.*?\}", t, re.S)
    if not block:
        sys.exit("FEL  hittar inte FARG i varld3d.js")
    ut = {}
    for namn, hexv in re.findall(r"(\w+)\s*:\s*\"#([0-9A-Fa-f]{6})\"", block.group(0)):
        ut[namn] = tuple(int(hexv[i:i + 2], 16) for i in (0, 2, 4))
    return ut


def main() -> int:
    roblox, webb = las_roblox(), las_webb()
    if not roblox:
        return print("FEL  tom Roblox-palett") or 1

    brister = 0

    for typ, (vantat, kalla) in KORT.items():
        for yta, palett in (("Roblox", roblox), ("webben", webb)):
            har = palett.get(typ)
            if har is None:
                print(f"FEL  {yta} saknar {typ!r}")
                brister += 1
            elif max(abs(a - b) for a, b in zip(har, vantat)) > TOLERANS:
                print(f"FEL  {yta} målar {typ!r} {har}, kortet säger {vantat} ({kalla})")
                brister += 1

    gemensamma = sorted(set(roblox) & set(webb))
    if not gemensamma:
        print("FEL  ingen dörrtyp finns på båda ytorna — läser jag rätt filer?")
        return 1

    for typ in gemensamma:
        if max(abs(a - b) for a, b in zip(roblox[typ], webb[typ])) > TOLERANS:
            print(f"FEL  {typ!r} skiljer sig: Roblox {roblox[typ]}, webben {webb[typ]}")
            brister += 1

    if brister:
        print(f"\n{brister} FEL")
        return 1

    print(f"OK   {len(gemensamma)} dörrfärger lika på båda ytorna, "
          f"{len(KORT)} verifierade mot kort")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
