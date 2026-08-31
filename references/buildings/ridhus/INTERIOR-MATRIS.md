# Ridhusets interiör — reference matrix

Byggd 2026-08-31 på **103 bilder**. Den tidigare versionen av det här
dokumentet var byggd på **3**.

Det här är dokumentet ridhusets interiör byggs ur. Varje rad ska kunna spåras
till en namngiven bild som någon faktiskt har tittat på.

- Bildregister med beskrivning per bild:
  `references/RIDHUS-INVENTERING-2026-08-31.md`
- Granskarnas underlag, ett avsnitt per fil: `granskning-2026-08-31/`
- Den gamla revisionsberättelsen, ordagrant bevarad:
  `INTERIOR-MATRIS-HISTORIK.md`

## Underlag

| källa | omfattning |
|---|---|
| `references/buildings/ridhus/*.jpg` | 76 foton, interiör och gavlar |
| `references/video/ridhus-nyckelrutor/*.jpg` | 27 filmrutor ur fem klipp |
| `references/plans/ridhus-entreplan-utrymning.jpg` | brandplan, entréplan |
| `references/plans/RIDHUS-PLANMATNING-2026-08-30.md` | planmätning |

`IMG_0191.MOV` finns inte i repot — `[DRIVE-ONLY]`. Inget nedan vilar på den.

## Klasser

| klass | betyder |
|---|---|
| `VERIFIED` | syns i en bild produktägaren granskat, och granskaren har tittat på den |
| `FOTO, EJ GRANSKAD` | syns i bild, men bilden är inte bland de 34 produktägaren granskat |
| `DERIVED` | räknat ur något verifierat |
| `ASSUMPTION` | valt tal, inget stöd |
| `[REFERENCE GAP]` | underlag saknas i de 103 bilderna |
| `[DRIVE-ONLY]` | underlag finns i Drive men inte i repot |
| `KNOWN MISMATCH` | spelet och verkligheten skiljer sig, felet är känt |
| `MOTSÄGELSE` | två bilder säger olika, ingen vinner utan mer info |

De 34 granskade bilderna är märkta `nyckelbild = ja` i inventeringen.

## Två regler som gäller hela dokumentet

**1. Kameraläget kontrolleras innan flera bilder binds ihop.** Det här arbetet
har gjort det felet två gånger. Först lästes en bild tagen längs en långsida mot
den bortre kortsidan som om båda väggarna var samma vägg. Sedan lästes en
beskuren förgrund som om den beskrev hela läktaren. Båda felen låg i
synteslagret, inte hos granskarna — och syntesen var det ingen som granskade.
Varje slutsats nedan som binder ihop flera bilder anger varifrån kameran tittar.

**2. Struktur och funktion hålls isär.** En okänd funktion får aldrig fyllas med
en trolig gissning. Se `docs/DELIVERY-PROTOCOL.md`.

---

# 1. Banan och sargen

Underlag: `granskning-2026-08-31/A-banan-och-sargen.md`, 16 bilder.

| fakta | klass | källa |
|---|---|---|
| Banan 20 × 60 m | `VERIFIED` | produktägaren, `SITEPLAN.md` |
| **En** bana, som inte byter material | `VERIFIED` | produktägaren 2026-08-31 |
| Sargen vitmålad liggande panel med svart sockelband | `VERIFIED` | `ridhus-inne-14-laktaren.jpg`, `-43-laktaren-vid-h.jpg`, `-31-langsidan-med-sponsorskyltar.jpg` |
| Sockelbandet är slitet och ojämnt, inte en ren list | `FOTO, EJ GRANSKAD` | `ridhus-inne-43-laktaren-vid-h.jpg` |
| Sarghöjd 1,35 m | `DERIVED` | — |
| Sockelbandets andel av sarghöjden | **prövat, ej ändrat** | 0,26 av 1,35 = 19 % |
| Underlaget är brun sand-/flisblandning med hovspår och harvspår | `VERIFIED` | `ridhus-inne-11-ridbanan.jpg`, `-43` |
| Dressyrbokstäverna sitter som vita skyltar på sargen, med djur-/symbolbild | `VERIFIED` | H med hästbild i `ridhus-inne-43`, B i `-31`, C och E tidigare |
| Bokstavsplacering A, B, C, E, H | `VERIFIED` | se § *Bokstäverna* nedan |
| Löst bokstavsställ med F, R, H, V, C, K, M, A bakom sargen | `FOTO, EJ GRANSKAD` | `ridhus-inne-21-hinderupplaget-och-bokstavsstall.jpg` |
| Sargluckor med svarta beslag, 2–3 horisontella springor | `VERIFIED` | `ridhus-inne-19-glaspartiet-och-skyltraden.jpg` |
| Minst en lucka är en öppningsbar dörr med gångjärn, ner till en trappa | `FOTO, EJ GRANSKAD` | `ridhus-inne-37-rampdorren.jpg` |
| Fönsterparti med nät i sargväggen vid A-hörnet | `FOTO, EJ GRANSKAD` | `ridhus-inne-36-vita-kortsidan.jpg`, `-38-vita-hallen-variant.jpg` |
| Hinderupplag bakom sargen: bommar i regnbågsfärger, stöd, koner, hinkar | `FOTO, EJ GRANSKAD` | `ridhus-inne-21`, `-44-klubbhornet-med-bommar.jpg` |
| Lösa bommar och koner står framme **på** banan under ridning | `VERIFIED` | `ridhus-inne-11`, `-38`, `IMG_0185-f01-laktarsidan.jpg` |
| Sargens exakta luckplacering i meter | `[REFERENCE GAP]` | — |

## Bokstäverna

Axeln är A→C. Läst i bild:

| bokstav | läge | källa |
|---|---|---|
| A | den vita kortsidan | `ridhus-inne-23-kortsidan-vid-a.jpg`, `-36`, `-38` |
| C | kortändan vid läktare/kafé | `IMG_0185-f01`, `IMG_0192-f01`, `IMG_0179` |
| B | sponsorlångsidan, framför spegeln | `ridhus-inne-31-langsidan-med-sponsorskyltar.jpg`, `-19`, `-20` |
| E | läktarlångsidan, vid domarbåset | `ridhus-inne-03-baset-vid-E.jpg` |
| H | läktarlångsidan | `ridhus-inne-43-laktaren-vid-h.jpg`, `-14`, `-28` |

**E och H ligger på samma långsida.** Det är den sida läktaren står på. Det är
konsistent med en 20 × 60-bana där K, E, H ligger på en långsida och F, B, M på
den andra, och det bekräftar att domarbåset "vid E" står på läktaren.

Att bokstavsstället bakom sargen har åtta bokstäver medan bara fem sitter fasta
betyder att banan kan sättas med full bokstavssättning. Spelet bör kunna göra
båda.

---

# 2. Läktaren — matrisen hade RÄTTAT BORT en korrekt egenskap

Underlag: `granskning-2026-08-31/B-laktaren.md`, 16 bilder, plus egen
kontrollgranskning av fyra bilder.

## Vad som var fel

Den gamla matrisen påstod, klassat `VERIFIED`:

> **Plant plankdäck**, inga trappsteg — r01 förgrund, beskuren
>
> Spelet byggde **fyra trappsteg i ljus furu** längs hela långsidan. Fotona
> visar ett plant däck. Trappstegen finns — vid KORTÄNDAN, under glasrummen.

**Detta är fel, och felet gick i spelets disfavör.** Spelet hade byggt stegade
bänkrader i ljus furu. Matrisen tog bort dem som ett fel. Bilderna visar att de
skulle ha varit kvar.

| bild | kameraläge | vad den visar |
|---|---|---|
| `ridhus-inne-07-laktartrappstegen.jpg` | på läktaren, längs raderna mot stjärnväggen | **tre stegade bänkrader i ljus furu**, med sittdynor på |
| `ridhus-inne-43-laktaren-vid-h.jpg` | i banan vid H, mot läktaren | stegade rader i ljust trä, fyra personer sittande |
| `ridhus-inne-14-laktaren.jpg` | i banan, längs hela läktarlångsidan | stegade rader **i hela långsidans längd** |
| `ridhus-inne-04-sargen-mot-laktaren.jpg` | på läktarens gångbräda vid ena änden | plan gångbräda i mörkt trä **framför** raderna |

Den gamla slutsatsen kom ur en beskuren förgrund av `ridhus-inne-01`. Det som
är plant i den beskärningen är **gångbrädan längst fram**, inte läktaren.
Läktaren består av tre saker, inte ett:

1. sargen mot banan,
2. en plan gångbräda i mörkt trä bakom sargkrönet,
3. stegade bänkrader i ljus furu som reser sig därifrån.

Den gamla matrisen slog ihop 2 och 3 och kallade dem ett plant däck.

## Vad som gäller

| fakta | klass | källa |
|---|---|---|
| Stegade bänkrader i ljus furu längs läktarlångsidan | `VERIFIED` | `ridhus-inne-07`, `-14`, `-43` |
| **Tre** bänkrader | `FOTO, EJ GRANSKAD` | `ridhus-inne-32-hornet-mot-laktaren.jpg` ("tre rader träbänkar"), `-41-banan-fran-laktaren.jpg` ("tre bänkrader"), `-07` (tre synliga) |
| Plan gångbräda i mörkt trä mellan sargen och raderna | `VERIFIED` | `ridhus-inne-04` |
| Raderna löper i hela långsidans längd | `VERIFIED` | `ridhus-inne-14` (en bildruta, hela sidan) |
| Lösa sittdynor på raderna, svarta och blå, en märkt Elon | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Räcke i metall vid uppgången | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Väggen ovanför läktaren är **ljus stående skivpanel** med synliga mörka pelare | `VERIFIED` | `ridhus-inne-14` |
| Solid mörkbetsad brädfront mot banan | **återkallad** | var byggd på samma beskärning som felet ovan |
| Ljus kappregel överst på fronten | **nedgraderad** till `[REFERENCE GAP]` | kan inte reproduceras i `-01`, `-02` eller `-04` |
| Däckets höjd 0,80 m | `DERIVED` | sittande huvuden ~0,7 m över sargkrönet i `-43` |
| Radernas stighöjd och djup | `[REFERENCE GAP]` | — |
| Gång bakom läktaren, sliten plywood, galvaniserad ventilationskanal upp genom takfoten | `FOTO, EJ GRANSKAD` | `ridhus-inne-39-gangen-bakom-laktaren.jpg` |
| Läktaren delas av en mellanvägg med stjärndekor, trappa på båda sidor | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Returtunna för burkar står på läktaren | `FOTO, EJ GRANSKAD` | `ridhus-inne-43` |

## Varför det här är den viktigaste raden i dokumentet

Ett fel som säger "bygg detta" kostar arbete. Ett fel som säger "riv detta" kostar
arbete **och** tar bort något som var rätt. Den gamla matrisen gjorde det andra,
med dokumentets starkaste klass, på en beskuren bild.

Regeln som följer: **en `VERIFIED` som vilar på en beskärning ska ange vad
beskärningen utesluter.** En beskärning är ett kamerabyte.

---

# 3. Kortändan vid C, trapporna och kaféet

Underlag: `granskning-2026-08-31/C-kortandan-och-kafeet.md`, 16 bilder.

Produktägaren har fastställt 2026-08-31: **den glasade våningen är ett kafé**,
med fönstervägg mot ridbanan.

| fakta | klass | källa |
|---|---|---|
| Trappstegsblock vid kortändan, **två trappor** upp | `VERIFIED` | `ridhus-inne-01-glasrummen.jpg` |
| Trapporna är i **mörkt/mörkbetsat** trä, inte samma ljusa furu som bänkraderna | `FOTO, EJ GRANSKAD` | `ridhus-inne-07`, `-08-laktartrappan.jpg` |
| Glasat band av rum ovanför, mörkbruna karmar | `VERIFIED` | `ridhus-inne-01`, `-07` |
| Bandet bryts av de två trapporna | `VERIFIED` | `ridhus-inne-01`, beskuren |
| Glaset går i bås med poster, inte som en remsa | `VERIFIED` | `ridhus-inne-01`, `-07` |
| Båsens delning 1,9 m | `ASSUMPTION` | — |
| **Exakt en** rund vit klocka vid kortändan, på den vita väggen mellan trapporna | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` (klockan och stjärnan i samma bildruta) |
| Vit stående brädvägg mellan bänkar och glas | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Stjärna med sju–åtta spetsar, tunna linjer, på den vita väggen | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Högtalare monterad på den vita väggen vid klockan | `FOTO, EJ GRANSKAD` | `ridhus-inne-07` |
| Kaféets funktion | `VERIFIED` | produktägaren 2026-08-31 |
| Handskriven svart tavla, "Välkomna till Ca…" | `FOTO, EJ GRANSKAD` | `ridhus-klubb-07-cafeet-genom-glaset.jpg` |
| Kaférummet sett från banan: fönsterband med lysrör och inredning bakom glas | `VERIFIED` | `ridhus-inne-01` |
| Kaférummet sett inifrån: vita bord, grå perforerade metallstolar, runda pelarbord, panelinnertak med ljusslinga | `VERIFIED` | `ridhus-klubb-09-cafesalen.jpg` |
| Ridbanan synlig genom glaset **inifrån** kaféplanet | `VERIFIED` | `ridhus-klubb-10-overvaningens-gang.jpg` |
| Alla meter vid kortändan | `[REFERENCE GAP]` | topologi rätt, mått valda |

## Kaféet är en gameplay-yta, inte en textur

Kaférummet är belagt **åt båda hållen**: från banan syns rummet genom glaset,
och från rummet syns banan. Det är alltså inte ett dekorativt glasband utan ett
rum spelaren kan stå i och titta ut ur medan andra rider.

Det gör den gamla `KNOWN MISMATCH` — *"glasbandet läser som en mörk remsa, inte
som fönster med bruna karmar in i upplysta rum"* — till en rumsfråga, inte en
materialfråga.

## Stjärnan: ordstriden är avgjord

Den gamla matrisen skrev "kompassros, LINJERITAD". Inventeringen skrev "målad
stjärna". `ridhus-inne-07` visar saken i närbild: en sjuspetsig stjärna i tunna
ljusa linjer på den vita väggen. **Samma objekt, två ordval.** Ingen motsägelse.
Den är dekor och byggs inte, men den är ett bra läsbart landmärke för att
identifiera kortändan i andra bilder.

## Klockhypotesen: avgjord mot den gamla matrisen

Den gamla matrisen påstod att kaféklockan sitter i norra änden och att
kortändans klocka *"fanns alltså inte alls"*, och lade till `kortanda.klocka`
som ett separat objekt.

`ridhus-inne-07` visar **en** rund vit klocka, på den vita väggen vid
kortändan, i samma bildruta som stjärnan. Ingen bild i underlaget visar två
klockor. Påståendet att kortändans klocka inte fanns är alltså motsagt.

**Men:** att det är samma klocka som datans `RIDHUSINNE.klocka` är fortfarande
inte bevisat, för det kräver att koordinatmodellen läses, inte att en bild
tittas på. `MOTSÄGELSE` tills geometrin är kontrollerad. Jag drar den inte
längre än så — det var precis den formen båda tidigare felen hade.

## En tredje uppgång som inte hör hit

Vid H-hörnet finns en **fristående vit lutande trappa** upp till ett annat
glasparti (`ridhus-inne-14`, `-15-hornet-mot-glasrummen.jpg`,
`-10-glasrumsvaggen.jpg`, alla med H synlig på sargen i samma bildruta). Det är
inte C-trapporna och ska inte läsas in i kortändans geometri.

---

# 4. Sponsorlångsidan

Underlag: `granskning-2026-08-31/D-langvaggen.md`, 22 bilder, plus egen
kontrollgranskning av `ridhus-inne-31`.

## Vad som var fel

Den gamla matrisen påstod, klassat `VERIFIED`: *"Rostbrun/mörkröd panel på DEL
av EN långsida"* och *"resten av samma vägg är ljus"*.

**Panelen täcker hela långsidan.** Det ljusa är inte samma väggs fortsättning —
det är den vita sargen under panelen och fönsterbandet över den. Väggen har tre
våningar i höjd, och den gamla matrisen läste dem som tre stycken i längd.

`ridhus-inne-31-langsidan-med-sponsorskyltar.jpg` avgör frågan: kameran står på
läktaren och tittar rakt över banan på hela den motstående långsidan i en
bildruta. Panelen är obruten från hörn till hörn.

| fakta | klass | källa |
|---|---|---|
| Mörk rödbrun liggande panel i **hela** långsidans längd | `VERIFIED` | `ridhus-inne-31`, `-11-ridbanan.jpg` |
| Vita/ljusa horisontella hyllister på panelen | `VERIFIED` | `ridhus-inne-31` |
| Panelen delas i fält av mörka pilastrar | `VERIFIED` | `ridhus-inne-31` |
| Fönsterband ovanför panelen, som **separata** öppningar per fält | `VERIFIED` | `ridhus-inne-31`, `-17`, `-24`, `-26` |
| Vit sarg med svart sockelband under panelen | `VERIFIED` | `ridhus-inne-31` |
| Sponsorskyltarna hänger på panelen | `VERIFIED` | `ridhus-inne-31` |
| **En** spegel, delad i två rutor, i brun ram, vid bokstaven B | `VERIFIED` | `ridhus-inne-31`, `-19`, `-20` |
| Svart panelsektion till höger om spegeln | `VERIFIED` | `ridhus-inne-31` |
| Ljus trädörr i panelväggen till höger om den svarta sektionen | `VERIFIED` | `ridhus-inne-31` |
| Trälucka/trappa intill spegeln | `FOTO, EJ GRANSKAD` | `ridhus-inne-37` |
| Panelens höjd i meter | `[REFERENCE GAP]` | — |
| Fönsterbandets höjd och postdelning | `[REFERENCE GAP]` | — |

## Skyltarna, i ordning från vänster

Läst i `ridhus-inne-31-langsidan-med-sponsorskyltar.jpg`:

1. **VÄLKOMMEN TILL UPPLANDS BRO RYTTARFÖRENING** — vit skylt med logotyp
2. **HUVUDSPONSOR ELON BARKARBY** — svart skylt, med en lista i vänsterkant:
   KÖKET, BADRUMMET, TVÄTTSTUGAN, STRÖKRUBBAN, ELMATERIEL, BELYSNING,
   LUFTVÄRMEPUMPAR, och till höger "Till din tjänst" med tre pictogram
3. **"Vi tror på dig!"** — röd/vit skylt
4. spegeln (två rutor, brun ram) — bokstaven **B** står på sargen framför
5. svart panelsektion
6. ljus trädörr
7. **Agria Djurförsäkring** — blå skylt
8. **Hästsportbutik** — vit skylt med grön logotyp
9. **två blå skyltar med hästmotiv**, foder/strö

Den gamla matrisen hade fyra skyltar. Underlaget visar minst nio objekt i rad.

**Men skyltuppsättningen är inte konstant.** Inventeringen läser i
`ridhus-inne-02-langsidan.jpg` namnen *Agria, Stigeberga Gård, RS Mustang* —
alltså **Stigeberga Gård** där `-31` har Hästsportbutik och foderskyltarna, och
**RS Mustang** som inte syns i `-31` alls. Antingen är det två olika partier av
samma vägg, eller så är bilderna tagna vid olika tidpunkter och skyltarna har
bytts.

Sponsorskyltar byts när avtal löper ut. **Spelet ska därför inte hårdkoda
skyltnamn.** Skyltarna bör vara en datadriven lista med ett givet antal platser
på panelen, så att en ändring är en datarad och inte en ombyggnad. Det är en
arkitekturkonsekvens, inte en referensfråga.

## En flaggad öppen fråga som nu är avgjord

Inventeringen hade en öppen fråga: sitter välkomstskylten och Elon-skylten på
en **kortsida** eller på långsidan? `IMG_0192-f04` och `IMG_0196-f01` läste dem
som kortsida.

`ridhus-inne-31` avgör det. Båda skyltarna sitter på **långsidan**, och
bokstaven **B** står på sargen i samma bildruta. B är en långsidesbokstav.
Filmrutorna är tagna i vinkel mot hörnet, vilket är samma perspektivkompression
som fällde väggmodellen första gången. **Frågan stryks som öppen.**

---

# 5. Läktarlångsidan — en fråga till produktägaren

Produktägarens rättade väggmodell 2026-08-31 lyder: *"Långsidorna: mörk rödbrun
horisontell panel med vita hyllister."* Plural.

Underlaget visar att **de två långsidorna inte är lika**:

| långsida | vägg ovanför sargen | källa |
|---|---|---|
| sponsorlångsidan (B) | mörk rödbrun panel, hela längden | `ridhus-inne-31` |
| läktarlångsidan (E, H) | **ljus stående skivpanel** med mörka pelare | `ridhus-inne-14` |

`ridhus-inne-14-laktaren.jpg` är tagen från banan rakt mot läktarlångsidan, i
hela dess längd, i en bildruta. Det är inte en vinkel mot ett hörn och alltså
inte samma perspektivfel som tidigare.

**Jag ändrar inte modellen på detta.** Produktägaren har rättat mig en gång på
just den här väggen, och den rättelsen var korrekt. Tre möjligheter står öppna:

1. Panelen sitter bara på sponsorlångsidan, och "långsidorna" var ett
   plural-slarv.
2. Panelen sitter på läktarlångsidan också, men bakom eller under bänkraderna
   där den inte syns från banan.
3. Något i min läsning av `-14` är fel.

**Detta är en fråga, inte en slutsats.** Se § *Öppna frågor*.

---

# 6. Taket och installationerna

Underlag: `granskning-2026-08-31/E-taket.md`, 15 bilder.

| fakta | klass | källa |
|---|---|---|
| Symmetriskt sadeltak | `VERIFIED` | nock i `ridhus-inne-16-sargen-mot-lang-sida.jpg`, utifrån i `ridhus-gavel-01..04` |
| Balkarna går **tvärs** hallen, lysrören **längs** | `VERIFIED` | `ridhus-inne-14`, `-31` |
| Balkarna är mörkt gråbruna, nästan neutrala — **inte** varma som stallets limträ | `VERIFIED` | färgmätning, se `INTERIOR-MATRIS-HISTORIK.md` |
| Korrugerad plåt som undertak | `VERIFIED` | `ridhus-inne-07`, `-14`, `-31` |
| Långa lysrörsarmaturer i rader | `VERIFIED` | `ridhus-inne-14`, `-31` |
| Bärande träpelare med synliga stålskor i betong | `VERIFIED` | `ridhus-inne-05-ridbanan-sponsorvaggen.jpg`, `-04` |
| Diagonala snedsträvor mellan pelare och balk | `VERIFIED` | `ridhus-inne-05`, `-07` |
| Ljusinsläpp som stående fönsterband under takfoten, **inte** i takytan | `VERIFIED` | `ridhus-inne-02`, `-11`, `-42-vita-hallen.jpg` |
| Riktade spotlights monterade på balkarna | `VERIFIED` | `ridhus-inne-28-langsidan-vid-h.jpg`, `-32-hornet-mot-laktaren.jpg` |
| Hornhögtalare under takfoten | `VERIFIED` | `ridhus-inne-14` |
| Minst **tre** olika ventilationskanaltyper | `VERIFIED` | se nedan |
| Kabelstegar och hängande kablar | `VERIFIED` | `ridhus-inne-14`, `-31` |
| Antal balkfält | `[REFERENCE GAP]` | ingen bild fångar hela längden utan perspektivkompression |
| Träslag i balkarna | `[REFERENCE GAP]` | färg avgör inte material |
| Takresning och balkdelning | `DERIVED` | spelets tidigare tal, 2,8 / 6,0 m — ej mätta |

## Ventilationen är tre saker, inte en

Den gamla matrisen hade en rad: *"stora runda spiralkanaler"*. Underlaget visar
tre olika dragningar, och en modell som bygger en av dem bygger fel:

1. **Isolerad flexkanal** i silverfolie, dragen längs undertaket
   (`ridhus-inne-04-sargen-mot-laktaren.jpg`).
2. **Galvaniserad kanal upp genom takfoten** i gången bakom läktaren
   (`ridhus-inne-39-gangen-bakom-laktaren.jpg`).
3. **Lodrät grå kanal ner längs väggen** (`ridhus-inne-14`, `-30`, `-44`).

## Lysrörstätheten skiljer sig mellan hallens delar

Den vita hallen vid kortändan A har synbart tätare lysrörsrader än den
brunpanelade delen (`ridhus-inne-42-vita-hallen.jpg` mot `ridhus-inne-11`).
`FOTO, EJ GRANSKAD`. Om det står sig är det en ljussättningsskillnad spelet bör
ha, inte ett fotoartefakt — men det är inte avgjort.

## Gavelbilderna

`ridhus-gavel-01.jpg` till `-04-statrappan.jpg` visar takformen utifrån från
fyra vinklar: rent symmetriskt sadeltak, mörk vindskiva, röd korrugerad
plåtfasad. **De beskrivs inte i inventeringen**, som bara täcker interiören, och
har därför ingen `nyckelbild`-markering. `FOTO, EJ GRANSKAD` — men otvetydiga.

Att de saknas i inventeringen är en lucka i inventeringen, inte i materialet.

---

# 7. Domarbåset

Underlag: `granskning-2026-08-31/F-baset-och-domartornet.md`, plus egen
kontrollgranskning av `ridhus-inne-14`.

## "Båset vid E" och "domartornet på läktaren" är samma struktur

Detta var avsnittets huvudfråga, och den är avgjord genom att jämföra
kameraläge i fyra bilder:

| bild | kameraläge | vad den visar |
|---|---|---|
| `ridhus-inne-03-baset-vid-E.jpg` | i banan vid E, underifrån | sadeltak, utskjutande takfot, trappa, grön skylt |
| `ridhus-inne-40-domartornet-pa-laktaren.jpg` | på läktardäcket, i sidled | samma bod, brunt trä, räcke, trappa |
| `ridhus-inne-16-sargen-mot-lang-sida.jpg` | i banan, långt avstånd | samma bod på läktaren |
| `ridhus-inne-14-laktaren.jpg` | i banan, hela läktarlångsidan | boden står **på** läktaren, mitt på långsidan, med trappa och grön skylt |

Samma sadeltak, samma träfärg, samma gröna skylt, samma läge i alla fyra. Det är
en bod, inte två.

Det stämmer också geometriskt: E och H ligger på samma långsida, och det är
läktarens sida. En bod mellan E och H står på läktaren. De två namnen var två
kameravinklar.

| fakta | klass | källa |
|---|---|---|
| Bod i brunt/mörkt trä, upphöjd på läktaren | `VERIFIED` | `ridhus-inne-14`, `-03` |
| Sadeltak med utskjutande takfot | `FOTO, EJ GRANSKAD` | `ridhus-inne-03`, beskuren |
| Trappa upp, räcke | `VERIFIED` | `ridhus-inne-14`, `-40` |
| Räcke på **båda** sidor av trappan | `FOTO, EJ GRANSKAD` | `ridhus-inne-03` |
| Grön utrymningsskylt | `VERIFIED` | `ridhus-inne-14`, `-03`, `-40` |
| Står mitt på läktarlångsidan, mellan E och H | `VERIFIED` | `ridhus-inne-14` |
| Bord och stolar bakom boden på läktardäcket | `FOTO, EJ GRANSKAD` | `ridhus-inne-40` |
| Takets resning 0,42 m | `ASSUMPTION` | — |
| Bodens insida: fönster, stolar, ljudutrustning | `[REFERENCE GAP]` | ingen bild visar insidan |

Den gamla matrisen klassade sina bås-rader `VERIFIED` på `r03`, som **inte** är
bland de 34 granskade bilderna. Klasserna ovan är justerade efter det.

---

# 8. Klubbdelen — nytt avsnitt

Underlag: `granskning-2026-08-31/G-klubbdelen.md`, 20 bilder.

Den gamla matrisen hade **inte en rad** om klubbdelen, trots att repot har 28
bilder av den. Det här avsnittet är därför ett nybygge, inte en prövning.

## Rum som kan beläggas i bild

| rum | källa | klass |
|---|---|---|
| Skåpkorridoren — skåp i grått/rött/mörkgrått, bröstningsvägg med fyra glaspartier, röda trästolar, valvfönster i ena änden | `ridhus-klubb-01-omkladningsgangen.jpg`, `-02-glasrummen.jpg`, `IMG_0169-f02-skapkorridoren.jpg` | `VERIFIED` |
| Entréparti — glasad dubbeldörr med sidoljus, grön nödutgångsskylt | `IMG_0169-f05-korridoren-mot-entren.jpg` | `FOTO, EJ GRANSKAD` |
| Smal korridor med tre vita innerdörrar | `ridhus-klubb-03-korridordorrarna.jpg` | `FOTO, EJ GRANSKAD` — dörrarnas mål **okänd funktion** |
| Kaférummet | `ridhus-klubb-07`, `-08`, `-09-cafesalen.jpg` | `FOTO, EJ GRANSKAD`, funktion från produktägaren |
| Gången på övre plan — glasrum till vänster, ridbanans sarg till höger utan mellanvägg | `ridhus-klubb-10-overvaningens-gang.jpg` | `VERIFIED` |
| Hinderförråd — bommar, hinderstöd på krysstativ, betonggolv | `ridhus-klubb-11-trappan-till-hinderforradet.jpg`, `-12-hinderforradet.jpg` | `FOTO, EJ GRANSKAD` — ensam källa |
| Stora toaletten — helkaklad, golvstående wc med stödhandtag | `ridhus-klubb-04-stora-toaletten.jpg` | `FOTO, EJ GRANSKAD` — ensam källa |
| Lilla toaletten — mycket smal, hörntvättställ | `ridhus-klubb-05-lilla-toaletten.jpg` | `FOTO, EJ GRANSKAD` — ensam källa |
| Dusch och wc — vägghängd duschblandare, golvbrunn | `ridhus-klubb-17-dusch-och-wc.jpg` | `FOTO, EJ GRANSKAD` — ensam källa |
| Skåprummet med pelaren — bärande fyrkantpelare, skåp i mörkblått/grått/vitt | `ridhus-klubb-16-skaprummet-med-pelaren.jpg` | `VERIFIED` — rummet innanför dörren **okänd funktion** |
| Omklädningen med valvfönstret — sju höga skåp, valvfönster mot grusad parkering och röd byggnad | `ridhus-klubb-14-omkladningen-med-valvfonstret.jpg` | `VERIFIED` |
| Korridoren mot glasrummen — skåp i grått/svart/rött/blått, glaspartier med skjutbara rutor | `ridhus-klubb-15-korridoren-mot-glasrummen.jpg` | `VERIFIED` |
| Korridor med toalettbås och en låst dörr | `ridhus-klubb-19-dorrarna-till-omkladningen.jpg` | `FOTO, EJ GRANSKAD` — låsta dörrens mål **okänd funktion** |
| Gröna skåpraden — fyra sektioner i två våningar | `ridhus-klubb-20-grona-skapen.jpg`, `-21-grona-skapen-vinkel.jpg` | `FOTO, EJ GRANSKAD` — rummet bakom underexponerat, **okänd funktion** |
| Hörn med svart utåtgående dörr, skjutfönster med gardin | `ridhus-klubb-06-svarta-dorren.jpg` | `FOTO, EJ GRANSKAD` |
| Hörn med svart enkeldörr och städredskap i hållare | `ridhus-klubb-13-svarta-utgangsdorren.jpg` | `FOTO, EJ GRANSKAD` — samma dörr som `-06`? oavgjort |
| Omklädningen med fåtöljerna — plåtskåp i rött/grått/mörkblått, tre vitmålade fåtöljer, tvåsits soffa med röda dynor | `ridhus-klubb-22-omkladningsrummet.jpg` | `VERIFIED` — placering i byggnaden okänd |

**Sexton rum kan beläggas. Inget av dem har ett mått.**

## Våningarna

| fakta | klass | källa |
|---|---|---|
| Gången på övre plan ligger i nivå med ridbanans sargkrön, banans golv klart lägre | `VERIFIED` | `ridhus-klubb-10` |
| Kaférummet ligger på samma våning som den gången — inga trappsteg mellan dem | `DERIVED` | `ridhus-klubb-07`–`-10` i serie |
| Hinderförrådet ligger på en **lägre** nivå — trappa ner från gången | `FOTO, EJ GRANSKAD` | `ridhus-klubb-10`, `-11` |
| Omklädningsdelens våning i förhållande till kaféet | `[REFERENCE GAP]` | ingen bild binder ihop dem |

Att omklädningsdelen inte kan placeras i höjd är en riktig lucka. Den lämnas
öppen i stället för att antas ligga på entréplan.

## Vad som saknas för att kunna bygga klubbdelen

- **Alla mått.** Det finns inte ett enda mått för klubbdelen i underlaget.
- **Planlösningen.** Sexton rum, men ingen bild som visar hur de sitter ihop.
  Brandplanen (`references/plans/ridhus-entreplan-utrymning.jpg`) täcker
  entréplan och kan sannolikt lösa en del av detta — det är inte prövat här.
- **Kaféets pentry/köksdel** syns delvis men inte i sin helhet.
- **Trappan mellan planen** — bara sedd uppifrån och nedifrån, aldrig hel.

---

# 9. Elva bilder som låg i repot utan att stå i inventeringen

Mappen har **103** bildfiler. Inventeringen beskriver **93**. Skillnaden är inte
slarv i räkningen utan elva filer som aldrig blev inventerade, för de låg i
repot redan innan de 93 importerades och ingen räknade om:

| fil | vad den visar |
|---|---|
| `ridhus-trappan-05-cafeskylten.jpg` | **kaféets yttre trappa och CAFÉ-skylten** — se nedan |
| `ridhus-gavel-01.jpg` … `-04-statrappan.jpg` | takformen utifrån, fyra vinklar |
| `ridhus-langsida-01-skylten.jpg` | långsidan utifrån med skylt |
| `ridhus-langsida-02-trappan.jpg` | långsidan utifrån med trappa |
| `ridhus-langsida-03-dubbeldorren.jpg` | dubbeldörren utifrån |
| `ridhus-skylten-06-narbild.jpg` | skylten i närbild |
| `ridhus-durkplatdorrarna-07.jpg` | durkplåtsdörrar |
| `ridhus-inne-03-baset-vid-E.jpg` | domarbåset — **den gamla matrisens `r03`** |

Omvänt står `IMG_0185-f01.jpg` i inventeringen men finns inte på disk; filen
heter `IMG_0185-f01-laktarsidan.jpg`. Ett namnfel i registret, inte en saknad
bild.

## Att `r03` inte var inventerad är värt att stanna vid

`ridhus-inne-03-baset-vid-E.jpg` är en av den gamla matrisens **tre** källbilder,
och den finns inte i inventeringen. Den har alltså aldrig fått en
`nyckelbild`-markering, och kunde inte ha fått en. Varje rad i den gamla
matrisens § 7 stod som `VERIFIED` på en bild som låg utanför registret.

## Kaféet hade en egen entré, och beviset låg i repot

`ridhus-trappan-05-cafeskylten.jpg`, committad **2026-08-30** — dagen innan
kafé­frågan ens ställdes — visar utifrån:

- ridhusets fasad i **röd korrugerad plåt**,
- en **galvaniserad utvändig trappa** upp längs fasaden till ett vilplan,
- ett **räcke med en blå skylt: CAFÉ**,
- grusplan, cykelställ, parkerade bilar, en grind och ett staket.

Det ger tre saker matrisen inte hade:

| fakta | klass | följd för bygget |
|---|---|---|
| Kaféet har en **egen utvändig entré** via en ståltrappa på fasaden | `FOTO, EJ GRANSKAD` | kaféet nås utifrån utan att gå genom stallet eller ridhuset — en egen ingång i spelet |
| Kaféet ligger på **övre plan**, bekräftat utifrån | `FOTO, EJ GRANSKAD` | stämmer med `ridhus-klubb-10` inifrån |
| Fasaden är röd korrugerad plåt | `FOTO, EJ GRANSKAD` | stämmer med gavelbilderna |

**Funktionen var alltså fotograferad i klartext i repot, i en fil ingen hade
inventerat.** Jag frågade produktägaren om något materialet redan svarade på.
Det är inte hans fel och inte granskarnas — de fick 93 filer att granska och
granskade 93.

**Felet är att ingen räknade filerna i mappen mot raderna i registret.** Det är
en kontroll som tar en rad kod och som borde ha funnits från början:

```
antal filer i references/buildings/ridhus + references/video/ridhus-nyckelrutor
  ==  antal bildrader i RIDHUS-INVENTERING-2026-08-31.md
```

Det bör bli en grind i CI, inte en vana. Se § *Öppna frågor*, punkt 6.

---

# 10. Grinden som saknades, och vad den fällde i det här dokumentet

`tools/kolla-nyckelbilder.py`, kopplad till CI i det här passet, kontrollerar
två saker:

1. **Varje tabellrad klassad `VERIFIED` måste citera minst en bild som är
   märkt `nyckelbild = ja` i inventeringen.** Rader som inte citerar någon bild
   alls hoppas över — de vilar på produktägaruppgift eller härledning.
2. **Antalet bildfiler i mapparna jämförs med antalet bildrader i
   inventeringen**, och varje oinventerad fil listas.

## Den fällde 13 rader i den här matrisen, skrivna av mig samma dag

Första körningen underkände tretton rader jag själv nyss hade klassat
`VERIFIED`. Samtliga är nedgraderade till `FOTO, EJ GRANSKAD`:

| avsnitt | rad | vilade på |
|---|---|---|
| 1 | sockelbandet slitet och ojämnt | `ridhus-inne-43` |
| 1 | fönsterparti med nät vid A-hörnet | `ridhus-inne-36`, `-38` |
| 2 | tre bänkrader | `ridhus-inne-32`, `-41`, `-07` |
| 2 | mellanvägg med stjärndekor | `ridhus-inne-07` |
| 3 | trapporna i mörkbetsat trä | `ridhus-inne-07`, `-08` |
| 3 | exakt en klocka vid kortändan | `ridhus-inne-07` |
| 3 | vit stående brädvägg mellan bänkar och glas | `ridhus-inne-07` |
| 3 | stjärnan med sju–åtta spetsar | `ridhus-inne-07` |
| 7 | sadeltak med utskjutande takfot | `ridhus-inne-03` |
| 8 | entrépartiet | `IMG_0169-f05` |
| 8 | smal korridor med tre dörrar | `ridhus-klubb-03` |
| 8 | kaférummet | `ridhus-klubb-07`, `-08` |
| 8 | korridor med toalettbås | `ridhus-klubb-19` |

**`ridhus-inne-07-laktartrappstegen.jpg` bär fem av de tretton.** Det är den
bild som avgjorde läktarfrågan — den enda som visar bänkraderna, klockan,
stjärnan och brädväggen i en och samma ruta. Och den är inte granskad.

Det är inte ett argument för att strunta i klassen. Det är ett argument för att
`ridhus-inne-07` bör granskas härnäst, tillsammans med `-32`, `-41`, `-43` och
`-08`. Fem bilder som skulle flytta tretton rader.

## Varför den här grinden är värd mer än de tretton raderna

Båda de fel som ombyggnaden hittade i den gamla matrisen — väggmodellen och
läktaren — hade samma form: en `VERIFIED` som vilade på en bild eller en
beskärning som ingen hade granskat. Grinden hade inte förhindrat felen, för den
mäter inte om en slutsats är riktig. Men den hade satt en tydlig lapp på båda:
*detta står som säkrast möjliga klass på ett obekräftat underlag.*

Grinden ersätter inte granskning. Den gör synligt var granskning saknas.

---

# Vad ombyggnaden gav

| | gamla matrisen | ny |
|---|---|---|
| källbilder | 3 | 103 |
| `[REFERENCE GAP]` | 13 | se nedan |
| avsnitt | 7 | 8 |
| rader om klubbdelen | 0 | 20 |

## Gaps som stängdes

1. **Sargluckans funktion** — minst en är en öppningsbar dörr med gångjärn ner
   till en trappa (`ridhus-inne-37`).
2. **Läktarens konstruktion** — stegade bänkrader i ljus furu, inte plant däck.
3. **Vägen upp på läktaren** — två trappor vid kortändan, en tredje vid H.
4. **Bokstavsplaceringen** — A, B, C, E, H alla belagda med namngiven bild, och
   axeln E/H på samma långsida bekräftad.
5. **Panelens utbredning** — hela sponsorlångsidan, inte ett delstycke.
6. **Fönsterbandets karaktär** — separata öppningar per fält, inte ett band.
7. **Skyltinventeringen** — nio objekt i ordning i stället för fyra namn.
8. **Spegelns antal och läge** — en spegel, två rutor, vid B.
9. **Klockan vid kortändan** — exakt en, mellan trapporna.
10. **Kaféfunktionen fotobelagd** — tavlan "Välkomna till Ca…" plus möblemang.
11. **Ventilationens dragning** — tre skilda kanaltyper.
12. **Ljusinsläppet** — under takfoten, inte i takytan.
13. **Takformen utifrån** — fyra gavelbilder.
14. **Domarbåset = domartornet** — en struktur, inte två.
15. **Klubbdelens rumslista** — 16 rum där matrisen hade noll.
16. **Välkomst- och Elon-skyltens vägg** — långsidan, tidigare flaggad öppen.
17. **Antalet bänkrader** — tre, i tre oberoende bilder.
18. **Kaféets entré** — egen utvändig ståltrappa på fasaden, med CAFÉ-skylt.

## Gaps som står kvar, med motivering

| gap | varför den inte kan stängas på foto |
|---|---|
| Alla mått i hallen | ingen bild har en känd referenslängd i bild |
| Alla mått i klubbdelen | samma, och ingen planritning för övre plan |
| Antal balkfält | perspektivkompression längs hallen |
| Läktarfrontens topplist | ingen närbild finns |
| Domarbodens insida | ingen bild in i boden |
| Klubbdelens planlösning | ingen bild binder rummen samman |
| Motstående kortsidans material | avgörs på plats, inte med fler foton |
| Träslag i takbalkarna | färg avgör inte material |

---

# Öppna frågor till produktägaren

1. **Läktarlångsidans material.** Din rättade modell säger att långsidorna är
   mörk rödbrun panel. `ridhus-inne-14-laktaren.jpg`, tagen från banan längs
   hela läktarsidan, visar ljus stående skivpanel med mörka pelare där.
   Sitter panelen bara på sponsorlångsidan, eller sitter den bakom bänkraderna
   där den inte syns? Se § 5.
3. **Sargluckorna.** Minst en är en dörr. Är de övriga dörrar, ventiler, eller
   löstagbara sektioner?
4. **Motstående kortsidans material** — kvarstår sedan igår, avgörs på plats.
5. **Omklädningsdelens våning** i förhållande till kaféet.
6. **Ska jag lägga in en grind som räknar bildfiler mot inventeringsrader?**
   Elva bilder låg oinventerade, och en av dem svarade på en fråga jag i stället
   ställde till dig. Grinden är triviell att skriva.
7. **De tio övriga oinventerade bilderna** — ska de inventeras i samma format
   som de 93, eller räcker tabellen i § 9?

# Motsägelser som lämnas oavgjorda

1. **Klockan i datan.** `RIDHUSINNE.klocka` mot `kortanda.klocka` — bilderna
   visar en klocka, men vilken av datans två den är kräver att
   koordinatmodellen läses. § 3.
2. **Svarta dörren** i `ridhus-klubb-06` och `-13` — samma dörr eller två?
3. **Kaférummets identitet** i `ridhus-klubb-02` mot `-09` — samma rum?
4. **Lysrörstätheten** mellan den vita hallen och den brunpanelade delen — verklig
   skillnad eller exponering? Inventeringen skriver "mycket tätt sittande rader"
   för `ridhus-inne-42` och "tätt sittande" för `-32` och `-41`, vilket lutar mot
   verklig skillnad, men ordval är inte en mätning.
5. **Sarg kontra läktarfront** — en tredje sargtyp, mörk obehandlad bräda, syns
   vid C och passar ingen av de två kända.

# Vad som inte är prövat i den här ombyggnaden

- **Geometridatan.** Ingen rad ovan har jämförts mot `src/site.js`,
  `UBRFKomplex.luau` eller `RIDHUSINNE`. Ombyggnaden prövade matrisen mot
  **bilderna**, inte spelet mot matrisen. Nästa steg är en jämförelse mot
  datan, och den kommer att hitta fler `KNOWN MISMATCH` än de som står här.
- **Brandplanen.** `ridhus-entreplan-utrymning.jpg` kan sannolikt lösa
  klubbdelens planlösning och hallens orientering. Inte gjort här.
- **Stallet och övriga byggnader.** Bara ridhuset.
