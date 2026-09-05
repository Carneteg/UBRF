# G02-B — Ryttarens hjälper och hästens svar

Issue #83. Arbetsdokument för gaten: acceptance contract, checkpointer,
mätvärden och kvarstående luckor. Uppdateras vid varje checkpoint.

**Status:** `READY_FOR_CHATGPT_REVIEW` (alla fem checkpointer pushade)

Det är den högsta status Claude får sätta. `READY_FOR_PRODUCT_ACCEPTANCE`
sätts av ChatGPT efter oberoende review; `PRODUCT_ACCEPTED` bara av Tobias.

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
| 2 | Hästens svar: fördröjning, känslighet, balans, fokus, spänning, energi | pushad `ca853a3` |
| 3 | Minst tre datadrivna skolhästprofiler | pushad `bc77fbb` |
| 4 | Roblox: hjälplagret och profilerna till paritet | pushad `8171f3b` |
| 5 | Telemetri, dokumentation, falsifieringsprotokoll | pushad |

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

---

## 5. Checkpoint 3 — skolhästprofilerna

### Vad som byggdes

Fyra profiler i `SKOLHAST_PROFILER` (`src/riding/svar.js`). En profil är
**sex multiplikatorer på svarsmodellen** — inte en egen kodväg. Byter man
profil på en häst ändras hur hon svarar, inte vilken kod som kör.

| Profil | svar | klar | balans | tapp | ater | fokus |
|--------|------|------|--------|------|------|-------|
| `skolhast` — pålitlig | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 |
| `kanslig` — svarar på lite | 0,72 | 1,45 | 1,35 | 1,15 | 1,00 | 1,25 |
| `tung` — tar tid, står stadigt | 1,38 | 1,30 | 0,70 | 1,25 | 0,85 | 0,85 |
| `arbetsvillig` — orkar länge | 0,86 | 0,85 | 0,90 | 0,80 | 1,20 | 1,05 |

`skolhast` är 1,00 rakt igenom och därmed modellens utgångsläge. Varje
annan profil mäts mot den, och en häst utan tilldelad profil beter sig
exakt som modellen alltid gjort.

### Tilldelningen har källa

Profilerna kommer ur **ridskolans egna beskrivningar** av hästarna
(snapshoten `references/data/ubrf-hastar-2026-09-01.json`, upstream
ubrf.se/hastar). Citatet står i kommentaren på varje rad i
`src/spel/hastar.js`:

- *"Han är en känsligare individ."* → Hamilton, `kanslig`
- *"kräver en mjuk balanserad ryttare"* → Conor, `kanslig`
- *"Lite åt det tyngre hållet."* → Curre, `tung`
- *"Kräver sin ryttare för att jobba bra."* → Replay, `tung`
- *"positiv inställning till arbetet. Alltid ambitiös."* → Hjärtat, `arbetsvillig`

**16 hästar** har källtext bakom sin profil. **17 hästar** har det inte —
beskrivningen säger inget om ridkänsla, eller är *"Mer info kommer."* — och
de ligger kvar på `skolhast`, märkta `profilStatus: "SAKNAR_KALLA"`. Det
är en deklarerad frånvaro av evidens, inte en tilldelning på känsla.

### Uppmätt, genom inputlagret

**Samma häst, bara profilnamnet bytt** (kloner av Cosmo — känslighet,
tyngd och utbildning identiska, så skillnaden kan bara komma från
profilen):

| Profil | svarstid | balans i ostödd volt | energi efter 8 min |
|--------|----------|----------------------|--------------------|
| `kanslig` | **0,060 s** | 0,559 | 0,446 |
| `arbetsvillig` | 0,128 s | 0,711 | **0,565** |
| `skolhast` | 0,148 s | 0,678 | 0,497 |
| `tung` | **0,213 s** | **0,777** | 0,412 |

**Tre riktiga UBRF-hästar**, samma ritt: Crokino (känslig) 0,060 s ·
Cosmo (skolhäst) 0,148 s · Curre (tyngre) 0,197 s. Energi efter åtta
minuter: Hjärtat 0,565 mot Curre 0,412.

### Falsifiering

| Mutation | Prov som föll |
|----------|---------------|
| Alla profiler blir 1,00 rakt igenom | två prov: kloner och riktiga hästar |
| `svarProfil()` returnerar alltid `skolhast` | samma två |
| En häst får profil utan källtext | källkedjeprovet |
| En profil får ett eget fält | strukturprovet ("inte fyra kodvägar") |

De två första är olika fel — data som är lika, respektive data som inte
läses — och båda faller på samma prov. Det är avsikten: provet frågar om
profilen **verkar**, inte om den finns.

### Paritet

`RidKanon.PROFILER` genereras ur `svar.js`; varje hästs `profil` följer
med till `UBRFSpelData` som vanlig hästdata. `spelkanon.spec` korsprovar
att varje profilnamn i hästdatan finns i kanonen — ett namn som inte
finns skulle annars tyst falla tillbaka på utgångsläget, och då rider man
en annan häst än den man valde — att minst tre profiler är i bruk och
inte bara definierade, och att `skolhast` är 1,00 rakt igenom också på
Roblox-sidan.

Roblox har fortfarande ingen svarsmodell att köra profilerna genom. Det
är checkpoint 4.

### Not tested

- Roblox runtime.
- **Om de fyra känns som fyra olika hästar.** Automatiken visar att de är
  mätbart olika; om skillnaden är den rätta karaktären är human gate.
- `kanslig` bottnar i svarstidens golv (0,06 s) för en välriden hjälp.
  Det är golvets syfte, men det betyder att samordningen inte går att
  skilja åt på henne — hon svarar direkt oavsett.

---

## 6. Checkpoint 4 — Roblox till paritet

### Vad som byggdes

Två nya delade moduler på Roblox-sidan, båda spegelbilder av webbens:

- `HorseCore/Hjalper.luau` — hjälpsemantiken, läser `RidKanon.HJALP`
- `HorseCore/Svar.luau` — svarsmodellen och profilerna, läser
  `RidKanon.SVAR` och `RidKanon.PROFILER`

**Inga tal skrivs av.** Båda läser den kanon som genereras ur webbens
moduler av `tools/exportera-ridkanon.mjs`. Ändras en konstant på webben
ändras den på Roblox, och `--kontrollera` faller om exporten inte körts.

`MovementController` fick svarstiden mellan begäran och svar, balansen,
energin och infallet. `Input` fick tygeln och paraden — tygeln som en
**analog** axel på höger avtryckare, vilket är bättre än webbens binära
Space och är avsikten: plattformsspecifik input, samma regler.

`loco.stamina` fanns sedan Gate 01 men drogs aldrig. Nu **är** den
energin, i sin egen skala. En sanning om hur trött hon är, inte två.

### Paritet bevisas på formlerna, inte på bokföringen

Att båda ytorna har samma konstanter bevisar ingenting om att de räknar
lika. `RidKanon.PROV` innehåller därför **webbens egna svar** på bestämda
indata, räknade av `hjalper.js` och `svar.js` när exporten kördes.
Paritetsspecen kör Roblox implementation på samma indata och jämför:

| Prov | Jämförelser | Största avvikelse |
|------|-------------|-------------------|
| hjälpsemantiken | 20 | 5,0 · 10⁻⁷ |
| paradens kvalitet | 5 | 1,1 · 10⁻⁷ |
| svarstiden, profil för profil | 5 | 1,4 · 10⁻¹⁷ |
| balansen vid spänning noll | 4 | 4,0 · 10⁻⁷ |
| infallet | 4 | 0 |
| energitakten, gångart för gångart | 16 | 5,0 · 10⁻⁷ |

Driver de två isär blir det rött, även om varenda konstant fortfarande
stämmer.

### En riktig bildruta, inte en handbyggd tabell

`movement.spec` kör en riktig `MovementController` och provar samma fyra
saker som webbens `ridtest`:

| Prov | Resultat |
|------|----------|
| Sex hjälper i rad | **6 av 6 besvarade**, svarstid 0,138–0,163 s |
| Åtta minuter trav | energi 0,999 → **0,701**, stamina 70,1 speglar den |
| Fem minuter halt efter det | energi → **0,971** |
| Volt utan kontakt | stöd 0,40, balans 0,718, ridd radie **2,20 m** |
| Volt med kontakten kvar | stöd 0,94, balans 0,970, radie **2,36 m** (7,0 % snävare än bett) |
| Telemetrin ur en riktig bildruta | bara `fokus`, `mjukhet`, `spanning` saknas |

### Vad som INTE portades, och varför

`Telemetri.SAKNAS` gick från tio fält till **tre**, och de tre har ett
gemensamt skäl:

- **`mjukhet`** — handens stadga över tid, ett eget delsystem på webben.
- **`spanning`** — detsamma.
- **`fokus`** — kräver båda.

Följden redovisas öppet i `HorseCore/Svar.luau` i stället för att döljas:
svarstiden på Roblox saknar fokustermen (0–`SVAR_FOKUS` sekunder) och
balansen saknar spänningstermen. Termerna anropas med sina **neutrala
element** — 1 respektive 0 — alltså med noll bidrag i stället för med en
gissning. Att fylla dem med konstanter hade gett paritet i siffran men
inte i upplevelsen, och det är precis vad paritetsregeln finns för att
förhindra. Hemmet är G02-C.

**Sitsen** finns inte som axel på Roblox: Shift och Ctrl är
gångartsknappar sedan Gate 01, och att flytta dem är en inputändring
utanför G02-B. `sits` och `vikt` står därför i `Hjalper.SAKNAS` och
utelämnas ur hjälperna hellre än fylls. Paradens kvalitet väger därmed
två hjälper på Roblox och tre på webben — deklarerat, inte gömt i en
formel som ser lika ut.

### Falsifiering

| Mutation | Prov som föll |
|----------|---------------|
| Roblox räknar yttertygelstödet på sitt eget vis | hjälpsemantiken (avvikelse 5,7 · 10⁻²) |
| Profilen läses inte på Roblox | tre paritetsprov: svarstid, balans, energitakt |
| Svaret går till fel gångart (hjälpen tappas) | **17 prov** i movement.spec |
| `INFALL_MAX` = 0 | båda volterna 2,38 m — ingen faller in |
| Energin dras inte | 1,000 → 1,000 på åtta minuter |
| Pekskärmens tygel blir en impuls | tygeln HÅLLS-provet |
| Paraden blir hållbar i stället för en impuls | 30 extra bildrutor |

Två av dem är värda en rad var. Den andra visar att profilerna verkligen
läses på Roblox och inte bara finns i tabellen. Den tredje visar vad som
händer om fördröjningen tappar bort en hjälp — hela gångartstrappan
faller, inte bara ett prov.

### Not tested

- **Roblox runtime.** Specarna körs som moduler under `luau`, inte i
  Studio. Att en riktig `MovementController`-bildruta producerar svaret
  är provat; att det känns rätt i Studio är det inte.
- **Q och F som tangentval.** Att kontakten hamnar på Q och halvhalten på
  F är ett val, inte ett faktum — `E` är upptagen av sitt upp/av sedan
  Gate 01. Human gate.
- **Om den analoga tygeln på avtryckaren känns bättre än en knapp.**

---

## 7. Checkpoint 5 — kontraktet G02-C läser

### Vad som byggdes

Ordern punkt 5: *"Telemetri som exponerar både hjälp och respons."* Att
fälten finns räcker inte — en läsare måste kunna se **vilka fält som är
vad**, annars får den gissa, och en gissning i ett kontrakt är en bugg
som väntar.

Telemetrin publicerar därför indelningen som data:

- `_hjalpFalt` / `RidKanon.HJALP_FALT` — vad ryttaren gör (10 fält)
- `_svarFalt` / `RidKanon.SVAR_FALT` — vad hästen svarar (9 fält)

Listorna kommer ur modulerna själva, inte ur en handskriven uppräkning,
och exporteras till Roblox där paritetsspecen provar att båda ytorna
publicerar **samma** indelning.

### Provet är strukturellt, inte en uppräkning

Fyra påståenden på var sin yta:

- varje svarsfält finns i telemetrikontraktet,
- hjälp och svar är två **skilda** listor — inget fält får vara båda,
- Roblox läser samma indelning som webben, inte en egen,
- varje svarsfält fylls, eller står i `Telemetri.SAKNAS`.

På webben körs det mot den **levande ritten** — samma telemetri spelet
självt skriver varje bildruta, efter en riktig liten ritt med uppgång,
parad och volt:

> bad `skritt` · går `skritt` · cue `halvhalt` · yttertygelstöd 0,78 →
> balans 0,922 · svarstid 0,152 s · paradkvalitet 0,93 · fokus 0,802 ·
> energi 0,834 · inga härledda fält

Det är raden G02-C ska kunna läsa: **vad ryttaren bad om, och vad hästen
gjorde av det.**

### Ett fel i själva provharnesket, rättat

Falsifieringen avslöjade en svaghet i `ridtest.mjs`: att ta bort
`svarstid` ur telemetrin fick sviten att **krascha** på
`undefined.toFixed()` vid prov 43 av 62, i stället för att bli röd. Rött
blev det — exitkoden — men utan att peka på vad som saknades, och de
nitton proven därefter sa ingenting alls.

Nu formaterar `nf()` ett saknat fält som `—`, och samma mutation ger tre
tydliga rader som namnger fältet:

    FEL  fördröjningen är verklig … telemetrin visar — s
    FEL  telemetrin skiljer på HJÄLPEN och SVARET … SVAR UTAN VÄRDE: svarstid
    FEL  och kontraktet räcker … svarstid — s

---

## 8. Falsifieringsprotokoll — hela G02-B

Varje garanti i den här gaten har en mutation som gör den röd. Det är
kravet i `docs/DELIVERY-PROTOCOL.md`: ett prov som aldrig visats kunna
falla är otillräcklig evidens.

| # | Mutation | Prov som föll |
|---|----------|---------------|
| 1 | Paraden knuffar axlarna igen (gamla envelopen) | axlarna rörde sig 0,260 / 0,270 / 0,280 |
| 2 | `stegaInput` returnerar ingen parad | kanal, verkan och kvalitet |
| 3 | `paradKvalitet()` returnerar en konstant | slarvig parad fick 1,00 |
| 4 | `YTTER_SLAPP` = 0 | stöd 0,53 / 0,89 i stället för 0,40 / 0,67 |
| 5 | Stödet tas ur `mal.rakriktning` | **ordningen vänder**: 0,609 → 0,597 |
| 6 | Kanonens `TYGEL_NEUTRAL` glider från modellens | dublettvakten |
| 7 | Ingen fördröjning alls | kontroll, samordning och energi |
| 8 | `SVAR_KLAR` = 0 | parader fick samma svar (0,238 / 0,241 s) |
| 9 | `ENERGI_TAPP` = 0 | energi 0,837 → 0,837 |
| 10 | `FOKUS_PARAD` = 0 | fokus 0,797 → 0,791 |
| 11 | `INFALL_MAX` = 0 | båda volterna 3,38 m |
| 12 | `BALANS_YTTER` = 0 | balans 1,000 i båda volterna |
| 13 | Telemetrin räknar balans/fokus själv igen | talen skilde sig från modellens |
| 14 | Väntan konsumeras aldrig | **åtta prov**, bland dem "1 hjälp, 0 svar" |
| 15 | Alla profiler blir 1,00 rakt igenom | kloner och riktiga hästar |
| 16 | `svarProfil()` ger alltid `skolhast` | samma två |
| 17 | En häst får profil utan källtext | källkedjeprovet |
| 18 | En profil får ett eget fält | strukturprovet |
| 19 | Roblox räknar yttertygelstödet på sitt eget vis | hjälpsemantiken (5,7 · 10⁻²) |
| 20 | Profilen läses inte på Roblox | svarstid, balans och energitakt |
| 21 | Svaret går till fel gångart | **17 prov** i movement.spec |
| 22 | `INFALL_MAX` = 0 på Roblox | båda volterna 2,38 m |
| 23 | Energin dras inte på Roblox | 1,000 → 1,000 på åtta minuter |
| 24 | Pekskärmens tygel blir en impuls | tygeln HÅLLS-provet |
| 25 | Paraden blir hållbar | 30 extra bildrutor |
| 26 | Hjälp och svar slås ihop till en lista | ÖVERLAPP: `tygel` |
| 27 | Ett svarsfält publiceras inte | tre prov namnger `svarstid` |

### Fyra fel av mina egna, hittade av falsifieringen och rättade

1. **Tydlighet mätt som impulsens storlek gick inte att göra röd.** Genom
   det riktiga inputlagret faller cue:n på första bildrutan rampen
   passerar tröskeln, och rampen går lika fort oavsett hur långt
   tangenten trycks. Termen hade varit en konstant förklädd till ett
   mätvärde. Tydlighet är i stället **samordning**.
2. **Kontroll-först-provet var grönt utan att ha sett efter.** Det körde
   i 0,35-sekundersklumpar, så väntefönstret var passerat när provet
   tittade — bandkontrollen blev sann av att ingenting mätts (min 9, max
   0 mot bandet 0,06–0,48).
3. **Yttertygelstödet lästes efter svängen** i Roblox-provet, där
   styrutslaget är noll och stödet därför 1 för båda ritterna. Provet
   var grönt av att mäta fel ögonblick.
4. **`ridtest.mjs` kraschade i stället för att bli röd** när ett
   kontraktsfält togs bort. Se checkpoint 5.

---

## 9. Vad som återstår, och var det hör hemma

| Öppet | Hem |
|-------|-----|
| `mjukhet` och `spanning` saknar källa på Roblox | G02-C |
| `fokus` följer av de två | G02-C |
| Sitsen finns inte som axel på Roblox (Shift/Ctrl är gångartsknappar) | eget inputbeslut |
| Samlingens dynamik (faller 0,16/bildruta) är Gate 01:s | eget beslut |
| Inner-/yttertygel som två riktiga axlar i stället för en härledning | eget inputbeslut |
| 17 hästar utan källtext ligger på `skolhast` | ny evidens från Tobias |

## 10. Vad som kräver Tobias PASS

Automatiken kan visa att storheterna finns, hänger ihop och skiljer sig
mätbart. Den kan inte säga att de känns rätt. Fyra saker är därför human
gate:

1. **Fördröjningen.** 0,14–0,17 s för en pigg häst, upp mot 0,22 s för en
   trött. Det är den mest kännbara ändringen i hela gaten.
2. **Infallet.** Att hästen alls får avvika från den båge ryttaren bad
   om. Avstängbart med `SVAR_KANON.INFALL_MAX = 0`, utan annan kod.
3. **Om de fyra profilerna känns som fyra olika hästar** — inte bara
   mäter olika.
4. **`Q` och `F` som Roblox-tangenter** för tygel och halvhalt. `E` är
   upptagen av sitt upp/av sedan Gate 01.
