#!/usr/bin/env python3
"""RUNTIME-GRINDEN — #252 DEL C.

Bygger placen ur PR-head, publicerar den till CI-placen genom Open Cloud,
kor `qa/runtime/smoke.luau` i RIKTIG Roblox-motor mot exakt den
publicerade versionen, och faller om en enda matning ar rod.

    python3 tools/runtime-grind.py
    python3 tools/runtime-grind.py --del ledning --del stadning
    python3 tools/runtime-grind.py --torrkor        # bygg + kontroller, ingen Open Cloud

Miljon (allt kravs, inget far saknas tyst):

    ROBLOX_API_KEY      secret. Skrivs ALDRIG ut.
    UBRF_UNIVERSE_ID    repository variable, 10766192504.
    UBRF_CI_PLACE_ID    CI-placens id. Se tools/skapa-ci-place.py.
    UBRF_HEAD_SHA       den commit evidensen binds till. GITHUB_* ar
                        reserverade och gar inte att satta i `env:`,
                        darfor ett eget namn. Faller tillbaka pa
                        GITHUB_SHA och sedan `git rev-parse HEAD`.

══ FAIL CLOSED ════════════════════════════════════════════════════════

Franvaron av ett nej ar inte ett ja. Varje utgang nedan ar ROD, aldrig
hoppad over:

  · saknad nyckel, saknat universe-id, saknat place-id,
  · CI-placens id ar universumets STARTPLACE,
  · placen gick inte att bygga, eller bygg-identiteten ar inaktuell,
  · publiceringen gav inget versionsnummer,
  · ingen task skapades, eller task-status ar inte COMPLETE,
  · smoken svarade inte med en lasbar rapport,
  · smoken korde noll matningar,
  · den korda placens kallhash ar inte PR-heads.

══ STARTPLACEN ════════════════════════════════════════════════════════

Roblox kan bara begransa en nyckel till en UPPLEVELSE, inte till en
enskild place. `universe-places:write` galler darfor alla places i UBRF,
och den har filen ar det enda som star mellan automatiken och
startplacen. Malet laeses ur `UBRF_CI_PLACE_ID`, och innan en enda byte
publiceras slas universumets `rootPlaceId` upp och jamfors. Ar de samma
ar det ett hart stopp.
"""
import argparse
import json
import os
import pathlib
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROT = pathlib.Path(__file__).resolve().parent.parent
SMOKE = ROT / "qa" / "runtime" / "smoke.luau"
IDENTITET = ROT / "roblox" / "game" / "UBRFBuild.luau"
HORSESERVICE = ROT / "roblox" / "src" / "server" / "HorseService.luau"

APIS = "https://apis.roblox.com"
GAMES = "https://games.roblox.com"

#[[ Terminala tillstand i Luau Execution. Demokoden hos Roblox pollar pa
#   `state ~= "PROCESSING"`, vilket slapper igenom QUEUED som om den vore
#   klar. Den listan ar explicit i stallet, och ett OKANT tillstand ar
#   rott — inte tolkat som klart. ]]
KLARA = {"COMPLETE", "FAILED", "CANCELLED"}
PAGANDE = {"STATE_UNSPECIFIED", "QUEUED", "PROCESSING"}


class Rott(SystemExit):
    """Grinden foll. Meddelandet ar skalet, och det ska vara lasbart."""

    def __init__(self, vad):
        print("")
        print("RUNTIME_GRIND: FAIL — " + str(vad))
        super().__init__(1)


def kor(*argv, **kw):
    return subprocess.run(list(argv), cwd=str(ROT), capture_output=True,
                          text=True, encoding="utf-8", errors="replace", **kw)


def krav(namn):
    v = os.environ.get(namn, "").strip()
    if not v:
        raise Rott("miljovariabeln %s saknas. Grinden hoppas inte over; "
                   "en grind utan sina forutsattningar ar rod." % namn)
    return v


# ── Open Cloud ─────────────────────────────────────────────────────────

def anrop(metod, url, nyckel, kropp=None, typ="application/json", tak=60):
    huvud = {"x-api-key": nyckel}
    if kropp is not None:
        huvud["Content-Type"] = typ
    begaran = urllib.request.Request(url, data=kropp, headers=huvud,
                                     method=metod)
    try:
        with urllib.request.urlopen(begaran, timeout=tak) as svar:
            text = svar.read().decode("utf-8", "replace")
            return svar.status, text
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:                      # noqa: BLE001
        #[[ Natverksfel ar inte «okant lage» — det ar rott. ]]
        return 0, "natverksfel: %s" % e


def jsonsvar(status, text, vad):
    if status < 200 or status >= 300:
        raise Rott("%s gav HTTP %s: %s" % (vad, status, text[:400]))
    try:
        return json.loads(text)
    except ValueError:
        raise Rott("%s svarade inte JSON: %s" % (vad, text[:400]))


def rootplace(universe):
    """Universumets STARTPLACE. Oautentiserat; ingen nyckel lacker ut."""
    url = "%s/v1/games?universeIds=%s" % (GAMES, universe)
    try:
        with urllib.request.urlopen(url, timeout=30) as svar:
            data = json.loads(svar.read().decode("utf-8", "replace"))
    except Exception as e:                      # noqa: BLE001
        #[[ Gar uppslaget inte att gora KAN vi inte veta att vi skriver pa
        #   ratt place. Da publicerar vi ingenting. ]]
        raise Rott("kunde inte sla upp universumets startplace (%s). "
                   "Utan den kontrollen publiceras ingenting." % e)
    poster = data.get("data") or []
    if not poster:
        raise Rott("universe %s gav ingen post hos games-API:t" % universe)
    rot = poster[0].get("rootPlaceId")
    if not rot:
        raise Rott("universe %s saknar rootPlaceId i svaret" % universe)
    return int(rot)


# ── Bygget ─────────────────────────────────────────────────────────────

def kallhash_ur_repot():
    text = IDENTITET.read_text(encoding="utf-8")
    m = re.search(r'kallhash\s*=\s*"([0-9a-f]{64})"', text)
    if not m:
        raise Rott("hittade ingen kallhash i %s" % IDENTITET)
    return m.group(1)


def bygg_placen(sha):
    """Placen ur PR-head, genom samma verktyg First Playable anvander."""
    #[[ INTE i roblox/releases/: den katalogen ar BEVARAD evidens, vaktad
    #   av tools/kolla-evidens-place.py, och en CI-artefakt som byggs om
    #   vid varje korning hor inte hemma dar. `roblox/tests/.build/` ar
    #   redan ignorerad i .gitignore. ]]
    ut = ROT / "roblox" / "tests" / ".build" / ("UBRFCI-%s.rbxlx" % sha[:7])
    r = kor(sys.executable, "tools/bygg-place.py", "--ut", str(ut), "--sha", sha)
    if r.returncode != 0:
        raise Rott("tools/bygg-place.py foll:\n%s\n%s" % (r.stdout, r.stderr))
    if not ut.is_file() or ut.stat().st_size == 0:
        raise Rott("placen byggdes inte: %s" % ut)
    print("  placen byggd: %s (%d byte)" % (ut.name, ut.stat().st_size))
    return ut


def kontrollera_identitet():
    r = kor(sys.executable, "tools/bygg-identitet.py", "--kontrollera")
    if r.returncode != 0:
        raise Rott("bygg-identiteten ar INAKTUELL — den korda placen hade "
                   "inte kunnat bindas till PR-head:\n%s\n%s"
                   % (r.stdout, r.stderr))
    print("  bygg-identitet aktuell")


def kontrollera_remotekoppling():
    """Smoken anropar `HorseService.mountRequest` och pastar att det ar
    samma funktion remoten skickar vidare till. `OnServerInvoke` gar inte
    att lasa tillbaka ur motorn, sa pastaendet maste bindas HAR — annars
    kan kopplingen tas bort utan att nagot blir rott."""
    text = HORSESERVICE.read_text(encoding="utf-8")
    #[[ TVA FORMER AR GILTIGA, och det ar Gate 1A som gjorde det sa.
    #   #256 kopplade remoten rakt; pa #264 ligger `Skopa.grind` utanpa.
    #   Kontrollens AVSIKT ar oforandrad: remoten ska till slut na den
    #   NAMNGIVNA handlaren, sa att smokens avsnitt 7 provar samma
    #   funktion som spelaren nar — inte en kopia av dess villkor.
    #   Att i stallet ta bort `Skopa.grind` hade offrat rate limiting
    #   for en textmatchning. ]]
    rakt = 'Net.get("MountRequest").OnServerInvoke = HorseService.mountRequest'
    via_skopa = re.search(
        r'Net\.get\("MountRequest"\)\.OnServerInvoke\s*=\s*'
        r'Skopa\.grind\(\s*"MountRequest"\s*,\s*HorseService\.mountRequest\s*\)',
        text) is not None
    if rakt not in text and not via_skopa:
        raise Rott("HorseService kopplar inte MountRequest till "
                   "`HorseService.mountRequest`. Smokens avsnitt 7 skulle "
                   "da prova en funktion remoten inte anvander.")
    print("  MountRequest kopplad till den namngivna handlaren")


# ── Smoken ─────────────────────────────────────────────────────────────

def skript(kallhash, del_):
    """Smoken med drivarens kontrakt inklistrat overst."""
    kalla = SMOKE.read_text(encoding="utf-8")
    if not kalla.strip():
        raise Rott("%s ar tom" % SMOKE)
    inledning = (
        "--[[ Satt av tools/runtime-grind.py. ]]\n"
        '_G.UBRF_VANTAD_KALLHASH = "%s"\n'
        '_G.UBRF_DEL = "%s"\n'
    ) % (kallhash, del_)
    return inledning + kalla


def publicera(nyckel, universe, place, fil):
    url = "%s/universes/v1/%s/places/%s/versions?versionType=Published" % (
        APIS, universe, place)
    kropp = fil.read_bytes()
    status, text = anrop("POST", url, nyckel, kropp,
                         typ="application/xml", tak=300)
    data = jsonsvar(status, text, "publiceringen")
    version = data.get("versionNumber")
    if not version:
        raise Rott("publiceringen gav inget versionsnummer: %s" % text[:400])
    print("  publicerad till place %s som version %s" % (place, version))
    return int(version)


def kor_task(nyckel, universe, place, version, kalla, del_, tak_sekunder=420):
    url = ("%s/cloud/v2/universes/%s/places/%s/versions/%s"
           "/luau-execution-session-tasks" % (APIS, universe, place, version))
    kropp = json.dumps({"script": kalla, "timeout": "300s"}).encode("utf-8")
    status, text = anrop("POST", url, nyckel, kropp)
    task = jsonsvar(status, text, "task-skapandet (%s)" % del_)
    vag = task.get("path")
    if not vag:
        raise Rott("task-svaret saknar `path`: %s" % text[:400])
    print("  task skapad: %s" % vag)

    slut = time.time() + tak_sekunder
    lage = task.get("state", "?")
    while time.time() < slut:
        if lage in KLARA:
            break
        if lage not in PAGANDE:
            raise Rott("okant task-tillstand %r — ett tillstand vi inte "
                       "kanner igen far inte tolkas som klart" % lage)
        time.sleep(5)
        status, text = anrop("GET", "%s/cloud/v2/%s" % (APIS, vag), nyckel)
        task = jsonsvar(status, text, "task-pollningen")
        lage = task.get("state", "?")
    if lage not in KLARA:
        raise Rott("task blev aldrig klar inom %d s (sista lage %s)"
                   % (tak_sekunder, lage))

    loggar = hamta_loggar(nyckel, vag)
    return task, loggar


def hamta_loggar(nyckel, vag):
    status, text = anrop("GET", "%s/cloud/v2/%s/logs" % (APIS, vag), nyckel)
    if status < 200 or status >= 300:
        return ["(loggarna gick inte att hamta: HTTP %s)" % status]
    try:
        data = json.loads(text)
    except ValueError:
        return ["(loggarna svarade inte JSON)"]
    ut = []
    for post in data.get("luauExecutionSessionTaskLogs", []):
        ut.extend(post.get("messages", []))
    return ut


def las_rapport(task, del_):
    if task.get("state") != "COMPLETE":
        fel = task.get("error") or {}
        raise Rott("task-status %s (%s: %s) for delen %r"
                   % (task.get("state"), fel.get("code"),
                      fel.get("message"), del_))
    resultat = (task.get("output") or {}).get("results") or []
    if not resultat:
        raise Rott("smoken returnerade ingenting for delen %r. En smoke "
                   "utan rapport ar rod, inte tom." % del_)
    rapport = resultat[0]
    if not isinstance(rapport, dict):
        raise Rott("smokens returvarde var inte en tabell: %r" % (rapport,))
    return rapport


# ── Huvudflodet ────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--del", dest="delar", action="append", default=None,
                    help="kor bara det har avsnittet; kan upprepas for "
                         "att dela upp korningen pa flera tasks")
    ap.add_argument("--torrkor", action="store_true",
                    help="bygg och kontrollera lokalt, ror inte Open Cloud")
    args = ap.parse_args()
    delar = args.delar or ["alla"]

    #[[ ══ VILKEN HEAD BINDS EVIDENSEN TILL? ═══════════════════════════
    #
    #   `UBRF_HEAD_SHA` och inte `GITHUB_SHA`. Forsta utkastet satte
    #   `GITHUB_SHA: ${{ github.event.pull_request.head.sha }}` i
    #   workflowen — men GITHUB_*-variabler ar RESERVERADE, och runnern
    #   ignorerar en `env:`-overskrivning av dem. Loggen visade det satta
    #   vardet medan processen fick runnerns eget. Foljden mattes i
    #   korning 35424956776: `GITHUB_SHA: 27cad7c3…` i env-listan,
    #   `head: 3c7369ca…` i utdatan — alltsa PR:ens MERGE-commit, inte
    #   dess head. Evidens som pastar fel SHA ar precis det problem
    #   Studio/Rojo-integritetsparet redan fangat en gang.
    #
    #   Bada redovisas nu: `head` ar den commit evidensen BINDS till, och
    #   `arbetstrad` ar vad checkouten faktiskt gav. Skiljer de sig sags
    #   det rakt ut i stallet for att tyst valjas bort. ]]
    sha = (os.environ.get("UBRF_HEAD_SHA", "").strip()
           or os.environ.get("GITHUB_SHA", "").strip())
    arbetstrad = kor("git", "rev-parse", "HEAD").stdout.strip()
    if not sha:
        sha = arbetstrad
    if not re.fullmatch(r"[0-9a-f]{40}", sha or ""):
        raise Rott("ingen giltig HEAD-SHA att binda evidensen till: %r" % sha)

    print("RUNTIME-GRINDEN — #252 DEL C")
    print("  head: %s" % sha)
    if arbetstrad and arbetstrad != sha:
        print("  arbetstrad: %s  (checkoutens commit; pa en PR ar det "
              "merge-commiten)" % arbetstrad)

    kontrollera_identitet()
    kontrollera_remotekoppling()
    kallhash = kallhash_ur_repot()
    print("  kallhash: %s" % kallhash)
    fil = bygg_placen(sha)

    if args.torrkor:
        for d in delar:
            kalla = skript(kallhash, d)
            print("  torrkor: skriptet for delen %r ar %d tecken"
                  % (d, len(kalla)))
        print("")
        print("RUNTIME_GRIND: TORRKORNING OK — ingen Open Cloud rord. "
              "Det har ar INTE ett PASS for grinden.")
        return 0

    nyckel = krav("ROBLOX_API_KEY")
    universe = krav("UBRF_UNIVERSE_ID")
    place = krav("UBRF_CI_PLACE_ID")
    if not place.isdigit() or not universe.isdigit():
        raise Rott("UBRF_UNIVERSE_ID och UBRF_CI_PLACE_ID ska vara tal "
                   "(fick %r respektive %r)" % (universe, place))

    #[[ STARTPLACEN. Enda spärren mellan automatiken och spelet. ]]
    start = rootplace(universe)
    if int(place) == start:
        raise Rott("UBRF_CI_PLACE_ID pekar pa universumets STARTPLACE (%d). "
                   "Automatiken far aldrig publicera dit. Satt variabeln "
                   "till CI-placens id." % start)
    print("  mal: place %s (startplacen %d ar INTE malet)" % (place, start))

    version = publicera(nyckel, universe, place, fil)

    totalt, totfel = 0, 0
    for d in delar:
        print("")
        print("── delen %s ──" % d)
        kalla = skript(kallhash, d)
        task, loggar = kor_task(nyckel, universe, place, version, kalla, d)
        for rad in loggar:
            print("    " + str(rad).rstrip())
        rapport = las_rapport(task, d)

        antal = int(rapport.get("antal") or 0)
        fel = int(rapport.get("fel") or 0)
        kord = str(rapport.get("kallhash") or "")
        if antal == 0:
            raise Rott("delen %r gjorde noll matningar" % d)
        if kord != kallhash:
            raise Rott("den korda placen bar kallhash %s, PR-head har %s — "
                       "evidensen kommer ur fel bygge" % (kord, kallhash))
        totalt += antal
        totfel += fel
        print("  delen %s: %d matningar, %d FEL" % (d, antal, fel))
        for rad in rapport.get("rader") or []:
            if not rad.get("ok"):
                print("    FEL  %s | %s | %s" % (rad.get("avsnitt"),
                                                 rad.get("namn"),
                                                 rad.get("detalj")))

    print("")
    print("  head     %s" % sha)
    print("  kallhash %s" % kallhash)
    print("  place    %s version %s" % (place, version))
    print("  %d matningar, %d FEL" % (totalt, totfel))
    if totfel:
        raise Rott("%d av %d matningar foll i riktig motor" % (totfel, totalt))
    print("")
    print("RUNTIME_GRIND: PASS — %d matningar i riktig motor pa %s"
          % (totalt, sha[:12]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
