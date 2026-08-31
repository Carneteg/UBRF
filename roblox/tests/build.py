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

GEOMETRI = [
    ("Geometri",    "buildings/Geometri.luau"),
    ("UBRFKomplex", "buildings/UBRFKomplex.luau"),
]

# Spelbar-värld-specen provar den rena segmenteringen + spawnregeln.
# Varldsspecen BYGGER numera ocksa. Den las forst bara geometrin, och kunde
# darfor inte se var spawnen faktiskt HAMNADE — bara vad uttrycket raknade ut.
# Dorrspecen kor WorldService mot en bank dar tween:en gar att halla pagaende.
DORRAR = [
    ("WorldService", "src/server/WorldService.luau"),
]

WORLD = GEOMETRI + [
    ("BuildKit",      "buildings/BuildKit.luau"),
    ("WorldGeometry", "buildings/WorldGeometry.luau"),
    ("WorldBuild",    "buildings/WorldBuild.luau"),
    ("Anlaggningen",  "buildings/Anlaggningen.luau"),
]

# Byggbänken kör själva byggskriptet. Anlaggningen.luau är inte en modul utan
# ett skript som körs för sin verkan, så det inlinas sist och returnerar inget.
BYGGE = GEOMETRI + [
    ("BuildKit",     "buildings/BuildKit.luau"),
    ("Anlaggningen", "buildings/Anlaggningen.luau"),
]

# Speldatan: stallet behöver både hästarna och den mätta stallgeometrin.
SPEL = GEOMETRI + [
    ("UBRFSpel", "game/UBRFSpel.luau"),
    ("Stallet",  "game/Stallet.luau"),
]

QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# F02:s granskningslage bygger pa QA-uppsattningen plus modulen sjalv.
GRANSKNING = QA + [
    ("Granskning", "buildings/Granskning.luau"),
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

REQUIRE = re.compile(
    r'require\(\s*(?:script\.Parent\.(\w+)'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS)\.HorseCore(?:\.(\w+))?'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS)\.(\w+))\s*\)')

MATERIALLISTA = ROT / "tests" / "roblox-material.txt"


def material() -> list:
    rader = MATERIALLISTA.read_text(encoding="utf-8").splitlines()
    return [r.strip() for r in rader if r.strip() and not r.startswith("#")]


def las(rel: str) -> str:
    return (ROT / rel).read_text(encoding="utf-8")


def inlina(kalla: str) -> str:
    def byt(m):
        if m.group(1): return m.group(1)
        if m.group(2): return m.group(2)
        if m.group(3): return m.group(3)
        return "__Core"
    return REQUIRE.sub(byt, kalla)


def bygg(spec_rel: str) -> pathlib.Path:
    if "dorrar" in spec_rel:
        moduler, stubbar = DORRAR, "tests/stubs-world.luau"
    elif "world" in spec_rel:
        moduler, stubbar = WORLD, "tests/stubs-bygge.luau"
    elif "spel" in spec_rel:
        moduler, stubbar = SPEL, "tests/stubs.luau"
    elif "granskning" in spec_rel:
        moduler, stubbar = GRANSKNING, "tests/stubs-bygge.luau"
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
