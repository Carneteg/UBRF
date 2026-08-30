# Ridhusets interiör — reference matrix

Steg 2 i interiör-P0. En rad per zon: plan-fakta, foto-fakta, `REFERENCE GAP`.
Beskriver **nuläget**, inte historiken.

## Källor

| kort | fil |
|---|---|
| r01 | `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg` (IMG_0179) |
| r02 | `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg` (IMG_0183) |
| r03 | `references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg` (IMG_0198) |
| plan | `references/plans/ridhus-entreplan-utrymning.jpg` |
| mätning | `references/plans/RIDHUS-PLANMATNING-2026-08-30.md` |

`IMG_0191.MOV` finns **inte** i repot — `[DRIVE-ONLY]`. Inget nedan vilar på den.

## 1. Banan och sargen

| fakta | klass | källa | spelet |
|---|---|---|---|
| Banan 20 × 60 m | `VERIFIED` | Tobias bekräftelse, `SITEPLAN.md` | `bana` |
| Sargen vit/gräddvit med svart sockelband | `VERIFIED` | r01 + r03 | `vagg`/`sockel` |
| Sarghöjd 1,35 m | `DERIVED` | — | `sargH` |
| Sockelbandets andel av sarghöjden | **prövat, ej ändrat** | r03 | 0,26 av 1,35 = 19 % |
| Dressyrbokstäver på sargen | `VERIFIED` | C i r01, E i r03 | byggs |
| E har en elefantbild | `VERIFIED` | r03 | `[REFERENCE GAP]` — ritas inte |

**Not:** en tidigare referens som påstods vara en måttsatt ritning är
**återkallad** (se `RIDHUS-PLANMATNING-2026-08-30.md`). Banans 20 × 60 står
kvar på Tobias bekräftelse, inte på den bilden. Påståendet om "5 m
sidozoner" kom ur den återkallade källan och används inte.

## 2. Långsidans läktare — `KNOWN MISMATCH A`, rättad

| fakta | klass | källa | spelet |
|---|---|---|---|
| **Plant plankdäck**, inga trappsteg | `VERIFIED` | r01 förgrund, beskuren | rättat |
| Solid mörkbetsad brädfront mot banan | `VERIFIED` | r01 + r02 | rättat |
| Ljus kappregel överst på fronten | `VERIFIED` | r01 | rättat |
| Däckets höjd 0,80 m | `DERIVED` ur r03 | sittande huvuden ~0,7 m över sargkrönet | `dackZ` |
| Frontens topp 1,45 m | `DERIVED` | strax över sargkrönet | `frontTopp` |
| Exakta mått | `[REFERENCE GAP]` | — | testas som relation |

Spelet byggde **fyra trappsteg i ljus furu** längs hela långsidan. Fotona
visar ett plant däck. Trappstegen finns — vid KORTÄNDAN, under glasrummen.
De två strukturerna hade blandats ihop.

## 3. Kortändan vid C

| fakta | klass | källa | spelet |
|---|---|---|---|
| Trappstegsblock i ljust trä | `VERIFIED` | r01 | `kortanda` |
| Två trappor upp | `VERIFIED` | r01 | byggs |
| Glasat band av rum ovanför, mörka karmar | `VERIFIED` | r01 | byggs |
| Bandet BRYTS av de två trapporna | `VERIFIED` | r01, beskuren | rättat — segment ur `trappor` |
| Glaset går i bås med poster, inte som en remsa | `VERIFIED` | r01 | `glasPost` |
| Båsens exakta delning | `[REFERENCE GAP]` | — | 1,9 m vald |
| Rund vit klocka på den vita väggen | `VERIFIED` | r01 | byggs |
| Vit stående brädvägg mellan bänkar och glas | `VERIFIED` | r01 | rättad — `glasOver` 0,35 → 1,6 |
| Kompassros, LINJERITAD, vänster om vänstra trappan | `VERIFIED` | r01, beskuren | byggd — `kortanda.stjarna` |
| Bokstaven C har en CYKELbild, E en elefant | `VERIFIED` | r01 + r03 | ritas inte, se nedan |
| Alla meter | `[REFERENCE GAP]` | — | topologi rätt, mått valda |

## 4. Övre långväggen — `RESOLVED` på båda ytorna

| fakta | klass | källa | spelet |
|---|---|---|---|
| Rostbrun/mörkröd panel på DEL av EN långsida | `VERIFIED` | r02 | `ovreVagg.sida:"W"`, y 6–40 |
| Vita horisontella band på panelen | `VERIFIED` | r02 | `panelList` |
| **Fönsterband ovanför panelen** | `VERIFIED` | r02 | rättat — `fonsterband` |
| Bandet löper förbi panelens stycke | `VERIFIED` | r02 | byggs i full längd |
| Bandets höjd och postdelning | `[REFERENCE GAP]` | — | valda |
| Resten av samma vägg är ljus | `VERIFIED` | r02 | byggs |
| Panelens exakta utbredning | `[antagande]` | — | y0/y1 |

## 5. Sponsorskyltar — `RESOLVED`

| fakta | klass | källa | spelet |
|---|---|---|---|
| Skyltar hänger på den rostbruna panelen | `VERIFIED` | r02 | kopplad via `andel`, båda ytorna |
| Agria, Hästsportbutik, RS Mustang, Svenskt Stallströ | `VERIFIED` | r02 | — |
| Skyltarnas läge relativt panelen | rättat | — | `andel` av panelens stycke, härlett |

## 6. Taket

| fakta | klass | källa | spelet |
|---|---|---|---|
| Mörka limträbalkar | `VERIFIED` | r01 + r02 | byggs |
| Korrugerad plåt som undertak | `VERIFIED` | r01 + r02 | byggs |
| Långa lysrörsarmaturer i rader | `VERIFIED` | r01 + r02 | byggs |
| Stora runda spiralkanaler (vent) | `VERIFIED` | r01 | byggs |
| Högtalare | `VERIFIED` | r01 | `[REFERENCE GAP]` |
| Kabelstegar | `VERIFIED` | r01, beskuren och zoomad | byggs |

## 7. Domarbåset vid E

| fakta | klass | källa | spelet |
|---|---|---|---|
| Mörkt trä, upphöjt, trappa med räcken | `VERIFIED` | r03 | byggs, båda ytorna |
| **Sadeltak med utskjutande takfot** | `VERIFIED` | r03, beskuren | rättat — `basTak` |
| Räcke på BÅDA sidor av trappan | `VERIFIED` | r03 | byggs |
| Roblox byggde bara en slät låda | rättat | — | nivå, tak, trappa, räcken |
| Takets resning | `[ASSUMPTION]` | — | 0,42 m |
| Grön exit-skylt | `VERIFIED` | r03 | byggs |
| Sitter på läktarnivå | `DERIVED` | r03 | följer `dackZ` |

## Prövat men INTE ändrat

**Sockelbandets höjd.** Spelet har 0,26 m av 1,35 (19 %). Ett ögonmått på en
nedskalad beskärning av r03 gav snarare ~28 %. Jag ändrade INTE värdet: mitt
mått är taget på en skalad bild utan tydliga kanter, och det är inte
precisare än det tal som redan står där. Att flytta ett rimligt värde på ett
osäkert ögonmått är samma fel som att mäta tröskeln i stället för ytan — det
har kostat två varv i det här arbetet redan. Behövs det, mät på en
beskärning i full upplösning med känd referenslängd i bild.

## Rättat i det här passet

- **A** läktaren: plant däck med solid front i stället för fyra trappsteg.
- **B** fönsterbandet ovanför panelen byggs nu.
- **C** skyltarnas läge HÄRLEDS ur panelens stycke i stället för att stå som
  tal. Ett första test på detta var för svagt — det passerade för vilka tal
  som helst som råkade ligga innanför stycket, vilket jag prövade genom att
  frikoppla dem. Testet mäter nu själva kopplingen.

## Brandplanens orientering — öppen fråga, INTE åtgärdad

Punkt 1 i arbetsordern (banans öppningar och grindar) förde mig till
`ridhus-entreplan-utrymning.jpg`. Den läser så här, zoomad:

- entré-/rumsdelen med trappor och "du är här" ligger i planens **övre** ände,
- längs planens **vänstra** långsida går ett smalt band med fem parallella
  linjer — läktaren sedd i plan, samma band `RIDHUS-PLANMATNING` mätte till
  0–14,5 % av bredden,
- **mitt på den bandade långsidan finns en grön utrymningsväg** med pil ut,
- den högra långväggen har regelbundna små hack (pilastrar eller nischer).

**Frågan:** om planens övre ände är husets norra, så är det bandade
långsidan VÄSTRA — men spelet har läktaren i ÖSTER (`x0:21` av 25), och
sponsorväggen i väster. Fotona stödjer spelets inbördes ordning: `-02` är
tagen FRÅN läktaren och visar sponsorväggen mitt emot.

**Vad som talar för att spelet ändå står rätt:** hästgången förbinder
ridhuset med stallet, och stallet ligger ÖSTER om ridhuset
(`STALL_X = RIDHUS_X + RIDHUS_BREDD + GARDSGAP`). Gången måste alltså gå in
på ridhusets östra sida, och spelet lägger läktargapet just där för att
hästen ska kunna ledas igenom. Planens utrymningsväg mitt på den bandade
sidan ligger på ungefär samma relativa läge som det gapet. Det talar för att
planens vänstra sida motsvarar spelets östra — alltså att planen inte är
orienterad som jag först antog.

**Det är en slutledning, inte ett bevis.** Planen har ingen norrpil, och
orienteringen går inte att avgöra ur bilden. Jag har därför **inte** ändrat
någon geometri. Att spegla en 50 m lång läktare på ett antagande om
planens orientering vore precis den sortens uppfunna kompromiss som
CLAUDE.md förbjuder.

**Situationsplanens insetruta avgör en del av det.** `SITUATIONSPLAN / SITE
PLAN` uppe i planens hörn visar ridhuset som den ORANGE, enkla rektangeln
till vänster och stallet som den GRÅ, trappstegsformade till höger, med
Björklidsvägen upptill. **Stallet ligger alltså öster om ridhuset, precis
som spelet har det.** Det bekräftar tomtens layout oberoende — men inte
vilken långsida läktaren ligger på.

**Vad som fortfarande skulle avgöra det:** en norrpil på huvudplanen, eller
en bild som visar läktaren och hästgångens dörr i samma ruta. Ingen sådan
bild finns i repot.

**Speglingen är nu en DATAÄNDRING.** `RIDHUSINNE.sidor` styr läktarens sida,
panelens sida, banans läge och båsets läge. Byt `{laktare:"E", panel:"W"}`
mot `{laktare:"W", panel:"E"}` så följer allt med, på båda ytorna, med alla
sex specar gröna. Provat i båda riktningarna.

**Speglingsprovet hittade två riktiga fel** som ingen annan kontroll såg:
banan ligger inte centrerad utan tätt mot väggen UTAN läktare, så en
spegling utan att flytta banan la läktaren 170 m² inne på banan; och min
första härledning av båsets x vände tecknet och la båset två meter utanför
däcket. Båda rättade.

**Luckan är stängd.** `speglar` följer `spegelSida` och cafeklockan följer
läktarsidan; inga literaler kvar. En spegling flyttar även väggdekoren.

## Öppna motsägelser

1. **Sarg kontra läktarfront.** r01 och r02 visar den mörka brädväggen SOM
   bangräns på däckets sida, utan vit sarg framför. r03 visar en vit sarg
   med sittplatser bakom, vid bokstaven E — på samma långsida. De går inte
   att förena ur bilderna. Spelet bygger tills vidare båda.
2. ~~Kabelstegarna syns inte i något foto.~~ **PRÖVAT OCH FALSKT.** Både
   en tidigare review och mitt eget första utkast av den här matrisen skrev
   att kabelstegarna inte syns. Jag beskar och zoomade takzonen i r01 innan
   jag tog bort dem: den perforerade rännan med regelbundna stegpinnar under
   stålbalken, med en kopplingsdosa mitt på, ÄR en kabelstege. Detaljen är
   riktig och står kvar. Hade jag följt reviewn utan att titta hade jag
   tagit bort ett korrekt drag.
3. `IMG_0191.MOV` är `[DRIVE-ONLY]` och kan inte prövas härifrån.
4. Roblox Studio är **inte** körd.

---

# Bevispaket: källa → implementation, per huvudvy

Reviewn kräver en jämförelse från närmast praktiska referenskamera för var
och en av de tre huvudvyerna, med varje synligt drag klassat. Bilderna ligger
i `audits/bilder/ridhus-jf-01..03.png`.

## Vy 1 — `-01` glasrummen, från läktaren mot C-kortändan

`audits/bilder/ridhus-jf-01.png`

| synligt drag | klass |
|---|---|
| Läktardäck i förgrunden, mot kortändan | `RESOLVED` |
| C-kortändan med band ovanför | `RESOLVED` |
| Trappa vid kortändan | `RESOLVED` |
| Rostbrun panel med vita band på motstående långvägg | `RESOLVED` |
| Bokstaven C på sargen framför blocket | `RESOLVED` |
| Limträstomme och lysrörsrader i taket | `RESOLVED` |
| **Trappstegsblocket vid kortändan syns inte i vyn** | `KNOWN MISMATCH` |
| **Runda vita klockan på kortändans vägg** | `KNOWN MISMATCH` |
| **Glasbandet läser som en mörk remsa, inte som fönster med bruna karmar in i upplysta rum** | `KNOWN MISMATCH` |
| Vit stående brädvägg med stjärndekor | `[REFERENCE GAP]` — dekoren ritas inte |
| Ventilationens spiralkanaler | `ASSUMPTION` — byggs, men syns inte i just den här vyn |

## Vy 2 — `-02` långsidan, från läktaren mot sponsorväggen

`audits/bilder/ridhus-jf-02.png`

| synligt drag | klass |
|---|---|
| Rostbrun panel på DEL av EN långsida | `RESOLVED` |
| Vita horisontella band på panelen | `RESOLVED` |
| Sponsorskyltar på panelen, i fotots ordning | `RESOLVED` |
| Fönsterband ovanför panelen | `RESOLVED` |
| Vit sarg med mörkt sockelband | `RESOLVED` |
| Resten av väggen ljus | `RESOLVED` |
| **Fönsterbandet läser som en slät ljus remsa — posterna syns knappt** | `KNOWN MISMATCH` |
| Speglarna i träram | `ASSUMPTION` — läge inte kopplat till panelen |
| Sanden och hindren | `ASSUMPTION` |

## Vy 3 — `-03` båset vid E, från banan mot båset

`audits/bilder/ridhus-jf-03.png`

| synligt drag | klass |
|---|---|
| Båset i mörkt trä, upphöjt | `RESOLVED` |
| Sadeltak med utskjutande takfot | `RESOLVED` |
| Trappa med räcke på båda sidor | `RESOLVED` |
| Grön exit-skylt | `RESOLVED` |
| Vit sarg med mörkt sockelband | `RESOLVED` |
| Bokstaven E på sargen | `RESOLVED` |
| **Elefantbilden bredvid E** | `[REFERENCE GAP]` — ritas inte |
| **Sittande publik på läktaren bakom båset** | `[REFERENCE GAP]` — inga NPC:er där |
| Läktarens trappstegskaraktär bakom båset | se den öppna motsägelsen sarg/läktarfront |

## Sammanräkning

`RESOLVED` 19 · `KNOWN MISMATCH` 4 · `[REFERENCE GAP]` 4 · `ASSUMPTION` 3

De fyra kvarstående `KNOWN MISMATCH` är alla i samma familj: **band som
läser som släta remsor i stället för som fönster och trappsteg**. Det hör
till punkt 6 och 7 i arbetsordern och är nästa steg — inte till geometrin,
som nu stämmer.

---

# Pass mot de fyra synliga mismatcharna

## Punkt 3 och 4 · ORSAKEN VAR MIN EGEN REGRESSION — RESOLVED

Jag rapporterade först att blockets "geometri hamnar någon annanstans än
datan anger". **Det var fel, och slutsatsen byggde på ett trasigt prov.**

Magentaprovet som gav "810 pixlar uppe i vänstra hörnet" mätte inte min
geometri — det mätte **den lila UPPGIFT-rutan i HUD:en**, vars ljusare
partier råkar passera filtret r>150, b>150, g<110. Ett omtag med grönt
mätte i stället **spelarens keps**. Två falska positiva i rad, och båda gav
samma svar oavsett kameravinkel, vilket borde ha avslöjat dem direkt: en
yta i världen kan inte ge exakt lika många pixlar åt två håll.

Den riktiga orsaken hittades genom att logga ALLA konsolrader:

```
warning: 3D-vandring misslyckades: ReferenceError: L is not defined
    at v3dRidhus (...)
```

`L` deklareras inne i läktarens sektionsloop. När jag byggde om läktaren
till ett däck lät jag domarbåsets block läsa `L.dackZ` — men det ligger
UTANFÖR loopen. Undantaget FÅNGAS av spelet och loggas som en varning, så
allt efter båsblocket i `v3dRidhus` byggdes aldrig: kortändans block,
glasbandet, kortändans klocka.

Mätbart: `ridhusinne` byggde **6 statiska objekt med felet, 33 utan**.

Regressionen kom med mitt eget läktarpass och stod kvar genom flera
commits. Alla skärmdumpar jag tog av ridhuset däremellan visade en scen där
en femtedel av geometrin fanns.

**Åtgärdat.** `golv` läser `R.laktare.dackZ` direkt. Kortändans block med
sockel, de två trapporna, det segmenterade glasbandet med karmar och djup,
och kortändans klocka syns nu alla från referenskameran. `RESOLVED`.

**Verktyget som saknades:** `tools/webbkoll.mjs`. Mina QA-skript lyssnade
bara på `pageerror` och console-rader av typen "error"; ett fångat undantag
loggas som VARNING och passerade som grönt. Den nya kollen räknar alla
nivåer, kräver att varje scen bygger objekt alls, och är falsifierad genom
att felet återinförts.

## Punkt 3 · den ursprungliga ocklusionsdiagnosen står kvar



Reviewn bad om diagnos före åtgärd. Den gav två fynd, det andra viktigare
än det första.

**Fynd 1 — ocklusion, mätbar i datan.** Blocket var 4 steg à 0,30 = 1,20 m
och sargen är 1,35. Hela blocket stod under sargkrönet. Dessutom stiger
raderna BORT från banan, så även efter en höjning till 5 × 0,32 = 1,60 kom
bara den översta raden över sargen — 0,25 m på fjorton meters håll.
`-01` visar flera rader över sargkrönet, så blocket står nu på en **sockel**
på 0,80 m: totalt 2,40 m, tre rader över sargen. `DERIVED` ur fotot.

**Fynd 2 var däremot fel** och är rättat ovan: blocket syntes inte därför
att det aldrig byggdes, inte därför att det låg fel.

**Sidofynd, oavgjort:** kortändan vid hall-y ≈ 2 renderar bokstaven **A** på
sargen, medan `DRESSYRBOKSTAVER` lägger A på ban-lokal (10, 60) och C på
(10, 0) — alltså C i den låga änden. Bokstäverna och blocket pekar åt olika
håll. Det kan vara samma fel som ovan eller ett eget. `KNOWN MISMATCH`.

## Punkt 4 · klockan — byggd, men syns inte än

Klockan i datan (`RIDHUSINNE.klocka`, y 63,6) är **cafeklockan i norra
änden**, inte den `-01` visar. Kortändans klocka fanns alltså inte alls.
Den är nu tillagd som `kortanda.klocka` med x härlett ur mittpunkten mellan
de två trapporna, alltså geometriskt fäst i kortändans struktur som reviewn
kräver. Den syns inte i vyn av samma skäl som blocket. `KNOWN MISMATCH`
tills renderingsfelet är spårat.

## Punkt 1 och 2 · glasbanden — djup tillagt

Båda banden fick det som skiljer ett fönster från en remsa, allt synligt i
`-01`/`-02`: en **mörk reveal bakom glaset** som ger rummet djup, **karmar
och poster som står proud** av glaslivet, och för kortändan **omväxlande
upplysta och mörka rutor**. Långsidans band går att bedöma i vyn
(`m-panel`); kortändans delar blockets renderingsfel.

## Orienteringsdatan är städad

Speglarna hänger nu på panelväggen via `spegelSida`, och cafeklockan och
trätrappan följer läktarsidan. Inget av dem är kvar som literaler. En
spegling är därmed en dataändring även för väggdekoren.

## Kompassrosen, den vita väggen och pictogrammen

`ridhus-inne-01` beskuren över kortändan visar tre saker som spelet saknade:

1. **En hög vit vägg** mellan översta bänkraden och fönstrens underkant,
   ungefär mansehöjd. Spelet hade `glasOver:0.35` — glaset satt nästan
   direkt på bänkarna, och det fanns därför ingenstans att sätta vare sig
   klocka eller dekor. Det var det som gjorde att stjärnan hamnade inne i
   glaset vid första försöket. Nu 1,6 m, `DERIVED` ur bildens proportioner.

2. **Kompassrosen** — en TUNN, linjeritad åttauddig stjärna, inte en fylld
   form. Byggd som fyra korsade smala stavar, vilket läser som en ritad
   stjärna på det avståndet. Läget härleds ur `trappor` så att den följer
   trapporna. `[ASSUMPTION]`: storleken.

3. **Pictogrammen vid bokstäverna**: C har en CYKEL, E har en elefant. Båda
   `VERIFIED`. De ritas INTE — vid den skala bokstäverna har på sargen blir
   en cykel eller elefant några pixlar, och en fläck som ska föreställa en
   elefant är sämre än ingen fläck. Står som verifierat men inte byggt, inte
   som `REFERENCE GAP`: källan är tydlig, det är renderingsskalan som är
   gränsen.

---

# Punkt 7 · ljus- och materialkaraktär, första passet

Ytorna mätta i fotona med beskär-titta-mät, och renderingen mätt mot dem.
Fyra av sju första prov träffade fel yta och förkastades — värdena nedan är
bara de visuellt kontrollerade.

| yta | foto | render före | render efter | utfall |
|---|---|---|---|---|
| bansand | `#6F5D4D` (`-03`) | `#976930` | `#746049` | `RESOLVED` |
| rostbrun panel | `#765B59` (`-02`, färgmask) | `#83512C`* | `#745348` | `RESOLVED` |
| sargens vita bräda | `#E3E0D1` (`-03`) | — | — | spelet har `#E9E5DC`, inom mätfelet |
| läktarfronten | `#4C3B2D` (`-01`) | — | — | spelet har `#4E3626`, inom mätfelet |
| läktardäckets plank | `#A69279` (`-01`) | — | — | spelet har `#C9BCA4`, ljusare |

\* kontaminerat av sanden i samma mask; panelens egna region gav `#745348`.

## Två fynd

**1. Panelen var för mättad.** Stod som `#5E2C33`, ett mättat rödlila, ur ett
gammalt textderivat som kallade den "mörkröd/maroon". Färgmask på `-02`, med
masken visuellt kontrollerad som grön overlay över just den väggen och
utanför sponsorskyltarna, ger `#765B59` — en betydligt dovare gråbrun-mauve.
**Bilden är facit, och den är dovare än ordet.**

**2. Sanden lästes aldrig ur datan.** Banans underlag ritades med ett
LITERALT `"#9C8663"` i renderaren och läste inte `RIDHUSINNE.sandFarg` alls.
Samma dolda literal som gårdsplanen, silon och sponsorskyltarna fällts på:
ändrar man datan händer ingenting. Den läser nu datan.

## Om den kanalvisa kompensationen

Sanden kompenseras KANALVIS, och det är avsiktligt trots att jag två gånger
förkastat kanalvis kompensation i det här arbetet. Skillnaden:

- det som sprängde boxfronternas reglar och ridhusväggen var kanalvis
  invertering av LJUSET på ytor med varierande infallsvinkel — highlights
  klipper och tonen spårar ur,
- sanden är en plan, jämnt belyst golvyta där en varm TEXTUR är den
  avvikande faktorn. Samma fall som stallets marksten, där kanalvis
  kompensation konvergerade på några enheter.

Kvoterna är mätta på skärmdump, inte gissade, och resultatet är verifierat:
`#746049` mot målet `#6F5D4D`.

## Kvar i punkt 7

- Läktardäckets plank renderas ljusare än fotot; inte åtgärdat.
- Kortändans bänkar är inte mätta — mina prov träffade sarg och sand.
- Takets ljussättning är inte mätt alls.

---

# Roblox-pariteten efter Review 09

Reviewn hittade att Roblox fortfarande byggde ridhusets GAMLA identitet
medan webben var rättad, och att sex gröna specar samexisterade med
spelarsynliga paritetsfel. Båda delarna stämde.

| fynd | före | efter |
|---|---|---|
| Rostbrun panel | **båda långsidorna, nästan full längd** | en sida, bara sitt stycke, ur `ovreVagg.sida/y0/y1` |
| Panelens färg | `IDFARG.panel`, gammalt mättat rödlila | delade, mätta `R.panel` `#765B59` |
| Sponsorskyltar | **byggdes inte alls** | ur delad `skyltar`, rätt antal och ordning |
| Kortändans vita vägg | gapet visade skalets material | egen vit vägg mellan bänkar och glas |
| Kortändans klocka | fanns inte | byggd, testad som RELATION mellan trapporna |
| Kompassrosen | fanns inte | fyra korsade stavar, vänster om vänstra trappan |

## Varför testerna inte fångade det

De två testerna för långväggen löd **"byggdes på BÅDA sidor"** och krävde
`2 × listar` läkt. De kodade alltså in det fel fotot motsäger, och HÖLL DET
PÅ PLATS: Roblox kunde bygga panelen på båda sidor i full längd med hela
sviten grön.

Ett test som skriver av bygget i stället för källan skyddar felet i stället
för att hitta det. Det är samma sjuka som fällt sju tal i den här sviten
tidigare, och det här var dess dyraste form.

De mäter nu relationer mot delad data: en sida, bara sitt stycke, rätt sida
enligt `sidor.panel`, skyltarna innanför stycket, klockan mellan trapporna,
rosen vänster om trapporna. Alla falsifierade genom att återinföra felet.

---

# Punkt 7, andra passet: hallens egna ytor

Alla fyra var LITERALER i renderaren och lästes aldrig ur datan — samma
mönster som sanden, silon, gårdsplanen och sponsorskyltarna.

| yta | spelet hade | mätt i `-01` | render efter |
|---|---|---|---|
| hallens väggar | `"#FFFFFF"` | `#ACA99D` (sd 27) | `#B5AA8A` |
| takstolarna | `"#7A5C3E"` varm mellanbrun | `#5C4C45` | — |
| undertakets plåt | `"#3A3E44"` mörk blågrå | `#5E5B5E` (517 kpx) | `#634B45` (takzon) |
| kortändans bänkar | `"#D8C7A4"` ljus furu | `#86715B` | `#775C3F` |

## Ridhusets tak är INTE stallets

En värmemask över hela takzonen i `-01` fann **35 kpx varma mot 517 kpx
neutrala**. Ridhusets takstolar läser mörkt gråbruna, nästan neutrala — till
skillnad från stallets limträ, som är tydligt varmt. Spelet hade en varm
mellanbrun balk och en mörk blågrå plåt; båda drog åt fel håll, åt var sitt.

Att jag mätte stallets tak först och fann varmt limträ gjorde det lätt att
anta samma sak här. Masken sa något annat.

## Kvarstående, redovisat som karaktär och inte som fel

De tre ytorna renderas fortfarande **varmare än fotot**, med blått nedtryckt
15–25 enheter i alla tre. Det är samma signatur på hela scenen, inte tre
separata fel, och det hör till webbrenderarens inomhusljus tillsammans med
trätexturen.

Jag jagar det INTE per yta med kanalvisa hack. Det står som en
`RENDERING LIMITATION` av samma slag som stallets vägg: ytorna ligger på sina
mätta värden och avviker hellre åt ett känt håll än att förfalskas var för
sig.
