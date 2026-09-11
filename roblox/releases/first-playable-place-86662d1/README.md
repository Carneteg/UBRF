# First Playable-place — källhead `86662d1`

> ## ⛔ INTE SANKTIONERAD FÖR TOBIAS
>
> Filen är **byggd och mätt**, inte godkänd. Runtime-QA i Roblox Studio är
> inte körd på den här kandidaten, och den miljö som byggde den kan inte
> köra den: ingen `robloxstudio` MCP, inget Windows-filsystem.
>
> `LATEST-FIRST-PLAYABLE.md` är därför **orörd**.

## Identitet

| | |
|---|---|
| källhead (source SHA) | `86662d173c5204ed3d63f86b7e76d0a487ce7eaa` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `b6afc634ace47186fa78ddb84ee0b11360e0b62a50026fc8d3a5e3486b845c8b` |
| storlek | 964 405 byte |
| instanser | 65 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `86662d173c5204ed3d63f86b7e76d0a487ce7eaa` |

Determinism: ombyggd ur samma källa, **byte-identisk**.

`PRE_TOBIAS_FIRST_PLAYABLE_GATE --place` mot exakt den här filen: **PASS**,
tio undergrindar. Världsmanifestet: **3375 delar** (3317 + 49 boxdörrar),
13 portaler, 33 hästar. Testsviten: **30 specar gröna**.

## PRE_TOBIAS-RUNDAN ÄR MED — fyra punkter stängda, en avgjord av Tobias

`…-59680e4` byggdes innan den fysiska världsrundan (`3711f58`, `464d15c`).
Den här bär den, och det är den största skillnaden:

| Punkt | Läge |
|---|---|
| takrymning | 94 par ur närhet → **27 verkliga hopp** (kastparabel med kollision) → **6** efter rättelserna. Rotorsaken var att INNERTAKEN inte kolliderade — det fanns aldrig ståplats på väggkrönen, men `Stalltak plåt` var genomsläppligt |
| världsrymning | tomten slutade i ett **stup**: norrut hamnade spelaren på y = −11,1 m utan mark under sig. Mark 120 m utanför åt alla håll, underst i marklistan |
| staketfysik | allt liggande virke bar `CanCollide = false` — staketen höll **ingenting**. Nu klassade efter uppgift: inhägnad spärrar, vägledande rail gör det inte |
| 52 mot 49 boxar | stängd, och modulnumren räknas nu **ur geometrin** i regressionen |
| markplansgrind | `Preflight` 2d/2e, verifierad i en riktig place |

**De två kvarvarande klätterstrukturerna är godtagna av Tobias** (beslut
19:0x): domarkurens tak och domarbåset i ridhuset, båda 2,30 m
småbyggnader inne på tomten, båda mätt terminala. De står i kända
begränsningar nedan, inte som blockerare.

## Och ledningen, sedan `…-59680e4`

`…-c5984d0` byggdes innan ledningen fungerade. Nu gör den det:
`LEADING_GAMEPLAY_GATE_PASS` (`2e246d4`), tolv hästar ledda ut ur sina
boxar och hela den kanoniska rutten stall → boxdörr → gångar → hästgången
→ ridbanan gången på 67,9 m med hästens egen Humanoid.

**Rotorsaken var inte den alla trodde.** `HorseService` sätter
`AutoRotate = false` på alla 33 hästar, och `MovementController` skriver
kursen BARA för den som sitter upp. En oriden häst hade alltså ingen som
vred henne — hon gick mot den 1,20 m breda dörren med sin 1,85 m långa
**sida före**. Vägpunkten, spåret och vägsökningen pekade rätt hela tiden;
kroppen pekade fel. Både dörr-waypointen och `PathfindingService` löste ett
problem som inte fanns.

Ledningen äger nu kursen så länge hon leds, på samma sätt som ritten:
**bara rotation, aldrig läge**. Vridtakten kommer ur kanon, och hon går dit
hon pekar med `Humanoid:Move` i stället för `MoveTo` mot punkten.

Fyra fel till hittades av mätning i samma runda: nätverksägarskapet (en
oriden häst intill en spelare ägs av den klienten, som skrev över serverns
kurs), dörrens delmål som följde det öppnade bladet 1,7 m ut i gången, två
glapp där hon stod still i dödzonen, och en fastnat-detektor som mätte
HASTIGHET — en ankrad häst rapporterade 1,59 studs/s.

## Vad den här också är — kandidaten att köra QA på

Två föregångare byggdes och avlöstes inom timmen, och båda av samma skäl:
de två grenarna arbetade parallellt ur `b31a460`, och den som byggde en
artefakt hade bara sin egen halva.

- `…-1e8b207` bar den fysiska utrustningen men **saknade
  locomotion-rättelsen** — den hade fallit på punkt 5 med exakt samma orsak
  som `9b5a570`.
- `…-41b829c` bar båda halvorna men **saknade `a3e13c5`**: 34 delar
  `Fasaddörr inifrån` stod 70–118 m fel, ute på tomma fältet, för att
  `byggRidhusInre` skickade byggnadslokala meter till en funktion som tar
  tomtkoordinater.

Den här filen är alla fyra spåren sammanslagna. Ingen av föregångarna är
rörd; de ligger kvar som historik.

| Ur | Vad |
|---|---|
| `50e5ed9` | `Humanoid.RootPart` binds — roten heter `HumanoidRootPart`, `HipHeight` = benhöjden. Det var orsaken till punkt 5-FAIL:en |
| `3ead609` | lektionskortets rubrik och punkter ur språkkatalogen, inte hårdkodad svenska |
| `27e5c2a` | boxfronten delas kring en 1,20 m boxdörr i alla 49 boxfack — hästen kan lämna sin box |
| `a3e13c5` | 34 `Fasaddörr inifrån` tillbaka i huset — de stod 70–118 m ute på fältet |
| `494b683` | sadeln och tränset som fysiska saker på boxfronten, hämtade av spelaren |
| `40c18a4` | kollisionen mellan de två: tränset hängde i boxdörrens öppning |
| `2e246d4` | ledningen: hästen vrider sig mot öppningen, nätverksägarskapet, dödzonsglappen, `led.fastnat` |
| `c6f648c` | sömmen: tränset krävs FÖRE ledningen, och `Stallet.boxdorr` |
| `3711f58` | takrymningen, staketfysiken, markplansgrinden, 52−3=49 |
| `464d15c` | tomten slutade i ett stup — mark 120 m utanför åt alla håll |
| `86662d1` | markplansgrinden: min duplikat borttagen, deras står (Terrain) |

### Sammanslagningen hade en tyst kollision, och den är rättad

Boxdörren tar fackets bortre ände. Utrustningsplatsen räknade sitt läge ur
boxens **mitt**, ±0,84 m — så den bortre punkten hamnade precis i
dörröppningen. Ett träns hängande i den enda vägen ut ur boxen, på alla 33
hästar, och ingen befintlig grind hade sagt något: de två härledningarna
läste samma datafält men räknade var för sig.

Nu räknas läget ur den **täta panelens** utbredning, och
`spelbarhet.spec` mäter varje sak mot de faktiskt byggda `Boxfront`- och
`Boxdörr`-delarna — 66 lägen. Falsifierad: med de gamla talen blir varje
träns rött.

## 52 mot 49 boxar — diagnostiserat

Runtime-QA:n rapporterade det som odiagnostiserat. `Stallet.boxantal()` är
**numreringsrymden** (4 rader × 13 platser = 52); `S.brott` skär två
passager och de facken finns inte — `hastgang` tar ett ur rad W, `ostport`
två ur rad E: 13 + 13 + 12 + 11 = **49**. `box(n)` ger `nil` för just de
tre, och har alltid gjort det.

Mätt i `spelbarhet.spec`: rutnät 52, fack 49 (W=12 MA=13 MB=13 E=11), nil 3,
**inga oförklarade** — och mätningen kräver att varje saknat nummer ligger i
en rad som ett brott faktiskt skär, så en box som försvinner av något annat
skäl går inte igenom.

## Kända begränsningar — godtagna, inte blockerare

- **Två klättringsbara småstrukturer.** Domarkurens tak (staketstolpe 1,35 m
  → gavelspets, landar 3,08 m, terminal 2,65 m) och domarbåset i ridhuset
  (sargkant 1,35 m → 3,10 m, terminal 3,25 m). Båda inne på tomten, båda
  utan fortsättning uppåt, ingen leder till ett huvudbyggnadstak eller ur
  världen. **Godtaget av Tobias.** De två åtgärder som ger faktiskt noll —
  sänkt hopp och genomsättliga staket — avvisades: den första ändrar
  rörelsekänslan (release blocker), den andra river upp staketens fysiska
  ärlighet.
- **Railen framför klubbgaveln ligger inne i stallets klubbdel** (y = 121,5)
  — miljöägarens att flytta, inte rörd här.
- **Uppsutten häst mot staket — inte testat.**
- **Grindarnas exakta lägen** i uteridbana och paddock är `[ANTAGANDE]`;
  `SITEPLAN` har frågan öppen.
- **Omgivningen utanför tomten** är ett platt grässkikt som ska ersättas.
- **Spelaren kan kliva över el-staketet** (0,70/1,05 m); hästen kan inte.
  Rimligt för ett trådstängsel mot en åker, men ett val.
- **Ridhuset är mycket mörkt inuti** — inte en gate-punkt, värt att titta på.

## Vad som fortfarande är öppet

- **Följavståndet ligger på ~4,2 m** när spelaren går. Stabilt och utan
  pendling, men en verklig handledare går vid bogen. Game feel — Tobias
  beslut, inte ändrat på eget bevåg.
- **Hästen blockerar gången.** 1,85 m kropp i en 2,64 m gång: står hon på
  tvären kommer spelaren inte förbi. Löses av att man går före henne.
- **Flera ledda hästar samtidigt är INTE testat** — kräver flera spelare.
- **Hästpopulationen är måttmässigt enhetlig**; 1,15× storlek behövde sex
  planeringsförsök mot ett, så marginalen genom 1,20 m-dörren är inte stor.
- **Takrymningen (P0-B).** 94 klätterpar mätta i runtime; 9 klasser där
  språnget från ett dörrblad eller en hylla till ett väggkrön eller takfall
  ligger innanför spelarens 2,40 m hopp. Behöver ett **produktbeslut** —
  att uppfinna barriärgeometri bryter byggnadsregeln och att sänka
  `JumpHeight` är förbjudet i ordern. Inte rörd här.
- **Baseplate-skörheten är STÄNGD** sedan `78805ae`: preflighten fäller nu
  ett främmande markplan (rad 2d) och mäter sin egen premiss (2e).
- **Staketen är visuella.** Bara stolparna kolliderar; reglarna inte. Kan
  vara avsiktligt, men är inte dokumenterat.
- **Paritet:** webben har inte den fysiska utrustningshämtningen.
- Allt i `docs/STUDIO-RUNTIME-QA.md` som var otestat i runtime är det
  fortfarande — § 6 (utrustningen) är helt ny och har aldrig körts.

## PLATSEN ÄR BOXFRONTEN, INTE SADELKAMMAREN

Ordern 16:21 pekade mot sadelkammaren. Den enda verifierade platsen i UBRF
där sadlar och träns finns är en annan:

> `references/buildings/stall/KORT.md` § Boxarna från gången:
> *"På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
> benskydd — mycket saker, tätt."* `[ej byggt i spelet ännu]`

`stall-inne-03-sadelkammaren.jpg` visar uttryckligen **inga sadelbockar**,
och `docs/F02-B-INREDNINGSMATRIS.md` har redan fällt sadlar där som
`REFERENCE GAP`. Att bygga dem i det rummet hade varit att hitta på en
UBRF-detalj — vilket ordern själv förbjuder. Sadelkammarens inredning är
orörd. Vill Tobias ha sadelkammaren krävs **ny referensevidens**, inte en
kodändring.

## Tidigare artefakter i kedjan

`…-1e8b207` (halv, se ovan), `…-9b5a570` (CTA:n, föll punkt 5 på
RootPart), `…-efa341e` (föll § 9), `…-67e7716` (föll § 1), `…-0a1b032`.
Alla ligger kvar orörda som historik.

## `.gitattributes`

`*.rbxlx` är märkt binär sedan `…-1e8b207`. Har du en utcheckning med
`core.autocrlf=true`: klona om, eller kör
`git rm --cached -r . && git reset --hard` **innan** du kopierar ut filen,
annars stämmer inte SHA256.
