# Kontrollmatris — vad spelaren faktiskt trycker på

Skriven på PO-tillägget till #151 (2026-09-09): *"Inventera faktiska
inputbindningar och HUD i webb/Roblox innan ändring; dokumentera den
plattformsspecifika kontrollmatrisen."*

**Allt nedan är läst ur källan**, inte ur minnet. Källorna är:

| Yta | Fil |
|---|---|
| Roblox tangent/gamepad | `roblox/src/client/Input.luau` |
| Roblox uppsittning och lektionsval | `roblox/src/client/init.client.luau` |
| Roblox pekskärm | `roblox/src/client/TouchControls.luau` |
| Webb tangentbord | `src/game.js` (`keydown`/`keyup`) |
| Webb pekskärm | `src/mobil.js` |

Den här filen **beskriver**; den binder ingenting. Ändras en bindning ska
matrisen ändras med den, och `roblox/tests/klient.spec.luau` faller om
kontrollhjälpen påstår en tangent som inte längre gör vad den lovar —
provet fyrar hjälpens egen tangent och läser vad `Input.luau` gjorde.

## Roblox

| Handling | Tangentbord | Gamepad | Pekskärm |
|---|---|---|---|
| Sitt upp / sitt av | `E` | `E` | `SITT AV` |
| Framåt / bakåt | `W` / `S` | vänster spak | spaken |
| Styr | `A` / `D` | vänster spak | spaken |
| Högre gångart | `LeftShift` | `R1` | `▲ FRAMÅT` |
| Lägre gångart | `LeftControl` | `L1` | `▼ LUGNARE` |
| Tygel (kontakt) | `Q` | `R2` | `TYGEL` |
| Halvhalt (parad) | `F` | `B` | `HALVHALT` |
| Sits lätt / djup | `Z` / `C` | `L2` | `DJUP SITS` |
| Hoppa | `Space` | `A` | `HOPP` |
| Lektionen vidare | `R` | `Y` | kortets knapp |
| Se ritten (ridanalys) | `T` | `X` | *Se ritten* |
| Gå vidare | `G` | — | *Gå vidare* |
| Kontrollhjälp | `H` | — | panelens *Stäng* |

## Webb

| Handling | Tangentbord | Pekskärm |
|---|---|---|
| Använd / sitt upp | `E` | `ANVÄND` |
| Skänkel fram / bak | `W` / `S` | spaken |
| Styr | `A` / `D` | spaken |
| Tygel (kontakt) | `Mellanslag` | `TYGEL` |
| Sits lätt / djup | `Shift` / `Ctrl` | `LÄTT` / `DJUP` |
| Halvhalt | `E` | `HALVHALT` |
| Lättridning | `R` | `LÄTTR.` |
| Diagonal | `Q` | `DIAG` |
| Nästa moment | `N` | `NÄSTA` |
| Byt vy | `V` | `VY` |
| Kontrollhjälp | `H` | panelens *Stäng* |
| **Gångart** | *inget eget reglage* | *inget eget reglage* |
| **Hoppa** | *inget eget reglage* | *inget eget reglage* |

## De två raderna utan reglage

Webben har **ingen gångartsknapp och inget hoppreglage**, och det är ett
produktval, inte ett hål:

- **Gångarten följer skänkeln och tygeln.** Spelaren ber om mer eller
  mindre gång, och övergångsmodellen i `src/riding/` avgör när bytet
  sker. Roblox har i stället en uttrycklig begäran (`LeftShift`/`R1`).
- **Avsprånget kommer ur anridningen.** Webben har ingen hoppknapp;
  hoppet avgörs av hur hästen rids fram mot hindret. Roblox har ett
  hoppreglage (`Space`/`ButtonA`).

Det här är en **verklig skillnad i inputsemantik**, och den ska inte
jämnas ut. Att lägga en gångartsknapp på webben, eller att ta bort
Roblox hoppknapp, vore en ändring av hoppfysik och bedömning — inte en
kontrollförbättring. `CLAUDE.md`:s paritetsregel tillåter uttryckligen
att inputadapter och UI är plattformsspecifika; det är kärnloopen,
hästlogiken och lärandet som ska motsvara varandra, och de gör det.

Kontrollhjälpen på båda ytorna säger detta rakt ut i stället för att
uppfinna en tangent: raderna står med texten *"följer skänkeln och
tygeln"* respektive *"avsprånget kommer ur anridningen"*.

## Regler som gäller på båda ytorna

1. **Reglagen följer inmatningen, inte plattformen.** En ren pekenhet får
   aldrig en bokstav hon inte kan trycka på; en iPad med tangentbord får
   den. Ordningen är tangentbord → gamepad → touch.
2. **En begäran är en flank, inte en ström.** En hållen gångartsknapp ger
   **ett** steg. Mätt i `roblox/tests/touch.spec.luau`, inklusive att 120
   bildrutor inte ger fler begäranden än 10 — bildrutetakten ändrar inte
   upplevelsen.
3. **Ingen begäran överlever en avsittning.** `Input.unbind()` nollar även
   `_upEdge`/`_downEdge`. Att den inte gjorde det var ett verkligt fel:
   en spelare som tryckte Shift och satt av fick gångartsbytet på första
   bildrutan efter nästa uppsittning.
4. **En panel som står uppe styr inte hästen.** Under kort och ridanalys
   fryses ridningen, och `Input.consume()` körs ändå och kastas så att
   engångsflankerna inte sparas till efter pausen.
5. **Minst 44 px träffyta** på varje knapp spelaren måste kunna nå.

## Not tested

Matrisen är läst ur källan och provad headless. Att tangenterna känns
rätt i handen, att gamepadens knappar sitter där fingret väntar sig dem,
och att pekknapparna går att träffa under en ritt på en riktig iPad är
`NOT_TESTED` — Studio, fysisk touch och fysisk gamepad är separata
manuella grindar.
