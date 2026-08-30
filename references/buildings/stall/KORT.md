# Byggnadskort: Stallet

Ifyllt ur fotona i denna mapp. Allt som inte syns i foto är märkt `[saknas foto]`,
gissningar `[antagande]`. Kortet är facit för byggfunktionen i `src/varld3d.js`.

> **Underlaget är 41 bildrutor** ur `references/video/`: 5 fasadbilder, 14 från
> entrén och 22 inifrån stallgången. De 22 inre bilderna hör till `STALLINNE` och
> den inomhusscenen; kortet nedan gäller utsidan och bygger på fasad- och
> entrébilderna.
>
> Fasadbilderna täcker **västra långsidan och den gavel som ligger närmast
> förstukvisten** — klubbgaveln mot grusplanen, i spelets väderstreck den
> **norra** (rättat 2026-08-29: grusplanen ligger vid nordvästra gaveln, se
> SITEPLAN.md). Östra långsidan och takytan uppifrån saknas; södra gaveln
> är läst ur Street View.

## Foton
| Fil | Fasad/vinkel | Visar |
|---|---|---|
| `stall-fasad-01.jpg` | Från grusplanen, ridhuset i förgrunden | Stallets tak och huvrad bakom ridhusets hörn |
| `stall-fasad-02.jpg` | Samma plan, bredare | Hela långsidan på håll, huvraden, skyltstolpen |
| `stall-fasad-03.jpg` | Snett framifrån västerut | Långsidans fönsterrad, förstukvisten, snörasskyddet, takhuvarna |
| `stall-fasad-04.jpg` | **Bästa översikten.** Hela byggnaden snett framifrån | Gaveln med spiraltrappan, förstukvisten, fönsterrytmen, var huvraden börjar |
| `stall-fasad-05.jpg` | Närmare gaveln | Gavelns fönster, balkongen, spiraltrappan, lampan |
| `stall-entre-01.jpg` | Under förstukvistens tak | Runt fönster, valvfönster, den vita ribbräcket, liggande panel |
| `stall-entre-03.jpg` | Vid räcket, mot dörren | Ockragul dörr, runt fönster, räckets ribbor |
| `stall-entre-06.jpg` | Rakt på dörren | Dörrens solfjäderfönster, "Entré"-skylten, mässingsplakett, vägglampa, betongsockel |
| `stall-entre-15-dorren.jpg` | Rakt på entrédörren, närbild | **Migrerad ur Drive/Stallhuset 2026-08-30** (`IMG_0132.HEIC`, fil-ID `1Ooy6szpBI0Kd0q1SXkNPG9GlZxwCTcUd`). Ockragul dörr med solfjäderfönster, "Entré"-skylt, två mässingsplaketter, kodlås, **runt vitt fönster på BÅDA sidor**, liggande faluröd panel, betongsockel |
| `stall-entre-12.jpg` | Inne i klubbdelen | Branddörren mot stallgången, pärlspont — hör till `STALLINNE` |

## Volym
- Fotavtryck (L × B): **21 × 54 m** `[ASSUMPTION 2026-08-30 — bredden i
  intervallet 15–23 m, se "Bredden" nedan och references/plans/OAVGJORT.md
  fråga 2. Nedgraderad från DERIVED efter Senior Fidelity Review 01: rytmen
  som bar talet är en mätning i längdriktningen och kan inte bevisa sex
  tvärgående band.]`.
  Längden går inte att mäta ur bilderna — ingen visar båda gavlarna samtidigt —
  men huvraden och fönsterrytmen stämmer med 54 m, och satellitbildens 236 px vid
  4,4 px/m ger samma tal (SITEPLAN.md).
- Höjd till takfot: **4,4 m** (hur: entrédörren mäter 85 px för 2,05 m i bild 04,
  alltså 41,5 px/m; takfoten ligger 190 px över marklinjen vid förstukvisten)
- Höjd till nock: **10,0 m** — takfoten plus 28° resning över halva bredden 21 m.
  Direkt mätning i bild 04 ger 9,8 m, vilket stämmer inom en halvmeter.
- Byggnadsform: rak länga med sadeltak och **en utskjutande förstukvist** på
  västra långsidan, nära norra gaveln.

### Bredden — oavgjord, se `references/plans/OAVGJORT.md`

Kortet antog 15 m därför att `STALLINNE` hade en gång och två boxrader, och
`STALLINNE` byggdes ur de 15 metrarna. Den cirkeln är bruten, men **bredden är
inte fastställd** — den är ett antagande i mitten av ett intervall.

Sedan 2026-08-30 finns utrymningsplanen i repot
(`references/plans/stall-plan1-utrymning.jpg`) och är mätt direkt. Den avgör
**planformen och bandens inbördes andelar**, men inte skalan: ritningen saknar
skalstock, och de två vägarna till en skala pekar åt olika håll.

| Om … | då blir … | rimligt? |
|---|---|---|
| längden 54 m | bredden 15,2 m, gångarna 1,9 m | nej, gången för smal |
| boxfacket 3,5 m | längden ~83 m, bredden 23,3 m | nej, längre än ridhuset |
| bredden 21 m | gångar 2,6 m, boxdjup 3,7–4,4 m | måtten inne rimliga, längden inte |

**Spelet bygger 21 m som `[ASSUMPTION]`**, mitt i intervallet 15–23 m. Siffran
ligger på ett enda ställe i koden (`STALLINNE.bredd`) och allt annat följer
andelarna. Ett enda uppmätt mått på plats stänger frågan — se `OAVGJORT.md`.

**Det som däremot ÄR mätt i planen och gäller:**

| Band | Andel av bredden |
|---|---|
| boxrad mot västra ytterväggen | 20,9 % |
| gång A | 12,4 % |
| boxrad, mitt | 17,8 % |
| boxrad, mitt | 17,6 % |
| gång B | 12,3 % |
| boxrad mot östra ytterväggen | 19,0 % |

Samma sex band, i samma ordning, med samma andelar i tre olika tvärsnitt.
**Gångarna är smalare än boxarna är djupa, ungefär två tredjedelar.** Spelet antog
tidigare att alla sex banden var lika breda; det var fel, och det är rättat.

Takgeometrin (takfot 4,4 m, nock 9,8 m mätt i bild 04) ger bredden 20,3 m vid 28°
och 22,1 m vid 26°. Det stöder intervallets övre del, men 28° är självt ett
antagande, så det kan inte låsa något.

- Byggnadsform: rak länga med sadeltak och **en utskjutande förstukvist** på
  västra långsidan, nära norra gaveln.

<details>
<summary><strong>ÖVERSPELAT 2026-08-30 — det gamla beviset för 21 m (öppna bara för historik)</strong></summary>

**Det här avsnittet gäller inte längre.** Det står kvar därför att det förklarar
varför spelet bygger just 21 m, inte för att bevisa att 21 m är rätt. Läs
avsnittet "Bredden — oavgjord" ovan; det är facit.

Senior Fidelity Review 01 underkände beviskedjan, och Review 02 krävde att den
inte får ligga kvar som aktiv kanon bredvid den rättade klassningen. Skälet är
konkret: en framtida agent som läser kortet före implementation kan annars låsa
om samma underkända slutsats.

Kedjan bestod av tre vägar. Så här föll de:

| Väg | Vad den sade | Status |
|---|---|---|
| Planformens sex band | vid 15 m blir varje band 2,50 m — fysiskt omöjligt för en häst | **Står kvar.** Den är ett undre gränsvärde, inte ett mått |
| Huvarnas och fönstrens 3,5 m-rytm | sex band à 3,5 m = 21,0 m | **STRUKEN.** Rytmen mäts i byggnadens längdriktning och kan inte bevisa tvärgående band. Planen visade dessutom att gångarna är ~2/3 av boxdjupet, inte lika breda |
| Takgeometrin | takfot 4,4 + nock 9,8 ger 20,3 m vid 28° | **Svagt stöd.** 28° är självt ett antagande; spannet 26–30° ger 18,7–22,1 m |

Formuleringar som stod här och som inte ska återanvändas: att bredden är
*"rättad"* eller *"fastställd"*, och att nockmätningen bevisade att *"bredden var
för smal"*. Nockmätningen är förenlig med intervallet 15–23 m; den pekar inte ut
en punkt i det.

Fördelningen mellan box och gång som det här avsnittet antog — sex lika breda
band à 3,5 m — är **också struken**. Planen mäter andelarna, och de är ojämna;
se tabellen ovan.

</details>

## Tak
- Form: sadeltak
- Nockriktning: längs byggnadens längd
- Lutning: **28°** `[antagande inom mätspann]`. Gavelns vänstra takfall mäter
  31° i bild 05 och 48° i bild 04, men gaveln står vriden i båda, så mätningen
  blir för brant. 28° är den flackaste rimliga tolkningen, och den som stämmer med
  takfot 4,4 och nock 9,8 över 21 m bredd — se "Bredden" ovan.
- Täckning: **mörk blågrå bandtäckt plåt**, med tydliga stående falsar
- Färg: **(103, 112, 121)** (hur: medianen av de gråa bildpunkterna på takytan i
  bild 03 och 05)
- Takutsprång: litet; **vit fascia och vitt undertak** under takfoten
- **Snörasskydd**: en svart vågrät stång på konsoler, ungefär en tredjedel upp på
  takfallet, längs hela långsidan. Syns i bild 03 och 04 och är ett av de drag som
  gör taket igenkännligt.
- **Hängränna och stuprör i svart** längs takfoten

## Takhuvar — byggnadens tydligaste drag på håll
En lång rad **ventilationshuvar på nocken**: fyrkantig skorstensliknande stam med
en bredare, flat hatt, i samma mörkgrå som taket. Bild 04 visar tolv stycken,
bild 03 fler.

**De börjar inte vid gaveln.** I bild 04 ligger gaveln vid bildpunkt x≈120 och
den första huven vid x≈610 — alltså först efter förstukvisten. Raden täcker
boxlängorna, inte klubbdelen. Det stämmer med `STALLINNE`, där boxarna börjar
söder om klubbdelen i norr.

Avstånd mellan huvarna: **~3,5 m**, alltså en per box.

## Fasader
| Sida | Material | Färg RGB / namn | Fönster | Dörrar/portar | Övrigt |
|---|---|---|---|---|---|
| Långsida V (mot gården) | **liggande träpanel** | **(80, 35, 47)** "mörk falurött" | **Rad av valvbågade, flerrutiga fönster med vit karm, ett per box (~3,5 m)** | förstukvistens ockragula dörr | Vita knutbrädor, vit foder runt varje fönster, ljusgrå betongsockel |
| Gavel N (klubbgaveln mot grusplanen, den höga, närmast förstukvisten) | samma | samma | 2 valvfönster högt, 2 lägre | **vit dörr till en liten balkong** | **Svart spiraltrappa** upp till balkongen; **rund gul lampa** bredvid dörren; vit knut i båda hörnen |
| Gavel S (mot gårdsplanen från Husbyvägen) | samma (Street View) | samma | valvfönster i två plan | **två entrédörrar under vita spetsiga skärmtak** | **rak ståltrappa** med avsats upp till en dörr i övervåningen `[läst ur Street View på avstånd]` |
| Långsida Ö | `[saknas foto]` | | | | |

Detaljfärger:
- Knutar, fönsterfoder, fascia, undertak, räcke: **(238, 236, 228)** "vit"
- Entrédörr: **(168, 118, 80)** "ockragul furu", med **solfjäderformat glasparti**
  överst och skylten "Entré"
- Tak, huvar, snörasskydd, hängränna: **(103, 112, 121)** respektive svart beslag
- Sockel: ljusgrå betong
- Staket framför: rödbrunt tvåregelsstaket; **vitt ribbstaket** vid förstukvisten

## Förstukvisten
Egen sadeltakad utbyggnad på långsidan, med:
- grått tak i samma plåt, vita vindskivor, **vitt pärlsponts-undertak**
- **vita stolpar** i hörnen
- **ett vitt räcke av liggande ribbor** — inte staket, inte spjälor, utan tätt
  liggande brädor med springa emellan. Det är det man ser först när man går fram.
- **ockragul dörr** i mitten, med vit karm och solfjäderfönster
- **ett runt fönster med korspröjs och bred vit karm** på var sida om dörren
- **valvfönster** utanför förstukvisten på båda sidor
- svart vägglampa med kupa över dörren, mässingsplaketter bredvid

## Kännetecken (det som gör att man känner igen den)
1. **Huvraden på nocken.** Tolv likadana lådor i rad, och de börjar först en bit in.
2. **Fönsterrytmen** — ett valvbågat fönster per box, jämnt hela långsidan.
3. **Förstukvisten med det vita ribbräcket** och den ockragula dörren.
4. **Spiraltrappan** upp till balkongen på gaveln närmast förstukvisten.
5. **Snörasskyddet** som svart streck tvärs över det stora grå taket.

## Omgivning som hör till byggnaden
- Grusplan framför
- **Skyltstolpe med åtta armar**: Café, Framridning, Karantänsstall, Ridhus,
  Sekretariat, Solsen(?), Toaletter, Utebana
- Picknickbord och bänkar på gräset
- Betongsuggor vid gaveln
- Rödbrunt tvåregelsstaket mot grusplanen

## Invändigt — utrymningsplanen ändrar bilden

En fotograferad **utrymningsplan (Presto AB, 2025-10-11)** visar stallets Plan 1.
Den är det bästa underlag som finns för insidan, och den säger att `STALLINNE` har
fel planform.

**Det som går att läsa säkert:**

- Stallet är ett **dubbelstall: fyra boxlängor och två gångar**, inte en gång med
  boxar på var sida. Från ena långsidan räknat: boxrad — gång — boxrad — boxrad —
  gång — boxrad. De två mittersta raderna står rygg mot rygg mot en gemensam spine
  med regelbundna märken på (troligen vattenkoppar eller foderluckor).
- Varje box har sitt dörrslag ritat ut mot gången, och de yttre raderna har ett
  märke på ytterväggen i varje box — rimligen valvfönstret, ett per box, vilket
  stämmer med fönsterrytmen utvändigt.
- **Klubbdelen ligger i ena änden**, med en **rak trappa** och en **spiraltrappa**,
  och "Här är du"-markeringen sitter vid entrén där. Det stämmer med fasadfotona:
  förstukvisten på långsidan nära gaveln, spiraltrappan på gaveln, och en Plan 2
  över just den delen.
- **Servicedelen ligger i andra änden**, med flera rum och en rund detalj.
- Utrymningsvägar finns på båda långsidorna, ungefär en tredjedel och två
  tredjedelar in, plus en utskjutande korridor mitt på.

**Det som INTE går att läsa ur den här bilden:**

Bilden är tagen snett, i en reflekterande ram, och mittpartiet är just det som
behöver läsas exakt. Antalet boxar ser ut att vara ett tiotal per länga — alltså
kanske ett fyrtiotal totalt — men de är inte räknade med säkerhet, och de exakta
måtten går inte att läsa ur just den här bilden.

**Vad som behövs för full 1:1-verifiering:**

1. **En rak bild på "Plan 1"**, hela planen i bild, utan vinkel och utan reflex.
   Då går boxarna att räkna och proportionerna att mäta.
2. **Samma på "Plan 2"**, för övervåningen.
3. Har ritningen en **skalstock eller ett måttsatt rum**, ta med det — då blir allt
   annat mätbart.
4. En sparad **satellitbeskärning** med byggnadens längd OCH bredd i bildpunkter.

**Vad som ändå går att bygga nu.** Planformens ordning är läsbar och entydig, och
bredden faller ut ur takgeometrin oberoende av hur planen delas — se "Bredden"
under Volym. `STALLINNE` är därför ombyggd 2026-08-30 till fyra boxlängor och två
gångar på 21 m bredd. Antalet boxar per länga och den exakta fördelningen mellan
box och gång är `[ASSUMPTION]` tills en rak planbild finns; ordningen är
`[VERIFIED]`.

## Stallgången invändigt — läst ur filmerna

Underlaget är **37 bildrutor** ur `video/IMG_0249.mov` (13,3 s, gången norrut)
och `video/IMG_0250.mov` (5,2 s, motsatt håll), uttagna i två bilder per sekund.
Det här är det bästa underlag som finns för insidan, och det säger att gången
inte alls ser ut som ett vanligt trästall.

### Taket — det man känner igen gången på inifrån
- **Sadeltak**, inte platt innertak. Undertaket är **galvaniserad korrugerad
  plåt**, ljus hela vägen upp i nocken.
- **Tvärbalkar i tegelrött** (ungefär (156, 74, 50)) ligger tvärs över gången
  med omkring fyra meters mellanrum, med **snedstag** upp mot en genomgående
  **nockbalk** i samma färg. Fackverket är byggnadens tydligaste inre drag.
- **Galvade dragstag** — smala vertikala rör — hänger från varje balk ner till
  boxarnas överkant. De ger gången sin vertikala rytm.
- **Takfönster** i rad högt i det ena takfallet, syns som ljusa rektanglar
  mellan balkarna.
- **Runda pendelarmaturer** i två rader, en över vardera boxraden, hängande i
  korta pendlar.

### Golvet — två material, inte ett
- **Markstensgång i mitten**, grå betongsten i rätmönster, ungefär tre fjärde-
  delar av gångens bredd.
- **Ljus spånremsa** (gulbeige) längs boxfronterna på båda sidor. Remsan är det
  som gör gången läsbar som en gång och inte som en korridor.

### Boxarna från gången
- Nedre delen: **mörkgrå kompositpanel** i hela sektioner, ungefär 1,3 m hög,
  med en galvad list i överkant.
- Övre delen: **galvad ram med galler**, och boxdörrarna har ett gallerparti.
- **Galvade stolpar** mellan boxarna går hela vägen upp till ungefär 2,2 m.
- På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
  benskydd — mycket saker, tätt. `[ej byggt i spelet ännu]`
- Svarta reglar och handtag på boxdörrarna.

### Gångens ändar
- I fonden syns en **grå metallport** i en vit vägg, med en **rund klocka**
  ovanför och en grön utrymningsskylt bredvid. `[ej byggt i spelet ännu]`
- En vit, rundad form högt upp vid ena änden — troligen ventilationstrumma
  eller en vit gavelvägg bortom taket. `[REFERENCE GAP — inte fastställd]`

### Vad som är byggt efter det här
`v3dStall` i `src/varld3d.js`: sadeltaket i galvad plåt (ritat obelyst, för en
takundersida som bara får ambient blev nästan svart medan filmen visar den
jämnt upplyst av armaturerna), de röda tvärbalkarna med snedstag och nockbalk,
dragstagen, takfönstren, pendelarmaturerna, och golvets två material.

Kvar mot filmen: sakerna som hänger på boxfronterna, och porten med klockan i
fonden.

### Vad filmerna inte avgör
- **Gångens exakta bredd.** Spelet har 5,2 m mellan boxfronterna, vilket ser
  rimligt ut mot bildrutorna, men inget mått är läsbart. `[antagande]`
- **Vilken av de två gångarna filmerna visar.** De visar en gång med boxar på
  båda sidor, vilket båda gångarna har i dubbelstallsplanen. Spelet lägger
  filmernas gång som den västra, närmast entrén, eftersom det är den man kommer
  in i från förstukvisten. `[ASSUMPTION]`
- **Antalet boxar per länga.** Filmen panorerar och samma box kan räknas två
  gånger; planbilden är för sned för att räkna i. Spelet bygger tio per länga,
  vilket ger fyrtio totalt och stämmer med planens "ett tiotal per länga".
  `[ASSUMPTION]`

## Placering (från SITEPLAN.md)
- Position: sydvästra hörnet i (154, 65), fotavtryck **21 × 54 m** (rättat
  2026-08-30; västra långsidan står kvar där den var, huset växer österut)
- Rotation: nocken nord–syd; västra långsidan mot gården och ridhuset
- Klubbgaveln (spiraltrappan) mot grusplanen i norr; servicegaveln mot
  gårdsplanen i söder
- **Sammanbyggt med ridhuset.** Tobias 2026-08-30: *"husen är sammanbyggda, jag
  har varit där"*, *"det är hästgång mellan byggnaderna"*. Hästgången (11 × 6 m)
  går från stallets västvägg till ridhusets östvägg, så att hästen kan ledas
  inomhus mellan husen. Utrymningsplanernas situationsplan ritar husen som
  skilda volymer — det är en CONTRADICTION som avgjorts till Product Owners
  fördel; se `references/plans/OAVGJORT.md` fråga 1.
- **Var hästgången ansluter är verifierat.** Satellitbilden
  (`references/plans/SATELLIT-HASTGANG-2026-08-30.md`) visar förbindelsen
  centralt i husens gemensamma längd. Den ligger i liv med **stallets egen
  tvärkorridor** — korridorens mitt ligger på y 91,05 och husens gemensamma
  mitt på y 92,0. Öppningen i västväggen sitter därför 26,75 m från
  klubbgaveln, mitt för korridoren, och ingen ny öppning behövde uppfinnas.
- Den västra hästporten på u 30 är **borttagen**. Den var uppfunnen för spelets
  skull och låg i tvärkorridorens västra ände, alltså där gången nu går.
  Skjutporten på östra långsidan mot hagarna står kvar — den är läst i
  Street View.
- Förstukvisten på västra långsidan, ~6 m från norra gaveln
- Marknivå: plant

## Fotobrist

**Delvis löst av Street View.** En bild från Husbyvägen (sep 2024) visar stallets
**östra långsida**, mot hagarna. Den sparas inte i repot, men det den visar är byggt:

- samma huvrad på nocken och samma fönsterrytm som på västra sidan
- en **stor skjutport i blågrått** ungefär mitt på längden
- fodersilon vid södra gaveln
- trästaketade hagar direkt utanför, och sandbanan bortom dem

1. **Östra långsidan på nära håll** — fönstrens antal och portens mått är lästa ur
   en Street View-bild på avstånd, inte mätta. `[antagande]`
2. **Södra gaveln på nära håll** — läst ur Street View på avstånd; portarnas
   och trappans mått är uppskattade. Där ligger servicedelen enligt `STALLINNE`.
3. **Takytan uppifrån**, för att räkna huvarna och se hela nocken.
4. **En rak bild på långsidan**, för längdmåttet och exakt fönsterantal.
5. Närbild på gavelns balkong och spiraltrappa.

## Byggstatus
- Byggd version: `src/site.js` (mått, färger, fönsterrytm, öppningar) och
  `v3dStallYttre` i `src/varld3d.js` (huvrad, snörasskydd, hängränna,
  förstukvist, balkong och spiraltrappa). Verifierad mot bild 04 från samma
  vinkel, i två omgångar.

Färgerna är mätta, inte gissade. Medianen av bildpunkterna på väggen i tre
fasadbilder ger (80,35,47), och av de gråa bildpunkterna på takytan (103,112,121).
Modellen ligger nu på (80,36,48) respektive (103,117,128).

Det som rättades mellan omgångarna:
1. Förstukvistens gavelspets var vit. På fotot är den röd panel med vita
   vindskivor — det är vindskivorna som är vita, inte spetsen.
2. Taket var för ljust och för blått, väggen för mörk i grönt och blått.
3. Knutbrädorna var 34 cm breda och läste som stolpar; nu 18 cm.
4. Runda fönster ritades som tolvhörningar och var för stora.

- Medvetna avvikelser från verkligheten:
  - Östra långsidan har inget fotounderlag och byggs som spegling av den
    västra: samma fönsterrytm, ingen förstukvist. `[antagande]`
  - Södra gavelns dörr- och trappmått är lästa ur Street View på avstånd. `[antagande]`
  - Längden 54 m är inte mätt, se Volym.
  - Entrén låg tidigare på södra gaveln i spelet. Fotona visar den på
    långsidan, ~5,6 m från klubbgaveln, och den är flyttad dit — både
    dörrmarkören på gården och utgången i stallgången.
  - 2026-08-29: hela huset vändes rätt — klubbgaveln med spiraltrappan
    vetter mot grusplanen i norr, servicedelen mot gårdsplanen i söder.
