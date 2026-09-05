#!/usr/bin/env python3
"""Fogar ihop en körbar testfil av stubbar + produktionskod.

luau-CLI:t sandboxar varje modul: globaler som sätts i en fil syns inte i en
require:ad fil. Roblox-stubbarna måste alltså ligga i samma miljö som koden de
stubbar. Lösningen är densamma som tools/build.py använder för JS-spåret —
foga ihop till en fil — med skillnaden att produktionskoden inlinas ORDAGRANT.
Varje modul blir en `local X = (function() ... end)()` och dess require-rader
byts mot namnen på de moduler som redan laddats.

Kör: python3 roblox/tests/build.py && luau roblox/tests/.build/movement.luau
"""
import re, sys, pathlib

ROT = pathlib.Path(__file__).resolve().parent.parent      # roblox/
UT = ROT / "tests" / ".build"

# Ordningen är beroendeordningen: en modul får bara referera det som står över.
#
# Geometrispecen mäter en annan del av spåret — anläggningen, inte hästen — och
# behöver därför inte hästsystemets moduler. Den får sin egen lista; att foga
# ihop hela hästsystemet för att kontrollera var en dörr sitter vore bara
# långsamt och skulle koppla ihop två spår som inte har med varandra att göra.
GEOMETRI = [
    ("Geometri",    "buildings/Geometri.luau"),
    ("UBRFKomplex", "buildings/UBRFKomplex.luau"),
]

# Byggbänken kör själva byggskriptet. Anlaggningen.luau är inte en modul utan
# ett skript som körs för sin verkan, så det inlinas sist och returnerar inget.
BYGGE = GEOMETRI + [
    ("BuildKit",     "buildings/BuildKit.luau"),
    ("Anlaggningen", "buildings/Anlaggningen.luau"),
]

# Speldatan: hästdata och skötseldata genereras var för sig. UBRFSpel är den
# tunna runtime-fasaden som fogar ihop dem innan Stallet läser kontraktet.
SPEL = GEOMETRI + [
    # RidKanon ar ren data utan beroenden och ligger med sa att
    # spelkanon.spec kan korsprova hastarnas `profil` mot de profiler som
    # faktiskt finns (G02-B punkt 3). Ett profilnamn i hastdatan som inte
    # finns i kanonen ar en tyst degradering till utgangslaget.
    ("RidKanon",     "src/shared/HorseCore/RidKanon.luau"),
    ("UBRFSpelData", "game/UBRFSpelData.luau"),
    ("UBRFSkotsel",  "game/UBRFSkotsel.luau"),
    ("UBRFSpel",     "game/UBRFSpel.luau"),
    ("Stallet",      "game/Stallet.luau"),
]

# QA-panelen provas ovanpa hela bygget: den behover en fardigbyggd anlaggning
# att stalla kameran mot, och Vyer for att veta vilka vyerna ar.
QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# Siktgrinden (issue #78) provar de fasta reviewkamerorna i Vyer mot det
# byggda och behover klientens Genomsikt-regel for att veta vad som tonas.
SIKT = QA + [
    ("Genomsikt", "src/client/Genomsikt.luau"),
]

# Forberedelsen provas ovanpa speldatan: reglerna laser fasordningen ur den
# exporterade skotseln, och reservationen ligger i Stallet. Hastsystemets
# rorelsemoduler behovs inte -- Preparation ror dem inte.
# HorseService ar med for att uppsittningsgrindens INKOPPLING ska ga att prova,
# inte bara dess regel: specen registrerar en grind och kor riktiga tryMount.
# Config/Gaits/RigAdapter maste ligga fore, de fylls in i __Core i den ordningen.
FORBEREDELSE = SPEL + [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    ("Networking",   "src/shared/HorseCore/Networking.luau"),
    ("HorseService", "src/server/HorseService.luau"),
    ("StallService", "src/server/StallService.luau"),
    # Klientsidan: prompt-beslutet (krav 8) provas har, inte i en lokal funktion.
    ("InteractionController", "src/client/InteractionController.luau"),
    ("PreparationController", "src/client/PreparationController.luau"),
    # GameplayService laddas SIST och ar poangen med hela listan: utan den
    # bevisade specen bara att HorseService-kroken fungerar, inte att
    # produktionen faktiskt registrerar GameplayService.farSittaUpp i den.
    ("GameplayService", "src/server/GameplayService.luau"),
]

# Paritetsspecen jamfor Roblox gangarter och telemetri mot webbens
# exporterade ridkanon. Den behover ingen rorelsemodul: den mater kontrakt,
# inte fysik.
PARITET = [
    ("Types",      "src/shared/HorseCore/Types.luau"),
    ("Config",     "src/shared/HorseCore/Config.luau"),
    ("Gaits",      "src/shared/HorseCore/Gaits.luau"),
    ("RidKanon",   "src/shared/HorseCore/RidKanon.luau"),
    ("Telemetri",  "src/shared/HorseCore/Telemetri.luau"),
]

MODULER = [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    # RidKanon och Telemetri ligger fore MovementController: movement.spec
    # provar att en RIKTIG controller-frame producerar underlaget till
    # telemetrin (G02-A, senior review blocker B).
    ("RidKanon",     "src/shared/HorseCore/RidKanon.luau"),
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    ("AnimationController", "src/client/AnimationController.luau"),
    ("CameraController",   "src/client/CameraController.luau"),
    ("RiderController",    "src/client/RiderController.luau"),
    ("Input",              "src/client/Input.luau"),
    ("TouchControls",      "src/client/TouchControls.luau"),
    ("Genomsikt",          "src/client/Genomsikt.luau"),
]

# require-formerna som förekommer i koden, till modulnamn.
# HorseCore star kvar sarskilt: utan barn blir det __Core, tabellen stubbfilen
# bygger. Sista alternativet tar de ovriga ReplicatedStorage-modulerna
# (UBRFSpelData, UBRFSkotsel, UBRFSpel, Stallet, UBRFKomplex).
# Lokalnamnet for ReplicatedStorage varierar i repot: `RS` i vissa filer,
# `ReplicatedStorage` i andra (StallService, GameplayService). Bada maste
# kannas igen -- annars lamnas require:t orort och luau far en nil-sokvag.
REQUIRE = re.compile(
    r'require\(\s*(?:script\.Parent\.(\w+)'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS|ReplicatedStorage)\.HorseCore(?:\.(\w+))?'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS|ReplicatedStorage)\.(\w+))\s*\)')

MATERIALLISTA = ROT / "tests" / "roblox-material.txt"


def material() -> list:
    """De Enum.Material-namn UBRF far anvanda, ur EN fil.

    Stubbarnas Enum.Material svarade forr pa vilket namn som helst, sa
    Enum.Material.CorrugatedMetal passerade hela sviten och sprack forst i
    Studio. Listan injiceras nu i stubbarna i stallet for att skrivas av."""
    rader = MATERIALLISTA.read_text(encoding="utf-8").splitlines()
    return [r.strip() for r in rader if r.strip() and not r.startswith("#")]


def las(rel: str) -> str:
    return (ROT / rel).read_text(encoding="utf-8")
def inlina(kalla: str) -> str:
    """Byter require-anrop mot modulnamn. HorseCore utan barn blir __Core,
    tabellen som stubbfilen bygger av de redan laddade modulerna."""
    def byt(m):
        if m.group(1): return m.group(1)
        if m.group(2): return m.group(2)
        if m.group(3): return m.group(3)
        return "__Core"
    return REQUIRE.sub(byt, kalla)

def bygg(spec_rel: str) -> pathlib.Path:
    # Ordningen ar viktig: "forberedelse" far inte falla igenom till MODULER,
    # dar varken UBRFSkotsel eller Stallet finns. Testas forst av det skalet.
    if "paritet" in spec_rel:
        moduler, stubbar = PARITET, "tests/stubs.luau"
    elif "forberedelse" in spec_rel:
        moduler, stubbar = FORBEREDELSE, "tests/stubs.luau"
    elif "spel" in spec_rel:
        moduler, stubbar = SPEL, "tests/stubs.luau"
    elif pathlib.Path(spec_rel).name == "sikt.spec.luau":
        moduler, stubbar = SIKT, "tests/stubs-bygge.luau"
    elif "qa" in spec_rel:
        moduler, stubbar = QA, "tests/stubs-bygge.luau"
    elif "bygge" in spec_rel:
        moduler, stubbar = BYGGE, "tests/stubs-bygge.luau"
    elif "geometri" in spec_rel:
        moduler, stubbar = GEOMETRI, "tests/stubs.luau"
    else:
        moduler, stubbar = MODULER, "tests/stubs.luau"
    stubbtext = las(stubbar).replace(
        "local __MATERIAL = {}",
        "local __MATERIAL = { " + ", ".join(f'"{m}"' for m in material()) + " }",
        1)
    delar = [stubbtext]
    for namn, rel in moduler:
        kropp = inlina(las(rel))
        delar.append(f"--[[ ══ {rel} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")
        if namn in ("Config", "Gaits", "StateMachine", "RigAdapter", "Networking"):
            delar.append(f"__Core.{namn} = {namn}\n")
    delar.append(f"--[[ ══ {spec_rel} ══ ]]\n{las(spec_rel)}\n")
    UT.mkdir(parents=True, exist_ok=True)
    mal = UT / (pathlib.Path(spec_rel).stem + ".luau")
    mal.write_text("\n".join(delar), encoding="utf-8")
    return mal

if __name__ == "__main__":
    specar = sys.argv[1:] or ["tests/movement.spec.luau"]
    for s in specar:
        p = bygg(s)
        print(f"{p.relative_to(ROT.parent)}: {len(p.read_text())} tecken")
