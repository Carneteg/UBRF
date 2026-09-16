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


---

# Andra passet: jakten på ersättare

Ordern efter PR #212: de tre ursprungliga är avvisade eller blockerade — hitta
bättre kandidater, minst två tekniskt trovärdiga per kategori **om butiken
faktiskt har dem**, och `NO_VIABLE_CANDIDATE` är ett bättre svar än en sänkt
ribba.

Mätt 2026-09-16 på `main` `541fa4aca1e0b8c14d11a3b92046a8b360779700`.
`bygg-identitet.py --kontrollera` grön, `rojo-sanning.py` 68 lika · 0 olika ·
0 oparade, `kor.sh` 37/37.

## Domarna, andra passet

| kategori | kandidat | asset | dom |
|---|---|---:|---|
| sadel | Race horse saddle (återuppladdad) | `82966041045527` | **FAIL + BLOCKED_FOR_RIGHTS** |
| sadel | horse hanging saddle decoration (CREDIT RHS) | `16245590175` | **BLOCKED_FOR_RIGHTS** |
| sadel | Working horse saddle | `4505046158` | **NO_VIABLE_CANDIDATE** (kunde inte granskas) |
| sadel | Sadles | `8709973262` | **NO_VIABLE_CANDIDATE** (kunde inte granskas) |
| träns | Horse with tack | `8512123329` | **FAIL + BLOCKED_FOR_RIGHTS** |
| träns | Horse Halter | `15057288717` | **NO_VIABLE_CANDIDATE** (kunde inte granskas) |
| hjälm | USPP Riding Helmet | `15813214956` | **FAIL** |
| hjälm | Helmet (Everest) | `16690671412` | **FAIL** |
| hjälm | uspp riding helmet (motor and horse) | `15860424841` | **NO_VIABLE_CANDIDATE** (kunde inte granskas) |

**Ingen kategori fick en `PASS_FOR_PROTOTYPE`.** Det beror inte på att ribban
är för hög — det beror på två olika saker, och de ska hållas isär.

## Det som föll på egna meriter

**`82966041045527` — en återuppladdning, och det syns i talen.** Samma namn
som den avvisade `9639407836`, **exakt samma trianglar och hörn** (24 540 /
16 586), men en annan uppladdare (`AidenHunter1919`), fyra år senare
(2026-09-11 mot 2022-05-15) — **och sex skript som originalet inte har**.

Det är signaturen för en stulen asset med kod påhängd. Den ska inte in i
spelet, och den hade dessutom fallit på exakt samma skala och budget som
originalet.

**`16245590175` — samma okontrollerbara kreditkrav.** Titeln säger *CREDIT
RHS*, uppladdaren är samma `corvyyn` som tränset i första passet, och vem RHS
är går fortfarande inte att fastställa. 20 000 trianglar, och det är dessutom
en **dekoration** — en sadel som hänger på en vägg, inte en sadel som sitter
på en häst.

**`8512123329` "Horse with tack"** — 32 694 trianglar, 35 MeshParts, **2
skript**, 5 animationer och 19 decals. Beskrivningen säger *"made by cookie
and me"*: delat upphovsmanskap där andra halvan bara heter "cookie". Det är
en hel häst med utrustning, inte utrustning, och den bär kod.

**`15813214956` "USPP Riding Helmet" — femton skript.** Metadata räcker för
domen; ingen granskning behövdes.

**`16690671412` "Helmet"** — skriptfri och 7 242 trianglar, men det är en
**Everest-hjälm**, alltså klättring. Fel produkt för en ridskola. Att den
tekniskt går att bära gör den inte till en ridhjälm.

## Det som INTE gick att granska — och varför

Fyra kandidater föll inte på sina meriter. De gick inte att öppna.

```
insert_asset 9639407836 (första passets sadel)   -> success
insert_asset 4505046158                          -> Failed to load asset:
insert_asset 8709973262                             User is not authorized to
insert_asset 15057288717                            access Asset. To load public
insert_asset 15860424841                            Creator Store assets that you
                                                    do not own, enable "Allow
                                                    Loading Third Party Assets"
                                                    in Game Settings > Security.
```

Kontrollmätningen är den översta raden: **den asset Tobias själv hämtade
2026-09-13 går att sätta in**, alla nya gör det inte. Slutsatsen —
`[antagande]`, för jag kan inte läsa kontots inventarium — är att de tre
ursprungliga redan ligger i kontots ägo, medan allt annat räknas som
tredjepartsinnehåll.

**Placen har alltså "Allow Loading Third Party Assets" AV**, och det är en
säkerhetsinställning i Tobias produktionsplace. Att slå på den ändrar vad den
KÖRANDE spelet får ladda, inte bara vad jag får titta på. **Jag har inte rört
den**, och den är inte min att röra.

Utan granskning går det inte att mäta det krav 4 och 5 i ordern kräver —
dimensioner mot hästens rigg, `Anchored`/`CanCollide`/`CanQuery`/`CanTouch`/
`Massless`, material, texturer, attachments. Och utan de måtten får ingen
kandidat ett `PASS_FOR_PROTOTYPE`. Ordern säger uttryckligen: tvinga inte
fram ett godkännande.

## De tre som förtjänar en omgranskning

För första gången i den här gaten finns kandidater i **rätt budgetklass**.
Vår hela procedurella utrustning är ~444 trianglar per häst:

| kandidat | trianglar | skript | uppladdare | not |
|---|---:|---:|---|---|
| `4505046158` Working horse saddle | **108** | 0 | TiredTato | inga MeshParts alls — ser ut att vara byggd av delar |
| `8709973262` Sadles | **564** | 0 | IoannisKomnenos | 2 MeshParts |
| `15860424841` uspp riding helmet | 5 554 | 0 | BillActual | 1 MeshPart, **1 decal** |
| `15057288717` Horse Halter | 6 722 | 0 | MeriTheLegume | grimma, inte träns; beskrivningen säger att hon gjort den själv i Blender |

De två första är de första sadelkandidaterna som över huvud taget ligger nära
vår egen budget — `4505046158` är **en fjärdedel** av vad vi bygger själva i
dag, mot `9639407836`:s femtiofem gånger.

Två varningar som gäller redan innan granskningen:

- **`15860424841` bär en decal, och "USPP" är någon annans märke.** En
  ridhjälm med en främmande grupps insignier på UBRF:s ryttare är en
  visuell och rättighetsmässig fråga, inte bara en teknisk.
- **`15057288717` är en grimma, inte ett träns.** Den hör till ledning
  (#200), inte till uppsittning. Som *tränskandidat* är den fel produkt;
  som grimma kan den bli intressant i en annan order.

## Rekommendation

**Ingen prototyporder ännu**, för ingen kandidat har nått
`PASS_FOR_PROTOTYPE`.

Det som skulle låsa upp passet är **ett** beslut från Tobias: att slå på
*Allow Loading Third Party Assets* i Game Settings > Security för placen, med
vetskapen om att det påverkar vad spelet får ladda i drift och inte bara vad
en audit får se. Sägs ja kan de fyra kandidaterna ovan granskas i karantän på
samma sätt som första passets tre, och `4505046158` och `8709973262` är de
som förtjänar att mätas först.

Sägs nej står gaten still på visuals, och dagens procedurella utrustning är
fortfarande den som gäller — den är korrekt, billig och byggd ur varje hästs
egna mått. Det är inget nödläge.

### `NOT_TESTED`, andra passet

- **Hierarki, flaggor, mått, material och texturer** för `4505046158`,
  `8709973262`, `15057288717` och `15860424841`. Blockerat, se ovan.
- **Kontots inventarium.** Jag kan inte läsa vilka assets kontot äger; att de
  tre ursprungliga går att sätta in och inga andra är en **mätning**, men
  förklaringen är ett antagande.
- **Visuellt skick.** Samma begränsning som i första passet: Studios viewport
  renderade svart för varje framing, även för den accepterade anläggningen.
- **Licenstext.** Creator Store-API:t returnerar ingen licensuppgift.
- **Hoppkandidaterna.** Fortfarande utanför — separat arena-/miljögate.


---

# Tredje passet: kandidaterna öppnade — och bilden avgjorde

Tobias slog manuellt på **Experience Settings > Security > Allow Loading Third
Party Assets**. Därmed gick de fyra blockerade kandidaterna att granska.

Mätt 2026-09-16 på `main` `541fa4aca1e0b8c14d11a3b92046a8b360779700`.
`rojo-sanning.py` 68 lika · 0 olika · 0 oparade, `bygg-identitet.py
--kontrollera` grön, `kor.sh` 37/37.

**Inställningens läge: `ON` under hela passet**, verifierat funktionellt —
`insert_asset 4505046158` gick igenom, vilket det inte gjorde före. Jag har
inte rört den och lämnar den `ON` enligt ordern.

## Domarna, tredje passet

| kategori | kandidat | asset | dom |
|---|---|---:|---|
| sadel | Working horse saddle | `4505046158` | **FAIL** |
| sadel | Sadles | `8709973262` | **FAIL** |
| hjälm | uspp riding helmet | `15860424841` | **BLOCKED_FOR_RIGHTS** |
| träns | Horse Halter | `15057288717` | **FAIL som träns** |

**Alla tre kategorier: `NO_VIABLE_CANDIDATE`.**

Och det viktigaste av allt: **den tekniskt bästa kandidaten föll på bilden.**
Talen sa "bäst i fältet". Bilden sa Napoleonkrigen.

## Måttstocken, mätt på en riktig häst i runtime

`Rida nu` på Blackrock Jack, `TackRigg`s egna delar:

```
Underlägg            1.32 x 0.07 x 1.80 studs   (0.44 x 0.02 x 0.60 m)
Sadel                1.20 x 0.17 x 1.38 studs   (0.40 x 0.06 x 0.46 m)
Sadelns gjord        0.62 x 0.10 x 0.33 studs
Träns                1.13 x 0.05 x 0.14 studs
Tränsets pannband    1.11 x 0.06 x 0.06 studs
hästen                2.23 x 5.27 x 7.64 studs
ryttarens huvud       1.16 x 1.11 x 1.14 studs
```

Hästarna är olika stora — Oska mäter 2.09 × 2.63 × 6.24 i bålen mot Jacks
1.86 × 2.34 × 5.55. Det är därför `Riggprofiler` finns, och det är därför en
färdig modell med **fast** storlek är ett problem och inte en detalj.

## 1 · `4505046158` Working horse saddle — FAIL

| | uppmätt |
|---|---|
| geometri | 9 `Part`, **0 meshar**, 108 trianglar |
| mått | 4.00 × 5.41 × 4.36 studs (1.33 × 1.80 × 1.45 m) |
| flaggor | CanCollide **9/9** · CanQuery **9/9** · CanTouch **9/9** · Massless **0/9** · Anchored **9/9** |
| material | Fabric ×7, Metal ×2 |
| texturer/decals | inga |
| skript / PackageLinks | 0 / 0 |
| attachments | inga · ingen `PrimaryPart` |

**Budgeten är utmärkt** — 108 trianglar är en fjärdedel av vår hela
utrustning. Allt annat är fel.

**Den bär en `Seat`.** En `Seat` på 2.61 × 0.05 × 3.07 studs ligger i modellen.
Det är ingen tredjepartskod, men det är ett **funktionellt gameplay-objekt**:
Roblox svetsar fast den som rör den. Vår uppsittning ägs av `HorseService`
med serverauktoritet, och en lös sits på hästen är en väg runt den. Den
skulle behöva rivas — och att den finns säger vad modellen är byggd för.

**Skalan är fel i en annan riktning än förra passets.** 4.00 studs bred mot
hästens bål på 2.23 — nästan dubbelt så bred som hästen — och 3.3 gånger vår
egen sadel.

**Visuellt** (bild tagen i karantänscenen): en grov brun **låda** med öppen
ovansida. Den läser som ett tråg eller ett flak, inte som en sadel.

## 2 · `8709973262` Sadles — FAIL, och det är den intressanta domen

| | uppmätt |
|---|---|
| geometri | 2 `MeshPart`, samma mesh (`rbxassetid://6906416080`), **564 trianglar totalt** |
| mått per del | 4.03 × 3.78 × 3.12 studs (1.34 × 1.26 × 1.04 m) |
| flaggor | CanCollide **0/2** · CanQuery 2/2 · CanTouch **0/2** · Massless **2/2** · Anchored **0/2** |
| material | Fabric |
| texturer | **2 — den enda texturerade kandidaten** |
| skript / PackageLinks | 0 / 0 |

**På pappret är den bäst i hela gaten.** 282 trianglar per sadel — mot vår
hela utrustning på ~444 och mot första passets 24 540. Trettiotre hästar
skulle kosta 9 306 trianglar. Flaggorna är nästan vår policy redan: bara
`CanQuery` står kvar. `MeshPart` skalar rent, till skillnad från en union.

**Och sedan tittade jag på den.**

Det är ingen engelsk ridsadel. Det är en **napoleonsk kavallerisadel**:
leopardfäll över sitsen, schabrak i mörkblått med röd och guldfärgad bård,
**kejserlig örn och krona** broderade på båda sidor.

Det är inte en detalj man skalar bort. `CLAUDE.md` är hårdast just här:
anläggningen ska kännas igen, verkligheten är facit, och **stiliserat betyder
förenklat — inte påhittat**. En husarsadel med kejsarörn på en lektionsponny
i Bro är påhittat innehåll av precis den sort regeln finns för att stoppa.

**Dom: FAIL på produktsanning.** Tekniskt hade den räckt. Det är därför det
visuella steget inte är en formalitet.

Heraldiken är historisk och inte ett modernt varumärke, så det är ingen
IP-blockerare — men det är främmande ornamentik på varje häst i stallet.

## 3 · `15860424841` uspp riding helmet — BLOCKED_FOR_RIGHTS

| | uppmätt |
|---|---|
| geometri | 15 delar: **8 `UnionOperation`**, 1 `MeshPart`, 1 `SpecialMesh`, 5 `Part` |
| trianglar | 5 554 |
| mått | 2.00 × 1.69 × 1.73 studs mot ryttarens huvud 1.16 × 1.11 × 1.14 → **1,7× huvudbredden** |
| flaggor | CanCollide 1/15 · CanQuery **15/15** · CanTouch **15/15** · Massless **0/15** · Anchored **15/15** |
| decals | **1 — `rbxassetid://15812851953`** |
| attachments | 2 · `PrimaryPart` satt |
| skript / PackageLinks | 0 / 0 |

**Bilden avgör, och den gissar ingenting.** Det är en **polishjälm för
motorcykel**: vit och blå kåpa, svart hakrem, **skärm med guldfärgad snodd**
och ett **guldfärgat polisemblem** fram. Assetens eget namn säger "motor and
horse".

Det är uniform och myndighetsinsignier — någon annans märke, på UBRF:s
ryttare. Ordern säger att USPP-frågan inte får gissas bort. Den gissas inte:
den är fotograferad.

Tekniskt är den dessutom svag för vårt bruk: åtta unioner är den dyraste
geometriklassen på mobil och den som skalar sämst, alla femton delarna är
ankrade, och ingen är massless.

## 4 · `15057288717` Horse Halter — FAIL som träns

| | uppmätt |
|---|---|
| geometri | 2 `MeshPart` (`default`, `rings`), 6 722 trianglar |
| mått | 1.75 × 2.31 × 1.42 studs (0.58 × 0.77 × 0.47 m) |
| flaggor | CanCollide 2/2 · CanQuery 2/2 · CanTouch 2/2 · Massless **0/2** · Anchored 0/2 |
| texturer/decals | inga |
| attachments | inga · ingen `PrimaryPart` |
| skript / PackageLinks | 0 / 0 |

**Det är en grimma, och en grimma är inte ett träns.** Ordern säger det rakt
ut, och bilden bekräftar produkten: ett blått nylongrimma med metallringar,
utan bett, utan tyglar, utan pannband på tränsets vis.

Rättigheterna är de renaste i hela gaten — uppladdaren skriver att hon gjort
den själv i Blender, och det finns inget märke på den. **Den hör hemma i en
annan order:** ledning (#200) använder grimma och grimskaft i verkligheten,
och då är 6 722 trianglar ett tal att väga mot vad den ersätter, inte mot
tränset.

## Sammanfattning: varför ingen av dem

| | budget | flaggor | skala | rättigheter | produkt |
|---|---|---|---|---|---|
| `4505046158` | ✔ 108 | ✘ allt fel + `Seat` | ✘ 1,8× hästen | ✔ | ✘ låda |
| `8709973262` | ✔ 282/sadel | ✔ nästan | ✘ 3,3× | ✔ | ✘ **napoleonsk kavalleri** |
| `15860424841` | ~ 5 554 | ✘ ankrad | ~ 1,7× huvudet | ✘ **polisemblem** | ✘ motorcykelhjälm |
| `15057288717` | ✘ 6 722 | ✘ ej massless | ✔ rimlig | ✔ | ✘ grimma, inte träns |

## Vad passet faktiskt visade

**Fri-asset-korpusen för ridutrustning är inte byggd för en svensk
ridskola.** Fyra bredare sökningar och sju granskade kandidater över tre pass
har gett: en stulen återuppladdning, två med kreditkrav som inte går att
verifiera, tre med skript, en polisuniform, en napoleonsk kavallerisadel, en
låda och en grimma.

Det som faktiskt fungerar i dag är `TackRigg`: **37 delar, ~444 trianglar,
noll kolliderande, alla massless, byggd ur varje hästs egna mått**. Ingen av
de sju kandidaterna slår den på helheten, och bara en slog den på budget.

**Rekommendationen är därför inte en till assetjakt.** Vill Tobias ha
mesh-kvalitet på utrustningen är vägen antingen en beställd/egen modell som
följer stallkortet, eller en riktad sökning efter *engelsk* dressyr-/
hoppsadel utan märken — med produktsanningen som första filter, inte som
sista.

## Städning och slutläge

Karantänen `ServerStorage.__EquipmentGate_Karantan` och granskningsscenen
`Workspace.__GranskningsScen` är borttagna, och de fjorton kopior av
kandidaterna som hamnade i `Workspace` under passet är städade — de fyra
rotnamnen `Horse saddle`, `Sadles`, `helmet` och `halter` finns inte kvar.

**En avvikelse ska redovisas:** `Workspace` hade **19** barn före passet och
har **26** efter min städning. De sju nya heter `LV cap` ×3, `Scene` ×2 och
två till `Model` — **inga av dem är mina**; jag satte bara in de fyra
kandidaterna, och de är borta. De ser ut som verktygsinföranden från Studio
under samma fönster. Enligt #171/#209 klassar jag och raderar inte: de står
nu i punkt 10e:s lista nästa gång preflighten kör.

`Workspace.AllowThirdPartySales` är oförändrad (`false`).
*Allow Loading Third Party Assets* lämnas **`ON`** enligt ordern.

### `NOT_TESTED`, tredje passet

- **Slutlig visuell och produktmässig bedömning.** Bilderna är tagna och
  beskrivna, men om en napoleonsk kavallerisadel eller ett polisemblem är
  acceptabelt är Tobias beslut, inte mitt.
- **Prestanda på riktig mobil.** Trianglarna är räknade, inte spelade.
- **Fästbarhet i praktiken.** Ingen kandidat har monterats på en häst — det
  vore produktionsintegration, och ordern förbjuder den.
- **Licenstext.** Creator Store-API:t returnerar ingen licensuppgift.
- **Hoppkandidaterna.** Fortfarande utanför — separat arena-/miljögate.
