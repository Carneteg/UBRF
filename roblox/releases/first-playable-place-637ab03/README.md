# First Playable-place — källhead `637ab03`

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
| källhead (source SHA) | `637ab037a2758e248b52ba8b9a9e8d816e05d3c6` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `2ae44a456899d4a849f4725487a973880838b18f8a4f50a90dcb7d3ae0ecea9b` |
| storlek | 984 514 byte |
| instanser | 66 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `637ab037a2758e248b52ba8b9a9e8d816e05d3c6` |

Determinism: ombyggd ur samma källa, **byte-identisk**.

> ## TACKET SITTER PÅ HÄSTEN NU — ETT SYSTEM, INTE TVÅ
>
> Två grenar byggde var sitt utrustningssystem. De kunde inte samexistera:
> båda vaktade `GameplayService.moment`, var och en krävde sin egen
> hämtning bokförd i sitt eget tillstånd, och `iordning`-fasen blev
> ofullbordbar. Produktbeslut 1 i `docs/BESLUT-162-TACK.md`, taget vid
> accepten av `30f3d90`, pekar ut `TackForradService` som implementationen.
>
> Deras system står. Mitt är **borttaget**, inte mergat — `UtrustningRigg`,
> `UtrustningController`, `utrustning.spec`, reglerna i `Preparation`,
> hämtningen i `GameplayService`, HUD-överstyrningen och de tolv
> `utr.*`-nycklarna. Allt ligger kvar i historiken.
>
> Vad som blev bättre av bytet: tacket sitter **fysiskt på hästen** i
> tretton delar, ägarskapet är ett attribut på delen (`ForHast`) i stället
> för en tabell i serverns tillstånd, uppsittningsgrinden läser världen, och
> tygelfästena har flyttat till huvudets del enligt `HORSE-MODEL-SPEC.md`.
>
> **Dörrgrinden följde med**, och den var värd att behålla: den mäter varje
> upphängning mot de faktiskt byggda `Boxfront`- och `Boxdörr`-delarna.
> Riktad mot `TackForradService.lage()` ger den 33 gröna upphängningar.
> Deras härledning räknar ur boxens MITT — samma härledning som en gång
> hängde mitt träns i dörröppningen på alla 33 hästar. Här håller den, för
> upphängningen är en enda punkt i mitten och inte mitten ± offset. Nu mätt
> i stället för antaget, och falsifierat: flyttas den 1,5 m blir alla 33
> röda på båda halvorna.
>
> Ett fynd i deras leverans som paritetsgrinden tog: `tack.ta_utrustning`,
> `tack.utrustning_for` och `tack.hamta_forst` låg bara i Roblox-katalogen.
> `sprak.spec` mäter Roblox-sidan och var grön; `sprakgrind.mjs` mäter
> paritet och föll. De tre är speglade till webben med samma text.

> ## ⛔ DEN HÄR ERSÄTTER `…-86662d1` (`b6afc634…`) — KÖR INTE DEN
>
> Hästen färdades **med svansen före** i varje föregångare i den här
> kedjan, ridd, ledd och driven. Rotorsaken var en enda rad:
> `MovementController` rörde sig längs `(sin h, 0, cos h)` medan
> orienteringen skrevs som `CFrame.Angles(0, h, 0)`, vars `LookVector` är
> `(−sin h, 0, −cos h)` — rakt motsatt den kurs som just räknats fram.
> `LedService` bar samma inversion: kursen lästes som `ToOrientation().Y`,
> alltså den vinkel man skickar TILL `CFrame.Angles`.
>
> Blickriktningen skrivs nu direkt med `CFrame.lookAt` på samma
> `forwardVector` som rörelsen använder, i båda filerna, och svängens
> tecken är vänt vid källan så att båge, vridtakt och kroppens lutning
> vänder tillsammans. Riggen är **orörd** — den följde Roblox egen
> konvention hela tiden, med huvudet på lokalt −Z.
>
> Uppmätt i Studio på rättelsen: `TRAVEL · LOOKVECTOR = +1,0000` ridd,
> ledd (27 av 27 rörelseramar) och driven; D ger höger och A vänster i två
> körningar var. Ryttaren satt rätt redan förut — hon vette åt samma håll
> som huvudet. Det var ekipaget som helhet som gick baklänges.
>
> **Varför det nådde fem pinnade artefakter:** bänken kunde inte se det.
> `stubs.luau` kastade bort rotationen i `CFrame.Angles` och lät `__mul`
> skicka vidare `a.LookVector`, så roten rapporterade alltid `(0,0,1)` och
> `MovementController.new` läste kurs 0 i varje körning. Mätt:
> `CFrame.Angles(0, 30°, 0).LookVector` gav `(0,000, 0,000, 1,000)` där
> Roblox ger `(−0,500, 0,000, −0,866)`. Två specar mätte den felvända
> konventionen och var gröna på en häst som gick baklänges; båda är
> rättade och falsifierade.

> ### PRE_TOBIAS_PHYSICAL_GATE: PASS på den här artefaktens källa
>
> Den fysiska världsgaten kördes klar på `464d15c`, och `86662d1` —
> källheaden som byggde den här filen — **innehåller** den commiten. Alla
> fem punkter gröna: takrymning, 52 mot 49, markplansgrind, staketfysik och
> adversariell genomspelning.
>
> Den sista P0-punkten är därmed också körd: **uppsutten häst mot
> inhägnad**, tolv fall mot tre stakettyper (`tra` med syll, `tra` utan
> syll, `el`). Alla slutna sektioner höll med 0,00 m genomträngningsdjup,
> båda grindarna släppte igenom, största förflyttning mellan bildrutor
> 0,029–0,034 m (ingen pop-through), ryttaren satt kvar på 0,96 m konstant
> avstånd hela vägen. **El-staketet håller den uppsuttna hästen** — samma
> staket som en avsutten spelare kliver över.
>
> Ekipaget kördes med spelarens egen inmatning genom `Input.consume()` →
> `movement:step()`, alltså samma väg som tangenterna, inte förbi ritten.

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
| `89f4266` | `gardtest` valde fel staket — tre rader blev röda av en MER komplett värld |
| `8d564ba` | runtime-QA-listans objekträknare var stale i två artefaktbyten |
| `0c610a8` | **hästen gick baklänges** — kursen skrevs med motsatt konvention |
| `c0f9cf9` · `30f3d90` · `73ac142` | tacket fysiskt på hästen, upphängt på boxfronten, och två fel som en genomspelning hittade |
| `637ab03` | ett utrustningssystem: deras står, mitt tas bort, dörrgrinden följer med |

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

`…-b0265bb` (`f2f1d3ac…`, rätt riktning men mitt utrustningssystem),
`…-86662d1` (`b6afc634…`, komplett värld och utrustning men hästen gick
baklänges), `…-59680e4`, `…-41b829c` och `…-1e8b207` (halva, se ovan),
`…-9b5a570` (CTA:n, föll punkt 5 på RootPart), `…-efa341e` (föll § 9),
`…-67e7716` (föll § 1), `…-0a1b032`. Alla ligger kvar orörda som historik
— **ingen pinnad artefakt regenereras någonsin på plats.**

## `.gitattributes`

`*.rbxlx` är märkt binär sedan `…-1e8b207`. Har du en utcheckning med
`core.autocrlf=true`: klona om, eller kör
`git rm --cached -r . && git reset --hard` **innan** du kopierar ut filen,
annars stämmer inte SHA256.
