# First Playable-place — källhead `9b5a570`

> ## ⛔ INTE SANKTIONERAD FÖR TOBIAS
>
> Filen är **byggd och mätt**, inte godkänd. Runtime-QA i Roblox Studio är
> inte körd på den här kandidaten, och den miljö som byggde den kan inte
> köra den: ingen `robloxstudio` MCP, inget Windows-filsystem.
>
> | | Krav | Läge |
> |---|---|---|
> | Studio-MCP runtime-QA | `docs/STUDIO-RUNTIME-QA.md` §0–§9 på exakt den här filen | **inte gjord** |
> | HUD-layouten (8c) | PO-ordern 09:36 verifierad i runtime | **inte gjord** |
>
> `LATEST-FIRST-PLAYABLE.md` är därför **orörd**. Den här mappen är ett
> mätunderlag för `PRE_TOBIAS_FIRST_PLAYABLE_GATE --place`, ingenting annat.

## Identitet

| | |
|---|---|
| källhead (source SHA) | `9b5a570ed5f00102dbcf28a134270489f439157a` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `9f308f7aa3989e79df5b7f2c71b1c3ab288b69c1caa9bcd9a491bc29d19175bc` |
| storlek | 875 963 byte |
| instanser | 62 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `9b5a570ed5f00102dbcf28a134270489f439157a` |

**Källheaden är den commit som BYGGDE filen** — inte den som mätte den, och
inte grenens spets. Det är den SHA Studio skriver i Output som
`FIRST_PLAYABLE_SHA`, och den distinktionen gjorde förra körlistan
osatisfierbar när den blandades ihop.

Determinism: ombyggd ur samma källa, **byte-identisk**.

## Varför den här finns — §9 `ride` och produktbeslutet 13:29

Föregående artefakt (`…-efa341e`, SHA256 `fa2b492d…`) kom igenom §0–§8c —
alla tre rättelserna och HUD:en passerade i runtime. §9 `ride` föll: hästen
rörde sig 0,00 studs.

Rotorsaken var **inte** ett rörelsefel. `MovementController` tar hästen ur
halt och 4,4 m framåt, mätt. Ridloopen fryser henne medan ett Ugneta-kort
väntar — med flit, så att försöket inte blir ogiltigt medan spelaren läser
— och kortets knapp sa bara `"Börja"`, hårdkodat på svenska.

Produktbeslut: behåll pausen, gör orsaken tydlig. Knappen säger nu
**Fortsätt för att börja lektionen** / **Continue to start the lesson**,
ur språkkatalogen.

## Tidigare artefakter i kedjan

`…-67e7716` föll i §1 på en osund vakt (`CFrame is not a valid member of
SurfaceGui`); `…-0a1b032` gav de tre fynden §2/§7/§8. Alla ligger kvar
orörda som historik.

## Vad som var nytt i `first-playable-place-efa341e`

Den förra artefakten kom aldrig förbi §1. Världsbygget **kraschade**:

    CFrame is not a valid member of SurfaceGui "…Skylt skylt.Skyltyta"
    FIRST_PLAYABLE_PREFLIGHT: FAIL — 1f anläggningen är byggd
    CRITICAL_STARTUP_GATE: FAIL — INGEN SPELARE SLÄPPS IN

Felet kom med §7-rättelsen i den artefakten. I Luau **kastar** indexering av
en egenskap som klassen inte har — den ger inte `nil` — och vakten
`if d.CFrame and d.Size` över `GetDescendants()` är därför osund för varje
icke-`BasePart`. Skyltarnas `SurfaceGui` blev den första som inte var en del.

Rättat på fyra ställen som ligger i kedja (`Anlaggningen`s öppningspass,
`BuildKit.speglaModell`, den delade `VM.lador` och fem spec-svep): alla går
nu genom `d:IsA("BasePart")`. Rättas bara ett flyttar kraschen till nästa.

Bänken kastar numera likadant, med samma meddelande, för de egenskaper en
klass faktiskt saknar. Det var därför sviten var grön förra gången.

## Vad som är nytt sedan `first-playable-place-0a1b032`

Den förra artefakten kördes igenom `docs/STUDIO-RUNTIME-QA.md` §0–§9 den
11 september. Portaler (13+1), 33/33 hästar, utrustning och kärnloopen
passerade. Tre fynd föll ut, och alla tre är rättade här:

| § | Fynd i `0a1b032` | Läge i `9b5a570` |
|---|---|---|
| 2 | spawnen vette 180° bort från stalldörren (`dot = −1.000000`) | rättad — `speglaModell` sätter spawnens speglade blickriktning, `forstaplayable` mäter den |
| 7 | skyltskivorna var blanka: texten fanns bara som attribut | rättad — `SurfaceGui` + `TextLabel`, face:en byts vid speglingen |
| 8 | `ProximityPrompt.ActionText` förblev svenskt under `en-us` | rättad — texten sätts före nyckeln, och `Prompttext` hävdar översättningen tillbaka |

Dessutom, ur PO-ordern 09:36: skötsel-HUD:en är flyttad ur sikten — en
hopfälld spårare uppe till höger, och de stora valen bara under faktisk
interaktion.

## Kvar, och redovisat

| | |
|---|---|
| P0-1 `Spelabstraktion sargport` | avgjord i runtime — den ska enligt §4 bort ur världen. **Inte gjord här**: det är en geometriändring, och den kräver en egen mapp med ny SHA. |
| `ride` | `Not tested` i förra körningen — simulerad input når inte Studio utan OS-fokus. Behöver en människa vid tangentbordet. |
| persistens efter omläsning | `Not tested` — inget datalager i en opublicerad place. |
| objekträknarna | Studio gav 12 färre än bänken i förra körningen. Odiagnostiserat; rapporteras, fäller inte. |

## Grindar mot exakt den här filen

`PRE_TOBIAS_FIRST_PLAYABLE_GATE --place` → **PASS**, nio undergrindar:
`FIRST_PLAYABLE_PREFLIGHT`, `END_TO_END_PLAYABILITY_GATE`,
`NO_VOID_BASIC_PLAYABILITY_GATE`, `BUILDING_TOPOLOGY_TRAVERSAL_GATE`,
`PHYSICAL_WORLD_COHERENCE_GATE`, `HANDIGHET_GATE`,
`ROSTER_PHYSICAL_PRESENCE_GATE`, `INSTRUCTION_CONTEXT_GATE`,
`WORLD_FIDELITY_ANCHOR_GATE`. Manifest: 3317 delar, 13 portaler, 33 hästar.

Rapport: `qa/pre-tobias/RAPPORT.md`.
