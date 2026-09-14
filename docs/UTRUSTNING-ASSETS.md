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
  lämnade de delarna kvar på hästen).
- Ingenting byts på hästryggen (`tack.sitter_upp`).
- Hjälmen kommer tillbaka efter respawn om spelaren hade den på.
- Studio-QA kan tvinga primitiverna: `workspace:SetAttribute("UBRFUtrustningVisual", "primitiv")`.

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
- Hjälmens läge på R15/R6 och skalade avatarer, kamera vid tredje person.
- Fysisk iPad/iPhone: att raderna nås med fingret utan att träffa spaken.
- Handkontroll: att `DPadLeft/Right` och `ButtonA` når panelen i Roblox
  klient (bänken fyrar `InputBegan`, inte en riktig kontroll).
- Prestanda: 24 540 trianglar per sadlad häst; en häst i taget i First
  Playable, inte 33.

**Tom ruta betyder inte PASS.**
