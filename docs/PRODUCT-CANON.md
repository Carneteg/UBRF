# UBRF — Product Canon

Det här dokumentet är den överordnade produktvisionen för UBRF-spelet. Vid konflikt mellan en bekväm implementation och den här visionen vinner visionen, om inte Product Owner uttryckligen beslutar något annat.

## North Star

**Bygg ett rid- och hästspel där spelaren har roligt samtidigt som hon lär sig hur hästar faktiskt fungerar, hur man rider och vilket ansvar och vilka plikter som följer med hästlivet. Allt utspelar sig på UBRF, som ska återskapas så verklighetstroget som det tillgängliga källmaterialet tillåter.**

Det ska kännas som att få vara på en riktig ridskola — inte som att läsa en digital lärobok och inte som att köra ett generiskt hästfordon.

## De fyra produktpelarna

### 1. Fun first — men aldrig tomt

Spelet måste vara roligt att spela även för någon som inte öppnar det för att studera.

Ridningen ska kännas mjuk, levande och tillfredsställande. Hästarna ska ha personlighet och beteende. Spelaren ska vilja rida en gång till, förbättra något, lära känna en häst, klara en övning eller hjälpa till i stallet.

Ingen mekanik får försvaras enbart med att "så fungerar det i verkligheten" om den i spel blir monoton, otydlig eller onödigt frustrerande. Den verkliga handlingen ska översättas till ett bra spelmoment utan att dess innebörd förvanskas.

### 2. Learning by doing

Kunskap ska i första hand läras genom handling och konsekvens, inte genom långa texter eller quiz.

Spelaren ska successivt kunna lära sig bland annat:

- hästens beteende, signaler och temperament,
- säkerhet runt hästar,
- visitering och daglig kontroll,
- ryktning och hovvård,
- sadling, tränsning och utrustning,
- fodring, vatten och grundläggande hästvälfärd,
- stallrutiner och ordning,
- hur man leder och hanterar en häst från marken,
- gångarter, hjälper, balans, sits och kontakt,
- ridvägar, ridbanans regler och ridlärarens instruktioner,
- dressyrens grundprinciper,
- hoppning och anridning,
- uteritt och underlag,
- hästens dagsform, stress, trötthet och återhämtning,
- ansvar före och efter ridning,
- etikett och säkerhet på en riktig ridskola.

Listan är långsiktig produktomfattning, inte ett krav att bygga allt samtidigt. Funktioner ska införas stegvis och först när kärnupplevelsen förblir tydlig och rolig.

### 3. Responsibility is gameplay

Att ha med hästar att göra innebär plikter. De ska inte ligga som dekoration runt ridningen — de är en del av spelet.

Spelaren ska förstå sambandet:

**hur jag tar hand om hästen → hur hästen mår → hur hästen beter sig → hur ridningen känns och går.**

Exempel: dålig förberedelse kan ge sämre dagsform eller obehag; rätt visitering kan upptäcka ett problem; felaktig utrustning ska märkas; efterarbete ska ha betydelse.

Konsekvenser ska vara pedagogiska och begripliga, inte slumpmässiga straff. Spelet ska förklara vad som hände genom världen, hästen och handledningen.

### 4. UBRF is the world

UBRF är inte inspiration till spelplatsen. **UBRF är spelplatsen.**

Målet är maximal verklighetstrohet i:

- anläggningens layout,
- byggnadernas placering och proportioner,
- fasader, tak, portar, fönster och färger,
- stallgång, boxar och relevanta interiörer,
- ridhus och ridbanor,
- vägar, hagar, parkering, entréer och omgivning,
- verkliga namn på platser och funktioner,
- hur man rör sig mellan platser,
- stallrutiner och den sociala logiken på en svensk ridskola.

**Verkligheten är facit.** Foton, film, ritningar, satellitbilder, platsdata och verifierade uppgifter väger högre än estetisk bekvämlighet.

"100 % likt" är ett fidelity-mål, inte tillåtelse att hitta på. Om underlag saknas ska delen markeras som `[REFERENCE GAP]` eller `[antagande]` och inte presenteras som verifierad verklighet. När nytt källmaterial kommer ska antagandet ersättas.

## Hästen är spelets kärna

Hästen får aldrig kännas som ett fordon med hästmodell ovanpå.

Kärnan som alltid prioriteras före nya features:

1. input,
2. respons,
3. acceleration och inbromsning,
4. sväng och viktförskjutning,
5. gångartsövergångar,
6. animation och hovkontakt,
7. ryttarens rörelse,
8. kamera,
9. ljud och fysisk feedback.

En spelare ska kunna känna skillnad mellan halt, skritt, trav och galopp utan att behöva läsa HUD:en.

## Realism vs spelbarhet

När realism och spelbarhet verkar krocka ska teamet inte automatiskt välja den ena.

Först ska frågan vara: **kan den verkliga principen uttryckas på ett enklare och roligare sätt utan att bli fel?**

Bra förenkling:
- komprimerar tid,
- minskar upprepning,
- gör återkoppling tydligare,
- behåller orsak och konsekvens.

Dålig förenkling:
- lär spelaren något som är fel,
- gör hästen till ett fordon,
- tar bort ansvar utan anledning,
- låter riskfyllda handlingar passera som korrekta,
- hittar på UBRF-detaljer som inte är verifierade.

## Progression

Progression ska i första hand vara **ökad kompetens och självständighet**, inte större siffror.

En ny spelare får hjälp och gör en sak i taget. Med erfarenhet förväntas hon själv komma ihåg fler moment, förbereda hästen bättre, läsa hästens signaler, rida mer precisa övningar och ta större ansvar.

Det ska kännas som att gå från nybörjare på ridskola till en trygg och kunnig hästmänniska.

## Plattform: Roblox + HTML/webb

**Roblox är den primära spelplattformen. Det är där UBRF-spelet i första hand ska spelas och där Roblox-versionen är ett förstaklassresultat — inte en senare port.**

Samtidigt ska samma kärnupplevelse vara **spelbar via HTML/webben**. Webbversionen är alltså inte bara ett internt prototypverktyg. Den ska kunna öppnas, provas och spelas utan Roblox-klienten och fungerar samtidigt som en snabb utvecklings-, QA- och delningsyta.

Plattformskontrakt:

- Roblox = primär spelplattform.
- HTML/webb = riktig spelbar parallell distribution.
- Kärnloop, hästlogik, lärande, ansvar, UBRF-värld och centrala gameplayregler ska motsvara varandra.
- Input, rendering, UI och teknisk implementation får vara plattformsspecifika.
- Gameplayparametrar och acceptance criteria ska hållas motoroberoende där det är rimligt.
- Ingen ny funktion får betraktas som fullständigt produktklar om den gör den avsedda kärnupplevelsen omöjlig att hålla fungerande på den andra spelbara ytan utan uttryckligt produktbeslut.
- Webb får användas för snabb iteration, men beslut får inte leda till att Roblox behandlas som en framtida eftertanke.
- Roblox får inte heller bli skäl att låta HTML/webbversionen förfalla till en icke-spelbar demo.

### Tidsbegränsat produktbeslut 2026-09-22: Roblox först

**Under etappen fram till verifierad First Playable är Roblox det enda aktiva
leveransmålet.** Beslutet är Tobias och förmedlat i PR #264, kommentar
`5779749429`. Det tar tillfälligt företräde framför kravet ovan att en ny
kärnfeature måste hållas möjlig på båda ytorna innan Roblox går vidare.
Tvåplattformsmålbilden står kvar; det är ordningen som ändras, inte målet.

**1 · Aktivt mål och vad pausen omfattar.** PC och iPad är två kontrollsätt i
samma Roblox-spel, inte två spelimplementationer. Pausat: nya webbfeatures, och
kravet att varje ny Roblox-funktion samtidigt implementeras på webben. Webben
bevaras i befintligt skick som spelbar referens och framtida distribution.
Pausen är **inte** tillstånd att radera, avveckla, publicera om eller medvetet
försämra webbversionen.

**2 · Undantaget.** Gemensamma ridregler, hästdata och källstyrd geometri
behåller sin kanoniska källa. Nödvändiga ändringar i delade källfiler,
generering och export är tillåtna inom aktivt scope även när filen ligger under
`src/`. Ingen andra Luau-sanning får skapas och ingen befintlig synkkontroll
kopplas bort. Befintliga tester och regressionsskydd behålls: en fallerande
kontroll får inte raderas, hoppas över eller kallas godkänd, och en
webbregression som våra ändringar orsakar ska fortfarande åtgärdas.

**3 · Nuvarande arbetsorder och ansvarig.** First Playable Session Closure,
PR #264, kommentar `5779419152`. Implementatör: **Claude**, en skrivande ägare.
Review: ChatGPT. Acceptans: Tobias.

**4 · Vad som återstår för First Playable, och vilket bevis som krävs.**
Åtkomlighet för Roblox touchkontroller, inklusive närområdeslistan mot
gåspaken. Därefter ett sammanhängande spelpass i en **fryst, identifierad
testbuild**: start, rörelse, gångarter, styrning, broms, avsittning, ny
ritt/respawn, och stall → utrustning → dörr → ledning → ridhus. PC, fysisk
touch och två spelare redovisas **separat**. Rörelsesäkerheten ska lösas före
öppet multiplayer. Robotkörda tester, DataModel-kontroller, faktisk fysik,
UI-interaktion och Tobias game feel hålls åtskilda; `NOT_TESTED` är inte PASS.

**5 · Återstart.** Att ta upp webbfeatures igen kräver ett **nytt**
produktägarbeslut. Ingen arbetsström startar automatiskt när den här etappen
levererats.

Beskriv aldrig en saknad webbimplementation som genomförd paritet. Under
etappen redovisas den som en **medveten, tidsbegränsad avvikelse** med
hänvisning hit.

### Produktbeslut 2026-09-26: completion first

Beslutet är Tobias, förmedlat i PR #264, kommentar `5843082008`.

**Ordning:**
1. infrastruktur
2. instruktör
3. tävling
4. hus
5. byggnader och området
6. utrustning
7. häst
8. ett samlat slutspeltest

**Scope:** hela anläggningen och alla arbetspaket i #266, inklusive F1–F3,
NPC-medtävlare och multiplayer.

**Ersätter:**
- punkt 3–4 ovan, som krävde upprepade speltest inför varje steg,
- kravet att #264 ska vara accepterad och mergad innan #266 påbörjas. Det
  gäller för implementation, inte för release.

**Gäller fortfarande:** pausen för webbfeatures och undantaget i punkt 2.

Status, grindar och slutprovfall per komponent finns i den låsta
leveransmatrisen, `docs/LEVERANSMATRIS.md`.

Se även `docs/ASSET-SOURCE-OF-TRUTH.md` för material- och datakällor.

## Beslutsfilter

Före en större feature eller ändring ska ChatGPT och Claude kunna svara ja på minst följande:

1. Gör detta spelet roligare, tydligare eller mer levande?
2. Lär spelaren något sant om hästar, ridning, ansvar eller UBRF — eller stödjer det tydligt en sådan upplevelse?
3. Stämmer det med verkligheten eller är eventuella antaganden tydligt markerade?
4. Förbättrar det kärnloopen snarare än att bara öka mängden innehåll?
5. Är designen rimligt konsekvent mellan Roblox och den spelbara HTML/webbversionen?

Om svaret är nej på flera punkter ska arbetet normalt inte prioriteras.

## Definition of success

UBRF är framgångsrikt när en spelare kan säga båda dessa saker:

> "Det är kul att vara här och rida. Jag vill spela igen."

och

> "Jag kan faktiskt mer om hästar och vad det innebär att ta hand om dem än innan jag började spela."

En person som känner den verkliga UBRF-anläggningen ska dessutom känna igen var hon är utan att behöva få det förklarat.