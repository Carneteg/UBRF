# UBRF — låst leveransmatris (completion first)

**Beslut:** Tobias, förmedlat i PR #264, kommentar `5843082008`
(COMPLETION_FIRST_INFRA1_20260926), som ersätter planeringsstoppet i
`5842944422`. Planen som den bygger på: `5842982274`.
**Skrivande ägare av filen:** Claude (ägarsession `3695fbae`). Ändringar i
ordning, scope eller status kräver en ny order; ingen annan agent skriver här.
**Bas när matrisen låstes:** `ecb2f2e11d63dbc3e325a6b1d70c8d48136c0869`.

## Ordning

1. Infrastruktur
2. Instruktör
3. Tävling
4. Hus
5. Byggnader och området
6. Utrustning
7. Häst
8. Samlat slutspeltest

Nödvändiga delade beroenden byggs före den komponent som behöver dem. Det gör
dem inte till en ny produktprioritet. De är inte bara kontrakt utan
beteende: den faktiska observationen av ridväg, rytm och hinder (B3, B4)
måste finnas och mätas innan en konsument (instruktörens råd, domaren)
bygger på den.

**Scope:** hela anläggningen och alla 22 arbetspaket i #266 (A1–F3),
inklusive NPC-medtävlare och multiplayer. Inga nya webbfeatures; Roblox PC
först. Det gamla kravet att #264 ska vara produktaccepterad och mergad före
#266 är ersatt för *implementation*, inte för *release*.

## Statusnivåer

Varje rad har exakt en av dessa. En nivå kräver alla nivåer före den.

| Nivå | Betyder | Vem sätter den |
|---|---|---|
| `EJ_PÅBÖRJAD` | inget byggt i denna ordning | — |
| `UPPSKJUTEN` | medvetet flyttad till slutspeltestet; NOT_TESTED, inte PASS | ordern |
| `BYGGT` | kod och fokuserade prov lokalt, falsifierat | Claude |
| `GRANSKAT` | oberoende review av diff och prov | Codex/ChatGPT |
| `INTEGRERAT` | inkopplad i spelvägen, regressionssviten grön | Claude, efter review |
| `SPELVERIFIERAT` | provad i det samlade slutspeltestet | Tobias |

`BYGGT` är aldrig spelbarhet. Bänkbevis märks `BANK_ONLY`. Slutspeltestet
körs först när allt överenskommet är integrerat och granskat, och med
Tobias uttryckliga omstart.

## Oförändrade säkerhetsgränser

- ingen push, publicering, CI-dispatch/omkörning som kan publicera, eller merge,
- ingen radering, stash eller reset,
- ingen överskrivning av `UBRF-PLAYTEST.rbxlx` eller originalstartplacen,
- ingen Rojo, ändring av behörigheter eller säkerhetsbypass,
- inga riktiga DataStore-skrivningar,
- ingen `PRODUCT_ACCEPTED` från en builder,
- `src/varld3d.js` (annan skrivare) och `.claude`-inställningarna rörs inte,
- webben, touch, positiv kvinnlig Ugneta och valet SV/EN bevaras,
- nya kostnader och all mänsklig acceptans är Tobias beslut.

## Grindar som måste passeras före beroende arbete

**G-MILJÖ — överlämning av miljön.** Claude äger miljöimplementationen först
efter en kontrollerad överlämning:
1. inventera Replits befintliga miljöarbete (PR #131/#132, gren
   `replit/pr-131-theory-fidelity`), accepterat innehåll och referenser,
2. fastställ vilka filer som byter ägare,
3. få överlämningen kvitterad.

Till dess görs inga miljöändringar och ingen andra skrivare startas. Tills
vidare gäller `docs/ENVIRONMENT-DELIVERY.md` för allt som inte är överlämnat.

**G-MILJÖ, begränsad överlämning för INFRA-2B2 (2026-09-26).** Tre filer rördes, bara för hindrens
metadata. Före ändringen var alla tre rena i arbetsträdet:
- `src/site.js` (senast `b0e6e56`),
- `roblox/buildings/UBRFKomplex.luau` (genererad, `exportera-geometri --kontrollera` i synk),
- `roblox/buildings/Anlaggningen.luau` (senast `757aa90`).

Replits senaste ändring i filerna är `cc3dd7b` (2026-09-07). Ändringen är tre `id`-fält i
`RIDHUSINNE.hinder` och attributet `HinderId` på bommen. Läge, mått, material, kollision och
namn är oförändrade, och det är provat. Ingen annan miljöfil rördes, och ingen
ägarkonflikt fanns. Resten av miljön är inte överlämnad.

**G-MILJÖ, begränsad överlämning för INFRA-PLATS1 (2026-09-26).** `Anlaggningen.luau` var ren
(senast `47063af`). Tillägget är attributet `PlatsId` på "Ridbanan" (`ridhus_bana`) och
"Dressyrlayout 20x60" (`ridhus_dressyr`). Ingen geometri, inget material, ingen kollision
och inga koordinater. Ett försök med `PlatsId` på "Sarg syd" togs bort igen före commit,
eftersom öppningssteget sågar den delen i bitar utan attribut.

**G-ASSET — hästens källa.** Vald asset är *Horse Rigged All Gaits*, inte K3.
Den saknade historiska `.blend`-källan är något annat än dagens
`roblox/assets/hastvisualer-k3.rbxmx`. Följande ska lösas tidigt i
infrastrukturen, före utrustningens slutförande:
- källa och rättigheter,
- offline-skala,
- ben och benkedjor,
- fästpunktskontraktet (sadel, träns, tyglar, ryttare).

Ingen uppladdning av assets utan egen order.

Status efter INFRA-4A (2026-09-26): källsidan är verifierad som etikett, källkedjan
CC0/CC-BY är oklar (`[REFERENCE GAP]`), och den lokala filen saknas (`BLOCKED`). Se
`docs/ASSET-SOURCE-OF-TRUTH.md`, «Horse Rigged All Gaits».

**G-REGEL — tävlingsregler.** Codex verifierar regelversion och klassdetaljer
för clear round, A och A:0 samt LC:1, LC:2 och LB:1 före respektive
implementationsorder. Officiella program kräver rättigheter. Annars används
egna träningsprogram med tydligt egna namn. Ett blockerat officiellt program
kopieras eller felmärks aldrig.

**D4-RÄTT — varaktig, servervaliderad rätt till ett pris (KRÄVS, pending
konsument).** `Sparning.registreraPris` är lokal förberedelse. `true` betyder
bara att posten ligger i en sessions minne:
- två sessioner kan båda få true för samma id,
- en skrivskyddad session får true fast inget kan sparas.

Före varje pris, rosett eller belöning i spel (D4, deltagarminne, lärandemärke)
krävs en egen servervaliderad rätt som härleds ur en **bekräftad** skrivning.
Den ska hantera tvetydiga skrivningar (landade men kastade), omförsök och
samtidiga sessioner. Presentationen härleds ur den bekräftade rätten. Ingen
oåterkallelig utdelning får ske på det lokala svaret eller inifrån
`UpdateAsync`-callbacken. Hela belöningssystemet byggs först i D4, inte i
INFRA-1.

**G-REFERENS.** Referensluckor förblir uttryckligen markerade arbetsantaganden
(`[REFERENCE GAP]`, `[antagande]`), aldrig påhittade fakta.

## Matris

Kolumner:
- **Källor:** order och issue.
- **Finns:** kontrollerat mot koden på `ecb2f2e`.
- **Gap:** det som saknas.
- **Beror på:** rader och grindar som måste komma först.
- **Teknisk acceptans:** fokuserade prov och falsifiering.
- **Slutprov:** fall som skjuts till det samlade speltestet.

### 1 · Infrastruktur

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| INFRA-1 Sparning v2 | denna order, #266 §5/§8, granskning R1 | `Sparning` v1 med `rev` och `passId`-kvitton; `SparService` med UpdateAsync, omförsök, fail-closed läsning | framsteg, resultat och sparade priskvitton — **lokal förberedelse, ingen utdelning** | — | v1→v2 förlustfritt; trasigt och oändligt nekas; kvitton idempotenta även vid omförsök och omkörd transformator; taket prövas mot lagrets rad (hel skrivning nekas); pris utan giltigt resultat karantänsätts; inaktuell skrivare skriver inte över; framtida rad orörd; 19 mutationer röda (`sparning-v2.spec`, BANK_ONLY); CODE_REVIEW_PASS `85f4b89`. Taket KAN nås: väntande poster över taket blockerar hela skrivningen, och varje konsument måste hantera det. Återanvänt id för ett avvisat resultat följs upp i D3 | framsteg och kvitton finns kvar efter riktig återanslutning | `GRANSKAT` (grund; konsumenter pending) |
| INFRA-2A Serverägd ridlogg | order `5843292675` | `Inspelning.handelse` (klientägd, oanropad) | — | INFRA-1 | post per ritt (`RidLogg`), inkopplad i `HorseService`: lyckad uppsittning, accepterad hjälp, trötthetstak, stopp under ritt, avslut en gång (avslutad/avbruten); nej, inaktuella märken och rättelser loggas inte; tak per ritt med reserverat avslut och synligt överflöde; ring om 32 avslutade poster; frysta djupkopior; 13 mutationer röda (`ridlogg.spec`, BANK_ONLY); CODE_REVIEW_PASS `4ece6e1`. Ingen persistens. **Mäter inte väg, rytm eller hinder.** | — | `GRANSKAT` (livscykel och accepterade gångarter; konsumenter pending) |
| INFRA-2B1 Serverobserverad ridväg och tempo | order `5843387134`, #266 B3 | — | — | INFRA-2A | `RidObservation`, matad från HorseServices uthållighetssteg (samma rot, dt och teleportgräns, egen baslinje per ritt): planavstånd, observerad fart, kurs och svängar (omslag ±π), höjd för sig, tid per accepterad gångart, tempojämnhet (variationskoefficient i fönster om 40 segment inom samma gångart, *inte* hovtakt); saknad rot, icke-ändligt, dt ≤ 0, luckor > 1 s och teleporter ger ingen sträcka, syns i giltigheten och **tömmer tempofönstret** (granskning R1): inget numeriskt tempo förrän 8 nya sammanhängande segment i samma gångart, skälet syns under tiden; O(1) per steg, fönster och rutt (512 punkter, delar vid brott) med tak, summor för hela ritten, frysta bilder, ring om 32; klientens fart används inte; 19 mutationer röda (`ridobservation.spec`, BANK_ONLY). Observation av klientägd fysik: inget fuskskydd, ingen belöning, ingen bedömning. | — | `GRANSKAT` (grund; CODE_REVIEW_PASS `5e66cf6`, konsumenter pending) |
| INFRA-2B2 Hinderobservation | order `5843534733`, #266 B4 | tre befintliga hinder i ridhuset (`src/site.js` → `UBRFKomplex.ridhus.hinder` → `Anlaggningen`), bommar `CanCollide=false` | — | INFRA-2B1, överlämningsnotering nedan | stabila id:n i källdatan och `HinderId` på bommen (bara metadata); `HinderObservation` registrerar ur bommens faktiska läge efter bygget och speglingen (dubbletter och ogiltig geometri avvisas) och observerar per ritt, ur ridobservationens GILTIGA segment: passage (bekräftat sidbyte, |v| > 0,25 studs; planträff och återgång är ingen passage; korsningens läge ur det senaste OBSERVERADE planmötet, aldrig kordan) inom bredden med riktning, sidan om, ingen passage, luftfas och landning ur serverns `FloorMaterial` (observation, kan vara inaktuell för klientägd häst; okänd evidens bryter landningskedjan), geometrisk överlapp; kontakt `otillganglig`, rivning aldrig; brott, ritten slut, dubblett och borttaget hinder ger okänt utfall; registret följer levande delar (ensam ersättare godtas, dubbletter fail-closed); tak 64 försök per ritt, frysta bilder; 18 + R1 17 + R2 21 mutationer röda (`hinderobservation.spec`, KOHERENS-bänken, BANK_ONLY). **Inte:** hoppfysik, domare, poäng, bana, persistens. | hoppet känns förberett; passage och luftfas i motor | `GRANSKAT` (observationsgrund; CODE_REVIEW_PASS `c9bcd56`; B4 och konsumenter pending) |
| INFRA-3 Regelprofilformat | #266 D1/E1, G-REGEL | inget | schema och validering: gren, klass, bedömning, version, feltabell, olydnad, tid, lika resultat, placeringstabell, rosetter | INFRA-2A | ogiltig profil nekas; ingen klass får innehåll före G-REGEL | — | `EJ_PÅBÖRJAD` |
| INFRA-4A Källkedja och lokal offlinetillgång (HRAG) | G-ASSET, #247, order `5843822257` | källsidan BlendSwap 28627 (etikett CC0) och en kommentar som pekar på Tarnyloo 17172 (etikett CC-BY, version okänd); K3-filen i repot (verifierad) | lokal `Horse Rigged All Gaits.blend` **saknas**; rättigheter per beståndsdel `[REFERENCE GAP]`; offlineverktyg saknas | — | rapport i `docs/ASSET-SOURCE-OF-TRUTH.md`: primärkällor med tid, inventering (sökta rötter, fynd, Quaternius-paketet är annat material), status VERIFIED/REFERENCE_GAP/BLOCKED per område; ingen export, ingen nedladdning | — | `GRANSKAT` som dokumentation (inte klartecken för asset, rigg, rättigheter eller export); skala, ben och fästen `BLOCKED` |
| INFRA-PLATS1 Platsgrund för ridhuset | order `5843903636` | `UgnetaGestalt.plats` mätte från en sågad bit av "Sarg syd" (redovisad motsägelse) | gemensam plats för bana och dressyrlayout | — | `Ridhusplats` (HorseCore, server och klient) ur de byggda delarna via `PlatsId`: enheter (studs, 3/m), rektanglar, A-kant, A → C ur layoutens längdaxel med tecknet ur banans mitt, lokal/värld i meter, uttryckligt otillgängligt; fail-closed för underlag modellen inte stödjer (ortonormal ändlig bas, horisontella samriktade ytor, layout A-förankrad och inom banan; R1; relativ girning godtas bara om sin θ · banans halva diagonal ≤ 0,1 studs, och varje yta prövas i sina egna axlar; R2); inkopplad i `UgnetaGestalt.plats` (produktionskonsument); 10 + R1 6 + R2 4 mutationer röda (`ridhusplats.spec`, GESTALT-bänken, BANK_ONLY) | Ugneta mitt på, 1,4 m bortom C (flyttad från den felaktiga platsen) | `BYGGT` + `INTEGRERAT` i Ugnetas väg (lokalt, R2-rättelse; ej granskat, ej spelverifierat) |
| INFRA-4B Statisk offlineinventering | nästa offlinepaket | — | kräver filen, BELAGDA rättigheter per beståndsdel (ett riskbeslut eller en attribution ersätter inte belägg) och tillåtelse att installera verktyg | INFRA-4A, underlag från Tobias | SHA256 och storlek; filversion, enheter, ben, actions, rottranslation och fästen, i en isolerad mapp utan autorun; mätt data åtskild från förslag | — | `BLOCKED` |
| INFRA-5 Bänk mot runtime (#252 DEL D) | #252 | runtime-grinden fungerar (CI-place `121231609290409`) | 0 av 76 specar märkta `BANK_ONLY` eller med runtime-motsvarighet | — | varje spec märkt; ingen kritisk grind vilar bara på bänken | — | `EJ_PÅBÖRJAD` |
| INFRA-6 Inaktuella dokument | inventering `5842982274` | — | `ASSET-SOURCE-OF-TRUTH.md:139` (rbxmx "saknas"), BESLUT-162 och `Svar.luau:306` ("ingen dagsform") | — | rättat med källa | — | `EJ_PÅBÖRJAD` |

### 2 · Instruktör — tio lektionsområden

Beslut: tio lektionsområden. Varje övning avslutas när uppgiften är gjord, med
nya försök, progression och fri ridning. Ugneta är positiv, kvinnlig och ger
råd som går att använda. Text utan ljud, med reglerbar mängd tal. SV/EN och
touch bevaras.

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| Område: skötsel | #266 C, #161 | `Preparation`, momentvägen | framsteg per område (INFRA-1) | INFRA-1 | framsteg skrivs vid avslutad skötsel | lär sig och minns | `EJ_PÅBÖRJAD` |
| Område: utrustning | #266 C, BESLUT-162 | tackkedjan, felnekande | uppgift, framsteg, vägledning vid fel | INFRA-1, Utrustning | fel nekas med vägledning utan dolt straff | — | `EJ_PÅBÖRJAD` |
| Område: ledning | #266 C | `LedService`, målzon | uppgiftsslut, framsteg | INFRA-1 | — | R4/R5-ledningsfallen | `EJ_PÅBÖRJAD` |
| Område: start/halt | #266 C, `RidKanon` halt_skritt | övning, 22 s-försök | uppgiftsbaserat slut (C3) | INFRA-2A, INFRA-2B1, B3 | halt på avsedd plats avslutar | — | `EJ_PÅBÖRJAD` |
| Område: väg | #266 C/B3 | linje = svängradie | position och figur | INFRA-2A, INFRA-2B1, B3 | fel plats ger inte rätt linjebetyg | — | `EJ_PÅBÖRJAD` |
| Område: tempo | #266 C/B3 | `rytm = nil` (`Lektion.luau:148`) | rytm faktiskt mätt | B3 | ingen rytmbedömning förrän den mäts | — | `EJ_PÅBÖRJAD` |
| Område: övergångar | #266 C | skritt_trav, trav_skritt | plats för övergången | B3 | — | — | `EJ_PÅBÖRJAD` |
| Område: volter och serpentiner | #266 C | storvolt, hörn | form, storlek och plats | B3 | — | — | `EJ_PÅBÖRJAD` |
| Område: galoppfattning | #266 C/§3.1 | galoppsidan följer varvet | igenkänning; egen hjälp om modellen stöder det | B1 | — | — | `EJ_PÅBÖRJAD` |
| Område: hoppning | #266 C/B4 | generellt hopp | bommar → hinder → linje → bana | B4 | — | — | `EJ_PÅBÖRJAD` |
| C1 konkreta råd | #266 C1, #236 | temafokus, cooldown 8/14 s, attribution | råd knutna till händelser; bekräftelse av förbättring; länk till replay | INFRA-2A, INFRA-2B1, B3 | råd bara när mätningen stöder det | ett råd leder till ett bättre försök | `EJ_PÅBÖRJAD` |
| C2 repliker, mängd tal, text | #266 C2, #234 | kanonens LIVE-tabell | reglage för mängd tal, textlägen; #234:s startreplik och NPC-blick (port via #265) | C1 | SV/EN-nycklar; ingen påhittad orsak | — | `EJ_PÅBÖRJAD` |
| C3 uppgiftsbaserade lektioner | #266 C3, §5 | 22 s-klocka | uppgiftsslut, tidsgräns bara som reserv, fri ridning | B3 | klockan ensam godkänner aldrig | — | `EJ_PÅBÖRJAD` |
| C4 färdighetsminne | #266 C4 | inget | framsteg → nästa lektion | INFRA-1 | sparat och återläst | — | `EJ_PÅBÖRJAD` |

### 3 · Tävling

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| D1 klass och regelprofil | #266 D1 | — | profiler för clear round, A, A:0 | INFRA-3, G-REGEL | räkneprov per profil | — | `EJ_PÅBÖRJAD` |
| D2 tävlingsdagen | #266 D2, §6 | — | tillstånd på servern: anmälan → bangång → framridning → startlista → signal → ritt → resultat → prisutdelning → eftervård; UI för PC och touch | D1, Hus/Byggnader (platser) | ingen klient kan hoppa ett steg | hela dagen | `EJ_PÅBÖRJAD` |
| D3 domare och protokoll | #266 D3, §7 | webbens `domaRitt` som referens | deterministisk domare på servern ur händelser | INFRA-2A, INFRA-2B1, INFRA-2B2, B4 | samma händelser ger samma resultat; fel, vägran, tid, lika resultat | protokollet begripligt | `EJ_PÅBÖRJAD` |
| D4 placering, rosett och persistens | #266 D4, §8 | kvitton i INFRA-1 | placering efter startfält; rosettordning 1 blågul, 2 blå, 3 gul, 4 röd, 5 grön, 6+ vit; clear round och deltagarminne åtskilda | INFRA-1, D3, D4-RÄTT | inga dubbla priser vid återanslutning, omförsök, tvetydig skrivning eller samtidiga sessioner | pris finns kvar | `EJ_PÅBÖRJAD` |
| D5 tävlingskläder | #248, #266 D5 | `TavlingskladerService` utan anropare | på/av inom tävlingssammanhanget | D2 | fail-closed återställning | kläder på och av | `EJ_PÅBÖRJAD` |
| NPC-medtävlare | order 5843082008 | webbens simulering som referens | deterministiska, märkta, samma regelmodell | D3 | resultat ändras inte i efterhand | — | `EJ_PÅBÖRJAD` |
| E1–E3 dressyr: LC:1, LC:2, LB:1 | #266 E | webbens "Dressyr LC" (eget) | program, protokoll, domarantal, avdrag | INFRA-3, G-REGEL (rättigheter) | räkneprov; inget felmärkt program | — | `EJ_PÅBÖRJAD` |
| Klubbdagar: hopp, dressyr, blandat | order 5843082008 | — | sammansättning av klasser | D1–D4, E | — | — | `EJ_PÅBÖRJAD` |
| F3 multiplayer | #266 F3 | — | startlista för flera spelare; ingen kan blockera eller manipulera | D2–D4 | köregler och avhopp | två spelare | `EJ_PÅBÖRJAD` |

### 4 · Hus och 5 · Byggnader och området

Mappningen är redan beslutad i den godkända planen (granskning R1,
`5843188384`):
- **Hus** betyder stallhusets interiörer.
- **Byggnader och området** betyder ridhuset och resten av anläggningen.

Det som återstår är en detaljerad, källstyrd mappning mot kort, SITEPLAN och
referenser, samt den kontrollerade överlämningen G-MILJÖ. Ingen ny
konstruktion hittas på.

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| Kartläggning och överlämning | G-MILJÖ, `ENVIRONMENT-DELIVERY.md` | 8 byggnader, 12 dörrar (`UBRFKomplex.luau`), kort för ridhus och stall | överlämningen; termer bekräftade | — | inventering kvitterad | — | `EJ_PÅBÖRJAD` |
| Hus | `references/buildings/stall/KORT.md`, F02 | stall med klubbdel | referensluckor: uppehållsrummets L-form, pentry, service efter pausrum | G-MILJÖ | kort före kod; kod följer kortet | igenkänning från motsvarande vinklar | `EJ_PÅBÖRJAD` |
| Byggnader och området | `SITEPLAN.md`, F01/F02, Spatial Canon v2 | ridhus, hästgång, uthus | F01 P0-motsägelser i ridhuset; bredder, hästpassage | G-MILJÖ | samma | samma | `EJ_PÅBÖRJAD` |

### 6 · Utrustning

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| Hjälm | order 5843082008 | ingen | hjälm för ryttaren | INFRA-4 | — | syns och sitter | `EJ_PÅBÖRJAD` |
| Sadel, träns, tyglar (slutförande) | #165, BESLUT-162 | procedurell tack | slutlig form på HRAG-fästpunkter | INFRA-4 | fästpunktsprov | syns rätt på hästen | `EJ_PÅBÖRJAD` |
| Kläder: användning och återlämning | #248 | katalog och tjänst | anropare | D2 | — | på och av | `EJ_PÅBÖRJAD` |
| Fel utrustning | order 5843082008 | nekas och räknas | vägledning; **inget nytt dolt straff** | — | fel nekas med vägledning; dagsformen oförändrad | — | `EJ_PÅBÖRJAD` |

### 7 · Häst

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| Asset: Horse Rigged All Gaits | G-ASSET, #247 | K3-mesh | byte till vald asset; nuvarande hästar och ID:n behålls | INFRA-4 | ID:n oförändrade; kontraktet uppfyllt | ser rätt ut, glider inte | `EJ_PÅBÖRJAD` |
| B1 ridkänsla | #266 B1 | ridkärna | helhet och galoppfattning | — | — | känns levande | `EJ_PÅBÖRJAD` |
| B2 animation, hovljud, kamera | #266 B2 | procedurella ben; ljudet läser en `Sounds`-konfiguration som ingen skapar | ljud kopplat; klipp | G-ASSET | ljudkällan finns i bygget | hovljud hörs | `EJ_PÅBÖRJAD` |
| B3 mätning av väg och rytm | #266 B3 | fas och telemetri | övningsspecifik mätning | INFRA-2B1 | fel plats fångas | — | `EJ_PÅBÖRJAD` |
| B4 hoppkedja | #266 B4 | generellt klienthopp | anridning, avsprång, hinderkontakt, landning, händelser på servern | INFRA-2B2 | bommen som ligger kvar räknas inte som riven | hoppet känns förberett | `EJ_PÅBÖRJAD` |
| F1 personligheter och variation | #266 F1 | temperament i `Config`, tom `HorseStats` | verkliga hästars profiler (underlag krävs) | G-REFERENS | — | — | `EJ_PÅBÖRJAD` |
| F2 vidare innehåll | #266 F2 | — | fler övningar och klasser | kärnan klar | — | — | `EJ_PÅBÖRJAD` |

### A · Stäng första passet (#266 A1–A3)

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| A1–A2 tekniska rättelser | #264 R4/R5 | R5-rättelserna (port, panel, avsittning) finns i `ecb2f2e` | runtime obekräftad | — | bänk och falsifiering klara | port, layout, avsittning och ledning nedan | `BYGGT` (overifierad runtime) |
| A3 sammanhängande spelverifiering | #264 R5, #266 A3 | — | hela vägen i spel | alla komponenter integrerade och granskade, Tobias omstart | — | hela vägen nedan | `UPPSKJUTEN` (NOT_TESTED) |

Fysisk iPad och iPhone är uttryckligen uppskjutet och blockerar inte PC.

## Samlat slutspeltest (uppskjutna fall)

Kvar från R4/R5 på `ecb2f2e`, allt NOT_TESTED:
- **Port:** raden följer motorns visning; X och klick på båda sidor om gränsen; ett dörrbyte; passage.
- **Layout:** panelen i desktop, kompakt och vanlig layout, hjälpen öppen, lång SV/EN-text.
- **Avsittning:** normal, hopp och fall.
- **Ledning:** gång, stopp, sväng, passage genom ledaren.
- **Hela vägen:** spawn → skötsel → ledning → ridhus 5/5 → uppsittning → ridning → avsittning.
- **Fysisk iPad och iPhone:** separat från emulator.

Därtill slutprovkolumnen i varje rad ovan. PC, touch, emulator och två
spelare redovisas separat.
