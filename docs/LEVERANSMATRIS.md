# UBRF — låst leveransmatris (completion first)

**Beslut:** Tobias, förmedlat i PR #264, kommentar `5843082008`
(COMPLETION_FIRST_INFRA1_20260926), som ersätter planeringsstoppet i
`5842944422`. Planen som den bygger på: `5842982274`.
**Nuvarande ansvar:** se [WORKING-AGREEMENT](WORKING-AGREEMENT.md).
Codex uppdaterar verifierad status; Claude granskar oberoende. Ändrad
produktordning eller scope kräver Tobias beslut, inte en statusstädning.
**Bas när matrisen låstes:** `ecb2f2e11d63dbc3e325a6b1d70c8d48136c0869`.

## Ordning

**Ändring 2026-09-26 18:01 UTC:** Tobias har godkänt nästa sammanhängande
voltlektion före mer grundinfrastruktur. VOLT1/FORSOK1 återanvänds; INFRA-3
och andra nya grundpaket är inte nästa uppgift. Se senaste beslutet i
[WORKING-AGREEMENT](WORKING-AGREEMENT.md). Katalogen nedan bevaras som
omfattning/beroenden, inte som en konkurrerande omedelbar arbetsorder.

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
| `BYGGT` | kod och fokuserade prov lokalt, falsifierat | implementeraren |
| `GRANSKAT` | oberoende review av diff och prov | oberoende granskaren |
| `INTEGRERAT` | inkopplad i spelvägen, regressionssviten grön | implementeraren, efter review |
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

**G-MILJÖ — historisk överlämningsgrind.** Den ursprungliga ordern gav Claude miljöimplementationen först
efter en kontrollerad överlämning:
1. inventera Replits befintliga miljöarbete (PR #131/#132, gren
   `replit/pr-131-theory-fidelity`), accepterat innehåll och referenser,
2. fastställ vilka filer som byter ägare,
3. få överlämningen kvitterad.

Till dess görs inga miljöändringar och ingen andra skrivare startas. Tills
vidare gäller `docs/ENVIRONMENT-DELIVERY.md` för allt som inte är överlämnat.

Aktuellt skrivansvar följer arbetsöverenskommelsen. Nedan bevaras belägg för
filspecifika överlämningar; de ger inte tillstånd att skriva över annan
skrivares kvarvarande arbete.

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
| INFRA-PLATS1 Platsgrund för ridhuset | order `5843903636` | `UgnetaGestalt.plats` mätte från en sågad bit av "Sarg syd" (redovisad motsägelse) | gemensam plats för bana och dressyrlayout | — | `Ridhusplats` (HorseCore, server och klient) ur de byggda delarna via `PlatsId`: enheter (studs, 3/m), rektanglar, A-kant, A → C ur layoutens längdaxel med tecknet ur banans mitt, lokal/värld i meter, uttryckligt otillgängligt; fail-closed för underlag modellen inte stödjer (ortonormal ändlig bas, horisontella samriktade ytor, layout A-förankrad och inom banan; R1; relativ girning godtas bara om småvinkelkriteriet sin θ · banans halva diagonal ≤ 0,1 studs (exakt punktförflyttning 2·sin(θ/2)·r), och varje yta prövas i sina egna axlar; R2); inkopplad i `UgnetaGestalt.plats` (produktionskonsument); 10 + R1 6 + R2 4 mutationer röda (`ridhusplats.spec`, GESTALT-bänken, BANK_ONLY) | Ugneta mitt på, 1,4 m bortom C (flyttad från den felaktiga platsen) | `GRANSKAT` (CODE_REVIEW_PASS `7221d8f`) + `INTEGRERAT` i Ugnetas väg (ej spelverifierat) |
| INFRA-OBS-PLATS1 Observerat ridläge i ridhusets ram | order `5844174376`, #266 B3/C | `RidObservation` (segment) och `Ridhusplats` (ram), var för sig | bryggan mellan dem | INFRA-2B1, INFRA-PLATS1 | `RidPlatsObservation` matad i samma uthållighetssteg: aktuell punkt (u, h, v) i meter, planärt medlemskap i bana och layout (inte markkontakt), plats- och ram-id, tid, status, och bara för ett giltigt sammanhängande segment i samma ram båda ändpunkterna; ramen i cache, omlöst bara vid barnändring, ändrat avtryck eller ändrad metadata (lyssnare per barn på `PlatsId`/`Forankring`, avgränsad livscykel; R1), ny ram bryter kontinuiteten; läsväg `HorseService.ridplats`; 9 + R1 5 mutationer röda (`ridplats.spec`, KOHERENS-bänken, BANK_ONLY) | — | `GRANSKAT` (CODE_REVIEW_PASS `039aa66`) + `INTEGRERAT` i HorseService (ej spelverifierat); övningsspecifik mätning: INFRA-VOLT1 |
| INFRA-VOLT1 Serverobserverad referensmätning för `storvolt` | order `5846331811` | klientens `storvolt` v1 (`RidKanon.INSPELNING`, `Lektion.kvalitet`), orörd; `RidPlatsObservation` | mätning mot en referens på sin plats | INFRA-OBS-PLATS1 | `VoltObservation`, egen version `server-referens-1`, matad bara med ridplatsbildens giltiga segment i samma ritt och ram (samma uthållighetssteg, ingen egen sampling); referens = dressyrlayoutens mitt i platsramen och `RidKanon.UGNETA.KVALITET.VOLT_RADIE` (10, tolkad som meter — antagande, inget officiellt program); sträckviktad radialavvikelse i kordans mittpunkt (medel, RMS, max, meter), signerad vinkel per segment (atan2, omslag ±π), varv bara på nettot, motriktning och återkomst; obestämd vinkel innanför 1,0 m (ändpunkter eller närmaste punkt) bryter vinkelkedjan — okänd vinkel är inte noll, varv bara i en obruten kedja av bestämda segment, centrumstycket blir ett eget okänt avsnitt och återhämtning kräver ett nytt helt varv (R1); avsnitt bryts av varje brott, ogiltig plats, ram- eller referensbyte och avslutad ritt; otillräckligt/okänt underlag ger inga mått; frysta bilder via `HorseService.volt`, 8 avsnitt per ritt, ring om 32 ritter; ingen poäng, lektion eller belöning; 37 mutationer röda mot slutlig R1-kod (varav 11 för kontinuitetsvakten), överlevare åtgärdade (nya prov, två döda grenar borttagna); nya R1-prov 12 FEL mot modulen på `5e95b2c` (`volt.spec`, 91 OK, KOHERENS-bänken, BANK_ONLY) | — | `GRANSKAT` (CODE_REVIEW_PASS `13a366b`) + `INTEGRERAT` i HorseService (ej spelverifierat); ingen konsument |
| INFRA-FORSOK1 Serverägd försökslivscykel | order `5847195010` | ritten (`HorseService`, `rittId`), `VoltObservation` | försök som serverägd post före instruktörens konsumenter | INFRA-VOLT1 | `RidForsok` + server-API i HorseService (`startaForsok`, `avbrytForsok`, `forsok`, `forsokVolt`; ingen RemoteEvent): servergenererat `forsokId`, ritt/häst/ryttare ur sessionen, övning `storvolt` med bara serverdefinitionen `server-referens-1` (klientens v1 nekas); ägare och AKTUELL accepterad ritt härleds ur `byRider`/sessionen (saknad, stängd, gammal och annan spelares ritt nekas utan mutation; ägarkontrollen `session.rider == player` provad mot en INJICERAD inaktuell bokföring via provkrokar — ingen reproducerad produktionsbugg); ett aktivt per ritt; sekvensbaserad dublett/retry (samma sekvens → samma utfall, äldre okänd → `inaktuell_begaran`), 16 utfall per ritt; stängs exakt en gång med ritten (avsittning, död, lämnande, avregistrering), nekad avsittning bevarar, uppsittning startar inget; start-/slutmarkörer (ritt-tid, voltens högsta avsnitts-nr) så att voltavsnitt som pågick vid starten aldrig tillskrivs; ett STÄNGT försök läser bara voltbilden fryst vid stängningen, aldrig den levande — inga data efter slutet (R1); `forsok.historik_gallrad` när underlaget gallrats; frysta bilder utan resultatfält (`bedomning = "ingen"`), 8 försök per ritt, ring om 32 ritter; ingen sparning (mätt), ingen poäng, ingen klient; 31 mutationer röda (varav 7 för slutgränsen) + 1 ekvivalent; R1-proven röda mot modulen på `ae1016c` (`ridforsok.spec`, 96 OK, KOHERENS-bänken, BANK_ONLY) | — | `GRANSKAT` + `INTEGRERAT` i HorseService (servergrund; CODE_REVIEW_PASS på `49a4ca2`, 96 originalprov + 32 reviewerassertions + 10 regressionsspecar, BANK_ONLY; ej spelverifierat). Bredare `dismount`/`aterforena`-risk vid inaktuell `byRider`: produktionsnåbarhet ej verifierad. PENDING: instruktörskonsument, klient/UI, uppgiftsbaserat lektionsavslut, bedömning och progression |
| INFRA-4B Statisk offlineinventering | nästa offlinepaket | — | kräver filen, BELAGDA rättigheter per beståndsdel (ett riskbeslut eller en attribution ersätter inte belägg) och tillåtelse att installera verktyg | INFRA-4A, underlag från Tobias | SHA256 och storlek; filversion, enheter, ben, actions, rottranslation och fästen, i en isolerad mapp utan autorun; mätt data åtskild från förslag | — | `BLOCKED` |
| INFRA-5 Bänk mot runtime (#252 DEL D) | #252 | runtime-grinden fungerar (CI-place `121231609290409`) | 0 av 76 specar märkta `BANK_ONLY` eller med runtime-motsvarighet | — | varje spec märkt; ingen kritisk grind vilar bara på bänken | — | `EJ_PÅBÖRJAD` |
| INFRA-6 Inaktuella dokument | inventering `5842982274`, Tobias städuppdrag 2026-09-26 | K3-filens gamla frånvaropåstående är redan märkt historiskt/löst i ASSET-SOURCE-OF-TRUTH; återöppnas inte | roll-/gate-/push-motsägelser rättade i separat lokal dokumentkandidat, oberoende review pending; BESLUT-162 och Svar-kommentaren om dagsform återstår att verifiera mot produktionsvägen | — | [städregister](CLEANUP-20260926.md), inga nya produktpåståenden utan källa | — | `BYGGT` (endast dokumentdelmängden ovan; resten pending, inte spelacceptans) |

### 2 · Instruktör — tio lektionsområden

Beslut: tio lektionsområden. Varje övning avslutas när uppgiften är gjord, med
nya försök, progression och fri ridning. Ugneta är positiv, kvinnlig och ger
råd som går att använda. Text utan ljud, med reglerbar mängd tal. SV/EN och
touch bevaras.

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| Område: skötsel | #266 C, #161 | `Preparation`, momentvägen | framsteg per område (INFRA-1) | INFRA-1 | framsteg skrivs vid avslutad skötsel | lär sig och minns | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: spelarens EGNA första gånger för hälsning, visitation, ryktning och hovar ([kontrakt](CARE-MEMORY-CONTRACT.md)) — bara bokstavligt eget arbete (aldrig "auto"/Rida nu), född i den godkända momentvägen, boolesk markör per målstolpe och kanondefinition, sparad/väntande/okänd, visad i skötselpanelens hjälplista; prov skrivna, ej körda. Eftervård, utrustning, ledning och full färdighetsmodell är INTE byggda |
| Område: utrustning | #266 C, BESLUT-162 | tackkedjan, felnekande | uppgift, framsteg, vägledning vid fel | INFRA-1, Utrustning | fel nekas med vägledning utan dolt straff | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: fel sadel/träns → varaktig rättelse i skötselpanelen (vems utrustningen är, vad man gör) och en RIKTIG återlämning `GameplayService.lamnaTillbaka` vid utrustningens egen front, sedan rätt utrustning den vanliga vägen ([kontrakt](EQUIPMENT-GUIDANCE-CONTRACT.md)); prov skrivna, ej körda. Hjälm, HRAG-fästen och övrig utrustningsundervisning ej byggda |
| Område: ledning | #266 C | `LedService`, målzon | uppgiftsslut, framsteg | INFRA-1 | — | R4/R5-ledningsfallen | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `LedLektion`, till fots — led den bundna hästen med vanlig ledning ≥ 12 m och in i den befintliga målzonen, kvar ≥ 1 s ([kontrakt](LEADING-LESSON-CONTRACT.md)); prov skrivna, ej körda. Förberedelsens ledsteg, dess kvittering och historia är orörda; övrig ledning, navigering och utrustning är inte en del av detta. Minne: första genuina fullföljandet ([kontrakt](LEADING-MEMORY-CONTRACT.md)) — född i LedLektions egen övergång till complete, boolesk markör per definition, sparad/väntande/okänd, visad på sidan till fots; BUILT_NOT_VERIFIED, prov skrivna, ej körda |
| Område: start/halt | #266 C, `RidKanon` halt_skritt | övning, 22 s-försök | uppgiftsbaserat slut (C3) | INFRA-2A, INFRA-2B1, B3 | halt på avsedd plats avslutar | — | `BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `HaltLektion` (halt → skritt på hjälp → halt vid X, [kontrakt](HALT-LESSON-CONTRACT.md)); prov skrivna, ej körda (Tobias beslut: testa sist) |
| Område: väg | #266 C/B3 | linje = svängradie | position och figur | INFRA-2A, INFRA-2B1, B3 | fel plats ger inte rätt linjebetyg | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `VagLektion` med två träningsvägar, mittlinjen och diagonalen (ordnad genomridning i korridor, figuren är lektionstypen, [kontrakt](RIDING-PATH-LESSON-CONTRACT.md)); prov skrivna, ej körda. Övriga ridvägar ej påbörjade |
| Område: tempo | #266 C/B3 | `rytm = nil` (`Lektion.luau:148`) | rytm faktiskt mätt | B3 | ingen rytmbedömning förrän den mäts | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `TempoLektion` (jämn OBSERVERAD fart i skritt ur RidObservations färska prov, [kontrakt](TEMPO-LESSON-CONTRACT.md)); prov skrivna, ej körda. Hovtakt/rytm är INTE byggd och `rytm` förblir okänd |
| Område: övergångar | #266 C | skritt_trav, trav_skritt | plats för övergången | B3 | — | — | `BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `OvergangLektion` (skritt → trav vid T1 → skritt vid T2, träningsmål på mittlinjen, [kontrakt](TRANSITION-LESSON-CONTRACT.md)); prov skrivna, ej körda |
| Område: volter och serpentiner | #266 C | storvolt, hörn | form, storlek och plats | B3 | — | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `SerpentinLektion` (träningsserpentin med tre bågar A → C, ordnade korsningar av mittlinjen, en spelets träningsväg och inget officiellt program, [kontrakt](SERPENTINE-LESSON-CONTRACT.md)); prov skrivna, ej körda. Halvvolt tillbaka till spåret (`HalvvoltLektion`, spelets träningsväg, [kontrakt](HALF-CIRCLE-LESSON-CONTRACT.md)) BUILT_NOT_VERIFIED 2026-09-27, prov skrivna, ej körda. Genom hörnet (`HornLektion`, egen typ `hornet`, ett orienterat träningshörn i den lösta ramen, [kontrakt](CORNER-LESSON-CONTRACT.md)) BUILT_NOT_VERIFIED 2026-09-27, prov skrivna, ej körda. Övriga övningar i området ej påbörjade |
| Område: galoppfattning | #266 C/§3.1 | galoppsidan följer varvet | igenkänning; egen hjälp om modellen stöder det | B1 | — | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: `GaloppLektion`, begärd trav → galopp inne i träningsmålet K efter färsk trav och följd av observerad galopp ([kontrakt](CANTER-DEPARTURE-LESSON-CONTRACT.md)); prov skrivna, ej körda. **Galoppsidan (igenkänning höger/vänster) är INTE byggd** — obyggt beroende tills en äkta källa finns |
| Område: hoppning | #266 C/B4 | generellt hopp | bommar → hinder → linje → bana | B4 | — | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: bara steg 1, `MarkbomLektion` — skritt över den BEFINTLIGA markbommen `ridhus_hinder_rod_50` mot C, passage = rotens plan ur HinderObservation ([kontrakt](GROUND-POLE-LESSON-CONTRACT.md)); prov skrivna, ej körda. Högre hinder, linje, bana, hopp-/kontakt-/landningsbedömning och fysisk hovplacering är INTE byggda |
| C1 konkreta råd | #266 C1, #236 | temafokus, cooldown 8/14 s, attribution | råd knutna till händelser; bekräftelse av förbättring; länk till replay | INFRA-2A, INFRA-2B1, B3 | råd bara när mätningen stöder det | ett råd leder till ett bättre försök | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: återkoppling när en övning är slut för de tio ridlektionerna och ledningen (`LektionsAterkoppling`, [kontrakt](LESSON-FEEDBACK-CONTRACT.md)) — sammanfattning ur försökets frysta resultat och ett nästa steg, bunden till försöket; neutral text vid tidsgräns; prov skrivna, ej körda. Tempocoachning ([kontrakt](TEMPO-COACHING-CONTRACT.md)): för jämn skritt EN valfri händelseknuten skriven rad åt gången (för långsamt/fort/ojämnt → framåtaxeln), med spärr och kommentarsvalen, och en faktisk jämförelse av spridningen mot förra distinkta fullföljandet i samma ritt; BUILT_NOT_VERIFIED, prov skrivna, ej körda. Bekräftelse av förbättring för volten ([kontrakt](CIRCLE-COMPARISON-CONTRACT.md)): medelavståndet till linjen mot förra distinkta fullföljningen i samma lektionsobjekt (samma ritt, häst, version och radie), «närmare» bara när de visade tiondelarna minskat, annars neutralt; BUILT, lokala prov gröna 2026-09-28, ej spelverifierat. Samma bekräftelse för halt vid X ([kontrakt](HALT-COMPARISON-CONTRACT.md)): det fullföljande haltets avstånd till X mot förra haltet (samma ritt, häst, version, ram och X); BUILT, lokala prov gröna 2026-09-28, ej spelverifierat. Händelseknutet råd när volten lämnar linjen ([kontrakt](CIRCLE-LINE-ADVICE-CONTRACT.md)): punktavvikelsens nollställning med tecken — utåt eller inåt — ger ETT konkret råd åt rätt håll, bara medan just den nollställningen visas; BUILT, lokala prov gröna 2026-09-28, ej spelverifierat. Händelseknutet råd när en övergång missar sin ring ([kontrakt](TRANSITION-TIMING-ADVICE-CONTRACT.md)): samma två segmentändpunkter som zonprovet, före eller efter ringen i färdriktningen, ger ETT råd om när övergången ska begäras; BUILT, lokala prov gröna 2026-09-28, ej spelverifierat. Samma regel för galoppfattningen vid K ([kontrakt](CANTER-TIMING-ADVICE-CONTRACT.md)); BUILT, lokala prov gröna 2026-09-28, ej spelverifierat. Händelseknutna råd för övriga lektioner, bekräftelse av förbättring för de åtta övriga lektionerna (de fryser ingen avvikelse, det kräver ny mätning) och replay-länk (servern har ingen inspelning per försök; `RidObservation.rutt` är per ritt med tak 512 punkter) är INTE byggda |
| C2 repliker, mängd tal, text | #266 C2, #234 | kanonens LIVE-tabell | reglage för mängd tal, textlägen; #234:s startreplik och NPC-blick (port via #265) | C1 | SV/EN-nycklar; ingen påhittad orsak | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: spelarens textinställningar i Ugnetas yta (`LararInstallning`, [kontrakt](INSTRUCTOR-TEXT-CONTROLS-CONTRACT.md)) — valfria live-kommentarer normalt/färre/inga och kort/detaljerad text efter övningen, endast skriven text, sessionslokalt; prov skrivna, ej körda. Röst finns inte (G02-C-beslutet står). NPC-blicken: Ugneta vänder sig lokalt och mjukt mot den bundna ryttaren ([kontrakt](INSTRUCTOR-GAZE-CONTRACT.md)), BUILT_NOT_VERIFIED, prov skrivna, ej körda. Startrepliken: en kort skriven hälsning när servern godtagit ett nytt start/retry-försök i någon av de tio ridlektionerna ([kontrakt](INSTRUCTOR-START-CONTRACT.md)), BUILT_NOT_VERIFIED, prov skrivna, ej körda. BubbleChat, röst, persistens och övriga C2-krav är INTE byggda |
| C3 uppgiftsbaserade lektioner | #266 C3, §5 | 22 s-klocka | uppgiftsslut, tidsgräns bara som reserv, fri ridning | B3 | klockan ensam godkänner aldrig | — | `DELVIS BYGGT` — de elva serverlektionerna slutar på uppgiften, tidsgränsen (120–180 s) är bara reserv och godkänner aldrig. Det gamla 22 s-passet (Tobias beslut alternativ A, 2026-09-28) står kvar som **fri träning med återspelning** ([kontrakt](FREE-PRACTICE-FRAMING-CONTRACT.md)): knappen, presentationen och rundans rubrik säger det; BUILT, lokala prov gröna, ej spelverifierat. Mindre stöd, första steget ([kontrakt](ROUTE-LESS-GUIDANCE-CONTRACT.md), Tobias beslut alternativ A): efter klarad mittlinje/diagonal kan spelaren själv välja «Rid utan streck» — bara start- och slutringen; «Visa vägen» ger hela guiden; inget sparas, inget automatiskt; BUILT, lokala prov gröna, ej spelverifierat. Samma val för hörnet ([kontrakt](CORNER-LESS-GUIDANCE-CONTRACT.md)): «Rid med bara bågen och ringarna» — inridningens och utridningens raka streck och pilar bort; BUILT, lokala prov gröna, ej spelverifierat. Serpentinen är INTE ren (bara bågar; utan dem säger ringarna inget om bågarna). Halvvolten ([kontrakt](HALF-CIRCLE-LESS-GUIDANCE-CONTRACT.md), Tobias beslut alternativ A): «Rid utan strecken längs spåret» — bara inridningen längs spåret bort; bågen, returdiagonalen och ringarna kvar (utan diagonalen vore startringen ett tvetydigt mål); BUILT, lokala prov gröna, ej spelverifierat. Bommen på marken ([kontrakt](GROUND-POLE-LESS-GUIDANCE-CONTRACT.md)): «Rid bara efter bommen och märkena» — kanter, pilar och utlöp bort, märkena vid bomändarna kvar; BUILT, lokala prov gröna, ej spelverifierat. Mönstret är uttömt: volt, halt, övergångar och galopp har bara sitt enda målmärke, serpentinen bara bågar. Svårighetssteg, sparat «mindre stöd» och generalrepetition är INTE byggda |
| C4 färdighetsminne | #266 C4 | inget | framsteg → nästa lektion | INFRA-1 | sparat och återläst | — | `DELVIS BYGGT` — BUILT_NOT_VERIFIED 2026-09-27: första-klarad-minne för de tio ridlektionerna (`LektionsMinne`, [kontrakt](LESSON-MEMORY-CONTRACT.md)) — boolesk markör per lektion och definition i v2-`framsteg`, född bara av lektionens egen övergång till complete med validerat fryst resultat, sparad/väntande/okänd skild åt, och ETT valfritt förslag i väljaren; prov skrivna, ej körda. Inget betyg, ingen skicklighet, inget antal; ledning, skötsel och full färdighetsmodell är INTE byggda |

### 3 · Tävling

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| D1 klass och regelprofil | #266 D1 | — | profiler för clear round, A, A:0 | INFRA-3, G-REGEL | räkneprov per profil | — | `DELVIS BYGGT` — profilen **A: Clear Round** (SvRF TR III 2025, [kontrakt](D1-CLEAR-ROUND-PROFILE-CONTRACT.md), [källutdrag](../references/rules/TR-III-2025-hoppning-A-clear-round.md)): ren modul `HorseCore/Klassprofil.luau` (flyttad från `roblox/regler/` när D2a började konsumera den); lokala prov gröna. Bedömning A med placeringar och A:0 är INTE byggda |
| D2 tävlingsdagen | #266 D2, §6 | — | tillstånd på servern: anmälan → bangång → framridning → startlista → signal → ritt → resultat → prisutdelning → eftervård; UI för PC och touch | D1, Hus/Byggnader (platser) | ingen klient kan hoppa ett steg | hela dagen | `DELVIS BYGGT` — **D2a**: den första clear round-ritten på träningsbanan blå → röd → blå → röd ([kontrakt](D2-CLEAR-ROUND-DAY-CONTRACT.md)): startsignal, startlinje, banan, mållinje, **förenklad bedömning** (rivningar observeras inte; aldrig «felfri», ingen rosett), en omstart; lokala prov gröna, ej spelverifierat. **D2b** ([kontrakt](D2B-PRE-RIDE-CONTRACT.md)): anmälan → solo startlista (startnummer 1 · 1 anmäld) → banskiss ur serverns bangeometri (uttalad förenkling av bangång till fots) → startsignal; start nekas i alla andra lägen; endast sessionen; lokala prov gröna, ej spelverifierat. **D2c** ([kontrakt](D2C-AFTERCARE-CONTRACT.md)): resultatkortet pekar in i den BEFINTLIGA eftervården (momenten ur kanonen via serverns bild); kedjan pass → clear round → avsittning → eftervård → räknat en gång bevisad genom de riktiga tjänsterna; lokala prov gröna, ej spelverifierat. Framridning (3c: väntar på `references/site/BANIDENTITET.md`), avskrittning/hemväg, prisutdelning och riktig rosett (B4/D4) är INTE byggda |
| D3 domare och protokoll | #266 D3, §7 | webbens `domaRitt` som referens | deterministisk domare på servern ur händelser | INFRA-2A, INFRA-2B1, INFRA-2B2, B4 | samma händelser ger samma resultat; fel, vägran, tid, lika resultat | protokollet begripligt | `EJ_PÅBÖRJAD` |
| D4 placering, rosett och persistens | #266 D4, §8 | kvitton i INFRA-1 | placering efter startfält; rosettordning 1 blågul, 2 blå, 3 gul, 4 röd, 5 grön, 6+ vit; clear round och deltagarminne åtskilda | INFRA-1, D3, D4-RÄTT | inga dubbla priser vid återanslutning, omförsök, tvetydig skrivning eller samtidiga sessioner | pris finns kvar | `DELVIS BYGGT` — **D4a** ([kontrakt](D4A-PRIZE-PERSISTENCE-CONTRACT.md)): grunden för D4-RÄTT — deterministisk kvittonyckel `Sparning.prisId`, BEKRÄFTAD rätt i `SparService` (bara det som ligger i lagret efter en lyckad läsning eller committad skrivning; tvetydig/nekad skrivning bekräftar inget) och prisskåpets läsmodell `SparService.bekraftadePriser` (typ, källa, visning åtskilda; inga bonusfält). Inert: ingen utdelning, ingen UI, ingen anropare. Placering, rosettfärger och clear round-utdelningen (D4b) är INTE byggda |
| D5 tävlingskläder | #248, #266 D5 | `TavlingskladerService` anropas från clear round-lektionen (R1: vaktbindningen fail closed) | på/av inom tävlingssammanhanget | D2 | fail-closed återställning | kläder på och av | `DELVIS BYGGT` — alternativ A ([kontrakt](D5-COMPETITION-CLOTHING-CONTRACT.md), Tobias 2026-09-28): frivilligt set vid clear round-anmälan (`anmal_<id>` ur katalogen), på i bakgrunden, av vid Avsluta/rittslut/lektionsbyte + tjänstens fyra vakter; misslyckad laddning stoppar aldrig ritten; endast sessionen. Förhandsvisning och sparad preferens (#248 §4) uppskjutna. Lokala prov gröna; att kläderna syns på en riktig avatar är NOT_TESTED (Studio) |
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
| B4 hoppkedja | #266 B4 | generellt klienthopp | anridning, avsprång, hinderkontakt, landning, händelser på servern | INFRA-2B2 | bommen som ligger kvar räknas inte som riven | hoppet känns förberett | `DELVIS BYGGT` — **B4a** ([kontrakt](B4A-KNOCKDOWN-EVENT-CONTRACT.md)): nedslagshändelsen på servern per hinderförsök (`nedslag` ja/nej/okand/vantar, `nedslagGrund`, `tNedslag`; registrets `fysisk`). Stängt vid fel: dagens bommar kan inte falla och ger alltid «okand», aldrig «nej»; en fysisk bom ger «nej» först efter ett fönster utan fall. D2-bedömningen oförändrad, ingen rosett. Fallande bommar (Replits miljö), verklig kontakt, replikering och kalibrering är NOT_TESTED (Studio). **B4b** ([kontrakt](B4B-DISOBEDIENCE-CLASSIFIER-CONTRACT.md), TR III 2025 moment 385 i references/rules/): R1: bara NEUTRAL evidens per försök (`stoppObserverat`, `tStopp`, `bakatEfterStopp`, `sidanOm`, `inSida`, `evidensGrund`) — observationslagret dömer aldrig vägran/utbrytning, eftersom TR 385 dömer mot «hinder som ska hoppas» som bara den banmedvetna D2 vet; domtabellen står i kontraktet för den konsumenten. **B4c** ([kontrakt](B4C-COURSE-EVIDENCE-CONSUMER-CONTRACT.md)): `ClearRoundUnderlag` — banmedveten SKUGGBEDÖMNING (vägran/utbrytning/ingen/okänd per nästa banhinder, nedslag per steg, `fullstandigt`), byggd på servern när resultatet sätts; `officiell = false` alltid, aldrig i bilden, den officiella D2-bedömningen oförändrad. Volt (1.3, kräver banordning och spår) och istadighet (5.1, produktbeslut) inte byggda; D2-bedömningen oförändrad |
| F1 personligheter och variation | #266 F1 | temperament i `Config`, tom `HorseStats` | verkliga hästars profiler (underlag krävs) | G-REFERENS | — | — | `EJ_PÅBÖRJAD` |
| F2 vidare innehåll | #266 F2 | — | fler övningar och klasser | kärnan klar | — | — | `EJ_PÅBÖRJAD` |

### A · Stäng första passet (#266 A1–A3)

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| A1–A2 tekniska rättelser | #264 R4/R5 | R5-rättelserna (port, panel, avsittning) finns i `ecb2f2e` | runtime obekräftad | — | bänk och falsifiering klara | port, layout, avsittning och ledning nedan | `BYGGT` (overifierad runtime) |
| A3 sammanhängande spelverifiering | #264 R5, #266 A3 | — | hela vägen i spel | alla komponenter integrerade och granskade, Tobias omstart | — | hela vägen nedan | `UPPSKJUTEN` (NOT_TESTED) |

Fysisk iPad och iPhone är uttryckligen uppskjutet och blockerar inte PC.

## Samlat slutspeltest (uppskjutna fall)

**Samlad och låst i [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md)** (#266 A2, 2026-09-28, omlåst efter vägvisaren):
byggidentitet `3217c09395f2…`, alla fysiska och motorberoende
punkter ur varje kontrakt sedan `7922d70` och de kvarvarande R4/R5-fallen från `ecb2f2e`
(port, layout, avsittning, ledning, hela vägen, fysisk iPad och iPhone), i spelordning
och med spårbarhet kontrakt → rad. Allt NOT_TESTED tills Tobias fyller i listan.
