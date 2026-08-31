# Integration — kön, kanoniska ägare och kollisionsregeln

Det här dokumentet är ett **tillägg** till `docs/DELIVERY-PROTOCOL.md`, inte en
ny governance. Protokollet säger *hur* en leverans ska bevisas. Det här säger
*vem som får skriva var, i vilken ordning arbetet går in, och vem som avgör när
två agenter har byggt samma sak.*

Det skrevs efter en mätning 2026-08-31 som visade att repot hade sex öppna
PR:er, att 23 filer ändrades i mer än en av dem, att två PR:er skapade samma
gate-dokument och att `ACTIVE-GATE.md` ändrades i tre parallellt. Protokollet
förbjöd redan detta i ord. Det som saknades var någon som höll kön.

## Roller — oförändrade

`CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS` gäller precis som i
`docs/DELIVERY-PROTOCOL.md`. Ingenting här flyttar acceptansen från Tobias.

Ett fjärde ansvar läggs till, och det är avsiktligt **inte** ett
bedömningsansvar:

### Integrationsledare

- håller **en** merge-kö och basbranch,
- avgör vilken PR som äger en fil när två vill ändra den,
- utfärdar filkarantän innan arbete börjar, inte efter,
- fäller dubbla sanningar om samma domänfakta,
- sammanfogar överlappande brancher i stället för att låta dem konkurrera,
- godkänner **ingenting** — varken review eller produktacceptans.

Integrationsledaren får inte skriva gameplay, geometri eller fidelity. Om
integrationen kräver en kodändring går den tillbaka till den som äger filen.

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

## Kön just nu

Ordningen är beslutad på filkollisioner och härkomst, inte på ålder:

| # | PR | Varför här |
|---|---|---|
| 1 | #34 governance | rör bara governance-filer, gör resten bedömbar |
| 2 | denna PR | sätter grinden innan innehåll mergas |
| 3 | #35 Supabase-spegel | egen yta, noll kollisioner, redan utlyft ur #33 |
| 4 | #29 skötseln som delad data | inför kanonisk ägare för skötselreglerna |
| 5 | #30 Roblox preparation | rebasas på #29 och ska läsa skötseln ur exporten, inte ur egna literaler |
| 6 | #33 F02 granskningsmodell | innehåller hela #32 — #32 stängs som ersatt |

#9 är 105 commits bakom `main` och stängs. Dess teman — ridkänsla, responsiv
layout, autopilot — levererades av Gate 01. Om något i den fortfarande behövs
skrivs det om mot nuvarande kod.
