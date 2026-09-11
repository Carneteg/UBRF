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
| Sitt upp / sitt av | `E` | `DPadDown` (styrkors ned) | `SITT AV` |
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
| Kontrollhjälp — öppna/stäng | `H` | `DPadUp` | `?`-knappen uppe till höger |
| Kontrollhjälp — stäng | `H` | `DPadUp` | panelens *Stäng* |
| Skötselmoment | — | — | momentknapparna i skötsel-HUD:en |
| Eftervårdsmoment | — | — | samma knappar, efter avsittning |

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
6. **Hjälpen går alltid att öppna igen.** En panel som bara går att stänga
   är en engångsruta, och det var precis felet #153 rapporterade som
   P2-4b: `H` fanns, men på en iPad utan tangentbord fanns ingen väg
   tillbaka när panelen väl var bortstängd.

## Styrkorsets knappar — varför `DPadUp` och `DPadDown`

`DPadUp` valdes för #161 (hjälpen) och `DPadDown` för #162 blockerare 2
(avsittningen) därför att de är **lediga**, och det är kontrollerat mot
källan, inte antaget:

| Bunden | Av | Till |
|---|---|---|
| `Thumbstick1` | `Input.luau` | styrning och framåt |
| `ButtonA` | `Input.luau` | hopp |
| `ButtonB` | `Input.luau` | halvhalt |
| `ButtonR1` / `ButtonL1` | `Input.luau` | gångart upp / ner |
| `ButtonR2` | `Input.luau` | tygel |
| `ButtonL2` | `Input.luau` | sits |
| `ButtonY` | `init.client.luau` | lektionen vidare |
| `ButtonX` | `init.client.luau` | se ritten |

Styrkorset rörs av ingen av dem. `ButtonStart` och `ButtonSelect`
valdes bort trots att de också är obundna i UBRF: de är reserverade av
Roblox egna menyer på konsol, och en hjälpknapp som ibland öppnar
Roblox-menyn i stället är sämre än ingen.

### Avsittningen (#162 blockerare 2)

Fram till #162 fanns **ingen** gamepadväg av hästen. `begarAvsittning`
var bunden till `E` och inget annat, medan uppsittningen går genom en
ProximityPrompt som handkontrollen når utan problem. En spelare med bara
handkontroll kom alltså upp på hästen och satt kvar där. Kontrollhjälpen
gjorde det värre genom att skriva `E` i gamepadkolumnen — en tangent
presenterad som ett reglage.

`DPadDown` är resten av styrkorset efter hjälpen, och paret läser sig
självt: hjälpen upp, av hästen ned. Ingen befintlig rid-, hopp-,
replay-, lektions- eller hjälpbindning ändrades.

Ledtexten i panelen **härleds** numera ur bindningen
(`KontrollHjalp.AVSITTNING_GAMEPAD` → `PADNAMN`), så texten och
reglaget kan inte glida isär igen. Det var den andra halvan av samma
blockerare.

**Ingen befintlig rid-, hopp- eller replaybindning har flyttats** för att
göra plats. Det var ett uttryckligt krav i #161.

`roblox/tests/klient.spec.luau` läser `KontrollHjalp.GAMEPADKNAPP` ur
modulen, kontrollerar att den inte finns i listan ovan, och fyrar den
genom klientens egen `InputBegan` — så tabellen här går att kontrollera
mot källan i stället för mot minnet.

## Skötselns moment (#161)

Skötseln kvitteras inte längre med ett tryck per fas. Varje fas har
**moment**, och de trycks på i skötsel-HUD:en:

| Fas | Moment | Ordningskrav |
|---|---|---|
| Hälsa lugnt | de tre framgångssätten | ett **val**, inte en lista |
| Visitera | fem punkter | strikt, framifrån och bakåt |
| Rykta | tre redskap × sina zoner | **redskapsordningen** är strikt, zonordningen fri |
| Gör i ordning | fyra hovar, sedan fyra utrustningssteg | strikt |
| Led till ridhuset | ett moment | — |
| Eftervård | fem steg efter avsittning | strikt |

Momenten **härleds ur `src/spel/skotsel.js`**, inte ur en Luau-lista. En
ny visitpunkt i JS-källan blir ett moment på Roblox utan att en rad Luau
ändras.

Momentknapparna är 44 px höga (`PreparationController.TRAFFYTA`).
Fasraderna ovanför dem är **inte** tryckbara — de är en lägesvisning, och
behöver därför inte samma yta.

### Var HUD:en ligger (PO-order 09:36)

Skötsel-HUD:en är **två ytor med olika livslängd**, inte en panel:

| yta | plats | när |
|---|---|---|
| spåraren | uppe till höger, hopfälld 300×60 px | alltid |
| spåraren utfälld | samma hörn, högst 45 % av skärmhöjden | när spelaren fäller ut den |
| interaktionspanelen | centralt nedtill, högst 420×300 px | **bara** medan spelaren står inom räckhåll och har något att välja på |

Hopfälld visar spåraren målet och `3/5`. Hela huvudraden är växlingsknappen
— 44 px, ett tryck var som helst på rubriken. Utfälld lägger den till
faslistan (som rullar när den inte ryms) och en kort hjälptext.

`PreparationController.SIKTRUTA` är kontraktet i tal: mitten av skärmen
(x 0,30–0,70, y 0,25–0,85), där avataren står och dit man tittar. Den
**hopfällda** spåraren får aldrig gå in i den, och `varldshud.spec` mäter
det på iPad (liggande och stående), laptop, skrivbord och telefon. Den
utfällda spåraren och interaktionspanelen får — båda är tillfälliga och
båda är spelarens eget beslut.

Spåraren börjar under `KontrollHjalp`s `?`-knapp: topbarens inset + 12 px
marginal + 48 px knapp + 8 px luft. Modulerna känner inte varandra, så
`klient.spec` mäter i stället att rutorna inte krockar — i skärmens
koordinater, eftersom de två ScreenGui:erna hanterar topbaren olika.

## Not tested

Matrisen är läst ur källan och provad headless. Att tangenterna känns
rätt i handen, att gamepadens knappar sitter där fingret väntar sig dem,
och att pekknapparna går att träffa under en ritt på en riktig iPad är
`NOT_TESTED` — Studio, fysisk touch och fysisk gamepad är separata
manuella grindar.

Särskilt `NOT_TESTED` efter #161, och uttryckligen inte omskrivet till
PASS:

- att `DPadUp` faktiskt fyrar på en fysisk handkontroll (bänken fyrar
  `InputBegan` själv — den provar bindningen, inte hårdvaran),
- att `?`-knappen uppe till höger går att träffa med tummen medan man
  håller i en iPad, och att den inte hamnar under Roblox egen topbar på
  en enhet med hak,
- att skötselns momentlista går att rulla och trycka på under ett riktigt
  pass, med två tummar samtidigt.
