# Byggnaderna i Roblox

Byggstenar för att bygga UBRF:s anläggning i Roblox Studio: väggar, sadeltak,
fönster, portar och staket. Kom hit från uppsättningspaketet.

**Det här är inte hästsystemet.** `roblox/src/` är ridningen och har ingen
koppling hit. De två delar bara repo.

| Fil | Vad |
|---|---|
| `BuildKit.luau` | byggstenarna — `newBuilding`, `wall`, `window`, `door`, `gableRoof`, `fence`, `cameraLike` |
| `Geometri.luau` | ren geometri: var en öppning sitter i en fasad, hur brant ett tak är, om två hus sitter ihop. Inga Roblox-anrop, så den går att mäta utanför Studio |
| `UBRFKomplex.luau` | **genererad** — hela anläggningens mått, färger och öppningar |
| `Anlaggningen.luau` | bygger hela komplexet ur `UBRFKomplex` |
| `Vyer.luau` | de fem vyer Gate F01 kräver, uträknade ur geometrin |
| `STUDIO-KONTROLL.md` | checklistan för Product Owner visual acceptance |
| `_exempel.luau` | mall för ett byggnadsskript, med Ridhuset som exempel |

## Var måtten kommer ifrån

`UBRFKomplex.luau` **skrivs inte för hand.** Den genereras ur `src/site.js` —
samma kod som webbspelet bygger sin värld av:

```
node tools/exportera-geometri.js              # skriver om modulen
node tools/exportera-geometri.js --kontrollera # faller om den är ur synk
```

Det är därför Roblox och webben inte kan glida isär om anläggningen. Ska ett
mått ändras ändras det i `src/site.js`, och sedan körs exporten. Ändrar man i
den genererade filen skrivs ändringen över nästa gång, och `--kontrollera`
säger ifrån innan dess.

Att innehållet stämmer mäts av `roblox/tests/geometri.spec.luau`:

```
python3 roblox/tests/build.py tests/geometri.spec.luau
luau roblox/tests/.build/geometri.spec.luau
```

Den kontrollerar bland annat att hästgången möter både ridhuset och stallet,
att interna öppningar vetter mot ett grannhus och inte ut i luften, och att
öppningarnas `u` räknas från rätt ände av rätt fasad.

## Så byggs anläggningen

```bash
python3 tools/studio-paket.py
```

fogar ihop **en** fil att klistra in — `roblox/buildings/.studio/UBRF-klistra-in.luau`
— efter att först ha kontrollerat att geometrin är i synk med `src/site.js`.
Klistra in hela filen i Studio och kör den en gång.

Paketet är avsiktligt inte committat: det är bara en hopfogning av filer som
redan ligger här, och en kopia i git hade blivit ännu en sanning att hålla i
synk.

Vill du hellre göra det för hand går det också: `BuildKit`, `Geometri`,
`UBRFKomplex` och `Vyer` som `ModuleScript` i `ServerStorage`, sedan
`Anlaggningen.luau`.

**Checklistan för Studio-kontrollen står i `STUDIO-KONTROLL.md`.**

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

**Samma fälla igen, 2026-08-30.** `BuildKit.gableRoof` läste
`model:GetAttribute("GavelFärg")` och `_exempel.luau` satte samma namn. Ett
attributnamn med ä hade kastat fel vid körning, precis som `Källa` nedan.
Attributet heter nu `GavelFarg`. Det hittades när `Anlaggningen.luau` skulle
anropa `gableRoof` för första gången — ingen hade byggt ett tak förrän då.

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
