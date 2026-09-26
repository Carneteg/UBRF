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

    # I Roblox-XML AR instansens namn dess <string name="Name">. Rattas den
    # inte hamnar modellen i placen som "ProvModell" och sokvagen
    # ServerStorage.HastVisualer.k3 loser inte upp -- hasten blir en lada
    # igen, fast av ett helt annat skal. `nod.namn` bevisar ingenting om
    # det: den kommer ur ANROPET, inte ur XML:en.
    kolla("MODELLENS EGEN Name ar projektfilens, inte filens",
          rot.findtext("./Properties/string[@name='Name']") == "k3",
          str(rot.findtext("./Properties/string[@name='Name']")))

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
          len(refs) == 7, "%d instanser" % len(refs))

    # MeshPart ar den form den RIKTIGA k3 har: 40 MeshPart, 40 Motor6D,
    # 2 Part, 2 WeldConstraint. Provas inte den formen sager fixturen
    # ingenting om filen vi faktiskt ska bara in. MeshPart stavar sin
    # textur TextureID, SpecialMesh stavar den TextureId -- en av de
    # detaljer som tyst tappas om man skriver om egenskaper i stallet
    # for att bara dem ororda.
    mp = next((e for e in rot.iter("Item")
               if e.get("class") == "MeshPart"), None)
    kolla("MeshPart-formen bars ocksa", mp is not None)
    kolla("MeshPartens MeshId foljde med",
          "rbxassetid://4863471909" in urler)
    kolla("och dess TextureID -- med MeshParts egen stavning",
          mp is not None and mp.find(
              "./Properties/Content[@name='TextureID']") is not None)
    wc = next((e for e in rot.iter("Item")
               if e.get("class") == "WeldConstraint"), None)
    kolla("WeldConstraint bars med sina bada Part-referenser",
          wc is not None and len(wc.findall("./Properties/Ref")) == 2)

    # -- 3. DET SOM SKA AVVISAS ------------------------------------------
    avvisas("ETT SKRIPT I MODELLEN AVVISAS",
            ratext.replace('<Item class="SpecialMesh" referent="RBX2">',
                           '<Item class="Script" referent="RBX2">', 1),
            "Script")
    #  KONTRAKTET HAR SVANGT, OCH DET AR RATTELSEN.
    #  Har stod att en delad strang AVVISAS. Det holl sa lange ingen
    #  riktig modell anvande dem. Den riktiga k3 har 169: 2 tabellposter
    #  och 167 hanvisningar (Tags, AeroMeshData, PhysicalConfigData,
    #  ModelMeshData, SlimHash). Avvisandets egen motivering -- "de bor i
    #  dokumentets egen tabell" -- var ingen anledning att saga nej, utan
    #  en beskrivning av vad som maste goras.
    #
    #  Att bara slanga tabellen hade inte synts i tradet:
    #  PhysicalConfigData ar kollisionsdata. Det som avvisas nu ar en
    #  HANVISNING UTAN POST, och en nyckel med tva olika innehall.
    avvisas("EN HANVISNING UTAN POST I TABELLEN AVVISAS",
            ratext.replace('<SharedString md5="prov1==">QUJD</SharedString>',
                           "", 1),
            "hanvisas utan att")
    avvisas("EN REFERENS UTANFOR MODELLEN AVVISAS",
            ratext.replace('<Ref name="Parent">null</Ref>',
                           '<Ref name="Parent">RBX999</Ref>', 1), "RBX999")
    extra = ('<Item class="Model" referent="RBX9"><Properties>'
             '<string name="Name">Extra</string></Properties></Item></roblox>')
    avvisas("TVA ROTINSTANSER AVVISAS",
            ratext.replace("</roblox>", extra, 1), "EN rotinstans")

    # -- 3b. DOKUMENTNIVAN FOLJER MED ------------------------------------
    kolla("den delade tabellen bars med noden", len(nod.delade) == 2,
          str(sorted(nod.delade)))
    kolla("och dess INNEHALL, inte bara nycklarna",
          nod.delade.get("prov1==") == "QUJD", repr(nod.delade.get("prov1==")))
    kolla("Meta bars ocksa -- ExplicitAutoJoints styr joints vid inlasning",
          nod.meta.get("ExplicitAutoJoints") == "true", str(nod.meta))
    #  Hanvisningarna ligger INNE i instanserna och ska folja <Item>.
    hanv = [(e.get("name"), (e.text or "").strip())
            for e in rot.iter("SharedString") if e.get("name")]
    kolla("hanvisningarna foljde med instansen",
          len(hanv) == 2 and all(v in nod.delade for _, v in hanv),
          str(hanv))

    #  Samma nyckel med OLIKA innehall ar en tyst forvanskning.
    a = BP.las_modell(FIXTUR, "a.rbxmx", "a")
    b = BP.las_modell(FIXTUR, "b.rbxmx", "b")
    b.delade["prov1=="] = "ANNAT"
    try:
        BP.samla_dokumentniva([a, b])
        kolla("SAMMA NYCKEL MED OLIKA INNEHALL AVVISAS", False,
              "slapptes igenom")
    except SystemExit as e:
        kolla("SAMMA NYCKEL MED OLIKA INNEHALL AVVISAS",
              "TVA olika" in str(e), str(e)[:70])
    #  Samma nyckel med SAMMA innehall ar deduplicering, inte en krock.
    c = BP.las_modell(FIXTUR, "c.rbxmx", "c")
    d = BP.las_modell(FIXTUR, "d.rbxmx", "d")
    delade, meta = BP.samla_dokumentniva([c, d])
    kolla("men samma nyckel med samma innehall ar deduplicering",
          len(delade) == 2 and meta.get("ExplicitAutoJoints") == "true",
          "%d nycklar" % len(delade))

    # -- 4. HELA VAGEN UT ------------------------------------------------
    raknare = [0]
    ut = BP.xml_for(nod, raknare, 1)
    kolla("raknaren tar med modellens instanser",
          raknare[0] == 7, "%d" % raknare[0])
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
