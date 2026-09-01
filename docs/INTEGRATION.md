# Integration — kön, kanoniska ägare och kollisionsregeln

Det här dokumentet är ett **tillägg** till `docs/DELIVERY-PROTOCOL.md`, inte en
ny governance. Protokollet säger *hur* en leverans ska bevisas. Det här säger
*vem som får skriva var, i vilken ordning arbetet går in, och vem som avgör när
två agenter har byggt samma sak.*

Det skrevs efter en mätning 2026-08-31 som visade att repot hade sex öppna
PR:er, att 23 filer ändrades i mer än en av dem, att två PR:er skapade samma
gate-dokument och att `ACTIVE-GATE.md` ändrades i tre parallellt. Protokollet
förbjöd redan detta i ord. Det som saknades var någon som höll kön.

## Roller — fyra axlar, en ägare var

`CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS` gäller precis som i
`docs/DELIVERY-PROTOCOL.md`. Ingenting här flyttar acceptansen från Tobias.

Det som saknades var inte en beskrivning av vem som är bra på vad, utan av vem
som får **bestämma** vad. Mätningen 2026-08-31 visade varför: tre av sex öppna
PR:er kom från `chatgpt/*`. Koordinatorn skrev implementationskod och skulle
sedan granska den. Det är exakt vad `CLAUDE.md` förbjuder i ord — "Ingen agent
får både införa en större förändring och ensam slutgodkänna den."

| Axel | Ägare | Får aldrig |
|---|---|---|
| **VAD** — vad spelet ska vara, vad som är klart | Tobias | delegeras |
| **HUR** — arkitektur, gate-uppdelning, tilldelning | ChatGPT | skriva implementationskod |
| **BYGGA** — koden | Claude | avgöra att den egna koden är klar |
| **SLÄPPA IN** — kö, kollisioner, mätning | Integrationsledare | skriva gameplay eller acceptera innehåll |

### ChatGPT skriver inte kod

Inte för att koden var dålig — dörr-hotfixen i #32 var korrekt — utan för att en
arkitekt som bygger inte längre kan granska oberoende. En oberoende granskare är
värd mer för projektet än en extra byggare.

ChatGPT äger `docs/KO.md`, gate-dokumenten och arkitekturbesluten. Behöver ett
arkitekturbeslut kod för att bevisas, beskrivs det i kön och byggs av Claude.

### Integrationsledare

- håller **en** merge-kö och basbranch,
- avgör vilken PR som äger en fil när två vill ändra den,
- utfärdar filkarantän innan arbete börjar, inte efter,
- fäller dubbla sanningar om samma domänfakta,
- mäter påståenden mot verkligheten över system som ingen agent ser samtidigt:
  GitHub, Supabase, Google Drive och `ubrf.se`,
- sammanfogar överlappande brancher i stället för att låta dem konkurrera,
- godkänner **ingenting** — varken review eller produktacceptans.

Integrationsledaren får inte skriva gameplay, geometri eller fidelity. Om
integrationen kräver en kodändring går den tillbaka till den som äger filen.
Skälet är samma som för ChatGPT: skriver integrationsledaren speldata finns
ingen kvar som kan fälla den.

## Repot är det delade minnet

Claude och ChatGPT har separata minnen som glider isär tyst. Det syns i att
båda skrev `docs/GATE-F02-INTERIOR-FIDELITY.md` — samma gate, två definitioner,
ingen visste om den andra.

**Står beslutet inte i en fil i `main`, existerar det inte.** Ett beslut i en
chattråd, en PR-kommentar eller ett agentminne är inte ett beslut; det är ett
förslag tills det ligger i repot.

## Tilldelning före arbete

Roten till dubbelarbetet i #29 och #30 var inte att två agenter kolliderade av
olycka. **Båda fick G01 S2** och byggde skötselpedagogiken parallellt, varav
bara den ena hade innehållet. Fördelningen upptäcktes när koden redan fanns.

Därför: ChatGPT skriver in nästa slice i `docs/KO.md` **innan någon börjar**,
med ägare och de filer slicen kommer att äga. En PR som rör filer som inte
står i dess köpost är inte färdig — den är ofördelad.

Kollisionen ska bli omöjlig att skapa, inte upptäckt i efterhand.

## En PR = ett gate-slice

#33 är 51 filer och +6 029 rader. En sådan PR granskas inte; man läser de
första tolv filerna och skriver "ser bra ut".

#35 är beviset att det går att göra rätt: Claude lyfte medvetet ut
Supabase-spegeln ur #33 med commit-texten "lyft ut Supabase-spegeln — en PR,
ett ansvar", och den blev den enda PR:n i hela kön med noll filkollisioner.

Riktvärde: en PR ska kunna granskas i ett sammanhang. Är den större krävs en
uppdelning i kön, inte ett längre PR-svar.

## Tobias tid är projektets trånga resurs

Han får bara två sorters frågor: **produktbeslut**, och sådant som **kräver
ögon i Studio**.

Att han granskade 11 QA-vyer i F01 var rätt användning. Att han skulle avgöra
om två PR:er dubblerade varandra var slöseri — `git merge-base --is-ancestor`
svarade på det i en sekund.

## Basbranch

`main` är basbranch och default branch. Inget annat.

En feature branch som legat mer än **tre dagar** utan att kunna mergas
rebasas eller stängs. En branch som ligger mer än **50 commits** bakom `main`
återanvänds inte — dess innehåll cherry-pickas eller skrivs om.

## Kanonisk ägare per domänfakta

Regeln är gammal — `CLAUDE.md` säger redan att två sanningar om samma sak alltid
blir fel till slut. Tabellen gör den kontrollerbar.

| Domänfakta | Kanonisk källa | Får läsas via | Får INTE definieras i |
|---|---|---|---|
| Hästarnas namn, ras, födelseår, beskrivning | `src/spel/hastar.js` | `tools/exportera-spel.js` → `roblox/game/UBRFSpel.luau` | `HorseCore/Config.luau`, handskriven Luau |
| Hästarnas spelparametrar 0–1 | `src/spel/hastar.js` | samma export | duplicerade balanstabeller |
| Skötsel- och förberedelseregler | `src/spel/skotsel.js` | samma export | `HorseCore/Preparation.luau` som egna literaler |
| Anläggningens geometri | `src/site.js` | `tools/exportera-geometri.js` → `roblox/buildings/UBRFKomplex.luau` | handskrivna koordinater i `buildings/` |
| Boxfördelning i stallet | `roblox/game/Stallet.luau` (härledd, `[antagande]`) | — | en andra fördelning i webben |
| Referensmaterialets status | `references/` + Supabase `public.reference_assets` | manifestet | prosa i en audit |
| Vilken gate som är aktiv | `docs/ACTIVE-GATE.md` | — | gate-status i en PR-beskrivning |
| Nästa slice och vem som äger den | `docs/KO.md` (ägs av ChatGPT) | — | en tilldelning som bara finns i en chatt |
| Process och statusord | `docs/DELIVERY-PROTOCOL.md` | — | ett nytt governance-dokument |

Supabase `public.hastar` är **upstream från ubrf.se**, inte kanon. Den får
användas för att uppdatera `src/spel/hastar.js`, men varken webben eller Roblox
får läsa den direkt in i spelet — då finns hästarna på två ställen igen.

Om en agent behöver ett domänfakta som inte står i tabellen: lägg till raden
i samma PR som fakta införs, med en ägare. Inte efteråt.

## Kollisionsregeln

**En fil har en skrivande PR i taget.**

Innan en agent börjar arbeta deklarerar den vilka filer den kommer att äga.
Om en fil redan är deklarerad i en öppen PR gäller:

1. den öppna PR:n äger filen,
2. den nya PR:n väntar, eller avgränsas till andra filer,
3. om båda behöver filen sammanfogas arbetet till **en** PR — inte två som
   mergas efter varandra och hoppas mötas.

`git merge-base --is-ancestor` avgör frågan när två brancher hävdar samma
arbete. Om branch B innehåller alla commits i branch A är A överflödig och
stängs som ersatt — den mergas inte "först för säkerhets skull".

Tre filer är särskilt utsatta och ändras aldrig i mer än en öppen PR:
`docs/ACTIVE-GATE.md`, aktivt gate-dokument under `docs/GATE-*`, och
`roblox/tests/kor.sh`.

## Automatiserad grind

`.github/workflows/grindar.yml` kör vid varje PR de kontroller som redan fanns
i repot men var frivilliga:

- `tools/kolla-material.py` — ogiltigt `Enum.Material` fäller Studio
- `tools/exportera-spel.js --kontrollera` — speldata i synk
- `tools/exportera-geometri.js --kontrollera` — geometri i synk
- `roblox/tests/kor.sh` — Luau-specarna, med luau hämtad i jobbet
- `tools/build.py` — webbygget
- checksummor och dörrfärgsparitet där branchen har dem
- en kontroll som fäller om en **genererad** fil handredigerats utan att dess
  generator ändrats

Grinden ersätter inte review och inte Studio-acceptans. Den tar bara bort
möjligheten att påstå Lager B utan exitkod.

`pull_request` kör som standard bara på `opened`, `synchronize` och `reopened`.
`ready_for_review` ingår inte, och saknades först — en PR kunde gå från draft
till bedömbar utan en enda exitkod. Rättat i #37. Läggs ett nytt statusberoende
steg till: kontrollera att händelsen finns i `types`.

## Branch protection på main

Protokollet krävde review i ord; ingenting stoppade en merge utan den. Sedan
2026-08-31 gäller på `main`:

- båda grindjobben (`grindar`, `dubbel-sanning`) måste vara gröna,
- branchen måste vara uppdaterad mot `main` innan merge,
- **en godkänd review** krävs,
- review faller om nya commits pushas efter godkännandet,
- öppna kommentarstrådar måste vara lösta,
- force push och radering av `main` är avstängt.

`enforce_admins` är **av** med avsikt: Tobias behåller en nödutgång. Ingen agent
har den.

## Kön just nu

Ordningen är beslutad på filkollisioner och härkomst, inte på ålder.

**I `main`:** #34 governance (`9771d1c`), #36 grinden (`375c317`), #37
grind-händelsen (`fbab296`).

**Stängda som ersatta:** #32 — hela dess innehåll finns i #33, bekräftat med
`git merge-base --is-ancestor`. #9 — 105 commits bakom `main`; dess teman
ridkänsla, responsiv layout och autopilot levererades av Gate 01.

**Kvar i kön:**

| # | PR | Läge | Varför här |
|---|---|---|---|
| 1 | #35 Supabase-spegel | väntar på review | egen yta, noll kollisioner, redan utlyft ur #33 |
| 2 | #29 skötseln som delad data | väntar på acceptance contract + rebase | inför kanonisk ägare för skötselreglerna |
| 3 | #30 Roblox preparation | blockerad bakom #29 | ska läsa skötseln ur exporten, inte ur egna literaler |
| 4 | #33 F02 granskningsmodell | väntar på Tobias PASS/FEL per rum | underlaget kompletteras först: 66 ridhusbilder + 8 filmer |
