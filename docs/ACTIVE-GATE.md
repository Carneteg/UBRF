# Active Gate

**Aktiv plan: issue #259 — UBRF Roblox Completion Plan, vägen till First Playable.**

| | |
|---|---|
| Aktiv gate | **Gate 0 — Gemensam sanning** |
| Bas | `ab0d662e67c04a570f959bc1673c419130ba0c06` (merge av PR #257) |
| Teknisk baseline | revisionsrapporten i issue #258 |
| Builder | **Claude** |
| Review | **ChatGPT** |
| Acceptans | **Tobias** |

Issue #259 är den överordnade produkt- och leveransplanen. Den ersätter den
tidigare gate-bilden i den här filen, som pekade på PR #135 och en baseline
från 2026-09-07. Allt som stod här om #135, G02-D, #161, #171 och #244 som
*aktiva* spår är historik och ligger under Historik och backlog nedan.

`docs/PRODUCT-CANON.md` är fortfarande produktens högsta källa. Den här filen
registrerar vad som är aktivt — den uppfinner inga krav.

## Vägen till First Playable

| Gate | Innehåll | Läge |
|---|---|---|
| **G0** | Gemensam sanning: den här filen, och `tools/kolla-generisk-hast.py` plattformsoberoende | **aktiv** |
| G1 | Säker och användbar interaktionsgrund: rate limiting för klientanropade RemoteFunctions (#258 P1-2), cleanup- och felvägar (#258 P2) | kö |
| G2 | Golden path till uppsittning: start → tilldelad häst → tack → synlig utrustning → ledning → ridhus → `RIDE NOW`, provad som en kedja | kö |
| G3 | Uppsutten ridning och game feel: skritt, trav, galopp, broms och yaw på PC och touch; `Gaits` som enda hastighetssanning | kö |
| G4 | Ride First-pedagogik och UI: coach-banner, temafiltrerad Ugneta-feedback, post-ride summary | kö |
| G5 | Roblox runtime och enheter: mänsklig QA i Studio, fysisk iPad och iPhone; #258 S1–S7 | kö |
| G6 | Release candidate: låst commit/place, hela sviten plus den mänskliga checklistan mot samma build | kö |

En implementations-PR åt gången. Små gates. Ingen självacceptans.

## First Playable — vad som ska gå att göra

En ny spelare ska utan utvecklarhjälp klara hela kedjan på **både PC och
iPad**: förstå vilken häst som är hennes, gå fram och interagera utan att
kontrollerna slåss om skärmen, hämta och **synligt bära** sadel och träns,
utrusta hästen och se utrustningen på modellen, leda henne mjukt ur boxen
till ridhuset med tydligt tillstånd, använda `RIDE NOW` på en förberedd häst
utan att solospel kan blockeras av en trasig turordning, rida responsivt på
servervaliderade avsikter i skritt, trav, galopp och inbromsning, sitta av,
och få kort begriplig återkoppling.

Ingen rå felkod, mallsträng, tangentbordsinstruktion på touch eller
blockerande panel får bryta kedjan.

Utomhusridning, hela tävlingsloopen och lång progression ligger **efter**
den här gaten. Den fullständiga definitionen står i #259.

## Icke förhandlingsbara kvalitetskrav

- Servern äger spelstatus, ägarskap, tillåtna övergångar och beständiga värden.
- Klienten skickar avsikt, aldrig betrodd position eller slutstatus.
- Lokal presentation får predikteras för respons, men korrigeras mot serverns sanning.
- Touch är en förstaklassplattform. Kritiska kontroller får inte ligga under
  CoreGui eller kräva tangentbord.
- "Show, don't tell": animation, ljud, hästens kropp och diskret coachning
  före stora HUD-paneler.
- Inga klientägda CFrame-loopar för locomotion, inga deprecated body movers,
  ingen parallell gångarts- eller hastighetssanning.
- Varje rättelse ska ha ett test som **kan bli rött** av den defekt den
  påstår sig stoppa. Studio- och enhetsberoende påståenden märks
  `NOT_TESTED` tills mänsklig runtime-QA finns.

## Claudes ändringsmandat i den här planen

Product Owner har i #259 gett uttryckligt mandat att **ändra, refaktorera,
ersätta eller ta bort** befintlig kod, tester och konfiguration — även
korsmodulärt — när det krävs för att nå First Playable. Att en lösning redan
finns är inte i sig ett skäl att behålla den.

Mandatet omfattar **inte** att merga själv, sätta `PRODUCT_ACCEPTED`, kringgå
CI eller branch protection, ändra sparad spelardata utan explicit
migrationsplan, eller expandera First Playable innan kärnloopen är accepterad.

Vid konflikt gäller: Product Owner-beslut i aktuell arbetsorder →
`docs/PRODUCT-CANON.md` → completion-planen i #259 → verifierat beteende på
`origin/main` → äldre roadmap-, gate- och PR-text.

## Required builder handshake

En GitHub-mention är inte i sig bevis för att en builder-session tagit emot
uppgiften. Innan implementation börjar ska tilldelad builder posta:

`CLAUDE_ACK #<nr> — base/head <SHA> — scope: <avgränsning>`

(motsvarande för Replit). Först efter den kvittensen räknas handoffen som
levererad.

När leveransen är klar ska builder posta exakt HEAD-SHA, Changed, Tested,
Falsified, Not tested, Remaining risk, human-test requirements och
`READY_FOR_CHATGPT_REVIEW`.

Ingen merge före ChatGPT-review och Tobias produkttest.

## Bindande lärdomar som överlever gateskiftet

Från den accepterade läktaren (#81 / PR #114). De gäller **allt** kommande
arbete som rör rendering, kollision, kamera och avatarhöjd:

1. `v3dFigurKloss` måste använda samma vertikala spelartillstånd som kollision
   och kamera (`o.y` / `VD.pz`), inte hårdkodad Y=0.
2. Review- och debuggeometri ska vara dev-only och aldrig synlig i produktvyn.
3. Kanonisk trapp- och däckgeometri hör hemma i den kanoniska
   site-/världsmodellen, inte som en sen runtime-patch.
4. Rendering, kollision, kamera och avatarhöjd verifieras tillsammans i den
   faktiska spelarvägen.
5. Webb och Roblox delar samma avsikts- och geometrikontrakt i stället för att
   hålla parallella sanningar.

Läktarens produktkrav är accepterade och skyddas av `laktartest`. De får inte
regrera.

## Historik och backlog

Inget av det här är aktiv gate. Raderna finns kvar för att spåren ska gå att
följa, inte för att de ska plockas upp utan ett nytt Tobias-beslut.

### Landat på `main`

| Spår | PR | Not |
|---|---|---|
| Tävlingskläder Fas A och Fas B (#248) | #250, #257 | Fas B `CHATGPT_CODE_REVIEW_PASS` på `9328365`, mergad i `ab0d662` |
| Coach Banner (#244) | #245 | Nederpanelen riven; hålls av `tools/kolla-nederpanel.py` |
| Touch-interaktion och ridavsikt (#246, #17) | #243, #249, #251 | |
| Serverauktoritativ ridinput (#233) | #238, #241, #242 | Gångarten är serverns; `StateSync` bär bara fart |
| Bänkens självprov fail closed (#252 del A/B) | #255 | |
| Studio- och Rojo-integritet (#171) | — | `UBRFBuild.luau` och `Integritet.luau` finns på `main`; policy i `docs/STUDIO-PLACE-INTEGRITY.md` |
| G02-D ridanalys och replay | — | `ReplayController.luau` och `Inspelning.luau` finns på `main` |

### Öppna spår som inte är aktiv gate

| Spår | PR | Läge |
|---|---|---|
| UgnetaController Ride First (#234) | **#253**, draft | Öppen draft från `2026-09-19 06:31`, före `ab0d662`. **Rör `docs/ACTIVE-GATE.md`** och registrerade sig själv här som aktivt spår; den registreringen är ersatt av den här filen. Innehållet hör tematiskt till **Gate 4**. |
| Runtime-grind i riktig motor (#252 del C) | **#256**, draft | Öppen draft från `2026-09-19 07:51`, före `ab0d662`. Hör tematiskt till **Gate 5**. |
| First Playable Candidate (#161) | — | Målbilden är uppgången i #259. Gren `claude/first-playable-20260910`. |
| Produktprovsbaseline (#135) och G02-D-integration | #138, #151 m.fl. | Tidigare aktiv gate-bild. Ersatt av #259. |
| Lydia-pronomenet | #116 | Separat språkbeslut. Inga aktiva cykler utan omprioritering. |
| Äldre `chatgpt/`- och `replit/`-drafts | #132–#149 m.fl. | Ej triagerade mot #259. |

Både #253 och #256 är äldre än basen och kan inte rebasas in utan ett
uttryckligt beslut om var i gate-ordningen de hör hemma. Att stänga, rebasa
eller lyfta in dem som egna gates är Tobias beslut, inte en builders.

## Vercel

Vercel är den enda UBRF-preview- och deployvägen.

## Source-of-truth rule

Står den här filen i konflikt med en nyare uttrycklig instruktion från Tobias
vinner Tobias, och filen ska uppdateras omedelbart.

Säger PR-kommentarer och den här filen emot varandra utan att det finns någon
nyare Tobias-instruktion: stoppa implementationen och red ut uppgiften innan
du kodar.
