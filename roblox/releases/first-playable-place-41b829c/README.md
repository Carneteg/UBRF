# First Playable-place — källhead `41b829c`

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
| källhead (source SHA) | `41b829c29faef86123b5af1cc4feb60d92f878bb` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `50bf743cf50f081f560e560ff08e342fafaec3cb939469dbed611e083b1c55a3` |
| storlek | 910 411 byte |
| instanser | 64 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `41b829c29faef86123b5af1cc4feb60d92f878bb` |

Determinism: ombyggd ur samma källa, **byte-identisk**.

`PRE_TOBIAS_FIRST_PLAYABLE_GATE --place` mot exakt den här filen: **PASS**,
tio undergrindar. Världsmanifestet: **3366 delar** (3317 + 49 boxdörrar),
13 portaler, 33 hästar. Testsviten: **30 specar gröna**.

## Den här är den FÖRSTA hela kandidaten

`…-1e8b207` var halv, och det är därför den ersätts efter tjugo minuter.
Den bar den fysiska utrustningen men saknade locomotion-rättelsen, för
`claude/p0-locomotion-lead-tack-20260911` grenade från samma commit
(`b31a460`) och arbetade parallellt. Den hade alltså fallit på punkt 5 i
Studio med exakt samma orsak som `9b5a570`.

Den här filen är de två grenarna sammanslagna.

| Ur | Vad |
|---|---|
| `50e5ed9` | `Humanoid.RootPart` binds — roten heter `HumanoidRootPart`, `HipHeight` = benhöjden. Det var orsaken till punkt 5-FAIL:en |
| `3ead609` | lektionskortets rubrik och punkter ur språkkatalogen, inte hårdkodad svenska |
| `27e5c2a` | boxfronten delas kring en 1,20 m boxdörr i alla 49 boxfack — hästen kan lämna sin box |
| `494b683` | sadeln och tränset som fysiska saker på boxfronten, hämtade av spelaren |
| `40c18a4` | kollisionen mellan de två: tränset hängde i boxdörrens öppning |

### Sammanslagningen hade en tyst kollision, och den är rättad

Boxdörren tar fackets bortre ände. Utrustningsplatsen räknade sitt läge ur
boxens **mitt**, ±0,84 m — så den bortre punkten hamnade precis i
dörröppningen. Ett träns hängande i den enda vägen ut ur boxen, på alla 33
hästar, och ingen befintlig grind hade sagt något: de två härledningarna
läste samma datafält men räknade var för sig.

Nu räknas läget ur den **täta panelens** utbredning, och
`spelbarhet.spec` mäter varje sak mot de faktiskt byggda `Boxfront`- och
`Boxdörr`-delarna — 66 lägen. Falsifierad: med de gamla talen blir varje
träns rött.

## Vad som fortfarande är öppet

- **Blockerare 2, ledandet.** Rutten är mätt framkomlig och `leda` kräver nu
  att spelaren bär tränset — men hästen **följer inte spelaren**, och `leda`
  har ingen zonkontroll, så steget kan bli sant med henne kvar i boxen.
- **Paritet:** webben har inte den fysiska utrustningshämtningen.
- Allt i `docs/STUDIO-RUNTIME-QA.md` som var otestat i runtime är det
  fortfarande — § 6 (utrustningen) är helt ny och har aldrig körts.

## PLATSEN ÄR BOXFRONTEN, INTE SADELKAMMAREN

Ordern 16:21 pekade mot sadelkammaren. Den enda verifierade platsen i UBRF
där sadlar och träns finns är en annan:

> `references/buildings/stall/KORT.md` § Boxarna från gången:
> *"På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
> benskydd — mycket saker, tätt."* `[ej byggt i spelet ännu]`

`stall-inne-03-sadelkammaren.jpg` visar uttryckligen **inga sadelbockar**,
och `docs/F02-B-INREDNINGSMATRIS.md` har redan fällt sadlar där som
`REFERENCE GAP`. Att bygga dem i det rummet hade varit att hitta på en
UBRF-detalj — vilket ordern själv förbjuder. Sadelkammarens inredning är
orörd. Vill Tobias ha sadelkammaren krävs **ny referensevidens**, inte en
kodändring.

## Tidigare artefakter i kedjan

`…-1e8b207` (halv, se ovan), `…-9b5a570` (CTA:n, föll punkt 5 på
RootPart), `…-efa341e` (föll § 9), `…-67e7716` (föll § 1), `…-0a1b032`.
Alla ligger kvar orörda som historik.

## `.gitattributes`

`*.rbxlx` är märkt binär sedan `…-1e8b207`. Har du en utcheckning med
`core.autocrlf=true`: klona om, eller kör
`git rm --cached -r . && git reset --hard` **innan** du kopierar ut filen,
annars stämmer inte SHA256.
