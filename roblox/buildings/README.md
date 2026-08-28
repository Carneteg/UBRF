# Byggnaderna i Roblox

Byggstenar för att bygga UBRF:s anläggning i Roblox Studio: väggar, sadeltak,
fönster, portar och staket. Kom hit från uppsättningspaketet.

**Det här är inte hästsystemet.** `roblox/src/` är ridningen och har ingen
koppling hit. De två delar bara repo.

| Fil | Vad |
|---|---|
| `BuildKit.luau` | byggstenarna — `newBuilding`, `wall`, `window`, `door`, `gableRoof`, `fence`, `cameraLike` |
| `_exempel.luau` | mall för ett byggnadsskript, med Ridhuset som exempel |

## Så används det

Lägg `BuildKit.luau` som en `ModuleScript` i `ServerStorage` med namnet
`BuildKit`, eller klistra in den överst i varje `run_code`-anrop mot Studio.
Skriv sedan ett byggnadsskript per byggnad efter mallen.

Varje skript tar bort sin gamla modell först och bygger om från grunden. Det är
avsiktligt: allt ska gå att återskapa ur repot, aldrig ur en Studio-fil som bara
finns på en dator.

## Måtten

**Alla mått i kod skrivs i meter.** `BuildKit.M` räknar om till studs (3 studs
per meter). Origo för en byggnad är sydvästra hörnet på marknivå.

Samma tal ska stå i byggnadskortet, i `references/SITEPLAN.md` och här. Skriver
man om ett mått till studs på vägen tappar man spårbarheten mot fotot, och då är
kortet inte längre facit.

## Två fällor som redan har slagit till

`_exempel.luau` innehöll `Källa = "..."` som tabellnyckel. Det är ogiltig Luau —
identifierare får inte innehålla å, ä eller ö — och skriptet gick därför inte att
köra. Ännu värre hade det varit om det kompilerat: Roblox tillåter bara
`[a-zA-Z0-9_]` i attributnamn, så `SetAttribute("Källa", …)` hade kastat fel vid
körning. Attributet heter nu `Referens`.

Svenska går utmärkt i strängar, kommentarer och instansnamn. Bara inte i
identifierare eller attributnamn.

## Arbetsflödet

Byggnadskortet är kontraktet, precis som för JS-spelet:

```
/fotoanalys ridhus     → fyller references/buildings/ridhus/KORT.md ur fotona
                         (granska måtten innan något byggs)
```

Sedan bygger du efter kortet, tar en skärmdump från samma vinkel som
referensfotot, och listar avvikelserna med siffror. `roblox/docs/STUDIO-SETUP.md`
beskriver hur Claude Code kopplas till Studio via MCP, vilket krävs för att det
sista steget ska kunna ske automatiskt.
