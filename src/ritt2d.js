/* ══════════════════════════════════════════════════════════════════
   RIDVYN — sidovy i lager, byggd som ui-kit-demo.html.

   Kameran står vid sidan av banan och följer med. Himmel, sol, moln,
   kullar, mark och gräs ritas med kod i kitets färger; häst, ryttare,
   träd och byggnader är målade PNG-sprites ur assets/. Saknas en
   sprite ritas en enkel siluett med streckad guldram och filnamnet,
   så att luckan syns i stället för att smyga förbi.

   Djupet görs med parallax: ju längre bort ett lager ligger, desto
   långsammare rör det sig. Hästens tillryggalagda väg driver allt.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const RITT2D={
  vag:0,            // tillryggalagd väg i meter — driver parallaxen
  sistX:null, sistY:null,
  moln:[{x:0.10,y:0.16,s:1.15},{x:0.46,y:0.09,s:0.85},
        {x:0.74,y:0.20,s:1.30},{x:1.16,y:0.12,s:0.95}],
  _var:{},
};

/* Kitets variabler — hämtas ur :root så att paletten bara finns på
   ett ställe. Cachas; de ändras inte under spelets gång. */
function r2Farg(namn){
  const c=RITT2D._var;
  if(c[namn])return c[namn];
  const v=getComputedStyle(document.documentElement).getPropertyValue(namn).trim();
  return (c[namn]=v||"#888");
}

/* Marklinjen och skalan: en meter i världen blir så här många pixlar. */
function r2Matt(){
  /* Stående skärm: horisonten högre upp, så att banan får plats
     ovanför pekkontrollerna. Skalan sätts av både bredd och höjd så
     att hästen är lika stor i bild oavsett format. */
  const stAende=CW<CH;
  const markY=CH*(stAende?0.68:0.845);
  const px=Math.max(CW/12.5, markY*0.245/1.62);
  return {markY, px};
}

/* ── Bakgrundslagren ──────────────────────────────────────────── */
function r2Himmel(){
  const g=cx.createLinearGradient(0,0,0,CH*0.86);
  g.addColorStop(0,r2Farg("--sky-top"));
  g.addColorStop(0.55,r2Farg("--sky-bottom"));
  g.addColorStop(1,"#C8ECFF");
  cx.fillStyle=g; cx.fillRect(0,0,CW,CH);

  const sx=CW*0.82, sy=CH*0.13, r=Math.min(CW,CH)*0.10;
  const sg=cx.createRadialGradient(sx,sy,0,sx,sy,r*3.2);
  sg.addColorStop(0,"rgba(255,246,201,.95)");
  sg.addColorStop(0.22,"rgba(255,224,112,.45)");
  sg.addColorStop(1,"rgba(255,224,112,0)");
  cx.fillStyle=sg; cx.beginPath(); cx.arc(sx,sy,r*3.2,0,Math.PI*2); cx.fill();
  const kg=cx.createRadialGradient(sx-r*0.3,sy-r*0.3,0,sx,sy,r);
  kg.addColorStop(0,"#FFF6C9"); kg.addColorStop(0.6,"#FFE070"); kg.addColorStop(1,"#FFCC33");
  cx.fillStyle=kg; cx.beginPath(); cx.arc(sx,sy,r,0,Math.PI*2); cx.fill();
}
function r2Moln(){
  const d=(RITT2D.vag*0.04)%1.6;
  cx.fillStyle="#fff";
  for(const m of RITT2D.moln){
    let x=((m.x-d)%1.6+1.6)%1.6*CW-CW*0.3;
    const y=CH*m.y, s=Math.min(CW,CH)*0.055*m.s;
    cx.globalAlpha=0.92;
    for(const [ox,oy,rr] of [[-1.15,.18,.78],[-.28,-.34,1.0],[.62,-.10,.88],[1.32,.20,.66]]){
      cx.beginPath(); cx.ellipse(x+ox*s,y+oy*s,rr*s,rr*s*0.72,0,0,Math.PI*2); cx.fill();
    }
  }
  cx.globalAlpha=1;
}
function r2Kullar(){
  const gras=r2Farg("--grass"), ljus=r2Farg("--grass-light"), mork=r2Farg("--grass-dark");
  const bas=r2Matt().markY;
  const lager=[
    {d:0.10, h:CH*0.20, y:bas-CH*0.115, f:ljus, br:1.35},
    {d:0.17, h:CH*0.16, y:bas-CH*0.075, f:gras, br:1.05},
    {d:0.26, h:CH*0.12, y:bas-CH*0.035, f:mork, br:0.80},
  ];
  for(const L of lager){
    const steg=CW*L.br;
    const off=-((RITT2D.vag*L.d*30)%steg);
    cx.fillStyle=L.f;
    cx.beginPath(); cx.moveTo(-CW,bas+CH);
    for(let x=off-steg; x<CW+steg; x+=steg){
      cx.moveTo(x,bas+CH);
      cx.ellipse(x+steg/2, L.y+L.h, steg*0.62, L.h, 0, Math.PI, 0);
    }
    cx.fill();
    cx.fillRect(-CW, L.y+L.h, CW*3, CH);
  }
}

/* Trädraden och byggnaderna — sprites, annars siluett med filnamn. */
const R2FOND=[
  {n:"trad-lov",     x:1.5,  h:5.6},
  {n:"byggnad-stall",x:8.0,  h:7.4},
  {n:"trad-lov",     x:15.0, h:5.0},
  {n:"trad-host",    x:19.5, h:5.4},
  {n:"byggnad-ridhus",x:27.0,h:9.0},
  {n:"trad-lov",     x:36.0, h:5.8},
  {n:"trad-host",    x:41.0, h:4.8},
];
function r2Fond(){
  const {markY,px}=r2Matt();
  const y=markY-CH*0.035;
  const d=0.38, period=46;                       // meter innan raden upprepas
  const off=(RITT2D.vag*d)%period;
  for(let k=-1;k<=1;k++)for(const o of R2FOND){
    const wx=o.x-off+k*period;
    const sx=CW*0.5+wx*px*0.34;
    if(sx<-CW*0.4||sx>CW*1.4)continue;
    const h=o.h*px*0.34;
    if(!ritaSprite(cx,o.n,sx,y,h,1))r2Siluett(o.n,sx,y,h);
  }
}
/* Enkel siluett + streckad guldram med filnamnet. Syns tydligt att
   den ska bytas mot en målad PNG. */
function r2Siluett(namn,x,markY,h){
  const trad=namn.startsWith("trad");
  cx.save();
  if(trad){
    const w=h*0.62;
    cx.fillStyle=namn==="trad-host"?"#C1762F":r2Farg("--grass-dark");
    cx.fillRect(x-h*0.045,markY-h*0.42,h*0.09,h*0.42);
    cx.fillStyle=namn==="trad-host"?"#D68A3C":r2Farg("--grass");
    cx.beginPath(); cx.ellipse(x,markY-h*0.66,w*0.55,h*0.36,0,0,Math.PI*2); cx.fill();
    cx.beginPath(); cx.ellipse(x-w*0.30,markY-h*0.50,w*0.34,h*0.24,0,0,Math.PI*2); cx.fill();
    cx.beginPath(); cx.ellipse(x+w*0.30,markY-h*0.52,w*0.32,h*0.22,0,0,Math.PI*2); cx.fill();
  }else{
    const w=h*1.5;
    cx.fillStyle="#8E2B24";
    cx.fillRect(x-w/2,markY-h*0.72,w,h*0.72);
    cx.fillStyle="#5A5F66";
    cx.beginPath(); cx.moveTo(x-w*0.56,markY-h*0.70); cx.lineTo(x,markY-h*1.0);
    cx.lineTo(x+w*0.56,markY-h*0.70); cx.closePath(); cx.fill();
  }
  const bw=trad?h*0.72:h*1.6, bh=h;
  cx.strokeStyle="#F6C445"; cx.lineWidth=2.5; cx.setLineDash([8,6]);
  cx.strokeRect(x-bw/2,markY-bh,bw,bh); cx.setLineDash([]);
  cx.fillStyle="#F6C445";
  cx.globalAlpha=0.75;
  cx.font='700 10px "Arial Rounded MT Bold","Trebuchet MS",sans-serif';
  cx.textAlign="center";
  cx.fillText(namn+".png",x,markY-bh-5);
  cx.globalAlpha=1;
  cx.restore();
}

/* Staketet längs banans långsida. */
function r2Staket(){
  const {markY,px}=r2Matt();
  const y=markY-CH*0.105;                    // vid banans bortre kant
  const stolpAvst=2.6, d=0.72;
  const off=(RITT2D.vag*d)%stolpAvst;
  const h=1.25*px*0.62;
  cx.strokeStyle="#E8DCC4"; cx.lineWidth=Math.max(3,px*0.10); cx.lineCap="round";
  for(const rel of [0.42,0.80]){
    cx.beginPath(); cx.moveTo(-20,y-h*rel); cx.lineTo(CW+20,y-h*rel); cx.stroke();
  }
  cx.strokeStyle="#F2E9D6"; cx.lineWidth=Math.max(4,px*0.13);
  for(let x=-off*px*0.72; x<CW+stolpAvst*px; x+=stolpAvst*px*0.72){
    cx.beginPath(); cx.moveTo(x,y); cx.lineTo(x,y-h); cx.stroke();
  }
  cx.lineCap="butt";
}

/* Marken: gräsremsa och ridbanans sand med harvspår som rullar. */
function r2Mark(){
  const {markY,px}=r2Matt();
  const kant=markY-CH*0.105;                 // banans bortre kant
  cx.fillStyle=r2Farg("--grass");
  cx.fillRect(0,kant-CH*0.045,CW,CH*0.045);
  cx.fillStyle=r2Farg("--grass-dark");
  cx.fillRect(0,kant-CH*0.048,CW,CH*0.008);

  const g=cx.createLinearGradient(0,kant,0,CH);
  g.addColorStop(0,"#CBB07C"); g.addColorStop(0.35,"#D9C08D"); g.addColorStop(1,"#C7A970");
  cx.fillStyle=g; cx.fillRect(0,kant,CW,CH-kant);

  cx.strokeStyle="rgba(140,116,74,.20)"; cx.lineWidth=2;
  const off=(RITT2D.vag*px)%(px*1.2);
  for(let i=0;i<14;i++){
    const t=i/13, y=kant+ (CH-kant)*t*t;
    const skala=1+t*2.2;
    cx.beginPath();
    for(let x=-off*skala-px*2; x<CW+px*2; x+=px*1.2*skala){
      cx.moveTo(x,y); cx.lineTo(x+px*0.7*skala,y);
    }
    cx.stroke();
  }
}
function r2Grastuvor(){
  const {markY,px}=r2Matt();
  const off=(RITT2D.vag*1.35*px)%(px*2.2);
  cx.strokeStyle=r2Farg("--grass-dark"); cx.lineWidth=Math.max(2.5,px*0.06);
  cx.lineCap="round";
  for(let x=-off; x<CW+px*2.2; x+=px*2.2){
    const y=markY-CH*0.108;
    for(const dx of [-0.11,0,0.11]){
      cx.beginPath(); cx.moveTo(x+dx*px,y);
      cx.lineTo(x+dx*px*1.5,y-px*(0.13+Math.abs(dx)*0.4)); cx.stroke();
    }
  }
  cx.lineCap="butt";
}

/* ── Ekipaget ─────────────────────────────────────────────────── */
/* Hästen står stilla i bild och världen rullar förbi. Takten syns i
   gungningen, galoppen vaggar, språnget lyfter hela ekipaget. */
function r2Ekipage(x,hast,gangart,fas,luft,aids,markY,hojd,alfa){
  const u=luft>0?1-luft/0.55:0, bage=luft>0?Math.sin(Math.PI*u):0;
  let bob=0, lut=0;
  if(gangart==="trav")bob=-0.030*Math.abs(Math.sin(2*Math.PI*fas));
  else if(gangart==="galopp"){bob=-0.050*Math.max(0,Math.sin(2*Math.PI*fas));
    lut=0.06*Math.sin(2*Math.PI*fas);}
  else if(gangart==="skritt")bob=-0.014*Math.abs(Math.sin(2*Math.PI*fas));
  if(luft>0){bob-=0.55*bage; lut-=0.30*Math.cos(Math.PI*u);}

  const y=markY+bob*hojd;
  cx.save();
  if(alfa!==undefined)cx.globalAlpha=alfa;
  /* markskugga — mjuk, aldrig hård svärta */
  cx.fillStyle="rgba(46,90,40,.28)";
  cx.beginPath();
  cx.ellipse(x,markY,hojd*0.52*(1-bage*0.35),hojd*0.075,0,0,Math.PI*2);
  cx.fill();

  cx.translate(x,y); cx.rotate(lut); cx.translate(-x,-y);
  const namn=hastSprite(hast);
  if(!ritaSprite(cx,namn,x,y,hojd,1)){
    /* Platshållare: den målarritade profilhästen, tydligt utmärkt. */
    const skala=hojd;
    ritaHastSida(cx,x,y,skala,-1,hast.farg,hast.man,
      {pose:gangart==="halt"?"sta":"ga", fas, sadel:true, skugga:false});
    cx.strokeStyle="#F6C445"; cx.lineWidth=2.5; cx.setLineDash([8,6]);
    cx.strokeRect(x-hojd*0.78,y-hojd*1.02,hojd*1.56,hojd*1.02);
    cx.setLineDash([]);
    cx.fillStyle="#F6C445"; cx.textAlign="center";
    cx.font='700 11px "Arial Rounded MT Bold","Trebuchet MS",sans-serif';
    cx.fillText(namn+".png",x,y-hojd*1.02-6);
  }
  /* Ryttaren sitter i sadeln och lättrider. */
  const a=aids||{sits:0.5,lattridning:true};
  const latt=gangart==="trav"&&a.lattridning
    ? -0.055*hojd*Math.max(0,Math.sin(2*Math.PI*fas)) : 0;
  const sadelY=y-hojd*0.72+latt, ryttarH=hojd*0.86;
  if(!ritaSprite(cx,"ryttare-sida",x-hojd*0.04,sadelY+ryttarH*0.28,ryttarH,1)){
    cx.strokeStyle="#F6C445"; cx.lineWidth=2; cx.setLineDash([7,5]);
    cx.strokeRect(x-ryttarH*0.22,sadelY-ryttarH*0.72,ryttarH*0.44,ryttarH*1.0);
    cx.setLineDash([]);
    cx.fillStyle="rgba(74,27,109,.55)";
    cx.fillRect(x-ryttarH*0.22,sadelY-ryttarH*0.72,ryttarH*0.44,ryttarH*1.0);
    cx.fillStyle="#F6C445"; cx.textAlign="center";
    cx.font='700 10px "Arial Rounded MT Bold","Trebuchet MS",sans-serif';
    cx.fillText("ryttare-sida.png",x,sadelY-ryttarH*0.72-5);
  }
  cx.restore();
}

/* ── Bildrutan ────────────────────────────────────────────────── */
function ritaRitt2D(){
  /* Vägen: hur långt hästen faktiskt har rört sig sedan förra rutan. */
  if(RITT2D.sistX!==null){
    RITT2D.vag+=Math.hypot(G.px-RITT2D.sistX, G.py-RITT2D.sistY);
  }
  RITT2D.sistX=G.px; RITT2D.sistY=G.py;

  const {markY,px}=r2Matt();
  r2Himmel(); r2Moln(); r2Kullar(); r2Fond(); r2Mark(); r2Staket();

  /* Andra ekipage: djupet ger dem mindre storlek och blekare färg. */
  const h=HORSES[G.hastId];
  const hojd=1.62*px;                       // mankhöjd 1,62 m
  for(let i=0;i<G.npcs.length;i++){
    const n=G.npcs[i];
    const rel=((n.s*0.7+i*37)%148)/148;
    const nx=CW*(0.04+rel*0.94), djup=0.62;   // längre in på banan
    r2Ekipage(nx, HORSES[n.hast]||h, G.scen==="bana"?"halt":"trav",
      (G.t*1.2+i*0.4)%1, 0, {sits:.5,lattridning:true},
      markY-CH*0.030, hojd*djup, 0.92);
  }

  if(h)r2Ekipage(CW*0.42, h, G.ride?G.ride.gangart:"halt", G.gaitFas, G.luft,
    G.aids, markY, hojd);

  r2Grastuvor();

  if(G.plats!=="ridhus"&&G.vader&&G.vader.typ==="regn")ritaRegn();
}
