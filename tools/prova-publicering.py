#!/usr/bin/env python3
"""KONTROLLPROV for #264: skiljer trasig artefakt fran trasig API-vag.

Runtime-grinden nadde Open Cloud for forsta gangen i job 106218507201 och
fick HTTP 400 {"code":"InvalidRequest","message":"Invalid Content stream"}.
Lokalt ar artefakten giltig XML med samma envelope som de bevarade
placerna, sa fragan gar inte att stanga utan nyckeln — och nyckeln finns
bara i CI.

Provet postar en MINIMAL men giltig place till SAMMA place, genom samma
endpoint, samma auth och samma rabyte-POST som `tools/runtime-grind.py`.
Den minimala filen ar med flit en BYTE-EXAKT PREFIX av vad
`tools/bygg-place.py` skriver: samma rotelement, samma tva <External>,
samma Workspace-Item. Skiljer sig utfallet ar skillnaden alltsa
INNEHALLET, inte formatet.

  minimal OK  + full FAIL  -> ARTIFACT_SPECIFIC
  minimal FAIL (samma fel) -> API_OR_SETUP
  nagot annat              -> INCONCLUSIVE

DIAGNOSTIK, INTE EN GRIND. Filen ar tillfallig och ska tas bort nar
fragan ar besvarad. Den ror aldrig startplacen: samma hardstopp som
runtime-grind.py:357-361 star ocksa har.
"""
import json
import os
import sys
import urllib.error
import urllib.request

APIS = "https://apis.roblox.com"
GAMES = "https://games.roblox.com"

#[[ Byte-exakt samma envelope som tools/bygg-place.py:239-245 skriver,
#   plus dess Workspace-Item. Tabbar, radbrytningar och attributordning
#   ar med flit identiska. ]]
MINIMAL = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
    'version="4">\n'
    "\t<External>null</External>\n"
    "\t<External>nil</External>\n"
    '\t<Item class="Workspace" referent="RBX0">\n'
    "\t\t<Properties>\n"
    '\t\t\t<string name="Name">Workspace</string>\n'
    "\t\t</Properties>\n"
    "\t</Item>\n"
    "</roblox>\n"
)


def krav(namn):
    varde = os.environ.get(namn, "").strip()
    if not varde:
        print("PROV: AVBRUTET — miljovariabeln %s saknas" % namn)
        raise SystemExit(2)
    return varde


def anrop(metod, url, nyckel, kropp=None, typ="application/json", tak=60):
    """Identisk med tools/runtime-grind.py:96-110."""
    huvud = {"x-api-key": nyckel}
    if kropp is not None:
        huvud["Content-Type"] = typ
    begaran = urllib.request.Request(url, data=kropp, headers=huvud,
                                     method=metod)
    try:
        with urllib.request.urlopen(begaran, timeout=tak) as svar:
            return svar.status, svar.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:                      # noqa: BLE001
        return 0, "natverksfel: %s" % e


def rootplace(universe):
    url = "%s/v1/games?universeIds=%s" % (GAMES, universe)
    with urllib.request.urlopen(url, timeout=30) as svar:
        data = json.loads(svar.read().decode("utf-8", "replace"))
    poster = data.get("data") or []
    if not poster:
        print("PROV: AVBRUTET — universe %s gav ingen post hos games-API:t. "
              "Utan startplatskontrollen postas ingenting." % universe)
        raise SystemExit(2)
    return int(poster[0]["rootPlaceId"])


def main():
    nyckel = krav("ROBLOX_API_KEY")
    universe = krav("UBRF_UNIVERSE_ID")
    place = krav("UBRF_CI_PLACE_ID")
    if not place.isdigit() or not universe.isdigit():
        print("PROV: AVBRUTET — universe/place ska vara tal (fick %r och %r)"
              % (universe, place))
        raise SystemExit(2)

    #[[ STARTPLACEN. Samma hardstopp som i grinden. Ett diagnostikprov ar
    #   inte ett skal att sanka sparren. ]]
    start = rootplace(universe)
    if int(place) == start:
        print("PROV: AVBRUTET — UBRF_CI_PLACE_ID pekar pa STARTPLACEN (%d). "
              "Provet postar aldrig dit." % start)
        raise SystemExit(2)

    kropp = MINIMAL.encode("utf-8")
    url = "%s/universes/v1/%s/places/%s/versions?versionType=Published" % (
        APIS, universe, place)

    print("KONTROLLPROV — minimal publicering (#264)")
    print("  universe      : %s" % universe)
    print("  mal-place     : %s  (startplacen %d ar INTE malet)"
          % (place, start))
    print("  url           : %s" % url)
    print("  content-type  : application/xml")
    print("  kroppens storlek: %d byte" % len(kropp))
    print("  exakt kropp:")
    for rad in MINIMAL.rstrip("\n").split("\n"):
        print("    | %s" % rad)
    print("")

    status, text = anrop("POST", url, nyckel, kropp,
                         typ="application/xml", tak=120)

    print("  HTTP-status   : %s" % status)
    print("  svarskropp    : %s" % text[:800])
    print("")

    if status == 0:
        print("PROV: INCONCLUSIVE — natverksfel, inget svar fran Roblox.")
        return 1

    if 200 <= status < 300:
        try:
            version = json.loads(text).get("versionNumber")
        except ValueError:
            version = None
        print("PROV: MINIMAL PUBLICERING LYCKADES (version %s)." % version)
        print("MINIMAL_PUBLISH_CONTROL: minimal=OK status=%s" % status)
        print("Den fulla artefakten foll pa samma endpoint och samma place.")
        print("=> ARTIFACT_SPECIFIC")
        return 0

    print("PROV: MINIMAL PUBLICERING FOLL OCKSA — status %s." % status)
    print("MINIMAL_PUBLISH_CONTROL: minimal=FAIL status=%s" % status)
    print("Envelopen ar byte-exakt densamma som den fulla artefaktens, sa "
          "innehallet ar inte det som avvisas.")
    print("=> API_OR_SETUP")
    return 0


if __name__ == "__main__":
    sys.exit(main())
