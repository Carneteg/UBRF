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

Nödvändiga delade beroenden byggs före den komponent som behöver dem, som
kontrakt utan beteendeändring. Det gör dem inte till en ny produktprioritet.

**Scope:** hela anläggningen och alla 22 arbetspaket i #266 (A1–F3),
inklusive NPC-medtävlare och multiplayer. Inga nya webbfeatures; Roblox PC
först. Det gamla kravet att #264 ska vara produktaccepterad och mergad före
#266 är ersatt för *implementation*, inte för *release*.

## Statusnivåer

Varje rad har exakt en av dessa. En nivå kräver alla nivåer före den.

| Nivå | Betyder | Vem sätter den |
|---|---|---|
| `EJ_PÅBÖRJAD` | inget byggt i denna ordning | — |
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

**G-ASSET — hästens källa.** Vald asset är *Horse Rigged All Gaits*, inte K3.
Den saknade historiska `.blend`-källan är något annat än dagens
`roblox/assets/hastvisualer-k3.rbxmx`. Följande ska lösas tidigt i
infrastrukturen, före utrustningens slutförande:
- källa och rättigheter,
- offline-skala,
- ben och benkedjor,
- fästpunktskontraktet (sadel, träns, tyglar, ryttare).

Ingen uppladdning av assets utan egen order.

**G-REGEL — tävlingsregler.** Codex verifierar regelversion och klassdetaljer
för clear round, A och A:0 samt LC:1, LC:2 och LB:1 före respektive
implementationsorder. Officiella program kräver rättigheter. Annars används
egna träningsprogram med tydligt egna namn. Ett blockerat officiellt program
kopieras eller felmärks aldrig.

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
| INFRA-1 Sparning v2 | denna order, #266 §5/§8 | `Sparning` v1 med `rev` och `passId`-kvitton; `SparService` med UpdateAsync, omförsök, fail-closed läsning | framsteg, resultat och priskvitton | — | v1→v2 förlustfritt; trasigt och oändligt nekas; kvitton idempotenta även vid omförsök och omkörd transformator; inaktuell skrivare skriver inte över; framtida rad orörd; 10 mutationer röda (`sparning-v2.spec`, BANK_ONLY) | framsteg och pris finns kvar efter riktig återanslutning | `BYGGT` (lokalt) |
| INFRA-2 Händelselogg (serverägd) | #266 §6–7, B3/B4 | `Inspelning.handelse` finns men anropas aldrig; klientägd | deterministisk logg `{t, typ, data}` som bara läggs till; delad av instruktör (observationer) och domare (protokoll) med skilda uppgifter | INFRA-1 | samma händelser ger samma utfall; serialiserbar; klient kan inte skriva poäng | — | `EJ_PÅBÖRJAD` |
| INFRA-3 Regelprofilformat | #266 D1/E1, G-REGEL | inget | schema och validering: gren, klass, bedömning, version, feltabell, olydnad, tid, lika resultat, placeringstabell, rosetter | INFRA-2 | ogiltig profil nekas; ingen klass får innehåll före G-REGEL | — | `EJ_PÅBÖRJAD` |
| INFRA-4 Hästens assetkontrakt | G-ASSET | K3-mesh och procedurella ben | källa och rättigheter för HRAG, skala, ben, fästpunkter | — | kontraktet dokumenterat och statiskt kontrollerat; ingen uppladdning | — | `EJ_PÅBÖRJAD` |
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
| Område: start/halt | #266 C, `RidKanon` halt_skritt | övning, 22 s-försök | uppgiftsbaserat slut (C3) | INFRA-2, B3 | halt på avsedd plats avslutar | — | `EJ_PÅBÖRJAD` |
| Område: väg | #266 C/B3 | linje = svängradie | position och figur | INFRA-2, B3 | fel plats ger inte rätt linjebetyg | — | `EJ_PÅBÖRJAD` |
| Område: tempo | #266 C/B3 | `rytm = nil` (`Lektion.luau:148`) | rytm faktiskt mätt | B3 | ingen rytmbedömning förrän den mäts | — | `EJ_PÅBÖRJAD` |
| Område: övergångar | #266 C | skritt_trav, trav_skritt | plats för övergången | B3 | — | — | `EJ_PÅBÖRJAD` |
| Område: volter och serpentiner | #266 C | storvolt, hörn | form, storlek och plats | B3 | — | — | `EJ_PÅBÖRJAD` |
| Område: galoppfattning | #266 C/§3.1 | galoppsidan följer varvet | igenkänning; egen hjälp om modellen stöder det | B1 | — | — | `EJ_PÅBÖRJAD` |
| Område: hoppning | #266 C/B4 | generellt hopp | bommar → hinder → linje → bana | B4 | — | — | `EJ_PÅBÖRJAD` |
| C1 konkreta råd | #266 C1, #236 | temafokus, cooldown 8/14 s, attribution | råd knutna till händelser; bekräftelse av förbättring; länk till replay | INFRA-2, B3 | råd bara när mätningen stöder det | ett råd leder till ett bättre försök | `EJ_PÅBÖRJAD` |
| C2 repliker, mängd tal, text | #266 C2, #234 | kanonens LIVE-tabell | reglage för mängd tal, textlägen; #234:s startreplik och NPC-blick (port via #265) | C1 | SV/EN-nycklar; ingen påhittad orsak | — | `EJ_PÅBÖRJAD` |
| C3 uppgiftsbaserade lektioner | #266 C3, §5 | 22 s-klocka | uppgiftsslut, tidsgräns bara som reserv, fri ridning | B3 | klockan ensam godkänner aldrig | — | `EJ_PÅBÖRJAD` |
| C4 färdighetsminne | #266 C4 | inget | framsteg → nästa lektion | INFRA-1 | sparat och återläst | — | `EJ_PÅBÖRJAD` |

### 3 · Tävling

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| D1 klass och regelprofil | #266 D1 | — | profiler för clear round, A, A:0 | INFRA-3, G-REGEL | räkneprov per profil | — | `EJ_PÅBÖRJAD` |
| D2 tävlingsdagen | #266 D2, §6 | — | tillstånd på servern: anmälan → bangång → framridning → startlista → signal → ritt → resultat → prisutdelning → eftervård; UI för PC och touch | D1, Hus/Byggnader (platser) | ingen klient kan hoppa ett steg | hela dagen | `EJ_PÅBÖRJAD` |
| D3 domare och protokoll | #266 D3, §7 | webbens `domaRitt` som referens | deterministisk domare på servern ur händelser | INFRA-2, B4 | samma händelser ger samma resultat; fel, vägran, tid, lika resultat | protokollet begripligt | `EJ_PÅBÖRJAD` |
| D4 placering, rosett och persistens | #266 D4, §8 | kvitton i INFRA-1 | placering efter startfält; rosettordning 1 blågul, 2 blå, 3 gul, 4 röd, 5 grön, 6+ vit; clear round och deltagarminne åtskilda | INFRA-1, D3 | inga dubbla priser vid återanslutning | pris finns kvar | `EJ_PÅBÖRJAD` |
| D5 tävlingskläder | #248, #266 D5 | `TavlingskladerService` utan anropare | på/av inom tävlingssammanhanget | D2 | fail-closed återställning | kläder på och av | `EJ_PÅBÖRJAD` |
| NPC-medtävlare | order 5843082008 | webbens simulering som referens | deterministiska, märkta, samma regelmodell | D3 | resultat ändras inte i efterhand | — | `EJ_PÅBÖRJAD` |
| E1–E3 dressyr: LC:1, LC:2, LB:1 | #266 E | webbens "Dressyr LC" (eget) | program, protokoll, domarantal, avdrag | INFRA-3, G-REGEL (rättigheter) | räkneprov; inget felmärkt program | — | `EJ_PÅBÖRJAD` |
| Klubbdagar: hopp, dressyr, blandat | order 5843082008 | — | sammansättning av klasser | D1–D4, E | — | — | `EJ_PÅBÖRJAD` |
| F3 multiplayer | #266 F3 | — | startlista för flera spelare; ingen kan blockera eller manipulera | D2–D4 | köregler och avhopp | två spelare | `EJ_PÅBÖRJAD` |

### 4 · Hus och 5 · Byggnader och området

Ordern använder orden *hus* och *byggnader/området*. Begreppen ska mappas mot
projektets egna termer innan något byggs:
- *hus* har Stallhuset (Tobias Drive-mapp) som starkaste hypotes,
- *byggnader* har mappen Byggnaden, och området i övrigt.

Ingen ny konstruktion hittas på.

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
| B3 mätning av väg och rytm | #266 B3 | fas och telemetri | övningsspecifik mätning | INFRA-2 | fel plats fångas | — | `EJ_PÅBÖRJAD` |
| B4 hoppkedja | #266 B4 | generellt klienthopp | anridning, avsprång, hinderkontakt, landning, händelser på servern | INFRA-2 | bommen som ligger kvar räknas inte som riven | hoppet känns förberett | `EJ_PÅBÖRJAD` |
| F1 personligheter och variation | #266 F1 | temperament i `Config`, tom `HorseStats` | verkliga hästars profiler (underlag krävs) | G-REFERENS | — | — | `EJ_PÅBÖRJAD` |
| F2 vidare innehåll | #266 F2 | — | fler övningar och klasser | kärnan klar | — | — | `EJ_PÅBÖRJAD` |

### A · Stäng första passet (#266 A1–A3)

| Paket | Källor | Finns | Gap | Beror på | Teknisk acceptans | Slutprov | Status |
|---|---|---|---|---|---|---|---|
| A1–A3 | #264 R4/R5 | R5-rättelserna finns i `ecb2f2e`, men runtime är NOT_TESTED | — | — | bänk och falsifiering klara | se listan nedan | `BYGGT` (overifierad runtime) |

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
