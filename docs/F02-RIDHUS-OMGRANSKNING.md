# Ridhuset — käll-för-käll-omgranskning 2026-09-03

**Beställd av Product Owner** (kommentar 13:19 UTC på #73: "Ridhuset still
does not visually/spatially match the real facility. Re-audit the riding
hall against the source material before any further polish. Identify the
remaining mismatches explicitly, then correct them.")

**Utförd** av en granskningsagent på branch `claude/f02-a-interior-topology`
@ `5387324`, mot samtliga 76 interiör-/gavelfoton, planerna, `KORT.md`,
`INTERIOR-MATRIS.md`, granskningsfilerna A–G och spelets renderingar.
Rapporten nedan är agentens text, oredigerad. Ovanför den står vad som
gjordes med varje rad.

## Vad som gjordes med raderna (huvudagenten)

| # | Rad | Åtgärd |
|---|---|---|
| 1 | Läktarens tre bänkrader | **Redan byggt i F02-B (#76)**: `laktare.rader` + `Geometri.laktarRader`, tre stegade rader i ljus furu bakom gångbrädan. Tobias såg den kombinerade previewn med raderna; raden är alltså inte orsaken till underkännandet. |
| 2 | Läktarlångsidans vägg | **Rättad i denna commit**: `IDENTITET.ridhus.laktarVagg` — mörka pelare där takstolarna landar (`takstomme.delning`, DERIVED) på båda långsidorna, skivskarvar på läktarsidan. Webb + Roblox. |
| 3 | Panelens utbredning | **Rättad**: `ovreVagg.y0/y1` härleds till hallens hela långsida (0 → langd − entre). Skyltarna följer med via `andel`. |
| 4 | Dubbla speglar | **F02-B**: `speglar` tas bort och `spegel_B` (en, delad) byggs där. Orört här för att inte skapa konflikt i samma rader. |
| 5 | Fönsterband → separata fönster | **Rättad**: `fonsterband.perFalt`, ett fönster per väggfält (`ridhusFalt`, delad regel). Bredden 3,0 m [uppskattning]. |
| 6 | Gångbrädans färg | **Redan byggt i F02-B**: `laktare.gangbrada.farg` `#5A4634`. |
| 7 | Läktarfrontens källhänvisning | **Rättad**: kommentaren vid `laktarfront` säger nu `[REFERENCE GAP]`; F02-B ersätter fältet. |
| 8 | Skyltordningen | **Rättad**: ordning och två RS Mustang enligt `-31`/`-17`, andelar lästa mot bokstäverna M/B/F (DERIVED). |
| 9 | Entrédelens tomma korridorer | F02-B/REFERENCE GAP: dörrblad, glaspartier, skåp. Geometrin (väggar/luckor) är F02-A; ytor och möbler är F02-B. Noterat som kvarstående. |
| 10 | Huvudentrén 2,2 mot 9 m | `CONTRADICTION`, exteriörlåset vinner. Oförändrat. |
| 11–18 | Café, sockelhöjd, sarglucka, dynor, domarbås, bokstäver, ventilation, skåp | F02-B-scope, redan rätt märkt, eller "stämmer". Inga ändringar. |

**Ett fynd utöver agentens tabell, av huvudagenten vid kontroll av
`ridhus-inne-23-kortsidan-vid-a.jpg`:** den vita A-gaveln står DIREKT bakom
den södra sargen (A-skylten på sargen, dubbel glasdörr i väggen, speglar på
väggen direkt ovanför sargen, bomförrådet i hörnet). Spelet har en 5,68 m
djup zon mellan sargen och gaveln (`bana.y` = 5,68) därför att hallens
verifierade längd 77,18 m = 11,5 m entrédel + 60 m bana + 5,68 m rest.
Fotot säger att resten inte ligger vid A. Antingen är banan längre än 60 m
mellan sargarna, eller så är entrédelen/C-blocket djupare än planen lästes.
**Löst i nästa commit (senior review på `e879784`):** 60 m var
dressyrlayoutens mått, inte hallens fysiska sarg-till-sarg. `bana` är nu
den fysiska ridytan (A-sargen mot gaveln → entrédelens gräns, h ≈ 65,5 m
DERIVED ur planen + fotot) och `dressyr` är 20 × 60-layouten förankrad i A.
(F02-B:s strukturella fynd 3, "sydgaveln vid A mot sargen", är samma sak
och löses av samma ändring.)

---

# Ridhuset — käll-för-käll-omgranskning mot spelet

Utförd 2026-09-03 på branch `claude/f02-a-interior-topology`. Ingen fil i
repot är ändrad av denna granskning. Uppdraget: jämföra allt verifierat
referensmaterial om ridhusets interiör mot vad `src/site.js`
(`RIDHUSINNE`), `src/varld3d.js` (`v3dRidhus`) och `src/data.js`
(`DRESSYRBOKSTAVER`) faktiskt bygger, och lista kvarvarande avvikelser.

**Viktigt att förstå innan tabellen läses:** `references/buildings/ridhus/
INTERIOR-MATRIS.md` (byggd 2026-08-31 på 103 bilder, den mest grundliga
källgranskningen i repot) skriver uttryckligen i sin sista rad: *"Ingen
rad ovan har jämförts mot `src/site.js`... Nästa steg är en jämförelse
mot datan, och den kommer att hitta fler `KNOWN MISMATCH` än de som står
här."* Den jämförelsen är vad den här rapporten gör. Flera av de allvarligaste
fynden nedan är alltså inte nya foto-observationer — de är redan
`VERIFIED` i repot, med namngivna bilder — men har aldrig förts in i
spelets geometri- och materialdata.

Jag har tittat på samtliga 76 interiör-/gavelfoton i
`references/buildings/ridhus/`, de två planerna, `KORT.md`,
`INTERIOR-MATRIS.md` och alla sju granskningsfiler A–G, samt läst
`src/site.js` rad ~85 och ~757–2000, `src/varld3d.js` `v3dRidhus`
(rad 1231–1705) och `src/data.js` `DRESSYRBOKSTAVER`. Jag har också
öppnat ett tiotal av de befintliga 3D-renderingarna i scratchpad
(`bas-06-laktaren.png`, `rh-06-laktaren.png`, `f02b-05/06/07*.png`,
`k06/k07-ridhus-*.png`) för att se hur datan faktiskt målas upp.

---

## 1. Avvikelser

| # | Zon | Källan visar | Spelet bygger | Klass | Allvar | Föreslagen rättelse |
|---|---|---|---|---|---|---|
| 1 | Läktare (långsida) | **Tre stegade bänkrader i ljus furu**, hela långsidans längd, bakom en mörk gångbräda. `VERIFIED`, `ridhus-inne-07-laktartrappstegen.jpg`, `-14-laktaren.jpg`, `-43-laktaren-vid-h.jpg` — tre oberoende bilder, samstämmiga. `INTERIOR-MATRIS.md` §2 säger uttryckligen att en tidigare version av spelet HADE dessa rader, och att de togs bort på ett felaktigt underlag ("felet gick i spelets disfavör") | `src/site.js` `RIDHUSINNE.laktare` byggs som ett **plant plankdäck** (`dackZ`, `dackDjup`) med solid front — kommentaren i koden säger uttryckligen "PLANT DÄCK, inte trappsteg". `src/varld3d.js` rad ~1393–1440 bygger bara plankdäck + front + räcke, inga bänkrader | **VERIFIED-avvikelse** | **Hög** | Bygg tillbaka 3 stegade rader i ljus furu (`#86715B`, redan mätt i `RIDHUSINNE.kortanda.bank`) bakom gångbrädan, längs hela `R.laktare` — inte bara vid kortändan |
| 2 | Läktarlångsida (vägg ovanför bänkarna) | **Ljus stående skivpanel med mörka pelare** — en egen väggtyp, skild från sponsorväggens rödbruna panel. `VERIFIED`, `ridhus-inne-14`, bekräftat av produktägaren 2026-08-31 (`INTERIOR-MATRIS.md` §5) | Finns inget sådant material i datan. `v3dRidhus` rad 1283–1286 målar **alla fyra ytterväggar** i samma platta färg `R.hallvagg` (`#ACA99D`) — samma ton som är mätt för den vita kortändeväggen. Bekräftat i renderingarna `bas-06-laktaren.png`, `rh-06-laktaren.png`, `f02b-06/07*.png`: väggen bakom domarbåset/vid E är en helt slät, enfärgad beige yta utan pelare, fönster eller relief | **VERIFIED-avvikelse** | **Hög** | Lägg till en egen materialdefinition (analog med `ovreVagg`) för läktarlångsidans vägg: stående ljusa skivor + mörka pelare på jämnt avstånd |
| 3 | Sponsorlångsida (panelens utbredning) | Panelen går **hörn till hörn längs hela långsidan**, inte ett mittstycke — "materialgränsen ligger i HÖRNET", `VERIFIED` med fyra bilder i samma bildruta (`ridhus-inne-31`, `-11`, `IMG_0189-f01`, `IMG_0192-f08`), `INTERIOR-MATRIS.md` §4 | `src/site.js` `ovreVagg:{sida:"E", y0:6, y1:40}` — spelets egen kommentar säger "ungefär 44 % av husets längd" (34 av 77,18 m). Resten av väggen (norr och söder om detta band) är bar `hallvagg` | **VERIFIED-avvikelse** | **Hög** | Sätt `ovreVagg.y0/y1` till banans fulla utsträckning (≈5,68–65,68), inte ett 34 m mittstycke |
| 4 | Sponsorlångsida, spegel vid B | **En (1)** spegel, delad av en mittpost i två lika rutor, i brun träram, monterad direkt ovanpå sargen vid bokstaven B. `VERIFIED`, fyra bilder (`ridhus-inne-27`, `-18`, `IMG_0189-f05`, `-f06`), `INTERIOR-MATRIS.md` §4 | `src/site.js` `RIDHUSINNE.speglar:[{y:19,b:3.2},{y:37,b:4.2}]` — **två** speglar av olika bredd. (Källan till felet: `KORT.md`, en äldre och grövre källa, skriver "två stycken" — en `CONTRADICTION` mellan repots två kort som aldrig avgjordes) | **CONTRADICTION**, avgjord av den mer detaljerade källan | Medel | Bygg en spegel med mittpost vid B (`y≈` bokstaven B:s läge på panelsidan); ta bort den andra |
| 5 | Sponsorlångsida, fönsterband | Fönstren sitter som **diskreta öppningar per väggfält**, avskilda av bärande pilastrar — inte ett löpande band. `VERIFIED`, `ridhus-inne-17-reklamvaggen-mot-hornet.jpg`, `-24-skyltvaggen-vid-f.jpg`, `INTERIOR-MATRIS.md` §4 | `src/varld3d.js` rad ~1368–1386 bygger **ett enda långt glasband** (`R.langd-1.0`) med jämnt fördelade spröjs (`postDelning`) — samma "generiska upprepade fönster"-mönster som dokumentet uttryckligen varnar för när det gäller kortändans glasband | Nyanserad `VERIFIED` | Medel | Dela fönsterbandet i fält som följer pilastrarnas/panelfältens rytm, med tät vägg mellan fälten, inte ett kontinuerligt band |
| 6 | Läktare, gångbräda | Gångbrädan mellan sarg och bänkrader är i **mörkt trä**. `VERIFIED`, `ridhus-inne-04-sargen-mot-laktaren.jpg` | `src/varld3d.js` rad 1406: `lak.lada(L.dackDjup,0.10,LL,"#C9BCA4",...)` — `#C9BCA4` är ett ljust gulbeige trä, inte mörkt | `VERIFIED-avvikelse` | Medel | Byt till en mörk träton, t.ex. i linje med `laktarfront.farg` (`#4E3626`) eller en egen mätning |
| 7 | Läktarens front mot banan (den solida mörka brädväggen) | Byggd på samma beskurna bild som fälldes för läktarraderna (`ridhus-inne-01`, beskuren) — matrisen har själv **återkallat** slutsatsen "solid mörkbetsad brädfront" och nedgraderat "ljus kappregel" till `[REFERENCE GAP]`. `INTERIOR-MATRIS.md` §2 | `src/site.js`/`varld3d.js` bygger fortfarande denna front och kappregel som om den vore `VERIFIED` (`IDENTITET.ridhus.laktarfront`, kommentaren "OM-AUDITENS PUNKT A ... VERIFIED att fronten är solid, mörk...") | `CONTRADICTION` — spelets egen källhänvisning är föråldrad | Låg-medel | Ingen ombyggnad krävs ännu, men kommentaren i koden bör rättas till `[REFERENCE GAP]` så att den inte längre citeras som starkare bevisad än den är |
| 8 | Sponsorlångsida, skyltordning | Ordning vänster→höger i `ridhus-inne-31` (den enda bild som fångar hela väggen): …Agria → **Hästsportbutik** → **två separata blå RS Mustang-skyltar**. `VERIFIED`, `INTERIOR-MATRIS.md` §4, "Skyltraden hårdkodas — beslut 2026-08-31" | `src/site.js` `skyltar` bygger ordningen …Agria → **RS Mustang** → **Stigsbergs Gård** (omvänd), och RS Mustang som **en** skylt i stället för två | `VERIFIED-avvikelse` | Låg | Byt plats på de två sista skyltarna; dela RS Mustang i två skyltar |
| 9 | Entrédel/klubbdel, väggmaterial | — (inget foto avgör ytmaterialet för de flesta av entréhallens väggar; men klubbdelens korridorer *har* dokumenterad möblering — skåp, glaspartier, dörrar, valvfönster — se `INTERIOR-MATRIS.md` §8) | `v3dVaggarOchRum` målar entréhallens väggar i en enda platt färg (`R.hallvagg`) utan dörrbladen, glaspartierna eller skyltarna som fotona visar. Bekräftat i `k06-ridhus-entre-ost.png` och `k07-ridhus-skap-syd.png`: en labyrint av släta, enfärgade korridorer utan en enda synlig dörr, fönster eller skylt | `REFERENCE GAP` i källan (rummens exakta ytor), men `ASSUMPTION` i spelet att lämna dem helt tomma trots att F02-B-möblering delvis finns | **Hög** för rumslig igenkänning — se § *Rumslig läsning* | F02-B-scope, men värt att flagga: en spelare som går in från parkeringen möter en tom, labyrintisk gång i stället för den dörr-, skylt- och glasrika korridor fotona visar |
| 10 | Huvudentrén | Planens entrécell ligger 2,2–2,7 m från gaveln; fasadens låsta dörr sitter 9 m från gaveln (`u:9`). Redan känd `CONTRADICTION`, exteriören låst av #71 | Spelet behåller fasadens dörr; planens entrécell ligger 6 m fel | `CONTRADICTION`, redan dokumenterad | Medel (redan känd, ej ny) | Avgörs av exteriörlåset, inte här — upprepas bara för fullständighet |
| 11 | C-kortända, glasrum sedda inifrån | Kaférummet inifrån har **vita bord, grå perforerade metallstolar, runda pelarbord, panelinnertak med ljusslinga**. `VERIFIED`, `ridhus-klubb-09-cafesalen.jpg` | `RIDHUSINNE.cafe` bygger bara ett golvplan och en vägg mot banan — ingen möblering, inga stolar/bord | `REFERENCE GAP`→`ASSUMPTION` (tomt) | Låg (F02-B-scope) | Möblera kaférummet enligt fotot när F02-B tar vid |
| 12 | C-kortända, sockelhöjd/bänkstruktur | `INTERIOR-MATRIS.md` markerar sockel/steghöjd, trappornas riktning och båsens delning som `[REFERENCE GAP]` trots att spelet bygger exakta tal (`sockelH:0.80`, `stegD:1.1` osv) | Spelet bygger exakta mått som om de vore mätta | `DERIVED`, korrekt märkt i koden själv | Låg | Ingen åtgärd — redan korrekt märkt `[ASSUMPTION]`/`DERIVED` i koden, tas med för att bekräfta att märkningen stämmer |
| 13 | Sargluckan med trappa | Minst en sarglucka är en **öppningsbar dörr med gångjärn, ner till en trappa**, intill spegeln. `FOTO, EJ GRANSKAD`, `ridhus-inne-37-rampdorren.jpg` | Finns inte i `RIDHUSINNE` — sargen byggs som en obruten linje förutom `sargGrind` (hästgången) och `SPELABSTRAKTIONER.ridhus.sargport` | `REFERENCE GAP` (funktion/mått), men elementet är inte ens representerat | Låg | Kräver granskning av bilden innan den läggs till (endast en granskare, ej korsverifierad) |
| 14 | Läktarens front, sittdynor och stolar | Elon-dynor på översta bänken, orangea plaststolar. `VERIFIED`/`FOTO, EJ GRANSKAD`, `ridhus-inne-07`, `-40` | Byggs (`R.dynor`, stolarna i `v3dRidhus` rad 1426–1432) | stämmer i sak, men sitter nu på ett plant däck i stället för på den översta av tre bänkrader — position blir fel när rad 1 rättas | följd av # 1 | Medel | Flytta dynorna/stolarna till översta bänkraden när raderna byggs tillbaka |
| 15 | Domarbåsets läge | Båset står **mellan E och H**, mitt på läktarlångsidan, `VERIFIED` `ridhus-inne-14` | `domarbas:{x:23.2, y:0...}` med `y` härlett till E:s position (husets y=32) | stämmer | — | ingen åtgärd, tas med för fullständighet i "vad som stämmer" nedan i stället |
| 16 | Bokstavsaxeln | K,V,E,S,H på läktarsidan; F,P,B,R,M på sponsorsidan; A söder, C norr. `VERIFIED` genom fem namngivna foton (§ *Bokstäverna*) | `src/data.js DRESSYRBOKSTAVER`: K,V,E,S,H vid x=0 (läktarsidan `sidor.laktare="W"`); F,P,B,R,M vid x=20 (panelsidan). A y=0 (söder), C y=60 (norr) | stämmer | — | ingen åtgärd, se "vad som stämmer" |
| 17 | Taket, installationstyper | Tre skilda ventilationsdragningar: isolerad flexkanal, galvaniserad kanal genom takfoten, lodrät grå kanal längs väggen. `VERIFIED`, `INTERIOR-MATRIS.md` §6 | `IDENTITET.ridhus.ventkanaler` bygger runda kanaler längs hallen med don — en typ, inte tre olika dragningar | `DERIVED`/nyanserad `VERIFIED` | Låg | Redan uttryckligt märkt `[ASSUMPTION]` i koden för antal/dimension; skillnaden i typ är mindre viktig för igenkänning än väggarna ovan |
| 18 | Skåpkorridoren/klubbdelens möblering | Skåp i grått/rött/mörkgrått, bröstningsvägg med fyra glaspartier, röda trästolar, valvfönster. `VERIFIED`, `ridhus-klubb-01`, `IMG_0169-f02` | `entrehall.rum` ger korridoren ett namn (`skapkorridor`) men ingen möblering byggs (F02-B) | `REFERENCE GAP`→scope | Låg | F02-B-scope, ej fidelitydata-fel |

*(Tabellen prioriterar allvar; rader 10–18 är antingen redan kända, lågt allvar,
eller redan korrekt märkta i koden — de tas med för fullständighet enligt
uppdragets krav på källa-för-källa-genomgång, inte för att de är nya fynd.)*

---

## 2. Vad som stämmer

Så att ingen river rätt saker:

- **Sargens grundform och andel**: vit sarg, ~1,35 m, mörk sockel som är
  ~19 % av höjden (`sockel 0.26/1.35`) — stämmer väl mot `ridhus-inne-31`
  och `-14`, där sockelbandets andel av den vita ytan ser ut att ligga i
  samma härad. `sargH:1.35` i `RIDHUSINNE`.
- **Bokstavsaxeln och sidorna**: K/V/E/S/H på läktarsidan, F/P/B/R/M på
  panelsidan, A i söder, C i norr — matchar de fem namngivna
  källbilderna exakt (se rad 16 ovan). `src/data.js` och `RIDHUSINNE.sidor`
  är konsekventa med varandra (kartan i `src/render.js` läser samma tabell,
  ingen dubbel vridning kvar).
- **Domarbåset**: mörkt trä, upphöjt på läktaren, trappa med räcken på
  båda sidor, grön exit-skylt, läge mellan E och H — allt fotoverifierat
  och allt byggt (`RIDHUSINNE.domarbas`, `basTak`).
- **C-blockets grundstruktur**: två trappor, glasband med mörka
  träkarmar som bryts av trapporna (inte ett löpande band), stjärnan och
  klockan på den vita mellanväggen — allt `VERIFIED` och allt byggt.
- **Panelens färg och läktarens riktning**: mätta färgvärden
  (`panel:"#765B59"`, sand `#6F5D4D`, tak `#5C4C45`/`#5E5B5E`) ersatte
  gissade toner och ligger nu nära de uppmätta värdena i dokumentationen.
  Läktaren i väster / panelen i öster stämmer med den nya, ankrade
  orienteringen (svarta gaveldörren).
- **Underlaget** byggs brunt och träfiberbemängt, inte gul sand — matchar
  `ridhus-inne-11`/`-43`.
- **Hindren och konerna** som ligger framme på banan mellan lektioner är
  ett riktigt observerat drag (`ridhus-inne-11`, `-38`) och finns i
  spelet, om än med `[ASSUMPTION]`-lägen.
- **Taket i stort**: symmetriskt sadeltak, balkar tvärs/lysrör längs,
  korrugerad plåt som undertak, stålprofiler, kabelstegar och
  ventilation utöver limträbalkarna — grundstrukturen är rätt, även om
  exakt kanaltyp skiljer (rad 17).

---

## 3. Rumslig läsning

Produktägarens iakttagelse — "läser inte rumsligt som det verkliga
ridhuset" — går att förankra konkret i minst fyra saker:

**1. Läktarsidan är den mest karaktäristiska ytan i hela hallen, och den
är den som saknas mest.** Den som stått i UBRF-ridhuset minns
trälänkarnas terrasserade bänkrader (`ridhus-inne-07`, `-14`, tre rader,
ljust trä, dynor) lika mycket som sargen. I spelet är den ytan i dag ett
platt, obrutet plankdäck (§ Avvikelse 1) framför en helt slät, enfärgad
vägg utan pelare eller fönster (§ Avvikelse 2) — se
`bas-06-laktaren.png`/`rh-06-laktaren.png`: kameran står nästan exakt
där fotografen stod i `-14`, och skillnaden är omedelbar. Detta är
sannolikt den enskilt största orsaken till att hallen inte känns igen —
det är den vägg spelaren står vänd mot vid E/domarbåset.

**2. Sponsorväggen är rätt i detalj men fel i utsträckning.** Panelen,
skyltarna och signaturfärgen är korrekt byggda och rätt placerade i sig
(se § Vad som stämmer) — men täcker bara ~44 % av väggens längd i
stället för hela den 60 m långa banväggen (§ Avvikelse 3). Effekten är
att den vägg som *ska* vara identifierande på hela sin längd bara läser
rätt i mitten och blir bar `hallvagg`-färg i båda ändarna, vilket bryter
intrycket särskilt nära kortändorna.

**3. Bredd/längd-förhållandet är en `REFERENCE GAP` som `KORT.md`
och `INTERIOR-MATRIS.md` själva räknat sig fram till, utan att det motsägs
av något foto.** `KORT.md` räknar fotavtrycket till 25 × 75 m ur den sneda
utrymningsplanen (2,7:1 uträknat mot bekräftade 20×60-banan), vilket ger
en 60 m bana + 4,4 m läktarband + 11,5 m entrédel i längd. Spelets
`RIDHUS_LANGD=77.18` (`VERIFIED`) och `RIDHUS_BREDD=25` ligger inom det
och motsägs inte av något foto jag sett — bredden är alltså rimlig, men
förblir formellt `[REFERENCE GAP]` tills ett uppmätt avstånd finns.
Takhöjden (6,2 m till takfot, `[antagande]` i `KORT.md`) syns inte i något
interiörfoto med känd referenslängd heller. Ingen bild motsäger dagens
tal, men inget bekräftar dem till centimetern.

**4. Entréupplevelsen är en tom labyrint, inte en möblerad hall.**
Klubbdelens 16 dokumenterade rum (skåp, glaspartier, röda stolar,
valvfönster, kaférum — `INTERIOR-MATRIS.md` §8) finns som geometri
(väggar och öppningar) men praktiskt taget ingen av dem har fått
material, dörrblad eller möbler i renderingen (`k06`/`k07` i
scratchpad). En spelare som går in från parkeringen möter i dag släta,
enfärgade korridorer utan en enda synlig dörr — motsatsen till fotonas
rum fulla av skåp, glas och skyltar. Detta ligger formellt inom F02-B
(möblering), men är värt att nämna eftersom det direkt påverkar om
"det känns som UBRF" redan innan man kommer ut på banan.

**Golvets färg** stämmer (brunt, träfiberbemängt, `#6F5D4D`-ish, inte gul
sand) — det är inte en bidragande orsak. **Ljuset** (lysrörsrader längs
hallen, spotlights på balkarna) är grundstrukturellt rätt. **Sargens
höjd/färg** stämmer väl. Det är alltså specifikt **läktarväggen och dess
bänkar**, samt **panelens utsträckning**, som är de två enskilt största
bidragsgivarna till att hallen inte läses som UBRF:s ridhus.

---

## 4. Referensluckor som kvarstår efter full källkontroll

1. **Alla exakta mått i hallen och klubbdelen** — ingen bild har en känd
   referenslängd i bild. Gäller panelens exakta höjd, fönsterbandets
   postdelning, läktarraders stig-/djupmått, balkfältens antal.
2. **Ridhusets bredd/längd-förhållande i djupled** — rektifieringen av
   entréplanet underkändes tidigare (kantresidual 8,11 %/4,89 % mot krav
   3 %), och Tobias kan inte fotografera om planen. Talen vilar på ett
   rutnät lagt på den sneda bilden, `±0,5 m`.
3. **Klubbdelens planlösning** — 16 rum kan beläggas i foto, men ingen
   bild binder ihop dem till en sammanhängande planlösning. Tobias
   markerade planurklipp (Bild 1–7) finns inte i repot.
4. **Sargluckornas funktion** — minst en är en dörr med trappa
   (`ridhus-inne-37`); om de övriga är dörrar, ventiler eller
   löstagbara sektioner är oklart.
5. **Motstående kortsidans material** (vid A) — läses olika i olika
   bilder (vit skivpanel enligt vissa, mörk panel enligt `IMG_0192-f04`/
   `IMG_0196-f01`) — `MOTSÄGELSE`, avgörs bäst på plats.
6. **Om den ljusa skivpanelens material på läktarlångsidan fortsätter
   bakom bänkraderna ner till golvet** — ingen bild ser bakom raderna.
7. **C-blockets tre trappsymboler i planen mot två synliga trappor i
   foto** — vilket håll de går är olöst.
8. **Sargporten för fotgängare** — ingen källa visar en grind i sargen;
   spelets nuvarande lösning är uttryckligen märkt `SPELABSTRAKTION`,
   inte fidelity, och det är korrekt hanterat redan.
9. **Kaférummets exakta möblering och mått**, **omklädningsdelens
   våningsrelation till kaféet**, och **södra sargens ev. öppning** —
   alla redan flaggade `[REFERENCE GAP]` i `INTERIOR-MATRIS.md` och
   inget nytt foto ändrar det.

Inget av ovanstående fylls med en gissning i den här rapporten.

---

## Sammanfattning

De 5–8 viktigaste avvikelserna, i fallande allvar: (1) Läktarens
karaktäristiska trebänkiga trätrappa saknas helt — spelet bygger ett
platt plankdäck där källan entydigt visar stegade rader i tre
oberoende foton, och repots egen granskning säger uttryckligen att den
tidigare borttagningen var ett misstag som aldrig rättades i koden.
(2) Läktarlångsidans vägg — den yta spelaren möter vid domarbåset — har
inget eget material alls; den målas i samma platta ton som alla andra
väggar, trots att källan visar en tydlig ljus skivpanel med mörka
pelare, skild från sponsorväggen. (3) Sponsorväggens rödbruna panel,
som i övrigt är korrekt i färg och detaljer, täcker bara knappt hälften
av väggens längd i stället för att gå hörn till hörn, vilket lämnar
bara väggens ändar bara. (4) En dubblerad spegel där källan visar en.
(5) Fönsterbandet byggs som ett kontinuerligt band i stället för
diskreta fönster mellan pilastrar. Utöver dessa: gångbrädans färg är
fel (ljus i stället för mörk), skyltordningen på sponsorväggen är delvis
omkastad, och entréhallens 16 dokumenterade rum saknar i praktiken
material, dörrar och möbler i renderingen — vilket gör ankomsten till
ridhuset till en tom, labyrintisk korridor snarare än den möblerade
hall fotona visar. Det som stämmer väl är sargens mått/färg,
bokstavsaxeln och sidfördelningen, domarbåset, C-blockets grundstruktur
och takets grundstruktur. Bredd/längd-förhållandet (25×77 m) motsägs
inte av något foto men förblir formellt en `REFERENCE GAP`. De två
högst prioriterade rättelserna för att adressera Tobias observation är
läktarväggens material och bänkraderna — det är den yta en besökare från
UBRF skulle sakna först.
