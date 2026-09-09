# G02-D — ridanalys, positiv feedback och replay

Status: `READY_FOR_CHATGPT_REVIEW` (builder-status; ingen självsatt acceptans).
Gren: `claude/g02-d-integration-20260909`, utgången ur #143 @ `87cad71`
med `claude/g02-d-ridanalys` @ `6bc25fd` **inmergad** — ingen fil ersatt i
klump. PO-beslut 2026-09-07 15:12 på #135, spec i `docs/RIDANALYS.md`
(PR #137 @ `f211617`). Acceptanstracker: #137.

Leveransen är en **vertikal slice**, inte hela G02-D: två övningar,
en mätning, en frivillig replay, ett uttryckligt val — nu på **båda**
ytorna.

## Integrationen mot P0

Grenen bygger på #143:s P0-arbete och behåller det:
`IN.styrDigital`/`IN.styrKansla` och `InputFeel.ride()` i `stegaInput`,
`src/input-feel.js` med sin script-tagg, och hela P0-QA-kedjan
(`forstadagentest`, `lastlagetest`, `gardtest`, `p0-qa-runner`). De två
sidorna rör olika delar av `src/game.js` — #143 inputlagret (rad 47–135),
G02-D lektionens lifecycle (rad 160 och framåt) — så mergen är en riktig
sammanslagning, inte ett val mellan dem.

**Ingen självskrivande workflow.** `.github/workflows/g02-d-complete-builder.yml`
finns inte på den här grenen och ska inte återinföras. Den checkade ut 14
filer från en rörlig gren, körde en generator och tre regex-patchar, och
testade alltså **en annan källa än den som var committad**. Grinden här är
`grindar.yml` och `ugneta.yml` — vanlig read-only CI på det utcheckade
commit:et.

`chatgpt/p0-control-feel-20260908`-grenens `p0-control-apply.yml` följde med
från #143. Den är låst till sin egen gren och fyrar inte här, men den har
samma form och bör städas av sin ägare — den är inte den här PR:ens att ta
bort.

## Vad som byggts

| Del | Fil | Vad den gör |
|---|---|---|
| Övningsdefinition | `src/riding/ovningsdef.js` | Versionerad definition av `storvolt` och `trav_skritt`. Motoroberoende. Säger vad övningen mäter — och vad den **inte** bedömer. |
| Inspelning | `src/riding/inspelning.js` | Skriver ned ritten i 20 Hz och spelar upp den read-only. |
| Ridanalys | `src/riding/ridanalys.js` | Mäter den ridna vägen: cirkelanpassning, avvikelse, sträcka, varv, gångartsbyten. **Bedömer ingenting.** |
| Val efter försöket | `src/replayvy.js` | Prova igen · Se ritten · Gå vidare. Pausar lektionen medan spelaren väljer. |
| Replayvy | `src/replayvy.js` | Spela/pausa, halv fart, spolning, ghost av eget förra försök, läsbar tabell, reduced motion. |

## Vad som INTE byggts

- **Den validerade ekipageanpassade referensen.** `ovningsdef.js` har
  `referens: null` för båda övningarna och påstår ingen. Ghosten är
  spelarens **eget** förra försök — en riktig ritt, inte en påhittad
  perfekt rörelse. En referens som varken är mätt på UBRF eller
  härledd ur en verifierad källa vore just det specen förbjuder.
  `[REFERENCE GAP]` tills underlag finns.
- De fyra övriga G02-C-övningarna har ingen versionerad definition och
  spelas därför med flit inte in. Det gäller nu båda ytorna: Roblox
  läser samma lista ur `RidKanon.INSPELNING.OVNING`.
- **Kameraval i replayen.** Se `## Kamerval`.

## Bedömningen är fortfarande Ugnetas

Ridanalysen mäter, `ugnetaKvalitet()` bedömer. Det finns **ingen andra
bedömningsväg**: analysen returnerar meter, sekunder och andelar, och
UI:t sätter ord på dem. Tröskeln `RIDANALYS_MARKBAR_M = 0.5` är en
läsbarhetsgräns för när en mening är värd att skriva — den står med
flit utanför `UGNETA_KVALITET` och ändrar inget omdöme.

Säkerhet och hästvälfärd är överordnade: ett säkerhetsrop tar över hela
lärarytan och släcker live-chipet (`ugnetaAterstallSagaUX`), oberoende
av vad mätningen visar.

## Paritet mot Roblox

| Regel | Webb | Roblox |
|---|---|---|
| Omridningen är spelarens uttryckliga val | `visaForsokVal` pausar och frågar | `fortsattning()` i `LektionController.luau` kallar `Lektion.vidare` på spelarens knapp/tangent/gamepad |
| Momentet betygsätts en gång, inte per försök | `momentBetygsatt()` anropas från exakt ett ställe per väg ut | `Lektion.avslutaForsok` + `Lektion.vidare` |
| Två försök på en känd övning | ja | ja (`pass.forsokNr < 2`) |
| "Gå vidare" — hoppa över omridningen | `momentGaVidare()` | `Lektion.hoppaOver` + `UgnetaController.gaVidare` |
| "Se ritten" — frivillig replay | `src/replayvy.js` | `client/ReplayController.luau` |
| Ritten spelas in en gång, versionerat | `src/riding/inspelning.js` | `HorseCore/Inspelning.luau` |
| Schema och övningsversion | `INSPELNING_SCHEMA`, `OVNINGAR_DEF[*].version` | **samma tal**, exporterade till `RidKanon.INSPELNING` av `tools/exportera-ridkanon.mjs` |
| Spöket är spelarens eget förra försök | ja | ja |
| Hästen står stilla bakom panelen | `G.paus` i `loop()` | frysningen i `init.client.luau` |
| Mindre rörelse startar inte uppspelningen | ja | `GuiService.ReducedMotionEnabled` |

De två rader som saknades på Roblox i förra rundan är byggda nu.
Definitionens version finns bara på **ett** ställe: webbens
`ovningsdef.js`. Roblox läser den ur den exporterade kanonen, och
`node tools/exportera-ridkanon.mjs --kontrollera` blir röd om de glider
isär.

Rendering skiljer sig med flit: webben ritar banan i 2D-canvas, Roblox i
GUI-frames. Det är renderingsskillnad, inte regelskillnad — och tillåtet
enligt paritetsregeln.

## Roblox: felet CI föll på

Klient-specen föll i CI (run `34186458506`, `342d3c9`) med
`attempt to index nil with 'aktiv'` ur `RenderStepped`. **Orsaken var
varken posen eller produktionskoden.** `ReplayController` och
`Inspelning` lades in i EN av bunterna i `roblox/tests/build.py`
(`PARITET`) men inte i `KLIENT`. `LektionController` require:ar bägge, så
i klientbunten blev require:t `nil` — och symptomet dök upp först i
loopen, långt ifrån orsaken.

Rättelsen är att båda modulerna står i **båda** listorna, i
beroendeordning, och att `Inspelning` läggs in i `__Core` som de andra
delade modulerna. Ingen produktionskod ändrades för att laga det, och
inget prov försvagades.

Posefrågan var alltså aldrig felet — men den är ändå besvarad på egna
meriter: `Inspelning.sampla` validerar posen **fält för fält**, så en
pose där positionen är omätbar men girningen är ett riktigt tal
**behåller girningen**. Att kasta hela posen på ett trasigt fält hade
tappat en yaw som faktiskt var mätt; att fylla i noll hade påstått ett
läge och en riktning som ingen mätt. Fältet blir `nil`.

## Testbevis

Alla siffror från grenens head. Kommandon i `docs/TOOLCHAIN.md`.

| Grind | Mätningar |
|---|---|
| `node tools/replaytest.mjs` | 39 (från 16) — kör det byggda spelet i Chromium och **klickar i sidan** |
| `bash roblox/tests/kor.sh` → `klient` | +45 mätningar för G02-D, alla genom `init.client.luau` och dess `RenderStepped` |
| `node tools/ugneta-forsok-test.mjs` | 18 (från 16) |
| `node tools/inspelningstest.mjs` | 60 |
| `node tools/ugnetatest.mjs` | alla OK |
| `node tools/ridtest.mjs`, `gardtest`, `uppdragstest`, `laktartest`, `bootkoll`, `ugneta-ui-test`, `kolla-ankare` | alla OK |
| `bash roblox/tests/kor.sh` | 16 specar |

### Falsifiering

Varje mutation infördes ensam, med en grön kontrollkörning före och
efter. Ett skript kontrollerar att mutationen **landade** — en tidigare
runda i den här PR:en visade "grönt under mutation" som i själva verket
var en mutation som aldrig skrevs.

| # | Mutation | Utfall |
|---|---|---|
| M1 | Panelen tar inte över — lifecyclen rider om automatiskt | RÖD (efter att provet skärpts; se nedan) |
| M2 | Försök 2 spelas inte in | RÖD, 16 FEL |
| M3 | Försöket stängs inte av lifecyclen (`ugnetaStangForsok`) | RÖD, 11 FEL |
| M4 | `G.paus` gör ingenting — hästen rider vidare bakom panelen | RÖD, 8 FEL |
| M5 | Betyget sätts en gång per försök | RÖD i båda sviterna |
| M6 | Ghosten sätts aldrig | RÖD |
| M7 | Mindre rörelse ignoreras | RÖD |
| M8 | Tillbaka lämnar spelaren utanför valet | RÖD |
| M9 | Uppspelningen skriver tillbaka i den levande ritten | RÖD |
| M10 | Den läsbara tabellen tas bort | RÖD |
| M11 | Slutpanelens Gå vidare betygsätter en gång till | RÖD |

**M1 var först GRÖN.** Assertionen räknade `paneler >= 1` och
slutpanelen räckte för att uppfylla den. Provet mäter nu klicket på
"Prova igen" och vilket försök som stod på när det gjordes.

**M3 var först GRÖN och avslöjade att `ugnetaStangForsok()` saknade
prov.** I den normala vägen hinner `lararSteg` stänga försöket ändå.
Vägen där funktionen behövs är tangenten **N** (hoppa över momentet):
då är varken `G.momentKlart` sant eller taket nått. Provet trycker nu
på tangenten.

### Falsifiering — Roblox

Samma disciplin på Luau-sidan. Varje mutation ensam, grön körning före
och efter.

| # | Mutation | Utfall |
|---|---|---|
| R1 | `ReplayController` ur `KLIENT`-listan | RÖD — `attempt to index nil with 'aktiv'`, **exakt CI-felet** |
| R2 | `Inspelning` ur `KLIENT`-listan | RÖD — samma fel |
| R3 | Posen kastas i klump när ett fält är trasigt | RÖD, 2 FEL |
| R4 | Pausen borttagen — hästen rider vidare bakom kort och panel | RÖD, 2 FEL |
| R5 | `Gå vidare` bedömer om momentet | RÖD, 1 FEL — `2 post i historiken` |
| R6 | `stang` kör återanropet före nollningen | RÖD, 1 FEL — `2 anrop` |
| R7 | Mindre rörelse ignoreras | RÖD, 1 FEL |

**R4 var först GRÖN, och det var provets fel.** Frysprovet läste
`pass.tid`, som står stilla ändå: `LektionController.steg` returnerar
redan tidigt när kortet väntar. Provet mäter nu humanoidens `Move`-anrop
— produktionens egen väg ut mot Roblox — med en kontrollmätning som visar
att räknaren går upp när ridningen är igång (`3303 Move-anrop`). Först då
blev R4 röd.

**R6 dödade först hela specen** i stället för att peka på felet: det
felaktiga anropet återinträdde utan botten. Provets återanrop gör nu
exakt ett återinträde, så mutationen ger en läsbar FEL-rad.

## Kamerval

Specen säger "camera choice **where supported**". Replayen ritar den ridna
vägen ovanifrån i planvy — på båda ytorna. Det finns ingen kamera att välja,
och en påhittad kameraväxel som inte gör något vore sämre än ingen.

På Roblox **skulle** en uppspelning kunna följa hästen i 3D, och då blir
kameravalet en riktig fråga. Den här leveransen bygger den inte: en 3D-replay
kräver att ekipaget spelas upp i världen, alltså en andra häst eller ett
spöke i workspace, och det är ett eget scope med egna säkerhets- och
prestandafrågor. `[antagande]` att planvyn räcker för att lära sig formen på
en volt — det är Tobias att avgöra.

## Not tested

- **Roblox Studio.** Ingen Studio-åtkomst i den här sessionen. Luau-specarna
  körs headless och säger ingenting om runtime-känsla, om hur panelen SER ut
  eller om den är läsbar på en telefonskärm. `NOT_TESTED`.
- **Roblox-bänken kör ingen fysik.** `humanoid:Move` spelas in men flyttar
  ingen rigg. Där ritten behöver en utsträckning flyttar `klient.spec.luau`
  riggens root själv, och det står i specen. Panelens bana är därför inget
  bevis för rörelsemodellen — den mäts i `movement.spec`.
- **Roblox reduced motion mot en riktig klientinställning.** Provet sätter
  `GuiService.ReducedMotionEnabled` i en stub. Att egenskapen finns och
  läses på en riktig klient är `NOT_TESTED`.
- **Fysisk touch och gamepad.** Emulering är inte en enhet.
- **Game feel i replayen** — om det känns bra att se sin egen ritt är
  Tobias avgörande, inte ett prov.

### Körbart testprotokoll (människa)

1. Starta en lektion och rid fram till **20 m volten**.
2. Låt försöket ta slut. **Förväntat:** lektionen stannar, hästen står
   still, och en panel visar Ugnetas två punkter samt
   *Prova igen · Se ritten · Gå vidare*.
3. Tryck **Se ritten**. **Förväntat:** din väg ritas ut, uppspelningen
   startar, tidsläget räknar. Pausa, halvera farten, spola med reglaget.
4. Tryck **Tillbaka**. **Förväntat:** du är åter i valet, inte i ritten.
5. Tryck **Prova igen** och rid volten en gång till.
6. **Förväntat efter försök 2:** panelen visar *Se ritten och jämför*,
   och i replayen ligger ditt förra försök som streckad linje. Knappen
   "Dölj förra försöket" släcker den.
7. Slå på **mindre rörelse** i operativsystemet och gör om steg 3.
   **Förväntat:** uppspelningen startar inte av sig själv, och samma
   mätvärden står i tabellen till höger.
8. Tryck **N** mitt i ett försök. **Förväntat:** den påbörjade ritten
   går att se om — den ska inte vara förlorad.

### Samma protokoll på Roblox (Studio)

1. Sitt upp och rid fram till **20 m volten** genom lektionens egna kort.
2. Låt försöket ta slut. **Förväntat:** hästen står still, kortet visar
   Ugnetas punkter och tre knappar — *Prova igen · Se ritten · Gå vidare*.
   Tangenterna är **R**, **T** och **G**; gamepad **Y** och **X**.
3. Tryck **Se ritten**. **Förväntat:** din väg ritas i planvy och
   uppspelningen startar. Spela/pausa, −5 s, +5 s, 0,5×.
4. **Förväntat medan panelen är uppe:** hästen rör sig inte, och ett
   styrkommando under pausen fyrar inte när du stänger panelen.
5. Tryck **Tillbaka** (eller **R**). **Förväntat:** kortet står kvar och
   valet är fortfarande ditt.
6. Tryck **Prova igen**, rid volten igen, öppna analysen. **Förväntat:**
   ditt förra försök ligger bakom i gult.
7. Sitt av (**E**) medan analysen står uppe. **Förväntat:** panelen och
   kortet släcks omedelbart.
8. Tryck **Gå vidare** efter försök 1. **Förväntat:** nästa övning
   presenteras, och betyget för den överhoppade övningen räknas **en**
   gång.

Rapportera avvikelse med steg-nummer och vad som hände i stället.
