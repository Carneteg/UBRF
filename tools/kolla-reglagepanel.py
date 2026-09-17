#!/usr/bin/env python3
"""GRIND 4 I KONTRAKTET FOR KONTEXTUELL RID-UX (arkitekturbeslut 2026-09-17).

    "All kod och UI som rorde den gamla panelen (10 knappar) ar fullstandigt
     bortrensad fran kallkoden (inte bara dold via Visible = false)."

Det gar inte att mata i en Luau-bank. Banken ser bara det som kompilerats
in, och en panel bakom `if false` eller `Visible = false` kompilerar precis
lika fint som en som ar borta. `driv-broms.spec.luau` matar att den inte
RITAS; den har grinden laser filerna pa disk och matar att den inte FINNS.

Det ar inte overflod. Precis den skillnaden var hela QA-fyndet: panelen var
slackt med `MINIMAL_UI = true` i tva veckor, sviten var gron hela tiden, och
koden lag kvar. En slackt panel ar en panel som kan tandas av misstag.

Grinden faller pa tre saker:

  1. PANELENS IDENTIFIERARE i klientkallan — ramnamnen, knappnamnen,
     byggfunktionen och det gamla pek-API:t.
  2. `MINIMAL_UI` i `TouchControls` — slackningen var provisorisk och ska
     inte finnas kvar nar panelen ar riven. (Ovriga moduler far ha kvar
     sin; de slacker annan UI efter ett eget produktbeslut.)
  3. SPRAKNYCKLAR till knappar som inte ritas. En nyckel utan knapp ar en
     etikett ingen kan se, och den drar med sig en oversattning att
     underhalla.

Kor: python3 tools/kolla-reglagepanel.py   (exit 1 vid fynd)
"""
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

# Filerna som ritar ridningens UI. Listan ar avsiktligt SMAL: grinden ska
# saga ifran om panelen kommer tillbaka dit den satt, inte forbjuda orden
# i hela repot. En framtida klientfil som ritar reglage hor hemma har.
KALLOR = [
    "roblox/src/client/TouchControls.luau",
    "roblox/src/client/Input.luau",
    "roblox/src/client/MovementController.luau",
    "roblox/src/client/KontrollHjalp.luau",
    "roblox/src/client/init.client.luau",
]

#[[ Varje post: (monster, vad det var, varfor det inte far finnas).
#   Monstren traffar KOD, inte prosa: de kraver den syntax identifieraren
#   faktiskt har. Utan det kravet hade varje kommentar som FORKLARAR
#   rivningen fallt grinden — och de kommentarerna ar det som gor rivningen
#   begriplig for nasta lasare. ]]
FORBJUDET = [
    (re.compile(r'nyRam\s*\(\s*"Gangarter"'),
     'ramen "Gangarter"',
     "gangartsgallret med HALT/SKRITT/TRAV/GALOPP/SAKTA"),
    (re.compile(r'nyRam\s*\(\s*"Knappar"'),
     'ramen "Knappar"',
     "hjalpargallret med TYGEL/SITS/HALVHALT/HOPPA/SITT AV"),
    (re.compile(r"^\s*local function nyKnapp\b", re.M),
     "byggfunktionen nyKnapp",
     "den byggde panelens tio TextButton i var egen ScreenGui"),
    (re.compile(r"\bfunction Input\.touchGaitTo\b"),
     "Input.touchGaitTo",
     "pekytans namngivna gangartsknappar; trappan stegas av DRIV/BROMS"),
    (re.compile(r"\bfunction Input\.touchGait\b"),
     "Input.touchGait",
     "ospārrad vag in i trappan vid sidan av handlingarna"),
    (re.compile(r"\bintent\.gaitTo\b|\bgaitTo\s*="),
     "avsikten gaitTo",
     "en begaran om en PLATS i trappan i stallet for ett steg"),
    (re.compile(r"\bself\.haltLas\b"),
     "halt-laset",
     "fanns bara for att framatutslaget upphavde den namngivna halten"),
    (re.compile(r'\bInstance\.new\s*\(\s*"TextButton"'),
     "en egen TextButton",
     "kontraktets absoluta forbud for ridningens reglage"),
]

#[[ `KontrollHjalp` ritar hjalppanelen och dess `?`-knapp med en egen
#   TextButton. Den ar INTE ett ridreglage och omfattas inte av forbudet;
#   den star kvar efter produktbeslutet om ren skarm och slacks med sin
#   egen MINIMAL_UI. Undantaget ar uttryckligt och per fil, inte ett
#   monster som hade slappt igenom nasta panel. ]]
UNDANTAG = {
    "roblox/src/client/KontrollHjalp.luau": {"en egen TextButton"},
}

# Spraknycklar som bara panelen anvande. De ska vara borta ur katalogen.
DODA_NYCKLAR = [
    "touch.halt", "touch.skritt", "touch.trav", "touch.galopp",
    "touch.sakta", "touch.gangartsknappar",
    "touch.hoppa", "touch.tygel", "touch.halvhalt", "touch.djup_sits",
]
KATALOGER = ["src/spel/sprak.js", "roblox/game/UBRFSprak.luau"]


#[[ ══ KOMMENTARERNA MASKAS BORT FORE SOKNINGEN ═══════════════════════
#
#   Forsta korningen foll pa sig sjalv: `intent.gaitTo` och `MINIMAL_UI`
#   fanns kvar i de kommentarer som FORKLARAR varfor de ar borta, och
#   grinden laste dem som att koden var tillbaka.
#
#   Att skriva om kommentarerna hade varit fel vag. En rivning som ingen
#   kan lasa efterat ar en rivning nasta lasare aterstaller av misstag; de
#   noterna ar halva varde av arbetet. Det ar GRINDEN som ska lasa kod.
#
#   Maskningen ersatter varje kommentartecken med ett mellanslag och later
#   radbrytningarna sta kvar, sa att radnumren i fyndet fortfarande pekar
#   pa ratt rad i originalfilen.
#
#   BEGRANSNING, uttryckligen: en strang som INNEHALLER "--" maskas fran
#   den punkten till radslutet. I de fem klientfilerna finns ingen sadan
#   strang, och konsekvensen vore falskt GRONT pa just den raden — aldrig
#   falskt rott. En fullstandig Luau-lexer vore fel verktyg for en grind
#   pa femton rader. ]]
BLOCKKOMMENTAR = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)
RADKOMMENTAR = re.compile(r"--[^\n]*")


def utan_kommentarer(text: str) -> str:
    def maska(traff) -> str:
        #[[ Behall radbrytningarna: radnumret i fyndet ska stamma. ]]
        return "".join("\n" if t == "\n" else " "
                       for t in traff.group(0))

    text = BLOCKKOMMENTAR.sub(maska, text)
    return RADKOMMENTAR.sub(maska, text)


def main() -> int:
    fynd = []

    for rel in KALLOR:
        fil = ROT / rel
        if not fil.exists():
            fynd.append(f"{rel}: filen saknas — listan i grinden ar inaktuell")
            continue
        text = utan_kommentarer(fil.read_text(encoding="utf-8"))
        undantagna = UNDANTAG.get(rel, set())
        for monster, vad, varfor in FORBJUDET:
            if vad in undantagna:
                continue
            traff = monster.search(text)
            if traff:
                rad = text[: traff.start()].count("\n") + 1
                fynd.append(f"{rel}:{rad}: {vad} ar tillbaka — {varfor}")

    #[[ MINIMAL_UI i TouchControls var slackningen, inte rivningen. ]]
    tc = ROT / "roblox/src/client/TouchControls.luau"
    if tc.exists() and re.search(
        r"\bMINIMAL_UI\b", utan_kommentarer(tc.read_text(encoding="utf-8"))
    ):
        fynd.append(
            "roblox/src/client/TouchControls.luau: MINIMAL_UI finns kvar — "
            "panelen ska vara RIVEN, inte slackt"
        )

    for rel in KATALOGER:
        fil = ROT / rel
        if not fil.exists():
            continue
        text = fil.read_text(encoding="utf-8")
        for nyckel in DODA_NYCKLAR:
            #[[ Nyckeln som DEFINITION, alltsa som katalogpost. Namnet i en
            #   kommentar som forklarar rivningen ar inte ett fynd. ]]
            if re.search(r'["\[]"?' + re.escape(nyckel) + r'"\]?\s*[:=]', text):
                fynd.append(
                    f"{rel}: spraknyckeln {nyckel} finns kvar — "
                    "knappen den etiketterar ritas inte"
                )

    if fynd:
        print("REGLAGEPANELEN AR INTE HELT RIVEN:")
        for f in fynd:
            print("  " + f)
        return 1

    print(
        f"  OK   reglagepanelen ar riven ur kallan "
        f"({len(KALLOR)} klientfiler, {len(DODA_NYCKLAR)} doda nycklar)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
