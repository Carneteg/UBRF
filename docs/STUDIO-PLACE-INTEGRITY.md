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
kommentar att den var tillfällig, och pekade på `3ead609` medan repots HEAD
stod på `78b7af8` — **53 commits senare**. Preflightens punkt 9 läste den och
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
| fem namnlösa `Model`, `rosto`, lös `Union` | **ospårad** | okänt ursprung |
| `Model` med `Lee enfield é`, `WW2`, `kll`, `ko` | **ospårad, främmande** | uppenbart orelaterat till en ridanläggning |
| `Jumps` | **ospårad** | hinder — kan vara avsett arbetsmaterial, se nedan |

### ServerStorage

Ingenting här är Rojo-mappat. Tjänsten ingår inte i projektfilen alls.

| objekt | klass | not |
|---|---|---|
| `__MCPGeneratedModels`, `__HastGranskning` | verktyg | MCP-/granskningsspår |
| `__Rojo_SessionLock` | verktyg | Rojo håller den medan `serve` kör |
| `HastVisualer` | **ospårad** | 1 barn, ogranskat innehåll |
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
