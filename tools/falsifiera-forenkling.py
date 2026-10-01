#!/usr/bin/env python3
"""FALSIFIERING AV #273 SIMPLIFY — kan proven bli roda?

Tre prov vaktar forenklingen:

  webb     tools/simplifytest.mjs                       (S1, S2, S3)
  server   roblox/tests/integration-forenkling.spec     (S2, S3)
  klient   roblox/tests/klient-forenkling.spec          (S1, S2, S3)

Varje mutation river EN sak i produktionskoden och kor det prov som ska
fanga den. En mutation som lamnar provet GRONT ar ett fynd: da vaktar
provet inte det den sager sig vakta.

  W1  S i sadeln skriver skankeln igen i stallet for att bromsa
  W2  kontrollistan oppnas av sig sjalv vid uppsittningen
  W3  TYGEL-knappen tillbaka i pekytans ridsats
  W4  spakens hojdled skriver skankeln igen
  W5  de avancerade hjalperna kravs igen (HJALP_KRAV = 1)
  W6  «Samma hast igen» oppnar den gamla skotseln
  W7  stallets eftervard ger ocksa bonusen
  W8  kollen stannar inte vid ett fynd
  W9  kortet visar momentets detaljmening i stallet for den korta raden
  W10 eftervardens ordningsregel borta (transet fore sadeln gar igenom)
  W11 rakriktningen laser yttertygelstodet oavsett kravet (granskning R1)
  W12 passet raknas vid avsittningen, fore eftervardens val (granskning R1)
  W13 clear round-raden raknar upp momenten igen (webb)
  R10 clear round-raden raknar upp momenten igen (Roblox)
  R1  serverns «Kolla» stannar inte vid fyndet
  R2  stallets eftervard bokfors som spelarens egen
  R3  den egna eftervardens bonus ar noll
  R4  handlingarnas turordning provas inte
  R5  kontrollistan tands vid uppsittningen (init.client)
  R6  tygeln ar inte langre markt som avancerad
  R7  eftervarden visar aldrig valet (alltid «sjalv»)
  R8  ett fynd kvitteras som «Allt ser bra ut»
  R9  en upprepad eftervardshandling kvitteras som gjord

KOR DEN INTE MED OCOMMITTAT ARBETE. Originalen halls i minnet och skrivs
tillbaka i `finally`; skriptet slutar med att kontrollera att arbetstradet
ar orort.

Kor: python tools/falsifiera-forenkling.py [W|R|namn ...]   (exit 1 vid fynd)
"""
import io
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

# Windows-konsolen ar cp1252 och kan inte skriva «✓». Utskriften far aldrig
# falla en korning — da blir mutationen kvar tills `finally` hunnit stada.
for _strom in (sys.stdout, sys.stderr):
    try:
        _strom.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

FILER = {
    "game": "src/game.js",
    "tavling": "src/tavling.js",
    "mobil": "src/mobil.js",
    "svar": "src/riding/svar.js",
    "scenes": "src/scenes.js",
    "forb": "src/forberedelse.js",
    "stegkort": "src/stegkort.js",
    "model": "src/model.js",
    "webbak": "src/lektioner/aterkoppling.js",
    "rbxak": "roblox/src/client/LektionsAterkoppling.luau",
    "gs": "roblox/src/server/GameplayService.luau",
    "prep": "roblox/src/shared/HorseCore/Preparation.luau",
    "init": "roblox/src/client/init.client.luau",
    "kh": "roblox/src/client/KontrollHjalp.luau",
    "pc": "roblox/src/client/PreparationController.luau",
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


def kor_webb():
    b = subprocess.run([sys.executable, "tools/build.py"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if b.returncode != 0:
        return "BYGGFEL", [(b.stdout + b.stderr).strip()[-200:]]
    r = subprocess.run(["node", "tools/simplifytest.mjs"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL") or "PAGEERROR" in l]
    if r.returncode == 0 and not fel:
        return "GRONT", []
    return ("ROTT" if fel else "KRASCH"), fel[:4] or [ut.strip()[-200:]]


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


def kor_ridtest():
    b = subprocess.run([sys.executable, "tools/build.py"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if b.returncode != 0:
        return "BYGGFEL", [(b.stdout + b.stderr).strip()[-200:]]
    r = subprocess.run(["node", "tools/ridtest.mjs"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL")]
    if r.returncode == 0 and not fel:
        return "GRONT", []
    return ("ROTT" if fel else "KRASCH"), fel[:4] or [ut.strip()[-200:]]


SERVER = kor_luau("integration-forenkling")
KLIENT = kor_luau("klient-forenkling")
CLEARROUND = kor_luau("clearround-eftervard")

# (namn, fil, gammalt, nytt, korning, beskrivning)
MUTATIONER = [
    ("W1", "game",
     'case"KeyS":if(iSadeln())ridBroms();else RIDIN.skankel=-1;RIDIN.pek=false;break;',
     'case"KeyS":RIDIN.skankel=-1;RIDIN.pek=false;break;',
     kor_webb, "S i sadeln skriver skankeln i stallet for att bromsa"),
    ("W2", "tavling",
     "  startaLektion();\n}\n\n/* ── Sekretariatet",
     "  if(typeof visaKontrollHjalp===\"function\")visaKontrollHjalp();\n  startaLektion();\n}\n\n/* ── Sekretariatet",
     kor_webb, "kontrollistan oppnas av sig sjalv vid uppsittningen"),
    ("W3", "mobil",
     '      <button class="pekKnapp stor" data-rid="broms" data-etikett="touch.broms" id="pekBroms">BROMS</button>',
     '      <button class="pekKnapp stor" data-hall="Space" data-etikett="touch.webb.tygel">TYGEL</button>\n'
     '      <button class="pekKnapp stor" data-rid="broms" data-etikett="touch.broms" id="pekBroms">BROMS</button>',
     kor_webb, "TYGEL-knappen tillbaka i ridsatsen"),
    ("W4", "mobil",
     "      if(typeof G!==\"undefined\"&&!G.p3)RIDIN.skankel=kurva(dodzon(-dy*k,0.12));",
     "      RIDIN.skankel=kurva(dodzon(-dy*k,0.12));",
     kor_webb, "spakens hojdled skriver skankeln igen"),
    ("W5", "svar", "  HJALP_KRAV: 0,", "  HJALP_KRAV: 1,",
     kor_webb, "de avancerade hjalperna kravs igen"),
    ("W6", "scenes",
     "    ridIgenMed(samma);};",
     "    ridIgenMed(samma);visaSkotsel();};",
     kor_webb, "«Samma hast igen» oppnar den gamla skotseln"),
    ("W7", "scenes",
     "  if(andel>0&&typeof SPAR!==\"undefined\"",
     "  if(typeof SPAR!==\"undefined\"",
     kor_webb, None),   # ersatts nedan: bonusen maste ocksa bli nollskild
    ("W8", "forb",
     '      if (r[2] === "fynd") return [true, null, "fynd"];\n',
     "",
     kor_webb, "kollen stannar inte vid ett fynd"),
    ("W9", "stegkort",
     "  const hText = () => SK_HANDLING[hd.id].text();",
     '  const hText = () => skKanon(Forb.nastaMoment(s, fas.id), "text");',
     kor_webb, "kortet visar momentets detaljmening"),
    ("W10", "forb",
     '      return [false, "pass.fel_tur", paTur.moment[0]];\n    }\n',
     "    }\n",
     kor_webb, "eftervardens ordningsregel borta"),
    ("W11", "model",
     "   const stod=1-stodKrav*(1-(HS?HS.ytterstod:1));",
     "   const stod=HS?HS.ytterstod:1;",
     kor_ridtest, "rakriktningen laser yttertygelstodet oavsett kravet"),
    ("W12", "game",
     "    G.passRes=null;\n    visaEftervard(dom);",
     "    raknaPass(dom);\n    visaEftervard(dom);",
     kor_webb, "passet raknas vid avsittningen, fore valet"),
    ("W13", "webbak",
     '        s += " " + t("aterkoppling.clearround.eftervard");',
     '        s += " " + t("aterkoppling.clearround.eftervard") + " " + b.eftervard.map(m => m.namn).join(" · ");',
     kor_webb, "clear round-raden raknar upp momenten igen (webb)"),
    ("R10", "rbxak",
     '			s ..= " " .. Sprak.t("aterkoppling.clearround.eftervard")',
     '			s ..= " " .. Sprak.t("aterkoppling.clearround.eftervard") .. " " .. tostring(b.eftervard[1].namn)',
     CLEARROUND, "clear round-raden raknar upp momenten igen (Roblox)"),
    ("R1", "gs",
     '			if s.fyndSett and not s.fyndRapporterat then\n				return true, "forb.oppet_fynd", nil\n			end\n',
     "",
     SERVER, "serverns «Kolla» stannar inte vid fyndet"),
    ("R2", "gs",
     '		Pass.utfor(p, m.id, "auto")',
     "		Pass.utfor(p, m.id)",
     SERVER, "stallets eftervard bokfors som spelarens egen"),
    ("R3", "gs", "local EGEN_EFTERVARD_BONUS = 0.02", "local EGEN_EFTERVARD_BONUS = 0",
     SERVER, "den egna eftervardens bonus ar noll"),
    ("R4", "prep",
     "	if not paTur or paTur.id ~= h.id then\n		local gjort = state.gjorda[h.fas] or {}",
     "	if false then\n		local gjort = state.gjorda[h.fas] or {}",
     SERVER, "handlingarnas turordning provas inte"),
    ("R5", "init",
     "	--[[ #273 S1: kontrollistan öppnas inte av sig själv vid uppsittningen.",
     "	KontrollHjalp.visa()\n	--[[ #273 S1: kontrollistan öppnas inte av sig själv vid uppsittningen.",
     KLIENT, "kontrollistan tands vid uppsittningen"),
    ("R6", "kh",
     '	{ nyckel = "hjalp.tygel",        tgb = "Q",      pad = "R2", avancerat = true },',
     '	{ nyckel = "hjalp.tygel",        tgb = "Q",      pad = "R2" },',
     KLIENT, "tygeln ar inte langre markt som avancerad"),
    ("R7", "pc",
     "		local sjalv = senastePass.borjad == true or egenEftervard == senastePass.hastId",
     "		local sjalv = true",
     KLIENT, "eftervarden visar aldrig valet"),
    ("R8", "pc",
     '			if skal ~= "forb.oppet_fynd" then',
     "			if true then",
     KLIENT, "ett fynd kvitteras som «Allt ser bra ut»"),
    ("R9", "gs",
     "	if kvar == 0 then\n		skickaPass(player)\n		return false, \"pass.redan_gjort\"\n	end\n",
     "",
     SERVER, "en upprepad eftervardshandling kvitteras som gjord"),
]

# W7 i tva led: villkoret bort racker inte (andelen ar 0 och ger 0). Bonusen
# ska laggas pa aven for stallet.
_W7 = ("W7", "scenes",
       "    m.rang=clamp(fore+Efter.BONUS*andel,0,1);",
       "    m.rang=clamp(fore+Efter.BONUS,0,1);",
       kor_webb, "stallets eftervard ger ocksa bonusen")


def mutera(namn, gammalt, nytt):
    text = _ORIG[namn]
    if text.count(gammalt) != 1:
        return None
    return text.replace(gammalt, nytt)


def main(argv):
    valda = [a for a in argv[1:]]
    resultat = []
    try:
        for m in MUTATIONER:
            mid, fil, gammalt, nytt, korning, besk = m
            if valda and not any(mid == v or mid.startswith(v) and len(v) == 1 for v in valda):
                continue
            if mid == "W7":
                # villkoret OCH andelen: stallet far bonusen
                t = mutera(fil, gammalt, nytt)
                t2 = None
                if t is not None and t.count(_W7[2]) == 1:
                    t2 = t.replace(_W7[2], _W7[3])
                besk = _W7[5]
                text = t2
            else:
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

    # Aterstallningen provas: arbetstradet ska vara orort.
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
