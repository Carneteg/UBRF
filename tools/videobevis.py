#!/usr/bin/env python3
"""Uttömmande bevispass över källfilmerna i references/video/.

Bakgrund. `references/video/README.md` beskriver filmerna som facit och
stillbilderna i `references/buildings/` som utplock ur dem. Den första
omgången tog sex bildrutor per film och missade det mesta. Så länge ett
urval styr vad som anses finnas, betyder "syns inte i bilderna" bara
"syns inte i de bildrutor någon råkade välja" — och ett REFERENCE GAP
satt på den grunden är ett påstående om urvalet, inte om anläggningen.

Det här skriptet tar bort urvalet ur ekvationen: filmerna är korta nog
att packa upp HELT. 825 bildrutor totalt vid 30 fps. Varje bildruta
extraheras, ingen cadence gissas.

Sedan gallras de på likhet, per film, med en medelvärdeshash — samma
metod README beskriver, men körd på hela materialet i stället för på ett
stickprov. Tröskeln är låg med flit: en panorering ändrar sig gradvis och
en hög tröskel hade kastat mellanlägena.

    python3 tools/videobevis.py --ut <katalog>
    python3 tools/videobevis.py --ut <katalog> --trosklel 8

Utdata är bildrutorna plus `index.json` med, per behållen bildruta:
film, bildrutenummer, tidsstämpel och hashavstånd till närmast behållna.
Indexet är beviset för vad som faktiskt granskats — ett REFERENCE GAP
efter det här passet är ett påstående om anläggningen, inte om urvalet.

Skriptet SÄGER INGET om vad bildrutorna visar. Det avgörs av en människa
eller en granskare som tittar på dem, och skrivs in i
`docs/F02-BEVISINDEX.md`.
"""

import argparse
import json
import pathlib
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image

ROT = pathlib.Path(__file__).resolve().parent.parent
FILMER = ROT / "references" / "video"


def hasha(sokvag: pathlib.Path) -> int:
    """Medelvärdeshash, 64 bitar. Gråskala, 8×8, tröskel = medelvärdet."""
    with Image.open(sokvag) as bild:
        liten = bild.convert("L").resize((8, 8), Image.Resampling.LANCZOS)
    arr = np.asarray(liten, dtype=np.float64)
    bitar = (arr > arr.mean()).ravel()
    varde = 0
    for b in bitar:
        varde = (varde << 1) | int(b)
    return varde


def avstand(a: int, b: int) -> int:
    return bin(a ^ b).count("1")


def packa_upp(film: pathlib.Path, katalog: pathlib.Path) -> list[pathlib.Path]:
    """Varje bildruta, ingen cadence. Filmerna är korta nog att det går."""
    katalog.mkdir(parents=True, exist_ok=True)
    kor = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(film),
         "-q:v", "2", str(katalog / "%04d.jpg")],
        capture_output=True, text=True)
    if kor.returncode != 0:
        sys.exit(f"FEL  ffmpeg foll pa {film.name}:\n{kor.stderr}")
    return sorted(katalog.glob("*.jpg"))


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--ut", required=True, help="katalog för bildrutorna")
    p.add_argument("--troskel", type=int, default=8,
                   help="minsta hashavstånd för att en bildruta ska behållas "
                        "(default 8, som README beskriver)")
    p.add_argument("--lucka", type=int, default=15,
                   help="längsta tillåtna lucka i bildrutor mellan behållna "
                        "(default 15 = 0,5 s vid 30 fps). Garanterar täckning "
                        "även när hashen står still i en långsam panorering.")
    p.add_argument("--fps", type=float, default=30.0,
                   help="bildfrekvens för tidsstämplarna (default 30)")
    a = p.parse_args()

    if shutil.which("ffmpeg") is None:
        sys.exit("FEL  ffmpeg saknas — bevispasset kan inte köras")

    ut = pathlib.Path(a.ut)
    ut.mkdir(parents=True, exist_ok=True)
    ravar = ut / ".rava"

    filmer = sorted(FILMER.glob("*.mov"))
    if not filmer:
        sys.exit(f"FEL  inga filmer i {FILMER}")

    index: list[dict] = []
    for film in filmer:
        rakatalog = ravar / film.stem
        alla = packa_upp(film, rakatalog)

        # Gallringen jämför ALDRIG över filmer. Två filmer av samma vägg är
        # två tillfällen, och det andra tillfället kan visa det första
        # missade.
        behallna: list[tuple[int, pathlib.Path]] = []
        senast = 0
        pa_lucka = 0
        for nummer, bildruta in enumerate(alla, start=1):
            h = hasha(bildruta)
            narmast = min((avstand(h, kh) for kh, _ in behallna), default=64)

            # Hashen ensam räcker inte. En LÅNGSAM panorering ändrar bilden
            # gradvis, så varje enskild bildruta liknar den förra och hela
            # filmen kan kollapsa till ett par bildrutor — precis det som
            # gör att en vinkel "inte finns" fast den är filmad. Därför
            # behålls en bildruta också när luckan blivit för lång, oavsett
            # hash. Täckningen blir då garanterad av tiden, inte av tur.
            av_lucka = (nummer - senast) >= a.lucka
            if narmast < a.troskel and not av_lucka:
                continue
            mal = ut / f"{film.stem}-{nummer:04d}.jpg"
            shutil.copy2(bildruta, mal)
            behallna.append((h, mal))
            senast = nummer
            pa_lucka += 1 if (narmast < a.troskel) else 0
            index.append({
                "film": film.name,
                "bildruta": nummer,
                "sekund": round((nummer - 1) / a.fps, 3),
                "fil": mal.name,
                "hashavstand": narmast,
                "behallen_av": "lucka" if narmast < a.troskel else "hash",
            })
        print(f"{film.name:<16} {len(alla):4d} bildrutor uppackade  "
              f"→ {len(behallna):3d} behållna "
              f"({len(behallna) - pa_lucka} på hash, {pa_lucka} på lucka)")

    shutil.rmtree(ravar, ignore_errors=True)
    (ut / "index.json").write_text(
        json.dumps({"troskel": a.troskel, "lucka": a.lucka, "bildrutor": index},
                   ensure_ascii=False, indent=2),
        encoding="utf-8")
    print(f"\n{len(index)} behållna bildrutor i {ut}")
    print("index.json listar film, bildrutenummer och tidsstämpel för var och en.")
    print("Vad de VISAR avgörs av den som tittar, inte av det här skriptet.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
