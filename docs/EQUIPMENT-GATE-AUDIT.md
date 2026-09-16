# Equipment Gate — auditen av assetkandidaterna

Issue #165. Det här dokumentet är **beslutsunderlaget**, inte en
implementation. Ingen av kandidaterna är inkopplad i spelet, och ingenting
ligger kvar i placen efter auditen.

Ordern var uttrycklig: gör ett **isolerat audit-/beslutspass först**,
importera ingenting permanent i produktionsvärlden, och markera allt oklart
som `BLOCKED_FOR_RIGHTS` i stället för godkänt.

Mätt 2026-09-16 på `main` `35bc06d7bd22691e9bc4d80cf42c96325a1ffea9`.
`bygg-identitet.py --kontrollera` grön (`700c39fc…11d2`, 67 källfiler),
`rojo-sanning.py` **68 lika · 0 olika · 0 oparade**, `kor.sh` 37/37.

## Domarna

| kandidat | asset | dom | kärnskälet |
|---|---:|---|---|
| Hästsadel + underlägg | `9639407836` | **FAIL** | 24 540 trianglar och fel skala — bredare än hästens egen bål |
| Hästträns | `15966015286` | **BLOCKED_FOR_RIGHTS** | titeln kräver kredd till "RHS"; vem RHS är går inte att fastställa |
| Ryttarhjälm | `123547958` | **FAIL + BLOCKED_FOR_RIGHTS** | bär ett skript, heter `TMNTHelmet`, ankrad del |

Hoppkandidaterna är **inte** auditerade. De ligger i en separat
arena-/miljögate enligt ordern.

## Måttstocken: vad vi bygger i dag

`TackRigg` bygger utrustningen procedurellt ur hästens **egna** mått. Uppmätt
på en riktig häst i en levande server-VM, efter `Rida nu`:

```
37 delar    0 meshar    0 unions    0 kolliderande    0 ej massless
```

Trettiosju lådor är ungefär **444 trianglar** för *hela* utrustningen —
underlägg, sadel, valv, flikar, gjord, stiglädrar, byglar, träns, pannband,
kindstycken, nosgrimma, hakrem och tyglar.

`TackRigg.del` sätter dessutom `CanCollide = false`, `CanQuery = false`,
`CanTouch = false` och `Massless = true` på varje del. **Utrustning
kolliderar aldrig** — det står i filhuvudet och är en produktregel, inte en
detalj.

Hästens bål (`HumanoidRootPart`) är **1,86 × 2,34 × 5,55 studs**. Vår
sadelsits är `0,40 × 0,055 × 0,46 m` = **1,20 × 0,165 × 1,38 studs**.

Allt nedan mäts mot de talen.

## 1 · Hästsadel `9639407836` — FAIL

`Race horse saddle and Saddle pad`, uppladdad 2022-05-15 av `Josijosi00`
(verifierad), gratis på Creator Store, `hasScripts: false`.

**Rättigheter:** gratis, köpbar, **ingen angiven attribution** i titel eller
beskrivning. Så långt går det att fastställa. Näten den består av
(`3686110091`, `3350805080` ×2, `3686127829`) går **inte** att slå upp i
Creator Store-API:t — de är nätassets, inte butikslistningar — så själva
nätens proveniens kan inte verifieras härifrån. Det blockerar inte i sig,
men det ska sägas.

**Tekniskt, uppmätt i karantän:**

| | kandidaten | vårt |
|---|---|---|
| trianglar | **24 540** | ~444 för hela utrustningen |
| delar | 4 MeshParts | 37 lådor |
| kolliderar | **2 av 4** | 0 |
| `CanQuery`/`CanTouch` | **alla** | inga |
| `Massless` | **ingen** | alla |
| texturer | **inga** | — |
| `PrimaryPart` | **saknas** | — |
| attachments | inga | — |

**Skalan är fel, och det är det avgörande.** Modellens `Top` är **2,38 studs
bred** — bredare än hästens hela bål på 1,86. Mot vår sadelsits:

```
bredd   2,38 mot 1,20 studs   ~2,0x
tjocklek 1,82 mot 0,165       ~11x
längd   2,04 mot 1,38         ~1,5x
```

Hela modellen mäter 0,79 × 1,13 × 0,84 m i vår skala. Den är byggd för en
större rigg än vår kategori D-ponny (mankhöjd 1,45 m).

**Prestanda:** 24 540 trianglar per häst. Trettiotre hästar i stallet ger
**809 820 trianglar** bara i sadlar — mot dagens ~14 650 för all utrustning
på alla hästar. Det är en femtiofemfaldig ökning på en mobilplattform, för
en detalj spelaren ser ovanifrån under ritten.

**Visuellt:** alla fyra delarna bär samma gråblå färg
(`0.357, 0.365, 0.412`) och materialen `Concrete` respektive
`SmoothPlastic`, utan en enda textur. Otexturerad grå betong är inte läder.
Vår egen sadel är åtminstone i `Leather` med sadelbruna färger ur kanon.

**Dom: FAIL.** Inte på rättigheter — på skala, budget och kollisionsläge.
Den skulle behöva skalas till ungefär halva storleken i två axlar och en
tiondel i den tredje, få sina kollisions- och massflaggor nollställda, få en
`PrimaryPart` och texturer. Då är det inte längre "importera en asset" utan
"bygg om en asset", och den frågan hör till Tobias.

## 2 · Hästträns `15966015286` — BLOCKED_FOR_RIGHTS

`Horse bridle [ALWAYS CREDIT RHS FOR IT!]`, uppladdad 2024-01-13 av
`corvyyn` (verifierad), gratis, `hasScripts: false`.

**Rättigheterna är det som stoppar den.** Titeln ställer ett uttryckligt
attributionskrav: *ALWAYS CREDIT RHS FOR IT*. Beskrivningen är **tom**.
Ingenting i asseten säger vem RHS är, och uppladdaren heter inte RHS. Kravets
exakta innebörd — vad som ska stå, var, och till vem — går alltså **inte att
fastställa ur asseten**.

Ordern säger att allt oklart ska markeras `BLOCKED_FOR_RIGHTS`, inte
godkänt. Det gör jag. Att gissa fram en kreditering vore att hitta på en
rättighetsuppgift, och det är samma sorts fel som att hitta på en
UBRF-detalj.

**Tekniskt, för fullständighetens skull:** en enda `UnionOperation`, 1 794
trianglar, 1,04 × 0,59 × 0,50 m, `CanCollide = true`, inte `Massless`, inga
attachments, inga texturer, enfärgat mörkgrå (`0.067` rakt igenom).

En union är dessutom fel verktyg för det här: vårt träns byggs ur hästens
**egen huvudstorlek** (`HX`, `HY0`, `HZ0` ur riggen) så att varje häst får ett
träns som passar just henne. En färdig union har en fast form och kan bara
skalas likformigt.

## 3 · Ryttarhjälm `123547958` — FAIL + BLOCKED_FOR_RIGHTS

`Moldenhauer Family Helmet`, uppladdad 2013-07-22 av `skitzochase`
(verifierad), gratis. **`hasScripts: true`, `scriptCount: 1`.**

**Den bär kod.** Skriptet heter `HatHelperGuideGiverScript` och sitter direkt
på delen. MCP-insättningen **strippade** det — resultatet säger
`removedScriptCount: 1` — men det är verktygets förtjänst, inte assetens. En
manuell Toolbox-import i Studio tar med skriptet. Ordern är tydlig: ingen
tredjepartskod får följa med in i spelet.

**Rättigheterna är oklara på ett obehagligt sätt.** Delen heter internt
`TMNTHelmet`, och beskrivningen lyder *"For safety reason, and war reasons.
:3"*. `TMNT` läser jag som en förkortning för ett känt tredjeparts-IP.
Listningens namn säger ingenting om ursprung eller rättigheter, och nätet
ligger på en legacy-URL (`http://www.roblox.com/asset/?id=93643378`) som inte
går att slå upp i Creator Store-API:t. Att en asset ligger gratis i butiken
säger ingenting om att innehållet får användas.

**Tekniskt:** `Anchored = true`, `CanCollide = true`, massa 2,51, ingen
`Massless`, ingen textur, 0,47 × 0,53 × 0,53 m. En **ankrad** del svetsad på
en ryttares huvud fryser huvudet i världen — den flaggan måste bort innan
delen ens kan sitta på någon.

**Dom: FAIL på kod och flaggor, BLOCKED_FOR_RIGHTS på ursprung.** Båda
räcker var för sig.

## Den minsta produktionssäkra vägen — kraven, inte koden

Ingen kandidat passerade, så **ingen adapter är byggd**. Ordern ber ändå om
vägen, och den här listan är vad ett visuellt lager måste uppfylla den dag en
kandidat passerar:

1. **Tillståndet ägs av servern, oförändrat.** `underlagg` / `sadel` / `trans`
   är kanon. Visuallagret får *läsa* det och bygga nät därefter — aldrig
   skriva det. `TackService.harTack` läser den **fysiska** delen, och det är
   fortfarande sanningen: ett visuellt lager som ljuger om vad som sitter på
   hästen skulle återinföra #162 blockerare 5 i ny form.
2. **Atomiciteten från #210 rörs inte.** Hämtningen är ett par; ett
   visuallager ändrar ingenting i den kedjan.
3. **Ingen ny klientauktoritet.** Nätet byggs på servern, precis som
   `TackRigg` gör i dag, och replikeras. Klienten väljer ingenting.
4. **Inga per-häst-specialfall.** Valet av visual ska gå genom
   `Riggprofiler` — samma väg som `HastVisual` redan använder för hästarnas
   egna nät — inte genom en tabell med hästnamn.
5. **Flaggorna är produktregel, inte smak.** `CanCollide = false`,
   `CanQuery = false`, `CanTouch = false`, `Massless = true` på varje del som
   hamnar på en häst eller en ryttare. Ingen asset får komma in med sina egna
   flaggor.
6. **Inga skript, inga remotes, inga PackageLinks** följer med. Assets
   behandlas som **material**, och materialet är nät och texturer.
7. **Budget.** Dagens hela utrustning är ~444 trianglar per häst. Ett tak
   måste sättas innan en mesh-baserad väg öppnas, och det ska mätas mot
   trettiotre hästar samtidigt på mobil — inte mot en häst i en tom scen.
8. **En regression som bevisar att visuallagret inte kan ändra
   equipment-state** hör till den leverans som bygger lagret, inte till den
   här auditen.

## Så här gick auditen till

Assets inspekterades först **utan** insättning (`preview_asset`: hierarki,
klasser, skriptantal, PackageLinks), och därefter i en karantänmapp
`ServerStorage.__EquipmentGate_Karantan` — alltså **utanför** den accepterade
världen. Dubbelprefixet `__` gör att #209:s integritetsgrind klassar mappen
som verktygsartefakt och inte som drift.

En separat Studio-instans (baseplate) begärdes först för full isolering, men
processen anslöt aldrig till MCP-pluginet. Karantänmappen är alltså
kompromissen, och den **är borttagen**: `Workspace` står på samma 19 barn som
före auditen, och ingenting med `EquipmentGate` i namnet finns kvar i
`ServerStorage`.

`Workspace.Saddle` och `Workspace.Union` som ligger kvar i placen är **inte**
mina — de är två av de femton ospårade objekt #209:s punkt 10e redan
namnger, och de rördes inte.

### `NOT_TESTED`

- **Visuellt skick i viewporten.** Studios 3D-viewport renderade svart för
  varje framing i det här passet — även för den accepterade anläggningen, så
  det är inte kandidaternas fel. Bedömningen av utseendet vilar därför på
  data: material, färg, texturfrånvaro och mått. **Ingen bild är tagen, och
  ingen sådan bedömning påstås.**
- **Licenstext.** Creator Store-API:t returnerar ingen licensuppgift. Det som
  går att fastställa är pris, köpbarhet, uppladdare och vad som står i titel
  och beskrivning.
- **Prestanda uppmätt på riktig mobil.** Trianglarna är räknade, inte
  spelade. Tobias fysiska gate gäller fortfarande.
- **Hoppkandidaterna.** Utanför det här passet enligt ordern.
