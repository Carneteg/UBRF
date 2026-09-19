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
#
# NYCKLARNA SKRIVS MED `/`, ALLTID. Se `nyckel()` nedan för varför det inte
# räcker att skriva dem så.
UNDANTAG = {
    # Paritetsscenariot i RidKanon är GOLDEN DATA: uppspelningen jämför
    # Roblox mot webbens egen stepRide med de hästar inspelningen gjordes
    # med. Namnen är alltså mätdata, inte en gren i spelets logik.
    "roblox/src/shared/HorseCore/RidKanon.luau": "paritetsscenariots golden data",
}


def nyckel(rel) -> str:
    """Sökvägen i grindens egen nyckelform: alltid `/`, aldrig `\\`.

    `pathlib.Path.relative_to()` ärver plattformens separator. På Linux ger
    den `roblox/src/...`, på Windows `roblox\\src\\...`. Undantagslistan ovan
    skrivs med `/`, så uppslaget `rel in UNDANTAG` missade ALLTID på Windows
    — och paritetsscenariots golden data rapporterades som hårdkodade
    hästid. Grinden var grön i CI och röd på utvecklarmaskinen, vilket är
    det sämsta av två världar: felet syns bara för den som inte kan agera
    på det, och den som ser det lär sig att ignorera grinden.

    Funktionen finns som en egen, namngiven sak just för att `testa-kolla-
    generisk-hast.py` ska kunna mäta normaliseringen direkt — på vilken
    plattform som helst — i stället för att bara kunna mäta den på Windows.
    """
    return str(rel).replace("\\", "/")


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
    """Tar bort kommentarer men BEHÅLLER radbrytningarna.

    Första versionen klippte bort blockkommentarer med allt innehåll,
    radbrytningar inkluderade. Radnumren i felrapporten gled då — de pekade
    på rader i den strippade texten, inte i filen — och ett fynd blev
    omöjligt att hitta. Ett mätverktyg som pekar fel är värre än inget."""
    def tomma(m):
        return "\n" * m.group(0).count("\n")
    kod = re.sub(r"--\[(=*)\[.*?\]\1\]", tomma, kod, flags=re.S)
    return re.sub(r"--[^\n]*", "", kod)


def main() -> int:
    ider = hastid()
    if len(ider) < 10:
        print(f"FEL  hittade bara {len(ider)} hästid i speldatan — skannern mäter inget")
        return 1
    fynd = []
    #[[ Varje skannad fil, i nyckelform. Utan den här mängden går det inte
    #   att skilja "undantaget behövdes inte" från "undantaget träffade
    #   aldrig något", och det var precis den skillnaden som gjorde
    #   separatorbuggen osynlig: nyckeln matchade ingenting, och grinden
    #   rapporterade i stället golden data som en defekt. ]]
    sedda = set()
    tystade = {rel: 0 for rel in UNDANTAG}
    for katalog in SKANNADE:
        for fil in sorted((ROT / katalog).rglob("*.luau")):
            rel = nyckel(fil.relative_to(ROT))
            sedda.add(rel)
            kod = avkommentera(fil.read_text(encoding="utf-8"))
            for i, rad in enumerate(kod.splitlines(), 1):
                for hid in ider:
                    if f'"{hid}"' in rad:
                        if rel in UNDANTAG:
                            tystade[rel] += 1
                            continue
                        fynd.append((rel, i, hid, rad.strip()[:90]))
    print(f"  Skannade {len(SKANNADE)} kataloger mot {len(ider)} kanoniska hästid.")
    for rel, skal in UNDANTAG.items():
        print(f"  Undantag: {rel} — {skal} ({tystade[rel]} rader tystade)")

    #[[ ETT UNDANTAG SOM INTE PEKAR PÅ EN SKANNAD FIL ÄR TRASIGT.
    #
    #   Felstavat, flyttat, borttaget — eller skrivet i en separatorform
    #   grinden inte känner igen. Alla fyra ser likadana ut inifrån: ett
    #   namn som aldrig jämförs med någonting. Att fälla på det är hela
    #   skälet till att den här raden finns; utan den kan grinden tysta
    #   fel fil, eller ingen fil, utan att någon märker det. ]]
    saknade = sorted(rel for rel in UNDANTAG if rel not in sedda)
    if saknade:
        print("\nUNDANTAG SOM INTE PEKAR PÅ NÅGON SKANNAD FIL:")
        for rel in saknade:
            print(f"  FEL  {rel}  — finns inte bland de skannade filerna")
        print("  Undantaget tystar alltså ingenting, och grinden mäter inte"
              " det den påstår.")
        return 1

    if fynd:
        print("\nHÄSTID HÅRDKODAT I RUNTIMEKOD — stacken är inte generisk:")
        for rel, i, hid, rad in fynd:
            print(f"  FEL  {rel}:{i}  \"{hid}\"  {rad}")
        return 1
    print("  OK   ingen individ har en egen gren i koden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
