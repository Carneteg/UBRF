# Studio-/Rojo-integritet — vad i placen är sanning

Issue #171. Det här dokumentet säger vad som äger vad i en UBRF-place, hur
drift klassas, och vad som får städas. Det är skrivet efter en **läsande**
Studio-audit av den anslutna placen `UBRF` (placeId `106030782437053`,
dataModelName `UBRF-Horse`).

Ingenting i det här dokumentet ger någon agent rätt att radera i Tobias
place. Klassa först, städa bara det som bevisats icke-kanoniskt, och aldrig
blint.

## Problemet som gav upphov till dokumentet

Rojo-träden stämde **exakt** mot repot — `HorseCore`, `Horse`, `Varld`,
klientens `Horse`, namn för namn. Ändå gick det inte att lita på ett enda
QA-resultat ur placen.

`ReplicatedStorage.UBRFBuild` var handplacerad. Modulen sa själv i sin
kommentar att den var tillfällig, och pekade på `3ead609` medan GitHub
`main` stod på `7d8fe86` — **44 commits senare**. Preflightens punkt 9 läste den och
sa PASS.

Roten var strukturell. `default.project.json` mappade ingen `UBRFBuild` alls,
så en Rojo-synkad place fick **ingen identitet**, och någon lade dit en för
hand för att få punkt 9 grön. `tools/bygg-place.py` gjorde rätt sak — men bara
för `.rbxlx`-vägen, alltså den väg som inte används dagligen.

Punkt 9 mätte dessutom bara att fältet `sha` fanns. En modul med fel innehåll
har också ett `sha`.

## Fyra klasser

Varje instans i en place hör till exakt en av dessa.

| klass | betyder | ägare |
|---|---|---|
| **kanonisk** | källstyrd, synkas ur repot | `default.project.json` |
| **runtime** | skapas av koden vid serverstart | den modul som skapar den |
| **verktyg** | plugin-/synkartefakt, `__`-prefix | verktyget som skapade den |
| **ospårad** | ingen känd källa äger den | ingen — ska utredas |

`roblox/src/server/Integritet.luau` gör klassningen. Den läser vad Rojo äger
ur den **genererade** identiteten (`UBRFBuild.rojo`), inte ur en handskriven
kopia — en andra namnlista hade blivit en andra sanning, och nästa gång någon
mappar in en modul hade grinden tyst slutat känna till den. Exakt så försvann
`UBRFSprak` ur preflighten en gång.

**Utan identitet klassas ingenting som kanoniskt.** Det är konservativt med
flit: en välvillig default var vad som höll #171 grön.

## Runtime är inte samma sak som drift

Skillnaden avgör vad som är ett riktigt fel och vad som bara är skräp i
editorn.

`TackForradService.start` **river sin mapp och bygger om den** vid varje
serverstart. En kvarglömd `Workspace.Tackförråd` är därför skräp i editorn men
självläkande i drift.

`Networking.get` gör tvärtom: den **återanvänder** det som redan ligger i
ReplicatedStorage. Ett fjärrobjekt som tagits bort ur koden eller döpts om
ligger kvar i en sparad place och följer med in i runtime, där ingen längre
vet vem som äger det.

Bara den andra sorten fäller grinden hårt. Att fälla allt hade gjort grinden
till brus, och en grind som alltid är röd slutar man läsa.

## Inventering av den granskade placen

Klassningen nedan är gjord på det som auditen faktiskt läste. Se
*Läsomfattning* längst ned för vad som **inte** granskats.

### ReplicatedStorage

| objekt | klass | not |
|---|---|---|
| `HorseCore`, `Stallet`, `UBRFKomplex`, `UBRFSkotsel`, `UBRFSpel`, `UBRFSpelData`, `UBRFSprak` | kanonisk | mappade i projektfilen |
| `UBRFBuild` | **var ospårad, nu kanonisk** | handplacerad i den granskade placen; mappas efter #171 |
| `HorseRemotes` (16 st) | runtime | `HorseCore/Networking.luau` |
| `MinHast` | runtime | `server/StallService.luau:237` |
| `UBRFPreflight` | runtime | `server/Preflight.luau` |

De 16 fjärrobjekten matchade `DEFINITIONS` namn för namn vid granskningen —
ingen drift **den dagen**. Mönstret gör ändå att drift kan uppstå tyst, och
det är det rad 10a och 10b nu mäter.

### Workspace

| objekt | klass | not |
|---|---|---|
| `Anläggning` (3 353 barn) | runtime | byggs av `Varld/Anlaggningen.luau` |
| `Tackförråd` (33 × `Utrustning …`) | runtime | rivs och byggs om vid varje start |
| `Terrain`, `Camera` | kanonisk | motorns egna |
| `SADDLE`, `Saddle`, `ew bridle` ×2, `Western Bridle` | **ospårad** | sannolika Creator Store-importer för tack-referens |
| `ThanksgivingHelmet`, `Joe's hairAccessory` | **ospårad** | avatartillbehör, inget med UBRF att göra |
| fem namnlösa `Model`, `rosto`, lös `Union` | **ospårad** | Toolbox-innehåll, se #215 nedan — `rosto` bär samma `Scene`/`LV cap` som familjen där |
| `Model` med `Lee enfield é`, `WW2`, `kll`, `ko` | **ospårad, främmande** | uppenbart orelaterat till en ridanläggning |
| `Jumps` | **ospårad** | hinder — kan vara avsett arbetsmaterial, se nedan |

### ServerStorage

Ingenting här är Rojo-mappat. Tjänsten ingår inte i projektfilen alls.

| objekt | klass | not |
|---|---|---|
| `__MCPGeneratedModels`, `__HastGranskning` | verktyg | MCP-/granskningsspår |
| `__Rojo_SessionLock` | verktyg | Rojo håller den medan `serve` kör |
| `HastVisualer` | **ospårad, men koden läser den** | `HastVisual.mall` hämtar hästarnas nätmallar här. Raderas den går varje häst tillbaka till lådor — tyst. Se omauditen nedan. |
| `UBRF_BACKUP_SUP0062` | **ospårad** | 9 barn, ogranskat innehåll |

## Städpolicy

**Grundregel: klassning är inte ett raderingsbeslut.**

1. **kanonisk** — rör aldrig för hand. Ändra källan och synka.
2. **runtime** — får tas bort i editorn när servern är stoppad. Koden bygger
   om den. Radera aldrig medan en session kör.
3. **verktyg** — lämna. Den försvinner med verktyget som skapade den.
   `__Rojo_SessionLock` får aldrig röras medan `rojo serve` kör.
4. **ospårad** — **utred, radera inte**. Ordningen är:
   1. avgör om objektet är arbetsmaterial någon avsiktligt lagt dit,
   2. om det ska behållas: flytta till `ServerStorage/Referens/` och notera
      det här, så att det slutar vara ospårat,
   3. om det ska bort: **flytta först till `ServerStorage/Karantän/`**, kör
      grinderna, och radera först när en runda visat att inget saknar det,
   4. dokumentera beslutet i den PR som gör det.

**Radera aldrig kanonisk världsgeometri eller accepterat gameplay-tillstånd**
för att få en grind grön. Läktaren, dörrarna och boxfronterna är accepterade
produkter; de faller under `docs/ACTIVE-GATE.md`, inte under städning.

### Avsiktligt ospårat tills Tobias beslutar

Följande lämnas **orört** av den här leveransen och är inte städat:

- alla Workspace-importer ovan (sadlar, träns, tillbehör, namnlösa modeller,
  `Jumps`, WW2-modellen),
- `HastVisualer` och `UBRF_BACKUP_SUP0062` i ServerStorage.

Skälet: #171 säger uttryckligen att destruktiv Studio-städning kräver
uttrycklig avgränsad evidens. Jag har klassat dem läsande. Att avgöra om
`Jumps` är arbetsmaterial för hinderbanan eller skräp är ett produktbeslut,
inte ett grindbeslut.

Grinden fäller dem heller inte i dag: rad 10c mäter bara ReplicatedStorage,
där en ospårad modul replikeras till varje klient och gör mest skada.
Workspace-roten mäts av preflightens befintliga 2d/2e (främmande markplan och
terräng), som redan är accepterade regler.

## Identiteten

`roblox/game/UBRFBuild.luau` genereras av `tools/bygg-identitet.py` och är
mappad i `default.project.json`. Både en Rojo-synkad place och en byggd
`.rbxlx` får därmed **samma** identitet.

`kallhash` är identiteten: en SHA-256 över innehållet i exakt de filer
projektfilen mappar. Den går att räkna om och jämföra exakt — alltså går den
att falsifiera.

`sha` är **upplysning, inte grind**. En committad fil kan inte känna sitt eget
commit-SHA, så fältet ligger alltid minst ett steg efter. Det var precis den
sortens påstående som gick sönder i #171, och därför gatar ingenting på det.

### Var gränsen går

| mäts av | mäter | mäter inte |
|---|---|---|
| Preflight 9a–9d (runtime) | att identiteten finns, är genererad, har rätt form | **färskhet** |
| `bygg-identitet.py --kontrollera` (CI) | att identiteten matchar källorna exakt | något i en körande place |

En place kan inte räkna om en hash över sin egen källkod — `Script.Source` går
inte att läsa i drift. Punkt 9c mäter därför **form**, inte färskhet, och
specen slår fast det i stället för att låta någon tro att den bevisar mer.
Färskheten mäts i CI mot arbetsträdet.


### När punkt 9 blir röd — tre fall, och hur de skiljs åt

Skrivet efter #188. En röd punkt 9 betyder **inte** att identiteten är fel.
Den betyder att *något led i kedjan disk → Rojo → Studio* har fastnat, och
leden ser likadana ut inifrån Studio:

| fall | var sanningen fastnat | hur det syns |
|---|---|---|
| **1 · repot** | arbetsträdet är inaktuellt | `bygg-identitet.py --kontrollera` är röd |
| **2 · Rojos VFS** | `rojo serve` serverar något annat än disken | bara mätbar på Rojos egen API |
| **3 · require-cache** | långlivad edit-VM cachar en äldre modul | `require()` ≠ `.Source` i samma VM |

Fall 3 har vi tagit fel på två gånger — #173 och #175 stängdes båda som
require-cache-artefakter efter att jag läst `require()` i stället för
`.Source`. Lärdomen därifrån gjorde nästa fel möjligt: i #188 såg det ut
som fall 3 igen, men det **var fall 2**.

**Fall 2 går inte att se inifrån Studio.** Studio kan omöjligt veta mer än
den blivit skickad, så en place som fått gammalt innehåll ser exakt ut som
en place vars cache ligger efter. Skillnaden finns bara hos servern.

### Rutinen

```
python3 tools/rojo-sanning.py          # alla filer, rad för rad
python3 tools/rojo-sanning.py --tyst   # bara avvikelser
```

Verktyget frågar den körande `rojo serve` vad den serverar för **varje**
mappad `.luau`-fil och jämför LF-normaliserat mot disken. Parningen går
genom projektträdet, inte genom filnamn: `src/server/init.server.luau` och
`src/client/init.client.luau` blir båda en instans som heter `Horse`, och
en namnmatchning hade parat fel fil med fel instans.

Läs slutraden. Den säger hur många filer som jämfördes — är den siffran
lägre än antalet mappade filer täcker mätningen inte allt, och då är punkt
9 inte klassificerad.

- **Alla lika** → fall 2 är uteslutet. Kör Studio-raderna verktyget skriver
  ut och skilj fall 3 från en instans som slutat ta emot patchar.
- **Någon olik** → fall 2. Mätningen säger att servern ligger efter, men
  **inte varför**. Kör om efter några sekunder: försvinner avvikelsen var
  det synklatens. **Består den** är servertillståndet inaktuellt — starta
  då om rätt `rojo serve`. **Aldrig en kodändring.** Att generera om en fil
  för att "få den att synka" döljer bara att servern inte levererar, och
  nästa gång är det en fil ingen kontrollerar.

  En omstart kopplar ned Rojo-pluginet, och det **återansluter inte av sig
  självt**. Mätt i #188: servern var grön 68/68 direkt efter omstarten
  medan placen stod kvar på det gamla innehållet tills någon tryckte
  Connect i Studio. Punkt 9 är alltså inte färdigmätt förrän pluginet är
  uppkopplat igen.

Verktyget är **ingen CI-grind** och ska inte bli en. Det kräver en körande
lokal server; på en byggagent finns ingen, och en grind som alltid är röd
där hade lärt alla att ignorera den. CI:s motsvarighet är
`bygg-identitet.py --kontrollera`, som mäter fall 1.

### Vad som mättes i #188

Samma place, samma server (`sessionId 74a1f363…`, `UBRF-Horse`, Rojo 7.7.0,
port 34872, en enda lyssnande process):

| lager | `kallhash` | `genererad` |
|---|---|---|
| disk, main `df60d31` | `4437b24e…` | 13:15:45Z |
| `rojo serve` | `45c0effe…` | 10:41:04Z |
| `.Source` i placen | `45c0effe…` | 10:41:04Z |
| `require()`, färsk play-VM | `45c0effe…` | 10:41:04Z |
| `require()`, långlivad edit-VM | `2b7fd064…` | 07:29:14Z |

Placen speglade alltså servern exakt — Studio gjorde inget fel. Servern
hade fastnat på 10:41, och en ny skrivning till filen (13:15 → 14:01) fick
den inte att läsa om.

**Det drabbade en sökväg, inte bevakningen.** Samtidigt var 67 andra
mappade filer identiska, och en mutation av
`src/shared/HorseCore/Gaits.luau` synkades av servern inom sekunder. Just
den här incidenten klassificerades därför som en **tappad
filbevakningshändelse** för `roblox/game/UBRFBuild.luau` — avvikelsen
bestod över en riktig bytediff — och inte som en död watcher. Den
slutsatsen hör till incidenten; verktyget drar den inte generellt, se
`Rutinen` ovan.

**Åtgärden verifierad:** `rojo serve` startades om (ny PID, samma port
34872, samma projektfil) och verktyget gick från `67 lika · 1 olika` till
`68 lika · 0 olika · 0 oparade` på första körningen efteråt.

Falsifiering: sattes diskens innehåll till exakt det servern serverade blev
verktyget grönt (68 av 68). Riktningen "ser den en annan fil än
UBRFBuild?" gick **inte** att mäta med servern igång — Rojo hann synka
mutationen innan mätningen — och redovisas som ej falsifierad. Täckningen
mäts i stället av att slutraden räknar alla 68 mappade filer.

## Krav på den som kör Rojo

**En körande `rojo serve` läser projektfilens träd vid start.** Mätt i den här
sessionen: Rojo startade 08:38:17, mappningen av `UBRFBuild` skrevs 09:06:57,
och den levande placen visade fortfarande den handplacerade modulen efteråt.

Därför: **starta om `rojo serve`** efter att den här grenen är utcheckad.
Innan det har den levande placen kvar sin gamla identitet och punkt 9 mäter
fortfarande fel.

Det steget är Tobias, inte en agents — en omstart byter innehållet i hans
öppna place.

## Läsomfattning för inventeringen

Auditen som ligger till grund för tabellerna ovan läste:

- `game.ReplicatedStorage`, `game.ServerScriptService`, `game.StarterPlayer`
  till djup 4,
- `game.Workspace` till djup 1,
- `game.ServerStorage` **endast toppnivå**.

**Inte läst:** innehållet i `Anläggning.UBRF` (3 353 barn), i
`UBRF_BACKUP_SUP0062` (9 barn), i `__HastGranskning` (6 barn) eller i
`HastVisualer` (1 barn). Klassningen av de fyra vilar på deras namn och
placering, inte på deras innehåll.


## Omaudit 2026-09-16 — vad som fortfarande reproducerar

Ordern i #171 var uttrycklig: mät om det NUVARANDE läget, anta inte att de
gamla fynden står kvar, och dokumentera det som redan är löst med evidens i
stället för att bygga om det.

Mätt på `main` `a5a4b71` i den anslutna placen, och sedan om på den här
grenens head.

### Löst sedan dokumentet skrevs

**Identiteten är inte längre handplacerad.** `ReplicatedStorage.UBRFBuild`
i placen bär samma `kallhash` som `tools/bygg-identitet.py` räknar ur
arbetsträdet, och `lage = "rojo"`. Punkt 9a–9d är gröna av rätt skäl, inte
av en välvillig default. Fyndet byggs alltså inte om; det redovisas som
åtgärdat.

**Fjärrobjekten är rena.** 10a och 10b gröna: varje objekt i `HorseRemotes`
finns i `Networking.definitioner()` och har rätt klass.

### Kvarstod, och var osynligt för grinden

Grinden tittade bara i `ReplicatedStorage`. Den sa alltså ingenting om
`ServerScriptService`, `Workspace` eller `ServerStorage` — och en grön
preflight gick att läsa som "placen är ren" medan sjutton objekt ingen källa
äger låg kvar, `UBRF_BACKUP_SUP0062` med 3 477 ättlingar bland dem.

Därför: **10d fäller** ospårat i `ServerScriptService` (det är den andra
tjänsten där ospårad kod faktiskt *kör*), och **10e rapporterar utan att
fälla** för `Workspace` och `ServerStorage`. Att fälla på dem hade gjort
grinden permanent röd tills någon städar, och en grind som alltid är röd
slutar man läsa.

### En place kan inte verifiera sin egen källkod

Det här är omauditens viktigaste fynd, och det begränsar vad punkt 9 någonsin
kan bli.

`kallhash` är det riktiga beviset, och placen bär källorna i
`ModuleScript.Source`. Men **ett spelskript får inte läsa `Source`.** Uppmätt
i en levande server-VM:

```
ServerScriptService.Horse.Integritet:247 function kallbytes
The current thread cannot read 'Source' (lacking capability PluginOrOpenCloud)
```

Ett första försök summerade just `#Source` över de Rojo-ägda träden. Talet
stämde — 1 234 328 tecken i både repo och place — men det var mätt från
**edit**-kontexten, där ett plugin får läsa. I runtime, alltså exakt där
preflighten kör, går det inte alls.

Slutsatsen är strukturell och står kvar i modulen: **hashförsvaret måste bo
utanför placen.** `bygg-identitet.py --kontrollera` i CI räknar om den på
riktigt; `rojo-sanning.py` täcker fall 2. Det placen själv kan göra är att
räkna INSTANSER, och det är vad punkt 9e gör.

### Punkt 9e — vad den kan och inte kan

9e räknar Rojo-ägda skriptobjekt i placen och jämför mot identitetens
`kallor`. `IsA` och `GetDescendants` kräver ingen läsrätt på källan.

Den fångar **tillagda och borttagna källor**, och en place som synkats från
ett annat projektträd. Den fångar **inte** en fil som redigerats utan att
läggas till eller tas bort. Det står utskrivet i modulen och upprepas här,
för att ingen ska läsa ett grönt 9e som "placen kör exakt den här koden".

**Räkningen går på `kallrotter`, inte på `rojo`.** Identiteten bär sedan den
här grenen båda: `rojo` är den grova toppnivålistan klassningen behöver,
`kallrotter` är varje `$path` i projektfilen med sin fulla instansväg.

Skälet mättes fram. `StarterPlayerScripts` är en behållare Rojo **delar med
motorn**: vid speltest lägger Roblox sina egna `RbxCharacterSounds` och
`AtomicBinding` där. Med den grova listan blev raden röd i en levande
server-VM — **69 mot identitetens 67** — utan att något var fel. Med
`kallrotter`: 67 mot 67.

### Serverns egna objekt i Workspace är runtime, inte drift

`RUNTIME` slår upp på namn. Workspace fylls dessutom av objekt vars namn
kommer ur speldata eller ur spelaren, och namnuppslag kan aldrig nå dem.

Mätt i en levande server-VM innan reglerna fanns: 10e namngav **49** ospårade
objekt i Workspace. 34 av dem var serverns egna — 33 hästar, en spelarkaraktär
och en uppsättning boxmarkörer.

`RUNTIMEREGLER` prövar därför ett villkor per objekt, och varje regel pekar
ut den rad som bevisligen skapar det:

| regel | källa |
|---|---|
| taggen `Horse` | `server/HastRigg.luau`, `server/HastVisual.luau` |
| namnprefixet `Boxmarkor_` | `server/StallService.luau:62` |
| `Players:GetPlayerFromCharacter` | spelarens egen karaktär |

Reglerna är **avsiktligt svaga mot förfalskning** — en främmande modell som
taggar sig `Horse` läses som runtime. Det är acceptabelt just för att 10e
rapporterar och aldrig fäller. Skulle en fällande rad någon gång vilja
använda dem måste de prövas om.

Efteråt, samma VM: **14 i Workspace, 2 i ServerStorage.** Edit-läget visar
15 i Workspace; skillnaden är `Joe's hairAccessory`, som karaktären plockar
upp vid speltest.

### Ospårat betyder inte umbärligt

`ServerStorage.HastVisualer` är ospårad — ingen Rojo-väg pekar på den — och
samtidigt läser `HastVisual.mall` den vid **varje** hästbygge. Utan mallen
faller inte spelet; varje häst går tillbaka till lådor, tyst.

Raden skrev tidigare ut den sida vid sida med en 3 477 objekt stor backup
ingen rör, som om det vore samma sak. 10e märker den nu:

```
ServerStorage 2: HastVisualer (KRÄVS AV server/HastVisual.luau:37 — mallarna
för hästarnas nät), UBRF_BACKUP_SUP0062
```

Ett namn får bara stå i den tabellen med en rad i koden bakom sig.

### Require-cachen i edit-VM:en, igen

Fall 3 i tabellen ovan reproducerades under arbetet och ska nämnas, eftersom
det kostade tid: modulens källa i placen innehöll `function
Integritet.kallbytes`, medan `require()` i samma edit-VM returnerade en
tabell **utan** den nyckeln. Läs `.Source`, inte `require()`, när frågan är
vad placen faktiskt bär.

### Vad som INTE gjordes

Ingenting raderades. Ingen geometri rördes. Klassningen är läsande, precis
som städpolicyn ovan kräver, och vad som ska bort är Tobias beslut.


## #215 — de sju objekten som dök upp under utrustningsauditen

Mätt 2026-09-16 på `main` `bd70f1097acbe5786f10accd201e60e57583fd0a`.
Preflighten före och efter: **38 mätningar, 0 röda**.

`Workspace` gick från **19** toppnivåbarn till **26** under passet i #165.
Frågan var vem som lagt dit dem, och svaret är mätt, inte gissat.

### Vad de är

Nio objekt i placen tillhör en och samma familj av fria Toolbox-modeller:
`LV cap` ×3 (lösa `MeshPart`), `Scene` ×2 och fyra `Model` som innehåller
`Scene`/`PERSONAGEM`-delar. Två Creator Store-listningar matchar dem
**strukturellt exakt**:

```
135146153534189  "CAP QUE O OTARIO ACHO QUE EU COPIEI DELE"
                 -> en MeshPart som heter LV cap

98854808330375   "Scene"
                 -> Scene/{PERSONAGEM.002, PERSONAGEM.003, PERSONAGEM.171, LV cap}
```

Den andra är instans för instans samma träd som `Workspace.Scene` i placen.

De hänger **4–5 m över gräset** (13–15 studs mätt med raycast), är ankrade och
kolliderande, och ligger staplade på varandra kring `tomt(99, 155)` och
`tomt(99–104, 176–204)`. Den nedersta i en av staplarna är
`Workspace.rosto.Scene.LV cap` — alltså **samma familj som redan fanns i
placen före sessionen**, och på samma plats. Det ser ut som upprepade
Toolbox-införanden vid samma kameraläge, vid olika tillfällen.

### Vad de INTE är

De kommer inte från agentens verktygskedja. Det är mätt, en gång per verktyg,
med räkning av `Workspace`-barn före och efter:

| verktyg | resultat |
|---|---|
| `search_assets` (sökning) | 26 → 26 |
| `preview_asset` (förhandsgranskning) | 26 → 26 |
| `insert_asset` till `ServerStorage` | 26 → 26 |
| klon till en `Workspace`-mapp och `Destroy` av mappen | 26 → 27 → 26 |

Sista raden är hela sekvensen från #165:s tredje pass, återspelad: den lämnar
ingenting efter sig. Kandidaterna som auditerades hette dessutom `Horse
saddle`, `Sadles`, `helmet` och `halter` — inget av de nio heter något av det,
och alla fyra är borttagna.

### Vad som INTE går att fastställa

**Vilka av de nio som är nya.** Baslinjen på 19 registrerade bara *namn*, och
den innehöll redan fem `Model`. Fyra av dagens sju `Model` tillhör
`PERSONAGEM`-familjen, vilket betyder att minst en fanns där före — men
instanser bär inga tidsstämplar, så den exakta uppdelningen går inte att mäta
i efterhand. Nettot `+7` är säkert; fördelningen inuti är det inte.

**Om de ligger i den sparade placen.** De finns i edit-datamodellen och
överlever en play-cykel (mätt: 26 barn före, 26 efter start och stopp). Om de
är sparade till disk går inte att läsa härifrån.

### Klassning och beslut

`Integritet.klassificera` säger `ospårad`, och punkt 10e listar dem — nu 21
namn i `Workspace`. **Grinden gjorde exakt det den ska**: den var tyst om
sådant här före #209, och det var därför driften kunde växa oupptäckt. Att
frågan över huvud taget ställdes är radens förtjänst.

**Ingenting är raderat.** #171:s regel gäller: klassa först, radera bara det
som bevisats icke-kanoniskt, och aldrig blint. Provenienssen är nu bevisad
(fritt Toolbox-innehåll utan koppling till UBRF), men **städning kräver ett
eget uttryckligt beslut från Tobias** — det här dokumentet auktoriserar inget.

Om beslutet blir städning gäller städpolicyn ovan: karantän först, kör
grinderna, radera sist.

### Inställningen för tredjepartsassets

Slagen PÅ av Tobias 17:19 för #165:s tredje pass, och **AV igen** när auditen
var klar. Båda lägena är verifierade funktionellt på samma asset:

```
PÅ   insert_asset 18632903662 -> success
AV   insert_asset 18632903662 -> "User is not authorized to access Asset"
```
