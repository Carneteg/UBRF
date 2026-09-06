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

## Kvar innan PRODUCT_ACCEPTED
- Full produktionsväg ska verifieras med två faktiska försök av samma övning i webbspelet.
- Human UX-test på liten mobil, surfplatta och desktop.
- Kontroll att Ugneta-kortet inte skymmer ridväg, vägvisare eller kritiska säkerhetsmeddelanden.
- Roblox-sidan ska få motsvarande G02-C-bedömningskontrakt innan hela G02-C kan kallas plattformsparitet.

Grön CI betyder att pedagogik-/UX-kontraktet och kvalitetsmotorn håller tekniskt. `PRODUCT_ACCEPTED` kräver fortfarande Tobias gameplay-test.
