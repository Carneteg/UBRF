# Utrustningsgaten (#165) — assets, beslut och gränser

EQUIPMENT & RIDER GEAR GATE, order 2026-09-14 03:40 med enhetsparitetstillägg
03:46. Byggd på den accepterade First Playable-linjen (`943bfda`); den
pinnade artefakten `…-91914a7` rörs inte.

## Vad som är ett tillstånd och vad som är ett utseende

Tillståndet är oförändrat sedan #162 blockerare 5: utrustning ÄR fysiska
delar. Sadel, underlägg, träns och tyglar ligger i hästens `Tack`-mapp med
`UBRFTack`/`ForHast`; hjälmen ligger nu på samma sätt i spelarens karaktär
med `UBRFTack = "hjalm"`/`ForSpelare`. `TackService` läser världen, för
inget register. Creator Store-modellerna är en VISUELL KÄLLA för samma delar
(`UBRFVisual = "asset" | "primitiv"`), aldrig ett andra system.

Katalogen `roblox/src/shared/HorseCore/Utrustning.luau` är det enda stället
som vet vilka typer som finns, vilken modell som är kandidat, om den är
antagen, var den fästs och om den krävs för att sitta upp.

## Assetutvärdering

| Typ | Asset | Utfall | Skäl |
|---|---:|---|---|
| Hjälm | 123547958 | **AVVISAD** → primitiv | Modellen innehåller 1 `Script` (toolbox `instanceCounts.script`). Filen kan inte hämtas utan inloggning (assetdelivery 401), så skriptet kan inte läsas. En fri modell från 2013 med ett oinspekterat skript sätts inte i en familjs spel. Primitiven är grön som webbens ryttarhjälm. |
| Hjälm | 11611844698 | **ERSATT** (PO 2026-09-14 05:02) — inte längre kandidat, står i `Utrustning.AVVISADE` | "Adrian Helmet" av cbr44446 (2022): fri, 7 MeshParts, 7 808 trianglar, 0 skript — klarade prövningen och var runtime-kandidat i `6696526` (PO-val 05:01), men Tobias bytte kandidat 05:02. Behålls som beslutsspår; `utrustningsgrind.spec` fäller varje katalogpost som pekar på den. |
| Hjälm | 92445706145003 | **ANTAGEN som runtime-kandidat** (PO-val 2026-09-14 05:02, enda gällande kandidaten) | "rosto do silva 25k" av Bebel_dopix (2025-04-20): fri (`IsPublicDomain`, `isFree`), 4 MeshParts, 3 194 trianglar / 9 029 hörn, **0 skript** (`hasScripts = false`, `instanceCounts.script = 0`), beskrivningen är titeln — inget attributionskrav; objekttyp Hat/Accessory. Samma prövning som sadel/träns. Laddas i runtime, passas in i huvudets låda (1,25 × 0,9 × 1,3 av `Head`), svetsas i `Head`, kolliderar inte, masslös; primitiven är fallback. Butiksbilden (thumbnails-API) visar en svart kupa med hakrem på ett huvud med hals — `[REFERENCE GAP]` om huvudet/halsen är delar av modellen; kan inte avgöras headless (assetdelivery 401). Läge/skala/klippning mot avatar och kamera samt texturer: HARDWARE CHECK. Båda utmönstrade ID:na står i `Utrustning.AVVISADE` och `utrustningsgrind.spec` fäller varje katalogpost som pekar på dem. |
| Sadel + underlägg | 9639407836 | **ANTAGEN som runtime-kandidat** | 4 MeshParts, 24 540 trianglar, inga skript, fri. Laddas med `InsertService:LoadAsset`, passas in i primitivens låda (0,44 × 0,30 × 0,62 m) och svetsas i `SaddleAttachment`s värddel. Underlägget ritas fortfarande som primitiv under (modellens egen pad ligger i sadeln). |
| Träns | 15966015286 | **ANTAGEN som runtime-kandidat** | 1 794 trianglar, inga skript, fri. Passas in i huvudets låda (×1,12) och svetsas i huvudet; tyglarna byggs som förut ur riggens bettpunkter. **Kredit RHS** registrerad. |
| Hopp | 2780160044 | rekommenderad för Studio-QA, **inte integrerad** | Lägst trianglar (888), inga skript, 92 % upp. Skala, kollision och ridlinje kan inte mätas headless; hindren på banan är i dag kanonplacerade primitiver (`RIDHUSINNE.hinder`). |
| Hopp | 2314446954 | andrahandsval | 792 trianglar men flera hinder i en modell. |
| Hopp | 174424237 | avvisad tills vidare | 7 680 trianglar för en hindersats (2014). |
| Hopp | 8941934960 | avvisad tills vidare | ingen nätsummering i API:et (troligen Parts), lägst röst. |

Rekommendation: **noll** hopp integreras i den här gaten; `2780160044`
öppnas i Studio först.

## Reglerna (samma på webb och Roblox)

- Hjälmen krävs för att sitta upp (`Utrustning.kravsForRidning("hjalm")`,
  nyckel `tack.saknar_hjalm`). `[antagande — PO att bekräfta]`: ridskolans
  regel att ingen rider utan hjälm är gjord till spelregel; flaggan kan
  stängas av i katalogen utan kodändring.
- Sadel och träns tas på genom skötselns moment `utr:1..5`, som förut.
- Sadel och träns kan tas AV igen i vanligt spel (`Utrustning`-remoten);
  checklistan ångras (`Preparation.angraUtrustning`) så att logiskt följer
  fysiskt. Kanonordningen vid avtagning är gjord → sadel → träns:
  sadeln får lyftas av medan hon är tränsad. Underlägget kan inte dras ut
  under sadeln.
- Eftervårdens "Ta av sadeln"/"Ta av tränset" tar av på riktigt (före #165
  lämnade de delarna kvar på hästen) — och **kvitterar sist** (#170
  blockerare 1): först får-jag (`Pass.farUtfora`, inget kvitto), sedan
  handgreppet per del (`TackService.taAv`), sedan läser servern världen
  (sitter något kvar → `tack.sitter_kvar`), och först då `Pass.utfor`.
  Är hästen borta nekas momentet med `tack.ingen_hast`. Ett nekat moment
  kvitteras aldrig och kan göras om utan omloggning. Samma ordning som
  påsättningen (`utforMoment`): logiskt kan inte gå före fysiskt åt något
  håll.
- Boxfrontens prompt lämnar **sadel och träns som ett par** till
  `GameplayService.valjUtrustningPar` (#169, #170 blockerare 2): hela
  valet prövas (kända typer, hästen finns i stallet) innan något skrivs,
  och skrivs sedan som en tabell. Nekas valet är det föregående paret
  orört, skälet kommer tillbaka (`tack.okand_hast` / `tack.okand_utrustning`)
  och `TackForradService.tag` loggar "tog" bara när båda togs — annars en
  varning med skälet. Att paret kan vara **fel hästs** är fortfarande
  poängen (webbens felval) och möts av `TackService.satPa` på hästen.
- Ingenting byts på hästryggen (`tack.sitter_upp`).
- Hjälmen kommer tillbaka efter respawn om spelaren hade den på.
- Studio-QA kan tvinga primitiverna: `workspace:SetAttribute("UBRFUtrustningVisual", "primitiv")`.

## Importsanering — vad som får följa med en Creator Store-modell

`TackRigg.laddaAsset` prövar **hela hierarkin** mot en vitlista av inerta
klasser (#170 blockerare 3, QA 05:45/05:50). Bär modellen en enda instans
utanför den — skript, prompter, klickdetektorer, ljud, eld/rök/partiklar,
ljus, beams, trails, highlights, säten, krafter, constraints, Humanoid,
animationer … — avvisas **hela modellen** och primitiven ritas. Ingen
rensning: att plocka bort det aktiva ur en modell man inte läst är att
gissa vad resten gjorde. Vitlistan:

- **behålls** — BaseParts, `Attachment`, `SpecialMesh`/`FileMesh`/
  `BlockMesh`/`CylinderMesh`, `SurfaceAppearance`, `Decal`, `Texture`;
- **löses upp** (accepteras men förstörs efter flytten, eftersom delarna
  plattas ut i `Tack`-mappen och svetsas om av oss) — `Model`, `Folder`,
  `Accessory`, `Hat`, `WeldConstraint`, `Weld`, `ManualWeld`, `Motor6D`,
  `Snap`.

Alla delar är dessutom CanCollide/CanQuery/CanTouch av och masslösa.
Provet `utrustningsgrind.spec` g) laddar ett elakt fixtur med elva aktiva
icke-skript-klasser (avvisas, primitiv, inget når karaktären eller
hästen), prövar 19 aktiva klasser en i taget (var och en fäller modellen
ensam) och h) ett inert fixtur (accepteras: yta, fäste och textur
behålls, behållare och gammal svets löses upp). Det som inte står på
vitlistan finns inte i spelet — det är därför hjälmens oinspekterbara
hierarki (assetdelivery 401) är acceptabel att *försöka* ladda: bär den
något aktivt syns primitiven, inte hjälmen (HARDWARE CHECK).

## Enhetsparitet — equip och unequip per inmatning

| Handling | Tangentbord/mus | Handkontroll | iPad/iPhone touch |
|---|---|---|---|
| Hjälm på / av | knappen i panelen (mus) eller `↑ ↓` + `Enter` | `◀ ▶` + `A` | knappen i panelen (44 px) |
| Sadla / tränsa (på) | momentknapparna `utr:1..5` — mus eller `↑ ↓` + `Enter` | `◀ ▶` + `A` | momentknapparna |
| Sadel av / träns av | knappen i panelen — mus eller `↑ ↓` + `Enter` | `◀ ▶` + `A` | knappen i panelen |

Markeringen fäller ut panelen själv, så "Visa alla" (en musknapp) krävs
aldrig utan mus. Panelen finns bara när man inte rider, och `ButtonA` är
bundet till hopp bara medan man rider (`Input.bind` i uppsittningen) —
de två möts aldrig. Layouten är oförändrad: panelen väjer redan för
tumspaken och hoppknappen (`interaktionsLayout`).

Webben: hjälmen finns som `G.hjalmPa` — den följer med sadel och träns
från sadelkammaren, går att ta av och på i boxmenyn (`bHjalm`), krävs i
`sittUpp` med samma nyckel, ritas på ryttaren bara när den är på, och
nollas vid dagens början. Sadel/träns är ett samlat moment på webben och
har ingen separat avtagning före ritten — **paritetsanteckning**, inte
byggd. Prov: `tools/utrustningstest.mjs` (i CI).

## NOT_TESTED / HARDWARE CHECK

- Studio-runtime: att Creator Store-sadeln och -tränset faktiskt laddas i
  en publicerad upplevelse (`InsertService` kräver att ägaren får ladda
  modellen), deras orientering, skala och klippning mot lådhästen och mot
  ett framtida nät. Inpassningen sker mot en låda; en modell med "fram" åt
  fel håll står fel tills en rotation läggs i katalogen.
- Hjälmen 92445706145003 i runtime: att `InsertService:LoadAsset`
  laddar den i en publicerad upplevelse, dess orientering och läge på
  R15/R6 och skalade avatarer, klippning mot huvud/hår och kameran i
  tredje person, texturerna, och om modellen bär eget huvud/hals (som
  butiksbilden antyder) — då ska `workspace.UBRFUtrustningVisual =
  "primitiv"` sättas tills katalogen pekar på en ren hjälm. Inpassningen
  sker mot huvudets låda; en rotation kan behövas i katalogen.
- Fysisk iPad/iPhone: att raderna nås med fingret utan att träffa spaken.
- Handkontroll: att `DPadLeft/Right` och `ButtonA` når panelen i Roblox
  klient (bänken fyrar `InputBegan`, inte en riktig kontroll).
- Prestanda: 24 540 trianglar per sadlad häst; en häst i taget i First
  Playable, inte 33.

**Tom ruta betyder inte PASS.**
