#!/usr/bin/env python3
"""Mäter tvärgående vägglinjer i stallets utrymningsplan.

Varför den finns: förra interiörrundan underkändes bland annat för att
rumsmåtten var "magic numbers from a visual read". Ett tal jag har läst av
med ögat i en bild går inte att pröva om av någon annan, och det går inte
att se om det ändras. Det här skriptet gör avläsningen reproducerbar:
samma bild in, samma tal ut, och metoden står i koden.

Vad den mäter: var de GENOMGÅENDE tvärväggarna ligger längs byggnadens
längd, uttryckt som ANDEL av byggnadens längd — inte i meter. Skalan är
medvetet utelämnad. Planen saknar skalstock och stallets bredd är olöst i
intervallet 15–23 m (references/plans/OAVGJORT.md fråga 2); att skriva ut
meter här hade gjort arbetsvärdet 21 m till kanon bakvägen.

Metod:
  1. beskär till Plan 1:s husrektangel (given som argument, avläst en gång),
  2. för varje bildrad: räkna hur stor andel av radens bredd som är MÖRK,
  3. en genomgående vägg ger en topp — den är mörk tvärs nästan hela huset,
     medan en boxvägg bara är mörk i sitt eget band,
  4. rapportera topparna som andel av husets längd.

Kör: python3 tools/f02-planmatning.py [--troskel 0.45] [--json]
"""

import argparse
import json
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("PIL saknas — pip install pillow")

PLAN = "references/plans/stall-plan1-utrymning-rak.jpg"

# Husrektangeln i Plan 1, avläst EN gång i bilden ovan och skriven här så att
# den går att granska och rätta. Norra gaveln överst, södra nederst.
# `[DERIVED]` — kanterna är väggens ytterlinje, ±3 px.
HUS = {"x0": 535, "x1": 968, "y0": 252, "y1": 1700}


def morkhet(im, hus):
    """Andel mörka bildpunkter per rad, inom husets bredd."""
    g = im.convert("L")
    b = g.load()
    ut = []
    for y in range(hus["y0"], hus["y1"]):
        morka = sum(1 for x in range(hus["x0"], hus["x1"]) if b[x, y] < 120)
        ut.append(morka / (hus["x1"] - hus["x0"]))
    return ut


def toppar(serie, troskel):
    """Sammanhängande band över tröskeln, returnerade som mittpunkter."""
    ut, start = [], None
    for i, v in enumerate(serie):
        if v >= troskel and start is None:
            start = i
        elif v < troskel and start is not None:
            ut.append(((start + i - 1) / 2, i - start, max(serie[start:i])))
            start = None
    if start is not None:
        ut.append(((start + len(serie) - 1) / 2, len(serie) - start,
                   max(serie[start:])))
    return ut


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--troskel", type=float, default=0.45,
                   help="andel mörka pixlar för att räknas som genomgående vägg")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    im = Image.open(PLAN)
    serie = morkhet(im, HUS)
    langd = HUS["y1"] - HUS["y0"]
    rader = []
    for mitt, tjocklek, topp in toppar(serie, a.troskel):
        rader.append({
            "andel_fran_norr": round(mitt / langd, 4),
            "tjocklek_px": tjocklek,
            "toppandel_mork": round(topp, 3),
        })

    if a.json:
        print(json.dumps({"hus_px": HUS, "langd_px": langd,
                          "troskel": a.troskel, "linjer": rader}, indent=2))
        return

    print(f"Plan: {PLAN}")
    print(f"Husrektangel (px): {HUS}, längd {langd} px")
    print(f"Tröskel: {a.troskel:.2f} av husbredden mörk\n")
    print(f"{'andel från norr':>16}  {'tjocklek px':>11}  {'max mörk':>8}")
    for r in rader:
        print(f"{r['andel_fran_norr']:>16.4f}  {r['tjocklek_px']:>11}  "
              f"{r['toppandel_mork']:>8.3f}")
    print(f"\n{len(rader)} genomgående linjer.")
    print("Andelar, inte meter: planen saknar skalstock och stallets bredd "
          "är olöst 15–23 m.")


if __name__ == "__main__":
    main()
