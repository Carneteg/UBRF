# UBRF – Ridskolespel i Roblox

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och lär sig sköta hästar.
Privat projekt för familjen. Max 10 spelare. Stil: tecknad, lik "Horse Riding Tales – Wild Pony", lila/guld enligt UI-kitet.

## Byggnader – den viktigaste regeln

**Anläggningen ska kännas igen av någon som varit på UBRF.** Byggnaderna ritas i spelets tecknade stil, men
proportioner, färger, takform, fönster/dörrplacering och placering på tomten ska stämma med verkligheten.
Verkligheten är facit. Fotona i `reference/buildings/` är facit. Gissa aldrig – titta.

### Hårda regler

1. **Bygg aldrig en byggnad utan att först ha öppnat dess foton** (`Read` på varje JPG i `reference/buildings/<byggnad>/`).
   Öppna alla foton, inte bara det första. Ett foto per fasad minst.
2. **Bygg aldrig utan ett ifyllt byggnadskort** (`reference/buildings/<byggnad>/KORT.md`). Saknas det: fyll i det först med `/fotoanalys <byggnad>`.
   Kortet är kontraktet: mått, färger, takvinkel, antal fönster, dörrar, detaljer. Koden ska följa kortet, kortet ska följa fotona.
3. **Verifiera visuellt innan du säger "klart".** Efter bygget: ta en skärmdump från samma vinkel som referensfotot
   (MCP `capture_screenshot` om det finns, annars be Tobias klistra in en skärmdump) och jämför sida vid sida.
   Lista avvikelser konkret ("taket är för flackt – foto ~25°, modell ~40°") och rätta. Minst en iteration, oftast två–tre.
4. **Tecknad stil ≠ fantasi.** Förenkla detaljer (färre brädor, plana ytor, mjuka färger) men ändra aldrig
   form, antal, färgton eller proportioner. Har ridhuset röd plåtfasad och ljust tak, så har det det i spelet också.
5. **Namnge som i verkligheten.** Byggnader heter Ridhuset, Stallet, Ridbanan osv. – aldrig "Building1".
6. **Inte hitta på.** Om ett foto saknas för en fasad: säg det, bygg den som spegling av motsatt sida och markera i kortet
   `[antagande]`. Be Tobias om ett foto.
7. **Skala:** 1 meter = 3 studs (Roblox-standard, avatar ≈ 5 studs). Skriv alltid mått i meter i kortet och räkna om i koden via `BuildKit.M`.
8. **Placering på tomten** styrs av `reference/SITEPLAN.md` (situationsplan). Bygg varje byggnad som en `Model` med
   `PrimaryPart` i sydvästra hörnet på marknivå, så kan den flyttas utan att förstöras.

### Arbetsflöde för en byggnad

`/fotoanalys <byggnad>` → granska kortet med Tobias → `/bygg-byggnad <byggnad>` → jämför → justera → commit.

### Teknik

- Byggnader byggs med Luau-skript i `src/buildings/<Byggnad>.lua` som använder `src/BuildKit.lua` (väggar, sadeltak, fönster, dörrar, staket).
  Skriptet körs i Studio via MCP (`run_code`/`eval`) och skapar/ersätter `workspace.Anläggning.<Byggnad>`.
  Aldrig handbyggda parts som bara finns i Studio – allt ska gå att återskapa från repo.
- Använd `Part`, `WedgePart` och `CornerWedgePart`. `MeshPart`/unioner bara om formen inte går att lösa annars.
- Färger: sätt `Color` med RGB från kortet (plockat från fotot), material `SmoothPlastic` för tecknad känsla, `Wood`/`Metal` sparsamt.
- Varje byggnad = en `Model` med attribut `Källa = "reference/buildings/<byggnad>"` och `Version`.
- Efter varje ändring i ett byggnadsskript: kör om hela skriptet (det tar bort gammal modell först), ta skärmdump, jämför.

### Foton

- Källa: Google Drive-mappen `UBRF` (HEIC från iPhone). Konverteras till JPG med `tools/convert-photos.sh` och sorteras in i
  `reference/buildings/<byggnad>/` med namn `<byggnad>-<fasad>-<nr>.jpg` (t.ex. `ridhus-syd-01.jpg`). HEIC kan inte läsas – konvertera alltid.
- Klubbens Instagram @ubrflikeshorses och Facebook-video finns som extra referens men fotona i repot är primära.
