# G02-C Ugneta — implementationsstatus

## Implementerat
- Ugneta är namngiven instruktör.
- Äldre kvinna, grått hår och glasögon representeras i lärar-UX.
- Aktiv instruktion är rubrik + högst två korta punkter.
- Mobil, surfplatta, desktop och låg landscape har responsiva regler.
- Första sex övningarna har korta ridinstruktioner.
- Lärarfeedback väljs deterministiskt från ridstate, inte slumpmässigt.
- Beröm anger vad som faktiskt förbättrades.
- Ett fokus åt gången och säkerhet går före undervisning.
- Försök lagras separat per övning.
- Försök 2 jämförs mot försök 1 från samma telemetry.
- Jämförelsefeedback prioriterar högst två observationer.
- 20 m volt bedömer explicit linje + rytm + balans.
- Övergångar bedömer explicit timing + mjukhet + hästens respons.
- Vanliga och säkerhetskritiska meddelanden återställer Ugneta-styling innan de visas.

## UX-beslut 1 + 3 (Tobias 2026-09-06, #119)
- Ugneta står **fysiskt vid sargen** under lektionen. Punkten kommer ur
  `ugnetaPlats()` och läses av både 3D-vyn (`src/scen3d.js`) och kartan
  (`src/render.js`) — en sanning, inte två uppfattningar om var hon står.
  Hon är borta under tävling, där en domare står i stället.
- **Live under ridning**: ett litet chip med några ord (`Mjukare hand`,
  `Bra rytm`, `Precis så`). Inget porträtt, ingen rubrik, ingen panel.
  Det som fanns före den här rundan var i praktiken variant 2 — hela
  kortet mitt under ridningen — och den varianten valdes inte.
- **Mellan försöken** visas hela kortet. Efter försök 1: högst en sak
  som var bra, en att förbättra och ett tydligt `Prova igen`. Efter
  försök 2: en konkret jämförelse mot försök 1.
- Ett säkerhetsrop släcker live-chipet och återställer vanlig UI.

## Försök 1 → 2 i produktionsflödet
En känd G02-C-övning rids två försök genom **ordinarie** moment-lifecycle
(`stegaLektion` i `src/game.js`): samma moment-objekt, samma mätning,
explicit nollställning av försökets ackumulator mellan försöken. Betyget
sätts först på sista försöket — ett moment som rids om ska inte räknas
två gånger i `bedomda`/`klarade`.

## Roblox-paritet
Bedömningskontraktet exporteras ur `src/larare.js` till
`RidKanon.UGNETA` av `tools/exportera-ridkanon.mjs`.
`roblox/src/shared/HorseCore/Ugneta.luau` läser den kanonen i stället
för att bära en egen lista, och `roblox/tests/paritet.spec.luau` blir
röd om dimensionerna skiljer sig eller kanonen inte regenererats.

Kanonen bär nu också övningarnas ordning och text, live-ordförrådet,
kopplingen dimension → cue, kvalitetsformelns tal och trösklarna
(`BATTRE`, `SVAG`, `BRA`). Det som tidigare var handskrivna kopior i
Luau — live-registret i `UgnetaController`, trösklarna i `Ugneta.luau`
— läses därifrån.

## Roblox-lektionen är inkopplad i klientens egen loop
`roblox/src/shared/HorseCore/Lektion.luau` är försökslifecyclen: den
mäter kvaliteten ur `HorseCore/Telemetri`, avgör när ett försök är slut,
nollställer explicit inför försök 2 och väljer live-cue.
`roblox/src/client/LektionController.luau` binder den till UX:en, och
`init.client.luau` startar den i `mount`, stegar den i sin ENDA
`RenderStepped`-loop och släcker den i `dismount`.

`roblox/tests/klient.spec.luau` kör faktiskt `init.client.luau`: den
fyrar `MountChanged`, driver `RenderStepped` och läser vad spelaren ser.
Tas raden `LektionController.steg(...)` bort blir specen röd med 6 fel;
tas `LektionController.start(...)` bort blir den röd med 7; tas
`LektionController.avbryt()` bort med 3.

### Deklarerade skillnader mot webben
Uppräknade i `Lektion.SKILLNAD`, provade av specen:
1. **Live-cuens ingång.** Webben väljer cue ur passets fokus
   (`LARARE.fokus`), som kommer ur ryttarmodellen `fard()`. Roblox har
   ingen ryttarmodell ännu och väljer ur den svagaste MÄTTA dimensionen
   i övningens kontrakt. Samma ordförråd, samma tabell, annan ingång.
2. **Rytmen är inte mätt** (`Lektion.SAKNAS`). Webbens `rytm` och halva
   `linje` kommer ur utbildningsskalan i `src/model.js`; Roblox har ingen
   sådan modell. En omätt dimension är `nil`, inte 0 — annars hade rytmen
   blivit svagast i varje 20 m volt och Ugneta tjatat om en takt hon
   aldrig sett.

## Ugnetas plats flyttad från A till C
Punkten kommer ur `RidKanon.UGNETA.PLATS` och löses upp mot banans mått
på båda ytorna. Den flyttades i den här rundan, och skälet är
geometriskt: webbens lektionsscen är en abstrakt 20 × 60-bana där det
finns plats 1,4 m bortom kortsidan vid A, men i den verifierade
byggnaden ligger banans A-ände 0,15 m från gavelväggen. Vid C fortsätter
den fysiska ridytan 5,5 m bortom dressyrlayoutens 60-m-linje — vilket
`DRESSYRBOKSTAVER` redan dokumenterar för C. Verkligheten är facit, inte
abstraktionen.

`[antagande]` Att UBRF:s instruktör står just vid C är inte belagt i
referensmaterialet. Ytan är verifierad; valet av punkt på den är det
inte.

## Kvar innan PRODUCT_ACCEPTED
- Två faktiska försök av samma övning genom produktionsflödet är nu verifierat
  headless (`tools/ugneta-forsok-test.mjs`, 15 mätningar). Kvar är Tobias eget
  gameplay-test: att det KÄNNS som en lektion, inte bara att lifecycle stämmer.
- Human UX-test på liten mobil, surfplatta och desktop.
- Kontroll att Ugneta-kortet inte skymmer ridväg, vägvisare eller kritiska säkerhetsmeddelanden.
- **Roblox-UX finns nu** (`roblox/src/client/UgnetaController.luau`): live-chip
  under ridning, kort mellan försöken med `Prova igen`, säkerhet före
  undervisning, och observationerna ur `HorseCore/Ugneta`. Provad av
  `roblox/tests/ugneta.spec.luau` (15 mätningar) i bänken — **inte** körd i
  Studio. Att den ser rätt ut och känns rätt på en riktig klient är kvar.
- **Ugneta är igenkännbar på båda ytorna.** Webbens 3D har `S3.del.ugneta`
  (kavaj, ansikte, grått hår, glasögonbågar) och kartan samma. Roblox har
  `roblox/src/client/UgnetaGestalt.luau`: samma färger, samma drag, byggd
  av husets egna primitiver. Hon kolliderar inte, hon finns bara under
  lektionen, och hennes plats räknas ut genom att MÄTA mellan de byggda
  delarna "Ridbanan" och "Sarg syd" — inte ur en andra modell av huset.
  Provad av `roblox/tests/ugneta-gestalt.spec.luau` ovanpå den faktiskt
  byggda anläggningen.

Grön CI betyder att pedagogik-/UX-kontraktet och kvalitetsmotorn håller tekniskt. `PRODUCT_ACCEPTED` kräver fortfarande Tobias gameplay-test.
