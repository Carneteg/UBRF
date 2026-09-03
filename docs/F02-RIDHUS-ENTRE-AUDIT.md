# Ridhusets entrédel — segmentaudit mot Spatial Canon v2

Status: `EVIDENS` för leveransen i PR #73 (F02-A). Ingen produktacceptans.
Kanon: `references/spatial/UBRF-SPATIAL-CANON-v2.json` § `buildings.ridhus`,
`docs/SPATIAL-CANON-V2-IMPLEMENTATION-ORDER.md` § 1 "Ridhus".

## Disposition i runtime (huvudagentens beslut ur auditen)

| segment (gammal `entrehall.vaggar`) | tidigare källa (matrisen) | verdikt | i runtime nu |
|---|---|---|---|
| `korridor_o` (x 2,2, N 0,3–13, `glasparti` N 2,4–3,8) | `PLAN` | planen bär bara N 4,6–8,3; fotona visar en öppen gång | **borttagen**; sträckan N 4,6–8,3 är receptionens GLASS |
| `wc_n_s`, `wc_n_mellan`, `wc_n_o` | `PLAN` + `[enligt Tobias]` | tre sidor mätbara i förstoringen; "två toaletter till vänster om entrén" | **kvar som WALL**, `ridhus_wc_n_enclosure`, VERIFIED_PLAN_OR_PHOTO |
| `skap_v` (x 4,2, N 1,1–16, fyra luckor) | `PLAN` | inga sammanhängande streck; skåpen är fristående möbler (`ridhus-klubb-01/-15`) | **borttagen** |
| `skap_o` (x 5,7, N 1,6–16, fyra luckor) | `PLAN` + `FOTO` | ingen planlinje; fotots glas hör till receptionen | **borttagen**; receptionens glas byggs som GLASS på den plansträcka som mäts (x 2,2, N 4,6–8,3) |
| `cell_1`–`cell_4` (tvärväggar N 3,9 · 6,4 · 7,9 · 9,8) | `PLAN`; funktion `REFERENCE GAP` | < 10 % täckning vid koordinaterna | **borttagna** |
| `hall_n_v` (N 4,3, x 5,7–10,6, dörr 1,9 m) | `PLAN`; funktion `REFERENCE GAP` | ingen linje; SITEPLAN: "otydlig i mitten, [antagande]"; den vägg som spärrade vägen entré → bana | **borttagen** |
| `hall_n_o`, `hall_mitt`, `hall_no`, `hall_no_s` | `PLAN`; funktion `REFERENCE GAP` | ingen egen evidens | **borttagna** |
| `hall_nv_s` (N 7,2, x 7,6–10,5) | `PLAN` | sammanfaller med C-blockets egen framkant | **borttagen** (C-blocket bygger sin egen kant) |
| `ostkorridor_v` (x 21,7, N 0,2–11,4) | `PLAN` | två korta körningar i takstolsmarkeringarnas rytm | **borttagen** |
| — (ny) `reception_glas` (x 2,2, N 4,6–8,3) | — | PO: receptionen är glasad; `ridhus-klubb-01/-02/-15`: låg bröstning + fyra glaspartier; planlinjen 3,7 m; Tobias Bild 2 (reception) hör till remsan x 2,2–4,2 | **GLASS** `ridhus_reception_glass`; väderstreck och rummets övriga avgränsning `REFERENCE GAP` — inga ersättningsväggar |
| `schakt` (sluten volym x 5,78–7,6, N 7,3–9,0) | `PLAN`; funktion `REFERENCE GAP` | oberoende ommätt x 5,58–7,42, N 7,15–9,04 | **kvar**, `ridhus_schakt_box`, ingen etikett, utanför rutten |

Regioner utan geometri: `entre` (vid fasadens låsta dörr, N 9–11),
`reception`, `hall`. Borttagna regioner: `vastkorridor`, `cellrad`,
`skapkorridor` (etiketten SKÅPKORRIDOREN), `ostkorridor`. HWC: funktionen är
känd ur Tobias Bild 5, geometrin är inte belagd → ingen vägg (`REFERENCE GAP`).

OPEN_AREA `ridhus_open_entrance_hall` täcker entrédelen utom toaletterna,
schaktet och receptionens remsa; NO_WALL_ZONE `ridhus_open_hall_no_room_boxes`
listar de 14 återkallade segmenten. Grindar: `roblox/tests/geometri.spec.luau`
(data) och `roblox/tests/bygge.spec.luau` (bygge + rutt med spelarradie).

---

## Subagentens rapport (oredigerad utom sökvägar)

# Ridhusets entré/reception — källgranskning mot Spatial Canon v2

Läst före arbete: `references/spatial/UBRF-SPATIAL-CANON-v2.json`, `docs/SPATIAL-CANON-V2.md`,
`docs/F02-INTERIOR-MATRIS.md` (§ Ridhuset), `references/SITEPLAN.md`,
`references/plans/RIDHUS-PLANMATNING-2026-08-30.md`,
`references/buildings/ridhus/granskning-2026-08-31/G-klubbdelen.md`. Nuvarande
`RIDHUSINNE.entrehall.vaggar` läst i `src/site.js` rad 1808–1892.

Auditen gjordes 2026-09-03 av en Sonnet-subagent på uppdrag av Claude (huvudagent), på begäran av Spatial Canon v2 (`PO-2026-09-03-RIDHUS-OPEN-01`). Arbetsbilderna (roterad plan, förstoringar, pixelmasker) är temporära och ligger inte i repot; alla mått går att göra om ur `references/plans/ridhus-entreplan-utrymning.jpg` med metoden nedan.

## 1. Orientering

**Metod.** `references/plans/ridhus-entreplan-utrymning.jpg` (4032×3024) är fotograferad
på högkant och roterad. Jag testade båda 90°-rotationerna; `rotate(-90)` (medurs) gör
titeltexten "UTRYMNINGSPLAN / EVACUATION PLAN" vågrät och läsbar — sparad som
`plan_rot_cw.jpg` (3024×4032). Det är den bilden alla pixelmått nedan utgår från.

I den läsbara bilden ligger den lilla rumsklustret (entrén) till **höger**, och en tät,
upprepad linjeramma längs **hela överkanten** av den stora gula hallytan (`strip_top.jpg`)
— fem-sex parallella tvärlinjer, exakt den signatur `RIDHUS-PLANMATNING-2026-08-30.md`
redan identifierat som **läktarens trappsteg i plan**. Underkanten (`strip_bottom.jpg`)
är en enkel ren linje med jämna korta tvärstreck (takstolsmarkeringar), ingen läktare.

Eftersom `references/SITEPLAN.md` rad 77 slår fast att ridhusets **cafégavel/entré vetter
mot grusplanen i norr**, och läktaren enligt samma dokument samt `F02-INTERIOR-MATRIS.md`
ligger längs **västra** långsidan: rutan med trappstegen = västväggen.

**Slutsats:** i `plan_rot_cw.jpg` är **höger = norr** (entrén), **vänster = söder**
(kortsidan vid A), **överkant = väster** (läktarsidan), **underkant = öster**. Detta
stämmer med `F02-INTERIOR-MATRIS.md`s egen tidigare slutsats (tre ankare, 2026-09-03) —
jag har verifierat den självständigt via läktarbandets läge, inte tagit den för given.

**Skala.** Den gula hallytans pixelmask (tröskling på gult, `yellow_mask.png`) ger
rader 1902–2706 (804 px) för byggnadens bredd 25 m → **32,16 px/m i tvärled**, vilket
jag använder genomgående (per uppdragets instruktion). Kolumner 194 (södra gaveln) till
den vägglinje jag mätte till kol. ≈2401 ger 2201 px för hallens 65,68 m →
**33,52 px/m i längdled** — internt konsekvent (< 5 % avvikelse mot tvärledsskalan),
men **längdled räknas ±0,5–1 m** eftersom bilden är snett fotograferad och entré-
klustrets egen nordgavel inte gick att fastslå lika rent (gult fyller inte de enskilda
rummen, bara korridorytorna, så gaveln ligger dold bland legendtext i mitt eget foto).

**Bättre kalibrerad crop.** Scratchpaden innehåller sedan tidigare en noggrannare
upprätning/rutnätsbild av samma kluster, `ridhus-kluster-grid2.png` (1608×2790, röda
kolumner var 5:e N-meter, blå rader var 5:e x-meter). Jag verifierade DEN bildens
kalibrering mot ett oberoende känt mått — den kryssade rutan ("schaktet") — innan jag
litade på den: uppmätt x 5,58–7,42, N 7,15–9,04 mot dokumenterat x 5,75–7,6, N 7,3–9,0.
Träffsäkert. Jag har därför använt den bildens kalibrering (84,6 px/m längdled,
94,6 px/m tvärled, N0 vid kol. 1356, x0 vid rad 285) för de pixelmått som krävde hög
precision nedan, och mina egna crops (`entrance_wide.jpg`, `entrance_grid.jpg`,
`nw_corner_zoom.jpg`) för den grova, egna orienteringskontrollen.

**Fynd som avviker från det uppgivna ankaret.** Uppdragets "här är du"-ankare
("huvudentrén ca N 2,2–3,8 i västra väggen") bygger enligt `F02-INTERIOR-MATRIS.md`
rad 558 på Tobias **egna planurklipp "Bild 1–7", som inte finns i repot** — det är alltså
inte spårbart i själva planbilden. När jag följer "här är du"-cirkelns egen
anslutningslinje till väggöppningen i `ridhus-kluster-grid2.png` hamnar punkten vid
kol. ≈1285, rad ≈698 → **N ≈ 0,8, x ≈ 4,4** — dvs. i **norra gaveln**, inte i västra
långväggen, och inte vid N2,2–3,8. Se `kluster_topright_zoom.png`. Jag kan inte
utesluta att jag följt fel dörrmarkering (flera brandsläckar-ikoner med egna
anslutningslinjer sitter tätt intill), men den enda linjen som går till just
"här är du"-cirkeln leder hit. **Detta är en `CONTRADICTION`, inte en rättelse** — jag
har inte ändrat något i koden, bara flaggar att planens egen "här är du"-punkt och det
Tobias-sourcade ankaret pekar på olika väggar. Rekommenderar att Product Owner får se
båda och avgöra.

## 2. Planens vägglinjer i entrédelen (N 0–11,5, hela bredden 0–25 m)

Automatisk pixelavsökning (mörka pixlar, tröskel <110/255) på `ridhus-kluster-grid2.png`
längs varje kandidatlinje, plus visuell kontroll. "Täckning" = andel av den förväntade
sträckan som faktiskt är mörk.

| Linje (plan) | Koord. (N, x) | Täckning | Tolkning |
|---|---|---|---|
| Hall/entré-gränsen | N 11,5 (hela bredden) | ~100 % av 25 m (rad 230–2683 vid kol. 380) | **Genomgående vägg, verifierad.** Inte en del av `entrehall.vaggar`, men bekräftar var N=11,5 verkligen ligger. |
| Toalettrum NV | N 1,2–2,4, x 0–1,7 | tre sidor solida (flera 60–130 px långa körningar) | **Verklig liten sluten volym** — matchar `wc_n_s`/`wc_n_mellan`/`wc_n_o` nästan exakt |
| Schaktet (kryssad ruta) | N 7,15–9,04, x 5,58–7,42 | heldraget X plus box | **Verklig sluten volym**, oförändrad sedan tidigare granskning; ingen ny funktion belagd |
| C-blockets norra framkant | N ≈ 7,05, x 7,6–10,5 | 95 % (277/290 px) | Sannolikt bänkblockets/trapphusets egen kant, **inte** en fristående rumsvägg |
| "Cellradens" 4 tvärväggar | N 3,9 / 6,4 / 7,9 / 9,8, x 2,2–4,2 | 3–19 px av ~190 möjliga (<10 %) | **Ingen vägg hittas** vid de exakta koordinaterna — punktvis brus, ingen linje |
| Vägg vid x≈2,2 (korridor_o) | N 4,6–8,3 | sammanhängande 314 px (av förväntat 0,3–13 m) | **Delvis en riktig linje**, men bara för en bit av den påstådda sträckan — inte N0,3–13 i sin helhet |
| Väggar x=4,2 / x=5,7 (skap_v/skap_o) | N 1,6–16 resp. 1,1–16 | enstaka px, ingen sammanhängande körning | **Ingen genomgående vägg** — bara kortare fragment som sannolikt är cellernas egna ändstumpar, inte två parallella korridorväggar |
| Öst-vägg x=21,7 (ostkorridor_v) | N 0,2–11,4 | två körningar à ~140 px, resten glest | Sannolikt **takstolsmarkeringar** (jfr `strip_bottom.jpg`), inte en rumsvägg |
| hall_n_v / hall_n_o / hall_mitt / hall_no / hall_no_s | x 5,7–21,7, N 4,3–7,2 m.fl. | ingen tydlig sammanhängande linje hittad vid stickprov | Matchar SITEPLAN.md:s egen varning: **"Ridhusets entréhall, rumsindelning: ... otydlig i mitten, `[antagande]` — väggar antydda, inte rum för rum"** |

**Sammanfattning:** planen bär tydligt bara tre säkra strukturer i entrédelen: det lilla
toalettrummet NV, schaktet, och C-blockets egen kant. Resten av det nuvarande
väggnätet (cellrad, dubbla parallella korridorväggar, öst-korridorens vägg, hela
NÖ-rumsklustret) saknar mätbart stöd i själva planlinjerna — vilket är precis det
`SPATIAL-CANON-V2.md` varnar för: "en planruta ... har tolkats som ett slutet rum".

## 3. Verdikt per segment i `entrehall.vaggar`

| id | Verdikt | Källa | Motivering |
|---|---|---|---|
| `korridor_o` (x2,2, N0,3–13, med `glasparti`) | **TA BORT som opak vägg / GÖR TILL ÖPPEN** | plan (delvis), foto | Planen bär bara en linje för N4,6–8,3 av 13 m, inte hela sträckan. Foton `ridhus-klubb-01/-02/-15` och `IMG_0169-f02/-f05` visar **en enda öppen gång** utan tvärvägg mellan skåpsida och glassida — man går rakt fram, ingen vägg att runda. `glasparti`-öppningen bör i så fall flyttas till receptionens verkliga glas (se punkt 4), inte stå kvar som ett hål i en vägg som annars inte finns. |
| `wc_n_s` | **BEHÅLL SOM WALL** | plan (stark pixelmatchning) | Tre sidor av en verklig liten sluten volym vid N1,2–2,4, x0–1,7, mätt oberoende ovan |
| `wc_n_mellan` | **BEHÅLL SOM WALL** | plan (stark pixelmatchning) | Samma volym, mellanvägg mellan de två båsen |
| `wc_n_o` | **BEHÅLL SOM WALL** | plan (stark pixelmatchning) | Långsidan som sluter volymen mot korridoren |
| `skap_v` (x4,2) | **TA BORT** | foto + plan | Ingen sammanhängande linje i planen (se tabell ovan). `ridhus-klubb-01/-15` visar skåpraden som **fristående möbler i en öppen gång**, inte en vägg med fyra dörröppningar — det är exakt PO:s "öppna ytor förväxlas med rum" |
| `skap_o` (x5,7) | **GÖR TILL GLASS där receptionen sitter, TA BORT övrigt** | foto (`ridhus-klubb-01/-02`) | Reception med fyra glaspartier ovanpå en låg disk är verifierad (punkt 4). Resten av linjen (bortom disken, in mot `hall_n_v` m.fl.) har varken plan- eller fotostöd |
| `cell_1` | **TA BORT** | plan | <10 % täckning vid exakt koordinat; ingen tvärlinje hittad |
| `cell_2` | **TA BORT** | plan | samma |
| `cell_3` | **TA BORT** | plan | samma |
| `cell_4` | **TA BORT** | plan | samma |
| `hall_n_v` (med dörr) | **TA BORT / OSÄKER** | — | `F02-INTERIOR-MATRIS.md` klassar redan funktionen `REFERENCE GAP`; `SITEPLAN.md` säger uttryckligen att rumsindelningen här är `[antagande]`, "otydlig i mitten". Ingen sammanhängande linje hittad vid stickprov. Denna vägg (med sin enda 1,9 m dörr) är sannolikt exakt den flaskhals som blockerar vägen entré→bana |
| `hall_n_o` | **TA BORT / OSÄKER** | — | samma motivering, ingen egen evidens hittad |
| `hall_nv_s` | **TA BORT som rumsvägg** | plan | Linjen jag hittade vid N≈7,05 sammanfaller med C-blockets egen framkant (bänk/trappa), inte en fristående partition — bör i så fall tillhöra C-blocksgeometrin, inte kodas som en väderoberoende vägg mellan två okända rum |
| `hall_mitt` | **TA BORT / OSÄKER** | — | ingen egen linje hittad, `REFERENCE GAP` för funktion sedan tidigare |
| `hall_no` | **TA BORT / OSÄKER** | — | samma |
| `hall_no_s` | **TA BORT / OSÄKER** | — | samma |
| `ostkorridor_v` (x21,7) | **TA BORT / OSÄKER** | plan | Bara två korta körningar hittade, som ligger på samma mönster som takstolsmarkeringarna på öst-väggen (jfr `strip_bottom.jpg`) — sannolikt feltolkade som vägg tidigare |

**Genomgående:** av 14 segment behåller granskningen **3 (toaletterna)** som WALL,
konverterar **1 (delar av `skap_o`)** till GLASS, och rekommenderar att **10** tas bort
eller lämnas öppna i väntan på bättre underlag. Ingen av de borttagna har både en
sammanhängande planlinje OCH ett foto som stöd — vilket är den tröskel
`SPATIAL-CANON-V2.md` sätter.

## 4. Receptionen

**Läge:** i den långa skåpkorridoren/omklädningsgången (samma gång i
`ridhus-klubb-01`, `-02`, `-03`, `-15` och `IMG_0169-f02`/`-f05` — identifierad via
återkommande möbler: samma röda mönstrade stolar och samma vita bågformade skåp syns i
flera av bilderna, se `G-klubbdelen.md`). Skåp med lådor i grått/rött/mörkgrått står på
**ena** långsidan; på den **andra** långsidan står en låg (bänkhög, ~90 cm) solid
bröstningsvägg med **fyra fasta glaspartier** upp mot taket och en bred avställningshylla
ovanpå disken, in mot ett bakomliggande rum med träskåp, inramade foton och (i en av
bilderna) en sadel/seldelar på hyllor.

**Väderstreck:** kan inte fastslås med säkerhet ur fotona ensamma (ingen kompassriktning
syns i bild, och jag har inte kunnat binda ihop just detta glasparti med ett specifikt
plan-koordinat — se REFERENCE GAP nedan). Givet att korridoren i planen motsvarar
skåpkorridoren (x ca 4–6 enligt tidigare planläsning) och att receptionens glas sitter på
**östra** sidan av den korridoren i den befintliga koden (`skap_o`, x5,7), är öst en rimlig
men **inte fotobelagd** placering.

**Glasets utsträckning:** fyra likstora fönster i rad, alla i samma vägglinje —
motsvarar en sammanhängande glasad sektion på uppskattningsvis 3–4 m (fyra fönster à
~0,8–1 m plus karmar, [uppskattning] ur bildproportioner, ingen skala i foto).

**Foton:** `ridhus-klubb-01-omkladningsgangen.jpg`, `ridhus-klubb-02-glasrummen.jpg`.

**Spatial Canon-krav:** detta parti ska kodas som `GLASS` med `canon_id`/`source_id`,
inte som ersättande opak vägg — vilket `skap_o` i sin nuvarande form är.

## 5. Toaletterna vid entrén

Planen bär (avsnitt 2/3) en verklig, mätbar liten sluten volym vid N1,2–2,4, x0–1,7,
som matchar `wc_n_s`/`wc_n_mellan`/`wc_n_o` nästan exakt. Foton `ridhus-klubb-04-
stora-toaletten.jpg`, `-05-lilla-toaletten.jpg` och `-17-dusch-och-wc.jpg` visar tre
**olika** toalettrum med olika ytskikt (helkaklat vitt kakel; gråbeige släta skivor;
grå skivor med golvbrunn) — men **ingen av bilderna visar rummets omgivning eller en
dörr/skylt som binder den till just denna plats i planen** (samma osäkerhet som
`G-klubbdelen.md` redan flaggar). Verdikt: väggarna **BEHÅLL** på planens geometriska
grund, men **funktionen "vilket av de tre fotograferade rummen detta är" förblir
`REFERENCE GAP`.**

## 6. Vägen entré → öppen hall → bana

Planen: den öppna gula hallytan sträcker sig ograverat ända fram till N=11,5-gränsen
(avsnitt 1–2) — det finns **ingen** vägglinje som spärrar hela bredden där. De gröna
pilarna i planen (evakueringsvägar) löper längs västsidans korridor och svänger, i den
nordöstra klustret, rakt in mot själva hallen (`entrance_wide.jpg`, `entrance_grid.jpg`)
— dvs. planens egen utrymningslogik antar att man KAN gå rakt fram från
entréklustret ut i hallen.

Foto: `ridhus-inne-39-gangen-bakom-laktaren.jpg` visar en trägångbrygga på
läktarnivå längs västväggen (samma sida som "Genomsiktlig"-läktaren), som norrut
leder fram till en trappa upp (mot caféet) och en **vit glasad dubbeldörr i marknivå**,
tänd och möblerad innanför — den enda bild i underlaget som binder ihop arenan
fysiskt med en döröppning vid just detta hörn. Det är rimlig men inte 100-procentig
evidens (`REFERENCE GAP`, se nedan) för att den öppna vägen mellan hall och bana ligger
i eller nära detta NV-hörn, brett nog för en dubbeldörr, inte en trång korridor.

**Vad som blockerar i koden idag:** `hall_n_v` (tvärvägg x5,7–10,5 med bara en 1,9 m
dörr vid x7,7–9,6) ligger tvärs över nästan hela den öppna sträckan mellan entrén och
hallgränsen, utan egen evidens (avsnitt 3). Om PO:s klagomål — "det går inte att gå
till ridhuset" — stämmer med koden är det med stor sannolikhet just den väggen (plus
`skap_v`/`skap_o`/`cell_1-4` som gör vägen dit trång) som är boven. Att ta bort den öppnar
en obruten yta hela vägen från entréklustret till N=11,5, i linje med
`ridhus_open_hall_no_room_boxes`.

## 7. REFERENCE GAP

- Exakt väderstreck och plan-koordinat för receptionens glas (öst antaget, inte
  fotobelagt).
- Vilket av de tre fotograferade toalettrummen (`-04`/`-05`/`-17`) som fysiskt är
  `wc_n_s`/`wc_n_mellan`.
- Funktionen bakom receptionens glas (kontor? sadelrum? — skåp och foton syns, inget
  namn).
- Alla rum i NÖ-klustret (`hall_n_v/n_o/mitt/no/no_s`): funktion och exakt vägg-
  geometri, redan flaggat `REFERENCE GAP` i `F02-INTERIOR-MATRIS.md`, bekräftat här av
  att ingen egen pixel-evidens hittades.
- Huvudentréns exakta läge: `CONTRADICTION` mellan det Tobias-sourcade ankaret (väst-
  väggen, N2,2–3,8, ospårbart "Bild 1") och min egen mätning av "här är du"-linjen i
  planen (norra gaveln, N≈0,8, x≈4,4). Olöst, kräver Product Owner.
- Bredden på den öppna vägen hall→bana vid NV-hörnet (uppskattas till "minst en
  dubbeldörrs bredd" ur `ridhus-inne-39`, inget mått).
- Planens egen linje vid x≈2,2, N4,6–8,3 (avsnitt 2): vad den motsvarar fysiskt är
  osäkert — kan vara skåprummets bakvägg, inte en korridorvägg mot receptionssidan.
