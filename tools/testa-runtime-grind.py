#!/usr/bin/env python3
"""RUNTIME-GRINDENS SJALVPROV — #252 DEL C.

En grind som aldrig visats kunna bli rod ar inget bevis. DEL B larde
banken det; samma krav galler en niva upp, och darfor provas varje
fail-closed-utgang i `tools/runtime-grind.py` har — i BADA riktningarna
dar det gar.

    python3 tools/testa-runtime-grind.py

Provet ror ALDRIG Open Cloud: varje utgang som provas ligger fore forsta
natverksanropet, eller matas genom att kalla funktionen direkt med ett
pahittat svar. Ingen nyckel behovs, och ingen place publiceras.
"""
import importlib.util
import io
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

HAR = pathlib.Path(__file__).resolve().parent
ROT = HAR.parent

spec = importlib.util.spec_from_file_location("rg", HAR / "runtime-grind.py")
rg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rg)

fynd = []
gjorda = 0


def skriv(text):
    #[[ Windows-konsolen ar cp1252. En AssertionError som bar ett
    #   ersattningstecken ur drivarens utdata dodade annars sjalva
    #   RAPPORTEN, och da sag provet ut att inte ga att kora. ]]
    kodning = getattr(sys.stdout, "encoding", None) or "utf-8"
    sys.stdout.write(str(text).encode(kodning, "replace")
                     .decode(kodning, "replace") + chr(10))


def prov(namn, f):
    global gjorda
    gjorda += 1
    try:
        f()
        skriv("  ok   %s" % namn)
    except AssertionError as e:
        fynd.append(namn)
        skriv("  FEL  %s: %s" % (namn, e))
    except Exception as e:                      # noqa: BLE001
        fynd.append(namn)
        skriv("  FEL  %s: ovantat %s: %s" % (namn, type(e).__name__, e))


def kor_grinden(extra_env=None, argv=("--torrkor",), cwd=None):
    """Kor drivaren som eget program och ge (exitkod, utdata)."""
    env = dict(os.environ)
    #[[ Ingen riktig nyckel far lacka in i provet. ]]
    for n in ("ROBLOX_API_KEY", "UBRF_UNIVERSE_ID", "UBRF_CI_PLACE_ID"):
        env.pop(n, None)
    #[[ En kopia av arbetstradet ar inget git-repo, sa `git rev-parse HEAD`
    #   ger tomt och SHA-sparren fyrar FORE den utgang provet ville mata.
    #   Provet lamnar darfor alltid en giltig head; att sparren SJALV
    #   fungerar matas av `utan_head_sha` nedan. ]]
    env.pop("GITHUB_SHA", None)
    env.setdefault("UBRF_HEAD_SHA", "0" * 40)
    #[[ BARNETS UTDATA SKA VARA UTF-8. Provet lasar roret som UTF-8, men
    #   drivaren skriver i konsolens kodning nar utdata gar till ett ror
    #   — pa Windows cp1252. Tankstreck blev `?` och nio av nitton
    #   textassertioner foll pa ett verktyg som fungerade. Samma klass av
    #   fel som M1 rattade i `pre-tobias-grind.py`. ]]
    env["PYTHONIOENCODING"] = "utf-8"
    env.update(extra_env or {})
    #[[ DRIVAREN LASER SITT EGET ROT ur `__file__`. Kor man repots kopia
    #   med `cwd` satt till ett muterat trad mater den alltsa REPOT, och
    #   varje mutationsprov blir gront av fel skal. Det hande i forsta
    #   utkastet: `inaktuell_identitet` kom ut gron med en nollad
    #   kallhash i kopian. Kor kopians egen fil. ]]
    rot = pathlib.Path(cwd or ROT)
    r = subprocess.run([sys.executable, str(rot / "tools" / "runtime-grind.py")]
                       + list(argv),
                       cwd=str(rot), capture_output=True, text=True,
                       encoding="utf-8", errors="replace", env=env)
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def rod(kod, ut, vad):
    assert kod != 0, "grinden blev GRON: %s\n%s" % (vad, ut[-600:])
    assert "RUNTIME_GRIND: FAIL" in ut, "inget FAIL-besked:\n%s" % ut[-600:]
    assert vad in ut, "FAIL-beskedet namner inte %r:\n%s" % (vad, ut[-600:])


# ── Miljon ─────────────────────────────────────────────────────────────

def utan_head_sha():
    """Evidensen ska bindas till en head. Ingen head, ingen matning."""
    kod, ut = kor_grinden({"UBRF_HEAD_SHA": "inte-en-sha"})
    rod(kod, ut, "HEAD-SHA")


def head_sha_ur_egen_variabel():
    """GITHUB_* gar inte att satta i en workflows `env:` — runnern
    ignorerar overskrivningen tyst. Drivaren maste darfor lasa sitt EGET
    namn FORST, annars binds evidensen till PR:ens merge-commit i
    stallet for dess head. Matt i korning 35424956776: env-listan sa
    27cad7c3, utdatan sa 3c7369ca."""
    egen = "a" * 40
    kod, ut = kor_grinden({"UBRF_HEAD_SHA": egen, "GITHUB_SHA": "b" * 40})
    assert kod == 0, ut[-600:]
    assert ("head: " + egen) in ut, (
        "drivaren band inte evidensen till UBRF_HEAD_SHA:" + chr(10) + ut[-600:])


def saknad_nyckel():
    kod, ut = kor_grinden({"UBRF_UNIVERSE_ID": "1", "UBRF_CI_PLACE_ID": "2"},
                          argv=())
    rod(kod, ut, "ROBLOX_API_KEY")


def saknat_universe():
    kod, ut = kor_grinden({"ROBLOX_API_KEY": "x", "UBRF_CI_PLACE_ID": "2"},
                          argv=())
    rod(kod, ut, "UBRF_UNIVERSE_ID")


def saknat_placeid():
    kod, ut = kor_grinden({"ROBLOX_API_KEY": "x", "UBRF_UNIVERSE_ID": "1"},
                          argv=())
    rod(kod, ut, "UBRF_CI_PLACE_ID")


def placeid_som_inte_ar_tal():
    kod, ut = kor_grinden({"ROBLOX_API_KEY": "x", "UBRF_UNIVERSE_ID": "1",
                           "UBRF_CI_PLACE_ID": "startplacen"}, argv=())
    rod(kod, ut, "ska vara tal")


def startplacen_ar_forbjuden():
    """Den enda sparren mellan automatiken och spelet.

    `rootplace` gar mot natet; den bytes ut mot universumets KANDA
    startplace sa att provet inte behover internet och sa att utfallet
    inte kan bli gront av ett natverksfel."""
    riktig = rg.rootplace
    rg.rootplace = lambda u: 106030782437053
    try:
        gammal = sys.stdout
        sys.stdout = io.StringIO()
        try:
            rg.main.__globals__["sys"].argv = ["rg"]
            os.environ["ROBLOX_API_KEY"] = "provnyckel"
            os.environ["UBRF_UNIVERSE_ID"] = "10766192504"
            os.environ["UBRF_CI_PLACE_ID"] = "106030782437053"
            kod = 0
            try:
                rg.main()
            except SystemExit as e:
                kod = e.code
            ut = sys.stdout.getvalue()
        finally:
            sys.stdout = gammal
            for n in ("ROBLOX_API_KEY", "UBRF_UNIVERSE_ID", "UBRF_CI_PLACE_ID"):
                os.environ.pop(n, None)
    finally:
        rg.rootplace = riktig
    assert kod != 0, "grinden lat startplacen vara mal:\n%s" % ut[-600:]
    assert "STARTPLACE" in ut, "skalet namner inte startplacen:\n%s" % ut[-600:]


def en_annan_place_ar_tillaten():
    """ANDRA RIKTNINGEN. Sparren far inte neka allt — da vaktar den inget."""
    riktig_rot, riktig_pub = rg.rootplace, rg.publicera
    rg.rootplace = lambda u: 106030782437053
    rg.publicera = lambda *a, **k: (_ for _ in ()).throw(
        rg.Rott("PROVET_NADDE_PUBLICERINGEN"))
    try:
        gammal = sys.stdout
        sys.stdout = io.StringIO()
        try:
            os.environ["ROBLOX_API_KEY"] = "provnyckel"
            os.environ["UBRF_UNIVERSE_ID"] = "10766192504"
            os.environ["UBRF_CI_PLACE_ID"] = "999999999"
            try:
                rg.main()
            except SystemExit:
                pass
            ut = sys.stdout.getvalue()
        finally:
            sys.stdout = gammal
            for n in ("ROBLOX_API_KEY", "UBRF_UNIVERSE_ID", "UBRF_CI_PLACE_ID"):
                os.environ.pop(n, None)
    finally:
        rg.rootplace, rg.publicera = riktig_rot, riktig_pub
    assert "PROVET_NADDE_PUBLICERINGEN" in ut, \
        "en icke-startplace slapptes inte fram till publiceringen:\n%s" % ut[-800:]


# ── Bygget och bindningen ──────────────────────────────────────────────

def _mappade_vagar():
    """Varje `$path` i projektfilen, som relativa sokvagar under roblox/.

    HANDSKRIVEN LISTA DOG HAR. Kopian raknade upp sina kataloger sjalv --
    tools, qa, roblox/game, roblox/src, roblox/buildings -- och den listan
    var en ANDRA SANNING bredvid default.project.json. Nar hastmallen
    mappades in som roblox/assets/hastvisualer-k3.rbxmx fanns den inte i
    kopian, och DA foll varje prov som bygger placen pa

        FEL: default.project.json mappar 'assets/...' som inte finns

    i stallet for pa det provet ville mata. Tva prov blev roda av fel
    skal, och ett sadant rott ar lika varde\u00f6st som ett falskt gront.

    Samma felklass som `rojo_agarskap` i bygg-identitet.py redan loser:
    listan GENERERAS ur projektfilen, sa nasta mappning foljer med utan
    att nagon behover minnas det."""
    import json
    projekt = json.loads(
        (ROT / "roblox" / "default.project.json").read_text(encoding="utf-8"))
    ut = set()

    def ga(nod):
        for nyckel, varde in nod.items():
            if nyckel.startswith("$") or not isinstance(varde, dict):
                continue
            if "$path" in varde:
                ut.add(varde["$path"])
            ga(varde)

    ga(projekt["tree"])
    return sorted(ut)


def _kopia():
    """Ett arbetstrad att mutera i, sa att repot aldrig ror sig."""
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="rgprov-"))
    for rel in ("tools", "qa"):
        mal = tmp / rel
        mal.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(str(ROT / rel), str(mal))
    (tmp / "roblox").mkdir(parents=True, exist_ok=True)
    shutil.copy2(str(ROT / "roblox" / "default.project.json"),
                 str(tmp / "roblox" / "default.project.json"))
    for rel in _mappade_vagar():
        kalla = ROT / "roblox" / rel
        mal = tmp / "roblox" / rel
        if mal.exists():
            continue
        mal.parent.mkdir(parents=True, exist_ok=True)
        if kalla.is_dir():
            shutil.copytree(str(kalla), str(mal))
        elif kalla.is_file():
            shutil.copy2(str(kalla), str(mal))
        else:
            raise AssertionError(
                "projektfilen mappar %r som inte finns i repot" % rel)
    return tmp


def ny_identitet(tmp):
    """Raknar om bygg-identiteten i KOPIAN.

    Utan den fyrar identitetskontrollen forst pa varje mutation som
    ror en mappad kalla, och da matar provet fel grind: mutationen
    `mountrequest_utan_namngiven_handlare` kom ut rod pa INAKTUELL i
    stallet for pa den saknade kopplingen. ]]"""
    r = subprocess.run([sys.executable, str(tmp / "tools" / "bygg-identitet.py")],
                       cwd=str(tmp), capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    assert r.returncode == 0, "kunde inte rakna om identiteten: %s" % r.stderr


def inaktuell_identitet():
    tmp = _kopia()
    try:
        p = tmp / "roblox" / "game" / "UBRFBuild.luau"
        s = p.read_text(encoding="utf-8")
        s = re.sub(r'kallhash = "[0-9a-f]{64}"',
                   'kallhash = "%s"' % ("0" * 64), s)
        p.write_text(s, encoding="utf-8")
        kod, ut = kor_grinden(cwd=tmp)
        rod(kod, ut, "INAKTUELL")
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


def identiteten_ar_aktuell_i_repot():
    """ANDRA RIKTNINGEN: oror trad ska ga igenom kontrollen."""
    kod, ut = kor_grinden()
    assert kod == 0, "torrkorningen foll pa ett ororat trad:\n%s" % ut[-800:]
    assert "bygg-identitet aktuell" in ut, ut[-400:]


def mountrequest_utan_namngiven_handlare():
    tmp = _kopia()
    try:
        p = tmp / "roblox" / "src" / "server" / "HorseService.luau"
        s = p.read_text(encoding="utf-8")
        #[[ MUTATIONEN MASTE TRAFFA DEN FORM SOM FAKTISKT FINNS.
        #
        #   Den skrevs mot #256:s raka koppling. Pa #264 ligger Gate 1A:s
        #   `Skopa.grind` utanpa, sa `replace` hittade ingenting, ingen
        #   mutation skedde, och falsifieringen rapporterade «grinden blev
        #   GRON» — vilket den ocksa hade gjort om kontrollen varit trasig.
        #   En mutation som inte muterar ar inget prov. Darfor bada
        #   formerna, OCH en vakt mot att ingen av dem traffade. ]]
        anonym = ('Net.get("MountRequest").OnServerInvoke = function(p, m)\n'
                  '\t\treturn HorseService.tryMount(p, m)\n\tend')
        fore = s
        s = re.sub(
            r'Net\.get\("MountRequest"\)\.OnServerInvoke\s*=\s*'
            r'(?:Skopa\.grind\(\s*"MountRequest"\s*,\s*'
            r'HorseService\.mountRequest\s*\)|HorseService\.mountRequest)',
            lambda _m: anonym, s, count=1)
        assert s != fore, ("mutationen traffade ingenting — HorseService "
                           "kopplar MountRequest pa ett satt provet inte kanner")
        p.write_text(s, encoding="utf-8")
        ny_identitet(tmp)
        kod, ut = kor_grinden(cwd=tmp)
        rod(kod, ut, "mountRequest")
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


def tom_smoke():
    tmp = _kopia()
    try:
        (tmp / "qa" / "runtime" / "smoke.luau").write_text("\n",
                                                           encoding="utf-8")
        kod, ut = kor_grinden(cwd=tmp)
        rod(kod, ut, "ar tom")
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


def placen_gar_inte_att_bygga():
    tmp = _kopia()
    try:
        p = tmp / "roblox" / "default.project.json"
        p.write_text('{"name":"trasig","tree":{"$className":"DataModel",'
                     '"ReplicatedStorage":{"$path":"finns/inte"}}}',
                     encoding="utf-8")
        kod, ut = kor_grinden(cwd=tmp)
        #[[ Ett trasigt `$path` faller redan i identitetsrakningen, som
        #   laser samma projektfil. Bada utgangarna ar RODA och bada ar
        #   ratt; provet kraver att NAGON av dem tog, och att beskedet
        #   namner projektfilen. ]]
        assert kod != 0, "ett trasigt projekt byggde anda: %s" % ut[-600:]
        assert "RUNTIME_GRIND: FAIL" in ut, ut[-600:]
        assert ("bygg-place.py foll" in ut or "INAKTUELL" in ut
                or "finns inte" in ut), ut[-600:]
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


# ── Rapporten ur motorn ────────────────────────────────────────────────

def task_som_inte_ar_complete():
    for lage in ("FAILED", "CANCELLED"):
        try:
            rg.las_rapport({"state": lage, "error": {"code": "X",
                                                     "message": "y"}}, "alla")
        except SystemExit:
            continue
        raise AssertionError("task-status %s lastes som grон" % lage)


def task_utan_resultat():
    try:
        rg.las_rapport({"state": "COMPLETE", "output": {"results": []}}, "alla")
    except SystemExit:
        return
    raise AssertionError("en tom rapport lastes som gron")


def task_med_resultat():
    """ANDRA RIKTNINGEN: en riktig rapport ska slappas igenom."""
    r = rg.las_rapport({"state": "COMPLETE",
                        "output": {"results": [{"antal": 1, "fel": 0}]}},
                       "alla")
    assert r["antal"] == 1, r


def okant_tasklage_ar_inte_klart():
    assert "TROLLERI" not in rg.KLARA and "TROLLERI" not in rg.PAGANDE
    assert "QUEUED" in rg.PAGANDE, "QUEUED far inte raknas som klart"
    assert "COMPLETE" in rg.KLARA


def smoken_har_alla_avsnitt():
    """Drivarens `--del` och smokens avsnittslista far inte glida isar."""
    kalla = (ROT / "qa" / "runtime" / "smoke.luau").read_text(encoding="utf-8")
    m = re.search(r"local AVSNITT = \{(.*?)\}", kalla, re.S)
    assert m, "hittade ingen AVSNITT-lista i smoken"
    namn = set(re.findall(r'"([a-z]+)"', m.group(1)))
    anropade = set(re.findall(r'skyddat\("([a-z]+)"', kalla))
    assert namn == anropade, \
        "AVSNITT och skyddat() ar inte overens: %s" % (namn ^ anropade)


def smoken_raknar_noll_som_fel():
    kalla = (ROT / "qa" / "runtime" / "smoke.luau").read_text(encoding="utf-8")
    assert "if antal == 0 then" in kalla, \
        "smoken har ingen sparr mot noll matningar"


if __name__ == "__main__":
    skriv("RUNTIME-GRINDENS SJALVPROV (#252 DEL C)")
    for fn in (utan_head_sha, head_sha_ur_egen_variabel, saknad_nyckel, saknat_universe, saknat_placeid,
               placeid_som_inte_ar_tal, startplacen_ar_forbjuden,
               en_annan_place_ar_tillaten, inaktuell_identitet,
               identiteten_ar_aktuell_i_repot,
               mountrequest_utan_namngiven_handlare, tom_smoke,
               placen_gar_inte_att_bygga, task_som_inte_ar_complete,
               task_utan_resultat, task_med_resultat,
               okant_tasklage_ar_inte_klart, smoken_har_alla_avsnitt,
               smoken_raknar_noll_som_fel):
        prov(fn.__name__, fn)
    if fynd:
        skriv("SJALVPROVET: %d av %d prov foll" % (len(fynd), gjorda))
        sys.exit(1)
    skriv("SJALVPROVET: alla %d prov grona" % gjorda)
