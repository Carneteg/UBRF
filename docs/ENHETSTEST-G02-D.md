# Enhetstest G02-D — protokoll för Studio och fysisk iPad

Skrivet på ChatGPTs oberoende review av `8413baa` (2026-09-09 04:22):
*"Next acceptance work is a real playable build and device test... Record
device, viewport, exact build SHA, pass/fail and reproducible defects."*

Det här är **den grinden**, inte en ny designrunda. Reviewen säger
uttryckligen att nästa steg är ett riktigt spelbart bygge och ett
enhetstest — inte fler spekulativa ombyggnader. Ingenting i den här filen
ändrar kod.

## Innan du börjar

| Fält | Fyll i |
|---|---|
| Build-SHA | `8413baaf47fe67dd7d48e174a7bb5521be1d3252` (eller senare — skriv den du faktiskt testade) |
| Yta | Roblox Studio · Roblox på iPad · webb på iPad · webb på telefon |
| Enhet och OS | t.ex. iPad Air 5, iPadOS 18.2 |
| Viewport / orientering | t.ex. 1180×820 landscape |
| Inmatning | finger · finger + tangentbord · gamepad (modell) |
| Webbpreview | Vercel-länken i #151 |

**Vad som INTE är bevisat headless, och alltså är hela poängen med det
här testet:** Luau-bänken kör ingen fysik. Provet flyttar riggens root
själv där ritten behöver utsträckning. Det säger ingenting om hur hästen
faktiskt rör sig, och ingenting alls om hoppning. Emulerade pekhändelser
är inte ett finger.

## Så här rapporterar du

En rad per steg. Skriv hellre "fungerade men kändes trögt" än att kryssa
i PASS — game feel är din bedömning, inte provets.

```
STEG 4  FEL  iPad Air 5 landscape 1180×820, Roblox Studio, 8413baa
             Höjde gångart med R1 → hästen gick upp TVÅ steg, skritt → galopp.
             Repro: 3 av 5 försök, alltid när jag tryckte snabbt efter en parad.
```

Vid avvikelse: steg-nummer, vad du gjorde, vad som hände i stället, och om
det går att upprepa. Det räcker — jag rotorsakar.

---

## A. Hela första dagen

1. Starta som gäst. **Förväntat:** uppdraget säger i ord vad du ska göra, utan att du behöver gissa en tangent.
2. Gå till ridläraren, prata. **Förväntat:** du får Blackrock Jack.
3. Gå till boxen, hämta utrustning i sadelkammaren, tillbaka till hästen.
4. Sköt om och sadla. **Förväntat:** varje steg har en tydlig nästa handling.
5. Led hästen ut och in i ridhuset, sitt upp vid sargporten.
6. **Förväntat efter uppsittning:** reglagen visas en gång, av sig själv, och går att stänga.

## B. Styrning och gångarter — kärnan i PO-kravet

7. **Neutral uppsittning:** rör ingenting i tio sekunder. **Förväntat:** hästen står stilla. Ingen krypning, ingen drift.
8. **Två tummar på iPad:** vänster tumme på spaken, höger på knapparna. **Förväntat:** du täcker inte hästen, hindret eller nästa mål.
9. **Liten styrning:** för spaken en liten bit. **Förväntat:** en liten korrigering, inte ett ryck.
10. **Fullt utslag:** för spaken helt åt sidan. **Förväntat:** full sväng — hela omfånget finns kvar.
11. **Lyft fingret mitt i en sväng.** **Förväntat:** styrningen nollas. Ingen drift vidare.
12. **Ett steg per begäran:** höj gångart en gång. **Förväntat:** exakt ett steg. Halt → skritt, inte halt → trav.
13. **HÅLL knappen/fingret nere i fem sekunder.** **Förväntat:** fortfarande **ett** steg.
14. Släpp och tryck igen. **Förväntat:** ett nytt steg går igenom.
15. Hela vägen upp och hela vägen ner: halt → skritt → trav → galopp → trav → skritt → halt. **Förväntat:** ett steg per begäran hela vägen.
16. **Bromsa och stanna.** **Förväntat:** förutsägbart, inte tvärnit och inte sladd.

## C. Fokus, avbrott och paneler

17. **Byt app** mitt i skritt (iPad: svep upp), gå tillbaka. **Förväntat:** hästen har inte fortsatt gå. Ingen hjälp ligger kvar.
18. **Rotera skärmen** mitt i en ritt. **Förväntat:** kontrollerna följer med, inget hamnar utanför skärmen eller under systemfältet.
19. **Öppna och stäng ett kort.** **Förväntat:** hästen står stilla medan kortet är uppe, och ett tryck under pausen fyrar inte när du stänger.
20. **Sitt av mitt i en gångartsbegäran** (tryck gångart upp och sitt av direkt). Sitt upp igen. **Förväntat:** hästen byter **inte** gångart av sig själv.
21. **Koppla in en gamepad mitt i en ritt** (om du har en). **Förväntat:** reglagen börjar visa gamepadknappar, inte tangenter.

## D. Hoppning — inte provat headless alls

22. Rid fram mot ett hinder i lämplig gångart. **Förväntat:** du förstår vilket reglage som hoppar, utan att gissa.
23. **Anridningen:** **Förväntat:** hästen möter hindret rimligt, inte i sista stund.
24. **Avsprång och landning:** **Förväntat:** det ser ut och känns som ett hopp, inte som en teleport eller ett studs.
25. Rid medvetet dåligt fram. **Förväntat:** vägran eller rivning — och att det syns varför.
26. **Förväntat genomgående:** säkerheten och hästens välfärd går före poängen.

## E. Ugneta, ridanalys och valen

27. Rid ett moment till slut. **Förväntat:** hästen stannar, kortet visar två punkter och tre val: *Prova igen · Se ritten · Gå vidare*.
28. **Se ritten.** **Förväntat:** din väg ritas. Alla fem kontroller går att träffa med tummen.
29. **Smal skärm / porträtt:** samma panel. **Förväntat:** inga knappar utanför kanten, inget under notch eller hemindikator.
30. Spela, pausa, −5 s, +5 s, 0,5×. **Förväntat:** alla svarar.
31. **Tillbaka.** **Förväntat:** du är åter i valet, inte i ritten.
32. **Prova igen**, rid om, öppna analysen. **Förväntat:** förra försöket ligger bakom som spöke.
33. **Gå vidare** efter försök 1. **Förväntat:** nästa övning — och betyget för den överhoppade räknas **en** gång.
34. Slå på **mindre rörelse** i systeminställningarna, öppna analysen. **Förväntat:** uppspelningen startar inte av sig själv, men allt innehåll finns kvar.

## F. Ut ur lektionen

35. Rid passet till slut. **Förväntat:** eftervården kommer.
36. **Förväntat:** passet sparas och syns i historiken.
37. Starta ett nytt pass. **Förväntat:** det börjar från början, inte mitt i det förra.

## G. Läsbarhet och känsla — din bedömning

38. Går texten att läsa på armlängds avstånd?
39. Är kontrasten tillräcklig i ridhusets ljus?
40. Ligger någon kritisk kontroll under Roblox eget UI eller iPadens systemfält?
41. Tappar det fart någonstans?
42. **Känns det bra att se sin egen ritt?** Den frågan kan bara du svara på.

---

## Vad som händer sedan

Avvikelser går till #151. Jag äger kodrättelserna: rotorsak först, rött
prov innan rättelse, falsifiering efter, och siffror i rapporten — inga
gissningar. Ingen `PRODUCT_ACCEPTED` och ingen merge till main förrän du
och ChatGPT säger det.

**Kända luckor som det här testet kan bekräfta eller avfärda** — de är
inte byggda, och byggs med flit inte på spekulation: Roblox safe
areas/notch och textskalning, samtidig multitouch, hot-plug av
gamepad/tangentbord, och hoppkedjan end-to-end. Visar testet att någon av
dem är ett verkligt problem blir den en beställning med bevis bakom sig.
