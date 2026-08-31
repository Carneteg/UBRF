# F02 — bevisindex: vad varje zon faktiskt är belagd av

Ett `REFERENCE GAP` som satts för att något inte syns i de **utvalda**
stillbilderna är ett påstående om urvalet, inte om anläggningen. Det här
dokumentet stänger den luckan: varje granskbar zon prövas mot **alla**
tillgängliga källor — plan, stillbild och **råfilm** — innan den får kallas
gap.

Bevispasset kördes med `tools/videobevis.py`, som packar upp filmerna **helt**
(825 bildrutor vid 30 fps) i stället för att gissa en cadence.

## Vad passet ändrade

Tre fynd, och inget av dem är ett nytt rum. Det största felet i samlingen var
inte att material saknades, utan att befintligt material var **felvänt och
felbenämnt**.

### 1. Åtta referensbilder låg upp och ner

`stall-entre-07.jpg` … `stall-entre-14.jpg` är **bit-identiska** med
bildrutorna 5, 15, 24, 35, 45, 54, 65 och 72 ur `IMG_0248.mov` *som ffmpeg
ger dem*, alltså utan filmens rotationsmetadata påförd. De låg alltså upp och
ner i repot. Matchningen är exakt — 0 bitfel på en 64-bitars medelvärdeshash,
mätt mot samtliga 78 bildrutor i filmen.

Konsekvensen var inte kosmetisk. **Skylten på branddörren går inte att läsa i
en upp-och-nervänd bild.** Åtta filer är nu vända rätt.

### 2. Därmed finns det en läsbar rumsskylt — och dokumentationen påstod motsatsen

`docs/F02-RUMSINVENTERING.md` och `docs/F02-DIGITALISERING.md` slog fast att
**ingen** rumsetikett är läsbar i något foto. Efter vändningen är det fel:
`stall-entre-13.jpg` visar en vit dörrskylt med texten **`Stall`** på en grå
branddörr med panikregel, bredvid en utrymningsskylt och ett larmtryck märkt
`UTRYMNINGSLARM`.

Men skylten namnger **rummet bakom dörren**, inte rummet kameran står i. Den
löser alltså en **passage**, inte en rumsfunktion. Inget av de 27 rummen i
`roblox/buildings/Planrum.luau` får ett namn av den. Den korrigerade
formuleringen står i båda dokumenten.

### 3. Hashgallringen tappade långsamma panoreringar

`references/video/README.md` beskrev en gallring på medelvärdeshash med
tröskel 8. Den metoden behöll **3 av 132** bildrutor ur `IMG_0246.mov` — en
långsam panorering ändrar bilden gradvis, så varje bildruta liknar den förra
och hela filmen kollapsar. Det är exakt det som får en filmad vinkel att
"inte finnas".

`tools/videobevis.py` behåller därför en bildruta också när **luckan** blivit
för lång, oavsett hash. Utfallet:

| Film | Bildrutor | Behållna | varav enbart på lucka |
|---|---|---|---|
| `IMG_0246.mov` | 132 | 9 | **8** |
| `IMG_0247.mov` | 61 | 20 | 0 |
| `IMG_0248.mov` | 78 | 15 | 0 |
| `IMG_0249.mov` | 399 | 37 | **19** |
| `IMG_0250.mov` | 155 | 25 | 5 |
| **summa** | **825** | **106** | **32** |

32 bildrutor som hashen ensam hade kastat. Bland dem ridhusets långsida med
ytter­trappan uppe på väggen, och panoreringen vidare mot stallet.

### Vad passet INTE hittade

Ingen ny byggd eller obyggd yta. Tre bildrutor jag först tog för nya vinklar
ur `IMG_0250` visade sig vara identiska med `stall-gang-20`, `-21` och `-22`
som redan låg i repot. De togs bort igen. Samlingen var alltså inte så tunn
som filmlängden antydde — den var felsorterad.

## Bevisindex per zon

`FILM` betyder att zonen är genomsökt i råfilmen, inte bara i urvalet.
`GAP EFTER UTTÖMT BEVIS` betyder att alla fem filmer är genomgångna och zonen
ändå inte syns — ett gap om anläggningen, inte om urvalet.

| Zon | Plan | Stillbilder | Råfilm (bildrutor) | Klass |
|---|---|---|---|---|
| stallets boxhall, banden | `stall-plan1-utrymning-rak` | `stall-gang-01…19` | `IMG_0249` 1–399, `IMG_0250` 1–83 | `PLAN` + `FILM` |
| stallets sidoöppning mot servicedelen | plan 1 | `stall-gang-20…22` | `IMG_0250` 84–155 | `FILM` — geometri belagd, **funktion olöst** |
| stallets entrévestibul, klubbänden | plan 1 | `stall-entre-07…14` | `IMG_0248` 1–78 | `FILM` — rak trappa syns **underifrån**, dörrpar, skylt `Stall` |
| stallets förstukvist utifrån | — | `stall-entre-01…06`, `-15`, `-16` | `IMG_0247` 1–61 | `FOTO` + `FILM` |
| mässingsplaketterna vid entrédörren | — | `stall-entre-15-dorren` | `IMG_0247` 50–61 | **finns**, men texten är `REFERENCE GAP` — oläslig i alla bildrutor |
| ridhusets långsida + yttertrappan | — | `ridhus-gavel-04-statrappan` | `IMG_0246` 30–75 | `FOTO` + `FILM` |
| ridhusets banhall | — | `ridhus-inne-01…03` | ingen film | `FOTO` |
| **stallets plan 2, invändigt** | plan 2 | inga | **ingen av de fem filmerna** | **GAP EFTER UTTÖMT BEVIS** |
| **ridhusets entréblock, invändigt** | `ridhus-entreplan-utrymning` | inga | **ingen av de fem filmerna** | **GAP EFTER UTTÖMT BEVIS** |
| **Café Krubban, invändigt** | — | `ridhus-trappan-05-cafeskylten` (utifrån) | **ingen av de fem filmerna** | **GAP EFTER UTTÖMT BEVIS** |

De tre sista är alltså kvar som `REFERENCE GAP` — men nu på rätt grund. De
sex omätta rummen i ridhusets entréblock får ingen hjälp av filmerna: ingen
film går in i ridhuset.

## Vad filmerna kan och inte kan

Filmerna är handhållna och gående. Skärpan mätt som Laplace-varians toppar
kring **83** i `IMG_0250` och **42** i `IMG_0248`; resten är rörelseoskärpa.

De duger till **topologi, förekomst och färgläge**. De duger **inte** till
mått: ingen skalstock finns i bild, och rörelseoskärpan gör kanterna
osäkra på flera pixlar. Ett mått taget ur en filmbildruta vore ett antagande
med en bild bakom sig, vilket är sämre än ett öppet antagande.

## Så körs passet om

```bash
python3 tools/videobevis.py --ut <katalog>          # 825 → 106 bildrutor
python3 tools/videobevis.py --ut <katalog> --lucka 8 # tätare täckning
```

`index.json` i utkatalogen listar film, bildrutenummer och tidsstämpel för
varje behållen bildruta. **Det indexet är beviset för vad som granskats.**
Skriptet uttalar sig aldrig om vad bildrutorna visar — det avgörs av den som
tittar, och skrivs in här.
