# Skåp- och receptionskorridor — granskningsunderlag

## Status

`READY_FOR_CHATGPT_REVIEW`

Detta är inte ett allmänt `PASS`, en merge eller en ny produktacceptans.

## Produkt och bas

- Produkt-SHA: `0848366976de118f35ba1c4200948aafa2462e5e`
- Ren förebas: `9a5c9f3bf55fab815cb6742f654f0365a2006c0d`
- Produktträd: `b46a591208ea407176b0bfee09a3e32c258f5849`
- Draft-PR: [#134](https://github.com/Carneteg/UBRF/pull/134)
- Exakt-SHA Vercel-preview: [ubrf-7jmwj7wfe-tobiascarneteg-5898s-projects.vercel.app](https://ubrf-7jmwj7wfe-tobiascarneteg-5898s-projects.vercel.app)

## Changed

- Befintliga skåpluckor har fått tydligare, ljusa profilramar.
- Gröna tvåvåningsskåp har bara källbelagd sockelventilation och befintliga ben.
- Höga grå/svarta skåp har separata över- och sockelband; inga universella luckhål används.
- Vita tvåvåningsskåp har profilramar men ingen osourcad ventilation.
- Samma familjespecifika metadata styr webb- och Roblox-renderingen.
- Roblox-komplexet är deterministiskt regenererat, inte handredigerat.

Skåpantal, footprints, transforms, orientering, collision, väggar, dörrar,
öppningar, reception, läktare och teorisal är inte ändrade. Arenans belysning
är också identisk med basen.

## Source evidence

De exakta GitHub-originalen ligger i
[`packs/0848366976de118f35ba1c4200948aafa2462e5e/sources/github/`](packs/0848366976de118f35ba1c4200948aafa2462e5e/sources/github/):

| Källa | Användning |
|---|---|
| `ridhus-klubb-01-omkladningsgangen.jpg` | korridorens befintliga skåpgrupper |
| `ridhus-klubb-02-glasrummen.jpg` | receptionens glasrum och befintliga passage |
| `ridhus-klubb-15-korridoren-mot-glasrummen.jpg` | riktning mot glasrummen och skåpens befintliga placering |
| `ridhus-klubb-16-skaprummet-med-pelaren.jpg` | pelare och vita tvåvåningsskåp |
| `ridhus-klubb-18-skapraden-narbild.jpg` | ljusa profiler samt separata över-/sockelband |
| `ridhus-klubb-20-grona-skapen.jpg` | gröna tvåvåningsskåp, ben och sockelventilation |
| `ridhus-klubb-21-grona-skapen-vinkel.jpg` | samma gröna familj ur en andra vinkel |

Google Drive-originalet `IMG_0268.MOV` hämtades och granskades. Det bekräftar
befintligt valvfönster, bänk/kläder och enkel korridorbelysning men användes
inte för nya objekt eller nya mått. Originalets SHA-256 är
`751a4bfa81246a0f1b3c6d31405f29ba0ec96298bb1119e99a564ab83c97f69b`.
En härledd kontaktbild finns i
[`sources/drive/IMG_0268-contact.jpg`](packs/0848366976de118f35ba1c4200948aafa2462e5e/sources/drive/IMG_0268-contact.jpg).

Supabase REST returnerade 82 `reference_assets`, men 0 exakta namnträffar för
`ridhus-klubb-16/-18/-20/-21` och `IMG_0268`; de raderna användes därför inte
som belägg för detaljgeometri.

## Visual evidence

- [21-kamerors index](packs/0848366976de118f35ba1c4200948aafa2462e5e/index.html)
- [Maskinläsbar pack.json](packs/0848366976de118f35ba1c4200948aafa2462e5e/pack.json) — `head` är produkt-SHA och `smutsigt` är `false`
- [RIDHUS-SKAPKORRIDOR efter](packs/0848366976de118f35ba1c4200948aafa2462e5e/RIDHUS-SKAPKORRIDOR.png)
- [RIDHUS-SKAPRUM efter](packs/0848366976de118f35ba1c4200948aafa2462e5e/RIDHUS-SKAPRUM.png)
- [RIDHUS-RECEPTION efter](packs/0848366976de118f35ba1c4200948aafa2462e5e/RIDHUS-RECEPTION.png)
- [Tre rena före-bilder och baseline-pack](packs/0848366976de118f35ba1c4200948aafa2462e5e/before-9a5c9f3bf55fab815cb6742f654f0365a2006c0d/)

Alla 21 kameror renderades och spelaren är synlig i samtliga. De tre
prioriterade korridorvyerna är dessutom kontrollerade manuellt.

## Tested

- JS-syntax, 58 Luau-filer och 14 Luau-testgrupper.
- Material-, speldata-, ridkanon-, geometri- och webb/Roblox-paritet.
- Interiörlåset: accepterad arkitektur/läktare, skåpfootprints, transforms,
  collision samt teorisalens 24 objekt och hash.
- Deterministisk export av `UBRFKomplex.luau`.
- 21 visuella kameror och 20 spatiala ankare.
- Siktgrind: 181 punkter, 0 dolda.
- Gång/navigation, ridruntime, gårdens 29 mätningar, uppdragskedjans 25
  mätningar, läktare och Ugneta-kanon/UI/försök.
- Oberoende arkitektgranskning av den korrigerade kumulativa produktdiffen:
  `PASS` utan kvarvarande severity-fynd.

## Falsified

- Geometrimutation avvisas av interiörlåset.
- Siktgrinden blir röd med toning avstängd: 10 dolda punkter.
- Första produktförsöket underkändes för arenaomfattande ljusändring,
  universellt hålmönster och övertolkad källklass. Dessa ändringar togs bort;
  evidensen regenererades först efter ny oberoende granskning.

## Not tested

- Verklig Roblox Studio-runtime och Studio-skärmbild: **Not tested**.
- Roblox-materialens slutliga visuella utfall i Studio: **Not tested**.
- Några exakta skåp- eller ventilationsmått: källorna saknar måttsättning.

## Remaining risk

- `ridhus-klubb-20/-21` ligger kvar på källklassen `FOTO`, inte `VERIFIED`.
- Antalet små renderade ventilationssegment är visuell upplösning, inte ett
  påstående om exakt hål- eller spaltantal.
- Studio-paritet kan inte produktgodkännas förrän verklig Studio-runtime har
  körts och granskats.
