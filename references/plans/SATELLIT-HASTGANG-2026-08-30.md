# Direkt satellitreferens — hästgången mellan ridhus och stall

Datum verifierad: 2026-08-30
Källa: Google Maps satellitbild uppladdad direkt av Tobias i ChatGPT-konversationen 2026-08-30 (`IMG_0253.jpeg`).
Evidensklass: **DIRECT VISUAL SOURCE / PRODUCT OWNER SUPPLIED**.

> Den här filen är en build-accessible verifierad derivatbeskrivning av den uppladdade satellitbilden. Exakta meter ska inte läsas ur skärmdumpen utan separat skala/mätning. Topologin nedan är däremot tydligt synlig.

## Vad bilden visar direkt

1. **Ridhuset och stallet är två långa parallella huvudvolymer.**
   - Ridhuset är den större/mörkare långbyggnaden närmast Enköpingsvägen.
   - Stallet är den smalare parallella långbyggnaden med den tydliga raden av takhuvar/ventilation.

2. **Det finns en tydlig taktäckt tvärgående förbindelse mellan huvudbyggnadernas inre långsidor.**
   - Förbindelsen går tvärs över mellanrummet mellan ridhus och stall.
   - Den är inte placerad längst vid någon av huvudbyggnadernas ändar.
   - Den ligger i den gemensamma/centrala delen av byggnadskomplexets överlappande längd.
   - Detta är den visuellt identifierade hästgången som Tobias tidigare bekräftat finns i verkligheten.

3. **Mellanrummet mellan ridhus och stall är INTE en enda obruten gräsgård.**
   - Den tvärgående förbindelsen delar mellanrummet i **två separata öppna/gröna gårdsytor** på var sin sida om gången.

4. **Den tidigare implementationen med hästgången i norra änden är en KNOWN MISMATCH.**
   - Nuvarande `src/site.js` placerar `hastgang` vid ungefär den ena änden av den gemensamma byggnadslängden.
   - Satellitbilden visar istället en tvärgående förbindelse i den centrala delen.
   - Den placeringen ska därför inte längre klassas som ett acceptabelt `ASSUMPTION`; den ska flyttas mot satellitbildens observerade position.

5. **Bilden ger inte stöd för två fullbredds-förbindelser över gapet.**
   - En tydlig tvärgående takvolym är synlig.
   - Eventuell separat `langa` som också binder ihop båda husen måste därför verifieras mot annan källa innan den får behandlas som verklig förbindelse.

## Vad bilden INTE fastställer

Följande ska fortfarande vara `ASSUMPTION`/`REFERENCE GAP` tills skala eller närmare foto finns:

- hästgångens exakta bredd i meter,
- exakt längd mellan fasaderna,
- takfot/nockhöjd,
- taklutning,
- dörrarnas exakta lägen,
- vilken intern rumsdel i ridhuset respektive stallet som gången mynnar i,
- detaljer inne i hästgången.

## Implementationsregel

Claude ska använda bilden så här:

- **topologin och den relativa placeringen är verifierad:** `RIDHUS ↔ central tvärgående HÄSTGÅNG ↔ STALL`;
- gångens placering ska justeras så att två öppna gårdsytor återstår på var sin sida;
- exakta mått får inte uppfinnas ur skärmdumpen;
- web och Roblox ska konsumera samma korrigerade geometri;
- en eventuell andra förbindande volym får bara behållas om en annan verifierad källa visar den.

## Review-konsekvens

Detta ersätter Gate F01:s tidigare öppna `REFERENCE GAP` om huruvida hästgången ligger i norra änden, mitten eller söder.

**Ny status:**
- hästgångens existens: `VERIFIED` (Product Owner + satellitbild),
- hästgångens centrala/tvärgående relativa placering: `VERIFIED`,
- nuvarande nordliga placering: `KNOWN MISMATCH`,
- exakta dimensioner/anslutningsdetaljer: fortsatt `ASSUMPTION` / `REFERENCE GAP`.
