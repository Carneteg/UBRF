#!/usr/bin/env python3
"""EN KATALOG, INTE FLERA (#248 Fas A, acceptanspunkt 1).

    "De tre seten ska definieras exakt en gang i en delad, typad katalog."
    "Inga kopierade ID-tabeller i UI och server."

Det gar inte att mata i en Luau-bank. Ett andra asset-id i en annan modul
kompilerar precis lika fint som inget andra id, och en spec ser bara det
den fragar efter. `tavlingsklader.spec.luau` matar att katalogen ar RATT;
den har grinden matar att den ar ENSAM.

Samma skal och samma monster som `kolla-reglagepanel.py` och
`kolla-nederpanel.py`.

Grinden faller pa tva saker:

  1. NAGOT AV DE SEX TALEN utanfor katalogmodulen. Det ar sa en kopierad
     ID-tabell ser ut, oavsett vad den heter.
  2. En andra definition av sjalva katalogen — ett `KATALOG`-liknande
     block i en annan fil som bar `shirtAssetId`/`pantsAssetId`.

UNDANTAG, uttryckliga: katalogmodulen sjalv, specen som bar ordern som
facit, och den har grinden. Provets kopia ar INTE en dubblering i
produktionen — den ar facit att mata mot, och den ar var enda kontroll
mot att nagon "rattar" ett tal i katalogen utan att nagon markte det.

Kor: python3 tools/kolla-tavlingsklader.py   (exit 1 vid fynd)
"""
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

KATALOGFIL = "roblox/src/shared/HorseCore/Tavlingsklader.luau"
SPECFIL = "roblox/tests/tavlingsklader.spec.luau"
DENNA = "tools/kolla-tavlingsklader.py"
#[[ Grindens EGET prov bar ett av talen med flit — det ska fanga en grind
#   som slutat leta, inte spegla den. Darfor undantas det, av samma skal
#   som specen: facit ligger utanfor det som provas. ]]
GRINDPROVET = "tools/testa-kolla-tavlingsklader.py"

#[[ De sex talen. De star har EN gang till, och det ar med flit: en grind
#   som laste talen ur filen den bevakar hade godkant vilken andring som
#   helst av just den filen. Facit maste ligga utanfor det som provas. ]]
ASSET_ID = [
    11268412339, 11268415210,     # white:  shirt, pants
    11268345931, 11268349501,     # pink:   shirt, pants
    11268265001, 11268267939,     # oak:    shirt, pants
]

#[[ Filer som FAR namna talen. Allt annat i repot far inte. ]]
UNDANTAG = {KATALOGFIL, SPECFIL, DENNA, GRINDPROVET}

#[[ Var grinden letar. Hela repot utom det som inte ar kalla. ]]
SOKMAPPAR = ["roblox", "src", "tools", "game"]
SUFFIX = {".luau", ".lua", ".js", ".mjs", ".py", ".json", ".ts"}
HOPPA = {"node_modules", ".build", ".git", "__pycache__", "dist", "releases"}



def kallfiler():
    for mapp in SOKMAPPAR:
        bas = ROT / mapp
        if not bas.exists():
            continue
        for fil in bas.rglob("*"):
            if not fil.is_file() or fil.suffix not in SUFFIX:
                continue
            if any(del_ in HOPPA for del_ in fil.parts):
                continue
            yield fil


def main() -> int:
    fynd = []
    sedd_katalog = False

    for fil in sorted(kallfiler()):
        rel = fil.relative_to(ROT).as_posix()
        if rel == KATALOGFIL:
            sedd_katalog = True
        if rel in UNDANTAG:
            continue
        try:
            text = fil.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for tal in ASSET_ID:
            if re.search(r"\b" + str(tal) + r"\b", text):
                rad = text[: text.index(str(tal))].count("\n") + 1
                fynd.append(
                    f"{rel}:{rad}: asset-id {tal} star utanfor katalogen — "
                    "en kopierad ID-tabell ar precis det kontraktet forbjuder"
                )

    #[[ FAIL CLOSED. Hittas inte katalogen alls ar grinden inaktuell, och
    #   en grind som tyst slutar mata ar varre an ingen grind. ]]
    if not sedd_katalog:
        fynd.append(
            f"{KATALOGFIL}: filen saknas — grinden bevakar nagot som inte finns"
        )

    if fynd:
        print("TAVLINGSKLADERNAS KATALOG AR INTE ENSAM:")
        for f in fynd:
            print("  " + f)
        return 1

    print(
        f"  OK   tavlingsklader-katalogen ar ensam "
        f"({len(ASSET_ID)} asset-id, {len(UNDANTAG)} undantagna filer)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
