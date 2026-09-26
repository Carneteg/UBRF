#!/usr/bin/env python3
"""FALSIFIERING AV #263 P1-RATTELSEN — hjalpen som forsvann i kortet.

Regressionen `klient-lektionspaus.spec` maste kunna bli rod. Tre
mutationer river rattelsen pa tre olika satt, och en fjarde river
replaypausen at andra hallet:

  L1  hela grenen tillbaka som den var — kortet ater varje hjalp
  L2  hjalpen slapps igenom men kvitterar inte kortet
  L3  kortet kvitteras men hjalpen slapps inte igenom
  L4  replayen slutar vara en hard paus (regeln at andra hallet)

L4 ar inte en mutation av rattelsen utan av det den skulle BEVARA.
Blir den inte rod har provet slutat vakta replaypausen, och da hade
rattelsen kunnat ata den utan att nagon sett det.

KOR DEN INTE MED OCOMMITTAT ARBETE.

Kor: python3 tools/falsifiera-lektionspaus.py   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
SPEC = "tests/klient-lektionspaus.spec.luau"
BYGGD = "tests/.build/klient-lektionspaus.spec.luau"

FILER = {
    "init": ROT / "roblox/src/client/init.client.luau",
}

_ORIG, _CRLF = {}, {}
for _namn, _p in FILER.items():
    _raa = _p.read_bytes()
    _CRLF[_namn] = b"\r\n" in _raa
    _ORIG[_namn] = _raa.decode("utf-8").replace("\r\n", "\n")


def skriv(namn, text):
    data = text.replace("\n", "\r\n") if _CRLF[namn] else text
    FILER[namn].write_bytes(data.encode("utf-8"))


def aterstall():
    for namn in FILER:
        skriv(namn, _ORIG[namn])


def kor():
    b = subprocess.run([sys.executable, "tests/build.py", SPEC],
                       cwd=str(ROT / "roblox"), capture_output=True, text=True)
    if b.returncode != 0:
        return "BYGGFEL", [(b.stdout + b.stderr).strip()[:200]]
    r = subprocess.run(["luau", BYGGD], cwd=str(ROT / "roblox"),
                       capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL")]
    if r.returncode != 0 and not fel:
        rad = ut.strip().splitlines()[-1][:200] if ut.strip() else "?"
        return "KRASCH", [rad]
    return ("ROTT" if fel else "GRONT"), fel


GREN = ('\tif LektionController.replayAktiv()\n'
        '\t\tor (LektionController.vantar() and not hjalp) then')
KVITT = '\tif LektionController.vantar() then LektionController.fortsatt() end'

FALS = [
    #[[ L1: exakt som koden sag ut fore rattelsen. Om den har inte blir
    #   rod matte provet aldrig felet. ]]
    ("L1 hela grenen tillbaka — kortet ater varje hjalp", "init",
     GREN, '\tif LektionController.vantar() or LektionController.replayAktiv() then'),

    ("L2 hjalpen slapps igenom men kvitterar inte kortet", "init",
     KVITT, '\tif false then LektionController.fortsatt() end'),

    ("L3 kortet kvitteras men hjalpen slapps inte igenom", "init",
     GREN, '\tif LektionController.replayAktiv()\n\t\tor LektionController.vantar() then'),

    #[[ L4: regeln at ANDRA hallet. Replayen ska forbli en hard paus. ]]
    ("L4 replayen slutar vara en hard paus", "init",
     GREN, '\tif (LektionController.replayAktiv() and not hjalp)\n'
           '\t\tor (LektionController.vantar() and not hjalp) then'),
]


def renArbetskopia():
    for p in FILER.values():
        rel = p.relative_to(ROT).as_posix()
        r = subprocess.run(["git", "status", "--porcelain", "--", rel],
                           cwd=str(ROT), capture_output=True, text=True)
        if r.returncode != 0 or r.stdout.strip():
            print("%s ar inte committad — committa forst." % rel)
            return False
    return True


def main():
    print("FALSIFIERING — #263 P1, lektionspausen\n")
    if not renArbetskopia():
        return 1

    status, fel = kor()
    if status != "GRONT":
        print("PROVET AR INTE GRONT FORE FALSIFIERINGEN: %s" % status)
        for f in fel[:5]:
            print("      %s" % f)
        return 1

    roda, trasiga = [], []
    for namn, fil, gammal, ny in FALS:
        muterad = _ORIG[fil]
        if muterad.count(gammal) != 1:
            print("  ??  %-52s KUNDE INTE MUTERAS (%d traffar)"
                  % (namn, muterad.count(gammal)))
            trasiga.append(namn)
            continue
        skriv(fil, muterad.replace(gammal, ny, 1))
        try:
            status, fel = kor()
        finally:
            aterstall()
        if status in ("ROTT", "KRASCH"):
            roda.append(namn)
            print("  ok  %-52s ROTT (%d fel)" % (namn, len(fel)))
            print("      -> %s" % fel[0].replace("\n", " ")[:90])
        else:
            print("  XX  %-52s %s — provet fangade inte mutationen"
                  % (namn, status))
            if status == "BYGGFEL":
                print("      %s" % fel[0].replace("\n", " ")[:160])
            trasiga.append(namn)

    status, fel = kor()
    print("\nEfter aterstallning av kallorna: %s" % status)
    if status != "GRONT":
        for f in fel[:5]:
            print("      %s" % f)
        trasiga.append("aterstallning")

    print("\nRESULTAT")
    print("  faktiskt roda      %d" % len(roda))
    print("  ofangade           %d%s"
          % (len(trasiga),
             ("  (%s)" % ", ".join(trasiga)) if trasiga else ""))
    print("  summa mutationer   %d" % len(FALS))
    return 1 if trasiga else 0


if __name__ == "__main__":
    sys.exit(main())
