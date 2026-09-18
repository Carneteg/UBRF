#!/usr/bin/env python3
"""GRIND 1 OCH 5 I KONTRAKTET FOR COACH BANNER (#244, 2026-09-18).

    "Gamla nederpanelen skapas eller visas inte langre i aktiv lektion."
    "Den befintliga nederpanelen ska tas bort ur den aktiva runtime-vagen,
     inte bara doljas bakom den nya."

Precis som reglagepanelen (se `kolla-reglagepanel.py`) gar det INTE att
mata i en Luau-bank. Banken ser bara det som kompilerats in, och ett kort
bakom `Visible = false` kompilerar lika fint som ett rivet.
`coachbanner.spec.luau` matar att panelen inte BYGGS; den har grinden
laser filerna pa disk och matar att den inte FINNS.

Grinden faller pa fyra saker:

  1. PANELENS IDENTIFIERARE i UgnetaController — ramen, avsandarraden,
     rubrikraden, punktraderna och deras utlaggning.
  2. `task.` i CoachBanner. Kontraktets krav 5 handlar om gamla
     `task.delay`-callbacks som kommer tillbaka och slacker ny text.
     Modulen bevakar inte det — den gor det OMOJLIGT genom att inte ha
     nagon fordrojd tradd alls; visningstiden raknas i klientens enda
     loop. Den har raden ar vad som haller det sant.
  3. EXEMPELANROP. `CoachBanner.Show` far bara ropas fran lektionens egen
     vag. En demonstrationsreplik nagon annanstans vore en andra sanning
     om vad Ugneta sager, och kontraktet forbjuder den uttryckligen.
  4. DEN DODA SPRAKNYCKELN `ugneta.rubrik` — avsandarradens text. En
     nyckel utan etikett drar med sig en oversattning att underhalla.

Kor: python3 tools/kolla-nederpanel.py   (exit 1 vid fynd)
"""
import importlib
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

#[[ Kommentarmaskningen ligger i systergrinden och ar inte trivial — den
#   maste bevara radnummer och hantera bade block- och radkommentarer. Att
#   skriva av den hit hade gett tva sanningar om vad "kod" ar, och den ena
#   hade slutat folja med. Importen ar darfor med flit. ]]
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
utan_kommentarer = importlib.import_module("kolla-reglagepanel").utan_kommentarer

LARARFIL = "roblox/src/client/UgnetaController.luau"
BANNERFIL = "roblox/src/client/CoachBanner.luau"

#[[ Varje post: (monster, vad det var, varfor det inte far finnas).
#   Monstren traffar KOD, inte prosa — kommentarerna som FORKLARAR
#   rivningen ar maskade bort innan sokningen, och de kommentarerna ar
#   halva vardet av arbetet. ]]
PANELEN = [
    (re.compile(r'\.Name\s*=\s*"Kort"'),
     'ramen "Kort"',
     "den bottenankrade dialogrutan; texten bor i CoachBanner"),
    (re.compile(r'\.Name\s*=\s*"Avsandare"'),
     'avsandarraden "Avsandare"',
     "RPG-raden UGNETA · RIDINSTRUKTOR ovanfor rubriken"),
    (re.compile(r'\.Name\s*=\s*"Rubrik"'),
     'rubrikraden "Rubrik"',
     "panelens egen rubrik; malet star i bannerns GoalLabel"),
    (re.compile(r'\.Name\s*=\s*"Punkt"\s*\.\.|\.Name\s*=\s*"Punkt\d'),
     'punktraderna "Punkt1..n"',
     "observationerna star i bannerns InstructionLabel"),
    (re.compile(r"\bkortPunkter\b"),
     "listan kortPunkter",
     "den fanns bara for att fylla panelens punktrader"),
    (re.compile(r"\bkortRubrik\b"),
     "kortRubrik",
     "referensen till panelens rubrikrad"),
    (re.compile(r"\blaggUtKort\b|\bvisaKort\b|\b_laggUtKort\b"),
     "panelens egna funktioner (laggUtKort/visaKort)",
     "utlaggningen foljde med till knappraden och heter laggUtVal"),
]

#[[ Bannerns forbud. `task.` racker som monster: modulen ska inte ha
#   vare sig delay, spawn, wait eller defer. ]]
BANNERN = [
    (re.compile(r"\btask\s*\."),
     "en task-anrop i CoachBanner",
     "visningstiden raknas i klientens enda loop, se modulens huvud"),
    (re.compile(r"\bdelay\s*\("),
     "det gamla globala delay()",
     "samma skal som task.delay ovan"),
]

#[[ Vem som far ropa `Show`. Lektionens egen vag, och ingen annan —
#   plus modulen sjalv, som DEFINIERAR funktionen. Utan undantaget foll
#   grinden pa raden `function CoachBanner.Show(...)`, alltsa pa att
#   funktionen existerar. ]]
TILLATNA_ANROPARE = {LARARFIL, BANNERFIL}

DODA_NYCKLAR = ["ugneta.rubrik"]
KATALOGER = ["src/spel/sprak.js", "roblox/game/UBRFSprak.luau"]


def las(rel: str):
    fil = ROT / rel
    if not fil.exists():
        return None
    return utan_kommentarer(fil.read_text(encoding="utf-8"))


def fynd_i(rel: str, regler) -> list:
    text = las(rel)
    if text is None:
        return [f"{rel}: filen saknas — listan i grinden ar inaktuell"]
    ut = []
    for monster, vad, varfor in regler:
        traff = monster.search(text)
        if traff:
            rad = text[: traff.start()].count("\n") + 1
            ut.append(f"{rel}:{rad}: {vad} ar tillbaka — {varfor}")
    return ut


def main() -> int:
    fynd = []
    fynd += fynd_i(LARARFIL, PANELEN)
    fynd += fynd_i(BANNERFIL, BANNERN)

    #[[ EXEMPELANROP. Svepet gar over hela klient- och serverkallan, inte
    #   bara over de tva filerna ovan: en demonstrationsreplik som laggs
    #   i en TREDJE modul ar precis det fallet kravet handlar om. ]]
    anrop = re.compile(r"\bCoachBanner\s*\.\s*Show\s*\(")
    for fil in sorted((ROT / "roblox/src").rglob("*.luau")):
        rel = fil.relative_to(ROT).as_posix()
        if rel in TILLATNA_ANROPARE:
            continue
        text = utan_kommentarer(fil.read_text(encoding="utf-8"))
        traff = anrop.search(text)
        if traff:
            rad = text[: traff.start()].count("\n") + 1
            fynd.append(
                f"{rel}:{rad}: CoachBanner.Show ropas utanfor lektionens vag — "
                "bannern ska bara bara lektionens egen pedagogiska text"
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
                    "raden den etiketterar ritas inte"
                )

    if fynd:
        print("NEDERPANELEN AR INTE HELT RIVEN:")
        for f in fynd:
            print("  " + f)
        return 1

    print(
        f"  OK   nederpanelen ar riven ur kallan "
        f"({len(PANELEN)} identifierare, {len(BANNERN)} bannerforbud, "
        f"{len(DODA_NYCKLAR)} dod nyckel)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
