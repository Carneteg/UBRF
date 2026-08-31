#!/usr/bin/env python3
"""Fyra hörn på planbladets rektangel — även de som aldrig fotograferades.

Bakgrund. Senior review bad om en sista rätning byggd på planbladets fyra
verkliga hörn i stället för extrempunkter i den gula ytan. Två av bladets
hörn ligger **utanför fotot**: skylten är beskuren i överkant. Hörnen går
alltså inte att peka ut.

Men de går att RÄKNA FRAM. Fyra fotograferade kanter på ett plant dokument
skär varandra i fyra punkter, och de punkterna är rektangelns hörn oavsett
om kameran råkade få med dem. Det här skriptet gör det:

1. varje kant anges med en grov tvåpunktshint,
2. hinten förfinas mot den starkaste gradienten vinkelrätt mot linjen —
   en dålig hint syns då som ett dåligt linjeresidual, den förgiftar inte
   resultatet tyst,
3. de fyra skärningspunkterna skrivs ut i den ordning
   `tools/rektifiera-plan.py --horn` vill ha dem.

**Bara tryck på dokumentet används** — ramkant, gröna bandets kanter,
legendrutans linjaler. Byggnadens väggar rörs inte. Det är med flit:
väggarna sparas till valideringen, och en validering på det man anpassat
mot bevisar ingenting.

    python3 tools/dokumentlinjer.py references/plans/ridhus-entreplan-utrymning.jpg
"""

import argparse
import json
import pathlib
import sys

import numpy as np
from PIL import Image

# Grova tvåpunktshintar i ORIGINALPIXLAR, avlästa ur ett rutnätsöverlägg.
# Familj A löper längs bladets långsida, familj B tvärs. Ingen av dem är en
# byggnadsvägg.
HINTAR = {
    "A_ram_vanster":   ((600, 40), (824, 2800)),
    "A_gron_vanster":  ((864, 40), (1004, 2800)),
    "A_gron_hoger":    ((1176, 40), (1320, 2800)),
    "A_blad_hoger":    ((2924, 40), (3196, 2760)),
    "B_blad_botten":   ((2400, 3014), (3200, 2842)),
    "B_legend_topp":   ((1220, 28), (2300, 8)),
}

# Vilka två linjer per familj som spänner den rektangel hörnen räknas ur.
YTTRE = {"A": ("A_ram_vanster", "A_blad_hoger"),
         "B": ("B_legend_topp", "B_blad_botten")}


def gradbild(bild: np.ndarray) -> np.ndarray:
    """Kantstyrka, Sobel på gråskala."""
    g = bild.mean(axis=2)
    kx = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], dtype=np.float64)
    ky = kx.T
    from numpy.lib.stride_tricks import sliding_window_view
    f = sliding_window_view(g, (3, 3))
    gx = (f * kx).sum(axis=(2, 3))
    gy = (f * ky).sum(axis=(2, 3))
    ut = np.zeros_like(g)
    ut[1:-1, 1:-1] = np.hypot(gx, gy)
    return ut


def forfina(grad: np.ndarray, p1, p2, prov: int = 400):
    """Fäst en hintad linje vid den kant den ligger nära, i krympande steg.

    Ett enda brett svep duger inte: söker man ±45 px efter största gradient
    fastnar man i text och struktur, och spridningen blir tiotals pixlar —
    då är det inte längre en kant man mätt. Därför tre pass med allt
    smalare fönster, och robust gallring mellan varje: punkter mer än tre
    MAD från linjen kastas innan nästa pass.

    RMS-spridningen som rapporteras är hintens kvitto. Ligger den inte i
    pixelklassen är linjen inte funnen, och den får inte användas."""
    h, w = grad.shape
    p1 = np.array(p1, dtype=np.float64)
    p2 = np.array(p2, dtype=np.float64)

    mitt = (p1 + p2) / 2
    d = (p2 - p1) / np.linalg.norm(p2 - p1)
    langd = np.linalg.norm(p2 - p1)

    behall = None
    for sok in (40, 12, 5):
        normal = np.array([-d[1], d[0]])
        punkter = []
        for t in np.linspace(-0.47, 0.47, prov):
            bas = mitt + d * (t * langd)
            basta, bastv = -1.0, None
            for s in np.arange(-sok, sok + 0.5, 0.5):
                q = bas + normal * s
                x, y = int(round(q[0])), int(round(q[1]))
                if 1 <= x < w - 1 and 1 <= y < h - 1:
                    v = grad[y, x]
                    if v > basta:
                        basta, bastv = v, q
            if bastv is not None and basta > 0:
                punkter.append(bastv)
        if len(punkter) < 20:
            sys.exit("FEL  for fa traffar for att anpassa en linje")
        arr = np.array(punkter)

        for _ in range(4):
            m = arr.mean(axis=0)
            _, _, vt = np.linalg.svd(arr - m)
            dd = vt[0]
            n = np.array([-dd[1], dd[0]])
            avv = (arr - m) @ n
            mad = np.median(np.abs(avv - np.median(avv))) or 1e-6
            kvar = arr[np.abs(avv - np.median(avv)) <= 3 * mad]
            if len(kvar) < 20 or len(kvar) == len(arr):
                arr = kvar if len(kvar) >= 20 else arr
                break
            arr = kvar

        mitt = arr.mean(axis=0)
        _, _, vt = np.linalg.svd(arr - mitt)
        d = vt[0]
        behall = arr

    n = np.array([-d[1], d[0]])
    avvik = (behall - mitt) @ n
    return mitt, d, float(np.sqrt((avvik ** 2).mean())), float(np.abs(avvik).max()), len(behall)


def skarning(l1, l2):
    """Skärningspunkt mellan två linjer givna som (punkt, riktning)."""
    (p, d), (q, e) = l1, l2
    A = np.array([d, -e]).T
    if abs(np.linalg.det(A)) < 1e-9:
        return None
    t = np.linalg.solve(A, q - p)
    return p + d * t[0]


def flyktpunkt(linjer):
    """Minsta-kvadrat-flyktpunkt för en familj, plus medelresidual."""
    A, b = [], []
    for p, d, *_ in linjer:
        n = np.array([-d[1], d[0]])
        A.append(n)
        b.append(n @ p)
    A, b = np.array(A), np.array(b)
    x, *_ = np.linalg.lstsq(A, b, rcond=None)
    return x, float(np.abs(A @ x - b).mean())


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("bild")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    arr = np.asarray(Image.open(a.bild).convert("RGB")).astype(np.float64)
    grad = gradbild(arr)

    linjer = {}
    print("linjeanpassning — spridningen ar hintens kvitto:\n")
    print(f"  {'linje':<20} {'RMS px':>8} {'max px':>8} {'punkter':>8}")
    for namn, (h1, h2) in HINTAR.items():
        mitt, d, rms, mx, n = forfina(grad, h1, h2)
        linjer[namn] = (mitt, d, rms, mx)
        print(f"  {namn:<20} {rms:8.2f} {mx:8.1f} {n:8d}")

    for fam in ("A", "B"):
        med = [v for k, v in linjer.items() if k.startswith(fam + "_")]
        fp, res = flyktpunkt(med)
        print(f"\nfamilj {fam}: {len(med)} linjer  flyktpunkt "
              f"({fp[0]:.0f}, {fp[1]:.0f})  medelresidual {res:.1f} px")

    horn = []
    for bn in (YTTRE["B"][0], YTTRE["B"][1]):
        for an in (YTTRE["A"][0], YTTRE["A"][1]):
            s = skarning(linjer[an][:2], linjer[bn][:2])
            horn.append((f"{an} x {bn}", s))
    # ordningen rektifiera-plan.py vill ha: ÖV ÖH NH NV
    ordnad = [horn[0][1], horn[1][1], horn[3][1], horn[2][1]]

    print("\nfyra hörn på planbladets rektangel, RÄKNADE ur fyra fotograferade kanter:")
    for namn, (h, _) in zip(("övre vänster", "övre höger", "nedre höger", "nedre vänster"),
                            zip(ordnad, ordnad)):
        pass
    for namn, s in zip(("övre vänster", "övre höger", "nedre höger", "nedre vänster"), ordnad):
        inne = 0 <= s[0] < arr.shape[1] and 0 <= s[1] < arr.shape[0]
        print(f"  {namn:<15} {s[0]:8.1f} {s[1]:8.1f}   "
              f"{'i bild' if inne else 'UTANFOR BILDEN — aldrig fotograferat'}")

    argstr = " ".join(f"{s[0]:.1f},{s[1]:.1f}" for s in ordnad)
    print(f"\n  --horn {argstr}")
    if a.json:
        print(json.dumps({"horn": [[float(s[0]), float(s[1])] for s in ordnad]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
