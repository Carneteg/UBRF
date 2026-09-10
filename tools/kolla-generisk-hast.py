#!/usr/bin/env python3
"""EN GENERISK HÄSTSTACK — ingen kod om en enskild UBRF-häst.

Produktkravet i #162: alla kanoniska UBRF-hästar ska vara ridbara, genom
EN datastyrd kedja. Jack får vara särskild på exakt ett ställe — vilken
häst spelaren får sin första dag, `Stallet.FORSTA_DAGEN_HAST` — och inte
någon annanstans.

`roster.spec.luau` mäter att varje häst i rostern går att rida. Den kan
inte se det andra halvan av kravet: att ingen individ har en egen gren i
koden. Ett `if hastId == "blackrock_jack"` kan ligga i en kodväg som
provet aldrig når, och det är precis en sådan gren som gör att häst nummer
34 plötsligt beter sig annorlunda utan att någon grind säger till.

Skannern läser hästarnas id ur den genererade speldatan och letar dem som
STRÄNGLITTERALER i runtimekoden. Kommentarer räknas inte — de FÅR nämna
en häst; det är resonemang, inte beteende.

Kör: python3 tools/kolla-generisk-hast.py   (exit 1 vid fynd)
"""
import pathlib, re, sys

ROT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROT / "roblox/game/UBRFSpelData.luau"
SKANNADE = ["roblox/src", "roblox/buildings"]

# TILLÅTNA UNDANTAG, med skäl. Ett undantag utan skäl är en tystad grind.
UNDANTAG = {
    # Paritetsscenariot i RidKanon är GOLDEN DATA: uppspelningen jämför
    # Roblox mot webbens egen stepRide med de hästar inspelningen gjordes
    # med. Namnen är alltså mätdata, inte en gren i spelets logik.
    "roblox/src/shared/HorseCore/RidKanon.luau": "paritetsscenariots golden data",
}


def hastid():
    """Hästarnas kanoniska id ur den genererade speldatan.

    Listan `ordning` i den genererade filen ÄR rostern, i kanonisk
    ordning. Att läsa den och inte skriva av namnen är hela poängen: en
    häst som läggs till skannas automatiskt."""
    text = DATA.read_text(encoding="utf-8")
    m = re.search(r"local ordning = \{(.*?)\}", text, re.S)
    if not m:
        return set()
    return set(re.findall(r'"([a-z0-9_]+)"', m.group(1)))


def avkommentera(kod: str) -> str:
    kod = re.sub(r"--\[(=*)\[.*?\]\1\]", "", kod, flags=re.S)
    kod = re.sub(r"--[^\n]*", "", kod)
    return kod


def main() -> int:
    ider = hastid()
    if len(ider) < 10:
        print(f"FEL  hittade bara {len(ider)} hästid i speldatan — skannern mäter inget")
        return 1
    fynd = []
    for katalog in SKANNADE:
        for fil in sorted((ROT / katalog).rglob("*.luau")):
            rel = str(fil.relative_to(ROT))
            kod = avkommentera(fil.read_text(encoding="utf-8"))
            for i, rad in enumerate(kod.splitlines(), 1):
                for hid in ider:
                    if f'"{hid}"' in rad:
                        if rel in UNDANTAG:
                            continue
                        fynd.append((rel, i, hid, rad.strip()[:90]))
    print(f"  Skannade {len(SKANNADE)} kataloger mot {len(ider)} kanoniska hästid.")
    for rel, skal in UNDANTAG.items():
        print(f"  Undantag: {rel} — {skal}")
    if fynd:
        print("\nHÄSTID HÅRDKODAT I RUNTIMEKOD — stacken är inte generisk:")
        for rel, i, hid, rad in fynd:
            print(f"  FEL  {rel}:{i}  \"{hid}\"  {rad}")
        return 1
    print("  OK   ingen individ har en egen gren i koden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
