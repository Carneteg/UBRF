#!/usr/bin/env python3
"""Första dagens häst ska vara SAMMA häst på båda ytorna.

Regeln "en ny spelares första dag rids på Blackrock Jack" är ett
produktbeslut, och sedan #162 blockerare 3 står den på två ställen:

    src/scenes.js          const FORSTA_DAGEN_HAST="blackrock_jack"
    roblox/game/Stallet.luau   Stallet.FORSTA_DAGEN_HAST = "blackrock_jack"

Två platser är en dubbel sanning, och CLAUDE.md är tydlig med vad som
händer då: den ena ändras och den andra glöms. Att flytta regeln till den
GENERERADE speldatan hade varit den riktiga lösningen, men den ligger i
`src/spel/` som är hästfakta — första dagen är en spelregel, inte ett
faktum om Jack — och att bygga om generatorn för en sträng vore att vidga
den här PR:en.

Den här grinden är därför kompromissen: två platser, men aldrig två
sanningar. Ändras den ena utan den andra faller CI.

Hästen måste dessutom finnas i den delade hästdatan. En kanonisk häst som
inte finns ger vänteläge för varje ny spelare — alltså ett ospelbart spel
för alla utom den som redan spelat.

Kör: python3 tools/kolla-forstadagen.py      (exit 1 vid avvikelse)
"""
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

KALLOR = [
    ("src/scenes.js", re.compile(r'FORSTA_DAGEN_HAST\s*=\s*"([a-z0-9_]+)"')),
    ("roblox/game/Stallet.luau",
     re.compile(r'Stallet\.FORSTA_DAGEN_HAST\s*=\s*"([a-z0-9_]+)"')),
]

fel = 0
funna = {}
for rel, monster in KALLOR:
    p = ROT / rel
    if not p.exists():
        print(f"FEL  {rel} finns inte")
        fel = 1
        continue
    traffar = monster.findall(p.read_text(encoding="utf-8"))
    if len(traffar) != 1:
        print(f"FEL  {rel}: {len(traffar)} träffar på FORSTA_DAGEN_HAST, väntade 1")
        fel = 1
        continue
    funna[rel] = traffar[0]
    print(f"     {rel}: {traffar[0]}")

if len(funna) == len(KALLOR) and len(set(funna.values())) != 1:
    print("FEL  ytorna är oense om första dagens häst — "
          + ", ".join(f"{k} = {v}" for k, v in funna.items()))
    fel = 1

# Hästen ska finnas på riktigt, i den delade datan.
if funna:
    hast = next(iter(funna.values()))
    hastar = (ROT / "src/spel/hastar.js").read_text(encoding="utf-8")
    if f'id:"{hast}"' not in hastar:
        print(f'FEL  {hast} finns inte i src/spel/hastar.js — '
              "varje ny spelare skulle få vänteläge")
        fel = 1
    else:
        print(f"     src/spel/hastar.js: {hast} finns")

if fel == 0:
    print("OK   första dagens häst är samma på webb och Roblox")
sys.exit(fel)
