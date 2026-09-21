#!/usr/bin/env python3
"""Fem armar for #264: Rojos XML muterad en egenskap i taget.

Den forra bisektionen var ogiltig for att jag KONSTRUERADE en bas som
borde vara likvardig med Rojos. Den var det inte — indraget forblev vart
och tjansterna saknade barn, och bada holls konstanta over alla armar.

Den har gangen muteras Rojos FAKTISKA bytes, en fil som ar matt till
HTTP 200. En mutation av en kant-god fil kan inte bara det felet.

  A  Rojos bygge, oforandrat            — basen, maste ge 2xx
  B  A med tva mellanslags indrag -> tabbar
  C  A + <External>null</External> och <External>nil</External>
  D  A + xmlns/xsi/schema-location pa roten
  E  A + den injicerade Workspace-noden ur bygg-place.py

Ger inte A 2xx ar korningen ogiltig och ingenting far laras av B-E.

    python3 tools/mutera-xml.py --bas <rojo.rbxlx> --katalog <ut>

VARJE ARMS PASTAENDE BEVISAS HAR, inte i en kommentar: skriptet
kontrollerar att B-E skiljer sig fran A i exakt den avsedda egenskapen
och avbryter annars.

CDATA AR HELIGT. Skriptkallor ligger i <![CDATA[...]]> och innehaller
egna radindrag. Att rora dem vore en INNEHALLSANDRING, inte en
formatandring, och skulle gora arm B till ett annat prov an det utger
sig for. B ror darfor aldrig rader inuti CDATA.

DIAGNOSTIK, INTE EN GRIND. Skriver bara filer — publicerar ingenting.
"""
import argparse
import hashlib
import pathlib
import sys

#[[ Ordagrant ur tools/bygg-place.py:239-242. ]]
ROT_NAMESPACE = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
    'version="4">'
)

#[[ Ur tools/bygg-place.py:243-244. Indraget foljer BASENS stil (tva
#   mellanslag), inte bygg-place.py:s tabbar — annars skulle arm C
#   variera BADE External och indrag, och da vore den inte enarmad.
#   Ordern ber om samma position och ordning, vilket ar det som bevaras. ]]
EXTERNAL = "  <External>null</External>\n  <External>nil</External>\n"

#[[ Workspace-noden i bygg-place.py:s EXAKTA serialiserade form, som
#   ordern begar — inklusive dess tabbindrag och RBX-referent. Det gor
#   att arm E bar med sig tabbar i just de fem raderna. Se rapporten:
#   ar arm B gron ar E ren, ar B rod ar E sammanblandad med den. ]]
WORKSPACE = (
    '\t<Item class="Workspace" referent="RBX0">\n'
    "\t\t<Properties>\n"
    '\t\t\t<string name="Name">Workspace</string>\n'
    "\t\t</Properties>\n"
    "\t</Item>\n"
)


def fel(text):
    print("AVBRUTET — %s" % text)
    raise SystemExit(2)


def rader(text):
    """Rader med radbrytningen kvar, sa bytes kan aterstallas exakt."""
    return text.splitlines(keepends=True)


def utanfor_cdata(text):
    """Ja/nej per rad: borjar raden UTANFOR ett CDATA-block?"""
    ut = []
    inne = False
    for rad in rader(text):
        ut.append(not inne)
        #[[ En rad kan bade oppna och stanga. Rakna i ordning. ]]
        i = 0
        while True:
            if not inne:
                j = rad.find("<![CDATA[", i)
                if j < 0:
                    break
                inne, i = True, j + 9
            else:
                j = rad.find("]]>", i)
                if j < 0:
                    break
                inne, i = False, j + 3
    return ut


def mutera_indrag(text):
    """Tva mellanslags indrag -> tabbar, aldrig inuti CDATA."""
    utanfor = utanfor_cdata(text)
    ut = []
    for rad, fri in zip(rader(text), utanfor):
        if not fri:
            ut.append(rad)
            continue
        strippad = rad.lstrip(" ")
        antal = len(rad) - len(strippad)
        if antal and antal % 2 == 0:
            ut.append("\t" * (antal // 2) + strippad)
        else:
            ut.append(rad)
    return "".join(ut)


def efter_roten(text, infogning):
    """Lagg infogningen direkt efter rotelementets rad."""
    r = rader(text)
    if not r or not r[0].startswith("<roblox"):
        fel("basens forsta rad ar inte rotelementet: %r" % (r[0][:60] if r
                                                            else ""))
    return r[0] + infogning + "".join(r[1:])


def mutera_rot(text):
    r = rader(text)
    if r[0].rstrip("\r\n") != '<roblox version="4">':
        fel("basens rotelement ar inte det vantade: %r" % r[0].rstrip())
    return ROT_NAMESPACE + "\n" + "".join(r[1:])


# ── Bevisen. Varje arm ska skilja sig fran A i EXAKT en sak. ───────────

def bevisa_indrag(a, b):
    """B ska bli A igen om man tar bort allt ledande indrag utanfor CDATA."""
    def platta(text):
        utanfor = utanfor_cdata(text)
        return "".join(rad.lstrip(" \t") if fri else rad
                       for rad, fri in zip(rader(text), utanfor))
    if platta(a) != platta(b):
        fel("arm B andrade nagot annat an indraget")
    if a == b:
        fel("arm B ar identisk med A — ingen mutation skedde")
    return "samma innehall rad for rad; bara ledande indrag skiljer"


def bevisa_infogning(a, m, infogad, namn):
    """M ska bli A igen om man tar bort exakt de infogade raderna."""
    ra, rm = rader(a), rader(m)
    inf = rader(infogad)
    if len(rm) != len(ra) + len(inf):
        fel("arm %s andrade antalet rader med %d, vantade %d"
            % (namn, len(rm) - len(ra), len(inf)))
    #[[ Ta bort de infogade raderna dar de las in och jamfor med A. ]]
    utan = rm[:1] + rm[1 + len(inf):]
    if "".join(utan) != a:
        fel("arm %s andrade nagot utover infogningen" % namn)
    return "exakt %d rader infogade direkt efter roten; resten ororda" % len(inf)


def bevisa_rot(a, d):
    ra, rd = rader(a), rader(d)
    if len(ra) != len(rd):
        fel("arm D andrade antalet rader")
    if "".join(ra[1:]) != "".join(rd[1:]):
        fel("arm D andrade nagot utanfor rotelementet")
    if ra[0] == rd[0]:
        fel("arm D andrade inte rotelementet")
    return "bara rad 1 skiljer; alla ovriga rader identiska"


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bas", required=True, help="Rojos rbxlx-bygge")
    p.add_argument("--katalog", required=True)
    a_arg = p.parse_args()

    basvag = pathlib.Path(a_arg.bas)
    if not basvag.is_file() or basvag.stat().st_size == 0:
        fel("basen finns inte eller ar tom: %s" % basvag)
    rabytes = basvag.read_bytes()
    A = rabytes.decode("utf-8")
    if A.encode("utf-8") != rabytes:
        fel("basen ar inte ren UTF-8 — muteringen far inte andra kodningen")

    kat = pathlib.Path(a_arg.katalog)
    kat.mkdir(parents=True, exist_ok=True)

    B = mutera_indrag(A)
    C = efter_roten(A, EXTERNAL)
    D = mutera_rot(A)
    E = efter_roten(A, WORKSPACE)

    armar = (
        ("A-bas", A, "Rojos bygge, oforandrat",
         "byte-identisk med bygget"),
        ("B-tabbar", B, "tva mellanslags indrag -> tabbar",
         bevisa_indrag(A, B)),
        ("C-external", C, "+ de tva <External>-noderna",
         bevisa_infogning(A, C, EXTERNAL, "C")),
        ("D-namespace", D, "+ xmlns/xsi/schema-location pa roten",
         bevisa_rot(A, D)),
        ("E-workspace", E, "+ Workspace-noden ur bygg-place.py",
         bevisa_infogning(A, E, WORKSPACE, "E")),
    )

    print("MUTATIONSPROV #264 — fem armar ur Rojos faktiska bytes")
    print("")
    for namn, text, vad, bevis in armar:
        b = text.encode("utf-8")
        vag = kat / ("mut-%s.rbxlx" % namn)
        vag.write_bytes(b)
        if namn == "A-bas" and b != rabytes:
            fel("arm A ar inte byte-identisk med bygget")
        print("  %-13s %s" % (namn, vad))
        print("     fil     : %s" % vag.name)
        print("     storlek : %d byte   (%+d mot A)"
              % (len(b), len(b) - len(rabytes)))
        print("     sha256  : %s" % hashlib.sha256(b).hexdigest())
        print("     bevis   : %s" % bevis)
        print("")

    print("Fem filer skrivna i %s. Ingenting publicerat." % kat)
    return 0


if __name__ == "__main__":
    sys.exit(main())
