# Mätningar på rörelsen

Roblox Studio går inte att köra här, men det mesta av rörelsekänslan sitter i
ren matematik: hur styrutslaget rampas, hur farten dras mot gångartens tempo,
hur svängen tar tag och släpper, hur kameran följer kursen. Den matematiken går
att köra med `luau` om Roblox-globalerna stubbas — och då går känslan att **mäta**
i stället för att beskrivas.

```bash
python3 roblox/tests/build.py && luau roblox/tests/.build/movement.spec.luau
python3 roblox/tests/build.py tests/camera.spec.luau && luau roblox/tests/.build/camera.spec.luau
```

## Varför en byggfil

`luau`-CLI:t sandboxar varje modul: globaler som sätts i en fil syns inte i en
`require`:ad fil, så stubbarna kan inte injiceras utifrån. `build.py` fogar
därför ihop stubbar och produktionskod till en körbar fil — samma grepp som
`tools/build.py` använder för JS-spåret. **Produktionskoden inlinas ordagrant**;
det enda som ändras är `require`-raderna, som byts mot namnen på de moduler som
redan laddats. Det som mäts är alltså den kod som körs i Studio, inte en kopia.

## Vad stubbarna täcker

Bara det rörelse- och kamerakoden faktiskt rör: vektorer med de operatorer som
används, `CFrame` som bär position och yaw, en `Humanoid` som sparar `WalkSpeed`
och rörelseriktning, och ett `workspace` vars `Raycast` alltid ger plan mark.
Saknas en stub kraschar bänken med tjänstens namn i klartext, i stället för att
tyst mäta fel sak.

## Vad mätningarna inte kan svara på

- **Hur det känns.** Siffrorna säger att svängen släpper på 0,38 s i stället för
  0,09 s. Om det känns rätt avgörs i Studio, av en människa.
- **Animation, ljud, nätverk.** Ligger utanför bänken.
- **Sluttningar och kollisioner.** Marken är plan i stubben. Humanoid gör det
  riktiga arbetet och går inte att stubba meningsfullt.
- **Typkontroll.** `luau-analyze` kan inte lösa Roblox-`require` utan Studios
  typdefinitioner, så varje fil ger tiotals falska `TypeError`. Kompilering med
  `luau-compile` är däremot rent besked.
