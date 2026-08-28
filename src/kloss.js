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

/* Hästens mått i meter, för en varmblodshäst på 1,62 m i mankhöjd.
   Samma siffror som den svepta hästen, men lästa som lådor. */
const KLOSSHAST={
  /* Bålen i tre block: bringa, mellanparti, kors. */
  bringa:[0.75,1.245,0, 0.46,0.38,0.52],       // mitt x,y,z + b,h,d
  bal:   [0.00,1.240,0, 1.24,0.52,0.60],
  kors: [-0.78,1.310,0, 0.50,0.42,0.56],
};

/* En låda med mitten i (x,y,z). Bygges egna lada() räknar från origo,
   så translationen görs här för att slippa upprepa den i varje rad. */
function kLada(b,x,y,z,w,h,d,farg){
  return b.lada(w,h,d,farg,M4.translation(x,y,z));
}

/* ── Träd: en stam och två kronblock ──────────────────────────────
   Kronan är två kuber i fallande storlek. Två räcker: en enda blir
   en låda på en pinne, tre blir en trappa. */
function klossTrad(b,x,z,h,f0,f1){
  kLada(b, x, h*0.225, z, 0.34, h*0.45, 0.34, "#5E4A34");
  kLada(b, x, h*0.640, z, h*0.76, h*0.44, h*0.76, f0);
  kLada(b, x+h*0.06, h*0.900, z-h*0.04, h*0.50, h*0.28, h*0.50, f1||f0);
}

/* ── Hästen ──────────────────────────────────────────────────────── */
function klossHastDelar(D){
  const nat=b=>GL.nat(b), V="#FFFFFF";
  const K=KLOSSHAST;

  /* Bålen ligger i hästens egna koordinater och ritas otonad utom
     genom uTon, så alla block är vita. */
  D.kropp=nat((()=>{
    const b=new Bygge();
    for(const [x,y,z,w,h,d] of [K.bringa,K.bal,K.kors]) kLada(b,x,y,z,w,h,d,V);
    return b;})());

  /* Halsen i halsens eget rum: x 0→1 från manken till nacken, och
     bara x skalas av halsens längd. Två block, det övre smalare. */
  D.hals=nat((()=>{
    const b=new Bygge();
    kLada(b, 0.20, 0.010, 0, 0.62, 0.54, 0.38, V);
    kLada(b, 0.76, 0.030, 0, 0.60, 0.34, 0.26, V);
    return b;})());

  /* Huvudet: pannben, nos, ögon och näsborrar. Ögonen är mörka block
     som tonas med pälsfärgen och därför alltid är mörkare än den. */
  D.huvud=nat((()=>{
    const b=new Bygge();
    kLada(b, -0.150, 0.005, 0, 0.34, 0.27, 0.23, V);       // skallen
    kLada(b,  0.185,-0.040, 0, 0.36, 0.21, 0.17, V);       // nosen
    for(const s of [-1,1]){
      kLada(b, -0.115, 0.045, s*0.118, 0.09, 0.07, 0.02, "#2A2622");
      kLada(b,  0.310,-0.055, s*0.050, 0.03, 0.05, 0.04, "#3A322C");
    }
    return b;})());

  D.ora=nat(new Bygge().lada(0.055,0.15,0.05,V,M4.translation(0,0.075,0)));

  /* Benen: enhetshöga block som s3Segment sträcker mellan lederna. */
  const stolpe=(w,d,farg)=>nat(new Bygge().lada(w,1,d,farg,M4.translation(0,0.5,0)));
  D.overben=stolpe(0.155,0.155,V);
  D.skenben=stolpe(0.105,0.105,V);
  D.strumpa=stolpe(0.125,0.125,"#F2EFE6");
  D.svansrot=stolpe(0.170,0.170,V);
  D.lock=stolpe(0.095,0.048,V);
  D.bom=stolpe(0.110,0.110,V);
  D.stam=stolpe(0.300,0.300,"#4A3A28");
  D.rem=stolpe(0.026,0.026,V);

  D.hov=nat(new Bygge().lada(0.135,0.105,0.135,"#2E2A26",M4.translation(0,0.052,0)));
  D.fjader=nat(new Bygge().lada(0.200,0.190,0.200,V,M4.translation(0,0.095,0)));

  /* Svansen: två block som faller från svansroten. */
  D.svansmassa=nat((()=>{
    const b=new Bygge();
    kLada(b,-0.030,-0.230,0, 0.20,0.46,0.22, V);
    kLada(b,-0.095,-0.600,0, 0.16,0.34,0.17, V);
    return b;})());

  /* Manen i halsens rum: sju block längs kammen, i två lager så att
     ett mörkare skikt sticker fram på ena sidan. Halsens ovansida
     sjunker från 0,30 vid manken till 0,12 vid nacken — blocken följer
     den linjen och gräver ned sig fem centimeter i halsen så att inget
     glapp uppstår när halsen reser sig. */
  const kam=t=>0.300-0.180*t;
  const manrad=(bredd,djup,zskift,hskal,ysank)=>{
    const b=new Bygge();
    for(let i=0;i<7;i++){
      const t=0.04+i*0.145, h=(0.205-0.070*t)*hskal;
      kLada(b, t, kam(t)-0.05-ysank+h/2, zskift, bredd, h, djup, V);
    }
    return b;
  };
  D.manunder=nat(manrad(0.115,0.105,-0.030,0.86,0.020));
  D.manmatta=nat(manrad(0.135,0.110, 0.030,1.00,0));

  D.blas=nat(new Bygge().lada(0.38,0.06,0.10,"#F2EFE6"));
  D.krona=nat(new Bygge().lada(2,2,2,V));                  // enhetskub att skala

  D.sadel=nat((()=>{
    const b=new Bygge();
    kLada(b, 0,    0.030, 0, 0.52,0.16,0.40, "#4A3526");
    kLada(b,-0.03,-0.050, 0, 0.56,0.028,0.48,"#3E6B47");   // schabraket
    return b;})());
  D.tacke=nat(new Bygge().lada(1.80,0.76,0.66,"#7A2E33"));

  klossRyttarDelar(D);
  D.person=nat((()=>{
    const b=new Bygge();
    kLada(b, 0, 0.55, 0, 0.34,0.62,0.24, V);
    kLada(b, 0, 0.98, 0, 0.24,0.24,0.22, "#D8B08C");
    return b;})());
}

/* ── Ryttaren i sadeln ────────────────────────────────────────────
   Samma fästpunkter som den svepta ryttaren, så sitsen, lättridningen
   och tyglarna räknas oförändrat. */
function klossRyttarDelar(D){
  const nat=b=>GL.nat(b);
  const KAVAJ="#33465F", BYXA="#D6C9AE", HUD="#E0B490", HAR="#6B4526";

  D.bal=nat(new Bygge().lada(0.30,0.24,0.40,BYXA));
  D.torso=nat((()=>{
    const b=new Bygge();
    kLada(b, 0,    0.020, 0, 0.25,0.48,0.38, KAVAJ);
    kLada(b, 0,    0.275, 0, 0.20,0.05,0.30, "#F4F1E8");   // kragen
    kLada(b, 0.01, 0.315, 0, 0.12,0.08,0.12, HUD);         // halsen
    return b;})());
  D.arm=nat(new Bygge().lada(0.090,1,0.090,KAVAJ,M4.translation(0,0.5,0)));
  D.lar=nat(new Bygge().lada(0.155,1,0.155,BYXA,M4.translation(0,0.5,0)));
  D.vad=nat(new Bygge().lada(0.110,1,0.110,"#1E1A16",M4.translation(0,0.5,0)));
  D.stovel=nat(new Bygge().lada(0.23,0.11,0.13,"#1E1A16",M4.translation(0.02,0,0)));
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
    kLada(b,-0.160,-0.060, 0, 0.100,0.300,0.140, HAR);     // hästsvansen
    return b;})());
  /* Hjälmen ritas redan 0,10 upp, så skalet ligger kring y=0 här. */
  D.hjalm=nat((()=>{
    const b=new Bygge();
    kLada(b, 0,    -0.010, 0, 0.230,0.150,0.230, "#23282F");
    kLada(b, 0.115,-0.030, 0, 0.100,0.035,0.200, "#20252C");  // skärmen
    kLada(b, 0,     0.072, 0, 0.100,0.035,0.090, "#3E6B47");  // klubbens färg
    return b;})());
}
