#!/usr/bin/env python3
"""GRINDEN SJALV PROVAS — I BADA RIKTNINGARNA (#259 Gate 0).

`kolla-generisk-hast.py` var GRON i CI och ROD pa Windows, och ingen av de
tva farger den visade var sann. `relative_to(ROT)` arver plattformens
separator; undantagslistan skrivs med `/`. Pa Windows matchade uppslaget
darfor aldrig, och paritetsscenariots golden data i `RidKanon.luau`
rapporterades som hardkodade hastid.

Det ar en obehaglig felklass: grinden ljuger bara for den som inte kan
agera pa den, och den som ser det roda larde sig att bortse fran grinden.
Symtomet ar en separator. Roten ar att ett undantag som inte matchar
NAGONTING sag likadant ut som ett undantag som inte BEHOVDES.

Provet matter darfor fyra saker, och tva av dem at "fel" hall:

  GRONT  `nyckel()` ger samma nyckel for bada separatorformerna — matbart
         pa vilken plattform som helst, inte bara pa Windows,
  ROTT   ett undantag som inte pekar pa nagon skannad fil faller grinden,
  ROTT   ett hardkodat hastid i en produktionsfil faller grinden,
  GRONT  samma hastid i en KOMMENTAR gor det inte — kommentarer far
         resonera om en hast, det ar beteende som ar forbjudet.

De tva sista finns for att den har rattelsen inte ska kunna forsvaga
grinden i tysthet. En grind som slutat leta ar samma tystnad som en grind
som letar pa fel stalle.

Provet skapar riktiga filer i repot och tar bort dem i `finally` — aven om
nagot kastar. Ett prov som kan lamna skrap i kallan vore varre an inget.

Kor: python3 tools/testa-kolla-generisk-hast.py   (exit 1 vid fynd)
"""
import importlib.util
import io
import contextlib
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
GRIND = ROT / "tools" / "kolla-generisk-hast.py"

#[[ Provfilerna ligger dar grinden faktiskt letar, och bar ett namn ingen
#   kan forvaxla med produktionskod. ]]
HARDKODAD = ROT / "roblox/src/client/__prov_hardkodad_hast.luau"
KOMMENTERAD = ROT / "roblox/src/client/__prov_kommenterad_hast.luau"

fel = 0


def check(namn, villkor, detalj=None):
    global fel
    if villkor:
        print("  OK   %s%s" % (namn, ("  " + detalj) if detalj else ""))
    else:
        fel += 1
        print("  FEL  %s%s" % (namn, ("  " + detalj) if detalj else ""))


def ladda():
    """Importerar grinden som modul, sa att de rena funktionerna gar att
    mata direkt i stallet for att bara kunna matas genom ett subprocess-
    exitvarde."""
    spec = importlib.util.spec_from_file_location("kolla_generisk_hast", GRIND)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def kor_grind():
    r = subprocess.run([sys.executable, str(GRIND)], cwd=str(ROT),
                       capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def nagon_hast(mod):
    """Ett kanoniskt hastid, last ur speldatan. Provet skriver INTE av ett
    namn: da hade det matt sin egen kopia i stallet for rostern."""
    ider = sorted(mod.hastid())
    return ider[0] if ider else None


def main():
    print("")
    print("GRINDPROV — kolla-generisk-hast (#259 Gate 0)")
    mod = ladda()

    # ── 1. NORMALISERINGEN ─────────────────────────────────────────
    print("\n-- Sokvagen far samma nyckel oavsett separator --")
    posix = "roblox/src/shared/HorseCore/RidKanon.luau"
    windows = "roblox\\src\\shared\\HorseCore\\RidKanon.luau"
    check("bakstreck normaliseras till snedstreck",
          mod.nyckel(windows) == posix, mod.nyckel(windows))
    check("snedstreck lamnas orort",
          mod.nyckel(posix) == posix, mod.nyckel(posix))
    check("bada formerna slar upp samma undantag",
          mod.nyckel(windows) in mod.UNDANTAG
          and mod.nyckel(posix) in mod.UNDANTAG)
    #[[ Den har raden ar den som hade fallit pa `main` fore rattelsen: den
    #   formen som `relative_to` ger pa Windows gick inte att sla upp. ]]
    check("den rana Windows-formen gar INTE att sla upp direkt",
          windows not in mod.UNDANTAG,
          "annars mater provet inget")

    # ── 2. ETT UNDANTAG SOM INTE TRAFFAR NAGOT SKA FALLA ───────────
    print("\n-- Ett undantag utan fil faller grinden --")
    riktiga = dict(mod.UNDANTAG)
    try:
        mod.UNDANTAG["roblox/src/finns/inte/Alls.luau"] = "medvetet trasigt undantag"
        ut = io.StringIO()
        with contextlib.redirect_stdout(ut):
            kod = mod.main()
        text = ut.getvalue()
        check("grinden faller pa ett undantag som inte pekar pa nagon fil",
              kod == 1, "exit=%d" % kod)
        check("och sager vilket undantag det galler",
              "finns/inte/Alls.luau" in text)
    finally:
        mod.UNDANTAG.clear()
        mod.UNDANTAG.update(riktiga)

    ut = io.StringIO()
    with contextlib.redirect_stdout(ut):
        kod = mod.main()
    check("och ar gron igen nar undantaget aterstallts",
          kod == 0, "exit=%d" % kod)

    # ── 3 och 4. GRINDEN LETAR FORTFARANDE RATT ────────────────────
    hid = nagon_hast(mod)
    if not hid:
        check("kunde lasa ett hastid ur speldatan", False)
        return 1

    print("\n-- Grinden letar fortfarande efter riktiga fynd --")
    try:
        HARDKODAD.write_text(
            "--!strict\n"
            "-- TILLFALLIG PROVFIL. Skapas och tas bort av\n"
            "-- tools/testa-kolla-generisk-hast.py. Ska ALDRIG committas.\n"
            "local function sarfall(id: string): boolean\n"
            '\treturn id == "%s"\n'
            "end\n"
            "return sarfall\n" % hid,
            encoding="utf-8")
        kod, text = kor_grind()
        check("ett hardkodat hastid i runtimekod faller grinden",
              kod == 1, "exit=%d" % kod)
        check("och namnger filen och hasten",
              "__prov_hardkodad_hast" in text and hid in text)
    finally:
        if HARDKODAD.exists():
            HARDKODAD.unlink()

    try:
        KOMMENTERAD.write_text(
            "--!strict\n"
            "-- TILLFALLIG PROVFIL. Skapas och tas bort av\n"
            "-- tools/testa-kolla-generisk-hast.py. Ska ALDRIG committas.\n"
            "--[[ Resonemang far namna en hast: %s red den forsta dagen,\n"
            "\toch det ar darfor tabellen ser ut sa har. ]]\n"
            "return true\n" % hid,
            encoding="utf-8")
        kod, text = kor_grind()
        check("samma hastid i en KOMMENTAR faller den inte",
              kod == 0, "exit=%d" % kod)
    finally:
        if KOMMENTERAD.exists():
            KOMMENTERAD.unlink()

    # ── 5. OCH REPOT SJALVT AR GRONT ───────────────────────────────
    print("\n-- Repot som det star --")
    kod, text = kor_grind()
    check("grinden ar gron pa kallan som den ar", kod == 0, "exit=%d" % kod)
    check("och undantaget tystade faktiskt nagot",
          "0 rader tystade" not in text,
          "ett undantag som tystar noll rader ar pa vag att bli dott")

    print("")
    if fel:
        print("%d matning(ar) foll." % fel)
        return 1
    print("Alla matningar gick igenom.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
