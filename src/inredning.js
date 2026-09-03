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
   tunna, dyna, lada. */

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

  const stall = [
    /* UPPEHÅLLSRUMMET — stall-inne-01-uppehallsrummet.jpg (IMG_0134).
       Två svarta skinnsoffor i vinkel kring två låga svarta bord, en rosa
       träponny med riktig sadel, rund väggklocka, krukväxt och inramade
       hästfoton på pärlsponten, allt vid ett valvfönster. Valvfönstren i
       västväggen sitter i fasaden 2,6 och 8,6 m från norra gaveln
       (site.js, `valv`), alltså y 67,35 och 61,35 — soffgruppen läggs vid
       det södra. Att möblerna FINNS är VERIFIED; var i rummet de står är
       ASSUMPTION inom rummet, förankrat i fönstret. */
    {id:"uppehall_soffa_v", rum:"uppehallsrum", typ:"soffa", pos:[U.x+0.55, 61.9], rikt:E,
     matt:{b:1.85, d:0.85, h:0.70}, farg:"#1C1C1E", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_soffa_s", rum:"uppehallsrum", typ:"soffa", pos:[2.6, 64.95], rikt:N,
     matt:{b:1.85, d:0.85, h:0.70}, farg:"#1C1C1E", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_bord_1", rum:"uppehallsrum", typ:"bord", pos:[1.65, 61.75], rikt:E,
     matt:{b:0.55, d:0.55, h:0.45}, farg:"#141416", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_bord_2", rum:"uppehallsrum", typ:"bord", pos:[1.65, 62.5], rikt:E,
     matt:{b:0.55, d:0.55, h:0.45}, farg:"#141416", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_ponny", rum:"uppehallsrum", typ:"ponny", pos:[1.0, 65.8], rikt:N,
     matt:{b:0.45, d:1.35, h:1.45}, farg:"#D63A8C", farg2:"#2A2420", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_klocka", rum:"uppehallsrum", typ:"klocka", pos:[U.x+0.02, 60.9], rikt:E,
     matt:{b:0.30, d:0.04, h:0.30}, z0:1.9, farg:"#F4F2EC",
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"uppehall_vaxt", rum:"uppehallsrum", typ:"vaxt", pos:[U.x+0.35, 63.9], rikt:E,
     matt:{b:0.7, d:0.7, h:1.9}, farg:"#4E7A3A", farg2:"#5B5B8C", kolliderar:true,
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},
    /* Sex inramade hästfoton i svarta ramar i en lös grupp. */
    {id:"uppehall_fotovagg", rum:"uppehallsrum", typ:"tavlor", pos:[U.x+0.02, 63.0], rikt:E,
     matt:{b:2.2, d:0.03, h:1.0}, z0:1.35, antal:6, farg:"#1E1E1E", farg2:"#8A9A7A",
     kalla:"stall-inne-01", klass:"VERIFIED", lage:"ASSUMPTION"},

    /* TEORISALEN — stall-inne-04-teorisalen.jpg (IMG_0138). Kameran står
       med valvfönstren till vänster och whiteboardväggen rakt fram. Rummets
       enda yttervägg i planen är norra gaveln (y 69,95) — fönstren sitter
       där, alltså tittar kameran österut: whiteboarden på ÖSTVÄGGEN
       (x 17,3), anatomiplanscherna på SYDVÄGGEN, skåpet med mikron i
       sydöstra hörnet, kartongerna längs sydväggen. DERIVED ur foto + plan.
       Bordsblocket står längs fönstersidan, stolarna runt det. */
    {id:"teori_whiteboard_1", rum:"teorisal", typ:"whiteboard", pos:[T.x+T.w-0.03, 68.55], rikt:W,
     matt:{b:1.5, d:0.03, h:1.0}, z0:0.95, farg:"#F7F7F5",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_whiteboard_2", rum:"teorisal", typ:"whiteboard", pos:[T.x+T.w-0.03, 66.95], rikt:W,
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
    {id:"teori_plansch_1", rum:"teorisal", typ:"tavlor", pos:[15.9, T.y+0.02], rikt:N,
     matt:{b:1.0, d:0.03, h:0.75}, z0:1.25, antal:1, farg:"#B8925C", farg2:"#E8DDD0",
     kalla:"stall-inne-04", klass:"VERIFIED", lage:"DERIVED"},
    {id:"teori_plansch_2", rum:"teorisal", typ:"tavlor", pos:[14.6, T.y+0.02], rikt:N,
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
    {id:"sadel_vastkrokar", rum:"sadelkammare", typ:"krokrad", pos:[SK.x+0.02, 62.4], rikt:E,
     matt:{b:2.6, d:0.35, h:0.9}, z0:1.15, antal:7, farg:"#9A9B93", farg2:"#232A3A",
     kalla:"stall-inne-03", klass:"VERIFIED", lage:"DERIVED"},
    {id:"sadel_stovelhylla", rum:"sadelkammare", typ:"stovelhylla", pos:[9.85, 62.4], rikt:W,
     matt:{b:2.6, d:0.4, h:2.2}, farg:"#F2F1EC", farg2:"#1E1E1E", kolliderar:true,
     kalla:"stall-inne-03", klass:"VERIFIED", lage:"DERIVED"},

    /* GÅNG A:s NORRA ÄNDE — filmerna IMG_0249/0250 (stall-gang-*): grå
       metallport i vit vägg med rund klocka ovanför och grön
       utrymningsskylt bredvid. Klockan byggs redan (STALLINNE.klocka);
       skylten saknades. Den sätts vid brandväggens dörr mot klubbdelen. */
    {id:"gangA_exitskylt", rum:"gangA", typ:"exitskylt", pos:[inreEntre.x1+0.45, genom.y-0.09], rikt:Sy,
     matt:{b:0.32, d:0.03, h:0.16}, z0:2.15, farg:"#1E9A4A",
     kalla:"stall-gang-05, KORT.md § Gångens ändar", klass:"VERIFIED", lage:"DERIVED"},
  ];

  /* ── RIDHUSET ───────────────────────────────────────────────────── */
  const ba = R.bana, L = R.laktare, Lk = R.kortanda;
  const lE = R.sidor && R.sidor.laktare === "E";
  const dackMitt = L.x0 + L.dackDjup / 2;
  const panelX = lE ? ba.x : ba.x + ba.w;               // långsidan mitt emot läktaren
  const Bok = DRESSYRBOKSTAVER.find(b => b.b === "B");
  const Hok = DRESSYRBOKSTAVER.find(b => b.b === "H");
  const SKP = rum(R.entrehall, "skapkorridor");         // x 4,2–5,7 · y 61,2–76,1
  const ENT = rum(R.entrehall, "entre");
  const skapV = R.entrehall.vaggar.find(v => v.id === "skap_v");
  const sydDorr = (R.dorrar || []).find(d => d.id === "ut_ridhus_S_8");
  const sydDorrX = sydDorr ? sydDorr.pos[0] : R.bredd / 2;

  /* Skåpen i skåpkorridoren fyller västväggens SLUTNA bitar mellan planens
     öppningar (ridhus-klubb-01: skåpraden till vänster på väg mot valv-
     fönstret, alltså på västsidan). Bitarna räknas ur samma vägglista som
     kollisionen — flyttas en öppning i F02-A följer skåpen med. */
  const skapBitar = (() => {
    const hal = (skapV.oppningar || []).map(o => [o.y0, o.y1]).sort((a, b) => a[0] - b[0]);
    const ut = []; let a = skapV.y0;
    for (const [h0, h1] of hal) { if (h0 - a > 0.6) ut.push([a, h0]); a = Math.max(a, h1); }
    if (skapV.y1 - a > 0.6) ut.push([a, skapV.y1]);
    return ut;
  })();

  const ridhus = [
    /* SPEGLARNA. Vid B: EN spegel delad i två rutor i brun träram, monterad
       direkt ovanpå sargen (ridhus-inne-34, -19, -31, IMG_0189-f05) —
       VERIFIED. Vid A: TVÅ speglar i träram på den vita kortsidan, en på
       var sida om dubbeldörren (ridhus-inne-23) — VERIFIED, lägena DERIVED
       ur bilden (ungefär en fjärdedel in från vardera hörnet). */
    {id:"spegel_B", rum:"bana", typ:"spegel", pos:[panelX + (lE ? -0.06 : 0.06), ba.y + Bok.y], rikt:lE ? E : W,
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
    {id:"laktare_returtunna", rum:"laktare", typ:"tunna", pos:[dackMitt, ba.y + Hok.y + 1.6], rikt:E,
     matt:{b:0.5, d:0.5, h:1.1}, z0:L.dackZ, farg:"#8E9196", farg2:"#C0392B",
     kalla:"ridhus-inne-43", klass:"FOTO", lage:"DERIVED"},
    {id:"laktare_stol_1", rum:"laktare", typ:"stol", pos:[dackMitt, R.domarbas.y + 2.2], rikt:lE ? W : E,
     matt:{b:0.45, d:0.45, h:0.8}, z0:L.dackZ, farg:"#D4551E", farg2:"#8C8F92",
     kalla:"ridhus-inne-40", klass:"FOTO", lage:"DERIVED"},
    {id:"laktare_stol_2", rum:"laktare", typ:"stol", pos:[dackMitt, R.domarbas.y + 2.9], rikt:lE ? W : E,
     matt:{b:0.45, d:0.45, h:0.8}, z0:L.dackZ, farg:"#D4551E", farg2:"#8C8F92",
     kalla:"ridhus-inne-40", klass:"FOTO", lage:"DERIVED"},

    /* SKÅPKORRIDOREN — ridhus-klubb-01 (nyckelbild), IMG_0169-f02/f03,
       IMG_0268-r12/r15. Höga smala plåtskåp i grått med enstaka röda och
       mörkgrå dörrar längs västväggen; vita trästolar med rött mönstrat
       tyg kring ett litet bord mitt i gången; en bänk med ridstövlar
       under valvfönstret i norra änden. Glaspartierna på östsidan är
       F02-A:s öppningar i `skap_o` — se den strukturella anmärkningen i
       matrisen; de rörs inte här. */
    ...skapBitar.map(([y0, y1], i) => (
      {id:"skap_v_"+(i+1), rum:"skapkorridor", typ:"skapbank", pos:[SKP.x+0.25, (y0+y1)/2], rikt:E,
       matt:{b:y1-y0-0.1, d:0.5, h:1.9}, farg:"#C9CBCB", fargor:["#C9CBCB","#C9CBCB","#3A3C40","#C9CBCB","#B8322E"],
       kolliderar:true,
       kalla:"ridhus-klubb-01, IMG_0169-f02, IMG_0268-r12", klass:"VERIFIED", lage:"DERIVED"})),
    {id:"skap_bord", rum:"skapkorridor", typ:"bord", pos:[SKP.x+SKP.w/2, 68.6], rikt:E,
     matt:{b:0.6, d:0.6, h:0.72}, farg:"#F2EFE8", kolliderar:true,
     kalla:"ridhus-klubb-01, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_stol_1", rum:"skapkorridor", typ:"stol", pos:[SKP.x+SKP.w/2, 69.3], rikt:Sy,
     matt:{b:0.5, d:0.5, h:0.95}, farg:"#F2EFE8", farg2:"#B8322E", kolliderar:true,
     kalla:"ridhus-klubb-01, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_stol_2", rum:"skapkorridor", typ:"stol", pos:[SKP.x+SKP.w/2, 67.9], rikt:N,
     matt:{b:0.5, d:0.5, h:0.95}, farg:"#F2EFE8", farg2:"#B8322E", kolliderar:true,
     kalla:"ridhus-klubb-01, IMG_0268-r15", klass:"VERIFIED", lage:"ASSUMPTION"},
    {id:"skap_stovelbank", rum:"skapkorridor", typ:"bank", pos:[SKP.x+SKP.w/2, SKP.y+SKP.h-0.35], rikt:Sy,
     matt:{b:1.2, d:0.4, h:0.45}, farg:"#C9A87C", farg2:"#1E1E1E", kolliderar:true,
     kalla:"ridhus-klubb-01, ridhus-klubb-14", klass:"VERIFIED", lage:"DERIVED"},

    /* ENTRÉN — IMG_0268-r03/r05: valvfönstret mot parkeringen med en
       bänk/låda under fönsterbrädan, full av jackor, hjälmväska och
       stövlar. Fönstret sitter i västväggen; bänken står under det. */
    {id:"entre_bank", rum:"entre", typ:"bank", pos:[ENT.x+0.3, ENT.y+ENT.h/2], rikt:E,
     matt:{b:1.1, d:0.45, h:0.5}, farg:"#F0EDE6", farg2:"#3A3634", kolliderar:true,
     kalla:"IMG_0268-r03, -r05", klass:"FOTO", lage:"DERIVED"},
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
