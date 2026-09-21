#!/usr/bin/env python3
"""J och K: alla kvarvarande kanda skillnader pa en gang, med bevis.

Utuslutet hittills, allt matt: formatet (XML fungerar), nyckel, scope,
endpoint, auth, tabbindrag, <External>, namespace-attribut,
Workspace-noden och Source-typen (ProtectedString kontra string, provad
at bada hallen).

Kvar i den UPPRAKNADE skillnadsmangden mellan var artefakt och Rojos
star tva saker:

    referentstil    var RBX0..RBX82   Rojo 0..81
    RunContext      var saknas        Rojo <token name="RunContext">0</token>

Provet lagger bada pa en gang, at bada hallen:

    J  Rojos fil + BADA skillnaderna   ska bryta en fil som gar igenom
    K  var fil  - BADA skillnaderna    ska laga en fil som faller

    J=400, K=200  -> orsaken finns i mangden; bisektera inuti den
    J=200, K=400  -> mangden ar TOM pa forklaringar. Sluta gissa.

Det andra utfallet ar det troliga och det mest anvandbara: det bevisar
att blockeraren ligger utanfor allt jag lyckats rakna upp, och att
delta-debugging av den riktiga artefakten ar ratt nasta metod.

    python3 tools/kvarvarande-diff.py --in <fil> --ut <fil> --riktning j|k

REFERENTER ar oanvanda i bada filerna — noll <Ref>-egenskaper. Skriptet
kontrollerar det anda och AVBRYTER om nagon dyker upp, for da skulle
omskrivningen bryta korsreferenser och mata fel sak.

DIAGNOSTIK, INTE EN GRIND. Skriver bara filer — publicerar ingenting.
"""
import argparse
import hashlib
import pathlib
import re
import sys

REFERENT = re.compile(r'referent="(RBX)?(\d+)"')
REF_EGENSKAP = re.compile(r"<Ref\b")
RUNCONTEXT = re.compile(r'[ \t]*<token name="RunContext">\d+</token>\r?\n')
CDATA = re.compile(r"<!\[CDATA\[(.*?)\]\]>", re.S)

#[[ Ordagrant som Rojo skriver den, inklusive indraget i Rojos fil. For
#   K infogas den i VAR fil, som har tabbar — indraget OCH radslutet
#   tas darfor fran Name-raden ovanfor i stallet for att hardkodas. ]]
RUNCONTEXT_RAD = '<token name="RunContext">0</token>'

#[[ Raden ska sta direkt efter Name och fore Source, dar Rojo har den.
#   Radslutet fangas i grupp 2: en CRLF-fil far inte fa en ensam LF-rad
#   instoppad, och en LF-fil inte en CRLF-rad. ]]
NAMN_RAD = re.compile(r'([ \t]*)<string name="Name">[^<]*</string>(\r?\n)')


def fel(text):
    print("AVBRUTET — %s" % text)
    raise SystemExit(2)


def las(vag):
    p = pathlib.Path(vag)
    if not p.is_file() or p.stat().st_size == 0:
        fel("filen finns inte eller ar tom: %s" % p)
    b = p.read_bytes()
    t = b.decode("utf-8")
    if t.encode("utf-8") != b:
        fel("filen ar inte ren UTF-8")
    return p, b, t


def rakna_referenter(t):
    rbx = len(re.findall(r'referent="RBX\d+"', t))
    tal = len(re.findall(r'referent="\d+"', t))
    return rbx, tal


def till_rbx(t):
    return REFERENT.sub(lambda m: 'referent="RBX%s"' % m.group(2), t)


def till_tal(t):
    return REFERENT.sub(lambda m: 'referent="%s"' % m.group(2), t)


def ta_bort_runcontext(t):
    return RUNCONTEXT.sub("", t)


def lagg_till_runcontext(t):
    """En RunContext-rad i varje Script-item, direkt efter Name."""
    ut = []
    i = 0
    antal = 0
    for m in re.finditer(r'<Item class="Script"[^>]*>', t):
        #[[ Hitta Name-raden inuti just det har Script-elementet. ]]
        nm = NAMN_RAD.search(t, m.end())
        if nm is None:
            fel("hittade ingen Name-rad i ett Script-element")
        ut.append(t[i:nm.end()])
        ut.append("%s%s%s" % (nm.group(1), RUNCONTEXT_RAD, nm.group(2)))
        i = nm.end()
        antal += 1
    ut.append(t[i:])
    if antal == 0:
        fel("hittade inga Script-element att lagga RunContext i")
    return "".join(ut), antal


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--in", dest="infil", required=True)
    p.add_argument("--ut", required=True)
    p.add_argument("--riktning", required=True, choices=("j", "k"))
    a = p.parse_args()

    invag, rabytes, text = las(a.infil)

    #[[ Oanvanda referenter ar forutsattningen for att omskrivningen ar
    #   ofarlig. Dyker en <Ref> upp ska provet STOPPA, inte gissa. ]]
    if REF_EGENSKAP.search(text):
        fel("filen innehaller <Ref>-egenskaper — omskrivning av referenter "
            "skulle bryta korsreferenser. Stoppar enligt ordern.")

    fore_rbx, fore_tal = rakna_referenter(text)
    fore_rc = len(RUNCONTEXT.findall(text))

    if a.riktning == "j":
        #[[ Rojos fil far VARA egenskaper. ]]
        if fore_rbx:
            fel("infilen har redan RBX-referenter — fel riktning?")
        steg1 = till_rbx(text)
        steg2 = ta_bort_runcontext(steg1)
        ny = steg2
        #[[ Reversibiliteten: referentbytet ska ga att vanda exakt. ]]
        if till_tal(steg1) != text:
            fel("referentbytet gick inte att vanda tillbaka till originalet")
        rc_andring = "borttagna: %d" % (fore_rc - len(RUNCONTEXT.findall(ny)))
    else:
        if fore_tal and not fore_rbx:
            fel("infilen har redan numeriska referenter — fel riktning?")
        steg1 = till_tal(text)
        if till_rbx(steg1) != text:
            fel("referentbytet gick inte att vanda tillbaka till originalet")
        ny, lagda = lagg_till_runcontext(steg1)
        #[[ Och det tillagget ska ga att ta bort igen och ge steg1. ]]
        if ta_bort_runcontext(ny) != steg1:
            fel("RunContext-tillagget gick inte att ta bort rent")
        rc_andring = "tillagda: %d" % lagda

    if CDATA.findall(text) != CDATA.findall(ny):
        fel("CDATA-innehallet andrades — skriptkallor ska vara ororda")

    efter_rbx, efter_tal = rakna_referenter(ny)
    if fore_rbx + fore_tal != efter_rbx + efter_tal:
        fel("antalet referenter andrades: %d -> %d"
            % (fore_rbx + fore_tal, efter_rbx + efter_tal))

    utvag = pathlib.Path(a.ut)
    utvag.parent.mkdir(parents=True, exist_ok=True)
    ub = ny.encode("utf-8")
    utvag.write_bytes(ub)

    print("KVARVARANDE SKILLNADER — riktning %s" % a.riktning.upper())
    print("  infil        : %s" % invag.name)
    print("    storlek    : %d byte" % len(rabytes))
    print("    sha256     : %s" % hashlib.sha256(rabytes).hexdigest())
    print("    referenter : RBX=%d  numeriska=%d" % (fore_rbx, fore_tal))
    print("    RunContext : %d" % fore_rc)
    print("  utfil        : %s" % utvag.name)
    print("    storlek    : %d byte   (%+d)" % (len(ub), len(ub) - len(rabytes)))
    print("    sha256     : %s" % hashlib.sha256(ub).hexdigest())
    print("    referenter : RBX=%d  numeriska=%d" % (efter_rbx, efter_tal))
    print("    RunContext : %d   (%s)" % (len(RUNCONTEXT.findall(ny)),
                                          rc_andring))
    print("  BEVIS")
    print("    <Ref>-egenskaper i filen                  : 0 (kontrollerat)")
    print("    referentbytet reversibelt till originalet : JA")
    print("    RunContext-andringen reversibel           : JA")
    print("    CDATA-block oforandrade (%d st)           : JA"
          % len(CDATA.findall(text)))
    print("    antalet referenter oforandrat             : JA")
    return 0


if __name__ == "__main__":
    sys.exit(main())
