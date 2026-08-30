# Stallets interiör — reference matrix

Skriven som steg 1 i interiör-P0. En rad per zon: vad PLANEN säger, vad
FOTO/FILM säger, vad som saknas, och vad spelet gör i dag på båda ytorna.

Klasser: `VERIFIED` · `MEASURED` · `DERIVED` · `ASSUMPTION` ·
`[REFERENCE GAP]` · `KNOWN MISMATCH` · `SUPERSEDED`.

Matrisen beskriver **nuläget efter det här passet**, inte historiken.
Historiken står i `audits/`.

## Källor

| kort | fil |
|---|---|
| i05 | `references/buildings/stall/stall-inne-05-stallgangen.jpg` |
| i06 | `references/buildings/stall/stall-inne-06-boxen-inifran.jpg` |
| i08 | `references/buildings/stall/stall-inne-08-breda-gangen.jpg` |
| i09 | `references/buildings/stall/stall-inne-09-gangen-ut.jpg` |
| i01–i04, i07 | uppehållsrum, pentry, sadelkammare, teorisal, spolspilta |
| plan | `references/plans/stall-plan1-utrymning-rak.jpg` |

## Matrisen

### 1. Boxrader och gångar

| fakta | klass | källa | spelet |
|---|---|---|---|
| Fyra boxrader, två gångar | `VERIFIED` | plan | webb + Roblox |
| 12 boxar per rad | `MEASURED` | plan, partiräkning | `STALL_BOXAR` |
| Boxbredd 3,5 m | `DERIVED` | plan / längd | `boxB` |
| Radernas djup ur bandandelar | `DERIVED` | plan | `STALL_BAND` |
| Husets bredd 21 m | `[REFERENCE GAP]` | — | arbetsvärde, se `KORT.md` |

### 2. Boxfronterna

| fakta | klass | källa | spelet |
|---|---|---|---|
| Tät nedre panel, lodräta spår, mörk antracit | `VERIFIED` | i05 + i06 | båda |
| Panelen `#454A4F` | `MEASURED` | i05 `#43474A`, i06 `#454B53` | `identitet.stall.boxfront.heldel` |
| Galvad stålram | `VERIFIED` | i05 + i06 | båda |
| Ramen `#9A9B93` | `MEASURED` | i05 `#999C97`, i06 `#9A998F` | `…boxfront.ram` |
| Bred kappregel ovanpå panelen | `VERIFIED` | i05 + i06 | båda |
| **Vågräta** runda reglar, luft emellan, fem st | `VERIFIED` | i05 | båda |
| Lodräta ändstolpar upp till överliggaren | `VERIFIED` | i05 + i06 | båda |
| Höjder 1,35 / 1,38 / 2,15 / 2,20 | `DERIVED` | spelets tidigare mått | delad data |
| Dörrbladet är ett rutnät i en smalare sektion | `[REFERENCE GAP]` | i05 visar det, men inte var per box | modelleras inte |
| Foderho på fronten | `[REFERENCE GAP]` | syns i i05 | modelleras inte |

Metod för färgerna: ytan lokaliseras, beskärs, **tittas på**, och mäts
först därefter (median). Rena tröskelvärden gav `#48`…`#41` beroende på var
tröskeln sattes — de mätte tröskeln, inte panelen.

### 3. Taket över boxhallen

| fakta | klass | källa | spelet |
|---|---|---|---|
| Limträstomme, tvärbalkar + snedstag + nockbalk | `VERIFIED` | i05 + i06 | båda |
| Limträ `#AD8A70` | `MEASURED`, spridning ±0,15 | i05 `#987B65`, i06 `#C2987B` | `…stallgang.limtra` |
| Korrugerad galvplåt som undertak | `VERIFIED` | i05 + i06 | båda |
| Plåt `#70716E` | `MEASURED` | i05 `#6B6C68`, i06 `#767574` | `…stallgang.takplat` |
| Takresning 2,1 m | `DERIVED` | flack sadel i bild, vinkel omätbar | `stall.takresning` |
| Balkdelning var 4:e meter | `ASSUMPTION` | — | båda |

De två bildrutorna skiljer sig **mycket** på limträet — taket är belyst
olika. Medelvärdet är det ärliga enskilda värdet; spridningen står här så
att ingen tror att siffran är exaktare än den är.

### 4. Armaturer

| fakta | klass | källa | spelet |
|---|---|---|---|
| Hängande armaturer under nocken | `VERIFIED` | i05 | webb |
| Antal, delning, typ | `[REFERENCE GAP]` | — | webbens är `ASSUMPTION` |
| Armaturer i Roblox | rättad | — | byggs nu, samma delning som webben |

### 5. Gångens golv

| fakta | klass | källa | spelet |
|---|---|---|---|
| Marksten i löpförband i mittstråket | `VERIFIED` | i05 + i09 | båda |
| Marksten `#867D6C` | `MEASURED` | i05, sd 17 | `stall.gangSten` |
| Spån ligger ut från boxarna längs fronterna | `VERIFIED` | i05 | webb |
| Spånremsan `#A79679` | `MEASURED` | i05, sd 49 | `stall.gangSpan` |
| Stenformat och förband | `[REFERENCE GAP]` | — | — |

Rättelse mot mitt eget första utkast av den här raden: spånremsan såg ut som
ett påhittat gult kantband och skrevs först upp som `KNOWN MISMATCH`. Fotot
visar tydligt spån som ligger ut i gången. Remsan var inte fel — den var för
gul och för ljus. Rätt åtgärd var att mäta den, inte att ta bort den.

### 6. Tvärkorridor, klubbdel, servicedel

| fakta | klass | källa | spelet |
|---|---|---|---|
| Tvärgång mitt i boxhallen | `MEASURED` | plan | båda |
| Tvärväggar på 0,72–0,755 av längden | `MEASURED` | plan | `klubbY` |
| Namngivna rum ur utrymningsplanen | `VERIFIED` | plan | båda, som låga volymer |
| Rummens inredning | `[REFERENCE GAP]` | i01–i04, i07 finns men är inte omsatta | — |
| Klockan i gångens bortre ände | `VERIFIED` | IMG_0160 + i05 | båda |

### 7. Hästgången till ridhuset

| fakta | klass | källa | spelet |
|---|---|---|---|
| Husen är sammanbyggda, hästen leds inomhus | `VERIFIED` | plan | båda |
| Gångens utseende inifrån | `[REFERENCE GAP]` | — | — |

## Öppna punkter efter det här passet

1. **Limträet läses fortfarande varmare och mer dominant** i webben än i i05.
   Tonen är mätt och rätt; det är balkarnas BREDD och DELNING som tar för
   mycket av taket. Delningen är `ASSUMPTION` och bör mätas.
2. **Reglarna på fronten är grövre** än fotots tunna runda rör. Antal och
   höjder stämmer; grovleken är stiliserad.
3. Husets bredd är fortfarande projektets äldsta öppna fråga.
4. Rummens interiörer (i01–i04, i07) är inhämtade men inte omsatta.
5. Dörrbladets rutnät och foderhon modelleras inte — `[REFERENCE GAP]`.
6. Roblox Studio är **inte** körd. Allt Roblox-arbete här är verifierat mot
   testbänken och mot koden, inte mot en skärm. Utseende, material, ljus och
   prestanda i Roblox är därmed OVERIFIERADE.
