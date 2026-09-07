# UBRF — Alpha-produktprov

Status: TESTPLAN, inte PRODUCT_ACCEPTED. Product Owner: Tobias. Review: ChatGPT. Gameplay och integration: Claude. Miljö: Replit.

## Baseline och omfattning

Utgångspunkt: PR135, `d47f97be0e8532c67674556a73530a850d89b010`. Den slutliga test-SHA:n ska låsas efter godkänd integrationsreview och eventuella avgränsade rättelser. PR134:s miljö och den produktgodkända teorisalen är frysta. Ingen ny miljöslice eller allmän detaljpolering under detta prov.

Alpha ska pröva en sammanhängande, rolig och pedagogiskt korrekt hästupplevelse. Den långsiktiga produktkanonen är inte ett löfte om att allt innehåll redan finns. Saknade moment redovisas öppet och får inte markeras PASS eller ersättas med påhittad funktionalitet.

## Teknisk grind

- Kontrollera exakt HEAD och att miljö-PR134, gameplay-PR128 och governance-PR133 ingår i integrationshistoriken.
- Kör alla relevanta CI-jobb på samma HEAD, inklusive bundlade gameplayregressioner, Luau, paritet, geometri, deterministisk Roblox-export, visuell grind och den obundlade webbstarten. En äldre grön SHA är inte bevis för en nyare.
- Webbstarten ska använda `npm ci` med publik låst registry och Chromium. Det befintliga `tools/bootkoll.mjs` ska ge ALLA OK. Negativ kontroll med bortkopplad modell ska falla och återställas utan produktändring.
- Verifiera faktisk Vercel-deployment i befintligt UBRF-projekt på exakt test-SHA, inte enbart en Ready-etikett eller ett äldre previewalias. Ingen ny hosting eller databas.
- Roblox-export är en byggartefakt, inte bevis för att Roblox Studio har körts.
- Registrera kvarstående kända fel separat. Ett fel får inte döljas av att en annan testsvit är grön.

## Speltest — webb och Roblox

För varje steg: ange PASS, FAIL, NOT_TESTED eller NOT_IMPLEMENTED. Notera plattform, enhet, exakt SHA, förväntat resultat, faktiskt resultat och eventuell skärmbild/video. Testa inte en funktion som saknas och kalla det godkänt.

1. Öppna spelet utan att skapa konto. Kontrollera gästläge, läsbarhet och att spelet startar utan fel.
2. Rör dig på gården och i stallet. Kontrollera respons, acceleration, inbromsning, kamera, kollision, dörrar och att inga debugobjekt syns. Verifiera den accepterade läktaren utan teleport eller förlorad höjd.
3. Välj en häst och följ befintlig väg till hästen. Genomför de förberedelse- och skötselmoment som faktiskt är implementerade. Notera separat om ett planerat moment saknas.
4. Led, sitt upp och rid. Känn efter om halt, skritt, trav och galopp är tydligt olika, om svängar och övergångar är mjuka och om hovkontakt, ryttarrörelse och kamera känns sammanhängande. Inga godtyckliga numeriska betyg ersätter spelkänslan.
5. Starta Ugneta-lektionen. Genomför presentation → försök 1 → resultat → aktivt återförsök → försök 2 → jämförelse → nästa övning. Kortet får inte starta ett nytt mätförsök automatiskt. Verifiera återförsök med faktisk knapp, tangentbord R och gamepad Y där de finns.
6. Avbryt under ett pågående försök. Kontrollera säkerhetsavsittning, avbruten telemetri, återställning och att ett gammalt försök inte kan påverka nästa. Saknade mätvärden får inte bli falska nollor eller godkända betyg.
7. Avsluta lektionen och genomför tillgängligt efterarbete. Kontrollera att hästens behov och spelarens handlingar får begripliga konsekvenser. Saknat efterarbete registreras som innehållslucka, inte som färdig funktion.
8. Stäng och öppna igen. Kontrollera befintligt sparande, hästidentitet, framsteg och att gästläget inte kräver kontoskapande. Testa därefter responsivitet och hela centrala loopen på telefon, surfplatta och dator.

Roblox Studio ska köras i verklig runtime. Tangentbord, gamepad och fysisk touch ska särskiljas. Om Studio eller en enhet saknas: NOT_TESTED med konkret reproduktionsunderlag. Webbtester, Luau-stubbar och export får aldrig räknas som ersättning.

## Beslut om alpha

P0: spelaren kan inte starta, fortsätta eller avsluta kärnloopen; allvarlig krasch, blockerande kollision, felaktig säkerhetslogik, dataförlust eller falskt godkänd kritisk telemetri. P1: ridning, kamera, input, hästkänsla eller central pedagogik är så svag att upplevelsen inte är rolig eller begriplig. P0 och P1 ska rättas före publik alpha.

P2: kosmetik, mindre miljödetaljer och icke-kritiska förbättringar som inte stoppar loopen. Dessa kan skjutas upp. Kända referensluckor och planerat men ännu ej implementerat innehåll ska redovisas, inte gömmas. Beslutet om minsta kompletta alpha-scope tas av Tobias efter att den faktiska spelupplevelsen har provats.

Slutgrinden är: teknisk review av ChatGPT → Tobias spelar och accepterar avgränsat alpha-scope → godkänd release-SHA → kontrollerad merge/deploy och Roblox-publicering. Ingen builder får själv sätta PRODUCT_ACCEPTED. Ingen publik launch eller main-merge ingår i att skapa detta testunderlag.
