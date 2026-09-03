# F02 — Spatial Canon v2 Implementation Order

Status: **BLOCKING CORRECTION**

Målbranch för implementation: `claude/f02-a-interior-topology`.

Källa som ska implementeras: `references/spatial/UBRF-SPATIAL-CANON-v2.json`.

## 1. Radera återkallad geometri först

### Stall

- Ta bort `sluten_volym_v` och alla fullhöjdsväggar som bygger samma återkallade tolkning inne i `stall_uppehall_open`.
- Uppehållsrummets två delytor ska fungera som en sammanhängande öppen yta.

### Ridhus

- Behandla nuvarande `RIDHUSINNE.entrehall.vaggar` som **ej betrodd vägglista**.
- Auditera varje segment mot faktisk plan/foto/Product Owner-korrigering.
- Om ett segment inte kan beläggas: ta bort det.
- Ett planfält eller funktionsnamn är inte väggbevis.

## 2. Bygg endast tillåtna primitiva objekt

Tillåtna fysiska partitioner i den omtvistade zonen:

- `WALL` med källa,
- `GLASS` med källa.

Övriga ytor modelleras som:

- `OPEN_AREA`,
- `OPENING`,
- `NO_WALL_ZONE`.

Receptionens verifierade avgränsning ska vara glasad. Saknas exakt glaslinje: lämna `REFERENCE GAP` i stället för att skapa opaque ersättningsvägg.

## 3. Gör rumsmetadata passiv

Ingen kod får bygga vägg bara för att ett objekt har `label`, `room`, `HWC`, `reception`, `ombyte` eller annan funktionsidentitet.

Väggar ska komma från spatiala primitivdata, inte från rummets namn.

## 4. Runtime provenance

I omtvistade interiörer ska varje byggt vägg-/glasobjekt bära:

- `canon_id`,
- `source_id`,
- `confidence`.

Webbens motsvarande data ska bära samma ID:n.

## 5. Topologigrindar

Obligatoriskt gångbar kedja i Ridhuset:

`main_entrance -> open_entrance_hall -> arena_access -> physical_riding_area`

Det ska vara en riktig fysisk väg, utan:

- clipping,
- teleport som ersätter passage,
- osynlig öppning genom en fidelity-vägg,
- smal korridor skapad av osourcade väggar.

## 6. Tester som måste bli röda vid mutation

- återinför `sluten_volym_v` -> rött,
- lägg en opaque vägg över `stall_uppehall_open` -> rött,
- återinför hela gamla `entrehall.vaggar` utan source ids -> rött,
- blockera `open_entrance_hall -> arena_access` -> rött,
- bygg receptionens avgränsning opaque i stället för GLASS -> rött,
- ta bort `canon_id` från en contested-area wall/glass -> rött.

## 7. Golden views

Rendera och dokumentera exakt samma kameravyer varje gång:

- `STALL-V1`: parkeringens entré -> in i uppehållsrummet,
- `RIDHUS-V1`: huvudentré -> entré/reception,
- `RIDHUS-V2`: öppna hallen -> ridbanan,
- `RIDHUS-V3`: receptionens glasade avgränsning.

Produktägaren ska kunna jämföra dessa utan att själv navigera runt för att hitta felet.

## 8. Leverans

Claude lämnar:

- exakt head SHA,
- diff mot föregående F02-A-head,
- lista över borttagna väggsegment och deras tidigare källa/orsak,
- lista över kvarvarande WALL/GLASS med `canon_id`,
- fyra golden views,
- walkability-test för entré -> ridyta,
- automatiska testresultat + falsifiering,
- `NOT TESTED IN ROBLOX STUDIO` om Studio inte faktiskt har körts.

Högsta status: `READY_FOR_CHATGPT_REVIEW`.
