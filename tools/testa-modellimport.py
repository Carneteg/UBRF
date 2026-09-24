#!/usr/bin/env python3
"""Provar att bygg-place.py bar en .rbxmx-modell UTAN att forstora den.

Bakgrunden ar #264: hastmallen gick inte att fa in i den reproducerbara
leveransvagen, och den enda hasten i placen var en lada. Byggaren las bara
Luau. Skalet som angavs holl inte -- .rbxmx ar text -- men det SVARA ar
inte att lasa filen, det ar att inte forstora den pa vagen in.

Tre saker kan ga sonder tyst, och alla tre mats har:

  1. REFERENTKOLLISIONEN. Bada dokumenten numrerar sina instanser RBX0,
     RBX1, ... Klistras modellen in ratt av pekar dess Motor6D pa VARA
     skript i stallet for pa sina egna delar. Da ser filen hel ut och
     hasten faller isar i Studio.

  2. EGENSKAPER SOM TAPPAS. Mesh-id, textur-id, CFrame, storlek. En
     modell utan MeshId ar en lada med ratt namn -- alltsa exakt det
     problem det har ska losa.

  3. SAKER SOM INTE FAR BARAS IN. Skript i en asset ar oreviderad korbar
     kod, och <SharedString> kan inte foljas med utan dokumentets egen
     tabell. Bada ska avvisas NAMNGIVET, inte tyst tappas.

    python3 tools/testa-modellimport.py
"""
from __future__ import annotations

import importlib.util
import io
import pathlib
import tempfile
import xml.etree.ElementTree as ET

ROT = pathlib.Path(__file__).resolve().parent.parent
FIXTUR = ROT / "roblox" / "tests" / "fixtures" / "provmodell.rbxmx"

_spec = importlib.util.spec_from_file_location(
    "byggplace", ROT / "tools" / "bygg-place.py")
BP = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(BP)

fel = 0


def kolla(namn, villkor, detalj=""):
    global fel
    if villkor:
        print("  ok   %s%s" % (namn, ("  " + detalj) if detalj else ""))
    else:
        fel += 1
        print("  FEL  %s%s" % (namn, ("  " + detalj) if detalj else ""))


def med_text(text):
    """Kor las_modell pa en tillfallig modellfil och ge tillbaka noden."""
    with tempfile.TemporaryDirectory() as d:
        p = pathlib.Path(d) / "prov.rbxmx"
        io.open(p, "w", encoding="utf-8", newline="\n").write(text)
        return BP.las_modell(p, "prov.rbxmx", "k3")


def avvisas(namn, text, vantat):
    """Modellen ska INTE ga igenom, och nejet ska saga varfor."""
    try:
        med_text(text)
    except SystemExit as e:
        kolla(namn, vantat in str(e), str(e)[:74])
        return
    kolla(namn, False, "slapptes igenom")


def main():
    print("MODELLIMPORTEN -- #264 R3")
    print("")

    kolla("fixturen finns", FIXTUR.is_file())
    if not FIXTUR.is_file():
        return 1
    ratext = io.open(FIXTUR, encoding="utf-8").read()

    nod = BP.las_modell(FIXTUR, "tests/fixtures/provmodell.rbxmx", "k3")
    kolla("modellen lases som en Model", nod.klass == "Model", nod.klass)
    kolla("och far namnet ur projektfilen, inte ur filen",
          nod.namn == "k3", nod.namn)
    kolla("den bars som fardig XML, inte som kalltext",
          nod.radxml is not None and nod.kalla is None)

    rot = ET.fromstring(nod.radxml)

    # -- 1. REFERENTERNA -------------------------------------------------
    refs = [e.get("referent") for e in rot.iter("Item")]
    kolla("varje instans har en referent", all(refs))
    gamla = ("RBX0", "RBX1", "RBX2", "RBX3", "RBX4")
    kolla("INGEN referent heter kvar RBX0 -- kollisionen ar bruten",
          not any(r in gamla for r in refs), str(refs[:2]))
    kolla("och de ar fortfarande unika sinsemellan",
          len(set(refs)) == len(refs),
          "%d av %d" % (len(set(refs)), len(refs)))

    egna = set(refs)
    inre = [(r.get("name"), (r.text or "").strip()) for r in rot.iter("Ref")]
    trasiga = [n for n, v in inre if v != "null" and v not in egna]
    kolla("VARJE inre referens pekar pa en instans i modellen",
          not trasiga, str(trasiga))
    kolla("och en referens utat lamnades som null",
          any(v == "null" for _, v in inre))

    def del_med_namn(n):
        for e in rot.iter("Item"):
            if e.findtext("./Properties/string[@name='Name']") == n:
                return e
        return None

    bal, ben = del_med_namn("Bal"), del_med_namn("Ben")
    prim = next((v for n, v in inre if n == "PrimaryPart"), None)
    kolla("PrimaryPart pekar pa ratt del efter omskrivningen",
          bal is not None and prim == bal.get("referent"), str(prim))
    p0 = next((v for n, v in inre if n == "Part0"), None)
    p1 = next((v for n, v in inre if n == "Part1"), None)
    kolla("JOINTEN halls ihop: Part0/Part1 pekar pa sina delar",
          bal is not None and ben is not None
          and p0 == bal.get("referent") and p1 == ben.get("referent"),
          "%s / %s" % (p0, p1))

    # -- 2. EGENSKAPERNA -------------------------------------------------
    urler = [e.text for e in rot.iter("url")]
    kolla("MESH-ID:t foljde med orort",
          "rbxassetid://4863472026" in urler, str(urler))
    kolla("och TEXTUR-ID:t ocksa",
          "rbxassetid://4863472127" in urler)
    cf = rot.find(".//CoordinateFrame[@name='CFrame']")
    kolla("TRANSFORMEN foljde med",
          cf is not None and cf.findtext("X") == "1.5"
          and cf.findtext("Y") == "2.25")
    kolla("och storleken", rot.find(".//Vector3[@name='size']") is not None)
    kolla("hela tradet kom med -- inga delar tappade pa vagen",
          len(refs) == 5, "%d instanser" % len(refs))

    # -- 3. DET SOM SKA AVVISAS ------------------------------------------
    avvisas("ETT SKRIPT I MODELLEN AVVISAS",
            ratext.replace('<Item class="SpecialMesh" referent="RBX2">',
                           '<Item class="Script" referent="RBX2">', 1),
            "Script")
    delad = ("<SharedStrings><SharedString md5=\"x\">a</SharedString>"
             "</SharedStrings></roblox>")
    avvisas("EN DELAD STRANG AVVISAS NAMNGIVET",
            ratext.replace("</roblox>", delad, 1), "SharedString")
    avvisas("EN REFERENS UTANFOR MODELLEN AVVISAS",
            ratext.replace('<Ref name="Parent">null</Ref>',
                           '<Ref name="Parent">RBX999</Ref>', 1), "RBX999")
    extra = ('<Item class="Model" referent="RBX9"><Properties>'
             '<string name="Name">Extra</string></Properties></Item></roblox>')
    avvisas("TVA ROTINSTANSER AVVISAS",
            ratext.replace("</roblox>", extra, 1), "EN rotinstans")

    # -- 4. HELA VAGEN UT ------------------------------------------------
    raknare = [0]
    ut = BP.xml_for(nod, raknare, 1)
    kolla("raknaren tar med modellens instanser",
          raknare[0] == 5, "%d" % raknare[0])
    kolla("och utskriften ar valformad XML", ET.fromstring(ut) is not None)
    kolla("mesh-id:t finns kvar i den utskrivna XML:en",
          "rbxassetid://4863472026" in ut)

    # -- 5. INGEN KROCK MED VARA EGNA INSTANSER --------------------------
    # Det avgorande provet: modellen bredvid vart eget trad, i SAMMA
    # dokument. Hittar man samma referent tva ganger har nagot pekat fel.
    vart = BP.Nod("Folder", "Prov")
    vart.barn.append(BP.Nod("ModuleScript", "En", "return 1"))
    raknare = [0]
    ihop = ("<roblox version=\"4\">" + BP.xml_for(vart, raknare, 1)
            + BP.xml_for(nod, raknare, 1) + "</roblox>")
    doc = ET.fromstring(ihop)
    alla = [e.get("referent") for e in doc.iter("Item")]
    kolla("INGEN REFERENT KROCKAR nar modellen ligger bredvid vart trad",
          len(set(alla)) == len(alla),
          "%d unika av %d" % (len(set(alla)), len(alla)))

    # -- 6. MODELLBYTES INGAR I BUILD-IDENTITETEN ------------------------
    # Ordern ar uttrycklig: identiteten ska rakna modellens bytes, inte
    # bara Luau. `kallhash` laser redan rena bytes for varje MAPPAD fil,
    # men «redan» ar ett antagande tills det ar matt. En hash som inte
    # ror sig nar modellen andras later en ny hast ga ut under gammal
    # identitet -- precis det felet #171 handlade om, i ny form.
    bi = importlib.util.spec_from_file_location(
        "byggidentitet", ROT / "tools" / "bygg-identitet.py")
    BI = importlib.util.module_from_spec(bi)
    bi.loader.exec_module(BI)

    with tempfile.TemporaryDirectory() as d:
        m = pathlib.Path(d) / "k3.rbxmx"
        io.open(m, "w", encoding="utf-8", newline="\n").write(ratext)
        fore = BI.kallhash([("k3.rbxmx", m)])
        io.open(m, "w", encoding="utf-8", newline="\n").write(
            ratext.replace("rbxassetid://4863472026",
                           "rbxassetid://9999999999", 1))
        efter = BI.kallhash([("k3.rbxmx", m)])
    kolla("MODELLBYTES ANDRAR BUILD-IDENTITETEN", fore != efter,
          "%s -> %s" % (fore[:12], efter[:12]))

    print("")
    print("%d fel" % fel)
    return 1 if fel else 0


if __name__ == "__main__":
    raise SystemExit(main())
