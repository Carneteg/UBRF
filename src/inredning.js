/* INREDNING — F02-B: verifierad inredning, utrustning och fasta detaljer
   inne i Stallhuset och Ridhuset. EN sanning för båda ytorna.

   Webben (src/varld3d.js, src/world.js) ritar ur den här listan och Roblox
   (roblox/buildings/Anlaggningen.luau) bygger ur samma lista via
   tools/exportera-geometri.js. Renderingen får skilja sig; VAR något står,
   hur stort det är och VAD det är får inte skilja sig.

   Regeln från ordern: befintlig spelinredning är ALDRIG bevis. Varje post
   här pekar på sin källa och bär en klass:

     VERIFIED   — objektet finns, sett i granskad bild/film
     FOTO       — sett i bild/film som inte granskats av produktägaren
     DERIVED    — läget följer av bilden + planen (t.ex. "under valvfönstret")
     ASSUMPTION — läget inom rummet är valt; att objektet finns är belagt

   Saknas belägg för att ett objekt finns byggs det inte. Rum utan
   belagd inredning lämnas tomma — `REFERENCE GAP` står i
   docs/F02-B-INREDNINGSMATRIS.md, inte som en soffa i spelet.

   Koordinater: husets lokala meter, x från västra väggen, y från södra
   gaveln — samma system som STALLINNE.klubb och RIDHUSINNE.entrehall.
   `pos` är objektets golvmitt, `rikt` är vilket håll framsidan vänder
   (0 = öster, PI/2 = norr, PI = väster, -PI/2 = söder), `matt.b` bredd
   längs fronten, `matt.d` djup, `matt.h` höjd, `z0` underkant över golvet
   (0 om utelämnad). `kolliderar` = spelaren går inte igenom.

   Objekttyperna (`typ`) är ett litet bibliotek som båda byggarna kan:
   soffa, fatolj, bord, stol, ponny, klocka, vaxt, tavlor, whiteboard,
   skap, hylla, kartong, lysror, ventkanal, krokrad, stovelhylla,
   exitskylt, spegel, skapbank, bank, bommar, hinderstod, bokstavsstall,
   tunna, dyna, lada, dorr, ror, brandslackare, vask, krokar, racke —
   okända typer ritas som en låda i färgen på båda ytorna. */

const INREDNING = (() => {
  const S = STALLINNE, R = RIDHUSINNE;
  const rum = (K, id) => K.rum.find(r => r.id === id).rekt;
  const N = Math.PI / 2, W = Math.PI, Sy = -Math.PI / 2, E = 0;

  /* ── STALLHUSET ─────────────────────────────────────────────────── */
  const U = rum(S.klubb, "uppehallsrum");     // x 0–5,9 · y 60,15–69,95
  const T = rum(S.klubb, "teorisal");         // x 11,2–17,3 · y 64,35–69,95
  const SK = rum(S.klubb, "sadelkammare");    // x 7,3–15,5 · y 57,45–64,35
  const genom = S.klubb.vaggar.find(v => v.id === "genomgaende");
  const inreEntre = genom.oppningar.find(o => o.id === "inre_entre");
  const radW = S.rader.find(r => r.id === "W");
  const fxW = radW.x0 + radW.djup;                       // västra boxradens front mot gång A

  const stall = [
    /* UPPEHÅLLSRUMMET — stall-inne-01-uppehallsrummet.jpg (IMG_0134).
       Två svarta skinnsoffor i vinkel kring två låga svarta bord, en rosa
       träponny med riktig sadel, rund väggklocka, krukväxt och inramade
       hästfoton på pärlsponten, allt vid ett valvfönster. Valvfönstren i
       västväggen sitter i fasaden 2,6 och 8,6 m från norra gaveln
       (site.js, `valv`), alltså y 67,35 och 61,35.
       LÄGET (omläst 2026-09-04 efter review 08:50): i bilden ligger
       ordningen längs västväggen klocka · växt · fotovägg · valvfönster
       med ponnyn under fönstret — fönstret HÖGER om fotoväggen, dvs. norr
       om den. Det går bara ihop med det NORRA fönstret (y 67,35): vid det
       södra får soffan inte plats söder om fönstret (rummet börjar 59,95).
       Samma norra fönster är pentryts valvfönster i stall-inne-02
       (valv + runt fönster i NV-hörnet) — pentryhörnan ligger alltså
       omedelbart norr om soffgruppen. Därför DERIVED, inte ASSUMPTION:
       soffan mot västväggen under fotoväggen (y 64,7–66,5), fönstret
       norr om den, ponnyn under fönstret, klockan och växten söder om
       fotoväggen, den andra soffan i vinkel söder om borden (bildens
       förgrund). Pentryts möbler byggs fortsatt inte (ingen order). */
    {id:"uppehall_soffa_v", rum:"uppehallsrum", typ:"soffa", pos:[U.x+0.55, 65.6], rikt:E,
     matt:{b:1.85, d:0.85, h:0.70}, farg:"#1C1C1E", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_soffa_s", rum:"uppehallsrum", typ:"soffa", pos:[2.6, 63.85], rikt:N,
     matt:{b:1.85, d:0.85, h:0.70}, farg:"#1C1C1E", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_bord_1", rum:"uppehallsrum", typ:"bord", pos:[1.65, 65.2], rikt:E,
     matt:{b:0.55, d:0.55, h:0.45}, farg:"#141416", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_bord_2", rum:"uppehallsrum", typ:"bord", pos:[1.65, 65.95], rikt:E,
     matt:{b:0.55, d:0.55, h:0.45}, farg:"#141416", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_ponny", rum:"uppehallsrum", typ:"ponny", pos:[1.1, 67.55], rikt:N,
     matt:{b:0.45, d:1.35, h:1.45}, farg:"#D63A8C", farg2:"#2A2420", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_klocka", rum:"uppehallsrum", typ:"klocka", pos:[U.x+0.02, 63.9], rikt:E,
     matt:{b:0.30, d:0.04, h:0.30}, z0:1.9, farg:"#F4F2EC",
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    {id:"uppehall_vaxt", rum:"uppehallsrum", typ:"vaxt", pos:[U.x+0.38, 64.45], rikt:E,
     matt:{b:0.7, d:0.7, h:1.9}, farg:"#4E7A3A", farg2:"#5B5B8C", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},
    /* Sex inramade hästfoton i svarta ramar i en lös grupp. */
    {id:"uppehall_fotovagg", rum:"uppehallsrum", typ:"tavlor", pos:[U.x+0.02, 65.75], rikt:E,
     matt:{b:2.2, d:0.03, h:1.0}, z0:1.35, antal:6, farg:"#1E1E1E", farg2:"#8A9A7A",
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"DERIVED"},

    /* TEORISALEN — stall-inne-04-teorisalen.jpg (IMG_0138). Kameran står
       med valvfönstren till vänster och whiteboardväggen rakt fram. Rummets
       enda yttervägg i planen är norra gaveln (y 69,95) — fönstren sitter
       där, alltså tittar kameran österut: whiteboarden på ÖSTVÄGGEN
       (x 17,3), anatomiplanscherna på SYDVÄGGEN, skåpet med mikron i
       sydöstra hörnet, kartongerna längs sydväggen. DERIVED ur foto + plan.
       Bordsblocket står längs fönstersidan, stolarna runt det. */
    /* Innerväggarna är 0,16 m tjocka kring sin linje (v3dVaggarOchRum), så
       väggfasta ting måste stå 0,10 från linjen — 0,03 hamnade INNE i
       väggen och syntes inte (checkpoint A, 7a5c60d). Fasadens innersida
       ligger däremot 0,025 innanför sin linje (fotoväggen på x 0,02). */
    {id:"teori_whiteboard_1", rum:"teorisal", typ:"whiteboard", pos:[T.x+T.w-0.10, 68.55], rikt:W,
     matt:{b:1.5, d:0.03, h:1.0}, z0:0.95, farg:"#F7F7F5",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_whiteboard_2", rum:"teorisal", typ:"whiteboard", pos:[T.x+T.w-0.10, 66.95], rikt:W,
     matt:{b:1.5, d:0.03, h:1.0}, z0:0.95, farg:"#F7F7F5",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_bord_1", rum:"teorisal", typ:"bord", pos:[13.2, 68.4], rikt:N,
     matt:{b:2.4, d:0.8, h:0.73}, farg:"#C8A878", kolliderar:true,
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_bord_2", rum:"teorisal", typ:"bord", pos:[13.2, 67.6], rikt:N,
     matt:{b:2.4, d:0.8, h:0.73}, farg:"#C8A878", kolliderar:true,
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_bord_3", rum:"teorisal", typ:"bord", pos:[15.6, 68.4], rikt:N,
     matt:{b:2.4, d:0.8, h:0.73}, farg:"#C8A878", kolliderar:true,
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    ...[[12.3,66.9],[13.3,66.9],[14.3,66.9],[15.3,66.9],[16.3,66.9],
        [12.3,69.2],[13.3,69.2],[14.3,69.2],[15.3,69.2],[16.3,69.2]].map((p,i)=>(
      {id:"teori_stol_"+(i+1), rum:"teorisal", typ:"stol", pos:p, rikt:i<5?N:Sy,
       matt:{b:0.45, d:0.45, h:0.85}, farg:"#EDEAE2", farg2:"#B8925C", kolliderar:true,
       kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"})),
    {id:"teori_skap_mikro", rum:"teorisal", typ:"skap", pos:[T.x+T.w-0.45, T.y+0.5], rikt:W,
     matt:{b:0.8, d:0.45, h:1.0}, farg:"#B8925C", mikro:true, kolliderar:true,
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_plansch_1", rum:"teorisal", typ:"tavlor", pos:[15.9, T.y+0.10], rikt:N,
     matt:{b:1.0, d:0.03, h:0.75}, z0:1.25, antal:1, farg:"#B8925C", farg2:"#E8DDD0",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_plansch_2", rum:"teorisal", typ:"tavlor", pos:[14.6, T.y+0.10], rikt:N,
     matt:{b:1.0, d:0.03, h:0.75}, z0:1.25, antal:1, farg:"#B8925C", farg2:"#E8DDD0",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    ...[15.3,14.6,13.9].map((x,i)=>(
      {id:"teori_kartong_"+(i+1), rum:"teorisal", typ:"kartong", pos:[x, T.y+0.3], rikt:N,
       matt:{b:0.55, d:0.45, h:0.45}, farg:"#B89A72", kolliderar:true,
       kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"})),
    /* Två långa lysrörsarmaturer i taket och en perforerad spiralkanal
       längs taket — det som gör rummet läsbart uppåt. */
    {id:"teori_lysror_1", rum:"teorisal", typ:"lysror", pos:[13.6, 67.2], rikt:N,
     matt:{b:1.5, d:0.2, h:0.08}, z0:2.75, farg:"#F6F2E4",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_lysror_2", rum:"teorisal", typ:"lysror", pos:[15.9, 67.2], rikt:N,
     matt:{b:1.5, d:0.2, h:0.08}, z0:2.75, farg:"#F6F2E4",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_ventkanal", rum:"teorisal", typ:"ventkanal", pos:[14.25, 69.2], rikt:N,
     matt:{b:5.6, d:0.3, h:0.3}, z0:2.6, farg:"#B9BDC0",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},

    /* SADELKAMMAREN — stall-inne-03-sadelkammaren.jpg (IMG_0137). Bilden
       visar INTE sadelbockar: den visar säkerhetsvästar på krokrader
       längs vänstra väggen, en vit öppen hylla full av ridstövlar till
       höger, och rakt fram en grå ståldörr med fönster och skylten
       "Teorisal". Man går in från gång A genom dörren i brandväggen
       (x 7,7–8,8) och har då västväggen (x 7,3) till vänster. Västarna
       läggs på den, stövelhyllan fristående mitt emot så att bildens
       smala passage uppstår. Dörren till teorisalen finns INTE i F02-A:s
       topologi (teorisal_s saknar öppning) — det rapporteras separat och
       byggs inte här. */
    {id:"sadel_vastkrokar", rum:"sadelkammare", typ:"krokrad", pos:[SK.x+0.02, 62.2], rikt:E,
     matt:{b:3.4, d:0.40, h:1.05}, z0:1.05, antal:10, farg:"#9A9B93", farg2:"#232A3A",
     kalla:"stall-inne-03", klass:"VERIFIED", lage:"DERIVED"},
    {id:"sadel_stovelhylla", rum:"sadelkammare", typ:"stovelhylla", pos:[10.3, 62.2], rikt:W,
     matt:{b:3.4, d:0.42, h:2.15}, farg:"#F2F1EC", farg2:"#1E1E1E", kolliderar:true,
     kalla:"stall-inne-03", klass:"VERIFIED", lage:"DERIVED"},
    /* Den grå ståldörren med fönster och skylten "Teorisal" rakt fram
       (stall-inne-03). F02-A:s `teorisal_s` har ingen öppning (rapporterat,
       topologin låst) — dörren ritas därför som ett stängt dörrblad med
       karm och fönster PÅ väggens sydsida, inte som passage. Läget längs
       väggen: mellan västarna och stövelhyllan [antagande]. */
    {id:"sadel_dorr_teori", rum:"sadelkammare", typ:"dorr", pos:[8.8, SK.y+SK.h-0.06], rikt:Sy,
     matt:{b:1.0, d:0.08, h:2.1}, farg:"#8C8F92", farg2:"#BFD3DC",
     kalla:"stall-inne-03", klass:"VERIFIED", lage:"DERIVED"},

    /* GÅNG A:s NORRA ÄNDE — filmerna IMG_0249/0250 (stall-gang-*): grå
       metallport i vit vägg med rund klocka ovanför och grön
       utrymningsskylt bredvid. Klockan byggs redan (STALLINNE.klocka);
       skylten saknades. Den sätts vid brandväggens dörr mot klubbdelen. */
    {id:"gangA_exitskylt", rum:"gangA", typ:"exitskylt", pos:[inreEntre.x1+0.45, genom.y-0.09], rikt:Sy,
     matt:{b:0.32, d:0.03, h:0.16}, z0:2.15, farg:"#1E9A4A",
     kalla:"stall-gang-05, KORT.md § Gångens ändar", klass:"VERIFIED", lage:"DERIVED"},

    /* ZONEN EFTER PAUSRUMMET — Product Owner 2026-09-04 15:15, referens
       `references/spatial/stall-efter-pausrum-po-v1.md` (PO-godkänd
       sammanfogning av Tobias nya foton 2026-09-04; fotona själva är
       [DRIVE-ONLY]). Bindande flöde: PAUSRUM → ÖPPEN SERVICE-/TVÄTTZON →
       STALLGÅNG → BOXFRONTER. Zonen är tvärkorridoren y 52,85–57,45 mellan
       brandväggen vid klubbY och den genomgående väggen: ett ÖPPET rum,
       inga nya väggar, inga rumslådor. Allt står så att inre entrén
       (x 4,1–5,0) → gång A och sadelkammarens dörr är fria.
       Att tingen finns: VERIFIED (PO-referensen). Mått och lägen:
       ASSUMPTION — referensen är omåttsatt (`REFERENCE GAP`).
       (`rikt` är fronten; `b` löper tvärs fronten — väggfasta ting på
       den genomgående väggen har rikt Sy, ting på västra boxradens front
       rikt E.) */
    // Vit servicevägg = den genomgående väggens sydsida (y 57,45).
    {id:"zon_ror", rum:"gangA", typ:"ror", pos:[9.15, genom.y-0.12], rikt:Sy,
     matt:{b:7.9, d:0.08, h:0.08}, z0:2.35, farg:"#9EA3A7",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster / vit servicevägg", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_ror_ned", rum:"gangA", typ:"ror", pos:[11.6, genom.y-0.12], rikt:Sy, lodrat:true,
     matt:{b:0.08, d:0.08, h:2.35}, farg:"#9EA3A7",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster / vit servicevägg", klass:"VERIFIED", lage:"ASSUMPTION"},
    /* Den grå service-/teknikdörren är inre entrén (planens öppning, redan
       passage med karm): dörrbladet ritas uppställt mot väggen väster om
       öppningen, kodlåset/knappsatsen på karmens östra sida. */
    {id:"zon_dorrblad_entre", rum:"gangA", typ:"dorr", pos:[inreEntre.x0-0.06, genom.y-0.55], rikt:W,
     matt:{b:0.9, d:0.05, h:2.1}, farg:"#8C8F92", farg2:"#BFD3DC",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (grå dörr, metallhandtag); stall-gang-05", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_knappsats", rum:"gangA", typ:"knappsats", pos:[inreEntre.x1+0.22, genom.y-0.09], rikt:Sy,
     matt:{b:0.10, d:0.04, h:0.16}, z0:1.2, farg:"#6E7275",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (kodlås/knappsats)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_klocka", rum:"gangA", typ:"klocka", pos:[(inreEntre.x0+inreEntre.x1)/2, genom.y-0.09], rikt:Sy,
     matt:{b:0.5, d:0.05, h:0.5}, z0:2.32, farg:"#EEECE4",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (väggklocka vid dörrzonen); KORT.md § Gångens ändar", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_brandslackare", rum:"gangA", typ:"brandslackare", pos:[inreEntre.x0-0.7, genom.y-0.14], rikt:Sy,
     matt:{b:0.18, d:0.18, h:0.55}, z0:0.85, farg:"#C8281E",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (säkerhetsutrustning rött)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_forsta_hjalpen", rum:"gangA", typ:"skylt", pos:[inreEntre.x0-0.7, genom.y-0.09], rikt:Sy,
     matt:{b:0.30, d:0.06, h:0.30}, z0:1.6, farg:"#2E8B57",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (säkerhetsutrustning grönt)", klass:"VERIFIED", lage:"ASSUMPTION"},
    // Tvättplatsen öster om sadelkammarens dörr (x 7,7–8,8).
    {id:"zon_vask", rum:"gangA", typ:"vask", pos:[10.6, genom.y-0.38], rikt:Sy,
     matt:{b:1.1, d:0.6, h:0.9}, farg:"#8E9296", farg2:"#C9CDD0", kolliderar:true,
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (rostfri skölj-/tvättstation)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_korg", rum:"gangA", typ:"korg", pos:[10.6, genom.y-0.20], rikt:Sy,
     matt:{b:0.8, d:0.28, h:0.25}, z0:1.45, farg:"#B9BDC0",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (väggmonterad hylla/korg)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_krokar", rum:"gangA", typ:"krokar", pos:[12.3, genom.y-0.10], rikt:Sy,
     matt:{b:0.8, d:0.12, h:0.55}, z0:1.3, farg:"#8E9296", farg2:"#2F5D8A",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Vänster (krokar/handdukar)", klass:"VERIFIED", lage:"ASSUMPTION"},
    // Mittzonen: låg avskärmning och arbetshyllan — mellan gång A och gång B.
    {id:"zon_racke", rum:"gangA", typ:"racke", pos:[12.6, S.klubbY+2.3], rikt:N,
     matt:{b:2.6, d:0.06, h:1.0}, farg:"#3A3D40", farg2:"#A8ADB0", kolliderar:true,
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (låg mörkgrå metallavskärmning)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_hylla", rum:"gangA", typ:"hylla", pos:[9.4, S.klubbY+2.1], rikt:Sy,
     matt:{b:1.2, d:0.5, h:1.25}, farg:"#3A3D40", kolliderar:true,
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (arbets-/förvaringshylla)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_back_1", rum:"gangA", typ:"kartong", pos:[9.1, S.klubbY+2.1], rikt:Sy,
     matt:{b:0.4, d:0.3, h:0.28}, z0:1.25, farg:"#2E5FA8",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (plastbackar)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_back_2", rum:"gangA", typ:"kartong", pos:[9.68, S.klubbY+2.1], rikt:Sy,
     matt:{b:0.4, d:0.3, h:0.28}, z0:1.25, farg:"#9EA3A7",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (plastbackar, flaskor)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_bin", rum:"gangA", typ:"tunna", pos:[10.55, S.klubbY+2.05], rikt:E,
     matt:{b:0.6, d:0.6, h:0.95}, farg:"#2E5FA8", farg2:"#1E3F78", kolliderar:true,
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (stor blå säck/bin)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"zon_pall", rum:"gangA", typ:"pall", pos:[8.2, S.klubbY+1.55], rikt:E,
     matt:{b:0.5, d:0.4, h:0.35}, farg:"#2A2C2E", kolliderar:true,
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (låg rull-/trappall)", klass:"VERIFIED", lage:"ASSUMPTION"},
    // Boxfronterna i gång A närmast zonen: anslagstavlor och brandsläckare.
    {id:"boxfront_tavla_1", rum:"gangA", typ:"whiteboard", pos:[fxW+0.03, S.klubbY-1.4], rikt:E,
     matt:{b:0.6, d:0.03, h:0.45}, z0:0.75, farg:"#FFFFFF",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (vita anslagstavlor)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"boxfront_tavla_2", rum:"gangA", typ:"whiteboard", pos:[fxW+0.03, S.klubbY-4.2], rikt:E,
     matt:{b:0.6, d:0.03, h:0.45}, z0:0.75, farg:"#FFFFFF",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (vita anslagstavlor)", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"boxfront_brandslackare", rum:"gangA", typ:"brandslackare", pos:[fxW+0.12, S.klubbY-2.8], rikt:E,
     matt:{b:0.18, d:0.18, h:0.55}, z0:0.5, farg:"#C8281E",
     kalla:"references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (brandsläckare mellan tavlorna)", klass:"VERIFIED", lage:"ASSUMPTION"},
  ];

  /* ── RIDHUSET ───────────────────────────────────────────────────── */
  const ba = R.bana, L = R.laktare, Lk = R.kortanda;
  const lE = R.sidor && R.sidor.laktare === "E";
  const dackMitt = L.x0 + L.dackDjup / 2;
  const panelX = lE ? ba.x : ba.x + ba.w;               // långsidan mitt emot läktaren
  const Bok = DRESSYRBOKSTAVER.find(b => b.b === "B");
  const Hok = DRESSYRBOKSTAVER.find(b => b.b === "H");
  const sydDorr = (R.dorrar || []).find(d => d.id === "ut_ridhus_S_8");
  const sydDorrX = sydDorr ? sydDorr.pos[0] : R.bredd / 2;
  const H = rum(R.entrehall, "hall");                 // hela entrédelen, x 0–25 · y 65,68–77,18
  const hus = ANL.byggnader.find(b => b.id === "ridhus");
  /* Det låga valvfönstret mot parkeringen (IMG_0268-r03, ridhus-klubb-14,
     -01 förgrunden): fasadens `valv` på norra gaveln med z0 1,35, det västra
     av de två (u räknas från östra hörnet). Bänken står under det. */
  const valvN = (hus.oppningar || []).filter(o => o.sida === "N" && o.typ === "valv" && o.z0 < 2)
    .map(o => ({ x: R.bredd - o.u - o.b / 2, b: o.b })).sort((a, b) => b.x - a.x)[0] || { x: 4.375, b: 1.05 };

  /* SKÅPEN — Spatial Canon v2 (F02-A, accepterad 2026-09-04): korridorväggarna
     `skap_v`/`skap_o` är ÅTERKALLADE; entrédelen är en OPEN_AREA och skåpen
     är fristående möbler i den (docs/F02-RIDHUS-ENTRE-AUDIT.md § 3). Läsning
     av `ridhus-klubb-01`/`-15`: man går längs en gång med receptionens
     bröstning + glas på ena sidan och skåpraden mitt emot, mot valvfönstret
     med stövelbänken i gångens ände. F02-A:s glas står på x 2,2 (planens
     linje) och planens skåpremsa på x 4,2–5,7 — skåpbankarna ställs alltså
     i remsan med FRONTEN mot glaset (väster), gången emellan. Var raden
     börjar och slutar visar ingen bild (planens "fyra luckor" är olästa) —
     ASSUMPTION; rutten entré → bana går norr om raden. Ingen bank står där väggen stod som en ersättningsvägg: de är
     0,5 m djupa möbler i öppen yta, inte en linje från gavel till gavel. */
  /* En LÅNG rad (review 2026-09-04 08:50: bildens identitet är den långa
     skåpraden) från receptionens sydvägglinje till gavelns valvfönster —
     rutten entré → bana går norr om raden (y ≈ 75,7). */
  const skapBitar = [[68.3, 75.0]];
  const skapX = 4.2 + 0.25;                              // fronten i remsans västkant

  const ridhus = [
    /* SPEGLARNA. Vid B: EN spegel delad i två rutor i brun träram, monterad
       direkt ovanpå sargen (ridhus-inne-34, -19, -31, IMG_0189-f05) —
       VERIFIED. Vid A: TVÅ speglar i träram på den vita kortsidan, en på
       var sida om dubbeldörren (ridhus-inne-23) — VERIFIED, lägena DERIVED
       ur bilden (ungefär en fjärdedel in från vardera hörnet). */
    {id:"spegel_B", rum:"bana", typ:"spegel", pos:[panelX + (lE ? -0.06 : 0.06), R.dressyr.y + Bok.y], rikt:lE ? E : W,
     matt:{b:3.2, d:0.06, h:1.6}, z0:R.sargH, antal:2, farg:"#7A5A3A",
     kalla:"ridhus-inne-34, -19, -31, IMG_0189-f05", klass:"VERIFIED", lage:"VERIFIED"},
    {id:"spegel_A_v", rum:"sydzon", typ:"spegel", pos:[sydDorrX - 5.2, 0.06], rikt:N,
     matt:{b:1.5, d:0.06, h:1.5}, z0:R.sargH, antal:1, farg:"#8A6A44",
     kalla:"ridhus-inne-23", klass:"VERIFIED", lage:"DERIVED"},
    {id:"spegel_A_o", rum:"sydzon", typ:"spegel", pos:[sydDorrX + 5.2, 0.06], rikt:N,
     matt:{b:1.5, d:0.06, h:1.5}, z0:R.sargH, antal:1, farg:"#8A6A44",
     kalla:"ridhus-inne-23", klass:"VERIFIED", lage:"DERIVED"},

    /* HINDERUPPLAGET på läktardäckets södra ände: bommar i regnbågsfärger
       lutade mot väggen, vita hinderstöd, och det lösa bokstavsstället
       med F R H V C K M A (ridhus-inne-21, -23 högerkant, granskning A
       § "hinderupplag i hörn"). Ytan är läktardäcket bakom sargen. */
    {id:"laktare_bommar", rum:"laktare", typ:"bommar", pos:[dackMitt, ba.y + 2.6], rikt:N,
     matt:{b:2.4, d:0.5, h:1.9}, z0:L.dackZ, antal:7,
     fargor:["#3A6EA5","#C0392B","#E8E4DA","#C9A23C","#4B8A3E"],
     kalla:"ridhus-inne-21, -23", klass:"VERIFIED", lage:"DERIVED"},
    {id:"laktare_hinderstod", rum:"laktare", typ:"hinderstod", pos:[dackMitt, ba.y + 5.2], rikt:N,
     matt:{b:1.8, d:0.6, h:1.5}, z0:L.dackZ, antal:3, farg:"#F0EDE6",
     kalla:"ridhus-inne-21", klass:"VERIFIED", lage:"DERIVED"},
    {id:"laktare_bokstavsstall", rum:"laktare", typ:"bokstavsstall", pos:[dackMitt, ba.y + 7.6], rikt:N,
     matt:{b:2.4, d:0.35, h:0.45}, z0:L.dackZ, antal:8, farg:"#F4F4F0",
     bokstaver:"FRHVCKMA",
     kalla:"ridhus-inne-21", klass:"VERIFIED", lage:"DERIVED"},

    /* Returtunnan för burkar på läktaren vid H (ridhus-inne-43) och de två
       orange plastskalstolarna bakom domarboden (ridhus-inne-40). De tre
       orange stolarna som stod utspridda på däcket utan källa är borta;
       de här står där bilderna sätter dem. */
    {id:"laktare_returtunna", rum:"laktare", typ:"tunna", pos:[dackMitt, R.dressyr.y + Hok.y + 1.6], rikt:E,
     matt:{b:0.5, d:0.5, h:1.1}, z0:L.dackZ, farg:"#8E9196", farg2:"#C0392B",
     kalla:"ridhus-inne-43", klass:"FOTO", lage:"DERIVED"},
    {id:"laktare_stol_1", rum:"laktare", typ:"stol", pos:[dackMitt, R.domarbas.y + 2.2], rikt:lE ? W : E,
     matt:{b:0.45, d:0.45, h:0.8}, z0:L.dackZ, farg:"#D4551E", farg2:"#8C8F92",
     kalla:"ridhus-inne-40", klass:"FOTO", lage:"DERIVED"},
    {id:"laktare_stol_2", rum:"laktare", typ:"stol", pos:[dackMitt, R.domarbas.y + 2.9], rikt:lE ? W : E,
     matt:{b:0.45, d:0.45, h:0.8}, z0:L.dackZ, farg:"#D4551E", farg2:"#8C8F92",
     kalla:"ridhus-inne-40", klass:"FOTO", lage:"DERIVED"},

    /* SKÅPKORRIDOREN — ridhus-klubb-01 (nyckelbild), -15, IMG_0169-f02/f03,
       IMG_0268-r12/r15. Höga smala plåtskåp i grått med enstaka röda och
       mörkgrå dörrar i en rad; vita trästolar med rött mönstrat tyg kring
       ett litet bord mitt i gången; en bänk med ridstövlar under
       valvfönstret i gångens ände. Att raden, gruppen och bänken FINNS är
       VERIFIED; lägena är ASSUMPTION i den öppna ytan (se skapBitar). */
    ...skapBitar.map(([y0, y1], i) => (
      {id:"skap_v_"+(i+1), rum:"hall", typ:"skapbank", pos:[skapX, (y0+y1)/2], rikt:W,
       matt:{b:y1-y0-0.1, d:0.5, h:1.9}, farg:"#C9CBCB", fargor:["#C9CBCB","#C9CBCB","#3A3C40","#C9CBCB","#B8322E"],
       kolliderar:true,
       kalla:"ridhus-klubb-01, -15, IMG_0169-f02, IMG_0268-r12", klass:"VERIFIED", lage:"ASSUMPTION"})),
    /* SKÅPFÖRVARINGEN — Product Owner 2026-09-04 11:56: "Saknas skåp."
       ridhus-klubb-16 (skåprummet med pelaren: höga mörkblå/grå skåp till
       vänster, tio halvhöga vita skåp i två våningar till höger), -18
       (närbild: tre grå + tre svarta luckor i vita profilramar), -20/-21
       (fyra gröna dubbelluckor i vita ramar på svarta ben, gul skogräns på
       golvet). Att skåpen FINNS: VERIFIED. Rummen de står i (Bild 2–5) är
       inte placerade — REFERENCE GAP kvarstår — så grupperna står som
       fristående förvaring i entrédelens ÖPPNA västra remsa (x 0–2,2 söder
       om receptionen), där planens cellrad bär funktionerna skåpförvaring/
       ombyte [antagande]: inga nya rum, inga väggar, gången x 2,2–4,2 och
       entréns vindfång fria. Lägena: ASSUMPTION. Antalet luckor förenklat
       (vita banken 3 × 2 mot bildens 5 × 2). */
    {id:"skap_grona", rum:"hall", typ:"skapbank", pos:[0.55, 69.3], rikt:E,
     matt:{b:1.6, d:0.5, h:1.8}, ben:0.15, vaningar:2, farg:"#EDEAE0", fargor:["#7FA07E"],
     kolliderar:true,
     kalla:"ridhus-klubb-20, -21", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_hoga_v", rum:"hall", typ:"skapbank", pos:[0.55, 71.5], rikt:E,
     matt:{b:2.0, d:0.5, h:1.9}, farg:"#EDEAE0", fargor:["#C9CBCB","#C9CBCB","#C9CBCB","#1F2430","#1F2430"],
     kolliderar:true,
     kalla:"ridhus-klubb-16, -18", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_vita_2v", rum:"hall", typ:"skapbank", pos:[1.45, 72.35], rikt:Sy,
     matt:{b:1.2, d:0.45, h:1.8}, vaningar:2, farg:"#F2F0EA", fargor:["#E9E5D8"],
     kolliderar:true,
     kalla:"ridhus-klubb-16", klass:"VERIFIED", lage:"ASSUMPTION"},
    /* Bordet med de två stolarna står i gången mellan glaset och skåpen
       (-01, -15); ungefär mitt för receptionsglaset. Planens etikett
       RECEPTION på samma remsa är passiv (F02-A); vilken sida av glaset som
       är receptionens insida är F02-A:s GEOMETRY_REFERENCE_GAP. */
    {id:"skap_bord", rum:"hall", typ:"bord", pos:[3.4, 74.7], rikt:E,
     matt:{b:0.6, d:0.6, h:0.72}, farg:"#F2EFE8", kolliderar:true,
     kalla:"ridhus-klubb-01, -15, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_stol_1", rum:"hall", typ:"stol", pos:[3.4, 75.4], rikt:Sy,
     matt:{b:0.5, d:0.5, h:0.95}, farg:"#F2EFE8", farg2:"#B8322E", kolliderar:true,
     kalla:"ridhus-klubb-01, -15, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_stol_2", rum:"hall", typ:"stol", pos:[3.4, 74.0], rikt:N,
     matt:{b:0.5, d:0.5, h:0.95}, farg:"#F2EFE8", farg2:"#B8322E", kolliderar:true,
     kalla:"ridhus-klubb-01, -15, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    /* RECEPTIONEN — Product Owner 2026-09-04 07:54 placerade rummet i
       nordvästra hörnet (site.js `reception_*`). Genom glaset i
       ridhus-klubb-02: låga träskåp/hyllor längs bakväggen, inramade
       tavlor ovanför, en vit stol med rött tyg innanför disken. Att de
       finns: VERIFIED; lägena i rummet: DERIVED (mot bakväggen). Rummet är
       personalens — spelaren ser det genom glaset. */
    {id:"reception_skap", rum:"reception", typ:"skap", pos:[0.33, 75.3], rikt:E,
     matt:{b:2.4, d:0.55, h:1.15}, farg:"#C9A87C", kolliderar:true,
     kalla:"ridhus-klubb-02", klass:"VERIFIED", lage:"DERIVED"},
    {id:"reception_tavlor", rum:"reception", typ:"tavlor", pos:[0.03, 75.3], rikt:E,
     matt:{b:1.6, d:0.03, h:0.5}, z0:1.5, antal:3, farg:"#2A2622", farg2:"#8C8A7A",
     kalla:"ridhus-klubb-02", klass:"VERIFIED", lage:"DERIVED"},
    {id:"reception_stol", rum:"reception", typ:"stol", pos:[1.3, 74.3], rikt:E,
     matt:{b:0.5, d:0.5, h:0.95}, farg:"#F2EFE8", farg2:"#B8322E", kolliderar:true,
     kalla:"ridhus-klubb-02", klass:"VERIFIED", lage:"DERIVED"},
    /* STÖVELBÄNKEN under valvfönstret mot parkeringen: ridhus-klubb-14 och
       IMG_0268-r03/-r05 visar SAMMA bänk (jackor, hjälmväska, stövlar) som
       -01 har i förgrunden — det är en bänk under ett fönster, inte två.
       Fönstret är fasadens låga valvfönster på norra gaveln (x ≈ 4,4);
       bänken står under det, mot gaveln. Den tidigare `entre_bank` "under
       entréfönstret" i västväggen är borttagen: den låsta fasaden har inget
       fönster vid entrédörren (u 9, b 2 fyller entréns hela bredd). */
    {id:"skap_stovelbank", rum:"hall", typ:"bank", pos:[valvN.x, H.y+H.h-0.32], rikt:Sy,
     matt:{b:1.2, d:0.4, h:0.45}, farg:"#C9A87C", farg2:"#1E1E1E", kolliderar:true,
     kalla:"ridhus-klubb-01, ridhus-klubb-14, IMG_0268-r03, -r05", klass:"VERIFIED", lage:"DERIVED"},
  ];

  return { stall, ridhus };
})();

/* Hjälpare som båda webbritarna använder. */
function inredningFor(scen) {
  return scen === "stallinne" ? INREDNING.stall : scen === "ridhusinne" ? INREDNING.ridhus : [];
}
/* Objektets fotavtryck som axelparallell rektangel — för kollision och 2D. */
function inredningRekt(o) {
  const q = Math.abs(Math.cos(o.rikt)) < 0.5;          // vänd norr/söder → b längs x
  const w = q ? o.matt.b : o.matt.d, h = q ? o.matt.d : o.matt.b;
  return { x: o.pos[0] - w / 2, y: o.pos[1] - h / 2, w, h };
}
