# UBRF Spatial Canon v2

Status: **ACTIVE OVERRIDE — PRODUCT OWNER CORRECTION**

Maskinläsbar källa: `references/spatial/UBRF-SPATIAL-CANON-v2.json`.

## Varför detta finns

Tidigare F02-loop har gjort samma grundfel flera gånger: en planruta eller en funktionsetikett har tolkats som ett slutet rum, varefter implementationen har skapat väggar som inte finns i verkligheten. Detta dokument bryter den loopen.

Från och med v2 modelleras fysisk verklighet med fem primitiva typer:

- `WALL` — verifierad ogenomskinlig fysisk vägg.
- `OPENING` — verifierad öppning i en vägg/gräns.
- `GLASS` — verifierat transparent/glasat parti.
- `OPEN_AREA` — fysisk öppen yta. Rumsnamn inom ytan skapar ingen vägg.
- `NO_WALL_ZONE` — explicit förbjuden zon för härledda/inventerade väggar.

**Rum är metadata. Väggar är geometri. Ett rumsnamn får aldrig skapa geometri.**

## Bindande källaordning för omtvistade interiörer

1. Tobias uttryckliga korrigering.
2. `UBRF-SPATIAL-CANON-v2.json`.
3. verifierad plan/foto/film.
4. härledd geometri, tydligt märkt.
5. befintlig implementation endast som jämförelse.

Om implementationen och Spatial Canon skiljer sig är implementationen fel tills motsatsen har verifierats av Product Owner.

## Stallhuset — ny låsning

### Uppehållsrummet

Product Owner har visuellt underkänt den vägg/slutna volym som byggts inne i uppehållsrummet.

**LÅST:** uppehållsrummet är en öppen L-formad yta. Den tidigare `sluten_volym_v`-tolkningen inne i denna öppna yta är återkallad och får inte byggas.

Den öppna ytan består av de två redan identifierade delarna:

- västdel: x 0,0–5,9, N 0,0–10,0,
- östdel: x 5,9–11,2, N 0,0–5,6.

Det får finnas möbler och fasta detaljer enligt källor, men de får inte skapa en intern fullhöjdsvägg.

## Ridhuset — ny låsning

### Grundprincip

Entré-/receptionsdelen har övermodellats. Nuvarande preview har gjort öppna ytor till trånga korridorer och separata rum.

**LÅST:** entré-/receptionsområdet ska i första hand läsas som en öppen hall. Befintliga `RIDHUSINNE.entrehall.vaggar` är inte längre en betrodd vägglista. Varje väggsegment måste återgodkännas från faktisk evidens.

### Reception

Receptionen är **inglasad**. Där källan visar avgränsning ska den representeras som `GLASS`, inte som ersättande ogenomskinliga lådväggar.

Exakt glasgeometri ska spåras från plan/foto. Saknas exakt punkt är den `REFERENCE GAP`; den får inte fyllas med en sannolik vägg.

### HWC och andra funktionsetiketter

Att en yta heter HWC, ombyte, reception eller entré innebär inte automatiskt att den ska omges av en full uppsättning väggar i modellen.

Endast väggar som faktiskt kan beläggas får byggas. Funktionsidentitet och fysisk avgränsning är två olika saker.

### Spelbar passage till ridbanan

Följande kedja är bindande:

`huvudentré -> öppen entréhall -> arena access -> fysisk ridyta`

Den måste vara:

- visuellt begriplig,
- fysiskt gångbar,
- fri från artificiella smala korridorer skapade av osourcade väggar,
- utan teleport/clipping genom fidelity-geometri.

Kamera-/transparenssystem får hjälpa läsbarhet, men får aldrig användas för att dölja felaktig rumsgeometri.

## Runtime-kontrakt

När v2 implementeras ska varje `WALL` och `GLASS` i omtvistade ytor bära:

- `canon_id`,
- `source_id`,
- `confidence`.

En vägg utan dessa attribut i omtvistad yta är ett testfel.

`OPEN_AREA` och `NO_WALL_ZONE` ska också exporteras till både webb och Roblox så att samma gränser kan testas på båda plattformarna.

## Obligatoriska grindar

1. Ingen runtime-vägg får skära `stall_uppehall_no_internal_wall`.
2. Ingen osourcad opaque partition får finnas i `ridhus_open_hall_no_room_boxes`.
3. Huvudentré -> ridyta ska gå att gå i faktisk spelkollision.
4. Receptionens verifierade avgränsning ska vara glas, inte opaque ersättningsvägg.
5. Webb och Roblox ska använda samma `canon_id` och topologibeslut.
6. Fast kameravy från stallentrén ska visa uppehållsrummet som öppen yta.
7. Fast kameravy från ridhusentrén ska visa en öppen hall, inte en korridor av rumslådor.
8. Fast kameravy mot ridbanan ska visa och tillåta den verkliga vägen in till ridhuset.

## Golden-view-process

För varje omtvistad yta ska en fast kameravy sparas som testvy. Varje build ska rendera samma vy före produktreview.

Minimikrav:

- `STALL-V1` — från parkeringens entré in i uppehållsrummet.
- `RIDHUS-V1` — från huvudentrén in över entré/reception.
- `RIDHUS-V2` — från öppna entréhallen mot ridbanan.
- `RIDHUS-V3` — receptionens glasade avgränsning.

Dessa vyer är regressionsbevis, inte ersättning för Product Owner acceptance.

## Implementeringsregel

Claude får inte försöka "rätta" Spatial Canon genom att återanvända nuvarande väggar och döpa om dem. Om ett väggsegment inte överlever källaudit ska det tas bort.

Ordningen är:

1. ta bort återkallad geometri,
2. bygg endast verifierad `WALL`/`GLASS`,
3. säkerställ `OPEN_AREA` och topologin,
4. kör tester,
5. rendera golden views,
6. `READY_FOR_CHATGPT_REVIEW`,
7. Tobias visuella acceptance.
