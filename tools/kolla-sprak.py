#!/usr/bin/env python3
"""SPRÅKGRINDENS STATISKA HALVA (#162).

`roblox/tests/sprak.spec.luau` kör ytorna på `sv-se` och `en-us` och mäter
att texten byter språk. Den kan inte se två saker:

  1. NY svensk spelartext som smyger in i en lokaliserad fil. Provet ritar
     de vyer det känner; en ny rubrik i en gren provet inte når blir
     svensk för alla utan att någon mätning säger till.
  2. En NYCKEL SOM INTE FINNS. `Sprak.t("hud.gor_i_ordnign")` returnerar
     nyckeln som text — spelaren läser då "hud.gor_i_ordnign". Det syns
     bara i just den vyn, och bara om någon tittar.

Skannern läser därför koden: varje nyckel som slås upp måste finnas i
katalogen, och i de lokaliserade filerna får ingen svensk stränglitteral
stå kvar utom de fyra former som har ett skäl (se REGLER nedan).

Kör: python3 tools/kolla-sprak.py   (exit 1 vid fynd)
"""
import pathlib, re, sys

ROT = pathlib.Path(__file__).resolve().parent.parent
KATALOG = ROT / "roblox/game/UBRFSprak.luau"

# Filer som ÄR lokaliserade. Listan är avsiktligt explicit: en ny fil som
# ritar spelartext ska läggas till här, och det är då man tänker på saken.
LOKALISERADE = [
    "roblox/src/client/PreparationController.luau",
    "roblox/src/client/KontrollHjalp.luau",
    "roblox/src/client/UgnetaController.luau",
    "roblox/src/client/InteractionController.luau",
    "roblox/src/client/TouchControls.luau",
    "roblox/src/client/Prompttext.luau",
    "roblox/src/server/DorrService.luau",
    "roblox/src/server/StallService.luau",
]

# Alla filer där en nyckel kan slås upp — nyckelkontrollen gäller brett.
NYCKELSOK = ["roblox/src", "roblox/buildings"]

SVENSKT = re.compile(r"[åäöÅÄÖ]")
STRANG = re.compile(r'"([^"\n]*)"')
# `Sprak.t("nyckel")`, `Sprak.finns("nyckel")`, `Sprak.forSpelare(p, "nyckel")`
# och `Sprak.iSprak("sv", "nyckel")` — i den sista är nyckeln ANDRA
# argumentet. Ett anrop med en VARIABEL nyckel (`Sprak.t(nyckel)`) kan
# skannern inte kontrollera och ska inte låtsas göra det.
NYCKEL_ANROP = re.compile(r'Sprak\.(?:t|finns)\("([A-Za-z0-9_.]+)"')
NYCKEL_ANROP2 = re.compile(r'Sprak\.iSprak\(\s*"[a-z-]+"\s*,\s*"([A-Za-z0-9_.]+)"')
NYCKEL_ANROP3 = re.compile(r'Sprak\.forSpelare\([^,]+,\s*"([A-Za-z0-9_.]+)"')
NYCKEL_ATTR = re.compile(r'SetAttribute\("Sprak(?:Nyckel|Objekt)",\s*"([A-Za-z0-9_.]+)"')

REGLER = """  Tillåtna svenska litteraler i en lokaliserad fil:
    · utvecklarutskrift   — raden innehåller warn( eller print(
    · objektnamn i världen — raden innehåller FindFirstChild( eller .Name =
    · svensk STANDARDTEXT intill sin nyckel — ActionText/ObjectText med ett
      SetAttribute("SprakNyckel"/"SprakObjekt", ...) inom tre rader. En
      ProximityPrompt replikeras till alla spelare och kan inte ha ett
      språk på servern; standardtexten gör prompten läsbar även för en
      klient utan Prompttext-modulen.
    · texten i en ~-sträng som bara är ett nyckelnamn (inte spelartext)"""


def avkommentera(kod: str) -> str:
    kod = re.sub(r"--\[(=*)\[.*?\]\1\]", "", kod, flags=re.S)
    return re.sub(r"--[^\n]*", "", kod)


def logiska(rader):
    """Slår ihop rader till SATSER. En `warn(...)` som går över tre rader är
    en utskrift, inte tre påståenden — och utan sammanslagningen såg
    fortsättningsraderna ut som spelartext utan nyckel."""
    ut, buffert, start, balans = [], "", 1, 0
    for i, rad in enumerate(rader, 1):
        if buffert == "":
            start = i
        buffert += (" " if buffert else "") + rad
        balans += rad.count("(") - rad.count(")")
        if balans <= 0:
            ut.append((start, buffert))
            buffert, balans = "", 0
    if buffert:
        ut.append((start, buffert))
    return ut


# Namn på objekt i världen. De läses av Studio och av koden, inte av
# spelaren, och de får inte översättas: `FindFirstChild("Anläggning")`
# måste hitta modellen `Anlaggningen.luau` faktiskt döpte.
OBJEKTNAMN = {"Anläggning", "Dörr"}


def katalognycklar() -> set:
    text = KATALOG.read_text(encoding="utf-8")
    return set(re.findall(r'\["([A-Za-z0-9_.]+)"\] = \{', text))


def main() -> int:
    nycklar = katalognycklar()
    if len(nycklar) < 50:
        print(f"FEL  katalogen har bara {len(nycklar)} nycklar — skannern mäter inget")
        return 1
    fel = []

    # 1. Varje uppslagen nyckel måste finnas.
    for katalog in NYCKELSOK:
        for fil in sorted((ROT / katalog).rglob("*.luau")):
            rel = str(fil.relative_to(ROT))
            kod = avkommentera(fil.read_text(encoding="utf-8"))
            for i, rad in enumerate(kod.splitlines(), 1):
                traffar = (list(NYCKEL_ANROP.finditer(rad)) + list(NYCKEL_ANROP2.finditer(rad))
                           + list(NYCKEL_ANROP3.finditer(rad)) + list(NYCKEL_ATTR.finditer(rad)))
                for m in traffar:
                    if m.group(1) not in nycklar:
                        fel.append(f"{rel}:{i}  okänd språknyckel \"{m.group(1)}\"")

    # 2. Ingen kvarlämnad svensk spelartext i de lokaliserade filerna.
    for rel in LOKALISERADE:
        fil = ROT / rel
        if not fil.exists():
            fel.append(f"{rel} finns inte — listan i kolla-sprak.py är stale")
            continue
        rader = avkommentera(fil.read_text(encoding="utf-8")).splitlines()
        for i, sats in logiska(rader):
            for s in STRANG.findall(sats):
                if not SVENSKT.search(s):
                    continue
                if "warn(" in sats or "print(" in sats:
                    continue
                if s in OBJEKTNAMN:
                    continue
                if "ActionText" in sats or "ObjectText" in sats:
                    #[[ Nyckeln kan stå i SAMMA sats (dörrens växling ligger
                    #   inne i en Triggered-callback) eller på en granne
                    #   (prompten som skapas). Båda räknas. ]]
                    granne = "\n".join(rader[max(0, i - 4):i + 6])
                    if ("SprakNyckel" in sats or "SprakObjekt" in sats
                            or "SprakNyckel" in granne or "SprakObjekt" in granne):
                        continue
                fel.append(f"{rel}:{i}  svensk spelartext utan nyckel: \"{s}\"")

    print(f"  Kontrollerade {len(nycklar)} nycklar och {len(LOKALISERADE)} lokaliserade filer.")
    if fel:
        print("\nSPRÅKGRINDEN FALLER:")
        for f in fel:
            print(f"  FEL  {f}")
        print("\n" + REGLER)
        return 1
    print("  OK   varje nyckel finns, och ingen svensk spelartext står kvar utan nyckel")
    return 0


if __name__ == "__main__":
    sys.exit(main())
