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
    #[[ Tjansterna och regelmodulerna bar spelarens NEJ sedan reviewen
    #   18:27. De ar med i listan darfor att mutationen "ett ratt svenskt
    #   servernej" annars bara fangades av en grind (sprak-en.spec) och
    #   inte av den statiska. Tva oberoende grindar pa samma regel ar
    #   inte overflod: den ena kor koden, den andra laser den. ]]
    "roblox/src/server/GameplayService.luau",
    "roblox/src/server/HorseService.luau",
    "roblox/src/shared/HorseCore/Pass.luau",
    "roblox/src/shared/HorseCore/Preparation.luau",
    #[[ Sparningens anmarkning ar ocksa en nyckel nu (#162 punkt 2:
    #   save/reconnect). Ingen yta visar den an, men den dag den gor det
    #   ska den inte vara ett svenskt ord. ]]
    "roblox/src/server/SparService.luau",
    "roblox/src/shared/HorseCore/Sparning.luau",
]

# Alla filer där en nyckel kan slås upp — nyckelkontrollen gäller brett.
NYCKELSOK = ["roblox/src", "roblox/buildings"]

SVENSKT = re.compile(r"[åäöÅÄÖ]")
#[[ åäö räcker inte. "kunde inte spara framstegen" är svensk spelartext utan
#   en enda omljudsbokstav — den mutationen slank igenom skannern (prov
#   19:40) och hittades bara för att jag provade den. Andra detektorn:
#   en sträng med MELLANSLAG som innehåller ett svenskt funktions- eller
#   vardagsord. Mellanslagskravet är det som håller den tyst: alla
#   nycklar (`pass.inte_dags`) och interna id:n (`UBRF_Spelare_v1`)
#   innehåller samma ord men inga mellanslag. Mätt över alla lokaliserade
#   filer gav detektorn noll falska fynd. ]]
SVENSKA_ORD = re.compile(
    r"(?<![A-Za-z])(och|inte|inget|inga|inne|kunde|kan|ska|maste|med|inom|som"
    r"|till|den|det|har|men|utan|redan|klar|klart|klara|hos|nu|sen|sedan"
    r"|bara|hela|vila|spara|sparat|sparar|spelet|spelare|dag|dagen|dagens"
    r"|hast|hasten|hastar|ryttare|ridit|rider)(?![A-Za-z])", re.I)


def misstankt_svenska(s: str) -> bool:
    """Ser strängen ut som svensk spelartext?"""
    return bool(SVENSKT.search(s) or (" " in s and SVENSKA_ORD.search(s)))
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
    · texten i en ~-sträng som bara är ett nyckelnamn (inte spelartext)
    · etikett till en retry-hjälpare (medRetry) vars parameter bevisligen
      bara går ut i warn( — kontrolleras genom att läsa hjälparens kropp"""


def avkommentera(kod: str) -> str:
    """Tar bort kommentarer men BEHÅLLER radbrytningarna.

    Första versionen klippte bort blockkommentarer med allt innehåll,
    radbrytningar inkluderade. Radnumren i felrapporten gled då — de pekade
    på rader i den strippade texten, inte i filen — och ett fynd blev
    omöjligt att hitta. Ett mätverktyg som pekar fel är värre än inget."""
    def tomma(m):
        return "\n" * m.group(0).count("\n")
    kod = re.sub(r"--\[(=*)\[.*?\]\1\]", tomma, kod, flags=re.S)
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

#[[ Etiketten till en retry-hjälpare. `medRetry("läsning av " .. p.Name, fn)`
#   namnger VAD som misslyckades i en warn — utvecklarutskrift, men skriven
#   på anropsraden i stället för inne i warn(, så den generella
#   warn/print-regeln ser den inte.
#
#   Undantaget är inte ett påstående på tro: `etikett_bara_i_warn` läser
#   hjälparens kropp och kräver att parametern bara förekommer på rader med
#   warn(. Skulle någon börja visa den för spelaren faller fyndet igen. ]]
ETIKETTANROP = {"medRetry": "vad"}


def etikett_bara_i_warn(kod: str, funk: str, param: str) -> bool:
    """True om `param` i `funk`s kropp bara förekommer på warn-rader.

    Kroppen läses från `function <funk>(` till nästa `end` i kolumn 0 —
    projektets lokala hjälpare ligger på toppnivå. Hittas ingen sådan
    kropp, eller nämns parametern inte alls, gäller inget undantag."""
    m = re.search(r"^(?:local )?function %s\(" % re.escape(funk), kod, re.M)
    if not m:
        return False
    rader = kod[m.start():].splitlines()
    kropp = []
    for rad in rader[1:]:
        if rad.startswith("end"):
            break
        kropp.append(rad)
    else:
        return False
    sett = False
    for rad in kropp:
        if re.search(r"\b%s\b" % re.escape(param), rad):
            sett = True
            if "warn(" not in rad and "print(" not in rad:
                return False
    return sett


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
        kod_rel = avkommentera(fil.read_text(encoding="utf-8"))
        rader = kod_rel.splitlines()
        for i, sats in logiska(rader):
            for s in STRANG.findall(sats):
                if not misstankt_svenska(s):
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
                if any(re.search(r'%s\(\s*"%s' % (re.escape(f), re.escape(s)), sats)
                       and etikett_bara_i_warn(kod_rel, f, p)
                       for f, p in ETIKETTANROP.items()):
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
