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
