/* ══════════════════════════════════════════════════════════════════
   KLOSSTILEN — världen byggd av rätblock.

   Stilen är vald med flit: när allt är kantigt läser formen som stil
   i stället för som ett misslyckat försök till en rundad kropp. Därför
   får inget här smygas in med klot eller cylindrar — en kloss som
   nästan är rund är det värsta av två världar.

   Delarna byggs i exakt samma lokala rum som de svepta motsvarigheterna
   i scen3d.js, så all rigg, animation, sadel och seldon fungerar
   oförändrat. Byt STIL i ljus.js så byter hela världen skepnad.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* En låda med mitten i (x,y,z). Bygges egna lada() räknar från origo,
   så translationen görs här för att slippa upprepa den i varje rad. */
function kLada(b,x,y,z,w,h,d,farg){
  return b.lada(w,h,d,farg,M4.translation(x,y,z));
}

/* ── Träd: en stam och två fasetterade kronor ─────────────────────
   Förlagans natur är lågpolygon, inte klossig — kronorna är koner med
   få sidor, inte kuber. Sex sidor räcker: fyra läser som en pyramid,
   åtta börjar likna en rundad gran. */
function klossTrad(b,x,z,h,f0,f1){
  b.cyl(0.19,0.15,h*0.44,"#5E4A34",M4.translation(x,0,z),5);
  b.cyl(h*0.40,h*0.10,h*0.42,f0,M4.translation(x,h*0.40,z),6);
  b.cyl(h*0.26,0.02,h*0.34,f1||f0,M4.translation(x,h*0.74,z),6);
}

/* ── Ryttaren och figurerna: klossiga, till skillnad från hästen ──
   I förlagan är figuren kantig och hästen inte. Bild 3 visar precis
   det: en R6-gubbe bredvid en häst med riktig anatomi. Så hästen får
   sin form av fasettering, och figuren av rätblock. */
function klossDelar(D){
  /* Ryttardelarna byggs av s3BygRyttare, som gör två uppsättningar —
     en för eleverna och en för dig. Här byggs bara resten. */
  D.person=GL.nat((()=>{
    const b=new Bygge();
    kLada(b, 0, 0.55, 0, 0.34,0.62,0.24, "#FFFFFF");
    kLada(b, 0, 0.98, 0, 0.24,0.24,0.22, "#D8B08C");
    return b;})());
}

/* Ryttaren i sadeln. Samma fästpunkter som den svepta ryttaren, så
   sitsen, lättridningen och tyglarna räknas oförändrat. */
/* Paletten kommer utifrån (jag.js via s3BygRyttare), så att samma kod
   kan bygga både elevernas och din ryttare. */
function klossRyttarDelar(D,J){
  const nat=b=>GL.nat(b);
  const KAVAJ=J.kavaj, BYXA=J.byxa, HUD=J.hy, HAR=J.har, STOVEL=J.stovel;

  D.bal=nat(new Bygge().lada(0.30,0.24,0.40,BYXA));
  D.torso=nat((()=>{
    const b=new Bygge();
    kLada(b, 0,    0.020, 0, 0.25,0.48,0.38, KAVAJ);
    kLada(b, 0,    0.275, 0, 0.20,0.05,0.30, "#F4F1E8");   // kragen
    kLada(b, 0.01, 0.315, 0, 0.12,0.08,0.12, HUD);         // halsen
    return b;})());
  D.arm=nat(new Bygge().lada(0.090,1,0.090,KAVAJ,M4.translation(0,0.5,0)));
  D.lar=nat(new Bygge().lada(0.155,1,0.155,BYXA,M4.translation(0,0.5,0)));
  D.vad=nat(new Bygge().lada(0.110,1,0.110,STOVEL,M4.translation(0,0.5,0)));
  D.stovel=nat(new Bygge().lada(0.23,0.11,0.13,STOVEL,M4.translation(0.02,0,0)));
  D.led=nat(new Bygge().lada(0.09,0.09,0.09,"#FFFFFF"));
  D.hand=nat(new Bygge().lada(0.092,0.10,0.076,"#2B2620"));

  /* Huvudet tittar mot +X, så ansiktet ligger på framsidan. */
  D.huvudR=nat((()=>{
    const b=new Bygge();
    kLada(b, 0, 0, 0, 0.200,0.220,0.210, HUD);
    for(const s of [-1,1])
      kLada(b, 0.101, 0.020, s*0.050, 0.020,0.050,0.040, "#241A14");
    kLada(b, 0.101,-0.058, 0, 0.020,0.020,0.090, "#241A14");
    return b;})());
  D.har=nat((()=>{
    const b=new Bygge();
    kLada(b,-0.010, 0.100, 0, 0.210,0.090,0.220, HAR);     // luggen
    /* Frisyren: svansen faller längst, flätan är smalare, kort hår
       slutar i nacken och uppsatt syns bara som luggen. */
    if(J.harstil==="svans")   kLada(b,-0.160,-0.060,0, 0.100,0.300,0.140, HAR);
    else if(J.harstil==="flata")kLada(b,-0.155,-0.070,0, 0.075,0.320,0.090, HAR);
    else if(J.harstil==="kort") kLada(b,-0.140, 0.020,0, 0.110,0.130,0.190, HAR);
    return b;})());
  /* Hjälmen ritas redan 0,10 upp, så skalet ligger kring y=0 här. */
  D.hjalm=nat((()=>{
    const b=new Bygge();
    const skarm=(typeof jagMorkare==="function")?jagMorkare(J.hjalm,0.14):J.hjalm;
    kLada(b, 0,    -0.010, 0, 0.230,0.150,0.230, J.hjalm);
    kLada(b, 0.115,-0.030, 0, 0.100,0.035,0.200, skarm);      // skärmen
    kLada(b, 0,     0.072, 0, 0.100,0.035,0.090, J.klubb);    // klubbens färg
    return b;})());
}
