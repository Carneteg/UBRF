# First Playable-place — källhead `91914a7`

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
| källhead (source SHA) | `91914a73f4257d7a90f925347a473e98fbc9e04f` |
| gren | `claude/first-playable-20260910`, bas `main` @ `7d8fe86` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `4771a340b69a3a986bf56c84ecdcd3edbf208be8add73d8742c2d59195cc115c` |
| storlek | 1 183 445 byte |
| instanser | 73 (varav 67 skript) |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `91914a73f4257d7a90f925347a473e98fbc9e04f` |

Determinism: ombyggd ur samma källa, **byte-identisk** (`cmp` rent).

**Länkregeln:** canonical länk ska peka på committen som INNEHÅLLER filen,
inte på källcommiten — `.rbxlx` läggs in i den *följande* commiten. Source-SHA
står separat ovan. `*.rbxlx` är märkt binär i `.gitattributes`; en utcheckning
med `core.autocrlf=true` ger fel SHA256.

## Vad som skiljer mot `5e89bcc`

Samma 73 instanser — inga nya moduler. 9 622 byte mer, och det är hela
skillnaden: topologiparitetsgaten ur PR #167 (`61ccee2` + `91914a7`, ChatGPT
code-level `READY_FOR_PRODUCT_ACCEPTANCE` 20:53 på exakt `91914a7`), bakad i
tre servermoduler och två datamoduler:

| modul | ändring |
|---|---|
| `UBRFKomplex.luau` | öppningarna bär `trafik`: hästgången och sarggrinden `"hast"`, sargporten och ridhusets sex dörrar för gående `"gaende"` (samma export som webben läser) |
| `UBRFSprak.luau` | ny nyckel `led.ingang_hast` (sv/en) |
| `LedService.luau` | `gangzonerUrKomplex`: varje dörr för gående paras med sin fasadöppning ur exporten och blir en zon; hästen stannar vid pivot när spelarens spår går genom en zon för gående och säger ifrån en gång; hästkapabla passager ger aldrig zon |
| `GameplayService.luau` | `start()` registrerar hela zonmängden ur exporten (sju zoner, noll luckor) och varnar per lucka |
| `RAPPORT.md` | regenererad mot den här filen |

Verifierat i den byggda filen: `gangzonerUrKomplex`, `satGangzoner`,
`hallenAvGangzon` och `led.ingang_hast` finns alla i placen; 19
`trafik = `-poster i den bakade exporten. Världen är oförändrad:
`3375 delar, 13 portaler, 33 hästar`.

Bänkbevis: `roblox/tests/ledning.spec.luau` (sektionerna "Öppningar för gående"
och "hela mängden ur exporten") och `integration.spec` Punkt 7; nio
falsifieringar dokumenterade i PR #167. Webbsidan av samma gate:
`tools/gangtest.mjs` (nu i CI) och `tools/uppdragstest.mjs`.

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
`…-637ab03` · `…-cd278d0` · `…-5e89bcc` · **`…-91914a7` (den här)**

En pinnad release regenereras aldrig på plats. Varje nytt läge får en egen
mapp med sin egen SHA.

> ### ⛔ Kör ingen artefakt före `…-b0265bb`
>
> I varje artefakt före `b0265bb` färdades hästen med **svansen före** —
> ridd, ledd och driven. Rotorsaken är rättad sedan dess; en äldre fil faller
> på § 9 av en orsak som inte längre finns.

## Inte testat

Studio-runtime på just den här filen — särskilt att hästen faktiskt stannar
vid huvudentrén och sargporten när man leder, och följer genom hästgången och
sarggrinden. Kamerakänsla. Fysisk input: tangentbord, handkontroll, iPad,
iPhone. Äkta multitouch och träffstack. Prestanda med full värld och hela
rostern. Flera ledda hästar samtidigt. Live DataStore.

**Tom ruta betyder inte PASS.** Protokollet är `docs/STUDIO-RUNTIME-QA.md`.
