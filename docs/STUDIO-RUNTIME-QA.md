# LOCAL STUDIO-MCP RUNTIME QA — körlista för PR #162

> **Den här filen är HANDOFF-paketet.** Den finns för att runtime-QA:n ska
> kunna jämföra Studio mot **mätta förväntningar** i stället för att titta sig
> omkring. Varje tal nedan är hämtat ur `qa/pre-tobias/WORLD_MANIFEST.json`,
> som i sin tur är mätt ur den byggda världen — inte skrivet för hand.

> Molnsessionen kan inte köra det här: den har ingen `robloxstudio` MCP och
> inget Windows-filsystem (mätt tre gånger). Den lokala Claude Code-sessionen
> på Tobias Windows-maskin kör det.

## 0. Identitet — kontrollera FÖRE allt annat

**TRE identiteter, och de är olika tal.** Att blanda ihop dem gjorde den här
listan osatisfierbar i sin första version: §0 pinnade artefakten byggd ur
`0a1b0323`, medan §1 krävde `93d596f5` — commiten som *mätte* placen, inte den
som *byggde* den. En fil kan inte innehålla SHA:n för en commit som skapades
efter den.

| Identitet | Värde | Vad det är |
|---|---|---|
| **PR / current head** | flyttas av docs-patchar | grenens spets. Säger vilken version av *den här listan* du läser. |
| **artifact source SHA** | `1e8b20755d2d543dad2433fbb105f3dd4b236585` | commiten som **byggde** placen. Ligger bakad i filen som `ReplicatedStorage/UBRFBuild.sha` och är det Studio skriver i Output. |
| **artifact SHA256** | `db3d7577e0880d2824b699b25874a0cc99690f29a2a28d3eb9f0d2f525082381` | filens hash. **Den här är den stabila** — den ändras inte av docs-patchar. |

| | |
|---|---|
| gren | `claude/first-playable-20260910`, bas `main` |
| fil i repot | `roblox/releases/first-playable-place-1e8b207/UBRFFirstPlayable.rbxlx` |
| storlek | 902 019 byte, 64 instanser |
| determinism | ombyggd ur samma källa, byte-identisk |

> **Den här artefakten ersätter `first-playable-place-9b5a570`.** Skillnaden
> är den blockerande produktluckan 16:21: sadeln och tränset är nu FYSISKA
> saker som hänger på hästens boxfront och måste hämtas. Två nya moduler bär
> hela ändringen (62 → 64 instanser), och **§ 6 är därmed helt omskriven och
> aldrig runtime-testad**.
>
> Allt som väntade på runtime i `…-9b5a570` väntar fortfarande: § 9 `ride`
> med den förklarande CTA:n, § 8b `ActionText` i båda locale, och § 8c
> HUD-layouten. Ingen av dem har mätts i Studio på någon artefakt ännu.
>
> Äldre artefakter (`…-efa341e`, `…-67e7716`, `…-0a1b032`) ligger kvar orörda
> som historik och ska inte öppnas.

> ### Ladda ner rätt bytes
>
> Repot märker sedan den här artefakten `*.rbxlx` som **binärfil** i
> `.gitattributes`. Utan det konverterar `core.autocrlf=true` radsluten i
> arbetsträdet på Windows, och då stämmer inte `certutil`-hashen nedan mot
> tabellen ovan — filen blir inte trasig, men hashen går inte att verifiera.
>
> Har du redan en utcheckning med `core.autocrlf=true` ligger de konverterade
> kopiorna kvar tills filerna ändras. Klona om, eller kör
> `git rm --cached -r . && git reset --hard`, INNAN du kopierar ut filen.

### Filen som ska öppnas i Studio

MCP:n kan inte öppna en place-fil. Det här steget är manuellt:

```
C:\Users\Tobias Carneteg\Desktop\UBRF-QA-162\first-playable-place-1e8b207\UBRFFirstPlayable.rbxlx
```

> ⚠️ **Öppna INTE `Desktop\UBRFFirstPlayable.rbxlx`.** Den kopian är
> byte-identisk med release `6a0e5d7` — två releaser bakom — och lades på
> skrivbordet innan den pinnade byggdes. Den bygger 11 dörrar, 6 gångytor och
> **en enda häst**. Det var precis det den första lokala körningen fastnade på.

```powershell
cd "C:\Users\Tobias Carneteg\Desktop\UBRF"
git fetch origin
git checkout claude/first-playable-20260910
git pull --ff-only
claude mcp list                      # MÅSTE visa robloxstudio
certutil -hashfile "$env:USERPROFILE\Desktop\UBRF-QA-162\first-playable-place-1e8b207\UBRFFirstPlayable.rbxlx" SHA256
```

Kontrollera **artifact SHA256** mot tabellen ovan. Stämmer den inte är det
**fel fil** — stoppa där. Kontrollera den mot filen Studio faktiskt har öppen,
inte mot den i repot: det var skillnaden mellan dem som fällde första försöket.

Saknas `robloxstudio` i `claude mcp list` är det **fel klient**: MCP:n är
registrerad för Claude Code, inte för Claude Desktop.

## 1. Startup och preflight

Studios Output ska bära, i den här ordningen:

```
FIRST_PLAYABLE_SHA=1e8b20755d2d543dad2433fbb105f3dd4b236585
FIRST_PLAYABLE_PREFLIGHT: PASS
OK UBRF byggd: 8 byggnader, 12 dörrar, 4 boxrader, 7 gångytor, 3309 objekt
OK  Öppningarna frigjorda: 8 delar delade till 16 bitar
OK  Världen vänd till högerhänt (norr = −Z): 3313 delar speglade
[Rigg] 33 av 33 hästar står i sina boxar
[Dörr] 13 dörrar fick interaktion
```

`FIRST_PLAYABLE_PREFLIGHT: FAIL` är fail-closed och ska stoppa körningen.

**STRUKTURTALEN är kontraktet**, alltså `8 byggnader, 12 dörrar, 4 boxrader,
7 gångytor`, `33 av 33 hästar` och `13 dörrar fick interaktion`. De stämde
exakt i förra körningen och ska göra det igen.

**OBJEKTRÄKNARNA är det inte.** Förra körningen gav `3293 objekt` och `3301
delar speglade` i Studio där bänken säger `3305`/`3313` — en konstant
avvikelse på 12 som ingen har diagnostiserat, och som molnsessionen inte kan
diagnostisera utan Studio. Talen ovan är **bänkens**. Rapportera avvikelsen
med de tal Studio faktiskt skriver; fäll inte körningen på dem.

De två SurfaceGui:er och två TextLabels som skyltarna fick i den här
artefakten är skälet till att objektantalet steg från 3305 till 3309 — de är
GUI-instanser och inte delar, och därför står `3313 delar speglade` stilla.

## 2. Spawn och mark — inget void

| Mätning | Förväntat |
|---|---|
| spawnläge (tomtkoordinat) | (161.6, 126.4) |
| spawnen vetter mot | `stall N dorrgul` |
| fall till mark | 0,10 m — inte mer |
| takfrihet | ≥ 1,75 m |
| marken under | kolliderande (`Förstukvist golv`) |

**Falsifiering:** gå fram till kanten av verandan. Faller avataren igenom
någon yta som ser ut som mark är det `NO_VOID`-brott och ett stopp.

## 3. Portaler — 13 st, var och en med sina två zoner

Varje rad ska gå att **gå igenom i båda riktningar**. Zonparet är mätt i
källdatan; runtime ska landa i samma zon.

| # | Byggnad | Sida | Typ | Bredd | Läge (x, y) |
|---|---|---|---|---|---|
| 1 | ridhus | N | `dorrvit` | 1.80 m | (139.0, 119.0) |
| 2 | ridhus | N | `dorr` | 1.10 m | (134.3, 119.0) |
| 3 | ridhus | W | `dorrvit` | 2.00 m | (118.0, 109.0) |
| 4 | ridhus | E | `portplat` | 3.40 m | (143.0, 48.5) |
| 5 | ridhus | E | `portbla` | 2.40 m | (143.0, 84.6) |
| 6 | ridhus | S | `portsilver` | 4.00 m | (128.0, 41.8) |
| 7 | stall | W | `dorrgul` | 1.15 m | (151.1, 118.8) |
| 8 | stall | W | `portbla` | 2.40 m | (151.1, 84.6) |
| 9 | stall | N | `dorrgul` | 1.15 m | (161.6, 125.0) |
| 10 | stall | E | `portbla` | 3.60 m | (172.1, 91.2) |
| 11 | stall | S | `dorrvit` | 1.15 m | (157.3, 55.0) |
| 12 | stall | S | `dorrvit` | 1.15 m | (164.2, 55.0) |
| 13 | langa | N | `dorrmork` | 1.10 m | (149.1, 40.0) |

### Deklarerade ICKE-passager — ska vara BLOCKERADE

- `ridhus W dorr` — [REFERENCE GAP] Öppningen ligger bakom läktarens bänkrader. Att såga hål i läktaren för att dörren ska gå att använda vore påhittad geometri. VILKEN långsida läktaren ligger på är ännu inte avgjord (se noten i buildings/Vyer.luau); visar sig den ligga på östra sidan blir den här dörren fri och raden ska bort.

Går den igenom är kontraktet brutet åt andra hållet: grinden räknar
`#blad + #deklarerade == genomgående`, så en icke-passage som *går* att
passera är lika fel som en dörr som inte gör det.

## 4. P0-1 — identifiera objektet, gissa inte

Tobias bild 2 visar en grind som verkligheten saknar. Två kandidater, och de
kräver **motsatta** åtgärder:

| Kandidat | Var | Status i källan | Om det är denna |
|---|---|---|---|
| `SPELABSTRAKTION sargport` | ridhusets norra kortsida | ingen bild visar en grind där; bredden vald | **ta bort ur världen** |
| `sargGrind` | ridhusets östra långsida mot hästgången | läget härlett, bredden `[ASSUMPTION]` | **behåll och märk rätt** |

**Så här avgörs det — inte genom att fråga Tobias igen:**

1. Hitta objektet i runtime. Läs `Name`, `Position`, och attributen
   `Oppningstyp`, `Etikett`, `Mot`, `Langs`, `Utat` om de finns.
2. Räkna om `Position` till tomtkoordinat med `BuildKit.tomtkoord` och jämför
   mot de två kandidaternas läge.
3. Ställ avataren framför den och gå. Notera vilken zon hon hamnar i.
4. Gör samma sak för BÅDA — ordern kräver att båda verifieras oavsett vilken
   bilden visar.

Redovisa per passage: runtime-objekt + sökväg, position, `fromZone -> toZone`,
om den ska vara passage enligt kanon, faktisk avatar-traversal, och vad som
blockerade i den tidigare builden om den föll.

## 5. Hästarna — 33/33 fysiskt närvarande, var och en i SIN box

Manifestet: **33 av 33**. Ingen får stå i en gång.

| Häst | Box | Läge (x, y) |
|---|---|---|
| `air` | 1 | (153.29, 63.60) |
| `allan` | 14 | (159.96, 63.60) |
| `berra` | 27 | (163.68, 63.60) |
| `bing` | 40 | (170.10, 63.60) |
| `blackrock_jack` | 31 | (163.68, 77.60) |
| `conor` | 2 | (153.29, 67.10) |
| `cosmo` | 15 | (159.96, 67.10) |
| `crokino` | 28 | (163.68, 67.10) |
| `curiretto` | 41 | (170.10, 67.10) |
| `dante` | 6 | (153.29, 81.10) |
| `dexter` | 19 | (159.96, 81.10) |
| `fay` | 3 | (153.29, 70.60) |
| `garnit` | 32 | (163.68, 81.10) |
| `hamilton` | 29 | (163.68, 70.60) |
| `hjartat` | 16 | (159.96, 70.60) |
| `jessy` | 45 | (170.10, 81.10) |
| `kay_z` | 42 | (170.10, 70.60) |
| `kennedy` | 7 | (153.29, 88.10) |
| `lady` | 20 | (159.96, 84.60) |
| `larry` | 4 | (153.29, 74.10) |
| `lothar` | 17 | (159.96, 74.10) |
| `lydia` | 44 | (170.10, 77.60) |
| `mac_kenzie` | 33 | (163.68, 84.60) |
| `marabou` | 46 | (170.10, 84.60) |
| `oska` | 30 | (163.68, 74.10) |
| `puma` | 43 | (170.10, 74.10) |
| `replay` | 8 | (153.29, 91.60) |
| `sune` | 5 | (153.29, 77.60) |
| `tess` | 18 | (159.96, 77.60) |
| `toblerone` | 21 | (159.96, 88.10) |
| `trixie` | 34 | (163.68, 88.10) |
| `troy` | 47 | (170.10, 95.10) |
| `westside` | 9 | (153.29, 95.10) |

**Detta är fyndet som en tidigare grind missade:** den frågade "står hästen
nära `box.varld`?", vilket är att jämföra ett tal med sig självt. Sexton av
trettiotre stod i gången. Kontrollera därför i Studio att varje häst står
**innanför en boxfront**, inte bara på rätt koordinat.

## 6. Utrustning — sadeln och tränset som FYSISKA saker

**NY I DEN HÄR ARTEFAKTEN. Aldrig runtime-testad.** Före den här byggen var
utrustningssteget ett tillståndsbyte: man tryckte på en HUD-rad vid hästen
och var sadlad. Nu hänger sadeln och tränset i världen och måste hämtas.

### Var de hänger — och varför inte i sadelkammaren

På **hästens egen boxfront**. Källan är
`references/buildings/stall/KORT.md` § Boxarna från gången, ur filmen: *"På
fronterna hänger sadlar med underlag, täcken, grimmor, träns och benskydd —
mycket saker, tätt."*

Sadelkammaren är **inte** platsen, och det är ett källbeslut, inte en
förenkling: `stall-inne-03-sadelkammaren.jpg` visar **inga sadelbockar** —
säkerhetsvästar på krokrader och en hylla med stövlar — och
`docs/F02-B-INREDNINGSMATRIS.md` har redan fällt sadlar där som
`REFERENCE GAP`. Att bygga sadelbockar i det rummet hade varit att hitta på
en UBRF-detalj. Rummets egen inredning står kvar oförändrad:

| Plats | Delar | Läge (x, y) |
|---|---|---|
| `sadel_dorr_teori` | 3 | (159.90, 119.34) |
| `sadel_stovelhylla` | 1 | (161.40, 117.25) |
| `sadel_vastkrokar` | 2 | (158.42, 117.25) |

### Dagens häst — Blackrock Jack

| | Tomtkoordinat (x, y) |
|---|---|
| boxen (box 31, rad MB, gång B) | (163.68, 77.60) |
| boxfronten mot gång B | (165.53, 77.60) |
| **sadeln** (`Sadel_blackrock_jack`) | (165.81, 76.76) |
| **tränset** (`Trans_blackrock_jack`) | (165.81, 78.44) |

Sakerna ligger i `workspace.Utrustning`, taggade `Utrustning`, med
attributen `HastId` och `UtrSort`. Formen är spelabstraktion — filmen mäter
ingen sadel — men läget härleds ur boxen och är inte skrivet för hand.

> **Boxdörren delar fronten.** Sedan `27e5c2a` har varje boxfack en 1,20 m
> dörr i fackets bortre ände. Sadeln och tränset hänger på den **täta
> panelen**, aldrig i dörröppningen — det mäts mot de faktiskt byggda
> delarna i `spelbarhet.spec` (66 lägen). Ser du en sadel stå i dörrgapet är
> det ett fynd: härledningen har glidit.

### Körlista

| # | Gör | Förväntat |
|---|---|---|
| 6a | läs Output vid start | `[Utrustning] 66 saker hänger på boxfronterna` |
| 6b | gå till Jacks boxfront | två saker hänger där, i gångens höjd, utan att blockera gången |
| 6c | sikta på dem | prompt **Ta med dig** / *Pick up* med objektet **Sadel med underlägg** respektive **Träns** (`en-us`: *Saddle with numnah* / *Bridle*) |
| 6d | sikta på en ANNAN hästs boxfront | **ingen prompt** — bara din egen hästs utrustning får en |
| 6e | hämta sadeln | den följer med på kroppen, synligt |
| 6f | gör hovarna, tryck sedan sadelsteget UTAN att ha hämtat | nekas med *du har ingen sadel med dig* |
| 6g | samma steg med sadeln i handen | går igenom |
| 6h | när `Gör i ordning` är klar | sadeln **försvinner från armen** — den sitter på hästen |
| 6i | tryck `Led till ridhuset` utan träns | nekas med *du har inget träns med dig* |
| 6j | HUD:ens hjälprad när fasen kräver en sak | *Sadeln hänger på boxfronten där Blackrock Jack står — hämta den.* och, när sadeln redan är hämtad, raden *Du bär: Sadel med underlägg* |

**Följ 6f–6j utan utvecklarkunskap**: instruktionen på skärmen ska räcka.
Behöver du gissa var sadeln finns är det ett fynd, inte ett handhavandefel.

## 7. Skyltar — kanoniska ankare

| Typ | Text | Läge (x, y) |
|---|---|---|
| `skylt` | **UPPLANDS-BRO RYTTARFÖRENING** | (118.0, 82.0) |
| `cafeskylt` | **CAFÉ KRUBBAN** | (124.4, 119.8) |

`UPPLANDS-BRO RYTTARFÖRENING` saknades i en tidigare build trots att den
finns i kanon och på webben. Den ska synas.

**RÄTTAT sedan förra körningen.** Då fanns skivorna på rätt läge med rätt
text — men bara som ATTRIBUT: noll barn, noll `SurfaceGui` i hela
`workspace`, alltså en blank benvit platta. Nu bär varje skiva en
`SurfaceGui` (`Skyltyta`) med en `TextLabel` (`Text`).

Kontrollera tre saker, och det tredje är det som lätt missas:

1. att texten **syns** utifrån, från motsvarande vinkel — skärmbild,
2. att den står rättvänd och läsbar, inte spegelvänd,
3. att den vetter **utåt**. Speglingen vänder delens lokala Z, så
   `SurfaceGui.Face` ska vara `Front` i den byggda världen. Står texten in
   mot väggen är facebytet i `BuildKit.speglaModell` fel.

## 8. HUD-kontext och språk

- Vid hästen: momentet på tur går att trycka på.
- Fyra gånger räckvidden bort (räckvidd 12 studs): raden går **inte** att
  trycka på, och rubriken byts till "Gå tillbaka till <hästens namn>".
- Tillbaka vid hästen: HUD:en återgår.
- Ingen prompt får skriva datans interna typnamn (`dorrgul`, `portbla`, …).
- Byt locale till `en-us`: alla spelarvända fält på engelska, egennamn kvar.

### 8b. Dörrarnas `ActionText` — RÄTTAT, verifiera igen

Förra körningen: `ActionText` stod kvar på `Öppna`/`Stäng` under `en-us` på
samtliga 13 dörrar medan `ObjectText` korrekt sa `Door`. Servern skrev över
klientens översättning.

Under `en-us`, på minst tre dörrar och **efter ett tryck på var och en**:

| | Förväntat |
|---|---|
| `ActionText` stängd dörr | `Open` |
| `ActionText` efter tryck | `Close` |
| `ActionText` efter tryck igen | `Open` |
| `ObjectText` | `Door` respektive `Gate` |

Under `sv-se` ska samma fält säga `Öppna`, `Stäng` och `Dörr`/`Port`. Står
det svenska ord under `en-us` är det samma fel tillbaka.

### 8c. Skötsel-HUD:en — NY LAYOUT, aldrig runtime-testad

PO-ordern 09:36 flyttade quest-/HUD-panelen. Allt nedan är mätt headless och
är `NOT_TESTED` i runtime — det är den här delen som behöver dig.

| Läge | Förväntat |
|---|---|
| normal gång | spåraren uppe till **höger**, ca 300×60 px, halvgenomskinlig |
| default | **hopfälld**: objective-titel + `n/m` + chevron `▾` |
| ett tryck på huvudraden | fälls **ut**: titel, faslista (rullar), kort hjälptext, `▴` |
| ett tryck till | fälls ihop igen, och läget står kvar över nästa vy |
| vid hästen med val | interaktionspanelen syns centralt nedtill |
| fyra räckvidder bort | interaktionspanelen **försvinner helt** — inte gråa knappar |
| tillbaka | den kommer tillbaka |

Och det ordern faktiskt handlar om: **gå och rid** med panelen uppe och se
efter att centrum, avataren och sikten framåt är fria. Kontrollera på
skrivbordsfönster och på ett iPad-format om Studio tillåter det.

`?`-knappen (`KontrollHjalp`) bor i samma hörn på pek-klienter. Den ska ligga
**ovanför** spåraren med luft emellan, aldrig över rubriken.

## 9. Kärnloopen

> ### `ride` — kvittera kortet FÖRST
>
> Förra körningen föll här: hästen rörde sig 0,00 studs. Rotorsaken är inte
> rörelselagret — `MovementController` är friad med mätning — utan att
> ridloopen fryser hästen medan ett Ugneta-kort väntar. Kortet kommer **en
> bildruta in i ritten**, inte vid uppsittningen.
>
> Kontraktet, enligt produktbeslutet 13:29:
>
> | Steg | Förväntat |
> |---|---|
> | kortet visas | knappen säger **Fortsätt för att börja lektionen** (`en-us`: **Continue to start the lesson**) |
> | medan kortet väntar | hästen står still — pausen SKA hålla |
> | kvittera (knappen, `R`, eller gamepad `Y`) | kortet stängs |
> | ge framåt | **positiv WalkSpeed och verklig förflyttning**, utan extra dold inputsekvens |
>
> Mätt headless: WalkSpeed 0,00 medan kortet väntar → 9,83 efter kvittering.
> Rör hon sig INTE efter kvittering är det ett riktigt runtime-fel.

> ### Och rotdelen är rättad sedan `9b5a570`
>
> På `9b5a570` föll punkt 5 av ett ANNAT skäl än pausen: hästens
> `Humanoid.RootPart` var `nil`, för kollidern hette `BodyCollider` och
> ingen del hette `HumanoidRootPart`. Utan rot fanns inget golv
> (`FloorMaterial = Air`) och ingen gångkraft lades på — `WalkSpeed` blev
> positiv men ingenting hände.
>
> Rättat i generatorn (`50e5ed9`): roten heter `HumanoidRootPart` och
> `HipHeight` sätts till benhöjden. Kontrollera i Output/Explorer:
>
> | Fält | Förväntat |
> |---|---|
> | `Humanoid.RootPart` | `HumanoidRootPart` — **inte** `nil` |
> | `HipHeight` | `2.01` |
> | `FloorMaterial` uppsutten på mark | `Concrete` / `Plastic` — **inte** `Air` |
> | `AssemblyLinearVelocity` under skritt | ≈ `WalkSpeed`, inte `0.001` |
>
> **Rid på ridbanan, inte i boxen.** I boxen går hon tills kroppen möter
> väggen — ~2,5 studs — och det är boxens mått, inte ett rörelsefel.

> ### Ledandet är fortfarande INTE fysisk gameplay
>
> Det som är gjort: rutten box → gång → port → ridbana är mätt framkomlig,
> boxdörrarna finns, och `leda` kräver nu att spelaren **bär tränset**.
>
> Det som INTE är gjort: hästen **följer inte spelaren**, och `leda` har
> ingen zonkontroll — steget kan bli sant med hästen kvar i boxen. Blockerare
> 2 står alltså öppen. Rapportera det som känt, inte som ett nytt fynd.

`mount -> ride -> dismount -> death -> respawn -> remount -> aftercare -> save`

- Uppsittning ska nekas innan skötseln är gjord (`pass.aterstar`).
- Ett moment 40 studs bort ska nekas (`spel.for_langt`).
- Döden ska släppa sitsen och inte lämna en spökryttare.
- Efter respawn ska skötseln fortfarande räknas som gjord.
- Passet ska räknas **en** gång och finnas kvar efter omläsning.

## 10. Rapportformat

Posta först när allt ovan är kört:

```
LOCAL_STUDIO_QA_PASS — pr-head <SHA> — source 1e8b2075… — rbxlx db3d7577e0880d2824b699b25874a0cc99690f29a2a28d3eb9f0d2f525082381 — MCP 3.1.3 — Studio runtime PASS
```

Faller något: rapportera `Observed | Root cause | Changed | Falsified |
Not tested`, och **bygg ingen ny `.rbxlx` förrän orsaken är rättad i källan**.
Blir P0-1 en geometriändring får nästa läge en **ny mapp med ny SHA** —
en pinnad release regenereras aldrig på plats.

---

Genererad ur `qa/pre-tobias/WORLD_MANIFEST.json`. Ändras världen ska
manifestet byggas om med `python3 tools/pre-tobias-grind.py --place <fil>`,
och då syns varje avvikelse mot den här listan som en diff.
