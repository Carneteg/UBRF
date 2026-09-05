# G02-B — Ryttarens hjälper och hästens svar

Issue #83. Arbetsdokument för gaten: acceptance contract, checkpointer,
mätvärden och kvarstående luckor. Uppdateras vid varje checkpoint.

**Status:** `IMPLEMENTING` (checkpoint 2 av 5 pushad)

Claude sätter aldrig `APPROVED`, `ACCEPTED`, `DONE` eller
`PRODUCT_ACCEPTED` här. Högsta status Claude får sätta är
`READY_FOR_CHATGPT_REVIEW` — se `docs/DELIVERY-PROTOCOL.md`.

---

## 1. Acceptance Contract

### Goal

Ryttarens hjälper ska vara **ridningens språk och inte enhetens**, och
hästen ska svara som en individ på hur de ges. Spelaren ska kunna känna
skillnad på att be rätt och att be fel, och lära sig verklig hästkunskap
av att göra det — inte av att läsa en text om det.

### Observed state (mot `main` efter #86)

1. Ridningen har fyra AXLAR — skänkel, styrning, tygel, sits. Det är
   enhetens språk. Ridningens ord — innertygel, yttertygel, vikt,
   halvhalt — finns inte som något modellen eller telemetrin kan läsa.
2. Halvhalten fanns bara som ett MÖNSTER: tangenten E knuffade skänkel,
   tygel och sits samtidigt och lät modellens mönsterläsare känna igen
   det. Signalen gick alltså inte att mäta, visa eller undervisa om.
3. `balans` och `fokus` är märkta `HARLEDDA` i telemetrin på båda
   ytorna — de har ingen egen källa i modellen.
4. Hästarna skiljer sig på egenskaper (känslighet, framåtbjudning,
   tyngd, förlåtande, skygghet) men det finns inga skolhästprofiler
   som *helheter* med mätbart olika svar.
5. Roblox har inget hjälplager alls (`Telemetri.SAKNAS`).

### Source of truth

- `docs/PRODUCT-CANON.md`, `docs/DELIVERY-PROTOCOL.md`, `docs/ACTIVE-GATE.md`
- PO-ordern i issue #83 (18:14/18:15 2026-09-05)
- `src/model.js` (`K`, `stepRide`), `src/game.js` (`RIDIN`, `stegaInput`)
- `src/riding/hjalper.js`, `src/riding/telemetri.js` (`RID_KANON`)
- `roblox/src/shared/HorseCore/` — `RidKanon.luau` genereras ur webben
- Gate 01:s uppmätta känsla, som inte får regrera

### Required change

1. **Semantiska hjälper** — skänkel, inner-/yttertygel, säte/vikt och
   halvhalt/parad som EGEN signal.
2. **Hästens svar** — fördröjning, känslighet, balans, fokus, spänning
   och energi som riktiga storheter, inte härledningar.
3. **Skolhästprofiler** — minst tre, datadrivna, mätbart olika, utan
   var sin kontroller.
4. **Paritet** — webb och Roblox delar kanoniska regler och data.
5. **Telemetri** — både hjälpen och svaret ska gå att läsa ut.

### Out of scope

- Ny fysikmotor, biomekanik eller simulatornivå på dressyren.
- Nya inputaxlar på någon yta. Semantiken byggs på de kontroller som
  finns; en riktig andra tygelaxel är ett eget produktbeslut.
- Omtrimning av Gate 01:s känsla. Övergångslängder, kurvaturtak,
  gångartsband och kameravärden rörs inte i den här gaten.
- #85 läktar-P0 (pausad av PO).

### Acceptance tests

- `node tools/ridtest.mjs` — hjälpproven går **genom inputlagret**
  (`RIDIN` → `stegaInput` → `stegaRitt`), inte via direktanrop av
  `stepRide`. PO-ordern är uttrycklig på den punkten.
- `bash roblox/tests/kor.sh` — paritetsspecen jämför hjälpkanonen och
  listar de luckor som faktiskt finns.
- `node tools/exportera-ridkanon.mjs --kontrollera` — Roblox läser
  webbens tal, skriver inte av dem.
- Varje ny garanti ska ha en **mutation som gör den röd**. Ett prov som
  aldrig visats kunna falla är inte evidens.

### Human gate

**Ja.** Hur en halvhalt KÄNNS, och om en skolhäst känns som en individ
i stället för som en parameteruppsättning, är game feel och därmed
Tobias sak. Automatiken kan visa att svaren skiljer sig mätbart; den kan
inte säga att skillnaden känns rätt.

### Known uncertainty

- `[ANTAGANDE]` Inner- och yttertygel som HÄRLEDNING ur styr- och
  tygelaxeln, inte som två egna axlar. Billigt att kullkasta: fyll
  `innerTygel`/`ytterTygel` från var sin axel så fungerar allt nedanför
  oförändrat. Motiveringen står i `src/riding/hjalper.js`.
- `[ANTAGANDE]` Vikten följer bågen. Det finns ingen viktaxel; sitsen
  säger hur djupt ryttaren sitter, bågen åt vilket håll vikten går.
- `[KÄND BEGRÄNSNING]` Samlingen faller 0,16 per bildruta utan halvhalt
  (Gate 01:s dynamik). En serie halvhalter bygger därför ingen samling i
  dag, oavsett kvalitet — uppmätt 0,000 för både välridna och slarviga.
  Paradens kvalitet publiceras nu; vad hästen GÖR av den hör till
  checkpoint 2.

---

## 2. Checkpointer

| # | Innehåll | Status |
|---|----------|--------|
| 0 | Skrittfyndet från #83 återverifierat mot main och stängt med mätning | pushad `751b5b4` |
| 1 | Semantiska hjälper: inner-/yttertygel, vikt, paraden som egen signal | pushad `9540e0c` |
| 2 | Hästens svar: fördröjning, känslighet, balans, fokus, spänning, energi | pushad |
| 3 | Minst tre datadrivna skolhästprofiler | ej påbörjad |
| 4 | Roblox: hjälplagret och profilerna till paritet | ej påbörjad |
| 5 | Telemetri, dokumentation, falsifieringsprotokoll | ej påbörjad |

---

## 3. Checkpoint 1 — hjälperna som semantik

### Vad som byggdes

`src/riding/hjalper.js` lägger ridningens ord ovanpå de fyra axlarna.
Axlarna är oförändrade — de är enhetens språk och Gate 01:s kanon.

| Ord | Källa | Härlett |
|-----|-------|---------|
| `skankel` | skänkelaxeln | nej |
| `tygel` | tygelaxeln | nej |
| `sits` | sitsaxeln | nej |
| `styrning` | styraxeln | nej |
| `innerTygel` | tygel + styrutslag | **ja** |
| `ytterTygel` | tygel − styrutslagets eftergift | **ja** |
| `ytterstod` | hur stor del av böjningen yttertygeln bär | **ja** |
| `bojSida` | styrutslagets tecken | ja |
| `vikt` | bågens sida × utslagets styrka | **ja** |
| `parad` | egen kanal från E-tangenten/HALVHALT-knappen | nej |

Paraden går nu hela vägen som egen kanal:
`RIDIN.parad` → `stegaInput` (0,14 s an · 0,10 s kvar · 0,18 s efterge)
→ `a.parad` → modellens flankläsning. Mönsterläsningen finns kvar för
den som rider halvhalten med riktiga hjälper; **båda vägarna mynnar i
samma signal**, och det är den signalen modellen och telemetrin läser.

Hästen läser dessutom HUR paraden reds: `paradKvalitet()` väger skänkeln
mot tröskeln och handen mot kontaktbandet, och resultatet publiceras som
`paradKvalitet` och `paradAlder` i telemetrin.

### Uppmätt, genom inputlagret

| Prov | Resultat |
|------|----------|
| Paraden rör inte de tre axlarna | `parad` 1,00 · skänkel/tygel/sits ±0,000 (var ±0,26–0,28) |
| En parad ur trav | trav → skritt, cue `halvhalt` |
| Samordnad parad (skänkel 0,67, tygel 0,41) | kvalitet **1,00** |
| Slarvig parad (skänkel 0,05, tygel 0,50) | kvalitet **0,46** — men tar ändå ned ett steg |
| Volt på lös tygel | stöd **0,40** (inner 0,60 / ytter 0,25) |
| Volt med kontakten kvar | stöd **0,67** |
| Rakriktning, lös → buren volt | 0,537 → 0,557 (**+3,7 %**) |

Den sista raden är den som säger att semantiken inte är dekoration: den
burna volten har LÄGRE schvung (0,543 → 0,497) och LÄGRE kontakt
(1,000 → 0,820) — tygeln kostar på båda de skalorna — och ändå högre
rakriktning. Yttertygelstödet bär skillnaden mot två motvindar.

### Falsifiering

Sex mutationer, sex röda prov:

| Mutation | Prov som föll |
|----------|---------------|
| Paraden knuffar axlarna igen (gamla envelopen) | axlarna rörde sig 0,260 / 0,270 / 0,280 |
| `stegaInput` returnerar ingen parad | tre prov: kanal, verkan och kvalitet |
| `paradKvalitet()` returnerar en konstant | slarvig parad fick 1,00 |
| `YTTER_SLAPP` = 0 | stöd 0,53 / 0,89 i stället för 0,40 / 0,67 |
| Stödet tas ur `mal.rakriktning` | **ordningen vänder**: 0,609 → 0,597 (−2,0 %) |
| Kanonens `TYGEL_NEUTRAL` glider från modellens | dublettvakten |

Den femte är den viktiga: utan yttertygeltermen blir den burna volten
SÄMRE än den lösa, eftersom schvung och kontakt då får bestämma ensamma.
Det är termen som vänder utfallet, inte mätuppställningen.

### Paritet

`RidKanon.HJALP`, `RidKanon.HJALP_FALT` och `RidKanon.HJALP_HARLEDDA`
genereras ur `src/riding/hjalper.js` och ligger på Roblox-sidan **före**
implementationen, med flit: när Roblox bygger sina hjälper ska den läsa
talen, inte skriva av dem.

Roblox har ännu inget hjälplager. Det är registrerat som två öppna
LUCKOR i paritetsspecen, inte tystat:

- `hjälplager, parad, spänning och mjukhet saknas på Roblox`
- `hjälpernas semantik är byggd på webben, inte på Roblox`

Hemmet är checkpoint 4.

### Not tested

- Roblox runtime. Ingen Studio-åtkomst i den här miljön; Luau-specarna
  körs som moduler under `luau`, inte i Studio.
- Hur paraden KÄNNS. Automatiken visar att kanalen finns, att signalen
  är separat och att kvaliteten skiljer sig — inte att skillnaden känns
  rätt i handen. Det är human gate.

---

## 4. Checkpoint 2 — hästens svar

### Vad som byggdes

`src/riding/svar.js` är nytt. Fyra storheter som förut inte fanns som
tillstånd, plus de två som redan gjorde det:

| Storhet | Före G02-B | Nu |
|---------|-----------|-----|
| känslighet | egenskap hos hästen | oförändrad, läses av svarstiden |
| spänning | tillstånd i modellen | oförändrad, driver balans och fokus |
| **fokus** | `HARLEDDA`: `1 − spänning` | tillstånd — handens stadga, lugnet, utomhus och den lästa halvhalten |
| **balans** | `HARLEDDA`: kurvatur och spänning | tillstånd — yttertygelstöd, svängens fartkrav, övergångar, spänning |
| **fördröjning** | fanns inte | `svarstid`, sekunder från begäran till svar |
| **energi** | fanns inte | tär av arbete, kommer tillbaka i halt |

`_harledda` i telemetrin är därmed **tom**. Fältet står kvar som
kontrakt: nästa härledda storhet ska deklareras där, inte smygas in.

### Att be är inte att få

Cue:n startade förut förloppet i samma bildruta den föll. Nu skiljer
modellen på begäran och svar:

- `beddGangart` — vad ryttaren bad om, sätts när cue:n faller,
- `malGangart` — vad hästen svarat på, sätts när svarstiden gått.

Under väntan skiljer sig de två utan att `iOvergang` är sant: hon har
hört, men inte börjat. Övergångens kanon (`K.OVERGANG`) mäter fortsatt
**förloppet** och inte fördröjningen — de redovisas var för sig, och
regressionsprovet klockar numera förloppet från att det startar. Blandas
de ihop kan provet bli grönt av att den ena växer medan den andra
krymper.

### Balansen har en verkan man känner

Balansen ändrar inte bara ett betyg. En häst som tappat balansen i en
sväng **faller in** på inre skuldran: bågen blir snävare än ryttaren bad
om. Det är den enda storheten i hela G02-B som flyttar hästen från det
ryttaren begärde, och den är därför taggad `[HUMAN GATE]` och
avstängbar med ett tal.

Taket ligger på *begäran*, inte på den integrerade kurvaturen, så P4:s
ändringstak och kurvaturens tröghet gäller oförändrat — infallet kan
inte göra styrningen ryckig, det flyttar var bågen hamnar.

Boten är precis den hjälp punkt 1 gav ryttaren: yttertygeln.

### Uppmätt, genom inputlagret

| Prov | Resultat |
|------|----------|
| Sex hjälper i rad | **6 av 6 besvarade**, sex väntefönster sedda, svarstid 0,142–0,166 s |
| Fördröjningen klockad utifrån | 0,133 s mot redovisade 0,147 s (en bildruta) |
| Välriden parad → svar | kvalitet 1,00 → **0,138 s** |
| Slarvig parad → svar | kvalitet 0,46 → **0,195 s** |
| Tio minuter trav | energi 0,835 → **0,463**, gångarten stod still |
| Fem minuter halt efter det | energi → **0,736** |
| Svarstid pigg → trött | 0,178 → **0,215 s** |
| Välriden halvhalt | fokus 0,797 → **0,875** (+9,8 %) |
| Ostödd volt | balans **0,733**, ridd radie 3,13 m |
| Buren volt | balans **0,852**, ridd radie 3,24 m (**3,3 % snävare än bett**) |
| Tolv sekunder rakt efteråt | balans **0,999** |

### Falsifiering

Åtta mutationer, åtta röda prov:

| Mutation | Prov som föll |
|----------|---------------|
| Ingen fördröjning alls (alla svarstermer 0) | tre prov: kontroll, samordning, energi |
| `SVAR_KLAR` = 0 | välriden och slarvig parad fick samma svar (0,238 / 0,241 s) |
| `ENERGI_TAPP` = 0 | energi 0,837 → 0,837 |
| `FOKUS_PARAD` = 0 | fokus 0,797 → 0,791 |
| `INFALL_MAX` = 0 | båda volterna 3,38 m — ingen faller in |
| `BALANS_YTTER` = 0 | balans 1,000 i båda volterna |
| Telemetrin räknar balans/fokus själv igen | de skilde sig från modellens |
| Väntan konsumeras aldrig | **åtta prov**, bland dem "1 hjälp, 0 svar" |

Den sista är den viktiga: den visar att kontroll-först-provet faktiskt
fångar en hjälp som tappas bort under fördröjningen.

### Två fel av mina egna, rättade

**Tydlighet mätt som impulsens storlek gick inte att göra röd.** Första
versionen lät svarstiden bero på hur långt över tröskeln framåtimpulsen
gick. Genom det riktiga inputlagret faller cue:n på den *första* bildruta
rampen passerar tröskeln, och rampen går lika fort oavsett hur långt
tangenten trycks — marginalen är alltså ~0 för både ett halvt och ett
helt tryck. Termen hade varit en konstant förklädd till ett mätvärde.
Tydlighet är i stället **samordning**: skänkeln framför tröskeln och
handen i kontaktbandet, samma formel som paradens kvalitet. Den
varierar mätbart (0,46–1,00) och provet ligger där.

**Kontroll-först-provet var grönt utan att ha sett efter.** Det körde i
0,35-sekundersklumpar, så väntefönstret var redan passerat när provet
tittade — och band-kontrollen blev sann av att ingenting hade mätts
(min 9, max 0 mot bandet 0,06–0,48). Nu räknas fönstren och provet
kräver ett per hjälp.

### Paritet

`RidKanon.SVAR` genereras ur `svar.js`. Paritetsspecen provar att
kanonen är hel och rimlig — spelbart svarsband, att en tydligare hjälp
bara kan göra svaret snabbare, att galoppen kostar mer energi än
skritten och halten ger tillbaka, att balansen faller fortare än den
byggs, och att infallet är begränsat.

Roblox har varken hjälplager eller svar. Tre öppna `LUCKA` med
checkpoint 4 som hem; `Telemetri.SAKNAS` är tio fält och listan provas
exakt, så ett nytt hål blir rött.

### Not tested

- Roblox runtime.
- **Hur fördröjningen känns.** 0,14–0,17 s för en pigg häst, upp mot
  0,22 s för en trött. Att det är rätt tal är game feel och därmed
  Tobias sak — det är den mest kännbara ändringen i hela checkpointen.
- **Om infallet läses som karaktär eller som trasig styrning.** Human
  gate, och avstängbart med ett tal.
