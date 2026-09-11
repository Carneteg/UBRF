# First Playable — integrationsytan och PR-matrisen

> Bindande styrning på PR #162 (2026-09-11 07:24): stoppa PR-stapling, konsolidera
> till EN ren integrationsgren med `main` som långsiktigt mål, och redovisa varje
> öppen PR som `INTEGRATED`, `SUPERSEDED`, `STILL_REQUIRED` eller `UNRELATED`.

## Vad mätningen visade — och varför konsolideringen är enklare än den såg ut

Ordern utgår från att kedjan `#159 → #154 → #152 → …` måste brytas genom
cherry-pick eller rebase. **Det behövs inte, och det vore sämre.** Mätt:

```
git merge-base --is-ancestor origin/main claude/first-playable-20260910   → SANT
git rev-list --count claude/first-playable-20260910..origin/main          → 0
git rev-list --count origin/main..claude/first-playable-20260910          → 171
```

`main` är alltså redan **förfader** till kandidaten. Kedjan finns bara som
**PR-baspekare**; commitgrafen ligger redan linjärt ovanpå `main`.

Det betyder tre saker:

1. En cherry-pick av "bara det nödvändiga" vore att **skriva om historik som redan
   är korrekt** — och varje omskrivning tappar provenance som granskningen bygger på.
2. Kandidatgrenen **är** den rena integrationsytan. Att skapa en ny gren med ett
   finare namn hade gett en dubblett utan att ändra en enda commit.
3. Konsolideringen är därför **en ändring av PR #162:s bas** från
   `claude/g02-e-camera-wip-20260909` till `main`. Kedjan bryts, beroendena blir
   explicita i en enda yta, och ingenting går förlorat.

Merge mot `main` kan inte ge konflikt: en förfader mergar alltid fast-forward.

## PR-matrisen

Metod: varje öppen PR:s head-SHA testas med `git merge-base --is-ancestor <head>
<kandidat>`. Är den förfader ligger PR:ens innehåll **i** kandidaten. Är den det
inte jämförs de egna commitarna med `git cherry`, som matchar på patch-id och
alltså ser en cherry-pickad ändring även när SHA:n skiljer.

### `INTEGRATED` — innehållet ligger i kandidaten `c5f3b59`

| PR | Gren | Vad |
|---|---|---|
| #159 | `claude/p3-sokvagar-20260909` | verktygens repo-rot ur modulen |
| #158 | `claude/p2-skaparchips-20260909` | 44 px träffytor i karaktärsskaparen |
| #157 | `claude/p2-replaypanel-20260909` | replaypanelen läsbar på telefon |
| #156 | `claude/p2-uppdragsetikett-20260909` | uppdragsetiketten innanför skärmen |
| #154 | `claude/p0-valfard-20260909` | välfärdsspärr, kamerakontrakt, Roblox-paritet |
| #152 | `claude/g02-e-camera-wip-20260909` | G02-E ryttarperspektiv |
| #151 | `claude/g02-d-integration-20260909` | Ridanalys på P0-baslinjen |
| #149 | `chatgpt/p0-input-impulse-part2` | korta ANVÄND-tryck i gångläget |
| #148 | `chatgpt/p0-input-impulse-part1` | one-shot inputimpuls |
| #145 | `chatgpt/p0-touch-repair` | invänta karttransform före touch-nav |
| #143 | `chatgpt/p0-consolidated` | samlad speltestkod och QA |
| #142 | `chatgpt/p0-feel-e2e` | verklig första dag, lugnare styrning |
| #141 | `chatgpt/p0-control-feel` | lugnare styrning till fots och i sadeln |
| #138 | `claude/g02-d-ridanalys` | övningen som data, ritten som post |
| #137 | `chatgpt/ridanalys-feedback` | konstruktiv ridfeedback och replay |
| #135 | `chatgpt/integration-review` | webb–Roblox-baseline |
| #134 | `replit/pr-132-locker-reception-corridor` | skåp- och receptionskorridor |
| #132 | `replit/pr-131-theory-fidelity` | teorisalens interiörbevis |
| #131 | `chatgpt/interior-fidelity-review` | F02-C interiörmaterial |
| #133 | `chatgpt/dual-platform-environment-roles` | miljöansvar och paritet |
| #128 | `claude/g02-c-followup-126` | Roblox-lektionen i klientens loop |

**De här PR:erna kan stängas som integrerade när #162 mergas** — men det är
författarens och Tobias beslut, inte mitt. Jag har inte stängt någon.

### `STILL_REQUIRED` — eget spår, ligger INTE i kandidaten

| PR | Vad | Varför det står kvar |
|---|---|---|
| #116 | Bränntomts Lydia = "henne", produktbeslut med provenance | **Mätt: `PRONOMEN_BESLUT` finns inte i kandidaten och inte i `main`.** I kandidaten faller Lydias pronomen igenom till `REFERENCE_GAP`, precis som före beslutet. PR:en går mot `main` direkt och kan landa oberoende. |
| #129 | Governance: aktivera Roblox-Ugneta efter accepterad läktare | Rör bara `docs/ACTIVE-GATE.md`. Kandidaten har ändrat samma fil i ett annat ärende, så en textkonflikt är möjlig — governance-spåret avgör ordningen. |

### `SUPERSEDED` — arbetet finns, men i en annan form

| PR | Vad | Ersatt av |
|---|---|---|
| #144 | G02-D: slutför Ridanalys och Roblox-paritet | #151 `g02-d-integration`, som är integrerad. #144 bär en egen exportkedja (`tools/ridanalys-canon.mjs`, `replay-core-transport.py`, fyra egna workflows) som kandidaten inte använder; `Replay.luau` finns inte i kandidaten. **Att den är ersatt är min bedömning av innehållet, inte ett produktbeslut** — den bör läsas av någon annan innan den stängs. |
| #140 | P0 QA: tre oberoende speltest | `tools/p0-qa-runner.mjs` finns i kandidaten; `tools/p0-speltest.mjs` och de två workflowsen gör det inte. Samma förbehåll. |
| #147 | P0 #146 del 1/2: regressionstest för kort ANVÄND-tryck | #148 (integrerad) bär inputimpulsen med egna regressionstester. `tools/p0-short-tap-test.mjs` och dess workflow finns inte i kandidaten. Samma förbehåll. |

### `UNRELATED` — rör inte First Playable

Jules-analyserna (#163, #160, #139), bot-genererade refaktorer och testtillägg
(#92, #95, #96, #98, #99, #101, #102, #104, #106, #108, #109, #112, #113, #115,
#118, #120–#124). De står mot `main` eller mot gamla `main`-SHA:n och har ingen
koppling till kandidatens innehåll.

## Vad jag INTE har gjort

- **Ingen PR stängd.** Matrisen är underlag; att stänga är författarens beslut.
- **Ingen merge till `main`.** Tobias har inte satt `PRODUCT_ACCEPTED`.
- **Ingen ny funktionell ändring i konsolideringssteget.** Det här dokumentet är
  hela diffen; koden är oförändrad.
- **Ingen historik omskriven.** Ingen rebase, ingen cherry-pick, ingen force-push.

## Gate-ordningen (bindande från 2026-09-11)

1. P0 säkerhet och grundläggande spelbarhet
2. Topologi/traversal och fysisk världssammanhållning
3. Kärnloopens funktion
4. Fidelity mot verkliga UBRF
5. Polish

Interiörfidelity är alltså **inte** överordnad P0/basic playability, och
läktar-P0 #114 på `main` får inte användas som skäl att blockera att First
Playables P0-/topologifel stängs. Redan verifierade P0-fixar från `main` och
andra grenar ska bevaras i konsolideringen — mätningen ovan visar att de är det,
eftersom `main` i sin helhet ligger under kandidaten.
