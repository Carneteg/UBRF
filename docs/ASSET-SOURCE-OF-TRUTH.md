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
