# Produktbeslut #162 — utrustningen

PO-beslut av Tobias vid accepten av `BLOCKER_5_PHYSICAL_TACK_PASS`, SHA `30f3d90`.
Dokumentet registrerar besluten; det uppfinner inga nya krav.

## Beslut 1 — utrustningens plats

**WEB GAMEPLAY PARITY + REAL UBRF PHYSICAL PLACEMENT.**

Sadel, underlägg och träns hör fysiskt ihop med **hästens egen box/boxfront**,
som implementerat i `roblox/src/server/TackForradService.luau`.

Skälet är källordningen: för UBRF:s **fysiska** utformning är verkligheten och
fotoreferensen facit över webbens förenklade representation.

> `references/buildings/stall/KORT.md:305`
> "På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
> benskydd — mycket saker, tätt."

Sadelkammarens referensbild (`stall-inne-03-sadelkammaren.jpg`) visar stövlar
och täcken, inga sadlar.

Webben är fortsatt facit för **spelkonceptet**:

- utrustningen är hästspecifik,
- rätt kontra fel utrustning är gameplay,
- spelaren måste fysiskt hämta utrustningen innan hon kan göra i ordning hästen.

**Flytta inte utrustningen till sadelkammaren enbart för webbparitet.**
De två ytorna får alltså skilja sig i *var* utrustningen hänger, men inte i
*vad* som gäller om man tar fel.

## Beslut 2 — dagsformsstraffet vid fel utrustning

**Implementeras INTE nu.** Roblox har i dag inget dagsformssystem.

Kroken och API:t behålls för en framtida **delad** dagsformsimplementation:
`TackService.felAntal(player)`, `Svar.startEnergi(dagsform)`,
`RidKanon.START.DAGSFORM`.

Det som INTE får göras:

- uppfinna ett Roblox-only dagsformssystem,
- ändra låst lokomotion,
- fejka straffet med orelaterade rörelsevärden.

Kravet på nuvarande beteende står kvar oförändrat:

> fel utrustning går att välja och försöka sätta på
> → nekas
> → spelaren får den kanoniska förklaringen
> → händelsen är mätbar och räknas

## Paritetsbacklog

| # | Punkt | Webbens sanning | Roblox i dag | Blockeras av |
|---|---|---|---|---|
| P-1 | Fel utrustning ska kosta dagsform | `scenes.js:471-474`: `dagsform -= 0,03 × min(felUtrustning, 3)` | felet nekas, förklaras och räknas i `TackService.felAntal`, men kostar ingenting | Roblox saknar dagsform (`Svar.luau:306-308`). Kräver en **delad** dagsformsimplementation, egen grind. |
