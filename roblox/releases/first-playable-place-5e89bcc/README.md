# First Playable-place — källhead `5e89bcc`

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
| källhead (source SHA) | `5e89bcc77e33f6d3e524890bab39c276519d4369` |
| gren | `claude/first-playable-20260910`, bas `main` @ `7d8fe86` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `d4a315f15efe24b07d09b9fa9e4494653bcdbf678e3535e7cf0ad8e2d9b7a1d3` |
| storlek | 1 173 823 byte |
| instanser | 73 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `5e89bcc77e33f6d3e524890bab39c276519d4369` |

Determinism: ombyggd ur samma källa, **byte-identisk** (`cmp` rent).

**Länkregeln:** canonical länk ska peka på committen som INNEHÅLLER filen,
inte på källcommiten — `.rbxlx` läggs in i den *följande* commiten. Source-SHA
står separat ovan. `*.rbxlx` är märkt binär i `.gitattributes`; en utcheckning
med `core.autocrlf=true` ger fel SHA256.

## Vad som skiljer mot `cd278d0`

Samma 73 instanser — inga nya moduler. 6 079 byte mer, och det är hela
skillnaden: produktionskoden ur PR #166 (pekridningens kontrakt, ChatGPT
code-level accept 14:15 på exakt `5e89bcc`), bakad i tre klientmoduler:

| modul | ändring |
|---|---|
| `TouchControls.luau` | kopplingarna till `UserInputService` rivs i `unmount` (läckte fyra per ritt); cellen aldrig under 44 px och tre i bredd när två 3-radsgaller inte ryms (iPhone i landskap); spakens ritade radie är inmatningsradien, knoppen skalad och innanför cirkeln; `reglageTopp()` |
| `KontrollHjalp.luau` | `vikForReglage(bredd, topp)` — `?` viker för gångartsraden bara när raden når dess band (iPhone), iPad oförändrad |
| `init.client.luau` | anropar `vikForReglage` vid upp- och avsittning |

Verifierat i den byggda filen: `tjanstKopplingar`, `vikForReglage`,
`reglageTopp`, `knopBana` och `perRad = 3` finns alla i placen. Världen är
oförändrad: `3375 delar, 13 portaler, 33 hästar`.

Bänkbevis: `roblox/tests/pekridning.spec.luau`, 85 mätningar genom den
riktiga `TouchControls.mount()` och klientens loop; 14 falsifieringar.
`docs/KONTROLLMATRIS.md` uppdaterad (namngivna pekgångarter, regel 5).

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
`…-637ab03` · `…-cd278d0` · **`…-5e89bcc` (den här)**

En pinnad release regenereras aldrig på plats. Varje nytt läge får en egen
mapp med sin egen SHA.

> ### ⛔ Kör ingen artefakt före `…-b0265bb`
>
> I varje artefakt före `b0265bb` färdades hästen med **svansen före** —
> ridd, ledd och driven. Rotorsaken är rättad sedan dess; en äldre fil faller
> på § 9 av en orsak som inte längre finns.

## Inte testat

Studio-runtime på just den här filen. Kamerakänsla. Fysisk input: tangentbord,
handkontroll, iPad, iPhone — särskilt tre knappar i bredd (64×44) på iPhone,
`?`-knappens nya plats och spakens knopp i cirkeln. Äkta multitouch och
träffstack. Prestanda med full värld och hela rostern. Flera ledda hästar
samtidigt. Live DataStore.

**Tom ruta betyder inte PASS.** Protokollet är `docs/STUDIO-RUNTIME-QA.md`.
