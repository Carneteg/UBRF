#!/usr/bin/env python3
"""LIVE-REVISIONEN — #293. Enbart LASANDE.

Svarar pa: vilken build ligger i den PUBLICERADE startplacen, jamfort med
repots kallhash? Kor en Luau Execution-task mot den redan publicerade
versionen och laser identiteten ur den.

══ SPARRAR ════════════════════════════════════════════════════════════

  1. Inget publiceringsanrop finns i filen. Enda POST:en ar skapandet av
     en Luau Execution-task, och skriptet den kor skriver ingenting.
  2. Nyckeln skrivs aldrig ut och sparas aldrig.
  3. Servern ser ingen klient: `LedPrompt` (klientens) kan INTE bevisas
     har. Byggidentiteten ar beviset; beteendet laser man ur den commit
     hashen motsvarar.
"""
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request

ROT = pathlib.Path(__file__).resolve().parent.parent
IDENTITET = ROT / "roblox" / "game" / "UBRFBuild.luau"
APIS = "https://apis.roblox.com"
GAMES = "https://games.roblox.com"
KLARA = {"COMPLETE", "FAILED", "CANCELLED"}
PAGANDE = {"STATE_UNSPECIFIED", "QUEUED", "PROCESSING"}

LUAU = r'''
local RS = game:GetService("ReplicatedStorage")
local r = { PlaceId = game.PlaceId, PlaceVersion = game.PlaceVersion }
local b = RS:FindFirstChild("UBRFBuild")
if b then
	local ok, m = pcall(require, b)
	if ok and type(m) == "table" then
		r.kallhash, r.sha, r.genererad, r.lage = m.kallhash, m.sha, m.genererad, m.lage
	else
		r.build_fel = tostring(m)
	end
else
	r.build = "UBRFBuild saknas"
end
local function finn(namn)
	for _, d in ipairs(game:GetDescendants()) do
		if d.Name == namn and d:IsA("LuaSourceContainer") then return d end
	end
end
local led = finn("LedService")
if led then
	local ok, s = pcall(function() return led.Source end)
	if ok then
		r.led_borttagen_i_kallan = s:find("led.borttagen", 1, true) ~= nil
	else
		r.led_kalla = "Source ej lasbar"
	end
else
	r.led_service = "saknas"
end
return r
'''


def anrop(metod, url, nyckel, kropp=None):
    huvud = {"x-api-key": nyckel}
    if kropp is not None:
        huvud["Content-Type"] = "application/json"
    b = urllib.request.Request(url, data=kropp, headers=huvud, method=metod)
    try:
        with urllib.request.urlopen(b, timeout=60) as s:
            return s.status, s.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:  # noqa: BLE001
        return 0, "natverksfel: %s" % e


def fall(vad):
    print("LIVE_REVISION: FAIL — %s" % vad)
    sys.exit(1)


def js(status, text, vad):
    if not 200 <= status < 300:
        fall("%s gav HTTP %s: %s" % (vad, status, text[:300]))
    try:
        return json.loads(text)
    except ValueError:
        fall("%s svarade inte JSON: %s" % (vad, text[:300]))


def main():
    nyckel = os.environ.get("ROBLOX_API_KEY", "").strip()
    uni = os.environ.get("UBRF_UNIVERSE_ID", "").strip()
    if not nyckel or not uni.isdigit():
        fall("ROBLOX_API_KEY eller UBRF_UNIVERSE_ID saknas")

    with urllib.request.urlopen("%s/v1/games?universeIds=%s" % (GAMES, uni),
                                timeout=30) as s:
        spel = json.loads(s.read().decode())["data"][0]
    place = int(spel["rootPlaceId"])
    print("universe: %s" % uni)
    print("startplace: %d" % place)
    print("universe.updated: %s" % spel.get("updated"))

    st, tx = anrop("GET", "%s/cloud/v2/universes/%s/places/%d" % (APIS, uni, place), nyckel)
    if 200 <= st < 300:
        p = json.loads(tx)
        print("place.updateTime: %s" % p.get("updateTime"))
    else:
        print("place.updateTime: (HTTP %s)" % st)

    # Ingen version i vagen = senast publicerade versionen.
    url = "%s/cloud/v2/universes/%s/places/%d/luau-execution-session-tasks" % (APIS, uni, place)
    task = js(*anrop("POST", url, nyckel,
                     json.dumps({"script": LUAU, "timeout": "60s"}).encode()),
              vad="task-skapandet")
    vag = task.get("path")
    if not vag:
        fall("task-svaret saknar path")
    print("task: %s" % vag)
    slut, lage = time.time() + 240, task.get("state", "?")
    while lage not in KLARA:
        if lage not in PAGANDE:
            fall("okant task-tillstand %r" % lage)
        if time.time() > slut:
            fall("task blev aldrig klar")
        time.sleep(5)
        task = js(*anrop("GET", "%s/cloud/v2/%s" % (APIS, vag), nyckel), vad="pollningen")
        lage = task.get("state", "?")
    if lage != "COMPLETE":
        fall("task %s: %s" % (lage, task.get("error")))
    res = (task.get("output") or {}).get("results") or []
    if not res or not isinstance(res[0], dict):
        fall("tomt eller ogiltigt resultat: %r" % (res,))
    live = res[0]

    repo = re.search(r'kallhash\s*=\s*"([0-9a-f]{64})"', IDENTITET.read_text(encoding="utf-8"))
    repo_hash = repo.group(1) if repo else None
    print("")
    print("LIVE game.PlaceId:      %s" % live.get("PlaceId"))
    print("LIVE game.PlaceVersion: %s" % live.get("PlaceVersion"))
    print("LIVE kallhash:          %s" % live.get("kallhash"))
    print("LIVE sha (upplysning):  %s" % live.get("sha"))
    print("LIVE genererad:         %s" % live.get("genererad"))
    print("LIVE led.borttagen i kalla: %s" % live.get("led_borttagen_i_kallan"))
    for k in ("build", "build_fel", "led_service", "led_kalla"):
        if live.get(k):
            print("LIVE %s: %s" % (k, live[k]))
    print("REPO kallhash (denna gren): %s" % repo_hash)
    if live.get("kallhash") and live.get("kallhash") == repo_hash:
        print("LIVE_REVISION: LIVE == REPO-HEAD")
    else:
        print("LIVE_REVISION: LIVE SKILJER SIG fran repo-head")


if __name__ == "__main__":
    main()
