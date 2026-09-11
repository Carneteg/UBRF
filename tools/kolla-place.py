#!/usr/bin/env python3
"""FIRST_PLAYABLE_PREFLIGHT, den halva som gar att mata utan Studio.

Arbetsordern i #162 (15:37) vill ha en grind som ar gron pa exakt
candidate-SHA innan Tobias far en ny Studio-build. Runtime-halvan sitter i
roblox/src/server/Preflight.luau och matter den korande placen. Den har
halvan mater PAKETET: att den genererade .rbxlx verkligen innehaller allt
First Playable behover, i ratt tjanst och med kod i sig.

Punkt 10, fail closed: saknas nagot blir det exit 1 och `FIRST_PLAYABLE_
PREFLIGHT: FAIL` med vad som saknas. Franvaro av ett PASS ar inte ett PASS.

    python3 tools/kolla-place.py                  # bygger och mater en ny place
    python3 tools/kolla-place.py <fil.rbxlx>      # mater en PINNAD fil

Filargumentet fanns inte forst, och den luckan bet: jag korde
`kolla-place.py <release>` och rapporterade "PASS pa den genererade filen"
— men skriptet byggde en NY place i en temp-katalog och matte den. Svaret
var sant om koden och osant om filen jag pastod att jag matt. En pinnad
release ska kunna matas som den ar.
"""
import pathlib
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROT = pathlib.Path(__file__).resolve().parent.parent

#[[ Vad en First Playable-build MASTE ha. Sokvagarna ar tjanst/instans som de
#   ser ut i placen. Listan ar med flit explicit: det var just antagandet att
#   "paketet innehaller vad som behovs" som gjorde att en manniska fick
#   hitta felet framfor en dorr i Studio. ]]
KRAVS = [
    # 1a-1b: den delade koden och speldatan
    ("ReplicatedStorage/HorseCore", True),
    ("ReplicatedStorage/HorseCore/Pass", True),
    ("ReplicatedStorage/HorseCore/Preparation", True),
    ("ReplicatedStorage/HorseCore/Sparning", True),
    ("ReplicatedStorage/UBRFSpelData", True),
    ("ReplicatedStorage/UBRFSkotsel", True),
    ("ReplicatedStorage/UBRFSpel", True),
    ("ReplicatedStorage/Stallet", True),
    ("ReplicatedStorage/UBRFKomplex", True),
    #[[ LOKALISERINGEN (#162). Texttabellen och uppslaget. Tabellen SAKNADES
    #   i projektfilen: den fanns i repot, genererades av exportoren och
    #   lastes av hela bansviten -- men mappades aldrig in i placen, sa
    #   `require(RS.UBRFSprak)` kastade och `WaitForChild` blockerade i
    #   Studio. Ingen grind sag det, for bankbygget fogar ihop modulerna
    #   sjalvt. Raden finns for att "koden ar oversatt" och "spelaren ser
    #   oversattningen" ar tva olika pastaenden. ]]
    ("ReplicatedStorage/UBRFSprak", True),
    ("ReplicatedStorage/HorseCore/Sprak", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/Prompttext", True),
    # 9: build-identiteten
    ("ReplicatedStorage/UBRFBuild", True),
    # 1c: server-runtime
    ("ServerScriptService/Horse", True),
    ("ServerScriptService/Horse/SparService", True),
    ("ServerScriptService/Horse/StallService", True),
    ("ServerScriptService/Horse/HorseService", True),
    ("ServerScriptService/Horse/GameplayService", True),
    ("ServerScriptService/Horse/DorrService", True),
    ("ServerScriptService/Horse/Preflight", True),
    # 1e: varldsbyggaren i SAMMA build
    ("ServerScriptService/Varld/Anlaggningen", True),
    ("ServerScriptService/Varld/BuildKit", True),
    ("ServerScriptService/Varld/Geometri", True),
    # 7: klienten, inte bara i repot
    ("StarterPlayer/StarterPlayerScripts/Horse", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/KontrollHjalp", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/TouchControls", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/Input", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/PreparationController", True),
    ("StarterPlayer/StarterPlayerScripts/Horse/InteractionController", True),
]

KLASSKRAV = {
    "ServerScriptService/Horse": "Script",
    "StarterPlayer/StarterPlayerScripts/Horse": "LocalScript",
    "ServerScriptService/Varld/Anlaggningen": "ModuleScript",
    "ReplicatedStorage/HorseCore": "ModuleScript",
}


def namn(item) -> str:
    e = item.find("Properties/string[@name='Name']")
    return e.text if e is not None and e.text else ""


def hitta(rot, vag: str):
    nod = rot
    for bit in vag.split("/"):
        traff = None
        for it in nod.findall("Item"):
            if namn(it) == bit:
                traff = it
                break
        if traff is None:
            return None
        nod = traff
    return nod


def kallmappning() -> dict:
    """Modulnamn -> fil pa disk, ur samma projektfil som byggaren laser."""
    import json
    projekt = json.loads((ROT / "roblox" / "default.project.json").read_text(encoding="utf-8"))
    ut = {}

    def gang(nod, bas: pathlib.Path):
        for nyckel, varde in nod.items():
            if nyckel.startswith("$"):
                continue
            if isinstance(varde, dict) and "$path" in varde:
                vag = bas / varde["$path"]
                if vag.is_file():
                    ut[nyckel] = vag
                else:
                    #[[ En katalogs `init.*.luau` blir instansen med
                    #   KATALOGENS NAMN I PROJEKTFILEN, inte katalogens eget
                    #   namn pa disk: `src/server/init.server.luau` heter
                    #   `Horse` i placen. Forsta versionen tog mappnamnet och
                    #   letade efter "server" — som forstas inte fanns. ]]
                    for f in vag.rglob("*.luau"):
                        stam = f.stem.split(".")[0]
                        ut[nyckel if stam == "init" else stam] = f
            elif isinstance(varde, dict):
                gang(varde, bas)

    gang(projekt["tree"], ROT / "roblox")
    return ut


def main() -> int:
    given = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if given is not None and not given.is_file():
        print(f"FIRST_PLAYABLE_PREFLIGHT: FAIL — {given} finns inte")
        return 1
    with tempfile.TemporaryDirectory() as tmp:
        if given is not None:
            ut = given
            print(f"  Mater den PINNADE filen {given}")
        else:
            ut = pathlib.Path(tmp) / "prov.rbxlx"
            r = subprocess.run([sys.executable, str(ROT / "tools" / "bygg-place.py"),
                                "--ut", str(ut)], capture_output=True, text=True)
            if r.returncode != 0:
                print(r.stdout + r.stderr, end="")
                print("\nFIRST_PLAYABLE_PREFLIGHT: FAIL — placen gick inte att bygga")
                return 1

        rot = ET.parse(ut).getroot()
        #[[ Varje inbaddad modul och dess kallkod, for nyttolastjamforelsen. ]]
        kod_i_placen = {}
        for it in rot.iter("Item"):
            k = it.find("Properties/ProtectedString[@name='Source']")
            if k is not None:
                kod_i_placen[namn(it)] = k.text or ""
        fel = []
        for vag, med_kod in KRAVS:
            nod = hitta(rot, vag)
            if nod is None:
                fel.append(f"{vag} saknas")
                print(f"  FEL  {vag}")
                continue
            if med_kod and nod.find("Properties/ProtectedString[@name='Source']") is None \
                    and nod.get("class") != "Folder":
                fel.append(f"{vag} har ingen kod")
                print(f"  FEL  {vag}: instansen finns men ar tom")
                continue
            print(f"  OK   {vag}")

        for vag, klass in KLASSKRAV.items():
            nod = hitta(rot, vag)
            if nod is not None and nod.get("class") != klass:
                fel.append(f"{vag} ar {nod.get('class')}, vantade {klass}")
                print(f"  FEL  {vag}: {nod.get('class')}, vantade {klass}")
            elif nod is not None:
                print(f"  OK   {vag} ar {klass}")

        #[[ Varldsbyggaren requiras i en place. En ModuleScript som inte
        #   returnerar exakt ett varde kastar "Module code did not return
        #   exactly one value" — EFTER att den kort, sa varlden ser byggd ut
        #   i Output medan resten av servern aldrig startar. Det tog en
        #   fysisk session i Studio att hitta; det ska det inte gora igen. ]]
        varld0 = hitta(rot, "ServerScriptService/Varld/Anlaggningen")
        kod0 = varld0.find("Properties/ProtectedString[@name='Source']").text if varld0 is not None else ""
        rader = [l.strip() for l in (kod0 or "").splitlines() if l.strip()
                 and not l.strip().startswith("--")]
        if rader and rader[-1].startswith("return "):
            print("  OK   varldsbyggaren returnerar ett varde (requiras som ModuleScript)")
        else:
            fel.append("varldsbyggaren returnerar inget varde")
            print("  FEL  varldsbyggaren saknar `return` — require() kastar efter bygget")

        #[[ Punkt 2: exakt en avsedd spawn. Den byggs i runtime av
        #   Anlaggningen, sa har mats i stallet att KODEN for den finns med i
        #   paketet — en place utan den raden ger ingen spawn alls. ]]
        varld = hitta(rot, "ServerScriptService/Varld/Anlaggningen")
        kod = varld.find("Properties/ProtectedString[@name='Source']").text if varld is not None else ""
        for markor, vad in (('SpawnLocation', "spawnen"),
                            ('UBRFStart', "spawnens markning"),
                            ('UBRFDorr', "dorrbladens markning")):
            if markor in (kod or ""):
                print(f"  OK   varldsbyggaren bygger {vad} ({markor})")
            else:
                fel.append(f"{vad} byggs inte ({markor} saknas i Anlaggningen)")
                print(f"  FEL  varldsbyggaren bygger inte {vad}")

        #[[ PUNKT 9: place-format-smoke. Well-formed XML rackte inte —
        #   forsta filen oppnade inte i Studio, och det som saknades var de
        #   tva <External>-raderna och en Workspace. Det mats nu, sa att
        #   samma avvikelse inte kan levereras igen. ]]
        txt = ut.read_text(encoding="utf-8")
        ext = txt.count("<External>")
        if ext >= 2:
            print(f"  OK   place-format: {ext} <External>-rader som i Roblox egen XML")
        else:
            fel.append(f"place-format: {ext} <External>-rader, vantade 2")
            print(f"  FEL  place-format: {ext} <External>-rader, vantade 2")

        tjanster = [namn(it) for it in rot.findall("Item")]
        for kravd in ("Workspace", "ReplicatedStorage", "ServerScriptService", "StarterPlayer"):
            if kravd in tjanster:
                print(f"  OK   place-format: tjansten {kravd} finns")
            else:
                fel.append(f"place-format: tjansten {kravd} saknas")
                print(f"  FEL  place-format: tjansten {kravd} saknas")

        #[[ Drift-skydd: spelbarhetsgrinden mater boxpromptens rackvidd mot
        #   talet 8, som StallService satter. Andras det dar utan att grinden
        #   foljer med mater grinden fel varld. ]]
        st = (ROT / "roblox" / "src" / "server" / "StallService.luau").read_text(encoding="utf-8")
        if "MaxActivationDistance = 8" in st:
            print("  OK   boxpromptens rackvidd ar 8 studs, som spelbarhetsgrinden antar")
        else:
            fel.append("StallService.MaxActivationDistance ar inte 8 — spelbarhetsgrinden matar fel")
            print("  FEL  StallService.MaxActivationDistance ar inte langre 8")

        #[[ NYTTOLASTEN AR SAMMA KOD SOM GRINDARNA KORDE.

        #   Grindarna mater kallan pa disk; spelaren far nyttolasten i
        #   .rbxlx-filen. Att de ar samma sak har varit ett ANTAGANDE, och
        #   just det antagandet bar hela raden "E2E ar gron, alltsa bar
        #   marken" — en place byggd ur en aldre eller halvsparad kallfil
        #   hade passerat varje matning anda.
        #
        #   Jamforelsen ar ordagrann pa varje inbaddad modul mot filen den
        #   kom ur. Ett tecken isar och det ar inte samma bygge. ]]
        avvikande = []
        kallor = kallmappning()
        jamforda = 0
        for modul, kalla in sorted(kallor.items()):
            if modul not in kod_i_placen:
                avvikande.append(f"{modul}: finns inte i placen")
                continue
            jamforda += 1
            i_filen = kalla.read_text(encoding="utf-8")
            if kod_i_placen[modul] != i_filen:
                avvikande.append(f"{modul}: {len(kod_i_placen[modul])} tecken i placen mot "
                                 f"{len(i_filen)} i {kalla.relative_to(ROT)}")
        if avvikande:
            for a in avvikande:
                fel.append("nyttolasten avviker fran kallan — " + a)
                print(f"  FEL  nyttolast {a}")
        else:
            print(f"  OK   nyttolasten ar ordagrant samma kod som grindarna korde "
                  f"({jamforda} moduler jamforda)")

    if fel:
        print(f"\nFIRST_PLAYABLE_PREFLIGHT: FAIL — {len(fel)} saknas:")
        for f in fel:
            print(f"  · {f}")
        print("STOPP: presentera inte den har builden som First Playable.")
        return 1
    print("\nFIRST_PLAYABLE_PREFLIGHT: PASS (pakethalvan — runtime matas i Studio)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
