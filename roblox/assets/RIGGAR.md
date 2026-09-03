# Hästriggar — källa, licens och proveniens

Issue #31 punkt 2: *license/provenance recorded*. En rigg utan den här raden
får inte användas, oavsett hur bra den ser ut.

Skälet är inte formalia. En köpt eller nedladdad modell bär villkor — får den
användas kommersiellt, får den ändras, måste upphovspersonen anges — och de
villkoren följer med tillgången in i spelet. Står de ingenstans är de borta
nästa gång någon frågar, och då är frågan inte längre teknisk.

## Regler

1. **En rad per riggtillgång.** Alla kolumner ifyllda. Tom cell = ofullständig
   rad, och `tools/kolla-riggkalla.py` fäller.
2. **Filen ska ligga i repot eller i Supabase.** `docs/ASSET-SOURCE-OF-TRUTH.md`
   gäller: Google Drive är insamlingsyta, aldrig en build-förutsättning. En rad
   vars enda plats är Drive markeras `[DRIVE-ONLY]` och fäller kontrollen —
   avsiktligt, för att en sådan rigg inte går att bygga med.
3. **`sha256` ska stämma** mot filen på angiven sökväg. Byts filen ut utan att
   summan uppdateras har någon bytt tillgång utan att säga det.
4. **`licens` ska vara ett namn någon kan slå upp** — `CC0`, `CC-BY-4.0`,
   `Roblox Marketplace`, `egen produktion`. Inte "fri" eller "ok".

## Riggar

<!-- TABELL-START -->

| id | fil | sokvag | kalla | licens | upphov | datum | sha256 |
|---|---|---|---|---|---|---|---|

<!-- TABELL-SLUT -->

**Tabellen är tom, och det är ett sant besked.** Repot har ingen
produktionsrigg. Issue #31 är öppen och stängs av en riggad modell som
importerar och rider — inte av det här dokumentet och inte av
`RigContract.luau`.

## Vad kontrollen gör när tabellen är tom

`tools/kolla-riggkalla.py` går igenom med exit 0 och skriver ut att noll riggar
är registrerade. Den påstår alltså inte att något är verifierat. Så fort en rad
läggs till gäller alla fyra reglerna ovan.

## När den första riggen kommer

Ordningen är:

1. lägg filen i repot (eller i Supabase-spegeln, med sökvägen här),
2. skriv raden i tabellen,
3. kör `python3 tools/kolla-riggkalla.py` — den ska gå igenom,
4. kör kontrollen mot modellen i Studio och spara utfallet:

   ```lua
   local Horse = require(game.ReplicatedStorage.HorseCore)
   local m = workspace.Fjodor
   print(Horse.RigContract.rapport(
       Horse.RigContract.kontrollera(m, {
           hastar  = require(game.ReplicatedStorage.UBRFSpel).hastar,
           harTagg = function(i, t)
               return game:GetService("CollectionService"):HasTag(i, t)
           end,
       })))
   ```

5. först därefter kan #31:s övriga punkter bedömas, och de kräver Studio.
