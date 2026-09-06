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

## Kvar innan PRODUCT_ACCEPTED
- Två faktiska försök av samma övning genom produktionsflödet är nu verifierat
  headless (`tools/ugneta-forsok-test.mjs`, 15 mätningar). Kvar är Tobias eget
  gameplay-test: att det KÄNNS som en lektion, inte bara att lifecycle stämmer.
- Human UX-test på liten mobil, surfplatta och desktop.
- Kontroll att Ugneta-kortet inte skymmer ridväg, vägvisare eller kritiska säkerhetsmeddelanden.
- Roblox-sidan har nu kontraktet och paritetsprovet, men **ingen Roblox-UI**
  läser det ännu: `Ugneta.luau` är data och regler på plats, inte en byggd
  lärarupplevelse i Studio. Det är kvar innan G02-C är paritet i praktiken.
- Ugnetas gestalt vid sargen är personmeshen som publiken använder — inte
  en egen modell med grått hår och glasögon i 3D. Porträttet i kortet bär
  utseendet; världsfiguren är en markering av var hon står.

Grön CI betyder att pedagogik-/UX-kontraktet och kvalitetsmotorn håller tekniskt. `PRODUCT_ACCEPTED` kräver fortfarande Tobias gameplay-test.
