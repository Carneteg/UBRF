# Slutspeltest — samlad checklista (#266 A2)

Status: LÅST KANDIDAT för Tobias fysiska slutprov, 2026-09-28 — **omlåst efter D2a** (clear round-ritten), samma dag. Ingenting här är
godkänt; varje rad står som NOT_TESTED tills Tobias fyller i den.
Beslut: Tobias «Do A» på [NEXT_PACKAGE_RECOMMENDATION_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865193035).

## Kandidaten

| | |
|---|---|
| Gren | `codex/circle-lesson-20260926` |
| Kodhuvud vid låsning | D2a-commiten på grenen (se leveransrapporten i #266); första låsningen var `19df5e6` |
| Byggidentitet (`kallhash`) | `c9556e93b2752beaf9680ee05307769c7d1c55c6c3db4b5e0788467d93940d40` ur 106 mappade filer (105 skript, 1 modell), beräknad med `tools/bygg-identitet.py` (tidigare låsning: `e23198df4614…`) |
| Kontroll i spelet | byggidentiteten i spelets diagnostik ska visa **`c9556e93b275`**. Visar den något annat är det inte den här kandidaten — avbryt och säg till. |
| Bas | `main` `7922d70` (#264) |

Varje ändring av en mappad Roblox-källa efter låsningen ger en ny `kallhash`
och gör låsningen ogiltig; dokumentändringar gör det inte.

**Om «spec written, not run» i äldre kontrakt:** de lokala proven i varje
kontrakt är sedan kontrollpunkt R1 (2026-09-27) körda och gröna i
`roblox/tests/kor.sh` (102 provfiler). Det som står kvar nedan är det som
bänken inte kan visa: motor, rendering, riktig input, nätverk, DataStore,
fysiska enheter och känsla.

## Så fylls den i

Spela PC först, sedan fysisk iPad och iPhone (separat från emulator). Per rad:
**PASS**, **FAIL** eller **NOTE** i kolumnen för respektive enhet, och en kort
anteckning vid FAIL/NOTE. Raderna står i den ordning du möter dem i spelet.

| Kolumn | Betyder |
|---|---|
| PC | tangentbord och mus |
| iPad / iPhone | fysisk enhet, riktiga fingrar |

## 0. Före start

| # | Kontroll | PC | iPad | iPhone |
|---|---|---|---|---|
| 0.1 | Byggidentiteten visar `c9556e93b275` | | | |
| 0.2 | Språk: spela en gång på svenska; byt till engelska minst i en lektion och vid ett slutkort | | | |

## 1. Spawn, stall och port

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 1.1 | Porten: raden följer vad motorn visar; X och klick på båda sidor om gränsen; ett dörrbyte; passage (R4/R5) | | | |
| 1.2 | Norra stallentrén: den inre ytan följer dörrbladet — stängd ser rätt ut, öppen ger synlig passage, kamera och spelare syns genom öppningen (DOOR-VISUAL) | | | |
| 1.3 | Närområdets lista: fler handlingar än rader bläddrar; tangenterna följer raderna; «Leda till ridhuset» tar bara en ledig rad och står sist, också på en ofullständig sista sida (närområdet, alternativ 3) | | | |

## 2. Skötsel och utrustning

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 2.1 | Skötselminnet: «Vad du gjort själv» i «?»-hjälpen visas och stämmer efter att du hälsat, visiterat, ryktat och gjort hovarna (CARE-MEMORY) | | | |
| 2.2 | Fel sadel/träns: vägledningen visas och «Lämna tillbaka X:s sadel» fungerar, också efter ett karaktärsbyte (EQUIPMENT-GUIDANCE) | | | |
| 2.3 | Skötselns fråga och rättelsen samtidigt i närområdet: inget trängs undan, allt nås (EQUIPMENT-GUIDANCE) | | | |

## 3. Leda till ridhuset

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 3.1 | Ledningslektionen: start, motorns riktiga navigation och dörrar, framme i ridhuset (LEADING-LESSON) | | | |
| 3.2 | En öppen skötselfråga döljer ingången; död och att lämna spelet under ledning (LEADING-LESSON) | | | |
| 3.3 | Ledningens fall: gång, stopp, sväng, passage genom ledaren (R4/R5) | | | |
| 3.4 | Ledningsminnet: « · klarad» och «Du har lett henne hela vägen förut» efter en riktig återinloggning (LEADING-MEMORY) | | | |

## 4. Uppsittning och fri träning

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 4.1 | Hela vägen: spawn → skötsel → ledning → ridhus 5/5 → uppsittning (R4/R5) | | | |
| 4.2 | Kortet vid uppsittning säger «Börja fri träning – rundor på 22 s» och får plats på knappen (FREE-PRACTICE) | | | |
| 4.3 | En runda: rubriken «Runda 1 – tiden (22 s) är slut»; «Se ritten» öppnar just den rundan (FREE-PRACTICE) | | | |
| 4.4 | Efter Avsluta i fri ridning: «Fri träning med återspelning» leder tillbaka till passet; får plats (FREE-PRACTICE) | | | |
| 4.5 | Begriper man skillnaden mellan fri träning och lektionerna med uppgift? (FREE-PRACTICE, Tobias bedömning) | | | |

## 5. Ugneta och lektionsvalet

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 5.1 | Lektionsmenyn: grupper, alla lektioner nås bredvid 0–3 kortknappar; « · klarad» och «förslag» syns rätt (LESSON-MEMORY) | | | |
| 5.2 | Ugneta vänder sig mjukt mot ryttaren; ser naturligt ut (INSTRUCTOR-GAZE) | | | |
| 5.3 | Starthälsningen syns ~6 s vid start/omstart och aldrig igen för samma försök (INSTRUCTOR-START) | | | |
| 5.4 | «Text»-knappen: Normal/Färre/Inga och Detaljerad/Kort ändrar det som ska ändras; fungerar efter respawn (INSTRUCTOR-TEXT-CONTROLS) | | | |
| 5.5 | Slutkortet: EN sammanfattning ur försöket + ETT nästa steg; läsbart och får plats på touch (LESSON-FEEDBACK) | | | |
| 5.6 | Lektionsminnet finns kvar efter en riktig återinloggning (LESSON-MEMORY, INFRA-1) | | | |

## 6. Lektionerna

Per lektion: hitta Start, rid uppgiften, förstå återkopplingen, Prova igen,
Avsluta. Därtill de särskilda raderna.

| # | Lektion — kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 6.1 | **Volt** — ett varv längs bandet klaras (CIRCLE-LESSON) | | | |
| 6.2 | Volt — hästen går fri från väggarna runt voltens bana (CIRCLE-LESSON, oförmätt) | | | |
| 6.3 | Volt — «Närmare linjen än förra volten …» efter ett bättre andra varv; texten får plats; känns det uppmuntrande? (CIRCLE-COMPARISON) | | | |
| 6.4 | Volt — glid medvetet >4 m utåt resp. inåt: rätt råd («Ni gled lite utåt …» / «Ni kom lite för nära mitten …»); hjälper det nästa varv? (CIRCLE-LINE-ADVICE) | | | |
| 6.5 | **Halt vid X** — halt, skritt, halt i ringen vid X klaras (HALT-LESSON) | | | |
| 6.6 | Halt — «Närmare X än förra haltet …» efter ett närmare halt (HALT-COMPARISON) | | | |
| 6.7 | **Jämn skritt** — klaras; den valfria raden (W/spaken) kommer vid rätt tillfälle och är läsbar; hjälper den? (TEMPO-LESSON, TEMPO-COACHING) | | | |
| 6.8 | **Övergångar** — trav vid T1, skritt vid T2 klaras (TRANSITION-LESSON) | | | |
| 6.9 | Övergångar — trava medvetet för tidigt resp. för sent: rätt råd om när (TRANSITION-TIMING-ADVICE) | | | |
| 6.10 | **Galoppfattning vid K** — går det att få galopp i vanligt spel (uthållighetstaket)? klaras; galoppsidan bedöms inte och det sägs (CANTER-DEPARTURE) | | | |
| 6.11 | Galopp — för tidigt/för sent vid K ger rätt råd (CANTER-TIMING-ADVICE) | | | |
| 6.12 | **Mittlinjen och diagonalen** — klaras; långa SV/EN-etiketter radbryts rätt (RIDING-PATH) | | | |
| 6.13 | Mittlinje/diagonal — «Rid utan streck»: räcker två ringar från sadeln? är det roligt? «Visa vägen» tillbaka (ROUTE-LESS-GUIDANCE) | | | |
| 6.14 | **Serpentin** — tre bågar klaras; korsningarna av mittlinjen räknas i riktigt spel (SERPENTINE) | | | |
| 6.15 | **Halvvolt** — klaras (HALF-CIRCLE-LESSON) | | | |
| 6.16 | Halvvolt — «Rid utan strecken längs spåret»: går inridningen längs spåret att följa utan linje (korridor 1,5 m)? (HALF-CIRCLE-LESS-GUIDANCE) | | | |
| 6.17 | **Genom hörnet** — klaras (CORNER-LESSON) | | | |
| 6.18 | Hörn — «Rid med bara bågen och ringarna»: räcker det från sadeln (korridor 1,2 m)? (CORNER-LESS-GUIDANCE) | | | |
| 6.19 | **Bom på marken** — rakt över bommen i skritt klaras (GROUND-POLE-LESSON) | | | |
| 6.20 | Bom — «Rid bara efter bommen och märkena»: räcker bommen och märkena; förstår man «Börja lite längre bak» utan ritat djup? (GROUND-POLE-LESS-GUIDANCE) | | | |
| 6.21 | **Clear round (träning)** — hittas under Ridvägar; «Starta ritten» ger startsignal; start- och mållinjen syns; texten visar nästa hinder (nummer, färg, riktning) (D2-CLEAR-ROUND-DAY) | | | |
| 6.22 | Clear round — går blått 0,68 m och rött 0,52 m att hoppa i riktigt spel, åt båda hållen enligt banan? (hoppfysiken, B4) | | | |
| 6.23 | Clear round — resultatkortet: «Inga observerade fel …», förenklad bedömning och «Träningsbana»; aldrig «felfri», ingen rosett; omstart bara efter fel i försök 1 (D2-CLEAR-ROUND-DAY) | | | |
| 6.24 | Clear round — en utbrytning, fel väg och 45 s/180 s ger begripliga besked (D2-CLEAR-ROUND-DAY) | | | |
| 6.25 | Clear round — sitt av mitt i banan, sitt upp igen och öppna clear round: «Förra clear round-ritten avbröts …» syns och försvinner vid ny start (D2-CLEAR-ROUND-DAY R1) | | | |

## 7. Avsittning, layout och återkomst

| # | Kontroll (källa) | PC | iPad | iPhone |
|---|---|---|---|---|
| 7.1 | Avsittning: normal, hopp och fall (R4/R5) | | | |
| 7.2 | Panelen i desktop, kompakt och vanlig layout, med hjälpen öppen och lång SV/EN-text (R4/R5) | | | |
| 7.3 | Respawn och ett tappat gränssnitt: Ugneta, text-inställningar och lektionen kommer tillbaka rätt (INSTRUCTOR-START, TEXT-CONTROLS) | | | |
| 7.4 | Framsteg och kvitton finns kvar efter en riktig återanslutning (INFRA-1) | | | |

## 8. Känsla — Tobias bedömning

| # | Fråga (källa) | Svar |
|---|---|---|
| 8.1 | Känns hästen levande? (B1) | |
| 8.2 | Leder ett råd till ett bättre försök? (C1) | |
| 8.3 | Är jämförelserna («närmare …») uppmuntrande, inte tjatiga? (CIRCLE/HALT-COMPARISON) | |
| 8.4 | Är «mindre vägvisning» en rolig egen utmaning? (C3) | |
| 8.5 | «Jag förstår min häst, jag märker att jag blir bättre och jag vill rida en gång till» — stämmer det? (#266 mål) | |

## Spårbarhet: kontrakt → rader

| Kontrakt | Rader |
|---|---|
| CANTER-DEPARTURE-LESSON | 6.10 |
| CANTER-TIMING-ADVICE | 6.11 |
| CARE-MEMORY | 2.1 |
| CIRCLE-COMPARISON | 6.3, 8.3 |
| CIRCLE-LESSON | 6.1, 6.2 |
| CIRCLE-LINE-ADVICE | 6.4 |
| CORNER-LESS-GUIDANCE | 6.18, 8.4 |
| CORNER-LESSON | 6.17 |
| DOOR-VISUAL | 1.2 |
| EQUIPMENT-GUIDANCE | 2.2, 2.3 |
| FREE-PRACTICE-FRAMING | 4.2–4.5 |
| GROUND-POLE-LESS-GUIDANCE | 6.20, 8.4 |
| GROUND-POLE-LESSON | 6.19 |
| HALF-CIRCLE-LESS-GUIDANCE | 6.16, 8.4 |
| HALF-CIRCLE-LESSON | 6.15 |
| HALT-COMPARISON | 6.6, 8.3 |
| HALT-LESSON | 6.5 |
| INSTRUCTOR-GAZE | 5.2 |
| INSTRUCTOR-START | 5.3, 7.3 |
| INSTRUCTOR-TEXT-CONTROLS | 5.4, 7.3 |
| LEADING-LESSON | 3.1, 3.2 |
| LEADING-MEMORY | 3.4 |
| LESSON-FEEDBACK | 5.5 |
| LESSON-MEMORY | 5.1, 5.6 |
| RIDING-PATH-LESSON | 6.12 |
| ROUTE-LESS-GUIDANCE | 6.13, 8.4 |
| SERPENTINE-LESSON | 6.14 |
| TEMPO-COACHING | 6.7 |
| TEMPO-LESSON | 6.7 |
| TRANSITION-LESSON | 6.8 |
| TRANSITION-TIMING-ADVICE | 6.9 |
| D2-CLEAR-ROUND-DAY | 6.21–6.25 |
| Närområdet, alternativ 3 (#266 R1) | 1.3 |
| R4/R5 (`ecb2f2e`) | 1.1, 3.3, 4.1, 7.1, 7.2 |
| INFRA-1 | 5.6, 7.4 |
| B1 / C1 / #266 mål | 8.1, 8.2, 8.5 |

Inte med, eftersom inget är byggt att pröva: D2–D5, F3, hus/byggnader,
utrustningsraderna, HRAG, B2 och B4 (`EJ_PÅBÖRJAD` i leveransmatrisen).
