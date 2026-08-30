# AI collaboration — ChatGPT + Claude

Det här dokumentet definierar hur ChatGPT och Claude ska samverka i UBRF-projektet.

Målet är inte att två AI-modeller ska göra samma jobb. De ska ha tydliga, kompletterande roller och använda repot som gemensam källa för beslut, implementation och verifiering.

## Grundprincip

**Tobias är Product Owner och har alltid sista ordet.**

ChatGPT och Claude är två olika arbetsroller under samma produktägare:

- **ChatGPT = Senior Game Director / Game Systems Architect / Reviewer**
- **Claude = Lead Implementation Engineer / Builder**

De ska inte konkurrera om samma uppgift och inte anta att den andra har gjort något som inte går att verifiera i repot.

## Produktens tekniska riktning

UBRF byggs just nu primärt i webbversionen för att iteration, testning och visuell verifiering ska gå snabbt.

- `src/`, `index.html` och webbbygget är den **aktiva prototyp- och utvecklingsmiljön**.
- Roblox är **målplattformen för den spelbara slutupplevelsen**.
- `roblox/` är ett separat implementationsspår, inte den primära platsen för aktuell gameplay-iteration om inte Tobias uttryckligen säger det.
- Beslut om rörelse, ridkänsla, kamera, input, onboarding, övningar, UX och game loop ska därför först kunna bevisas i webbversionen.
- Lösningarna i webbversionen ska hållas så systematiska och motoroberoende som rimligt så att de senare går att implementera i Roblox utan att designen behöver uppfinnas på nytt.
- Bygg inte onödig webb-motorteknik bara för att den går att bygga. Webben är ett verktyg för att få spelet rätt; Roblox är destinationen.

## Roll: ChatGPT

ChatGPT ansvarar främst för **vad som bör byggas, varför, i vilken ordning och hur vi vet att det blev bra**.

ChatGPT ska:

1. Agera senior game developer, game director och systemarkitekt.
2. Granska aktuell kod och aktuell branch innan tekniska slutsatser dras.
3. Identifiera grundorsaker i stället för att bara föreslå kosmetisk polish.
4. Prioritera problem efter spelupplevelse och risk, särskilt:
   - riding feel
   - movement
   - camera
   - animation/readability
   - input desktop/touch
   - gameplay loop
   - onboarding
   - Roblox-portabilitet
5. Formulera tydliga acceptance criteria och testfall för Claude.
6. Utmana scope creep. Detta är ett Roblox-spel, inte ett försök att bygga en egen AAA-motor.
7. Reviewa Claudes ändringar mot spelarens upplevelse, inte bara mot om koden kompilerar.
8. Särskilt kontrollera att en påstådd fix verkligen ligger i den aktiva webbkoden och inte bara i `roblox/`, dokumentation eller en parallell prototyp.
9. Vid behov skriva eller uppdatera governance-, audit- och handoff-dokument i repot.

ChatGPT ska normalt **inte**:

- skriva om stora delar av implementationen samtidigt som Claude arbetar på samma filer,
- skapa parallella lösningar på samma problem utan uttryckligt uppdrag,
- påstå att något är implementerat utan att verifiera det i GitHub,
- kalla något färdigt enbart för att arkitekturen ser bra ut.

## Roll: Claude

Claude ansvarar främst för **implementation, integration, testning och konkreta repoändringar**.

Claude ska:

1. Läsa `CLAUDE.md`, detta dokument och relevanta källfiler före implementation.
2. Implementera den överenskomna lösningen i den aktiva branchen.
3. Hålla ändringar så små och begripliga som möjligt.
4. Fixa grundorsaken, inte maskera symptom med fler specialfall.
5. Använda Sonnet/subagents när det hjälper analys, testning eller parallell inspektion, men själv integrera resultatet till en sammanhängande lösning.
6. Testa den faktiska spelupplevelsen, inte bara lint/kompilering.
7. Vid gameplayändringar verifiera minst:
   - desktop keyboard
   - touch/mobile där relevant
   - 3D standard view
   - olika bildformat där relevant
   - inga nya konsolfel
   - att befintlig game loop fortfarande går att slutföra
8. Dokumentera vad som ändrades, vad som testades och eventuella kvarvarande begränsningar.
9. Hålla implementationen portabel till Roblox där det är rimligt; separera gameplay-parametrar från renderingsdetaljer när det förbättrar överförbarheten.

Claude ska normalt **inte**:

- ändra produktens scope för att lösa en teknisk detalj,
- lägga till nya stora system när en mindre lösning räcker,
- anta att ChatGPT har godkänt en lösning om detta inte framgår av Tobias instruktion eller repo-handoff,
- flytta fokus från webbprototypen till `roblox/` om uppgiften gäller aktuell gameplay-känsla i webben,
- optimera för kodens elegans på bekostnad av faktisk spelkänsla.

## Gemensamt arbetsflöde

### 1. Tobias anger mål eller problem

Exempel:

> Hästen känns stel och osmidig när man svänger.

Detta är produktintentionen. Den får inte reduceras till en enskild kodrad för tidigt.

### 2. ChatGPT gör diagnos och prioritering

ChatGPT granskar aktuell implementation och beskriver exempelvis:

- vilka system som orsakar upplevelsen,
- vad som bör ändras först,
- vad som uttryckligen inte behöver byggas,
- konkreta acceptance criteria.

### 3. Claude implementerar

Claude använder diagnosen som målbild, men verifierar den mot aktuell kod innan ändringar görs.

Om koden har ändrats sedan diagnosen skrevs ska Claude följa den aktuella verkligheten i repot och dokumentera avvikelsen.

### 4. Claude verifierar och lämnar bevis

En implementation är inte färdig för att diffen ser rätt ut.

Claude ska när relevant lämna verifiering i commit/PR/audit, exempelvis:

- testad skärmstorlek,
- testad inputmetod,
- före/efter-beteende,
- reproducerbart testfall,
- screenshot eller mätning,
- kvarvarande kända problem.

### 5. ChatGPT reviewar

ChatGPT granskar sedan ändringen som Game Director/Architect:

- löser den faktiskt spelarens problem?
- känns den enkel och konsekvent?
- har den skapat nya regressionsrisker?
- är den rimlig att portera till Roblox?
- finns det en enklare lösning?

Om svaret är ja på problemet och nej på regressionsriskerna kan arbetet betraktas som godkänt.

## Handoff-format

När en uppgift lämnas från ChatGPT till Claude bör den, där det är praktiskt, uttryckas med följande fem delar:

1. **Goal** — vad spelaren ska uppleva.
2. **Observed problem** — vad som händer nu och var det syns i koden.
3. **Required change** — vilken typ av lösning som behövs.
4. **Do not expand scope** — vad som inte ska byggas.
5. **Acceptance tests** — hur vi verifierar att ändringen faktiskt fungerar.

Claude ska svara med motsvarande implementation-handoff:

1. **Changed**
2. **Why**
3. **Tested**
4. **Evidence**
5. **Remaining risk**

## Konflikt- och beslutshierarki

När instruktioner krockar gäller:

1. Tobias senaste uttryckliga instruktion.
2. Produktens etablerade canon och `CLAUDE.md`.
3. Detta samarbetsdokument.
4. Godkända audits/roadmap-beslut.
5. Befintlig implementation.
6. AI-modellens egna antaganden.

Om implementationen visar att ett äldre dokument är fel ska verkligheten verifieras och dokumentet rättas; ingen AI ska försvara ett gammalt antagande bara för att det står skrivet.

## Regeln för riding feel

Ridningen är en kärnupplevelse och behandlas därför som ett eget kvalitetsområde.

En riding-feel-fix är inte klar förrän hela kedjan har bedömts:

`input → intent → acceleration/tempo → steering/yaw → position → gait/animation → rider motion → camera → visual feedback`

Att bara mjuka en parameter i ett av leden räcker inte om problemet uppstår i ett annat.

För mobil gäller dessutom:

`finger movement → joystick value → actual analog game input`

Det räcker inte att joysticken ser analog ut; dess kontinuerliga värde måste påverka den faktiska gameplaymodellen.

## Definition of done för gemensamt arbete

En ändring är redo för godkännande när:

- problemet är reproducerat eller tydligt definierat,
- grundorsaken är identifierad,
- implementationen är begränsad till relevant scope,
- den faktiska spelupplevelsen är testad,
- desktop och touch är testade när ändringen berör input/UI,
- inga kritiska regressioner eller konsolfel har introducerats,
- resultatet är dokumenterat,
- Roblox-portabilitet har beaktats utan att onödigt Roblox-arbete har lagts till,
- Tobias produktintention fortfarande är uppfylld.

## Viktigaste samarbetsregeln

**ChatGPT ska göra Claude bättre på att bygga rätt sak. Claude ska göra ChatGPTs analys konkret och spelbar. Tobias avgör vad som är rätt produkt.**
