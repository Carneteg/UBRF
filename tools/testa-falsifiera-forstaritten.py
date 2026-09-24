#!/usr/bin/env python3
"""PROVET FOR FALSIFIERARENS RAKNING (#264 FALSIFIER_REPORTING_FIX).

`falsifiera-forstaritten.py` raknade accepterat grona `(svag)`-mutationer
som FANGADE och skrev `RESULTAT: 24 av 24 mutationer fangades` nar 20 var
roda. Den siffran hamnade i en rapport. Det har provet haller tre saker
fast, bade i de rena funktionerna och genom hela `main()`:

  1. en accepterat gron mutation raknas aldrig som fangad
  2. en verkligt rod mutation raknas som fangad
  3. en ofangad mutation — och en rod aterstallning — ger exit != 0

`main()` kors med stubbad `kor`, `skriv` och `aterstall` och en pahittad
kalltext. Ingen kallfil skrivs om, ingen luau kors.

Kor: python3 tools/testa-falsifiera-forstaritten.py [VERKTYG.py]

Argumentet ar till for falsifiering: provet laddar verktygets KALLA fran
den sokvagen, men som om den lag i tools/, sa att en aldre eller muterad
kopia utanfor repot kan provas utan att repot rors.
"""
import contextlib
import io
import pathlib
import sys
import types

ROT = pathlib.Path(__file__).resolve().parent.parent
VERKTYG = ROT / "tools" / "falsifiera-forstaritten.py"

fel = 0


def prova(vad, ok, detalj=""):
    global fel
    if ok:
        print("  OK   %s%s" % (vad, "  " + detalj if detalj else ""))
    else:
        fel += 1
        print("  FEL  %s%s" % (vad, "  " + detalj if detalj else ""))


def ladda(kalla):
    """Verktyget som modul. `__file__` pekar alltid pa tools/, for
    verktyget raknar ut repots rot ur den."""
    m = types.ModuleType("falsifiera_forstaritten")
    m.__file__ = str(VERKTYG)
    kod = compile(pathlib.Path(kalla).read_text(encoding="utf-8"),
                  str(VERKTYG), "exec")
    exec(kod, m.__dict__)
    return m


def korMain(m, fals, statusar):
    """Kor `main()` med en kalltext och en foljd av `kor()`-svar. Sista
    svaret ar aterstallningskontrollens."""
    m.FALS = fals
    m._ORIG = {"ForstaRitten": "ALFA\nBETA\nGAMMA\n"}
    m._CRLF = {"ForstaRitten": False}
    m.renArbetskopia = lambda: True
    skrivet = []
    m.skriv = lambda namn, text: skrivet.append(namn)
    m.aterstall = lambda: None
    svar = iter(statusar)

    #[[ Samma form som den riktiga `kor()`: ROTT och KRASCH bar sina
    #   felrader, BYGGFEL bar byggets utskrift, GRONT bar ingenting. ]]
    def kor():
        s = next(svar)
        if s in ("ROTT", "KRASCH"):
            return s, ["FEL  pahittad matning"]
        if s == "BYGGFEL":
            return s, ["pahittat byggfel"]
        return s, []
    m.kor = kor
    ut = io.StringIO()
    #[[ Ett undantag ar ett svar, inte ett avbrott. Utan fangsten kraschade
    #   provet pa forsta trasiga mutanten och matte aldrig de ovriga —
    #   rott, men av fel skal. Nu blir kraschen `kod = None`, varje
    #   kontroll pa den faller med detalj, och resten av provet kors. ]]
    try:
        with contextlib.redirect_stdout(ut):
            kod = m.main()
    except Exception as e:                       # noqa: BLE001
        return None, ut.getvalue() + "\nUNDANTAG I main(): %r" % (e,)
    return kod, ut.getvalue()


def resultatrad(text):
    for rad in text.splitlines():
        if rad.startswith("RESULTAT:"):
            return rad
    return ""


def main():
    kalla = sys.argv[1] if len(sys.argv) > 1 else str(VERKTYG)
    m = ladda(kalla)
    print("FALSIFIERARENS RAKNING\n")

    ROD = ("R1 en regel som provet fangar", "ForstaRitten", "ALFA", "alfa")
    SVAG = ("S1 en kand svag regel (svag, se noten)", "ForstaRitten",
            "BETA", "beta")
    OFANGAD = ("O1 en regel utan markering", "ForstaRitten",
               "GAMMA", "gamma")
    EJ = ("E1 en mutation som inte traffar (svag, se noten)",
          "ForstaRitten", "FINNS INTE", "x")

    print("-- Hela main(): accepterat gront ar inte fangat --")
    kod, ut = korMain(m, [ROD, SVAG], ["ROTT", "GRONT", "GRONT"])
    rad = resultatrad(ut)
    prova("en rod och en accepterat gron ger '1 av 2 ... fangades'",
          rad.startswith("RESULTAT: 1 av 2 mutationer fangades"), repr(rad))
    prova("och den accepterat grona redovisas i RESULTAT",
          "1 accepterat grona" in rad, repr(rad))
    prova("inga ofangade och gron aterstallning ger exit 0", kod == 0,
          "exit=%r" % kod)

    print("\n-- Hela main(): en verkligt rod raknas --")
    kod, ut = korMain(m, [ROD], ["ROTT", "GRONT"])
    rad = resultatrad(ut)
    prova("en rod mutation ger '1 av 1 ... fangades'",
          rad.startswith("RESULTAT: 1 av 1 mutationer fangades"), repr(rad))
    kod, ut = korMain(m, [ROD], ["KRASCH", "GRONT"])
    prova("en krasch raknas ocksa som fangad",
          resultatrad(ut).startswith("RESULTAT: 1 av 1 mutationer fangades"),
          repr(resultatrad(ut)))

    print("\n-- Hela main(): ofangat ar ett fynd --")
    kod, ut = korMain(m, [ROD, OFANGAD], ["ROTT", "GRONT", "GRONT"])
    prova("en gron mutation utan svag-markering ger exit != 0", kod not in (0, None),
          "exit=%r" % kod)
    prova("och den raknas inte som fangad",
          resultatrad(ut).startswith("RESULTAT: 1 av 2 mutationer fangades"),
          repr(resultatrad(ut)))
    kod, ut = korMain(m, [ROD, OFANGAD], ["ROTT", "BYGGFEL", "GRONT"])
    prova("ett byggfel ar ofangat, exit != 0", kod not in (0, None), "exit=%r" % kod)
    kod, ut = korMain(m, [EJ], ["GRONT"])
    prova("en svag mutation som inte gar att applicera ar ofangad, exit != 0",
          kod not in (0, None), "exit=%r" % kod)
    prova("och raknas inte som fangad",
          resultatrad(ut).startswith("RESULTAT: 0 av 1 mutationer fangades"),
          repr(resultatrad(ut)))
    kod, ut = korMain(m, [ROD], ["ROTT", "ROTT"])
    prova("en rod aterstallning ger exit != 0", kod not in (0, None), "exit=%r" % kod)

    print("\n-- De rena funktionerna --")
    klassa = getattr(m, "klassa", None)
    sammanfatta = getattr(m, "sammanfatta", None)
    prova("klassa och sammanfatta finns",
          callable(klassa) and callable(sammanfatta))
    if callable(klassa) and callable(sammanfatta):
        prova("svag + GRONT = ACCEPTED_GREEN",
              klassa(SVAG[0], "GRONT") == m.ACCEPTED_GREEN)
        prova("ROTT = RED", klassa(ROD[0], "ROTT") == m.RED)
        prova("KRASCH = RED", klassa(ROD[0], "KRASCH") == m.RED)
        prova("svag men ROTT = RED", klassa(SVAG[0], "ROTT") == m.RED)
        prova("omarkerad + GRONT = UNCAUGHT",
              klassa(OFANGAD[0], "GRONT") == m.UNCAUGHT)
        prova("svag + BYGGFEL = UNCAUGHT",
              klassa(SVAG[0], "BYGGFEL") == m.UNCAUGHT)
        prova("svag + EJ_MUTERAD = UNCAUGHT",
              klassa(SVAG[0], "EJ_MUTERAD") == m.UNCAUGHT)
        _, k = sammanfatta([m.RED, m.ACCEPTED_GREEN], True)
        prova("sammanfatta: rod + accepterat gron = exit 0", k == 0)
        _, k = sammanfatta([m.RED, m.UNCAUGHT], True)
        prova("sammanfatta: en ofangad = exit 1", k == 1)
        _, k = sammanfatta([m.RED], False)
        prova("sammanfatta: rod aterstallning = exit 1", k == 1)

    print("")
    if fel:
        print("FALSIFIERARPROVET: %d FEL" % fel)
        return 1
    print("FALSIFIERARPROVET: alla grona")
    return 0


if __name__ == "__main__":
    sys.exit(main())
