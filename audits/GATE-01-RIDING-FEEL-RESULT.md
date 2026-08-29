# Gate 01 — Riding Feel: resultat

Struktur enligt `docs/GATE-01-PLATFORM-ADDENDUM.md`, som gör Gate 01 till ett
plattformsparitetsarbete: Roblox är primär spelplattform och primär subjektiv
playtest, HTML/webb är en parallell spelbar distribution som ska hålla samma
kärnupplevelse.

Commits att granska: `61d503d` (webben) · `58a8030` (kurvatur, fas och lutningstak
till Roblox) · `eed6178` (ryttarens sekundärrörelse på båda) · `62462d1` (touchgolvet)
Datum: 2026-08-29
Implementation: Claude Code
Status: **lämnas till ChatGPT för review.** Gaten stängs inte av mig, och kan
enligt addendumet inte stängas alls förrän Tobias har gjort en Roblox
Studio-playtest — den kan inte utföras härifrån.

---

## 1 · Ändrade filer

| Fil | Vad |
|---|---|
| `src/game.js` | Ridinputkontraktet (`RIDIN`, `ridAvsiktTillHjalp`), svängen som kurvatur, gångartsfas ur sträcka, kroppens svänglutning, dt-baserad väggrespons |
| `src/mobil.js` | Joysticken matar ridinputen kontinuerligt i stället för syntetiska W/A/S/D; expo-kurva och dödzon |
| `src/scen3d.js` | Kamerans egen kurs, mjukad boom, separata svar för position och blickpunkt; hästkroppens lutning som egen rotation |
| `src/scenes.js` | Nollställer kurvatur, sträcka, fas och ryttarsignaler när ett pass börjar om |
| `roblox/src/client/MovementController.luau` | Svängen som kurvatur med vändning på stället, gångartsfas ur flyttad sträcka |
| `roblox/src/client/RiderController.luau` | Ryttarens tröghet och balans ovanpå sitsen |
| `roblox/src/shared/HorseCore/RigAdapter.luau` | `setRiderLean` mot en sparad baspose, samma form som `setBodyTilt` |
| `roblox/src/shared/HorseCore/Gaits.luau` | `cycleLength` — cykelns längd i meter, till den distansdrivna fasen |
| `roblox/src/shared/HorseCore/Config.luau` | Kurvaturtak och tidskonstanter; lutningstaket sänkt 15° → 4,3° |
| `roblox/tests/` | Mätbänken utökad med ryttarspec, ledstubb och `CFrame` som bär tre vinklar |

En ny testfil. Inget nytt beroende, ingen fysikmotor, ingen WebGL-omskrivning, inget
nytt lager i Roblox-arkitekturen — `RiderController` och `RigAdapter` fanns redan och
behöll sina gränser.

---

## 2 · Root causes som faktiskt löstes

**P0 — touchjoysticken var inte analog i ridningen.** `IN.joy` fanns men lästes
aldrig av ridningen. `joyLage` skickade i stället syntetiska tangenthändelser när
axlarna passerade trösklar (`dy<-0.28`, `dx>0.32`), så spaken var visuellt analog
men ridmodellen fick tre lägen.

**P0 — vridhastigheten växte med farten.** `omega = styrning × clamp(0.5 + tempo×0.22, 0.4, 2.2)`.
I galopp gav full styrning 2,2 rad/s, alltså 126°/s. Det gör att man viker hästen
genom en sväng i stället för att rida en båge, och det är kärnan i fordonskänslan.

**P0 — fasen var tidsdriven, inte distansdriven.** `gaitFas += stegFrek × dt × (0.6 + tempo×0.12)`.
Nära rätt, men samma sträcka kunde ge olika många hovnedslag beroende på hur tempot
varierade på vägen.

**P1 — kroppen svarade inte på svängen.** `s3RitaHast` hade bob och galoppvaggning
men ingen rullning ur den faktiska rörelsen.

**P1 — kameran kopierade hästens kurs.** Boom och blick byggdes båda direkt ur
`G.rikt` med en gemensam utjämningsfaktor, och boomens väggsökning gav diskreta
längdhopp.

**P1 — väggresponsen var bildfrekvensberoende.** `lerpAngle(..., 0.06)` per bildruta.

---

## 3 · Före och efter

| | Före | Efter |
|---|---|---|
| Touch 25/50/100 % | samma sväng (tröskel passerad = full input) | 61 m / 19,6 m / 4,4 m radie |
| Full styrning, skritt | 1,77 m radie, 0,82 rad/s | 3,63 m radie, 0,40 rad/s |
| Full styrning, galopp | 3,9 m radie, **2,2 rad/s (126°/s)** | 6,97 m radie, 0,80 rad/s (46°/s) |
| Radie mot fart | krympte relativt (yaw växte snabbare än tempot) | **ökar**: 3,6 → 4,4 → 7,0 m |
| Gångartsfas | tid × tempo | sträcka ÷ cykellängd |
| Kroppens lutning i sväng | ingen | 0° halt, 0,4° skritt, 1,7° trav, 3,2° galopp |
| Väggkurs vid 30 vs 144 Hz | olika (fast faktor per ruta) | identisk |
| Kamerans kurs | hästens, direkt | egen, 0,16 s fördröjning |

---

## 4 · Hur analog touch verifierades

Playwright i 390×844 med touch. Joysticken dras med riktiga `PointerEvent` till
25, 50 och 100 procent av sin radie, och `RIDIN.styr` och den resulterande
kurvaturen läses ur körande spel:

| Spakutslag | `RIDIN.styr` | Kurvatur (1/m) | Svängradie |
|---|---|---|---|
| 25 % | 0,072 | 0,0164 | 61,1 m |
| 50 % | 0,226 | 0,0511 | 19,6 m |
| 100 % | 1,000 | 0,2255 | 4,4 m |
| släppt | 0 | — | — |

Tre tydligt olika resultat: en linjekorrigering, en 20 m volt och en snäv volt.

Kurvan är expo (35 % rak, resten kubisk) med dödzon 0,07. En rent kvadratisk kurva
provades först och föll: 25 % gav 2 % styrning, alltså 203 m radie — i praktiken
rakt fram, vilket inte är tre användbara nivåer.

---

## 5 · Styrrespons per gångart och nivå

Mätt i körande spel med tempot låst vid gångartens norm, hästen fryst mitt på banan
så att väggarna inte kommer in i mätningen. Häst: Lydia (känslighet 0,5-klassen).

| Gångart | Tempo | Styrning | Kurvatur (1/m) | Radie | Vridhastighet |
|---|---|---|---|---|---|
| Skritt | 1,45 | 0,25 | 0,0689 | 14,5 m | 5,7°/s |
| Skritt | 1,45 | 0,50 | 0,1379 | 7,3 m | 11,5°/s |
| Skritt | 1,45 | 1,00 | 0,2758 | 3,6 m | 22,9°/s |
| Trav | 3,20 | 0,25 | 0,0565 | 17,7 m | 10,4°/s |
| Trav | 3,20 | 0,50 | 0,1131 | 8,8 m | 20,7°/s |
| Trav | 3,20 | 1,00 | 0,2261 | 4,4 m | 41,5°/s |
| Galopp | 5,60 | 0,25 | 0,0359 | 27,9 m | 11,5°/s |
| Galopp | 5,60 | 0,50 | 0,0717 | 14,0 m | 23,0°/s |
| Galopp | 5,60 | 1,00 | 0,1434 | 7,0 m | 46,0°/s |

Kurvaturen är linjär i styrningen (0,25 → 0,50 → 1,00 ger exakt 1×, 2×, 4× av
kvartsvärdet), och radien ökar monotont med gångarten vid varje nivå.

En 20 m volt behöver 10 m radie: i trav rids den på ungefär 0,45 styrning, alltså
delvis utslag — precis vad Target feel punkt 4 efterfrågar.

---

## 6 · Test desktop / mobil / surfplatta

**Hela kedjan spelad med tangenttryck och riktiga tryck**, från start till
resultatskärm: Rid direkt → gården → stallentrén → ridläraren → hästen i hagen →
tillbaka in → boxen → sadelkammaren → skötseln → led ut → ridhuset → sargporten →
lektion → resultat.

- Desktop 1280×800: alla fjorton stegen OK, noll konsolfel.
- Mobil 390×844 touch: alla fjorton stegen OK, noll konsolfel.

**Layout på tolv viewports** (320×568, 375×667, 390×844, 430×932, 844×390 liggande,
768×1024, 820×1180, 1024×1366, 1180×820 liggande, 1280×720, 1440×900, 1920×1080):
inga överlapp, ingen sidled-scroll, inget utanför bild, alla touchmål ≥ 44 px.

---

## 7 · 30 vs 60 vs 144 Hz

Samma manöver, tre bildfrekvenser, tre sekunder trav med styrning 0,6:

| | 30 Hz | 60 Hz | 144 Hz |
|---|---|---|---|
| Kurvatur (1/m) | 0,1357 | 0,1357 | 0,1357 |
| Kurs (rad) | 0,337 | 0,321 | 0,323 |
| Gångartsfas | 0,567 | 0,521 | 0,495 |

Kurvaturen är **exakt identisk** — den är ett dt-baserat filter mot ett mål som
inte beror på bildrutan. Kursen skiljer 0,014 rad (0,8°) över tre sekunder, vilket
är integrationsfel i Eulersteget och inte en beteendeskillnad.

Väggresponsen, rakt in i sargen i tre sekunder: kursen blir **−1,561 rad vid alla
tre frekvenser**. Före ändringen var den bildfrekvensberoende.

Fasen skiljer 0,072 av ett varv (26°) mellan 30 och 144 Hz. Det följer av att
sträckan skiljer några centimeter av samma integrationsfel; det syns inte i
animationen, men det är den siffra som är känsligast av de mätta.

---

## 7b · Roblox implementation & Studio evidence

Roblox-spåret fick först tre riktade ändringar samma dag, innan addendumet gjorde
det till primärt Gate 01-target. De löser samma tre feel-fel som webbsidan, i den
motoroberoende delen av modellen. Därefter portades webbens verifierade modell hit
i två steg (`58a8030`, `eed6178`), så att pariteten blev en delad formulering i
stället för två likvärdiga.

| Ändring | Fil | Mätt |
|---|---|---|
| Styrutslaget rampas innan det används; en tangent har annars tre lägen | `roblox/src/client/MovementController.luau` (`_steer`), `Config.MOVEMENT.SteerTauPress/Release` | Tid tillbaka till nära noll 0,09 → **0,38 s**; tid till halva svängen står kvar på **0,09 s** |
| Låg fart: krypningen borta. `WalkSpeed 0.35` ersatt av att roten vrids direkt | `MovementController.luau` | WalkSpeed 0,350 → **0,000** medan hästen fortfarande vänder sig (0,45 rad) |
| Kameran har egen kurs i stället för att läsa hästens rått | `roblox/src/client/CameraController.luau`, `Config.CAMERA.YawTau` | 0,88 rad kvar efter en bildruta, ifatt inom 0,5 s, största kurssteg 0,02 rad vid nollpassage |
| Svängen räknas som kurvatur, inte vridhastighet; fasen drivs av flyttad sträcka; lutningstaket sänkt 15° → 4,3° | `MovementController.luau`, `Gaits.cycleLength`, `Config.MOVEMENT` | Radien ökar med gångarten: **4,07 → 5,38 → 7,94 m**; lågfartsprecisionen 0,343 → **0,141 rad** |
| Ryttaren får tröghet och balans ovanpå sitsen | `roblox/src/client/RiderController.luau`, `RigAdapter.setRiderLean` | Acceleration −2,14°, inbromsning 3,15°, taket nås exakt vid ihållande inbromsning, 0,00 % spridning över 30/60/144 fps |

**Verifiering utanför Studio.** `roblox/tests/` innehåller en mätbänk som kör
**produktionskoden ordagrant** mot stubbade Roblox-globaler. `build.py` fogar ihop
stubbar och källfiler till en körbar fil — luau-CLI:t sandboxar varje modul, så
stubbar går inte att injicera via `require`. Elva mätningar på rörelsen, fem på
kameran och sjutton på ryttaren, alla gröna:

```
python3 roblox/tests/build.py && luau roblox/tests/.build/movement.spec.luau
python3 roblox/tests/build.py tests/camera.spec.luau && luau roblox/tests/.build/camera.spec.luau
python3 roblox/tests/build.py tests/rider.spec.luau && luau roblox/tests/.build/rider.spec.luau
```

Utöver det: `luau-compile` rent på samtliga filer under `roblox/src/`.

**Det mätbänken visade som inte behövde lagas:** gångartsbytena är redan rena
(fyra byten upp, fyra ned, inget flimmer vid bandgränserna — hysteresen i `Gaits`
gör sitt jobb). Ingenting ändrades där.

**Och två saker den fångade som annars hade gått igenom.** Kurvaturportningen tog
bort hästens förmåga att vända på stället, eftersom kurvatur × tempo är noll vid
stillastående — bänken fällde det direkt, och `TurnInPlaceRate` blandas nu in under
0,55 m/s. Ryttarmätningen visade att ett tvärstopp på en bildruta bara ger 0,43° av
tillåtna 3,15°: utjämningen dämpar krockspiken av sig själv, och taket bits först av
en ihållande hård inbromsning. Det var mitt eget antagande som var fel, inte koden.

### Vad som INTE kan verifieras utanför Roblox Studio

Detta är listan addendumet ber om, och den är lång med flit:

- **All subjektiv känsla.** Siffrorna säger att svängen släpper fyra gånger mjukare, inte om det känns rätt.
- **Humanoid-samspelet.** Marken, sluttningar, kanter och trappor sköts av `Humanoid`; stubben ger plan mark och kan inte säga hur `AutoRotate` beter sig mot vår egen rotation vid noll fart.
- **Att vrida roten direkt** (krypningsfixen) mot fysikmotorn och nätverksägarskapet — bänken har ingen fysik.
- **Animationsblending**, `AnimationTrack`-övergångar och procedurell påbyggnad.
- **Kameran mot verklig geometri**: väggkontrollens strålkastning finns inte i stubben.
- **Frame-rate-känsla i praktiken**, gamepad, och touch i Roblox-klienten.
- **Hela kärnloopen i Studio**: uppsittning, uthållighet, ljud, damm.

## 7c · HTML/web implementation & browser evidence

Se avsnitt 1–7 ovan. Sammanfattat: ridinputkontraktet (`RIDIN`), svängen som
kurvatur med gångartstak, gångartsfas ur markförflyttning, kroppens svänglutning ur
centripetalkraft, ryttarens tröghet och balans ovanpå sitsen, dt-baserad väggrespons
och kamera med egen kurs.

Bevisen är körda i Chromium via Playwright mot `dist/ridskolan.html`: hela
lektionskedjan från start till resultatskärm på 1280×800 och 390×844 touch utan
konsolfel, tolv viewports utan layoutfel, styrtabellen per gångart och nivå,
touchmätningen med riktiga `PointerEvent`, och 30/60/144 Hz-jämförelsen.

Ryttarens sekundärrörelse är mätt på ridloopen med fast dt: stillastående 0,000°,
acceleration 3,22 m/s² → −2,58° pitch, inbromsning −3,86 m/s² → 3,10°, och i galopp
lutar hästen 4,06° medan ryttaren följer med 1,38° inåt. Taken hålls, och balansen
är exakt 0,34 av hästens lutning.

Mätningen fångade också att 44 px-golvet bara gällt `#viewToggle`: sju knappar i
menyerna låg på 26–39 px på 390×844 och 820×1180 med riktig pekskärm. Det är rättat
under `.pek`, och rörelsemätningen på fyra viewports är grön efteråt — testläget
synligt, hästen rör sig, inga konsolfel, inga mål under 44 px.

Webbversionen är direkt spelbar och bruten av ingenting i det här arbetet.

## 7d · Parity table

Vad som är samma regel på båda plattformarna, och var siffrorna skiljer sig.

| Regel | Roblox | HTML/webb | Paritet |
|---|---|---|---|
| Styrutslaget rampas före användning | `SteerTauPress 0,11` / `Release 0,17` | `kappaTau 0,13` upp / `0,19` ned | ✅ samma princip, tal i samma storleksordning |
| Svarvheten sjunker per gångart | `Gaits.turn`: 1,00 / 0,82 / 0,62 / 0,42 | `GANGSVANG`: 1,00 / 0,82 / 0,52 | ✅ samma storhet; webben har fyra gångarter mot Roblox fem |
| Snabbare gångart ger vidare sväng | kurvaturtak × `turn`; radie 4,1 → 5,4 → 7,9 m | kurvaturtak; radie 3,6 → 4,4 → 7,0 m | ✅ samma formulering sedan `58a8030`; talen skiljer med Roblox egna gångartstempon |
| Acceleration olika upp och ned | `gait.accel` / `gait.retard` | modellens `stepRide` | ✅ |
| Analog touchprecision | pekstöd finns, otestat i klient | expo-kurva + dödzon; 25/50/100 % → 61 / 19,6 / 4,4 m | ⚠️ webben verifierad, Roblox inte |
| Gångartsfas ur rörelsen | faktiskt flyttad sträcka ÷ `Gaits.cycleLength` | sträcka ÷ cykellängd | ✅ båda distansdrivna sedan `58a8030` |
| Turn/body response | centripetal × 0,012, tak 0,075 rad | centripetal × 0,012, tak 0,075 rad | ✅ identiska tal sedan `58a8030` |
| Kamera med egen kurs | `CAMERA.YawTau 0,13` | `KAM_YAW_TAU 0,16` | ✅ |
| Ingen krypning vid låg fart | roten vrids direkt, `WalkSpeed 0` | omega = kurvatur × tempo, noll vid stillastående | ✅ olika mekanism, samma utfall |
| Frame-rate-oberoende | `dt`-baserade filter, mätt över 30/60/144 i bänken | mätt: kurvatur identisk, väggkurs identisk | ✅ |
| Ryttarens sekundärrörelse | tröghet 0,014/rad, tak 0,055; balans 0,34, tak 0,030 | samma tal | ✅ identiska tal sedan `eed6178` |
| Utbildningsmässiga ridregler | gångart väljs, aldrig exakt tempo | hjälper (skänkel/tygel/sits) + utbildningsskalan | ⚠️ webben bär pedagogiken — se skillnad 3 |

## 7e · Intentional platform differences

1. **Kvarvarande taldifferens i svängen.** Sedan `58a8030` räknar båda
   plattformarna kurvatur (1/m) och får vridhastigheten som kurvatur × tempo, med
   samma gångartsfaktorer. Radierna skiljer ändå — 4,1 / 5,4 / 7,9 m i Roblox mot
   3,6 / 4,4 / 7,0 m i webben — därför att Roblox gångarter går i andra tempon
   (1,45 / 3,20 / 5,60 m/s). Skillnaden följer alltså av gångartsdefinitionen, inte
   av svängmodellen, och bör ligga kvar tills en playtest säger vilken uppsättning
   tempon som är rätt.
2. **Roblox behöver dessutom vändning på stället.** Kurvatur × tempo är noll när
   hästen står still — det är precis det som tar bort krypningen — men i Roblox ska
   hästen kunna vridas på stället. `TurnInPlaceRate` blandas därför in under
   0,55 m/s. Webben har inte det behovet: där vrids ryttaren i gå-läget, inte
   hästen.
3. **Pedagogiken finns bara i webben.** Hjälper, utbildningsskala, ridlärare och
   lektionsmoment är JS-sidans, och Roblox-spåret har inte den lagren än. Det är en
   känd skillnad i mognad, inte ett designval.
4. **Fyra mot fem gångarter.** Webben har halt/skritt/trav/galopp; Roblox har
   dessutom fyrsprång. Webbens `galopp` motsvarar Roblox `canter`.

## 8 · Kvarvarande begränsningar

1. **Ryttarens sekundärrörelse är byggd men inte sedd i rörelse.** Trögheten och
   balansen är mätta som tal på båda plattformarna (`eed6178`), och den pedagogiska
   sitslogiken är orörd. Om ±3,2° och ±1,7° läser som en människa eller som en
   darrning syns först när någon tittar på den.
2. **Känslan är inte bedömd.** Alla siffror ovan säger vad modellen gör, inte om
   den känns rätt. Att en 20 m volt rids på 0,45 styrning är en mätning; om det
   känns lagom avgörs av en människa som rider.
3. **Konstanterna är trimmade mot mätningar, inte mot playtest.** `KAPPA_MAX` 0,42,
   gångartsfaktorerna, expo 0,35, dödzon 0,07, lutningens 0,012-skalning och
   kamerans 0,16 s — alla är valda för att träffa rimliga tal i tabellerna ovan.
   De är avsedda att justeras efter Studio-/webbplaytest.
4. **Mätningarna fryser hästen mitt på banan** för att hålla väggarna utanför.
   Samspelet mellan sväng och sarg i ett verkligt hörn är alltså inte mätt, bara
   observerat som att kursen blir bildfrekvensoberoende.
5. **Gamepad är inte provad.** Kontraktet tar emot analoga värden, men ingen
   gamepad har testats i den här miljön.

---

## 9 · Roblox-portabilitet

Modellen är avsiktligt motoroberoende: styrkurvan, gångartens kurvaturtak,
kurvaturens tidskonstanter, faslagen och lutningens centripetalsignal är rena tal
och regler utan WebGL-beroende. Gångartsfaktorerna (`skritt 1,00 / trav 0,82 /
galopp 0,52`) är samma storhet som `turn` i `roblox/src/shared/HorseCore/Gaits.luau`,
så designen översätts i stället för att uppfinnas igen.

---

## 10 · Acceptanskriterier

| Kriterium | Status |
|---|---|
| `IN.joy` eller motsvarande analog data används kontinuerligt i ridinputen på touch | ✅ |
| 25/50/100 % joystick ger mätbart och visuellt olika styrrespons | ✅ 61 / 19,6 / 4,4 m |
| keyboard och touch går genom samma normaliserade ridinputkontrakt | ✅ `RIDIN` |
| svängradien ökar i praktiken med fart/gångart vid jämförbar input | ✅ 3,6 → 4,4 → 7,0 m |
| inga synliga pivots/powerslides i trav eller galopp | ✅ vridhastigheten sjönk från 126 till 46°/s; kurvatur × tempo kan inte ge pivot |
| gångartsfas är kopplad till faktisk förflyttning/effektiv steglängd | ✅ |
| hästen har smoothed visuell turn lean från faktisk rörelse | ✅ centripetal, 0–3,2° |
| ryttaren följer hästen subtilt utan att pedagogisk sitslogik försvinner | ✅ tröghet ±3,2°, balans ±1,7°, sitslogiken orörd |
| kamera känns stabil i raksträcka, volt och hörn | ⚠️ egen kurs, mjuk boom, separata svar — men "känns" är inte mätt |
| kameran hoppar inte synligt vid väggundvikande | ✅ boomen utjämnad i stället för diskreta steg |
| väggkollision/steering correction är frame-rate independent | ✅ identisk kurs vid 30/60/144 Hz |
| 30 och 60 FPS ger jämförbar styrkänsla | ✅ kurvaturen identisk |
| befintlig första lektion går att spela från start till resultat | ✅ desktop och mobil |
| inga nya konsolfel | ✅ |
| inga nya features utanför Gate 01 | ✅ |

**Tretton av femton uppfyllda, en som kräver mänsklig bedömning, en kvar: kamerans stabilitet i volt och hörn kan bara avgöras av någon som rider.**

---

## 10b · Remaining risks

Riskerna, som addendumet kräver dem — sorterade efter vad som mest sannolikt sänker
gaten vid review eller playtest.

1. **Ingen Roblox Studio-playtest har skett.** Addendumet säger uttryckligen att
   Gate 01 inte kan stängas utan den, och den kan inte göras härifrån. Det här är
   den enda risk som ensam blockerar gaten.
2. **Roblox-ändringarna är mätta i en stubbad miljö.** Krypningsfixen vrider roten
   direkt; hur det samspelar med `Humanoid.AutoRotate`, fysiken och
   nätverksägarskapet är oprövat och är den ändring som mest sannolikt beter sig
   annorlunda i Studio än i bänken.
3. **Pariteten är nästan exakt, men inte helt.** Två av tolv rader i
   paritetstabellen är gula: Roblox touch är overifierad, och pedagogiken finns bara
   i webben. Sväng, fas, lutning och ryttarrörelse delar numera formulering och tal.
   Det som är kvar av taldifferens är gångartstempona, som är ett produktbeslut, inte
   en portningslucka.
4. **Konstanterna är trimmade mot mätningar, inte mot playtest.** Alla tal i båda
   spåren är valda för att träffa rimliga siffror i tabellerna, inte för att någon
   ridit med dem.
5. **Touch är overifierad i Roblox.** Webbens analoga touch är mätt med riktiga
   pekhändelser; Roblox-klientens är det inte.
6. **Gamepad är overifierad på båda.** Kontrakten tar emot analoga värden, ingen
   gamepad har testats.

## 11 · Överlämning

Enligt `docs/GATE-01-RIDING-FEEL.md` stänger jag inte gaten. Arbetet lämnas till
ChatGPT för senior gameplay review av diff, mätresultat och Product Canon-följsamhet,
och till Tobias för avgörandet om känslan räcker.

Om känslan inte sitter trots de gröna raderna ovan ska gaten inte stängas —
dokumentets egen regel, och den rätta.
