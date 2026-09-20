# `qa/runtime/` — nivån mellan stubbarna och människan

Skriven på #252 DEL C.

Projektet hade två nivåer och ett hål mellan dem:

| Nivå | Var | Vad den kan se | Vad den inte kan se |
|---|---|---|---|
| **Bänken** | `roblox/tests/*.spec.luau` | regler, data, ordning, nej-vägar | instanser, instansegenskaper, welds, fysik, state som inte rivs |
| *(hålet)* | — | — | — |
| **Människan** | Tobias, fysisk enhet | game feel, kamera, responsivitet, visuell trovärdighet | körs sällan; senaste registrerade acceptans i `audits/` var 2026-08-30 |

Den här katalogen är hålet. `smoke.luau` körs **serverside i riktig
Roblox-motor** — genom Open Cloud Luau Execution i CI, eller i Studios
serverruntime lokalt — mot en place byggd ur exakt den commit som mäts.

## Vad den avgör, och vad den inte avgör

Runtime-grinden avgör **fungerar det**. Den avgör inte **är det bra**.
Kvar hos Tobias, och bara en gång per spelbar kedja: fysisk touch på
iPhone och iPad, game feel, kamera, responsivitet, och visuell
trovärdighet mot referensmaterialet.

## Kör den

```sh
# Hela vägen: bygg placen, publicera, kör i motorn. Kräver ROBLOX_API_KEY,
# UBRF_UNIVERSE_ID och UBRF_CI_PLACE_ID. Görs normalt av CI.
python3 tools/runtime-grind.py

# Bara bygge, identitet och kopplingar. Rör inte Open Cloud.
# Det här är INTE ett PASS för grinden, och säger det själv.
python3 tools/runtime-grind.py --torrkor

# Drivarens egen falsifiering, 18 prov i båda riktningarna.
python3 tools/testa-runtime-grind.py
```

Lokalt i Studio: lägg `smoke.luau` som en `ModuleScript` i
**`ServerStorage`** (inte `ServerScriptService` — preflightens punkt 10d
fäller allt ospårat där, och då blir `CRITICAL_STARTUP_GATE` rött av
provets egen instrumentering), starta ett playtest i **Run**-läge, och
kör:

```lua
_G.UBRF_VANTAD_KALLHASH = require(game.ReplicatedStorage.UBRFBuild).kallhash
_G.UBRF_DEL = "alla"
return require(game.ServerStorage.CISmoke)
```

## Testsätet

Luau Execution kör en server utan klienter, och en `Player` går inte att
skapa — mätt i motorn ger både `Instance.new("Player")` och
`Players:CreateLocalPlayer(1)` avslaget *«lacking capability
WritePlayer»*. Smoken bygger därför en **aktör**: userId, namn, en riktig
karaktärsmodell med `HumanoidRootPart` och `Humanoid`, och de två
karaktärssignalerna. Den deklarerar `harKlient = false`; se
`roblox/src/shared/HorseCore/Aktor.luau` för varför det är en opt-out och
inte ett typtest.

Serverhandlingarna körs sedan **som de är**. Nedkopplingen går genom
`GameplayService.lamnar`, `LedService.lamnar` och `HorseService.lamnar` —
produktionens egna handlare, samma funktioner `PlayerRemoving` kopplar —
och inte genom en avskrift av vad de gör.

## Vad som inte går att mäta utan klient

Redovisas som `Not tested`, aldrig omskrivet till PASS:

- **nätverksägarskap.** `SetNetworkOwner` kräver en riktig spelare;
  anropet är redan `pcall`:at i produktionen och loggar en varning.
- **fjärranropens tråd.** Smoken anropar de namngivna handlarna
  (`HorseService.mountRequest`), inte `InvokeServer` över nätet. Att
  remoten pekar på rätt handlare bindes statiskt av
  `tools/runtime-grind.py`, eftersom `OnServerInvoke` inte går att läsa
  tillbaka ur motorn.
- **allt klientside:** HUD, kamera, prompt-UI, touch, input.
- **game feel.** Se ovan.
