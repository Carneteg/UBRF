# UBRF — Asset & Source of Truth

Status: CANONICAL

## Grundregel

Google Drive får vara **insamlingsyta**, men får aldrig vara en teknisk förutsättning för att Claude, ChatGPT, Roblox-versionen eller webbversionen ska kunna byggas, testas eller verifieras.

Allt material som behövs för implementation eller verifiering ska finnas i minst en av dessa två kanoniska ytor:

1. **GitHub** — kod, styrdokument, verifierade referensbilder/frames, byggnadskort, siteplan, licenser och andra utvecklingsartefakter.
2. **Supabase** — speldata, katalogdata och ett sökbart manifest över referens-/assetmaterial. Binära runtime-assets får läggas i Supabase Storage när de behövs där.

För kritiskt referensmaterial är målet att både GitHub och Supabase ska kunna tala om **vad materialet är, var det finns och vilken verifieringsstatus det har**.

## Drive-policy

- Drive är upstream/originalkälla när Tobias lägger in nytt foto, film, PDF eller modellmaterial där.
- Ett nytt Drive-material är inte automatiskt build-ready.
- Innan material får vara beroende för en task ska relevant del migreras eller härledas till GitHub/Supabase.
- Claude ska aldrig stoppas av att Drive inte går att läsa.
- Om endast Drive-version finns: markera `[DRIVE-ONLY]` och behandla det som en migrationslucka, inte som implementerbar sanning.
- Om originalmedia är mycket stort får GitHub innehålla verifierade frames/derivat + proveniens medan Supabase-manifestet pekar på den kanoniska utvecklingskopian.

## GitHub

GitHub är den primära utvecklingssanningen för:

- `CLAUDE.md`
- `docs/`
- `references/`
- `roblox/`
- `src/`
- migrationsfiler
- audit/resultat
- testbevis som behövs för review

`references/` ska innehålla det material Claude faktiskt behöver för att bygga mot verkligheten: utvalda bilder/frames, mått, byggnadskort, siteplan, licenser och tydliga reference gaps.

## Supabase

UBRF-projektet i Supabase innehåller runtime-/speldata. Tabellen `public.reference_assets` är asset-manifestet.

Varje relevant referenspost kan ange:

- `github_path`
- `github_url`
- `supabase_storage_path`
- originalkälla/proveniens
- verifieringsstatus
- om materialet är build-kritiskt

RLS är aktiverad. Manifestet ska inte göras publikt bara för att förenkla utveckling.

## Plattformskanon

**Roblox är huvudplattformen där spelet primärt spelas.**

Samtidigt ska UBRF finnas som **spelbar HTML/webbversion**, inte bara som ett internt testverktyg. Webbversionen ska vara lätt att öppna och prova utan Roblox-klient och får användas för snabb utveckling, QA och delning.

Det betyder:

- Roblox är primär spelplattform och slutlig Roblox-implementation är ett förstaklassresultat.
- HTML/webb är också en riktig spelbar distribution av samma kärnupplevelse.
- Gemensamma gameplayregler, parametrar och acceptance criteria ska hållas motoroberoende där det är rimligt.
- Ingen plattform får driva spelets design i en riktning som gör den andra onödigt omöjlig att hålla spelbar.
- Plattformsspecifik rendering/input får skilja sig, men kärnloopen, lärandet, hästlogiken och UBRF-världen ska motsvara varandra.

## Nuvarande Drive-inventering 2026-08-29

Drive-mappen `UBRF` innehåller vid senaste inventeringen:

- `1.pdf` — `[DRIVE-ONLY]` tills binären/ett verifierat derivat finns i GitHub eller Supabase.
- `Models/License.txt` — migrerad till `references/licenses/quaternius-cc0.txt` i GitHub.
- `Models/Blends/` — tom vid inventeringen.
- `Models/OBJ/` — tom vid inventeringen.
- `Models/FBX/` — tom vid inventeringen.
- `Models/glTF/` — tom vid inventeringen.

Tomma mappar är inte assets och skapar inget build-beroende.

## Definition of done för nytt källmaterial

Ett nytt referensmaterial är redo för implementation när:

1. det kan nås utan att Claude behöver Drive,
2. dess proveniens är dokumenterad,
3. det har en GitHub-path och/eller Supabase-lokalisering,
4. verifieringsstatus är tydlig,
5. eventuella licensvillkor finns i repo,
6. tasken kan genomföras även om Google Drive är helt otillgängligt.

## Hästmallen `k3` — proveniens och kvarstående osäkerhet (2026-09-24)

Gäller `ServerStorage.HastVisualer.k3`, den modell hästarnas nät monteras
ur. Statusen skrivs här i stället för i en PR-kommentar, eftersom det är
en **källfråga** och inte en implementationsdetalj.

### Vad som är belagt

| fakta | källa |
|---|---|
| profilen `k3` anger `kalla = "Creator Store 5878963783 (jameesbound)"` | `roblox/src/shared/HorseCore/Riggprofiler.luau:39` |
| profilens mått är avlästa ur modellen (`mankhojd = 5.78` studs, tackfästen ur dess egen inbyggda utrustning) | samma fil, noten ovanför `PROFILER` |
| asset 5878963783 heter `horse`, `AssetTypeId 10` (Model), skapad av användaren `jameesbound` (id 1013626927) | `https://economy.roblox.com/v2/assets/5878963783/details`, hämtad 2026-09-24 |
| assetens `Created` och `Updated` är båda `2020-10-26` | samma svar |
| `IsPublicDomain: true`, `IsForSale: false`, `PriceInRobux: null` | samma svar |
| modellen finns i startplacen `106030782437053` | Tobias öppnade placen 2026-09-24 |
| **inventerad direkt ur DataModel 2026-09-24:** 84 descendants — 40 `MeshPart`, 40 `Motor6D`, 2 `Part`, 2 `WeldConstraint`; `PrimaryPart = HumanoidRootPart`; **40 unika nät**, `rbxassetid://4863471909` … `4863476316` | Studio-MCP mot place `106030782437053`, `gameId 10766192504` |

Hämtningen är gjord två gånger oberoende av varandra — av ChatGPT i
granskningen av `259b421` och av Claude i R3 — med samma svar.

### Vad som INTE är belagt

1. **`IsPublicDomain` är inte en licensbestämning.** Fältet betyder att
   assetet är fritt att ta i Roblox egen katalog, under Robloxs villkor.
   Det säger ingenting om upphovsrätt utanför plattformen och får inte
   skrivas om till CC0 eller «fri att använda». Ingen licenstext från
   upphovspersonen finns i repot.
2. **Att `k3` är den häst Tobias vill ha visuellt.** Det finns ett
   tidigare material, `Horse Rigged All Gaits.blend`, och ingenting
   binder ihop de två. De antas **inte** vara utbytbara.
3. **Att kopian i startplacen är oförändrad** mot 5878963783. Att assetet
   aldrig uppdaterats sedan 2020 gör det rimligt, men det är inte samma
   sak som en jämförelse.

### Vägen in i bygget

Byggaren `tools/bygg-place.py` kan sedan 2026-09-24 bära ett `.rbxmx`-
beroende med bevarade mesh-/textur-id, transformer, joints, PrimaryPart
och kollisionsfritt omskrivna referenser — se `tools/testa-modellimport.py`.
`tools/kolla-hastmodell.py` vaktar resultatet och slår på sig själv så
snart `default.project.json` mappar modellen.

*(historiskt, 2026-09-24 — löst, se nedan)* **Kvarvarande blockerare:** själva filen. `k3` fanns då bara i startplacen,
och den vägen ut krävde Studio. Se `[REFERENCE GAP]` nedan.

- **LÖST, verifierat 2026-09-26 (INFRA-4A):** `roblox/assets/hastvisualer-k3.rbxmx`
  finns i repot sedan `e9c28d5`: 238 888 byte, SHA256
  `43652860a758aa86d1f03dcf55a466755e8616d3de098258e3d4d6c6aff0b6f6`, XML (`<roblox `),
  40 `MeshPart` och 40 `Motor6D`, samma som inventeringen ovan. Gäller
  K3-mallen, INTE den valda assetten Horse Rigged All Gaits (se nästa avsnitt).
  Texten nedan är historisk.
- *(historiskt)* `[REFERENCE GAP]` `roblox/assets/hastvisualer-k3.rbxmx` saknades —
  **numera av EXPORTFORMAT, inte av åtkomst.**

  Studio är anslutet sedan 2026-09-24 (place `106030782437053`,
  `gameId 10766192504`), modellen är läst och inventerad — men den
  programmatiska exporten skriver **binärt** `.rbxm` oavsett
  filändelse: `export_rbxm` med `.rbxmx` gav 12 560 byte med magin
  `<roblox!`, inte `<roblox `. Motorn har ingen dokumenterad
  Luau-väg som serialiserar en INSTANS till XML — `DataModel` har
  `SavePlace` (deprekerad, gäller placen) och ingenting för en
  enskild modell.

  Den kanoniska artefakten är `.rbxlx`, alltså XML, så ett binärt
  delträd går inte att bädda in.

  **Konkret åtgärd, ett steg:** högerklicka
  `ServerStorage.HastVisualer.k3` i Studios Explorer →
  **Save to File…** → spara som `hastvisualer-k3.rbxmx` i
  `C:\Users\Tobias Carneteg\Desktop\UBRF\roblox\assets\`. Ändelsen `.rbxmx` är det som gör filen till XML.
  Det ändrar ingenting i placen.

## Horse Rigged All Gaits — vald asset, källkedja och gap (2026-09-26, INFRA-4A)

Beslutet är att den valda hästmodellen är **Horse Rigged All Gaits**, INTE `k3`
(PR #264, kommentar `5843082008`; grinden G-ASSET i `docs/LEVERANSMATRIS.md`).
`k3` förblir produktionens nuvarande rigg tills en granskad väg ersätter den.
Nuvarande roster och ID:n bevaras. Det här avsnittet dokumenterar källan. Det
är inte en implementerad rigg, en render eller ett spelbevis.

### Primärkällor, lästa 2026-09-26 cirka 06:18 UTC

| uppgift | källa | status |
|---|---|---|
| titel "Horse Rigged All Gaits", uppladdare `fdoss001`, sidans licensetikett **CC0**, "Blender 2.9x · Eevee", 584 MB, "Uploaded about 5 years ago" | https://blendswap.com/blend/28627 | VERIFIED (sidans etikett) |
| beskrivningen: "I was tired of not being able to find a good horse online so I made this." — nämner ingen annan upphovsperson | samma sida | VERIFIED (sidans text) |
| **tredjepartskommentar** av `Ailuros`: "The original horse mesh is by Tarnyloo. https://blendswap.com/blend/17172" (upprepad) | samma sida, kommentarsfältet | VERIFIED att kommentaren finns — INTE att påståendet stämmer |
| titel "Horse", uppladdare `Tarnyloo`, licensetikett **CC-BY**, "Blender 2.7x · Blender Internal", "Uploaded over 10 years ago"; **ingen licensversion och ingen attributionstext visas** | https://blendswap.com/blend/17172 | VERIFIED (sidans etikett); licensversion `[REFERENCE GAP]` |
| #247 anger källfilen `C:\Users\Tobias Carneteg\Downloads\Horse Rigged All Gaits.blend`, cirka 613 MB | issue #247 | en uppgift, inte ett filbevis |

584 MB på sidan och cirka 613 MB i #247 är förenliga (613·10⁶ byte ≈ 584,6 MiB).
Det bevisar ändå inte att en lokal fil är just den filen.

### Vad som INTE är belagt

1. **Att hela paketet är CC0.** Sidans etikett är CC0, men en kommentar pekar
   ut originalnätet som Tarnyloo:s CC-BY-modell. Kommentaren bevisar inte en
   härledning, men den gör att CC0 för hela paketet inte kan antas.
   `[REFERENCE GAP]` per beståndsdel: nät, rigg, animationer (actions),
   material och eventuell utrustning har okänd upphovsperson tills det finns en
   jämförelse eller ett uttalande.
2. **Vilken CC-BY-version Tarnyloo upplåtit.** Sidan visar ingen version, och en
   generell länk till CC BY 4.0 får inte tas som bevis. `[REFERENCE GAP]`
3. **Den lokala filens identitet.** Filen finns inte (se inventeringen), så
   ingen SHA256 kan anges. `BLOCKED`
4. **Rättsligt klartecken.** Det ges inte här. Beslutet att använda en
   beståndsdel under oklar licens är Tobias, och det kräver underlag.

### Inventering (en gång, avgränsad), 2026-09-26 06:17 UTC

**Sökta rötter:**
- `C:\Users\Tobias Carneteg\Downloads`, två nivåer: `*.blend`, `*.blend1`,
  `*horse*`, `*hast*`, `*gait*` och `*blendswap*`. Innehållsförteckningarna för
  de fyra arkiven över 50 MB listades, utan uppackning.
- `C:\Users\Tobias Carneteg\Desktop`, tre nivåer: `*.blend`, `*horse rigged*`
  och `*all gaits*`.
- Repots spårade filer: `*.blend`, `all gaits` och `rigged`.

**Resultat:**
- `Downloads\Horse Rigged All Gaits.blend` **finns inte**. Ingen `.blend`-fil
  finns inom det sökta djupet (två nivåer). Djupare mappar och andra
  enheter är inte sökta, så frånvaron där är inte belagd.
- `Downloads\UBRF-20260828T143052Z-1-001.zip` (Drive-export, 297 304 470 byte)
  innehåller `UBRF/Models/Blends/Horse.blend` (2 850 084 byte),
  `Horse_White.blend` och tio andra djur, med `UBRF/Models/License.txt`:
  "LowPoly Models by @Quaternius … CC0 1.0 Universal".
  - **Det är ett annat material** (Quaternius lågpolygonpaket), inte Horse
    Rigged All Gaits.
  - Arkivet är inte uppackat, och ingen SHA256 är tagen eftersom det inte är
    den valda filen.
- `download.zip`, `OneDrive_2026-08-03.zip` och `UBRF-main.zip` innehåller ingen
  `.blend`-fil och inget material från BlendSwap.
- Ingen `.blend`-fil finns på Desktop inom tre nivåer, och ingen bland repots spårade filer.
- Kontrollerade platser för Blender: `PATH` och `C:\Program Files\Blender Foundation`.

Sökningen är avslutad. Ingen ny sökning görs utan en ny ledtråd.

### Offlineverktyg

Blender hittades inte på de kontrollerade platserna (`PATH` och
`C:\Program Files\Blender Foundation`); andra platser är inte sökta. Python
saknar `bpy` och `blender_asset_tracer`.
Ingen installation har gjorts, så verktyget är `BLOCKED` tills filen finns.

När filen finns ska en säker statisk läsning göras i en egen granskningsmapp.
Filen får inte öppnas i ett Blender-läge som kör inbäddade skript. Det kräver
uttryckligen `--disable-autoexec` FÖRE filargumentet, till exempel
`blender --background --disable-autoexec --factory-startup <fil> --python-expr …`.
`--factory-startup` ensamt stänger INTE av inbäddade skript (Blenders manual,
Command Line Arguments, 5.1). Alternativet är en ren blend-parser som inte kör
kod ur filen.

### Status per område

| område | status |
|---|---|
| källsida och etikett 28627 (CC0) | VERIFIED (etikett) |
| kommentaren om Tarnyloo | VERIFIED att den finns; påståendet `[REFERENCE GAP]` |
| licens 17172 (CC-BY, version okänd) | etiketten VERIFIED; versionen `[REFERENCE GAP]` |
| rättigheter för paketet per beståndsdel | `[REFERENCE GAP]` |
| lokal fil och dess identitet | `BLOCKED` (saknas) |
| offlineverktyg | `BLOCKED` (inget installerat, ingen installation i 4A) |
| skala, ben, actions, klipplängder, rottranslation, fästpunkter | `BLOCKED` — inte uppmätt, och inte uppfunnet |

### Vad som kan fortsätta utan assetten

- Allt gameplay- och infrastrukturarbete som inte beror på hästens nät eller
  rigg, till exempel instruktören (på 2A/2B1/2B2) och tävlingens datalager.
- Fästpunktskontraktet som **gränssnitt**: vilka punkter som ska finnas (sadel,
  träns, tyglar, ryttare) och hur `Riggprofiler` bär dem. Det görs utan mätta
  värden, och `k3` fortsätter som produktionsrigg.

### Vad som kräver underlag från Tobias

1. **Filen:** `Horse Rigged All Gaits.blend` (eller BlendSwap-zipen) på en
   angiven plats. Nedladdningen, cirka 584 MB och med konto, görs inte i 4A.
2. **Rättsunderlag:** BELÄGG för rättigheterna per beståndsdel, till exempel
   upphovspersonernas licenstext med version. Attribution eller ett riskbeslut
   ersätter INTE belagda rättigheter. Proveniens och licens per beståndsdel
   förblir `[REFERENCE GAP]` tills belägg finns, och inget generellt
   riskgodkännande begärs.
3. **Verktyget:** tillåtelse att installera Blender (gratis) eller ett
   parserbibliotek för den statiska läsningen.

### Minsta nästa offlinepaket (4B), när 1 och 3 finns
1. SHA256 och storlek för filen, jämförda med sidans 584 MB.
2. En statisk läsning i en isolerad mapp, utan autorun:
   - filversion och enheter;
   - objekt, nät, armatur och ben (deformben mot kontrollben);
   - actions med ramintervall och fps;
   - rottranslation per action;
   - befintlig sadel, träns och tyglar samt ryttarfästen.
3. Uppmätt data hålls isär från fästpunktsförslag. Ingen export och ingen
   integration.
