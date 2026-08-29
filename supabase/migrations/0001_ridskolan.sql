-- ══════════════════════════════════════════════════════════════════
-- RIDSKOLAN — spelarnas utveckling och deras hästminnen.
--
-- Spelet är local-first: localStorage är sanningen och allt fungerar
-- utan nät, precis som förut. Det här är en synk ovanpå, så att man kan
-- rida på mobilen och fortsätta på datorn.
--
-- Hästminnet är EGET PER SPELARE. Var och en har sin egen relation till
-- varje häst; ingen kan förstöra en häst för någon annan.
-- ══════════════════════════════════════════════════════════════════

-- ── Ryttaren ──────────────────────────────────────────────────────
-- En rad per spelare, med samma id som auth-användaren. Fälten är exakt
-- de som SPAR innehåller i spelet, så att synken blir en avskrift och
-- inte en översättning.
create table if not exists public.ryttare (
  id          uuid primary key references auth.users(id) on delete cascade,
  namn        text        not null default 'Ryttare',
  grupp       text        not null default 'ledlektion',
  poang       integer     not null default 0,
  pass        integer     not null default 0,
  fardighet   jsonb       not null default
    '{"sits":0.12,"hand":0.10,"kansla":0.08,"skotsel":0.15}'::jsonb,
  uppdaterad  timestamptz not null default now(),
  skapad      timestamptz not null default now()
);

-- ── Hästminnet ────────────────────────────────────────────────────
-- Per spelare och häst. rang är förtroendet er emellan, och det rör sig
-- högst några hundradelar per pass — därför är det värt att spara.
create table if not exists public.hastminne (
  ryttare_id     uuid        not null references public.ryttare(id) on delete cascade,
  hast_id        text        not null,
  rang           real        not null default 0.45,
  pass           integer     not null default 0,
  sista_pass_nr  integer,
  sista_form     real,
  rehab          boolean     not null default false,
  skada          jsonb,
  uppdaterad     timestamptz not null default now(),
  primary key (ryttare_id, hast_id)
);

-- ── Passen ────────────────────────────────────────────────────────
-- Historiken, en rad per ridet pass. Det som efter-passet räknar fram
-- sparas här, så att utvecklingen går att följa över tid och inte bara
-- över en kväll: hämtningarna, spänningen före och efter, och
-- färdigheterna på båda sidor av passet.
create table if not exists public.pass (
  id             bigint generated always as identity primary key,
  ryttare_id     uuid        not null references public.ryttare(id) on delete cascade,
  ridet          timestamptz not null default now(),
  hast_id        text        not null,
  grupp          text        not null,
  plats          text,
  snitt          real,
  fel            integer,
  utesluten      boolean     not null default false,
  hamtningar     integer,
  tid_ute        real,
  mjukhet        real,
  spanning_fore  real,
  spanning_slut  real,
  losgjord_fore  real,
  losgjord_slut  real,
  fard_fore      jsonb,
  fard_efter     jsonb,
  rang_fore      real,
  rang_efter     real
);
create index if not exists pass_ryttare_ridet on public.pass (ryttare_id, ridet desc);

-- ── Radsäkerhet ───────────────────────────────────────────────────
-- Var och en ser och skriver bara sina egna rader. Ingen policy för
-- anon: utan inloggning finns ingenting att hämta.
alter table public.ryttare   enable row level security;
alter table public.hastminne enable row level security;
alter table public.pass      enable row level security;

drop policy if exists "egen ryttare" on public.ryttare;
create policy "egen ryttare" on public.ryttare
  for all to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "eget hastminne" on public.hastminne;
create policy "eget hastminne" on public.hastminne
  for all to authenticated
  using (ryttare_id = (select auth.uid())) with check (ryttare_id = (select auth.uid()));

drop policy if exists "egna pass" on public.pass;
create policy "egna pass" on public.pass
  for all to authenticated
  using (ryttare_id = (select auth.uid())) with check (ryttare_id = (select auth.uid()));

-- ── Ryttarraden skapas av sig själv ───────────────────────────────
-- Utan det här måste klienten göra ett extra anrop direkt efter
-- registreringen, och misslyckas det står spelaren utan rad.
create or replace function public.ny_ryttare()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.ryttare (id, namn)
  values (new.id, coalesce(new.raw_user_meta_data->>'namn', 'Ryttare'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists ny_ryttare_trigger on auth.users;
create trigger ny_ryttare_trigger
  after insert on auth.users
  for each row execute function public.ny_ryttare();
