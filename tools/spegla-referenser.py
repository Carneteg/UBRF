#!/usr/bin/env python3
"""Speglar referensmedia till Supabase Storage och håller manifestet ärligt.

Regeln som styr hela skriptet: `supabase_storage_path` får aldrig sättas för
ett objekt som inte finns i Storage. Ett manifest som påstår att en fil är
speglad, när den inte är det, är värre än ett tomt manifest — det gör att
nästa agent slutar leta.

    python3 tools/spegla-referenser.py --lista        # vad som skulle speglas
    python3 tools/spegla-referenser.py --ladda-upp    # kräver hemlig nyckel
    python3 tools/spegla-referenser.py --kontrollera  # verifierar manifestet

GitHub-sidans checksummor ägs av `tools/kolla-referenser.py` i F02-spåret.
Det här verktyget läser filerna direkt och behöver inte den listan.

Nyckeln läses ur SUPABASE_SECRET_KEY eller SUPABASE_SERVICE_ROLE_KEY. Den
publicerbara nyckeln duger INTE och ska inte duga: hinken är privat, och att
öppna anon-skrivning för att komma runt det hade gjort råmaterialet skrivbart
för var och en som har den publika nyckeln.
"""

import argparse
import hashlib
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

ROT = pathlib.Path(__file__).resolve().parent.parent
PROJEKT = "tdznhaybxmekznasxtts"
URL = f"https://{PROJEKT}.supabase.co"
HINK = "reference-assets"

# Vad som speglas, och vilken asset_type raden får.
KALLOR = [
    ("references/buildings", ("*.jpg", "*.jpeg", "*.png"), "photo"),
    ("references/plans",     ("*.jpg", "*.jpeg", "*.png"), "plan"),
    ("references/video",     ("*.mov", "*.mp4"),           "video"),
]

MIME = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".mov": "video/quicktime", ".mp4": "video/mp4",
}


def nyckel() -> str | None:
    for namn in ("SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY"):
        v = os.environ.get(namn)
        if v:
            return v
    return None


def summa(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for bit in iter(lambda: f.read(1 << 20), b""):
            h.update(bit)
    return h.hexdigest()


def samla() -> list[dict]:
    """Filerna som ska speglas, med id, väg, storlek och sha256."""
    ut = []
    for katalog, monster, typ in KALLOR:
        bas = ROT / katalog
        if not bas.is_dir():
            continue
        filer: list[pathlib.Path] = []
        for m in monster:
            filer.extend(bas.rglob(m))
        for f in sorted(filer):
            rel = f.relative_to(ROT).as_posix()
            ut.append({
                "id": rel.replace("references/", "").replace("/", "-").rsplit(".", 1)[0],
                "github_path": rel,
                "lagringsvag": rel[len("references/"):],
                "asset_type": typ,
                "bytes": f.stat().st_size,
                "sha256": summa(f),
                "lokal": f,
            })
    return ut


def be(metod: str, vag: str, n: str, data: bytes | None = None,
       typ: str | None = None) -> tuple[int, bytes]:
    r = urllib.request.Request(f"{URL}{vag}", data=data, method=metod)
    r.add_header("apikey", n)
    r.add_header("Authorization", f"Bearer {n}")
    if typ:
        r.add_header("Content-Type", typ)
    try:
        with urllib.request.urlopen(r) as svar:
            return svar.status, svar.read()
    except urllib.error.HTTPError as fel:
        return fel.code, fel.read()


def main() -> int:
    p = argparse.ArgumentParser()
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--lista", action="store_true")
    g.add_argument("--ladda-upp", action="store_true")
    g.add_argument("--kontrollera", action="store_true")
    p.add_argument("--json", action="store_true", help="skriv listan som JSON")
    a = p.parse_args()

    filer = samla()

    if a.lista:
        if a.json:
            print(json.dumps([{k: v for k, v in f.items() if k != "lokal"}
                              for f in filer], ensure_ascii=False, indent=2))
            return 0
        per = {}
        for f in filer:
            per[f["asset_type"]] = per.get(f["asset_type"], 0) + 1
        for typ, antal in sorted(per.items()):
            print(f"{typ:<8} {antal:4d} filer")
        print(f"{'summa':<8} {len(filer):4d} filer, "
              f"{sum(f['bytes'] for f in filer) / 1e6:.1f} MB")
        return 0

    n = nyckel()
    if not n:
        print("SUPABASE_SECRET_KEY / SUPABASE_SERVICE_ROLE_KEY saknas i miljön.")
        print()
        print("Hinken är privat. Den publicerbara nyckeln kan inte skriva till")
        print("den, och det är avsiktligt: att lägga in en anon-insert-policy")
        print("för att komma runt det hade gjort råfilmerna skrivbara för alla")
        print("som har den publika nyckeln. Uppladdningen kräver en hemlig")
        print("nyckel, och den finns inte i den här miljön.")
        return 2

    if a.ladda_upp:
        lyckade, verifierade = 0, 0
        for f in filer:
            vag = f"/storage/v1/object/{HINK}/{f['lagringsvag']}"
            typ = MIME.get(f["lokal"].suffix.lower(), "application/octet-stream")
            kropp = f["lokal"].read_bytes()
            kod, svar = be("POST", vag, n, kropp, typ)
            if kod == 409:  # finns redan
                kod, svar = be("PUT", vag, n, kropp, typ)
            if kod not in (200, 201):
                print(f"FEL  {f['lagringsvag']}  HTTP {kod}  {svar[:200]!r}")
                continue
            lyckade += 1

            #[[ VERIFIERINGEN LÄSER TILLBAKA OBJEKTET. Att hasha den lokala
            #   filen och kalla resultatet verifierat vore att intyga något
            #   som aldrig lämnade maskinen: en trunkerad uppladdning, en
            #   omkodning i tjänsten eller ett fel i sökvägen hade sett
            #   likadant ut. Manifestet får bara sin sha256 och sin
            #   storage_verified_at ur det som faktiskt kom tillbaka. ]]
            kod2, hamtat = be("GET", vag, n)
            if kod2 != 200:
                print(f"FEL  {f['lagringsvag']} gick inte att läsa tillbaka: HTTP {kod2}")
                continue
            sha_ute = hashlib.sha256(hamtat).hexdigest()
            if sha_ute != f["sha256"] or len(hamtat) != f["bytes"]:
                print(f"FEL  {f['lagringsvag']} skiljer sig efter uppladdning: "
                      f"{len(hamtat)} byte / {sha_ute[:12]}… mot "
                      f"{f['bytes']} byte / {f['sha256'][:12]}…")
                continue
            verifierade += 1
            f["verifierad_sha256"] = sha_ute
            f["verifierad_bytes"] = len(hamtat)

        print(f"{lyckade}/{len(filer)} objekt uppladdade, "
              f"{verifierade} verifierade genom att läsas tillbaka")
        if verifierade:
            print("\nManifestrader att skriva — BARA de verifierade. Sökväg och")
            print("storage_verified_at hör ihop; schemats check-villkor tillåter")
            print("inte det ena utan det andra.")
            for f in filer:
                if "verifierad_sha256" in f:
                    print(f"  {f['id']}  {HINK}/{f['lagringsvag']}  "
                          f"{f['verifierad_bytes']} byte")
        return 0 if verifierade == len(filer) else 1

    #[[ --kontrollera: jämför manifestet mot verkligheten, åt båda hållen.
    #   En lista som bara läses uppifrån och ner missar precis det fall den
    #   finns till för — ett objekt i hinken som ingen rad känns vid. ]]
    kod, svar = be("POST", f"/storage/v1/object/list/{HINK}", n,
                   json.dumps({"prefix": "", "limit": 1000}).encode(), "application/json")
    if kod != 200:
        print(f"FEL  kunde inte lista hinken: HTTP {kod} {svar[:200]!r}")
        return 1
    i_hinken = {o.get("name") for o in json.loads(svar) if isinstance(o, dict)}
    vantade = {f["lagringsvag"] for f in filer}
    saknas = sorted(vantade - i_hinken)
    foraldralosa = sorted(i_hinken - vantade)
    for v in saknas:
        print(f"FEL  {v} finns i repot men inte i hinken")
    for v in foraldralosa:
        print(f"FEL  {v} ligger i hinken utan motsvarande fil i repot")
    print(f"\n{len(i_hinken)} objekt i hinken, {len(vantade)} filer i repot, "
          f"{len(saknas)} saknas, {len(foraldralosa)} föräldralösa")
    return 1 if (saknas or foraldralosa) else 0


if __name__ == "__main__":
    raise SystemExit(main())
