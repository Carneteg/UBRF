#!/usr/bin/env python3
"""Fogar ihop körbara Luau-specar av stubbar + produktionskod.

Produktionskoden inlinas ordagrant; require-anrop byts mot moduler som redan
ligger i samma luau-CLI-miljö. Materialallowlisten injiceras fortfarande i de
Roblox-stubbar som bygger värld/rigg — G01-utbyggnaden får inte försvaga den
spärr som fångar Studio-ogiltiga Enum.Material.
"""
import re, sys, pathlib

ROT = pathlib.Path(__file__).resolve().parent.parent
UT = ROT / "tests" / ".build"

GEOMETRI = [
    ("Geometri",    "buildings/Geometri.luau"),
    ("UBRFKomplex", "buildings/UBRFKomplex.luau"),
]

BYGGE = GEOMETRI + [
    ("BuildKit",     "buildings/BuildKit.luau"),
    ("Anlaggningen", "buildings/Anlaggningen.luau"),
]

SPEL = GEOMETRI + [
    ("UBRFSpel", "game/UBRFSpel.luau"),
    ("Stallet",  "game/Stallet.luau"),
]

QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# GameplayService använder riktiga Preparation-regler, men HorseService,
# StallService, nät och RigAdapter är kontrollerade attrapper i stubben. Då kan
# specen bevisa exakt vilken spärr som nekar i stället för att få grönt av en
# annan tjänsts råkade beteende.
GAMEPLAY = [
    ("Preparation",     "src/shared/HorseCore/Preparation.luau"),
    ("GameplayService", "src/server/GameplayService.luau"),
]
HUD = [("GameplayController", "src/client/GameplayController.luau")]
INTERAKTION = [("InteractionController", "src/client/InteractionController.luau")]

MODULER = [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    ("CameraController",   "src/client/CameraController.luau"),
    ("RiderController",    "src/client/RiderController.luau"),
    ("Input",              "src/client/Input.luau"),
    ("TouchControls",      "src/client/TouchControls.luau"),
]

# script.Parent.X, HorseCore via direkt GetService/lokal alias/RS, och övriga
# ReplicatedStorage-moduler som heter samma sak i testmiljön.
REQUIRE = re.compile(
    r'require\(\s*(?:script\.Parent\.(\w+)'
    r'|(?:game:GetService\("ReplicatedStorage"\)|ReplicatedStorage|RS)'
    r'\.HorseCore(?:\.(\w+))?'
    r'|(?:game:GetService\("ReplicatedStorage"\)|ReplicatedStorage|RS)\.(\w+))\s*\)')

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
    if "hud" in spec_rel:
        moduler, stubbar = HUD, "tests/stubs-gameplay.luau"
    elif "interaktion" in spec_rel:
        moduler, stubbar = INTERAKTION, "tests/stubs-gameplay.luau"
    elif "gameplay" in spec_rel:
        moduler, stubbar = GAMEPLAY, "tests/stubs-gameplay.luau"
    elif "spel" in spec_rel:
        moduler, stubbar = SPEL, "tests/stubs.luau"
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
        "local __MATERIAL = { " + ", ".join(f'\"{m}\"' for m in material()) + " }",
        1)
    delar = [stubbtext]
    for namn, rel in moduler:
        kropp = inlina(las(rel))
        delar.append(f"--[[ ══ {rel} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")
        if namn in ("Config", "Gaits", "StateMachine", "RigAdapter", "Preparation"):
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
