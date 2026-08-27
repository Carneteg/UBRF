/* ══════════════════════════════════════════════════════════════════
   RENDERING — två vyer på samma canvas.
   2D: ridhuset uppifrån som en banskiss, anläggningen runtomkring.
   3D: handrullad perspektivprojektion bakom hästen (ingen CDN får
   användas i en publicerad artifact, så ingen three.js — och för
   ett ridhus med raka linjer behövs den inte heller).
   ══════════════════════════════════════════════════════════════════ */
const cv=document.getElementById("cv"),cx=cv.getContext("2d");
let CW=0,CH=0,DPR=1;
function resize(){DPR=Math.min(window.devicePixelRatio||1,2);
  CW=cv.clientWidth;CH=cv.clientHeight;cv.width=CW*DPR;cv.height=CH*DPR;
  cx.setTransform(DPR,0,0,DPR,0,0);}
window.addEventListener("resize",resize);resize();

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
function draw2D(G){
  v2fit();
  cx.fillStyle=COL.mark;cx.fillRect(0,0,CW,CH);
  const s=V2.scale;

  // anläggningen runtomkring — svaga fotavtryck med etiketter
  cx.save();cx.globalAlpha=0.9;
  const foot=(r,label,fill)=>{
    const[a,b]=w2s(r.x,r.y);
    cx.fillStyle=fill||"#20242B";cx.strokeStyle="#31363E";cx.lineWidth=1;
    cx.fillRect(a,b,r.w*s,r.h*s);cx.strokeRect(a,b,r.w*s,r.h*s);
    if(label&&s>7){cx.fillStyle="#5D636C";cx.font=`500 ${Math.max(9,s*0.85)}px "IBM Plex Mono"`;
      cx.textAlign="center";cx.fillText(label,a+r.w*s/2,b+r.h*s/2+3);}
  };
  foot(SITE.stall,"STALL","#232028");
  foot(SITE.sadelkammare,s>9?"SADELK.":"", "#232028");
  foot(SITE.cafe,"CAFÉ","#232028");
  foot(SITE.utebana,"UTERIDBANA","#1E241C");
  for(const h of SITE.hagar)foot(h,"HAGE","#1B231A");
  foot(SITE.framridning,"FRAMRIDNING","#1E241C");
  cx.restore();

  // ridhuset: golv
  const[gx,gy]=w2s(0,0);
  cx.fillStyle=COL.sand;cx.fillRect(gx,gy,20*s,60*s);
  // harvade spår
  cx.strokeStyle="rgba(0,0,0,.05)";cx.lineWidth=1;
  for(let i=1;i<20;i++){cx.beginPath();cx.moveTo(gx+i*s,gy);cx.lineTo(gx+i*s,gy+60*s);cx.stroke();}
  // fyrkantspåret
  cx.strokeStyle=COL.spar;cx.lineWidth=Math.max(2,s*0.5);
  cx.strokeRect(gx+1.5*s,gy+1.5*s,17*s,57*s);
  // sarg + läktare
  cx.strokeStyle=COL.vagg;cx.lineWidth=Math.max(3,s*0.45);
  cx.strokeRect(gx,gy,20*s,60*s);
  cx.fillStyle=COL.laktare;cx.fillRect(gx-2.2*s,gy+14*s,1.8*s,32*s);
  if(s>7){cx.save();cx.translate(gx-1.3*s,gy+30*s);cx.rotate(-Math.PI/2);
    cx.fillStyle="#5D636C";cx.font=`500 ${s*0.8}px "IBM Plex Mono"`;cx.textAlign="center";
    cx.fillText("LÄKTARE",0,3);cx.restore();}
  // tre ingångar
  cx.strokeStyle=COL.sandDark;cx.lineWidth=Math.max(3,s*0.5);
  for(const[ix,iy,horiz]of[[10,0,1],[20,10,0],[20,50,0]]){
    const[a,b]=w2s(ix,iy);cx.beginPath();
    if(horiz){cx.moveTo(a-1.2*s,b);cx.lineTo(a+1.2*s,b);}else{cx.moveTo(a,b-1.2*s);cx.lineTo(a,b+1.2*s);}
    cx.stroke();}
  // bokstäver
  cx.font=`600 ${Math.max(11,s*1.05)}px Petrona,serif`;cx.textAlign="center";cx.fillStyle=COL.bokstav;
  for(const{b,x,y}of DRESSYRBOKSTAVER){
    let[a,c]=w2s(x,y);
    if(x===0)a-=s*0.9; if(x===20)a+=s*0.9; if(y===0)c-=s*0.6; if(y===60)c+=s*1.3;
    cx.fillText(b,a,c+4);}

  // volt-guide under lösgörande
  if(G.scen==="lektion"&&G.moment?.id==="losgorande"){
    const[a,b]=w2s(10,10);
    cx.strokeStyle="rgba(214,174,60,.30)";cx.lineWidth=2;cx.setLineDash([6,7]);
    cx.beginPath();cx.arc(a,b,10*s,0,Math.PI*2);cx.stroke();cx.setLineDash([]);
  }

  // hinder
  if(G.hinderAktiva)for(const h of BANA.hinder)drawFence2D(h,s,G);
  // NPC-ekipage
  for(const n of G.npcs)drawHorse2D(n.x,n.y,n.rikt,n.farg,s*0.9,false);
  // spelaren
  drawHorse2D(G.px,G.py,G.rikt,HORSES[G.hastId].farg,s,true,G);
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
  cx.font=`600 ${Math.max(9,s*0.78)}px "IBM Plex Mono"`;cx.textAlign="center";
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
function draw3D(G){
  const cam={x:G.px-Math.cos(G.rikt)*V3.back, y:G.py-Math.sin(G.rikt)*V3.back,
    z0:V3.h, fx:Math.cos(G.rikt), fy:Math.sin(G.rikt)};
  // himmel/tak + golv
  const grad=cx.createLinearGradient(0,0,0,CH*0.60);
  grad.addColorStop(0,"#15181D");grad.addColorStop(1,"#23272E");
  cx.fillStyle=grad;cx.fillRect(0,0,CW,CH*0.60);
  cx.fillStyle=COL.sand;cx.fillRect(0,CH*0.60,CW,CH*0.40);
  const items=[];
  // golvlinjer (var 5 m + fyrkantspår)
  for(let y=0;y<=60;y+=5)items.push({z:0,typ:"linje",p:[[0,y],[20,y]]});
  for(const seg of [[[1.5,1.5],[18.5,1.5]],[[18.5,1.5],[18.5,58.5]],[[18.5,58.5],[1.5,58.5]],[[1.5,58.5],[1.5,1.5]]])
    items.push({z:0,typ:"spar",p:seg});
  // väggar som stolpar + band
  for(let y=0;y<=60;y+=4){items.push({typ:"stolpe",x:0,y});items.push({typ:"stolpe",x:20,y});}
  for(let x=0;x<=20;x+=4){items.push({typ:"stolpe",x,y:0});items.push({typ:"stolpe",x,y:60});}
  // bokstäver
  for(const B of DRESSYRBOKSTAVER)items.push({typ:"bokstav",...B});
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
      cx.strokeStyle=o.typ==="spar"?"rgba(120,110,80,.5)":"rgba(0,0,0,.10)";
      cx.lineWidth=o.typ==="spar"?2:1;
      cx.beginPath();cx.moveTo(A[0],A[1]);cx.lineTo(B[0],B[1]);cx.stroke();
    }else if(o.typ==="stolpe"){
      const A=proj(o.x,o.y,0,cam),B=proj(o.x,o.y,1.3,cam);
      if(!A||!B)continue;
      cx.strokeStyle=COL.vaggLjus;cx.lineWidth=Math.max(1,90/A[2]);
      cx.beginPath();cx.moveTo(A[0],A[1]);cx.lineTo(B[0],B[1]);cx.stroke();
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
    cx.fillStyle=nasta?"#E7C86B":"#8A8066";cx.font=`600 ${sz}px "IBM Plex Mono"`;
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
