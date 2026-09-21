#!/usr/bin/env python3
"""KONTROLLPROV for #264. Postar en place till CI-placen och REDOVISAR.

Runtime-grinden nadde Open Cloud i job 106218507201 och fick HTTP 400
{"code":"InvalidRequest","message":"Invalid Content stream"}. Provet
postar en kontrollfil till SAMMA place genom samma endpoint, samma auth
och samma rabyte-POST som `tools/runtime-grind.py`.

VAD PROVET KAN OCH INTE KAN
---------------------------
Forsta omgangen (job 106221302313) postade en handgenererad minimal
place och fick samma 400. Den drog slutsatsen API_OR_SETUP. Den
slutsatsen var FOR STARK och ar tillbakadragen:

  Kontrollfilen skrevs for hand med SAMMA envelope-antaganden som
  `tools/bygg-place.py`. Delar de ett serialiserings- eller schemafel
  faller bada av exakt samma skal. Att Pythons XML-parser accepterar en
  fil bevisar inte att Roblox anser den vara en giltig place.

Darfor: en handgenererad kontroll kan aldrig ge annat an INCONCLUSIVE.
Bara en OBEROENDE kant-god place — en som Roblox sjalvt har skrivit,
sparad ur Studio och verifierat aterppnad — diskriminerar. Skicka en
sadan med `--fil` och `--kand-god`.

Skriptet klassificerar inte orsaken at nagon. Det redovisar ramatningen
och sager ut vad matningen kan bara.

DIAGNOSTIK, INTE EN GRIND. Gron exitkod betyder «matning erhallen», inte
«publicering lyckades». Las klassificeringsraden, aldrig exitkoden.
Filen ar tillfallig och ska tas bort nar fragan ar besvarad.
"""
import argparse
import hashlib
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

APIS = "https://apis.roblox.com"
GAMES = "https://games.roblox.com"

#[[ Roblox binara containerformat. En .rbxl MASTE skickas som
#   application/octet-stream och en .rbxlx som application/xml — parningen
#   ar dokumenterad, och fel typ ar ett eget fel vi inte vill blanda in i
#   matningen. Formatet avgors av filens FORSTA BYTES, inte av dess namn:
#   en binarfil med .rbxlx-andelse ar en vanlig felkalla. ]]
BINAR_MAGI = b"<roblox!"

#[[ HARDBUNDET MAL. Ordern tillater exakt ett par, och diagnostiken ska
#   inte kunna riktas nagon annanstans av en felsatt variabel. Avvikelse
#   ar ett stopp, inte en varning. ]]
TILLATET_UNIVERSE = "10766192504"
TILLATEN_PLACE = "121231609290409"

#[[ Byte-exakt samma envelope som tools/bygg-place.py:239-245 skriver.
#   Anvands bara nar ingen oberoende fil ges — och ger da INCONCLUSIVE. ]]
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


def stopp(text):
    print("PROV: AVBRUTET — %s" % text)
    raise SystemExit(2)


def krav(namn):
    varde = os.environ.get(namn, "").strip()
    if not varde:
        stopp("miljovariabeln %s saknas" % namn)
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
    try:
        with urllib.request.urlopen(url, timeout=30) as svar:
            data = json.loads(svar.read().decode("utf-8", "replace"))
    except Exception as e:                      # noqa: BLE001
        stopp("kunde inte sla upp startplacen (%s). Utan den kontrollen "
              "postas ingenting." % e)
    poster = data.get("data") or []
    if not poster:
        stopp("universe %s gav ingen post hos games-API:t" % universe)
    return int(poster[0]["rootPlaceId"])


def malet():
    """Hardbunden kontroll av att vi postar exakt dit ordern tillater."""
    universe = krav("UBRF_UNIVERSE_ID")
    place = krav("UBRF_CI_PLACE_ID")
    if universe != TILLATET_UNIVERSE:
        stopp("UBRF_UNIVERSE_ID ar %r, men diagnostiken ar bunden till %r"
              % (universe, TILLATET_UNIVERSE))
    if place != TILLATEN_PLACE:
        stopp("UBRF_CI_PLACE_ID ar %r, men diagnostiken ar bunden till %r"
              % (place, TILLATEN_PLACE))
    #[[ Baltet OCH hangslena: aven med ratt konstanter slas startplacen
    #   upp live, ifall upplevelsens rootPlaceId nagon gang andras. ]]
    start = rootplace(universe)
    if int(place) == start:
        stopp("malet ar upplevelsens STARTPLACE (%d). Provet postar aldrig "
              "dit." % start)
    return universe, place, start


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--fil", help="place-fil att posta i stallet for den "
                                 "inbyggda minimala")
    p.add_argument("--kand-god", action="store_true",
                   help="intyga att --fil ar en OBEROENDE kant-god place: "
                        "skriven av Roblox, sparad ur Studio och verifierat "
                        "aterppnad. Bara da kan utfallet diskriminera.")
    p.add_argument("--tredjepart", action="store_true",
                   help="filen kommer fran en OBEROENDE TREDJEPARTS-serializer "
                        "(rbx-dom/Rojo), inte fran Roblox sjalvt. En enskild "
                        "korning avgor da ingenting — det ar PARET av tva "
                        "format ur samma serializer som diskriminerar.")
    p.add_argument("--vantad-sha256",
                   help="kontrollfilens vantade SHA-256. Avviker den postas "
                        "ingenting: en kontroll vars bytes andrats pa vagen "
                        "ar inte langre den kontroll som granskades.")
    a = p.parse_args()

    if a.kand_god and not a.fil:
        stopp("--kand-god utan --fil sager ingenting")
    if a.tredjepart and not a.fil:
        stopp("--tredjepart utan --fil sager ingenting")
    if a.kand_god and a.tredjepart:
        stopp("--kand-god och --tredjepart motsager varandra: en fil ar "
              "antingen Roblox-skriven eller tredjeparts, inte bada")
    if a.vantad_sha256 and not a.fil:
        stopp("--vantad-sha256 utan --fil sager ingenting")

    nyckel = krav("ROBLOX_API_KEY")
    universe, place, start = malet()

    sha = None
    if a.fil:
        vag = pathlib.Path(a.fil)
        if not vag.is_file() or vag.stat().st_size == 0:
            stopp("filen finns inte eller ar tom: %s" % vag)
        kropp = vag.read_bytes()
        sha = hashlib.sha256(kropp).hexdigest()
        #[[ CI laser filen ur en checkout, inte ur arbetstradet. Andrade
        #   bytes pa vagen — radslutsnormalisering, LFS, en annan fil med
        #   samma namn — ska stoppa matningen, inte matas. ]]
        if a.vantad_sha256 and sha != a.vantad_sha256.strip().lower():
            stopp("kontrollfilens SHA-256 stammer inte.\n"
                  "         vantat: %s\n"
                  "         faktisk: %s"
                  % (a.vantad_sha256.strip().lower(), sha))
        kalla = "%s (%d byte)" % (vag.name, len(kropp))
        oberoende = a.kand_god
    else:
        kropp = MINIMAL.encode("utf-8")
        sha = hashlib.sha256(kropp).hexdigest()
        kalla = "inbyggd minimal place (%d byte)" % len(kropp)
        oberoende = False

    #[[ Typen foljer filens bytes, aldrig dess namn. ]]
    binar = kropp[:len(BINAR_MAGI)] == BINAR_MAGI
    typ = "application/octet-stream" if binar else "application/xml"

    url = "%s/universes/v1/%s/places/%s/versions?versionType=Published" % (
        APIS, universe, place)

    print("KONTROLLPROV — publicering mot CI-placen (#264)")
    print("  universe      : %s  (hardbunden)" % universe)
    print("  mal-place     : %s  (hardbunden; startplacen %d ar INTE malet)"
          % (place, start))
    print("  url           : %s" % url)
    print("  format        : %s" % ("BINART (.rbxl-magi i bytes)" if binar
                                    else "XML"))
    print("  content-type  : %s" % typ)
    print("  kropp         : %s" % kalla)
    print("  sha256        : %s" % sha)
    print("  ursprung      : %s" % ("tredjepart (rbx-dom/Rojo)" if a.tredjepart
                                    else "Roblox-skriven, kant-god" if oberoende
                                    else "handgenererad"))
    if not a.fil:
        print("  exakt kropp:")
        for rad in MINIMAL.rstrip("\n").split("\n"):
            print("    | %s" % rad)

    status, text = anrop("POST", url, nyckel, kropp, typ=typ, tak=300)

    #[[ RAMATNINGEN. Star for sig, utan tolkning. ]]
    print("")
    print("=== RAMATNING ===")
    print("  HTTP-status   : %s" % status)
    print("  svarskropp    : %s" % text[:800])
    version = None
    if 200 <= status < 300:
        try:
            version = json.loads(text).get("versionNumber")
        except ValueError:
            version = None
    print("  versionNumber : %s" % (version if version else "—"))
    print("  place-version andrad: %s" % ("JA" if version else "NEJ"))

    #[[ TOLKNINGEN. Separat, och avsiktligt forsiktig. ]]
    print("")
    print("=== VAD MATNINGEN BAR ===")

    if status == 0:
        print("  Natverksfel — inget svar fran Roblox.")
        print("PROV: INCONCLUSIVE")
        return 1

    if a.tredjepart:
        #[[ Rojo/rbx-dom ar en oberoende implementation, men inte Roblox
        #   egen. En ensam korning kan darfor inte skilja «var XML ar fel»
        #   fran «XML-vagen ar trasig». Det ar PARET — samma serializer,
        #   samma innehall, bara formatet olika — som isolerar variabeln. ]]
        print("  Filen kommer fran en TREDJEPARTS-serializer (rbx-dom/Rojo),")
        print("  inte fran Roblox sjalvt. Den har ensamma korningen avgor")
        print("  darfor ingenting. Klassificeringen kommer ur PARET:")
        print("    XML 400 + binar 2xx  -> formatet ar enda variabeln")
        print("    XML 2xx              -> var egen XML ar det avvikande")
        print("PROV: RAMATNING status=%s format=%s (del av parprov)"
              % (status, "binar" if binar else "xml"))
        return 0

    if not oberoende:
        print("  Kontrollfilen ar INTE en oberoende kant-god Roblox-place.")
        print("  Den ar handgenererad med samma envelope-antaganden som")
        print("  tools/bygg-place.py. Ett gemensamt serialiserings- eller")
        print("  schemafel skulle falla bada filerna av samma skal, och")
        print("  XML-valformning bevisar inte place-giltighet.")
        print("  Utfallet kan darfor INTE skilja artefaktfel fran")
        print("  API-/setupfel, oavsett vilken status som kom tillbaka.")
        print("PROV: INCONCLUSIVE status=%s" % status)
        return 0

    print("  Kontrollfilen ar intygad oberoende kant-god.")
    if not 200 <= status < 300:
        print("  Aven en place skriven av Roblox sjalvt avvisas.")
        print("  => felet ligger inte i det vi genererar.")
        print("PROV: API_OR_SETUP status=%s" % status)
        return 0

    if binar:
        #[[ En binar kontroll som gar igenom bevisar att nyckel, scope,
        #   place, endpoint och auth fungerar. Den bevisar INTE att var
        #   XML-artefakt ar giltig — wire-formatet skilde sig. ]]
        print("  Den binara vagen fungerar: nyckelns scope, CI-placens")
        print("  tillstand, endpointen och auth ar darmed bevisat i ordning.")
        print("  Det bevisar INTE att var XML-artefakt ar giltig; formatet")
        print("  skilde sig, sa XML-vagen ar fortfarande oprovad.")
        print("PROV: BINARY_PATH_PASS status=%s" % status)
        return 0

    print("  En Roblox-skriven XML-place gick igenom dar var egen foll,")
    print("  med samma wire-format och samma endpoint.")
    print("  => skillnaden ligger i det vi sjalva genererar.")
    print("PROV: ARTIFACT_SPECIFIC status=%s" % status)
    return 0


if __name__ == "__main__":
    sys.exit(main())
