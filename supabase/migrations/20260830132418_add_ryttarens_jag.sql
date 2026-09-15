alter table public.ryttare
  add column if not exists jag jsonb not null default '{}'::jsonb;

comment on column public.ryttare.jag is
  'Ryttarens utseende och valda egenskaper. Samma form som SPAR.jag i spelet.';
