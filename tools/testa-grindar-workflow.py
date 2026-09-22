#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GRINDARNA SKA VARA FAIL CLOSED (#264 G8).

Varje kontroll i `grindar.yml` var forut inlindad i

    if [ -f tools/x.py ]; then python3 tools/x.py
    else echo "hoppar: ..."; fi

Att RADERA ett obligatoriskt skript fick alltsa steget att passera utan att
testa nagonting, och loggraden "hoppar" gick inte att skilja fran ett PASS
nar man laste efter ett rott kryss. Gron CI betydde "inget foll", inte "allt
kordes".

Det har provet vaktar rattelsen, och det gor det pa fyra satt:

  STRUKTUR   YAML:en lases med en riktig parser. Inget `if [ -f`, inget
             `hoppar`, inget `|| true` och ingen `continue-on-error` far
             finnas i jobben `grindar` eller `ridning`.
  INVENTARIE En fast lista over de obligatoriska anropen. Forsvinner ett
             steg, eller tappar det sina argument, faller provet. Listan ar
             kontraktet; den far bara andras med en motivering.
  BETEENDE   Run-blocken KORS. Inte en kopia av dem -- texten hamtas ur
             YAML:en och exekveras i en isolerad fixtur med skal-skal pa
             PATH. Ett prov som bara letar efter strangar bevisar att
             filen ser ratt ut, inte att den GOR ratt.
  MASKERING  I ett steg som forst bygger och sedan kor det byggda maste ett
             misslyckat bygge falla steget aven nar en GAMMAL genererad fil
             ligger kvar och skulle ha gett gron utmatning.

Fixturerna ar temporara kataloger. Provet ror aldrig arbetstradet, den
kanoniska playtest-filen eller historiska releaser.
"""
import io
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit("PyYAML kravs: pip install pyyaml")

ROT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YML = os.path.join(ROT, ".github", "workflows", "grindar.yml")
JOBB = ("grindar", "ridning")

#[[ KONTRAKTET. (jobb, obligatorisk sokvag, kommandoraderna i ordning).
#   Genererad ur filen nar grinden infordes, sedan fast. ]]
INVENTARIE = [
    ('grindar', 'tools/testa-grindar-workflow.py', ['python3 -m pip install --quiet pyyaml', 'python3 tools/testa-grindar-workflow.py --forhandskoll']),
    ('grindar', 'tools/kolla-material.py', ['python3 tools/kolla-material.py']),
    ('grindar', 'tools/bygg-identitet.py', ['python3 tools/bygg-identitet.py --kontrollera']),
    ('grindar', 'tools/exportera-spel.js', ['node tools/exportera-spel.js --kontrollera']),
    ('grindar', 'tools/exportera-ridkanon.mjs', ['node tools/exportera-ridkanon.mjs --kontrollera']),
    ('grindar', 'tools/exportera-geometri.js', ['node tools/exportera-geometri.js --kontrollera']),
    ('grindar', 'tools/kolla-dorrfarg.py', ['python3 tools/kolla-dorrfarg.py']),
    ('grindar', 'tools/kolla-forstadagen.py', ['python3 tools/kolla-forstadagen.py']),
    ('grindar', 'tools/kolla-rojo.py', ['python3 tools/kolla-rojo.py']),
    ('grindar', 'tools/kolla-nyckelbilder.py', ['python3 tools/kolla-nyckelbilder.py']),
    ('grindar', 'roblox/tests/kor.sh', ['bash roblox/tests/kor.sh']),
    ('grindar', 'tools/handighetsgrind.mjs', ['node tools/handighetsgrind.mjs']),
    ('grindar', 'tools/pre-tobias-grind.py', ['python3 tools/pre-tobias-grind.py']),
    ('grindar', 'references/CHECKSUMS.sha256', ['cd references && sha256sum -c --quiet CHECKSUMS.sha256']),
    ('grindar', 'tools/build.py', ['python3 tools/build.py']),
    ('grindar', 'tools/testa-hastkanon-save.mjs', ['node tools/testa-hastkanon-save.mjs']),
    ('grindar', 'tools/studio-paket.py', ['python3 tools/studio-paket.py']),
    ('grindar', 'tools/kolla-place.py', ['python3 tools/kolla-place.py']),
    ('grindar', 'tools/kolla-evidens-place.py', ['python3 tools/kolla-evidens-place.py']),
    ('grindar', 'roblox/tests/spelbarhet.spec.luau', ['python3 roblox/tests/build.py tests/spelbarhet.spec.luau', 'luau roblox/tests/.build/spelbarhet.spec.luau']),
    ('grindar', 'roblox/tests/integration.spec.luau', ['python3 roblox/tests/build.py tests/integration.spec.luau', 'luau roblox/tests/.build/integration.spec.luau']),
    ('grindar', 'roblox/tests/roster.spec.luau', ['python3 roblox/tests/build.py tests/roster.spec.luau', 'luau roblox/tests/.build/roster.spec.luau']),
    ('grindar', 'roblox/tests/sprak.spec.luau', ['python3 roblox/tests/build.py tests/sprak.spec.luau', 'luau roblox/tests/.build/sprak.spec.luau']),
    ('grindar', 'roblox/tests/sprak-en.spec.luau', ['python3 roblox/tests/build.py tests/sprak-en.spec.luau', 'luau roblox/tests/.build/sprak-en.spec.luau']),
    ('grindar', 'tools/kolla-sprak.py', ['python3 tools/kolla-sprak.py']),
    ('grindar', 'tools/kolla-generisk-hast.py', ['python3 tools/kolla-generisk-hast.py']),
    ('grindar', 'tools/testa-kolla-generisk-hast.py', ['python3 tools/testa-kolla-generisk-hast.py']),
    ('grindar', 'tools/sokvagstest.mjs', ['node tools/sokvagstest.mjs']),
    ('grindar', 'tools/testa-grindar-workflow.py', ['python3 -m pip install --quiet pyyaml', 'python3 tools/testa-grindar-workflow.py']),
    ('ridning', 'tools/ridtest.mjs', ['npm install --no-save --no-package-lock playwright@1.49.1', 'npx playwright install --with-deps chromium']),
    ('ridning', 'tools/build.py', ['python3 tools/build.py']),
    ('ridning', 'tools/sprakgrind.mjs', ['node tools/sprakgrind.mjs']),
    ('ridning', 'tools/ridtest.mjs', ['node tools/ridtest.mjs']),
    ('ridning', 'tools/gardtest.mjs', ['node tools/gardtest.mjs']),
    ('ridning', 'tools/uppdragstest.mjs', ['node tools/uppdragstest.mjs']),
    ('ridning', 'tools/inputsemantiktest.mjs', ['node tools/inputsemantiktest.mjs']),
    ('ridning', 'tools/valfardstest.mjs', ['node tools/valfardstest.mjs']),
    ('ridning', 'tools/uppdragsetikett-test.mjs', ['node tools/uppdragsetikett-test.mjs']),
    ('ridning', 'tools/replaylayouttest.mjs', ['node tools/replaylayouttest.mjs']),
    ('ridning', 'tools/skapartest.mjs', ['node tools/skapartest.mjs']),
    ('ridning', 'tools/rostgrind.mjs', ['node tools/rostgrind.mjs']),
    ('ridning', 'tools/laktartest.mjs', ['node tools/laktartest.mjs']),
]

fel = []
prov = 0


def prova(vad, ok, detalj=""):
    global prov
    prov += 1
    if ok:
        print("  OK   %s  %s" % (vad, detalj))
    else:
        print("  FEL  %s  %s" % (vad, detalj))
        fel.append(vad)


def las():
    return yaml.safe_load(io.open(YML, encoding="utf-8"))


def stegen(d):
    """(jobb, namn, run) for varje steg med ett run-block i scope."""
    for jobb in JOBB:
        for steg in d["jobs"][jobb]["steps"]:
            if steg.get("run"):
                yield jobb, steg.get("name", "(namnlost)"), steg["run"]


# ── STRUKTUR ────────────────────────────────────────────────────────────
def struktur(d):
    forbjudet = (
        ("if [ -f", "villkorat steg"),
        ("hoppar", "overhoppningsrad"),
        ("|| true", "maskerad exitkod"),
    )
    traffar = []
    for jobb, namn, run in stegen(d):
        for bit, vad in forbjudet:
            if bit in run:
                traffar.append("%s/%s: %s" % (jobb, namn[:40], vad))
    prova("inget steg hoppar over sig sjalvt", not traffar,
          "; ".join(traffar) if traffar else "0 traffar i %s" % ", ".join(JOBB))

    cont = [j + "/" + (s.get("name") or "?")
            for j in JOBB for s in d["jobs"][j]["steps"]
            if s.get("continue-on-error")]
    prova("ingen continue-on-error", not cont, "; ".join(cont) or "0")

    #[[ Varje run-block i scope ska bada ha strikt skal OCH en namngiven
    #   assertion for sin obligatoriska indata. ]]
    utan_set = []
    for jobb, namn, run in stegen(d):
        if "set -euo pipefail" not in run:
            utan_set.append("%s/%s" % (jobb, namn[:40]))
    prova("varje run-block ar strikt", not utan_set, "; ".join(utan_set) or "0")
    #[[ DEN ENDA TILLATNA AVVIKELSEN, identifierad pa INNEHALL och inte pa
    #   sitt namn: steget som hamtar luau-binaren fran uppstroms har ingen
    #   indata i repot att assertera. Namnet bar ett a-umlaut och skulle ha
    #   gjort provet beroende av teckenkodning. ]]
    kvar = []
    for jobb, namn, run in stegen(d):
        if re.search(r"^\s*test -f \S+ \|\|", run, re.M):
            continue
        if "luau-lang/luau/releases" in run:
            continue
        kvar.append("%s/%s" % (jobb, namn[:40]))
    prova("varje run-block assertar sin indata", not kvar,
          "; ".join(kvar) or "0 utover hamtningen av luau-binaren")


# ── INVENTARIE ──────────────────────────────────────────────────────────
def inventarie(d):
    funna = []
    for jobb, _, run in stegen(d):
        m = re.search(r"^\s*test -f (\S+) \|\|", run, re.M)
        if not m:
            continue
        kmd = [l.strip() for l in run.split("\n")
               if l.strip() and not l.strip().startswith(("set -euo", "test -f"))]
        funna.append((jobb, m.group(1), kmd))

    saknade = [x for x in INVENTARIE if x not in funna]
    prova("alla %d obligatoriska anrop finns kvar" % len(INVENTARIE),
          not saknade,
          "; ".join("%s %s" % (j, v) for j, v, _ in saknade[:4]) or "0 saknade")
    nya = [x for x in funna if x not in INVENTARIE]
    prova("inget oanmalt anrop har smugit in", not nya,
          "; ".join("%s %s" % (j, v) for j, v, _ in nya[:4]) or "0 nya")

    #[[ Provet sjalvt maste ocksa vara obligatoriskt. ]]
    d_alla = las()
    allt = "\n".join(s.get("run") or "" for j in d_alla["jobs"].values()
                      for s in j["steps"])
    prova("grinden anropar det har provet", "testa-grindar-workflow.py" in allt,
          "sokt i alla jobb")


# ── BETEENDE: run-blocken KORS ──────────────────────────────────────────
SKAL = """#!/bin/sh
echo "$(basename "$0") $*" >> "$UBRF_LOGG"
exit ${UBRF_EXIT:-0}
"""


def bygg_fixtur(filer, exits=None):
    """En tom katalog med `filer` skapade och skal-skal pa PATH.

    `exits` mappar kommandonamn till exitkod, sa ett steg kan provas med en
    byggare som faller men ett luau som lyckas."""
    d = tempfile.mkdtemp(prefix="g8-")
    for f in filer:
        p = os.path.join(d, f.replace("/", os.sep))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        io.open(p, "w", encoding="utf-8").write("# fixtur\n")
    bin_ = os.path.join(d, "__bin")
    os.makedirs(bin_)
    for namn in ("python3", "node", "luau", "npm", "npx", "sha256sum", "bash"):
        p = os.path.join(bin_, namn)
        kod = (exits or {}).get(namn, 0)
        io.open(p, "w", encoding="utf-8", newline="\n").write(
            SKAL.replace("${UBRF_EXIT:-0}", str(kod)))
        os.chmod(p, os.stat(p).st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    return d, bin_


def kor_block(run, filer, exits=None):
    """Kor det FAKTISKA run-blocket ur YAML:en i en isolerad fixtur."""
    d, bin_ = bygg_fixtur(filer, exits)
    try:
        skript = os.path.join(d, "__steg.sh")
        io.open(skript, "w", encoding="utf-8", newline="\n").write(run)
        logg = os.path.join(d, "__logg.txt")
        miljo = dict(os.environ)
        miljo["PATH"] = bin_ + os.pathsep + miljo["PATH"]
        miljo["UBRF_LOGG"] = logg
        r = subprocess.run(["bash", "-e", "__steg.sh"], cwd=d, env=miljo,
                           capture_output=True, encoding="utf-8",
                           errors="replace")
        kord = io.open(logg, encoding="utf-8").read() if os.path.exists(logg) else ""
        return r.returncode, (r.stdout or "") + (r.stderr or ""), kord
    finally:
        shutil.rmtree(d, ignore_errors=True)


def block_for(d, vag, kommando=None):
    """Run-blocket for ett givet obligatoriskt indata, eller None.

    RETURNERAR None I STALLET FOR ATT AVBRYTA. Under ett
    falsifieringspass dar assertionen tagits bort ur ett steg fanns
    inget block att hamta, och en `SystemExit` har slog ut hela
    beteendedelen: provet blev rott, men utan en enda rad som sa
    VILKEN kontroll som saknades. Ett avbrott ar inte en matning.
    """
    for jobb, namn, run in stegen(d):
        m = re.search(r"^\s*test -f (\S+) \|\|", run, re.M)
        if m and m.group(1) == vag and (kommando is None or kommando in run):
            return run
    return None


def beteende(d):
    def hamta(vag, kommando=None):
        run = block_for(d, vag, kommando)
        prova("steget for %s gar att hitta" % vag, run is not None,
              "har en namngiven assertion" if run else "INGET SADANT STEG")
        return run

    #[[ 1. FRISKT SKRIPT ANROPAS MED SINA ARGUMENT. ]]
    run = hamta("tools/bygg-identitet.py")
    if run is None:
        return
    rc, ut, kord = kor_block(run, ["tools/bygg-identitet.py"])
    prova("friskt skript kors och lyckas",
          rc == 0 and "bygg-identitet.py --kontrollera" in kord,
          "rc=%d  %s" % (rc, kord.strip().replace("\n", " | ")))

    #[[ 2-5. SAKNAD INDATA FALLER, MED SOKVAGEN I UTSKRIFTEN. ]]
    for vag, kmd in (("tools/bygg-identitet.py", None),
                     ("roblox/tests/kor.sh", None),
                     ("tools/kolla-place.py", None),
                     ("tools/ridtest.mjs", "node tools/ridtest.mjs"),
                     ("references/CHECKSUMS.sha256", None),
                     #[[ Grinden som vaktar grindarna maste sjalv falla nar
                     #   den raderas -- annars vore den sin egen undantag. ]]
                     ("tools/testa-grindar-workflow.py", None)):
        run = hamta(vag, kmd)
        if run is None:
            continue
        rc, ut, kord = kor_block(run, [])
        prova("SAKNAD %s faller" % vag,
              rc != 0 and vag in ut and not kord.strip(),
              "rc=%d  korde=%r" % (rc, kord.strip()))

    #[[ 6. ETT SKRIPT SOM SVARAR NOLLSKILT FALLER STEGET. ]]
    run = hamta("tools/kolla-place.py")
    if run is not None:
        rc, ut, kord = kor_block(run, ["tools/kolla-place.py"], {"python3": 3})
        prova("nollskilt svar fran ett befintligt skript faller steget",
              rc != 0, "rc=%d" % rc)

    #[[ 7. MASKERING: byggaren faller, den GAMLA genererade filen skulle ha
    #      gett gront. Steget maste anda falla, och luau far inte ha kort. ]]
    run = hamta("roblox/tests/spelbarhet.spec.luau")
    if run is None:
        return
    rc, ut, kord = kor_block(
        run,
        ["roblox/tests/spelbarhet.spec.luau",
         "roblox/tests/.build/spelbarhet.spec.luau"],
        {"python3": 1, "luau": 0})
    #[[ DELSTRANGSFALLAN: `"luau" not in kord` traffar "spelbarhet.spec.luau"
    #   i den loggade BYGGRADEN. Fragan ar om luau KORDES, sa raderna
    #   maste jamforas som rader. ]]
    kordes = [l.split()[0] for l in kord.split("\n") if l.strip()]
    prova("trasigt bygge maskeras inte av en gammal genererad fil",
          rc != 0 and "luau" not in kordes,
          "rc=%d  korde=%r" % (rc, kord.strip().replace("\n", " | ")))


def forhandskoll():
    """Namnger ALLA obligatoriska indata som saknas -- inte bara den forsta.

    GitHub stoppar ett jobb vid forsta roda steget. Saknas tre kontroller
    upptacks de en korning i taget, och varje varv kostar en full CI. Det
    har steget lagger ingen ny sanning till: det laser samma YAML och
    samma `test -f`-rader som stegen sjalva, och sager allt pa en gang."""
    d = las()
    saknade = []
    for jobb, namn, run in stegen(d):
        m = re.search(r"^\s*test -f (\S+) \|\|", run, re.M)
        if m and not os.path.exists(os.path.join(ROT, m.group(1))):
            saknade.append((jobb, m.group(1), namn))
    if not saknade:
        print("FORHANDSKOLL: alla obligatoriska indata finns")
        return 0
    print("FORHANDSKOLL: %d obligatoriska indata SAKNAS" % len(saknade))
    for jobb, vag, namn in saknade:
        print("   %-34s  jobb %-8s  steget %s" % (vag, jobb, namn))
    return 1


def main():
    if "--forhandskoll" in sys.argv[1:]:
        return forhandskoll()
    print("-- GRINDARNA AR FAIL CLOSED (G8) --")
    d = las()
    struktur(d)
    inventarie(d)
    beteende(d)
    print("")
    if fel:
        print("%d av %d prov FOLL:" % (len(fel), prov))
        for f in fel:
            print("   - %s" % f)
        return 1
    print("alla %d prov grona" % prov)
    return 0


if __name__ == "__main__":
    sys.exit(main())
