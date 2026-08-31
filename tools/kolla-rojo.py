#!/usr/bin/env python3
"""Kontrollerar det tools/start-ubrf-rojo.ps1 vägrar starta utan.

Startaren är PowerShell och går inte att köra i CI. Men den vilar på tre
antaganden om repot, och DE går att pröva härifrån:

  · att roblox/default.project.json finns,
  · att den är läsbar JSON,
  · att den heter UBRF-Horse.

Byter någon namn på projektet slutar startaren fungera — och det skulle
upptäckas först när någon står i Studio och undrar varför. Nu faller det här
i stället, på en maskin där det är billigt.

Skriptet läser dessutom porten och projektsökvägen UR startaren, så att de två
filerna inte kan glida isär utan att någon märker det.
"""

import json
import pathlib
import re
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
STARTARE = ROT / "tools" / "start-ubrf-rojo.ps1"
PROJEKT = ROT / "roblox" / "default.project.json"
NAMN = "UBRF-Horse"


def fel(text: str) -> int:
    print(f"FEL  {text}")
    return 1


def main() -> int:
    brister = 0

    if not PROJEKT.exists():
        return fel(f"{PROJEKT.relative_to(ROT)} saknas")

    try:
        data = json.loads(PROJEKT.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return fel(f"{PROJEKT.relative_to(ROT)} är inte giltig JSON: {e}")

    if data.get("name") != NAMN:
        brister += fel(
            f"projektet heter {data.get('name')!r}, startaren kräver {NAMN!r}")

    if not STARTARE.exists():
        return fel(f"{STARTARE.relative_to(ROT)} saknas")

    kalla = STARTARE.read_text(encoding="utf-8")

    # Namnet startaren jämför mot ska vara samma som filen faktiskt har.
    if f"'{NAMN}'" not in kalla:
        brister += fel(f"startaren jämför inte mot {NAMN!r}")

    # Sökvägen ska vara EXPLICIT. Serveras katalogen i stället för filen är vi
    # tillbaka i katalogsökning, vilket är just det som gick fel.
    if "roblox/default.project.json" not in kalla:
        brister += fel("startaren pekar inte ut roblox/default.project.json explicit")

    # Porten ska vara en egen, inte Rojos vanliga 34872 som ett annat projekt
    # kan ligga kvar på.
    m = re.search(r"\[int\]\s*\$Port\s*=\s*(\d+)", kalla)
    if not m:
        brister += fel("hittar ingen $Port-parameter i startaren")
    elif m.group(1) == "34872":
        brister += fel("startaren använder Rojos standardport 34872 — den ska vara egen")
    else:
        print(f"OK   egen Rojo-port {m.group(1)}, inte standardens 34872")

    # Den får inte döda processer åt någon. Att rapportera PID är hela poängen.
    if re.search(r"Stop-Process|taskkill", kalla, re.IGNORECASE):
        brister += fel("startaren dödar processer — den ska rapportera PID och sluta")

    # Två projektfiler vore två sanningar. Rotkatalogen ska inte ha en egen.
    if (ROT / "default.project.json").exists():
        brister += fel("det finns en default.project.json i repo-roten också — två sanningar")

    if brister:
        print(f"\n{brister} FEL")
        return 1

    print(f"OK   {PROJEKT.relative_to(ROT)} heter {NAMN}, en enda projektfil")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
