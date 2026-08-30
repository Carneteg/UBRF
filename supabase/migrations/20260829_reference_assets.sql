create table if not exists public.reference_assets (
  id text primary key,
  title text not null,
  asset_type text not null,
  source_origin text not null,
  github_path text,
  github_url text,
  supabase_storage_path text,
  external_source_url text,
  verification_status text not null default 'unverified'
    check (verification_status in ('verified','reference_gap','unverified','superseded')),
  required_for_build boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.reference_assets enable row level security;

comment on table public.reference_assets is
  'Canonical manifest for UBRF source/reference assets. Runtime and AI build work must not depend on Google Drive; required assets must resolve to GitHub and/or Supabase.';
