# ASSETS_NEEDED.md

Allt målat i spelet är PNG-sprites i `assets/`. Jag kan inte generera bilder —
de görs utanför projektet (Bing Image Creator gratis, annars Midjourney, DALL·E,
Recraft; eller färdiga CC0-paket från Kenney.nl och itch.io) och läggs sedan här.
Fram tills dess ritar jag tydligt markerade platshållare.

Frilägg bakgrunden (remove.bg eller motsvarande) och spara som PNG med alfakanal.

## Stilblocket

Lägg detta sist i **varje** bildprompt, ordagrant, så att allt hänger ihop:

```
stylized 3D cartoon game art, hand-painted textures, vibrant saturated colors,
soft rounded shapes, bright cheerful daylight, lush green grass, clear blue sky,
mobile horse game aesthetic, white background, no text, no watermark
```

## Namngivning

`assets/<kategori>-<namn>[-<variant>].png`, t.ex. `hast-fjord-sida.png`,
`byggnad-stall-front.png`, `ikon-rosett.png`. Allt i gemener, inga mellanslag.

---

## Nivå 1 — minsta uppsättning för att se om stilen landar

Elva bilder. Med dessa kan hela ridscenen, stallgården och HUD:en visas i rätt
stil, och vi vet om vi är på rätt väg innan mer tid läggs.

| Fil | Prompt (+ stilblocket) |
|---|---|
| `hast-fux-sida.png` | `a chestnut horse with flowing mane and tail, side view, full body, standing, game sprite` |
| `hast-skimmel-sida.png` | `a dapple grey horse with white flowing mane, side view, full body, standing, game sprite` |
| `hast-fjord-sida.png` | `a dun fjord pony with upright cream and black mane, side view, full body, standing, game sprite` |
| `ryttare-sida.png` | `a young rider character in navy jacket, cream breeches, tall black boots and a riding helmet, side view, full body, arms forward holding reins, game sprite` |
| `ryttare-front.png` | `a young rider character in navy jacket and riding helmet, front view, full body, standing, friendly face, game sprite` |
| `byggnad-stall.png` | `a red wooden Swedish horse stable with white trim and a grey metal roof, three-quarter front view, game asset` |
| `byggnad-ridhus.png` | `a large red riding arena building with white trim and tall sliding doors, three-quarter front view, game asset` |
| `trad-lov.png` | `a lush round deciduous tree, full canopy, side view, game asset` |
| `trad-host.png` | `a lush round deciduous tree with orange autumn leaves, side view, game asset` |
| `staket-sektion.png` | `a white wooden three-rail paddock fence section, side view, seamless tiling, game asset` |
| `mark-gras-tile.png` | `lush cartoon grass texture tile, top-down, seamless tiling, game asset` |

## Nivå 2 — resten av anläggningen

`byggnad-cafe.png`, `byggnad-sadelkammare.png`, `hinder-bom.png`,
`hinder-oxer.png`, `vattenkar.png`, `hobalar.png`, `skottkarra.png`,
`hastransport.png`, `silo.png`, `flaggstang.png`, `picknickbord.png`,
`buske.png`, `blommor.png`, `stenhast.png`

## Nivå 3 — hästarnas färger

En sprite per pälsfärg i profil, samma pose som nivå 1 så att de går att byta rakt av:
`hast-brun-sida`, `hast-mörkbrun-sida`, `hast-svart-sida`, `hast-palomino-sida`,
`hast-russ-sida`, `hast-connemara-sida`, `hast-welsh-sida`

Tecken (bläs, strumpor) läggs på i kod som overlay — be inte generatorn om dem,
den gör dem olika varje gång.

## Nivå 4 — ikoner till HUD och menyer

I `ui-kit-demo.html` är ikonerna emoji som platshållare (🥕 🧹 🐴 ⚙️ 👥 🛍️).
De byts mot målade PNG:er: runda, tjock vit eller guldkant, mjuk skugga under,
256×256.

`ikon-hjarta`, `ikon-stjarna`, `ikon-adelsten`, `ikon-mynt`, `ikon-hovslag`,
`ikon-borste`, `ikon-hovkrats`, `ikon-sadel`, `ikon-trans`, `ikon-hink`,
`ikon-morot`, `ikon-grep`, `ikon-rosett`, `ikon-pokal`, `ikon-installningar`,
`ikon-butik`, `ikon-vanner`

## Om animation

Bildgeneratorer håller inte karaktären konsekvent mellan bildrutor — be inte om
gångartscykler. En profilbild per häst räcker: takten görs i kod med
gungning, sträckning och benmask, och det blir jämnare än genererade rutor.

## Fotona från Drive

De 103 UBRF-fotona är bästa referensen för byggnaderna. Kör dem genom en
generator med `turn this photo into stylized cartoon game art` + stilblocket,
så blir stallet och ridhuset våra egna byggnader i rätt stil.
