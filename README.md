# Ridskolan — UBRF

Ett ridspel byggt kring Upplands-Bro Ryttarförening (Husbyvägen 1A, Bro).
Du börjar längst ner i kedjan: till fots på gården. Du tilldelas en häst av
ridläraren, visiterar, ryktar, kratsar och sadlar i stallet, leder hästen
över gården in i ridhuset — och först då börjar lektionen. Du styr inte
hästen: du styr fyra hjälper, och hjälperna flyttar hästens tillstånd på
utbildningsskalan.

## Köra

Öppna `index.html` via en lokal webbserver, t.ex.:

```
python3 -m http.server 8000
```

och gå till `http://localhost:8000/`. Bygg en-fils-versionen (för artefakt/
delning) med:

```
python3 tools/build.py     # → dist/ridskolan.html
```

## Din ryttare

Första gången frågar spelet vem du är: utseende (namn, hy, hår, frisyr,
kavaj, ridbyxor, hjälm) och **tre egenskaper av sex** — Styrka, Upprätt
sits, Pondus, Mjuk hand, Lugn och Tålamod. Alla sex är hämtade ur
Ridhandboken och lutar ridmodellen någon tiondel; ingen av dem låter dig
hoppa över att lära dig något. Allt bor i `src/jag.js`.

## Tangenter

| Till fots | I sadeln |
|---|---|
| `W A S D` gå, `Shift` jogga | `W/S` skänkel, `Space` tygeltag, `A/D` styrning |
| `E` interagera (dörrar, ridlärare, box) | `E` halvhalt, `Shift` lätt sits, `Ctrl` nedsittning |
| `V` karta / bakom dig | `R` lättridning, `Q` byt diagonal, `F` spö |
| `T` träningsboken | `T` momentets övning, `N` nästa moment, `P` autopilot |

## Anläggningen

`src/site.js` är den enda sanningen om geometrin, byggd mot 103
referensfoton från anläggningen (Drive-mappen `UBRF`, IMG_0064–0166 —
fotona ligger inte i repot):

- **Ridhuset** i mörkröd korrugerad plåt med svarta detaljer: 20×60-banan,
  cafétrappan och Café Krubban på södra gaveln, UBRF-skylten på västra
  långsidan mot grusvägen och åkrarna, durkplåtdörrarna mot gården,
  silverporten på norra gaveln.
- **Stallet** (byggt 2016) i faluröd träpanel med vita knutar, välvda
  småfönster och rad av ventilationshuvar på nocken; L-format via
  förbindelselängan som stänger gräsgården mellan stall och ridhus.
  Södra gaveln: klubbdelens veranda med den gulockra entrédörren och
  bullseye-fönstren. Norra gaveln: fodersilon, ensilagebalarna.
- **Stallgången**: två boxrader i antracitgrå komposit med galvade galler,
  namnskyltar (Lady, Westside, Makadu, Kennedy, Tina m.fl. från fotona,
  blandade med de spelbara hästarna från ubrf.se), klubbdelen med
  uppehållsrum och teorisal i söder, spolspilta och spånförråd i norr.
- **Omnejden**: grusparkeringen, lekhagen med stenhästarna, skyltstolpen
  (Framridning · Ridhus · Stallentré · Toaletter · Utebana), röda stugan
  och busshållplatsen vid infarten, utebanorna på slänten i nordväst med
  domarkuren och belysningsmasterna, hagarna i öster med betande hästar.

## Träningsboken

`src/ovningar.js`: 16 övningar och 11 kunskapskapitel, strukturerade efter
Markus Ridhandbok (markusholst.com/ridhandboken) — fem grundkommandon,
hästens form, övergångarna, skolorna, galopparbetet. Texterna är spelets
egna sammanfattningar med källhänvisning per kapitel. Varje övning bär
vikter mot utbildningsskalan så att lektionens bedömningsmodell kan användas
rakt av. Ingen databas behövs — spelet är en fil och banken är data.

## Kodstruktur

| Fil | Innehåll |
|---|---|
| `src/model.js` | Ridmodellen — rak port av Luau-modulerna (utbildningsskalan, gångarter, avsprång, domare) |
| `src/data.js` | Hästarna (ur ubrf.se/hastar), lektionen, banan |
| `src/site.js` | Anläggningens geometri + stallets interiör |
| `src/ovningar.js` | Träningsboken: övningsbank + hästkunskap |
| `src/render.js` | Ridhusets 2D/3D-rendering (lektionen) |
| `src/world.js` | Gå-läget: fysik, interaktion, gårdens och stallets rendering |
| `src/game.js` | Input, speltillstånd, lektionslogik, HUD, huvudloop |
| `src/scenes.js` | Meny, tilldelning, skötsel, resultat |
| `tools/build.py` | Bygger `dist/ridskolan.html` (en fil) |
