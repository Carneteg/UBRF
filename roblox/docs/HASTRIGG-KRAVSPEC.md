# Kravspec för hästriggen — issue #31

Det här dokumentet stänger issue #31:s *underlag*. Det stänger inte issue #31.
Issue #31 stängs av en riggad modell som importerar och rider, ingenting annat.

## Vad det här dokumentet är, och vad det inte är

`HORSE-MODEL-SPEC.md` finns redan och är kontraktet mellan modellen och koden.
Den beskriver hierarki, kollision, attachments och skelett, och den beskriver dem
bra. **Den här kravspecen skriver inte om den.**

Det som saknades var något annat: en artist som ska bygga eller köpa riggen kan
inte ta ett enda beslut ur `HORSE-MODEL-SPEC.md` utan att först ha svaret på tre
frågor som inte står där.

1. **Hur stor är en häst i det här spelet?** Specen anger `6 × 4 × 2,5` studs för
   ett varmblod men aldrig omräkningen mellan meter och studs. Utan den kan
   modellen inte skalas i Blender, och specen säger själv att skalning måste ske
   i Blender och inte i Studio.
2. **Hur långa ska klippen vara?** Specen anger normtempo i m/s. Ett klipp mäts
   i sekunder. Omvandlingen står ingenstans, och den är inte uppenbar.
3. **Vad får riggen kosta i trianglar och ben?** Roblox har hårda gränser. De
   stod inte i specen.

Alla tre svar går att räkna fram ur koden som redan finns. Det är gjort nedan,
och siffrorna är kontrollerade mot koden och mot Roblox' egen dokumentation.

---

# 1. Skalan — den siffra allt annat hänger på

```
1 meter = 3,0 studs
```

Källa: `Config.STUDS_PER_METRE = 3.0` i `roblox/src/shared/HorseCore/Config.luau`,
och `roblox/buildings/BuildKit.luau` som bygger hela anläggningen på samma
konstant. Spellogiken räknar i meter, Roblox i studs, och omräkningen sker på ett
enda ställe.

**Detta är ett projektbeslut, inte en Roblox-standard.** Roblox anger ingen
omräkning mellan studs och meter i sin egen dokumentation
([Roblox: Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)).
Den allmänt använda konventionen i Roblox-världen är ungefär 3,57 studs per meter,
räknat ur avatarens höjd.

Det har en direkt konsekvens som måste stå i klartext:

> **En köpt modell som är skalad efter Roblox' avatarproportioner blir cirka
> 19 % för stor för UBRF:s värld.** Den ska skalas om till 3,0 studs per meter
> innan den importeras, och skalningen ska göras i källfilen.

Skalas den i Studio i stället skalas benen separat, och tygelfästena hamnar fel.
Det står redan i `HORSE-MODEL-SPEC.md` och gäller.

## Måtten per ras, räknade ur rastabellen

`Config.BREEDS` anger `Height` i meter för varje ras — det är mankhöjden.
`HORSE-MODEL-SPEC.md` anger en `BodyCollider` på cirka `6 × 4 × 2,5` studs för ett
varmblod. Varmblodets mankhöjd är 1,66 m, alltså 4,98 studs. Ur de två uppgifterna
faller proportionerna ut:

```
längd  = mankhöjd × 1,20
djup   = mankhöjd × 0,80
bredd  = mankhöjd × 0,50
```

Regeln reproducerar specens egna `5,98 × 3,98 × 2,49` för varmblod. Den är alltså
inte påhittad ovanpå specen utan utläst ur den.

| ras | mankhöjd (m) | mankhöjd (studs) | `BodyCollider` L × D × B (studs) | `HipHeight` (studs) |
|---|---|---|---|---|
| Shetland | 1,02 | 3,06 | 3,67 × 2,45 × 1,53 | 1,84 |
| Icelandic | 1,38 | 4,14 | 4,97 × 3,31 × 2,07 | 2,48 |
| Mustang | 1,50 | 4,50 | 5,40 × 3,60 × 2,25 | 2,70 |
| Arabian | 1,52 | 4,56 | 5,47 × 3,65 × 2,28 | 2,74 |
| QuarterHorse | 1,52 | 4,56 | 5,47 × 3,65 × 2,28 | 2,74 |
| Andalusian | 1,60 | 4,80 | 5,76 × 3,84 × 2,40 | 2,88 |
| Thoroughbred | 1,63 | 4,89 | 5,87 × 3,91 × 2,44 | 2,93 |
| Friesian | 1,65 | 4,95 | 5,94 × 3,96 × 2,47 | 2,97 |
| Warmblood | 1,66 | 4,98 | 5,98 × 3,98 × 2,49 | 2,99 |

`HipHeight` är räknad som `mankhöjd − djup/2`, precis som `HORSE-MODEL-SPEC.md`
föreskriver.

## Ett fel som den fasta collidern döljer

`HORSE-MODEL-SPEC.md` ger **en** collider-storlek, `6 × 4 × 2,5`, utan att säga
att den gäller ett varmblod.

En Shetlandsponny är 1,02 m i mankhöjd, alltså 3,06 studs. **En collider som är
4 studs djup är högre än ponnyn är hög.** Sätts specens siffra på en Shetland blir
`HipHeight` 1,06 studs, ponnyn står till knäna i marken eller svävar, och ingen
justering i Studio rättar det snyggt.

Collidern **måste** skala med rasens `Height`. Tabellen ovan är den skalningen.
Detta är inte en teoretisk invändning: `Config.BREEDS` har redan nio raser med
mankhöjder från 1,02 till 1,66 m, och `UBRFSpel.hastar` binder verkliga hästar
till dem.

---

# 2. Klipplängderna — räknade, inte gissade

Det här är den del artisten inte kan härleda själv, och den som avgör om hovarna
glider.

## Hur koden driver en gångart

`Gaits.cycleLength(gångart)` returnerar `norm / cycles`, alltså **hur många meter
hästen förflyttar sig på en hel rörelsecykel**. `MovementController` rad 233 låter
fasen följa marken: fasen ökar med tillryggalagd sträcka delad med cykellängden.

Ett klipp ska därför innehålla **exakt en hel rörelsecykel** — inte två, inte en
och en halv. Klippets längd vid normtempo blir då:

```
klipplängd i sekunder = cykellängd / norm = 1 / cycles
```

| gångart | norm (m/s) | cykellängd (m) | klipplängd (s) | rutor @ 30 fps | rutor @ 60 fps |
|---|---|---|---|---|---|
| Skritt | 1,45 | 1,450 | 1,0000 | 30,00 | 60,00 |
| Trav | 3,20 | 2,133 | 0,6667 | 20,00 | 40,00 |
| Galopp | 5,60 | 3,200 | 0,5714 | 17,14 | 34,29 |
| Fyrsprång | 8,60 | 4,195 | 0,4878 | 14,63 | 29,27 |

## Galopp och fyrsprång går inte i heltal, och det ska hanteras i data

Skritt och trav landar på jämna rutantal. Galopp och fyrsprång gör det inte, i
varken 30 eller 60 fps. Ett klipp kan inte vara 34,29 rutor långt.

**Producera i 60 fps, avrunda till heltal, och rätta `cycles` till det klippet
faktiskt är.** `HORSE-MODEL-SPEC.md` säger redan att det ena eller det andra ska
göras, inte varken eller. Här är vilket:

| gångart | rutor @ 60 fps | `cycles` ska sättas till | avvikelse mot dagens värde |
|---|---|---|---|
| Skritt | 60 | 1,0000 | ±0,00 % |
| Trav | 40 | 1,5000 | ±0,00 % |
| Galopp | **34** | **1,7647** | +0,84 % |
| Fyrsprång | **29** | **2,0690** | +0,93 % |

Under en procent. Det är inte kännbart, och det är exakt, vilket är bättre än
nästan rätt och odokumenterat.

30 fps duger inte: fyrsprånget skulle behöva 14,63 rutor, och närmaste heltal ger
2,4 % respektive 4,5 % fel.

## Hovnedslagen i klippet

`Gaits.beatRate` ger `cycles × steps × (fart / norm)` hovnedslag per sekund, och
`steps` är nedslag per cykel: skritt fyra, trav två, galopp tre, fyrsprång fyra.
Hovkontakt i klippet ska ligga jämnt fördelad över cykeln på de fraktionerna, för
det är där ljudet och dammet utlöses.

| gångart | nedslag per cykel | hovkontakt vid fas |
|---|---|---|
| Skritt | 4 | 0,00 · 0,25 · 0,50 · 0,75 |
| Trav | 2 | 0,00 · 0,50 |
| Galopp | 3 | 0,00 · 0,33 · 0,67 |
| Fyrsprång | 4 | 0,00 · 0,25 · 0,50 · 0,75 |

Fasindelningen är jämn därför att `SoundController` och `EffectsController` läser
`math.floor(loco.phase × beats)` och utlöser vid varje heltalssteg. Det är inte en
åsikt om hästanatomi utan vad koden gör. En biomekaniskt riktig galopp har ojämnt
fördelade nedslag; vill vi ha det ska koden ändras först, och då är det en egen
issue.

---

# 3. Det största fyndet: hovljudet och hovarna har olika klockor

Det här är inte en artistanvisning. Det är ett arkitekturfel som gör
acceptanskriteriet *"animation timing must match the movement norms closely enough
to prevent obvious hoof sliding"* omöjligt att uppfylla i delar av tempobandet,
hur bra klippen än är.

**Fasen är distanslåst. Animationen är klocklåst.**

| konsument | drivs av | var |
|---|---|---|
| hovljud | `loco.phase`, distanslåst | `SoundController.luau` rad 74 |
| hovdamm | `loco.phase`, distanslåst | `EffectsController.luau` rad 50 |
| **animationen** | `track:AdjustSpeed(Gaits.playbackRate(...))`, klocklåst | `AnimationController.luau` rad 130 |

`Gaits.playbackRate` klampar kvoten `fart / norm` till `[0,72 ; 1,32]`. Utanför
klampen fortsätter fasen följa marken medan animationen är fartbegränsad. Då
glider hovarna, **och hovljudet spelas ur takt med den synliga hovkontakten.**

## Var klampen slår, räknat på gångarternas egna band

| gångart | band (m/s) | kvot vid min | kvot vid max | klampar |
|---|---|---|---|---|
| Skritt | 0,90 – 2,00 | **0,621** | **1,379** | **både min och max** |
| Trav | 2,40 – 4,30 | 0,750 | **1,344** | **max** |
| Galopp | 4,60 – 7,00 | 0,821 | 1,250 | nej |
| Fyrsprång | 7,20 – 11,00 | 0,837 | 1,279 | nej |

**Skritt klampar i båda ändar av sitt eget band.** Långsam skritt är det tempo
spelaren rider i mest, i stallgången och på uppvärmningen, och det är det tempo
där felet är störst: 0,621 mot golvet 0,72 är 16 % fel.

Trav klampar i övre delen av bandet, 1,344 mot taket 1,32.

Galopp och fyrsprång är rena. Felet finns alltså i de två gångarter en nybörjare
använder, och inte i de två som ser mest imponerande ut.

## Två vägar, och jag rekommenderar den ena

**Väg A — driv animationen på fasen.** Sätt `AnimationTrack.TimePosition` från
`loco.phase × klipplängd` i stället för att justera uppspelningshastigheten. Då
blir hovglidning **strukturellt omöjlig** vid varje tempo, och hovljudet matchar
den synliga hovkontakten automatiskt, för båda läser samma fas.

**Väg B — vidga klampen till `[0,60 ; 1,40]`.** En rad. Men den botar bara
symtomet i dagens band; nästa gång ett band justeras kommer felet tillbaka, och
ljudet och bilden har fortfarande olika klockor.

Jag rekommenderar **väg A**, och den bör vara en egen issue som blockerar
acceptans av issue #31:s punkt om hovglidning — inte en ändring som smygs in i en
tillgångs-PR.

Notera också att `HORSE-MODEL-SPEC.md` skriver att klampen är **±30 %**. Koden
klampar `[0,72 ; 1,32]`, alltså −28 % och +32 %. Dokumentationen är avrundad åt
fel håll i nedre änden. Liten sak, men specen är ett kontrakt.

---

# 4. `stride`-fältet är död data som beskrivs som levande

`Gaits.BY_NAME` har ett `stride`-fält per gångart, och kommentaren i filen säger:

> `stride`-fältet är enskild steglängd och används av animationslagret

**Fältet läses inte någonstans i kodbasen.** Kontrollerat med sökning över alla
`.luau`-filer: `stride` förekommer bara i sin egen typdeklaration, sina egna
värden och den kommentar som påstår att det används.

Värre: värdena stämmer inte med det de utger sig för att vara. Cykellängd delad
med antal nedslag ger steglängden, och den jämförelsen ser ut så här:

| gångart | cykel / nedslag (m) | `stride`-fältet | avvikelse |
|---|---|---|---|
| Skritt | 0,362 | 0,46 | +27 % |
| Trav | 1,067 | 0,63 | −41 % |
| Galopp | 1,067 | 1,00 | −6 % |
| Fyrsprång | 1,049 | 1,28 | +22 % |

**En artist som läser kommentaren och lägger hovavtrycken på 0,63 m i trav bygger
in 41 % glidning från början.** Det är precis det acceptanskriteriet förbjuder, och
det står inbjudande i en fil som annars är noggrann.

Åtgärd: antingen tas fältet bort, eller så räknas det om till `cycleLength / steps`
och får en verklig konsument. Tills det är avgjort ska **ingen artist använda
`stride` till någonting.** Cykellängden i § 2 är det bindande måttet.

---

# 5. Roblox' hårda gränser

Verifierade mot Roblox' egen dokumentation, inte mot minnet.

| gräns | värde | källa |
|---|---|---|
| trianglar per enskilt nät | **20 000** | [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| ben som får påverka en vertex | **4** | [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| benens skala i källfilen | måste vara `1, 1, 1` | [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| benens rotation i källfilen | måste vara `0, 0, 0` | [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| rotbenets position | måste vara `0, 0, 0` | [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| texturupplösning för Marketplace-tillgångar | högst **2048 × 2048** | [Character specifications](https://create.roblox.com/docs/art/characters/specifications) |

Ingen maxgräns för antal ben per nät anges i den dokumentationen. Skelettet i
`HORSE-MODEL-SPEC.md` har 29 ben inklusive rotbenet — 28 plus `Root` — och därtill
de frivilliga `LeftEar` och `RightEar`. Det är långt under vad som brukar bli ett
problem, men jag har inte hittat en publicerad gräns att stödja det på. **Om
antalet ben blir ett hinder kommer det att visa sig vid import, inte i det här
dokumentet.**

## UBRF:s egen trianglabudget, snävare än Roblox' gräns

20 000 trianglar är taket för **ett** nät. Ridhuset kan innehålla tolv hästar
samtidigt i en lektion, plus ryttare, plus byggnaden. Budgeten sätts därför lägre:

| del | trianglar | motivering |
|---|---|---|
| `HorseMesh` inklusive huvud och ben | **högst 6 000** | tolv hästar = 72 000, hanterbart på skolchromebook |
| `Mane` + `Tail` | högst 1 500 tillsammans | man och svans är två plana kort med genomsiktlig textur, inte volym |
| `Tack` (sadel, träns, stigbyglar) | högst 1 200 | syns bara ovanifrån under ritt |
| **summa per häst** | **högst 8 700** | |

Siffrorna är en budget jag sätter, inte en Roblox-gräns. **Målgruppen är barn som
lär sig om hästar, och de sitter ofta på skolans utrustning.** En häst som är
vacker på en speldator och rycker på en chromebook är fel häst. Underkänn hellre
en modell på trianglar än att optimera efter lansering.

---

# 6. Blender till Roblox — fällan med +Z

`HORSE-MODEL-SPEC.md` säger att rotbenet ska peka framåt längs **+Z**. Roblox'
dokumentation säger att rotbenets rotation ska vara **`0, 0, 0`**. De två kraven
tillsammans betyder något som är lätt att missa:

Blender har **−Y** som framåt och **+Z** som uppåt. Roblox har **+Z** som framåt
och **+Y** som uppåt. Det finns alltså inget sätt att både ha rotationen `0,0,0`
och peka rätt utan att hantera axelbytet vid export.

Ordningen som fungerar:

1. Modellera hästen med **nosen mot −Y** i Blender, stående på `Z = 0`, mitt över
   origo. Det är Blenders normala framåt.
2. Rotbenet i **världsorigo**, rotation `0,0,0`, skala `1,1,1`.
3. Applicera all skalning och rotation på nätet och armaturen
   (`Object → Apply → All Transforms`) innan export. Roblox läser transformerna,
   inte avsikten.
4. Skala så att **mankhöjden i Blender-meter × 3 = mankhöjden i studs** enligt
   tabellen i § 1. Ett varmblod ska vara 4,98 studs i manken.
5. Exportera FBX med `Forward = -Z Forward`, `Up = Y Up`, och
   **`Apply Scalings = FBX All`**.
6. Kontrollera i Studio att hästen tittar mot `+Z` när modellens `Orientation` är
   `0,0,0`. Gör den inte det, rätta i Blender och exportera om. **Rätta det aldrig
   genom att rotera modellen i Studio** — då är rotbenets orientering fortfarande
   fel, och alla klipp ärver felet.

Punkt 6 är kontrollen. De fem föregående är hur man klarar den.

---

# 7. Att köpa eller att bygga

Issue #31 kräver att tillgången är lagligt användbar och att licensen är
dokumenterad i GitHub. Produktägarens kommentar kräver dessutom uttryckliga
kommersiella villkor och redigerbar källfil framför en ogenomskinlig gratismodell
från Roblox.

Tre vägar, med licensläget verifierat.

## Väg 1 — CC0, och därmed noll licensrisk

[Quaternius](https://quaternius.com/packs/universalanimationlibrary.html) släpper
sina paket under **CC0**, uttryckligen fritt för personligt, utbildnings- och
kommersiellt bruk, och levererar FBX, GLB och `.blend`. Det finns en animerad häst
([poly.pizza, CC0](https://poly.pizza/m/qvTrSG9pZF)).

- **Starkt:** noll licensrisk, redigerbar källfil, ingen attribution krävs.
- **Svagt:** stiliserat lågpolygont, byggt som djur och inte som ridhäst. Sadel,
  träns och stigbyglar saknas, och de fem attachment-punkterna finns inte.
  Klippen är inte gjorda mot UBRF:s cykellängder.
- **Bedömning:** bästa **utgångspunkten**, inte färdig produkt. Den ger en riggad,
  laglig, redigerbar bas att bygga vidare på.

## Väg 2 — CC-BY från Sketchfab

Flera riggade hästar med sadel finns under **CC Attribution**, till exempel
[Toon Horse with Saddle](https://sketchfab.com/3d-models/toon-horse-with-saddle-rigged-animated-db8fe38f93cb48e7a5c9df446a105f7a)
med skritt, trav och galopp, och
[Animated Rigged Horse With Saddle](https://sketchfab.com/3d-models/animated-rigged-horse-with-saddle-b08743c2c4734fb98a4e0a2f5767c318).

- **Starkt:** sadel och träns finns redan, kortare väg till en komplett rigg.
- **Svagt:** attribution måste finnas kvar i spelet och i repot, permanent, och
  det är ett åtagande någon måste förvalta.
- **Bedömning:** dugligt, men CC0 är billigare i förvaltning. Välj CC-BY bara om
  modellen är märkbart bättre.

## Väg 3 — betald tillgång

[Realistic Animated Horse 2.0 från WildMesh](https://sketchfab.com/3d-models/realistic-animated-horse-20-75ca409fb4da47c9ae4725046e9bfa1e)
är den kvalitetsnivå issue #31 beskriver som mål.

> **Gratisversionen är märkt "personal use only".** Kommersiell användning gäller
> **endast** versioner köpta via Fab eller Patreon. Ladda inte ner gratisversionen
> till repot. Det vore ett licensbrott, och det skulle ligga i historiken.

- **Bedömning:** enda vägen om målet är realistisk kvalitet direkt. Kräver inköp
  och kvitto, och kvittot ska journalföras precis som beslutet i
  `docs/BESLUT-BILDMATERIAL.md`.

## Vad jag rekommenderar

**Väg 1 som bas, och egen riggning ovanpå.** Skälen är att UBRF ändå måste
- lägga in de fem attachment-punkterna,
- byta collidern mot en låda enligt tabellen i § 1,
- producera om alla fyra gångartsklipp till UBRF:s cykellängder enligt § 2,
- och skala om till 3,0 studs per meter.

Det arbetet ska göras oavsett vilken modell som köps. Då är CC0-basen den som
kostar minst att arbeta i, och den lämnar inget licensåtagande efter sig.

**Men det är ett beslut som kostar pengar eller tid och därför inte är mitt.**
Väg 3 köper realism för pengar; väg 1 köper kontroll för arbetstid. Produktägaren
avgör.

## Roblox Creator Store

`HORSE-MODEL-SPEC.md` förutser köpta modeller med egna bennamn och löser det med
`Map_<nyckel>`-attribut, vilket är rätt. Men
[Creator Store Terms](https://en.help.roblox.com/hc/en-us/articles/21308223046932-Creator-Store-Terms)
ger inte alltid källfilen, och utan `.blend` kan gångartsklippen inte göras om mot
UBRF:s cykellängder. **En modell utan källfil kan inte uppfylla § 2.** Det
diskvalificerar de flesta Creator Store-hästar för produktion, och det är
sannolikt vad produktägarens kommentar om ogenomskinliga gratismodeller redan
syftade på.

---

# 8. Acceptanstester — issue #31:s åtta punkter, gjorda falsifierbara

Issue #31:s definition of done är åtta punkter. Sex av dem är formulerade så att
de går att uppfylla på en känsla. Här är samma åtta som prov med ett svar.

| # | issue #31 säger | provet | godkänt när |
|---|---|---|---|
| 1 | riggen är versionerad och tillgänglig för bygget | filen finns i repot eller Supabase, med sökväg i `ASSET-SOURCE-OF-TRUTH.md` | Google Drive är **inte** en beroendekedja |
| 2 | licens och proveniens är journalförd | egen fil i `docs/`, i samma form som `BESLUT-BILDMATERIAL.md` | licenstexten är citerad, inte länkad |
| 3 | importerar rent i Studio | import utan varningar | inga varningar, inte "bara ofarliga varningar" |
| 4 | alla attachments och configar validerar | **F8**-rutan enligt `HORSE-MODEL-SPEC.md` steg 5 | alla fem attachments och alla fyra Configuration-block listas som hittade |
| 5 | ett kanoniskt `HorseId` binder genom PR #30-flödet | tilldela `air`, kontrollera bindningen | `G01Phase` blir **inte** `waiting_model` |
| 6 | uppsittning, fyra gångarter och avstigning utan fysikinstabilitet | rid ett varv i ridhuset i varje gångart | `BodyCollider.Position.Y` varierar mindre än 0,10 studs på plant golv |
| 7 | silhuetten är hästlik, inte klossig | produktägarens ögon | Tobias godkänner. Detta är den enda punkten som **inte** ska automatiseras |
| 8 | basriggen bär rasvariation genom skala, material och textur | sätt `Breed = "Shetland"` och `Breed = "Warmblood"` på samma basrigg | båda står rätt i marken med `HipHeight` ur tabellen i § 1, utan egen rörelsemotor |

## Två prov issue #31 inte har, och som borde finnas

**Prov 9 — klipplängderna.** Mät varje klipps längd i Studio och jämför mot
tabellen i § 2. Godkänt vid högst en rutas avvikelse i 60 fps. Utan det provet är
punkt 6 en åsikt.

**Prov 10 — hovglidning, mätt.** Rid i skritt vid `0,90 m/s`, gångartens nedre
bandgräns, och film hoven i kontakt. Glider den bakåt relativt marken är provet
underkänt. **Med dagens klocklåsta animation kommer provet att underkännas oavsett
hur bra klippen är** — se § 3. Det är därför § 3 måste åtgärdas innan punkt 6 kan
godkännas, och därför provet ska skrivas nu och inte efter att någon har lagt två
veckor på klipp.

---

# 9. Ett beroende som inte är löst

Issue #31:s tekniska kontrakt kräver att riggen uppfyller
`roblox/docs/G01-HORSE-IDENTITY-CONTRACT.md`.

**Den filen finns inte i `main`.** Den finns bara i grenen
`chatgpt/g01-preparation-integration`, som är **PR #30, fortfarande draft, och
blockerad bakom PR #29.**

Innehållet är läst och det är gott: `HorseId` som stabil maskinnyckel, `HorseName`
som presentation, `AssignedUserId` som körtidstillstånd, och `StallService` →
`GameplayService` → `HorseService` som befogenhetskedja. Kravspecen ovan är
skriven mot det innehållet.

Men **acceptanspunkt 5 kan inte köras förrän PR #30 är mergad**, och PR #30 väntar
på PR #29. Det är kedjan som avgör när issue #31 kan stängas, och den syns
ingenstans i issue #31.

Åtgärd: skriv beroendet i issue #31, så att nästa person som tar upp den inte
börjar med att leta efter en fil som inte finns i `main`.

---

# 10. Vad som inte är prövat i det här dokumentet

- **Ingen modell är importerad.** Allt ovan är räknat ur koden och kontrollerat
  mot Roblox' dokumentation. Första importen kommer att hitta saker inget
  dokument kan förutse.
- **Trianglabudgeten i § 5 är inte mätt på riktig hårdvara.** 6 000 per häst är
  en bedömning grundad på tolv hästar samtidigt, inte på en profilering.
- **Ryttarens IK är inte specificerad.** `HORSE-MODEL-SPEC.md` beskriver
  attachment-punkterna men inte hur ryttarens armar och ben faktiskt löses.
  `RiderController.luau` finns; jag har inte läst den mot det här.
- **Ljudtillgångarna är inte behandlade.** `Sounds`-blocket kräver åtta klipp per
  häst, och de har samma licensfråga som modellen. Det är en egen kravspec.
- **`Rear` och `Graze`** står som frivilliga i modellspecen. För ett spel som
  lär barn om hästar är beteenden sannolikt viktigare än ett fjärde
  fyrsprångsklipp, men det är en produktprioritering och inte min.
