#!/usr/bin/env python3
"""Mäter fram dörr-/portlägen ur stallets utrymningsplan.

Utrymningsplanens **gröna band** markerar utrymningsvägar, och där ett band
korsar husets yttervägg finns en dörr. Det är den enda dörrmarkeringen i
planen som går att läsa utan att gissa: bandens läge är entydigt, till
skillnad från de tunna väggluckorna inne i huset.

Skriptet letar därför upp den gula husytan, letar upp de gröna banden, och
för varje band som **rör** husytans kant räknar det ut var på väggen det
sitter — i **normaliserade andelar 0–1**, aldrig i meter. Meterskalan är
inte fastställd (`OAVGJORT.md` fråga 2) och får inte smyga in bakvägen.

    python3 tools/planoppningar.py references/plans/stall-plan1-utrymning-rak.jpg

Vad skriptet INTE gör: inre dörrar. Väggluckorna inne i planen är för tunna
och för många för att skiljas från ritbrus, och en påhittad innerdörr är
värre än en saknad. De står som REFERENCE GAP.
"""

import argparse
import importlib.util
import json
import pathlib
import sys

import numpy as np
from PIL import Image

ROT = pathlib.Path(__file__).resolve().parent.parent


def ladda_rp():
    s = importlib.util.spec_from_file_location("rp", str(ROT / "tools" / "rektifiera-plan.py"))
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


def gron_mask(a: np.ndarray) -> np.ndarray:
    """Utrymningsbandens gröna.

    Fotot är mörkt och avfärgat: bandet mäter (126, 128, 69) och den gula
    husytan (173, 156, 80). På g-minus-r ligger de 19 enheter isär — bandet
    +2, ytan -17 — vilket inte räcker ensamt. Det som skiljer dem säkert är
    ljusheten: bandet är mörkare. Vit bakgrund faller på g-minus-b.

    Trösklarna är alltså mätta ur just den här bilden, inte lånade."""
    r, g, b = a[:, :, 0].astype(np.int16), a[:, :, 1].astype(np.int16), a[:, :, 2].astype(np.int16)
    return (g - b > 40) & (g >= r - 3) & (r < 155)


def klumpar(mask: np.ndarray, minsta: int, rp) -> list[np.ndarray]:
    """Alla sammanhängande ytor över en storlek, inte bara den största."""
    kvar = mask.copy()
    ut = []
    while True:
        if not kvar.any():
            break
        try:
            k = rp.storsta_klumpen(kvar)
        except SystemExit:
            break
        if int(k.sum()) < minsta:
            break
        ut.append(k)
        kvar = kvar & ~k
    return ut


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("bild")
    p.add_argument("--minsta-band", type=int, default=1200,
                   help="minsta gröna klump som räknas som utrymningsband")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    rp = ladda_rp()
    arr = np.asarray(Image.open(a.bild).convert("RGB"))

    #[[ Den gula ytan är UPPDELAD av ritningens väggstreck, så den största
    #   sammanhängande gula klumpen blir ett enskilt rumsblock i stället för
    #   huset. Vidga masken först så att strecken sluts, hitta klumpen, och
    #   använd bara dess omslutande rektangel — vidgningen får aldrig påverka
    #   ett mått, bara sammanhanget. ]]
    gul = rp.gul_mask(arr)
    vid = gul.copy()
    for _ in range(5):
        n = vid.copy()
        n[1:, :] |= vid[:-1, :]; n[:-1, :] |= vid[1:, :]
        n[:, 1:] |= vid[:, :-1]; n[:, :-1] |= vid[:, 1:]
        vid = n
    hus = rp.storsta_klumpen(vid)
    ys, xs = np.nonzero(hus)
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    B, L = x1 - x0, y1 - y0
    print(f"husets omslutande rektangel: x {x0}–{x1} ({B} px), y {y0}–{y1} ({L} px)")

    band = klumpar(gron_mask(arr), a.minsta_band, rp)
    print(f"{len(band)} gröna band över {a.minsta_band} px\n")

    #[[ Ett band räknas som en dörr först när det RÖR husytan. Legendens
    #   gröna rutor och återsamlingsplatsens symbol ligger fritt och
    #   faller därmed bort av sig själva. ]]
    hus_bred = hus.copy()
    for _ in range(6):
        n = hus_bred.copy()
        n[1:, :] |= hus_bred[:-1, :]; n[:-1, :] |= hus_bred[1:, :]
        n[:, 1:] |= hus_bred[:, :-1]; n[:, :-1] |= hus_bred[:, 1:]
        hus_bred = n

    fynd = []
    for k in band:
        if not (k & hus_bred).any():
            continue
        kys, kxs = np.nonzero(k)
        bx0, bx1, by0, by1 = int(kxs.min()), int(kxs.max()), int(kys.min()), int(kys.max())
        cx, cy = (bx0 + bx1) / 2, (by0 + by1) / 2

        # Vilken vägg? Den kant bandets mittpunkt ligger närmast.
        avstand = {"V": abs(cx - x0), "O": abs(cx - x1),
                   "S": abs(cy - y1), "N": abs(cy - y0)}
        vagg = min(avstand, key=avstand.get)
        if vagg in ("V", "O"):
            pos = (cy - y0) / L
            bredd = (by1 - by0) / L
        else:
            pos = (cx - x0) / B
            bredd = (bx1 - bx0) / B
        fynd.append({"vagg": vagg, "andel": round(float(pos), 4),
                     "bandbredd": round(float(bredd), 4),
                     "px": [bx0, by0, bx1, by1], "storlek": int(k.sum())})

    fynd.sort(key=lambda f: (f["vagg"], f["andel"]))
    print(f"{'vägg':<5} {'andel längs väggen':>20} {'bandbredd':>10} {'px':>26} {'storlek':>8}")
    for f in fynd:
        print(f"{f['vagg']:<5} {f['andel']:>20.4f} {f['bandbredd']:>10.4f} "
              f"{str(f['px']):>26} {f['storlek']:>8}")
    print(f"\n{len(fynd)} band rör husytan = {len(fynd)} läsbara ytterdörrar.")
    print("Inre dörrar mäts INTE här — se skriptets docstring.")
    if a.json:
        print(json.dumps({"hus_px": [x0, y0, x1, y1], "oppningar": fynd},
                         ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
