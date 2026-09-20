# Active Gate

**Aktiv plan: issue #259 — UBRF Roblox Completion Plan, vägen till First Playable.**

| | |
|---|---|
| Aktiv gate | **First Playable closure — de maskinellt körbara resterna** |
| Aktiv gren | `claude/gate2a-first-ride-20260919`, **PR #264** |
| Head | `43f42c3` |
| Bas | `9c1ebeae7337bbfa138016811d9e380aad4ef3eb` (merge av Gate 1A / PR #262) |
| Överordnad plan | issue #259 |
| Builder | **Claude** |
| Review | **ChatGPT** |
| Acceptans | **Tobias** |

Issue #259 är den överordnade produkt- och leveransplanen. `docs/PRODUCT-CANON.md`
är fortfarande produktens högsta källa. Den här filen registrerar vad som är
aktivt — den uppfinner inga krav.

**Den här filen pekade fram till 2026-09-20 ut Gate 0 som aktiv gate.** Det var
inaktuellt: G0 är levererad, och grenen har sedan dess kört sex gates till.
CLAUDE.md kräver att dokumentet uppdateras innan motstridig implementation
fortsätter, och det är vad den här revideringen gör. Allt nedan är knutet till
evidens i PR #264.

## Vägen till First Playable

| Gate | Innehåll | Läge |
|---|---|---|
| **G0** | Gemensam sanning: den här filen, och `tools/kolla-generisk-hast.py` plattformsoberoende | **klar** — `0bf1ef6`; grinden passerar på Windows med separatornormalisering och en vakt mot undantag som inte pekar på någon fil |
| **G1** | Säker interaktionsgrund: rate limiting (#258 P1-2), cleanup- och felvägar | **klar** — `Skopa` grindar tretton fjärranrop med deklarerade tak; merge av PR #262 |
| **G2** | Golden path till uppsittning, provad som en kedja | **klar i allt utom en sträcka** — hela kedjan körd i Studio; ledsträckan stall → ridhus är ännu inte körd i ett svep, se M3 nedan |
| **G3** | Uppsutten ridning och game feel | **mekaniken klar** — skritt 4,35 · trav 9,6 · galopp 16,8 studs/s mätt mot `Gaits`; game feel är Tobias bedömning och är **uppskjuten**, inte godkänd |
| **G4** | Ride First-pedagogik och UI | **klar i det maskinellt mätbara** — coach banner, Ugneta-feedback och `efterForsok` verifierade i runtime |
| **G5** | Roblox runtime och enheter | **delvis** — Studio-QA gjord maskinellt; **fysisk iPad och iPhone uppskjutna av produktbeslut**, inte godkända |
| **G6** | Release candidate | kö |

En implementations-PR åt gången. Små gates. Ingen självacceptans.

## Levererat på den aktiva grenen

Varje rad har evidens i PR #264. Ingen av dem är `PRODUCT_ACCEPTED`.

| Gate | Markör | Kort |
|---|---|---|
| Gate 2A — First Ride | `READY_FOR_CHATGPT_REVIEW` | häst i rörelse utan stallkedjan före |
| Runtime routing | ChatGPT-review klar | två defekter rättade: `MinHast` fanns i två exemplar och hängde varje anropare; en varning som fyrade vid varje uppsittning |
| Lektionskortet och styrningen | `READY_FOR_CHATGPT_REVIEW` | ett kort som syns är inget rörelselås; bara replayen stoppar hästen |
| Full world performance | `DESKTOP_PERFORMANCE_BASELINE_ACCEPTED` | 60 FPS i sex av sju scenarier; ingen tillväxt över 11 min |
| Multi-horse leading | `CHATGPT_MULTI_HORSE_REVIEW_PASS_WITH_LIMITS` | två riktiga klienter, två boxrader, noll överhörning |
| Camera feel | `CAMERA_FEEL_READY_FOR_HUMAN_REVIEW` | mekaniken mätt; känslan **uppskjuten av Tobias** |
| Visuellt paket | `VISUAL_PACK_READY` | preview verifierad mot head; `CHATGPT_VISUAL_PASS` ej utfärdad |
| M1 — lokala grindkedjan | pushad | `PRE_TOBIAS_FIRST_PLAYABLE_GATE: PASS` lokalt efter två verktygsfel |

## Uppskjutet — inte godkänt

Ingen av posterna nedan får läsas som grön.

| Post | Status |
|---|---|
| Tobias kamerakänsla i Studio | `CAMERA_HUMAN_FEEL_REVIEW_DEFERRED_BY_PRODUCT_OWNER` |
| Fysisk iPad och iPhone | `PHYSICAL_DEVICE_DEFERRED` — `TouchControls.luau:614` bär själv noten |
| Om prompter och HUD **syns** | `NOT_TESTED` — `capture_screenshot` ger svart 3D-fält i harnessen |
| Visuell fidelity side-by-side | ligger hos ChatGPT; paketet är klart |
| `PRODUCT_ACCEPTED` | endast Tobias |

## Backlog — inte First Playable

Rörs inte utan färskt bevis att de blockerar något:

- 33 hästriggar simuleras alltid (1 564 oankrade delar),
- `Markkontakt` strålar mot alla hästar två gånger i sekunden,
- `PathfindingService` ger `NoPath` över långa sträckor i den här världen,
- `TavlingskladerService` startas aldrig av någon,
- bomkameran (`Kameralage`, feedbackvinkeln) har ingen anropare i produktionskoden,
- `REFERENCE GAP` i byggnaderna — kräver foto, inte kod.

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
