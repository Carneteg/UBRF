# Teorisal — reviewunderlag

## Exakt produktbas

- Produkt-SHA: `1c6157463422f163ad210f8a33994619c60dcb06`
- Renderbas före ändringen: `c985bbf30150f638b033b878b2e9464b2176429d`
- Fast kamera: `STALL-TEORISAL`
- Produktpaket: [`packs/1c6157463422f163ad210f8a33994619c60dcb06/`](packs/1c6157463422f163ad210f8a33994619c60dcb06/)
- Förebild: [`packs/c985bbf30150f638b033b878b2e9464b2176429d/STALL-TEORISAL.png`](packs/c985bbf30150f638b033b878b2e9464b2176429d/STALL-TEORISAL.png)
- Efterbild: [`packs/1c6157463422f163ad210f8a33994619c60dcb06/STALL-TEORISAL.png`](packs/1c6157463422f163ad210f8a33994619c60dcb06/STALL-TEORISAL.png)
- Original: [`../../references/buildings/stall/stall-inne-04-teorisalen.jpg`](../../references/buildings/stall/stall-inne-04-teorisalen.jpg)

## Changed

- Befintliga whiteboards, två planscher, tre bord, tio stolar, två armaturer
  och den befintliga takrännan har fått källsynliga rendererdetaljer.
- Klubbrummens golv använder en särskild lågkontrasterad, periodisk och
  icke-riktad matt betongyta i webbversionen.
- Samma objektsidentitet och detaljmetadata exporteras till Roblox.

## Falsified

- Samtliga 24 befintliga teorisalsobjekts `pos`, `z0`, `matt`, `rikt` och
  collision är hash-låsta mot baslinen före korrigeringen.
- Ingen läsbar whiteboardtext eller anatomietikett har rekonstruerats.
- Ingen dörr, möbel, öppning, footprint eller rumsgeometri har lagts till.
- Den tidigare upplevda golvfogen finns inte i produktbilden.

## Tested

- Webbbuild och käll-/runtimekontroller för interiören.
- A-gavelns öppnings- och geometriguard.
- Läktarens 13 mätningar.
- Ridkärna, gång, gård, hästkanon-save, Ugneta och uppdragskedja med
  Replits underhållna Chromium.
- Roblox-exporten regenererades två gånger med identisk filhash.
- Reviewverktyget producerade 21 av 21 fasta kameror från ren produkt-SHA.

## Not tested

- Roblox Studio-runtime och en faktisk Roblox-efterbild finns inte i denna
  miljö. Export- och strängkontroller är inte ett visuellt paritetsbevis.
- Vercel-preview och GitHub CI ska kontrolleras efter evidenscommitten.

## Reviewstatus

`READY_FOR_CHATGPT_REVIEW`

Detta dokument sätter inte `PASS` eller `PRODUCT_ACCEPTED`. ChatGPT-review och
Tobias uttryckliga PASS återstår.