# Gate 01 — Riding Feel

Status: ACTIVE
Owner: Tobias (Product Owner)
Game direction/review: ChatGPT
Implementation: Claude
Target: webbversionen i `src/`, med Roblox som målplattform

## Varför den här gaten finns

UBRF-spelets kärna är hästen. Om det inte är roligt och naturligt att rida spelar det ingen roll hur mycket innehåll, kunskap eller miljö som byggs runtomkring.

Den här gaten ska därför stängas innan större nya gameplayfunktioner läggs till.

Målet är inte maximal realism i varje fysikdetalj. Målet är en trovärdig, mjuk, begriplig och tillfredsställande ridkänsla som samtidigt bär spelets utbildningsidé.

Spelaren ska känna:

- att hon rider en häst, inte styr ett fordon,
- att små hjälper ger små reaktioner och större hjälper ger större reaktioner,
- att gångarter känns olika,
- att hästen har massa, riktning, rytm och kropp,
- att kamera och ryttare följer rörelsen utan att slåss mot spelaren,
- att samma grundbeteende fungerar på tangentbord, mobil och surfplatta.

## Scope

I scope:

- ridinput,
- styrning,
- acceleration/deceleration som påverkar känslan,
- svängradie och riktningsrespons,
- gångartsfas och markkontakt,
- hästens visuella kroppsrörelse i sväng,
- ryttarens visuella respons,
- ridkamera,
- kollisioner som direkt påverkar ridkänslan,
- desktop/touch-paritet,
- mätning och test av ovanstående.

Inte i scope:

- nya stallsysslor,
- nya tävlingstyper,
- nya områden,
- fler hästraser,
- ny progression,
- ny ekonomi,
- stor omskrivning av WebGL-motorn,
- portning till Roblox i denna gate.

## Senior game-dev diagnosis

### P0 — touchjoysticken är inte analog i själva ridningen

`src/mobil.js` skapar `IN.joy={x,y,styrka}` och beskriver joysticken som analog. Men `IN.joy` används inte av ridinputen i `src/game.js`; ridningen får i stället syntetiska W/A/S/D-events när joystickens axlar passerar trösklar.

Resultatet är att touch visuellt ser analog ut men ridresponsen fortfarande blir tröskelstyrd/digital.

Detta är en blockerande feel-bugg.

Krav:

- touchens X/Y/magnitude ska mata ridinputen kontinuerligt,
- den ska översättas till hästhjälper, inte direkt till teleport/fart,
- vertikal axel ska påverka skänkel/avlastning gradvis,
- horisontell axel ska påverka styrhjälpen gradvis,
- tangentbordet ska fortsätta fungera som digital källa genom samma normaliserade ridinputlager.

### P0 — svängmodellen blir för aggressiv i hög fart

Nuvarande `stegaRitt()` räknar i praktiken yaw rate som styrinput multiplicerad med ett värde som växer med tempo.

Det gör att hästen kan rotera snabbare i radianer per sekund när farten ökar. Det ger för snäva, fordonslika kurvor och gör att spelaren kan "vika" hästen genom en sväng i stället för att rida en båge.

Roblox-spårets data har redan en bättre designidé: svarvheten ska minska per gångart när farten ökar. Webbversionens gameplay ska följa samma princip, inte nödvändigtvis samma exakta implementation.

Krav:

- snabbare gångart ska ge större praktisk svängradie,
- styrning ska uttryckas som önskad kurvatur/svängintention snarare än "mer fart = mer yaw",
- små styrutslag ska ge breda bågar,
- full styrning får vara tydlig men inte ge arcade-pivot,
- inga in-place-turns när hästen är i rörelse.

Rekommenderad riktning:

- normaliserad steering axis `[-1..1]`,
- input curve med bättre precision nära mitten,
- smoothed desired steering/curvature,
- gait/speed-dependent max curvature,
- kritiskt dämpad eller exponentiell utjämning som är `dt`-baserad.

Undvik att stapla specialfall per häst. Grundmodellen ska vara gemensam och hästdata ska bara modifiera den inom rimliga intervall.

### P0 — gånganimationen är inte tillräckligt låst till faktisk förflyttning

`G.gaitFas` avanceras i dag från en tidsfrekvens multiplicerad med tempo. Det är bättre än en helt fast animation, men det är fortfarande inte verkligt distanslåst.

Konsekvensen kan bli att hovarna ser ut att glida, att kroppens bob och markförflyttningen inte riktigt är samma rörelse och att övergångar mellan gångarter känns syntetiska.

Krav:

- fasen ska i första hand drivas av faktisk markförflyttning/tempo och gångartens effektiva steglängd/cykellängd,
- samma färdsträcka i samma gångart ska ge stabil och förutsägbar hovtakt,
- gångartsbyte ska fasas utan synligt hopp eller omstart av benen,
- stillastående häst får inte fortsätta "gå på stället" genom fasdrift.

### P1 — hästkroppen saknar egentlig svängrespons

`src/scen3d.js` har vertikal bob och galoppvaggning, men kroppen reagerar inte tydligt på den faktiska svängen. Det gör att positionen svänger medan kroppen visuellt ser mer neutral ut än den borde.

Krav:

- lägg till subtil, smoothed turn lean/body response från faktisk svänghastighet och tempo,
- lean ska vara visuellt trovärdig, inte motorcykelartad,
- låg fart = nästan ingen lean,
- trav/galopp = tydligare men kontrollerad lean,
- riktning och kropp får aldrig kännas frikopplade.

En bra signal är centripetal belastning (`speed * yawRate` eller motsvarande kurvaturform), inte rå knappinput.

### P1 — ryttaren behöver svara på hästens rörelse, inte bara kontrollvärden

Ryttaren har redan sits, lättridning och hopprespons. Det är bra. Men ridkänslan tjänar på små inertiala reaktioner kopplade till gångart, acceleration och sväng.

Krav:

- behåll befintlig pedagogisk sitslogik,
- lägg endast subtil sekundär rörelse,
- ryttarens bäcken/överkropp ska visuellt följa hästens rytm,
- acceleration/inbromsning får ge liten kroppsförskjutning,
- sväng får ge liten balansrespons,
- ingen överdriven camera-shake- eller ragdollkänsla.

### P1 — kamera ska filtrera hästens rörelse, inte kopiera den

Kameran är redan `dt`-mjukad, vilket är rätt. Men den bygger sitt mål direkt från aktuell hästriktning och använder hårda rumsklampar efter smoothing.

I snabba kursändringar och nära väggar kan det fortfarande ge en kamera som dras runt mer abrupt än hästkroppen upplevs göra.

Krav:

- kamera-position och look target ska ha separata mjuka svar,
- kameran ska följa riktningen med lätt fördröjning, inte kännas fastsvetsad,
- look-ahead ska ligga i färdriktningen,
- väggundvikande får inte ge synliga hopp,
- kameran ska prioritera läsbarhet av vägen framför hästen,
- minimera vertikal bob i kameran; spelaren ska se hästens rörelse, inte bli åksjuk.

Behåll befintligt stöd för olika skärmformat.

### P1 — väggresponsen är delvis frame-rate dependent

När hästen klampar mot ridhusgränsen används fast lerp-faktor per bildruta för riktningskorrigering. Det innebär olika effektiv respons vid 30, 60 och 120 FPS.

Krav:

- all movement smoothing/collision steering ska vara `dt`-baserad,
- mot vägg ska hästen hellre glida längs gränsen än snappa, vibrera eller fastna,
- samma scenario ska kännas i stort sett likadant vid 30 och 60 FPS.

## Target feel

Spelet ska efter Gate 01 kunna klara följande utan att spelaren slåss mot kontrollerna:

1. Rida rakt och göra små linjekorrigeringar.
2. Rida ett helt fyrkantsspår utan kamera- eller styrjitter.
3. Rida hörn som bågar, inte som 90-graders pivotar.
4. Rida en 20 m volt i trav med kontrollerad, delvis styrinput.
5. Göra en mindre volt i skritt utan att kroppen ser ut som ett roterande fordon.
6. Gå skritt → trav → galopp → trav → skritt med läsbara övergångar.
7. Släppa styrningen och få en mjuk återgång mot neutral.
8. Göra samma sak på touch med 25 %, 50 % och 100 % joystickutslag och få tre tydligt olika resultat.

## Input contract

Claude ska skapa/behålla ett tydligt normaliserat ridinputlager.

Önskad konceptuell output per frame:

- `forwardAid` / skänkelintention,
- `reinAid` / tygelintention,
- `seatAid`,
- `steeringAxis [-1..1]`,
- övriga diskreta ridhandlingar.

Keyboard och touch får ha olika rå input, men efter detta lager ska ridmodellen inte behöva veta vilken enhet som används.

Touch ska inte reduceras till syntetiska digitala A/D/W/S innan ridmodellen får värdena.

## Steering contract

Följande egenskaper måste gälla:

- input nära 0 har hög precision,
- 25 % < 50 % < 100 % styrning i faktisk kurvatur,
- svängrespons byggs upp och släpper mjukt,
- högre fart ger inte mindre svängradie än lägre fart vid motsvarande input,
- full styrning i galopp får inte se ut som arcade powerslide,
- `dt` ska påverka integration, inte gameplayresultat.

Exakta konstanter får Claude trimma genom testning. Optimera först för feel, därefter för enhetliga siffror.

## Animation contract

- gångartsfas ska följa markförflyttningen,
- hovkontakt och förflyttning ska visuellt stämma,
- bob, ben och kropp ska använda samma fasgrund,
- övergångar ska blendas/continuera utan synlig fasreset,
- svänglean beräknas separat från gångartsbob,
- rider motion läggs ovanpå, inte i stället för, den pedagogiska sitslogiken.

## Camera contract

Kameran ska ge känslan "jag rider framåt" och inte "jag kontrollerar en kamera som följer ett objekt".

Prioritet:

1. vägen framåt är läsbar,
2. hästen/ryttaren är stabila i kompositionen,
3. svängar känns mjuka,
4. väggar bryter inte kameran,
5. olika skärmformat fungerar,
6. ingen onödig shake.

## Performance / frame independence

Gate 01 får inte lösas genom mer rendering eller tunga system.

- behåll enkel uppdateringsmodell,
- använd `dt`-baserade filter,
- inga nya stora dependencies,
- ingen physics engine,
- ingen rewrite av WebGL,
- inga per-frame allocationer i hot paths om de lätt kan undvikas.

## Roblox portability

Webben är prototypen, Roblox är destinationen.

För varje ny gameplayparameter ska Claude fråga: kan denna översättas till Roblox utan att designen uppfinns igen?

Bra kandidater att hålla motoroberoende:

- steering curve,
- gait-dependent turn limits,
- acceleration response,
- animation phase rules,
- lean response,
- camera tuning targets.

WebGL-specifik kod ska bara stå för visningen av dessa värden.

## Test matrix

Claude ska minst testa:

### Desktop
- 1280×800, keyboard, 60 FPS normalt.
- Rakt spår, hörn, 20 m volt, gångartsövergångar.

### Mobile
- ungefär 390×844 porträtt, touch.
- Joystick 25 %, 50 %, 100 %.
- Små korrigeringar åt båda håll.
- Full lektion ska fortfarande gå att slutföra.

### Tablet
- ungefär 1024×768 landscape, touch.
- Samma ridövningar.

### Low frame rate
- simulera/throttla cirka 30 FPS.
- jämför styrrespons, väggrespons och kamera mot 60 FPS.

## Acceptance criteria — blockerande

Gate 01 får inte markeras klar förrän alla är uppfyllda:

- [ ] `IN.joy` eller motsvarande analog data används kontinuerligt i ridinputen på touch.
- [ ] 25/50/100 % joystick ger mätbart och visuellt olika styrrespons.
- [ ] keyboard och touch går genom samma normaliserade ridinputkontrakt.
- [ ] svängradien ökar i praktiken med fart/gångart vid jämförbar input.
- [ ] inga synliga pivots/powerslides i trav eller galopp.
- [ ] gångartsfas är kopplad till faktisk förflyttning/effektiv steglängd.
- [ ] hästen har smoothed visuell turn lean från faktisk rörelse.
- [ ] ryttaren följer hästen subtilt utan att pedagogisk sitslogik försvinner.
- [ ] kamera känns stabil i raksträcka, volt och hörn.
- [ ] kameran hoppar inte synligt vid väggundvikande.
- [ ] väggkollision/steering correction är frame-rate independent.
- [ ] 30 och 60 FPS ger jämförbar styrkänsla.
- [ ] befintlig första lektion går att spela från start till resultat.
- [ ] inga nya konsolfel.
- [ ] inga nya features utanför Gate 01.

## Mätbevis som Claude ska lämna

Skapa efter implementation:

`audits/GATE-01-RIDING-FEEL-RESULT.md`

Den ska minst innehålla:

1. ändrade filer,
2. root causes som faktiskt löstes,
3. före/efter-beskrivning,
4. hur analog touch verifierades,
5. enkel tabell med styrrespons/uppskattad svängradie eller kurvatur för minst walk/trot/canter och flera inputnivåer,
6. testresultat desktop/mobile/tablet,
7. 30 vs 60 FPS-resultat,
8. kvarvarande begränsningar,
9. exakt commit-SHA som ska reviewas av ChatGPT.

## Handoff protocol

Claude får implementera Gate 01 och använda subagents för analys/test, men ska inte själv stänga gaten.

När implementation och audit är klara:

1. Claude committar.
2. Claude skriver resultatfilen ovan.
3. Arbetet lämnas till ChatGPT för senior gameplay review.
4. ChatGPT kontrollerar diff, mätresultat och att implementationen följer Product Canon.
5. Tobias avgör slutligen om känslan är tillräckligt bra.

Om Gate 01 inte känns bra trots att checklistan är grön ska den inte stängas. Feel vinner över checkboxar.

## Definition of done i en mening

**En ny spelare ska inom 30 sekunder kunna börja rida och känna att hästen svarar mjukt, begripligt och levande — och en erfaren hästperson ska inte omedelbart uppleva styrningen som ett fordon med hästutseende.**
