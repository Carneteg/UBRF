#!/usr/bin/env python3
"""FALSIFIERING AV #274 — «RIDA NU» ÄR INGEN ÅTERVÄNDSGRÄND. Kan proven bli röda?

Tre prov vaktar fortsättningen efter välfärdsstoppet:

  webb     tools/valfardstest.mjs                        (hela kedjan + negativa fall)
  server   roblox/tests/ridefirst-fortsatt.spec          (tjänsten: stopp, ersättare, Rida nu)
  klient   roblox/tests/klient-fortsatt.spec             (stoppkortets knapp)

Varje mutation river EN sak i produktionskoden och kör det prov som ska
fånga den. En mutation som lämnar provet GRÖNT är ett fynd: då vaktar
provet inte det den säger sig vakta.

  Roblox server
  R1  ersättare erbjuds utan att hästen är stoppad
  R2  fortsättningen går att köra utan stopp
  R3  anropsplatsen tappar det uttryckliga undantaget (tilldela utan undanta)
  R4  förberedelsen byggs inte om för den nya hästen (bind borta)
  R5  frågan «finns en frisk häst?» före bytet borta (tilldelningen rivs)
  R6  vyn bär inget ersattare-fält
  R7  valet ignorerar undantaget (StallService.dagensFor)
  R8  valet ignorerar vilande hästar (StallService.dagensFor)
  Roblox klient
  C1  knappen hänger på räckvidden (död knapp utom räckhåll)
  C2  panelen göms utom räckhåll trots knappen
  C3  knapp ritas även när ingen ersättare finns
  C4  klienten skickar med en egen hästpekare
  Webb
  W1  «fortsätt» går att köra utan stopp (båda vakterna borta)
  W2  tilldelningen ignorerar undantaget
  W3  stoppkortet visar en knapp även utan frisk häst
  W4  fortsättningen räknar dagen en gång till
  W5  ersättaren väljs ur rotationen utan undantag och utan vilande

KÖR DEN INTE MED OCOMMITTAT ARBETE. Originalen hålls i minnet och skrivs
tillbaka i `finally`; skriptet slutar med att kontrollera att arbetsträdet
är orört.

Kör: python tools/falsifiera-fortsatt.py [R|C|W|namn ...]   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

# Windows-konsolen är cp1252 och kan inte skriva alla tecken. Utskriften får
# aldrig fälla en körning — då blir mutationen kvar tills `finally` hunnit städa.
for _strom in (sys.stdout, sys.stderr):
    try:
        _strom.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

FILER = {
    "gs": "roblox/src/server/GameplayService.luau",
    "ss": "roblox/src/server/StallService.luau",
    "pc": "roblox/src/client/PreparationController.luau",
    "stegkort": "src/stegkort.js",
    "uppdrag": "src/uppdrag.js",
}

_ORIG, _CRLF = {}, {}
for _namn, _rel in FILER.items():
    _raa = (ROT / _rel).read_bytes()
    _CRLF[_namn] = b"\r\n" in _raa
    _ORIG[_namn] = _raa.decode("utf-8").replace("\r\n", "\n")


def skriv(namn, text):
    data = text.replace("\n", "\r\n") if _CRLF[namn] else text
    (ROT / FILER[namn]).write_bytes(data.encode("utf-8"))


def aterstall():
    for namn in FILER:
        skriv(namn, _ORIG[namn])


def _tolka(r):
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL") or "PAGEERROR" in l]
    if r.returncode == 0 and not fel:
        return "GRONT", []
    return ("ROTT" if fel else "KRASCH"), fel[:4] or [ut.strip()[-200:]]


def kor_webb():
    b = subprocess.run([sys.executable, "tools/build.py"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if b.returncode != 0:
        return "BYGGFEL", [(b.stdout + b.stderr).strip()[-200:]]
    r = subprocess.run(["node", "tools/valfardstest.mjs"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace",
                       timeout=600)
    return _tolka(r)


def kor_luau(spec):
    def _kor():
        b = subprocess.run([sys.executable, "tests/build.py", "tests/%s.spec.luau" % spec],
                           cwd=str(ROT / "roblox"), capture_output=True, text=True,
                           encoding="utf-8", errors="replace")
        if b.returncode != 0:
            return "BYGGFEL", [(b.stdout + b.stderr).strip()[-200:]]
        r = subprocess.run(["luau", "tests/.build/%s.spec.luau" % spec], cwd=str(ROT / "roblox"),
                           capture_output=True, text=True, encoding="utf-8", errors="replace",
                           timeout=180)
        ut = r.stdout + r.stderr
        fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL")]
        if r.returncode == 0 and not fel and "alla gröna" in ut:
            return "GRONT", []
        return ("ROTT" if fel else "KRASCH"), fel[:4] or [ut.strip()[-200:]]
    return _kor


SERVER = kor_luau("ridefirst-fortsatt")
KLIENT = kor_luau("klient-fortsatt")

# (namn, fil, gammalt, nytt, korning, beskrivning)
MUTATIONER = [
    ("R1", "gs",
     "	local s = state[player]\n	if not s or not s.stoppad then return nil, nil end\n"
     "	local d = StallService.ersattare(player, s.hastId)",
     "	local s = state[player]\n	if not s then return nil, nil end\n"
     "	local d = StallService.ersattare(player, s.hastId)",
     SERVER, "ersattare erbjuds utan att hasten ar stoppad"),
    ("R2", "gs",
     "	local s = state[player]\n	if not s or not s.stoppad then\n"
     "		return false, \"forb.inget_stopp\"\n	end\n",
     "	local s = state[player]\n	if not s then\n"
     "		return false, \"forb.inget_stopp\"\n	end\n",
     SERVER, "fortsattningen gar att kora utan stopp"),
    ("R3", "gs",
     "	local dagens = StallService.tilldela(player, s.hastId)\n",
     "	local dagens = StallService.tilldela(player)\n",
     SERVER, "anropsplatsen tappar det uttryckliga undantaget"),
    ("R4", "gs",
     "	bunden[player] = nil\n	GameplayService.bind(player)\n	return true, nil, dagens.id",
     "	bunden[player] = nil\n	return true, nil, dagens.id",
     SERVER, "forberedelsen byggs inte om for den nya hasten"),
    ("R5", "gs",
     "	if not StallService.ersattare(player, s.hastId) then\n"
     "		return false, \"spel.ingen_frisk_hast\"\n	end\n	local dagens",
     "	local dagens",
     SERVER, "fragan «finns en frisk hast?» fore bytet borta"),
    ("R6", "gs",
     "	if ersNamn then v.ersattare = ersNamn end\n",
     "",
     SERVER, "vyn bar inget ersattare-falt"),
    ("R7", "ss",
     "	if undanta then vilande[undanta] = true end\n",
     "",
     SERVER, "valet ignorerar undantaget"),
    ("R8", "ss",
     "	local vilande = Stallet.vilandeHastar(StallService.hastminnen(player))\n	if undanta then",
     "	local vilande = {}\n	if undanta then",
     SERVER, "valet ignorerar vilande hastar"),
    ("C1", "pc",
     "	local utomRackhall = utomRackhall and m.id ~= FORTSATT_ID\n",
     "",
     KLIENT, "knappen hanger pa rackvidden"),
    ("C2", "pc",
     "	return antalVal > 0 and (not utomRackhall or rattelseAktiv or fortsattNu)",
     "	return antalVal > 0 and (not utomRackhall or rattelseAktiv)",
     KLIENT, "panelen goms utom rackhall trots knappen"),
    ("C3", "pc",
     '		if type(vy.ersattare) == "string" and vy.ersattare ~= "" then',
     "		if true then",
     KLIENT, "knapp ritas aven nar ingen ersattare finns"),
    ("C4", "pc",
     '	skicka(FORTSATT_ID, "FortsattHast", nil)',
     '	skicka(FORTSATT_ID, "FortsattHast", nil, "annan_hast")',
     KLIENT, "klienten skickar med en egen hastpekare"),
    ("W1", "stegkort",
     "  if (!s || !s.stoppad || typeof tilldelaDagensHast !== \"function\") return null;\n"
     "  return tilldelaDagensHast(s.hastId) || null;\n}\n"
     "function stegkortFortsatt() {\n  const s = G.forb;\n  if (!s || !s.stoppad) return false;\n",
     "  if (!s || typeof tilldelaDagensHast !== \"function\") return null;\n"
     "  return tilldelaDagensHast(s.hastId) || null;\n}\n"
     "function stegkortFortsatt() {\n  const s = G.forb;\n  if (!s) return false;\n",
     kor_webb, "fortsatt gar att kora utan stopp"),
    ("W2", "uppdrag",
     "  if(undanta)vilande[undanta]=true;\n",
     "",
     kor_webb, "tilldelningen ignorerar undantaget"),
    ("W3", "stegkort",
     "    if (ers)\n      return { id: \"stopp\"",
     "    if (true)\n      return { id: \"stopp\"",
     kor_webb, "stoppkortet visar en knapp aven utan frisk hast"),
    ("W4", "stegkort",
     "  if (!ny || ny === s.hastId || !sattAktivHast(ny)) return false;\n  skAterkoppla(\"\");",
     "  if (!ny || ny === s.hastId || !sattAktivHast(ny)) return false;\n  SPAR.pass++;\n  skAterkoppla(\"\");",
     kor_webb, "fortsattningen raknar dagen en gang till"),
    ("W5", "stegkort",
     "  return tilldelaDagensHast(s.hastId) || null;\n}\nfunction stegkortFortsatt",
     "  return tilldelaLedig(tilldelningsId(), {}, {}, null) || null;\n}\nfunction stegkortFortsatt",
     kor_webb, "ersattaren valjs utan undantag och utan vilande"),
]


def mutera(namn, gammalt, nytt):
    text = _ORIG[namn]
    if text.count(gammalt) != 1:
        return None
    return text.replace(gammalt, nytt)


def main(argv):
    valda = [a for a in argv[1:]]
    resultat = []
    try:
        for mid, fil, gammalt, nytt, korning, besk in MUTATIONER:
            if valda and not any(mid == v or (len(v) == 1 and mid.startswith(v)) for v in valda):
                continue
            text = mutera(fil, gammalt, nytt)
            if text is None:
                resultat.append((mid, besk, "EJ_MUTERAD", ["grenen matchade inte exakt en gang"]))
                print("%-4s EJ_MUTERAD  %s" % (mid, besk), flush=True)
                continue
            skriv(fil, text)
            try:
                utfall, rader = korning()
            finally:
                skriv(fil, _ORIG[fil])
            resultat.append((mid, besk, utfall, rader))
            print("%-4s %-8s %s" % (mid, utfall, besk), flush=True)
            for r in rader[:2]:
                print("       " + r[:230], flush=True)
    finally:
        aterstall()

    # Återställningen provas: arbetsträdet ska vara orört.
    st = subprocess.run(["git", "status", "--porcelain", "--"] + list(FILER.values()),
                        cwd=str(ROT), capture_output=True, text=True)
    rent = st.stdout.strip() == ""
    fangade = [r for r in resultat if r[2] in ("ROTT", "KRASCH")]
    ofangade = [r for r in resultat if r[2] not in ("ROTT", "KRASCH")]
    print("")
    print("RESULTAT: %d av %d mutationer fangades (%d ofangade)" % (len(fangade), len(resultat), len(ofangade)))
    for r in ofangade:
        print("  OFANGAD  %s  %s  (%s)" % (r[0], r[1], r[2]))
    print("ARBETSTRADET: %s" % ("orort" if rent else "ANDRAT — " + st.stdout.strip()))
    return 0 if (not ofangade and rent) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
