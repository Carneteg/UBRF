/* ══════════════════════════════════════════════════════════════════
   RENDERING — två vyer på samma canvas.
   2D: ridhuset uppifrån som en banskiss, anläggningen runtomkring.
   3D: handrullad perspektivprojektion bakom hästen (ingen CDN får
   användas i en publicerad artifact, så ingen three.js — och för
   ett ridhus med raka linjer behövs den inte heller).
   ══════════════════════════════════════════════════════════════════ */
const cv=document.getElementById("cv"),cx=cv.getContext("2d");
let CW=0,CH=0,DPR=1;

/* ── Automatisk kvalitet ──────────────────────────────────────────
   Upplösningen följer vad hårdvaran orkar: tre nivåer på canvasens
   pixeltäthet (1, 1,45, 2 × CSS-pixlar). Går bilduppdateringen trögt
   trappas den ner INNAN reservrenderaren behöver ta över; flyter det
   på länge trappas den försiktigt upp igen. Geometrin, färgerna och
   anläggningen är exakt desamma på alla nivåer — bara skärpan skiljer.
   Måste stå före resize(): den läser KVAL redan vid inladdningen. */
const KVAL={niva:2, tak:[1,1.45,2], ack:0, n:0, sist:0};
function kvalPuls(dt){
  KVAL.ack+=dt; KVAL.n++;
  if(KVAL.ack<2)return;
  const snitt=KVAL.ack/KVAL.n, nu=performance.now();
  KVAL.ack=0; KVAL.n=0;
  if(snitt>0.032&&KVAL.niva>0&&nu-KVAL.sist>4000){
    KVAL.niva--; KVAL.sist=nu; resize();          // under ~31 fps: släpp skärpa
  }else if(snitt<0.013&&KVAL.niva<2&&nu-KVAL.sist>12000){
    KVAL.niva++; KVAL.sist=nu; resize();          // stabilt snabbt: ta tillbaka
  }
}

function resize(){
  DPR=Math.min(window.devicePixelRatio||1,KVAL.tak[KVAL.niva]);
  CW=cv.clientWidth;CH=cv.clientHeight;cv.width=CW*DPR;cv.height=CH*DPR;
  cx.setTransform(DPR,0,0,DPR,0,0);}
window.addEventListener("resize",resize);resize();

/* ── Bildformatet ─────────────────────────────────────────────────
   3D-kamerorna anger LODRÄT synfält. På en stående telefon blir det
   vågräta då mycket smalare än på en bildskärm — samma komposition
   beskuren, inte anpassad. Här breddas synfältet gradvis när skärmen
   är högre än den är bred, så att man ser lika mycket av världen.
   Världen ändras inte — bara hur mycket av den som får plats i rutan. */
function glFov(bas){
  const a=CW/Math.max(CH,1);
  return a>=1?bas:clamp(bas*(1+0.5*(1-a)),bas,bas*1.5);
}

const COL={
  sand:"#C9BFA6",sandDark:"#B4A98D",sandLine:"#A2976E",
  vagg:"#2E3238",vaggLjus:"#3A3F47",tak:"#22262C",
  mark:"#1A2018",markLjus:"#242C21",grus:"#565049",
  bokstav:"#6E6450",spar:"rgba(140,130,100,.32)",
  bom:"#D6AE3C",bomAlt:"#E6E4DE",stod:"#4A3F30",
  npc:["#8A7A5E","#6E7E8A","#7E6E8A"],
  laktare:"#262B31",
};

/* ── 2D ovanifrån ─────────────────────────────────────────────── */
const V2={scale:12,cxm:10,cym:30};
function v2fit(){
  const m=44; V2.scale=Math.min((CW-2*m-380)/20,(CH-2*m)/60);
  if(CW<900)V2.scale=Math.min((CW-2*m)/20,(CH-2*m)/60);
  V2.scale=clamp(V2.scale,6,18);
}
function w2s(x,y){ // världsmeter → skärm. Banan centrerad, y nedåt = C-sidan
  return [CW/2+(x-10)*V2.scale, CH/2+(y-30)*V2.scale];
}
/* Träden längs skogsstigen (banrums-koordinater, utanför spåret). */
const STIGTRAD=[[-2.5,6],[22.5,14],[-3,26],[23,38],[-2,50],[22.5,56],
  [4,-3],[15,-2.6],[6,62.8],[16,63],[-3.2,40],[23.2,26]];
function tradfarg2(i){
  // TRADFARG (world.js) är par [bas, ljus] — ta basen
  if(typeof TRADFARG!=="undefined")return TRADFARG[i%TRADFARG.length][0];
  return ["#7A6A32","#8A5A2E","#6E7038","#9A6A28"][i%4];
}
function draw2D(G){
  v2fit();
  const ute=G.plats&&G.plats!=="ridhus", stig=G.plats==="stig";
  cx.fillStyle=ute?"#20281B":COL.mark;cx.fillRect(0,0,CW,CH);
  const s=V2.scale;

  // anläggningen runtomkring — svaga fotavtryck med etiketter (i ridhuset)
  if(!ute){
    cx.save();cx.globalAlpha=0.9;
    const foot=(r,label,fill)=>{
      const[a,b]=w2s(r.x,r.y);
      cx.fillStyle=fill||"#20242B";cx.strokeStyle="#31363E";cx.lineWidth=1;
      cx.fillRect(a,b,r.w*s,r.h*s);cx.strokeRect(a,b,r.w*s,r.h*s);
      if(label&&s>7){cx.fillStyle="#5D636C";cx.font=`500 ${Math.max(9,s*0.85)}px "IBM Plex Mono",monospace`;
        cx.textAlign="center";cx.fillText(label,a+r.w*s/2,b+r.h*s/2+3);}
    };
    foot(SITE.stall,"STALL","#232028");
    foot(SITE.sadelkammare,s>9?"SADELK.":"", "#232028");
    foot(SITE.cafe,"CAFÉ","#232028");
    foot(SITE.utebana,"UTERIDBANA","#1E241C");
    for(const h of SITE.hagar)foot(h,"HAGE","#1B231A");
    foot(SITE.framridning,"FRAMRIDNING","#1E241C");
    cx.restore();
  }

  // golvet: fibersand inne, grus ute, gräs med stig i skogen
  const[gx,gy]=w2s(0,0);
  cx.fillStyle=stig?"#2A331F":ute?"#B7A88A":COL.sand;
  cx.fillRect(gx,gy,20*s,60*s);
  if(!stig){ // harvade spår
    cx.strokeStyle="rgba(0,0,0,.05)";cx.lineWidth=1;
    for(let i=1;i<20;i++){cx.beginPath();cx.moveTo(gx+i*s,gy);cx.lineTo(gx+i*s,gy+60*s);cx.stroke();}
  }
  // fyrkantspåret — på stigen är spåret själva grusvägen
  cx.strokeStyle=stig?"#6E6459":COL.spar;
  cx.lineWidth=stig?Math.max(6,s*1.7):Math.max(2,s*0.5);
  cx.strokeRect(gx+1.5*s,gy+1.5*s,17*s,57*s);
  if(stig){ // mittsträng av gräs i grusvägen
    cx.strokeStyle="rgba(52,64,38,.55)";cx.lineWidth=Math.max(1.5,s*0.22);
    cx.setLineDash([s*1.2,s*0.9]);
    cx.strokeRect(gx+1.5*s,gy+1.5*s,17*s,57*s);cx.setLineDash([]);
  }
  if(!ute){
    // sarg + läktare
    cx.strokeStyle=COL.vagg;cx.lineWidth=Math.max(3,s*0.45);
    cx.strokeRect(gx,gy,20*s,60*s);
    cx.fillStyle=COL.laktare;cx.fillRect(gx-2.2*s,gy+14*s,1.8*s,32*s);
    if(s>7){cx.save();cx.translate(gx-1.3*s,gy+30*s);cx.rotate(-Math.PI/2);
      cx.fillStyle="#5D636C";cx.font=`500 ${s*0.8}px "IBM Plex Mono",monospace`;cx.textAlign="center";
      cx.fillText("LÄKTARE",0,3);cx.restore();}
    { // publiken på läktaren: fullsatt på tävling, några föräldrar annars
      const antal=G.tavling?14:3, steg2=G.tavling?2.15:7.5;
      for(let i=0;i<antal;i++){
        const[a,b]=w2s(-1.3,(G.tavling?15.6:22)+i*steg2);
        cx.fillStyle=["#8A4A3A","#3E5C74","#6B5E3C","#4E6B4A"][i%4];
        cx.beginPath();cx.arc(a,b,Math.max(2,s*0.22),0,Math.PI*2);cx.fill();}
    }
    // tre ingångar
    cx.strokeStyle=COL.sandDark;cx.lineWidth=Math.max(3,s*0.5);
    for(const[ix,iy,horiz]of[[10,0,1],[20,10,0],[20,50,0]]){
      const[a,b]=w2s(ix,iy);cx.beginPath();
      if(horiz){cx.moveTo(a-1.2*s,b);cx.lineTo(a+1.2*s,b);}else{cx.moveTo(a,b-1.2*s);cx.lineTo(a,b+1.2*s);}
      cx.stroke();}
  }else if(!stig){
    // uteridbanans trästaket med stolpar
    cx.strokeStyle="#5A4633";cx.lineWidth=Math.max(2.5,s*0.3);
    cx.strokeRect(gx,gy,20*s,60*s);
    cx.fillStyle="#4A3A28";
    for(let y=0;y<=60;y+=4){const[a,b]=w2s(0,y),[a2]=w2s(20,y);
      cx.fillRect(a-s*0.14,b-s*0.14,s*0.28,s*0.28);cx.fillRect(a2-s*0.14,b-s*0.14,s*0.28,s*0.28);}
    for(let x=4;x<=16;x+=4){const[a,b]=w2s(x,0),[,b2]=w2s(x,60);
      cx.fillRect(a-s*0.14,b-s*0.14,s*0.28,s*0.28);cx.fillRect(a-s*0.14,b2-s*0.14,s*0.28,s*0.28);}
    if(s>7){cx.fillStyle="#5D6C58";cx.font=`500 ${Math.max(9,s*0.8)}px "IBM Plex Mono",monospace`;
      cx.textAlign="center";cx.fillText("UTERIDBANAN · 36×80",gx+10*s,gy-s*0.8);}
    if(G.tavling&&G.tavling.typ==="dressyr"){ // domarkuren vid C
      const[a,b]=w2s(10,62.2);
      cx.fillStyle="#E6E1D5";cx.fillRect(a-1.3*s,b-0.5*s,2.6*s,1.1*s);
      cx.strokeStyle="#4A4536";cx.strokeRect(a-1.3*s,b-0.5*s,2.6*s,1.1*s);
      if(s>7){cx.fillStyle="#3A3E44";cx.font=`600 ${s*0.55}px "IBM Plex Mono",monospace`;
        cx.textAlign="center";cx.fillText("DOMARE",a,b+s*0.2);}
    }
  }else{
    // skogen: träd runt stigen
    for(let i=0;i<STIGTRAD.length;i++){const[tx,ty]=STIGTRAD[i];
      const[a,b]=w2s(tx,ty);
      cx.fillStyle="rgba(0,0,0,.25)";
      cx.beginPath();cx.ellipse(a+s*0.3,b+s*0.3,s*1.4,s*1.1,0,0,Math.PI*2);cx.fill();
      cx.fillStyle=tradfarg2(i);
      cx.beginPath();cx.arc(a,b,s*(1.1+0.35*((i*7)%3)),0,Math.PI*2);cx.fill();}
  }
  // bokstäver — dressyrbokstäver finns inne och på uteridbanan
  if(!stig){
    cx.font=`600 ${Math.max(11,s*1.05)}px Petrona,serif`;cx.textAlign="center";cx.fillStyle=COL.bokstav;
    for(const{b,x,y}of DRESSYRBOKSTAVER){
      let[a,c]=w2s(x,y);
      if(x===0)a-=s*0.9; if(x===20)a+=s*0.9; if(y===0)c-=s*0.6; if(y===60)c+=s*1.3;
      cx.fillText(b,a,c+4);}
  }

  // banguide för dagens övning (ur träningsboken)
  const guide=G.scen==="lektion"&&G.moment&&
    (typeof OVNINGSGUIDE!=="undefined")&&OVNINGSGUIDE[G.moment.ovning];
  if(guide)ritaGuide2D(guide,s);

  // hinder
  if(G.hinderAktiva)for(const h of BANA.hinder)drawFence2D(h,s,G);
  // NPC-ekipage
  for(const n of G.npcs)drawHorse2D(n.x,n.y,n.rikt,n.farg,s*0.9,false);
  // spelaren
  drawHorse2D(G.px,G.py,G.rikt,HORSES[G.hastId].farg,s,true,G);
}
function ritaGuide2D(g,s){
  cx.strokeStyle="rgba(214,174,60,.32)";cx.fillStyle="rgba(214,174,60,.32)";
  cx.lineWidth=2;cx.setLineDash([6,7]);
  cx.beginPath();
  if(g.typ==="volt"){
    const[a,b]=w2s(g.cx,g.cy);cx.arc(a,b,g.r*s,0,Math.PI*2);
  }else if(g.typ==="serpentin"){
    for(let y=0;y<=60;y+=1.5){
      const x=10+8.2*Math.cos(Math.PI*y/20);
      const[a,b]=w2s(x,y);
      y===0?cx.moveTo(a,b):cx.lineTo(a,b);}
  }else if(g.typ==="diagonal"){
    let[a,b]=w2s(g.fran[0],g.fran[1]);cx.moveTo(a,b);
    [a,b]=w2s(g.till[0],g.till[1]);cx.lineTo(a,b);
    if(g.ater){[a,b]=w2s(g.ater[0],g.ater[1]);cx.lineTo(a,b);}
  }else if(g.typ==="langsida"){
    let[a,b]=w2s(g.x,g.y0);cx.moveTo(a,b);
    [a,b]=w2s(g.x,g.y1);cx.lineTo(a,b);
    [a,b]=w2s(g.inre,g.y0);cx.moveTo(a,b);
    [a,b]=w2s(g.inre,g.y1);cx.lineTo(a,b);
  }else if(g.typ==="horn"){
    for(const[hx,hy,v0]of[[1.5,1.5,0],[18.5,1.5,Math.PI/2],[18.5,58.5,Math.PI],[1.5,58.5,-Math.PI/2]]){
      const[a,b]=w2s(hx,hy);
      cx.moveTo(a+Math.cos(v0)*6*s,b+Math.sin(v0)*6*s);
      cx.arc(a,b,6*s,v0,v0+Math.PI/2);}
  }else if(g.typ==="bage"){
    for(let y=10;y<=50;y+=1.5){
      const x=1.8+5.5*Math.sin(Math.PI*(y-10)/40);
      const[a,b]=w2s(x,y);
      y===10?cx.moveTo(a,b):cx.lineTo(a,b);}
  }
  cx.stroke();cx.setLineDash([]);
  if(g.typ==="punkter")for(const p of g.p){
    const[a,b]=w2s(p[0],p[1]);
    cx.beginPath();cx.arc(a,b,Math.max(4,s*0.5),0,Math.PI*2);cx.fill();}
}
function drawFence2D(h,s,G){
  const[a,b]=w2s(h.x,h.y),L=4*s/2;
  const riven=G.rivna.has(h.nr), nasta=G.nastaHinder===h.nr;
  cx.save();cx.translate(a,b);cx.rotate(h.rot+Math.PI/2);
  cx.fillStyle=COL.stod;cx.fillRect(-L-3,-3,6,6);cx.fillRect(L-3,-3,6,6);
  cx.strokeStyle=riven?"#7A5A50":(nasta?"#E7C86B":COL.bom);
  cx.lineWidth=Math.max(3,s*0.42);
  if(riven){cx.save();cx.rotate(0.12);cx.beginPath();cx.moveTo(-L,3);cx.lineTo(L,7);cx.stroke();cx.restore();}
  else{cx.beginPath();cx.moveTo(-L,0);cx.lineTo(L,0);cx.stroke();
    if(h.typ==="oxer"){cx.strokeStyle=COL.bomAlt;cx.lineWidth=Math.max(2,s*0.28);
      cx.beginPath();cx.moveTo(-L,-s*0.45);cx.lineTo(L,-s*0.45);cx.stroke();}}
  cx.restore();
  // nummer på anridningssidan, mörk platta för läsbarhet
  const nx=a-Math.cos(h.rot)*1.9*s, ny=b-Math.sin(h.rot)*1.9*s;
  cx.fillStyle=nasta?"#8A6A12":"#4A4536";
  cx.beginPath();cx.arc(nx,ny,Math.max(7,s*0.62),0,Math.PI*2);cx.fill();
  cx.fillStyle=nasta?"#F2E4B8":"#C9BFA6";
  cx.font=`600 ${Math.max(9,s*0.78)}px "IBM Plex Mono",monospace`;cx.textAlign="center";
  cx.fillText(String(h.nr),nx,ny+Math.max(3,s*0.27));
}
function drawHorse2D(x,y,rikt,farg,s,arSpelare,G){
  const[a,b]=w2s(x,y);
  cx.save();cx.translate(a,b);cx.rotate(rikt+Math.PI/2);
  if(arSpelare&&G&&G.luft>0){ // språnget: hästen "lyfter" ur planet
    const f=1+0.38*Math.sin(Math.PI*(1-G.luft/0.55));
    cx.scale(f,f);}
  const L=s*1.5,W=s*0.62;
  // skugga
  cx.fillStyle="rgba(0,0,0,.22)";cx.beginPath();cx.ellipse(1,2,W*0.9,L*0.72,0,0,Math.PI*2);cx.fill();
  // kropp
  cx.fillStyle=farg;cx.beginPath();cx.ellipse(0,0,W*0.78,L*0.62,0,0,Math.PI*2);cx.fill();
  // hals+huvud
  cx.beginPath();cx.ellipse(0,-L*0.62,W*0.42,L*0.34,0,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(0,-L*0.92,W*0.26,L*0.20,0,0,Math.PI*2);cx.fill();
  // öron
  cx.fillRect(-W*0.22,-L*1.06,W*0.14,L*0.12);cx.fillRect(W*0.08,-L*1.06,W*0.14,L*0.12);
  // svans
  cx.strokeStyle=farg;cx.lineWidth=Math.max(2,s*0.16);
  cx.beginPath();cx.moveTo(0,L*0.60);cx.lineTo(0,L*0.86);cx.stroke();
  if(arSpelare){ // ryttare
    cx.fillStyle="#20242B";cx.beginPath();cx.ellipse(0,-L*0.08,W*0.34,W*0.34,0,0,Math.PI*2);cx.fill();
    cx.fillStyle="#D6AE3C";cx.beginPath();cx.ellipse(0,-L*0.08,W*0.16,W*0.16,0,0,Math.PI*2);cx.fill();
  }
  cx.restore();
  if(arSpelare&&G&&G.spanningPuls>0){
    cx.strokeStyle=`rgba(208,101,90,${0.4*G.spanningPuls})`;cx.lineWidth=2;
    cx.beginPath();cx.arc(a,b,s*2+Math.sin(G.t*9)*2,0,Math.PI*2);cx.stroke();}
}

/* ── 3D bakom hästen ─────────────────────────────────────────── */
const V3={h:2.3,back:6.5,fov:1.05};
function proj(px,py,pz,cam){
  // kamerarum: framåt = +z
  const dx=px-cam.x, dy=py-cam.y, dz=pz-cam.z0;   // z0 = kamerans höjd
  const cz= dx*cam.fx+dy*cam.fy;      // djup
  const cxm=-dx*cam.fy+dy*cam.fx;     // sida
  if(cz<0.3)return null;
  const f=(CH*0.9)/V3.fov;
  return [CW/2+cxm/cz*f, CH*0.60-(dz)/cz*f, cz];
}
/* Reservrenderaren: den handrullade målarvyn används när WebGL saknas. */
function draw3DCanvas(G){
  const cam={x:G.px-Math.cos(G.rikt)*V3.back, y:G.py-Math.sin(G.rikt)*V3.back,
    z0:V3.h, fx:Math.cos(G.rikt), fy:Math.sin(G.rikt)};
  const ute=G.plats&&G.plats!=="ridhus", stig=G.plats==="stig";
  const vader=(G.vader&&G.vader.typ)||"sol";
  // himmel/tak + golv
  const grad=cx.createLinearGradient(0,0,0,CH*0.60);
  if(!ute){grad.addColorStop(0,"#15181D");grad.addColorStop(1,"#23272E");}
  else{const sky={sol:["#2C3A55","#B08A5C"],mulet:["#39404A","#7A7A70"],
      regn:["#2C3138","#4E545A"]}[vader];
    grad.addColorStop(0,sky[0]);grad.addColorStop(1,sky[1]);}
  cx.fillStyle=grad;cx.fillRect(0,0,CW,CH*0.60);
  cx.fillStyle=stig?"#2A331F":ute?"#B7A88A":COL.sand;
  cx.fillRect(0,CH*0.60,CW,CH*0.40);
  const items=[];
  // golvlinjer (var 5 m + fyrkantspår — på stigen är spåret grusvägen)
  if(!stig)for(let y=0;y<=60;y+=5)items.push({z:0,typ:"linje",p:[[0,y],[20,y]]});
  // fyrkantspåret i korta bitar så att närliggande delar inte klipps
  // bort med hela segmentet när ena änden hamnar bakom kameran
  for(const[[x0,y0],[x1,y1]]of[[[1.5,1.5],[18.5,1.5]],[[18.5,1.5],[18.5,58.5]],
      [[18.5,58.5],[1.5,58.5]],[[1.5,58.5],[1.5,1.5]]]){
    const n=Math.max(1,Math.round(Math.hypot(x1-x0,y1-y0)/4));
    for(let i=0;i<n;i++){
      const a=i/n,b2=(i+1)/n;
      items.push({z:0,typ:"spar",p:[[x0+(x1-x0)*a,y0+(y1-y0)*a],[x0+(x1-x0)*b2,y0+(y1-y0)*b2]]});
    }
  }
  // väggar som stolpar + band (staketstolpar ute, träd på stigen)
  if(!stig){
    for(let y=0;y<=60;y+=4){items.push({typ:"stolpe",x:0,y});items.push({typ:"stolpe",x:20,y});}
    for(let x=0;x<=20;x+=4){items.push({typ:"stolpe",x,y:0});items.push({typ:"stolpe",x,y:60});}
  }else{
    for(let i=0;i<STIGTRAD.length;i++)
      items.push({typ:"trad",x:STIGTRAD[i][0],y:STIGTRAD[i][1],farg:tradfarg2(i)});
  }
  // bokstäver
  if(!stig)for(const B of DRESSYRBOKSTAVER)items.push({typ:"bokstav",...B});
  // publik: fullsatt läktare på tävlingsdag, några föräldrar annars
  if(!ute){
    const antal=G.tavling?14:3, steg=G.tavling?2.2:7.5;
    for(let i=0;i<antal;i++)items.push({typ:"publik",x:-1.4,y:(G.tavling?16:22)+i*steg,c:i});
  }else if(G.tavling&&!stig){
    items.push({typ:"kur",x:10,y:62.6});
    for(let i=0;i<6;i++)items.push({typ:"publik",x:-1.8,y:18+i*4.6,c:i});
  }
  // hinder
  if(G.hinderAktiva)for(const h of BANA.hinder)items.push({typ:"hinder",h});
  // NPC
  for(const n of G.npcs)items.push({typ:"npc",n});

  // sortera på avstånd till kameran (painter)
  const dist=o=>{const x=o.x??o.h?.x??o.n?.x??o.p?.[0][0],y=o.y??o.h?.y??o.n?.y??o.p?.[0][1];
    return -((x-cam.x)**2+(y-cam.y)**2);};
  items.sort((a,b2)=>dist(a)-dist(b2));

  for(const o of items){
    if(o.typ==="linje"||o.typ==="spar"){
      const A=proj(o.p[0][0],o.p[0][1],0,cam),B=proj(o.p[1][0],o.p[1][1],0,cam);
      if(!A||!B)continue;
      cx.strokeStyle=stig?"rgba(94,86,77,.92)":o.typ==="spar"?"rgba(120,110,80,.5)":"rgba(0,0,0,.10)";
      cx.lineWidth=stig?clamp(900/Math.min(A[2],B[2]),6,110):o.typ==="spar"?2:1;
      if(stig)cx.lineCap="round";
      cx.beginPath();cx.moveTo(A[0],A[1]);cx.lineTo(B[0],B[1]);cx.stroke();
      if(stig)cx.lineCap="butt";
    }else if(o.typ==="stolpe"){
      const A=proj(o.x,o.y,0,cam),B=proj(o.x,o.y,ute?1.15:1.3,cam);
      if(!A||!B)continue;
      cx.strokeStyle=ute?"#5A4633":COL.vaggLjus;cx.lineWidth=Math.max(1,(ute?110:90)/A[2]);
      cx.beginPath();cx.moveTo(A[0],A[1]);cx.lineTo(B[0],B[1]);cx.stroke();
      if(ute){ // överliggare mot nästa stolpe åt öster/söder ritas som kort band
        cx.strokeStyle="rgba(90,70,51,.7)";cx.lineWidth=Math.max(1,70/A[2]);
        cx.beginPath();cx.moveTo(B[0]-14,B[1]);cx.lineTo(B[0]+14,B[1]);cx.stroke();}
    }else if(o.typ==="trad"){
      const A=proj(o.x,o.y,0,cam),B=proj(o.x,o.y,3.1,cam);
      if(!A||!B)continue;
      cx.strokeStyle="#4A3A28";cx.lineWidth=Math.max(2,150/A[2]);
      cx.beginPath();cx.moveTo(A[0],A[1]);cx.lineTo(B[0],B[1]);cx.stroke();
      const sz=clamp(2600/A[2],10,190);
      cx.fillStyle=o.farg;
      cx.beginPath();cx.ellipse(B[0],B[1]-sz*0.18,sz*0.55,sz*0.62,0,0,Math.PI*2);cx.fill();
      cx.fillStyle="rgba(0,0,0,.14)";
      cx.beginPath();cx.ellipse(B[0]+sz*0.16,B[1]-sz*0.05,sz*0.34,sz*0.38,0,0,Math.PI*2);cx.fill();
    }else if(o.typ==="publik"){
      const A=proj(o.x,o.y,0,cam);if(!A)continue;
      const sz=clamp(700/A[2],5,60);
      const cols=["#8A4A3A","#3E5C74","#6B5E3C","#4E6B4A","#7A4A6B","#5A5A66"];
      cx.fillStyle=cols[o.c%6];
      cx.beginPath();cx.ellipse(A[0],A[1]-sz*0.5,sz*0.22,sz*0.42,0,0,Math.PI*2);cx.fill();
      cx.fillStyle="#C9A98A";
      cx.beginPath();cx.arc(A[0],A[1]-sz*1.0,sz*0.15,0,Math.PI*2);cx.fill();
    }else if(o.typ==="kur"){
      const P2=(x,y,z)=>proj(x,y,z,cam);
      const a=P2(o.x-1.3,o.y,0),b2=P2(o.x+1.3,o.y,0),c2=P2(o.x+1.3,o.y,2.2),d2=P2(o.x-1.3,o.y,2.2);
      if(a&&b2&&c2&&d2){
        cx.fillStyle="#E6E1D5";
        cx.beginPath();cx.moveTo(a[0],a[1]);cx.lineTo(b2[0],b2[1]);cx.lineTo(c2[0],c2[1]);cx.lineTo(d2[0],d2[1]);cx.closePath();cx.fill();
        cx.strokeStyle="#4A4536";cx.lineWidth=1.5;cx.stroke();
        const t=P2(o.x,o.y,1.45);
        if(t){const fz=clamp(240/t[2],8,20);
          cx.fillStyle="#3A3E44";cx.font=`600 ${fz}px "IBM Plex Mono",monospace`;cx.textAlign="center";
          cx.fillText("DOMARE",t[0],t[1]);}
      }
    }else if(o.typ==="bokstav"){
      let bx=o.x,by=o.y; if(o.x===0)bx=-0.6; if(o.x===20)bx=20.6; if(o.y===0)by=-0.6; if(o.y===60)by=60.6;
      const A=proj(bx,by,1.1,cam);if(!A)continue;
      const sz=clamp(560/A[2],8,42);
      cx.fillStyle="#8A8066";cx.font=`600 ${sz}px Petrona,serif`;cx.textAlign="center";
      cx.fillText(o.b,A[0],A[1]);
    }else if(o.typ==="hinder"){
      drawFence3D(o.h,cam,G);
    }else if(o.typ==="npc"){
      const A=proj(o.n.x,o.n.y,0,cam);if(!A)continue;
      const sz=clamp(900/A[2],6,80);
      cx.fillStyle=o.n.farg;
      cx.beginPath();cx.ellipse(A[0],A[1]-sz*0.45,sz*0.55,sz*0.42,0,0,Math.PI*2);cx.fill();
      cx.beginPath();cx.ellipse(A[0]+sz*0.34*Math.cos(o.n.rikt-G.rikt),A[1]-sz*0.8,sz*0.2,sz*0.3,0,0,Math.PI*2);cx.fill();
      cx.fillStyle="rgba(0,0,0,.25)";cx.beginPath();cx.ellipse(A[0],A[1],sz*0.55,sz*0.14,0,0,Math.PI*2);cx.fill();
    }
  }
  drawOwnHorse3D(G);
  if(ute&&vader==="regn"){ // regnstrimmor framför allt
    cx.strokeStyle="rgba(190,200,210,.26)";cx.lineWidth=1;
    const off=(G.t*640)%CH;
    cx.beginPath();
    for(let i=0;i<70;i++){
      const rx=(i*97+i*i*13)%CW, ry=((i*173)%CH+off)%CH;
      cx.moveTo(rx,ry);cx.lineTo(rx-3,ry+14);
    }
    cx.stroke();
  }
}
function drawFence3D(h,cam,G){
  const L=2, dx=Math.cos(h.rot+Math.PI/2)*L, dy=Math.sin(h.rot+Math.PI/2)*L;
  const riven=G.rivna.has(h.nr), nasta=G.nastaHinder===h.nr, H=BANA.hojd;
  const P=(x,y,z)=>proj(x,y,z,cam);
  const A0=P(h.x-dx,h.y-dy,0),A1=P(h.x-dx,h.y-dy,H+0.25);
  const B0=P(h.x+dx,h.y+dy,0),B1=P(h.x+dx,h.y+dy,H+0.25);
  if(!A0||!B0)return;
  cx.strokeStyle=COL.stod;cx.lineWidth=Math.max(2,110/A0[2]);
  cx.beginPath();cx.moveTo(A0[0],A0[1]);cx.lineTo(A1[0],A1[1]);cx.stroke();
  cx.beginPath();cx.moveTo(B0[0],B0[1]);cx.lineTo(B1[0],B1[1]);cx.stroke();
  const bom=(z,col,off)=>{const a=P(h.x-dx,h.y-dy,z),b=P(h.x+dx,h.y+dy,z);if(!a||!b)return;
    cx.strokeStyle=col;cx.lineWidth=Math.max(2.5,150/a[2]);
    cx.beginPath();cx.moveTo(a[0],a[1]+(off||0));cx.lineTo(b[0],b[1]+(off||0));cx.stroke();};
  if(riven){bom(0.06,"#7A5A50",3);}
  else{bom(H,nasta?"#E7C86B":COL.bom);bom(H*0.5,COL.bomAlt);
    if(h.typ==="oxer")bom(H*0.97,"rgba(230,228,222,.75)");}
  // nummerplatta
  const NP=P(h.x-dx*1.1,h.y-dy*1.1,H+0.5);
  if(NP){const sz=clamp(300/NP[2],9,22);
    cx.fillStyle=nasta?"#E7C86B":"#8A8066";cx.font=`600 ${sz}px "IBM Plex Mono",monospace`;
    cx.textAlign="center";cx.fillText(String(h.nr),NP[0],NP[1]);}
}
function drawOwnHorse3D(G){
  const h=HORSES[G.hastId];
  const fas=G.gaitFas, g=G.ride.gangart;
  let bob=g==="trav"?Math.abs(Math.sin(fas*Math.PI*2))*10
    :g==="galopp"?Math.sin(fas*Math.PI*2)*13
    :g==="skritt"?Math.sin(fas*Math.PI*2)*4:0;
  if(G.luft>0)bob-=64*Math.sin(Math.PI*(1-G.luft/0.55)); // språnget lyfter framdelen
  const sv=Math.sin(fas*Math.PI*4)*(g==="halt"?0:3);
  const y0=CH*0.985+bob*0.35, cxm=CW/2+sv;
  // hals
  cx.fillStyle=h.farg;
  cx.beginPath();
  cx.moveTo(cxm-CW*0.072,CH+2);
  cx.quadraticCurveTo(cxm-CW*0.058,y0-CH*0.24+bob, cxm-CW*0.020,y0-CH*0.31+bob);
  cx.lineTo(cxm+CW*0.020,y0-CH*0.31+bob);
  cx.quadraticCurveTo(cxm+CW*0.058,y0-CH*0.24+bob, cxm+CW*0.072,CH+2);
  cx.closePath();cx.fill();
  // man
  cx.fillStyle=h.man;
  cx.beginPath();
  cx.moveTo(cxm-CW*0.022,y0-CH*0.30+bob);
  cx.quadraticCurveTo(cxm-CW*0.040,y0-CH*0.20+bob, cxm-CW*0.050,CH+2);
  cx.lineTo(cxm-CW*0.032,CH+2);
  cx.quadraticCurveTo(cxm-CW*0.022,y0-CH*0.18+bob, cxm-CW*0.008,y0-CH*0.295+bob);
  cx.closePath();cx.fill();
  // huvud + öron
  const hy=y0-CH*0.315+bob*1.15;
  cx.fillStyle=h.farg;
  cx.beginPath();cx.ellipse(cxm,hy,CW*0.021,CH*0.040,0,0,Math.PI*2);cx.fill();
  const ora=(dir)=>{cx.beginPath();
    cx.moveTo(cxm+dir*CW*0.011,hy-CH*0.026);
    cx.quadraticCurveTo(cxm+dir*CW*0.022,hy-CH*0.072,cxm+dir*CW*0.005,hy-CH*0.048);
    cx.closePath();cx.fill();};
  ora(-1);ora(1);
  // tyglar mot handen — spänns med tygelhjälpen
  const drag=G.aids.tygel;
  cx.strokeStyle="#3A2E20";cx.lineWidth=3;
  cx.beginPath();cx.moveTo(cxm-CW*0.017,hy+CH*0.02);
  cx.quadraticCurveTo(cxm-CW*0.09*(1-drag*0.55),CH*0.92, cxm-CW*0.05,CH+4);cx.stroke();
  cx.beginPath();cx.moveTo(cxm+CW*0.017,hy+CH*0.02);
  cx.quadraticCurveTo(cxm+CW*0.09*(1-drag*0.55),CH*0.92, cxm+CW*0.05,CH+4);cx.stroke();
}
