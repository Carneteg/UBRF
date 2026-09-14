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
from datetime import datetime, timezone

ROT = pathlib.Path(__file__).resolve().parent.parent
PROJEKT = "tdznhaybxmekznasxtts"
URL = f"https://{PROJEKT}.supabase.co"
HINK = "reference-assets"

# Vad som speglas, och vilken asset_type raden får.
#
#[[ BILD galler aven i references/video. Katalogen listade en gang bara
#   filmbehallarna, och da lag de 192 nyckelrutorna i
#   references/video/*/ helt utanfor spegeln -- utan att nagot sa ifran, for
#   verktyget rapporterade glatt "139 filer" och menade alla det kande till.
#
#   De rutorna ar inte dekoration. INTERIOR-MATRIS citerar dem som belagg,
#   och kallfilmerna till de flesta av dem ligger inte i repot (#46,
#   [DRIVE-ONLY]). Rutorna ar alltsa den enda kopian av det beviset som
#   finns, vilket gor dem mer angelagna att spegla an filmerna, inte mindre.
#
#   Exakt samma omfattningsfel fanns i tools/kolla-referenser.py och rattades
#   dar. Att det gick att gora om i ett andra verktyg sager att felet sitter i
#   monstret -- en katalog vars namn later som en filtyp -- och inte i en
#   slarvig rad. ]]
BILD = ("*.jpg", "*.jpeg", "*.png")
KALLOR = [
    ("references/buildings", BILD,                 "photo"),
    ("references/plans",     BILD,                 "plan"),
    ("references/video",     BILD + ("*.mov", "*.mp4"), "video"),
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


#[[ HTTP-GRANSEN AR UTBRYTBAR MED FLIT. Bada vagarna som betyder nagot --
#   uppladdningen och kontrollen -- kraver en hemlig nyckel, och darfor kunde
#   ingen av dem provas. Tva fel fick ligga kvar i just de raderna: manifestet
#   skrevs aldrig, och hinkkontrollen listade inte rekursivt. Ett prov som
#   inte kan na koden ar inget prov, och da spelar det ingen roll hur noga
#   resten av filen ar skriven. `tools/prov-spegla.py` satter TRANSPORT till
#   en fejkad server och kor bada vagarna helt utan nyckel. ]]
def _urllib_transport(metod: str, url: str, huvuden: dict,
                      data: bytes | None) -> tuple[int, bytes]:
    r = urllib.request.Request(url, data=data, method=metod)
    for k, v in huvuden.items():
        r.add_header(k, v)
    try:
        with urllib.request.urlopen(r) as svar:
            return svar.status, svar.read()
    except urllib.error.HTTPError as fel:
        return fel.code, fel.read()


TRANSPORT = _urllib_transport


def be(metod: str, vag: str, n: str, data: bytes | None = None,
       typ: str | None = None, extra: dict | None = None) -> tuple[int, bytes]:
    huvuden = {"apikey": n, "Authorization": f"Bearer {n}"}
    if typ:
        huvuden["Content-Type"] = typ
    if extra:
        huvuden.update(extra)
    return TRANSPORT(metod, f"{URL}{vag}", huvuden, data)


def skriv_manifestrad(f: dict, n: str) -> tuple[bool, str]:
    """Satter spegelfalten pa manifestraden. Returnerar (lyckades, skal).

    Kors BARA efter att objektet lasts tillbaka och stamt. Sokvagen och
    storage_verified_at hor ihop -- schemats check-villkor tillater inte det
    ena utan det andra -- och darfor skrivs de i samma anrop.

    `return=representation` ar inte kosmetik: en PATCH som inte matchar nagon
    rad ger HTTP 200 med en TOM lista. Utan att rakna raderna hade ett id som
    inte finns i manifestet sett ut som en lyckad skrivning."""
    kropp = json.dumps({
        "supabase_storage_path": f"{HINK}/{f['lagringsvag']}",
        "sha256": f["verifierad_sha256"],
        "bytes": f["verifierad_bytes"],
        "storage_verified_at": datetime.now(timezone.utc)
            .isoformat(timespec="seconds").replace("+00:00", "Z"),
    }).encode()
    kod, svar = be("PATCH", f"/rest/v1/reference_assets?id=eq.{f['id']}", n,
                   kropp, "application/json",
                   {"Prefer": "return=representation"})
    if kod not in (200, 204):
        return False, f"HTTP {kod} {svar[:200]!r}"
    try:
        rader = json.loads(svar) if svar else []
    except json.JSONDecodeError:
        return False, f"oläsbart svar: {svar[:200]!r}"
    if len(rader) != 1:
        return False, (f"PATCH matchade {len(rader)} rader, inte 1 — "
                       f"finns id {f['id']!r} i manifestet?")
    return True, ""


def lista_rekursivt(n: str, prefix: str = "") -> tuple[set, str | None]:
    """Alla objektsokvagar i hinken, hela vagen ner.

    Supabase list ar INTE rekursiv: den listar det som ligger direkt under en
    sokvag, och mappar kommer tillbaka som poster utan `id`. En enda listning
    med prefix "" ger alltsa `buildings`, `plans`, `video` -- aldrig
    `buildings/stall/foo.jpg`. Den som jamfor de namnen med sina nastlade
    nycklar far aldrig en trafft, och kontrollen kan da inte ga igenom ens
    nar spegeln ar helt korrekt."""
    ut: set = set()
    offset = 0
    while True:
        kod, svar = be("POST", f"/storage/v1/object/list/{HINK}", n,
                       json.dumps({"prefix": prefix, "limit": 100,
                                   "offset": offset}).encode(),
                       "application/json")
        if kod != 200:
            return ut, f"HTTP {kod} {svar[:200]!r} vid prefix {prefix!r}"
        try:
            poster = json.loads(svar)
        except json.JSONDecodeError:
            return ut, f"oläsbart svar vid prefix {prefix!r}"
        if not poster:
            return ut, None
        for o in poster:
            if not isinstance(o, dict) or not o.get("name"):
                continue
            full = f"{prefix}/{o['name']}" if prefix else o["name"]
            if o.get("id") is None:
                djupare, fel = lista_rekursivt(n, full)
                if fel:
                    return ut, fel
                ut |= djupare
            else:
                ut.add(full)
        if len(poster) < 100:
            return ut, None
        offset += len(poster)


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
        lyckade, verifierade, skrivna = 0, 0, 0
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

            #[[ SKRIVNINGEN, inte en utskrift av vad som borde skrivas.
            #   Tidigare raknade skriptet fram raderna och skrev ut dem, och
            #   ingenting nadde databasen. Manifestet forblev tomt medan bade
            #   PR-texten och dokumentet pastod att falten sattes efter
            #   aterlasning. Ett manifest som inte skrivs ar samma sak som ett
            #   manifest som ljuger: nasta agent slutar leta lika snabbt. ]]
            ok, skal = skriv_manifestrad(f, n)
            if not ok:
                print(f"FEL  {f['lagringsvag']} laddades upp och verifierades, "
                      f"men manifestraden gick inte att skriva: {skal}")
                continue
            skrivna += 1

        print(f"{lyckade}/{len(filer)} objekt uppladdade, "
              f"{verifierade} verifierade genom att läsas tillbaka, "
              f"{skrivna} manifestrader skrivna")
        if skrivna != len(filer):
            print("\nManifestet speglar alltså INTE hela repot. Sökväg och")
            print("storage_verified_at hör ihop; schemats check-villkor tillåter")
            print("inte det ena utan det andra, så en halvskriven rad finns inte.")
        return 0 if skrivna == len(filer) else 1

    #[[ --kontrollera: jämför manifestet mot verkligheten, åt båda hållen.
    #   En lista som bara läses uppifrån och ner missar precis det fall den
    #   finns till för — ett objekt i hinken som ingen rad känns vid. ]]
    i_hinken, fel = lista_rekursivt(n)
    if fel:
        print(f"FEL  kunde inte lista hinken: {fel}")
        return 1
    vantade = {f["lagringsvag"] for f in filer}
    saknas = sorted(vantade - i_hinken)
    foraldralosa = sorted(i_hinken - vantade)
    for v in saknas:
        print(f"FEL  {v} finns i repot men inte i hinken")
    for v in foraldralosa:
        print(f"FEL  {v} ligger i hinken utan motsvarande fil i repot")
    #[[ Manifestet ar tredje parten. Hinken och repot kan stamma medan en rad
    #   pekar pa ett objekt som inte finns -- det ar precis det fall
    #   check-villkoret i schemat inte kan fanga, for det ser bara att bada
    #   falten ar satta, aldrig om sokvagen leder nagonstans. ]]
    kod, svar = be("GET", "/rest/v1/reference_assets"
                   "?select=id,supabase_storage_path&supabase_storage_path=not.is.null",
                   n)
    pastadda = 0
    if kod != 200:
        print(f"FEL  kunde inte läsa manifestet: HTTP {kod} {svar[:200]!r}")
        return 1
    for rad in json.loads(svar) if svar else []:
        vag = (rad.get("supabase_storage_path") or "")
        utan_hink = vag[len(HINK) + 1:] if vag.startswith(HINK + "/") else vag
        pastadda += 1
        if utan_hink not in i_hinken:
            print(f"FEL  manifestraden {rad.get('id')!r} påstår {vag!r}, "
                  f"men objektet finns inte i hinken")
            foraldralosa.append(f"manifest:{rad.get('id')}")

    print(f"\n{len(i_hinken)} objekt i hinken, {len(vantade)} filer i repot, "
          f"{pastadda} manifestrader med sökväg, "
          f"{len(saknas)} saknas, {len(foraldralosa)} föräldralösa")
    return 1 if (saknas or foraldralosa) else 0


if __name__ == "__main__":
    raise SystemExit(main())
