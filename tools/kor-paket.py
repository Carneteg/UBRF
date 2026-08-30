#!/usr/bin/env python3
"""Kör det genererade Studio-paketet headless, mot byggbänkens stubbar.

Det bevisar att filen man klistrar in i Studio faktiskt KÖR: att den bygger
utan runtime-fel och att vyerna sätter kameran. Det bevisar ingenting om
utseende, ljus eller material — det syns bara i Studio.

Finns för att en handgjord `cat stubs paket | luau` missar att stubbarnas
materiallista injiceras av roblox/tests/build.py. Utan injektionen avvisas
varje material och felet pekar åt fel håll.

    python3 tools/kor-paket.py
"""
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROT / "roblox" / "tests"))

STUBB = ROT / "roblox" / "tests" / "stubs-bygge.luau"
PAKET = ROT / "roblox" / "buildings" / ".studio" / "UBRF-klistra-in.luau"


def main() -> int:
    if not PAKET.exists():
        print("Paketet finns inte. Kör: python3 tools/studio-paket.py")
        return 1

    from build import material  # samma injektion som specarna använder

    stubb = STUBB.read_text(encoding="utf-8").replace(
        "local __MATERIAL = {}",
        "local __MATERIAL = { " + ", ".join(f'"{m}"' for m in material()) + " }",
        1)

    ihop = ROT / "roblox" / "tests" / ".build" / "paket.luau"
    ihop.parent.mkdir(parents=True, exist_ok=True)
    ihop.write_text(stubb + "\n" + PAKET.read_text(encoding="utf-8"), encoding="utf-8")

    kord = subprocess.run(["luau", str(ihop)], capture_output=True, text=True)
    print(kord.stdout, end="")
    if kord.returncode != 0:
        print(kord.stderr, end="")
        print(f"\nPaketet KRASCHADE (exitkod {kord.returncode}). "
              "Studio hade fallit på samma ställe.")
        return kord.returncode
    print("Paketet kör utan runtime-fel.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
