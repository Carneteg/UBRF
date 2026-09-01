#!/usr/bin/env python3
"""Vaktar att varje hastrigg har en kall-, licens- och provenienspost.

Issue #31 punkt 2. En rigg utan kand licens far inte anvandas, och en rigg
vars fil bara finns i Google Drive gar inte att bygga med.

Kontrollen ar AVSIKTLIGT gron pa en tom tabell, och sager da att noll riggar
ar registrerade. Den paastar alltsa inte att nagot ar verifierat nar det inte
finns nagot att verifiera -- skillnaden mellan "inget fel hittat" och "inget
att titta pa" ska sta i utskriften och inte gissas av den som laser den.

    python3 tools/kolla-riggkalla.py
"""

import hashlib
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
TABELL = ROT / "roblox" / "assets" / "RIGGAR.md"

KOLUMNER = ["id", "fil", "sokvag", "kalla", "licens", "upphov", "datum", "sha256"]

#[[ En licens ska ga att sla upp. "fri", "ok" och "vet ej" ar inte licenser,
#   de ar hopp om att fragan aldrig stalls. ]]
INTE_LICENSER = {"fri", "gratis", "ok", "okand", "vet ej", "-", "?", "tba"}


def summa(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for bit in iter(lambda: f.read(1 << 20), b""):
            h.update(bit)
    return h.hexdigest()


def rader(text: str) -> list[dict]:
    inne = text.split("<!-- TABELL-START -->")[-1].split("<!-- TABELL-SLUT -->")[0]
    ut = []
    for rad in inne.splitlines():
        rad = rad.strip()
        if not rad.startswith("|"):
            continue
        celler = [c.strip() for c in rad.strip("|").split("|")]
        # Rubrikraden och streckraden hoppas over.
        if celler[:1] == ["id"] or set("".join(celler)) <= set("-: "):
            continue
        ut.append(dict(zip(KOLUMNER, celler)))
    return ut


def main() -> int:
    if not TABELL.exists():
        print(f"FEL  {TABELL.relative_to(ROT)} saknas")
        return 1

    text = TABELL.read_text(encoding="utf-8")
    poster = rader(text)
    fel = []

    for i, r in enumerate(poster, 1):
        namn = r.get("id") or f"rad {i}"

        saknade = [k for k in KOLUMNER if not r.get(k)]
        if saknade:
            fel.append(f"{namn}: tomma kolumner {', '.join(saknade)}")
            continue

        if "[DRIVE-ONLY]" in r["sokvag"]:
            fel.append(
                f"{namn}: sokvagen ar [DRIVE-ONLY]. Drive ar inte en "
                f"build-forutsattning -- lagg filen i repot eller i Supabase"
            )
            continue

        if r["licens"].strip().lower() in INTE_LICENSER:
            fel.append(f"{namn}: {r['licens']!r} ar inget licensnamn")

        p = ROT / r["sokvag"]
        if not p.exists():
            fel.append(f"{namn}: {r['sokvag']} finns inte pa disk")
            continue

        faktisk = summa(p)
        if faktisk != r["sha256"]:
            fel.append(
                f"{namn}: sha256 stammer inte\n"
                f"       i tabellen {r['sha256']}\n"
                f"       pa disk    {faktisk}"
            )

    for f in fel:
        print("FEL  " + f)

    if fel:
        print(f"\n{len(fel)} fel i {TABELL.relative_to(ROT)}")
        return 1

    if not poster:
        #[[ Tom tabell ar inte ett godkannande. Sag vad som INTE kontrollerats,
        #   annars laser nasta person exit 0 som "riggarna ar i ordning". ]]
        print("OK   0 riggar registrerade -- ingenting att verifiera an.")
        print("     Issue #31 ar oppen: repot har ingen produktionsrigg.")
        return 0

    print(f"OK   {len(poster)} rigg(ar) med kalla, licens och matchande sha256")
    return 0


if __name__ == "__main__":
    sys.exit(main())
