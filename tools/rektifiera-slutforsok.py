#!/usr/bin/env python3
"""Sista beräkningsförsöket att räta ridhusplanen.

Kravet står i `docs/F02-REKTIFIERING-KRAV.md` och är committat INNAN det här
kördes. Kortfattat: anpassa på planbladets tryck, validera på byggnadens
väggar, och stoppa om valideringen faller.

**Anpassningen** använder bara dokumentets eget tryck — ramkant, det gröna
bandets kanter, legendrutans linjaler. Fyra fotograferade kanter i varje
riktning ger två flyktpunkter, och ur dem en homografi som lägger
flyktlinjen i oändligheten. Byggnadens väggar rörs inte i det steget.

**Valideringen** sker på byggnadens väggar i den rätade bilden. De ingick
inte i anpassningen, så de kan falsifiera den. Mäts:

- parallellitet inom varje väggfamilj,
- ortogonalitet mellan familjerna,
- den gula planytans kantresidual.

Alla tre jämförs mot förhandsdeklarerade tal. Faller något: stopp. Talen
sänks inte i efterhand.

    python3 tools/rektifiera-slutforsok.py
"""

import importlib.util
import math
import pathlib
import sys

import numpy as np
from PIL import Image

ROT = pathlib.Path(__file__).resolve().parent.parent
BILD = ROT / "references" / "plans" / "ridhus-entreplan-utrymning.jpg"
# Utfallet sparas UTANFOR references/. En underkand ratning far inte ligga
# bland kallmaterialet: nasta agent som ser en fil dar utgar rimligen fran att
# den ar anvandbar, och den har ar 14,31 % skev.
UT = ROT / "audits" / "f02-rektifiering-slutforsok.jpg"

# FÖRHANDSDEKLARERAT, se docs/F02-REKTIFIERING-KRAV.md. Rör inte.
KRAV_KANT_PROCENT = 3.0
KRAV_ORTOGONAL_GRADER = 1.0
KRAV_PARALLELL_GRADER = 1.0


def ladda(namn: str, fil: str):
    s = importlib.util.spec_from_file_location(namn, str(ROT / "tools" / fil))
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


def flyktpunkt(linjer):
    """Minsta-kvadrat-skärning av linjer givna som (punkt, riktning)."""
    A, b = [], []
    for p, d in linjer:
        n = np.array([-d[1], d[0]])
        A.append(n)
        b.append(n @ p)
    x, *_ = np.linalg.lstsq(np.array(A), np.array(b), rcond=None)
    return np.array([x[0], x[1], 1.0])


def rektifierande_H(vpa, vpb, bild_w, bild_h):
    """Homografi som lägger flyktlinjen i oändligheten och gör de två
    riktningarna vinkelräta."""
    l = np.cross(vpa, vpb)
    l = l / l[2]
    Hp = np.array([[1, 0, 0], [0, 1, 0], [l[0], l[1], 1.0]])

    # Riktningarna efter Hp: flyktpunkterna hamnar i oändligheten.
    def riktning(vp):
        v = Hp @ vp
        return np.array([v[0], v[1]])

    da, db = riktning(vpa), riktning(vpb)
    da = da / np.linalg.norm(da)
    db = db / np.linalg.norm(db)
    # Affin del som skickar da -> (0,1) och db -> (1,0).
    M = np.linalg.inv(np.array([[db[0], da[0]], [db[1], da[1]]]))
    Ha = np.eye(3)
    Ha[:2, :2] = M
    H = Ha @ Hp

    # Skala och centrera så hela bilden får plats.
    horn = np.array([[0, 0, 1], [bild_w, 0, 1], [bild_w, bild_h, 1], [0, bild_h, 1]], dtype=float)
    ut = (H @ horn.T).T
    ut = ut[:, :2] / ut[:, 2:3]
    mn, mx = ut.min(axis=0), ut.max(axis=0)
    s = 2600.0 / max(mx - mn)
    S = np.array([[s, 0, -mn[0] * s], [0, s, -mn[1] * s], [0, 0, 1]])
    return S @ H, tuple(np.ceil((mx - mn) * s).astype(int))


def vaggfamiljer(bild: Image.Image, rp):
    """Byggnadens väggriktningar i EN bild, via Hough inne i den gula ytan.

    Det här är valideringsmaterialet. Det användes inte i anpassningen."""
    mask_full = rp.storsta_klumpen(rp.gul_mask(np.asarray(bild.convert("RGB"))))
    ys, xs = np.nonzero(mask_full)
    crop = bild.crop((int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())))
    k = 900 / crop.width
    crop = crop.resize((900, max(2, int(crop.height * k))), Image.LANCZOS)
    g = np.asarray(crop.convert("L"), dtype=np.float32)
    gulmask = rp.gul_mask(np.asarray(crop.convert("RGB")))
    H, W = g.shape

    gx = np.zeros_like(g); gy = np.zeros_like(g)
    gx[:, 1:-1] = g[:, 2:] - g[:, :-2]
    gy[1:-1, :] = g[2:, :] - g[:-2, :]
    mag = np.hypot(gx, gy)
    nara = gulmask.copy()
    for _ in range(4):
        n = nara.copy()
        n[1:, :] |= nara[:-1, :]; n[:-1, :] |= nara[1:, :]
        n[:, 1:] |= nara[:, :-1]; n[:, :-1] |= nara[:, 1:]
        nara = n
    if not nara.any():
        sys.exit("FEL  hittade ingen gul planyta att validera mot")
    kant = (mag > np.percentile(mag[nara], 98.0)) & nara
    ys, xs = np.nonzero(kant)

    NT = 720
    thetas = np.linspace(-np.pi / 2, np.pi / 2, NT, endpoint=False)
    rmax = int(np.hypot(W, H)) + 1
    rho = xs[:, None] * np.cos(thetas)[None, :] + ys[:, None] * np.sin(thetas)[None, :]
    ri = np.round(rho).astype(np.int32) + rmax
    acc = np.zeros((NT, 2 * rmax + 1), dtype=np.int32)
    for t in range(NT):
        np.add.at(acc[t], ri[:, t], 1)

    def toppar(gradmin, gradmax, antal, minpoang):
        """Starkaste linjerna i ett vinkelband, med undertryckt närområde."""
        band = [t for t in range(NT)
                if gradmin <= (math.degrees(thetas[t]) % 180) <= gradmax]
        tagna = []
        lokal = acc.copy()
        for _ in range(antal):
            basta, bt, br = -1, None, None
            for t in band:
                r = int(np.argmax(lokal[t]))
                if lokal[t, r] > basta:
                    basta, bt, br = int(lokal[t, r]), t, r
            if bt is None or basta < minpoang:
                break
            tagna.append(math.degrees(thetas[bt]) % 180)
            for t in range(max(0, bt - 8), min(NT, bt + 9)):
                lokal[t, max(0, br - 14): br + 15] = 0
        return tagna

    # Två skilda vinkelband: långsidorna är tre gånger så långa som
    # tvärväggarna och tar annars varenda plats.
    langa = toppar(60, 120, 8, 40)
    tvar = toppar(0, 30, 4, 25) + toppar(150, 180, 4, 25)
    return langa, tvar


def _dubblad(vinklar):
    """Riktningar lever modulo 180 grader. 0 och 175 ligger 5 grader isar,
    inte 175 — en naiv max-minus-min ljuger dar, och en falsk FALLER ar lika
    illa som ett falskt OK. Darfor dubbleras vinkeln och rakningen gors pa
    enhetscirkeln, dar 0 och 180 ar samma punkt."""
    return np.deg2rad(np.array(vinklar, dtype=float) % 180.0) * 2.0


def medelriktning(vinklar) -> float:
    """Cirkulart medelvarde, i grader modulo 180."""
    a = _dubblad(vinklar)
    return float((math.degrees(math.atan2(np.sin(a).mean(), np.cos(a).mean())) / 2.0) % 180.0)


def spridning(vinklar) -> float:
    """Storsta inbordes avstand inom familjen, modulo 180 grader."""
    if len(vinklar) < 2:
        return float("nan")
    v = np.array(vinklar, dtype=float) % 180.0
    varst = 0.0
    for i in range(len(v)):
        for j in range(i + 1, len(v)):
            d = abs(v[i] - v[j]) % 180.0
            varst = max(varst, min(d, 180.0 - d))
    return float(varst)


def ortogonalitet(fam1, fam2) -> float:
    """Hur langt fran 90 grader familjerna star, modulo 180."""
    if not fam1 or not fam2:
        return float("nan")
    d = abs(medelriktning(fam1) - medelriktning(fam2)) % 180.0
    return float(abs(min(d, 180.0 - d) - 90.0))


def main() -> int:
    dl = ladda("dl", "dokumentlinjer.py")
    rp = ladda("rp", "rektifiera-plan.py")

    bild = Image.open(BILD).convert("RGB")
    arr = np.asarray(bild).astype(np.float64)
    grad = dl.gradbild(arr)

    print("ANPASSNING — bara dokumentets tryck, inga byggnadsväggar\n")
    linjer = {"A": [], "B": []}
    for namn, (h1, h2) in dl.HINTAR.items():
        m, d, rms, mx, n = dl.forfina(grad, h1, h2)
        linjer[namn[0]].append((m, d))
        print(f"  {namn:<20} RMS {rms:5.2f} px   max {mx:5.1f} px")

    vpa = flyktpunkt(linjer["A"])
    vpb = flyktpunkt(linjer["B"])
    print(f"\n  flyktpunkt A  ({vpa[0]:10.0f}, {vpa[1]:10.0f})")
    print(f"  flyktpunkt B  ({vpb[0]:10.0f}, {vpb[1]:10.0f})")

    H, storlek = rektifierande_H(vpa, vpb, bild.width, bild.height)
    Hinv = np.linalg.inv(H)
    Hinv = Hinv / Hinv[2, 2]
    ratad = bild.transform(storlek, Image.Transform.PERSPECTIVE,
                           Hinv.ravel()[:8], Image.Resampling.BICUBIC)
    UT.parent.mkdir(parents=True, exist_ok=True)
    ratad.save(UT, quality=93)
    print(f"\n  rätad bild: {UT.relative_to(ROT)}  {storlek[0]} × {storlek[1]} px")

    print("\nVALIDERING — byggnadens väggar, som INTE ingick i anpassningen\n")
    langa, tvar = vaggfamiljer(ratad, rp)
    print(f"  långsidor   {len(langa)} linjer  vinklar "
          f"{[round(v, 2) for v in langa]}")
    print(f"  tvärväggar  {len(tvar)} linjer  vinklar "
          f"{[round(v, 2) for v in tvar]}")

    par_l = spridning(langa)
    par_t = spridning(tvar)
    ort = ortogonalitet(langa, tvar)

    kontroll = rp.storsta_klumpen(rp.gul_mask(np.asarray(ratad)))
    kant = rp.kantresidual(kontroll)
    varst = max((d["andel_av_bredd"] for d in kant.values()), default=1.0) * 100

    print("\nUTFALL MOT DET FÖRHANDSDEKLARERADE KRAVET\n")
    rader = [
        ("kantresidual, gula ytan", varst, KRAV_KANT_PROCENT, "%"),
        ("parallellitet, långsidor", par_l, KRAV_PARALLELL_GRADER, "°"),
        ("parallellitet, tvärväggar", par_t, KRAV_PARALLELL_GRADER, "°"),
        ("ortogonalitet mellan familjerna", ort, KRAV_ORTOGONAL_GRADER, "°"),
    ]
    fall = 0
    for namn, varde, krav, enhet in rader:
        ok = (varde == varde) and varde <= krav
        fall += 0 if ok else 1
        print(f"  {namn:<34} {varde:8.2f} {enhet}   krav ≤ {krav:.1f} {enhet}   "
              f"{'OK' if ok else 'FALLER'}")

    if fall:
        print(f"\n{fall} av {len(rader)} mått faller. STOPP enligt "
              "docs/F02-REKTIFIERING-KRAV.md.")
        print("Kravet sänks inte i efterhand och de sex rummen hittas inte på.")
        return 1
    print("\nAlla mått inom kravet.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
