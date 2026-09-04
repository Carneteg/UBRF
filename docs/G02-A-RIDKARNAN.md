# G02-A — Ridkärnans konsolidering (issue #82)

Status: `READY_FOR_CHATGPT_REVIEW` (Claudes högsta normala status enligt
`docs/DELIVERY-PROTOCOL.md`). Ingen del av det här dokumentet är
produktacceptans.

## Vad uppdraget ÄR

Ett delta ovanpå Gate 01, inte en omskrivning. Ridkärnan fanns redan:

- webben — `Gait`/`stepRide` i `src/model.js`, ridinputkontraktet `RIDIN`
  och `ridAvsiktTillHjalp` samt kurvaturstyrningen i `src/game.js`, den
  analoga spaken i `src/mobil.js`, kameran i `src/scen3d.js`,
- Roblox — `MovementController`, `RiderController`, `HorseCore/Gaits`,
  `HorseCore/Config`, `TouchControls`.

G02-A rör inte deras intrimmade värden. Det som saknades var tre saker, och
det är dem det här arbetet lägger till.

## 1. Uppsutten/avsutten som tillstånd

Förut framgick det bara indirekt av vilken scen som var igång. Nu finns det
som ett namngivet tillstånd på båda ytorna: `RID_TILLSTAND` i
`src/riding/telemetri.js`, `Telemetri.Ritt` i
`roblox/src/shared/HorseCore/Telemetri.luau`.

Inkopplat på webben i `sittUpp()` (`src/tavling.js`, båda vägarna in i en
ritt) och `startaVandring()` (`src/world.js`).

## 2. Telemetri med ärlig proveniens

`ridTelemetri()` respektive `Telemetri.las()` läser ut de storheter G02-B/C
behöver: gångart, faktisk och önskad fart, kurvatur, svängradie,
vridhastighet, rytm, steglängd, spänning, mjukhet, balans, fokus, hjälper.

Ren avläsning — inget i lagret räknar fysik eller kan påverka ridkänslan.

`balans` och `fokus` finns inte som egna storheter i modellen. De härleds ur
mjukhet och spänning och är märkta `_harledda` (webb) respektive
`Telemetri.HARLEDDA` (Roblox). De påstår alltså inte att de är mätta.
G02-B ger dem riktiga källor.

## 3. Gångartsövergångarnas kontrakt

Grannbyten i gångartsordningen är lagliga, plus halt från vad som helst.
`halt → galopp` är inte en övergång utan ett glapp, och räknas som ett.

Kontraktet **dömer, det styr inte**: gångarten kommer fortsatt ur
`Gait.forTempo` / `Gaits.forSpeed` med hysteres. Ett kontrakt som styrde
hade ändrat ridkänslan, vilket är utanför uppdraget.

## Paritet — mätt, inte påstådd

Paritetsregeln i `CLAUDE.md` har hittills varit en text. Den är nu körbar:

- `tools/exportera-ridkanon.mjs` exporterar webbens ridkanon
  (gångartsband, hysteres, trösklar, telemetrins fältnamn) till
  `roblox/src/shared/HorseCore/RidKanon.luau`. Trösklarna **mäts** ur
  `Gait.forTempo` med halveringsmetoden i stället för att skrivas av.
- `roblox/tests/paritet.spec.luau` jämför Roblox `Gaits`/`Telemetri` mot den
  kanonen. Ingår i `bash roblox/tests/kor.sh`.
- `node tools/exportera-ridkanon.mjs --kontrollera` faller om kanonen är
  osynk. Kört i CI (`.github/workflows/grindar.yml`), och filen står i
  `dubbel-sanning`-listan så att den inte kan handredigeras.

### Kända avvikelser — dokumenterade, inte harmoniserade

Specen kräver att dessa ser ut **exakt** så här. Det gör två saker: en NY
avvikelse blir röd, och en avvikelse som rättas tvingar fram en ändring i
specen i stället för att glida förbi.

| Avvikelse | Webb | Roblox |
| --- | --- | --- |
| Galoppens övre bandgräns | 8,00 m/s | canter ≤ 7,00 m/s |
| Fyrsprång | saknas | `gallop` 7,20–11,0 m/s |
| Cykellängd, skritt/trav/galopp | 1,61 / 2,21 / 3,50 m | 1,45 / 2,13 / 3,20 m |
| Hjälplager, spänning, mjukhet, balans, fokus | finns | saknar källa |

Att jämna ut någon av dem **ändrar ridkänslan** och är ett produktbeslut,
inte något en konsolidering får göra på eget initiativ. De fyra ligger
därför kvar som de är, synliga i varje testkörning.

Cykellängdsavvikelsen är sedan tidigare dokumenterad i `Gaits.luau` och
`roblox/docs/HASTRIGG-KRAVSPEC.md` § 4; den står nu också i en körning i
stället för bara i en kommentar.

## Evidens

`node tools/ridtest.mjs` — 13 kontroller, webben, i riktig runtime:
Gate 01:s normtempon och band, gångartsstegen både ur `Gait.forTempo` och
genom att faktiskt köra `stepRide`, övergångskontraktet, telemetrins fält,
identiteten `vridhastighet = kurvatur × tempo`, härledningsmärkningen,
upp-/avsittning, och två live-fall som startar en riktig ritt i spelet.

`bash roblox/tests/kor.sh` — 13 specar, `paritet` inräknad.

### Falsifiering

Varje central kontroll har visats kunna bli röd:

| Mutation | Utfall |
| --- | --- |
| telemetrianropet ur `stegaRitt()` | FEL — `G.telemetri saknas` |
| `ridSittUpp` ur `sittUpp()` | FEL — `ritt false/null` |
| `ridSittAv` ur `startaVandring()` | FEL — `vandring true` |
| Roblox trav-norm 3,20 → 3,30 | FEL — normtempo trav/trot, + cykellängden |
| Roblox hysteres 0,35 → 0,30 | FEL — hysteresen |
| Roblox tröskel 4,45 → 4,60 | FEL — trösklarna |
| `SAKNAS` påstår att `spanning` finns | FEL — deklarerade luckor |
| webbens `HYST` ändrad utan omexport | FEL — `--kontrollera` osynk |
| samma, efter omexport | FEL — hysteresen i paritetsspecen |

## Not tested

- **Roblox Studio.** Ingen Studio-runtime finns i den här miljön. Luau-specarna
  provar kontrakt och tabeller, inte hur ritten känns i Studio.
  `Telemetri.las()` är provad mot en konstruerad `Locomotion`, inte mot en
  MovementController som körts en riktig bildruta.
- **Subjektiv game feel.** Kräver Tobias uttryckliga PASS.
- **20 m volt mot Gate 01:s 0,45 styrutslag** — nästa checkpoint.
