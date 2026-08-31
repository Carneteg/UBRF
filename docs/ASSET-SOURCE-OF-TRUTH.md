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

### Källordning — råfilmerna är källa, inte proveniens

Ett `REFERENCE GAP` som satts för att något inte syns i de **utvalda**
stillbilderna är ett påstående om urvalet, inte om anläggningen. Ordningen
en detalj ska sökas i är därför:

1. **råmaterialet** — stillbilderna i `references/buildings/` **och råfilmerna
   i `references/video/`**,
2. plan- och utrymningsritningar i `references/plans/`,
3. verifierade derivat: byggnadskort `KORT.md`, `INTERIOR-MATRIS.md`,
4. aktuell implementation,
5. antaganden — först när steg 1–4 är uttömda och det syns att de är det.

**Ett gap får inte sättas förrän filmerna är genomsökta.** Sök med
`tools/videobevis.py`, som packar upp filmerna helt i stället för att gissa en
cadence, och skriv in vilken film och vilket bildruteintervall som granskats i
`docs/F02-BEVISINDEX.md`. Ett gap utan den noteringen är ogranskat.

sha256 för allt speglingsbart referensmedia står i `references/CHECKSUMS.sha256`
(`sha256sum -c references/CHECKSUMS.sha256`).

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

### Lagringshinken `reference-assets` — egen infrastruktur-PR

Binärspegeln till Supabase Storage hör inte till fidelity-arbetet och
följer därför en **separat PR**, inte F02. Skälet är att de kanoniska
fotona, filmerna och planerna redan är build-åtkomliga i GitHub och
checksumverifierade via `references/CHECKSUMS.sha256`
(`python3 tools/kolla-referenser.py`) — spegeln är redundans, inte en
förutsättning för att bedöma interiörtopologi.

**Läget just nu: hinken är privat och tom.** Manifestrader finns, **noll**
har `supabase_storage_path` satt, och noll objekt ligger i hinken. Det är
redovisat, inte glömt.

Två regler gäller oavsett vilken PR som fyller den:

- **RLS försvagas inte** för att komma runt en saknad privilegierad nyckel.
  En anon-insert-policy hade gjort råfilmerna skrivbara för var och en som
  har den publika nyckeln.
- En manifestrad får inte påstå att en fil är speglad utan att objektet
  verifierats. Regeln ligger i schemat:
  `check (supabase_storage_path is null or storage_verified_at is not null)`.

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
