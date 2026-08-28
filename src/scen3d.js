/* ══════════════════════════════════════════════════════════════════
   RIDSCENEN I 3D — hästen, ryttaren och anläggningen byggda av riktig
   geometri och renderade med djupbuffert, sol och skuggor.
   Hästen är riggad: skuldror, höfter, knän och kotor är egna leder
   som animeras ur gångartens takt — skritt fyra slag, trav diagonala
   par, galopp tre slag med ledande ben — och tucken i språnget är
   samma led som bär hästen i stancen. Allt är byggt i spelet: inga
   modellfiler, inga texturer utifrån.
   Koordinater: banans x → världens X, banans y → världens Z, upp = Y.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const S3={
  redo:false, forsokt:false, canvas:null,
  plats:null, statiskt:[], hinderNat:null, stolpNat:null,
  del:{}, tex:{},
  kam:{x:10,y:2.6,z:52, tx:10,ty:1.4,tz:46, satt:false},
};

/* ── Ljussättning per plats och väder ─────────────────────────── */
function s3Ljus(over){
  const v=(G.vader&&G.vader.typ)||"sol";
  const inne=(over||G.plats)==="ridhus";
  if(inne)return {   // ridhusets lysrör: jämnt, varmt och utan hårda skuggor
    sol:[0.35,0.88,0.32], solFarg:"#B3A78A", himmel:"#7E838A", mark:"#4A443A",
    dimFarg:"#3A3C40", dimNara:44, dimFjarr:120, skuggAlfa:0.24, skuggFarg:"#0A0A0C",
    himmelTopp:"#15181D", himmelBotten:"#23272E",
  };
  if(v==="regn")return {
    sol:[-0.35,0.72,0.60], solFarg:"#8E969E", himmel:"#7A828C", mark:"#4A4E44",
    dimFarg:"#6E747C", dimNara:26, dimFjarr:130, skuggAlfa:0.12, skuggFarg:"#0A0C10",
    himmelTopp:"#2C3138", himmelBotten:"#5E646C",
  };
  if(v==="mulet")return {
    sol:[-0.30,0.78,0.55], solFarg:"#A8A89C", himmel:"#868C94", mark:"#50543E",
    dimFarg:"#8E8E84", dimNara:34, dimFjarr:160, skuggAlfa:0.14, skuggFarg:"#0C0E12",
    himmelTopp:"#39404A", himmelBotten:"#8A8A80",
  };
  return { // gyllene timme
    sol:[-0.58,0.50,0.64], solFarg:"#E2B478", himmel:"#7C8CA8", mark:"#5E5238",
    dimFarg:"#B08A5C", dimNara:55, dimFjarr:210, skuggAlfa:0.26, skuggFarg:"#1A1206",
    himmelTopp:"#2C3A55", himmelBotten:"#D8A268",
  };
}

/* ── Texturer, målade i spelet ────────────────────────────────── */
function s3Texturer(){
  const T=S3.tex;
  T.sand=glCanvasTex(256,256,(c,w,h)=>{
    c.fillStyle="#C0B394";c.fillRect(0,0,w,h);
    for(let i=0;i<2600;i++){
      const x=Math.random()*w,y=Math.random()*h,r=Math.random();
      c.fillStyle=r<0.5?"rgba(150,138,112,.35)":r<0.8?"rgba(212,200,172,.35)":"rgba(120,104,80,.30)";
      c.fillRect(x,y,1+Math.random()*2,1+Math.random()*2);
    }
    c.strokeStyle="rgba(140,128,102,.30)";c.lineWidth=1.5;   // harvspåren
    for(let i=0;i<16;i++){c.beginPath();c.moveTo(0,i*16+4);c.lineTo(w,i*16+4);c.stroke();}
  },true);
  T.gras=glCanvasTex(256,256,(c,w,h)=>{
    c.fillStyle="#4A5C34";c.fillRect(0,0,w,h);
    for(let i=0;i<3000;i++){
      const x=Math.random()*w,y=Math.random()*h;
      c.fillStyle=Math.random()<0.5?"rgba(96,116,64,.5)":"rgba(58,72,40,.5)";
      c.fillRect(x,y,2,1+Math.random()*3);
    }
  },true);
  T.grus=glCanvasTex(256,256,(c,w,h)=>{
    c.fillStyle="#8A8176";c.fillRect(0,0,w,h);
    for(let i=0;i<2200;i++){
      const x=Math.random()*w,y=Math.random()*h;
      c.fillStyle=Math.random()<0.5?"rgba(112,104,94,.6)":"rgba(160,152,140,.5)";
      c.beginPath();c.arc(x,y,0.7+Math.random()*1.8,0,7);c.fill();
    }
  },true);
  T.tra=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#6B4A34";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(0,0,0,.16)";c.lineWidth=1;
    for(let i=0;i<10;i++){c.beginPath();c.moveTo(0,i*13+3);c.lineTo(w,i*13+5);c.stroke();}
  },true);
  T.plat=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#3A3E44";c.fillRect(0,0,w,h);
    for(let i=0;i<16;i++){
      c.fillStyle=i%2?"rgba(255,255,255,.05)":"rgba(0,0,0,.10)";
      c.fillRect(i*8,0,4,h);
    }
  },true);
  /* Sponsorbanderollerna på västerväggen. */
  T.skyltar=(RIDHUSINNE.skyltar||[]).map(s=>glCanvasTex(512,128,(c,w,h)=>{
    c.fillStyle=s.bg;c.fillRect(0,0,w,h);
    c.fillStyle=s.fg;c.textAlign="center";c.textBaseline="middle";
    let px=64;c.font=`600 ${px}px "IBM Plex Sans", sans-serif`;
    while(c.measureText(s.text).width>w-40&&px>14){px-=3;
      c.font=`600 ${px}px "IBM Plex Sans", sans-serif`;}
    c.fillText(s.text,w/2,h/2);
  }));
  /* Dressyrbokstäverna på sargen. */
  T.bokstav={};
  for(const b of DRESSYRBOKSTAVER) if(!T.bokstav[b.b])
    T.bokstav[b.b]=glCanvasTex(128,128,(c,w,h)=>{
      c.fillStyle="#F2EDE2";c.fillRect(0,0,w,h);
      c.strokeStyle="#3A3E44";c.lineWidth=6;c.strokeRect(3,3,w-6,h-6);
      c.fillStyle="#2E3238";c.textAlign="center";c.textBaseline="middle";
      c.font='700 84px Petrona, Georgia, serif';
      c.fillText(b.b,w/2,h/2+4);
    });
}

/* ── Hästens delar. Byggs en gång i mankhöjd 1,60 m och skalas. ── */
function s3BygHast(){
  const D=S3.del, vit="#FFFFFF";
  const nyNat=b=>GL.nat(b);
  /* Måtten är en varmblodshäst på 1,62 m i mankhöjd: bålen 1,85 m
     lång, 0,72 m hög och 0,58 m bred, benen 1,08 m från bog till hov. */
  D.kropp=nyNat(new Bygge().klot(1,vit,M4.skala(0.92,0.36,0.29),16));
  D.bringa=nyNat(new Bygge().klot(1,vit,M4.skala(0.34,0.36,0.28),14));
  D.kors=nyNat(new Bygge().klot(1,vit,M4.skala(0.40,0.37,0.30),14));
  D.hals=nyNat(new Bygge().cyl(0.21,0.115,1,vit,null,12));
  D.huvud=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,vit,M4.skala(0.24,0.115,0.095),12);
    b.klot(1,vit,M4.mul(M4.translation(0.23,-0.035,0),M4.skala(0.10,0.075,0.075)),10);
    return b;})());
  D.ora=nyNat(new Bygge().cyl(0.038,0.004,0.14,vit,null,7));
  D.overben=nyNat(new Bygge().cyl(0.078,0.058,1,vit,null,12));
  D.skenben=nyNat(new Bygge().cyl(0.050,0.040,1,vit,null,12));
  D.hov=nyNat(new Bygge().cyl(0.062,0.058,0.10,"#2E2A26",null,9));
  D.svansrot=nyNat(new Bygge().cyl(0.085,0.075,1,vit,null,8));
  D.svanstagel=nyNat(new Bygge().cyl(0.095,0.030,1,vit,null,8));
  D.man=nyNat(new Bygge().lada(1,1,0.030,vit));
  D.sadel=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,"#4A3526",M4.mul(M4.translation(0,0.03,0),M4.skala(0.26,0.075,0.20)),12);
    b.lada(0.54,0.025,0.46,"#E8E4DA",M4.translation(-0.03,-0.05,0));  // schabrak
    return b;})());
  D.tacke=nyNat(new Bygge().klot(1,"#7A2E33",M4.skala(0.90,0.38,0.33),14));
  /* Ryttaren. */
  D.bal=nyNat(new Bygge().lada(0.30,0.22,0.34,"#3B4A63"));
  D.torso=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,"#F0EDE4",M4.skala(0.15,0.24,0.19),12);          // överkroppen
    b.klot(1,"#F0EDE4",M4.mul(M4.translation(0,0.16,0),M4.skala(0.17,0.09,0.20)),10);
    b.klot(0.075,"#D8B08C",M4.translation(0.01,0.26,0),8);    // halsen
    return b;})());
  D.arm=nyNat(new Bygge().cyl(0.055,0.05,1,"#F0EDE4",null,11));
  D.lar=nyNat(new Bygge().cyl(0.085,0.07,1,"#3B4A63",null,11));
  D.vad=nyNat(new Bygge().cyl(0.065,0.055,1,"#3B4A63",null,11));
  D.stovel=nyNat(new Bygge().lada(0.22,0.10,0.11,"#241C16"));
  D.huvudR=nyNat(new Bygge().klot(0.105,"#D8B08C",null,10));
  D.hjalm=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,"#3E6B47",M4.skala(0.135,0.115,0.135),12);
    b.lada(0.20,0.02,0.20,"#2E5237",M4.translation(0.03,-0.04,0));   // skärmen
    return b;})());
  D.led=nyNat(new Bygge().klot(0.048,"#F0EDE4",null,9));
  D.hand=nyNat(new Bygge().klot(1,"#D8B08C",M4.skala(0.048,0.052,0.038),9));
  D.rem=nyNat(new Bygge().cyl(0.012,0.012,1,"#241A12",null,5));
  /* Hinder och stolpar. */
  D.bom=nyNat(new Bygge().cyl(0.055,0.055,1,vit,null,8));
  D.stod=nyNat(new Bygge().lada(0.10,1,0.10,"#4A3F30"));
  /* Natur och staket. */
  D.stam=nyNat(new Bygge().cyl(0.16,0.11,1,"#4A3A28",null,7));
  D.krona=nyNat(new Bygge().klot(1,vit,null,12));
  D.pale=nyNat(new Bygge().lada(0.12,1,0.12,"#5A4633"));
  D.regel=nyNat(new Bygge().lada(1,0.10,0.05,"#6B5540"));
  D.person=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,vit,M4.mul(M4.translation(0,0.55,0),M4.skala(0.19,0.32,0.17)),10);
    b.klot(0.13,"#D8B08C",M4.translation(0,0.98,0),10);
    return b;})());
}

/* Matris som lägger en enhetscylinder (radie 1, höjd 1, längs +Y)
   mellan två punkter — används till ben, tyglar, bommar och reglar. */
function s3Segment(a,b,r){
  const dx=b[0]-a[0], dy=b[1]-a[1], dz=b[2]-a[2];
  const len=Math.hypot(dx,dy,dz)||1e-6;
  const ay=[dx/len,dy/len,dz/len];
  const tmp=Math.abs(ay[1])>0.985?[1,0,0]:[0,1,0];
  let ax=[tmp[1]*ay[2]-tmp[2]*ay[1], tmp[2]*ay[0]-tmp[0]*ay[2], tmp[0]*ay[1]-tmp[1]*ay[0]];
  const l1=Math.hypot(ax[0],ax[1],ax[2])||1; ax=[ax[0]/l1,ax[1]/l1,ax[2]/l1];
  const az=[ay[1]*ax[2]-ay[2]*ax[1], ay[2]*ax[0]-ay[0]*ax[2], ay[0]*ax[1]-ay[1]*ax[0]];
  return new Float32Array([
    ax[0]*r, ax[1]*r, ax[2]*r, 0,
    ay[0]*len, ay[1]*len, ay[2]*len, 0,
    az[0]*r, az[1]*r, az[2]*r, 0,
    a[0], a[1], a[2], 1]);
}

/* ── Gångarternas takt ────────────────────────────────────────────
   Faserna är hästens verkliga benföljd: skritt fyra slag (vh, vf,
   hh, hf), trav diagonala par, galopp tre slag med yttre bakben
   först. Stancen bär, svingen förs fram med böjt knä. ── */
const S3FAS={
  halt:   [0,0,0,0],
  skritt: [0.00,0.25,0.50,0.75],   // vf, hf, vb, hb
  trav:   [0.00,0.50,0.50,0.00],
  galopp: [0.34,0.66,0.00,0.34],
};
function s3Ben(fas,gangart,i){
  const G0=S3FAS[gangart]||S3FAS.halt;
  const bak=i>=2;
  if(gangart==="halt")return {t1:bak?-0.04:0.03, t2:0.06};
  const A={skritt:0.30, trav:0.42, galopp:0.50}[gangart]||0.3;
  const D={skritt:0.62, trav:0.46, galopp:0.42}[gangart]||0.6;
  let p=(fas+G0[i])%1; if(p<0)p+=1;
  let t1,t2;
  if(p<D){                       // stance: benet bär och förs bakåt
    const u=p/D;
    t1=A*(1-2*u);
    t2=0.05+0.10*Math.sin(Math.PI*u);
  }else{                         // sving: knäet viks och benet förs fram
    const u=(p-D)/(1-D);
    t1=-A+2*A*(0.5-0.5*Math.cos(Math.PI*u));
    t2=0.15+(bak?1.05:0.95)*Math.sin(Math.PI*u);
  }
  return {t1, t2};
}

/* ── En häst: rigg, ben, man, svans, sadel, ryttare ───────────── */
function s3RitaHast(o){
  const D=S3.del, gl=GL;
  const h=o.hast, M=(h.typ==="ponny"?1.42:1.62)/1.62;    // skala mot 1,62 m
  const farg=h.farg, man=h.man;
  const gangart=o.gangart||"halt", fas=o.fas||0;
  const luft=o.luft||0;
  const u=luft>0?1-luft/0.55:0;                          // 0→1 genom språnget
  const bage=luft>0?Math.sin(Math.PI*u):0;
  /* Kroppens rörelse: takten lyfter, galoppen vaggar, språnget stiger. */
  let bob=0,lut=0;
  if(gangart==="trav")bob=0.035*Math.sin(4*Math.PI*fas);
  else if(gangart==="galopp"){bob=0.06*Math.sin(2*Math.PI*fas);lut=0.07*Math.sin(2*Math.PI*fas);}
  else if(gangart==="skritt")bob=0.018*Math.sin(4*Math.PI*fas);
  if(luft>0){bob+=1.15*bage; lut-=0.52*Math.cos(Math.PI*u);}

  /* Grundmatris: position, riktning (hästen är byggd mot +X), skala. */
  const bas=M4.mul(
    M4.mul(M4.translation(o.x,bob*M,o.z), M4.rotY(-o.rikt)),
    M4.mul(M4.rotZ(lut), M4.skala(M)));
  const P=(x,y,z)=>[x,y,z];                              // lokala punkter
  const rita=(nat,mat,ton)=>{
    const m=M4.mul(bas,mat);
    gl.rita(nat,m,{ton});
    if(o.skugga)gl.skugga(nat,m,0);
  };

  /* Bålen. */
  rita(D.kropp,M4.translation(0,1.18,0),farg);
  rita(D.bringa,M4.translation(0.70,1.20,0),farg);
  rita(D.kors,M4.translation(-0.72,1.22,0),glMorka(farg,0.96));
  /* Halsen: reser sig när hästen samlas, sträcks på lång tygel. */
  const samling=o.samling===undefined?0.4:o.samling;
  const halsA=P(0.86,1.36,0), halsL=0.76+0.06*(1-samling);
  /* Betande häst sänker halsen till marken; annars styr samlingen. */
  const halsVin=o.beta ? -0.72
    : 0.55+0.55*samling+(luft>0?0.25*Math.cos(Math.PI*u):0);
  const halsB=P(halsA[0]+Math.cos(halsVin)*halsL, halsA[1]+Math.sin(halsVin)*halsL, 0);
  rita(D.hals,s3Segment(halsA,halsB,1),farg);
  /* Huvudet följer halsens vinkel, nosen något nedåt. */
  const nick=o.beta ? -1.15 : halsVin-0.95-0.25*samling;
  const huvudM=M4.mul(M4.translation(halsB[0]+Math.cos(nick)*0.16,
    halsB[1]+Math.sin(nick)*0.16-0.02,0), M4.rotZ(nick));
  rita(D.huvud,huvudM,farg);
  for(const s of [-1,1])
    rita(D.ora,M4.mul(M4.mul(huvudM,M4.translation(-0.10,0.10,s*0.085)),
      M4.rotZ(-0.25*s*0+0.15)),glMorka(farg,0.9));
  /* Manen längs halsen. */
  for(let i=0;i<10;i++){
    const t=i/9, mx=halsA[0]+(halsB[0]-halsA[0])*t, my=halsA[1]+(halsB[1]-halsA[1])*t;
    const sv=Math.sin(fas*Math.PI*2+i*0.7)*0.025*(gangart==="halt"?0.3:1);
    const ut=0.13+0.03*Math.sin(t*Math.PI);      // manen faller utanför halsen
    rita(D.man,M4.mul(M4.mul(
      M4.translation(mx-Math.cos(halsVin)*0.02+Math.sin(halsVin)*ut,
                     my+Math.cos(halsVin)*ut, sv),
      M4.rotZ(halsVin-1.57)), M4.skala(0.09,0.20,1)),man);
  }
  /* Benen: fram vh/hf, bak vb/hb. Knät viks bakåt fram, framåt bak. */
  const fasten=[[0.64,1.12,0.17],[0.64,1.12,-0.17],[-0.70,1.16,0.19],[-0.70,1.16,-0.19]];
  for(let i=0;i<4;i++){
    const f=fasten[i], bak=i>=2;
    let {t1,t2}=s3Ben(fas,gangart,i);
    if(luft>0){                                   // tucken i språnget
      const fram=!bak;
      const tuck=fram?Math.max(0,Math.sin(Math.PI*Math.min(u*1.4,1)))
                     :Math.max(0,Math.sin(Math.PI*Math.max((u-0.25)*1.35,0)));
      t1=fram?(0.55*tuck-0.1):(-0.65*tuck+0.05);
      t2=(fram?1.55:1.25)*tuck+0.1;
    }
    const L1=bak?0.52:0.50, L2=bak?0.48:0.46;
    const d1=t1, d2=t1+(bak?-t2:t2);
    const kna=P(f[0]+Math.sin(d1)*L1, f[1]-Math.cos(d1)*L1, f[2]);
    const kota=P(kna[0]+Math.sin(d2)*L2, kna[1]-Math.cos(d2)*L2, f[2]);
    rita(D.overben,s3Segment(f,kna,1),farg);
    rita(D.skenben,s3Segment(kna,kota,1),glMorka(farg,0.94));
    rita(D.hov,M4.translation(kota[0],kota[1]-0.10,kota[2]),"#FFFFFF");
  }
  /* Svansen. */
  const svSv=Math.sin(fas*Math.PI*2)*0.09*(gangart==="halt"?0.2:1);
  const rotA=P(-1.02,1.46,0), rotB=P(-1.17,1.33,svSv*0.15);
  rita(D.svansrot,s3Segment(rotA,rotB,1),farg);          // svansroten bär pälsens färg
  rita(D.svanstagel,s3Segment(rotB,P(rotB[0]-0.10,rotB[1]-0.66,svSv*0.5),1),man);
  /* Täcke, sadel och ryttare. */
  if(o.tacke)rita(D.tacke,M4.translation(-0.02,1.20,0),"#FFFFFF");
  if(o.sadel){
    rita(D.sadel,M4.translation(0.10,1.56,0),"#FFFFFF");
    for(const s of [-1,1])   // gjorden runt bålen
      rita(D.rem,s3Segment(P(0.10,1.52,s*0.16),P(0.10,1.06,s*0.26),1),"#4A3526");
  }
  if(o.ryttare)s3RitaRyttare(bas,{...o,fas,gangart,luft,u,bage,huvudPos:huvudB(halsB,nick)});
  function huvudB(hb,n){return [hb[0]+Math.cos(n)*0.34, hb[1]+Math.sin(n)*0.34-0.04, 0];}
}

/* ── Ryttaren: sits, lättridning, lätt sits och tyglarna ──────── */
function s3RitaRyttare(bas,o){
  const D=S3.del, gl=GL;
  const rita=(nat,mat,ton)=>{const m=M4.mul(bas,mat);
    gl.rita(nat,m,{ton}); if(o.skugga)gl.skugga(nat,m,0);};
  const a=o.aids||{sits:0.5,tygel:0.3,lattridning:true,diagonal:1};
  /* Lättridning: upp ur sadeln vartannat travsteg. */
  const latt=o.gangart==="trav"&&a.lattridning
    ? 0.085*Math.max(0,Math.sin(4*Math.PI*o.fas)) : 0;
  /* Sitsen: Ctrl djupt ner, Shift lätt sits framåt. Språng = framåt. */
  let lutning=0.16+0.42*(0.5-clamp(a.sits,0,1));
  if(o.luft>0)lutning=0.55*o.bage+0.16;
  const satY=1.64+latt, satX=0.06+lutning*0.10;
  const bal=M4.mul(M4.translation(satX,satY,0),M4.rotZ(-lutning*0.5));
  rita(D.bal,bal,"#FFFFFF");
  const torso=M4.mul(M4.translation(satX+0.02,satY+0.30,0),M4.rotZ(-lutning));
  rita(D.torso,torso,"#FFFFFF");
  /* Huvudet blickar dit hästen ska. */
  const hx=satX+0.04+Math.sin(lutning)*0.52, hy=satY+0.30+Math.cos(lutning)*0.30;
  rita(D.huvudR,M4.translation(hx,hy,0),"#FFFFFF");
  rita(D.hjalm,M4.translation(hx,hy+0.05,0),"#FFFFFF");
  /* Benen: låret ner mot stigbygeln, vaden längs hästens sida. */
  for(const s of [-1,1]){
    const hoft=[satX-0.02,satY-0.02,s*0.19];
    const kna=[hoft[0]+0.30,hoft[1]-0.26,s*0.30];
    const hal=[kna[0]-0.05,kna[1]-0.42,s*0.30];
    rita(D.lar,s3Segment(hoft,kna,1),"#FFFFFF");
    rita(D.led,M4.translation(kna[0],kna[1],kna[2]),"#3B4A63");   // knäet
    rita(D.vad,s3Segment(kna,hal,1),"#FFFFFF");
    rita(D.stovel,M4.translation(hal[0]+0.04,hal[1]-0.04,hal[2]),"#FFFFFF");
    // stigbygeln
    rita(D.rem,s3Segment([satX+0.02,satY-0.06,s*0.26],[hal[0],hal[1]+0.02,hal[2]],1),"#9A9AA0");
  }
  /* Armarna och tyglarna: handen närmare kroppen när du tar tygel. */
  const drag=clamp(a.tygel,0,1);
  const hand=[satX+0.34-drag*0.10, satY+0.34-lutning*0.12, 0];
  for(const s of [-1,1]){
    const axel=[satX+0.02,satY+0.46,s*0.16];
    const bage=[(axel[0]+hand[0])/2+0.02,(axel[1]+hand[1])/2-0.03,s*0.155];
    rita(D.led,M4.translation(axel[0],axel[1],axel[2]),"#F0EDE4");   // axeln
    rita(D.arm,s3Segment(axel,bage,1),"#FFFFFF");
    rita(D.led,M4.translation(bage[0],bage[1],bage[2]),"#F0EDE4");   // armbågen
    rita(D.arm,s3Segment(bage,[hand[0],hand[1],s*0.13],1),"#FFFFFF");
    rita(D.hand,M4.translation(hand[0],hand[1]-0.02,s*0.13),"#FFFFFF");
    // tygeln till bettet
    if(o.huvudPos)
      rita(D.rem,s3Segment([hand[0],hand[1],s*0.13],
        [o.huvudPos[0],o.huvudPos[1],s*0.075],1),"#3A2E20");
  }
}

/* Himlen: en ring av band från horisont till zenit, plus ett lock.
   Ritas obelyst, så färgen i banden är gradienten. Centrum flyttas
   med scenen så att kupolen alltid omsluter kameran. */
function s3Himmel(centrum){
  if(S3.himmel)GL.fritt(S3.himmel.nat);
  const L=s3Ljus(), himmel=new Bygge();
  const topp=glFarg(L.himmelTopp), bot=glFarg(L.himmelBotten);
  const BANDN=8, H0=-30, HTOT=170, bh=HTOT/BANDN;
  const cx0=centrum[0], cz0=centrum[1];
  for(let i=0;i<BANDN;i++){
    const t=i/(BANDN-1), e=Math.pow(t,1.45);   // glöden når högre upp
    const f=[bot[0]+(topp[0]-bot[0])*e, bot[1]+(topp[1]-bot[1])*e, bot[2]+(topp[2]-bot[2])*e];
    himmel.cyl(150,150,bh*1.02,f,M4.translation(cx0,H0+i*bh,cz0),24,false);
  }
  himmel.yta(320,320,topp,M4.translation(cx0,H0+HTOT,cz0),1);
  S3.himmel={nat:GL.nat(himmel)};
  S3.himmelC=centrum;
}

/* ── Anläggningen: byggs om när platsen byter ─────────────────── */
function s3ByggPlats(plats){
  for(const s of S3.statiskt)GL.fritt(s.nat);
  S3.statiskt=[];
  const T=S3.tex, lagg=(bygge,tex)=>S3.statiskt.push({nat:GL.nat(bygge),tex});
  s3Himmel([10,30]);

  if(plats==="ridhus"){
    /* Golvet: hallens betong och banans fibersand. */
    /* Texturerade ytor får bära sin egen färg — vertexfärgen vit,
       annars mörkas underlaget två gånger. */
    const golv=new Bygge().yta(30,72,"#FFFFFF",M4.translation(10,0,30),9);
    lagg(golv,T.grus);
    const sand=new Bygge().yta(20,60,"#FFFFFF",M4.translation(10,0.02,30),7);
    lagg(sand,T.sand);
    /* Sargen runt banan: vit panel med mörk sockel. */
    const sarg=new Bygge();
    const vagg=(x0,z0,x1,z1)=>{
      const dx=x1-x0, dz=z1-z0, len=Math.hypot(dx,dz), vin=Math.atan2(dz,dx);
      const mitt=M4.mul(M4.translation((x0+x1)/2,0,(z0+z1)/2),M4.rotY(-vin));
      sarg.lada(len,0.26,0.14,"#2E2E2C",M4.mul(mitt,M4.translation(0,0.13,0)));
      sarg.lada(len,1.10,0.12,"#E9E5DC",M4.mul(mitt,M4.translation(0,0.81,0)));
      sarg.lada(len,0.06,0.16,"#CFC8BC",M4.mul(mitt,M4.translation(0,1.38,0)));
    };
    vagg(0,0,20,0); vagg(20,0,20,60); vagg(20,60,0,60); vagg(0,60,0,0);
    lagg(sarg,null);
    /* Hallens väggar och tak med limträbalkar. */
    const hall=new Bygge();
    const yv=(x,z,w,d,h,f)=>hall.lada(w,h,d,f,M4.translation(x,h/2,z));
    yv(10,-4.5,30,0.3,5.2,"#E9E5DC"); yv(10,64.5,30,0.3,5.2,"#E9E5DC");
    yv(-4.8,30,0.3,72,5.2,"#E9E5DC"); yv(24.8,30,0.3,72,5.2,"#E9E5DC");
    /* Sadeltaket: två fall från takfoten på 5,2 m upp till nocken på
       8,2 m, burna av limträbalkar var sjätte meter. */
    const halvSpann=14.8, resning=3.0;
    const takLen=Math.hypot(halvSpann,resning), takVin=Math.atan2(resning,halvSpann);
    for(const s of [-1,1]){
      const mx=10+s*halvSpann/2, my=5.2+resning/2;
      hall.lada(takLen,0.18,72,"#3A3E44",
        M4.mul(M4.translation(mx,my,30),M4.rotZ(s*takVin)));
    }
    for(let z=-3;z<=63;z+=6){       // limträbalkar och nockås
      hall.lada(29.8,0.24,0.22,"#7A5C3E",M4.translation(10,5.30,z));
      hall.lada(0.20,2.9,0.20,"#7A5C3E",M4.translation(10,6.7,z));
    }
    hall.lada(0.26,0.26,72,"#6B4F35",M4.translation(10,8.18,30));
    for(let z=0;z<=60;z+=7.5){      // lysrörsarmaturer
      hall.lada(1.2,0.10,0.24,"#F6F2E4",M4.translation(5.5,5.25,z));
      hall.lada(1.2,0.10,0.24,"#F6F2E4",M4.translation(14.5,5.25,z));
    }
    lagg(hall,null);
    /* Läktaren i öster med trappstegsbänkar. */
    const lak=new Bygge();
    for(let i=0;i<3;i++){
      lak.lada(1.1,0.45,32,"#FFFFFF",M4.translation(20.9+i*1.05,0.22+i*0.45,30));
      lak.lada(1.0,0.10,32,"#F0EAE0",M4.translation(20.9+i*1.05,0.47+i*0.45,30));
    }
    lak.lada(0.16,1.6,32,"#C8BCA8",M4.translation(24.2,0.8,30));
    lagg(lak,T.tra);
    /* Spegelbandet och sponsorväggen i väster. */
    const panel=new Bygge();
    for(let z=16;z<=44;z+=4.6)
      panel.lada(0.08,1.9,4.2,"#7E858C",M4.translation(-0.30,2.2,z));
    lagg(panel,null);
    S3.skyltNat=(RIDHUSINNE.skyltar||[]).map((s,i)=>{
      const b=new Bygge();
      b.panel(s.b,s.b*0.25,"#FFFFFF",
        M4.mul(M4.translation(-0.34,2.6,s.y),M4.rotY(Math.PI/2)));
      return {nat:GL.nat(b), tex:T.skyltar[i]};
    });
    /* Dressyrbokstäverna på sargen. */
    S3.bokstavNat=DRESSYRBOKSTAVER.map(b=>{
      const bb=new Bygge();
      let mat;
      if(b.x===0)      mat=M4.mul(M4.translation(0.10,0.95,b.y),M4.rotY(Math.PI/2));
      else if(b.x===20)mat=M4.mul(M4.translation(19.90,0.95,b.y),M4.rotY(-Math.PI/2));
      else if(b.y===0) mat=M4.mul(M4.translation(b.x,0.95,0.10),M4.rotY(Math.PI));
      else             mat=M4.translation(b.x,0.95,59.90);
      bb.panel(0.55,0.55,"#FFFFFF",mat);
      return {nat:GL.nat(bb), tex:T.bokstav[b.b]};
    });
  }else{
    /* Utomhus: gräsmark, banunderlag och skogsbryn. */
    const mark=new Bygge().yta(400,400,"#FFFFFF",M4.translation(10,0,30),80);
    lagg(mark,T.gras);
    if(plats==="utebana"){
      const sand=new Bygge().yta(22,62,"#FFFFFF",M4.translation(10,0.03,30),8);
      lagg(sand,T.sand);
      const stak=new Bygge();
      const post=(x,z)=>stak.lada(0.12,1.30,0.12,"#D8CCB8",M4.translation(x,0.65,z));
      for(let z=0;z<=60;z+=4){post(-0.6,z);post(20.6,z);}
      for(let x=0;x<=20;x+=4){post(x,-0.6);post(x,60.6);}
      const regel=(x0,z0,x1,z1,y)=>{
        const dx=x1-x0,dz=z1-z0,len=Math.hypot(dx,dz),vin=Math.atan2(dz,dx);
        stak.lada(len,0.10,0.05,"#E0D4C0",
          M4.mul(M4.translation((x0+x1)/2,y,(z0+z1)/2),M4.rotY(-vin)));
      };
      for(const y of [0.62,1.16]){
        regel(-0.6,-0.6,20.6,-0.6,y); regel(-0.6,60.6,20.6,60.6,y);
        regel(-0.6,-0.6,-0.6,60.6,y); regel(20.6,-0.6,20.6,60.6,y);
      }
      lagg(stak,T.tra);
      /* Anläggningen i fonden: ridhuset och stallet i falurött. */
      const byggn=new Bygge();
      byggn.lada(26,6.4,66,"#6E1F1D",M4.translation(52,3.2,26));
      byggn.lada(27,0.4,68,"#3A3E44",M4.translation(52,6.6,26));
      byggn.lada(15,3.6,54,"#7C2A24",M4.translation(86,1.8,30));
      byggn.lada(16,0.4,56,"#7E8288",M4.translation(86,3.9,30));
      lagg(byggn,null);
    }else{
      /* Skogsstigen: grusvägen längs spåret. */
      const stig=new Bygge();
      const band=(x0,z0,x1,z1,br)=>{
        const dx=x1-x0,dz=z1-z0,len=Math.hypot(dx,dz),vin=Math.atan2(dz,dx);
        stig.lada(len+br,0.06,br,"#FFFFFF",
          M4.mul(M4.translation((x0+x1)/2,0.03,(z0+z1)/2),M4.rotY(-vin)));
      };
      band(1.5,1.5,18.5,1.5,3.2); band(18.5,1.5,18.5,58.5,3.2);
      band(18.5,58.5,1.5,58.5,3.2); band(1.5,58.5,1.5,1.5,3.2);
      lagg(stig,T.grus);
    }
    /* Träden. */
    const skog=new Bygge();
    const TF=["#4E6B33","#C1762F","#B0512E","#C99B3A","#54703A","#A8622C"];
    let fro=7;
    const rnd=()=>{fro=(fro*16807)%2147483647;return fro/2147483647;};
    const trad=(x,z,h,f)=>{
      skog.cyl(0.20,0.13,h*0.42,"#4A3A28",M4.translation(x,0,z),7);
      skog.klot(1,f,M4.mul(M4.translation(x,h*0.62,z),M4.skala(h*0.36,h*0.42,h*0.36)),10);
      skog.klot(1,f,M4.mul(M4.translation(x+h*0.10,h*0.85,z),M4.skala(h*0.24,h*0.26,h*0.24)),9);
    };
    const tat=plats==="stig"?46:22;
    for(let i=0;i<tat;i++){
      const kant=i%4;
      let x,z;
      if(kant===0){x=-4-rnd()*16; z=-10+rnd()*82;}
      else if(kant===1){x=24+rnd()*16; z=-10+rnd()*82;}
      else if(kant===2){x=-14+rnd()*48; z=-6-rnd()*14;}
      else {x=-14+rnd()*48; z=66+rnd()*14;}
      trad(x,z,5+rnd()*4.5,TF[Math.floor(rnd()*TF.length)]);
    }
    lagg(skog,null);
  }
  S3.plats=plats;
  S3.vaderNyckel=(G.vader&&G.vader.typ)||"sol";
  if(typeof V3D!=="undefined")V3D.plats=null;   // gå-lägets nät är frigjorda
}

/* ── Hindren ──────────────────────────────────────────────────── */
function s3RitaHinder(){
  const D=S3.del;
  for(const h of BANA.hinder){
    const riven=G.rivna.has(h.nr), nasta=G.nastaHinder===h.nr;
    const L=2.0, dx=Math.cos(h.rot+Math.PI/2)*L, dz=Math.sin(h.rot+Math.PI/2)*L;
    const H=BANA.hojd;
    for(const s of [-1,1]){        // stöden
      const x=h.x+dx*s, z=h.y+dz*s;
      const m=M4.mul(M4.translation(x,(H+0.35)/2,z),M4.skala(1,H+0.35,1));
      GL.rita(D.stod,m,{});
      GL.skugga(D.stod,m,0);
    }
    const bom=(y,farg,fall)=>{
      const a=[h.x-dx,y,h.y-dz], b=[h.x+dx,y,h.y+dz];
      const m=fall
        ? s3Segment([a[0],0.06,a[2]+0.35],[b[0],0.06,b[2]+0.42],1)
        : s3Segment(a,b,1);
      GL.rita(D.bom,m,{ton:farg});
      GL.skugga(D.bom,m,0);
    };
    if(riven)bom(0.06,"#7A5A50",true);
    else{
      bom(H,nasta?"#E7C86B":"#D6AE3C");
      bom(H*0.55,"#E6E4DE");
      if(h.typ==="oxer")bom(H*0.98,"#E6E4DE");
    }
  }
}

/* ── Kameran: bakom hästen, mjukt efterföljande ───────────────── */
function s3Kamera(dt){
  const fram=[Math.cos(G.rikt),0,Math.sin(G.rikt)];
  const hojd=G.luft>0?3.35:3.05, bak=G.luft>0?7.6:7.0;
  const mx=G.px-fram[0]*bak, mz=G.py-fram[2]*bak;
  const k=S3.kam;
  if(!k.satt){k.x=mx;k.y=hojd;k.z=mz;k.tx=G.px;k.ty=1.35;k.tz=G.py;k.satt=true;}
  const f=1-Math.pow(0.0016,Math.min(dt,0.05));   // ramtidsoberoende mjukhet
  k.x+=(mx-k.x)*f; k.y+=(hojd-k.y)*f; k.z+=(mz-k.z)*f;
  k.tx+=((G.px+fram[0]*3.4)-k.tx)*f;
  k.ty+=((1.52+(G.luft>0?0.7:0))-k.ty)*f;
  k.tz+=((G.py+fram[2]*3.4)-k.tz)*f;
  return k;
}

/* ── Bildrutan ────────────────────────────────────────────────── */
let s3Sist=0;
function rita3D(Gs){
  if(S3.trasig)return false;
  if(!S3.redo){
    if(S3.forsokt)return false;
    S3.forsokt=true;
    const c=document.getElementById("gl");
    if(!c||!GL.init(c)){S3.trasig=true;return false;}
    S3.canvas=c;
    try{ s3Texturer(); s3BygHast(); }
    catch(e){console.warn("3D-uppbyggnad misslyckades:",e);S3.trasig=true;return false;}
    S3.redo=true;
  }
  const nu=performance.now(), dt=s3Sist?Math.min((nu-s3Sist)/1000,0.1):0.016;
  s3Sist=nu;
  const plats=G.plats||"ridhus";
  const vader=(G.vader&&G.vader.typ)||"sol";
  if(S3.plats!==plats||S3.vaderNyckel!==vader)s3ByggPlats(plats);
  const L=s3Ljus();
  GL.start(CW,CH,DPR,L);
  const k=s3Kamera(dt);
  GL.kamera([k.x,k.y,k.z],[k.tx,k.ty,k.tz],1.02);
  /* Himlen först, utan djup. */
  const gl=GL.gl;
  gl.depthMask(false);
  GL.rita(S3.himmel.nat,M4.translation(k.x-S3.himmelC[0],0,k.z-S3.himmelC[1]),{platt:true,baksidor:true});
  gl.depthMask(true);
  /* Anläggningen. */
  for(const s of S3.statiskt)GL.rita(s.nat,M4.ny(),{tex:s.tex});
  if(plats==="ridhus"){
    for(const s of (S3.skyltNat||[]))GL.rita(s.nat,M4.ny(),{tex:s.tex,baksidor:true});
    for(const s of (S3.bokstavNat||[]))GL.rita(s.nat,M4.ny(),{tex:s.tex,baksidor:true});
    /* Publiken på läktaren. */
    const antal=G.tavling?14:3, steg=G.tavling?2.2:7.5, z0=G.tavling?16:22;
    const kul=["#8A4A3A","#3E5C74","#6B5E3C","#4E6B4A"];
    for(let i=0;i<antal;i++)
      GL.rita(S3.del.person,M4.mul(M4.translation(21.6+(i%2)*1.05,0.5+(i%2)*0.45,z0+i*steg),
        M4.skala(1)),{ton:kul[i%4]});
  }
  if(G.hinderAktiva)s3RitaHinder();
  /* NPC-ekipagen. */
  for(const n of G.npcs)
    s3RitaHast({hast:HORSES[n.hast]||{typ:"hast",farg:n.farg,man:"#2B1E15"},
      x:n.x, z:n.y, rikt:n.rikt, gangart:G.scen==="bana"?"halt":"trav",
      fas:(G.t*1.4+n.s*0.1)%1, sadel:true, ryttare:true, skugga:true,
      aids:{sits:0.5,tygel:0.35,lattridning:true}, samling:0.35});
  /* Din häst. */
  const h=HORSES[G.hastId];
  if(h)s3RitaHast({hast:h, x:G.px, z:G.py, rikt:G.rikt,
    gangart:G.ride?G.ride.gangart:"halt", fas:G.gaitFas, luft:G.luft,
    sadel:true, ryttare:true, skugga:true, aids:G.aids,
    samling:G.ride?clamp(G.ride.skala.samling*0.6+G.ride.skala.kontakt*0.4,0,1):0.4});
  /* Regnet ritas av 2D-lagret ovanpå. */
  return true;
}

/* Växlar mellan WebGL-lagret och den handrullade vyn. */
function gl3dLage(pa){
  const app=document.getElementById("app");
  if(app&&app.classList.contains("gl3d")!==!!pa)app.classList.toggle("gl3d",!!pa);
}
/* Tredjepersonsvyn: äkta 3D när kortet räcker, annars målarvyn. */
function draw3D(Gs){
  if(rita3D(Gs)){
    gl3dLage(true);
    cx.clearRect(0,0,CW,CH);
    if(G.plats!=="ridhus"&&G.vader&&G.vader.typ==="regn"){
      cx.strokeStyle="rgba(190,200,210,.26)";cx.lineWidth=1;
      const off=(G.t*640)%CH;
      cx.beginPath();
      for(let i=0;i<70;i++){
        const rx=(i*97+i*i*13)%CW, ry=((i*173)%CH+off)%CH;
        cx.moveTo(rx,ry);cx.lineTo(rx-3,ry+14);
      }
      cx.stroke();
    }
    return;
  }
  gl3dLage(false);
  draw3DCanvas(Gs);
}
