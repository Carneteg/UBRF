#!/usr/bin/env python3
"""En byte: radbrytningen efter </roblox>. Med bevis.

Arm L visade att Rojos innehall i VAR serialisering gar igenom (200).
En direkt jamforelse mellan L och var artefakt gav noll skiljande rader
nar ordningen sorteras bort — identiska radmultimangder — och exakt en
byte i skillnad:

    Rojo och L (200):  ...</roblox>      ingen avslutande radbrytning
    var        (400):  ...</roblox>\\n    avslutande radbrytning

Korrelationen holl over alla sjutton matningar i utredningen: varje fil
utan avslutande radbrytning accepterades, varje fil med avvisades. Den
forklarar ocksa varfor bisektionens bas var ogiltig — den kom ur min
egen generator och slutade likadant.

Provet gar at bada hallen, en byte i taget:

    M  var fil  - sista radbrytningen   ska LAGA en fil som faller
    N  Rojos fil + en radbrytning       ska BRYTA en fil som gar igenom

    python3 tools/sista-byten.py --in <fil> --ut <fil> --atgard ta-bort|lagg-till

Verktyget vagrar rora nagot annat: utfilen maste skilja exakt EN byte i
langd, den byten maste vara den sista, och den omvanda atgarden maste ge
tillbaka infilens exakta bytes.

DIAGNOSTIK, INTE EN GRIND. Skriver bara filer — publicerar ingenting.
"""
import argparse
import hashlib
import pathlib
import sys

RADBRYTNING = b"\n"
ROTSLUT = b"</roblox>"


def fel(text):
    print("AVBRUTET — %s" % text)
    raise SystemExit(2)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--in", dest="infil", required=True)
    p.add_argument("--ut", required=True)
    p.add_argument("--atgard", required=True,
                   choices=("ta-bort", "lagg-till"))
    a = p.parse_args()

    invag = pathlib.Path(a.infil)
    if not invag.is_file() or invag.stat().st_size == 0:
        fel("infilen finns inte eller ar tom: %s" % invag)
    fore = invag.read_bytes()

    if a.atgard == "ta-bort":
        if not fore.endswith(ROTSLUT + RADBRYTNING):
            fel("infilen slutar inte med '</roblox>' + radbrytning: %r"
                % fore[-16:])
        efter = fore[:-1]
        tillbaka = efter + RADBRYTNING
    else:
        if not fore.endswith(ROTSLUT):
            fel("infilen slutar inte med '</roblox>': %r" % fore[-16:])
        efter = fore + RADBRYTNING
        tillbaka = efter[:-1]

    #[[ Tre bevis, alla tre maste halla. En byte ar en liten atgard och
    #   just darfor latt att tro pa utan att kontrollera. ]]
    if abs(len(efter) - len(fore)) != 1:
        fel("langden andrades med %d byte, inte 1"
            % abs(len(efter) - len(fore)))
    kortare, langre = sorted((fore, efter), key=len)
    if langre[:len(kortare)] != kortare:
        fel("skillnaden ligger inte i SISTA byten — filerna skiljer sig "
            "ocksa tidigare")
    if tillbaka != fore:
        fel("den omvanda atgarden gav inte tillbaka infilens exakta bytes")

    utvag = pathlib.Path(a.ut)
    utvag.parent.mkdir(parents=True, exist_ok=True)
    utvag.write_bytes(efter)

    print("SISTA BYTEN — %s" % a.atgard)
    print("  infil      : %s" % invag.name)
    print("    storlek  : %d byte" % len(fore))
    print("    sha256   : %s" % hashlib.sha256(fore).hexdigest())
    print("    sista 14 : %r" % fore[-14:])
    print("  utfil      : %s" % utvag.name)
    print("    storlek  : %d byte   (%+d)" % (len(efter),
                                              len(efter) - len(fore)))
    print("    sha256   : %s" % hashlib.sha256(efter).hexdigest())
    print("    sista 14 : %r" % efter[-14:])
    print("  BEVIS")
    print("    langdskillnad exakt 1 byte                 : JA")
    print("    all text fore sista byten identisk         : JA")
    print("    omvand atgard ger tillbaka infilens bytes  : JA")
    return 0


if __name__ == "__main__":
    sys.exit(main())
