# G02-A — Ridkärnans konsolidering (issue #82)

Status: `READY_FOR_CHATGPT_REVIEW` (Claudes högsta normala status enligt
`docs/DELIVERY-PROTOCOL.md`). Ingen del av det här dokumentet är
produktacceptans.

Dokumentet beskriver läget efter **G02-A.1**, ridkänslopasset P1–P7, och
efter senior review 2026-09-05 17:21. Historiken finns i PR #86; här står
det som gäller nu.

**De fyra kärnrörelseavvikelser som tidigare blockerade produktacceptans är
stängda.** PO-beslutet 2026-09-05 valde webbens A-modell till kanon, och
Roblox är harmoniserad mot den: kurvaturtak, galoppens svängfaktor,
galoppens övre bandgräns och cykellängderna är nu samma tal på båda
ytorna. Paritetsspecen skriver ut `KÄRNRÖRELSEN HAR PARITET` och räknar
**2 kända luckor, varav 0 blockerar**.

Kvar för produktacceptans är alltså inte paritetsfrågor utan Tobias
subjektiva game-feel-test och de luckor som listas under *Kvarstående
luckor* längre ned.

## Vad uppdraget ÄR

Ett delta ovanpå Gate 01, inte en omskrivning. Ridkärnan fanns redan:

- webben — `Gait`/`stepRide` i `src/model.js`, ridinputkontraktet `RIDIN`
  och `ridAvsiktTillHjalp` samt kurvaturstyrningen i `src/game.js`, den
  analoga spaken i `src/mobil.js`, kameran i `src/scen3d.js`,
- Roblox — `MovementController`, `RiderController`, `HorseCore/Gaits`,
  `HorseCore/Config`, `TouchControls`.

G02-A rör inte deras intrimmade värden. Det som saknades var tre saker, och
det är dem det här arbetet lägger till.

## 1. Uppsutten/avsutten som tillstånd

Förut framgick det bara indirekt av vilken scen som var igång. Nu finns det
som ett namngivet tillstånd på båda ytorna: `RID_TILLSTAND` i
`src/riding/telemetri.js`, `Telemetri.Ritt` i
`roblox/src/shared/HorseCore/Telemetri.luau`.

Inkopplat på webben i `sittUpp()` (`src/tavling.js`, båda vägarna in i en
ritt) och `startaVandring()` (`src/world.js`).

## 2. Telemetri med ärlig proveniens

`ridTelemetri()` respektive `Telemetri.las()` läser ut de storheter G02-B/C
behöver: gångart, faktisk och önskad fart, kurvatur, svängradie,
vridhastighet, rytm, steglängd, spänning, mjukhet, balans, fokus, hjälper.

Ren avläsning — inget i lagret räknar fysik eller kan påverka ridkänslan.

`balans` och `fokus` finns inte som egna storheter i modellen. De härleds ur
mjukhet och spänning och är märkta `_harledda` (webb) respektive
`Telemetri.HARLEDDA` (Roblox). De påstår alltså inte att de är mätta.
G02-B ger dem riktiga källor.

## 3. Gångartsövergångarnas kontrakt

Grannbyten i gångartsordningen är lagliga, plus halt från vad som helst.
`halt → galopp` är inte en övergång utan ett glapp, och räknas som ett.

Kontraktet **dömer, det styr inte**: gångarten kommer fortsatt ur
`Gait.forTempo` / `Gaits.forSpeed` med hysteres. Ett kontrakt som styrde
hade ändrat ridkänslan, vilket är utanför uppdraget.

## Paritet — mätt, inte påstådd

Paritetsregeln i `CLAUDE.md` har hittills varit en text. Den är nu körbar:

- `tools/exportera-ridkanon.mjs` exporterar webbens ridkanon
  (gångartsband, hysteres, trösklar, telemetrins fältnamn) till
  `roblox/src/shared/HorseCore/RidKanon.luau`. Trösklarna **mäts** ur
  `Gait.forTempo` med halveringsmetoden i stället för att skrivas av.
- `roblox/tests/paritet.spec.luau` jämför Roblox `Gaits`/`Telemetri` mot den
  kanonen. Ingår i `bash roblox/tests/kor.sh`.
- `node tools/exportera-ridkanon.mjs --kontrollera` faller om kanonen är
  osynk. Kört i CI (`.github/workflows/grindar.yml`), och filen står i
  `dubbel-sanning`-listan så att den inte kan handredigeras.

### Kvarstående luckor — och vad som är stängt

Registret skiljer på tre saker, och skillnaden är hela poängen:

- **Stängt.** En fråga som fanns och som ett beslut har avgjort. Raden
  mäter numera att beslutet står kvar; ändras värdet blir den `FEL`.
- **`LUCKA`.** En saknad funktion med känt hem. Skrivs `PO`, aldrig `OK`,
  och räknas inte som paritet.
- **`BLOCKERAR`.** En lucka som hindrar produktacceptans. **Det finns
  inga sådana rader i dag.**

#### Stängda efter PO-beslutet 2026-09-05

| Fråga | Var | Är |
| --- | --- | --- |
| Kurvaturtak vid full styrning | webb 0,42 / Roblox 0,30 1/m | **0,42 på båda** ⇒ 2,4 m radie i skritt |
| Galoppens svängfaktor | webb 0,52 / Roblox 0,62 | **0,52 på båda** |
| Galoppens övre bandgräns | webb 8,00 / Roblox 7,00 m/s | **8,00 på båda** |
| Cykellängd skritt/trav/galopp | webb 1,61/2,21/3,50, Roblox 1,45/2,13/3,20 m | **1,61 / 2,21 / 3,50 på båda** |

Underlaget för beslutet finns i `docs/G02-A-AB-BESLUTSUNDERLAG.md`. Att
jämna ut dem ändrade ridkänslan på Roblox, vilket var själva beslutet —
inte något en konsolidering gjorde på eget initiativ.

#### Stängt efter senior review 2026-09-05

| Fråga | Var | Är |
| --- | --- | --- |
| Fyrsprånget spelbart | Roblox `ceiling = "gallop"` gjorde en femte gångart nåbar | **`Gaits.SPELBAR_TOPP = "canter"`** — gångarten finns kvar som data men går inte att rida |
| Övergångsförloppet | webben mjukstegskurva över bestämd längd, Roblox linjär `approach()` | **samma kurva och samma längder på båda**, mätta mot kanon inom ±0,08 s |

#### Kvarstående luckor

| Lucka | Klass | Hem |
| --- | --- | --- |
| Fyrsprånget finns som data på Roblox, saknas på webben | `LUCKA` | framtida scope; kräver att webben får gångarten först |
| Hjälplager, spänning, mjukhet, balans, fokus saknar källa på Roblox | `LUCKA` | G02-B |

Ingen av dem blockerar. `balans` och `fokus` är dessutom märkta som
**härledda** på båda ytorna — de påstår inte att de är mätta.

### G02-A.1 — ridkänslopasset

Sju faser, en commit per fas, på arbetsorder från PO 2026-09-05.

| Fas | Vad |
| --- | --- |
| P1 | `tools/ridkansla.mjs` — baslinje och instrumentering utan webbläsare |
| P2 | övergången som förlopp med mjukstegskurva i stället för snäpp |
| P3 | vikt och svar per gångart (`upp`/`ner`/`svangTau`) |
| P4 | styrning och kropp — plus cue-modellens P0 genom inputlagret |
| P5 | paraden och halten — hjälpens styrka styr inbromsningen |
| P6 | kameran och kroppen följer simuleringen |
| P7 | den vertikala slicen på båda ytorna |

**P4 hittade två fel som inget prov kunde se.** Cue-modellen från P2 mätte
impulsen per bildruta, men spelets hjälp rampar med `STIG` 0,28 s och når
aldrig tröskeln — hästen kunde inte lämna skritt genom tangentbord eller
pekskärm. Och hjälpfiltret startade under neutralläget, så hästen gick i
väg av sig själv vid uppsittning. Båda var osynliga därför att varje prov
körde `stepRide()` direkt med hjälper som hoppar färdigt på en bildruta.

Det strukturella svaret är viktigare än fixen: **sju kontroller och hela
den vertikala slicen kör nu genom `stegaRitt()` och `RIDIN`**, samma väg
som ett tangenttryck.

#### Övergångsförloppet — kanon och uppmätt

Sekunder för en neutral häst. Kanonvärdena bor i `K.OVERGANG`
(`src/model.js`), exporteras till `RidKanon.OVERGANG` och speglas i
`Config.MOVEMENT.Transition`.

| Övergång | Kanon | Uppmätt webb | Uppmätt Roblox | Kuvert |
| --- | --- | --- | --- | --- |
| halt→skritt | 0,80 | 0,81 | 0,80 | 0,6–1,0 |
| skritt→trav | 0,95 | 0,96 | 0,95 | 0,7–1,2 |
| trav→galopp | 1,20 | 1,21 | 1,20 | 0,9–1,5 |
| nedåt, bestämt | 0,78 | 0,78 | — | 0,6–1,2 |
| nedåt, mjukt | 0,98 | 1,13 (ytterhäst) | 1,05 | 0,6–1,2 |

Skalan är **1,0 för en neutral häst** på båda ytorna: webbens
`1 + 0,393·(tyngd − 0,40)`, Roblox `1 / accelScale`. Basvärdena betyder
alltså det de säger, och de två ytorna går att jämföra utan omräkning.
Kurvan är u²(3−2u) på båda — noll lutning i båda ändar, ingen platå.

Gångartsetiketten byter vid 55 % av förloppet, inte när tempot råkar
passera ett band: hästen är på väg in i travet en stund innan travet syns.

## Gate 01-styrkanonens proveniens

Senior review av #86 frågade om dagens värden verkligen är Gate 01:s, eller
om kanonen har glidit. Spårat med `git log -L`:

| Konstant | Införd | Ändrad sedan dess |
| --- | --- | --- |
| `KAPPA_MAX = 0,42` (webb) | `33559d9` — Gate 01-committen | nej |
| `GANGSVANG` (webb) | `33559d9` — Gate 01-committen | nej |
| `CurvatureMax` (Roblox) | `58a8030` — Gate 01:s Roblox-port, med 0,30 | **ja — 0,42 efter PO-beslutet 2026-09-05** |

**Ingen OAVSIKTLIG drift.** Webbens två konstanter är orörda sedan Gate
01-committen. Roblox `CurvatureMax` ändrades 0,30 → 0,42, och det är
PO-beslutet 2026-09-05 som gjorde det — inte en glidning.

Den skenbara motsägelsen mot auditen är två olika storheter. Auditen
(`audits/GATE-01-RIDING-FEEL-RESULT.md`, rad 133) mäter **κ i det körande
spelet vid fullt utslag**: skritt κ 0,2758, radie 3,6 m. `KAPPA_MAX` är
**takkonstanten**, som aldrig nås: hjälplagret mättar `styrning` vid 0,72
för råinsats 1,00, och hästens känslighetsfönster
(`0,78 + 0,44 × kanslighet`) skalar taket därutöver.

Uppmätt i dag, råinsats 1,00, häst med `kanslighet` 0,45:

| Gångart | styrning | κ-tak | κ | radie |
| --- | --- | --- | --- | --- |
| skritt | 0,72 | 0,4108 | 0,2957 | 3,38 m |
| trav | 0,72 | 0,3368 | 0,2425 | 4,12 m |
| galopp | 0,72 | 0,2136 | 0,1538 | 6,50 m |

Auditens 0,2758 faller ur samma formel med en häst vars `kanslighet` är
0,30. Skillnaden är alltså hästen, inte kanonen.

Avvikelsen mot Roblox var **född i porteringen**: `58a8030` gav Roblox
samma formulering men egna tal, och Gate 01-auditens paritetstabell
(rad 283) godkände raden uttryckligen på *formuleringen* — "samma
formulering sedan `58a8030`; talen skiljer med Roblox egna gångartstempon".
Senior review av G02-A gjorde samma invändning på nytt: samma formulering
är inte samma känsla. **Frågan är avgjord.** PO valde webbens värden, och
Roblox bär dem sedan 2026-09-05.

## Volten — styrutslaget mätt som en ridd bana

#81 visade vad som händer när ett test provar formeln i stället för
banan: formeln stämde, och läktaren gick ändå inte att gå upp på. Volten
mäts därför på samma sätt som en ryttare rider den — fast styrutslag,
samplat läge ur den körande ridloopen, minsta-kvadrat-cirkel på punkterna.

| Mätning | Resultat |
| --- | --- |
| Full styrning, skritt | ridd radie **3,38 m** = 1/κ **3,38 m**, största avvikelse från cirkeln **0,5 cm** över 240 punkter |
| 0,45 styrutslag | ridd radie **7,51 m** = 1/κ, alltså en volt på **15,0 m** |
| Kurvaturlagen | κ 0,1331 = styrutslag 0,324 × gångartens tak 0,4108 |
| 10 m volt i trav, sökt utslag | diameter **9,70 m**, största avvikelse **0,4 cm** |

**En 20 m volt får inte plats i ridhuset.** Uppmätt till 17,8 m diameter
med 1,05 m avvikelse från cirkeln — och avvikelsen är sargen, inte
styrningen: hallen är 20 m bred. Volten går att rida som en figur längs
långsidan, men inte som volt. Ska en lektion be om en 20 m volt behöver
den läggas utomhus. Det är ett mätresultat att ta ställning till, inte ett
fel att rätta.

Insatt styrutslag 0,45 blir **0,324** efter hjälplagrets utjämning.
Kurvaturen följer den utjämnade hjälpen, inte råinsatsen.

## Evidens

| Grind | Vad den täcker |
| --- | --- |
| `node tools/ridtest.mjs` | 47 kontroller i webbens runtime: Gate 01:s band och normtempon, gångartsstegen genom `RIDIN` och `stegaRitt`, övergångskontraktet och de uppmätta övergångstiderna, telemetrins fält och härledningsmärkning, styrningens karaktär per gångart, paraden, kameran, kroppens lutning och den vertikala slicen |
| `bash roblox/tests/kor.sh` | 13 specar, `paritet` inräknad |
| `node tools/ridkansla.mjs` | ridkänslans mätvärden i den rena modellen — tider, acceleration, överslag, stoppsträcka |
| `node tools/styrkansla.mjs` | styrningens mätvärden i den byggda sidan — kurvaturens ändringstakt, in- och urläggning, riktningsbyte, hörn, volter |
| `node tools/exportera-ridkanon.mjs --kontrollera` | kanonen i synk; filen står dessutom i `dubbel-sanning` |

De två `-kansla`-verktygen är **instrument, inte grindar**: de skriver
tabeller. Kraven bor i `ridtest` och i specarna, så att ett mätvärde kan
synas i en körning utan att smyga in en gräns som ingen beslutat.

### Falsifiering

Varje central kontroll har visats kunna bli röd. G02-A:s ursprungliga
mutationer står i PR #86; nedan de som hör till G02-A.1 och till senior
review 2026-09-05.

| Mutation | Utfall |
| --- | --- |
| cue mätt per bildruta igen | ridtest 2 FEL |
| hjälpfiltret nollställs inte vid rittstart | ridtest 1 FEL |
| anropet ur `avslutaSkotsel` bort | ridtest 1 FEL |
| neutralläget glider isär mellan modell och spel | ridtest 1 FEL |
| Roblox flankdetektering bort | movement 1 + touch 2 FEL |
| webbens `svangTau` eller `upp`/`ner` kollapsade | paritet 4 FEL |
| Roblox `svangTau` kollapsad eller ur `kappaTau` | paritet 2 FEL / movement 1 FEL |
| kurvaturens takttak bort (webb / Roblox) | ridtest 1 FEL (1,43×) / movement 1 FEL (2,29×) |
| `KAPPA_RAT_TID` glider isär | paritet 1 FEL |
| paradlängden oberoende av hjälpens styrka | ridtest 1 FEL |
| Roblox bromsmekanismerna bort | movement 1 FEL |
| kameran samma i alla gångarter | ridtest 1 + paritet 2 FEL |
| kamerans yaw 10× trögare | ridtest 1 FEL |
| lutningen ur styrspaken i stället för ur farten | ridtest 1 FEL |
| cue-spärren bort | ridtest 4 FEL |
| uppsittningen ur på Roblox | movement 2 FEL |
| `Gaits.SPELBAR_TOPP` tillbaka till fyrsprång | movement 2 + paritet 1 FEL |
| Roblox tillbaka till linjär `approach()` | movement 1 FEL |
| övergångslängderna glider isär | paritet 1 FEL |
| webbens skalning tillbaka till den orebasade | ridtest 2 FEL |

**Två ändringar togs bort igen** när falsifieringen visade att de inte
gjorde något: ett kurvaturtak som aldrig band, och en kuvertklippning som
hade tystat just det prov den fanns för att skydda. En gräns som gömmer
det den finns för att fånga är sämre än ingen gräns.

**Fyra prov mätte fel sak och rättades:** `kor.sh` rapporterade varje
vanligt testfel som en krasch; `movement.spec` letade efter ett teckenbyte
mellan två bildrutor i riktningsbytet, vilket missar det starkaste
utfallet av alla; samma prov mätte vridhastighet i stället för kurvatur;
och svängradietabellens gångarter var förskjutna ett steg, så raden märkt
"walk" reds i trav.

## Not tested

- **Roblox Studio.** Ingen Studio-runtime finns i den här miljön.
  Telemetrin är sedan senior review inkopplad read-only i klientens
  ridloop (`init.client.luau`) och provad mot en RIKTIG `MovementController`
  som körts verkliga bildrutor (`movement.spec.luau`), inklusive ett prov
  på att avläsningen inte ändrar rörelsen. Det som fortfarande inte är
  provat är Studio-runtimen själv: att `RunService.RenderStepped`-loopen
  beter sig som specen i en riktig klient.
- **Subjektiv game feel.** Kräver Tobias uttryckliga PASS.
- **Render review-build.** Render-tjänsten `srv-dadf7idg1s2s73f1109g` bygger
  från `main` med auto-deploy, inte från den här branchen. En review-build
  för `claude/g02-a-riding-core` finns alltså inte på Render; Netlifys
  `deploy-preview-86` är det som går att öppna i dag. Att lägga upp en ny
  Render-tjänst för branchen är ett infrastrukturbeslut som är Tobias, inte
  mitt.
- **Volten på Roblox.** Den är mätt på webben. Roblox-motsvarigheten kräver
  en MovementController som körts riktiga bildrutor mot en Humanoid, alltså
  Studio. Paritetsspecen jämför i stället styrkanonens siffror, och de är
  numera identiska.
- **Touch visuellt.** Kamerakoden har ingen gren för pekskärm — den läser
  bara `G.rikt` och `G.ride`, och styrningen går genom samma `RIDIN` som
  tangenterna, vilket proven täcker. Att bilden SER rätt ut på en telefon
  är inte visat.
- **Absolut acceleration i m/s² mellan ytorna.** Paritetsspecen prövar att
  tabellerna bär samma tal och att övergångstiderna är samma uppmätta
  sekunder. Att en och samma manöver ger identisk m/s² på båda ytorna
  kräver Studio och är `[ANTAGANDE]` tills det gjorts. Vad som ÄR mätt är
  ordningen och förhållandet mellan gångarterna.
