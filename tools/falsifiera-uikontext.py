#!/usr/bin/env python3
"""FALSIFIERING AV PO-ORDERN 2026-09-20 — PRODUCT CLARIFICATION.

Ordern: "Add regression tests that distinguish task relevance from mere
panel visibility. Falsify them by restoring the competing prompt state."

Sju mutationer aterstaller var sin bit av det konkurrerande prompt-laget.
`klient-uikontext.spec` ska bli ROD av allihop:

  M1  Mount-grinden riven ur `init.client`
        -> «Sitt upp» star bredvid «Lossa sadelgjorden» igen (punkt 3)
  M2  `setLedCheck` fragar bara hast-id — laget precis fore ordern
        -> ledknappen konkurrerar med varje skotselsteg (punkt 1)
  M3  `aktuellUppgift` struntar i att repet redan ar i handen
        -> slapp-vagen forsvinner mitt i en ledning (punkt 4)
  M4  `aktuellUppgift` struntar i ledsteget
        -> `leda`-fasen blir onabar, alltsa #162 blockerare 2 (punkt 2)
  M5  regeln blir en REN YTREGEL: fragar panelen i stallet for uppgiften
        -> exakt det `8aba0f3` gjorde, och exakt det ordern forbjuder
  M6  `farVisasLed` lanar uppsittningens svar igen
        -> ledningens synlighet vilar pa Mount-regeln (avsnitt 7)
  M7  `LedSync` harleder hasten ur knapparna igen
        -> serverns ledbesked nar aldrig en klient utan knapp

M5 ar den viktigaste: den ar SKILLNADEN mellan den har leveransen och den
utbackade. Kommer den ut gron mater provet inte det ordern bad om.

M6 var gron i forsta passet — Mount-grinden och den gamla raden stod i
serie, sa den yttre rackte. Avsnitt 7 i specen skrevs for att tvinga isar
dem, och det ar den matningen M6 nu faller pa.

Kallfilerna laggs tillbaka UR MINNET efter varje varv, aldrig genom
`git checkout`. Kor anda inte med ocommittat arbete.

Kor: python3 tools/falsifiera-uikontext.py   (exit 1 vid fynd)
"""
import io
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
SPEC = "tests/klient-uikontext.spec.luau"
BYGGD = "roblox/tests/.build/klient-uikontext.spec.luau"

IC = ROT / "roblox/src/client/InteractionController.luau"
PC = ROT / "roblox/src/client/PreparationController.luau"
INIT = ROT / "roblox/src/client/init.client.luau"

ORIGINAL = {p: io.open(p, encoding="utf-8").read() for p in (IC, PC, INIT)}


def skriv(p, s):
    io.open(p, "w", encoding="utf-8", newline="").write(s)


def kor():
    bygg = subprocess.run([sys.executable, "roblox/tests/build.py", SPEC],
                          cwd=ROT, capture_output=True, text=True)
    if bygg.returncode != 0:
        return "BYGGFEL", [(bygg.stdout + bygg.stderr).strip()[-300:]]
    r = subprocess.run(["luau", BYGGD], cwd=ROT, capture_output=True, text=True)
    ut = r.stdout + r.stderr
    rader = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL")]
    return ("ROD" if r.returncode != 0 else "GRON"), rader


MUTATIONER = [
    ("M1 Mount-grinden riven ur init.client", INIT,
     "\tif PreparationController.skotselstegAgerFokus() then return false end\n"
     "\treturn PreparationController.redo()",
     "\treturn PreparationController.redo()"),

    ("M2 setLedCheck fragar bara hast-id (laget fore ordern)", INIT,
     '\tif model:GetAttribute("HorseId") ~= id then return false end\n'
     "\treturn not PreparationController.skotselstegAgerFokus()",
     '\treturn model:GetAttribute("HorseId") == id'),

    ("M3 aktuellUppgift struntar i att repet ar i handen", PC,
     '\tif leder then return "leda" end\n'
     '\tif PreparationController.nastaFas() == "leda" then return "leda" end',
     '\tif PreparationController.nastaFas() == "leda" then return "leda" end'),

    ("M4 aktuellUppgift struntar i ledsteget", PC,
     '\tif leder then return "leda" end\n'
     '\tif PreparationController.nastaFas() == "leda" then return "leda" end',
     '\tif leder then return "leda" end'),

    ("M5 ren ytregel: fraga panelen i stallet for uppgiften", PC,
     "function PreparationController.skotselstegAgerFokus(): boolean\n"
     '\treturn PreparationController.aktuellUppgift() == "skotsel"\nend',
     "function PreparationController.skotselstegAgerFokus(): boolean\n"
     "\treturn PreparationController.skotselstegVantar()\nend"),

    ("M6 farVisasLed lanar uppsittningens svar igen", IC,
     "local function farVisasLed(model: Model): boolean\n"
     "\tif InteractionController.g01Lage() ~= true then\n"
     "\t\t--[[ nil → göm (fail closed), false → legacy utan G01-loopen. ]]\n"
     "\t\treturn farVisas(model)\n\tend\n"
     "\treturn ledFor ~= nil and ledFor(model)\nend",
     "local function farVisasLed(model: Model): boolean\n"
     "\tif farVisas(model) then return true end\n"
     "\tif InteractionController.g01Lage() ~= true then return false end\n"
     "\treturn ledFor ~= nil and ledFor(model)\nend"),

    ("M7 LedSync harleder hasten ur knapparna igen", IC,
     "\t\tlocal min: Model? = nil\n"
     '\t\tif leder and type(hastId) == "string" then\n'
     '\t\t\tfor _, model in CollectionService:GetTagged("Horse") do\n'
     '\t\t\t\tif model:IsA("Model")\n'
     '\t\t\t\tand model:GetAttribute("HorseId") == hastId then\n'
     "\t\t\t\t\tmin = model :: Model\n\t\t\t\t\tbreak\n\t\t\t\tend\n"
     "\t\t\tend\n\t\tend",
     "\t\tlocal min: Model? = nil\n"
     "\t\tfor model in pairs(ledKnappar) do\n"
     '\t\t\tif leder and model:GetAttribute("HorseId") == hastId then\n'
     "\t\t\t\tmin = model\n\t\t\tend\n\t\tend"),
]


def main():
    print("\nFALSIFIERING: klient-uikontext.spec mot PO-ordern 2026-09-20\n")
    fynd = 0
    for namn, fil, gammal, ny in MUTATIONER:
        s = ORIGINAL[fil]
        if gammal not in s:
            print("  ??    %s" % namn)
            print("          monstret finns inte i kallan — mutationen kordes ALDRIG")
            fynd += 1
            continue
        skriv(fil, s.replace(gammal, ny, 1))
        try:
            lage, rader = kor()
        finally:
            skriv(fil, s)
        if lage == "ROD":
            print("  ROD   %s" % namn)
            for r in rader:
                print("          %s" % r)
        else:
            fynd += 1
            print("  %-5s %s" % (lage, namn))
            print("          PROVET MATER INTE DEN HAR REGELN")
            for r in rader:
                print("          %s" % r)

    for p, s in ORIGINAL.items():
        skriv(p, s)

    print("")
    if fynd:
        print("%d mutation(er) kom inte ut rod." % fynd)
        return 1
    print("Alla %d mutationer foll provet." % len(MUTATIONER))
    return 0


if __name__ == "__main__":
    sys.exit(main())
