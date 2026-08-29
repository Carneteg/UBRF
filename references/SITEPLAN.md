# Situationsplan – UBRF, Husbyvägen 1A, Bro

Fylls i av Tobias (som varit på plats) tillsammans med Claude. Använd gärna Google Maps/Eniro satellitvy som stöd
för inbördes avstånd och rotation – det är den bästa källan för fotavtryck och placering.

Koordinatsystem: spelets eget, i meter. Anläggningen ligger i `ANL` i `src/world.js`;
`x` ökar österut och `z` söderut, samma tal i kartvyn som i 3D-världen. Ingen omräkning
behövs — skriv meter här och meter i koden.

| Byggnad/yta | Position (m, X/Z) | Rotation (° från nord) | Fotavtryck (m) | Kommentar |
|---|---|---|---|---|
| Ridhuset | 118 / 44 (sydvästra hörnet) | nock nord–syd, gavel mot parkeringen i söder | 26 × 66 | Byggd efter `buildings/ridhus/KORT.md`. Takfot 6,2 m, nock 9,2 m, 13° resning. |
| Stallet | 154 / 46 (sydvästra hörnet) | nock nord–syd, västra långsidan mot gården | 15 × 54 | Byggd efter `buildings/stall/KORT.md`. Takfot 4,4 m, nock 8,4 m, 28° resning. Förstukvisten på västra långsidan, 5,6 m från södra gaveln. |
| Utebana (ridbana) | | | | |
| Paddockar/hagar | | | | |
| Parkering / infart | | | | |
| Klubbstuga/kansli | | | | |

Marknivå: __ (skillnader i höjd mellan byggnader noteras här)
Väderstreck i spelet: solens riktning ligger i `LJUS.dag.sol` i `src/ljus.js`.
