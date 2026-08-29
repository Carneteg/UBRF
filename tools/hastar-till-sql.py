#!/usr/bin/env python3
"""Genererar supabase/migrations/0003_hastar.sql ur src/data.js.

Hästarna är spelets data och bor i data.js — det är där de redigeras.
Den här filen skriver av dem till SQL så att molnet kan referera dem, och
den ska köras om varje gång HORSES ändras:

    python3 tools/hastar-till-sql.py

Skälet att generera i stället för att skriva för hand: två listor över
samma arton hästar glider isär, alltid. Här finns bara en källa.
"""
import json, pathlib, subprocess

ROT = pathlib.Path(__file__).resolve().parent.parent

# Läsningen görs av node, inte av en regex. Ett försök att plocka isär
# HORSES med reguljära uttryck kvoterade "stallknep:" mitt inne i en
# beskrivning som om det vore en nyckel — JS går inte att parsa så. node
# finns ändå i miljön och kan läsa filen som det den är.
HORSES = json.loads(subprocess.run(
    ["node", "-e",
     "const fs=require('fs');"
     "const src=fs.readFileSync(process.argv[1],'utf8');"
     "const H=new Function(src+';return HORSES;')();"
     "process.stdout.write(JSON.stringify(H));",
     str(ROT / "src" / "data.js")],
    capture_output=True, text=True, check=True).stdout)

def cite(v):
    if v is None: return "null"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float)): return repr(v)
    return "'" + str(v).replace("'", "''") + "'"

rader = []
for hid, h in HORSES.items():
    flaggor = json.dumps(h.get("flaggor") or {}, ensure_ascii=False)
    rader.append("  (" + ", ".join([
        cite(hid), cite(h["namn"]), cite(h.get("typ")), cite(h.get("kategori")),
        cite(h.get("ras")), cite(h.get("fodd")), cite(h.get("besk")),
        cite(h.get("kanslighet")), cite(h.get("framatbjudning")),
        cite(h.get("forlatande")), cite(h.get("skygghet")),
        cite(h.get("hoppkapacitet")), cite(h.get("hopplust")),
        cite(h.get("tyngd")), cite(h.get("utbildning")), cite(h.get("maxhojd")),
        cite(flaggor) + "::jsonb",
    ]) + ")")

sql = """-- ══════════════════════════════════════════════════════════════════
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
""" + ",\n".join(rader) + """
on conflict (id) do update set
  namn=excluded.namn, typ=excluded.typ, kategori=excluded.kategori,
  ras=excluded.ras, fodd=excluded.fodd, beskrivning=excluded.beskrivning,
  kanslighet=excluded.kanslighet, framatbjudning=excluded.framatbjudning,
  forlatande=excluded.forlatande, skygghet=excluded.skygghet,
  hoppkapacitet=excluded.hoppkapacitet, hopplust=excluded.hopplust,
  tyngd=excluded.tyngd, utbildning=excluded.utbildning,
  maxhojd=excluded.maxhojd, flaggor=excluded.flaggor,
  uppdaterad=now();
"""

mal = ROT / "supabase" / "migrations" / "0003_hastar.sql"
mal.write_text(sql, encoding="utf-8")
print(f"{mal.relative_to(ROT)}: {len(HORSES)} hästar, {len(sql)} tecken")
