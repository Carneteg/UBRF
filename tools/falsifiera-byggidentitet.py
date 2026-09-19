#!/usr/bin/env python3
"""FALSIFIERINGSPASSET FOR #263 — klientlasbar byggidentitet.

Varje mutation nedan bryter EN regel, och `klient-byggidentitet.spec`
ska da bli rott pa just den raden. Ett prov som aldrig visats kunna
bli rott ar ingen grind.

De skarpaste ligger forst, for de handlar om det ordern var mest
uttrycklig om:

  B1  det efterslapande `sha` presenteras som buildens commit
  B2  en saknad identitet visas som nagot annat an okand
  B3  en trasig hash slapps igenom som en identitet
  B4  version 0 skrivs som versionen noll i stallet for opublicerad

RESULTATRAKNINGEN AR RATTAD HAR. `falsifiera-forstaritten.py` skriver
`RESULTAT: N av N mutationer fangades` och raknar de accepterat grona
som fangade, eftersom de aldrig hamnar i `trasiga`. Den raden gjorde
att jag rapporterade fel antal pa #264. Den har filen redovisar
FAKTISKT RODA och ACCEPTERAT GRONA var for sig, och summan av dem.

KOR DEN INTE MED OCOMMITTAT ARBETE. Den skriver om kallorna och lagger
tillbaka dem efterat; ett avbrott mitt i lamnar en muterad fil.

Kor: python3 tools/falsifiera-byggidentitet.py   (exit 1 vid fynd)
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
SPEC = "tests/klient-byggidentitet.spec.luau"
BYGGD = "tests/.build/klient-byggidentitet.spec.luau"

FILER = {
    "Byggidentitet": ROT / "roblox/src/client/Byggidentitet.luau",
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
    #[[ ══ DE FYRA SOM ORDERN VAR MEST UTTRYCKLIG OM ═══════════════ ]]

    #[[ B1 ar den farligaste raden i hela leveransen. `sha` slapar per
    #   konstruktion — en committad fil kan inte kanna sitt eget
    #   commit-SHA — och en rad som pastod att det var den korande
    #   builden hade varit en logn med siffror i. QA hade da jamfort
    #   mot fel varde och trott att bygget stamde. ]]
    ("B1 det efterslapande sha visas som en rad", "Byggidentitet",
     '\t\t{ nyckel = "bygg.miljo", varde = miljo() },',
     '\t\t{ nyckel = "bygg.miljo", varde = miljo() },\n'
     '\t\t{ nyckel = "bygg.lage", varde = text(id, "sha") },'),

    #[[ B2: en saknad identitet blir en tom tabell i stallet for nil.
    #   Da ser vyn ut att ha last nagot, och raderna fylls av det som
    #   `text()` gor av nil — vilket ar precis den tysta vagen. ]]
    ("B2 saknad identitet ger tom tabell i stallet for nil", "Byggidentitet",
     '\tif m == nil or not m:IsA("ModuleScript") then return nil end',
     '\tif m == nil or not m:IsA("ModuleScript") then return {} end'),

    ("B3 en hash med fel langd slapps igenom", "Byggidentitet",
     '\tif #h ~= 64 or h:match("^%x+$") == nil then return okand() end',
     '\tif false then return okand() end'),

    ("B4 version 0 skrivs som talet noll", "Byggidentitet",
     '\tif v == 0 then return Sprak.t("bygg.opublicerad") end',
     '\tif false then return Sprak.t("bygg.opublicerad") end'),

    #[[ ══ FAIL CLOSED I DETALJ ═══════════════════════════════════ ]]

    ("B5 require-felet sväljs och ger en identitet ändå", "Byggidentitet",
     '\tif not ok or typeof(data) ~= "table" then return nil end',
     '\tif not ok then return nil end'),

    ("B6 tomma strängar räknas som lästa värden", "Byggidentitet",
     '\tif typeof(v) ~= "string" or v == "" then return okand() end',
     '\tif typeof(v) ~= "string" then return okand() end'),

    ("B7 källantalet tvingas till en sträng", "Byggidentitet",
     '\tif typeof(v) ~= "number" then return okand() end\n\treturn tostring(v)',
     '\treturn tostring(v)'),

    ("B8 PlaceId skrivs ut utan typtest", "Byggidentitet",
     '\tlocal v = (game :: any).PlaceId\n'
     '\tif typeof(v) ~= "number" then return okand() end',
     '\tlocal v = (game :: any).PlaceId\n'
     '\tif false then return okand() end'),

    ("B9 PlaceVersion skrivs ut utan typtest", "Byggidentitet",
     '\tlocal v = (game :: any).PlaceVersion\n'
     '\tif typeof(v) ~= "number" then return okand() end',
     '\tlocal v = (game :: any).PlaceVersion\n'
     '\tif false then return okand() end'),

    #[[ ══ MILJON ══════════════════════════════════════════════════ ]]

    ("B10 miljön säger alltid Studio", "Byggidentitet",
     '\tlocal namn = if arStudio() then Sprak.t("bygg.studio")\n'
     '\t\telse Sprak.t("bygg.server")',
     '\tlocal namn = Sprak.t("bygg.studio")'),

    ("B11 tom JobId skrivs ut ändå", "Byggidentitet",
     '\tif typeof(j) == "string" and j ~= "" then',
     '\tif typeof(j) == "string" then'),

    #[[ ══ HASHEN I TVA FORMER ════════════════════════════════════ ]]

    ("B12 hashen visas alltid hel", "Byggidentitet",
     '\treturn if kort then h:sub(1, 12) else h',
     '\treturn h'),

    ("B13 hashen visas alltid kort — hela går inte att få ut", "Byggidentitet",
     '\treturn if kort then h:sub(1, 12) else h',
     '\treturn h:sub(1, 12)'),

    ("B14 stängningen fäller inte ihop hashen", "Byggidentitet",
     '\thashKort = true\n\tspeglaKnapp()',
     '\tspeglaKnapp()'),

    #[[ ══ LIVSCYKELN ═════════════════════════════════════════════ ]]

    #[[ B15 och B16 ar respawnfallet: utan vakten bygger varje anrop en
    #   yta till, och spelaren far en hog av knappar pa varandra. ]]
    ("B15 knappen byggs om vid varje start", "Byggidentitet",
     '\tif knappGui ~= nil then return end',
     '\tif false then return end'),

    ("B16 panelen byggs om vid varje start", "Byggidentitet",
     '\tif panelGui ~= nil then return end',
     '\tif false then return end'),

    ("B17 ytorna rivs vid respawn", "Byggidentitet",
     '\tg.ResetOnSpawn = false\n\tg.IgnoreGuiInset = false\n'
     '\t--[[ Över hjälpknappen (16) och hjälppanelen (15), under ridanalysen',
     '\tg.ResetOnSpawn = true\n\tg.IgnoreGuiInset = false\n'
     '\t--[[ Över hjälpknappen (16) och hjälppanelen (15), under ridanalysen'),

    #[[ B18 ar kravet «far inte fanga styrning nar stangd». En tand
    #   ScreenGui tar traffar aven med genomskinliga ramar. ]]
    ("B18 panelen är tänd som utgångsläge", "Byggidentitet",
     '\tg.Enabled = false\n\tg.Parent = player:WaitForChild("PlayerGui")\n\tpanelGui = g',
     '\tg.Enabled = true\n\tg.Parent = player:WaitForChild("PlayerGui")\n\tpanelGui = g'),

    ("B19 knappen ligger kvar medan panelen står uppe", "Byggidentitet",
     '\tif b ~= nil then b.Visible = not Byggidentitet.synlig() end',
     '\tif b ~= nil then b.Visible = true end'),

    #[[ ══ LAYOUTEN ═══════════════════════════════════════════════ ]]

    ("B20 knappen viker inte undan för ridreserven", "Byggidentitet",
     '\tif reservBredd > 0 and reservTopp < botten then',
     '\tif false then'),

    ("B21 knappen viker undan även när reserven är borta", "Byggidentitet",
     '\tif reservBredd > 0 and reservTopp < botten then',
     '\tif true then'),

    ("B22 knappen går under 44 px träffyta", "Byggidentitet",
     'local KNAPPSTORLEK = 44',
     'local KNAPPSTORLEK = 40'),

    ("B23 stängknappen går under 44 px träffyta", "Byggidentitet",
     '\tstang.Size = UDim2.fromOffset(96, 44)',
     '\tstang.Size = UDim2.fromOffset(96, 30)'),

    #[[ B24: knappen skriver in sig i hjalpknappens band. Da ligger de
    #   tva pa varandra den dag `MINIMAL_UI` slas av. ]]
    ("B24 knappen tar hjälpknappens hörn", "Byggidentitet",
     'local HJALPBAND = 12 + 48',
     'local HJALPBAND = 0'),

    #[[ B25: hojden slutar folja radantalet. Det ar exakt felet provet
    #   fangade forsta gangen — atta pixlar utanfor skarmen pa 568x320. ]]
    ("B25 panelhöjden följer inte radantalet", "Byggidentitet",
     '\treturn RUBRIK_HOJD + antalRader * RAD_HOJD + STANG_HOJD + PANELPADDING * 2',
     '\tlocal _ = antalRader\n\treturn 280'),
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
    print("FALSIFIERING — #263 byggidentitet, varje regel ska kunna bli rod\n")
    if not renArbetskopia():
        return 1

    #[[ Kontrollen fore allt annat: ar provet gront som det star? Ar det
    #   inte det mater falsifieringen ett redan trasigt prov, och varje
    #   «rott» nedan bevisar ingenting. ]]
    status, fel = kor()
    if status != "GRONT":
        print("PROVET AR INTE GRONT FORE FALSIFIERINGEN: %s" % status)
        for f in fel[:5]:
            print("      %s" % f)
        return 1

    roda, gronaSvaga, trasiga = [], [], []
    for post in FALS:
        namn, fil = post[0], post[1]
        par = [(post[2], post[3])] if len(post) == 4 else post[2]
        muterad = _ORIG[fil]
        missad = None
        for gammal, ny in par:
            if muterad.count(gammal) != 1:
                missad = gammal
                break
            muterad = muterad.replace(gammal, ny, 1)
        if missad is not None:
            print("  ??  %-52s KUNDE INTE MUTERAS (%d traffar)"
                  % (namn, _ORIG[fil].count(missad)))
            trasiga.append(namn)
            continue
        skriv(fil, muterad)
        try:
            status, fel = kor()
        finally:
            aterstall()
        if status == "ROTT":
            roda.append(namn)
            print("  ok  %-52s ROTT (%d fel)" % (namn, len(fel)))
            print("      -> %s" % fel[0][:90])
        elif status == "KRASCH":
            roda.append(namn)
            print("  ok  %-52s ROTT (krasch)" % namn)
            print("      -> %s" % fel[0].replace("\n", " ")[:90])
        elif "(svag" in namn:
            #[[ Redovisad, inte gomd, och INTE inraknad bland de roda. ]]
            gronaSvaga.append(namn)
            print("  --  %-52s GRONT (kand svag, se noten)" % namn)
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

    #[[ TRE TAL, INTE ETT. Den gamla raden slog ihop roda och accepterat
    #   grona till «N av N fangades» och dolde darmed precis det som
    #   maste redovisas. ]]
    print("\nRESULTAT")
    print("  faktiskt roda      %d" % len(roda))
    print("  accepterat grona   %d%s"
          % (len(gronaSvaga),
             ("  (%s)" % ", ".join(gronaSvaga)) if gronaSvaga else ""))
    print("  ofangade           %d%s"
          % (len(trasiga),
             ("  (%s)" % ", ".join(trasiga)) if trasiga else ""))
    print("  summa mutationer   %d" % len(FALS))
    return 1 if trasiga else 0


if __name__ == "__main__":
    sys.exit(main())
