create table public.hastar (
  id text primary key,                -- slug, matchar hast_id i hastminne/pass
  namn text not null,
  typ text not null check (typ in ('häst','ponny')),
  fodd integer,
  far text,
  mor text,
  morfar text,
  ras text,
  mankhojd integer,
  import text,
  kategori text,
  beskrivning text,
  bild_fil text,
  bild_url text,
  kalla_url text,
  aktiv boolean not null default true,
  skapad timestamptz not null default now(),
  uppdaterad timestamptz not null default now()
);
alter table public.hastar enable row level security;
create policy "hastar_read_all" on public.hastar for select using (true);
comment on table public.hastar is 'Ridskolans hästar och ponnys, hämtade från ubrf.se/hastar';
