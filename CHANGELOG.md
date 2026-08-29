# Ändringslogg — Ridskolan

Vad som ändrats i spelet, nyast överst, grupperat per månad och dag. Loggen är
skriven för den som spelar, inte för den som läser koden: varje post säger vad
som märks i spelet och varför det gjordes. Commit-hasharna i parentes pekar på
detaljerna.

## Format för nya poster

Lägg nya poster överst under rätt månad. En post per sak som märks för
spelaren — inte per commit. Formen:

```
### ÅÅÅÅ-MM-DD · Kort rubrik i imperativ eller som påstående
Två–tre meningar: vad som ändrades, vad man märker, och varför.
Hänvisa till commits i parentes: (abc1234, def5678).
```

Rena kodstädningar, kommentarsrättningar och `.gitignore`-ändringar loggas
inte. Byggnadsarbete efter foton loggas som en post per byggnad och pass.

---

## Augusti 2026

### 2026-08-29 · Underhållsrunda: snabbare gård, tydligare första ritt
Gården i 3D ritar bara hästar inom synhåll och bygger inte om scenen vid
varje dörr — draw calls per bildruta sjönk från ~405 till 95–310 och
dörrhacket på gården från ~40 ms till ~6. Första ritten visar ridlärarens
steg ("Ridläraren · 2 av 4 · Tygel") i uppgiftsrutan och "Sitt upp"-prompten
hänger inte kvar; gå-läget startar i 3D med en tangentremsa de tre första
passen; på mobil säger instruktionerna TYGEL och ANVÄND i stället för Space
och E; pass 0 börjar med hästen sadlad, som introt lovar. Sidovyn och
sprite-pipelinen (död kod) togs bort. Kokbok i `PROMPTS.md`, rapporter i
`audits/`.

### 2026-08-29 · Första testrundan: stillastående ger inte längre godkänt
Att stå still var den snabbaste vägen genom ett moment — nu kräver momenten
att man faktiskt rider. Sadeltexten låg över räknaren i skötselrutan och är
flyttad. (c18cfab, 09925a2)

### 2026-08-29 · NPC-ekipagen bromsar för varandra
De andra eleverna i ridhuset saktar in bakom varandra och går om på insidan
i stället för att rida igenom. (988280d)

### 2026-08-29 · Grafikpass: kontaktskugga och kamera
Kontaktskuggan under hästen syntes inte; nu gör den det. Kameran gick genom
väggar i stallet och ridhuset och kolliderar nu i stället. (fb2eed3)

### 2026-08-29 · Onboarding: kortare väg in, tangenter i tur och ordning
Första passet visar en tangent i taget i den ordning man behöver dem, och
HUD:en syns nu från start. Vägen från menyn till första ritten är kortare.
(b3eea87)

### 2026-08-29 · Din egen ryttare
Första gången frågar spelet vem du är: namn, utseende och tre egenskaper av
åtta, hämtade ur *7 egenskaper hos en skicklig ryttare* och Ridhandboken. Var
och en lutar ridmodellen en aning. Ett frivilligt konto för molnsynk kom
samtidigt. (c8ed26c, 7d66e05)

### 2026-08-29 · Skötseln som genomgång, inte som drag
Visitering, ryktning, sadling och hovkratsning är nu sekvenser med kamera
och egen vy — visiteringen görs framifrån och bakåt, och varje tillsägelse
från ridläraren har sitt varför. HUD:en följer skärmstorleken på riktigt.
(070c9f2, 5b176fe, 2b0d215, a42952a, 01ffdb4)

### 2026-08-29 · Ridhuset invändigt: läktare, hinder, bokstäver, entréhall
Läktaren är en trästomme, hindren står framme, sargen har tolv bokstäver
med bildgåtor och entréhallen är möblerad i stället för en tunnel.
(dbf0826, bfa2f1d, 2425bb2)

### 2026-08-29 · Måtten rättade efter utrymningsplaner och satellitbild
Ridhuset är 25 × 75 m (inte 26 × 66) och stallets planform var fel — båda
uträknade ur utrymningsplanerna. Hela anläggningen är omläst ur satellit-
och Street View-bilder. (e0876d9, 605d77f, 7eb4bdd, 3f94a17)

### 2026-08-29 · Molnsynk, frivillig och local-first
Ryttaren, hästminnet och passen kan synkas till molnet så att man kan rida
på mobilen i stallet och fortsätta på datorn. Utan inloggning eller nät
spelar man precis som förut. (41b71c1)

### 2026-08-29 · Efter passet: vad som växte och varför
Resultatskärmen berättar vad som utvecklades, av vilket beteende, och vad
det betyder nästa gång. (600067e)

### 2026-08-29 · Stallet och ridhuset byggda efter fotona
Huvraden, fönsterrytmen och förstukvisten på stallet; ridhusets fasad och
tak — och tre fel i 3D-motorn rättade på vägen. 66 distinkta bildrutor ur
filmerna används som referens. (b1fc34b, 7c3937b, 9bafa1d)

### 2026-08-28 · Hästen driver, har humör och lydnad
Hästen har egen vilja: den driver, har dagsform och lydnad, och slarvig
skötsel kostar i relationen. Att bli bättre som ryttare märks och gör
ridningen lättare. (8f5768e, 1b9b1a0)

### 2026-08-28 · A och D var spegelvända i gå-läget
Rättat. (d8f3c04)

### 2026-08-28 · Klosstil i hela världen
Hästen är lågpolygon med plana ytor efter referensbilderna; figurerna är
klossiga i Roblox-snitt och stilen gäller hela världen. Roblox-spåret med
hästsystem för riggade modeller ligger separat i `roblox/`. (99a58ce,
affe70d, 9275958, 650cfdf, 5cf5fa8, 06e52b2)

### 2026-08-28 · Nytt uttryck: ui-kit-demo
Spelet bytte grafiskt uttryck till ui-kit-demon (kall stallmorgon, varm
sand, guld). Texten blev läsbarare och figuren mer människolik. Ridningen
provades som sidovy med sprites; den ligger kvar men används inte. (593d222,
961f654, a402eff, 6939851)

### 2026-08-28 · Riktig 3D
Egen WebGL-motor med riggad häst, ryttare och anläggning. Gå-läget — gården,
stallgången och ridhuset — kör i samma motor. Stallets servicedel
(spolspiltan, sadelkammaren) är spelbar. (0052076, 87829a9, 6d6decd)

### 2026-08-27 · Åtta steg från stalldag till tävling
Utvecklingsplanen skrevs och genomfördes i följd: ridhuset invändigt som
gå-scen; mobilstöd med pekkontroller; mocka och fodra vid boxen; hämta i
hagen och täcke efter väder; ryttarens utveckling med gruppsteg och
uppflyttning; lektioner ur träningsboken och teorisal; hästarna som
individer med egenheter och skador; uteridbanan och skogsstigen; tävling
med Påskhoppet, dressyr LC och rosettvägg; ljud och liv på anläggningen.
(1fb7387, 7aa6e3f, 8315449, 56cfbc7, 2a45c5e, df342c1, 3fc43af, e003fa2,
bc14a06, 9a159bf)

### 2026-08-27 · Anläggningen på Husbyvägen 1A som gå-läge
Gården, stallet och omnejden byggda som gå-läge med kamerakollision.
Grafikpass med riktiga hästar, materialtexturer och gyllene hösttema.
Träningsboken med övningsbank och hästkunskap efter Ridhandboken. Spelet
döptes till Ridskolan. (52d1176, 3c3b80f, 8caef94, ade1731, 556db67)

### 2026-08-27 · Projektet startar
Ridskolan-POC:en importerad som projektbas. (7c4b1a2)
