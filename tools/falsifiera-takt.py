#!/usr/bin/env python3
"""FALSIFIERINGSPASSET FOR #259 GATE 1A — takten framfor fjarrfunktionerna.

En grind som aldrig visats kunna bli rod ar ingen grind. Varje mutation
nedan bryter EN regel i `Skopa.luau` eller i en av de fyra tjansterna som
lindar sina handlare, och `takt.spec.luau` ska da bli rott pa just den
raden. Den mutation som forblir GRON pekar ut en matning som inte mater.

Ordern i #259 kraver uttryckligen tre av dem: borttagen limiter, delad
budget mellan spelare, och utebliven cleanup. De ligger som F1, F4 och F6.
Resten finns for att de gransar till samma regel och darfor kan dolja
varandra.

KOR DEN INTE MED OCOMMITTAT ARBETE I KALLORNA. Den skriver om dem och
lagger tillbaka dem efterat; ett avbrott mitt i lamnar en muterad fil, och
da ar commiten som ar raddningen. Skriptet vagrar darfor starta om nagon
av filerna har ocommittade andringar.

Kor: python3 tools/falsifiera-takt.py   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
SPEC = "tests/takt.spec.luau"
BYGGD = "tests/.build/takt.spec.luau"

FILER = {
    "Skopa": ROT / "roblox/src/server/Skopa.luau",
    "LedService": ROT / "roblox/src/server/LedService.luau",
    "GameplayService": ROT / "roblox/src/server/GameplayService.luau",
}

#[[ Radsluten maste overleva passet — samma skal som i
#   falsifiera-tavlingsklader-session.py: filerna ar CRLF i arbetskopian,
#   och en aterstallning med rena \n hade lamnat en spokdiff. ]]
_ORIG = {}
_CRLF = {}
for _namn, _p in FILER.items():
    _raa = _p.read_bytes()
    _CRLF[_namn] = b"\r\n" in _raa
    _ORIG[_namn] = _raa.decode("utf-8").replace("\r\n", "\n")


def skriv(namn, text):
    p = FILER[namn]
    data = text.replace("\n", "\r\n") if _CRLF[namn] else text
    p.write_bytes(data.encode("utf-8"))


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
    #[[ EN KRASCH AR OCKSA ROTT, och det ar ingen uppmjukning.
    #
    #   `kor.sh` provar tre saker, och den FORSTA ar exitkoden: en spec som
    #   avslutar med annat an 0 rapporteras som fallen innan nagon
    #   FEL-rakning gors. Den raden finns just for att en krasch en gang
    #   sag ut som gront.
    #
    #   F10 ar fallet: tas fail closed-vakten bort gor `hinkar[player]` ett
    #   uppslag med nil-nyckel och Luau kastar. Mutationen upptacks alltsa
    #   — men av motorn och inte av en matning, och den skillnaden ska
    #   synas i rapporten i stallet for att gommas bakom ett gront "ok". ]]
    if r.returncode != 0 and not fel:
        rad = ut.strip().splitlines()[-1][:200] if ut.strip() else "?"
        return "KRASCH", [rad]
    return ("ROTT" if fel else "GRONT"), fel


#[[ (etikett, fil, gammal, ny) ]]
FALS = [
    ("F1 limitern slapper igenom allt", "Skopa",
     "\tif hink.polletter < 1 then\n\t\trakna(player, handling, nu)\n\t\treturn false\n\tend",
     "\tif false then\n\t\trakna(player, handling, nu)\n\t\treturn false\n\tend"),

    ("F2 grinden kor handlaren anda", "Skopa",
     "\t\tif not Skopa.slapp(player, handling) then\n"
     "\t\t\tif avslagsvar then\n\t\t\t\treturn avslagsvar()\n\t\t\tend\n"
     '\t\t\treturn false, "takt.for_snabbt"\n\t\tend',
     "\t\tSkopa.slapp(player, handling)\n\t\tif false then\n"
     '\t\t\treturn false, "takt.for_snabbt"\n\t\tend'),

    ("F3 polletten forbrukas aldrig", "Skopa",
     "\think.polletter -= 1\n\treturn true",
     "\treturn true"),

    ("F4 budgeten delas mellan spelare", "Skopa",
     "\tlocal mina = hinkar[player]\n\tif not mina then\n\t\tmina = {}\n\t\thinkar[player] = mina\n\tend",
     '\tlocal mina = hinkar["alla" :: any]\n\tif not mina then\n\t\tmina = {}\n'
     '\t\thinkar["alla" :: any] = mina\n\tend'),

    ("F5 hinkarna delas mellan handlingar", "Skopa",
     "\tlocal hink = mina[handling]\n\tif not hink then",
     '\tlocal hink = mina["en"]\n\tif not hink then'),

    ("F6 cleanup vid frankoppling uteblir", "Skopa",
     "function Skopa.glom(player: Player)\n\thinkar[player] = nil\n\tavslag[player] = nil\nend",
     "function Skopa.glom(player: Player)\nend"),

    ("F6b cleanup missar avslagsraknaren", "Skopa",
     "\thinkar[player] = nil\n\tavslag[player] = nil",
     "\thinkar[player] = nil"),

    ("F7 pafyllningen star still", "Skopa",
     "\think.polletter = math.min(grans.tak,\n"
     "\t\think.polletter + (nu - hink.senast) * grans.pafyll)",
     "\think.polletter = math.min(grans.tak, hink.polletter)"),

    ("F8 pafyllningen har inget tak", "Skopa",
     "\think.polletter = math.min(grans.tak,\n"
     "\t\think.polletter + (nu - hink.senast) * grans.pafyll)",
     "\think.polletter = hink.polletter + (nu - hink.senast) * grans.pafyll"),

    ("F9 avslagen loggas en rad per anrop", "Skopa",
     "\tif nu - a.sedan >= LOGGFONSTER then",
     "\tif true then"),

    ("F10 en anonym anropare slapps igenom", "Skopa",
     '\tif type(player) ~= "table" and typeof(player) ~= "Instance" then\n\t\treturn false\n\tend',
     "\tif false then\n\t\treturn false\n\tend"),

    ("F11 LedBorja lindas inte", "LedService",
     '\tNet.get("LedBorja").OnServerInvoke = Skopa.grind("LedBorja",\n\t\tfunction(player, modell)',
     '\tNet.get("LedBorja").OnServerInvoke = (function(_h, f) return f end)("LedBorja",\n'
     '\t\tfunction(player, modell)'),

    ("F12 PreparationHello lindas inte", "GameplayService",
     '\tNet.get("PreparationHello").OnServerInvoke = Skopa.grind("PreparationHello",',
     '\tNet.get("PreparationHello").OnServerInvoke = (function(_h, f) return f end)("PreparationHello",'),
]


def renArbetskopia():
    """Kallorna maste vara committade innan de far muteras."""
    for namn, p in FILER.items():
        rel = p.relative_to(ROT).as_posix()
        r = subprocess.run(["git", "status", "--porcelain", "--", rel],
                           cwd=str(ROT), capture_output=True, text=True)
        if r.returncode != 0:
            print("KUNDE INTE FRAGA GIT om %s." % rel)
            return False
        if r.stdout.strip():
            print("%s har OCOMMITTADE andringar." % rel)
            print("Committa forst: ett avbrott mitt i passet lamnar en muterad fil.")
            return False
    return True


def main():
    print("FALSIFIERING — #259 Gate 1A, varje regel ska kunna bli rod\n")
    if not renArbetskopia():
        return 1
    trasiga = []
    for namn, fil, gammal, ny in FALS:
        traffar = _ORIG[fil].count(gammal)
        if traffar != 1:
            print("  ??  %-44s KUNDE INTE MUTERAS (%d traffar i %s)"
                  % (namn, traffar, fil))
            trasiga.append(namn)
            continue
        skriv(fil, _ORIG[fil].replace(gammal, ny, 1))
        try:
            status, fel = kor()
        finally:
            aterstall()
        if status == "ROTT":
            print("  ok  %-44s ROTT (%d fel)" % (namn, len(fel)))
            print("      -> %s" % fel[0][:94])
        elif status == "KRASCH":
            #[[ Rott, men av motorn och inte av en matning. Se noten i
            #   `kor`: `kor.sh` provar exitkoden forst, sa sviten faller. ]]
            print("  ok  %-44s ROTT (krasch — sviten faller pa exitkoden)" % namn)
            print("      -> %s" % fel[0].replace("\n", " ")[:94])
        else:
            print("  XX  %-44s %s — provet fangade inte mutationen"
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
    fangade = len(FALS) - len([t for t in trasiga if t != "aterstallning"])
    print("\nRESULTAT: %d av %d mutationer fangades" % (fangade, len(FALS)))
    return 1 if trasiga else 0


if __name__ == "__main__":
    sys.exit(main())
