# PROVBYGGE ur e9a37ff — **inte sanktionerat**

> ## ⚠️ Det här är ett PROVBYGGE, inte en sanktionerad First Playable
>
> `LATEST-FIRST-PLAYABLE.md` säger fortfarande **INGEN FIL SANKTIONERAD**,
> och det gäller. Filen ligger här för att du ska KUNNA prova de två
> rättelser som gjordes efter att förra placen frös — inte för att jag
> säger att den är klar. Vill du hellre vänta på att hela gaten är
> färdig och ChatGPT har gjort sin review, gör det; ingenting nedan är
> verifierat i Studio, och jag kan inte köra Studio.

| Fält | Värde |
|---|---|
| Fil | [`UBRFFirstPlayable.rbxlx`](https://github.com/Carneteg/UBRF/raw/8b6fcd53e46b3cd9b0434640bd4fa0ce67bf7a5f/roblox/releases/first-playable-place-e9a37ff/UBRFFirstPlayable.rbxlx) |
| Commit som INNEHÅLLER filen | `8b6fcd53e46b3cd9b0434640bd4fa0ce67bf7a5f` |
| Källkod (gameplay + värld) | `e9a37ffc527230a57302c6808d139b9e2de07bcd` |
| Pakethalvan av preflighten | `FIRST_PLAYABLE_PREFLIGHT: PASS` |
| Status | **PROVBYGGE** — ingen sanktion, ingen produktacceptans |

## Så öppnar du den

1. Klicka länken ovan och spara filen (t.ex. på skrivbordet).
2. **Roblox Studio → File → Open from File…** och välj filen.
   Skriv inte sökvägen för hand — förra gången blev sökvägen dubblerad
   (`C:/Users/.../Desktop/"C:/Users/.../Desktop/UBRFFirstPlayable.rbxlx"`)
   och Studio svarade `Cannot open place file for reading`.
3. Tryck **Play**. Titta i **Output** om något ser fel ut.

## Vad som är rättat sedan förra placen frös

| Symptom du såg | Orsak | Rättning |
|---|---|---|
| "nu är jag i luften och faller och dör" | startplatsen låg 3,2 m ut i tomma luften, utan kollision | startplatsen härleds ur förstukvistens golv, med mark under |
| "nu får jag en fryst bild istället" + `Module code did not return exactly one value` | världsmodulen returnerade ingenting, så `require` kastade EFTER att världen byggts och tog med sig alla tjänster | modulen returnerar `true`, och pakethalvan av preflighten fäller om sista kodraden inte är ett `return` |
| ingen häst att sköta eller rida | inget i repot skapade en häst-`Model`/`Seat`/`Humanoid` | `HastRigg` bygger Blackrock Jack i hans box, taggad `Horse` |
| passet gick aldrig att göra färdigt | `local riderHook` deklarerades EFTER funktionen som läser den, så kroken var alltid nil: uppsittningen drev aldrig passet och eftervården gick inte att göra | deklarationen flyttad; mätt i `integration.spec.luau` |
| död mitt i ritten låste dagen | varje avsittning avslutade ritten, även döden | dagen slutar när eftervården börjar, inte när fötterna når marken |

## Vad som INTE är verifierat

- **Ingenting i Studio.** Jag har ingen Studio och ingen runtime. Alla
  mätningar är gjorda i bänken utanför Roblox.
- Fysik, animationer, kamerakänsla, IK och hur hästen KÄNNS.
- Att placen laddar utan fel i Studio. Preflighten skriver
  `FIRST_PLAYABLE_PREFLIGHT: PASS` eller `FAIL` i Output vid start —
  läs den raden först av allt.
- Lokalisering sv/en är **inte** byggd än. Allt är på svenska.

## Om den fryser igen

Kopiera de första raderna ur **Output** — särskilt raden som börjar
`FIRST_PLAYABLE_PREFLIGHT`. Den säger vilken del som fattas, och det är
snabbare än att gissa.
