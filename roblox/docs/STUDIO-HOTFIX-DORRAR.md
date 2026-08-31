# Studio-kontroll — dörrarna och ankomsten

Den här kontrollen gäller **bara** hotfixen: dörrar som går att öppna och passera,
och en startpunkt nära UBRF. Den ersätter inte `STUDIO-QA.md`, som är den
kanoniska fidelity-granskningen med de elva vyerna.

**F01-acceptansen 2026-08-30 gäller inte den här ändringen.** Den kördes på
paketet från PR #26, innan fasaderna byggdes om i segment och innan dörrarna
fick runtime. Allt nedan är okvitterat tills du har kört det.

## Varför det behövs en server den här gången

Tidigare Studio-körningar räckte med att klistra in paketet. Nu gör de inte det.

Paketet bygger dörrpanelerna, lägger på attributen och sätter en `ProximityPrompt`
på var och en. Men **själva öppnandet ägs av servern** —
`roblox/src/server/WorldService.luau` — så att alla spelare ser samma dörrläge.
Klistrar du bara in paketet får du en prompt som inte gör någonting.

Därför: paketet bygger världen, Rojo ger servern, Play kör den.

## Så här kör du

### 1. Generera paketet från aktuell head

```bash
python3 tools/studio-paket.py
```

Filen hamnar i `roblox/buildings/.studio/UBRF-klistra-in.luau`. Den är avsiktligt
inte committad — generera alltid om, klistra aldrig in en gammal.

### 2. Koppla in källkoden med Rojo

```bash
rojo serve roblox/
```

I Studio: Rojo-pluginen → **Connect**. Då dyker `ServerScriptService.Horse` upp
med `WorldService`, `HorseService` och `StallService`.

`init.server.luau` startar `WorldService` **först**. Så även om något senare i
startordningen klagar är dörrarna redan igång.

### 3. Bygg världen

Klistra in **hela** `UBRF-klistra-in.luau` i Command Bar och kör den **en gång**.
Den river en tidigare modell och bygger om från grunden.

Utskriften ska innehålla de här raderna:

```
OK UBRF byggd: 8 byggnader, 12 dörrar, 4 boxrader, 6 gångytor, N objekt
[WorldBuild] Spelbar värld: 17/17 dörr-/portöppningar + UBRFSpawn
Serverkoden finns. Tryck Play — Output ska visa [World] Dorrar bundna: N
```

De fyra första talen ska stämma exakt, och dörrsiffran ska vara **17/17**.
Vänstertalet är dörrar som *blev* dörrar; högertalet är dörrar som *skulle*
bli det. Står det `14/17` hittade bygget inte tre paneler, och raderna ovanför
säger vilka. `N` i byggraden varierar och är **inget godkännandekriterium**.

Står det i stället:

```
DORRARNA KOMMER INTE ATT FUNGERA: ServerScriptService innehaller ingen WorldService.
```

då är Rojo inte inkopplat. Prompten kommer att synas och inte göra någonting.
Gå tillbaka till steg 2 och kör om paketet — allt nedan är meningslöst utan det.

### 4. Play

Vid start ska Output visa:

```
[World] Dörrar bundna: 17 — UBRFSpawn hittad
```

Siffran ska vara densamma som bygget rapporterade. Kommer raden inte alls är
servern inte inkopplad. Säger den `0`, eller färre än bygget, följer en varning
som pekar ut vilket av de två stegen som gick fel.

## Vad du ska kontrollera

### 1. Ankomsten

Du ska starta **mellan husen, strax norr om den nordligaste gaveln, vänd inåt mot
anläggningen** — inte på en Baseplate hundratals studs bort.

De 4 metrarna ut från gaveln är ett **spelval**, inte ett mätt UBRF-mått. Att det
känns för nära eller för långt är ett omdöme värt att skriva ner, men det är inte
ett fel.

### 2. En slagdörr öppnas och stängs

Gå fram till en dörr. Prompten ska säga `Öppna`. Efter tryck ska bladet **synligt
röra sig**, och prompten byta till `Stäng`.

Nio slagdörrar står i marknivå. Fyra av dem vetter mot norr och ligger alltså
närmast där du startar — börja med dem:

| Byggnad | Sida | Dörr |
|---|---|---|
| stall | N | den **ockragula** entrédörren på klubbgaveln |
| ridhus | N | en **vit** dörr, 1,8 m bred |
| ridhus | N | en smalare dörr, 1,1 m |
| `langa` | N | en **mörk** dörr, 1,1 m — den lilla byggnaden, inte stallet |

### 3. Du kan gå igenom

Det här är hela poängen med ändringen. Gå **rakt igenom** den öppnade dörren.

Det får inte finnas någon osynlig vägg kvar. Fasaden byggs numera som segment
runt öppningarna i stället för som en hel vägg med en dörrbild ovanpå — fastnar
du i hålet är det precis det felet som inte är löst.

### 4. Dörren stänger igen

Tryck `Stäng`. Bladet ska gå tillbaka till utgångsläget och prompten åter visa
`Öppna`. Efter stängning ska du **inte** kunna gå igenom.

### 5. En skjutport

Fem portar skjuter i sidled i stället för att svänga. Prova minst en, och gå
igenom den också.

| Byggnad | Sida | Port |
|---|---|---|
| ridhus | E | plåtport, 3,4 × 2,9 m |
| ridhus | E | blå port, 2,4 × 2,6 m — **hästgången** |
| ridhus | S | silverport, 4,0 × 3,6 m — den största |
| stall | W | blå port, 2,4 × 2,6 m — **hästgången**, andra sidan |
| stall | E | blå port, 3,6 × 3,2 m |

De två märkta *hästgången* är förbindelsen mellan husen. Fungerar de går det att
leda hästen inomhus mellan stall och ridhus — det är den intressanta av dem.

### 6. De elva vyerna, snabbt

Panelen **UBRF QA** öppnas av sig själv. Klicka igenom de elva vyerna en gång
till, men den här gången med **en enda fråga**: har fasadombyggnaden gjort någon
av dem sämre?

Du letar efter glipor i väggar, dubbla ytor som flimrar mot varandra, hål som
inte hör till en dörr eller ett fönster. Du bedömer **inte** om UBRF känns igen —
det är redan avgjort och står i `STUDIO-QA.md`.

## Tre dörrar som sitter i luften

Tre dörrblad sitter över marknivå och nås i verkligheten via en trappa:

| Byggnad | Sida | Höjd | Vad det är |
|---|---|---|---|
| ridhus | N | 4,02 m | cafédörren mot balkongen, utvändig ståltrappa |
| stall | N | 4,60 m | balkongdörren på klubbgaveln, spiraltrappan — rakt ovanför den gula |
| stall | S | 4,35 m | trappdörren |

De byggs som riktiga öppningar och får prompt som alla andra. Men **om du kan ta
dig upp till dem beror på om trappan är gångbar geometri i Roblox — och det är
inte något den här hotfixen rörde.** Kommer du inte fram: notera det som en
observation, inte som ett fel i dörrarna.

Når du en av dem och prompten ändå inte öppnar bladet — då är det ett fynd.

## Vad som inte är ett fynd

Att en dörr rör sig lite fort eller lite långsamt. Att ett portblad glider åt det
ena hållet i stället för det andra. Möblering, ljussättning, kosmetisk polish.
Att stallet fortfarande känns lite mörkt — det är noterat sedan F01 och ligger
kvar som polish.

## Om något är fel

**Klistra in de tre raderna först** — byggraden, `[WorldBuild]`-raden och
`[World]`-raden. Tillsammans säger de var i kedjan det gick sönder, och de tre
lägena ser olika ut:

| Vad du ser | Var felet ligger |
|---|---|
| ingen `[World]`-rad alls | servern kördes aldrig — Rojo |
| `Dörrar bundna: 0` | panelerna saknar attributen — bygget |
| `bundna` < `17/17` | bygget och servern är inte överens |
| allt stämmer, men bladet rör sig inte | då är det en riktig dörrbugg |

Skriv sedan vad du **såg** och **var** — vilken byggnad, vilken sida, vilken dörr.
Skärmdump vid visuella fel. Skriv inte gissad orsak; det öppnar en riktad fix på
fel ställe.

Vid `FEL`: `qa-dorr-<byggnad>-<sida>-FEL.png`.

## När allt är grönt

Rapportera de sex punkterna som PASS på PR:en. **Först då** går hotfixen att
merga, och först då återupptas G01. Automatiserad falsifiering är grön sedan
tidigare — den säger ingenting om det du just kontrollerade.
