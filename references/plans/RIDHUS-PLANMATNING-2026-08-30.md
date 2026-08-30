# Ridhuset — mätt i utrymningsplanen

Datum: 2026-08-30 · reviderad samma dag efter källrättelse
Källa: **`references/plans/ridhus-entreplan-utrymning.jpg`**, som ligger i repot.
Mätt i bildpunkter med tröskling på planytans gula färg och på väggstreckens
mörka pixlar.

## Rättelse: vad den här filen INTE vilar på

Filen skrevs först som en prövning av `RIDHUS-MATTSATT-PLAN-2026-08-30.md`
(`7c70d67`). **Den referensen är återkallad** — bilden var ingen måttsatt
ritning utan en satellitbild med en mätlinje i Google Maps, och dess
meteretiketter hör till mätverktyget, inte till byggnaden. Den ersattes av
`references/site/SATELLIT-MATNING-2026-08-30.md` (`0d4116c`).

**Mätningarna nedan berörs inte av det.** De gjordes aldrig på den bilden — jag
har aldrig haft den — utan på utrymningsplanen i repot. Det som däremot faller
är den ram jag satte dem i:

| Påstående | Status |
|---|---|
| Banan 20 × 60 m är `VERIFIED` **enligt en måttsatt plan** | **SUPERSEDED.** Banan är fortfarande `VERIFIED`, men på Tobias tidigare bekräftelse (`SITEPLAN.md`, ridhuskortet) — inte på den bilden |
| Läktarbandet jämfört med en **5 m sidozon** | **SUPERSEDED.** De 5 metrarna kom ur den återkallade referensen. Jämförelsen stryks |
| Fotavtrycket 25 × 75 stärkt av **planförhållandet 3,022 : 1** | **Står kvar** — mätt i utrymningsplanen, oberoende av den återkallade bilden |
| En längd på 65 m är utesluten | **Står kvar** — bygger på utrymningsplanen plus den bekräftade 60 m-banan |

## Mätningarna

| Vad | Mätt | Metod |
|---|---|---|
| Planens längd/bredd-förhållande | **3,022 : 1** | Gula planytans omslutande rektangel, 817 × 2469 px |
| Entrédelens djup | **15,1 %** av längden | Väggtätheten per rad: entrédelen är full av rum, banan är en lugn yta. Övergången ligger 334 px in av 2205 |
| Bandet längs ena långsidan | **0–14,5 %** av bredden | Fem parallella linjer i tvärsnitt vid fyra olika y-lägen: 2,6 · 5,8 · 8,4 · 11,1 · 14,2 %. Det är läktarens trappsteg sedda i plan |

## Vad de avgör

### 1 · Fotavtrycket 25 × 75 m motsägs INTE

25 × 75 ger förhållandet 3,00 : 1. Planen mäter **3,022 : 1** — under en
procents skillnad. Det är en oberoende bekräftelse av ett mått som hittills
bara var härlett.

### 2 · En längd på 65 m är utesluten

Om huset vore 65 m långt skulle entrédelens 15,1 % motsvara 9,8 m, och kvar
för banan blir **55,2 m**. Banan är verifierat **60 m**. Det går inte ihop.

Vid 75 m blir entrédelen 11,4 m och kvar 63,6 m — vilket rymmer en 60 m bana
med marginal. **Fotavtrycket står kvar.**

Det är en slutsats ur planen och den bekräftade banan, inte ur någon
meteretikett.

### 3 · Sidozonen är läktarens band

De fem parallella linjerna i tvärsnittet är läktartrappstegen. Bandet är
**14,5 % av bredden ≈ 3,6 m** vid 25 m. Spelet bygger läktaren 21 → 25, alltså
4 m. Nära, och inom avläsningsfelet.

Jämförelsen med en "5 m sidozon" som stod här är struken: de 5 metrarna kom ur
den återkallade referensen.

### 4 · Entrédelen

Mätt **11,4 m** vid 75 m längd. Spelet bygger `entre: 13`. Skillnaden 1,6 m är
inom felmarginalen för en snett fotograferad plan, och jag ändrar den inte på
den här grunden.

## Klassningar efter prövningen

| Fakta | Före | Efter |
|---|---|---|
| Banan 20 × 60 m | `[antagande]` | **VERIFIED** — Tobias bekräftelse, se `SITEPLAN.md`. **Inte** den återkallade bilden |
| Fotavtryck 25 × 75 m | `DERIVED` ur perspektivkorrigering | **DERIVED, stärkt** — två oberoende avläsningar, 3,00 mot 3,022 |
| Längd 65 m | föreslagen som möjlig | **UTESLUTEN** — ryms inte med en 60 m bana |
| Läktarbandets bredd 4 m | `ASSUMPTION` | `DERIVED` — 14,5 % av bredden mätt i utrymningsplanen |
| Entrédelen 13 m | `ASSUMPTION` | `ASSUMPTION`, mätt till 11,4 m — inom felmarginal |

## Kvar

`[REFERENCE GAP]` **En måttsatt ritning på ridhuset.** Någon sådan finns inte i
repot. Utrymningsplanen saknar skalstock, så allt ovan är proportioner — det som
låser dem i meter är den bekräftade 20 × 60-banan.

`[REFERENCE GAP]` **Ridhusplanen rakt framifrån.** Den i repot är fotograferad
snett, vilket är felkällan bakom entrédelens 11,4 m mot spelets 13.
