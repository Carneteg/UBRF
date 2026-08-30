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
| Vit stående brädvägg med stjärndekor | `VERIFIED` | r01 | `[REFERENCE GAP]` — dekoren ritas inte |
| Alla meter | `[REFERENCE GAP]` | — | topologi rätt, mått valda |

## 4. Övre långväggen — `KNOWN MISMATCH B`, delvis

| fakta | klass | källa | spelet |
|---|---|---|---|
| Rostbrun/mörkröd panel på DEL av EN långsida | `VERIFIED` | r02 | `ovreVagg.sida:"W"`, y 6–40 |
| Vita horisontella band på panelen | `VERIFIED` | r02 | `panelList` |
| **Fönsterband ovanför panelen** | `VERIFIED` | r02 | rättat — `fonsterband` |
| Bandet löper förbi panelens stycke | `VERIFIED` | r02 | byggs i full längd |
| Bandets höjd och postdelning | `[REFERENCE GAP]` | — | valda |
| Resten av samma vägg är ljus | `VERIFIED` | r02 | byggs |
| Panelens exakta utbredning | `[antagande]` | — | y0/y1 |

## 5. Sponsorskyltar — `KNOWN MISMATCH C`

| fakta | klass | källa | spelet |
|---|---|---|---|
| Skyltar hänger på den rostbruna panelen | `VERIFIED` | r02 | **kopplingen saknas** |
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

**Känd lucka:** `speglar` ritas mot banans västra kant i renderaren och
`klocka.x` är ett literalt tal — de följer INTE med en spegling. De är
väggdekor, inte bärande struktur, och luckan står i `site.js` så att den
som speglar vet vad som återstår.

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
