-- Privat lagringshink for UBRF:s kall- och referensmedia.
-- Privat med flit: rafilmerna fran anlaggningen ska inte ligga oppet.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('reference-assets', 'reference-assets', false, 67108864,
        array['image/jpeg','image/png','video/quicktime','video/mp4'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- INGEN anon- eller authenticated-policy laggs till. Uppladdning kraver en
-- hemlig nyckel som gar forbi RLS. Att oppna anon-insert for att kunna spegla
-- hade gjort rafilmerna skrivbara for var och en som har den publika nyckeln.

-- Kolumner som gor spegeln kontrollerbar i stallet for pastadd.
alter table public.reference_assets
  add column if not exists sha256 text,
  add column if not exists bytes bigint,
  add column if not exists storage_verified_at timestamptz;

-- En rad far inte pasta att den ar speglad utan att nagon verifierat objektet.
-- Regeln star i schemat, inte bara i ett dokument, sa nasta agent inte kan
-- satta en sokvag "sa lange" och glomma bort det.
alter table public.reference_assets
  drop constraint if exists reference_assets_spegel_verifierad;
alter table public.reference_assets
  add constraint reference_assets_spegel_verifierad
  check (supabase_storage_path is null or storage_verified_at is not null);

comment on constraint reference_assets_spegel_verifierad on public.reference_assets is
  'En sokvag i Storage far bara sattas tillsammans med storage_verified_at. Ett manifest som pastar att en fil ar speglad, nar den inte ar det, far nasta agent att sluta leta.';
