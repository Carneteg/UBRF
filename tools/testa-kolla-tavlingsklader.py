#!/usr/bin/env python3
"""GRINDEN SJALV PROVAS — I BADA RIKTNINGARNA (#248, senior review av 129bd58).

En grind som bara provas at ena hallet ar halva grinden. Den har kor
`kolla-tavlingsklader.py` mot tva konstruerade fall och kraver ett svar av
varje:

  ROTT   en kopierad asset-ID-literal i en annan produktionsfil,
  GRONT  en LEGITIM konsument som anropar `Tavlingsklader.set(id)` och
         laser postens `shirtAssetId` / `pantsAssetId`.

Den andra riktningen ar den som gav CHANGES_REQUESTED. Forsta utkastet av
grinden foll pa faltnamnen var som helst utanfor katalogen, vilket hade
forbjudit den framtida tavlingsservern att lasa katalogens publika falt.
Fas A hade da gjort Fas B omojlig utan att forst forsvaga sin egen grind.

Provet skapar riktiga filer i repot, kor grinden, och tar bort dem igen i
`finally` — aven om nagot kastar. Ett prov som kan lamna skrap efter sig i
kallan vore varre an inget prov.

Kor: python3 tools/testa-kolla-tavlingsklader.py   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
GRIND = ROT / "tools" / "kolla-tavlingsklader.py"

#[[ Filerna laggs i klientkallan, alltsa dar grinden faktiskt letar, och de
#   bar ett namn ingen kan forvaxla med produktionskod. ]]
KOPIA = ROT / "roblox/src/client/__prov_kopierad_katalog.luau"
KONSUMENT = ROT / "roblox/src/client/__prov_laglig_konsument.luau"

#[[ Ett av de sex talen, skrivet har och inte last ur katalogen: provet ska
#   fanga en grind som slutat leta, inte spegla den. ]]
WHITE_SHIRT = "11268412339"

KOPIERAD_KALLA = """--!strict
-- TILLFALLIG PROVFIL. Skapas och tas bort av
-- tools/testa-kolla-tavlingsklader.py. Ska ALDRIG committas.
local EGEN = {
	white = { shirt = %s, pants = 11268415210 },
}
return EGEN
""" % WHITE_SHIRT

LAGLIG_KALLA = """--!strict
-- TILLFALLIG PROVFIL. Skapas och tas bort av
-- tools/testa-kolla-tavlingsklader.py. Ska ALDRIG committas.
--
-- SA HAR SKA EN KONSUMENT SE UT: den fragar katalogen och laser postens
-- publika falt. Inga egna tal, ingen egen tabell. Det ar precis den kod
-- den framtida tavlingsservern behover kunna skriva.
local Tavlingsklader = require(game:GetService("ReplicatedStorage")
	.HorseCore.Tavlingsklader)

local function klaPa(valtId: string)
	local set = Tavlingsklader.set(valtId)
	if not set then return nil end
	return { shirt = set.shirtAssetId, pants = set.pantsAssetId }
end

return klaPa
"""


def kor_grind() -> int:
    return subprocess.run(
        [sys.executable, str(GRIND)], capture_output=True, text=True
    ).returncode


def main() -> int:
    fel = []
    try:
        #[[ Utgangslaget maste vara gront, annars mater provet ingenting. ]]
        if kor_grind() != 0:
            fel.append("utgangslaget ar inte gront — grinden faller redan utan provfiler")

        # ── RIKTNING 1: en kopierad ID-literal ska ge ROTT ──────────────
        KOPIA.write_text(KOPIERAD_KALLA, encoding="utf-8")
        if kor_grind() == 0:
            fel.append(
                "en kopierad asset-ID-literal i roblox/src/client gav GRONT — "
                "grinden slapper igenom precis det den finns for"
            )
        KOPIA.unlink()

        # ── RIKTNING 2: en laglig konsument ska ge GRONT ────────────────
        KONSUMENT.write_text(LAGLIG_KALLA, encoding="utf-8")
        if kor_grind() != 0:
            fel.append(
                "en konsument som anropar Tavlingsklader.set(id) och laser "
                "shirtAssetId/pantsAssetId gav ROTT — grinden forbjuder sin "
                "egen publika typ, och gor Fas B omojlig"
            )
        KONSUMENT.unlink()
    finally:
        for f in (KOPIA, KONSUMENT):
            if f.exists():
                f.unlink()

    if fel:
        print("GRINDPROVET FOLL:")
        for f in fel:
            print("  " + f)
        return 1
    print("  OK   tavlingskladergrinden faller pa kopierade ID och slapper "
          "igenom lagliga konsumenter")
    return 0


if __name__ == "__main__":
    sys.exit(main())
