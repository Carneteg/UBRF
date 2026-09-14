#!/usr/bin/env python3
"""SERVERAR ROJO DET SOM LIGGER PA DISK? (#188)

Preflight punkt 9 jamfor `ReplicatedStorage.UBRFBuild.kallhash` mot repots
mappade kallor. Nar den raden blir rod finns det TRE oberoende stallen
sanningen kan ha fastnat pa, och de ser LIKADANA UT inifran Studio:

  1. REPOT ar inaktuellt      — `bygg-identitet.py --kontrollera` ar rod.
  2. ROJOS VFS ar inaktuell   — `rojo serve` serverar nagot annat an
                                disken. Studio far da troget fel innehall
                                utan att nagot ser trasigt ut. VARFOR
                                servern hamnat dar sager matningen inte:
                                det kan vara en tappad
                                filbevakningshandelse, men ocksa helt
                                vanlig synklatens eller annat lokalt
                                servertillstand. Skillnaden avgors av om
                                avvikelsen BESTAR.
  3. STUDIOS require-CACHE    — `require()` i en langlivad edit-VM ger ett
                                tredje, annu aldre varde medan `.Source` ar
                                ratt.

Fall 3 tog jag fel pa tva ganger (#173, #175) genom att lasa `require()` i
stallet for `.Source`. I #188 sag det ut som fall 3 igen — men det VAR
fall 2: servern serverade `45c0effe…` fran 10:41 medan disken hade
`4437b24e…`, och den reagerade inte heller pa en ny skrivning till filen.
Just DEN incidenten klassificerades darfor som en tappad
filbevakningshandelse for en sokvag: avvikelsen bestod over en riktig
bytediff, medan 67 andra mappade filer fortsatte synka. Den slutsatsen
horde till incidenten — verktyget drar den inte generellt.

Skillnaden gar inte att gissa, och den gar inte att se inifran Studio: dar
ar fall 2 och 3 omojliga att skilja at, eftersom Studio omojligt kan veta
mer an den blivit skickad. Den maste matas pa ROJOS EGEN API.

Vad skriptet gor:

  - fragar den korande servern vad den serverar for VARJE mappad
    scriptinstans — inte bara UBRFBuild, for samma sorts avvikelse kan
    traffa vilken fil som helst, och da ar det nasta grind som ljuger,
  - parar ihop instans och fil genom PROJEKTTRADET, inte genom filnamn,
  - jamfor LF-normaliserat innehall, byte for byte,
  - skriver ut exakt vad du kor i Studio for att skilja fall 3 fran fall 2.

Kor:   python3 tools/rojo-sanning.py [--port 34872] [--tyst]
Exit:  0 nar allt Rojo serverar ar identiskt med disken, annars 1.

Atgard vid fall 2: kor om efter nagra sekunder. BESTAR avvikelsen ar
servertillstandet inaktuellt — starta da om ratt `rojo serve`. Aldrig en
kodandring: att generera om en fil for att "fa den att synka" doljer bara
att servern inte levererar, och nasta gang ar det en fil ingen
kontrollerar.
"""
import argparse
import hashlib
import http.client
import json
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
ROBLOX = ROT / "roblox"


# ── En minimal msgpack-lasare ────────────────────────────────────────
#
# Rojo 7.7 svarar `application/msgpack` och forhandlar inte om JSON.
# `msgpack`-paketet ar ingen beroende i det har repot och ska inte bli en:
# grinden ska kunna koras pa en ren maskin utan pip. Formatet ar litet och
# vi behover bara de typer Rojos svar faktiskt anvander.
def avkoda(b: bytes, i: int = 0):
    """Returnerar (varde, nasta_index)."""
    c = b[i]
    i += 1
    if c <= 0x7F:
        return c, i
    if c >= 0xE0:
        return c - 0x100, i
    if 0x80 <= c <= 0x8F:
        return _karta(b, i, c & 0x0F)
    if 0x90 <= c <= 0x9F:
        return _lista(b, i, c & 0x0F)
    if 0xA0 <= c <= 0xBF:
        n = c & 0x1F
        return b[i:i + n].decode("utf-8", "replace"), i + n
    if c == 0xC0:
        return None, i
    if c == 0xC2:
        return False, i
    if c == 0xC3:
        return True, i
    if c in (0xC4, 0xC5, 0xC6):          # bin 8/16/32
        w = {0xC4: 1, 0xC5: 2, 0xC6: 4}[c]
        n = int.from_bytes(b[i:i + w], "big")
        i += w
        return b[i:i + n], i + n
    if c in (0xCA, 0xCB):                # float 32/64
        import struct
        w = 4 if c == 0xCA else 8
        return struct.unpack(">f" if c == 0xCA else ">d", b[i:i + w])[0], i + w
    if c in (0xCC, 0xCD, 0xCE, 0xCF):    # uint 8/16/32/64
        w = {0xCC: 1, 0xCD: 2, 0xCE: 4, 0xCF: 8}[c]
        return int.from_bytes(b[i:i + w], "big"), i + w
    if c in (0xD0, 0xD1, 0xD2, 0xD3):    # int 8/16/32/64
        w = {0xD0: 1, 0xD1: 2, 0xD2: 4, 0xD3: 8}[c]
        return int.from_bytes(b[i:i + w], "big", signed=True), i + w
    if c in (0xD9, 0xDA, 0xDB):          # str 8/16/32
        w = {0xD9: 1, 0xDA: 2, 0xDB: 4}[c]
        n = int.from_bytes(b[i:i + w], "big")
        i += w
        return b[i:i + n].decode("utf-8", "replace"), i + n
    if c in (0xDC, 0xDD):                # array 16/32
        w = 2 if c == 0xDC else 4
        n = int.from_bytes(b[i:i + w], "big")
        return _lista(b, i + w, n)
    if c in (0xDE, 0xDF):                # map 16/32
        w = 2 if c == 0xDE else 4
        n = int.from_bytes(b[i:i + w], "big")
        return _karta(b, i + w, n)
    raise ValueError("okand msgpack-typ 0x%02x vid %d" % (c, i - 1))


def _lista(b, i, n):
    ut = []
    for _ in range(n):
        v, i = avkoda(b, i)
        ut.append(v)
    return ut, i


def _karta(b, i, n):
    ut = {}
    for _ in range(n):
        k, i = avkoda(b, i)
        v, i = avkoda(b, i)
        ut[k] = v
    return ut, i


def hamta(port: int, sokvag: str):
    k = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
    k.request("GET", sokvag)
    r = k.getresponse()
    kropp = r.read()
    k.close()
    if r.status != 200:
        raise RuntimeError("%s gav HTTP %d" % (sokvag, r.status))
    return avkoda(kropp)[0]


# ── Disken ───────────────────────────────────────────────────────────
def diskkarta(projektnamn: str):
    """Varje mappad .luau-fil, som {full Rojo-vag: Path}.

    Parningen gar genom PROJEKTTRADET, inte genom filnamn. Filnamn racker
    inte: `src/server/init.server.luau` och `src/client/init.client.luau`
    blir bada en instans som heter `Horse`, sa en namnmatchning hade
    antingen hoppat over dem eller parat fel fil med fel instans. Falskt
    gront ar varre an ingen matchning alls.

    Projektnamnet kommer fran SERVERN, inte fran filen: det ar servern som
    bestammer vad roten heter i de vagar vi jamfor mot."""
    projekt = json.loads((ROBLOX / "default.project.json").read_text("utf-8"))
    ut = {}

    def fil_till_vag(vag, f, rot_katalog):
        """En fil under en mappad KATALOG far sin vag ur katalogstrukturen.
        `init*` ar inget eget barn — den ar mappens egen instans, och
        `.server`/`.client` ar en klassmarkor, inte en del av namnet."""
        delar = list(f.relative_to(rot_katalog).parts)
        sista = delar.pop()
        stam = sista[:-len(".luau")]
        if not stam.startswith("init"):
            for markor in (".server", ".client"):
                if stam.endswith(markor):
                    stam = stam[:-len(markor)]
                    break
            delar.append(stam)
        return ".".join([vag] + delar)

    def ga(nod, vag):
        if not isinstance(nod, dict):
            return
        sokvag = nod.get("$path")
        if isinstance(sokvag, str):
            p = ROBLOX / sokvag
            if p.is_file():
                ut[vag] = p
            elif p.is_dir():
                for f in sorted(p.rglob("*")):
                    if f.is_file() and f.suffix == ".luau":
                        ut[fil_till_vag(vag, f, p)] = f
            else:
                #[[ Samma regel som `bygg-identitet.py`: en mappad vag som
                #   inte finns ar ett riktigt fel, inte nagot att hoppa
                #   over tyst. ]]
                raise SystemExit(
                    "FEL: default.project.json mappar %r som inte finns" % sokvag)
        for nyckel, varde in nod.items():
            if not nyckel.startswith("$"):
                ga(varde, vag + "." + nyckel)

    for tjanst, nod in projekt["tree"].items():
        if tjanst.startswith("$"):
            continue
        ga(nod, projektnamn + "." + tjanst)
    return ut


def lf(text) -> str:
    if isinstance(text, bytes):
        text = text.decode("utf-8", "replace")
    return text.replace("\r\n", "\n")


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def falt(text: str, namn: str):
    m = re.search(r'%s\s*=\s*"([^"]+)"' % namn, text)
    return m.group(1) if m else None


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=34872,
                   help="porten `rojo serve` lyssnar pa (default 34872)")
    p.add_argument("--tyst", action="store_true",
                   help="skriv bara avvikelser och slutsatsen")
    arg = p.parse_args()

    print("== ROJO-SERVERN ==")
    try:
        info = hamta(arg.port, "/api/rojo")
    except Exception as e:                                  # noqa: BLE001
        print("   INGEN SERVER pa port %d (%s)" % (arg.port, e))
        print()
        print("   Utan en korande `rojo serve` gar fall 2 inte att mata, och")
        print("   da ar en rod punkt 9 INTE klassificerad. Starta servern och")
        print("   kor om. Rapportera aldrig 'det ar require-cache' utan den")
        print("   har matningen — det var precis felslutet i #188.")
        return 1
    print("   sessionId     %s" % info.get("sessionId"))
    print("   projectName   %s" % info.get("projectName"))
    print("   serverVersion %s" % info.get("serverVersion"))

    #[[ ETT anrop racker: `/api/read` pa roten ger hela subtradet platt. ]]
    inst = hamta(arg.port, "/api/read/%s" % info["rootInstanceId"])["instances"]

    def full_vag(nod):
        delar, n = [], nod
        while n is not None:
            delar.append(n["Name"])
            foralder = n.get("Parent")
            n = inst.get(foralder) if foralder else None
        return ".".join(reversed(delar))

    serverade = {}
    for nod in inst.values():
        kalla = (nod.get("Properties") or {}).get("Source")
        if kalla is None:
            continue
        if isinstance(kalla, dict):
            kalla = kalla.get("String", kalla.get("BinaryString", b""))
        serverade[full_vag(nod)] = lf(kalla)
    print("   scriptinstanser i tradet: %d" % len(serverade))

    print("\n== DISK MOT SERVER ==")
    lika, olika, oklara = 0, [], []
    for vag, f in sorted(diskkarta(info["projectName"]).items()):
        serverad = serverade.get(vag)
        if serverad is None:
            oklara.append((f, "ingen instans pa %s i Rojos trad" % vag))
            continue
        pa_disk = lf(f.read_bytes())
        if sha(serverad) == sha(pa_disk):
            lika += 1
            if not arg.tyst:
                print("   OK   %-44s %s" % (f.relative_to(ROT).as_posix(), vag))
        else:
            olika.append((f, vag, pa_disk, serverad))

    for f, vag, pa_disk, serverad in olika:
        print("   FEL  %-44s %s" % (f.relative_to(ROT).as_posix(), vag))
        print("        disk    %6d bytes  sha %s" % (
            len(pa_disk.encode("utf-8")), sha(pa_disk)[:16]))
        print("        server  %6d bytes  sha %s" % (
            len(serverad.encode("utf-8")), sha(serverad)[:16]))
        for namn in ("kallhash", "genererad"):
            d, s = falt(pa_disk, namn), falt(serverad, namn)
            if d or s:
                print("        %-9s disk %s" % (namn, d))
                print("        %-9s server %s" % ("", s))

    for f, skal in oklara:
        print("   ?    %-44s %s" % (f.relative_to(ROT).as_posix(), skal))

    print("\n== STUDIO — kor detta sjalv i edit-kontexten ==")
    print("""   local m = game:GetService("ReplicatedStorage").UBRFBuild
   print("Source ", string.match(m.Source, 'kallhash%s*=%s*"([0-9a-f]+)"'))
   print("require", require(m).kallhash)""")
    print("   `Source` ska matcha SERVERN ovan, inte disken — Studio kan")
    print("   omojligt veta mer an den blivit skickad. Skiljer sig")
    print("   `require` fran `Source` ar det fall 3, require-cache i den")
    print("   langlivade VM:en: mat om i en FARSK play-VM. Se #173/#175.")

    print("\n== SLUTSATS ==")
    print("   %d fil(er) lika · %d olika · %d oparade"
          % (lika, len(olika), len(oklara)))
    if olika:
        print("   FALL 2: `rojo serve` serverar annat an disken.")
        print("   Det ar varken ett repo-fel eller en produktbugg.")
        print("   Matningen sager INTE varfor servern ligger efter. Kor om")
        print("   efter nagra sekunder: forsvinner avvikelsen var det bara")
        print("   synklatens. BESTAR den ar servertillstandet inaktuellt —")
        print("   starta da om ratt `rojo serve`. Ingen kodandring.")
        return 1
    if oklara:
        print("   Inga avvikelser, men %d fil(er) gick inte att para." % len(oklara))
        print("   Los dem innan du kallar punkt 9 klassificerad — en oparad")
        print("   fil ar en fil ingen matning tacker.")
        return 1
    print("   Disk och Rojo ar overens. En rod punkt 9 beror da pa")
    print("   Studio-sidan — fall 3 ovan, eller en instans som inte langre")
    print("   tar emot patchar. Ga vidare med Studio-raderna.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
