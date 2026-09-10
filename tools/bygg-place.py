#!/usr/bin/env python3
"""Bygger en First Playable-place (.rbxlx) ur roblox/default.project.json.

Bakgrund: blockeraren i #162. Roblox-sidan hade tva halvor som aldrig mottes
— det inklistrade Studio-paketet byggde varlden utan gameplay, och
Rojo-projektet mappade gameplay utan varld. Tobias testade darfor miljo +
QA-panel i tron att det var First Playable, spawnade fel och kom inte in
genom nagon dorr.

Den har filen ger EN place dar bada finns. `rojo` ar den kanoniska
utvecklingsvagen, men rojo finns inte i den har miljon och ska inte behova
finnas hos den som bara vill granska: darfor genereras placen har, UR SAMMA
projektfil, sa att de tva inte kan glida ifran varandra. Projektfilen ar
sanningen; det har verktyget laser den och hittar inget eget pa.

    python3 tools/bygg-place.py [--ut <sokvag.rbxlx>] [--sha <exakt sha>]

Mappningen foljer Rojos egen semantik, for att en fil inte ska hamna som
ModuleScript har och Script i Rojo:

    kat/init.luau          -> ModuleScript med katalogens namn
    kat/init.server.luau   -> Script       med katalogens namn
    kat/init.client.luau   -> LocalScript  med katalogens namn
    fil.server.luau        -> Script
    fil.client.luau        -> LocalScript
    fil.luau               -> ModuleScript
"""
import argparse
import json
import pathlib
import subprocess
import sys
import xml.etree.ElementTree as ET

ROT = pathlib.Path(__file__).resolve().parent.parent
ROBLOX = ROT / "roblox"
PROJEKT = ROBLOX / "default.project.json"


def klass_for(fil: pathlib.Path) -> str:
    namn = fil.name
    if namn.endswith(".server.luau") or namn.endswith(".server.lua"):
        return "Script"
    if namn.endswith(".client.luau") or namn.endswith(".client.lua"):
        return "LocalScript"
    return "ModuleScript"


def stam(fil: pathlib.Path) -> str:
    """Instansnamnet for en fil: alla suffix bort, inte bara det sista."""
    n = fil.name
    for slut in (".server.luau", ".client.luau", ".server.lua", ".client.lua",
                 ".luau", ".lua"):
        if n.endswith(slut):
            return n[: -len(slut)]
    return fil.stem


class Nod:
    """En instans pa vag ut i XML:en."""

    def __init__(self, klass: str, namn: str, kalla: str | None = None):
        self.klass = klass
        self.namn = namn
        self.kalla = kalla
        self.barn: list["Nod"] = []


INIT = {
    "init.server.luau": "Script",
    "init.client.luau": "LocalScript",
    "init.luau": "ModuleScript",
    "init.server.lua": "Script",
    "init.client.lua": "LocalScript",
    "init.lua": "ModuleScript",
}


def fran_katalog(kat: pathlib.Path, namn: str) -> Nod:
    """En katalog blir en Folder, eller ett skript om den har en init-fil."""
    klass, kalla = "Folder", None
    for init, k in INIT.items():
        p = kat / init
        if p.is_file():
            klass, kalla = k, p.read_text(encoding="utf-8")
            break

    nod = Nod(klass, namn, kalla)
    for barn in sorted(kat.iterdir(), key=lambda q: q.name):
        if barn.name.startswith("."):
            continue
        if barn.is_dir():
            nod.barn.append(fran_katalog(barn, barn.name))
        elif barn.suffix in (".luau", ".lua") and barn.name not in INIT:
            nod.barn.append(Nod(klass_for(barn), stam(barn),
                                barn.read_text(encoding="utf-8")))
    return nod


def fran_sokvag(rel: str, namn: str) -> Nod:
    p = (ROBLOX / rel).resolve()
    if not p.exists():
        raise SystemExit(f"$path pekar pa nagot som inte finns: {rel}")
    if p.is_dir():
        return fran_katalog(p, namn)
    return Nod(klass_for(p), namn, p.read_text(encoding="utf-8"))


def bygg_trad(spec: dict, namn: str) -> Nod:
    """Ett trad-nod ur projektfilen. `$path` och `$className` som i Rojo."""
    if "$path" in spec:
        nod = fran_sokvag(spec["$path"], namn)
    else:
        nod = Nod(spec.get("$className", "Folder"), namn)

    for nyckel, varde in spec.items():
        if nyckel.startswith("$") or not isinstance(varde, dict):
            continue
        nod.barn.append(bygg_trad(varde, nyckel))
    return nod


# ── XML ────────────────────────────────────────────────────────────────
# CDATA far inte innehalla "]]>". Koden har ar full av `]]` (Luaus langa
# kommentarer), sa den sekvensen MASTE hanteras och inte antas bort.
def cdata(text: str) -> str:
    bitar = text.split("]]>")
    return "<![CDATA[" + "]]]]><![CDATA[>".join(bitar) + "]]>"


def xml_for(nod: Nod, raknare: list[int], djup: int) -> str:
    ind = "\t" * djup
    ref = raknare[0]
    raknare[0] += 1
    ut = [f'{ind}<Item class="{nod.klass}" referent="RBX{ref}">',
          f"{ind}\t<Properties>",
          f'{ind}\t\t<string name="Name">{nod.namn}</string>']
    if nod.kalla is not None:
        ut.append(f'{ind}\t\t<ProtectedString name="Source">'
                  + cdata(nod.kalla) + "</ProtectedString>")
    ut.append(f"{ind}\t</Properties>")
    for barn in nod.barn:
        ut.append(xml_for(barn, raknare, djup + 1))
    ut.append(f"{ind}</Item>")
    return "\n".join(ut)


def sha_nu() -> str:
    try:
        return subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROT,
                              capture_output=True, text=True,
                              check=True).stdout.strip()
    except Exception:
        return "OKAND"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ut", default=None)
    ap.add_argument("--sha", default=None)
    args = ap.parse_args()

    sha = args.sha or sha_nu()
    ut = pathlib.Path(args.ut) if args.ut else \
        ROBLOX / "releases" / f"first-playable-place-{sha[:7]}" / "UBRF-FirstPlayable.rbxlx"

    projekt = json.loads(PROJEKT.read_text(encoding="utf-8"))
    trad = projekt["tree"]

    rotnoder: list[Nod] = []
    for nyckel, varde in trad.items():
        if nyckel.startswith("$") or not isinstance(varde, dict):
            continue
        rotnoder.append(bygg_trad(varde, nyckel))

    #[[ Build-identiteten, punkt 9 i arbetsordern: builden ska SJALV kunna
    #   saga vilken head den kommer ur, sa att ingen kan testa fel paket av
    #   misstag. Preflight laser den och skriver den forst i outputen. ]]
    identitet = (
        "--!strict\n"
        "--[[ GENERERAD av tools/bygg-place.py. Andra inte har. ]]\n"
        "return {\n"
        f'\tsha = "{sha}",\n'
        f'\tmiljo_sha = "{sha}",\n'
        '\tvag = "tools/bygg-place.py ur roblox/default.project.json",\n'
        "}\n")
    for nod in rotnoder:
        if nod.namn == "ReplicatedStorage":
            nod.barn.append(Nod("ModuleScript", "UBRFBuild", identitet))

    raknare = [0]
    kropp = "\n".join(xml_for(n, raknare, 1) for n in rotnoder)
    doc = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
           'version="4">\n' + kropp + "\n</roblox>\n")

    #[[ Well-formedness ar inte samma sak som att Studio oppnar filen, men en
    #   trasig XML ar ett fel vi KAN fanga har — och da ska den aldrig lamnas
    #   ifran sig. ]]
    ET.fromstring(doc)

    ut.parent.mkdir(parents=True, exist_ok=True)
    ut.write_text(doc, encoding="utf-8")
    try:
        visa = ut.relative_to(ROT)
    except ValueError:
        visa = ut
    print(f"{visa}: {raknare[0]} instanser, {len(doc)} tecken")
    print(f"FIRST_PLAYABLE_SHA={sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
