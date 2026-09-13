# Gate 01 — Platform Addendum

Status: CANONICAL OVERRIDE for `docs/GATE-01-RIDING-FEEL.md`

Det äldre Gate 01-dokumentet beskriver webbversionen som enda implementationstarget. Den formuleringen är ersatt av följande produktbeslut.

## Target

**Roblox är primär spelplattform och primär subjektiv playtest för Gate 01. HTML/webb är samtidigt en riktig spelbar parallell distribution och ska behålla samma kärnupplevelse.**

Gate 01 implementeras därför som ett plattformsparitetsarbete:

1. definiera/tuna den motoroberoende ridkänslan och dess acceptance criteria,
2. implementera och verifiera den i Roblox/Luau som primär spelimplementation,
3. behåll/justera HTML/webb så att samma kärnregler och kvalitetsmål är spelbara där,
4. dokumentera avsiktliga plattformsskillnader i input, kamera eller rendering.

## Roblox blockerande test

Gate 01 kan inte stängas utan faktisk Roblox Studio-playtest av:

- keyboard,
- touch där möjligt,
- skritt/trav/galopp,
- raka linjer och små korrigeringar,
- hörn och volt,
- acceleration/inbromsning,
- häst-/ryttarrespons,
- kamera,
- frame-rate-stabil känsla,
- full kärnloop som är implementerad i Roblox-spåret.

Claude ska tydligt skriva vad som inte kan verifieras utanför Roblox Studio. Tobias avgör slutlig subjektiv feel.

## HTML/webb blockerande paritet

Webbversionen får inte brytas av Gate 01 och ska fortsatt vara direkt spelbar via HTML. Där samma mekanik finns ska följande motsvara Roblox-designen:

- steering-intention,
- gångartsberoende svängbegränsning,
- acceleration/deceleration-princip,
- analog touchprecision,
- gångarts-/animationsrytm,
- turn/body response,
- camera intent,
- utbildningsmässiga ridregler.

Exakta tekniska implementationer får skilja sig.

## Bevis

`audits/GATE-01-RIDING-FEEL-RESULT.md` ska ha separata sektioner:

- `Roblox implementation & Studio evidence`
- `HTML/web implementation & browser evidence`
- `Parity table`
- `Intentional platform differences`
- `Remaining risks`

Ingen agent får kalla Gate 01 klar enbart på webbrowser-test eller enbart på Luau-kompilering.

## Paritetsregistret (G02-A)

Paritetstabellen och de avsiktliga plattformsskillnaderna är sedan G02-A
körbara i stället för bara skrivna: `roblox/tests/paritet.spec.luau` jämför
Roblox `Gaits`/`Telemetri` mot webbens exporterade ridkanon och kräver att
de kända avvikelserna ser exakt ut som de gör. En ny avvikelse blir röd.

Registret och dess bevis står i `docs/G02-A-RIDKARNAN.md`.
