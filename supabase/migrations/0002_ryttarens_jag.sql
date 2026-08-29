-- ══════════════════════════════════════════════════════════════════
-- RYTTAREN DU SKAPAR — utseendet och de tre egenskaperna.
--
-- Läggs som en enda jsonb-kolumn i stället för som sju kolumner. Skälet
-- är att den här strukturen kommer att ändras: en frisyr till, en
-- egenskap till, en färg som byter namn. Med jsonb är det en ändring i
-- jag.js och ingenting här; med kolumner vore varje sådan ändring en ny
-- migration och en risk att spelet och tabellen glider isär.
--
-- Formen är densamma som `SPAR.jag` i spelet:
--   {namn, hy, har, harstil, kavaj, byxa, hjalm, egenskaper[], skapad}
--
-- RLS ärvs: raden i `ryttare` är redan skyddad av policyn i 0001, och
-- en ny kolumn på samma rad omfattas av den. Ingen ny policy behövs.
-- ══════════════════════════════════════════════════════════════════

alter table public.ryttare
  add column if not exists jag jsonb not null default '{}'::jsonb;

comment on column public.ryttare.jag is
  'Ryttarens utseende och valda egenskaper. Samma form som SPAR.jag i spelet.';
