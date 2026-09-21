#!/usr/bin/env python3
"""Fyra minimala XML-placer for bisektionen i #264.

Parprovet visade att XML-vagen fungerar: Rojos XML gick igenom med HTTP
200 medan var egen foll pa 400 «Invalid Content stream». Felet ligger
alltsa i VAR XML. Tre skillnader mot Rojos envelope star kvar som
misstankta, och de provas har en i taget.

  1  basen      — Rojo-stil rot, vara tjanster, INGEN Workspace,
                  INGA External, INGA namespace-attribut
  2  bas + Workspace-noden exakt som tools/bygg-place.py skriver den
  3  bas + <External>null</External> och <External>nil</External>
  4  bas + xmlns/xsi/schema-location pa rotelementet

Varje variant skiljer sig fran BASEN med exakt en egenskap. Faller en
av dem medan basen gar igenom ar den egenskapen blockeraren.

Gar inte basen igenom mater provet ingenting — da ar det
BISECT_BASELINE_INVALID och ingen slutsats far dras om nagon variant.

    python3 tools/bisektion-xml.py --katalog <ut-katalog>

DIAGNOSTIK, INTE EN GRIND. Tillfallig fil; tas bort nar fragan ar
besvarad. Skriver bara filer — publicerar ingenting.
"""
import argparse
import hashlib
import pathlib
import sys
import xml.etree.ElementTree as ET

#[[ Rojos rotelement: bara version. Det ar den enda XML vi VET att
#   Roblox place-ingester accepterar (run 35569440952, HTTP 200). ]]
ROT_BAR = '<roblox version="4">'

#[[ Var rot, ordagrant ur tools/bygg-place.py:239-242. ]]
ROT_NAMESPACE = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
    'version="4">'
)

#[[ Ur tools/bygg-place.py:243-244. ]]
EXTERNAL = "\t<External>null</External>\n\t<External>nil</External>\n"

#[[ Workspace-noden precis som tools/bygg-place.py:231-232 stoppar in
#   den nar projektfilen inte deklarerar nagon: tabbindrag, RBX-referent,
#   enbart Name. Byte for byte samma form som i den artefakt som foll. ]]
WORKSPACE = (
    '\t<Item class="Workspace" referent="RBX0">\n'
    "\t\t<Properties>\n"
    '\t\t\t<string name="Name">Workspace</string>\n'
    "\t\t</Properties>\n"
    "\t</Item>\n"
)

#[[ Vara tjanster ur roblox/default.project.json. Tomma: bisektionen
#   provar TOPPNIVANS egenskaper, inte innehallet — det har parprovet
#   redan rensat, eftersom Rojos 1,6 MB gick igenom. ]]
TJANSTER = ("ReplicatedStorage", "ServerScriptService", "StarterPlayer")


def tjanstnoder():
    ut = []
    for i, namn in enumerate(TJANSTER):
        ut.append(
            '\t<Item class="%s" referent="%d">\n'
            "\t\t<Properties>\n"
            '\t\t\t<string name="Name">%s</string>\n'
            "\t\t</Properties>\n"
            "\t</Item>\n" % (namn, i, namn)
        )
    return "".join(ut)


def bygg(rot, external, workspace):
    kropp = ""
    if external:
        kropp += EXTERNAL
    if workspace:
        kropp += WORKSPACE
    kropp += tjanstnoder()
    return rot + "\n" + kropp + "</roblox>\n"


VARIANTER = (
    ("1-bas", "basen: Rojo-stil rot, vara tjanster, inget mer",
     dict(rot=ROT_BAR, external=False, workspace=False)),
    ("2-workspace", "bas + Workspace-noden ur bygg-place.py",
     dict(rot=ROT_BAR, external=False, workspace=True)),
    ("3-external", "bas + de tva <External>-noderna",
     dict(rot=ROT_BAR, external=True, workspace=False)),
    ("4-namespace", "bas + xmlns/xsi/schema-location pa roten",
     dict(rot=ROT_NAMESPACE, external=False, workspace=False)),
)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--katalog", required=True,
                   help="katalog att skriva varianterna i")
    a = p.parse_args()

    kat = pathlib.Path(a.katalog)
    kat.mkdir(parents=True, exist_ok=True)

    bas = None
    print("BISEKTION #264 — fyra minimala XML-placer")
    print("")
    for namn, beskrivning, arg in VARIANTER:
        doc = bygg(**arg)

        #[[ En variant som inte ens ar valformad XML skulle mata fel sak.
        #   Den kontrollen ar billig och ska sta fore allt annat. ]]
        try:
            ET.fromstring(doc)
        except ET.ParseError as e:
            print("AVBRUTET — variant %s ar inte valformad XML: %s"
                  % (namn, e))
            return 2

        b = doc.encode("utf-8")
        vag = kat / ("bisekt-%s.rbxlx" % namn)
        vag.write_bytes(b)

        #[[ Varje variant ska skilja sig fran BASEN med exakt en sak.
        #   Det kontrolleras har i stallet for att lovas i en kommentar. ]]
        if bas is None:
            bas = doc
            skillnad = "(basen sjalv)"
        else:
            extra = len(b) - len(bas.encode("utf-8"))
            skillnad = "+%d byte mot basen" % extra

        print("  %-12s %-46s" % (namn, beskrivning))
        print("     fil     : %s" % vag.name)
        print("     storlek : %d byte   %s" % (len(b), skillnad))
        print("     sha256  : %s" % hashlib.sha256(b).hexdigest())
        print("     rot     : %s" % ("namespace" if arg["rot"] is ROT_NAMESPACE
                                     else "bar"))
        print("     External: %s   Workspace: %s"
              % ("JA" if arg["external"] else "nej",
                 "JA" if arg["workspace"] else "nej"))
        print("")

    print("Fyra filer skrivna i %s. Ingenting publicerat." % kat)
    return 0


if __name__ == "__main__":
    sys.exit(main())
