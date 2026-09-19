#!/usr/bin/env python3
"""FALSIFIERINGSPASSET FOR #248 Fas B.

En grind som aldrig visats kunna bli rod ar ingen grind. Varje mutation
nedan bryter EN regel i `TavlingskladerService`, och
`tavlingsklader-session.spec.luau` ska da bli rott pa just den raden. Den
mutation som forblir GRON pekar ut en matning som inte mater -- och det
ar hela skalet till att filen finns i repot i stallet for i ett
terminalfonster: en reviewer ska kunna kora om den i stallet for att tro
pa en sammanfattning.

Den skrev en gron rad en gang. Provet "respawn skriver INTE pa den nya
avataren" holl aven nar vakten i `avsluta` togs bort, for aterstallningen
riktar sig mot den kropp sessionen borjade pa och naddes darfor aldrig av
den nya. Skyddet var arkitektur, inte vakt. Provet fick en andra matning
-- att den lamnade kroppen inte heller skrivs pa -- och bada mutationerna
faller nu var for sig (F5a och F5b).

KOR DEN INTE MED OCOMMITTAT ARBETE I MODULEN. Den skriver om kallan och
lagger tillbaka den efterat; ett avbrott mitt i lamnar en muterad fil,
och da ar det commiten som ar raddningen. Skriptet vagrar darfor starta
om modulen har ocommittade andringar.

Kor: python3 tools/falsifiera-tavlingsklader-session.py   (exit 1 vid fynd)
"""
import subprocess
import pathlib
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
MOD = ROT / "roblox" / "src" / "server" / "TavlingskladerService.luau"
SPEC = "tests/tavlingsklader-session.spec.luau"
BYGGD = "tests/.build/tavlingsklader-session.spec.luau"

#[[ RADSLUTEN MASTE OVERLEVA PASSET. Forsta versionen laste med
#   `read_text` och skrev tillbaka med `write_text`: universella radslut
#   in, rena \n ut. Filen ar CRLF i arbetskopian, sa "aterstallningen"
#   lamnade en fil som var identisk i innehall men andrad i varje rad --
#   en spokdiff i `git status` efter ett pass som pastod sig ha stadat
#   efter sig. Nu lases och skrivs bytes, och konventionen aterskapas. ]]
_RAA = MOD.read_bytes()
_CRLF = b"\r\n" in _RAA
ORIG = _RAA.decode("utf-8").replace("\r\n", "\n")


def skrivModul(text):
    data = text.replace("\n", "\r\n") if _CRLF else text
    MOD.write_bytes(data.encode("utf-8"))


def kor():
    b = subprocess.run([sys.executable, "tests/build.py", SPEC], cwd=str(ROT / "roblox"),
                       capture_output=True, text=True)
    if b.returncode != 0:
        return "BYGGFEL", [(b.stdout + b.stderr).strip()[:200]]
    r = subprocess.run(["luau", BYGGD], cwd=str(ROT / "roblox"),
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    ut = r.stdout + r.stderr
    fel = [l.strip() for l in ut.splitlines() if l.strip().startswith("FEL")]
    return ("ROTT" if fel else "GRONT"), fel


VAKT = ('\t\tif player.Character ~= session.character then\n'
        '\t\t\treturn true, "karaktar_borta", orsak\n\t\tend')

FALS = [
    ("F1 bada posterna verifieras fore forsta skrivningen",
     '\t\t\tif uppslag.assetTypeId ~= l.assetType then\n'
     '\t\t\t\treturn false, "fel_assettype"\n\t\t\tend\n\t\tend',
     '\t\t\tif uppslag.assetTypeId ~= l.assetType then\n'
     '\t\t\t\treturn false, "fel_assettype"\n\t\t\tend\n'
     '\t\t\tsakert(avataradapter.skrivMall, character, l.klass, l.egenskap,\n'
     '\t\t\t\tTavlingskladerService.mall((set :: any)[l.falt]))\n\t\tend'),

    ("F2 en fallen skrivning rullar tillbaka",
     '\t\t\t\taterstall(character, fore)\n\t\t\t\treturn false, "skrivning_foll"',
     '\t\t\t\treturn false, "skrivning_foll"'),

    ("F3 ett ursprungligen saknat lager tas bort igen",
     '\t\t\telse\n\t\t\t\tif not sakert(avataradapter.taBort, character, l.klass) then\n'
     '\t\t\t\t\tallt = false\n\t\t\t\tend\n\t\t\tend',
     '\t\t\telse\n\t\t\t\tif not sakert(avataradapter.skrivMall, character, l.klass, l.egenskap, "") then\n'
     '\t\t\t\t\tallt = false\n\t\t\t\tend\n\t\t\tend'),

    ("F4 generationsvakten efter ett yield",
     '\t\t\tif inaktuell(player, genFore, character) then\n'
     '\t\t\t\treturn false, "inaktuell"\n\t\t\tend',
     '\t\t\tif false then\n\t\t\t\treturn false, "inaktuell"\n\t\t\tend'),

    ("F5a vakten: en lamnad kropp skrivs inte pa",
     VAKT,
     '\t\tif false then\n\t\t\treturn true, "karaktar_borta", orsak\n\t\tend'),

    ("F5b riktningen: aterstallning foljer inte med till ny avatar",
     VAKT + '\n\n\t\tlocal helt = aterstall(session.character, session.ursprung)',
     '\t\tlocal helt = aterstall(player.Character or session.character, session.ursprung)'),

    ("F6 ursprungslaget sparas bara en gang",
     '\t\tif befintlig then\n\t\t\tbefintlig.setId = set.id',
     '\t\tif befintlig then\n\t\t\tbefintlig.setId = set.id\n\t\t\tbefintlig.ursprung = fore'),

    ("F7 vakterna kopplas bort vid avslut",
     '\t\tfor _, k in ipairs(session.kopplingar) do\n\t\t\tk:Disconnect()\n\t\tend',
     '\t\tfor _, k in ipairs(session.kopplingar) do\n\t\t\tlocal _ = k\n\t\tend'),

    ("F8 gransen slapper bara in de tre orden",
     '\t\tlocal set = Tavlingsklader.set(katalogId)\n\t\tif not set then',
     '\t\tlocal set = Tavlingsklader.set(katalogId)\n'
     '\t\t\tor { id = tostring(katalogId), namn = "?",\n'
     '\t\t\t\tshirtAssetId = tonumber(katalogId) or 0,\n'
     '\t\t\t\tpantsAssetId = tonumber(katalogId) or 0 }\n\t\tif not set then'),

    ("F9 andra starta med samma set ar ett no-op",
     '\t\tif befintlig and befintlig.setId == set.id and befintlig.character == character then\n'
     '\t\t\treturn true, "oforandrad"\n\t\tend',
     ''),

    ("F10 sessionen tas ur registret fore aterstallningen",
     '\t\tsessioner[player] = nil\n\t\tfor _, k in ipairs(session.kopplingar) do',
     '\t\tfor _, k in ipairs(session.kopplingar) do'),
]


def renArbetskopia():
    """Modulen maste vara committad innan den far muteras. Se filhuvudet."""
    r = subprocess.run(["git", "status", "--porcelain", "--",
                        "roblox/src/server/TavlingskladerService.luau"],
                       cwd=str(ROT), capture_output=True, text=True)
    if r.returncode != 0:
        print("KUNDE INTE FRAGA GIT — vagrar mutera en kalla jag inte kan aterstalla.")
        return False
    if r.stdout.strip():
        print("TavlingskladerService.luau har OCOMMITTADE andringar.")
        print("Committa forst: ett avbrott mitt i passet lamnar en muterad fil.")
        return False
    return True


def main():
    print("FALSIFIERING — #248 Fas B, varje grind ska kunna bli rod\n")
    if not renArbetskopia():
        return 1
    trasiga = []
    for namn, gammal, ny in FALS:
        traffar = ORIG.count(gammal)
        if traffar != 1:
            print("  ??  %-52s KUNDE INTE MUTERAS (%d traffar)" % (namn, traffar))
            trasiga.append(namn)
            continue
        skrivModul(ORIG.replace(gammal, ny, 1))
        try:
            status, fel = kor()
        finally:
            skrivModul(ORIG)
        if status == "ROTT":
            print("  ok  %-52s ROTT (%d fel)" % (namn, len(fel)))
            print("      -> %s" % fel[0][:96])
        else:
            print("  XX  %-52s %s — grinden fangade inte mutationen" % (namn, status))
            if status == "BYGGFEL":
                print("      %s" % fel[0].replace("\n", " ")[:160])
            trasiga.append(namn)

    status, fel = kor()
    print("\nEfter aterstallning av kallan: %s" % status)
    if status != "GRONT":
        for f in fel[:5]:
            print("      %s" % f)
        trasiga.append("aterstallning")
    print("\nRESULTAT: %d av %d mutationer fangades" % (len(FALS) - len([t for t in trasiga if t != "aterstallning"]), len(FALS)))
    return 1 if trasiga else 0


if __name__ == "__main__":
    sys.exit(main())
