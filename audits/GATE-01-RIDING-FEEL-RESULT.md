# Gate 01 — Riding Feel: resultat

Commit att granska: `33559d96e59b8ba7e88f2ba6a5ff7a71ab32c30b`
Datum: 2026-08-29
Implementation: Claude Code
Status: **lämnas till ChatGPT för review.** Gaten stängs inte av mig.

---

## 1 · Ändrade filer

| Fil | Vad |
|---|---|
| `src/game.js` | Ridinputkontraktet (`RIDIN`, `ridAvsiktTillHjalp`), svängen som kurvatur, gångartsfas ur sträcka, kroppens svänglutning, dt-baserad väggrespons |
| `src/mobil.js` | Joysticken matar ridinputen kontinuerligt i stället för syntetiska W/A/S/D; expo-kurva och dödzon |
| `src/scen3d.js` | Kamerans egen kurs, mjukad boom, separata svar för position och blickpunkt; hästkroppens lutning som egen rotation |
| `src/scenes.js` | Nollställer kurvatur, sträcka och fas när ett pass börjar om |

Ingen ny fil, inget nytt beroende, ingen fysikmotor, ingen WebGL-omskrivning.

---

## 2 · Root causes som faktiskt löstes

**P0 — touchjoysticken var inte analog i ridningen.** `IN.joy` fanns men lästes
aldrig av ridningen. `joyLage` skickade i stället syntetiska tangenthändelser när
axlarna passerade trösklar (`dy<-0.28`, `dx>0.32`), så spaken var visuellt analog
men ridmodellen fick tre lägen.

**P0 — vridhastigheten växte med farten.** `omega = styrning × clamp(0.5 + tempo×0.22, 0.4, 2.2)`.
I galopp gav full styrning 2,2 rad/s, alltså 126°/s. Det gör att man viker hästen
genom en sväng i stället för att rida en båge, och det är kärnan i fordonskänslan.

**P0 — fasen var tidsdriven, inte distansdriven.** `gaitFas += stegFrek × dt × (0.6 + tempo×0.12)`.
Nära rätt, men samma sträcka kunde ge olika många hovnedslag beroende på hur tempot
varierade på vägen.

**P1 — kroppen svarade inte på svängen.** `s3RitaHast` hade bob och galoppvaggning
men ingen rullning ur den faktiska rörelsen.

**P1 — kameran kopierade hästens kurs.** Boom och blick byggdes båda direkt ur
`G.rikt` med en gemensam utjämningsfaktor, och boomens väggsökning gav diskreta
längdhopp.

**P1 — väggresponsen var bildfrekvensberoende.** `lerpAngle(..., 0.06)` per bildruta.

---

## 3 · Före och efter

| | Före | Efter |
|---|---|---|
| Touch 25/50/100 % | samma sväng (tröskel passerad = full input) | 61 m / 19,6 m / 4,4 m radie |
| Full styrning, skritt | 1,77 m radie, 0,82 rad/s | 3,63 m radie, 0,40 rad/s |
| Full styrning, galopp | 3,9 m radie, **2,2 rad/s (126°/s)** | 6,97 m radie, 0,80 rad/s (46°/s) |
| Radie mot fart | krympte relativt (yaw växte snabbare än tempot) | **ökar**: 3,6 → 4,4 → 7,0 m |
| Gångartsfas | tid × tempo | sträcka ÷ cykellängd |
| Kroppens lutning i sväng | ingen | 0° halt, 0,4° skritt, 1,7° trav, 3,2° galopp |
| Väggkurs vid 30 vs 144 Hz | olika (fast faktor per ruta) | identisk |
| Kamerans kurs | hästens, direkt | egen, 0,16 s fördröjning |

---

## 4 · Hur analog touch verifierades

Playwright i 390×844 med touch. Joysticken dras med riktiga `PointerEvent` till
25, 50 och 100 procent av sin radie, och `RIDIN.styr` och den resulterande
kurvaturen läses ur körande spel:

| Spakutslag | `RIDIN.styr` | Kurvatur (1/m) | Svängradie |
|---|---|---|---|
| 25 % | 0,072 | 0,0164 | 61,1 m |
| 50 % | 0,226 | 0,0511 | 19,6 m |
| 100 % | 1,000 | 0,2255 | 4,4 m |
| släppt | 0 | — | — |

Tre tydligt olika resultat: en linjekorrigering, en 20 m volt och en snäv volt.

Kurvan är expo (35 % rak, resten kubisk) med dödzon 0,07. En rent kvadratisk kurva
provades först och föll: 25 % gav 2 % styrning, alltså 203 m radie — i praktiken
rakt fram, vilket inte är tre användbara nivåer.

---

## 5 · Styrrespons per gångart och nivå

Mätt i körande spel med tempot låst vid gångartens norm, hästen fryst mitt på banan
så att väggarna inte kommer in i mätningen. Häst: Lydia (känslighet 0,5-klassen).

| Gångart | Tempo | Styrning | Kurvatur (1/m) | Radie | Vridhastighet |
|---|---|---|---|---|---|
| Skritt | 1,45 | 0,25 | 0,0689 | 14,5 m | 5,7°/s |
| Skritt | 1,45 | 0,50 | 0,1379 | 7,3 m | 11,5°/s |
| Skritt | 1,45 | 1,00 | 0,2758 | 3,6 m | 22,9°/s |
| Trav | 3,20 | 0,25 | 0,0565 | 17,7 m | 10,4°/s |
| Trav | 3,20 | 0,50 | 0,1131 | 8,8 m | 20,7°/s |
| Trav | 3,20 | 1,00 | 0,2261 | 4,4 m | 41,5°/s |
| Galopp | 5,60 | 0,25 | 0,0359 | 27,9 m | 11,5°/s |
| Galopp | 5,60 | 0,50 | 0,0717 | 14,0 m | 23,0°/s |
| Galopp | 5,60 | 1,00 | 0,1434 | 7,0 m | 46,0°/s |

Kurvaturen är linjär i styrningen (0,25 → 0,50 → 1,00 ger exakt 1×, 2×, 4× av
kvartsvärdet), och radien ökar monotont med gångarten vid varje nivå.

En 20 m volt behöver 10 m radie: i trav rids den på ungefär 0,45 styrning, alltså
delvis utslag — precis vad Target feel punkt 4 efterfrågar.

---

## 6 · Test desktop / mobil / surfplatta

**Hela kedjan spelad med tangenttryck och riktiga tryck**, från start till
resultatskärm: Rid direkt → gården → stallentrén → ridläraren → hästen i hagen →
tillbaka in → boxen → sadelkammaren → skötseln → led ut → ridhuset → sargporten →
lektion → resultat.

- Desktop 1280×800: alla fjorton stegen OK, noll konsolfel.
- Mobil 390×844 touch: alla fjorton stegen OK, noll konsolfel.

**Layout på tolv viewports** (320×568, 375×667, 390×844, 430×932, 844×390 liggande,
768×1024, 820×1180, 1024×1366, 1180×820 liggande, 1280×720, 1440×900, 1920×1080):
inga överlapp, ingen sidled-scroll, inget utanför bild, alla touchmål ≥ 44 px.

---

## 7 · 30 vs 60 vs 144 Hz

Samma manöver, tre bildfrekvenser, tre sekunder trav med styrning 0,6:

| | 30 Hz | 60 Hz | 144 Hz |
|---|---|---|---|
| Kurvatur (1/m) | 0,1357 | 0,1357 | 0,1357 |
| Kurs (rad) | 0,337 | 0,321 | 0,323 |
| Gångartsfas | 0,567 | 0,521 | 0,495 |

Kurvaturen är **exakt identisk** — den är ett dt-baserat filter mot ett mål som
inte beror på bildrutan. Kursen skiljer 0,014 rad (0,8°) över tre sekunder, vilket
är integrationsfel i Eulersteget och inte en beteendeskillnad.

Väggresponsen, rakt in i sargen i tre sekunder: kursen blir **−1,561 rad vid alla
tre frekvenser**. Före ändringen var den bildfrekvensberoende.

Fasen skiljer 0,072 av ett varv (26°) mellan 30 och 144 Hz. Det följer av att
sträckan skiljer några centimeter av samma integrationsfel; det syns inte i
animationen, men det är den siffra som är känsligast av de mätta.

---

## 8 · Kvarvarande begränsningar

1. **Ryttarens sekundärrörelse (P1) är inte byggd.** Den pedagogiska sitslogiken är
   orörd och fungerar, men de små inertiala reaktionerna på acceleration och sväng
   som Gate-dokumentet efterfrågar finns inte. Detta är den enda P0/P1-punkt i
   dokumentet som står obesvarad.
2. **Känslan är inte bedömd.** Alla siffror ovan säger vad modellen gör, inte om
   den känns rätt. Att en 20 m volt rids på 0,45 styrning är en mätning; om det
   känns lagom avgörs av en människa som rider.
3. **Konstanterna är trimmade mot mätningar, inte mot playtest.** `KAPPA_MAX` 0,42,
   gångartsfaktorerna, expo 0,35, dödzon 0,07, lutningens 0,012-skalning och
   kamerans 0,16 s — alla är valda för att träffa rimliga tal i tabellerna ovan.
   De är avsedda att justeras efter Studio-/webbplaytest.
4. **Mätningarna fryser hästen mitt på banan** för att hålla väggarna utanför.
   Samspelet mellan sväng och sarg i ett verkligt hörn är alltså inte mätt, bara
   observerat som att kursen blir bildfrekvensoberoende.
5. **Gamepad är inte provad.** Kontraktet tar emot analoga värden, men ingen
   gamepad har testats i den här miljön.

---

## 9 · Roblox-portabilitet

Modellen är avsiktligt motoroberoende: styrkurvan, gångartens kurvaturtak,
kurvaturens tidskonstanter, faslagen och lutningens centripetalsignal är rena tal
och regler utan WebGL-beroende. Gångartsfaktorerna (`skritt 1,00 / trav 0,82 /
galopp 0,52`) är samma storhet som `turn` i `roblox/src/shared/HorseCore/Gaits.luau`,
så designen översätts i stället för att uppfinnas igen.

---

## 10 · Acceptanskriterier

| Kriterium | Status |
|---|---|
| `IN.joy` eller motsvarande analog data används kontinuerligt i ridinputen på touch | ✅ |
| 25/50/100 % joystick ger mätbart och visuellt olika styrrespons | ✅ 61 / 19,6 / 4,4 m |
| keyboard och touch går genom samma normaliserade ridinputkontrakt | ✅ `RIDIN` |
| svängradien ökar i praktiken med fart/gångart vid jämförbar input | ✅ 3,6 → 4,4 → 7,0 m |
| inga synliga pivots/powerslides i trav eller galopp | ✅ vridhastigheten sjönk från 126 till 46°/s; kurvatur × tempo kan inte ge pivot |
| gångartsfas är kopplad till faktisk förflyttning/effektiv steglängd | ✅ |
| hästen har smoothed visuell turn lean från faktisk rörelse | ✅ centripetal, 0–3,2° |
| ryttaren följer hästen subtilt utan att pedagogisk sitslogik försvinner | ❌ **inte byggt** |
| kamera känns stabil i raksträcka, volt och hörn | ⚠️ egen kurs, mjuk boom, separata svar — men "känns" är inte mätt |
| kameran hoppar inte synligt vid väggundvikande | ✅ boomen utjämnad i stället för diskreta steg |
| väggkollision/steering correction är frame-rate independent | ✅ identisk kurs vid 30/60/144 Hz |
| 30 och 60 FPS ger jämförbar styrkänsla | ✅ kurvaturen identisk |
| befintlig första lektion går att spela från start till resultat | ✅ desktop och mobil |
| inga nya konsolfel | ✅ |
| inga nya features utanför Gate 01 | ✅ |

**Tolv av femton uppfyllda, en obyggd, en som kräver mänsklig bedömning.**

---

## 11 · Överlämning

Enligt `docs/GATE-01-RIDING-FEEL.md` stänger jag inte gaten. Arbetet lämnas till
ChatGPT för senior gameplay review av diff, mätresultat och Product Canon-följsamhet,
och till Tobias för avgörandet om känslan räcker.

Om känslan inte sitter trots de gröna raderna ovan ska gaten inte stängas —
dokumentets egen regel, och den rätta.
