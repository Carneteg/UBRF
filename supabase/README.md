# Supabase — migrationshistoriken

`migrations/` speglar **exakt** den historik projektet
`tdznhaybxmekznasxtts` faktiskt har kört. Filnamnen är versionerna ur
`supabase_migrations.schema_migrations`, och innehållet är de SQL-satser
raderna bär — inte en rekonstruktion ur filnamnen.

Lägg inte till en fil här utan att den motsvarar en verklig migration.
Supabases GitHub-integration jämför den här katalogen mot fjärrhistoriken,
och en fil som inte finns där uppe kommer att köras mot databasen.

## Varför katalogen skrevs om (issue #183)

Supabase Preview var röd med `Remote migration versions not found in local
migrations directory`. Fjärrhistoriken hade sex tidsstämplade versioner;
katalogen hade fyra filer med korta namn som inte motsvarade någon av dem:

| fjärrversion | fanns lokalt som | förhållande |
|---|---|---|
| `20260829070852_ridskolan_ryttare_hastminne_pass` | `0001_ridskolan.sql` | samma objekt, omskriven med kommentarer |
| `20260829100930_create_hastar` | `0003_hastar.sql` | **avvek** — se nedan |
| `20260829193335_add_reference_assets_manifest` | `20260829_reference_assets.sql` | identisk sånär som på radbrytningar |
| `20260830132418_add_ryttarens_jag` | `0002_ryttarens_jag.sql` | samma satser |
| `20260831080829_referensspegel_hink_och_integritet` | — | aldrig committad |
| `20260831112333_reference_assets_lasepolicy` | — | aldrig committad |

De fyra korta filerna var alltså en parallell omskrivning som aldrig var
den körda historiken, plus två migrationer som bara fanns i databasen.

`0003_hastar.sql` var dessutom **inte körbar** mot produktionen: den
infogade i tio kolumner — `kanslighet`, `framatbjudning`, `forlatande`,
`skygghet`, `hoppkapacitet`, `hopplust`, `tyngd`, `utbildning`,
`maxhojd`, `flaggor` — som inte finns i `public.hastar`, och den bar 17 av
33 hästar. Dess generator, `tools/hastar-till-sql.py`, finns inte i repot.
Hästarnas kanon ligger sedan dess i `src/spel/hastar.js`, härledd ur
`references/data/ubrf-hastar-2026-09-01.json`.

Ingenting kördes mot databasen för att rätta det här. Bara katalogen
ändrades, så att den säger sanningen om vad som redan är kört. De gamla
filernas text finns kvar i git-historiken före den commit som tog bort dem.
