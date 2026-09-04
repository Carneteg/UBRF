# Visual Fidelity Gate — före Tobias review

Issue #78. Gaten finns för att bryta rundan *Claude bygger → Tobias hittar
grundfel*. Automatiken var grön medan väggar dolde spelaren, Ridhuset inte
läste som UBRF och uppehållsrummet var för litet. Därför räcker inte
`Grindar` (geometri, provenance, specar): innan Tobias ser en F02-version ska
den ha gått genom fasta kameror, ett reviewpaket från exakt PR-head, en
siktgrind, spatiala ankare och ChatGPTs visuella review.

Kedjan:

```
Claude bygger → automatiska geometri/navigationstester → fasta screenshots
→ ChatGPT senior visual QA → Claude rättar → Tobias ser endast reviewklar version
```

Statuskedjan för F02:

```
IMPLEMENTED → AUTOMATED_GREEN → VISUAL_PACK_READY → CHATGPT_VISUAL_PASS
→ READY_FOR_PRODUCT_ACCEPTANCE → PRODUCT_ACCEPTED
```

- Claude får sätta t.o.m. `VISUAL_PACK_READY` (paketet finns, från exakt head).
- `CHATGPT_VISUAL_PASS` sätts av ChatGPT efter side-by-side-review av paketet.
- `READY_FOR_PRODUCT_ACCEPTANCE` sätts av ChatGPT; `PRODUCT_ACCEPTED` bara av Tobias.
- **Ingen F02-PR presenteras för Tobias före `CHATGPT_VISUAL_PASS`.**
- Automation sätter aldrig en visuell status. `VISUALLY_ACCEPTED` finns inte;
  verktygen vägrar en kameralista som innehåller den.
- **En grön CI betyder inte visual fidelity.**

`docs/DELIVERY-PROTOCOL.md` gäller i övrigt oförändrat (Acceptance Contract,
falsifiering, evidens, human gate).

## 1. Fasta reviewkameror

`qa/visual-gate/kameror.json` är listan. Tolv kameror ur #78 plus den
exteriöra `STALL-ANKOMST`, samma ID på webb och Roblox:

| ID | Var |
|---|---|
| `STALL-ANKOMST` | Stallhuset entré från gården (exteriör, spelarens ansats; runda 3) |
| `STALL-ENTRE` | Stallhuset entré inifrån |
| `STALL-UPPEHALL` | Uppehållsrum |
| `STALL-UPPEHALL-SOFFA` | Uppehållsrummets soffhörna i fotots vinkel (stall-inne-01); explicit kamera, tillkom med F02-B (#76) |
| `STALL-KLUBBDORRAR` | Klubbdelens inre entré från gång A — dörrläsbarhet (review 2026-09-04 07:54 blocker 4); explicit kamera |
| `RIDHUS-RECEPTION` | Receptionen från skåpgången — glasdisken i NV-hörnet mot skåpraden (blocker 1); explicit kamera |
| `RIDHUS-ENTRE-INNE` | Huvudentrén inifrån — fasadens dörr ritad på väggens insida (blocker 2); explicit kamera |
| `RIDHUS-LAKTARTRAPPA` | Läktartrappan vid H från hallens sydvästra hörn (blocker 3); explicit kamera |
| `RIDHUS-SKAPRUM` | Skåpförvaringen i entrédelens västra remsa (ridhus-klubb-16/-18/-20/-21; Product Owner 2026-09-04 11:56 "Saknas skåp"); explicit kamera |
| `STALL-EFTER-PAUSRUM-V1` | Zonen efter pausrummet från inre entrén ut mot service-/tvättzonen och stallgången (PO 2026-09-04 15:15, `references/spatial/stall-efter-pausrum-po-v1.md`); explicit kamera |
| `STALL-EFTER-PAUSRUM-V2` | Från stallgången tillbaka mot tvätt-/serviceväggen och utgångsrelationen (samma PO-referens); explicit kamera |
| `STALL-TEORISAL` | Teorisal |
| `STALL-SADELKAMMARE` | Sadelkammare |
| `STALL-GANG-A` | Stallgång A |
| `HASTPASSAGE` | Hästpassage |
| `RIDHUS-ENTRE` | Ridhuset entré |
| `RIDHUS-SKAPKORRIDOR` | Skåpkorridor (öppen gång) |
| `ARENA-A` | Arena A-sida |
| `ARENA-C` | Arena C-sida |
| `LAKTARE` | Läktare |
| `C-BLOCK-OVRE` | C-block / övre relation |

Lägena är **uttryck i husens data** (`S` = `STALLINNE`, `R` = `RIDHUSINNE`,
`SA` = `SPELABSTRAKTIONER`) som räknas ut i sidan. Ändras datan följer kameran
med; ett handskrivet tal vore en andra sanning. Kameran är spelets egen
tredjepersonskamera (3,6 m bakom figuren, 2,25 m över hennes golv,
kläms in och lyfts vid väggar) — det spelaren faktiskt ser, inte en fri kamera.

Varje kamera bär `referenser` (repo-sökvägar till verifierat material),
`gap` (det ingen referens visar) och **`ram`** — ramkontraktet: vad som
MÅSTE synas i bilden för att den ska duga som jämförelse. En bild som inte
visar sitt ram-innehåll är fel ställd, inte "klar" (senior review
2026-09-04 05:24: en bild som mest är golv är ingen evidens). Kameran står
i ögonhöjd; där följkameran inte får plats (ett brott i en boxrad) ställs
den explicit med `kamera` + `mal` — fortfarande uttryck i datan.
`granskning` är ChatGPTs fält: `EJ_GRANSKAD` | `MISMATCH` |
`CHATGPT_VISUAL_PASS`, med `av` och `head`. HUD:en döljs i evidensbilderna.

Roblox: samma tolv vyer finns i `roblox/buildings/Vyer.luau`, gruppen
**Visuell grind** (`Vyer.ga("RIDHUS-ENTRE")`), räknade ur `UBRFKomplex`.
`tools/kolla-visuell-grind.mjs` kräver att varje ID finns på båda ytorna.

## 2. Screenshot-pack från exakt PR-head

```
python3 tools/build.py
node tools/screenshot-pack.mjs [--ut qa/screenshot-pack] [--utan-referenser]
```

Skriver `<ID>.png` per kamera, `pack.json` (head-SHA, smutsigt arbetsträd
ja/nej, kameralägen, siktprov, granskningsstatus) och `index.html` —
side-by-side per kamera: referens-ID (med kopia under `ref/`), implementation
@ head, siktprov, **mismatch-status (ChatGPT)**, kvarstående `REFERENCE GAP`.
Paketet är gitignorerat lokalt; CI laddar upp det.

**Exakt head:** på `pull_request` checkar `actions/checkout` annars ut den
syntetiska merge-committen. Workflowen checkar därför ut
`pull_request.head.sha`, asserterar `git rev-parse HEAD` mot den, skickar
den till `screenshot-pack.mjs --forvantad-head` (som vägrar om HEAD skiljer)
och asserterar efteråt att `pack.json.head` är PR-headen och att trädet
var rent. Skiljer något sig är jobbet rött — paketet är då inte evidens.

CI (`.github/workflows/visuell-grind.yml`) kör på varje PR från exakt headen:
kameralista + Roblox-paritet, spatiala ankare, siktgrinden med negativ
kontroll, screenshot-packet som artifact `screenshot-pack-<sha>`, och skriver
EN PR-kommentar (uppdateras vid varje push) med **head-SHA, Netlify-preview
för just den PR:n och länk till paketet**.

## 3. Navigation / wall-occlusion gate

Regeln är rendering, inte geometri: rummen flyttas aldrig för att lösa
skymning (CLAUDE.md). Det som står mellan kameran och spelaren tonas:

- webben `src/varld3d.js`: `tona` (fotavtryck i planet) för väggbitar,
  slutna volymer och domarbåset; `tona3d` (omslutande låda) för
  takinstallationerna, som bara tonas när kameran står uppe bland dem (övre
  gången); kamerahinder (`v3dKameraHinder`) håller kameran ute ur boxraderna
  och domarbåset genom att dra den **in mot spelaren** i stället för till
  närmaste kant;
- Roblox `roblox/src/client/Genomsikt.luau`: attributet `Genomsiktlig`,
  samma sträckeregel.

Mätningen (`v3dSiktProv`): från kameran till fem kroppspunkter (höft, bröst,
huvud, båda axlarna) genom varje opak statisk triangel; det som tonas hoppas
över. Fyra av fem punkter bakom otonad geometri = **DOLD**. Sträckan slutar
0,5 m före figuren så att det hon står intill inte räknas.

```
node tools/siktgrind.mjs
```

provar de tolv kamerorna och gångrutterna genom interiörerna (stallet
entré → gång A → hästgången; ridhuset entré → sargport → bana; hallen →
bänkradssteg → raderna → C-trappa → övre gången; läktardäcket), ~150
punkter. **Negativ kontroll varje körning:** toningen stängs av i sidan och
provet körs om — minst en punkt måste bli DOLD, annars avslutar grinden rött
("minst en avsiktlig visibility-regression ger röd gate").

Roblox: `roblox/tests/sikt.spec.luau` skjuter sträckan reviewkamera → figur
genom de byggda delarna och kräver `Genomsiktlig` på allt som skymmer, med
samma negativa kontroll (utan attributet ska minst en kamera bli DOLD).

## 4. Spatial anchor checks

`references/spatial/UBRF-SPATIAL-ANCHORS.json` är **den enda listan**.
Varje ankare bär `kalla` och `konfidens` (`MEASURED`, `MEASURED_LOCAL`,
`VERIFIED`, `VERIFIED_PLAN_OR_PHOTO`, `VERIFIED_PROPORTION`,
`PRODUCT_OWNER_VERIFIED`, `RELATION`, `DERIVED`) och ett `prov` som räknas ut
i `src/site.js`-kontexten:

```
node tools/kolla-ankare.mjs
```

Värden får bara komma från plan, verifierat underlag eller Tobias. **Ett
rött ankare rättas i datan eller i källan — aldrig i ankaret.** Ett
`DERIVED` ankare får inte bära ett tal. Roblox läser samma data
(`tools/exportera-geometri.js --kontrollera` i `Grindar`), så listan gäller
båda ytorna.

Ankare 2026-09-04: ridhusets och stallets längd, gårdsgapet och hästgången,
hästgångens gränssnitt, dressyr 20 × 60 inuti banan, entrédelen 11,5 m,
receptionens glas, C-trapporna, C-blockets bredd, läktaren väster hela banan,
uppehållsrummets öppna L-yta (kanon v2), inre entrén, stallets bandandelar,
brottet för hästgången.

**Öppet fynd:** toalettrummet NV (`wc_n1`/`wc_n2`) har inget ankare — matrisen
(N 0,3–1,1 / 1,6–2,4), auditen (N 1,2–2,4) och datan (N 0,28–1,38 /
1,38–2,38) säger olika. Flaggat för F02-A-reviewn (#73); inte löst här,
eftersom den här slicen inte får ändra F02:s verklighetsdata.

## 5. Side-by-side evidence pack

`index.html` i paketet, per kamera: referens-ID · implementation-screenshot ·
mismatch-status · `REFERENCE GAP`. Statusen kopieras ur `kameror.json`; en
kamera utan referensbild står som `REFERENCE GAP`. Automation kallar aldrig
något `VISUALLY_ACCEPTED`.

## 6. ChatGPT gate — hur en review går till

1. Claude pushar; CI lägger paketet + preview + head-SHA i PR-kommentaren.
   PR-body: status `VISUAL_PACK_READY`.
2. ChatGPT öppnar `index.html` ur artifacten (eller den incheckade kopian
   under `docs/visual-gate/`), jämför kamera för kamera mot referenserna och
   skriver per kamera `MISMATCH` (med vad) eller `CHATGPT_VISUAL_PASS` i
   `qa/visual-gate/kameror.json` (`av`, `head`) — eller listar dem i
   review-kommentaren så Claude för in dem.
3. Claude rättar `MISMATCH`, pushar, ny runda.
4. När alla tolv är `CHATGPT_VISUAL_PASS` på samma head: `CHATGPT_VISUAL_PASS`
   på PR:n → ChatGPT kan sätta `READY_FOR_PRODUCT_ACCEPTANCE` → Tobias.

## 7. Preview discipline

- Previewn är Netlify deploy-preview för PR:n, byggd från exakt PR-head:
  `https://deploy-preview-<nr>--ubrf-game.netlify.app`.
- PR-kommentaren (CI) innehåller head-SHA + preview + paket. Claudes egna
  rapportkommentarer anger också exakt head-SHA.
- **`main`-länken används aldrig som reviewlänk för en omergad förändring.**
- `pack.json` markerar om paketet renderades från ett smutsigt arbetsträd;
  ett sådant paket är inte PR-evidens.

## Ambienta figurer

Product Owner 2026-09-04 (#78): de tre anonyma gårdsfigurerna
(`gardsFolk()`: grusvägen, picknickborden, lekhagen) är borttagna ur
gårdsscenen. Varje synlig person ska ha en roll — ridlärare, elev, förälder,
stallpersonal. Lektionernas NPC-ryttare (`NPC_ELEVER`) är kvar. Inga nya
dekorfigurer; `tools/kolla-visuell-grind.mjs` faller om `gardsFolk` eller
en gårdsfigurlista dyker upp i `src/` igen. Roblox har inga motsvarande
figurer.

## Hårda regler

- Rör inte accepterad exteriör för att lösa kameraskymning.
- Inga generiska möbler eller påhittade spatiala fakta.
- Roblox och webb delar kanonisk spatial data (`src/site.js` → exportören).
- Roblox Studio är fortsatt slutlig runtime/visual acceptance för Roblox-målet;
  `roblox/docs/STUDIO-QA.md` § Visuell grind.
- Grön CI betyder inte visual fidelity.
