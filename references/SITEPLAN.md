# Situationsplan – UBRF, Husbyvägen 1A, Bro

Underlaget är satellitvy och Street View över Husbyvägen 1A (Google Maps), lästa
tillsammans med fotona i `buildings/`. **Bilderna sparas inte i repot** — de är
Googles, och det är måtten vi behöver, inte bilderna. Det som är läst ur dem står
här nedan med metoden angiven.

Koordinatsystem: spelets eget, i meter. Anläggningen ligger i `ANL` i `src/site.js`;
`x` ökar österut och `y` norrut, samma tal i kartvyn som i 3D-världen. Ingen omräkning
behövs — skriv meter här och meter i koden.

## Så ser tomten ut i verkligheten

Två långa byggnader **parallellt intill varandra**, sammanbyggda med en hästgång,
med en smal gräsgård emellan.
Stallet ligger på ridhusets nordöstra sida. Båda löper **nordväst–sydost**, ungefär
**40° vridet från norr**.

- **Grusplanen — parkeringen** ligger vid husens **nordvästra gavlar**, mot
  Björklidsvägen. Utrymningsplanerna pekar dit ("parkeringen mot Björklidsvägen"
  är återsamlingsplats), och det är därifrån gavelfotona i `buildings/ridhus/`
  och `buildings/stall/` är tagna. **Står man på grusplanen har man ridhuset
  till höger och stallet till vänster**, med hästgången som binder ihop dem
  synlig mellan gavlarna längre bort — det är ankomstvyn, och den spelet ska
  träffa. Husen läser som **ett** komplex, inte som två fristående lador.
- **Björklidsvägen** kommer in från nordväst, till grusplanen.
- **Enköpingsvägen** går längs ridhusets sydvästra långsida. Det är den sidan som
  bär UBRF-skylten och den långa entrékvisten — och kvisten sitter närmast
  **caféets gavel i nordväst** (Street View).
- **Husbyvägen** går i öster/sydost; därifrån går en grusväg in till gårdsplanen
  vid stallets sydöstra gavel. Den gaveln (Street View) har två entrédörrar
  under vita skärmtak och en rak ståltrappa till övervåningen; strax intill
  står fodersilon (satellit).
- **Hagarna** ligger direkt öster om stallet, med trästaket.
- **Utebanorna** ligger norr och nordost om hagarna: en stor sandbana och en
  mindre paddock.
- Aspviks koloniträdgårdsförening ligger sydost om anläggningen.

### Skala i satellitbilden

`[SUPERSEDED]` **Pixelskalargumentet gäller inte längre.** Det löd: ridhuset
är 330 bildpunkter långt, vid 75 m ger det 4,4 punkter per meter, och stallets
236 punkter blir då 54 m — "två oberoende vägar till samma tal".

De två vägarna var inte oberoende. Båda vilade på ridhusets 75 m, som var ett
antagande, och pixelskalan ärvde felet rakt av. Product Owner har sedan mätt
längdaxlarna direkt: **ridhuset 77,18 m** och **stallet 69,95 m**, båda
`MEASURED`. Stallet var alltså 16 m för kort, och argumentet ovan bekräftade
bara sitt eget antagande.

Det är därför inget skalargument kvar här. Mått kommer från direkta mätningar
med två ändpunkter, eller så är de `[REFERENCE GAP]`.

## Är husen sammanbyggda? — ja, med en hästgång

**Avgjort av Tobias 2026-08-30:** *"husen är sammanbyggda, jag har varit där"*
och *"det är hästgång mellan byggnaderna"*. Man leder hästen inomhus mellan
stallet och ridhuset i stället för att gå ut över gården.

**Utrymningsplanernas egen situationsplan visar motsatsen** — två separata
volymer med vit yta emellan, i båda planerna, med bara färgerna ombytta. Det är
en verklig CONTRADICTION mellan källorna, avgjord till Product Owners fördel
enligt konflikthierarkin i `CLAUDE.md` (Tobias uttryckliga beslut slår
verifierad referens). En låg förbindelse behöver inte vara ritad som egen volym
i en schematisk situationsplan om den inte är en egen brandcell.

Kvar som öppen fråga: **var** hästgången går. Läget i spelet är härlett, inte
hämtat ur en källa — se `references/plans/OAVGJORT.md` fråga 1.

## Placeringen i spelet

Tabellen är avstämd mot `ANL` i `src/site.js` 2026-08-29 och läses ur koden,
inte ur minnet — siffrorna nedan är de som faktiskt byggs.

| Byggnad/yta | Position (m, X/Y) | Rotation | Fotavtryck (m) | Kommentar |
|---|---|---|---|---|
| Ridhuset | 118 / 41,82 (sydvästra hörnet) | nock nord–syd, cafégaveln mot grusplanen i **norr** | 25 `[REFERENCE GAP]` × **77,18** `MEASURED` | Längden är Product Owner-satellitmätning; tidigare 75 m var ett antagande. Bredden är olöst. Norra gaveln vid **y = 119** — referenslinjen som allt annat mäts från, eftersom den är mest fotoverifierad (caféet, ståltrappan, parkeringen). Den inre banan 20 × 60 skalas INTE med skalet. Byggd efter `buildings/ridhus/KORT.md`. Takfot 6,2 m, nock 9,2 m, 13° resning. |
| Stallet | **151,10** / **55,05** (sydvästra hörnet) | nock nord–syd, klubbgaveln (spiraltrappan) mot grusplanen i **norr** | 21 `[REFERENCE GAP]` × **69,95** `MEASURED` | **Längden är mätt, bredden är det inte.** `MEASURED` med Google Maps-tolerans; huset är oregelbundet, så måttet definierar inte ett fullständigt rätblock. Spelet hade 54 m — 16 m, 30 %, för kort. Boxantalet följde med: planen visar ~12 boxar per rad, inte 9. **Bredden 29,28 m är ÅTERTAGEN**, så 21 m är åter ett arbetsvärde i intervallet 15–23 m. Takfot 4,4 m, nock 10,0 m, 28° resning hör ihop med bredden och är antaganden de också. **Norra gaveln vid y = 125, alltså 6 m NORR om ridhusets** — se raden om gavelförskjutningen nedan. Västra långsidan, den fotograferade, står kvar; ändras bredden växer huset österut. |
| **Gavelförskjutningen** | stallet 6 m norr om ridhuset | — | `[REFERENCE GAP]` storleken | Husen ligger **inte i liv**. Modellen påstod tidigare att de norra gavlarna sammanföll på y = 119 och kallade det verifierat — en starkare utsaga än underlaget bär. Riktningen är avgjord: `buildings/stall/stall-gavel-06-silon.jpg`, tagen söder om båda husen, visar ridhusets södra ände långt närmare kameran än stallets gavel. Med stallet förskjutet SÖDERUT hamnade de södra ändarna nästan i liv, vilket bilden motsäger. Storleken 6 m är ett arbetsvärde. |
| Gårdarna mellan husen | 143–151,10, y 55,05–76,85 och y 80,35–119 | — | 8,10 × 21,8 och 8,10 × 38,65 | **Två skilda gårdsytor**, en på var sida om hästgången. Bredden 8,10 m är det MÄTTA lokala gapet i södra tvärsnittet; de gamla 11 m är `[SUPERSEDED]`. `[ASSUMPTION]` att gapet är sig likt hela vägen norrut — det är inte visat. |
| Grusplanen / parkeringen | 106 / 121 | — | 48 × 34 | Vid norra gavlarna, mot Björklidsvägen. Hit kommer man. |
| Planen framför klubbgaveln | 144 / 119 | — | 36 × 16 | Mellan grusplanen och stallets entrégavel |
| Gårdsplanen i sydost | 148 / 40 | — | 44 × 24 | Vid stallets södra gavel; infart från Husbyvägen (144/10, 62 × 8) |
| Grusvägen längs ridhuset | 112 / 20 | — | 6 × 101 | Mot åkern i väster |
| Gången öster om stallet | 175 / 64 | — | 3 × 57 | Mot hagarna; smalnad när stallet blev 21 m brett |
| Hage Ö1 | 178 / 65 | — | 28 × 28 | Direkt öster om stallet; hämtgrinden vid 178/79 |
| Hage Ö2 | 178 / 97 | — | 28 × 20 | |
| Träningsytorna | se `TRANINGSYTOR` i `src/site.js` | — | `NO_STOR` **33,57** `MEASURED SIDE` × 40 `[REFERENCE GAP]`; `NO_LITEN` `[REFERENCE GAP]` | **Reality-first.** Källorna visar minst TVÅ inhägnade sandytor nordost om husen; spelet hade en. Ytorna listas med neutrala plats-ID, och 33,57 hör till `NO_STOR` eftersom det är en egenskap hos marken, inte hos spelobjektet. Spelets `UTEBANA` och `PADDOCK` är två rader som pekar in i listan. **Båda ytornas världslägen och `NO_STOR`:s långsida är arbetsvärden**, inte mätta — de enda villkoren är norr om husen, öster om stallet, innanför tomten och utan överlapp. Se `references/site/BANIDENTITET.md`. |
| Domarkuren | 183,75 / 159,8 | — | 4,5 × 3,5 | **Utanför** banans norra kortsida, mot trädridån. Låg tidigare 184/148 — det är helt innanför banans staket. `[ASSUMPTION]` vilken kortsida |
| Fodersilon | 166 / 60 | — | — | Vid stallets **södra** gavel, syns i satellitbilden |
| **Hästgången** | **143 / 76,85** | nock öst–väst | **8,10 × 3,5** | Binder ihop ridhusets östvägg (x = 143) med stallets västvägg (x = 151,10). Bredden är det MÄTTA lokala gapet; djupet 3,5 m är `[ASSUMPTION]`. `[REFERENCE GAP]` LÄGET längs husen: 39,83 m är ÅTERTAGET (kumulativt över tre mätpunkter). Gången ligger där stallets tvärkorridor mynnar — en härledning, inte ett mått. Takfot 3,2 m, nock 4,0 m. Scenövergång åt båda hållen genom läktargapet. |
| Låga längan i söder | 147 / 59 | nock öst–väst | 7 × 6 | `[ASSUMPTION]` Att *något* står mellan gavlarna i söder syns i Street View; läge, mått, tak och dörr är antagna. Smalnad från 10 m till 7 m 2026-08-30 så att den södra gårdsytan fortfarande når gårdsplanen |
| Röda stugan | 94 / 140 | nock öst–väst | 6,5 × 4,5 | Vid infarten från Björklidsvägen `[antagande]` |
| Spelarens startpunkt | 146 / 136, blickriktning söder | — | — | På grusplanen: ridhuset till höger, stallet till vänster |

Marknivå: plant över hela anläggningen.

> `[KNOWN MISMATCH]` **Det stämmer inte, och slänten borde inte ha tagits bort.**
>
> En slänt upp mot banorna fanns i den första versionen och togs bort med
> motiveringen att satellitbilden inte visade någon höjdskillnad. En
> ovanifrånbild är fel instrument för att mäta höjd, och slutsatsen var
> därför inte bärig.
>
> `references/omnejd/banan-01`, `-02` och `-03` visar alla tre samma sak från
> marknivå: en **grässlänt** upp från grusvägen till banans nivå. Banans
> sandyta ligger tydligt ovanför omgivande mark.
>
> Spelet bygger fortfarande tomten platt. Det är en medveten men **oavgjord**
> avvikelse, inte ett beslut: höjden är inte mätt någonstans, och ingen av
> bilderna har en skala som når. En höjdmodell är dessutom ett ingrepp i både
> `src/world.js` (gång och kollision) och `src/varld3d.js` (mark ritas som
> plana lager på 0,008 m isär) och i Roblox-byggaren, alltså långt utanför en
> rekvisitaändring.
>
> Vad som behövs för att stänga den: **ett mätt höjdmått** mellan grusvägen
> och banans yta, och Tobias beslut om terräng är värt ingreppet.

Väderstreck i spelet: solens riktning ligger i `LJUS.dag.sol` i `src/ljus.js`.

## Medvetna avvikelser

1. **Rotationen.** Verkligheten är vriden ~40° från norr. `ANL` är byggd av
   axelriktade rektanglar, så spelets rutnät är i stället lagt **längs byggnaderna**:
   spelets norr är verklighetens nordväst. Inbördes placering, avstånd och vilken
   sida som vetter åt vad stämmer; kompassriktningen gör det inte. Att vrida hela
   anläggningen skulle kräva att varje rektangel blev en polygon.
2. **Gavlarna rättade 2026-08-29.** Spelet lade tidigare grusplanen, entréerna
   och silon vid fel gavlar — hela ankomsten blev spegelvänd (ridhuset till
   vänster i stället för till höger). Nu ligger ankomsten vid spel-norr
   (verklighetens nordväst): satellitbilden, Street View-bilderna och
   utrymningsplanernas återsamlingsplats pekar alla på samma sak. Kvar som
   avvikelse: Björklidsvägen och Husbyvägen är förenklade till raka
   kantvägar. `[avvikelse]`
3. **Skogsstigen** i norr är påhittad. Det finns skog runt anläggningen, men
   sträckningen är inte läst ur någon bild. `[antagande]`
4. **Åkern i väster** är en förenkling av markerna och koloniområdet.

## Utrymningsplanerna

Det finns uppsatta utrymningsplaner (Presto AB, 2025-10-11) i båda husen, och de är
det bästa underlaget som finns för insidorna — bättre än varje foto. De är
fotograferade snett och sitter i reflekterande ramar, så måtten går inte att läsa ur
dem, men planformen gör det. Vad de säger står i respektive byggnadskort under
"Invändigt".

Kort: **stallet är ett dubbelstall** med fyra boxlängor och två gångar, och
**ridhuset har en djup entré- och trapphusdel i gaveln** med två trapphus och en
hiss.

Stallet är ombyggt efter sin plan 2026-08-30. **Bredden gick inte att läsa ur
ritningen och är inte fastställd.** Planen ger bandens ordning och inbördes
andelar — det är `VERIFIED` och skaloberoende — men den saknar skalstock, så
skalan måste komma någon annanstans ifrån, och de vägar som finns pekar åt olika
håll.

Spelet bygger **21 m som arbetsantagande**, i intervallet 15–23 m. Det är inte en
rättelse och inte en slutsats. Det undre gränsvärdet håller därför att sex band
inte ryms i 15 m utan att bli 2,5 m vardera; takgeometrin stöder svagt intervallets
övre del. Den tidigare beviskedjan genom huvarnas och fönstrens 3,5 m-rytm är
**struken** — den är en mätning i byggnadens längdriktning och kan inte bevisa
tvärgående band.

Se stallkortet och `references/plans/OAVGJORT.md` fråga 2. Ett enda uppmätt mått
på plats stänger frågan.

Ridhuset är ombyggt efter sin plan. Ritningen saknar skalstock, men Tobias har
bekräftat att banan är **20×60**, och två kända mått räcker för att räkna bort
perspektivet: byggnaden är **25 × 75 m**, inte 26 × 66 som gissades förut.
`STALLINNE` står kvar som känt fel tills det finns en rak bild på stallets plan.

## Referensstatus per yta

Vad varje del är byggd efter, så att Roblox-spåret vet vad som är mätt och
vad som är antaget. `[antagande]` = härlett men inte sett; `[REFERENCE GAP]`
= inget underlag alls, minimal lösning vald.

| Del | Underlag | Status |
|---|---|---|
| Husens inbördes läge och riktning | Satellitbild + Street View + utrymningsplanernas återsamlingsplats | Verifierat |
| Ridhusets gavel mot grusplanen | `buildings/ridhus/ridhus-gavel-01..03.jpg` (ur `video/IMG_0246.mov`) | Verifierat |
| Ridhusets långsida mot Enköpingsvägen | Street View sep 2024 + juli 2026 | Verifierat, ej mätt |
| Ridhusets östra gavel och norra långsida | — | `[REFERENCE GAP]` — husets färg och list, inga öppningar utöver de nödvändiga |
| Ridhuset invändigt, mått | Utrymningsplan (Presto 2025-10-11) + bekräftad 20×60-bana | Uträknat, se ridhuskortet |
| Ridhusets entréhall, rumsindelning | Utrymningsplanen, otydlig i mitten | `[antagande]` — väggar antydda, inte rum för rum |
| Stallets klubbgavel och västra långsida | `buildings/stall/stall-fasad-01..05.jpg`, `stall-entre-*.jpg` | Verifierat |
| Stallets södra gavel | Street View, på avstånd | `[antagande]` — dörrarnas och trappans mått uppskattade |
| Stallets östra långsida | Street View, på avstånd | `[antagande]` — spegling av västra sidan |
| Stallgången invändigt | `video/IMG_0249.mov` + `IMG_0250.mov`, 37 bildrutor | Verifierat, se stallkortet |
| Stallets planform (dubbelstall) | Utrymningsplanen | **Byggd 2026-08-30** — fyra boxlängor och två gångar. Bandens ordning och andelar är mätta i planen `[VERIFIED]`; totalbredden 21 m är ett arbetsantagande i intervallet 15–23 m, se stallkortet |
| Hagar, banor, paddock | Satellitbild | Verifierat läge, mått ej mätta |
| Skogsstigen i norr | — | `[REFERENCE GAP]` — sträckningen påhittad |
| Åkern i väster | Satellitbild, förenklad | `[antagande]` |

## Kvar att kontrollera på plats

- Stallets längd. 54 m är räknat baklänges ur boxantalet och stämmer grovt med
  satellitbilden, men är inte mätt.
- Avståndet mellan husen. 10 m i spelet, ser ut som 10–14 m i satellitbilden.
- Var exakt hagarnas grindar sitter.
