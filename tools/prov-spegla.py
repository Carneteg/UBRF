#!/usr/bin/env python3
"""Prov for tools/spegla-referenser.py -- utan nyckel, utan natverk.

Bada vagarna som betyder nagot i speglingsverktyget kraver en hemlig nyckel:
uppladdningen och kontrollen. Darfor kunde ingen av dem provas, och darfor
fick tva fel ligga kvar i just de raderna -- manifestet skrevs aldrig, och
hinkkontrollen listade inte rekursivt. Bada hittades av en lasare, inte av
en grind.

Det har provet satter `spegla.TRANSPORT` till en fejkad Supabase och kor
kodvagarna pa riktigt. Ingen nyckel, inget natverk, ingen delad tillstand
mellan fallen.

    python3 tools/prov-spegla.py
"""

import contextlib
import hashlib
import importlib.util
import io
import os
import json
import pathlib
import sys
import tempfile

ROT = pathlib.Path(__file__).resolve().parent.parent

_spec = importlib.util.spec_from_file_location(
    "spegla", ROT / "tools" / "spegla-referenser.py")
spegla = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(spegla)

fails = 0


def check(namn, villkor, detalj=""):
    global fails
    if villkor:
        print(f"  OK   {namn}{'  ' + detalj if detalj else ''}")
    else:
        fails += 1
        print(f"  FEL  {namn}{'  ' + detalj if detalj else ''}")


class FejkadSupabase:
    """Beter sig som de delar av Supabase skriptet faktiskt ror.

    Viktigast: `list` ar INTE rekursiv, precis som i tjansten. Den svarar med
    det som ligger direkt under prefixet, och mappar kommer tillbaka utan
    `id`. Fejkar man den rekursiv provar man en tjanst som inte finns, och da
    hade felet i kontrollen aldrig kunnat visa sig har heller."""

    def __init__(self, objekt=None, manifest=None, trasig_aterlasning=None):
        self.objekt = dict(objekt or {})          # sokvag -> bytes
        self.manifest = list(manifest or [])      # rader med id
        self.trasig = trasig_aterlasning or {}    # sokvag -> bytes att svara med
        self.patchar = []                         # allt som skrevs
        self.listanrop = []

    def __call__(self, metod, url, huvuden, data):
        vag = url.split(".co", 1)[1]

        if vag.startswith(f"/storage/v1/object/list/{spegla.HINK}"):
            fraga = json.loads(data)
            prefix = fraga["prefix"]
            self.listanrop.append(prefix)
            return 200, json.dumps(self._lista(prefix)).encode()

        if vag.startswith(f"/storage/v1/object/{spegla.HINK}/"):
            nyckel = vag[len(f"/storage/v1/object/{spegla.HINK}/"):]
            if metod in ("POST", "PUT"):
                self.objekt[nyckel] = data
                return 200, b"{}"
            if metod == "GET":
                if nyckel in self.trasig:
                    svar = self.trasig[nyckel]
                    return (404, b"") if svar is None else (200, svar)
                if nyckel not in self.objekt:
                    return 404, b""
                return 200, self.objekt[nyckel]

        if vag.startswith("/rest/v1/reference_assets"):
            if metod == "GET":
                return 200, json.dumps(
                    [r for r in self.manifest if r.get("supabase_storage_path")]
                ).encode()
            if metod == "PATCH":
                id_ = vag.split("id=eq.", 1)[1].split("&")[0]
                falt = json.loads(data)
                traffar = [r for r in self.manifest if r["id"] == id_]
                for r in traffar:
                    r.update(falt)
                self.patchar.append((id_, falt))
                return 200, json.dumps(traffar).encode()

        raise AssertionError(f"ovantat anrop: {metod} {vag}")

    def _lista(self, prefix):
        direkt, mappar = [], set()
        for k in self.objekt:
            if prefix and not k.startswith(prefix + "/"):
                continue
            rest = k[len(prefix) + 1:] if prefix else k
            if "/" in rest:
                mappar.add(rest.split("/", 1)[0])
            else:
                direkt.append(rest)
        return ([{"name": m, "id": None} for m in sorted(mappar)]
                + [{"name": d, "id": "obj-" + d} for d in sorted(direkt)])


def bygg_filer(tmp, innehall):
    """Skriver filer under en tillfallig references/ och returnerar samla()."""
    filer = []
    for rel, data in innehall.items():
        p = tmp / "references" / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    gammal_rot = spegla.ROT
    spegla.ROT = tmp
    try:
        filer = spegla.samla()
    finally:
        spegla.ROT = gammal_rot
    return filer


INNEHALL = {
    "buildings/stall/a.jpg": b"aaaa",
    "buildings/ridhus/b.jpg": b"bbbbbb",
    "plans/c.png": b"cc",
    #[[ En nyckelruta under video/. Speglade verktyget en gang bara *.mov
    #   darifran, och 192 sadana rutor foll utanfor utan att nagot sa
    #   ifran. Filen ligger i provet just for att halla den vagen oppen. ]]
    "video/nyckelrutor/d.jpg": b"dddd",
}


def med_filer(fn):
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        return fn(bygg_filer(tmp, INNEHALL), tmp)


def manifest_for(filer):
    return [{"id": f["id"], "supabase_storage_path": None} for f in filer]


#[[ KOR main(), INTE EN KOPIA AV DEN.
#
#   Forsta versionen av det har provet byggde om uppladdningsslingan och
#   kontrollen har inne och anropade hjalpfunktionerna direkt. Det hade varit
#   vardelost: bagge felen som provet finns till for att fanga satt i att
#   main() INTE anropade det den skulle. Ett prov med en egen kopia av
#   slingan hade varit gront genom hela buggen.
#
#   Darfor gar allt genom main(), med argv, miljo och ROT satta. Enda
#   fejkade delen ar HTTP-gransen. ]]
def kor(argv, fejk, rot):
    spegla.TRANSPORT = fejk
    gammal_argv, gammal_rot = sys.argv, spegla.ROT
    gammal_nyckel = os.environ.get("SUPABASE_SECRET_KEY")
    sys.argv = ["spegla-referenser.py"] + argv
    spegla.ROT = rot
    os.environ["SUPABASE_SECRET_KEY"] = "prov-nyckel-inte-en-riktig"
    ut = io.StringIO()
    try:
        with contextlib.redirect_stdout(ut):
            kod = spegla.main()
    finally:
        sys.argv, spegla.ROT = gammal_argv, gammal_rot
        if gammal_nyckel is None:
            os.environ.pop("SUPABASE_SECRET_KEY", None)
        else:
            os.environ["SUPABASE_SECRET_KEY"] = gammal_nyckel
    return kod, ut.getvalue()


print("\n── Omfattningen: bilder räknas också i references/video ──")


def _t0(filer, rot):
    vagar = {f["lagringsvag"] for f in filer}
    check("nyckelrutan under video/ kom med",
          "video/nyckelrutor/d.jpg" in vagar, str(sorted(vagar)))
    check("och fick asset_type video",
          next(f["asset_type"] for f in filer
               if f["lagringsvag"] == "video/nyckelrutor/d.jpg") == "video")
    check("alla fyra filerna samlades", len(filer) == 4, str(len(filer)))


med_filer(_t0)


print("\n── Uppladdningen skriver manifestet, inte bara en utskrift ──")


def _t1(filer, rot):
    fejk = FejkadSupabase(manifest=manifest_for(filer))
    kod, ut = kor(["--ladda-upp"], fejk, rot)
    check("main returnerar 0 när allt speglades", kod == 0, f"kod={kod}")
    check("utskriften räknar skrivna rader, inte bara verifierade",
          "4 manifestrader skrivna" in ut, ut.strip().splitlines()[-1] if ut else "")
    check("PATCH nådde databasen", len(fejk.patchar) == 4, f"{len(fejk.patchar)} patchar")

    a = next(r for r in fejk.manifest if r["id"].endswith("-a"))
    check("sökvägen är hinken plus nyckeln",
          a["supabase_storage_path"] == "reference-assets/buildings/stall/a.jpg",
          str(a.get("supabase_storage_path")))
    check("sha256 kommer ur det som lästes tillbaka",
          a["sha256"] == hashlib.sha256(b"aaaa").hexdigest())
    check("bytes stämmer", a["bytes"] == 4, str(a.get("bytes")))
    check("storage_verified_at är satt", bool(a.get("storage_verified_at")),
          str(a.get("storage_verified_at")))


med_filer(_t1)


print("\n── En misslyckad återläsning får INTE skriva manifestet ──")


def _t2(filer, rot):
    #[[ Objektet finns men gar inte att lasa tillbaka. Da vet vi ingenting om
    #   vad som ligger dar, och raden ska forbli tom. ]]
    fejk = FejkadSupabase(manifest=manifest_for(filer),
                          trasig_aterlasning={"buildings/stall/a.jpg": None})
    kod, ut = kor(["--ladda-upp"], fejk, rot)
    check("main returnerar 1", kod == 1, f"kod={kod}")
    check("bara de två läsbara skrevs", "3 manifestrader skrivna" in ut)
    a = next(r for r in fejk.manifest if r["id"].endswith("-a"))
    check("den olästa raden har ingen sökväg",
          a.get("supabase_storage_path") is None, str(a.get("supabase_storage_path")))


med_filer(_t2)


print("\n── En ändrad återläsning får INTE skriva manifestet ──")


def _t3(filer, rot):
    #[[ Tjansten svarar 200 men med annat innehall -- en trunkerad uppladdning
    #   eller en omkodning ser exakt sa ut. Att hasha den LOKALA filen hade
    #   sluppit igenom det har. ]]
    fejk = FejkadSupabase(manifest=manifest_for(filer),
                          trasig_aterlasning={"buildings/ridhus/b.jpg": b"XXX"})
    kod, ut = kor(["--ladda-upp"], fejk, rot)
    check("main returnerar 1", kod == 1, f"kod={kod}")
    check("den ändrade filen skrevs inte", "3 manifestrader skrivna" in ut)
    b = next(r for r in fejk.manifest if r["id"].endswith("-b"))
    check("raden är orörd", b.get("sha256") is None)


med_filer(_t3)


print("\n── En PATCH som inte matchar någon rad är ett fel, inte en succé ──")


def _t4(filer, rot):
    #[[ PostgREST svarar 200 med TOM lista nar inget id matchar. Utan att
    #   rakna raderna hade ett id som inte finns i manifestet sett ut som en
    #   lyckad skrivning, och spegeln hade rapporterats klar. ]]
    fejk = FejkadSupabase(manifest=[])  # inga rader alls
    kod, ut = kor(["--ladda-upp"], fejk, rot)
    check("main returnerar 1", kod == 1, f"kod={kod}")
    check("noll rader skrivna när manifestet saknar id:na",
          "0 manifestrader skrivna" in ut)
    check("och skälet står i utskriften",
          "matchade 0 rader" in ut, ut.strip().splitlines()[0] if ut else "")


med_filer(_t4)


print("\n── Listningen går hela vägen ner ──")


def _t5(filer, rot):
    fejk = FejkadSupabase(objekt={f["lagringsvag"]: b"x" for f in filer})
    spegla.TRANSPORT = fejk
    hittade, fel = spegla.lista_rekursivt("n")
    check("inget fel vid listning", fel is None, str(fel))
    check("alla nästlade objekt hittades",
          hittade == {f["lagringsvag"] for f in filer}, str(sorted(hittade)))
    check("den steg ner i undermappar, inte bara toppnivån",
          "buildings/stall" in fejk.listanrop, str(fejk.listanrop))

    #[[ REGRESSIONSVAKT. Sa har gjorde den gamla koden: EN listning med
    #   prefix "" och namnen rakt av. Provet visar vad den faktiskt sag, sa
    #   att ingen aterinfor det i tron att det ar samma sak. ]]
    #[[ Provet holl forst pa den exakta uppsattningen {buildings, plans} och
    #   foll sa fort en video-katalog tillkom. Det matte ett tillfalligt varde
    #   i stallet for egenskapen. Egenskapen ar: en enda listning ger BARA
    #   toppnivanamn, aldrig en nastlad nyckel. ]]
    gammalt_satt = {o["name"] for o in fejk._lista("")}
    check("en enda listning med prefix \"\" ger bara toppnivånamn",
          gammalt_satt and all("/" not in namn for namn in gammalt_satt),
          str(sorted(gammalt_satt)))
    check("och delar inga sökvägar med de nästlade nycklarna",
          not (gammalt_satt & {f["lagringsvag"] for f in filer}))
    check("den rekursiva listningen hittar det den gamla missade",
          hittade - gammalt_satt == hittade, f"{len(hittade)} mot {len(gammalt_satt)}")


med_filer(_t5)


print("\n── Kontrollen fäller saknat, föräldralöst och lögnaktigt manifest ──")


def _t6(filer, rot):
    alla = {f["lagringsvag"]: b"x" for f in filer}

    kod, ut = kor(["--kontrollera"], FejkadSupabase(objekt=alla), rot)
    check("en komplett spegel går igenom", kod == 0, ut.strip().splitlines()[-1])

    utan_en = dict(alla)
    utan_en.pop("plans/c.png")
    kod, ut = kor(["--kontrollera"], FejkadSupabase(objekt=utan_en), rot)
    check("ett saknat objekt fälls", kod == 1 and "plans/c.png finns i repot" in ut)

    extra = dict(alla)
    extra["buildings/stall/smygare.jpg"] = b"x"
    kod, ut = kor(["--kontrollera"], FejkadSupabase(objekt=extra), rot)
    check("ett föräldralöst objekt fälls",
          kod == 1 and "smygare.jpg ligger i hinken" in ut)

    #[[ Hinken och repot stammer, men en manifestrad pekar pa nagot som inte
    #   finns. Schemats check-villkor ser bara att bada falten ar satta,
    #   aldrig om sokvagen leder nagonstans. ]]
    kod, ut = kor(["--kontrollera"], FejkadSupabase(
        objekt=alla,
        manifest=[{"id": "spoke", "supabase_storage_path":
                   "reference-assets/buildings/stall/finns-inte.jpg"}]), rot)
    check("en manifestrad som pekar i tomma luften fälls",
          kod == 1 and "spoke" in ut and "finns inte i hinken" in ut)


med_filer(_t6)

print("")
if fails:
    print(f"{fails} mätning(ar) föll.")
    sys.exit(1)
print("Alla mätningar gick igenom.")
