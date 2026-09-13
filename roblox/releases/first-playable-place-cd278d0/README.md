# First Playable-place — källhead `cd278d0`

> ## ⛔ INTE SANKTIONERAD FÖR TOBIAS
>
> Filen är **byggd och mätt**, inte godkänd. Runtime-QA i Roblox Studio är
> inte körd på den här kandidaten, och den miljö som byggde den kan inte
> köra den: ingen `robloxstudio` MCP, inget Windows-filsystem.
>
> `LATEST-FIRST-PLAYABLE.md` är därför **orörd**.

## Identitet

| | |
|---|---|
| källhead (source SHA) | `cd278d0d4ac09f61f16fdd51f9375cf44e1dac27` |
| gren | `claude/first-playable-20260910`, bas `main` @ `7d8fe86` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `49cbe3c76f2ed51f5294bbb207735b7bd08512bf7d10ae3696adf97332aef7a2` |
| storlek | 1 167 744 byte |
| instanser | 73 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `cd278d0d4ac09f61f16fdd51f9375cf44e1dac27` |

Determinism: ombyggd ur samma källa, **byte-identisk** (`cmp` rent).

**Länkregeln:** canonical länk ska peka på committen som INNEHÅLLER filen,
inte på källcommiten — `.rbxlx` läggs in i den *följande* commiten. Source-SHA
står separat ovan. `*.rbxlx` är märkt binär i `.gitattributes`; en utcheckning
med `core.autocrlf=true` ger fel SHA256.

## Varför den är större än `637ab03`

`637ab03` var 984 514 byte och 66 instanser; den här är 1 167 744 byte och 73.
Skillnaden är **mätt, inte gissad**: mellan de två källhuvudena mergades `main`
in, och det tillförde exakt sju nya produktionsmoduler —

    roblox/src/client/DinHast.luau
    roblox/src/client/HastGang.luau
    roblox/src/server/Belysning.luau
    roblox/src/server/HastVisual.luau
    roblox/src/server/Markkontakt.luau
    roblox/src/shared/HorseCore/Riggprofiler.luau
    roblox/src/shared/HorseCore/Utseende.luau

— plus 24 ändrade. Sju nya moduler, sju nya instanser. Objekträknarna i
världen står still: `3375 delar, 13 portaler, 33 hästar`, samma som förut.
Tillväxten ligger i tjänstelagret, inte i geometrin.

## Vad som är nytt i koden sedan `637ab03`

| commit | vad |
|---|---|
| `458b44c` | QA-sele för skötselpanelen mot mobilens rörelsereglage |
| `4e6e3c0` | skötselpanelen väjer ur EGNA mått i stället för ur ett Roblox-internt GUI-namn |
| `be0735c` | hästresans fyra sömmar: omsittning, släppt koppel, vikarien mot sparfilen, pektexterna |
| `cd278d0` | två spelare och fria blicken, plus åtta bänkhål som gjorde `TouchControls.mount()` omätbar |

Den enda **produktionsändringen** i kedjan är `4e6e3c0`: +47 rader i
`PreparationController.luau`, noll borttagna. Resten är prov och stubbar.

## Grindar mot exakt den här filen

`PRE_TOBIAS_FIRST_PLAYABLE_GATE`: **PASS**, alla nio undergrindar.

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` | PASS (kolla-place, forstaplayable) |
| `END_TO_END_PLAYABILITY_GATE` | PASS (spelbarhet) |
| `NO_VOID_BASIC_PLAYABILITY_GATE` | PASS (mark) |
| `BUILDING_TOPOLOGY_TRAVERSAL_GATE` | PASS (topologi) |
| `PHYSICAL_WORLD_COHERENCE_GATE` | PASS (varldskoherens) |
| `HANDIGHET_GATE` | PASS (handighet, handighetsgrind) |
| `ROSTER_PHYSICAL_PRESENCE_GATE` | PASS (roster) |
| `INSTRUCTION_CONTEXT_GATE` | PASS (varldshud) |
| `WORLD_FIDELITY_ANCHOR_GATE` | PASS (kolla-ankare, kolla-nyckelbilder) |
| `WORLD_MANIFEST` | 3375 delar, 13 portaler, 33/33 hästar |

Evidensen ligger i `qa/pre-tobias/RAPPORT.md` och
`qa/pre-tobias/WORLD_MANIFEST.json`.

## Kedjan — inga mappar regenereras

`…-0a1b032` · `…-67e7716` · `…-efa341e` · `…-9b5a570` · `…-1e8b207` ·
`…-41b829c` · `…-c5984d0` · `…-59680e4` · `…-86662d1` · `…-b0265bb` ·
`…-637ab03` · **`…-cd278d0` (den här)**

En pinnad release regenereras aldrig på plats. Varje nytt läge får en egen
mapp med sin egen SHA.

> ### ⛔ Kör ingen artefakt före `…-b0265bb`
>
> I varje artefakt före `b0265bb` färdades hästen med **svansen före** —
> ridd, ledd och driven. Rotorsaken är rättad sedan dess; en äldre fil faller
> på § 9 av en orsak som inte längre finns.

## Inte testat

Studio-runtime på just den här filen. Kamerakänsla. Fysisk input: tangentbord,
handkontroll, iPad, iPhone. Äkta multitouch och träffstack. Prestanda med full
värld och hela rostern. Flera ledda hästar samtidigt. Live DataStore.

**Tom ruta betyder inte PASS.** Protokollet är `docs/STUDIO-RUNTIME-QA.md`.
