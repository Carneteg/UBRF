# Byggnadskort: Ridhuset

Ifyllt av `/fotoanalys ridhus` ur fotona i denna mapp. Allt som inte syns i foto är
märkt `[saknas foto]`, gissningar `[antagande]`.
Kortet är facit för byggfunktionen i `src/varld3d.js`.

> **Underlaget är tre bildrutor** ur `references/video/IMG_0246.mov`, alla från
> parkeringen. Första uttaget tog bara sex bildrutor per film; vid tre bilder i
> sekunden och gallring av nästan identiska rutor gav samma klipp åtta distinkta
> vinklar, varav tre visar hallen. Bild 03 visar nocken och båda takfallen, vilket
> första omgången saknade helt.
>
> Kvar saknas: långsidan, baksidan, och något som visar takytan. Måtten nedan är
> uppskattningar med angiven metod — inte mätningar.

## Foton
| Fil | Fasad/vinkel | Visar |
|---|---|---|
| `ridhus-gavel-01.jpg` | Snett från SV, ögonhöjd, från parkeringen | Gavelns övre del, det svarta bandet, entrén med skärmtak, runt ventilationsgaller, fläktlåda |
| `ridhus-gavel-02.jpg` | Samma hörn, något bredare | Två entréer, Café Krubban-skylt, staketet framför |
| `ridhus-gavel-03.jpg` | Längst till vänster i panoreringen, hela hallen | **Nocken och båda takfallen.** Caféannexet i två våningar till höger, med balkong, utvändig trappa och valvbågade fönster |

## Volym
- Fotavtryck (L × B): **26 × 66 m**. Var ett antagande ur "en 20×60-bana ryms";
  utrymningsplanen (se nedan) ger proportionen 2,7:1, alltså ~70 m vid 26 m bredd.
  Kortets 66 m ligger inom felmarginalen för en snett fotograferad ritning.
- Höjd till takfot: **6,2 m** `[antagande]`. Den svarta listen är **inte** takfoten
  — det syns i bild 03, där taklinjen fortsätter långt ovanför listen. Listen är
  övre bjälklaget, se nedan. Takfotens höjd går inte att mäta ur något foto
  eftersom ingen bild visar var taket möter långsidan; 6,2 m är valt för att en
  20×60-bana ska ha fri höjd och för att stämma med nocken.
- Höjd till svarta listen: **4,1 m**. Tre avläsningar ur bild 03 ger 3,5 / 3,8 /
  4,5 m beroende på om skalan tas ur dörrhöjden, ur höjdförhållandet list–takfot
  eller ur nocken. 4,1 är medianen. Kortets första siffra 4,2 m låg inom spannet.
- Höjd till nock: **9,2 m** (hur: nocken mäter 683 px över marklinjen i bild 03,
  dörren 175 px för 2,0 m, alltså 87,5 px/m → 7,8 m. Byggd höjd är 9,2 m, vilket
  är takfoten 6,2 plus 13° resning över halva bredden — mätningen och
  konstruktionen skiljer 1,4 m och mätningen är den osäkrare av de två.)
- Byggnadsform: rektangulär hall med ett **caféannex i två våningar** på högra
  gaveln. Annexet har egen, lägre taklinje, balkong på övervåningen och nås av en
  utvändig ståltrappa. Det är Café Krubban.

## Tak
- Form: sadeltak
- Nockriktning: längs långsidan; gaveln vetter mot parkeringen (troligen mot väster)
- Lutning: **13,0°** som byggd, ur intervallet nedan (26 m bredd, 3,0 m resning).
- Uppmätt lutning: **~14°**, rimligt intervall 11–17° (hur: i bild 03 syns nocken vid
  bildpunkt x≈440 och båda takfallen. Vänstra fallet mäter 11,6°, det högra 16,3°.
  Skillnaden är perspektiv — gaveln är vriden, så det bortre fallet trycks ihop
  och det närmare tänjs ut. Sanningen ligger mellan, och medelvärdet är det bästa
  estimatet tills en rak gavelbild finns.)
- Täckning: `[saknas foto]` — takytan syns inte. Svart plåt `[antagande]`, utifrån
  att alla synliga takbeslag och vindskivor är svarta.
- Takutsprång: litet, uppskattningsvis 20–30 cm; vindskiva och takfot i **svart**
- Takfönster / ljusinsläpp: syns inte på gaveln. En ridhushall har normalt
  ljusband i taket `[antagande]`

## Fasader
| Sida | Material | Färg RGB / namn | Fönster | Dörrar/portar | Övrigt |
|---|---|---|---|---|---|
| Gavel mot parkeringen (V) | **vertikalt korrugerad stålplåt**, ribba ~12 cm | **(97, 45, 57)** "mörkt vinröd plåt" | 1 runt ventilationsgaller ~Ø 0,5 m; 1 rektangulärt jalusigaller ~0,6 × 0,9 m | 1 svart ytterdörr under vitt skärmtak med sadelform | Svart list horisontellt vid ~4,2 m över hela bredden; svart fläktlåda med rund kanal högt upp; skylt "Café Krubban" |
| Caféannexet (höger gavel) | samma plåt, två våningar | samma | **4 valvbågade vitmålade fönster**, två per våning, flerrutiga | 1 svart dörr på övervåningen, ut mot balkongen | Utvändig ståltrappa med räcken upp till balkongen; balkongräcke i stål; blå skylt vid trappan |
| Långsida N | `[saknas foto]` | | | | |
| Långsida S | `[saknas foto]` | | | | |
| Gavel Ö | `[saknas foto]` | | | | |

> **Rättad färg.** Kortets första avläsning (138, 34, 40) togs i en ljus fläck och
> blev för ljus och för varm. Medelvärdet över en väggyta i vart och ett av de tre
> fotona ger (100,51,67), (102,51,67) och (93,41,49) — alltså **(97, 45, 57)**, en
> mörk vinröd med blåton (B > G). Det är den färgen ögat känner igen. I koden står
> råvaran (135, 47, 64); belysningen tar ner den till fotots värde.

Detaljfärger:
- Beslag, vindskivor, takfot, list: **(32, 32, 34)** "svart"
- Dörr- och fönsterfoder, skärmtak: **(238, 238, 232)** "vit"
- Entrédörr: **(24, 24, 26)** "svart"
- Staket framför: **(122, 46, 40)** "rödbrun", två liggande reglar

## Kännetecken (det som gör att man känner igen den)
1. **Vinröd korrugerad plåt med svarta beslag** — inte falurött trä. Den svarta
   horisontella listen vid ~4,2 m delar fasaden i två våder och är det första ögat
   fastnar på.
2. **Den vita skärmtakskuren över den svarta dörren** — en liten spetsig gaveltriangel
   mitt på en annars slät plåtvägg.
3. **Den utvändiga metalltrappan** längs högra delen, upp mot Café Krubban.
4. Det **runda ventilationsgallret** högt på gaveln, ensamt på en tom fasadyta.

## Omgivning som hör till byggnaden
- Grusparkering direkt framför, plats för minst 6 bilar
- Rödbrunt tvåregelsstaket mellan parkeringen och byggnaden
- Ljusa block (hinderstöd eller betongsuggor) uppradade bakom staketet
- Ett ungt lövträd med stödkäpp framför fasaden
- Skylt "Café Krubban" vid trappan

## Invändigt — utrymningsplanen

En fotograferad **utrymningsplan (Presto AB, 2025-10-11)**, rubricerad
"Upplands-Bro kommun Ridhus, Husbyvägen 1, Bro, Entréplan", visar ridhusets
bottenvåning.

**Det den bekräftar:**

- **Fotavtryckets proportion är 2,7:1.** Byggnaden mäter 1790 × 665 bildpunkter i
  planen. Med bredden 26 m ger det längden **~70 m** — kortets 66 m var en ren
  gissning ur "en 20×60-bana ryms", och den håller. Det här är den enda oberoende
  kontrollen av längdmåttet som finns.
- **Läktaren ligger längs ena långsidan** och löper större delen av längden, med
  ett smalt band mellan läktaren och banan. Det stämmer med `RIDHUSINNE`.
- **Entré- och trapphusdelen ligger i ena gaveln** — samma gavel som caféet och
  yttertrappan utvändigt.
- Utrymningsvägar längs långsidan och i båda ändar.

**Det den ändrar:**

Gaveldelen är **djup — omkring en sjättedel av byggnadens längd** — och innehåller
**två trapphus, en hiss** och ett antal rum. I spelet är den bara en 3 m djup
caféöverbyggnad, och går man in från parkeringen kommer man rakt ut i ridhuset. I
verkligheten kommer man in i en entréhall.

Det betyder också att banan är **kortare än byggnaden** med god marginal. Om
gaveldelen tar tolv meter ryms ingen 20×60-bana i en 66 m lång byggnad, och
antingen är huset längre än 66 m eller banan kortare än 60 m.

**Vad jag inte kan läsa:** bilden är tagen snett, och underkanten lutar synligt mot
överkanten. Längdmått blir därför fel — den bortre delen av planen är
ihoptryckt. Proportionen ovan är grov, och den exakta uppdelningen mellan bana och
gaveldel går inte att mäta.

`RIDHUSINNE` lämnas orörd tills det finns en rak bild. Banan är 20×60 där, vilket
är den bana ridmodellen och dressyrbokstäverna räknar med — att korta den är ingen
liten ändring och ska inte göras på ett snett foto.

## Placering (från SITEPLAN.md)
- Position: sydvästra hörnet i (118, 44), fotavtryck 26 × 66 m
- Rotation: nocken i nord–sydlig riktning, gaveln mot parkeringen i söder
- Marknivå: plant

## Fotobrist

**Delvis löst av Street View.** Bilder från Enköpingsvägen (sep 2024 och juli 2026)
visar ridhusets **sydvästra långsida** — den som i spelet är den västra. De sparas
inte i repot, men det de visar är byggt:

- en **lång entrékvist** närmast caféets gavel: pulpettak på vita stolpar, ramp med
  räcke, vita dubbeldörrar
- den **svarta dörren** intill UBRF-skylten, ungefär mitt på längden
- en rad **små fyrkantsfönster högt uppe** på den bortre delen
- taket är mörkt och flackt, och långsidan är i övrigt en obruten röd plåtvägg

`[öppen fråga]` Om den svarta listen går runt hela huset eller bara sitter på
gaveln går inte att avgöra ur Street View — upplösningen räcker inte. Modellen låter
den gå runt, eftersom den ligger i övre bjälklagets höjd och en bjälklagslinje inte
brukar sluta i ett hörn. En bild rakt på långsidan avgör saken.

Kvar att fotografera, i fallande ordning:

1. **Gaveln rakt framifrån**, hela byggnaden i bild. Lutningen är uppskattad till
   14° ur bild 03, men spannet 11–17° är för brett för att bygga efter utan att
   gissa fel på just det som avgör igenkänningen.
2. **Långsidan rakt från sidan** på nära håll — för listens höjd, fönstrens antal
   och längdmåttet.
3. **Ett foto på avstånd som visar hela taket**, för täckning, ljusband och nock.
4. Baksidan och den östra gaveln.
5. Närbild på entrén med dörren helt synlig ned till marken, för höjdskalan.

## Byggstatus
- Byggd version: `src/site.js` (mått, färger, öppningar) och `v3dRidhusYttre` i
  `src/varld3d.js` (gaveldetaljer, balkong, trappa). Verifierad mot bild 03 från
  samma vinkel, i tre omgångar.

Det som rättades mellan omgångarna, med felet först:
1. **Sadeltaket lutade åt fel håll** — takfallen var vridna med `rotZ(+s·vin)` i
   stället för `−s·vin`, så huset hade dalgång i stället för nock. Samma teckenfel
   fanns invändigt i ridhuset och i skärmtaken.
2. **Plåtens korrugering töjdes över hela väggen** — 1,6 m per ribba i stället för
   12 cm, och den låg ner på gaveln eftersom `GEO.lada` lägger u längs höjden på
   ±Z-sidorna. Väggarna byggs nu med `ladaM`, som mäter texturen i meter.
3. **Gavelspetsen lystes upp som om solen stod bakom väggen** — triangelns normal
   pekade in i huset, vilket gav ett synligt skarvband vid takfoten.
4. **Färgen var för ljus och för varm**, se rättelsen ovan.
5. Vitt foder ritades som en skiva bakom dörren, vilket gjorde dörr och foder till
   ett blekt block. Nu är det en ram runt öppningen.

- Medvetna avvikelser från verkligheten:
  - Långsidorna och östra gaveln har inget fotounderlag. De får husets färg, den
    svarta listen och takfoten, men portar och fönster där är `[antagande]`.
  - Takytan syns inte på något foto. Svart plåt, `[antagande]`.
  - Caféannexet är byggt som en balkong med pulpettak mot gaveln, inte som en
    egen huskropp. I bild 03 ser man en mörk takkant över balkongen och en lägre
    taklinje till höger; vilken av dem som är annexets tak går inte att avgöra.
