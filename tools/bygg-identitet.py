#!/usr/bin/env python3
"""Genererar roblox/game/UBRFBuild.luau — buildens identitet.

Bakgrund: #171. En live-audit av den anslutna Studio-placen visade att
`ReplicatedStorage.UBRFBuild` var HANDPLACERAD. Modulen sa sjalv i sin
kommentar att den var tillfallig, och den pekade pa `3ead609` medan repots
HEAD stod pa `78b7af8` — 53 commits senare. Preflightens punkt 9 laser den
modulen och rapporterade PASS. Grinden som skulle svara pa "vilken kod
testas?" svarade alltsa med fel svar, och varje QA-slutsats ur den placen
vilade pa det.

Roten var strukturell, inte slarv: `default.project.json` mappade ingen
UBRFBuild alls. En Rojo-synkad place fick darfor ingen identitet, och nagon
lade dit en for hand for att fa punkt 9 gron. `tools/bygg-place.py` gjorde
ratt sak men bara for .rbxlx-vagen — den vag Tobias INTE kor dagligen.

    python3 tools/bygg-identitet.py                 # skriv identiteten
    python3 tools/bygg-identitet.py --kontrollera   # faller om den ar inaktuell

VAD SOM AR IDENTITETEN, och varfor det inte ar git-SHA:t.

`sha` kan aldrig vara sjalvverifierande: filen committas, och da andras HEAD
av just den committen. En modul som pastar sig veta sitt eget commit-SHA
ljuger alltid med minst ett steg. Det var precis den sortens pastaende som
gick sonder i #171.

Identiteten ar darfor `kallhash`: en SHA-256 over innehallet i exakt de filer
`default.project.json` mappar in i placen. Den gar att rakna om nar som helst
och jamfora exakt — alltsa gar den att FALSIFIERA. `sha` star kvar som
upplysning om vilken head generatorn kordes pa, och `--kontrollera` gatar
aldrig pa den.

Filen hashar inte sig sjalv. Den ar mappad in i samma trad, och en hash over
sin egen utdata har ingen fixpunkt.
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
ROBLOX = ROT / "roblox"
PROJEKT = ROBLOX / "default.project.json"
MAL = ROBLOX / "game" / "UBRFBuild.luau"

#[[ Lagen en genererad identitet far ha. Preflighten slapper bara igenom
#   dessa; allt annat — inklusive den handplacerade "rojo-live" ur #171 —
#   raknas som okand identitet och faller grinden. ]]
LAGE_ROJO = "rojo"
LAGE_PLACE = "place"


def mappade_vagar(trad):
    """Alla $path ur projektfilen, som sokvagar relativt roblox/."""
    ut = []

    def ga(nod):
        if not isinstance(nod, dict):
            return
        vag = nod.get("$path")
        if isinstance(vag, str):
            ut.append(vag)
        for nyckel, varde in nod.items():
            if not nyckel.startswith("$"):
                ga(varde)

    ga(trad)
    return ut


def filer_for(vag):
    """Filerna bakom en $path. En katalog tas rekursivt, sorterad."""
    p = ROBLOX / vag
    if p.is_file():
        return [p]
    if p.is_dir():
        return sorted((f for f in p.rglob("*") if f.is_file()),
                      key=lambda f: f.as_posix())
    #[[ En mappad vag som inte finns ar ett riktigt fel: placen far da ett
    #   hal som varken Rojo eller preflighten namner. Tyst hoppa over den
    #   vore att aterinfora #171:s grundbugg i ny form. ]]
    raise SystemExit(f"FEL: default.project.json mappar {vag!r} som inte finns")


def kallfiler():
    """Varje fil som Rojo synkar in i placen — utom identiteten sjalv."""
    projekt = json.loads(PROJEKT.read_text(encoding="utf-8"))
    sedda = set()
    ut = []
    for vag in sorted(set(mappade_vagar(projekt["tree"]))):
        #[[ Identiteten mappas in i samma trad men hashas aldrig: en hash
        #   over sin egen utdata har ingen fixpunkt. Undantaget maste ligga
        #   FORE filuppslaget — annars faller forsta korningen pa att filen
        #   som ska genereras inte finns an. ]]
        if (ROBLOX / vag).resolve() == MAL.resolve():
            continue
        for f in filer_for(vag):
            if f.resolve() == MAL.resolve():
                continue
            nyckel = f.relative_to(ROBLOX).as_posix()
            if nyckel in sedda:
                continue
            sedda.add(nyckel)
            ut.append((nyckel, f))
    return sorted(ut, key=lambda par: par[0])


def rojo_agarskap(trad):
    """Vilka toppnivainstanser Rojo ager per tjanst.

    `Integritet.luau` behover veta vad som ar kallstyrt for att kunna skilja
    det fran runtime-skapat och frammande. Listan GENERERAS har i stallet for
    att skrivas for hand i Luau: en handskriven kopia hade blivit en andra
    sanning bredvid projektfilen, och nasta gang nagon mappar in en modul
    hade grinden tyst slutat kanna till den. Exakt sa forsvann `UBRFSprak`
    ur preflighten en gang.
    """
    ut = {}
    for tjanst, nod in trad.items():
        if tjanst.startswith("$") or not isinstance(nod, dict):
            continue
        namn = sorted(n for n in nod.keys() if not n.startswith("$"))
        if namn:
            ut[tjanst] = namn
    return ut


def kallhash(filer):
    """SHA-256 over sokvag + innehall for varje mappad fil.

    Radslut normaliseras till LF. Utan det ger samma commit olika hash pa en
    Windows-checkout med autocrlf an pa CI, och en identitet som beror pa VEM
    som raknade den ar ingen identitet.
    """
    h = hashlib.sha256()
    for nyckel, f in filer:
        kropp = f.read_bytes().replace(b"\r\n", b"\n")
        h.update(nyckel.encode("utf-8"))
        h.update(b"\0")
        h.update(hashlib.sha256(kropp).hexdigest().encode("ascii"))
        h.update(b"\n")
    return h.hexdigest()


def sha_nu():
    try:
        return subprocess.run(["git", "rev-parse", "HEAD"], cwd=str(ROT),
                              capture_output=True, text=True,
                              check=True).stdout.strip()
    except Exception:
        return "OKAND"


def rojo_luau(agarskap):
    rader = []
    for tjanst in sorted(agarskap):
        namn = ", ".join(f'"{n}"' for n in agarskap[tjanst])
        rader.append(f"\t\t{tjanst} = {{ {namn} }},")
    return "\n".join(rader)


def modultext(hash_, sha, lage, antal, nu, agarskap):
    return (
        "--!strict\n"
        "--[[ GENERERAD av tools/bygg-identitet.py — andra inte har.\n"
        "\n"
        "\tBuildens identitet, last av Preflight punkt 9. `kallhash` ar den\n"
        "\tsom galler: en SHA-256 over innehallet i de filer\n"
        "\t`default.project.json` mappar in i placen. Den gar att rakna om\n"
        "\toch jamfora exakt.\n"
        "\n"
        "\t`sha` ar UPPLYSNING, inte grind. En committad fil kan inte kanna\n"
        "\tsitt eget commit-SHA, sa det faltet ligger alltid minst ett steg\n"
        "\tefter. Gata aldrig pa det. ]]\n"
        "return {\n"
        f'\tkallhash = "{hash_}",\n'
        f'\tlage = "{lage}",\n'
        f'\tkallor = {antal},\n'
        f'\tsha = "{sha}",\n'
        f'\tmiljo_sha = "{sha}",\n'
        f'\tgenererad = "{nu}",\n'
        '\tvag = "tools/bygg-identitet.py ur roblox/default.project.json",\n'
        "\n"
        "\t--[[ Vad Rojo AGER per tjanst. Integritet.luau skiljer kallstyrt\n"
        "\t\tfran runtime-skapat och frammande med den har listan. ]]\n"
        "\trojo = {\n"
        + rojo_luau(agarskap) + "\n"
        "\t},\n"
        "}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kontrollera", action="store_true",
                    help="skriv inget; fall om den committade identiteten "
                         "inte matchar kallorna")
    ap.add_argument("--lage", default=LAGE_ROJO, choices=[LAGE_ROJO, LAGE_PLACE])
    args = ap.parse_args()

    projekt = json.loads(PROJEKT.read_text(encoding="utf-8"))
    filer = kallfiler()
    nu_hash = kallhash(filer)

    if args.kontrollera:
        if not MAL.exists():
            print(f"FEL: {MAL.relative_to(ROT)} saknas — kor "
                  "python3 tools/bygg-identitet.py")
            return 1
        text = MAL.read_text(encoding="utf-8")
        #[[ Lases som text och inte via Luau: kontrollen ska funka i CI utan
        #   en luau-runtime, och den behover bara ett falt. ]]
        funnen = None
        for rad in text.splitlines():
            bit = rad.strip()
            if bit.startswith("kallhash"):
                funnen = bit.split('"')[1] if '"' in bit else None
                break
        if funnen is None:
            print(f"FEL: {MAL.relative_to(ROT)} saknar kallhash — "
                  "identiteten ar inte genererad")
            return 1
        if funnen != nu_hash:
            print("FEL: build-identiteten ar INAKTUELL.")
            print(f"  committad: {funnen}")
            print(f"  kallorna:  {nu_hash}")
            print(f"  {len(filer)} mappade filer raknade")
            print("  kor: python3 tools/bygg-identitet.py")
            return 1
        print(f"build-identitet aktuell: {funnen}  ({len(filer)} kallfiler)")
        return 0

    text = modultext(nu_hash, sha_nu(), args.lage, len(filer),
                     datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
                     rojo_agarskap(projekt["tree"]))
    MAL.parent.mkdir(parents=True, exist_ok=True)
    MAL.write_text(text, encoding="utf-8")
    print(f"{MAL.relative_to(ROT)}: kallhash {nu_hash} ur {len(filer)} filer")
    return 0


if __name__ == "__main__":
    sys.exit(main())
