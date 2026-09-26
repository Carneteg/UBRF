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
    fil.rbxmx              -> modellens egna instanser, oforandrade

MODELLER (#264 R3). Byggaren las forst BARA Luau, och da gick ingen
hastmodell att fa in i den reproducerbara vagen — bara ladhastar. Skalet
som angavs, "en modell ar inte text", holl inte: .rbxmx AR text, samma
XML som den har filen sjalv skriver.

Det som faktiskt kravs ar att BEVARA modellens struktur: mesh- och
textur-id, transformer, joints, PrimaryPart och alla interna referenser.
Referenserna ar det svara — bada filerna numrerar sina instanser, och tva
RBX0 i samma dokument pekar pa varandras saker. Se `las_modell`.
"""

#[[ PEP 604 (`str | None`) kraver Python >= 3.10. Den har maskinen kor
#   3.7.9, och da foll HELA den lokala grindkedjan pa en syntaxrad:
#
#       TypeError: unsupported operand type(s) for |: 'type' and 'NoneType'
#       FIRST_PLAYABLE_PREFLIGHT: FAIL - placen gick inte att bygga
#
#   Meddelandet ljog: placen gick utmarkt att bygga, tolken kunde bara
#   inte lasa annoteringen. CI kor 3.12 och var gron, sa felet syntes
#   bara for den som korde grinden lokalt — alltsa precis den som
#   behovde svaret.
#
#   `from __future__ import annotations` gor varje annotering till en
#   strang som aldrig evalueras. Den finns sedan 3.7.0, andrar ingen
#   korning, och later filen behalla den modernare skrivningen. Samma
#   skal som Gate 0 angav for `kolla-generisk-hast.py`: en grind man
#   inte kan lita pa lokalt ar varre an ingen grind. ]]
from __future__ import annotations

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
    """En instans pa vag ut i XML:en.

    `radxml` ar en fardig <Item>-strang som skrivs ut ORORD. Den anvands
    for modeller: deras egenskaper ska ga igenom exakt som de lag, inte
    tolkas om av den har filen.
    """

    def __init__(self, klass: str, namn: str, kalla: str | None = None,
                 radxml: str | None = None):
        self.klass = klass
        self.namn = namn
        self.kalla = kalla
        self.radxml = radxml
        #[[ Dokumentnivasaker som modellen bar med sig. Se `las_modell`. ]]
        self.delade: dict[str, str] = {}
        self.meta: dict[str, str] = {}
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


#[[ -- MODELLER UR .rbxmx ------------------------------------------
#
#   Tva dokument, tva numreringar. Modellfilen har sina egna
#   `referent="RBX0"` och sina `<Ref>`-egenskaper som pekar pa dem --
#   Motor6D.Part0/Part1, Weld.C0, Model.PrimaryPart. Klistras de in ratt
#   av pekar de pa VARA instanser i stallet, och en haststomme blir en
#   hog lossryckta delar med joints till slumpvisa skript.
#
#   Darfor far varje modellfil ett eget namnrum pa sina referenter, och
#   varje <Ref> som pekar INOM filen skrivs om till samma namnrum. En
#   <Ref> som pekar utat (`null`) lamnas i fred.
#
#   Vad som INTE bars igenom, med flit:
#     . skript i modellen -- ordern forbjuder oreviderad korbar asset-kod,
#       och en modell ska vara utseende, inte beteende,
#     . <SharedString>-block bars numera MED -- se nedan.
#
#   DE DELADE STRANGARNA, och varfor avvisandet inte holl. Forst vagrade
#   byggaren varje modell som anvande dem, med motiveringen att de bor i
#   dokumentets egen tabell. Den riktiga k3 har 169 av dem, och da var
#   motiveringen inte ett skal att saga nej utan en BESKRIVNING AV VAD
#   SOM MASTE GORAS.
#
#   Sa har ser de ut i filen:
#
#     <SharedStrings>                       <- tabellen, pa dokumentniva
#       <SharedString md5="yuZ...">..</SharedString>
#     </SharedStrings>
#     ...inne i en instans:
#       <SharedString name="PhysicalConfigData">yuZ...</SharedString>
#
#   Alltsa: hanvisningarna ligger INNE i instanserna och foljer med
#   <Item> av sig sjalva; det som saknas ar tabellen. I k3 ar det 167
#   hanvisningar (Tags, AeroMeshData, PhysicalConfigData, ModelMeshData,
#   SlimHash) mot 2 poster.
#
#   Nycklarna ar INNEHALLSHASHAR, sa tva modeller med samma data far
#   samma nyckel -- det ar avsiktlig deduplicering, inte en krock.
#   Samma nyckel med OLIKA innehall vore daremot ett riktigt fel och
#   avvisas.
#
#   Att bara slanga tabellen hade inte synts: PhysicalConfigData ar
#   kollisionsdata, och en hast med tappad kollision ser likadan ut i
#   tradet. ]]
SKRIPTKLASSER = {"Script", "LocalScript", "ModuleScript"}


def _modellnamnrum(rel: str) -> str:
    """Ett stabilt, kollisionsfritt prefix per modellfil."""
    rent = "".join(c if c.isalnum() else "_" for c in rel)
    return "M_" + rent[-32:]


def las_modell(p: pathlib.Path, rel: str, namn: str) -> Nod:
    rot = ET.fromstring(p.read_text(encoding="utf-8"))

    #[[ Tabellen ligger pa dokumentniva och foljer inte med <Item>. ]]
    tabell = {}
    for t in rot.findall("SharedStrings"):
        for e in t.findall("SharedString"):
            nyckel = e.get("md5")
            if nyckel is None:
                raise SystemExit(f"{rel}: en <SharedString> saknar md5.")
            tabell[nyckel] = e.text or ""

    poster = [e for e in rot if e.tag == "Item"]
    if len(poster) != 1:
        raise SystemExit(
            f"{rel}: forvantade EN rotinstans, hittade {len(poster)}.")

    for e in poster[0].iter("Item"):
        k = e.get("class")
        if k in SKRIPTKLASSER:
            raise SystemExit(
                f"{rel}: modellen innehaller ett {k} -- korbar asset-kod "
                "bars inte in av byggaren.")

    rymd = _modellnamnrum(rel)
    egna = {}
    for e in poster[0].iter("Item"):
        r = e.get("referent")
        if r:
            egna[r] = f"{rymd}_{r}"
    for e in poster[0].iter("Item"):
        r = e.get("referent")
        if r:
            e.set("referent", egna[r])
    for ref in poster[0].iter("Ref"):
        v = (ref.text or "").strip()
        if v in egna:
            ref.text = egna[v]
        elif v and v != "null":
            raise SystemExit(
                f"{rel}: en <Ref> pekar utanfor modellen ({v}). "
                "Yttre referenser bars inte in.")

    #[[ Namnet i projektfilen vinner, precis som for en Luau-fil: det ar
    #   sokvagen i DataModel som kod och prov refererar. ]]
    for prop in poster[0].findall("./Properties/string"):
        if prop.get("name") == "Name":
            prop.text = namn
            break

    #[[ VARJE hanvisning maste ha en post. En som saknas ar en tappad
    #   textur eller kollisionsmodell, och den sortens fel syns inte i
    #   tradet -- bara i spelet. ]]
    saknade = set()
    for e in poster[0].iter("SharedString"):
        if e.get("name") is None:
            continue
        v = (e.text or "").strip()
        if v and v not in tabell:
            saknade.add(v)
    if saknade:
        raise SystemExit(
            f"{rel}: {len(saknade)} delad(e) strang(ar) hanvisas utan att "
            "finnas i filens egen tabell.")

    #[[ Metan hor till dokumentet, inte till <Item>. `ExplicitAutoJoints`
    #   styr om motorn skapar joints automatiskt vid inlasning; tappas
    #   den kan en riggad modell fa joints den inte ska ha. ]]
    meta = {}
    for m in rot.findall("Meta"):
        if m.get("name"):
            meta[m.get("name")] = m.text or ""

    xml = ET.tostring(poster[0], encoding="unicode")
    nod = Nod(poster[0].get("class") or "Model", namn, None, xml)
    nod.delade = tabell
    nod.meta = meta
    return nod


def fran_sokvag(rel: str, namn: str) -> Nod:
    p = (ROBLOX / rel).resolve()
    if not p.exists():
        raise SystemExit(f"$path pekar pa nagot som inte finns: {rel}")
    if p.is_dir():
        return fran_katalog(p, namn)
    if p.suffix == ".rbxmx":
        return las_modell(p, rel, namn)
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
    #[[ En modell skrivs ut som den lag. Den rakas in i instansraknaren
    #   sa att artefaktens storlek stammer, men den numreras inte om:
    #   `las_modell` har redan gett den ett eget namnrum. ]]
    if nod.radxml is not None:
        raknare[0] += sum(1 for _ in ET.fromstring(nod.radxml).iter("Item"))
        return ind + nod.radxml
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


def _xml_text(t: str) -> str:
    """Text i ett XML-element. Tabellen bar base64, men undanta anda."""
    return (t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def samla_dokumentniva(rotnoder: list[Nod]) -> tuple[dict, dict]:
    """Delade strangar och Meta ur alla modeller i tradet.

    Nycklarna ar innehallshashar: samma nyckel med samma innehall ar
    deduplicering och helt riktigt. Samma nyckel med OLIKA innehall vore
    en tyst forvanskning av nagons kollisionsdata, och avvisas.
    """
    delade: dict[str, str] = {}
    meta: dict[str, str] = {}

    def ga(n: Nod) -> None:
        for nyckel, varde in n.delade.items():
            if nyckel in delade and delade[nyckel] != varde:
                raise SystemExit(
                    f"delad strang {nyckel!r} forekommer med TVA olika "
                    "innehall -- en av dem skulle skrivas over tyst.")
            delade[nyckel] = varde
        for nyckel, varde in n.meta.items():
            if nyckel in meta and meta[nyckel] != varde:
                raise SystemExit(
                    f"<Meta name={nyckel!r}> forekommer med tva olika "
                    f"varden: {meta[nyckel]!r} och {varde!r}.")
            meta[nyckel] = varde
        for b in n.barn:
            ga(b)

    for n in rotnoder:
        ga(n)
    return delade, meta


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
    #[[ Filnamnet halls fritt fran bindestreck och mellanslag. Nar Tobias
    #   forsta place-fil hamnade pa hans skrivbord blev den "UBRFFirstPlayable
    #   .rbxlx" pa vagen, och en fil man tror sig ha ar inte samma fil som den
    #   man har. Da ar det enklare att heta samma sak hela vagen. ]]
    ut = pathlib.Path(args.ut) if args.ut else \
        ROBLOX / "releases" / f"first-playable-place-{sha[:7]}" / "UBRFFirstPlayable.rbxlx"

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
    #[[ #171: identiteten ar numera en MAPPAD fil, roblox/game/UBRFBuild.luau,
    #   genererad av tools/bygg-identitet.py. Da kommer den in via tradet
    #   ovan som vilken annan modul som helst, och den har raden skulle lagga
    #   dit en ANDRA med samma namn.
    #
    #   Skalet till att den mappades: en Rojo-synkad place fick forr ingen
    #   identitet alls, sa nagon lade dit en for hand. Den blev kvar och pekade
    #   pa en head 44 commits gammal medan punkt 9 lyste gront.
    #
    #   Raden star kvar for den place som byggs ur en gren DAR mappningen inte
    #   finns — men bara da, och identiteten far inte langre hittas pa nar
    #   filen finns. ]]
    for nod in rotnoder:
        if nod.namn == "ReplicatedStorage" and \
                not any(b.namn == "UBRFBuild" for b in nod.barn):
            nod.barn.append(Nod("ModuleScript", "UBRFBuild", identitet))

    #[[ En place MASTE ha en Workspace. Projektfilen namner ingen, for Rojo
    #   behover den inte — men en fil som ska OPPNAS av Studio ar inte samma
    #   sak som ett synktrad. Anlaggningen bygger sedan sina modeller i den
    #   har Workspacen vid serverstart. ]]
    if not any(n.namn == "Workspace" for n in rotnoder):
        rotnoder.insert(0, Nod("Workspace", "Workspace"))

    #[[ Dokumentnivan samlas FORE kroppen skrivs: tabellen maste finnas i
    #   samma dokument som hanvisningarna, annars ar de lika tappade som
    #   om de aldrig burits med. ]]
    delade, meta = samla_dokumentniva(rotnoder)
    metarader = "".join(
        f'\t<Meta name="{k}">{_xml_text(v)}</Meta>\n'
        for k, v in sorted(meta.items()))
    if delade:
        deladerader = "\n\t<SharedStrings>\n" + "".join(
            f'\t\t<SharedString md5="{k}">{_xml_text(v)}</SharedString>\n'
            for k, v in sorted(delade.items())) + "\t</SharedStrings>"
    else:
        deladerader = ""

    raknare = [0]
    kropp = "\n".join(xml_for(n, raknare, 1) for n in rotnoder)
    #[[ De tva <External>-raderna star i BORJAN av varje XML-fil Roblox sjalvt
    #   skriver. Vi genererar filen for hand, och en fil som avviker fran
    #   formatet ar en fil Studio kan vagra lasa — sa den ska inte avvika. ]]
    doc = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
           'version="4">\n'
           + metarader
           + "\t<External>null</External>\n"
           "\t<External>nil</External>\n"
           #[[ INGEN radbrytning efter </roblox>. Roblox place-ingester
           #   avvisar skrapbytes EFTER dokumentelementet, och en enda
           #   avslutande radbrytning racker: HTTP 400 {"code":
           #   "InvalidRequest","message":"Invalid Content stream"}.
           #
           #   Matt at bada hallen i #264, run 35576448203: var artefakt
           #   utan byten gav 200, och en Roblox-accepterad fil MED byten
           #   gav 400. Felmeddelandet pekar utat, pa strommen — inte pa
           #   nagot i innehallet. Lagg inte tillbaka radbrytningen for
           #   att filen «ser ostadad ut» i en editor.
           #
           #   De bevarade placerna under roblox/releases/ byggdes fore
           #   fixen och slutar med radbrytning. De ska INTE byggas om:
           #   historisk evidens ar historisk, och kolla-evidens-place.py
           #   vaktar deras hashar. ]]
           + kropp + deladerader + "\n</roblox>")

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
