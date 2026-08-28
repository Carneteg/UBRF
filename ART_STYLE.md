# ART_STYLE.md — facit för allt visuellt i Ridskolan

**`ui-kit-demo.html` i projektroten är den visuella sanningen.** Öppna den innan
något ändras. Variablerna och komponenterna där återanvänds i hela spelet — de
skrivs inte om, de importeras. Den här filen beskriver dem; vid konflikt vinner
`ui-kit-demo.html`.

Stilgenren är *färgglad, målad hästspelsestetik* för mobil. Vi härmar genren,
aldrig ett enskilt spels bilder, logotyper eller namn.

Läs också `references/` innan något visuellt görs.

## Variablerna

Alla färger ligger i `:root`. Ändra dem där — aldrig inline, aldrig en hex i en
komponent.

```css
--sky-top:#4EA8DE;   --sky-bottom:#9BD4F5;
--grass:#5CBB3F;     --grass-dark:#2E8B2E;   --grass-light:#8FD65A;
--panel-top:#8A3BD4; --panel-bottom:#4A1B6D; --panel-border:#F6C445;
--gold:#F6C445;      --gold-dark:#C99424;    --cream:#F5EFE0;
--emerald:#3DDC97;   --heart:#FF5A79;        --brown:#8B5A2B;
--btn-green-top:#7ED957;  --btn-green-bottom:#3E9E2E;
--btn-gold-top:#FFD966;   --btn-gold-bottom:#E0A62E;
--btn-purple-top:#A55BE8; --btn-purple-bottom:#6A2C91;
--text-outline: 0 2px 0 rgba(40,10,60,.55);
```

Typsnitt: `"Arial Rounded MT Bold", "Trebuchet MS", Verdana, Arial, sans-serif`.
Rundat, tjockt, inget annat.

## Komponenterna

Klassnamnen kommer från kitet och används som de är:

| Klass | Vad |
|---|---|
| `.scene` | hela spelytan: himmelsgradient, sol, moln, kullar |
| `.sun` `.cloud .c1 .c2` | sol med glow, moln som driver långsamt i sidled |
| `.hills` `.hill .h1 .h2 .h3` | tre rundade kullager i gräsfärgerna |
| `.hud` | översta raden: nivåbricka, XP-mätare, pillren |
| `.badge-lvl` | rund nivåbricka, lila radial med guldkant |
| `.pill` | valuta/liv: mörk lila kapsel med guldkant och `+`-knapp |
| `.coin.gold` `.gem` `.heart` `.plus` | mynt, ädelsten (roterad ruta), hjärta, plusknapp |
| `.xp` `.bar` `.fill` `.fill.mint` `.gloss` `.txt` | mätare med glansreflex och text i mitten |
| `.gametitle` `.subtitle` | speltiteln som guldgradient med lila drop-shadow |
| `.panel` `.panel h2` `.inner` | lila panel med guldram och rundad rubrikflik |
| `.quest` `.icon` `.info` | uppdragsrad: rund guldikon, text, liten mätare |
| `.btn` + `.green` `.gold` `.purple` `.big` `.round` | knappar |
| `.btnstack` `.btnrow` `.menu-center` `.row` | layout |

**Knappen är signaturen:** 6 px hård skugga under, inre vit glans upptill, inre
mörk skugga nedtill, och en indragen vit outline (`outline-offset:-6px`). Vid
tryck sjunker den 4 px och skuggan krymper till 2 px. `.big` pulsar långsamt.

**Mätaren** har alltid tre lager: `fill`, `gloss` och `txt`.

**Rubrikfliken** i panelen har `border-radius:18px 18px 40% 40%` — den rundade
underkanten är en del av uttrycket.

## Formspråk

- Inga skarpa hörn. Paneler 22 px, knappar 18 px, runda knappar 50 %.
- Chunky: 4 px guldram runt paneler, 2,5 px runt piller och mätare.
- All text är fet (800–900) och vit med `--text-outline`.
- Ikoner är runda med vit kant och skugga under.

## Ljus och känsla

Klar solig dag. Höga mättade färger, mjuka skuggor, ingen hård svärta.
Naturen frodig och överdriven. Varmt, tryggt, drömskt — PEGI 3.

## Arbetsdelning — vad som ritas hur

**Ritas ALDRIG med kod** (hästar, karaktärer, byggnader, träd, buskar, rekvisita):
PNG-sprites i `assets/`, inlagda med `<img>` eller `drawImage`. Saknas en asset
används en tydligt markerad platshållare (emoji duger i demon) och den förs upp i
`ASSETS_NEEDED.md`.

**Ritas med kod:** himmel, sol, moln, kullar och mark, allt UI, HUD, knappar,
paneler, mätare, partiklar, övergångar och animationer.

## Arbetssätt

1. Läs `ui-kit-demo.html` och `references/` först.
2. Bygg med kitets variabler och klasser. Skriv inte nya varianter av en
   komponent som redan finns.
3. Efter varje visuell ändring: skärmdump med Playwright, jämför själv mot
   `references/` och mot kitet, justera avvikelserna innan något visas upp.
4. Kritik ska peka: inte "snyggare", utan *"himlen är för blek, gräset ska vara
   mer mättat grönt som i referensen"*.
