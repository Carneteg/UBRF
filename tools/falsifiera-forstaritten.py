#!/usr/bin/env python3
"""FALSIFIERINGSPASSET FOR #263 GATE 2A — First Ride.

Kriterium 10 i ordern: varje nytt test falsifieras med minst en
mutation. Varje mutation nedan bryter EN regel, och
`forstaritten.spec.luau` ska da bli rott pa just den raden.

De skarpaste ligger forst, for de handlar om det ordern var mest
uttrycklig om:

  F1   First Ride-grenen slapper igenom mer an checklistan
  F2   valfardsstoppet kringgas
  F3   villkoret laser inte bestandig sanning
  F4   barriaren (skydd 1) prövas inte
  F5   hasten forbereds inte fysiskt

KOR DEN INTE MED OCOMMITTAT ARBETE. Den skriver om kallorna och lagger
tillbaka dem efterat; ett avbrott mitt i lamnar en muterad fil.

Kor: python3 tools/falsifiera-forstaritten.py   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
SPEC = "tests/forstaritten.spec.luau"
BYGGD = "tests/.build/forstaritten.spec.luau"

FILER = {
    "ForstaRitten": ROT / "roblox/src/server/ForstaRitten.luau",
    "GameplayService": ROT / "roblox/src/server/GameplayService.luau",
    "LedService": ROT / "roblox/src/server/LedService.luau",
    "SparService": ROT / "roblox/src/server/SparService.luau",
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
    #[[ En krasch ar ocksa rott: `kor.sh` prover exitkoden forst. Men det
    #   ska SYNAS i rapporten att det var motorn och inte en matning. ]]
    if r.returncode != 0 and not fel:
        rad = ut.strip().splitlines()[-1][:200] if ut.strip() else "?"
        return "KRASCH", [rad]
    return ("ROTT" if fel else "GRONT"), fel


FALS = [
    #[[ F1 OCH F2 AR REDUNDANTA MED VARANDRA — och det ar avsiktligt.
    #
    #   `forstaRittenSlapper` har tva sparrar:
    #
    #     F1  bara `pass.aterstar` far ersattas
    #     F2  valfardsstoppet provas uttryckligen
    #
    #   `provaUppsittning` prover `stoppad` FORE faserna, sa en stoppad
    #   hast ger alltid `forb.lararen_tar_over` — aldrig `pass.aterstar`.
    #   F1 ensam racker darfor for att halla valfardsstoppet, och F2 ar
    #   ett andra lager mot att nagon en dag byter ordning pa nejen.
    #
    #   Foljden: ingen av dem gar att falla ENSAM, och bada kommer ut
    #   grona nedan. Det ar inte en omatt regel — det ar tva
    #   oberoende sparrar framfor samma dorr. F1F2 river BADA och ar
    #   den mutation som visar att skyddet faktiskt mats.
    #
    #   Redovisade som kanda svaga mutationer, med skalet utskrivet. ]]
    ("F1 grenen slapper igenom mer an checklistan (svag, se noten)",
     "GameplayService",
     '\tif skal ~= "pass.aterstar" then return false end',
     "\tif false then return false end"),

    ("F2 valfardsstoppet kringgas (svag, se noten)", "GameplayService",
     "\tif s ~= nil and s.stoppad then return false end",
     "\tif false then return false end"),

    ("F1F2 BADA sparrarna rivs — valfardsstoppet ska da falla",
     "GameplayService",
     [('\tif skal ~= "pass.aterstar" then return false end',
       "\tif false then return false end"),
      ("\tif s ~= nil and s.stoppad then return false end",
       "\tif false then return false end")]),

    ("F3 villkoret laser inte pass-raknaren", "ForstaRitten",
     "\t\treturn Sparning.aktuelltPass(save) == 1",
     "\t\treturn true"),

    ("F4 lasningen provas inte alls (skydd 1)", "ForstaRitten",
     "\tif not SparService.betroddLasning(player) then return false end",
     "\tif false then return false end"),

    ("F5 hasten forbereds inte fysiskt", "ForstaRitten",
     "\t\t\tlocal ok, skal = TackService.satPa(player, modell, typ, hastId, modell)\n"
     "\t\t\tif not ok then return false, skal end",
     "\t\t\tlocal _ = typ"),

    ("F6 sitsen provas inte fore teleporten", "ForstaRitten",
     "\tif sits == nil or sitsNamn == nil\n\t\tor modell:FindFirstChild(sitsNamn) ~= sits then",
     "\tif false then"),

    ("F7 ridhuszonen provas inte", "ForstaRitten",
     "\tif LedService.malzon() == nil then",
     "\tif false then"),

    ("F8 idempotensen faller", "ForstaRitten",
     "\tif startad[player] then\n"
     '\t\treturn { ok = false, steg = "redan_startad" }\n\tend',
     '\tif false then\n\t\treturn { ok = false, steg = "redan_startad" }\n\tend'),

    ("F9 klockan startar efter arbetet (skydd 8)", "ForstaRitten",
     "\tmatning[player] = {\n\t\tspelKlar = klocka(),",
     "\tmatning[player] = {\n\t\tspelKlar = klocka() + 1000,"),

    ("F10 cleanup vid frankoppling uteblir", "ForstaRitten",
     "\tstartad[player] = nil\n\tmatning[player] = nil\n\tforra[player] = nil",
     "\tlocal _ = player"),

    ("F11 avsittning river inte sessionsstatus (skydd 6)", "ForstaRitten",
     "\t\tForstaRitten.noteraAvsittning(player)\n"
     "\t\tstartad[player] = nil\n\t\tmatning[player] = nil\n\t\tforra[player] = nil",
     "\t\tForstaRitten.noteraAvsittning(player)"),

    ("F12 stallFram bokfor ledningen anda", "LedService",
     "function LedService.stallFram(player: Player, modell: Model): (boolean, string?)",
     "function LedService.stallFram(player: Player, modell: Model): (boolean, string?)\n"
     '\tnoteraUppnatt(player, tostring(modell:GetAttribute("HorseId") or ""), "malNatt")'),

    ("F13 servern ser inte hastens rorelse", "ForstaRitten",
     "\tif m.forstaRorelse == nil and f.gangen > RORELSE_TROSKEL then",
     "\tif false then"),

    #[[ ══ RE-REVIEW AV `d4912c0` — de tre blockerande fynden ═══════
    #
    #   F15-F19 provar rattelserna. De tre forsta (F15, F16, F17) ar de
    #   som fallde det HAR provet i sin forra form: matningarna dolde
    #   defekterna i stallet for att mata dem. ]]

    ("F15 lasningen betros utan att provas (P1-1)", "SparService",
     "\tif not SparService.redo(player) then return false end\n\tif sparade[player] == nil then return false end\n\tlocal a = anmarkning[player]\n\tif a == nil then return true end\n\treturn BETRODDA[a] == true",
     "\treturn true"),

    ("F16 rorelsen jamfors per prov i stallet for ackumulerat (P1-2)",
     "ForstaRitten",
     "\tf.gangen += (pos - f.pos).Magnitude",
     "\tf.gangen = (pos - f.pos).Magnitude"),

    ("F17 yaw jamfors per prov i stallet for ackumulerat (P1-2)",
     "ForstaRitten",
     [("\t\t\tf.svangtVanster += dyaw",
       "\t\t\tf.svangtVanster = dyaw"),
      ("\t\t\tf.svangtHoger -= dyaw",
       "\t\t\tf.svangtHoger = -dyaw")]),

    ("F18 ingen bounded vantan pa ridklar karaktar (P1-3)",
     "ForstaRitten",
     "\tlocal ridklar = vantaRidklar(player, karVidStart, id)\n\tif ridklar == nil then",
     "\tlocal ridklar = { kar = player.Character }\n\tif false then"),

    ("F19 kroppsbyte fore mount upptacks inte (P1-3)",
     "ForstaRitten",
     "\tif player.Character ~= karVidStart then",
     "\tif false then"),
    #[[ ══ RE-REVIEW 2: det gamla forsoket som vaxte in i ny kropp ══
    #
    #   F20-F22 provar polletten. F20 ar reviewerns egen reproduktion:
    #   utan den laser vantan om `player.Character` och tar over nasta
    #   kropp. ]]

    #[[ F20 OCH F21 TACKER VARANDRA — och en tredje vakt tacker bada.
    #
    #   Vanteloopen har tre sparrar:
    #
    #     F20  `ridklarNu(kar)` — den NAMNGIVNA kroppen, inte
    #          `player.Character`
    #     F21  polletten (`mitt`)
    #     ...  och `player.Character ~= kar`, som fangar bada
    #
    #   Ingen av de tva forsta gar darfor att falla ensam. F20F21
    #   river ALLA TRE och ar den mutation som visar att skyddet mats.
    #   Samma monster som F1/F2, och redovisat pa samma satt. ]]
    ("F20 vantan laser om player.Character (svag, se noten)",
     "ForstaRitten",
     "\t\tlocal r = ridklarNu(kar)",
     "\t\tlocal r = ridklarNu(player.Character)"),

    ("F21 polletten provas inte under vantan (svag, se noten)",
     "ForstaRitten",
     "\t\tif not mitt(player, id) then return nil end",
     "\t\tif false then return nil end"),

    ("F20F21 ALLA TRE sparrarna i vantan rivs",
     "ForstaRitten",
     [("\t\tlocal r = ridklarNu(kar)",
       "\t\tlocal r = ridklarNu(player.Character)"),
      ("\t\tif not mitt(player, id) then return nil end",
       "\t\tif false then return nil end"),
      ("\t\tif player.Character ~= kar then return nil end",
       "\t\tif false then return nil end")]),

    ("F22 samma kropp far tva aktiva forsok", "ForstaRitten",
     "\tif pagar ~= nil and pagar.kar == karVidStart then",
     "\tif false then"),

    ("F14 nedvaxlingen raknas inte som broms", "ForstaRitten",
     "\t\tif fore >= 0 and efter >= 0 and efter < fore then\n\t\t\tm.bromsat = true\n\t\tend",
     "\t\tif false then\n\t\t\tm.bromsat = true\n\t\tend"),
]


def renArbetskopia():
    for namn, p in FILER.items():
        rel = p.relative_to(ROT).as_posix()
        r = subprocess.run(["git", "status", "--porcelain", "--", rel],
                           cwd=str(ROT), capture_output=True, text=True)
        if r.returncode != 0 or r.stdout.strip():
            print("%s ar inte committad — committa forst." % rel)
            return False
    return True


#[[ ══ UTFALLET HAR TRE KLASSER, INTE TVA (#264 FALSIFIER_REPORTING_FIX) ══
#
#   Raknaren var `fangade = len(FALS) - len(trasiga)`, och en accepterat
#   gron `(svag)`-mutation lades aldrig i `trasiga`. Den raknades alltsa
#   som FANGAD. Utskriften sa `24 av 24 mutationer fangades` nar 20 var
#   roda och 4 grona, och den siffran skrevs av rakt in i en rapport.
#
#   En accepterat gron mutation ar redovisad, inte fangad. Den far ALDRIG
#   ingå i fangade-talet — men den ar heller inget fynd, for skalet ar
#   dokumenterat vid F1/F2 och F20/F21 och paret river bada och ar rott.
#
#     RED             ROTT eller KRASCH — provet fangade mutationen
#     ACCEPTED_GREEN  GRONT, och mutationen ar uttryckligen markerad svag
#     UNCAUGHT        allt annat: gront utan markering, byggfel, eller en
#                     mutation som inte gick att applicera alls
#
#   Klassningen och sammanfattningen ar rena funktioner, sa att de gar
#   att prova utan att en enda kallfil skrivs om. Se
#   tools/testa-falsifiera-forstaritten.py. ]]
RED, ACCEPTED_GREEN, UNCAUGHT = "RED", "ACCEPTED_GREEN", "UNCAUGHT"


def arSvag(namn):
    return "(svag" in namn


def klassa(namn, status):
    """Status ar ROTT, KRASCH, GRONT, BYGGFEL eller EJ_MUTERAD."""
    if status in ("ROTT", "KRASCH"):
        return RED
    if status == "GRONT" and arSvag(namn):
        return ACCEPTED_GREEN
    return UNCAUGHT


def sammanfatta(klasser, aterstallningGron):
    """(rader, exitkod). Exit 0 bara utan UNCAUGHT och med gron aterstallning."""
    roda = klasser.count(RED)
    grona = klasser.count(ACCEPTED_GREEN)
    ofangade = klasser.count(UNCAUGHT)
    rader = [
        "RED (fangade):              %d" % roda,
        "ACCEPTED_GREEN (kanda svaga): %d" % grona,
        "UNCAUGHT (ofangade):        %d" % ofangade,
        "RESULTAT: %d av %d mutationer fangades (%d accepterat grona, "
        "%d ofangade)" % (roda, len(klasser), grona, ofangade),
    ]
    ok = ofangade == 0 and aterstallningGron
    return rader, (0 if ok else 1)


def main():
    print("FALSIFIERING — #263 Gate 2A, varje regel ska kunna bli rod\n")
    if not renArbetskopia():
        return 1
    klasser = []
    for post in FALS:
        namn, fil = post[0], post[1]
        #[[ En mutation ar antingen ETT par (gammal, ny) eller en LISTA
        #   av par som ska galla samtidigt. Listan behovs for regler som
        #   tacker varandra: F1 och F2 ar tva oberoende sparrar framfor
        #   samma dorr, och ingen av dem gar att falla ensam. ]]
        par = [(post[2], post[3])] if len(post) == 4 else post[2]
        muterad = _ORIG[fil]
        missad = None
        for gammal, ny in par:
            if muterad.count(gammal) != 1:
                missad = gammal
                break
            muterad = muterad.replace(gammal, ny, 1)
        if missad is not None:
            #[[ En mutation som inte gar att applicera har inte provat
            #   nagonting. Den ar UNCAUGHT, aven om den ar markerad svag. ]]
            print("  ??  %-48s KUNDE INTE MUTERAS (0 traffar i %s)"
                  % (namn, fil))
            klasser.append(klassa(namn, "EJ_MUTERAD"))
            continue
        skriv(fil, muterad)
        try:
            status, fel = kor()
        finally:
            aterstall()
        klass = klassa(namn, status)
        klasser.append(klass)
        if klass == RED and status == "ROTT":
            print("  ok  %-48s ROTT (%d fel)" % (namn, len(fel)))
            print("      -> %s" % fel[0][:90])
        elif klass == RED:
            print("  ok  %-48s ROTT (krasch — sviten faller pa exitkoden)" % namn)
            print("      -> %s" % fel[0].replace("\n", " ")[:90])
        elif klass == ACCEPTED_GREEN:
            #[[ Redovisad, inte gomd — och INTE fangad. Se noten vid
            #   F1/F2: de tacker varandra, och F1F2 ar mutationen som
            #   visar att skyddet faktiskt mats. ]]
            print("  --  %-48s GRONT (ACCEPTED_GREEN — kand svag, tacks av "
                  "den andra sparren)" % namn)
        else:
            print("  XX  %-48s %s — provet fangade inte mutationen"
                  % (namn, status))
            if status == "BYGGFEL":
                print("      %s" % fel[0].replace("\n", " ")[:160])

    status, fel = kor()
    print("\nEfter aterstallning av kallorna: %s" % status)
    if status != "GRONT":
        for f in fel[:5]:
            print("      %s" % f)
    rader, kod = sammanfatta(klasser, status == "GRONT")
    print("")
    for rad in rader:
        print(rad)
    return kod


if __name__ == "__main__":
    sys.exit(main())
