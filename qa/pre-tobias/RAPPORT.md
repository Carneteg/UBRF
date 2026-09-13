# PRE_TOBIAS_FIRST_PLAYABLE_GATE — release evidence bundle

> **FAIL** — genererad 2026-09-13 15:40 UTC av `tools/pre-tobias-grind.py`.

> **Ingen ny `.rbxlx` får sanktioneras för Tobias.**


## Identitet

| | |
|---|---|
| artefaktens källhead (bakad `UBRFBuild.sha`) | `5e89bcc77e33f6d3e524890bab39c276519d4369` |
| mätt `.rbxlx` | `roblox/releases/first-playable-place-5e89bcc/UBRFFirstPlayable.rbxlx` |
| `.rbxlx` SHA256 | `d4a315f15efe24b07d09b9fa9e4494653bcdbf678e3535e7cf0ad8e2d9b7a1d3` |
| storlek | 1173823 byte |
| instanser | 73 (`<Item class=` i filen), varav 67 skript |
| grindkörarens commit (`git HEAD` där rapporten skrevs) | `df6a77105c9478bd0eec62b1651f2ec637261221` |
| gren | `claude/first-playable-20260910` |

## Undergrindarna

| Grind | Vad den mäter | Utfall |
|---|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` | placen innehåller allt First Playable behöver | **FAIL** (kolla-place ❌, forstaplayable) |
| `END_TO_END_PLAYABILITY_GATE` | hela spelresan går att gå | **PASS** (spelbarhet) |
| `NO_VOID_BASIC_PLAYABILITY_GATE` | ingen spelbar yta utan stöd under | **PASS** (mark) |
| `BUILDING_TOPOLOGY_TRAVERSAL_GATE` | varje portal mynnar i rätt zon | **PASS** (topologi) |
| `PHYSICAL_WORLD_COHERENCE_GATE` | världen håller ihop fysiskt | **PASS** (varldskoherens) |
| `HANDIGHET_GATE` | världen är högerhänt på båda ytorna | **PASS** (handighet, handighetsgrind) |
| `ROSTER_PHYSICAL_PRESENCE_GATE` | hela rostern står fysiskt i stallet | **PASS** (roster) |
| `INSTRUCTION_CONTEXT_GATE` | instruktionen följer state och zon | **PASS** (varldshud) |
| `WORLD_FIDELITY_ANCHOR_GATE` | de verifierade ankarmåtten och skyltarna stämmer | **PASS** (kolla-ankare, kolla-nyckelbilder) |

## World manifest summary

| | |
|---|---|
| byggda delar | 3375 |
| marklager | 16 bärande, 0 dekor |
| fysiska hästar | 33 / 33 |
| utrustningsplatser | 3 |
| skyltar | UPPLANDS-BRO RYTTARFÖRENING, CAFÉ KRUBBAN |
| spawn | (161.6, 126.4) mot stall N dorrgul |

### Kritiska portaler

| Byggnad | Sida | Typ | Bredd | Läge |
|---|---|---|---|---|
| ridhus | N | dorrvit | 1.80 m | (139.0, 119.0) |
| ridhus | N | dorr | 1.10 m | (134.3, 119.0) |
| ridhus | W | dorrvit | 2.00 m | (118.0, 109.0) |
| ridhus | E | portplat | 3.40 m | (143.0, 48.5) |
| ridhus | E | portbla | 2.40 m | (143.0, 84.6) |
| ridhus | S | portsilver | 4.00 m | (128.0, 41.8) |
| stall | W | dorrgul | 1.15 m | (151.1, 118.8) |
| stall | W | portbla | 2.40 m | (151.1, 84.6) |
| stall | N | dorrgul | 1.15 m | (161.6, 125.0) |
| stall | E | portbla | 3.60 m | (172.1, 91.2) |
| stall | S | dorrvit | 1.15 m | (157.3, 55.0) |
| stall | S | dorrvit | 1.15 m | (164.2, 55.0) |
| langa | N | dorrmork | 1.10 m | (149.1, 40.0) |

**Deklarerade icke-passager** — öppningar som med flit INTE går att gå igenom:

- `ridhus W dorr` — [REFERENCE GAP] Öppningen ligger bakom läktarens bänkrader. Att såga hål i läktaren för att dörren ska gå att använda vore påhittad geometri. VILKEN långsida läktaren ligger på är ännu inte avgjord (se noten i buildings/Vyer.luau); visar sig den ligga på östra sidan blir den här dörren fri och raden ska bort.

### Rekvisita kanon har men världen inte bygger

ac×2, balar×1, bank×1, bord×2, busskylt×1, flagga×1, grushog×1, silo×1, sopstation×1, stenhast×4, stol×1, torvbalar×1, transport×1, vagvisare×1

## Kvarvarande NOT_TESTED

Ordern, punkt 8: här får bara verklig Roblox-motor och spelkänsla stå — aldrig statiskt synliga världsproblem.

- att `.rbxlx` **öppnar** i Studio och att Play startar
- spelkänsla, kamera, animation och hästbeteende i motorn
- fysisk input: tangentbord, handkontroll, iPad, **iPhone** (tre knappar i bredd 64×44, `?`-knappens plats, spakens knopp i cirkeln)
- äkta multitouch och Roblox träffrouting — bänken mäter staplingskontraktet, inte vilket objekt motorn ger fingret
- kontroll- och kamerakänsla i handen; mjukvarukontrakten är testade (`camera.spec`, `pekridning.spec`), känslan inte
- performance med full värld och hela rostern
- DataStore i skarpt läge, och revisionskollisionen
- visuell granskning av ROBLOX-världen; `CHATGPT_VISUAL_PASS` gäller webbrenderingen, inte den här

## Artefaktkedjan, uttryckligen

Placen är script-only: 73 instanser räknade ur filen (`<Item class=`), varav 67 skript, noll geometri. Det finns ingen geometri i XML:en att läsa, så kedjan är `tools/kolla-place.py` — de inbäddade modulerna byte-identiska mot disk — plus att grindarna kör exakt de modulerna. Samma bevisvärde, men det är ett **argument** och inte en mätning ur filen.

