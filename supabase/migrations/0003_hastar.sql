-- ══════════════════════════════════════════════════════════════════
-- HÄSTARNA — UBRF:s ridskolehästar som referenstabell.
--
-- GENERERAD FIL. Redigera inte här — ändra i `src/data.js` och kör
--     python3 tools/hastar-till-sql.py
-- Två listor över samma hästar glider isär, alltid. Det finns en källa,
-- och det är spelet.
--
-- Beskrivningarna är ordagranna från ubrf.se/hastar. Siffrorna är
-- spelets modellvärden, inte fakta om djuren: `kanslighet` är hur skarpt
-- hästen svarar på en hjälp i modellen, inte en omdöme om hästen.
--
-- Tabellen är REFERENS, inte spelets sanning. Spelet är local-first och
-- läser hästarna ur data.js även utan nät; det här är för att kunna
-- följa vilka hästar som finns och koppla `hastminne.hast_id` till något
-- med namn. Därför är den läsbar för alla inloggade och skrivbar för
-- ingen — bara service-nyckeln kommer åt den.
-- ══════════════════════════════════════════════════════════════════

create table if not exists public.hastar (
  id              text primary key,
  namn            text        not null,
  typ             text,                 -- hast | ponny
  kategori        text,                 -- A–D för ponny, hast för häst
  ras             text,
  fodd            integer,
  beskrivning     text,                 -- ordagrant från ubrf.se/hastar
  -- Modellvärden, alla 0–1. Se src/model.js för vad var och en gör.
  kanslighet      real, framatbjudning real, forlatande real, skygghet real,
  hoppkapacitet   real, hopplust real, tyngd real, utbildning real,
  maxhojd         real,                 -- meter, högsta hinder
  flaggor         jsonb       not null default '{}'::jsonb,
  uppdaterad      timestamptz not null default now()
);

alter table public.hastar enable row level security;

-- Läsbar för alla inloggade, skrivbar för ingen. Hästarna är gemensamma;
-- det är hastminne som är privat per ryttare.
drop policy if exists hastar_las on public.hastar;
create policy hastar_las on public.hastar
  for select to authenticated using (true);

insert into public.hastar
  (id, namn, typ, kategori, ras, fodd, beskrivning,
   kanslighet, framatbjudning, forlatande, skygghet,
   hoppkapacitet, hopplust, tyngd, utbildning, maxhojd, flaggor)
values
  ('toblerone', 'Toblerone', 'ponny', 'C', 'Fjordhäst', 2007, 'Toblerone är en snäll, välutbildad och populär fjordvalack. Han har tidigare tävlat i både hoppning samt dressyr.', 0.35, 0.42, 0.95, 0.05, 0.72, 0.78, 0.62, 0.9, 0.75, '{}'::jsonb),
  ('cosmo', 'Cosmo M Z', 'hast', 'hast', 'Belgiskt varmblod', 2012, 'Cosmo är en snäll och okomplicerad valack som är grundutbildad i både dressyr och hoppning.', 0.42, 0.5, 0.8, 0.15, 0.72, 0.75, 0.42, 0.68, 0.9, '{}'::jsonb),
  ('air', 'Air Italia', 'hast', 'hast', 'Danskt varmblod', 2011, 'Air är en valack som kom till ridskolan 2018. Han har landat bra i verksamheten och kan gå med i alla slags grupper.', 0.45, 0.5, 0.72, 0.2, 0.6, 0.65, 0.4, 0.65, 0.8, '{}'::jsonb),
  ('larry', 'Larry', 'hast', 'hast', 'Irländsk Sporthäst', 2016, 'En riktig ”tjejhäst”. Hoppar bra och går även bra i dressyren.', 0.55, 0.58, 0.7, 0.18, 0.8, 0.8, 0.35, 0.72, 0.95, '{}'::jsonb),
  ('hamilton', 'Hamilton', 'hast', 'hast', 'Holländskt varmblod, KWPN', 2011, 'Hamilton är en arbetsvillig valack som gillar det mesta. Han är en känsligare individ.', 0.75, 0.62, 0.5, 0.35, 0.72, 0.75, 0.32, 0.72, 0.9, '{}'::jsonb),
  ('conor', 'Conor', 'hast', 'hast', 'Ungerskt halvblod', 2016, 'En trevlig häst som kräver en mjuk balanserad ryttare.', 0.88, 0.55, 0.32, 0.28, 0.7, 0.7, 0.22, 0.7, 0.85, '{}'::jsonb),
  ('crokino', 'Crokino', 'hast', 'hast', 'Holländskt varmblod, KWPN', 2011, 'Crokino är en större, lite känsligare häst men som är lättriden trots sin storlek. Han är rädd för spö så låt bli det när du sitter upp.', 0.78, 0.52, 0.55, 0.42, 0.68, 0.62, 0.38, 0.72, 0.85, '{"radd_for_spo": true}'::jsonb),
  ('lydia', 'Bränntomts Lydia', 'ponny', 'D', 'Connemara', 2003, 'Lydia har tidigare tävlat hoppning med sin förra ryttare. Lydia är en väldigt bra barnponny.', 0.3, 0.45, 0.95, 0.06, 0.72, 0.82, 0.42, 0.8, 0.75, '{}'::jsonb),
  ('dexter', 'Dexter', 'ponny', 'D', 'Import: Polen', 2015, 'En ponny med lite mer fart. Duktig på att hoppa.', 0.6, 0.9, 0.52, 0.22, 0.88, 0.9, 0.18, 0.62, 1, '{}'::jsonb),
  ('lady', 'Lady', 'ponny', 'C', 'Welsh Cob', 2009, 'Lady är en trygg fuxponny som burit generationer av nybörjare. Hon vet var lektionen ska sluta innan du vet det.', 0.32, 0.4, 0.92, 0.08, 0.58, 0.6, 0.55, 0.72, 0.7, '{}'::jsonb),
  ('chip', 'Chip', 'ponny', 'B', 'Gotlandsruss', 2013, 'Chip är liten, kvick och alldeles för smart. Äter allt som inte är fastsurrat — håll koll på foderpåsen.', 0.38, 0.55, 0.85, 0.12, 0.55, 0.7, 0.3, 0.58, 0.6, '{}'::jsonb),
  ('tina', 'Tina', 'ponny', 'D', 'New Forest', 2010, 'Tina är en ordentlig lektionsponny med fin trav. Hon är kittlig — rykta med lugna drag så står hon som en klippa.', 0.48, 0.46, 0.74, 0.15, 0.62, 0.66, 0.38, 0.66, 0.75, '{"kittlig": true}'::jsonb),
  ('westside', 'Westside', 'hast', 'hast', 'Svenskt varmblod', 2014, 'Westside är en rejäl valack som gör jobbet varje lektion. Rak, ärlig och lätt att tycka om.', 0.5, 0.55, 0.68, 0.22, 0.7, 0.72, 0.38, 0.66, 0.85, '{}'::jsonb),
  ('makadu', 'Makadu', 'hast', 'hast', 'Import: Irland', 2012, 'Makadu är en godmodig valack med ett gammalt stallknep: han blåser upp magen när du gjordar. Vänta, och dra åt igen.', 0.44, 0.48, 0.75, 0.16, 0.66, 0.7, 0.45, 0.64, 0.8, '{"blaser_upp_magen": true}'::jsonb),
  ('mara', 'Mara', 'hast', 'hast', 'Hannoveranare', 2013, 'Mara är stallets sto med egen åsikt. Sur min i boxen, guld under sadeln — döm henne inte vid boxdörren.', 0.58, 0.52, 0.62, 0.25, 0.68, 0.64, 0.36, 0.68, 0.85, '{}'::jsonb),
  ('husky', 'Husky', 'hast', 'hast', 'Import: Polen', 2015, 'Husky är en gråskimmel med spring i benen. Svårfångad i hagen — gå lugnt fram, andra försöket brukar sitta.', 0.46, 0.6, 0.66, 0.3, 0.72, 0.74, 0.34, 0.6, 0.85, '{"svarfangad": true}'::jsonb),
  ('kennedy', 'Kennedy', 'hast', 'hast', 'Svenskt varmblod', 2016, 'Kennedy är stallets unghäst, född 2016. Stort steg och stort hjärta, men allt är fortfarande på riktigt för honom.', 0.7, 0.58, 0.45, 0.38, 0.75, 0.78, 0.3, 0.55, 0.9, '{}'::jsonb)
on conflict (id) do update set
  namn=excluded.namn, typ=excluded.typ, kategori=excluded.kategori,
  ras=excluded.ras, fodd=excluded.fodd, beskrivning=excluded.beskrivning,
  kanslighet=excluded.kanslighet, framatbjudning=excluded.framatbjudning,
  forlatande=excluded.forlatande, skygghet=excluded.skygghet,
  hoppkapacitet=excluded.hoppkapacitet, hopplust=excluded.hopplust,
  tyngd=excluded.tyngd, utbildning=excluded.utbildning,
  maxhojd=excluded.maxhojd, flaggor=excluded.flaggor,
  uppdaterad=now();
