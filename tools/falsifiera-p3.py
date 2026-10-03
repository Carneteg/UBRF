#!/usr/bin/env python3
"""FALSIFIERING AV P3-BASEN — kan P3:s grindar bli roda?

Granskning #273 5928307604, blockerare 3: P3 saknade en reproducerbar
falsifiering. Varje mutation river EN sak i produktionskoden och kor de
grindar som sager sig vakta den. En mutation som lamnar en namngiven grind
GRON ar ett fynd: da vaktar grinden inte det den sager sig vakta.

  lektionsparitet (konstant / identitet mot Roblox-kallan)
    P1  haltlektionens ring ar 1,6 m i stallet for Roblox 1,5
    P2  haltlektionens VERSION skiljer sig fran serverns

  ridpanelen (hierarki / reglage)
    P3  ridpanelens karna har tre rader i stallet for fyra
    P4  E i sadeln sitter inte langre av

  lektionens livscykel och slutvillkor
    P5  ett halt UTANFOR ringen raknas (syntetiskt prov OCH webblasarritten)
    P6  ryttarens hjalp nar aldrig lektionen (bara webblasarritten kan se det)
    P7  en klarad lektion sparas inte i lektionsminnet (webblasarritten)

  sprak
    P8  ridpanelens titel ar en svensk literal i stallet for katalognyckeln
    P9  en ridtext saknar engelska i katalogen

KOR DEN INTE MED OCOMMITTAT ARBETE. Originalen halls i minnet och skrivs
tillbaka i `finally`; skriptet slutar med att kontrollera att arbetstradet
ar orort.

Kor: python tools/falsifiera-p3.py [P1 P5 ...]   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

# Windows-konsolen ar cp1252. Utskriften far aldrig falla en korning — da
# blir mutationen kvar tills `finally` hunnit stada.
for _strom in (sys.stdout, sys.stderr):
    try:
        _strom.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

FILER = {
    "halt": "src/lektioner/halt.js",
    "koppling": "src/lektioner/koppling.js",
    "meny": "src/lektionsmeny.js",
    "kh": "src/kontrollhjalp.js",
    "game": "src/game.js",
    "ridpanel": "src/ridpanel.js",
    "sprak": "src/spel/sprak.js",
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


def _kor(kommando):
    r = subprocess.run(kommando, cwd=str(ROT), capture_output=True, text=True,
                       encoding="utf-8", errors="replace", timeout=900)
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL") or "PAGEERROR" in l]
    if r.returncode == 0 and not fel:
        return "GRONT", []
    return ("ROTT" if fel else "KRASCH"), fel[:3] or [ut.strip()[-200:]]


def bygg():
    b = subprocess.run([sys.executable, "tools/build.py"], cwd=str(ROT),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    return b.returncode == 0, (b.stdout + b.stderr).strip()[-200:]


def grind(skript, behover_bygge=True):
    def kor():
        if behover_bygge:
            ok, svans = bygg()
            if not ok:
                return "BYGGFEL", [svans]
        return _kor(["node", "tools/%s.mjs" % skript])
    kor.namn = skript
    return kor


PARITET = grind("lektionsparitet", behover_bygge=False)
SYNTET = grind("lektionstest", behover_bygge=False)
PANEL = grind("ridpaneltest")
E2E = grind("lektion-e2e-test")
BLANDNING = grind("sprakblandningtest")
SPRAKGRIND = grind("sprakgrind")

# (namn, fil, gammalt, nytt, [grindar som ALLA ska bli roda], beskrivning)
MUTATIONER = [
    ("P1", "halt", "  const ZON_R = 1.5;\n", "  const ZON_R = 1.6;\n",
     [PARITET], "haltlektionens ring ar 1,6 m i stallet for 1,5"),
    ("P2", "halt", 'OVNING: "starthalt", VERSION: "server-halt-1"', 'OVNING: "starthalt", VERSION: "server-halt-2"',
     [PARITET], "haltlektionens VERSION skiljer sig fran serverns"),
    ("P3", "kh",
     'const KONTROLL_KARNA = ["hjalp.webb.driv", "hjalp.webb.bromsa", "hjalp.styr", "hjalp.sitt_upp_av"];',
     'const KONTROLL_KARNA = ["hjalp.webb.driv", "hjalp.webb.bromsa", "hjalp.styr"];',
     [PANEL], "ridpanelens karna har tre rader i stallet for fyra"),
    ("P4", "game",
     'case"KeyE":if(iSadeln()&&!wasDown&&!overlayUppe()&&typeof ridAvsittning==="function")ridAvsittning();break;',
     'case"KeyE":break;',
     [PANEL], "E i sadeln sitter inte langre av"),
    ("P5", "halt", "else if (halt && s.haltHjalp && stilla && iZon) {", "else if (halt && s.haltHjalp && stilla) {",
     [SYNTET, E2E], "ett halt utanfor ringen raknas"),
    ("P6", "koppling",
     'LektionObs.handelse(R.O, { fran: R.bedd, till: bedd, orsak: "hjalp", handling: ride.cue || null });',
     'LektionObs.handelse(R.O, { fran: R.bedd, till: bedd, orsak: "annat", handling: ride.cue || null });',
     [E2E], "ryttarens hjalp nar aldrig lektionen"),
    ("P7", "meny", "    SPAR.lektionsminne[k] = true;\n", "    SPAR.lektionsminne[k] = false;\n",
     [E2E], "en klarad lektion sparas inte i lektionsminnet"),
    ("P8", "ridpanel", '<span class="skUt">${esc(rpT("ugneta.titel"))}</span>',
     '<span class="skUt">Ugneta · Ridinstruktör</span>',
     [BLANDNING], "ridpanelens titel ar en svensk literal"),
    ("P9", "sprak",
     '"aterkoppling.halt.kort": { sv: "Bra – halt vid X!", en: "Good – halt at X!" },',
     '"aterkoppling.halt.kort": { sv: "Bra – halt vid X!" },',
     [SPRAKGRIND], "en ridtext saknar engelska i katalogen"),
]


def mutera(namn, gammalt, nytt):
    text = _ORIG[namn]
    if text.count(gammalt) != 1:
        return None
    return text.replace(gammalt, nytt)


def main(argv):
    valda = argv[1:]
    resultat = []
    try:
        for mid, fil, gammalt, nytt, grindar, besk in MUTATIONER:
            if valda and mid not in valda:
                continue
            text = mutera(fil, gammalt, nytt)
            if text is None:
                resultat.append((mid, besk, "-", "EJ_MUTERAD"))
                print("%-3s EJ_MUTERAD  %s — grenen matchade inte exakt en gang" % (mid, besk), flush=True)
                continue
            skriv(fil, text)
            try:
                for g in grindar:
                    utfall, rader = g()
                    resultat.append((mid, besk, g.namn, utfall))
                    print("%-3s %-8s %-20s %s" % (mid, utfall, g.namn, besk), flush=True)
                    for r in rader[:2]:
                        print("       " + r[:230], flush=True)
            finally:
                skriv(fil, _ORIG[fil])
    finally:
        aterstall()
        # dist/ byggs om ur de aterstallda kallorna, sa att nasta prov inte
        # rakar kora en muterad sida.
        bygg()

    st = subprocess.run(["git", "status", "--porcelain", "--"] + list(FILER.values()),
                        cwd=str(ROT), capture_output=True, text=True)
    rent = st.stdout.strip() == ""
    fangade = [r for r in resultat if r[3] in ("ROTT", "KRASCH")]
    ofangade = [r for r in resultat if r[3] not in ("ROTT", "KRASCH")]
    print("")
    print("RESULTAT: %d av %d grindkorningar blev roda (%d ofangade)" % (len(fangade), len(resultat), len(ofangade)))
    for r in ofangade:
        print("  OFANGAD  %s  %s  %s  (%s)" % (r[0], r[2], r[1], r[3]))
    print("ARBETSTRADET: %s" % ("orort" if rent else "ANDRAT — " + st.stdout.strip()))
    return 0 if (not ofangade and rent) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
