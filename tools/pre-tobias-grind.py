#!/usr/bin/env python3
"""PRE_TOBIAS_FIRST_PLAYABLE_GATE — samlingsgrinden före en Studio-build.

Bindande processändring på PR #162 (05:42). Tobias hittade void death,
dörrar in i bås, tomt stall, saknad utrustning, fel instruktion, gräs inomhus
och en saknad kanonisk skylt — fel som är för grundläggande för att nå ett
första speltest. Den här grinden är den barriären.

    python3 tools/pre-tobias-grind.py
    python3 tools/pre-tobias-grind.py --place <fil.rbxlx>

Den är en SAMLINGSGRIND: den blir grön bara om varje undergrind blir grön.
En undergrind som inte går att köra räknas som RÖD, aldrig som hoppad — det
var just frånvaron av ett svar som blev ett antaget PASS förut.

Utdata:
    qa/pre-tobias/WORLD_MANIFEST.json   världen som den faktiskt byggs
    qa/pre-tobias/RAPPORT.md            release evidence bundle (punkt 8)

ARTEFAKTFRÅGAN, redovisad som det den är: ordern vill att kontrollerna läser
den genererade `.rbxlx` eller ett manifest deriverat ur den. Placen är
script-only — 62 instanser, noll geometri — så det finns ingen geometri i
XML:en att läsa. Kedjan är i stället `kolla-place.py`, som visar att de 54
inbäddade modulerna är byte-identiska mot disk, plus att grindarna kör exakt
de modulerna. Det ger samma bevisvärde, men det är ett ARGUMENT och inte en
mätning ur filen, och det står så både här och i rapporten.
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import re
import subprocess
import sys

ROT = pathlib.Path(__file__).resolve().parent.parent
UT = ROT / "qa" / "pre-tobias"

BORJAR = "### WORLD_MANIFEST_BORJAR ###"
SLUTAR = "### WORLD_MANIFEST_SLUTAR ###"


def kor(cmd, cwd=ROT):
    """Kör och ge (ok, utdata). Ett krascher är RÖTT, inte hoppat."""
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=900)
        return p.returncode == 0, (p.stdout or "") + (p.stderr or "")
    except Exception as e:                                   # noqa: BLE001
        return False, f"gick inte att köra: {e}"


def spec(namn):
    """Bygg och kör EN Luau-spec. Bygget hör till körningen: kör man bara
    .build/ rapporterar man om en gammal fil, inte om koden på disk."""
    ok, logg = kor([sys.executable, "tests/build.py", f"tests/{namn}.spec.luau"],
                   cwd=ROT / "roblox")
    if not ok:
        return False, "BYGGET FÖLL\n" + logg
    ok, logg = kor(["luau", f"tests/.build/{namn}.spec.luau"], cwd=ROT / "roblox")
    #[[ Samma tre krav som kor.sh: exitkod 0, inga FEL-rader, och en slutrad.
    #   Exitkoden är den enda som inte går att lura genom att skriva rätt text. ]]
    fel = [r for r in logg.splitlines() if r.strip().startswith("FEL")]
    slut = ("alla gröna" in logg) or ("Alla mätningar gick igenom" in logg)
    return (ok and not fel and slut), logg


#[[ Undergrindarna, med ordens egna namn. Varje post är
#   (GRIND, beskrivning, [körningar]) och alla körningar måste bli gröna. ]]
def grindarna(place):
    kp = [sys.executable, "tools/kolla-place.py"] + ([place] if place else [])
    return [
        ("FIRST_PLAYABLE_PREFLIGHT", "placen innehåller allt First Playable behöver",
         [("kolla-place", lambda: kor(kp)), ("forstaplayable", lambda: spec("forstaplayable"))]),
        ("END_TO_END_PLAYABILITY_GATE", "hela spelresan går att gå",
         [("spelbarhet", lambda: spec("spelbarhet"))]),
        ("NO_VOID_BASIC_PLAYABILITY_GATE", "ingen spelbar yta utan stöd under",
         [("mark", lambda: spec("mark"))]),
        ("BUILDING_TOPOLOGY_TRAVERSAL_GATE", "varje portal mynnar i rätt zon",
         [("topologi", lambda: spec("topologi"))]),
        ("PHYSICAL_WORLD_COHERENCE_GATE", "världen håller ihop fysiskt",
         [("varldskoherens", lambda: spec("varldskoherens"))]),
        ("HANDIGHET_GATE", "världen är högerhänt på båda ytorna",
         [("handighet", lambda: spec("handighet")),
          ("handighetsgrind", lambda: kor(["node", "tools/handighetsgrind.mjs"]))]),
        ("ROSTER_PHYSICAL_PRESENCE_GATE", "hela rostern står fysiskt i stallet",
         [("roster", lambda: spec("roster"))]),
        ("INSTRUCTION_CONTEXT_GATE", "instruktionen följer state och zon",
         [("varldshud", lambda: spec("varldshud"))]),
        ("WORLD_FIDELITY_ANCHOR_GATE", "de verifierade ankarmåtten och skyltarna stämmer",
         [("kolla-ankare", lambda: kor(["node", "tools/kolla-ankare.mjs"])),
          ("kolla-nyckelbilder", lambda: kor([sys.executable, "tools/kolla-nyckelbilder.py"]))]),
    ]


def manifest():
    """WORLD_MANIFEST ur den byggda världen (punkt 3)."""
    ok, logg = kor([sys.executable, "tests/build.py", "tests/varldsmanifest.spec.luau"],
                   cwd=ROT / "roblox")
    if not ok:
        return None, "BYGGET FÖLL\n" + logg
    ok, logg = kor(["luau", "tests/.build/varldsmanifest.spec.luau"], cwd=ROT / "roblox")
    if BORJAR not in logg or SLUTAR not in logg:
        return None, logg
    rå = logg.split(BORJAR, 1)[1].split(SLUTAR, 1)[0]
    try:
        return json.loads(rå), logg
    except json.JSONDecodeError as e:
        return None, f"manifestet är inte giltig JSON: {e}\n{logg}"


def sha256(p: pathlib.Path):
    h = hashlib.sha256()
    with p.open("rb") as f:
        for bit in iter(lambda: f.read(1 << 16), b""):
            h.update(bit)
    return h.hexdigest()


def git(*a):
    ok, ut = kor(["git"] + list(a))
    return ut.strip() if ok else "okänd"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--place", help="pinnad .rbxlx att mäta i stället för en ny")
    ap.add_argument("--snabb", action="store_true",
                    help="hoppa över manifestet (för felsökning av grindarna)")
    arg = ap.parse_args()

    print("PRE_TOBIAS_FIRST_PLAYABLE_GATE")
    print("=" * 64)

    resultat, allt_gront = [], True
    for namn, vad, korningar in grindarna(arg.place):
        delar, gront = [], True
        for delnamn, f in korningar:
            ok, logg = f()
            delar.append((delnamn, ok, logg))
            gront = gront and ok
        allt_gront = allt_gront and gront
        resultat.append((namn, vad, gront, delar))
        print(f"{'PASS' if gront else 'FAIL'}  {namn}")
        for delnamn, ok, logg in delar:
            print(f"        {'ok ' if ok else 'FEL'} {delnamn}")
            if not ok:
                for r in logg.splitlines()[-8:]:
                    print(f"            {r}")

    man, manlogg = (None, "hoppad med --snabb") if arg.snabb else manifest()
    if not arg.snabb:
        if man is None:
            allt_gront = False
            print("FAIL  WORLD_MANIFEST kunde inte byggas")
            for r in manlogg.splitlines()[-8:]:
                print(f"            {r}")
        else:
            print(f"PASS  WORLD_MANIFEST  {man['byggda_delar']} delar, "
                  f"{len(man['portaler'])} portaler, {man['hastar']['antal']} hästar")

    UT.mkdir(parents=True, exist_ok=True)
    if man is not None:
        (UT / "WORLD_MANIFEST.json").write_text(json.dumps(man, indent=2, ensure_ascii=False) + "\n")

    skriv_rapport(resultat, man, allt_gront, arg.place)
    print("=" * 64)
    print(f"PRE_TOBIAS_FIRST_PLAYABLE_GATE: {'PASS' if allt_gront else 'FAIL'}")
    print(f"rapport: {(UT / 'RAPPORT.md').relative_to(ROT)}")
    if not allt_gront:
        print("Ingen ny .rbxlx får sanktioneras för Tobias.")
    return 0 if allt_gront else 1


def rad(namn, varde):
    return f"| {namn} | {varde} |"


def skriv_rapport(resultat, man, allt_gront, place):
    """Release evidence bundle, punkt 8 i ordern."""
    huvud = git("rev-parse", "HEAD")
    gren = git("rev-parse", "--abbrev-ref", "HEAD")
    #[[ Grindens EGEN utdata räknas inte som en smutsig arbetskatalog. Den
    #   skrivs av den här körningen, varje gång — räknades den med stod
    #   varningen alltid tänd, och en varning som alltid lyser är ingen
    #   varning. Allt annat räknas. ]]
    smutsigt = "\n".join(r for r in git("status", "--porcelain").splitlines()
                         if "qa/pre-tobias" not in r).strip()
    r = []
    r.append("# PRE_TOBIAS_FIRST_PLAYABLE_GATE — release evidence bundle\n")
    r.append(f"> **{'PASS' if allt_gront else 'FAIL'}** — genererad "
             f"{datetime.datetime.now(datetime.timezone.utc):%Y-%m-%d %H:%M} UTC av "
             "`tools/pre-tobias-grind.py`.\n")
    if not allt_gront:
        r.append("> **Ingen ny `.rbxlx` får sanktioneras för Tobias.**\n")
    if smutsigt:
        r.append("> ⚠️ Arbetsträdet har ocommittade ändringar — rapporten gäller "
                 "alltså inte källkommiten ensam.\n")

    r.append("\n## Identitet\n")
    r.append("| | |\n|---|---|")
    r.append(rad("source SHA", f"`{huvud}`"))
    r.append(rad("gren", f"`{gren}`"))
    if place:
        p = pathlib.Path(place)
        if p.exists():
            r.append(rad("mätt `.rbxlx`", f"`{p}`"))
            r.append(rad("`.rbxlx` SHA256", f"`{sha256(p)}`"))
            r.append(rad("storlek", f"{p.stat().st_size} byte"))
    else:
        r.append(rad("release commit", "ingen ny release byggd i den här körningen"))
        r.append(rad("`.rbxlx` SHA256", "— ingen fil mätt, kör med `--place`"))

    r.append("\n## Undergrindarna\n")
    r.append("| Grind | Vad den mäter | Utfall |\n|---|---|---|")
    for namn, vad, gront, delar in resultat:
        stod = ", ".join(f"{d}{'' if ok else ' ❌'}" for d, ok, _ in delar)
        r.append(f"| `{namn}` | {vad} | {'**PASS**' if gront else '**FAIL**'} ({stod}) |")

    if man:
        r.append("\n## World manifest summary\n")
        r.append("| | |\n|---|---|")
        r.append(rad("byggda delar", man["byggda_delar"]))
        r.append(rad("marklager", f"{man['mark']['barande']} bärande, "
                                  f"{man['mark']['dekor']} dekor"))
        r.append(rad("fysiska hästar", f"{man['hastar']['antal']} / "
                                       f"{man['hastar']['kanoniska']}"))
        r.append(rad("utrustningsplatser", len(man["utrustning"])))
        r.append(rad("skyltar", ", ".join(s["text"] for s in man["skyltar"]) or "inga"))
        r.append(rad("spawn", f"({man['spawn']['x']}, {man['spawn']['y']}) mot "
                              f"{man['spawn']['motdorr']}"))

        r.append("\n### Kritiska portaler\n")
        r.append("| Byggnad | Sida | Typ | Bredd | Läge |\n|---|---|---|---|---|")
        for p in man["portaler"]:
            r.append(f"| {p['byggnad']} | {p['sida']} | {p['typ']} | "
                     f"{p['bredd']:.2f} m | ({p['x']:.1f}, {p['y']:.1f}) |")
        if man["icke_passager"]:
            r.append("\n**Deklarerade icke-passager** — öppningar som med flit "
                     "INTE går att gå igenom:\n")
            for p in man["icke_passager"]:
                r.append(f"- `{p['byggnad']} {p['sida']} {p['typ']}` — {p['skal']}")
        if man["rekvisita_som_saknas"]:
            r.append("\n### Rekvisita kanon har men världen inte bygger\n")
            r.append(", ".join(f"{x['typ']}×{x['antal']}"
                               for x in man["rekvisita_som_saknas"]))

    r.append("\n## Kvarvarande NOT_TESTED\n")
    r.append("Ordern, punkt 8: här får bara verklig Roblox-motor och spelkänsla stå "
             "— aldrig statiskt synliga världsproblem.\n")
    r.append("- att `.rbxlx` **öppnar** i Studio och att Play startar")
    r.append("- spelkänsla, kamera, animation och hästbeteende i motorn")
    r.append("- fysisk input: tangentbord, handkontroll, iPad")
    r.append("- performance med full värld och hela rostern")
    r.append("- DataStore i skarpt läge, och revisionskollisionen")
    r.append("- visuell granskning av ROBLOX-världen; `CHATGPT_VISUAL_PASS` gäller "
             "webbrenderingen, inte den här")

    r.append("\n## Artefaktkedjan, uttryckligen\n")
    r.append("Placen är script-only: 62 instanser, noll geometri. Det finns ingen "
             "geometri i XML:en att läsa, så kedjan är `tools/kolla-place.py` — de "
             "inbäddade modulerna byte-identiska mot disk — plus att grindarna kör "
             "exakt de modulerna. Samma bevisvärde, men det är ett **argument** och "
             "inte en mätning ur filen.\n")

    (UT / "RAPPORT.md").write_text("\n".join(r) + "\n")


if __name__ == "__main__":
    sys.exit(main())
