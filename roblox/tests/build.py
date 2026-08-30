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

# QA-panelen provas ovanpa hela bygget: den behover en fardigbyggd anlaggning
# att stalla kameran mot, och Vyer for att veta vilka vyerna ar.
QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

MODULER = [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    ("CameraController",   "src/client/CameraController.luau"),
    ("RiderController",    "src/client/RiderController.luau"),
    ("Input",              "src/client/Input.luau"),
    ("TouchControls",      "src/client/TouchControls.luau"),
]

# require-formerna som förekommer i koden, till modulnamn.
REQUIRE = re.compile(
    r'require\(\s*(?:script\.Parent\.(\w+)'
    r'|game:GetService\("ReplicatedStorage"\)\.HorseCore(?:\.(\w+))?)\s*\)')

def las(rel: str) -> str:
    return (ROT / rel).read_text(encoding="utf-8")

def inlina(kalla: str) -> str:
    """Byter require-anrop mot modulnamn. HorseCore utan barn blir __Core,
    tabellen som stubbfilen bygger av de redan laddade modulerna."""
    def byt(m):
        return m.group(1) or m.group(2) or "__Core"
    return REQUIRE.sub(byt, kalla)

def bygg(spec_rel: str) -> pathlib.Path:
    if "qa" in spec_rel:
        moduler, stubbar = QA, "tests/stubs-bygge.luau"
    elif "bygge" in spec_rel:
        moduler, stubbar = BYGGE, "tests/stubs-bygge.luau"
    elif "geometri" in spec_rel:
        moduler, stubbar = GEOMETRI, "tests/stubs.luau"
    else:
        moduler, stubbar = MODULER, "tests/stubs.luau"
    delar = [las(stubbar)]
    for namn, rel in moduler:
        kropp = inlina(las(rel))
        delar.append(f"--[[ ══ {rel} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")
        if namn in ("Config", "Gaits", "StateMachine", "RigAdapter"):
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
