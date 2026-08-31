#!/usr/bin/env python3
"""Söker planets två vinkelräta linjefamiljer och deras flyktpunkter.

Andra försöket att räta ridhusplanen. Det första — fyra hörn på den gula
planytan, tools/rektifiera-plan.py — konvergerade inte, och invändningen att
man ska pröva PARALLELLA VÄGGRIKTNINGAR i stället för hörn är riktig: en plan
yta går att räta ur två flyktpunkter utan att ett enda hörn behöver hittas.

Metoden: Sobel-kanter INNE i planytan (ramen och legenden får inte rösta),
Hough, och toppar sökta i två skilda vinkelband — annars äter långsidorna hela
listan, de är tre gånger så långa som tvärväggarna. Varje familj skärs sedan i
minsta-kvadratmening.

DET AVGÖRANDE TALET ÄR MEDELRESIDUALEN. Konvergerar en familj mot en äkta
flyktpunkt ligger den nära noll. Gör den inte det är familjen förorenad — av
läktarband med egen lutning, av symboler, av korta segment — och en homografi
byggd på den punkten hade rätat bilden fel utan att någonting sagt ifrån.

    python3 tools/analysera-planlinjer.py

Utfall 2026-08-31 på ridhus-entreplan-utrymning.jpg: 178 px respektive 382 px
på en bild 900 × 2502. Alldeles för högt. Se docs/F02-DIGITALISERING.md.
"""
import numpy as np
from PIL import Image
import importlib.util
spec = importlib.util.spec_from_file_location("rp", "tools/rektifiera-plan.py")
rp = importlib.util.module_from_spec(spec); spec.loader.exec_module(rp)

full = Image.open("references/plans/ridhus-entreplan-utrymning.jpg").convert("RGB")
mask_full = rp.storsta_klumpen(rp.gul_mask(np.asarray(full)))
ys, xs = np.nonzero(mask_full)
x0, y0 = int(xs.min()), int(ys.min())
crop = full.crop((x0, y0, int(xs.max()), int(ys.max())))
skala = 900 / crop.width
crop = crop.resize((900, int(crop.height * skala)), Image.LANCZOS)
g = np.asarray(crop.convert("L"), dtype=np.float32)
gulmask = rp.gul_mask(np.asarray(crop))
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
kant = (mag > np.percentile(mag[nara], 98.0)) & nara
ys, xs = np.nonzero(kant)

NT = 720
thetas = np.linspace(-np.pi/2, np.pi/2, NT, endpoint=False)
rmax = int(np.hypot(W, H)) + 1
rho = xs[:, None] * np.cos(thetas)[None, :] + ys[:, None] * np.sin(thetas)[None, :]
ri = np.round(rho).astype(np.int32) + rmax
acc = np.zeros((NT, 2 * rmax + 1), dtype=np.int32)
for t in range(NT):
    np.add.at(acc[t], ri[:, t], 1)

def toppar(tmin, tmax, n, minp):
    """Toppar inom ett vinkelband — annars äter långsidorna hela listan."""
    band = [(t, thetas[t]) for t in range(NT) if tmin <= np.degrees(thetas[t]) <= tmax]
    kand = []
    for t, th in band:
        for r in np.flatnonzero(acc[t] >= minp):
            kand.append((int(acc[t][r]), t, int(r), th))
    kand.sort(reverse=True)
    valda = []
    for p, t, r, th in kand:
        if any(abs(t - t2) < 10 and abs(r - r2) < 20 for _, t2, r2, _ in valda): continue
        valda.append((p, t, r, th))
        if len(valda) >= n: break
    return valda

fam = {
    "långsidor (nära lodrät i bild)": toppar(-20, 20, 14, 60),
    "tvärväggar (nära vågrät i bild)": toppar(60, 90, 14, 25) + toppar(-90, -60, 14, 25),
}
linjer = {}
for namn, v in fam.items():
    print(f"\n{namn}: {len(v)} linjer")
    L = []
    for p, t, r, th in v[:14]:
        a, b, c = np.cos(th), np.sin(th), -(r - rmax)
        L.append((a, b, c))
        print(f"   θ={np.degrees(th):+7.2f}°  ρ={r - rmax:6d}  poäng {p}")
    linjer[namn] = np.array(L)

def flyktpunkt(L):
    """Minsta-kvadrat-skärning: punkten som ligger närmast alla linjer."""
    A = L[:, :2]; b = -L[:, 2]
    p, *_ = np.linalg.lstsq(A, b, rcond=None)
    res = np.abs(A @ p - b)
    return p, float(res.mean())

for namn, L in linjer.items():
    if len(L) >= 2:
        p, res = flyktpunkt(L)
        print(f"\n{namn}: flyktpunkt ({p[0]:12.1f}, {p[1]:12.1f})  medelresidual {res:.2f} px")
        print(f"   avstånd från bildmitt: {np.hypot(p[0]-W/2, p[1]-H/2):.0f} px  (bild {W}×{H})")
np.save("/tmp/claude-0/-home-user-UBRF/f2a66cec-5e4b-56b0-8cd1-296a27a15d9e/scratchpad/fam.npy",
        np.array([len(v) for v in linjer.values()]))
print(f"\nbeskärning ({x0}, {y0}), skala {skala:.5f}")
import numpy as np
from PIL import Image
import importlib.util
spec = importlib.util.spec_from_file_location("rp", "tools/rektifiera-plan.py")
rp = importlib.util.module_from_spec(spec); spec.loader.exec_module(rp)

full = Image.open("references/plans/ridhus-entreplan-utrymning.jpg").convert("RGB")
mask_full = rp.storsta_klumpen(rp.gul_mask(np.asarray(full)))
ys, xs = np.nonzero(mask_full)
x0, y0 = int(xs.min()), int(ys.min())
crop = full.crop((x0, y0, int(xs.max()), int(ys.max())))
skala = 900 / crop.width
crop = crop.resize((900, int(crop.height * skala)), Image.LANCZOS)
g = np.asarray(crop.convert("L"), dtype=np.float32)
gulmask = rp.gul_mask(np.asarray(crop))
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
kant = (mag > np.percentile(mag[nara], 98.0)) & nara
ys, xs = np.nonzero(kant)

NT = 720
thetas = np.linspace(-np.pi/2, np.pi/2, NT, endpoint=False)
rmax = int(np.hypot(W, H)) + 1
rho = xs[:, None] * np.cos(thetas)[None, :] + ys[:, None] * np.sin(thetas)[None, :]
ri = np.round(rho).astype(np.int32) + rmax
acc = np.zeros((NT, 2 * rmax + 1), dtype=np.int32)
for t in range(NT):
    np.add.at(acc[t], ri[:, t], 1)

def toppar(tmin, tmax, n, minp):
    """Toppar inom ett vinkelband — annars äter långsidorna hela listan."""
    band = [(t, thetas[t]) for t in range(NT) if tmin <= np.degrees(thetas[t]) <= tmax]
    kand = []
    for t, th in band:
        for r in np.flatnonzero(acc[t] >= minp):
            kand.append((int(acc[t][r]), t, int(r), th))
    kand.sort(reverse=True)
    valda = []
    for p, t, r, th in kand:
        if any(abs(t - t2) < 10 and abs(r - r2) < 20 for _, t2, r2, _ in valda): continue
        valda.append((p, t, r, th))
        if len(valda) >= n: break
    return valda

fam = {
    "långsidor (nära lodrät i bild)": toppar(-20, 20, 14, 60),
    "tvärväggar (nära vågrät i bild)": toppar(60, 90, 14, 25) + toppar(-90, -60, 14, 25),
}
linjer = {}
for namn, v in fam.items():
    print(f"\n{namn}: {len(v)} linjer")
    L = []
    for p, t, r, th in v[:14]:
        a, b, c = np.cos(th), np.sin(th), -(r - rmax)
        L.append((a, b, c))
        print(f"   θ={np.degrees(th):+7.2f}°  ρ={r - rmax:6d}  poäng {p}")
    linjer[namn] = np.array(L)

def flyktpunkt(L):
    """Minsta-kvadrat-skärning: punkten som ligger närmast alla linjer."""
    A = L[:, :2]; b = -L[:, 2]
    p, *_ = np.linalg.lstsq(A, b, rcond=None)
    res = np.abs(A @ p - b)
    return p, float(res.mean())

for namn, L in linjer.items():
    if len(L) >= 2:
        p, res = flyktpunkt(L)
        print(f"\n{namn}: flyktpunkt ({p[0]:12.1f}, {p[1]:12.1f})  medelresidual {res:.2f} px")
        print(f"   avstånd från bildmitt: {np.hypot(p[0]-W/2, p[1]-H/2):.0f} px  (bild {W}×{H})")
np.save("/tmp/claude-0/-home-user-UBRF/f2a66cec-5e4b-56b0-8cd1-296a27a15d9e/scratchpad/fam.npy",
        np.array([len(v) for v in linjer.values()]))
print(f"\nbeskärning ({x0}, {y0}), skala {skala:.5f}")
