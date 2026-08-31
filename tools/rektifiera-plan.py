#!/usr/bin/env python3
"""Rätar ut ett fotograferat planblad med en projektiv transform.

Utrymningsplanerna i `references/plans/` är FOTON av plana dokument. Ett foto
av ett plan är en projektiv avbildning av en plan yta, och den går att invertera
exakt om fyra kontrollpunkter går att peka ut. Att kalla bilden "perspektiv,
går inte att mäta i" är alltså att sluta för tidigt.

Kontrollpunkterna tas ur planytans egen färg: den gula byggnadsytan tröskas
fram, största sammanhängande klumpen behålls, och dess fyra hörn plockas som
extrempunkter i (x+y) och (x−y). Homografin löses som ett 8×8-system och
bilden varpas med PIL.

VAD SKRIPTET RAPPORTERAR, OCH VARFÖR DET INTE ÄR NOLL PER DEFINITION.
Fyra punkter mappas exakt av en homografi — ett residual räknat på dem vore
alltid noll och skulle inte bevisa något. Skriptet mäter i stället hur RAKA
den rätade planytans kanter blev: kanterna samplas i den rätade bilden och
avvikelsen från den ideala rektangeln redovisas i pixlar och i procent av
sidans längd. Är planet verkligen plant och hörnen rätt tagna blir kanterna
raka; blev de inte det är transformen fel, och siffran säger det.

    python3 tools/rektifiera-plan.py <bild> <ut.jpg> [--aspekt 3.022]

Aspekten är målrektangelns längd/bredd. Den avgör inte skalan i meter — bara
proportionen — och normaliserade koordinater ur den rätade bilden är därför
skalfria.
"""

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image


def gul_mask(bild: np.ndarray) -> np.ndarray:
    """Planytans gula fält. Trösklarna är breda med flit: färgen varierar med
    blixt och pappersvinkel, och en snäv tröskel hade fallit på nästa foto."""
    r = bild[:, :, 0].astype(np.int16)
    g = bild[:, :, 1].astype(np.int16)
    b = bild[:, :, 2].astype(np.int16)
    return (r > 120) & (g > 110) & (b < 190) & (r - b > 35) & (g - b > 25)


def storsta_klumpen(mask: np.ndarray) -> np.ndarray:
    """Största sammanhängande ytan, via radvis union-find på 4-grannskap.

    Utan det här steget kan en gul reflex i ramen eller en symbol i legenden
    dra ett hörn flera hundra pixlar fel, och hela rätningen blir skev utan
    att något säger ifrån."""
    h, w = mask.shape
    etikett = np.zeros((h, w), dtype=np.int32)
    forald: list[int] = [0]

    def rot(a: int) -> int:
        while forald[a] != a:
            forald[a] = forald[forald[a]]
            a = forald[a]
        return a

    def slaihop(a: int, b: int) -> None:
        ra, rb = rot(a), rot(b)
        if ra != rb:
            forald[max(ra, rb)] = min(ra, rb)

    nasta = 1
    for y in range(h):
        rad = mask[y]
        if not rad.any():
            continue
        for x in np.flatnonzero(rad):
            vanster = etikett[y, x - 1] if x > 0 else 0
            ovan = etikett[y - 1, x] if y > 0 else 0
            if vanster and ovan:
                etikett[y, x] = min(vanster, ovan)
                slaihop(vanster, ovan)
            elif vanster or ovan:
                etikett[y, x] = vanster or ovan
            else:
                etikett[y, x] = nasta
                forald.append(nasta)
                nasta += 1

    if nasta == 1:
        sys.exit("FEL  hittade ingen gul planyta i bilden")

    platt = np.array([rot(i) if i else 0 for i in range(nasta)], dtype=np.int32)
    slutlig = platt[etikett]
    raknade = np.bincount(slutlig.ravel())
    raknade[0] = 0
    return slutlig == int(np.argmax(raknade))


def horn(mask: np.ndarray) -> np.ndarray:
    """Fyra hörn ur en fyrhörning: extrempunkter i summa och differens.

    Ger ordningen övre vänster, övre höger, nedre höger, nedre vänster."""
    ys, xs = np.nonzero(mask)
    summa, diff = xs + ys, xs - ys
    return np.array([
        [xs[np.argmin(summa)], ys[np.argmin(summa)]],
        [xs[np.argmax(diff)], ys[np.argmax(diff)]],
        [xs[np.argmax(summa)], ys[np.argmax(summa)]],
        [xs[np.argmin(diff)], ys[np.argmin(diff)]],
    ], dtype=np.float64)


def homografi(kalla: np.ndarray, mal: np.ndarray) -> np.ndarray:
    """Löser H så att mal ≈ H · kalla, som ett 8×8-system."""
    A, b = [], []
    for (x, y), (u, v) in zip(kalla, mal):
        A.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        b.append(u)
        A.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b.append(v)
    losning = np.linalg.solve(np.array(A), np.array(b))
    return np.append(losning, 1.0).reshape(3, 3)


def applicera(H: np.ndarray, punkter: np.ndarray) -> np.ndarray:
    homogena = np.hstack([punkter, np.ones((len(punkter), 1))])
    ut = homogena @ H.T
    return ut[:, :2] / ut[:, 2:3]


def kantresidual(mask: np.ndarray) -> dict:
    """Hur raka blev planytans kanter EFTER rätningen?

    Fyra punkter mappas exakt av en homografi, så ett residual på hörnen vore
    noll av konstruktion. Kanterna däremot är oberoende av passningen: de
    innehåller hundratals punkter som transformen aldrig fick se."""
    h, w = mask.shape
    ut = {}
    for namn, axel in (("vänster", "v"), ("höger", "h")):
        rader = []
        for y in range(h):
            x = np.flatnonzero(mask[y])
            if x.size:
                rader.append(x[0] if axel == "v" else x[-1])
        if rader:
            arr = np.array(rader, dtype=np.float64)
            mitten = arr[len(arr) // 10: -len(arr) // 10 or None]
            ut[namn] = {
                "median_px": float(np.median(mitten)),
                "max_avvikelse_px": float(np.max(np.abs(mitten - np.median(mitten)))),
                "andel_av_bredd": float(np.max(np.abs(mitten - np.median(mitten))) / w),
            }
    return ut


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("bild")
    p.add_argument("ut")
    p.add_argument("--aspekt", type=float, default=3.022,
                   help="målrektangelns längd/bredd (default: planens mätta 3,022)")
    p.add_argument("--bredd", type=int, default=900)
    p.add_argument("--horn", nargs=4, metavar="X,Y",
                   help="fyra kontrollpunkter i ordningen ÖV ÖH NH NV. Utan dem "
                        "gissas hörnen ur den gula ytans extrempunkter, vilket "
                        "faller när planytan har inhak — kantresidualen säger till.")
    a = p.parse_args()

    kalla_bild = Image.open(a.bild).convert("RGB")
    arr = np.asarray(kalla_bild)
    mask = storsta_klumpen(gul_mask(arr))
    if a.horn:
        h4 = np.array([[float(v) for v in p.split(",")] for p in a.horn], dtype=np.float64)
        kalla_horn = "angivna på kommandoraden"
    else:
        h4 = horn(mask)
        kalla_horn = "automatiska (extrempunkter i den gula ytan)"

    mb, ml = a.bredd, int(round(a.bredd * a.aspekt))
    mal = np.array([[0, 0], [mb, 0], [mb, ml], [0, ml]], dtype=np.float64)

    H = homografi(h4, mal)
    Hinv = np.linalg.inv(H)
    Hinv = Hinv / Hinv[2, 2]

    ratad = kalla_bild.transform((mb, ml), Image.Transform.PERSPECTIVE,
                                 Hinv.ravel()[:8], Image.Resampling.BICUBIC)
    pathlib.Path(a.ut).parent.mkdir(parents=True, exist_ok=True)
    ratad.save(a.ut, quality=94)

    kontroll = storsta_klumpen(gul_mask(np.asarray(ratad)))
    residual = kantresidual(kontroll)

    print(f"källa   {a.bild}")
    print(f"rätad   {a.ut}  ({mb} × {ml} px, aspekt {a.aspekt})")
    print(f"\nkontrollpunkter i källbilden (px) — {kalla_horn}:")
    for namn, (x, y) in zip(("övre vänster", "övre höger", "nedre höger", "nedre vänster"), h4):
        print(f"  {namn:<14} {x:7.1f} {y:7.1f}")
    print("\nkantresidual EFTER rätning — kanterna såg transformen aldrig:")
    for namn, d in residual.items():
        print(f"  {namn:<8} median x={d['median_px']:7.1f} px · "
              f"max avvikelse {d['max_avvikelse_px']:5.1f} px "
              f"({d['andel_av_bredd'] * 100:.2f} % av bredden)")

    varsta = max((d["andel_av_bredd"] for d in residual.values()), default=1.0)
    if varsta > 0.03:
        print(f"\nVARNING: kanterna är fortfarande krokiga ({varsta * 100:.1f} %). "
              "Hörnen är troligen fel tagna, eller bladet är inte plant.")
        return 1
    print(f"\nOK   kanterna raka inom {varsta * 100:.2f} % av bredden")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
