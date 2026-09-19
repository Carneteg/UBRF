#!/usr/bin/env python3
"""BANKEN SJALV PROVAS — I BADA RIKTNINGARNA (#252 DEL B).

DEL A (audits/BANK-AUDIT-2026-09-19.md) visade att build.py i ett ar kunde
bygga en spec dar en require:ad modul saknades i bunten: namnet blev en
odefinierad global, `nil`, och 14 specar korde grona utan att en enda rad
sa ifran. En bank som kan tiga om det ar ingen bank.

Den har filen provar att banken nu FALLER i vart och ett av de fall som
tidigare passerade tyst — och att den fortfarande BYGGER de riktiga
buntarna. Varje rott fall kraver ett BankFel som namnger modulen; ett rott
fall som bara "inte byggde" racker inte, for da vet ingen varfor.

  ROTT   require av en modul som inte ligger i bunten
  ROTT   require av en modul som ligger EFTER den i bunten
  ROTT   deklarerad modul vars fil inte finns
  ROTT   tom bunt
  ROTT   bunt med noll produktmoduler
  ROTT   samma modul deklarerad tva ganger
  ROTT   samma bunt definierad tva ganger i build.py
  ROTT   require av HorseCore som helhet mot en stubbfil utan __Core
  GRONT  en require som bara star i en Luau-kommentar
  GRONT  varje riktig bunt bygger, och varje deklarerad modul star EN gang

Provet skriver bara i tests/.build/, som kor.sh anda bygger om.

Kor: python3 tests/testa-build.py   (exit 1 vid fynd)
"""
import pathlib
import sys

HAR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HAR))
import build  # noqa: E402

fynd = []
gjorda = 0


def prov(namn, fn):
    global gjorda
    gjorda += 1
    try:
        fn()
        print(f"  ok   {namn}")
    except AssertionError as e:
        fynd.append(f"{namn}: {e}")
        print(f"  FEL  {namn}: {e}")
    except BaseException as e:  # BankFel arver SystemExit, sa Exception racker inte
        fynd.append(f"{namn}: ovantat {type(e).__name__}: {e}")
        print(f"  FEL  {namn}: ovantat {type(e).__name__}: {e}")


def rott(fn, *maste_namna):
    """Kor fn och krav ett BankFel vars text namnger varje ord i maste_namna."""
    try:
        fn()
    except build.BankFel as e:
        text = str(e)
        assert text.startswith("BANKEN FAIL-CLOSED"), f"fel prefix: {text[:60]!r}"
        for ord_ in maste_namna:
            assert ord_ in text, f"BankFel namnger inte {ord_!r}:\n{text}"
        return text
    raise AssertionError("inget BankFel — bygget passerade tyst")


def utan(bunt, namn):
    return [(n, r) for n, r in bunt if n != namn]


def flytta_sist(bunt, namn):
    return utan(bunt, namn) + [(n, r) for n, r in bunt if n == namn]


SPEC = "tests/integration.spec.luau"
STUBB = "tests/stubs.luau"

# ── ROTT ────────────────────────────────────────────────────────────────

def saknad_modul():
    #[[ Exakt DEL A:s hal: TackForradService borta ur integrationsbunten.
    #   GameplayService require:ar den, sa bygget ska falla DAR och saga det. ]]
    rott(lambda: build.foga(SPEC, utan(build.INTEGRATION, "TackForradService"), STUBB),
         "TackForradService", "GameplayService")


def fel_ordning():
    #[[ Modulen finns i bunten men EFTER den som require:ar den. Det ar
    #   samma nil vid korning som om den saknades; banken ska inte skilja. ]]
    rott(lambda: build.foga(SPEC, flytta_sist(build.INTEGRATION, "TackForradService"), STUBB),
         "TackForradService", "GameplayService", "FORE")


def saknad_fil():
    bunt = build.INTEGRATION + [("Spoke", "src/server/FinnsInte.luau")]
    rott(lambda: build.foga(SPEC, bunt, STUBB), "Spoke", "src/server/FinnsInte.luau")


def tom_bunt():
    rott(lambda: build.foga(SPEC, [], STUBB), "tom")


def noll_produktmoduler():
    rott(lambda: build.foga(SPEC, [("Varldsmatning", "tests/varldsmatning.luau")], STUBB),
         "noll produktmoduler")


def dubbel_modul():
    bunt = build.INTEGRATION + [("Geometri", "buildings/Geometri.luau")]
    rott(lambda: build.foga(SPEC, bunt, STUBB), "Geometri", "mer an en gang")


def dubbel_buntdefinition():
    kalla = "FORBEREDELSE = [\n]\nINTEGRATION = FORBEREDELSE + [\n]\nFORBEREDELSE = [\n]\n"
    rott(lambda: build.kontrolleraBuntdefinitioner(kalla), "FORBEREDELSE", "2x")


def core_utan_core():
    rott(lambda: build.inlina('local Core = require(RS.HorseCore)\n', set(),
                              "src/server/X.luau", SPEC, har_core=False),
         "__Core", "src/server/X.luau")


def require_i_specen():
    #[[ Aven SPECEN sjalv gar genom samma grind: en spec som require:ar en
    #   modul bunten inte laddar far inte bli ett tyst nil-pass. ]]
    rott(lambda: build.inlina('local T = require(script.Parent.Parent.TackForradService)\n'
                              'local U = require(script.Parent.SomSaknas)\n',
                              {"Geometri"}, SPEC, SPEC, har_core=True),
         "SomSaknas", SPEC)


# ── GRONT ───────────────────────────────────────────────────────────────

def kommentar_ar_ingen_require():
    kalla = ('-- local X = require(script.Parent.SomSaknas)\n'
             '--[[ require(script.Parent.SomSaknas) ]]\n'
             '--[==[\n  require(RS.SomSaknas)\n]==]\n'
             'local Y = require(script.Parent.Geometri)\n')
    ut = build.inlina(kalla, {"Geometri"}, "src/server/X.luau", SPEC, har_core=True)
    assert "local Y = Geometri\n" in ut, ut
    assert ut.count("require(") == 3, ut  # de tre i kommentarerna ror vi inte


def core_med_core():
    ut = build.inlina('local Core = require(RS.HorseCore)\nlocal G = require(RS.HorseCore.Gaits)\n',
                      {"Gaits"}, "src/server/X.luau", SPEC, har_core=True)
    assert ut == 'local Core = __Core\nlocal G = Gaits\n', ut


def buntdefinitionerna_i_build_py():
    build.kontrolleraBuntdefinitioner()


def riktiga_buntar_bygger():
    #[[ En spec per bunt, samma routing som kor.sh anvander. Efter bygget
    #   ska varje deklarerad modul sta exakt en gang — och det som DEL A
    #   fann nil ska sta som modul, inte som naket namn. ]]
    for spec in ("tests/geometri.spec.luau", "tests/bygge.spec.luau",
                 "tests/forstaplayable.spec.luau", "tests/spel.spec.luau",
                 "tests/spelbarhet.spec.luau", "tests/qa.spec.luau",
                 "tests/sikt.spec.luau", "tests/forberedelse.spec.luau",
                 "tests/integration.spec.luau", "tests/paritet.spec.luau",
                 "tests/ugneta-gestalt.spec.luau", "tests/klient.spec.luau",
                 "tests/klient-hjalpknapp.spec.luau", "tests/varldskoherens.spec.luau",
                 "tests/movement.spec.luau"):
        moduler, stubbar = build.valjBunt(spec)
        mal = build.foga(spec, moduler, stubbar)
        text = mal.read_text(encoding="utf-8")
        for namn, rel in moduler:
            n = text.count(f"\nlocal {namn} = (function()\n")
            assert n == 1, f"{spec}: {namn} star {n} ganger"
    text = (build.UT / "integration.spec.luau").read_text(encoding="utf-8")
    for namn in ("TackForradService", "DorrService", "HastVisual"):
        assert f"\nlocal {namn} = (function()\n" in text, f"{namn} saknas i integration"


if __name__ == "__main__":
    print("BANKENS SJALVPROV (#252 DEL B)")
    for fn in (saknad_modul, fel_ordning, saknad_fil, tom_bunt, noll_produktmoduler,
               dubbel_modul, dubbel_buntdefinition, core_utan_core, require_i_specen,
               kommentar_ar_ingen_require, core_med_core, buntdefinitionerna_i_build_py,
               riktiga_buntar_bygger):
        prov(fn.__name__, fn)
    if fynd:
        print(f"BANKENS SJALVPROV: {len(fynd)} av {gjorda} prov foll")
        sys.exit(1)
    print(f"BANKENS SJALVPROV: alla {gjorda} prov grona")
