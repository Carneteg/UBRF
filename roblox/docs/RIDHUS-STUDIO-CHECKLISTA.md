# Ridhuset i Studio — manuell slutkontroll

Testbänken mäter vad byggaren PRODUCERAR: antal, lägen, storlekar, färger och
relationer. Den ser inte utseende, material, ljus eller prestanda. Den här
listan är det som återstår och som bara går att avgöra i Studio.

Kör `roblox/buildings/.studio/UBRF-klistra-in.luau` och gå igenom punkterna.
Varje rad har vad du ska SE och vad som är fel om du ser något annat.

## 1. Den rostbruna panelen

- [ ] Panelen finns på **EN** långsida, inte båda.
- [ ] Den täcker **en del** av väggen (~34 m av 77), inte hela längden.
- [ ] Tonen är dov gråbrun-mauve, inte mättat rödlila.
- [ ] Tre vita vågräta läkt ligger på panelen.
- [ ] Resten av samma vägg är ljus.

Fel om: panelen syns på båda sidor, går hela längden, eller lyser rödlila.

## 2. Sponsorväggen

- [ ] Sex skyltar hänger **på panelen**, inte på den ljusa delen.
- [ ] Ordningen följer `ridhus-inne-02` från vänster.
- [ ] Ingen skylt hamnar utanför panelens stycke.

Förenklad grafik är i sin ordning. Fel antal eller fel ordning är det inte.

## 3. Fönsterbandet

- [ ] Ett band av fönster mellan panelens överkant och takfoten.
- [ ] Bandet löper **förbi** panelens stycke, in på den ljusa delen.
- [ ] Poster syns som poster, inte som en slät remsa.

## 4. Kortändan vid C

- [ ] Trappstegsblock på sockel, flera rader **över** sargkrönet.
- [ ] Två trappor upp, med räcken.
- [ ] Glasbandet i **segment**, brutet av trapporna — inte en obruten remsa.
- [ ] Vit vägg mellan bänkarnas ovankant och glasets underkant.
- [ ] Rund vit klocka **mellan** de två trapporna.
- [ ] Kompassros, linjeritad, **vänster** om vänstra trappan.

Fel om: gapet mellan bänkar och glas visar skalets material i stället för
den vita väggen.

## 5. Domarbåset vid E

- [ ] Båset står på en upphöjd nivå, i mörkt trä.
- [ ] Sadeltak med utskjutande takfot — inte en låda med lock.
- [ ] Trappa med räcke på **båda** sidor.
- [ ] Grön exit-skylt vid öppningen.

## 6. Taket

- [ ] Takstolar i **mörkt gråbrunt, nästan neutralt** trä — INTE varmt
      limträ som stallets. En värmemask på `ridhus-inne-01` gav 35 kpx varma
      mot 517 kpx neutrala. Ser taket varmbrunt ut är det fel.
- [ ] Stålprofiler tvärs balkarna.
- [ ] Kabelstegar **med stegpinnar** — de syns i `ridhus-inne-01` och ska
      finnas. En slät låda läser som ännu en balk.
- [ ] Stora runda ventilationskanaler.

## 7. Banan och sargen

- [ ] 20 × 60, sarg i vitt/gräddvitt med mörkt sockelband.
- [ ] Sanden är dovt brungrå (`#6F5D4D`), inte ljus beige eller orange.
- [ ] Porten vid A och grinden mot hästgången är öppningar, inte väggar.

## Vad som INTE går att kvittera här

- **Orienteringen** är `REFERENCE GAP`. Läktarens absoluta öst/väst är inte
  bevisad; `RIDHUSINNE.sidor` speglar hela interiören om det visar sig fel.
- **Motsägelsen sarg kontra läktarfront** är öppen: `-01`/`-02` visar den
  mörka brädväggen som bangräns, `-03` en vit sarg med sittplatser bakom, på
  samma långsida. Spelet bygger båda.
- Pictogrammen vid C (cykel) och E (elefant) är verifierade men inte byggda —
  de blir några pixlar i den skalan.
