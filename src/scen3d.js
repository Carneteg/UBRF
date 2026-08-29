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
  plats:null, rum:null, statiskt:[], hinderNat:null, stolpNat:null,
  del:{}, tex:{},
  kam:{x:10,y:2.6,z:52, tx:10,ty:1.4,tz:46, satt:false},
};

/* ── Ljussättning per plats och väder ─────────────────────────── */
function s3Ljus(over){
  /* Alla värden bor i src/ljus.js — justera dem där. */
  return ljusFor(over||G.plats, (G.vader&&G.vader.typ)||"sol");
}

/* ── Texturer, målade i spelet ────────────────────────────────── */
function s3Texturer(){
  const T=S3.tex;
  T.sand=glCanvasTex(256,256,(c,w,h)=>{
    c.fillStyle=MARKFARG.sand;c.fillRect(0,0,w,h);
    for(let i=0;i<2600;i++){
      const x=Math.random()*w,y=Math.random()*h,r=Math.random();
      c.fillStyle=r<0.5?glTonRGBA(MARKFARG.sandMork,.32)
        :r<0.82?glTonRGBA(MARKFARG.sandLjus,.34):"rgba(120,98,58,.26)";
      c.fillRect(x,y,1+Math.random()*2,1+Math.random()*2);
    }
    c.strokeStyle=glTonRGBA(MARKFARG.sandMork,.26);c.lineWidth=1.5;  // harvspåren
    for(let i=0;i<16;i++){c.beginPath();c.moveTo(0,i*16+4);c.lineTo(w,i*16+4);c.stroke();}
  },true);
  T.gras=glCanvasTex(256,256,(c,w,h)=>{
    c.fillStyle=MARKFARG.gras;c.fillRect(0,0,w,h);
    for(let i=0;i<3200;i++){
      const x=Math.random()*w,y=Math.random()*h,r=Math.random();
      c.fillStyle=r<0.46?glTonRGBA(MARKFARG.grasLjus,.34)
        :r<0.92?glTonRGBA(MARKFARG.grasMork,.30):"rgba(255,255,255,.07)";
      c.fillRect(x,y,2,2+Math.random()*4);
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
  /* Dressyrbokstäverna på sargen — två små skyltar bredvid varandra,
     bilden till vänster och bokstaven till höger, precis som i verkligheten. */
  T.bokstav={};
  for(const b of DRESSYRBOKSTAVER) if(!T.bokstav[b.b])
    T.bokstav[b.b]=glCanvasTex(256,128,(c,w,h)=>{
      c.clearRect(0,0,w,h);
      const skylt=(x0,x1)=>{
        c.fillStyle="#F6F2E8";c.fillRect(x0,10,x1-x0,h-20);
        c.strokeStyle="#4A4E52";c.lineWidth=4;c.strokeRect(x0+2,12,x1-x0-4,h-24);
      };
      skylt(4,118); skylt(138,252);
      s3BokstavsBild(c,b.bild,61,64,84);
      c.fillStyle="#2E3238";c.textAlign="center";c.textBaseline="middle";
      c.font='700 82px Petrona, Georgia, serif';
      c.fillText(b.b,195,68);
    });
}

/* ── Bildgåtorna ──────────────────────────────────────────────────
   Ritade som få, feta former: de ska läsas på tio meters håll i ett
   ridhus, inte granskas. Mitt i (x,y), ungefär s stor. */
function s3BokstavsBild(c,id,x,y,s){
  const r=s/2, F=(f,fn)=>{c.fillStyle=f;c.beginPath();fn();c.fill();};
  switch(id){
    case"banan":
      F("#F2C53D",()=>{c.arc(x,y-r*0.15,r*0.92,0.25*Math.PI,0.95*Math.PI);
        c.arc(x,y+r*0.30,r*0.92,0.95*Math.PI,0.25*Math.PI,true);});
      break;
    case"morot":
      F("#E2801E",()=>{c.moveTo(x-r*0.42,y-r*0.35);c.lineTo(x+r*0.42,y-r*0.35);c.lineTo(x,y+r*0.92);});
      F("#4E9B3A",()=>{c.moveTo(x-r*0.45,y-r*0.42);c.lineTo(x,y-r*0.95);c.lineTo(x+r*0.45,y-r*0.42);});
      break;
    case"cykel":
      c.strokeStyle="#2E3238";c.lineWidth=s*0.10;
      for(const d of [-1,1]){c.beginPath();c.arc(x+d*r*0.52,y+r*0.22,r*0.44,0,7);c.stroke();}
      c.beginPath();c.moveTo(x-r*0.52,y+r*0.22);c.lineTo(x,y-r*0.42);
      c.lineTo(x+r*0.52,y+r*0.22);c.stroke();
      break;
    case"fisk":
      F("#3E7FB8",()=>{c.ellipse(x+r*0.10,y,r*0.70,r*0.45,0,0,7);});
      F("#3E7FB8",()=>{c.moveTo(x-r*0.55,y);c.lineTo(x-r*0.98,y-r*0.45);c.lineTo(x-r*0.98,y+r*0.45);});
      F("#F6F2E8",()=>{c.arc(x+r*0.45,y-r*0.12,r*0.10,0,7);});
      break;
    case"ananas":
      F("#E8B93C",()=>{c.ellipse(x,y+r*0.22,r*0.52,r*0.68,0,0,7);});
      F("#4E9B3A",()=>{c.moveTo(x-r*0.50,y-r*0.38);c.lineTo(x,y-r*0.98);c.lineTo(x+r*0.50,y-r*0.38);});
      break;
    case"elefant":
      F("#8E96A0",()=>{c.ellipse(x-r*0.10,y+r*0.05,r*0.62,r*0.50,0,0,7);});
      F("#8E96A0",()=>{c.ellipse(x-r*0.62,y-r*0.10,r*0.34,r*0.38,0,0,7);});
      c.strokeStyle="#8E96A0";c.lineWidth=s*0.13;c.beginPath();
      c.moveTo(x-r*0.80,y+r*0.10);c.quadraticCurveTo(x-r*1.00,y+r*0.70,x-r*0.62,y+r*0.86);c.stroke();
      break;
    case"hus":
      F("#B0332E",()=>{c.rect(x-r*0.52,y-r*0.12,r*1.04,r*0.94);});
      F("#3A3E44",()=>{c.moveTo(x-r*0.72,y-r*0.12);c.lineTo(x,y-r*0.86);c.lineTo(x+r*0.72,y-r*0.12);});
      break;
    case"katt":
      F("#E09A3E",()=>{c.arc(x,y+r*0.14,r*0.60,0,7);});
      for(const d of [-1,1])F("#E09A3E",()=>{c.moveTo(x+d*r*0.18,y-r*0.34);
        c.lineTo(x+d*r*0.62,y-r*0.92);c.lineTo(x+d*r*0.66,y-r*0.20);});
      F("#2E3238",()=>{c.arc(x-r*0.22,y+r*0.02,r*0.09,0,7);});
      F("#2E3238",()=>{c.arc(x+r*0.22,y+r*0.02,r*0.09,0,7);});
      break;
    case"sol":
      F("#F0C24A",()=>{c.arc(x,y,r*0.50,0,7);});
      c.strokeStyle="#F0C24A";c.lineWidth=s*0.09;
      for(let i=0;i<8;i++){const a=i*Math.PI/4;c.beginPath();
        c.moveTo(x+Math.cos(a)*r*0.66,y+Math.sin(a)*r*0.66);
        c.lineTo(x+Math.cos(a)*r*0.95,y+Math.sin(a)*r*0.95);c.stroke();}
      break;
    case"vante":
      F("#B0332E",()=>{c.roundRect?c.roundRect(x-r*0.40,y-r*0.55,r*0.80,r*1.15,r*0.30)
        :c.rect(x-r*0.40,y-r*0.55,r*0.80,r*1.15);});
      F("#B0332E",()=>{c.ellipse(x-r*0.58,y+r*0.10,r*0.22,r*0.34,0,0,7);});
      F("#F6F2E8",()=>{c.rect(x-r*0.46,y+r*0.42,r*0.92,r*0.22);});
      break;
    case"paron":
      F("#9BB84A",()=>{c.ellipse(x,y+r*0.32,r*0.52,r*0.60,0,0,7);});
      F("#9BB84A",()=>{c.ellipse(x,y-r*0.28,r*0.34,r*0.40,0,0,7);});
      c.strokeStyle="#6B4A34";c.lineWidth=s*0.08;c.beginPath();
      c.moveTo(x,y-r*0.62);c.lineTo(x+r*0.12,y-r*0.96);c.stroke();
      break;
    case"ros":
      F("#C8404E",()=>{c.arc(x,y-r*0.18,r*0.48,0,7);});
      F("#E8737E",()=>{c.arc(x,y-r*0.18,r*0.24,0,7);});
      c.strokeStyle="#4E9B3A";c.lineWidth=s*0.09;c.beginPath();
      c.moveTo(x,y+r*0.28);c.lineTo(x,y+r*0.95);c.stroke();
      F("#4E9B3A",()=>{c.ellipse(x+r*0.30,y+r*0.60,r*0.26,r*0.13,0,0,7);});
      break;
    default:
      F("#8E96A0",()=>{c.arc(x,y,r*0.5,0,7);});
  }
}

/* ── Ryttarens delar ──────────────────────────────────────────────
   Bryts ut ur hästbygget för att de ska kunna byggas om ensamma: byter
   du färg i skaparrutan är det bara de här näten som ska ersättas, inte
   hela hästen. Färgerna kommer ur ryttarprofilen (jag.js) — samma
   källa som klossläget läser, så de två kan aldrig glida isär. */
const RYTTARDELAR=["bal","torso","arm","lar","vad","stovel","huvudR","har","hjalm"];
const RYTTARE_NORM={kavaj:"#33465F",byxa:"#D6C9AE",hy:"#E0B490",har:"#6B4526",
  hjalm:"#23282F",stovel:"#1E1A16",klubb:"#3E6B47",harstil:"svans"};

/* Anropas två gånger: en gång för de andra eleverna i ridhuset, som ska
   se ut som de alltid gjort, och en gång för dig. Näten är små, så två
   uppsättningar kostar mindre än att göra din färg till allas. */
function s3BygRyttare(){
  const D=S3.del;
  s3BygRyttarSet(D, RYTTARE_NORM);
  D.jag=D.jag||{};
  s3BygRyttarSet(D.jag,
    (typeof jagFarg==="function")?jagFarg():RYTTARE_NORM);
}
function s3BygRyttarSet(D,J0){
  const lp=STIL==="kloss", nyNat=b=>GL.nat(lp?glPlatta(b):b);
  const J={...J0};
  J.hjalmMork=(typeof jagMorkare==="function")?jagMorkare(J.hjalm,0.14):J.hjalm;
  /* I klossläget är ryttaren rätblock, inte svepta ytor. Samma lokala
     rum, så riggen nedan ritar dem utan att veta om bytet. */
  if(lp&&typeof klossRyttarDelar==="function"){ klossRyttarDelar(D,J); return; }
  /* Ryttaren: ridkavaj, ljusa ridbyxor, långa stövlar och hjälm med
     hästsvans — samma siluett som en elev på ridskolan. */
  D.bal=nyNat(new Bygge().klot(1,J.byxa,M4.skala(0.165,0.125,0.185),11));
  D.torso=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,J.kavaj,M4.mul(M4.translation(0,-0.02,0),M4.skala(0.125,0.215,0.155)),13);
    b.klot(1,J.kavaj,M4.mul(M4.translation(-0.01,0.15,0),M4.skala(0.135,0.105,0.185)),12);
    b.klot(1,"#F4F1E8",M4.mul(M4.translation(0.02,0.235,0),M4.skala(0.075,0.045,0.085)),9);
    b.klot(0.062,J.hy,M4.translation(0.01,0.27,0),9);          // halsen
    return b;})());
  D.arm=nyNat(new Bygge().cyl(0.044,0.038,1,J.kavaj,null,11));
  D.lar=nyNat(new Bygge().cyl(0.078,0.058,1,J.byxa,null,11));
  D.vad=nyNat(new Bygge().cyl(0.056,0.048,1,J.stovel,null,11));
  D.stovel=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,J.stovel,M4.mul(M4.translation(0.02,0,0),M4.skala(0.115,0.052,0.062)),10);
    return b;})());
  D.huvudR=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,J.hy,M4.skala(0.098,0.115,0.098),13);
    b.klot(1,J.hy,M4.mul(M4.translation(0.048,-0.048,0),M4.skala(0.042,0.052,0.058)),9);
    for(const s of [-1,1]){                                   // ögonen
      b.klot(1,"#FFFFFF",M4.mul(M4.translation(0.062,0.004,s*0.034),
        M4.skala(0.015,0.019,0.016)),7);
      b.klot(1,"#2B2118",M4.mul(M4.translation(0.072,0.002,s*0.035),
        M4.skala(0.010,0.013,0.011)),7);
    }
    b.klot(1,"#B9755E",M4.mul(M4.translation(0.082,-0.054,0),
      M4.skala(0.010,0.008,0.024)),6);                        // munnen
    return b;})());
  /* Håret: nacklugg under hjälmen, och därefter den valda frisyren.
     Hästsvansen faller längst, flätan smalnar av, kort hår slutar vid
     nacken och uppsatt syns bara som luggen. */
  D.har=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,J.har,M4.mul(M4.translation(-0.052,0.012,0),M4.skala(0.092,0.104,0.098)),12);
    const n={svans:5, flata:4, kort:2, uppsatt:0}[J.harstil];
    for(let i=0;i<(n===undefined?5:n);i++){
      const t=i/4, av=J.harstil==="flata"?(1-0.16*i):1;
      b.klot(1,J.har,M4.mul(M4.translation(-0.085-0.035*t*t,-0.055-0.115*t,0),
        M4.skala(0.055*av,0.070,0.062*av)),9);
    }
    return b;})());
  D.hjalm=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,J.hjalm,M4.mul(M4.translation(-0.014,0,0),
      M4.skala(0.114,0.082,0.110)),14);
    b.klot(1,J.hjalmMork,M4.mul(M4.translation(0.090,-0.012,0),
      M4.skala(0.076,0.012,0.086)),12);                        // skärmen
    b.klot(1,J.klubb,M4.mul(M4.translation(-0.03,0.062,0),
      M4.skala(0.070,0.026,0.080)),10);                        // klubbens färg
    return b;})());
}

/* ── Hästens delar. Byggs en gång i mankhöjd 1,60 m och skalas. ── */
function s3BygHast(){
  const D=S3.del, vit="#FFFFFF";
  /* Lågpolyläget: samma form, färre segment och plana ytnormaler.
     Förlagans hästar är inte klossiga — de är fasetterade. Anatomin är
     kvar in i minsta detalj, men varje polygon läser som ett eget plan
     eftersom ljuset bryts vid varje kant i stället för att glida över
     ytan. Det är fasetteringen som gör uttrycket, inte grovheten. */
  const lp=STIL==="kloss";
  const S=(hog,lag)=>lp?lag:hog;
  const nyNat=b=>GL.nat(lp?glPlatta(b):b);
  /* Måtten är en varmblodshäst på 1,62 m i mankhöjd: bålen 1,85 m
     lång, 0,72 m hög och 0,58 m bred, benen 1,08 m från bog till hov. */
  /* Bålen sveps i ett stycke: bringan smal och djup, gjordläget vidast,
     flanken indragen och korset runt igen. Ryggen är smalare än buken,
     så ryggraden syns som en linje i stället för som ett rör. */
  const ROND=(t,a,b)=>{                        // rundar av ändarna
    if(t<a)return Math.sqrt(Math.max(0,1-Math.pow((a-t)/a,2)));
    if(t>b)return Math.sqrt(Math.max(0,1-Math.pow((t-b)/(1-b),2)));
    return 1;
  };
  const KX=[[0,0.98],[0.22,0.60],[0.50,0.14],[0.78,-0.52],[1,-1.04]];
  const KTOPP=[[0,1.335],[0.10,1.450],[0.22,1.520],[0.42,1.478],[0.62,1.466],
               [0.80,1.516],[0.90,1.498],[1,1.420]];
  const KBUK=[[0,1.140],[0.10,1.030],[0.25,0.990],[0.50,1.000],[0.70,1.090],
              [0.85,1.200],[1,1.300]];
  const KBRE=[[0,0.105],[0.10,0.200],[0.22,0.266],[0.42,0.300],[0.60,0.296],
              [0.74,0.254],[0.85,0.296],[0.94,0.238],[1,0.115]];
  D.kropp=nyNat(s3Svep(new Bygge(),vit,S(30,17),S(16,10),(t,u)=>{
    const a=u*Math.PI*2, ca=Math.cos(a), sa=Math.sin(a);
    const r=ROND(t,0.045,0.965);
    const topp=s3Stn(t,KTOPP), buk=s3Stn(t,KBUK);
    const yc=(topp+buk)/2, h=(topp-buk)/2*r;
    const w=s3Stn(t,KBRE)*r*(1-0.28*Math.max(0,ca)*Math.max(0,ca));
    return [s3Stn(t,KX), yc+h*ca, w*sa];
  }));
  /* Halsen: djup och smal, med kam ovanpå och struphuvud under.
     Byggs i halsens eget rum, x 0→1 från manken till nacken. */
  D.hals=nyNat(s3Svep(new Bygge(),vit,S(18,10),S(13,8),(p,u)=>{
    const t=-0.12+1.18*p, a=u*Math.PI*2, ca=Math.cos(a), sa=Math.sin(a);
    const r=ROND(p,0.05,0.94);
    const topp=s3Stn(t,lp
      ?[[-0.12,0.21],[0.05,0.31],[0.45,0.270],[0.80,0.215],[1.06,0.160]]
      :[[-0.12,0.20],[0.05,0.30],[0.45,0.245],[0.80,0.175],[1.06,0.120]]);
    const buk=s3Stn(t,lp
      ?[[-0.12,-0.23],[0.05,-0.285],[0.40,-0.250],[0.75,-0.180],[1.06,-0.140]]
      :[[-0.12,-0.22],[0.05,-0.275],[0.40,-0.225],[0.75,-0.135],[1.06,-0.100]]);
    const bre=s3Stn(t,lp
      ?[[-0.12,0.21],[0.05,0.215],[0.45,0.185],[0.80,0.145],[1.06,0.118]]
      :[[-0.12,0.20],[0.05,0.205],[0.45,0.160],[0.80,0.108],[1.06,0.082]]);
    const yc=(topp+buk)/2, h=(topp-buk)/2*r;
    const w=bre*r*(1-0.34*Math.max(0,ca)*Math.max(0,ca));
    return [t, yc+h*ca, w*sa];
  }));
  /* Huvudet: pannben brett, käkpartiet tungt, nosen avsmalnande. */
  D.huvud=nyNat(s3Svep(new Bygge(),vit,S(18,10),S(13,7),(p,u)=>{
    const x=-0.32+0.68*p, a=u*Math.PI*2, ca=Math.cos(a), sa=Math.sin(a);
    const r=ROND(p,0.06,0.93);
    const topp=s3Stn(x,[[-0.32,0.075],[-0.20,0.135],[-0.05,0.126],[0.08,0.096],
                        [0.20,0.058],[0.36,0.046]]);
    const buk=s3Stn(x,[[-0.32,-0.075],[-0.20,-0.128],[-0.05,-0.156],[0.08,-0.163],
                       [0.20,-0.114],[0.36,-0.086]]);
    const bre=s3Stn(x,[[-0.32,0.072],[-0.20,0.106],[-0.05,0.114],[0.08,0.099],
                       [0.20,0.068],[0.36,0.059]]);
    const yc=(topp+buk)/2, h=(topp-buk)/2*r;
    return [x, yc+h*ca, bre*r*sa];
  }));
  D.ora=nyNat(new Bygge().cyl(0.038,0.004,0.14,vit,null,S(7,4)));
  D.overben=nyNat(new Bygge().cyl(S(0.078,0.096),S(0.058,0.072),1,vit,null,S(12,6)));
  D.skenben=nyNat(new Bygge().cyl(S(0.050,0.062),S(0.040,0.052),1,vit,null,S(12,6)));
  D.hov=nyNat(new Bygge().cyl(S(0.062,0.078),S(0.058,0.072),S(0.10,0.125),"#2E2A26",null,S(9,6)));
  D.svansrot=nyNat(new Bygge().cyl(0.085,0.075,1,vit,null,S(8,5)));
  D.svanstagel=nyNat(new Bygge().cyl(0.095,0.030,1,vit,null,S(8,5)));
  D.man=nyNat(new Bygge().lada(1,1,0.030,vit));
  /* Manen hänger som lockar, inte som en kam: varje lock är en smal
     avsmalnande sträng som faller längs halsens sida. */
  D.lock=nyNat(new Bygge().cyl(0.082,0.030,1,vit,null,S(9,4)));
  /* Manen byggs en gång som en hel matta i halsens eget rum: x går
     0→1 från manken till nacken, y uppåt, z ut åt sidan manen faller.
     Överlappande klot ger en sammanhängande massa i stället för en kam. */
  /* Manen i två lager: ett mörkare under och ett ljusare över, båda
     med skålad kant så att lockarna syns. */
  /* I lågpolyläget ligger manen tätt mot halsen som en kam med grova
     flikar, inte som ett draperi — det är så förlagan ser ut. */
  const mFall=lp?0.58:1, mFrek=lp?2.6:4.5, mTjock=lp?0.032:0.014;
  const manYta=(skal,djup)=>s3Yta(new Bygge(),vit,S(22,13),S(10,6),(t,v)=>{
    const r=0.215-0.108*t+0.020+djup;
    const kl=Math.min(v/0.26,1), th=-0.34+0.88*kl;
    const h=Math.max(0,v-0.26)/0.74;
    const lock=0.80+0.20*Math.cos(t*Math.PI*2*mFrek);   // lockarnas kant
    const fall=(0.15+0.16*Math.sin(t*Math.PI*0.85))
      *(1-0.45*Math.max(0,t-0.72)/0.28)*lock*skal*mFall;
    return [t+0.020*h*h,
            r*Math.cos(th)-fall*h*(1.30-0.30*h),
            r*Math.sin(th)+0.028*h*h+0.014*Math.sin(t*Math.PI*2*mFrek)*h];
  },mTjock);
  D.manunder=nyNat(manYta(0.86,0.0));
  D.manmatta=nyNat(manYta(1.0,0.026));
  /* Svanstageln: en tofs som faller från svansroten och smalnar av. */
  D.svansmassa=nyNat(lp
    ? s3Svep(new Bygge(),vit,9,6,(t,u)=>{
        const a=u*Math.PI*2;
        const w=(0.095+0.080*Math.sin(t*Math.PI*0.90))*(1-0.78*t*t);
        return [Math.cos(a)*w*0.85 - 0.10*t*t, -t*1.06, Math.sin(a)*w];
      })
    : s3Yta(new Bygge(),vit,10,12,(u,t)=>{
        const vin=u*Math.PI*2;
        const w=(0.105+0.075*Math.sin(t*Math.PI*0.85))*(1-t*t*0.92);
        return [Math.sin(vin)*w*0.80 - 0.16*t*t, -t*0.98, Math.cos(vin)*w];
      },0.010));
  /* Hovskägget — den tunga typens flikar över kotan. */
  D.fjader=nyNat(new Bygge().cyl(0.052,0.098,0.19,vit,null,S(12,6)));
  /* Strumpan måste vara GROVARE än skenbenet den läggs över. Radierna
     var fasta medan skenbenet går genom S(), som i klossläget väljer de
     tjockare lågpolytalen (0,062/0,052) — strumpan hamnade alltså inuti
     benet och syntes aldrig, på nio av sjutton hästar. */
  D.strumpa=nyNat(new Bygge().cyl(S(0.050,0.062)*1.10,S(0.040,0.052)*1.10,
    1,"#F2EFE6",null,S(10,6)));
  /* Kontaktskuggan: en platt skiva som läggs i tre storlekar med
     fallande täckning. En mjuk fläck kostar tjugo trianglar; en
     projicerad silhuett av hela hästen kostar tusentals. */
  D.skuggflack=nyNat(new Bygge().disk(1,"#FFFFFF",null,24));
  D.blas=nyNat(new Bygge().klot(1,"#F2EFE6",M4.skala(0.19,0.030,0.048),12));
  D.sadel=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,"#4A3526",M4.mul(M4.translation(0,0.03,0),M4.skala(0.26,0.075,0.20)),12);
    b.lada(0.56,0.028,0.48,"#3E6B47",M4.translation(-0.03,-0.05,0));  // grönt schabrak
    return b;})());
  D.tacke=nyNat(new Bygge().klot(1,"#7A2E33",M4.skala(0.90,0.38,0.33),14));
  s3BygRyttare();
  D.led=nyNat(new Bygge().klot(0.042,"#FFFFFF",null,9));
  D.hand=nyNat(new Bygge().klot(1,"#2B2620",M4.skala(0.046,0.050,0.038),9));
  D.rem=nyNat(new Bygge().cyl(0.012,0.012,1,"#241A12",null,S(5,4)));
  /* Hinder och stolpar. */
  D.bom=nyNat(new Bygge().cyl(0.055,0.055,1,vit,null,S(8,6)));
  D.stod=nyNat(new Bygge().lada(0.10,1,0.10,"#4A3F30"));
  /* Natur och staket. */
  D.stam=nyNat(new Bygge().cyl(0.16,0.11,1,"#4A3A28",null,S(7,5)));
  D.krona=nyNat(new Bygge().klot(1,vit,null,S(12,6)));
  D.pale=nyNat(new Bygge().lada(0.12,1,0.12,"#5A4633"));
  D.regel=nyNat(new Bygge().lada(1,0.10,0.05,"#6B5540"));
  D.person=nyNat((()=>{
    const b=new Bygge();
    b.klot(1,vit,M4.mul(M4.translation(0,0.55,0),M4.skala(0.19,0.32,0.17)),10);
    b.klot(0.13,"#D8B08C",M4.translation(0,0.98,0),10);
    return b;})());
  /* Klosstilen ersätter delarna i samma lokala rum, så riggen ovan
     ritar dem utan att veta om bytet. */
  if(STIL==="kloss")klossDelar(D);
}

/* Slät yta ur en punktfunktion f(t,v) — ger mjuka normaler och en
   tunn skiva åt båda håll. Manen och svansen ska läsas som hår, inte
   som ett pärlband av klot. */
function s3Yta(b,farg,nt,nv,f,tjock){
  const rut=[],nrm=[],P=[],N=[],U=[],I=[];
  for(let i=0;i<=nt;i++){const rad=[];
    for(let j=0;j<=nv;j++)rad.push(f(i/nt,j/nv));
    rut.push(rad);}
  for(let i=0;i<=nt;i++){const rad=[];
    for(let j=0;j<=nv;j++){
      const a=rut[Math.min(i+1,nt)][j], c=rut[Math.max(i-1,0)][j];
      const d=rut[i][Math.min(j+1,nv)], e=rut[i][Math.max(j-1,0)];
      const u=[a[0]-c[0],a[1]-c[1],a[2]-c[2]];
      const w=[d[0]-e[0],d[1]-e[1],d[2]-e[2]];
      let n=[u[1]*w[2]-u[2]*w[1], u[2]*w[0]-u[0]*w[2], u[0]*w[1]-u[1]*w[0]];
      const L=Math.hypot(n[0],n[1],n[2])||1;
      rad.push([n[0]/L,n[1]/L,n[2]/L]);}
    nrm.push(rad);}
  const tj=tjock===undefined?0.018:tjock;
  for(const sida of [1,-1]){
    const bas=P.length/3;
    for(let i=0;i<=nt;i++)for(let j=0;j<=nv;j++){
      const q=rut[i][j], n=nrm[i][j];
      P.push(q[0]+n[0]*tj*sida, q[1]+n[1]*tj*sida, q[2]+n[2]*tj*sida);
      N.push(n[0]*sida, n[1]*sida, n[2]*sida);
      U.push(i/nt, j/nv);}
    for(let i=0;i<nt;i++)for(let j=0;j<nv;j++){
      const a=bas+i*(nv+1)+j, c=a+1, d=a+nv+1, e=d+1;
      if(sida>0)I.push(a,d,e, a,e,c); else I.push(a,e,d, a,c,e);}
  }
  return b.las(P,N,U,I,farg,null);
}

/* ── Svepta kroppar ───────────────────────────────────────────────
   Ett djur är inte staplade klot. s3Svep bygger en sluten, solid yta
   av ringar längs en led: f(t,u) ger punkten där t går längs kroppen
   och u varvet runt. Normalerna räknas ur grannringarna, så ytan blir
   len över hela längden — bog, buk och kors i ett stycke.
   Ringarna måste smalna av mot noll i båda ändarna; då sluter sig
   kroppen av sig själv. ── */
function s3Svep(b,farg,nt,nu,f){
  const rut=[],P=[],N=[],U=[],I=[];
  for(let i=0;i<=nt;i++){const rad=[];
    for(let j=0;j<=nu;j++)rad.push(f(i/nt, j/nu));
    rut.push(rad);}
  for(let i=0;i<=nt;i++)for(let j=0;j<=nu;j++){
    const q=rut[i][j];
    const a=rut[Math.min(i+1,nt)][j], c=rut[Math.max(i-1,0)][j];
    const d=rut[i][(j+1)%nu], e=rut[i][(j-1+nu)%nu];
    const t=[a[0]-c[0],a[1]-c[1],a[2]-c[2]];
    const w=[d[0]-e[0],d[1]-e[1],d[2]-e[2]];
    let n=[t[1]*w[2]-t[2]*w[1], t[2]*w[0]-t[0]*w[2], t[0]*w[1]-t[1]*w[0]];
    let L=Math.hypot(n[0],n[1],n[2]);
    if(L<1e-9){n=[0,1,0];L=1;}
    P.push(q[0],q[1],q[2]); N.push(n[0]/L,n[1]/L,n[2]/L); U.push(i/nt, j/nu);
  }
  for(let i=0;i<nt;i++)for(let j=0;j<nu;j++){
    const a=i*(nu+1)+j, c=a+1, d=a+nu+1, e=d+1;
    I.push(a,d,e, a,e,c);
  }
  return b.las(P,N,U,I,farg,null);
}
/* Linjär tolkning över stationer [[t,v],…] — kroppens mått anges
   där de betyder något: bog, gjordläge, flank, kors. */
function s3Stn(t,st){
  if(t<=st[0][0])return st[0][1];
  for(let i=1;i<st.length;i++){
    if(t<=st[i][0]){
      const a=st[i-1], b=st[i], k=(t-a[0])/Math.max(b[0]-a[0],1e-6);
      const s=k*k*(3-2*k);                       // mjuk övergång
      return a[1]+(b[1]-a[1])*s;
    }
  }
  return st[st.length-1][1];
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
    t2=0.12+(bak?0.78:0.62)*Math.sin(Math.PI*u);
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
  /* Kroppens rörelse: takten lyfter, galoppen vaggar, språnget stiger.
     Det här är gångartens egen rytm, räknad ur fasen — den ska hållas
     skild från svängens lutning nedan, annars går det inte att trimma
     den ena utan att den andra ändras. */
  let bob=0,lut=0;
  if(gangart==="trav")bob=0.035*Math.sin(4*Math.PI*fas);
  else if(gangart==="galopp"){bob=0.06*Math.sin(2*Math.PI*fas);lut=0.07*Math.sin(2*Math.PI*fas);}
  else if(gangart==="skritt")bob=0.018*Math.sin(4*Math.PI*fas);
  if(luft>0){bob+=1.15*bage; lut-=0.52*Math.cos(Math.PI*u);}

  /* ── Svängens lutning ─────────────────────────────────────────────
     Kroppen lade sig inte i svängen: positionen böjde av medan hästen
     såg neutral ut, och det är en av de tydligaste sakerna som får en
     ridning att läsa som ett fordon.

     Signalen är centripetalkraften — kurvatur gånger tempo i kvadrat,
     alltså samma storhet som faktiskt drar i en kropp i en böj — inte
     rå knappinput. Låg fart ger då nästan ingen lutning, och trav och
     galopp ger tydlig men kontrollerad. Klampningen finns för att en
     häst inte lägger sig som en motorcykel: fyra grader är mycket på en
     häst, och mer läser som fel. */
  const banLut=o.banlut||0;

  /* Grundmatris: position, riktning (hästen är byggd mot +X), skala.
     Svängens lutning är en rullning kring färdriktningen och läggs som
     en egen rotation efter kursen, så att den inte blandas ihop med
     gångartens vaggning. */
  const bas=M4.mul(
    M4.mul(M4.translation(o.x,bob*M,o.z), M4.rotY(-o.rikt)),
    M4.mul(M4.mul(M4.rotX(banLut), M4.rotZ(lut)), M4.skala(M)));
  const P=(x,y,z)=>[x,y,z];                              // lokala punkter
  const rita=(nat,mat,ton)=>{ gl.rita(nat,M4.mul(bas,mat),{ton}); };
  /* Skuggan läggs en gång för hela ekipaget, som en mjuk fläck under
     buken — inte som en projicerad silhuett per kroppsdel. */
  if(o.skugga)s3Skuggflack(o.x,o.z,1.05*M,1-Math.min(luft/0.55,1)*0.55);

  /* Bålen — en enda svept kropp, redan i hästens egna mått. */
  rita(D.kropp,M4.ny(),farg);
  /* Halsen: reser sig när hästen samlas, sträcks på lång tygel. */
  const samling=o.samling===undefined?0.4:o.samling;
  const halsA=P(0.84,1.34,0), halsL=0.88+0.07*(1-samling);
  /* Betande häst sänker halsen till marken; annars styr samlingen. */
  const halsVin=o.beta ? -0.72
    : 0.55+0.55*samling+(luft>0?0.25*Math.cos(Math.PI*u):0);
  const halsB=P(halsA[0]+Math.cos(halsVin)*halsL, halsA[1]+Math.sin(halsVin)*halsL, 0);
  const halsM=M4.mul(M4.mul(M4.translation(halsA[0],halsA[1],0),M4.rotZ(halsVin)),
    M4.skala(halsL,1,1));
  rita(D.hals,halsM,farg);
  /* Huvudet följer halsens vinkel, nosen något nedåt. */
  const nick=o.beta ? -1.15 : halsVin-0.95-0.25*samling;
  const huvudM=M4.mul(M4.translation(halsB[0]+Math.cos(nick)*0.19,
    halsB[1]+Math.sin(nick)*0.19-0.02,0), M4.rotZ(nick));
  rita(D.huvud,huvudM,farg);
  for(const s of [-1,1])
    rita(D.ora,M4.mul(M4.mul(huvudM,M4.translation(-0.10,0.10,s*0.085)),
      M4.rotZ(-0.25*s*0+0.15)),glMorka(farg,0.9));
  if(h.tecken&&h.tecken.blas)     // bläsen längs nosryggen
    rita(D.blas,M4.mul(huvudM,M4.translation(0.07,0.105,0)),"#FFFFFF");
  /* Tränset: nosgrimma, kindstycke och pannband i läder. */
  if(o.sadel){
    const HP=(x,y,z)=>{
      const m=M4.mul(huvudM,M4.translation(x,y,z));
      return [m[12],m[13],m[14]];
    };
    for(const s of [-1,1]){
      rita(D.rem,s3Segment(HP(0.04,0.09,s*0.085),HP(0.04,-0.09,s*0.075),1.6),"#6B4A2E");
      rita(D.rem,s3Segment(HP(-0.16,0.11,s*0.09),HP(0.05,0.05,s*0.10),1.5),"#6B4A2E");
    }
    rita(D.rem,s3Segment(HP(0.04,0.10,-0.085),HP(0.04,0.10,0.085),1.5),"#6B4A2E");
    rita(D.rem,s3Segment(HP(-0.17,0.12,-0.09),HP(-0.17,0.12,0.09),1.5),"#6B4A2E");
  }
  /* Manen: en sammanhängande matta som följer halsen. */
  {
    const sv=Math.sin(fas*Math.PI*2)*0.05*(gangart==="halt"?0.2:1);
    const mm=M4.mul(M4.mul(M4.mul(
      M4.translation(halsA[0],halsA[1],0), M4.rotZ(halsVin)),
      M4.rotX(sv)), M4.skala(halsL,1,1));
    rita(D.manunder,mm,glMorka(man,0.72));
    rita(D.manmatta,mm,man);
  }
  /* Pannlugg mellan öronen. */
  for(const d of [-1,0,1]){
    const lp=[halsB[0]+Math.cos(nick)*0.10, halsB[1]+Math.sin(nick)*0.10+0.05, d*0.045];
    rita(D.lock,s3Segment(lp,[lp[0]+0.16,lp[1]-0.20,d*0.05],0.8),man);
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
    const tecken=h.tecken||{};
    if(tecken.strumpor&&tecken.strumpor[i])
      rita(D.strumpa,s3Segment([kna[0],kna[1]-0.10,kna[2]],kota,1),"#FFFFFF");
    if(h.fjader)   // hovskägget faller över kotan
      rita(D.fjader,M4.translation(kota[0],kota[1]-0.17,kota[2]),
        tecken.strumpor&&tecken.strumpor[i]?"#F6F3EA":glMorka(man,1.0));
    rita(D.hov,M4.translation(kota[0],kota[1]-0.10,kota[2]),"#FFFFFF");
  }
  /* Svansen. */
  const svSv=Math.sin(fas*Math.PI*2)*0.09*(gangart==="halt"?0.2:1);
  const rotA=P(-1.00,1.48,0), rotB=P(-1.13,1.30,svSv*0.12);
  rita(D.svansrot,s3Segment(rotA,rotB,1),farg);          // svansroten bär pälsens färg
  rita(D.svansmassa,M4.mul(M4.translation(rotB[0],rotB[1]+0.02,0),
    M4.rotZ(svSv*0.35)),man);
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

/* Mjuk kontaktskugga på marken. Fem ringar av en SKIVA med fallande
   täckning — förut var det tre fyrkanter, och tre staplade rutor på
   marken läser sämre än ingen skugga alls.

   Den innersta ringen låg dessutom på 0,16 × 0,42 = 6,7 % alfa, alltså
   osynlig. Kontaktskuggan är det enskilt starkaste tecknet på att något
   står på marken i stället för att sväva; den ska synas.

   Solens riktning skjuter fläcken något åt sidan, och ringarna glider
   med — så skuggan tänjs åt det håll ljuset faller. */
function s3Skuggflack(x,z,r,styrka){
  const D=S3.del, L=GL.ljus; if(!D.skuggflack||!L)return;
  const sl=Math.hypot(L.sol[0],L.sol[1],L.sol[2])||1;
  const dx=-L.sol[0]/sl*0.45, dz=-L.sol[2]/sl*0.45;
  const gl=GL.gl, a=(L.skuggAlfa===undefined?0.22:L.skuggAlfa)*(styrka===undefined?1:styrka);
  gl.enable(gl.BLEND); gl.depthMask(false);
  /* Ringarna syntes som band: fem skivor med rejäla alfasteg ritar fem
     synliga kanter på marken. Fler ringar med mindre steg gör samma
     avtoning utan att man ser trappan. */
  const ringar=[];
  for(let i=0;i<9;i++){
    const t=i/8;                            // 0 innerst, 1 ytterst
    ringar.push([0.62+t*1.62, 0.30*(1-t)*(1-t)]);
  }
  for(const [k,v] of ringar){
    GL.rita(D.skuggflack,
      M4.mul(M4.translation(x+dx*k*0.4,0.045,z+dz*k*0.4),
             M4.skala(r*2.3*k,1,r*1.5*k)),
      {platt:true, alfa:a*v, ton:L.skuggFarg||"#000000"});
  }
  gl.depthMask(true); gl.disable(gl.BLEND);
}

/* ── Ryttaren: sits, lättridning, lätt sits och tyglarna ──────── */
function s3RitaRyttare(bas,o){
  /* o.jag sant = du. Övriga elever ritas ur normaluppsättningen. */
  const D=(o.jag&&S3.del.jag&&S3.del.jag.torso)?S3.del.jag:S3.del, gl=GL;
  const rita=(nat,mat,ton)=>{ gl.rita(nat,M4.mul(bas,mat),{ton}); };
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
  const torso=M4.mul(M4.translation(satX+0.02,satY+0.28,0),M4.rotZ(-lutning));
  rita(D.torso,torso,"#FFFFFF");
  /* Huvudet blickar dit hästen ska; håret följer med. */
  const hx=satX+0.04+Math.sin(lutning)*0.50, hy=satY+0.28+Math.cos(lutning)*0.33;
  const huvM=M4.mul(M4.translation(hx,hy,0),M4.rotZ(-lutning*0.6));
  rita(D.har,huvM,"#FFFFFF");
  rita(D.huvudR,huvM,"#FFFFFF");
  rita(D.hjalm,M4.mul(huvM,M4.translation(0,0.100,0)),"#FFFFFF");
  /* Benen: låret ner mot stigbygeln, vaden längs hästens sida. */
  for(const s of [-1,1]){
    const hoft=[satX-0.02,satY-0.02,s*0.19];
    const kna=[hoft[0]+0.30,hoft[1]-0.26,s*0.30];
    const hal=[kna[0]-0.05,kna[1]-0.42,s*0.30];
    rita(D.lar,s3Segment(hoft,kna,1),"#FFFFFF");
    rita(D.vad,s3Segment(kna,hal,1),"#FFFFFF");
    rita(D.stovel,M4.translation(hal[0]+0.03,hal[1]-0.03,hal[2]),"#FFFFFF");
    // stigbygeln
    rita(S3.del.rem,s3Segment([satX+0.02,satY-0.06,s*0.26],[hal[0],hal[1]+0.02,hal[2]],1),"#9A9AA0");
  }
  /* Armarna och tyglarna: handen närmare kroppen när du tar tygel.
     Axelleden är vit i nätet och färgas här, så den följer kavajen. */
  const kavajTon=(o.jag&&typeof jagFarg==="function")?jagFarg().kavaj:"#33465F";
  const drag=clamp(a.tygel,0,1);
  const hand=[satX+0.44-drag*0.06, satY+0.06-lutning*0.10, 0];
  for(const s of [-1,1]){
    const axel=[satX+0.01,satY+0.44,s*0.145];
    const bage=[axel[0]+0.09,(axel[1]+hand[1])/2+0.05,s*0.155];
    rita(S3.del.led,M4.translation(axel[0],axel[1],axel[2]),kavajTon); // axeln
    rita(D.arm,s3Segment(axel,bage,1),"#FFFFFF");
    rita(D.arm,s3Segment(bage,[hand[0],hand[1],s*0.13],1),"#FFFFFF");
    rita(S3.del.hand,M4.translation(hand[0],hand[1]-0.02,s*0.13),"#FFFFFF");
    // tygeln till bettet
    if(o.huvudPos)
      rita(S3.del.rem,s3Segment([hand[0],hand[1],s*0.13],
        [o.huvudPos[0],o.huvudPos[1],s*0.075],1),"#3A2E20");
  }
}

/* Himlen: en ring av band från horisont till zenit, plus ett lock.
   Ritas obelyst, så färgen i banden är gradienten. Centrum flyttas
   med scenen så att kupolen alltid omsluter kameran. */
function s3Himmel(centrum){
  /* Gradienten och solen ritas av GL.himmel som ett helskärmspass.
     Här byggs bara molnen — klungor av tillplattade klot högt upp. */
  if(S3.himmel)GL.fritt(S3.himmel.nat);
  const himmel=new Bygge();
  const cx0=centrum[0], cz0=centrum[1];
  let fro=91; const rnd=()=>{fro=(fro*16807)%2147483647;return fro/2147483647;};
  for(let i=0;i<14;i++){
    const v=rnd()*Math.PI*2, r=74+rnd()*54, y=26+rnd()*20;
    const mx=cx0+Math.cos(v)*r, mz=cz0+Math.sin(v)*r;
    const st=4.5+rnd()*4.0;
    for(const [ox,oy,oz,rr] of [[-1.25,.10,.2,.80],[-.30,-.30,-.1,1.05],
        [.62,-.05,.15,.92],[1.34,.18,-.2,.70],[.15,.34,.3,.72]]){
      himmel.klot(1,"#FFFFFF",M4.mul(
        M4.translation(mx+ox*st, y+oy*st, mz+oz*st),
        M4.skala(rr*st, rr*st*0.55, rr*st*0.8)),8);
    }
  }
  S3.himmel={nat:GL.nat(himmel)};
  S3.himmelC=centrum;
}

/* ── Anläggningen: byggs om när platsen byter ─────────────────── */
function s3ByggPlats(plats){
  for(const s of S3.statiskt)GL.fritt(s.nat);
  S3.statiskt=[];
  /* Rummet kameran måste hålla sig inom. Ridhusets golv är 30 × 72 med
     mitten i (10, 30); marginalen håller kameran innanför panelen.
     Utomhus finns inga väggar och boomen får vara fri. */
  S3.rum=plats==="ridhus"?{x0:-4.3,x1:24.3,z0:-5.3,z1:65.3}:null;
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
    const TF=LOVFARG;
    let fro=7;
    const rnd=()=>{fro=(fro*16807)%2147483647;return fro/2147483647;};
    const trad=(x,z,h,f)=>{
      if(STIL==="kloss")return klossTrad(skog,x,z,h,f,glMorka(f,0.86));
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
  /* ── Kamerans egen kurs ───────────────────────────────────────────
     Kameran satt fastsvetsad i hästens kurs: varje styrutslag vred hela
     bilden i samma bildruta som hästen vred sig, vilket läser som att
     man styr en kamera snarare än rider framåt. Nu har den en EGEN kurs
     som följer hästens med kort fördröjning — hästen svänger först,
     bilden hinner ifatt.

     Skillnaden räknas den korta vägen runt cirkeln, annars snurrar
     kameran ett helt varv när kursen passerar noll. */
  const k=S3.kam;
  const KAM_YAW_TAU=0.16;
  if(k.yaw===undefined)k.yaw=G.rikt;
  {let d=G.rikt-k.yaw;
   while(d>Math.PI)d-=2*Math.PI; while(d<-Math.PI)d+=2*Math.PI;
   k.yaw+=d*(1-Math.exp(-dt/KAM_YAW_TAU));}

  /* Boomen ligger bakom kamerans kurs; blicken siktar i hästens
     FÄRDRIKTNING, så att vägen framåt är läsbar även mitt i en sväng. */
  const bakat=[Math.cos(k.yaw),0,Math.sin(k.yaw)];
  const fram=[Math.cos(G.rikt),0,Math.sin(G.rikt)];
  const hojd=G.luft>0?2.30:1.95;
  let bakMal=G.luft>0?5.0:4.05;

  /* Boomen kortas tills kameran ligger innanför rummets väggar. Utan
     det går kameran rakt genom sargen så fort man rider i ett hörn —
     och man rider i hörnen hela tiden, eftersom fyrkantspåret går där.
     Att korta boomen i stället för att flytta kameran i sidled håller
     hästen kvar mitt i bilden. */
  const R=S3.rum;
  /* Kameran väjer för väggar OCH för andra ekipage. Utan hästarna kunde
     boompunkten hamna närmare en NPC än ryttaren själv, och då fyllde ett
     annat hästhuvud hela skärmen. */
  const fritt=(px,pz)=>{
    if(R&&(px<R.x0||px>R.x1||pz<R.z0||pz>R.z1))return false;
    for(const n of (G.npcs||[]))
      if(Math.hypot(px-n.x,pz-n.y)<1.9)return false;
    return true;
  };
  for(let i=0;i<10&&bakMal>1.35;i++){
    if(fritt(G.px-bakat[0]*bakMal, G.py-bakat[2]*bakMal))break;
    bakMal*=0.82;
  }
  /* Boomlängden mjukas i stället för att hoppa. Söksteget ovan ger
     diskreta längder — 4,05, 3,32, 2,72 — och utan utjämningen syntes
     varje steg som ett ryck när man red längs sargen. Den drar in sig
     snabbare än den åker ut, så att kameran aldrig hinner fastna i en
     vägg men lugnt återtar sitt läge när det är fritt igen. */
  if(k.bak===undefined)k.bak=bakMal;
  k.bak+=(bakMal-k.bak)*(1-Math.exp(-dt/(bakMal<k.bak?0.10:0.42)));

  const mx=G.px-bakat[0]*k.bak, mz=G.py-bakat[2]*k.bak;
  if(!k.satt){k.x=mx;k.y=hojd;k.z=mz;k.tx=G.px;k.ty=1.35;k.tz=G.py;k.satt=true;}

  /* Position och blickpunkt har SEPARATA svar. Blicken är snabbare än
     kroppen: den ska ligga stadigt på vägen framåt medan kameran själv
     glider mjukare. Med en gemensam faktor blev det antingen en slängig
     blick eller en trög kamera. */
  const fPos=1-Math.exp(-dt/0.13);
  const fBlick=1-Math.exp(-dt/0.09);
  k.x+=(mx-k.x)*fPos; k.y+=(hojd-k.y)*fPos; k.z+=(mz-k.z)*fPos;
  /* Mjukningen kan glida ut genom en vägg i en sväng även när målet
     ligger innanför. Ett hårt tak efteråt, så att det aldrig händer. */
  if(R){
    k.x=Math.max(R.x0,Math.min(R.x1,k.x));
    k.z=Math.max(R.z0,Math.min(R.z1,k.z));
  }
  k.tx+=((G.px+fram[0]*2.6)-k.tx)*fBlick;
  k.ty+=((1.58+(G.luft>0?0.6:0))-k.ty)*fBlick;
  k.tz+=((G.py+fram[2]*2.6)-k.tz)*fBlick;
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
  /* Himlen först: gradient och sol som ett helskärmspass, molnen som
     geometri ovanpå. Ingen djupskrivning. */
  const gl=GL.gl;
  GL.himmel(L);
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
  if(h)s3RitaHast({hast:h, jag:true, x:G.px, z:G.py, rikt:G.rikt,
    gangart:G.ride?G.ride.gangart:"halt", fas:G.gaitFas, luft:G.luft,
    banlut:G.banLut||0,
    sadel:true, ryttare:true, skugga:true, aids:G.aids,
    samling:G.ride?clamp(G.ride.skala.samling*0.6+G.ride.skala.kontakt*0.4,0,1):0.4});
  GL.efter();          // glöd och mättnad
  /* Regnet ritas av 2D-lagret ovanpå. */
  return true;
}

/* Växlar mellan WebGL-lagret och den handrullade vyn. */
function gl3dLage(pa){
  const app=document.getElementById("app");
  if(app&&app.classList.contains("gl3d")!==!!pa)app.classList.toggle("gl3d",!!pa);
}
/* Ridvyn: äkta 3D bakom hästen. Saknas WebGL faller den tillbaka på
   den handrullade målarvyn. Sidovyn i src/ritt2d.js ligger kvar men
   används inte. */
function draw3D(Gs){
  if(rita3D(Gs)){
    gl3dLage(true);
    cx.clearRect(0,0,CW,CH);
    if(G.plats!=="ridhus"&&G.vader&&G.vader.typ==="regn"){
      cx.strokeStyle="rgba(210,226,238,.30)";cx.lineWidth=1;
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
