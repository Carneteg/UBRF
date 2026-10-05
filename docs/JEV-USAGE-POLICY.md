# Jev / TypeSafe usage policy — UBRF

Detta dokument är **bindande teknisk styrning** för när och hur Jev/TypeSafe får användas i UBRF.

Syftet är att få värdet av ett probabilistiskt beslutslager utan att göra spelets kärnregler, säkerhet eller resultat beroende av en modell som kan vara osäker eller fel.

Vid konflikt gäller Tobias senaste uttryckliga beslut först, därefter `docs/PRODUCT-CANON.md`, `CLAUDE.md`, `docs/DELIVERY-PROTOCOL.md` och denna policy.

## Grundregel

> **Kod äger sanning och konsekvenser. Jev får hjälpa till att välja mellan begränsade, tillåtna alternativ när bedömningen är mjuk eller tvetydig.**

Jev är ett **beslutslager**, inte en source of truth och inte en ersättning för spelregler.

Om ett beslut kan uttryckas korrekt, begripligt och stabilt som deterministisk kod ska det normalt vara kod.

## När Jev passar i UBRF

Jev får övervägas när alla följande villkor är uppfyllda:

1. Det finns flera **fördefinierade, säkra alternativ** att välja mellan.
2. Underlaget är tvetydigt, kontextberoende eller innehåller flera samtidiga signaler.
3. Ett felaktigt val kan fångas av en deterministisk fallback utan att skada spelstatus.
4. Jev behöver inte skriva direkt till kärnstate.
5. Valet går att logga, jämföra och falsifiera.

Bra exempel:

- välja vilket **coaching focus** Ugneta bör prioritera bland godkända fokus, utifrån validerad ridtelemetri;
- shadow-analys av Jevs val jämfört med dagens deterministiska Ugneta;
- offline QA/triage, t.ex. sortera testfall, gruppera återkommande problem eller prioritera granskningsfall;
- klassificera ofarliga observationer där ett deterministiskt fallback-svar alltid finns.

## När Jev inte ska användas

Jev får **inte** vara auktoritativt för:

- hästfysik, locomotion, styrning, acceleration eller kollision;
- säkerhets- eller välfärdsgrindar;
- lektionskrav, pass/fail eller officiella mätgränser;
- poäng, resultat, placeringar eller tävlingsregler;
- progression, unlocks, ekonomi eller belöningar;
- beständig data, migrationer eller ägarskap;
- autentisering, behörighet eller säkerhetskritiska beslut;
- verklighetsfakta om UBRF;
- beslut som måste vara reproducerbara enligt en officiell regelprofil.

**Confidence gör aldrig ett förbjudet beslut tillåtet.**

## Kod vs Jev vs generativ AI

Använd denna ordning:

### Deterministisk kod
Välj kod när svaret ska vara exakt och reproducerbart:
- "är hästen inom zonen?"
- "klarade spelaren lektionen?"
- "hur många fel fick ekipaget?"
- "får spelaren sitta upp?"
- "vilken hastighet gäller i trav?"

### Jev
Välj Jev när spelet har ett antal säkra alternativ men prioriteringen är mjuk:
- "vilket av tempo, linje eller beröm är mest relevant att ta upp nu?"

### Generativ AI / LLM
Använd generativ AI bara när fri formulering faktiskt ger produktvärde. Den får inte bli en genväg runt deterministiska regler. Om fri text visas för spelaren krävs separat produktbeslut, språk-/säkerhetsgranskning och fallback.

## Input: validera före nätverk

All evidens ska behandlas som **otillförlitlig tills den validerats**.

Före ett Jev-anrop ska koden kontrollera minst:

- exakta tillåtna fältnamn;
- kända enumvärden;
- rätt datatyper;
- ändliga numeriska värden;
- rimliga och dokumenterade intervall;
- begränsad storlek på tabeller/strängar;
- att nödvändig evidens finns.

Ogiltig, okänd eller orimlig evidens betyder normalt:

> **skicka inte till Jev — använd deterministisk fallback eller no-op.**

JEV-POC-1 visade att hög confidence kan förekomma även på skräpdata. Confidence får därför aldrig ersätta inputvalidering.

## Klientdata

Serverhärledd telemetri är att föredra.

Om en PoC måste använda klientberäknad evidens:

- den behandlas som **untrusted**;
- servern validerar allt innan användning;
- den får endast påverka shadow-/analysdata tills annat uttryckligen godkänts;
- klienten får inte själv deklarera den auktoritativa slutsatsen om servern kan räkna fram den från delad logik.

För JEV-POC-2 är den godkända principen A': klienten kan skicka minimal lektionsdata som untrusted shadow input, medan servern återberäknar den befintliga delade Ugneta-logiken som jämförelse.

## Secrets och nätverk

- API-nycklar får aldrig ligga i Roblox-klient, webbläsar-JS, repo, logg eller spelarens enhet.
- Roblox-runtime använder server-side Secrets Store / motsvarande skyddad mekanism.
- Lokala verktyg använder miljövariabel eller annan godkänd secret store.
- Secret får aldrig skrivas ut i felmeddelanden eller testloggar.
- Nätverksanrop ska ha timeout, rate limit/cooldown och begränsad concurrency.
- Inga obegränsade retries.
- Gameplay får aldrig behöva vänta på Jev för att fortsätta.

## Data och integritet

Skicka minsta möjliga data.

Som standard får Jev inte få:

- UserId;
- username/display name;
- e-post;
- chat;
- fri spelartext;
- kontometadata;
- andra personidentifierande fält.

Använd anonyma shadow-/session-id:n när korrelation behövs.

Undantag kräver uttryckligt Tobias-beslut och separat privacy/safety-review.

## Fallback

Varje runtime-användning av Jev måste ha en deterministisk fallback.

Fallback ska aktiveras vid minst:

- timeout;
- API-fel;
- rate limit;
- ogiltig response;
- val utanför allow-list;
- saknad/NaN/icke-ändlig confidence;
- confidence under beslutad tröskel;
- invalid input;
- avstängd feature flag.

Fallback-beteendet ska vara fullt spelbart och säkert på egen hand.

## Confidence

Confidence är endast **extra evidens**.

Regler:

- confidence används först efter inputvalidering och hårda grindar;
- en hög confidence får inte kringgå en säkerhets- eller regelgrind;
- threshold måste motiveras med faktisk evaldata;
- threshold får inte beskrivas som sannolikhet att svaret är korrekt;
- om rätt/fel inte separeras av confidence i evaldata ska tröskeln behandlas som ett grovt routingverktyg, inte kvalitetssignal.

## Rollout-steg

Jev får inte gå direkt från idé till spelarsynlig runtime.

### Steg 0 — offline PoC
Syntetiska/lagrade scenarier. Mät:
- godtagbara val;
- feltyper;
- instabilitet;
- latency/API-fel;
- jämförelse mot deterministisk baseline.

### Steg 1 — shadow
Jev kör parallellt men **spelaren ser ingenting**.
Krav:
- default OFF;
- sanitiserad logg;
- ingen gameplay-write;
- faktisk runtime-telemetri;
- deterministisk comparator/fallback;
- runtime stability mäts.

### Steg 2 — begränsad pilot
Endast efter ChatGPT-review och Tobias uttryckliga beslut.
Jev får påverka ett låg-risk-val med deterministisk fallback och tydlig rollback.

### Steg 3 — spelarsynlig användning
Kräver separat produktacceptans och, där relevant, ett uttryckligt beslut om Roblox/webb-paritet.

**Nuvarande status 2026-09-30:** Jev är godkänt för experiment och shadow-PoC. Spelarsynlig Jev-coaching är inte godkänd.

## Webbparitet

- Ett avstängt, spelarinvisibelt shadow-/instrumentationsexperiment behöver inte implementeras på webben samtidigt, om Tobias uttryckligen godkänt undantaget.
- Så snart Jev påverkar en spelarvänd upplevelse måste plattformsparitet eller ett nytt dokumenterat undantag beslutas.
- En Roblox-hemlighet får aldrig flyttas till webbläsarklienten för att "nå paritet"; webben behöver i så fall en säker serverväg.

## Ugneta: godkänd målarkitektur

Det primära Jev-fallet i UBRF är **prioritering av coaching focus**, inte fri styrning av Ugneta.

Mönstret är:

```text
ridtelemetri
  ↓
deterministisk validering/mätning
  ↓
hårda regler + säkerhetsgrindar
  ↓
Jev väljer ett fokus ur allow-list
  ↓
confidence/policy/fallback
  ↓
befintlig godkänd Ugneta-presentation
```

Jev får välja exempelvis `praise`, `tempo`, `transition_timing`, `line` eller `no_comment` när dessa finns i aktuellt kontrakt.

Jev får inte uppfinna en fysisk observation som spelet inte mäter.

## Observability

Shadow/pilot ska logga sanitiserat:

- anonymt sample-id;
- lektion/fas;
- validerad evidens som faktiskt skickades;
- deterministiskt val;
- Jev-val;
- confidence;
- agree/disagree;
- latency;
- status, t.ex. `jev`, `timeout`, `api_error`, `invalid_input`, `hard_gate`.

Logga aldrig secret eller rå auth-header.

## Obligatorisk Jev-beslutspunkt i varje jobb

Jev får inte bli något som en builder antingen glömmer eller lägger in slentrianmässigt. Därför ska **varje icke-trivialt gameplay-, integration-, QA- eller produktionsjobb** göra ett uttryckligt Jev-beslut innan implementationen expanderar.

Tillåtna klassificeringar:

- `JEV_NOT_NEEDED` — vanlig deterministisk kod är rätt lösning för uppgiften.
- `JEV_OFFLINE_QA_CANDIDATE` — Jev kan ge värde i offline-analys/QA men ska inte kopplas till runtime i jobbet.
- `JEV_SHADOW_CANDIDATE` — det finns ett avgränsat runtime-val som kan vara värt att jämföra i default-OFF, player-invisible shadow innan något pilotbeslut.
- `JEV_FUTURE_PILOT_CANDIDATE` — ett framtida låg-risk-case kan vara intressant efter separat PoC/shadow/review, men **får inte implementeras som pilot eller player-visible inom den aktuella uppgiften**.

Klassificeringen är en **analys och scope-markör, inte ett tillstånd att aktivera Jev**. Ny runtime-användning måste fortfarande följa rollout-gaterna i denna policy.

### Beslutsregel

Buildern ska fråga:

1. Är beslutet en deterministisk regel/sanning/konsekvens? Då är det `JEV_NOT_NEEDED`.
2. Finns flera fördefinierade säkra alternativ där prioriteringen faktiskt är mjuk eller tvetydig?
3. Finns verklig, validerbar evidens/telemetri?
4. Kan Jev isoleras från core state och alltid falla tillbaka deterministiskt?
5. Går nyttan att mäta mot nuvarande deterministiska baseline?

Om 2–5 inte har tydliga ja-svar ska klassificeringen vara `JEV_NOT_NEEDED`.

Typiska `JEV_NOT_NEEDED`-områden är kontrollscheman, input, broms/gångart, care-flow, safety/welfare, fysik, pass/fail, progression, persistence och andra exakta spelregler.

Ett typiskt kandidatfall är däremot prioritering av **vilket tillåtet Ugneta-coachingfokus** som är mest relevant utifrån redan validerad telemetri.

### Krav i brief och leverans

Varje sådan uppgift ska innehålla eller själv lägga till en rad:

`JEV_DECISION: <klassificering> — <kort motivering>`

Samma rad ska återkomma i builderns slutrapport. Om buildern under arbetet hittar ett nytt möjligt Jev-case utanför scope får det bara noteras som framtida kandidat; det får inte smygimplementeras.

## Acceptance för varje nytt Jev-case

Varje nytt användningsfall kräver ett Acceptance Contract som minst svarar på:

1. Varför behövs Jev i stället för vanlig kod?
2. Vilken allow-list får modellen välja ur?
3. Vilken data skickas och varifrån kommer den?
4. Hur valideras input?
5. Vad får Jev aldrig ändra?
6. Vad är fallback?
7. Hur falsifieras allow-list, validator och isolation?
8. Hur mäts nytta mot deterministisk baseline?
9. Är användningen shadow, pilot eller spelarsynlig?
10. Krävs Tobias produktacceptans och/eller webbparitet?

Om dessa frågor inte har tydliga svar ska Jev inte kopplas in.

## Arbetsregel

**Jev ska förtjäna sin plats genom mätbar nytta.**

Att ett probabilistiskt system kan göra ett val är inte skäl nog att använda det. Om deterministisk kod ger samma eller bättre spelarresultat med mindre risk, latency och komplexitet väljer UBRF den deterministiska lösningen.
