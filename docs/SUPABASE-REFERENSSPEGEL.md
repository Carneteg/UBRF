# Supabase-spegel för referensmedia

Redundant, maskinläsbar kopia av UBRF:s käll- och referensmedia i Supabase
Storage, plus manifestet i `public.reference_assets`.

**GitHub förblir kanoniskt.** Spegeln är redundans, inte en förutsättning:
fotona, filmerna och planerna är redan build-åtkomliga i repot och
checksumverifierade. Den här PR:en är därför avsiktligt skild från
fidelity-arbetet i F02 — ett ansvar per PR.

## Läget

| | |
|---|---|
| hink | `reference-assets` i projekt `tdznhaybxmekznasxtts` |
| synlighet | **privat** |
| filstorleksgräns | 64 MB |
| mime-typer | jpeg, png, quicktime, mp4 |
| objekt i hinken | **0** |
| manifestrader | 82 |
| rader med `supabase_storage_path` | **0** |

Att siffran är noll är redovisat, inte glömt.

## Varför inget är uppladdat

Uppladdning kräver en nyckel som går förbi RLS. Den finns inte i
byggmiljön — mätt, inte antaget:

```
POST /storage/v1/bucket  med den publicerbara nyckeln
→ 403  new row violates row-level security policy
```

**Ingen anon-insert-policy lades in för att komma runt det.** Det hade gjort
råfilmerna från anläggningen skrivbara för var och en som har den publika
nyckeln, och den avvägningen är inte en implementationsdetalj.

Nyckeln ska inte klistras in i en PR-tråd, ett repo, ett testutfall eller en
chattkonversation. Uppladdningen hör hemma i en miljö med en riktig
hemlighetshantering, och `tools/spegla-referenser.py --ladda-upp` gör hela
jobbet där.

## Regeln som ligger i schemat

```sql
check (supabase_storage_path is null or storage_verified_at is not null)
```

En manifestrad kan alltså inte påstå att en fil är speglad utan att någon
verifierat objektet. Regeln står i databasen, inte bara i det här dokumentet,
så nästa agent inte kan sätta en sökväg "så länge" och glömma bort det.

Falsifierad: ett försök att sätta `supabase_storage_path` utan
`storage_verified_at` avvisas, och räkningen står kvar på 0 rader.

## Vad som ska bevisas när spegeln fylls

- objektantal per typ mot `--lista`,
- sha256 per objekt mot GitHub-sidan,
- att varje icke-tom `supabase_storage_path` pekar på ett objekt som finns,
- att inget objekt ligger i hinken utan manifestrad,

och allt det **utan** att nyckeln syns någonstans i utdata.
