# Ridhusets interiör — reference matrix

Steg 2 i interiör-P0. En rad per zon: plan-fakta, foto-fakta, `REFERENCE GAP`.
Beskriver **nuläget**, inte historiken.

## Källor

| kort | fil |
|---|---|
| r01 | `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg` (IMG_0179) |
| r02 | `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg` (IMG_0183) |
| r03 | `references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg` (IMG_0198) |
| plan | `references/plans/ridhus-entreplan-utrymning.jpg` |
| mätning | `references/plans/RIDHUS-PLANMATNING-2026-08-30.md` |

`IMG_0191.MOV` finns **inte** i repot — `[DRIVE-ONLY]`. Inget nedan vilar på den.

## 1. Banan och sargen

| fakta | klass | källa | spelet |
|---|---|---|---|
| Banan 20 × 60 m | `VERIFIED` | Tobias bekräftelse, `SITEPLAN.md` | `bana` |
| Sargen vit/gräddvit med svart sockelband | `VERIFIED` | r01 + r03 | `vagg`/`sockel` |
| Sarghöjd 1,35 m | `DERIVED` | — | `sargH` |
| Dressyrbokstäver på sargen | `VERIFIED` | C i r01, E i r03 | byggs |
| E har en elefantbild | `VERIFIED` | r03 | `[REFERENCE GAP]` — ritas inte |

**Not:** en tidigare referens som påstods vara en måttsatt ritning är
**återkallad** (se `RIDHUS-PLANMATNING-2026-08-30.md`). Banans 20 × 60 står
kvar på Tobias bekräftelse, inte på den bilden. Påståendet om "5 m
sidozoner" kom ur den återkallade källan och används inte.

## 2. Långsidans läktare — `KNOWN MISMATCH A`, rättad

| fakta | klass | källa | spelet |
|---|---|---|---|
| **Plant plankdäck**, inga trappsteg | `VERIFIED` | r01 förgrund, beskuren | rättat |
| Solid mörkbetsad brädfront mot banan | `VERIFIED` | r01 + r02 | rättat |
| Ljus kappregel överst på fronten | `VERIFIED` | r01 | rättat |
| Däckets höjd 0,80 m | `DERIVED` ur r03 | sittande huvuden ~0,7 m över sargkrönet | `dackZ` |
| Frontens topp 1,45 m | `DERIVED` | strax över sargkrönet | `frontTopp` |
| Exakta mått | `[REFERENCE GAP]` | — | testas som relation |

Spelet byggde **fyra trappsteg i ljus furu** längs hela långsidan. Fotona
visar ett plant däck. Trappstegen finns — vid KORTÄNDAN, under glasrummen.
De två strukturerna hade blandats ihop.

## 3. Kortändan vid C

| fakta | klass | källa | spelet |
|---|---|---|---|
| Trappstegsblock i ljust trä | `VERIFIED` | r01 | `kortanda` |
| Två trappor upp | `VERIFIED` | r01 | byggs |
| Glasat band av rum ovanför, mörka karmar | `VERIFIED` | r01 | byggs |
| Rund vit klocka på den vita väggen | `VERIFIED` | r01 | byggs |
| Vit stående brädvägg med stjärndekor | `VERIFIED` | r01 | `[REFERENCE GAP]` — dekoren ritas inte |
| Alla meter | `[REFERENCE GAP]` | — | topologi rätt, mått valda |

## 4. Övre långväggen — `KNOWN MISMATCH B`, delvis

| fakta | klass | källa | spelet |
|---|---|---|---|
| Rostbrun/mörkröd panel på DEL av EN långsida | `VERIFIED` | r02 | `ovreVagg.sida:"W"`, y 6–40 |
| Vita horisontella band på panelen | `VERIFIED` | r02 | `panelList` |
| **Fönsterband ovanför panelen** | `VERIFIED` | r02 | rättat — `fonsterband` |
| Bandet löper förbi panelens stycke | `VERIFIED` | r02 | byggs i full längd |
| Bandets höjd och postdelning | `[REFERENCE GAP]` | — | valda |
| Resten av samma vägg är ljus | `VERIFIED` | r02 | byggs |
| Panelens exakta utbredning | `[antagande]` | — | y0/y1 |

## 5. Sponsorskyltar — `KNOWN MISMATCH C`

| fakta | klass | källa | spelet |
|---|---|---|---|
| Skyltar hänger på den rostbruna panelen | `VERIFIED` | r02 | **kopplingen saknas** |
| Agria, Hästsportbutik, RS Mustang, Svenskt Stallströ | `VERIFIED` | r02 | — |
| Skyltarnas läge relativt panelen | rättat | — | `andel` av panelens stycke, härlett |

## 6. Taket

| fakta | klass | källa | spelet |
|---|---|---|---|
| Mörka limträbalkar | `VERIFIED` | r01 + r02 | byggs |
| Korrugerad plåt som undertak | `VERIFIED` | r01 + r02 | byggs |
| Långa lysrörsarmaturer i rader | `VERIFIED` | r01 + r02 | byggs |
| Stora runda spiralkanaler (vent) | `VERIFIED` | r01 | byggs |
| Högtalare | `VERIFIED` | r01 | `[REFERENCE GAP]` |
| Kabelstegar | `VERIFIED` | r01, beskuren och zoomad | byggs |

## 7. Domarbåset vid E

| fakta | klass | källa | spelet |
|---|---|---|---|
| Mörkt trä, upphöjt, trappa med räcken | `VERIFIED` | r03 | byggs |
| Grön exit-skylt | `VERIFIED` | r03 | byggs |
| Sitter på läktarnivå | `DERIVED` | r03 | följer `dackZ` |

## Rättat i det här passet

- **A** läktaren: plant däck med solid front i stället för fyra trappsteg.
- **B** fönsterbandet ovanför panelen byggs nu.
- **C** skyltarnas läge HÄRLEDS ur panelens stycke i stället för att stå som
  tal. Ett första test på detta var för svagt — det passerade för vilka tal
  som helst som råkade ligga innanför stycket, vilket jag prövade genom att
  frikoppla dem. Testet mäter nu själva kopplingen.

## Öppna motsägelser

1. **Sarg kontra läktarfront.** r01 och r02 visar den mörka brädväggen SOM
   bangräns på däckets sida, utan vit sarg framför. r03 visar en vit sarg
   med sittplatser bakom, vid bokstaven E — på samma långsida. De går inte
   att förena ur bilderna. Spelet bygger tills vidare båda.
2. ~~Kabelstegarna syns inte i något foto.~~ **PRÖVAT OCH FALSKT.** Både
   en tidigare review och mitt eget första utkast av den här matrisen skrev
   att kabelstegarna inte syns. Jag beskar och zoomade takzonen i r01 innan
   jag tog bort dem: den perforerade rännan med regelbundna stegpinnar under
   stålbalken, med en kopplingsdosa mitt på, ÄR en kabelstege. Detaljen är
   riktig och står kvar. Hade jag följt reviewn utan att titta hade jag
   tagit bort ett korrekt drag.
3. `IMG_0191.MOV` är `[DRIVE-ONLY]` och kan inte prövas härifrån.
4. Roblox Studio är **inte** körd.
