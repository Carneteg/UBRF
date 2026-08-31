#!/usr/bin/env python3
"""Fogar ihop en enda fil att klistra in i Roblox Studio.

Paketet bygger UBRF-anläggningen, gör fasadöppningarna spelbara och lägger
UBRFSpawn vid den naturliga ankomsten. QA-panelen startas sist.

    python3 tools/studio-paket.py

Filen skrivs till roblox/buildings/.studio/ och är avsiktligt INTE committad:
den är bara en hopfogning av filer som redan ligger i repot, och en kopia i
git hade blivit ännu en sanning att hålla i synk.

Modulerna inlinas ordagrant, som roblox/tests/build.py gör för testbänken —
det som körs i Studio är alltså exakt den kod som ligger i repot.
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
BYGG = ROT / "roblox" / "buildings"
UT = BYGG / ".studio" / "UBRF-klistra-in.luau"

# Ordningen är beroendeordningen. Anlaggningen körs först, WorldBuild
# efterbehandlar sedan dess solida fasader till riktiga öppningar och spawn.
MODULER = [
    ("BuildKit",       "BuildKit.luau"),
    ("Geometri",       "Geometri.luau"),
    ("WorldGeometry",  "WorldGeometry.luau"),
    ("WorldBuild",     "WorldBuild.luau"),
    ("UBRFKomplex",    "UBRFKomplex.luau"),
    ("Vyer",           "Vyer.luau"),
    ("QAPanel",        "QAPanel.luau"),
]
SKRIPT = "Anlaggningen.luau"


def main() -> int:
    # Geometrin måste vara i synk, annars bygger Studio en gammal anläggning.
    synk = subprocess.run(
        [sys.executable and "node", str(ROT / "tools" / "exportera-geometri.js"),
         "--kontrollera"],
        capture_output=True, text=True)
    if synk.returncode != 0:
        print(synk.stdout + synk.stderr, end="")
        print("\nAvbryter: kör om exporten innan du bygger i Studio.")
        return 1

    # Materialnamnen först: ett ogiltigt Enum.Material avbryter bygget mitt i
    # Studio och allt efter det blir följdfel.
    mat = subprocess.run(
        [sys.executable, str(ROT / "tools" / "kolla-material.py")],
        capture_output=True, text=True)
    if mat.returncode != 0:
        print(mat.stdout + mat.stderr, end="")
        print("\nAvbryter: Studio hade fallit pa det har.")
        return 1

    delar = ["""--[[ ══════════════════════════════════════════════════════════════════
     UBRF — hela anläggningen, att klistra in i Roblox Studio.

     GENERERAD av tools/studio-paket.py. Ändra inte här; ändra i
     src/site.js (geometrin) eller i roblox/buildings/ (byggandet), och
     kör om skriptet.

     Paketet bygger nu även:
       · verkliga hål bakom dörrar/portar
       · ProximityPrompt-data för öppning/stängning
       · UBRFSpawn vid den naturliga ankomsten

     Runtime-dörrarna drivs av roblox/src/server/WorldService.luau.

     UBRF QA-panelen öppnas av sig själv i Studio: klicka Nästa,
     titta, klicka PASS eller FEL. UBRFQA() öppnar den igen.
     ══════════════════════════════════════════════════════════════════ ]]

"""]

    for namn, fil in MODULER:
        kropp = (BYGG / fil).read_text(encoding="utf-8")
        delar.append(f"--[[ ══ {fil} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")

    delar.append(f"--[[ ══ {SKRIPT} ══ ]]\n"
                 + (BYGG / SKRIPT).read_text(encoding="utf-8") + "\n")

    # Efter byggandet: ersätt de gamla solida fasadpartsen med segment runt
    # öppningarna, konfigurera dörrpanelerna och lägg den riktiga spawnen.
    delar.append(
        "\nlocal __worldOk = WorldBuild.apply(BuildKit, UBRFKomplex, Geometri, WorldGeometry)\n"
        "assert(__worldOk, \"WorldBuild misslyckades — spelbar värld skapades inte\")\n")

    # Paketet bygger dörrpanelerna och sätter prompten, men SERVERN äger
    # öppnandet. Utan roblox/src/server inlagt får den som testar en prompt som
    # inte gör någonting — och rapporterar rimligen "dörrarna fungerar inte" om
    # en uppsättning som aldrig kördes. Det gick inte att se förrän man stod
    # framför dörren. Nu syns det direkt efter bygget, innan Play.
    delar.append(
        "\nlocal __serverFinns = false\n"
        "for _, __i in ipairs(game:GetService(\"ServerScriptService\"):GetDescendants()) do\n"
        "\tif __i.Name == \"WorldService\" then __serverFinns = true break end\n"
        "end\n"
        "if __serverFinns then\n"
        "\tprint(\"Serverkoden finns. Tryck Play — Output ska visa \"\n"
        "\t\t.. \"[World] Dorrar bundna: N\")\n"
        "else\n"
        "\twarn(\"DORRARNA KOMMER INTE ATT FUNGERA: ServerScriptService \"\n"
        "\t\t.. \"innehaller ingen WorldService. Prompten kommer att synas och \"\n"
        "\t\t.. \"inte gora nagonting. Kor 'rojo serve roblox/' och Connect i \"\n"
        "\t\t.. \"Rojo-pluginen, kor sedan om paketet.\")\n"
        "end\n")

    # QA-panelen startas sist och bara i Studio. Den ligger med i paketet,
    # inte i roblox/src/client/, så den följer aldrig med som spelar-UI.
    delar.append(
        "\nVyer.lista()\n"
        "QAPanel.start(Vyer)\n"
        "local __qaOk = pcall(function()\n"
        "\t_G.UBRFQA = function() QAPanel.start(Vyer) end\n"
        "end)\n"
        "print(__qaOk\n"
        "\tand \"Skriv UBRFQA() i Command Bar for att oppna panelen igen.\"\n"
        "\tor \"UBRFQA() gick inte att registrera — kor om paketet for att oppna panelen.\")\n")

    UT.parent.mkdir(parents=True, exist_ok=True)
    UT.write_text("\n".join(delar), encoding="utf-8")

    rader = UT.read_text(encoding="utf-8").count("\n")
    print(f"{UT.relative_to(ROT)}: {rader} rader")
    print("Klistra in hela filen i Studio och kör den en gång.")
    print("Paketet ska skriva [WorldBuild] Spelbar värld: ... + UBRFSpawn")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
