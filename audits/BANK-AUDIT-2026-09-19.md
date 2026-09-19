# Bänkaudit — den döda bänkkopian och de två stubbhålen (#252 DEL A)

Datum: 2026-09-19
Bas: `main` @ `5d0741bd2cf6ee30d1af1b978cc35fe276ac024d`
Status: **`READY_FOR_CHATGPT_REVIEW`** — endast DEL A. Ingen kod i `build.py`, ingen `qa/runtime/`, ingen workflow, ingen CI-place.

> Auditen svarar på två frågor ur #252: **vilka assertions kunde aldrig bli röda**, och **vilka av FAS 1–3:s falsifieringar är därmed obevisade**. Allt nedan är läst ur git-historiken och mätt med sonder körda mot den trasiga bänken (`3acc87c^` = `9a263b2`) och mot aktuell `main`. Ingenting är runtime. Varje påstående om bänken har ett kommando bakom sig, se § 8.

## Det viktigaste först

Det fanns tre hål, och de hade tre olika skadeområden. Att blanda ihop dem ger fel slutsats om vad som är obevisat.

| Hål | Var | Skadeområde | Gjorde någon assertion grön av fel skäl? |
|---|---|---|---|
| **1. Den döda bunt-kopian** | `roblox/tests/build.py`, `FORBEREDELSE` tre gånger | 14 specar i förberedelse-/integrationsbunten, 2026-09-17 10:47 → 2026-09-18 13:30 UTC | **Nej.** Ingen av de 14 specarna rörde `TackForradService` någonsin (uppmätt, § 3.3). Hålet gjorde boxfrontsvägen *omätbar* i integrationsbänken, inte felaktigt grön. |
| **2. `typeof` ostubbad** | `roblox/tests/stubs.luau` | varje produktionsvakt `typeof(x) ~= "Instance"` tog alltid i bänken | **Ja.** Varje `GameplayService.ridaNu` i bänken svarade `false, spel.ingen_hast` (uppmätt, § 4.2). Tre assertions i `ridefirst.spec` var gröna av det skälet, och «Rida nu»-genvägens slutfas kördes aldrig i någon bänk. |
| **3. `CFrame - Vector3` ostubbad** | `roblox/tests/stubs.luau` | `LedService.placeraVidMal` rad 448/454 | **Dolt av hål 2.** Hade vakten släppt igenom hade raden kraschat i stället (uppmätt, § 5). |

**FAS 1–3:s falsifieringar är inte invaliderade av något av de tre hålen.** `tack-fas1/2/3.spec` kördes hela tiden på `KOHERENS`-bunten, som var definierad EN gång och fick `TackForradService` i samma commit som förberedelsebuntens döda kopia (`0b86f48`). Produktionsvägarna de mäter — `TackForradService`, `TackService`, `TackRigg`, `GameplayService.valjEn/sadla/transa` — innehåller ingen hård `typeof`-vakt och ingen `CFrame - Vector3`. Det som är obevisat om FAS 1–3 är det som alltid var obevisat: den fysiska gaten, som Tobias uttryckligen avstod från (`PRODUCT_ACCEPTED_WITH_QA_WAIVER` på #237, 2026-09-17 18:23 UTC) och som #246 sedan öppnade igen som hårdvarugrind.

Det som **är** obevisat i bänken, och var det hela vägen fram till #249:

1. att «Rida nu» gör hästen uppsittningsklar (ledningsmomenten och `Preparation.provaUppsittning` efter `placeraVidMal` kördes aldrig),
2. att boxfronten tänds igen när en spelare som bär sadeln lämnar (`glom → slappBuret → satSynlig`) i integrationskontext,
3. att `MountRequest`-remotens egen validering (`hast.ogiltig`) gör något alls — ingen spec går genom `OnServerInvoke` på servern,
4. och, med samma logik, allt som bara går att se i riktig motor (DEL C).

## 1. Tidslinje

| När (UTC) | Commit | Vad |
|---|---|---|
| 2026-09-11 | `12c432c` (#162 P0-3) | `FORBEREDELSE`, `INTEGRATION`, `QA` och `SIKT` blir definierade **tre gånger** i `build.py`. Kopiorna är identiska; Python låter den sista vinna. Ofarligt men dött. |
| 2026-09-17 10:47 | `0b86f48` (#235 FAS 1) | `TackForradService` läggs till i den **första** `FORBEREDELSE`-kopian (död) **och** i `KOHERENS` (levande, en definition). `tack-fas1.spec` routas till `KOHERENS`. **Hål 1 blir skadligt.** |
| 2026-09-17 | `a4f35f4`, `8b8c71d` | FAS 2 och FAS 3; `tack-fas2/3.spec` routas till `KOHERENS`. |
| 2026-09-17 17:42 | `017d53d` | PR #237 mergad med QA-undantag. |
| 2026-09-17 → 09-18 | #238, #239, #241, #242, #243 | Fem PR:er mergade med grön svit medan hål 1–3 var öppna. |
| 2026-09-18 13:19 | `9a263b2` (#246 A) | Sista commiten på den trasiga bänken (`3acc87c^`). |
| 2026-09-18 13:30 | `3acc87c` | Dubbletterna bort; `TackForradService` i den bunt som körs. **Hål 1 stängt.** |
| 2026-09-18 13:35 | `1f3157e` | `typeof` och `CFrame ± Vector3` stubbade. **Hål 2 och 3 stängda.** |
| 2026-09-18 | `b4d78f2` | QA-sekvensen (ta sadeln → led → Rida nu) körd i bänken första gången. |
| 2026-09-18 14:28 | `34c7ac2` | PR #249 mergad. |

`LedService.placeraVidMal` med sin `typeof`-vakt och `CFrame - Vector3` på rad 448/454 kom med #184-reviewens rättelse «fysisk sanning för leda, fail-closed ridaNu» (`d4527b1`, 2026-09-14). `MountRequest`-remotens handler är från `5cf5fa8` (2026-08-28) och dess `hast.ogiltig`-nej från `fa6f8cd` (2026-09-10). Hål 2 och 3 har alltså funnits sedan respektive rad skrevs; de blev *synliga* först när #246 försökte mäta QA-scenariot.

## 2. Vad bänken gör med en modul som saknas

`build.py` byter varje `require(script.Parent.X)` mot det nakna namnet `X` (`inlina()`, `REQUIRE`-regexen). Finns modulen i bunten är `X` en `local` som redan definierats högre upp i den ihopfogade filen. Finns den inte är `X` en **odefinierad global**, alltså `nil`, och ingenting säger ifrån. I `GameplayService` blev raden

```lua
local TackForradService = require(script.Parent.TackForradService)
```

till `local TackForradService = TackForradService` — en lokal som kopierar `nil` ur tomma luften. Specen startar, bygger, kör och skriver «alla gröna» så länge ingen rad råkar dereferera den. Det är hålets hela mekanik, och det är DEL B:s uppgift att stänga den.

## 3. Hål 1 — den döda kopian

### 3.1 Exakt vad som var dött

Diff mellan de tre kopiorna på `3acc87c^` (skript i § 8):

| Bunt | Kopior | Skillnad kopia 1 → kopia 2 | kopia 1 → kopia 3 |
|---|---|---|---|
| `FORBEREDELSE` | 3 | 3 rader: `TackForradService`-raden och dess två kommentarsrader saknas | samma |
| `INTEGRATION` | 3 | 0 rader | 0 rader |
| `QA` | 3 | 0 rader | 0 rader |
| `SIKT` | 3 | 0 rader | 0 rader |

Alltså: fram till `0b86f48` var dubbletterna ofarliga. Från `0b86f48` till `3acc87c` saknade den bunt som faktiskt kördes exakt en modul.

### 3.2 Vilka specar körde på den trasiga bunten

Routingen i `build.py` på `3acc87c^` ger `INTEGRATION` (= `FORBEREDELSE` + rigg) eller `FORBEREDELSE` till:

`ridefirst · statesync · ridinput · hasthojd · avsittning · tack · buren-tack · ledning · sprak-en · integration · roster · skotselpass · forberedelse · ridanu-avslag`

(`ridinput` tillkom med #241 och `ridanu-avslag` med `9a263b2`, båda inne i fönstret.)

**Inte** på den trasiga bunten: `tack-fas1`, `tack-fas2`, `tack-fas3`, `promptkonflikt`, `ledning-integration`, `varldshud` — alla på `KOHERENS`, som var definierad en gång och hade `TackForradService` från `0b86f48` och framåt (kontrollerat på `0b86f48`, `a4f35f4`, `8b8c71d` och `bfb83f0`).

### 3.3 Mätning: rörde någon av de 14 specarna modulen?

Sond: den ihopfogade specfilen på `3acc87c^` fick en `local TackForradService` överst som **skriver ut varje deref** (print, inte error — så att även en deref inuti `pcall` syns) och svarar `nil`. `GameplayService`s `local TackForradService = TackForradService` fångar den. Sedan kördes specen som vanligt.

| Spec | Assertions (OK) | FEL | Deref av `TackForradService` |
|---|---:|---:|---|
| ridefirst | 46 | 0 | ingen |
| statesync | 36 | 0 | ingen |
| ridinput | 83 | 0 | ingen |
| hasthojd | 43 | 0 | ingen |
| avsittning | 35 | 0 | ingen |
| tack | 86 | 0 | ingen |
| buren-tack | 52 | 0 | ingen |
| ledning | 95 | 0 | ingen |
| sprak-en | 21 | 0 | ingen |
| integration | 134 | 0 | ingen |
| roster | 7 | 0 | ingen |
| skotselpass | 226 | 0 | ingen |
| forberedelse | 212 | 0 | ingen |
| ridanu-avslag | 16 | 0 | ingen |
| **Summa** | **1 092** | **0** | **0** |

Skälet står i källan: de enda produktionsraderna som läser `TackForradService` är `GameplayService.valjEn` (rad 758, 792, 793, 819) och `GameplayService.slappBuret` (rad 714, inuti `pcall`). `valjEn` nås bara som callback ur `TackForradService.start(GameplayService.valjEn)`, som bara `init.server.luau` och `KOHERENS`-specarna anropar. `slappBuret` loopar över `burenAv`, som bara `valjEn` fyller. Ingen av de 14 specarna kunde nå dit.

### 3.4 Slutsats för hål 1

- **Inga assertions var gröna av fel skäl på grund av hål 1.** De 1 092 assertionerna mätte det de sade sig mäta, med en modul som aldrig behövdes för dem.
- **Det som saknades var täckning, inte sanning.** Boxfrontsvägen (`valjEn`: avstånd fail-closed, ägarregister, idempotens, `satSynlig` av/på; `glom → slappBuret`: fronten tänds igen när bäraren lämnar) var omöjlig att mäta i integrationsbänken. Den mättes i `KOHERENS` av `tack-fas1/2/3`, och därför är det där evidensen finns — inte i «hela sviten grön».
- **Det som #246 inte kunde mäta** var precis QA-sekvensen *ta sadeln på fronten → led → Rida nu* i integrationskontext; den fick sin första bänkkörning i `b4d78f2`, efter rättelsen.

### 3.5 FAS 1–3:s falsifieringar mot hål 1

| Fas | Rapporterat | Bunt | Påverkad av hål 1 |
|---|---|---|---|
| FAS 1 (`0b86f48` → `40277eb`) | 16 av 17 röda; 1 grön redovisad som onåbar gren (`40277eb`) | `KOHERENS` | **Nej** |
| FAS 2 (`a4f35f4` → `0974324`) | 18 av 20 röda; G5 parad med G5b, G6 onåbar försvarsrad | `KOHERENS` | **Nej** |
| FAS 3 (`8b8c71d` → `5e9f040`, `6b7a8bb`) | 11 av 13 röda; T10 onåbar, bevisad av T7 | `KOHERENS` | **Nej** |

Påståendet i #252 att «FAS 1–3 godkändes på den bunten» stämmer bara i betydelsen att PR #237:s *«lokal full testsuite grön»* innefattade de 14 specarna ovan. FAS-specarna själva körde med modulen på plats.

## 4. Hål 2 — `typeof` var inte stubbad

### 4.1 Var vakten sitter

Luau-CLI:t svarar `"table"` på `typeof(stubbinstans)`. Produktionen har två **hårda** vakter av formen `typeof(x) ~= "Instance" or not x:IsA(...)`:

| Rad (`3acc87c^`) | Funktion | Nås i bänken av |
|---|---|---|
| `LedService.luau:433` | `placeraVidMal` — stallets utställning av hästen i `ridaNu` | `ridefirst.spec` (6 anrop), `ridanu-avslag.spec` |
| `HorseService.luau:1284` | `MountRequest`-remotens `OnServerInvoke` | **ingen spec** — alla kallar `HorseService.tryMount` direkt; `forberedelse.spec` stubbar `InvokeServer` på klientsidan |

Fem andra vakter är skrivna **bänk-toleranta**: `typeof(x) ~= "Instance" and type(x) ~= "table"` (`GameplayService.sadla` 911, `.transa` 1033, `TackService.karaktarFor` 145, `.satPa` 203, `LedService` 694). De släpper igenom vilken tabell som helst. Det är bänken som format produktionen, och det bör DEL D ta ställning till: antingen är `type(x) ~= "table"`-halvan en försvagning som ska bort nu när `typeof` är stubbad, eller så är den avsiktlig och ska sägas rakt ut.

### 4.2 Mätning

Sond på `3acc87c^` respektive `5d0741b`, samma spec, samma modell:

| Mätning | `3acc87c^` (trasig) | `5d0741b` (main) |
|---|---|---|
| `typeof(Instance.new("Model"))` | `table` | `Instance` |
| `LedService.placeraVidMal(spelare, riktig modell)` | `false, spel.ingen_hast` | `true, nil` |
| `ridefirst.spec` block «stallets arbete», `ridaNu(sp1)` | `false, spel.ingen_hast` | `true` |
| `ridefirst.spec` block «spelaren gör första fasen», `ridaNu(sp2)` | `false, spel.ingen_hast` | `true` |
| `ridefirst.spec` block «ett andra Rida nu», andra anropet | `false, spel.ingen_hast` | `false, spel.redan_redo` |
| `ridefirst.spec` slutrad | `alla gröna` | `alla gröna` |

`ridaNuInre` (`GameplayService.luau:437–547`) kör stegfaserna med `"auto"` **före** `placeraVidMal` (rad 484–513) och ledningsmomenten plus `Preparation.provaUppsittning` **efter** (rad 532–545). I bänken avbröts varje anrop på rad 527–530. Allt efter den raden har aldrig körts i någon bänk.

### 4.3 Assertions som aldrig kunde bli röda

I `ridefirst.spec`, blocket «Ett andra «Rida nu» säger sanningen» (`3acc87c^` rad 405–463):

| Assertion | Varför den var grön | Kunde den bli röd? |
|---|---|---|
| «ett upprepat «Rida nu» svarar ALDRIG med ett utrustningsfel» | alla sex svar var `spel.ingen_hast`, som inte är ett tackfel | Bara om `placeraVidMal` släppt igenom — vilket den aldrig gjorde. Skälet den mätte var bänkens, inte produktens. |
| «och svaret är stabilt — samma skäl varje gång» | samma bänkfel sex gånger | Nej: ett fel som uppstår före all logik är alltid stabilt. |
| «upprepningarna rörde INTE förberedelsen» | ingenting hände alls | Nej: ett anrop som avbryts före ledningsmomenten kan inte röra dem. |

Specens egen not (rad 436–440) säger att «bänken kör inte hela kedjan i mål» — men anger fel skäl (att riggen taggas efter `PlayerAdded` och att `placeraVidMal` behöver en värld). Det verkliga skälet var `typeof`. Noten dokumenterade ett hål utan att veta vilket.

Assertionerna i de två tidigare blocken (omsorgsandel `0`, `0 < andel < 1`, `1,0`; dagsform; ägarskap av egna moment) var **riktiga**: de mäter state som stegfasloopen skrev före rad 527.

**Det som aldrig asserterades och aldrig kunde asserteras i bänken:** att `ridaNu` svarar `true`, att ledningsmomenten kvitteras av stallet, att hästen efter «Rida nu» är uppsittningsklar (`provaUppsittning`), och att ett andra tryck svarar `spel.redan_redo`. Ingen spec påstod det heller — men PR #237:s och #202:s leveranser byggde på att vägen fungerade. Studio-mätningen i PR #251 (på `8a3c435`, alltså med båda rättelserna) är i dag den enda evidensen för slutfasen, och den är gjord i emulator, inte på enhet.

`ridanu-avslag.spec` (`9a263b2`) mäter `provaSteg`/`provaMoment`/`utforMoment` och språkkatalogen direkt och når inte `placeraVidMal`; dess 16 assertions är opåverkade.

### 4.4 `MountRequest`-remotens vakt

Raden `if typeof(model) ~= "Instance" or not model:IsA("Model") then return false, "hast.ogiltig"` har aldrig körts i en spec. Hade någon spec gått genom `OnServerInvoke` hade **varje** uppsittning svarat `hast.ogiltig` — och det hade avslöjat hål 2 den 28 augusti. Att alla specar går direkt på `tryMount` är rätt för regelproven, men det betyder att remotens egen validering är `BANK_ONLY`-omätbar och hör hemma i DEL C:s smoke.

## 5. Hål 3 — `CFrame - Vector3`

`LedService.placeraVidMal` rad 448 och 454: `CFrame.new(mitt) * (pivot.CFrame - pivot.Position)`. Stubben saknade `__sub` på `CFrame`; Lua tog `Vector3`:ans metametod, som läser `a.X` på en CFrame. Sond på `3acc87c^`: `attempt to perform arithmetic (sub) on nil and number`. På `5d0741b`: `0`.

Eftersom hål 2 stoppade varje anrop på rad 433 nådde ingen spec rad 448. Hål 3 har alltså inte gjort någon assertion grön av fel skäl — det låg bakom hål 2 och hade blivit en krasch (röd) i samma stund hål 2 stängdes. Det är exakt vad `1f3157e` beskriver.

## 6. Mönstret, inte bara fyndet

Det här är inte första gången. Repot har sex tidigare dokumenterade bänkhål, alla upptäckta av att något annat gick fel:

| När | Commit/PR | Hål |
|---|---|---|
| 2026-08-30 | `a9ab93c` | `Enum.Material` svarade ja på vilket namn som helst; `CorrugatedMetal` fällde Studio |
| 2026-09-14 | `e666d3b` | signaler saknade `Wait`, `Players:GetPlayerFromCharacter` saknades; `integration.spec` kraschade med noll FEL-rader |
| 2026-09-14 | `067a423` | `DinHast` fanns i ingen bunt; `workspace.ChildAdded` och `GuiObject.AbsoluteSize` saknades |
| 2026-09-18 | PR #243 (M3) | dubbel nollning gjorde en mutation omöjlig att göra röd |
| 2026-09-18 | PR #245 | `Enum.TextTransform` stubbad fast egenskapen inte finns på `TextLabel`; Studio hade kastat |
| 2026-09-18 | PR #249 (E3) | en golv-assertion som aldrig band |

Gemensamt: **en krasch eller ett `nil` i bänken läser som grönt eller som ett produktfel**, aldrig som ett bänkfel. `e666d3b` säger det rakt ut: «ett krasch läste som något annat än ett hål i bänken». Det är därför DEL B (fail-closed bänk) och DEL C (riktig motor) inte är två alternativ utan två lager.

## 7. Vad som är obevisat — listan

| # | Påstående som stått som «klart» | Bevisläge i dag | Vem stänger |
|---|---|---|---|
| 1 | «Rida nu» gör hästen uppsittningsklar (ledning kvitteras, `provaUppsittning` ok, andra tryck `spel.redan_redo`) | bänk: mätt först i `b4d78f2`/PR #249 efter rättelsen; runtime: Studio-emulator i PR #251, ingen fysisk enhet | DEL C smoke + #246 hårdvarugrind |
| 2 | Boxfronten tänds igen när bäraren lämnar (`glom → slappBuret → satSynlig`) | `tack-fas1.spec` F4/R4 på `KOHERENS`; aldrig i integrationskontext (PlayerRemoving med aktiv förberedelse) | DEL C: städning efter disconnect |
| 3 | `MountRequest`-remotens validering (`hast.ogiltig`) | aldrig körd i någon spec | DEL C |
| 4 | FAS 1–3:s fysiska kedja (touch pickup, sadling, tränsning på iPhone/iPad) | uttryckligen avstådd: `PRODUCT_ACCEPTED_WITH_QA_WAIVER` (#237); #246 kräver nu fysisk iPad/iPhone | Tobias |
| 5 | Fem produktionsvakter skrivna bänk-toleranta (§ 4.1) | fungerar, men släpper igenom tabeller | DEL D-beslut |
| 6 | Allt i de 14 integrationsspecarna som *inte* går genom `placeraVidMal` | bevisat i bänk enligt sina egna assertions; oberört av hål 1–3 | — |

**Inte obevisat, och det bör sägas lika tydligt:** FAS 1–3:s 45 röda mutationer, `KOHERENS`-specarnas assertions, och de 1 092 assertionerna i tabellen § 3.3 utom de tre i § 4.3.

### 7.1 Tidigare «godkända» slutsatser som vilar på bunten

| Slutsats | Var den drogs | Vad den faktiskt vilar på | Läge |
|---|---|---|---|
| «Ett andra «Rida nu» svarar `spel.redan_redo`, aldrig ett tackfel» (#202 punkt 2) | `ridefirst.spec` + Studio-mätning på `e6a674c` | Studio-mätningen; specens tre assertions var gröna av bänkskäl (§ 4.3) | Bänkbevis först i `b4d78f2`; runtime PR #251 |
| «Rida nu → uppsittningsklar häst» (FUN FIRST `83cc802`, fail-closed i `d4527b1`; #184/#202/#237) | `ridefirst.spec`, PR #237 «lokal full testsuite grön» | ingenting i bänken: slutfasen kördes aldrig (§ 4.2) | Studio-emulator PR #251 (`8a3c435`); ingen fysisk enhet |
| PR #237 «Verification: lokal full testsuite grön» | PR-text, `CHATGPT_CODE_REVIEW_PASS` på `da56797`, `PRODUCT_ACCEPTED_WITH_QA_WAIVER` | 49 bänkar varav 13 på den trasiga bunten (§ 3.2); de mätte vad de sa (§ 3.3) men **inte** boxfronten i integrationskontext | Fysisk gate avstådd; #246 öppnade den igen |
| PR #238, #239, #241, #242, #243 «hela sviten grön» / CI grön | respektive PR | samma 14 specar; ingen av dem rör `TackForradService` (§ 3.3); #241/#243:s egna specar (`ridinput`, `klient-ridhandlingar`) går inte genom `placeraVidMal` | oberörda av hål 1–3 utom att «Rida nu»-slutfasen inte ingick i något av dem |
| #246 «jag kan inte reproducera `forb.fel_tur`» (PR #249) | bänken efter `3acc87c`/`1f3157e` | första bänkkörning av QA-sekvensen någonsin; Studio-mätning i PR #251 hittade den verkliga orsaken (raden trängdes bort) | rättad i #251; hårdvarugrind kvar |

Det gemensamma: **inget av ovanstående var falskt** i bemärkelsen att en spec ljög om ett mätvärde. Det som var falskt var *känslan av täckning* — «hela sviten grön» lästes som att «Rida nu»-vägen och boxfronten var provade, och det var de inte.

## 8. Tested — så här togs mätningarna

Arbetsträd på `3acc87c^` (`9a263b2`) och `5d0741b`, `luau` ur `/usr/local/bin`, `python3 tests/build.py`.

```text
# Kopiorna
python3: re.split(r'(?m)^FORBEREDELSE = ', build.py) → 3 kopior; difflib mellan 1↔2, 1↔3
  FORBEREDELSE: 3 rader (TackForradService + 2 kommentarsrader) · INTEGRATION/QA/SIKT: 0 rader

# Routing och SPECAR
git show 3acc87c^:roblox/tests/build.py | sed -n 630,770p
git show {0b86f48,3acc87c^,bfb83f0}:roblox/tests/kor.sh | grep '^SPECAR='
git show {0b86f48,a4f35f4,8b8c71d,bfb83f0}:roblox/tests/build.py | grep -n 'tack-fas'   → KOHERENS, 1 definition

# Sond A — bänkens sanning (spec med "integration" i namnet → INTEGRATION-bunten)
  3acc87c^:  TackForradService i bunten false · forHast → attempt to index nil
             typeof(Model) table · CFrame-Vector3 → arithmetic (sub) on nil
             placeraVidMal → false, spel.ingen_hast
  5d0741b:   true · ja · Instance · 0 · true, nil

# Sond B — ridefirst.spec med ridaNu-svaren utskrivna
  3acc87c^:  sp1 false spel.ingen_hast · sp2 false spel.ingen_hast · andra anropet false spel.ingen_hast · alla gröna
  5d0741b:   sp1 true · sp2 true · andra anropet false spel.redan_redo · alla gröna

# Sond C — fällan: local TackForradService = setmetatable({}, {__index = print-och-nil}) överst i varje byggd spec
  14 specar · 1 092 OK · 0 FEL · 0 deref
```

**Falsifiering av auditens egna påståenden:** samma tre sonder på `5d0741b` ger motsatt utfall på varje rad som hålen förklarar (tabellen § 4.2 och § 8). Om auditen hade fel om orsaken hade sonderna på `main` sett likadana ut som på `3acc87c^`.

## 9. Not tested

- **Ingen runtime.** Inget av detta är kört i Roblox-motorn. Det är DEL C.
- **Inte varje historisk head.** Fönstrets avgränsning vilar på routingtabellen på `3acc87c^` och `SPECAR` på `0b86f48`/`bfb83f0`; jag har inte kört sviten på var och en av de mellanliggande commitsen. Mekaniken är dock densamma på alla (samma tre kopior, samma routing).
- **Bänk-toleranta vakter (§ 4.1)** är identifierade, inte provade mot Roblox. Om `type(x) ~= "table"`-halvan skyddar något i riktig motor är en fråga för DEL D.

## 10. Remaining risk

- `build.py` saknar fortfarande varje skydd mot en modul som blir `nil` (DEL B). Ett nytt `require` i en modul som inte läggs i rätt bunt ger exakt samma tystnad i dag.
- Fem vakter i produktionen är formade av bänken (§ 4.1).
- Ingen bänkspec har ännu märkningen `BANK_ONLY` eller en runtime-motsvarighet (DEL D).
- Slutfasen i «Rida nu» har en enda evidens i motorn (PR #251, emulator). Ett runtime-test som inte visats kunna bli rött är samma lögn som bänken var — kravet i #252 gäller fullt ut när DEL C skrivs.
