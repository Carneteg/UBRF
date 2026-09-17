#!/usr/bin/env python3
"""EVIDENS_PLACE (#219): den bevarade First Playable-placen ar oforandrad.

#218 bevarade den kandidat Tobias satte PRODUCT_ACCEPTED pa (PR #162) som
en ren evidensartefakt under roblox/releases/. README:n i mappen anger
SHA256, men ingenting pa main kontrollerade den. Den har grinden gor det,
och kontrollerar dessutom att .gitattributes-regeln som skyddar filen mot
radslutsnormalisering fortfarande galler.

Varfor regeln behovs: filen ar XML utan NUL-byte, sa git klassar den som
text. Utan `*.rbxlx binary` ger `core.autocrlf=true` (Windows-standard)
en checkout med 30 946 CR-byte, 1 214 391 byte och en annan hash. Samma
sak skulle en `* text=auto`-regel gora vid nasta add.

Fail closed: exit 1 och `EVIDENS_PLACE: FAIL` med vad som avviker.

    python3 tools/kolla-evidens-place.py
"""
import hashlib
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent

#[[ Den bevarade artefakten och dess accepterade identitet (README i mappen). ]]
FIL = "roblox/releases/first-playable-place-91914a7/UBRFFirstPlayable.rbxlx"
SHA256 = "4771a340b69a3a986bf56c84ecdcd3edbf208be8add73d8742c2d59195cc115c"
STORLEK = 1_183_445


def git(*arg):
    return subprocess.run(
        ["git", *arg], cwd=ROT, check=True, capture_output=True, text=True
    ).stdout


def sha256_av(data):
    return hashlib.sha256(data).hexdigest()


def main():
    fel = []

    # 1. Den committade bloben ar den accepterade filen.
    blob = subprocess.run(
        ["git", "show", f"HEAD:{FIL}"], cwd=ROT, check=True, capture_output=True
    ).stdout
    if sha256_av(blob) != SHA256:
        fel.append(f"committad blob har SHA256 {sha256_av(blob)}, vantat {SHA256}")
    if len(blob) != STORLEK:
        fel.append(f"committad blob ar {len(blob)} byte, vantat {STORLEK}")

    # 2. Arbetstradets fil ar byte for byte samma: checkouten har inte
    #    normaliserat radslut.
    stig = ROT / FIL
    if not stig.is_file():
        fel.append(f"{FIL} saknas i arbetstradet")
    else:
        data = stig.read_bytes()
        cr = data.count(b"\r")
        if sha256_av(data) != SHA256:
            fel.append(
                f"arbetstradets fil har SHA256 {sha256_av(data)} "
                f"({len(data)} byte, {cr} CR-byte), vantat {SHA256}"
            )

    # 3. Skyddet galler: filen ar markerad binary (=> text unset).
    attr = git("check-attr", "text", "--", FIL).strip()
    if not attr.endswith(": unset"):
        fel.append(f".gitattributes skyddar inte filen: `{attr}` (vantat `text: unset`)")

    if fel:
        print("EVIDENS_PLACE: FAIL")
        for rad in fel:
            print(f"  - {rad}")
        return 1
    print(f"EVIDENS_PLACE: PASS — {FIL} ar {SHA256[:12]}… ({STORLEK} byte), text unset")
    return 0


if __name__ == "__main__":
    sys.exit(main())
