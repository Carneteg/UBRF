#!/usr/bin/env python3
"""CI-PLACEN — #252 DEL C punkt 0.

Skapar EN place vid namn «UBRF CI» i universe `UBRF_UNIVERSE_ID` och
skriver ut dess placeId, sa att Tobias kan lagga in `UBRF_CI_PLACE_ID`.

    python3 tools/skapa-ci-place.py            # torrkor: bara inventering
    python3 tools/skapa-ci-place.py --skapa    # forsoker skapa

══ MATT BEGRANSNING, INTE ETT ANTAGANDE ═══════════════════════════════

Ordern sager «skapa den med Open Cloud Create Place-API:et». **Det
API:et finns inte dokumenterat.** Kontrollerat 2026-09-19 mot
create.roblox.com:

    GET    /cloud/v2/universes/{u}/places/{p}          Stable
    PATCH  /cloud/v2/universes/{u}/places/{p}          Stable
    POST   /universes/v1/{u}/places/{p}/versions       Beta  (publicering)
    POST   /cloud/v2/universes/{u}/places             — finns inte i referensen

Referenssidan for Place-resursen listar Get och Update, och
publiceringen ligger kvar pa den aldre v1-vagen. Ingen skapandeoperation
star i den stabila eller beta-dokumentationen.

Filen provar darfor de kandidatvagar som ANDA kan finnas odokumenterade,
EN gang var, och rapporterar exakt vad Roblox svarade. Gar ingen igenom
ar svaret «det gar inte har» — inte ett pahittat place-id, och inte en
grind som tyst pekas om mot startplacen.

══ SPARRAR ════════════════════════════════════════════════════════════

  1. Inventeringen korst FORST. Finns redan en place som heter «UBRF CI»
     skapas ingen ny; id:t skrivs ut och filen avslutar med 0.
  2. Utan `--skapa` ror filen ingenting.
  3. Startplacen (`rootPlaceId`) rors aldrig, av nagon vag.
  4. Nyckeln skrivs aldrig ut.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

APIS = "https://apis.roblox.com"
GAMES = "https://games.roblox.com"
DEVELOP = "https://develop.roblox.com"

NAMN = "UBRF CI"


def hamta(url, tak=30):
    with urllib.request.urlopen(url, timeout=tak) as svar:
        return json.loads(svar.read().decode("utf-8", "replace"))


def anrop(metod, url, nyckel, kropp=None):
    huvud = {"x-api-key": nyckel}
    data = None
    if kropp is not None:
        huvud["Content-Type"] = "application/json"
        data = json.dumps(kropp).encode("utf-8")
    begaran = urllib.request.Request(url, data=data, headers=huvud,
                                     method=metod)
    try:
        with urllib.request.urlopen(begaran, timeout=60) as svar:
            return svar.status, svar.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:                      # noqa: BLE001
        return 0, "natverksfel: %s" % e


def inventera(universe):
    """Vilka places finns i upplevelsen? Oautentiserat uppslag."""
    data = hamta("%s/v1/universes/%s/places?limit=100&sortOrder=Asc"
                 % (DEVELOP, universe))
    return data.get("data") or []


def startplace(universe):
    data = hamta("%s/v1/games?universeIds=%s" % (GAMES, universe))
    poster = data.get("data") or []
    if not poster:
        raise SystemExit("universe %s gav ingen post hos games-API:t"
                         % universe)
    return int(poster[0]["rootPlaceId"])


#[[ Kandidatvagarna. Ingen av dem ar dokumenterad; de provas en gang var
#   och utfallet redovisas rakt. Ordningen ar «nyast API forst». ]]
def kandidater(universe):
    return [
        ("POST", "%s/cloud/v2/universes/%s/places" % (APIS, universe),
         {"displayName": NAMN, "description": "Runtime-grind, #252 DEL C."}),
        ("POST", "%s/universes/v1/%s/places" % (APIS, universe),
         {"name": NAMN, "templatePlaceId": None}),
        ("POST", "%s/v1/universes/%s/places" % (DEVELOP, universe),
         {"name": NAMN}),
    ]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--skapa", action="store_true",
                    help="forsok faktiskt skapa placen")
    args = ap.parse_args()

    universe = os.environ.get("UBRF_UNIVERSE_ID", "").strip()
    if not universe.isdigit():
        print("FEL: UBRF_UNIVERSE_ID saknas eller ar inte ett tal")
        return 1

    rot = startplace(universe)
    platser = inventera(universe)
    print("universe %s — startplace %d" % (universe, rot))
    for p in platser:
        print("  place %s  %r%s" % (p.get("id"), p.get("name"),
                                    "  <- STARTPLACE" if int(p.get("id", 0)) == rot else ""))

    for p in platser:
        if str(p.get("name", "")).strip() == NAMN:
            print("")
            print("CI_PLACE_ID=%s" % p.get("id"))
            print("Placen finns redan. Ingen ny skapas.")
            return 0

    if not args.skapa:
        print("")
        print("Ingen place vid namn %r. Kor med --skapa for att forsoka." % NAMN)
        return 0

    nyckel = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not nyckel:
        print("FEL: ROBLOX_API_KEY saknas")
        return 1

    print("")
    print("Provar kandidatvagarna, en gang var:")
    for metod, url, kropp in kandidater(universe):
        visad = url.replace(universe, "<universe>")
        status, text = anrop(metod, url, nyckel, kropp)
        print("  %s %s -> HTTP %s  %s" % (metod, visad, status, text[:200]))
        if 200 <= status < 300:
            try:
                data = json.loads(text)
            except ValueError:
                data = {}
            nytt = data.get("placeId") or data.get("id")
            #[[ cloud/v2 svarar med `path` = universes/{u}/places/{id}. ]]
            if not nytt and isinstance(data.get("path"), str):
                nytt = data["path"].rsplit("/", 1)[-1]
            if nytt:
                if int(nytt) == rot:
                    print("")
                    print("STOPP: svaret pekar pa STARTPLACEN. Ingenting "
                          "anvands.")
                    return 1
                print("")
                print("CI_PLACE_ID=%s" % nytt)
                print("Lagg in det som repository variable UBRF_CI_PLACE_ID.")
                return 0
            print("    (svaret bar inget place-id — raknas inte som lyckat)")

    print("")
    print("INGEN VAG GICK IGENOM. Open Cloud har ingen dokumenterad")
    print("Create Place, och ingen av kandidatvagarna svarade med ett")
    print("place-id. CI-placen maste da skapas for hand EN gang:")
    print("")
    print("  Creator Dashboard -> Creations -> UBRF -> Places")
    print("  -> Create Place, namn: %r" % NAMN)
    print("")
    print("Lagg darefter in dess id som repository variable")
    print("UBRF_CI_PLACE_ID. Runtime-grinden pekas ALDRIG om mot")
    print("startplacen under tiden; den ar rod tills variabeln finns.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
