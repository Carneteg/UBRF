# Utvecklingsplan — Ridskolan

Spelets idé: du är ryttaren och gör **alla** momenten — sköter hästen,
städar, tränar, får instruktioner och lär dig. Du börjar längst ner i
kedjan och utvecklas. Anläggningen är UBRF på Husbyvägen 1A.

Varje steg är spelbart när det är klart. Vi bygger uppifrån och ner i
listan och håller `main` grön: ett steg mergas först när kedjan
meny → stall → lektion fungerar i test.

## Klart hittills

- ✅ **Grunden** — ridmodellen (utbildningsskalan, fyra hjälper,
  gångarter, hoppning med domarprotokoll), skötselns fyra handgrepp,
  hästtilldelningen.
- ✅ **Anläggningen** — gå-läge till fots, gården och stallet byggda
  efter 103 referensfoton, kedjan infart → ridlärare → box → skötsel →
  leda → lektion.
- ✅ **Träningsboken** — 16 övningar och 11 kunskapskapitel efter
  Markus Ridhandbok, viktade mot utbildningsskalan.
- ✅ **Grafikpasset** — anatomiska hästar, materialtexturer på
  byggnaderna, gyllene hösttema.

## Steg 1 · Anläggningen exakt (finslipning)

**Mål:** att den som rider på UBRF känner igen varje meter.

- ⏳ Flygbild/karta → korrekta mått och lägen för alla byggnader och
  banor. **Väntar på en flygbild i Drive-mappen** — måtten är tills
  vidare rekonstruerade ur referensfotona.
- ✅ Ridhuset invändigt i gå-läge: läktaren, sponsorväggarna, speglarna,
  domarbåset, trappan till Café Krubban.
- ✅ Stallets servicedel spelbar: spolspiltan med slangvinda (leriga ben
  efter hagen spolas av) och sadelkammaren där varje häst har sin egen
  sadelbygel och tränskrok med namnskylt.
- ✅ Fler foton ur Drive-mappen vävs in (interiörer, detaljer, hästarna).

**Klart när:** kartvyn kan läggas bredvid en flygbild utan att skämmas.

## Steg 2 · Stallmomenten på riktigt

**Mål:** hela dagsrutinen i stallet — inte bara före lektionen.

- Mocka boxen (eget minispel), halm/spån från spånförrådet.
- Fodra efter varje hästs foderschema (hö, kraftfoder, vatten) — fel
  foder märks på hästen.
- Leda till och från hagen; täcke på/av efter väder.
- Stallschemat på whiteboarden: dagens sysslor som uppgiftslista.
- Allt kopplas till dagsform och stallro — som skötseln redan gör.

**Klart när:** en hel stalldag kan spelas utan att sitta upp en enda gång.

## Steg 3 · Ryttarens utveckling

**Mål:** "du börjar längst ner och utvecklas" på riktigt.

- Framsteg sparas (localStorage): ryttare, nivå, hästrelationer.
- Gruppstegen: ledlektion → knatte → minior → grupp 1–5 → hoppgrupp
  (förväntansnivåerna finns redan i modellen).
- Ridlärarens omdömen ackumuleras till uppflyttning.
- Hästrotation och belöning: skickligare ryttare får känsligare hästar.
- Hästminne: rang och förtroende per häst består mellan pass.

**Klart när:** att flyttas upp en grupp känns förtjänat.

## Steg 4 · Lektioner ur träningsboken

**Mål:** varje lektion är unik och lärorik — som en riktig ridskola.

- Lektionsbyggare: ridläraren sätter ihop dagens lektion av övningar
  ur banken efter grupp och gångart.
- Banguider ritas för varje övning: volter, serpentiner, diagonaler,
  skänkelvikningens linje.
- Bedömning per övning med övningens egna skala-vikter.
- Teorilektioner i teorisalen: frågor ur kunskapskapitlen.

**Klart när:** två lektioner i rad aldrig är likadana.

## Steg 5 · Hästarna som individer

**Mål:** alla UBRF-hästar, med egenheter man lär sig.

- Hela hästlistan från ubrf.se med beskrivningar och flaggor
  (som Crokinos spörädsla — fler sådana).
- Dagsform påverkas av gårdagens skötsel och vila.
- Händelser: sten i hoven, skav, hovslagardag, veterinärbesök —
  och vägen tillbaka (efter ridhandbokens "Från hälta till hälsa").

**Klart när:** man väljer favorithäst av rätt skäl.

## Steg 6 · Utomhus

**Mål:** anläggningen runt omkring används.

- Lektioner på uteridbanan (utomhusfaktorn finns redan i modellen:
  skygghet väger tyngre ute).
- Framridning före lektion; skrittrunda som avslutning.
- Uteritt: skogsstigen runt anläggningen med moment ur banken
  ("lydighetsövningar behöver ingen bana — grusvägar duger").

**Klart när:** en hel lektion kan ridas utan tak över huvudet.

## Steg 7 · Tävling

**Mål:** klubbtävlingen som säsongsmål.

- Påskhoppet: klasser, startordning, publik på läktaren, sekretariat.
- Dressyr LC på uteridbanan med protokoll och domare i domarkuren.
- Rosetter och resultatlista som sparas i klubbrummet.

**Klart när:** första rosetten hänger på boxdörren.

## Steg 8 · Ljud och liv

**Mål:** anläggningen låter och lever.

- Ljud: hovslag per underlag, gnägg, stallljud, ridlärarens röst.
- Fler människor: elever som sköter sina hästar, föräldrar på läktaren.
- Dagstid och väder (regnet gör underlaget tyngre — modellen har
  redan en underlagsfaktor).

**Klart när:** man hör var man är med ögonen stängda.

## ✅ Riktig 3D

Ridscenen renderas i äkta 3D med en egen WebGL-motor (`src/gl.js`,
`src/scen3d.js`) — perspektiv med djupbuffert, sol och hemisfäriskt
omgivningsljus, dimma och projicerade skuggor. Hästen är riggad:
skuldror, höfter, knän och kotor animeras ur gångartens takt, och
ryttaren lättrider, sitter lätt och tar tygel med hjälperna.

Ingen three.js och inget CDN — motorn är skriven för spelet, så det
förblir en enda fil som fungerar utan nätverk. Saknas WebGL faller
vyn tillbaka på den handrullade målarrenderaren, och gå-läget till
fots använder den fortfarande.

**Kvar att ta vidare:** gå-läget (gården, stallet, ridhuset invändigt)
kan flyttas över till samma motor, och Roblox-porten finns kvar som
möjlighet — modellen, anläggningen och övningarna följer med oavsett.
