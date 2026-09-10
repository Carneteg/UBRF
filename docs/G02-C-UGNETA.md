# G02-C — Ugneta: pedagogik och feedbackkontrakt

## Instruktören
Ugneta är en äldre kvinnlig ridinstruktör med grått hår och glasögon. Hon är den återkommande läraren under ridträning.

**Ugneta talar inte.** Raden ovan stod tidigare som "den återkommande
lärarrösten", vilket var menat bildligt — men spelet hade samtidigt en
faktisk uppläsning: `ljudRost()` i `src/ljud.js` läste hennes repliker med
webbläsarens svenska talsyntes. Formuleringen kunde alltså läsas som ett stöd
för den, och det ska den inte kunna.

Tobias produktbeslut 2026-09-10 (issue #161): **ingen röst får agera
ridlärare.** Uppläsningen är borttagen. Ugnetas repliker, rubriker, punkter och
säkerhetsrop är oförändrade och står kvar som SKRIVEN text — beslutet gällde
rösten, inte pedagogiken. Hela feedbackkontraktet nedan är alltså intakt.

Ersätt den inte med inspelad röst, en annan talsyntes, Roblox uppläsning eller
en AI-röst; `tools/rostgrind.mjs` faller om något av det kommer tillbaka.

## Pedagogisk grundregel
Under aktiv ridning ska eleven aldrig behöva läsa en lång förklaring.

Varje lärarmeddelande ska bestå av:
- en kort rubrik
- 1–2 konkreta punkter
- ett enda prioriterat fokus åt gången

Säkerhetsinstruktioner går alltid före undervisning.

## Träningsloop
`instruktion → utförande → mätning → bedömning → feedback → nytt försök → förbättring`

Feedback ska komma från faktisk ridstate/telemetri. Ingen slumptext får användas för att välja korrigering.

## Första lektionspaketet
1. Halt → skritt
2. Skritt → trav
3. 20 m volt
4. Hörn med bibehållen rytm
5. Trav → skritt
6. Enkel galoppfattning

## Hur Ugneta pratar
Bra:
- “Lätta lite i handen.”
- “Behåll rytmen genom hörnet.”
- “Bra — kontakten blev mjuk och jämn.”
- “Förbered först. Be sedan en gång.”

Undvik:
- flera fel i samma meddelande
- långa stycken medan hästen rör sig
- generiska poäng eller “bra jobbat” utan orsak
- att skylla hästens reaktion på eleven när datan visar annat

## UX-kontrakt
Feedbackkortet ska:
- vara läsbart på mobil, surfplatta och dator
- inte täcka centrala ridytan mer än nödvändigt
- skala typografi och porträtt efter viewport
- fungera även på låg landscape-skärm
- visa Ugneta tydligt som avsändare
- begränsa aktiv feedback till högst två punkter

## Bedömning
G02-C bedömer kvalitet, inte bara completion. Dimensioner:
- väg/linje
- rytm
- tempo
- balans
- hjälper/timing
- övergångens mjukhet
- hästens respons/fokus/spänning

20 m volt ska minst väga linje + rytm + balans. Övergångar ska minst väga timing + mjukhet + hästens respons.

### Vad varje yta faktiskt kan mäta
Bedömningen ska komma ur telemetri, inte ur en siffra som ser ut som
telemetri. Därför gäller: **en dimension utan källa på en yta är omätt,
inte noll.** En nolla hade gjort den till den svagaste i varje övning,
och läraren hade kommenterat något hon aldrig sett.

Roblox saknar utbildningsskalan (`src/model.js`) och mäter därför ingen
`rytm`; `linje` bygger bara på den mätta svängradien. Luckan är
deklarerad i `HorseCore/Lektion.SAKNAS` och provad — den får inte växa
fram i tysthet.

## Försök 1 → försök 2
När samma övning görs igen ska Ugneta prioritera faktisk förbättring, till exempel:
- “Övergången blev mjukare.”
- “Bättre rytm, men volten faller fortfarande inåt.”

Högst två prioriterade observationer visas samtidigt.

## Var Ugneta står
Vid C, strax bortom dressyrlayoutens kortsida — alltså utanför ridvägen,
på den del av den fysiska ridytan som fortsätter förbi 60-m-linjen.
Punkten är kanon (`RidKanon.UGNETA.PLATS`) och löses upp mot banans egna
mått på båda ytorna; på Roblox räknas den fram genom att mäta mellan de
byggda delarna, inte ur en andra modell av huset.

`[antagande]` Att UBRF:s instruktör står just vid C är inte belagt i
referensmaterialet. Ytan är verifierad; valet av punkt på den är det
inte, och ersätts när evidens finns.
