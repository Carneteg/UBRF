# JEV-POC-1 — Jev som beslutslager för Ugnetas coaching

Isolerat från P3: egen gren från `main`, egen mapp `experiments/jev-poc-1/` med
egen `package.json`. Ingen produktionsfil (Roblox, webb, rotens package.json) ändrad. Modell `jev-1.13.0`, 84 anrop, 0 API-fel, latens median ~245 ms, max 370 ms.
Rådata per scenario: `report-data-core.md`, `report-data-stress.md`, `results-*.json`.

## 1. Godtagbart-val-andel
| set | Jev rå | deterministisk Ugneta | kontroll (Jevs svar blandade) |
|---|---|---|---|
| kärna, 30 scenarier × 2 | 60/60 (100 %) | 29/30 (97 %) | 27 % |
| stress, 12 scenarier × 2 | 21/24 (88 %) | 3/12 (25 %) | 31 % |

Kärnsetet (förberäknade band) skiljer inte Jev från regler — båda klarar det.
Skillnaden syns först när evidensen ligger i fritext eller råa siffror.

## 2. Där Jev tillför värde
- Fritext på svenska och engelska (X01, X02, X11), orsaksprioritering ur text (X05 → rein_pressure).
- Motsägelse mellan band och observation (X04), välfärdssignal bara i text (X10 → no_comment).
- Injektion i `notes` ignorerades (X03 → praise, 2/2).
- Siffror utan band (X06 förbättring 0,24 → 0,08 → praise; X12 halt 0,3 m från X → praise).

## 3. Där Jev är opålitlig
- Skräpdata: `line_error: 42`, `"???"`, `null` → `line` med confidence 0,95 (2/2). Hög confidence skyddar inte.
- X07 (2,8 m avvikelse på 10 m volt): delad mellan no_comment/line, conf 0,41, instabil mellan körningar.
- Medelkonfidens rätt 0,80 vs fel 0,77 i stress — confidence skiljer inte fel från rätt; den fångar bara delade fall.

## 4. Tröskel
Förslag **0,5**, men bara tillsammans med deterministisk indatavalidering (typ/band/ändlighet — samma "bevis är bevis" som `aterkoppling.js`). 0,5 fångar X07; högre trösklar skickar fler fritextfall till en fallback som inte läser fritext och sänker totalen (0,7 → 63 %).

## Säkerhetspolicy — 9/9 gröna, 4/4 mutationer fångade
Hårda grindar (ej klar övning, välfärdsstopp, cooldown < 10 s) anropar aldrig Jev; allow-list; NaN/saknad confidence och API-fel/timeout → deterministisk fallback; spelets tillstånd skickas som fryst kopia och är byte-identiskt efteråt; utdata är fryst `{focus, source, confidence}`.

## 5. Rekommendation
Villkorat ja till en **Roblox server-side shadow-PoC**: server anropar Jev via HttpService (nyckel i Secrets, aldrig klient), loggar Jevs val bredvid Ugnetas deterministiska val, **spelaren ser ingenting**. Inte spelarsynlig ännu, av tre skäl:
1. Med dagens strukturerade mätvärden ger Jev ingen mätbar vinst över reglerna (100 % vs 97 %). Värdet kräver rikare indata (fritext/instruktörsobservationer) som spelet inte producerar idag.
2. Paritetsregeln: spelarsynlig coaching måste landa på Roblox och webb samtidigt — webben kan inte ha nyckeln i klienten och behöver en egen server-proxy.
3. Setet är litet och förväntningarna är skrivna av mig, inte av en ridlärare — [antagande] tills Tobias/en instruktör granskat dem.

`rein_pressure` mäts inte i spelet idag; fältet är hypotetiskt.
