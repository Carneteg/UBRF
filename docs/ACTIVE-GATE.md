# Active Gate

Current active implementation: **Sammanhållen produktprovsbaseline — PR #135**

Källleveranser som baselinen är byggd av:

| spår | ägare | PR | SHA |
|---|---|---|---|
| Miljö | **Replit** | #134 | `98736e3` (evidenshead), `0848366` (produkt-SHA) |
| Gameplay | **Claude** | #128 | `f183963` |
| Governance | ChatGPT | #133 | `cf9c5e1` |
| Accepterad bas | — | — | `e65675d` |

Integration: **Claude**
Review: **ChatGPT**
Product acceptance: **Tobias**

Mandatory delivery chain:

> **TILLDELAD BUILDER BYGGER → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Rollfördelningen mellan builders står i `docs/ENVIRONMENT-DELIVERY.md`: Replit
bygger miljön, Claude bygger gameplay och integration. Äldre gate-text som
utpekar Claude som ensam builder gäller inte.

## Current priority

Den sammanhållna baselinen i PR #135 ska bli produktprovbar: en byggd webb och
en deterministisk Roblox-export ur samma miljö- och spelkanon, relevanta
regressioner körda på integrations-SHA:t, och en spelbar Vercel-preview.

Acceptance criteria för nästa gate efter #135 skrivs av ChatGPT, inte av en
builder. Det här dokumentet registrerar vad som är aktivt — det uppfinner inte
nya krav.

Starta inte orelaterat arbete medan baselinen är aktiv.

## Parallellt sanktionerat spår — G02-D

PO-beslut 2026-09-07 15:12 på #135: **G02-D — ridanalys, positiv feedback och
replay**, på egen feature branch `claude/g02-d-ridanalys` (PR #138). Spec:
`docs/RIDANALYS.md` (PR #137 @ `f211617`). Leveransen är en vertikal slice —
20 m volt plus en övergång — och den ska återanvända befintliga modeller, inte
bygga ett parallellt bedömningssystem.

Det här spåret är alltså **inte** orelaterat arbete i den mening stycket ovan
menar: det är beställt av Tobias efter alpha-frysningen, på egen gren, och rör
inte baselinens kärnfiler i #135.

Byggare: **Claude**. Review: **ChatGPT**. Acceptans: **Tobias**. Status och
paritetsredovisning i `docs/G02-D-RIDANALYS-REPLAY.md`.

**Integrationsgren 2026-09-09:** `claude/g02-d-integration-20260909`, utgången
ur #143 @ `87cad71` (senaste P0-integrationen) med `claude/g02-d-ridanalys`
@ `6bc25fd` inmergad. Grenen bär både P0-inputlagret och G02-D:s lifecycle;
ingen fil är ersatt i klump. #137 är kvar som acceptanstracker.

Rutan "Se ritten — frivillig replay: **saknas** på Roblox" i
paritetstabellen är stängd: `HorseCore/Inspelning.luau` och
`client/ReplayController.luau` är byggda, inkopplade i `LektionController`
och `init.client.luau`, och provade genom klientens egen `RenderStepped`.
Schema och övningsversion exporteras till `RidKanon.INSPELNING`, så webbens
`ovningsdef.js` är fortsatt enda källa.

**Ingen självskrivande builder-workflow.** `g02-d-complete-builder.yml`
finns inte på integrationsgrenen och ska inte återinföras: den testade en
syntetiserad källa, inte den committade. Grindarna är `grindar.yml` och
`ugneta.yml` — vanlig read-only CI på det utcheckade commit:et.

## Parallellt sanktionerat spår — First Playable Candidate (#161)

PO-beslut 2026-09-10 i issue #161: **First Playable Candidate**, på egen
feature branch `claude/first-playable-20260910` med draft-PR mot
`claude/ridspel-stall-omnejd-zo2zce`. Beslutet häver vänteläget för #153:s tre
återstående punkter — P1-3b Roblox skötselmoment, P1-3c Roblox varaktig
progression och P2-4b återöppningsbar kontrollhjälp — och slår samman dem med
de godkända fixarna ur #154, #156, #157, #158 och #159 till EN spelbar version.

Den här filen **registrerar** att spåret är aktivt. Den skriver inga
acceptanskriterier: de står i #161 och är Tobias, inte en builders.

Integrationens härledning, verifierad mot remote heads före merge:

| PR | gren | head | relation |
|---|---|---|---|
| #152 | `claude/g02-e-camera-wip-20260909` | `e5af8fc` | integrationsbas |
| #154 | `claude/p0-valfard-20260909` | `88067d3` | 2 commits ovanpå `e5af8fc` |
| #156 | `claude/p2-uppdragsetikett-20260909` | `8b1bc4b` | 1 commit ovanpå `88067d3` |
| #157 | `claude/p2-replaypanel-20260909` | `6097c3b` | 1 commit ovanpå `88067d3` |
| #158 | `claude/p2-skaparchips-20260909` | `d2b6366` | 1 commit ovanpå `88067d3` |
| #159 | `claude/p3-sokvagar-20260909` | `55d38a4` | 1 commit ovanpå `88067d3` |

Riktiga merges med `88067d3` som gemensam förälder. Enda konflikten var
`.github/workflows/grindar.yml`, där #156/#157/#158 var för sig lade till ett
jobb sist i samma steglista; alla tre behölls. Ingen filersättning, ingen
#144-integration, ingen force-push.

Byggare: **Claude**. Review: **ChatGPT**. Acceptans: **Tobias**.
Högsta status en builder får sätta är `READY_FOR_CHATGPT_REVIEW`.

**Ingen merge till main i det här uppdraget.** Kandidaten är den enda version
som därefter ska testas som spel; de små PR:erna ligger kvar som provenance.

## Accepted / merged

### P0 Läktare — issue #81 / PR #114

`PRODUCT_ACCEPTED` av Tobias 2026-09-07 04:25 UTC på
`a1360bcf2a08fdaa469d489f379f44683b526a56`, mergad till main i `e65675d`.
Inte längre aktivt arbete.

Lärdomarna från de underkända försöken står kvar och är **bindande** för allt
kommande arbete som rör rendering, kollision, kamera och avatarhöjd:

1. `v3dFigurKloss` måste använda samma vertikala spelartillstånd som kollision
   och kamera (`o.y` / `VD.pz`), inte hårdkodad Y=0.
2. Review-/debuggeometri, som de gula genomskinliga trappabstraktionerna, ska
   vara dev/debug-only och aldrig synlig i produktvyn.
3. Kanonisk trapp-/däckgeometri hör hemma i den kanoniska site-/världsmodellen,
   inte som en sen runtime-patch.
4. Rendering, kollision, kamera och avatarhöjd ska verifieras tillsammans i den
   faktiska spelarvägen.
5. Webb och Roblox ska dela samma avsikts-/geometrikontrakt i stället för att
   hålla parallella sanningar.

Läktarens produktkrav — gångbar trappa utan teleport, synlig höjdändring,
läsbara steg med tangentbord och touch, ogenomskinligt däck under spelaren,
ingen debuggeometri i produktvy, minst 10 m gångväg, fri passage förbi
domarbåset, låst exteriörgeometri utan verifierad källa — är accepterade och
skyddas nu av `laktartest`. De får inte regrera.

### G02-C / PR #119

`PRODUCT_ACCEPTED` av Tobias och mergad. Issue #84 stängd.

### G02-C follow-up / issue #126 → PR #128

Uppföljningsskulden i #126 är byggd i PR #128 och satt till
`READY_FOR_PRODUCT_ACCEPTANCE` av ChatGPT efter oberoende re-review av
`f183963`. Kvarvarande produktgrind: Tobias Studio-/enhetstest.

## Required builder handshake

En GitHub-mention är inte i sig bevis för att en builder-session tagit emot
uppgiften.

Innan implementation börjar ska tilldelad builder posta i den aktuella PR:en:

`CLAUDE_ACK #<nr> — base/head <SHA> — scope: <avgränsning>`

(motsvarande för Replit). Först efter den kvittensen räknas handoffen som
levererad.

När leveransen är klar ska builder posta:

- exakt HEAD SHA,
- Changed,
- Tested,
- Falsified,
- Not tested,
- Remaining risk,
- human-test requirements,
- `READY_FOR_CHATGPT_REVIEW`.

Ingen merge före ChatGPT-review och Tobias produkttest.

## Vercel

Vercel är den enda UBRF-preview-/deployvägen.

## Separat, ej aktivt

### PR #116 — Lydia-pronomenet

Separat, tekniskt grönt språkbeslut. Lägg inga aktiva implementationscykler på
det om inte Tobias omprioriterar.

## Source-of-truth rule

Om det här dokumentet står i konflikt med en nyare uttrycklig instruktion från
Tobias vinner Tobias, och filen ska uppdateras omedelbart.

Om PR-kommentarer och den här filen säger emot varandra och det inte finns
någon nyare Tobias-instruktion: stoppa implementationen och red ut uppgiften
innan du kodar.
