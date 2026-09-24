#!/usr/bin/env python3
"""Vaktar hastmodellens vag in i placen -- och sager nar den saknas.

Bakgrund (#264). Tobias speltest visade en LADHAST. Mallen finns
(`ServerStorage.HastVisualer.k3`, 42 delar, 40 nat, 40 Motor6D) men bara i
startplacen, och byggaren las forst bara Luau. R3 gav byggaren formagan att
bara en `.rbxmx`; den har grinden vaktar att formagan ocksa ANVANDS och att
modellen kommer fram hel.

DEN SLAR PA SIG SJALV. Sa lange projektfilen inte mappar nagon hastmodell
rapporterar grinden `SAKNAS` och gar igenom -- beroendet ar en KAND
blockerare, inte ett fel nagon infort. I samma stund mappningen finns blir
grinden strang, utan att nagon behover komma ihag att skruva pa den. En
grind man maste minnas att aktivera ar en grind som gloms.

    python3 tools/kolla-hastmodell.py
"""
from __future__ import annotations

import json
import pathlib
import xml.etree.ElementTree as ET

ROT = pathlib.Path(__file__).resolve().parent.parent
ROBLOX = ROT / "roblox"
PROJEKT = ROBLOX / "default.project.json"

#[[ Sokvagen i DataModel som `HastRigg` skulle lasa mallen ur. Namnet star
#   har och i projektfilen -- gar de isar ska det synas har, inte i Studio. ]]
TJANST = "ServerStorage"
MAPP = "HastVisualer"
MALL = "k3"

fel = 0


def kolla(namn, villkor, detalj=""):
    global fel
    if villkor:
        print("  ok   %s%s" % (namn, ("  " + detalj) if detalj else ""))
    else:
        fel += 1
        print("  FEL  %s%s" % (namn, ("  " + detalj) if detalj else ""))


def main():
    print("HASTMODELLEN -- #264")
    print("")

    trad = json.loads(PROJEKT.read_text(encoding="utf-8"))["tree"]
    tjanst = trad.get(TJANST)
    nod = tjanst.get(MAPP) if isinstance(tjanst, dict) else None
    mall = nod.get(MALL) if isinstance(nod, dict) else None
    vag = mall.get("$path") if isinstance(mall, dict) else None

    if vag is None:
        #[[ INGEN mappning an. Det ar den kanda blockeraren, och den ska
        #   rapporteras som den ar -- inte som ett PASS och inte som ett
        #   fel nagon infort. ]]
        print("  SAKNAS  %s.%s.%s ar inte mappad i default.project.json"
              % (TJANST, MAPP, MALL))
        print("")
        print("  Hastmallen finns i startplacen 106030782437053 men har")
        print("  annu inte kunnat exporteras till repot. Byggaren KAN bara")
        print("  en .rbxmx sedan #264 R3 -- se tools/testa-modellimport.py.")
        print("  Den har grinden blir strang av sig sjalv nar mappningen")
        print("  laggs till; ingen behover komma ihag att aktivera den.")
        print("")
        print("HASTMODELL: SAKNAS (kand blockerare, inte ett regressionsfel)")
        return 0

    p = (ROBLOX / vag)
    kolla("modellfilen finns", p.is_file(), vag)
    if not p.is_file():
        return 1
    kolla("och den ar en .rbxmx -- inte ett binart .rbxm",
          p.suffix == ".rbxmx", p.suffix)

    rot = ET.fromstring(p.read_text(encoding="utf-8"))
    poster = [e for e in rot if e.tag == "Item"]
    kolla("filen har exakt en rotinstans", len(poster) == 1,
          "%d" % len(poster))
    if len(poster) != 1:
        return 1
    modell = poster[0]

    kolla("rotinstansen ar en Model", modell.get("class") == "Model",
          str(modell.get("class")))

    delar = [e for e in modell.iter("Item") if e.get("class") in
             ("Part", "MeshPart", "WedgePart", "UnionOperation")]
    nat = [e for e in modell.iter("Item")
           if e.get("class") in ("SpecialMesh", "MeshPart")]
    joints = [e for e in modell.iter("Item") if e.get("class") == "Motor6D"]
    kolla("modellen har delar", len(delar) > 0, "%d" % len(delar))
    #[[ EN LADA AR INTE EN HAST. Det var hela fyndet: en modell utan nat
    #   ser ut som en modell i tradet och som en lada pa skarmen. ]]
    kolla("OCH NAT -- annars ar det fortfarande en lada", len(nat) > 0,
          "%d nat" % len(nat))
    kolla("och joints, sa att den gar att animera", len(joints) > 0,
          "%d Motor6D" % len(joints))

    # Referensintegritet: varje <Ref> ska peka inom modellen eller vara null.
    egna = {e.get("referent") for e in modell.iter("Item")}
    trasiga = [(r.get("name"), (r.text or "").strip())
               for r in modell.iter("Ref")
               if (r.text or "").strip() not in egna
               and (r.text or "").strip() not in ("", "null")]
    kolla("VARJE referens pekar inom modellen eller ar null",
          not trasiga, str(trasiga[:3]))

    prim = next(((r.text or "").strip() for r in modell.iter("Ref")
                 if r.get("name") == "PrimaryPart"), None)
    kolla("PrimaryPart ar satt och pekar pa en del i modellen",
          prim is not None and prim in egna, str(prim))

    skript = [e.get("class") for e in modell.iter("Item")
              if e.get("class") in ("Script", "LocalScript", "ModuleScript")]
    kolla("och modellen bar ingen korbar kod", not skript, str(skript))

    print("")
    print("HASTMODELL: %s" % ("FEL" if fel else "PASS"))
    return 1 if fel else 0


if __name__ == "__main__":
    raise SystemExit(main())
