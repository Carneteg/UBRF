# G02-D — ridanalys, positiv feedback och replay

Status: `READY_FOR_CHATGPT_REVIEW` (builder-status; ingen självsatt acceptans).
Gren: `claude/g02-d-ridanalys`. PO-beslut 2026-09-07 15:12 på #135, spec i
`docs/RIDANALYS.md` (PR #137 @ `f211617`).

Leveransen är en **vertikal slice**, inte hela G02-D: två övningar,
en mätning, en frivillig replay, ett uttryckligt val.

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
- **Roblox-paritet för definitionen** (`RidKanon`-export) och
  inspelning/replay på Roblox. Se paritetsredovisningen nedan.
- De fyra övriga G02-C-övningarna har ingen versionerad definition och
  spelas därför med flit inte in.

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
| Omridningen är spelarens uttryckliga val | **nytt i den här leveransen** — `visaForsokVal` pausar och frågar | fanns redan: `fortsattning()` i `LektionController.luau` kallar `Lektion.vidare` på spelarens knapp/tangent/gamepad |
| Momentet betygsätts en gång, inte per försök | `momentBetygsatt()` anropas från exakt ett ställe per väg ut | `Lektion.avslutaForsok` + `Lektion.vidare` |
| Två försök på en känd övning | ja | ja (`pass.forsokNr < 2`) |
| "Gå vidare" — hoppa över omridningen | ja | **saknas** |
| "Se ritten" — frivillig replay | ja | **saknas** (ingen inspelning på Roblox ännu) |

Webben rörde sig alltså **mot** Roblox modell, inte ifrån den: det var
webben som red om automatiskt. De två raderna som saknas på Roblox är
nya på båda ytorna och hör till ett senare steg i G02-D; de är inte
webb-only-features som smugit in bakvägen.

## Testbevis

Alla siffror från grenens head. Kommandon i `docs/TOOLCHAIN.md`.

| Grind | Mätningar |
|---|---|
| `node tools/replaytest.mjs` | 39 (från 16) — kör det byggda spelet i Chromium och **klickar i sidan** |
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

## Kamerval

Specen säger "camera choice **where supported**". Replayen ritar den ridna
vägen ovanifrån i 2D — det finns ingen kamera att välja, och en påhittad
kameraväxel som inte gör något vore sämre än ingen. På Roblox, där en
uppspelning skulle kunna följa hästen i 3D, är kameravalet en riktig fråga och
hör till det steg som bygger inspelning där.

## Not tested

- **Roblox Studio.** Ingen Studio-åtkomst i den här sessionen. Luau-specarna
  körs headless och säger ingenting om runtime-känsla.
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

Rapportera avvikelse med steg-nummer och vad som hände i stället.
