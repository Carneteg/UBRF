#!/usr/bin/env python3
"""Fogar ihop en enda fil att klistra in i Roblox Studio.

Studio-kontrollen är det enda som återstår innan Gate F01 kan stängas, och den
ska inte kräva att någon lägger fyra ModuleScripts i rätt ordning i
ServerStorage. Det här skriptet gör en fil man klistrar in i ett
`run_code`-anrop eller en Script i Studio, kör en gång, och är klar.

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

# Ordningen är beroendeordningen. Anlaggningen sist: den är ett skript som körs
# för sin verkan, inte en modul som returnerar något.
MODULER = [
    ("BuildKit",     "BuildKit.luau"),
    ("Geometri",     "Geometri.luau"),
    ("UBRFKomplex",  "UBRFKomplex.luau"),
    ("Vyer",         "Vyer.luau"),
    ("QAPanel",      "QAPanel.luau"),
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

    #[[ Materialnamnen. Ett ogiltigt Enum.Material avbryter bygget MITT I
    #   Studio med "is not a valid member", och allt efter det blir foljdfel.
    #   Battre att inte lamna ifran sig paketet alls. ]]
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

     Kör en gång. Sedan:

         UBRF QA-panelen öppnas av sig själv i Studio: klicka Nästa,
         titta, klicka PASS eller FEL. UBRFQA() öppnar den igen.

         Vyer.lista()             -- vyerna Studio-kontrollen kräver
         Vyer.ga("kortandan")     -- ställ kameran för hand i stället

     Kvitteringen sker i ETT dokument:

         roblox/docs/STUDIO-QA.md                 <-- kanonisk QA-lista

     Bakgrund och detaljunderlag:

         roblox/buildings/STUDIO-KONTROLL.md      komplexet, stallet, vägarna
         roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md  ridhusets interiör

     Baslinje: Review 11 (kodgate passerad, Studio återstår).
     ══════════════════════════════════════════════════════════════════ ]]

"""]

    for namn, fil in MODULER:
        kropp = (BYGG / fil).read_text(encoding="utf-8")
        delar.append(f"--[[ ══ {fil} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")

    delar.append(f"--[[ ══ {SKRIPT} ══ ]]\n"
                 + (BYGG / SKRIPT).read_text(encoding="utf-8") + "\n")
    #[[ QA-panelen startas sist och bara i Studio. Den ligger med i PAKETET,
    #   inte i roblox/src/client/, just for att den aldrig ska kunna folja med
    #   ut i spelet. UBRFQA() finns kvar sa att den gar att oppna igen. ]]
    #[[ _G ar skrivbart i Roblox men INTE i luau-CLI:t, dar paketet
    #   verifieras. Utan pcall dor hela paketet pa sista raden med exitkod 1
    #   — vilket det gjorde, och syntes bara pa exitkoden eftersom stderr och
    #   stdout kom i olika ordning. Misslyckas den sager vi det i stallet for
    #   att svalja det. ]]
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
    print("Checklistan: roblox/docs/STUDIO-QA.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
