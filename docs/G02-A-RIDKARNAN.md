# G02-A — Ridkärnans konsolidering (issue #82)

Status: `READY_FOR_CHATGPT_REVIEW` (Claudes högsta normala status enligt
`docs/DELIVERY-PROTOCOL.md`). Ingen del av det här dokumentet är
produktacceptans.

**G02-A kan inte nå `PRODUCT_ACCEPTED` medan de fyra `BLOCKERAR`-raderna i
paritetsregistret står öppna.** De är skillnader i kärnrörelsen som
påverkar känslan, och att jämna ut dem är Tobias produktbeslut.

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

### Öppna produktbeslut — INTE ett parity pass

Efter senior review av #86 (blocker A) är registret skilt från
paritetskontrollerna, i specen och här. Raderna nedan är **inte**
godkännanden och räknas inte som paritet. De skrivs som `PO`, aldrig `OK`,
och de **blockerar produktacceptans av G02-A**.

Värdena kontrolleras ändå. Stämmer ett av dem inte längre har någon ändrat
en feel-siffra i tysthet, och då blir raden `FEL`. Registret dokumenterar
alltså skillnaden utan att sanktionera den, och skyddar samtidigt mot att
den ändras utan beslut.

| Avvikelse | Webb | Roblox |
| --- | --- | --- |
| Kurvaturtak vid full styrning | 0,42 1/m ⇒ 2,4 m radie | 0,30 1/m ⇒ 3,3 m radie |
| Galoppens svängfaktor | 0,52 | canter 0,62 |
| Galoppens övre bandgräns | 8,00 m/s | canter ≤ 7,00 m/s |
| Fyrsprång | saknas | `gallop` 7,20–11,0 m/s |
| Cykellängd, skritt/trav/galopp | 1,61 / 2,21 / 3,50 m | 1,45 / 2,13 / 3,20 m |
| Hjälplager, spänning, mjukhet, balans, fokus | finns | saknar källa |

Fyra av dem är klassade `BLOCKERAR` (kärnrörelse som påverkar känslan):
kurvaturtaket, galoppens svängfaktor, galoppens övre bandgräns och
cykellängden. Två är klassade `LUCKA` (saknad funktion, G02-B:s arbete):
fyrsprånget och hjälplagret.

De två första är nya fynd ur det här arbetet och de tyngsta: **samma
styrutslag ger olika snäv volt på de två ytorna.** Full styrning i skritt
är 2,4 m radie på webben mot 3,3 m på Roblox — nästan en meter, alltså
inte en avrundning.

Att jämna ut någon av dem **ändrar ridkänslan** och är ett produktbeslut,
inte något en konsolidering får göra på eget initiativ. De ligger därför
kvar som de är, synliga i varje testkörning — men de gör också att G02-A
inte kan nå `PRODUCT_ACCEPTED` förrän Tobias har avgjort dem.

Tidskonstanterna för att lägga sig i och räta upp sig ur en båge
(0,13 respektive 0,19 s) och svängfaktorerna för halt, skritt och trav
stämmer redan, och specen kräver att de fortsätter göra det.

Cykellängdsavvikelsen är sedan tidigare dokumenterad i `Gaits.luau` och
`roblox/docs/HASTRIGG-KRAVSPEC.md` § 4; den står nu också i en körning i
stället för bara i en kommentar.

## Gate 01-styrkanonens proveniens

Senior review av #86 frågade om dagens värden verkligen är Gate 01:s, eller
om kanonen har glidit. Spårat med `git log -L`:

| Konstant | Införd | Ändrad sedan dess |
| --- | --- | --- |
| `KAPPA_MAX = 0,42` (webb) | `33559d9` — Gate 01-committen | nej |
| `GANGSVANG` (webb) | `33559d9` — Gate 01-committen | nej |
| `CurvatureMax = 0,30` (Roblox) | `58a8030` — Gate 01:s Roblox-port | nej |

**Ingen drift.** Ingen av dem har rörts efter sin införandecommit.

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

Avvikelsen mot Roblox är däremot **född i porteringen**: `58a8030` gav
Roblox samma formulering men egna tal, och Gate 01-auditens paritetstabell
(rad 283) godkände raden uttryckligen på *formuleringen* — "samma
formulering sedan `58a8030`; talen skiljer med Roblox egna gångartstempon".
Det är precis den invändning senior review nu gör på G02-A-nivå: samma
formulering är inte samma känsla. Beslutet ligger hos Tobias.

## Volten — styrutslaget mätt som en ridd bana

#81 visade vad som händer när ett test provar formeln i stället för
banan: formeln stämde, och läktaren gick ändå inte att gå upp på. Volten
mäts därför på samma sätt som en ryttare rider den — fast styrutslag,
samplat läge ur den körande ridloopen, minsta-kvadrat-cirkel på punkterna.

| Mätning | Resultat |
| --- | --- |
| Full styrning, trav | ridd diameter **8,25 m**, största avvikelse från cirkeln **1,0 cm** över 240 punkter |
| Samma, mot kurvaturen | ridd radie **4,12 m** = 1/κ **4,12 m** |
| 0,45 styrutslag, trav | ridd radie **9,16 m** = 1/κ **9,16 m**, alltså en volt på **18,3 m** |
| Kurvaturlagen | κ 0,1091 = styrutslag 0,324 × gångartens tak 0,3368 |

Två saker värda att notera för produktbeslut:

1. **0,45 styrutslag i trav ger en 18,3 m volt i en 18,4 m bred hall.**
   Volten ryms alltså precis, och rids den inte mitt i banan tar den i
   sargen. Det är ett mätresultat, inte ett fel — men det är värt att veta
   innan en lektion ber spelaren rida en volt var som helst i ridhuset.
2. Insatt styrutslag 0,45 blir **0,324** efter hjälplagrets utjämning.
   Kurvaturen följer den utjämnade hjälpen, inte råinsatsen.

## Evidens

`node tools/ridtest.mjs` — 13 kontroller, webben, i riktig runtime:
Gate 01:s normtempon och band, gångartsstegen både ur `Gait.forTempo` och
genom att faktiskt köra `stepRide`, övergångskontraktet, telemetrins fält,
identiteten `vridhastighet = kurvatur × tempo`, härledningsmärkningen,
upp-/avsittning, och två live-fall som startar en riktig ritt i spelet.

`bash roblox/tests/kor.sh` — 13 specar, `paritet` inräknad.

### Falsifiering

Varje central kontroll har visats kunna bli röd:

| Mutation | Utfall |
| --- | --- |
| telemetrianropet ur `stegaRitt()` | FEL — `G.telemetri saknas` |
| `ridSittUpp` ur `sittUpp()` | FEL — `ritt false/null` |
| `ridSittAv` ur `startaVandring()` | FEL — `vandring true` |
| Roblox trav-norm 3,20 → 3,30 | FEL — normtempo trav/trot, + cykellängden |
| Roblox hysteres 0,35 → 0,30 | FEL — hysteresen |
| Roblox tröskel 4,45 → 4,60 | FEL — trösklarna |
| `SAKNAS` påstår att `spanning` finns | FEL — deklarerade luckor |
| webbens `HYST` ändrad utan omexport | FEL — `--kontrollera` osynk |
| samma, efter omexport | FEL — hysteresen i paritetsspecen |
| Roblox `CurvatureTauPress` 0,13 → 0,16 | FEL — tidskonstanten |
| Roblox trot `turn` 0,82 → 0,75 | FEL — svängfaktorn |
| `GANGSVANG` omdöpt i `src/game.js` | exporten avslutar med kod 1 i stället för att exportera en nolla |
| `omega = κ · tempo · 1,1` | FEL — den ridna radien slutar vara 1/κ |
| `KAPPA_MAX` 0,42 → 0,50 | FEL — kurvaturlagen |
| `GANGSVANG.trav` 0,82 → 0,70 | FEL — kurvaturlagen och den ridna volten |

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
  Studio. Paritetsspecen jämför i stället styrkanonens siffror, och de två
  som skiljer sig står i registret ovan.
