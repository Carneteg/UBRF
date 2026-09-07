# F02-C — källinventering och prioriterad avvikelsematris

Datum: 2026-09-07  
Interiörspår: PR #131 → draft-PR #132  
Renderad produktcommit: `c985bbf30150f638b033b878b2e9464b2176429d`  
Evidenscommit: `fb5d7924c5019a6421c3692b2cb616c0c0ea0a4d`

Status: **SOURCE_AUDIT / VISUAL_PACK_READY — inte visuellt eller produktmässigt godkänd.**

## Avgränsning och lås

Inventeringen är skrivskyddad mot källsystemen. Den ändrar inte byggnadsgeometri,
collision, läktare, ridmekanik, Ugneta/gameplay eller webb-/Roblox-kanon.
PR #131 är fortsatt bas och enda interiörspår. PR #132 är en draft mot PR #131:s
branch, inte mot `main`.

Följande får inte ändras utan ny, entydig evidens och separat review:

- `docs/INTERIOR-GEOMETRY-LOCK.json`,
- accepterad läktargeometri och gångbarhet,
- låst byggnadsgeometri, öppningar och collision,
- `src/site.js`, `src/world.js`, `src/model.js` och `src/riding/**`,
- Claude/PR #128:s Ugneta- och gameplayspår.

## Beständigt granskningspaket

Det nya paketet finns i:

`docs/visual-gate/packs/c985bbf30150f638b033b878b2e9464b2176429d/`

Paketet innehåller 21 fasta kamerabilder, `pack.json`, `source-index.json` och
`index.html`. Manifestet anger ren render-head `c985bbf…`, 56 källkopplingar
till 40 unika källor, `VISUAL_PACK_READY` och `product_accepted=false`.
Bildreferenser är länkade till oföränderliga GitHub-blobbar på samma render-head.
Det äldre `docs/visual-gate/pack/` anger `46cbd05…` och är uttryckligen inte ny
evidens.

Vercel:

- spelbar render-head `c985bbf…`:
  `https://ubrf-bb1vsz9pe-tobiascarneteg-5898s-projects.vercel.app`
- draft-PR/evidens-head `fb5d792…`, vars enda nya commit efter render-head är
  evidensfiler:
  `https://ubrf-fch5sdjq7-tobiascarneteg-5898s-projects.vercel.app`
- granskningsindex:
  `https://ubrf-fch5sdjq7-tobiascarneteg-5898s-projects.vercel.app/docs/visual-gate/packs/c985bbf30150f638b033b878b2e9464b2176429d/index.html`

## Källstatus

### GitHub

Reviewbranch och draft-PR är spårbara. Alla 21 nya bilder ligger i den
SHA-namngivna katalogen. Käll-ID:n i manifestet pekar på repo-path och
Git-blob-SHA, inte på mappnamn som visuell evidens.

### Supabase `tdznhaybxmekznasxtts`

`public.reference_assets` innehåller exakt 82 poster:

- 66 foton,
- 5 filmer,
- 6 planer,
- 2 dokument,
- 1 PDF,
- 1 licens,
- 1 referenssamling.

Manifestkontroll mot GitHub:

- 81/82 `github_path` finns lokalt,
- 80 pekar på spårade filer,
- `references/plans/ridhus-entreplan-rektifierad.jpg` saknas,
- åtta stallentrébilder (`stall-entre-07.jpg`–`stall-entre-14.jpg`) har
  bytevärden som inte matchar nuvarande GitHub-filer,
- alla 82 saknar `sha256`,
- alla 82 saknar `storage_verified_at`,
- fem poster saknar `bytes`.

Detta verifierar manifestets struktur och radantal, inte Storage-binärer eller
visuellt innehåll. Full jämförelse:
`docs/source-audit/supabase-github-2026-09-07.json`.

### Google Drive

Liveinventeringen omfattar 230 filer:

| Område | Livefiler | Namn omnämnda i kanon/index | Ej matchade namn |
| --- | ---: | ---: | ---: |
| Byggnaden | 20 | 14 | 6 |
| Omnejd | 11 | 4 | 7 |
| Ridhuset | 116 | 88 | 28 |
| Stallhuset | 83 | 21 | 62 |
| Parkering | 0 | 0 | 0 |
| Models | 0 | 0 | 0 |
| `1.pdf` | 0 | 0 | 0 |

Exempel på ej matchade, potentiellt nyare käll-ID:n är:

- Byggnaden: `IMG_0066`–`IMG_0069`, `IMG_0071`, `IMG_0074`,
- Omnejd: `IMG_0285`–`IMG_0287`, `IMG_0300`–`IMG_0302`, `IMG_0308.MOV`,
- Ridhuset: bland annat `IMG_0205`–`IMG_0209`, `IMG_0251`,
  `IMG_0261`–`IMG_0281` och `IMG_0303`–`IMG_0305`,
- Stallhuset: 62 ej matchade namn, bland annat `IMG_0136`–`IMG_0157`
  och `IMG_0210`–`IMG_0226`.

Drive-listningen exponerar ingen användbar MD5/SHA-256 för dessa poster.
`likely_match` betyder därför endast filnamns-/indexmatchning.
Samtliga 230 är fortsatt `content_verified=false` tills prioriterade binärer
öppnats och jämförts. Full liveinventering:
`docs/source-audit/drive-supabase-github-2026-09-07.json`.

`1.pdf` och Models-licensen finns som externa manifestposter men inte som
livefiler i de listade rotkategorierna. Derivat eller mappnamn får inte användas
som ersättning för originalinnehållet.

## Prioriterad avvikelsematris

| Prio | Rum/zon | Källa och evidensklass | Observerad skillnad/risk | Minsta korrekta nästa steg | Webb/Roblox-paritet | Human gate |
| --- | --- | --- | --- | --- | --- | --- |
| P0 | Spårbar review | `pack.json`, `source-index.json`, Vercel; VERIFIED teknisk proveniens | Äldre paket gällde fel SHA | Använd endast SHA-paketet; ingen visuell rättelse | Samma produktdata på `c985bbf`; evidenscommit ändrar bara docs | Tobias öppnar paketet; ingen automation sätter PASS |
| P0 | Figur, navigation och skymning | 21 kamerors siktprov; AUTOMATED | Tidigare skymd figur/navigation är ett känt underkänt problem; fasta kameror bevisar inte fri spelrutt | Manuell gång- och kamerakontroll i webb och Roblox Studio före korrigering | Route/collision måste skyddas separat i båda | Tobias bedömer game feel; Studio ännu inte manuellt granskat |
| P0 | Stall — uppehållsrum | `stall-inne-01`, `stall-inne-02`, spatial canon; VERIFIED rum, DERIVED möblering | `STALL-UPPEHALL` är avsiktligt `MISMATCH`; hela cirka 10 m och öppen L-form måste synas; soffans exakta fönsterläge är gap | Öppna prioriterade nya Stallhuset-källor; bevara `OPEN_AREA/NO_WALL_ZONE`; korrigera endast källbelagd möblering | Samma öppna topologi och objektidentitet; Roblox-material får vara dokumenterad approximation | Side-by-side + gångbarhet + Tobias PASS |
| P0 | Läktare | låsfil, läktartest, `LAKTARE`; ACCEPTED baseline / AUTOMATED | Tekniska skydd är gröna men ingen ny mänsklig acceptans | Ingen ändring; endast regression och manuell kontroll | Bevara höjd, trappa, collision och vy i båda | Tobias acceptance kvarstår blockerande |
| P1 | Teorisal | `stall-inne-04`, `STALL-TEORISAL`; VERIFIED visuell inventering | Whiteboards, planscher, bord/stolar, skåp/mikro, ljus och kanal finns; status `EJ_GRANSKAD` | Tobias/oberoende side-by-side i nya paketet; rätta bara konkreta fynd | Gemensam metadata finns; visuell likvärdighet måste granskas separat | Ingen `CHATGPT_VISUAL_PASS` eller Tobias PASS ännu |
| P1 | Sadelkammare/teorisalsdörr | `stall-inne-03`, plan; foto VERIFIED, läge ASSUMPTION | Bild visar smal passage och dörr; plan/topologi saknar öppning och bredden motsäger fotointrycket | Granska ny Stallhuset-film/foto; stoppa om läget förblir motsägande | Ingen öppning i endast en implementation | Tobias beslutar vid plan/foto-konflikt |
| P1 | Efter pausrum/service | två PO-varianter + spatial dokumentation; CONFLICT | Slutna rum kontra öppen bukt är olöst | Behåll båda alternativen som `REFERENCE GAP`; klassificera ny Drive-evidens | Ingen asymmetrisk geometri | PO/Tobias väljer endast med evidens |
| P1 | Hästpassage | satellit-/planunderlag; PARTIAL/REFERENCE GAP | Exakt läge, dimensioner och utseende saknas | Öppna relevant Drive-video/foto; ändra inte passage före entydig källa | Samma öppning och collision i webb/Roblox | Manuell traversering och Tobias beslut |
| P1 | Ridhusentré/reception | ridhusbilder/plan; VERIFIED/PARTIAL | Öppen hall och NW-receptionens glas får inte byggas igen; toaletter/okända dörrar är gap | Prioritera ej matchade `IMG_0303`–`IMG_0305` och relevanta filmer; minsta material-/möbelrättning | Samma öppna hall, glas och dörrfunktioner | Side-by-side och Tobias PASS |
| P1 | Ridhusplan | Supabase planpost; MISSING BINARY | `ridhus-entreplan-rektifierad.jpg` saknas i GitHub | Återfinn originalet i Drive/Storage och verifiera rättighet/hash innan eventuell migrering | Ingen geometriändring från manifestpost ensam | Källa måste godkännas före användning |
| P2 | Stallentrébilder 07–14 | Supabase/GitHub; METADATA MISMATCH | Manifestets bytevärden är inaktuella | Jämför faktisk Storage-/Drive-binär, fastställ kanonisk fil och SHA-256; ändra inte bild eller kanon ännu | Ingen produktpåverkan | Proveniensreview |
| P2 | Omnejd/utebanor | Drive `IMG_0285`–`0308`; UNREVIEWED | Identitet, skala, nivåskillnad och grind är okända | Öppna endast relevanta nya filer och klassificera observationer | Om senare byggt: gemensam spatial data | Tobias avgör anläggningsidentitet |
| P2 | Parkering/Models/`1.pdf` | tom livekategori eller extern manifestpost; REFERENCE GAP | Ingen livefil verifierad i aktuell listning | Separat riktad Drive-uppslagning; använd inte mappnamn som bevis | Ingen produktändring | Källa/rättighet måste verifieras |

## Tested

- `python3 tools/build.py` — exit 0 före screenshotpaketet.
- `node tools/screenshot-pack.mjs --ut /tmp/ubrf-review-c985bbf-complete --forvantad-head c985bbf…` — exit 0.
- 21 kameror renderades; siktprovet rapporterade spelaren synlig i samtliga.
- Manifest: exakt render-head, rent arbetsträd, 21 kameror.
- 21 PNG är 1280×720, större än 10 kB, byte-unika och har 2 626–8 798 färger.
- GitHub branch, manifest och index lästes tillbaka efter push.
- Vercel deployment för `fb5d792…` är `success`; både spelstart och paketindex renderar.
- Supabase: projektref matchar, `Content-Range: 0-81/82`.
- Supabase- och Drive-inventeringarna var GET/read-only.

Tidigare oförändrad produktcommit `c985bbf…` hade dessutom grönt
interiörtest, A-gavelguard, 13 läktarmätningar och 14 Roblox-specgrupper.
Evidens- och auditcommits ändrar ingen kod som dessa tester mäter.

## Falsified

- Fel `--forvantad-head` avvisades innan capture.
- Temporär ändring av en spårad fil gav `smutsigt:true`; filen återställdes
  byteidentiskt före commit.
- Små/tomma bilder och duplicerade kameracaptures skulle fälla paketkontrollen.
- Det äldre paketets manifest kontrollerades och anger fortfarande `46cbd05…`,
  inte `c985bbf…`.
- Supabase-connectorns lagrade API-nyckel gav 401 och användes därför inte som
  bevis; read-only-kontrollen gjordes via projektets befintliga Replit-secrets.

## Not tested

- Ingen människa har ännu godkänt side-by-side-vyerna.
- Ingen ny manuell Roblox Studio-runda eller game-feel-test har körts.
- Supabase Storage-binärerna har inte hämtats eller hashats.
- Ingen av de 230 Drive-filerna har i denna inventering visuellt klassificerats.
- Drive-only/ej matchad betyder inte bevisat ny eller ändrad binär.
- Motstridiga mått, okända öppningar, pentryts läge, Plan 2, servicedelen,
  hästpassagen, toaletter, sargporten och uteridbanans nivåskillnad är olösta.

## Remaining risk

Den största risken är att manifest- eller filnamn förväxlas med faktisk visuell
evidens. Därefter följer att kosmetiska rättelser kan dölja tidigare underkänd
rumsskala, navigation eller skymning. Därför är nästa tillåtna steg riktad
granskning av prioriterade original—inte implementation.

## Human gate

Tobias behöver:

1. öppna Vercel-indexet och granska `STALL-TEORISAL`,
2. kontrollera att det är paketet för `c985bbf…`, inte äldre `46cbd05…`,
3. bedöma uppehållsrummets hela storlek/öppenhet och tidigare
   skymnings-/navigationsproblem,
4. senare göra målmiljötest i Roblox Studio där game feel/collision berörs,
5. uttryckligen ge PASS per rum/zon innan `PRODUCT_ACCEPTED` kan sättas.

Ingen agent får själv sätta `PRODUCT_ACCEPTED` eller merga leveransen.