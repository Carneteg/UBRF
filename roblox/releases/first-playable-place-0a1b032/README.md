# First Playable-place — källhead `0a1b032`

> ## ⛔ INTE SANKTIONERAD FÖR TOBIAS
>
> Filen är **byggd och mätt**, inte godkänd. Två av arbetsorderns steg går
> inte att köra i den miljö som byggde den, och båda är obligatoriska innan
> någon öppnar den här filen som speltest:
>
> | | Krav | Läge |
> |---|---|---|
> | steg 4 | P0-1 identifierad i Studio-runtime — vilken grind Tobias bild 2 visar | **inte gjord** |
> | steg 7 | Studio-MCP runtime-QA på exakt denna kandidat | **inte gjord** |
>
> `LATEST-FIRST-PLAYABLE.md` är därför **orörd**. Den här mappen är ett
> mätunderlag för `PRE_TOBIAS_FIRST_PLAYABLE_GATE --place`, ingenting annat.

## Identitet

| | |
|---|---|
| källhead (source SHA) | `0a1b0323fd2b77224c88388e4b11227c66745ff0` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `574d613abedc6dd84bf7a4d85cf39209819d378a0143278c9ddfd4bbe2f15bec` |
| storlek | 850 282 byte |
| innehåll | 62 instanser |
| byggd av | `python3 tools/bygg-place.py --sha 0a1b032…` ur `roblox/default.project.json` |

**Determinismen är kontrollerad, inte antagen.** En ombyggnad ur samma källa
gav samma SHA256 och en byte-identisk fil (`cmp -s`).

Källheaden är den commit som *byggde* filen. Själva filen läggs in i den
FÖLJANDE commiten — en fil kan inte innehålla sin egen SHA. Canonical länk
ska peka på committen som **innehåller** filen; det var den förväxlingen som
gav en verklig 404 i en tidigare runda.

## Vad gaten säger om just den här filen

`PRE_TOBIAS_FIRST_PLAYABLE_GATE`: **PASS**, alla nio undergrindar, mätt med
`--place` mot exakt den här filen.

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` | PASS |
| `END_TO_END_PLAYABILITY_GATE` | PASS |
| `NO_VOID_BASIC_PLAYABILITY_GATE` | PASS |
| `BUILDING_TOPOLOGY_TRAVERSAL_GATE` | PASS |
| `PHYSICAL_WORLD_COHERENCE_GATE` | PASS |
| `HANDIGHET_GATE` | PASS |
| `ROSTER_PHYSICAL_PRESENCE_GATE` | PASS |
| `INSTRUCTION_CONTEXT_GATE` | PASS |
| `WORLD_FIDELITY_ANCHOR_GATE` | PASS |
| `WORLD_MANIFEST` | 3 313 delar, 13 portaler, 33/33 hästar |

Full rapport: `qa/pre-tobias/RAPPORT.md`.

## Vad PASS här INTE betyder

Placen är **script-only**: 62 instanser, noll geometri. Det finns ingen
geometri i XML:en att mäta. Kedjan är `tools/kolla-place.py` — de inbäddade
modulerna byte-identiska mot disk — plus att grindarna kör exakt de
modulerna. Samma bevisvärde, men det är ett **argument** och inte en mätning
ur filen, och det ska stå som just det.

Ingenting här är provat i Roblox Studio. Att filen öppnar, att Play startar,
spelkänsla, kamera, animation, hästbeteende, fysisk input, performance och
DataStore i skarpt läge är alla **oprovade**. Roblox-världen har heller aldrig
haft en visuell granskning — `CHATGPT_VISUAL_PASS` gäller webbrenderingen.
