#!/usr/bin/env python3
"""Byter serialiserad typ pa skriptens Source, och BEVISAR att inget mer andras.

Mutationsprovet (run 35570961741) rensade tabbar, External,
namespace-attribut och Workspace. Kvar star en systematisk skillnad
mellan var artefakt och Rojos:

    var  (400):  <ProtectedString name="Source">   x77
    Rojo (200):  <string name="Source">            x77

`ProtectedString` ar en sakerhetsskyddad vardetyp. Provet gar at bada
hallen:

    F  Rojos fil, string -> ProtectedString   ska BRYTA en fil som gar igenom
    G  var fil, ProtectedString -> string     ska LAGA en fil som faller

    python3 tools/byt-source-typ.py --in <fil> --ut <fil> --till protected|string

EN FALLA: stangningstaggen `</string>` anvands ocksa av `<string
name="Name">`. En naiv sok-och-ersatt skulle doda varje Name-egenskap i
filen. Darfor matchas HELA elementet med en regex, och bytet bevisas
genom att det omvanda bytet maste ge tillbaka originalets exakta bytes.

DIAGNOSTIK, INTE EN GRIND. Skriver bara filer — publicerar ingenting.
"""
import argparse
import hashlib
import pathlib
import re
import sys

#[[ Hela elementet, inte bara oppningstaggen. DOTALL for att kallan ar
#   flerradig CDATA. Icke-girigt sa att tva pa varandra foljande
#   Source-element inte slas ihop till ett. ]]
PROTECTED = re.compile(
    r'<ProtectedString name="Source">(.*?)</ProtectedString>', re.S)
STRING = re.compile(r'<string name="Source">(.*?)</string>', re.S)

CDATA = re.compile(r"<!\[CDATA\[(.*?)\]\]>", re.S)


def fel(text):
    print("AVBRUTET — %s" % text)
    raise SystemExit(2)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--in", dest="infil", required=True)
    p.add_argument("--ut", required=True)
    p.add_argument("--till", required=True, choices=("protected", "string"))
    a = p.parse_args()

    invag = pathlib.Path(a.infil)
    if not invag.is_file() or invag.stat().st_size == 0:
        fel("infilen finns inte eller ar tom: %s" % invag)
    rabytes = invag.read_bytes()
    text = rabytes.decode("utf-8")
    if text.encode("utf-8") != rabytes:
        fel("infilen ar inte ren UTF-8")

    fore_p = len(PROTECTED.findall(text))
    fore_s = len(STRING.findall(text))

    if a.till == "protected":
        if fore_s == 0:
            fel("infilen har inga <string name=\"Source\"> att byta")
        ny = STRING.sub(
            lambda m: '<ProtectedString name="Source">%s</ProtectedString>'
            % m.group(1), text)
        #[[ Omvanda bytet maste ge tillbaka originalet, byte for byte.
        #   Det ar beviset for att inget annat rorts. ]]
        tillbaka = PROTECTED.sub(
            lambda m: '<string name="Source">%s</string>' % m.group(1), ny)
    else:
        if fore_p == 0:
            fel("infilen har inga <ProtectedString name=\"Source\"> att byta")
        ny = PROTECTED.sub(
            lambda m: '<string name="Source">%s</string>' % m.group(1), text)
        tillbaka = STRING.sub(
            lambda m: '<ProtectedString name="Source">%s</ProtectedString>'
            % m.group(1), ny)

    if tillbaka != text:
        fel("det omvanda bytet gav inte tillbaka originalet — nagot mer an "
            "taggnamnen andrades")

    efter_p = len(PROTECTED.findall(ny))
    efter_s = len(STRING.findall(ny))

    #[[ Kallorna sjalva far inte ha rorts. ]]
    if CDATA.findall(text) != CDATA.findall(ny):
        fel("CDATA-innehallet andrades — skriptkallor ska vara ororda")

    #[[ Antalet Name-egenskaper ska vara oforandrat. Det ar den konkreta
    #   fallan: en naiv ersattning av </string> hade dodat dem. ]]
    namn_fore = text.count('<string name="Name">')
    namn_efter = ny.count('<string name="Name">')
    if namn_fore != namn_efter:
        fel("antalet <string name=\"Name\"> andrades: %d -> %d"
            % (namn_fore, namn_efter))

    utvag = pathlib.Path(a.ut)
    utvag.parent.mkdir(parents=True, exist_ok=True)
    ub = ny.encode("utf-8")
    utvag.write_bytes(ub)

    print("BYTE AV SOURCE-TYP -> %s" % a.till)
    print("  infil        : %s" % invag.name)
    print("    storlek    : %d byte" % len(rabytes))
    print("    sha256     : %s" % hashlib.sha256(rabytes).hexdigest())
    print("    Source-taggar fore : ProtectedString=%d  string=%d"
          % (fore_p, fore_s))
    print("  utfil        : %s" % utvag.name)
    print("    storlek    : %d byte   (%+d)" % (len(ub), len(ub) - len(rabytes)))
    print("    sha256     : %s" % hashlib.sha256(ub).hexdigest())
    print("    Source-taggar efter: ProtectedString=%d  string=%d"
          % (efter_p, efter_s))
    print("  BEVIS")
    print("    omvant byte ger tillbaka originalets exakta bytes : JA")
    print("    CDATA-block oforandrade (%d st)                   : JA"
          % len(CDATA.findall(text)))
    print("    <string name=\"Name\"> oforandrade (%d st)          : JA"
          % namn_fore)
    return 0


if __name__ == "__main__":
    sys.exit(main())
