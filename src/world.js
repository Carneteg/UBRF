/* ══════════════════════════════════════════════════════════════════
   VÄRLDEN — gå-läget. Du börjar längst ner i kedjan: till fots vid
   infarten från Husbyvägen. Två scener ("gard", "stallinne") med
   W/S fram/back, A/D sväng, Shift jogg, E interagera, V växlar
   karta/tredjeperson. Geometrin ligger i site.js — den här filen
   vet bara hur man går, krockar och ritar det fotona visar.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const GA={fart:1.7, jogg:3.3, svang:2.7, radie:0.35};
const VD={
  px:0, py:0, rikt:0, fas:0, tid:0,
  spår:[], hastX:0, hastY:0, hastRikt:0,
  prompt:null, ePrev:false, _ov:null,
};

const VCOL={
  gras:"#39462C", grasLj:"#455438", grus:"#7C766A", asfalt:"#44464A",
  sand:"#CFC5AC", sandKant:"#8E856D", aker:"#6E6544", betong:"#8A8B8C",
  slant:"#4A5836",
  tak:"#41454C", vit:"#E3DDD1", knut:"#D8D2C6",
  fonster:"#2E3A48", fonsterLj:"#55677A",
  dorrgul:"#C99435", dorrvit:"#DDD8CC", dorrgra:"#9A9C9E", dorrmork:"#3A3430",
  portplat:"#A8ABAD", portsilver:"#B9BCBE", dorr:"#26221E",
  himmel0:"#33404E", himmel1:"#8A93A0", skog:"#26301F",
  staketTra:"#9C9484", staketEl:"#7C766B", staketRail:"#7C2A24",
  galv:"#AEB2B5",
  stallVagg:"#CFC8BC", boxFront:"#3E4144", boxRam:"#AEB2B5", galler:"#8E9296",
  skylt:"#20242B", parlspont:"#E8E2D6",
};

function fargSkala(hex,f){
  const n=parseInt(hex.slice(1),16);
  const r=Math.min(255,(n>>16)*f)|0, g=Math.min(255,((n>>8)&255)*f)|0, b=Math.min(255,(n&255)*f)|0;
  return `rgb(${r},${g},${b})`;
}
/* Solen står i sydväst — söderfasader ljusast, norr i skugga. */
const SKUGGA={S:1.00,W:0.90,E:0.74,N:0.62,takW:0.96,takE:0.76,platt:0.88};

/* ── Gå-fysik ─────────────────────────────────────────────────── */
function kollideraRekt(nx,ny,r,rekt){
  const cx2=clamp(nx,rekt.x,rekt.x+rekt.w), cy=clamp(ny,rekt.y,rekt.y+rekt.h);
  const dx=nx-cx2, dy=ny-cy, d2=dx*dx+dy*dy;
  if(d2>=r*r) return [nx,ny];
  if(d2<1e-9){ // inne i rektangeln — knuffa ut åt närmsta kant
    const v=[nx-rekt.x, rekt.x+rekt.w-nx, ny-rekt.y, rekt.y+rekt.h-ny];
    const i=v.indexOf(Math.min(...v));
    if(i===0)return[rekt.x-r,ny]; if(i===1)return[rekt.x+rekt.w+r,ny];
    if(i===2)return[nx,rekt.y-r]; return[nx,rekt.y+rekt.h+r];
  }
  const d=Math.sqrt(d2);
  return [cx2+dx/d*r, cy+dy/d*r];
}
function kollideraSeg(nx,ny,r,ax,ay,bx,by){
  const abx=bx-ax,aby=by-ay,len2=abx*abx+aby*aby;
  const t=len2>0?clamp(((nx-ax)*abx+(ny-ay)*aby)/len2,0,1):0;
  const cx2=ax+abx*t, cy=ay+aby*t, dx=nx-cx2, dy=ny-cy, d2=dx*dx+dy*dy;
  if(d2>=r*r||d2<1e-9) return [nx,ny];
  const d=Math.sqrt(d2);
  return [cx2+dx/d*r, cy+dy/d*r];
}

function overlayUppe(){
  if(!VD._ov)VD._ov=document.getElementById("ov");
  return !VD._ov.classList.contains("hide");
}

function stegaVandring(dt){
  VD.tid+=dt;
  if(overlayUppe())return;
  const fram=(IN.ned.KeyW?1:0)-(IN.ned.KeyS?0.6:0);
  const sv=(IN.ned.KeyD?1:0)-(IN.ned.KeyA?1:0);
  VD.rikt+=sv*GA.svang*dt;
  const jogg=IN.ned.ShiftLeft||IN.ned.ShiftRight;
  const fart=fram*(jogg?GA.jogg:GA.fart);
  let nx=VD.px+Math.cos(VD.rikt)*fart*dt;
  let ny=VD.py+Math.sin(VD.rikt)*fart*dt;
  const r=GA.radie;
  if(G.scen==="gard"){
    for(const b of ANL.byggnader) [nx,ny]=kollideraRekt(nx,ny,r+0.2,b.rekt);
    for(const st of ANL.staket) for(let i=0;i<st.p.length-1;i++)
      [nx,ny]=kollideraSeg(nx,ny,r,st.p[i][0],st.p[i][1],st.p[i+1][0],st.p[i+1][1]);
    nx=clamp(nx,1,ANL.bredd-1); ny=clamp(ny,1,ANL.djup-1);
  }else{ // stallinne
    const S=STALLINNE, vx=S.bredd/2;
    nx=clamp(nx,0.5,S.bredd-0.5); ny=clamp(ny,0.5,S.langd-0.5);
    if(ny>S.boxStartY&&ny<S.serviceY){          // stallgången mellan boxfronterna
      nx=clamp(nx,vx-S.ganghalva+r,vx+S.ganghalva-r);
    }else{
      for(const rum of S.rum)     [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
      for(const rum of S.service) [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
    }
    for(const tv of S.tvarvaggar){               // tvärväggar med dörrgap
      [nx,ny]=kollideraSeg(nx,ny,r,0,tv.y,vx-tv.gap/2,tv.y);
      [nx,ny]=kollideraSeg(nx,ny,r,vx+tv.gap/2,tv.y,S.bredd,tv.y);
    }
  }
  VD.px=nx; VD.py=ny;
  if(Math.abs(fart)>0.05){
    VD.fas=(VD.fas+Math.abs(fart)*dt*1.9)%1;
    const s=VD.spår;
    if(!s.length||Math.hypot(nx-s[s.length-1][0],ny-s[s.length-1][1])>0.35)
      s.push([nx,ny]); if(s.length>40)s.shift();
  }
  // hästen följer 2,2 m bakom i spåret när du leder
  if(G.leder){
    let kvar=2.2, hx=VD.px, hy=VD.py, vin=VD.rikt;
    const s=VD.spår;
    let fx=VD.px, fy=VD.py;
    for(let i=s.length-1;i>=0;i--){
      const d=Math.hypot(fx-s[i][0],fy-s[i][1]);
      if(d>=kvar){const t=kvar/Math.max(d,1e-6);
        hx=fx+(s[i][0]-fx)*t; hy=fy+(s[i][1]-fy)*t;
        vin=Math.atan2(fy-s[i][1],fx-s[i][0]); kvar=0; break;}
      kvar-=d; fx=s[i][0]; fy=s[i][1];
    }
    if(kvar>0){hx=fx-Math.cos(VD.rikt)*kvar; hy=fy-Math.sin(VD.rikt)*kvar;}
    VD.hastX=hx; VD.hastY=hy; VD.hastRikt=vin;
  }
  interagera();
}

/* ── Interaktion ──────────────────────────────────────────────── */
function interaktioner(){
  const L=[];
  if(G.scen==="gard"){
    for(const d of ANL.dorrar){
      if(d.mot==="ridhus"){
        L.push({pos:d.pos, text:G.leder?`Led ${HORSES[G.hastId].namn} in — lektionen börjar`:d.text,
          gor(){ if(G.leder){G.leder=false; hudLage("ritt"); startaLektion();}
                 else saga("Lektionen börjar i stallet. Hämta din häst först.",3.2); }});
      }else if(d.mot==="info"){
        L.push({pos:d.pos, text:d.text, gor(){saga(d.info,4);}});
      }else{
        L.push({pos:d.pos, text:d.text, gor(){gaTill(d.mot,d.spawn);}});
      }
    }
  }else{
    const S=STALLINNE;
    for(const d of S.dorrar) L.push({pos:d.pos,
      text:G.leder?`Led hästen ${d.text.toLowerCase().replace("ut ","ut ")}`:d.text,
      gor(){gaTill(d.mot,d.spawn);}});
    if(!G.hastId) L.push({pos:S.ridlarare.pos, text:"Prata med ridläraren",
      gor(){visaTilldelning();}});
    if(G.hastId&&!G.skotselRes){
      const b=hittaBox(G.hastId);
      if(b) L.push({pos:b.dorr, text:`Gör i ordning ${HORSES[G.hastId].namn}`,
        gor(){visaSkotsel();}});
    }
  }
  return L;
}
function interagera(){
  const L=interaktioner(); let bast=null,bd=2.4;
  for(const i of L){const d=Math.hypot(VD.px-i.pos[0],VD.py-i.pos[1]); if(d<bd){bd=d;bast=i;}}
  VD.prompt=bast;
  const e=!!IN.ned.KeyE;
  if(e&&!VD.ePrev&&bast&&!overlayUppe()) bast.gor();
  VD.ePrev=e;
}
function hittaBox(hastId){
  const S=STALLINNE;
  for(const sida of ["W","E"]){
    const rad=S.boxar[sida];
    for(let i=0;i<rad.length;i++) if(rad[i]===hastId){
      const y=S.boxStartY+i*S.boxB+S.boxB/2;
      const x=sida==="W"?S.bredd/2-S.ganghalva:S.bredd/2+S.ganghalva;
      return {sida,i,y,dorr:[x,y]};
    }
  }
  return null;
}
/* Boxens skylt/häst: HORSES-id, "#NAMN" (riktig skylt, sällskapshäst)
   eller null (tom box). */
const SALLSKAPSFARG=["#5C4633","#6E5138","#4A3A2C","#7A5C40","#3E3128","#8A6E4E"];
function boxHast(id){
  if(!id)return null;
  if(id[0]==="#"){
    let h=0;for(const c of id)h=(h*31+c.charCodeAt(0))%997;
    return {namn:id.slice(1), farg:SALLSKAPSFARG[h%SALLSKAPSFARG.length], man:"#241A12", spelbar:false};
  }
  const h=HORSES[id];
  return h?{namn:h.namn, farg:h.farg, man:h.man, spelbar:true}:null;
}

/* ── Scenbyten ────────────────────────────────────────────────── */
function gaTill(scen,spawn){
  G.scen=scen;
  if(spawn){VD.px=spawn.x;VD.py=spawn.y;VD.rikt=spawn.rikt;VD.spår.length=0;}
}
function startaVandring(){
  overlay(false);
  G.scen="gard"; G.hastId=null; G.skotselRes=null; G.leder=false;
  const s=ANL.spawn; VD.px=s.x;VD.py=s.y;VD.rikt=s.rikt;VD.spår.length=0;
  hudLage("gang");
  saga("Du är framme på Husbyvägen 1A. Ridläraren väntar i stallgången.",4.5);
}
function hudLage(lage){
  const gang=lage==="gang";
  for(const id of ["pyr","aids","gait"]){
    const el=document.getElementById(id);
    if(el){const hud=el.closest(".hud")||el; hud.style.display=gang?"none":"";}
  }
  const vt=document.getElementById("viewToggle");
  vt.hidden=false;
  vt.querySelector('[data-v="2d"]').textContent=gang?"Karta":"Bana";
  vt.querySelector('[data-v="3d"]').textContent=gang?"Bakom dig":"Bakom hästen";
}
function visaUppgift(rubrik,text){
  document.getElementById("momentLbl").textContent="Uppgift";
  document.getElementById("momentNamn").textContent=rubrik;
  document.getElementById("momentText").textContent=text||"";
  document.querySelector("#momentBar i").style.width="0%";
}

/* ── 3D-maskineri: kamera, near-klipp, painter ────────────────── */
const K3={hojd:1.62, bak:3.6, fov:1.02, horisont:0.52, nara:0.35};
function kamera(){
  let kx=VD.px-Math.cos(VD.rikt)*K3.bak, ky=VD.py-Math.sin(VD.rikt)*K3.bak;
  if(G.scen==="gard")
    for(const b of ANL.byggnader)[kx,ky]=kollideraRekt(kx,ky,0.4,b.rekt);
  return {x:kx, y:ky,
    z:K3.hojd+0.5, fx:Math.cos(VD.rikt), fy:Math.sin(VD.rikt),
    f:(CH*0.92)/K3.fov, hor:CH*K3.horisont};
}
function tillKam(k,x,y,z){
  const dx=x-k.x, dy=y-k.y;
  return {d:dx*k.fx+dy*k.fy, s:-dx*k.fy+dy*k.fx, h:z-k.z};
}
function projK(k,p){ return [CW/2+p.s/p.d*k.f, k.hor-p.h/p.d*k.f]; }
function klippPoly(pts){ // Sutherland–Hodgman mot d >= K3.nara
  const ut=[];
  for(let i=0;i<pts.length;i++){
    const a=pts[i], b=pts[(i+1)%pts.length];
    const ain=a.d>=K3.nara, bin=b.d>=K3.nara;
    if(ain)ut.push(a);
    if(ain!==bin){
      const t=(K3.nara-a.d)/(b.d-a.d);
      ut.push({d:K3.nara, s:a.s+(b.s-a.s)*t, h:a.h+(b.h-a.h)*t});
    }
  }
  return ut;
}
function ritaPoly3D(k,varldPts,fill,kant){
  let pts=varldPts.map(p=>tillKam(k,p[0],p[1],p[2]));
  pts=klippPoly(pts); if(pts.length<3)return;
  cx.beginPath();
  const s0=projK(k,pts[0]); cx.moveTo(s0[0],s0[1]);
  for(let i=1;i<pts.length;i++){const s=projK(k,pts[i]);cx.lineTo(s[0],s[1]);}
  cx.closePath();
  if(fill){cx.fillStyle=fill;cx.fill();}
  if(kant){cx.strokeStyle=kant;cx.lineWidth=1;cx.stroke();}
}
function ritaLinje3D(k,a,b,farg,bredd){
  const p0=tillKam(k,a[0],a[1],a[2]), p1=tillKam(k,b[0],b[1],b[2]);
  if(p0.d<K3.nara&&p1.d<K3.nara)return;
  let A=p0,B=p1;
  if(A.d<K3.nara){const t=(K3.nara-A.d)/(B.d-A.d);
    A={d:K3.nara,s:A.s+(B.s-A.s)*t,h:A.h+(B.h-A.h)*t};}
  if(B.d<K3.nara){const t=(K3.nara-B.d)/(A.d-B.d);
    B={d:K3.nara,s:B.s+(A.s-B.s)*t,h:B.h+(A.h-B.h)*t};}
  const s0=projK(k,A), s1=projK(k,B);
  cx.strokeStyle=farg; cx.lineWidth=bredd;
  cx.beginPath();cx.moveTo(s0[0],s0[1]);cx.lineTo(s1[0],s1[1]);cx.stroke();
}
function ritaText3D(k,x,y,z,txt,storlek,farg,font){
  const p=tillKam(k,x,y,z); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(storlek*k.f/(p.d*38),7,42);
  cx.fillStyle=farg; cx.font=`600 ${sz}px ${font||'"IBM Plex Mono",monospace'}`;
  cx.textAlign="center"; cx.fillText(txt,s[0],s[1]);
}
function avst2(p){return (p[0]-VD.px)**2+(p[1]-VD.py)**2;}

/* ── Byggnader ────────────────────────────────────────────────── */
function byggnadsYtor(b){
  const {x,y,w,h}=b.rekt, hV=b.hV, hN=b.hN, mx=x+w/2, my=y+h/2, ytor=[];
  const hörn={SW:[x,y],SE:[x+w,y],NE:[x+w,y+h],NW:[x,y+h]};
  const vagg=(p0,p1,sida)=>{
    const gavel=(b.nock==="NS"&&(sida==="S"||sida==="N"))||(b.nock==="EW"&&(sida==="E"||sida==="W"));
    const pts=[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],hV]];
    if(gavel){
      const m=[(p0[0]+p1[0])/2,(p0[1]+p1[1])/2];
      pts.push([m[0],m[1],hN]);
    }
    pts.push([p0[0],p0[1],hV]);
    ytor.push({mitt:[(p0[0]+p1[0])/2,(p0[1]+p1[1])/2], pts,
      farg:fargSkala(b.fargV,SKUGGA[sida]), sida, p0, p1});
  };
  vagg(hörn.SW,hörn.SE,"S"); vagg(hörn.SE,hörn.NE,"E");
  vagg(hörn.NE,hörn.NW,"N"); vagg(hörn.NW,hörn.SW,"W");
  if(b.nock==="NS"){
    ytor.push({mitt:[x+w*0.25,my], tak:true, farg:fargSkala(b.fargT,SKUGGA.takW),
      pts:[[x,y,hV],[x,y+h,hV],[mx,y+h,hN],[mx,y,hN]]});
    ytor.push({mitt:[x+w*0.75,my], tak:true, farg:fargSkala(b.fargT,SKUGGA.takE),
      pts:[[x+w,y,hV],[x+w,y+h,hV],[mx,y+h,hN],[mx,y,hN]]});
  }else{
    ytor.push({mitt:[mx,y+h*0.25], tak:true, farg:fargSkala(b.fargT,SKUGGA.takE),
      pts:[[x,y,hV],[x+w,y,hV],[x+w,my,hN],[x,my,hN]]});
    ytor.push({mitt:[mx,y+h*0.75], tak:true, farg:fargSkala(b.fargT,SKUGGA.takW),
      pts:[[x,y+h,hV],[x+w,y+h,hV],[x+w,my,hN],[x,my,hN]]});
  }
  return ytor;
}
function vaggPunkt(b,sida){ // fasadens p0→p1 (medurs sedd utifrån)
  const {x,y,w,h}=b.rekt;
  if(sida==="S")return[[x,y],[x+w,y]];
  if(sida==="E")return[[x+w,y],[x+w,y+h]];
  if(sida==="N")return[[x+w,y+h],[x,y+h]];
  return[[x,y+h],[x,y]];
}
function ritaOppning(k,b,o){
  const [p0,p1]=vaggPunkt(b,o.sida);
  const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]), ux=(p1[0]-p0[0])/L, uy=(p1[1]-p0[1])/L;
  const P=(u,z)=>[p0[0]+ux*u, p0[1]+uy*u, z];
  const FARG={dorr:VCOL.dorr, dorrgul:VCOL.dorrgul, dorrvit:VCOL.dorrvit,
    dorrgra:VCOL.dorrgra, dorrmork:VCOL.dorrmork, portplat:VCOL.portplat,
    portsilver:VCOL.portsilver, fonster:VCOL.fonster, valv:VCOL.fonster,
    rund:VCOL.fonster};
  const farg=FARG[o.typ]||VCOL.dorr;
  if(o.typ==="valv"){       // välvt spröjsfönster: rekt + båge
    const pts=[P(o.u,o.z0),P(o.u+o.b,o.z0),P(o.u+o.b,o.z0+o.h*0.7)];
    for(let i=1;i<5;i++){const t=i/5;
      pts.push(P(o.u+o.b*(1-t), o.z0+o.h*(0.7+0.3*Math.sin(Math.PI*t))));}
    pts.push(P(o.u,o.z0+o.h*0.7));
    ritaPoly3D(k,pts,farg,VCOL.knut);
  }else if(o.typ==="rund"){ // bullseye-fönster
    const cu=o.u+o.b/2, cz=o.z0+o.h/2, pts=[];
    for(let i=0;i<10;i++){const v=i/10*Math.PI*2;
      pts.push(P(cu+Math.cos(v)*o.b/2, cz+Math.sin(v)*o.h/2));}
    ritaPoly3D(k,pts,farg,VCOL.knut);
  }else{
    ritaPoly3D(k,[P(o.u,o.z0),P(o.u+o.b,o.z0),P(o.u+o.b,o.z0+o.h),P(o.u,o.z0+o.h)],
      farg, o.typ==="portplat"?"#5A5C5E":VCOL.knut);
    if(o.typ==="fonster")
      ritaPoly3D(k,[P(o.u,o.z0+o.h*0.55),P(o.u+o.b,o.z0+o.h*0.55),
        P(o.u+o.b,o.z0+o.h),P(o.u,o.z0+o.h)],VCOL.fonsterLj,null);
  }
}
function ritaHuvar(k,b){ // stallets rad av svarta ventilationshuvar på nocken
  const {x,y,w,h}=b.rekt, mx=x+w/2;
  for(let yy=y+3;yy<y+h-2;yy+=4.6){
    ritaPoly3D(k,[[mx-0.35,yy,b.hN],[mx+0.35,yy,b.hN],
      [mx+0.35,yy,b.hN+0.8],[mx-0.35,yy,b.hN+0.8]],"#1C1E20",null);
    ritaPoly3D(k,[[mx-0.5,yy,b.hN+0.8],[mx+0.5,yy,b.hN+0.8],
      [mx+0.5,yy,b.hN+0.95],[mx-0.5,yy,b.hN+0.95]],"#26282A",null);
  }
}

/* ── Rekvisita i 3D ───────────────────────────────────────────── */
function billboard(k,x,y,storlek){
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return null;
  const s=projK(k,p);
  return {s, sz:clamp(storlek*k.f/p.d,2,CH), d:p.d};
}
function ritaProp3D(k,p){
  const [x,y]=p.pos;
  if(p.norm && (k.x-x)*p.norm[0]+(k.y-y)*p.norm[1] < 0) return; // fasadprop, fel sida
  switch(p.typ){
    case "silo":{ const B=billboard(k,x,y,5.6); if(!B)return;
      const {s,sz}=B, br=sz*0.24;
      cx.fillStyle="#9EA2A6";
      cx.fillRect(s[0]-br/2,s[1]-sz,br,sz*0.62);
      cx.beginPath();cx.moveTo(s[0]-br/2,s[1]-sz*0.38);cx.lineTo(s[0]+br/2,s[1]-sz*0.38);
      cx.lineTo(s[0]+br*0.12,s[1]-sz*0.16);cx.lineTo(s[0]-br*0.12,s[1]-sz*0.16);cx.closePath();cx.fill();
      cx.strokeStyle="#6E7276";cx.lineWidth=Math.max(1,sz*0.014);
      cx.beginPath();cx.moveTo(s[0]-br*0.4,s[1]);cx.lineTo(s[0]-br*0.4,s[1]-sz*0.3);
      cx.moveTo(s[0]+br*0.4,s[1]);cx.lineTo(s[0]+br*0.4,s[1]-sz*0.3);cx.stroke();
      cx.beginPath();cx.moveTo(s[0]-br/2,s[1]-sz,br,sz*0.62);cx.stroke();
      break;}
    case "balar":{ // ensilagebalar i två lager
      for(let i=0;i<5;i++){const B=billboard(k,x+ (i%3)*1.6, y+((i/3)|0)*1.4, 1.3);
        if(!B)continue;const {s,sz}=B;
        cx.fillStyle="#DDDBD4";
        cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.55,sz*0.45,0,0,Math.PI*2);cx.fill();
        cx.strokeStyle="#B9B7B0";cx.lineWidth=1;
        cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.34,sz*0.28,0,0,Math.PI*2);cx.stroke();}
      break;}
    case "grushog":{ const B=billboard(k,x,y,1.4); if(!B)return;
      const {s,sz}=B; cx.fillStyle="#7C7870";
      cx.beginPath();cx.moveTo(s[0]-sz*0.8,s[1]);cx.quadraticCurveTo(s[0],s[1]-sz*1.0,s[0]+sz*0.8,s[1]);
      cx.closePath();cx.fill(); break;}
    case "transport":{ const B=billboard(k,x,y,2.4); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="rgba(0,0,0,.25)";
      cx.beginPath();cx.ellipse(s[0],s[1],sz*0.7,sz*0.1,0,0,Math.PI*2);cx.fill();
      cx.fillStyle="#E4E2DC";
      cx.beginPath();cx.moveTo(s[0]-sz*0.65,s[1]);cx.lineTo(s[0]-sz*0.65,s[1]-sz*0.62);
      cx.quadraticCurveTo(s[0],s[1]-sz*0.82,s[0]+sz*0.65,s[1]-sz*0.62);
      cx.lineTo(s[0]+sz*0.65,s[1]);cx.closePath();cx.fill();
      cx.fillStyle="#B9B7B0";cx.fillRect(s[0]-sz*0.65,s[1]-sz*0.14,sz*1.3,sz*0.05);
      cx.fillStyle="#2A2C2E";
      cx.beginPath();cx.arc(s[0]-sz*0.3,s[1],sz*0.09,0,Math.PI*2);
      cx.arc(s[0]+sz*0.3,s[1],sz*0.09,0,Math.PI*2);cx.fill();
      break;}
    case "bord":{ const B=billboard(k,x,y,1.0); if(!B)return;
      const {s,sz}=B; cx.strokeStyle="#5E5648";cx.lineWidth=Math.max(1.5,sz*0.08);
      cx.beginPath();cx.moveTo(s[0]-sz*0.7,s[1]-sz*0.5);cx.lineTo(s[0]+sz*0.7,s[1]-sz*0.5);
      cx.moveTo(s[0]-sz*0.5,s[1]-sz*0.5);cx.lineTo(s[0]-sz*0.8,s[1]);
      cx.moveTo(s[0]+sz*0.5,s[1]-sz*0.5);cx.lineTo(s[0]+sz*0.8,s[1]);
      cx.moveTo(s[0]-sz*0.9,s[1]-sz*0.28);cx.lineTo(s[0]+sz*0.9,s[1]-sz*0.28);
      cx.stroke(); break;}
    case "bank": case "stol":{ const B=billboard(k,x,y,0.9); if(!B)return;
      const {s,sz}=B, br=p.typ==="bank"?0.8:0.3;
      cx.strokeStyle="#8C8474";cx.lineWidth=Math.max(1.5,sz*0.09);
      cx.beginPath();cx.moveTo(s[0]-sz*br,s[1]-sz*0.45);cx.lineTo(s[0]+sz*br,s[1]-sz*0.45);
      cx.moveTo(s[0]-sz*br,s[1]-sz*0.85);cx.lineTo(s[0]-sz*br,s[1]);
      cx.moveTo(s[0]+sz*br,s[1]-sz*0.85);cx.lineTo(s[0]+sz*br,s[1]);cx.stroke();
      break;}
    case "trappa":{ // cafétrappan i galvat stål på södra gaveln
      const steg=7;
      for(let i=0;i<=steg;i++){
        const t=i/steg;
        ritaLinje3D(k,[x-2.6+t*2.6,y,0.1+t*3.6],[x-2.6+t*2.6,y-0.9,0.1+t*3.6],VCOL.galv,2);
      }
      ritaLinje3D(k,[x-2.6,y-0.45,1.1],[x,y-0.45,4.6],VCOL.galv,2.5);
      ritaLinje3D(k,[x,y,3.8],[x+1.4,y,3.8],VCOL.galv,2.5);   // avsatsen
      ritaLinje3D(k,[x,y-0.9,3.8],[x+1.4,y-0.9,3.8],VCOL.galv,1.5);
      ritaLinje3D(k,[x+1.4,y-0.9,3.8],[x+1.4,y-0.9,4.8],VCOL.galv,1.5);
      break;}
    case "skylt":{ // UBRF-skylten: vitt band med text på fasaden
      const b=ANL.byggnader.find(bb=>bb.id==="ridhus");
      ritaPoly3D(k,[[x-0.05,y-5,3.4],[x-0.05,y+5,3.4],[x-0.05,y+5,4.4],[x-0.05,y-5,4.4]],
        "#E8E4DA","#B9B5AB");
      ritaText3D(k,x-0.1,y,3.75,p.text,2.6,"#5A5F66");
      break;}
    case "cafeskylt":
      ritaPoly3D(k,[[x-0.5,y,2.6],[x+0.5,y,2.6],[x+0.5,y,3.0],[x-0.5,y,3.0]],"#E8E4DA","#3A3E44");
      ritaText3D(k,x,y,2.72,"CAFÉ KRUBBAN",1.6,"#2F5C8F");
      break;
    case "flagga":{
      ritaLinje3D(k,[x,y,0],[x,y,7],"#D8D2C6",2.5);
      ritaPoly3D(k,[[x,y,7],[x+1.6,y,6.7],[x,y,6.2]],"#3A6EA5",null);
      break;}
    case "skyltstolpe":{
      ritaLinje3D(k,[x,y,0],[x,y,2.6],"#2A2C2E",3);
      const namn=["Framridning","Ridhus","Information","Stallentré","Toaletter","Utebana"];
      for(let i=0;i<namn.length;i++){
        const z=2.5-i*0.3;
        ritaPoly3D(k,[[x,y,z-0.12],[x+1.3,y,z-0.12],[x+1.3,y,z+0.12],[x,y,z+0.12]],"#22242A",null);
        ritaText3D(k,x+0.65,y,z,namn[i],1.0,"#D8D2C6");
      }
      break;}
    case "stenhast":{ const B=billboard(k,x,y,0.9); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle=["#C9C2B4","#A8A29A","#3A3A3A","#C9C2B4"][(x*7|0)%4];
      cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.42,sz*0.26,0,0,Math.PI*2);cx.fill();
      cx.beginPath();cx.ellipse(s[0]+sz*0.34,s[1]-sz*0.66,sz*0.13,sz*0.2,0.4,0,Math.PI*2);cx.fill();
      cx.fillRect(s[0]-sz*0.3,s[1]-sz*0.3,sz*0.09,sz*0.3);
      cx.fillRect(s[0]+sz*0.18,s[1]-sz*0.3,sz*0.09,sz*0.3);
      break;}
    case "mast":{
      ritaLinje3D(k,[x,y,0],[x,y,8],"#6E7276",2.5);
      ritaPoly3D(k,[[x-0.5,y,8],[x+0.5,y,8],[x+0.5,y,8.35],[x-0.5,y,8.35]],"#D8D8CC",null);
      break;}
    case "sopstation":{ const B=billboard(k,x,y,1.6); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="#7A7C72";cx.fillRect(s[0]-sz*0.9,s[1]-sz*0.8,sz*1.2,sz*0.8);
      cx.fillStyle="#4E6E4E";cx.fillRect(s[0]+sz*0.35,s[1]-sz*0.65,sz*0.6,sz*0.65);
      break;}
    case "ac":{ const B=billboard(k,x,y,0.8); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="#DDDBD4";cx.fillRect(s[0]-sz*0.5,s[1]-sz*0.9,sz,sz*0.6);
      cx.strokeStyle="#9A988E";cx.strokeRect(s[0]-sz*0.5,s[1]-sz*0.9,sz,sz*0.6);
      break;}
    case "veranda":{ // vita stolpar, räcke och skärmtak vid stallentrén
      const b=3.4, dj=1.6;
      for(const [px,py] of [[x-b/2,y-dj],[x+b/2,y-dj]]){
        ritaLinje3D(k,[px,py,0],[px,py,2.5],"#E3DDD1",3);
      }
      ritaPoly3D(k,[[x-b/2-0.2,y-dj-0.2,2.5],[x+b/2+0.2,y-dj-0.2,2.5],
        [x+b/2+0.2,y+0.4,2.9],[x-b/2-0.2,y+0.4,2.9]],"#C9C4B8","#9A968C");
      for(const sida of [-1,1]){
        ritaLinje3D(k,[x+sida*b/2,y-dj,1.0],[x+sida*b/2,y,1.0],"#E3DDD1",2);
        for(let i=1;i<4;i++)
          ritaLinje3D(k,[x+sida*b/2,y-dj+i*dj/4,0.15],[x+sida*b/2,y-dj+i*dj/4,1.0],"#E3DDD1",1.2);
      }
      break;}
    case "busskylt":{
      ritaLinje3D(k,[x,y,0],[x,y,2.4],"#6E7276",2);
      ritaPoly3D(k,[[x-0.3,y,2.4],[x+0.3,y,2.4],[x+0.3,y,2.9],[x-0.3,y,2.9]],"#3E6E4E",null);
      break;}
  }
}

/* ── Gården i 3D ──────────────────────────────────────────────── */
function markFarg(typ){
  return typ==="gras"?VCOL.grasLj:typ==="grus"?VCOL.grus:typ==="asfalt"?VCOL.asfalt
    :typ==="aker"?VCOL.aker:typ==="betong"?VCOL.betong:typ==="slant"?VCOL.slant:VCOL.sand;
}
function ritaGard3D(){
  const k=kamera();
  const gr=cx.createLinearGradient(0,0,0,k.hor);
  gr.addColorStop(0,VCOL.himmel0); gr.addColorStop(1,VCOL.himmel1);
  cx.fillStyle=gr; cx.fillRect(0,0,CW,k.hor);
  cx.fillStyle=VCOL.skog; cx.fillRect(0,k.hor-CH*0.035,CW,CH*0.035);
  cx.fillStyle=VCOL.gras; cx.fillRect(0,k.hor,CW,CH-k.hor);
  for(const m of ANL.mark){ if(m.typ==="gras")continue;
    const r=m.rekt;
    ritaPoly3D(k,[[r.x,r.y,0.01],[r.x+r.w,r.y,0.01],[r.x+r.w,r.y+r.h,0.01],[r.x,r.y+r.h,0.01]],
      fargSkala(markFarg(m.typ),SKUGGA.platt),null);
  }
  for(const c of ANL.cirklar){
    const pts=[];
    for(let i=0;i<14;i++){const v=i/14*Math.PI*2;
      pts.push([c.c[0]+Math.cos(v)*c.r, c.c[1]+Math.sin(v)*c.r, 0.015]);}
    ritaPoly3D(k,pts,fargSkala(markFarg(c.typ),SKUGGA.platt),c.kant?VCOL.sandKant:null);
  }
  const items=[];
  for(const b of ANL.byggnader){
    for(const y of byggnadsYtor(b))
      items.push({d:-avst2(y.mitt), rita(){
        ritaPoly3D(k,y.pts,y.farg,fargSkala(y.farg,0.75));
        if(!y.tak) for(const o of (b.oppningar||[])) if(o.sida===y.sida) ritaOppning(k,b,o);
      }});
    if(b.huvar) items.push({d:-avst2([b.rekt.x+b.rekt.w/2,b.rekt.y+b.rekt.h/2])+1,
      rita(){ritaHuvar(k,b);}});
  }
  for(const st of ANL.staket) for(let i=0;i<st.p.length-1;i++){
    const a=st.p[i], c=st.p[i+1];
    items.push({d:-avst2([(a[0]+c[0])/2,(a[1]+c[1])/2]), rita(){ritaStaket3D(k,a,c,st.typ);}});
  }
  for(const t of ANL.trad) items.push({d:-avst2(t), rita(){ritaTrad3D(k,t);}});
  for(const p of ANL.props) items.push({d:-avst2(p.pos), rita(){ritaProp3D(k,p);}});
  for(const hg of ANL.hagar) for(let i=0;i<hg.hastar.length;i++){
    const h=HORSES[hg.hastar[i]]; if(!h)continue;
    const hx=hg.rekt.x+hg.rekt.w*(0.25+0.5*((i*0.618)%1));
    const hy=hg.rekt.y+hg.rekt.h*(0.3+0.45*((i*0.377)%1));
    items.push({d:-avst2([hx,hy]), rita(){ritaHage3DHast(k,hx,hy,h,i);}});
  }
  for(const d of ANL.dorrar) items.push({d:-avst2(d.pos), rita(){ritaMarkor3D(k,d.pos);}});
  if(G.leder) items.push({d:-avst2([VD.hastX,VD.hastY]), rita(){ritaLeddHast3D(k);}});
  items.sort((a,b)=>a.d-b.d);
  for(const o of items)o.rita();
  ritaSpelare3D();
}
function ritaStaket3D(k,a,c,typ){
  const L=Math.hypot(c[0]-a[0],c[1]-a[1]); if(L<0.01)return;
  const n=Math.max(1,Math.round(L/2.6));
  const hj=typ==="tra"?1.25:typ==="rail"?0.85:1.0;
  const farg=typ==="tra"?VCOL.staketTra:typ==="rail"?VCOL.staketRail:VCOL.staketEl;
  for(let i=0;i<=n;i++){
    const t=i/n, px=a[0]+(c[0]-a[0])*t, py=a[1]+(c[1]-a[1])*t;
    const p0=tillKam(k,px,py,0), p1=tillKam(k,px,py,hj);
    if(p0.d<K3.nara||p1.d<K3.nara)continue;
    const s0=projK(k,p0), s1=projK(k,p1);
    cx.strokeStyle=farg; cx.lineWidth=Math.max(1,k.f*0.06/p0.d);
    cx.beginPath();cx.moveTo(s0[0],s0[1]);cx.lineTo(s1[0],s1[1]);cx.stroke();
  }
  ritaLinje3D(k,[a[0],a[1],hj],[c[0],c[1],hj],farg,typ==="el"?1:2.2);
  if(typ!=="el")ritaLinje3D(k,[a[0],a[1],hj*0.55],[c[0],c[1],hj*0.55],farg,typ==="rail"?1.6:2);
}
function ritaTrad3D(k,t){
  const p=tillKam(k,t[0],t[1],0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=t[2]*k.f/p.d;
  cx.strokeStyle="#3A3128"; cx.lineWidth=Math.max(1.5,sz*0.09);
  cx.beginPath();cx.moveTo(s[0],s[1]);cx.lineTo(s[0],s[1]-sz*1.1);cx.stroke();
  cx.fillStyle="#25301F";
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*1.5,sz*0.65,sz*0.75,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#2E3B26";
  cx.beginPath();cx.ellipse(s[0]-sz*0.2,s[1]-sz*1.62,sz*0.42,sz*0.5,0,0,Math.PI*2);cx.fill();
}
function ritaHage3DHast(k,x,y,h,i){
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.6*k.f/p.d,3,90);
  const beta=Math.sin(VD.tid*0.6+i*2.1)>0.3; // betar med huvudet nere
  cx.fillStyle="rgba(0,0,0,.25)";
  cx.beginPath();cx.ellipse(s[0],s[1],sz*0.62,sz*0.13,0,0,Math.PI*2);cx.fill();
  cx.fillStyle=h.farg;
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.52,sz*0.58,sz*0.34,0,0,Math.PI*2);cx.fill();
  for(const bx of[-0.38,-0.16,0.14,0.36])
    cx.fillRect(s[0]+bx*sz-sz*0.035,s[1]-sz*0.36,sz*0.07,sz*0.38);
  const hx=s[0]+sz*0.62, hy=beta?s[1]-sz*0.12:s[1]-sz*0.78;
  cx.beginPath();cx.ellipse(s[0]+sz*0.52,s[1]-(beta?sz*0.35:sz*0.68),sz*0.16,sz*0.28,beta?0.9:0.25,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(hx,hy,sz*0.12,sz*0.17,beta?1.2:0.5,0,Math.PI*2);cx.fill();
  cx.strokeStyle=h.man;cx.lineWidth=Math.max(1,sz*0.06);
  cx.beginPath();cx.moveTo(s[0]-sz*0.58,s[1]-sz*0.6);cx.lineTo(s[0]-sz*0.66,s[1]-sz*0.1);cx.stroke();
}
function ritaMarkor3D(k,pos){
  const p=tillKam(k,pos[0],pos[1],2.6+0.15*Math.sin(VD.tid*3));
  if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(0.4*k.f/p.d,4,18);
  cx.fillStyle="rgba(214,174,60,.85)";
  cx.beginPath();cx.moveTo(s[0],s[1]+sz);cx.lineTo(s[0]-sz*0.6,s[1]-sz*0.4);
  cx.lineTo(s[0]+sz*0.6,s[1]-sz*0.4);cx.closePath();cx.fill();
}
function ritaLeddHast3D(k){
  const h=HORSES[G.hastId]; if(!h)return;
  const p=tillKam(k,VD.hastX,VD.hastY,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.7*k.f/p.d,6,240);
  const bob=Math.sin(VD.fas*Math.PI*2)*sz*0.02;
  cx.fillStyle="rgba(0,0,0,.28)";
  cx.beginPath();cx.ellipse(s[0],s[1],sz*0.6,sz*0.13,0,0,Math.PI*2);cx.fill();
  cx.fillStyle=h.farg;
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.55+bob,sz*0.56,sz*0.36,0,0,Math.PI*2);cx.fill();
  for(const bx of[-0.36,-0.14,0.16,0.38]){
    const sving=Math.sin(VD.fas*Math.PI*2+(bx>0?0:Math.PI))*sz*0.05;
    cx.fillRect(s[0]+bx*sz-sz*0.04+sving,s[1]-sz*0.38,sz*0.08,sz*0.4);}
  cx.beginPath();cx.ellipse(s[0]+sz*0.5,s[1]-sz*0.86+bob,sz*0.17,sz*0.3,0.35,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(s[0]+sz*0.66,s[1]-sz*1.02+bob,sz*0.13,sz*0.18,0.5,0,Math.PI*2);cx.fill();
  cx.strokeStyle=h.man;cx.lineWidth=Math.max(1.5,sz*0.06);
  cx.beginPath();cx.moveTo(s[0]+sz*0.42,s[1]-sz*0.95);cx.quadraticCurveTo(s[0]+sz*0.3,s[1]-sz*0.75,s[0]+sz*0.28,s[1]-sz*0.6);cx.stroke();
  cx.beginPath();cx.moveTo(s[0]-sz*0.56,s[1]-sz*0.62);cx.lineTo(s[0]-sz*0.64,s[1]-sz*0.12);cx.stroke();
}
function ritaSpelare3D(){
  const y0=CH*0.995, x0=CW/2, s=CH*0.30;
  const gung=Math.sin(VD.fas*Math.PI*2)*s*0.03;
  cx.fillStyle="#23272E";
  cx.beginPath();
  cx.moveTo(x0-s*0.30,CH+2);
  cx.quadraticCurveTo(x0-s*0.32,y0-s*0.52+gung,x0-s*0.18,y0-s*0.60+gung);
  cx.lineTo(x0+s*0.18,y0-s*0.60+gung);
  cx.quadraticCurveTo(x0+s*0.32,y0-s*0.52+gung,x0+s*0.30,CH+2);
  cx.closePath();cx.fill();
  cx.fillStyle="#181B20";
  cx.beginPath();cx.ellipse(x0,y0-s*0.72+gung,s*0.155,s*0.17,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#0F1114";
  cx.beginPath();cx.ellipse(x0,y0-s*0.76+gung,s*0.15,s*0.12,0,0,Math.PI,true);cx.fill();
}

/* ── Gården i 2D (karta) ─────────────────────────────────────── */
const V2G={s:4,ox:0,oy:0};
function g2fit(){
  const m=26;
  V2G.s=Math.min((CW-2*m)/ANL.bredd,(CH-2*m)/ANL.djup);
  V2G.ox=(CW-ANL.bredd*V2G.s)/2; V2G.oy=(CH-ANL.djup*V2G.s)/2;
}
function gs(x,y){return [V2G.ox+x*V2G.s, V2G.oy+(ANL.djup-y)*V2G.s];}
function gsRekt(r){const[a,b]=gs(r.x,r.y+r.h);return[a,b,r.w*V2G.s,r.h*V2G.s];}
function ritaGard2D(){
  g2fit();
  cx.fillStyle=VCOL.gras; cx.fillRect(0,0,CW,CH);
  const s=V2G.s;
  for(const m of ANL.mark){const[a,b,w,h]=gsRekt(m.rekt);
    cx.fillStyle=markFarg(m.typ); cx.fillRect(a,b,w,h);
    if(m.typ==="sand"){cx.strokeStyle=VCOL.sandKant;cx.lineWidth=1.5;cx.strokeRect(a,b,w,h);}}
  for(const c of ANL.cirklar){const[a,b]=gs(c.c[0],c.c[1]);
    cx.fillStyle=markFarg(c.typ);
    cx.beginPath();cx.arc(a,b,c.r*s,0,Math.PI*2);cx.fill();
    if(c.kant){cx.strokeStyle=VCOL.sandKant;cx.lineWidth=1.5;cx.stroke();}}
  for(const st of ANL.staket){
    cx.strokeStyle=st.typ==="tra"?VCOL.staketTra:st.typ==="rail"?VCOL.staketRail:VCOL.staketEl;
    cx.lineWidth=st.typ==="el"?1.2:2;
    cx.beginPath();
    for(let i=0;i<st.p.length;i++){const[a,b]=gs(st.p[i][0],st.p[i][1]);
      i?cx.lineTo(a,b):cx.moveTo(a,b);}
    cx.stroke();}
  for(const t of ANL.trad){const[a,b]=gs(t[0],t[1]);
    cx.fillStyle="#25301F";cx.beginPath();cx.arc(a,b,t[2]*s*0.8,0,Math.PI*2);cx.fill();}
  for(const p of ANL.props){const[a,b]=gs(p.pos[0],p.pos[1]);
    if(p.typ==="silo"){cx.fillStyle="#9EA2A6";cx.beginPath();cx.arc(a,b,s*1.2,0,Math.PI*2);cx.fill();}
    else if(p.typ==="balar"){cx.fillStyle="#DDDBD4";
      for(let i=0;i<5;i++)cx.fillRect(a+(i%3)*s*1.4,b-((i/3)|0)*s*1.2,s*1.2,s*1.0);}
    else if(p.typ==="transport"){cx.fillStyle="#E4E2DC";
      cx.save();cx.translate(a,b);cx.rotate(-(p.rikt||0));cx.fillRect(-s*1.8,-s*0.9,s*3.6,s*1.8);cx.restore();}
    else if(p.typ==="stenhast"){cx.fillStyle="#A8A29A";cx.beginPath();cx.arc(a,b,s*0.45,0,Math.PI*2);cx.fill();}
    else if(p.typ==="mast"||p.typ==="flagga"){cx.fillStyle="#B9BCBE";cx.beginPath();cx.arc(a,b,s*0.35,0,Math.PI*2);cx.fill();}
  }
  for(const hg of ANL.hagar)for(let i=0;i<hg.hastar.length;i++){
    const h=HORSES[hg.hastar[i]];if(!h)continue;
    const hx=hg.rekt.x+hg.rekt.w*(0.25+0.5*((i*0.618)%1));
    const hy=hg.rekt.y+hg.rekt.h*(0.3+0.45*((i*0.377)%1));
    const[a,b]=gs(hx,hy);
    cx.fillStyle=h.farg;cx.beginPath();cx.ellipse(a,b,s*0.9,s*0.5,i,0,Math.PI*2);cx.fill();}
  for(const b of ANL.byggnader){
    const[a,c,w,h]=gsRekt(b.rekt);
    cx.fillStyle=fargSkala(b.fargT,0.95); cx.fillRect(a,c,w,h);
    cx.strokeStyle=fargSkala(b.fargV,0.7); cx.lineWidth=2; cx.strokeRect(a,c,w,h);
    cx.strokeStyle="rgba(0,0,0,.3)"; cx.lineWidth=1;
    cx.beginPath();
    if(b.nock==="NS"){const mx=a+w/2;cx.moveTo(mx,c);cx.lineTo(mx,c+h);}
    else{const my=c+h/2;cx.moveTo(a,my);cx.lineTo(a+w,my);}
    cx.stroke();
    if(b.label&&s>1.8){cx.fillStyle="#C7C2B6";cx.font=`500 ${Math.max(9,s*2.4)}px "IBM Plex Mono"`;
      cx.textAlign="center";cx.fillText(b.label,a+w/2,c+h/2+3);}
  }
  for(const d of ANL.dorrar){const[a,b]=gs(d.pos[0],d.pos[1]);
    cx.fillStyle="rgba(214,174,60,.9)";cx.beginPath();cx.arc(a,b,3.5,0,Math.PI*2);cx.fill();}
  const[sx,sy]=gs(ANL.skylt.pos[0],ANL.skylt.pos[1]);
  cx.fillStyle="#8E939B";cx.font=`500 ${Math.max(9,s*2.0)}px "IBM Plex Mono"`;
  cx.textAlign="center";cx.fillText(ANL.skylt.text,sx,sy);
  if(G.leder){const[a,b]=gs(VD.hastX,VD.hastY);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.save();cx.translate(a,b);cx.rotate(-VD.hastRikt);
    cx.beginPath();cx.ellipse(0,0,s*1.3,s*0.55,0,0,Math.PI*2);cx.fill();cx.restore();}
  ritaSpelare2D(gs(VD.px,VD.py),-VD.rikt,Math.max(s,2.2));
}
function ritaSpelare2D(pos,rikt,s){
  const[a,b]=pos;
  cx.save();cx.translate(a,b);cx.rotate(rikt);
  cx.fillStyle="rgba(0,0,0,.3)";
  cx.beginPath();cx.ellipse(1,1,s*0.55,s*0.55,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#D6AE3C";
  cx.beginPath();cx.moveTo(s*0.9,0);cx.lineTo(-s*0.5,-s*0.55);cx.lineTo(-s*0.5,s*0.55);
  cx.closePath();cx.fill();
  cx.restore();
}

/* ── Stallet invändigt: 2D ────────────────────────────────────── */
function ritaStall2D(){
  const S=STALLINNE, m=30;
  const s=Math.min((CW-2*m-340)/S.bredd,(CH-2*m)/S.langd);
  const ox=(CW-S.bredd*s)/2, oy=(CH-S.langd*s)/2;
  const ss=(x,y)=>[ox+x*s, oy+(S.langd-y)*s];
  cx.fillStyle="#14171B";cx.fillRect(0,0,CW,CH);
  const[fa,fb]=ss(0,S.langd);
  cx.fillStyle=S.golv;cx.fillRect(fa,fb,S.bredd*s,S.langd*s);
  const vx=S.bredd/2;
  const[ga]=ss(vx-S.ganghalva,0);
  cx.fillStyle=S.gangGolv;
  cx.fillRect(ga,fb,S.ganghalva*2*s,S.langd*s);
  for(const tv of S.tvarvaggar){
    const[a,b]=ss(0,tv.y);
    cx.strokeStyle="#4A4438";cx.lineWidth=2;
    cx.beginPath();cx.moveTo(a,b);cx.lineTo(a+(vx-tv.gap/2)*s,b);
    cx.moveTo(a+(vx+tv.gap/2)*s,b);cx.lineTo(a+S.bredd*s,b);cx.stroke();
  }
  for(const sida of["W","E"]){
    const rad=S.boxar[sida];
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB;
      if(y0+S.boxB>S.serviceY)break;
      const bx=sida==="W"?vx-S.ganghalva-S.boxDjup:vx+S.ganghalva;
      const[a,b]=ss(bx,y0+S.boxB);
      cx.strokeStyle="#4A4438";cx.lineWidth=1.5;
      cx.strokeRect(a,b,S.boxDjup*s,S.boxB*s);
      const h=boxHast(rad[i]);
      if(h){cx.fillStyle=h.farg;
        cx.beginPath();cx.ellipse(a+S.boxDjup*s/2,b+S.boxB*s/2,s*1.1,s*0.5,sida==="W"?0.4:-0.4,0,Math.PI*2);cx.fill();
        if(s>6){cx.fillStyle=h.spelbar?"#E6E4DE":"#8E877A";
          cx.font=`500 ${Math.max(8,s*0.6)}px "IBM Plex Mono"`;
          cx.textAlign=sida==="W"?"right":"left";
          cx.fillText(h.namn,sida==="W"?a-6:a+S.boxDjup*s+6,b+S.boxB*s/2+3);}}
    }
  }
  for(const grupp of [S.rum,S.service]) for(const r of grupp){
    const[a,b]=ss(r.rekt.x,r.rekt.y+r.rekt.h);
    cx.strokeStyle="#4A4438";cx.lineWidth=1.5;cx.strokeRect(a,b,r.rekt.w*s,r.rekt.h*s);
    cx.fillStyle="#8E877A";cx.font=`500 ${Math.max(7,s*0.45)}px "IBM Plex Mono"`;cx.textAlign="center";
    cx.fillText(r.label,a+r.rekt.w*s/2,b+r.rekt.h*s/2);}
  const rl=S.ridlarare;
  if(!G.hastId){const[a,b]=ss(rl.pos[0],rl.pos[1]);
    cx.fillStyle="#D6AE3C";cx.beginPath();cx.arc(a,b,s*0.5,0,Math.PI*2);cx.fill();
    cx.fillStyle="#C7C2B6";cx.font=`500 ${Math.max(8,s*0.55)}px "IBM Plex Mono"`;
    cx.textAlign="left";cx.fillText(rl.namn,a+s*0.8,b+3);}
  const mb=G.hastId&&!G.skotselRes&&hittaBox(G.hastId);
  if(mb){const[a,b]=ss(mb.dorr[0],mb.dorr[1]);
    cx.strokeStyle="rgba(214,174,60,.8)";cx.lineWidth=2;
    cx.beginPath();cx.arc(a,b,s*0.9+Math.sin(VD.tid*3)*2,0,Math.PI*2);cx.stroke();}
  for(const d of S.dorrar){const[a,b]=ss(d.pos[0],d.pos[1]);
    cx.fillStyle="rgba(214,174,60,.9)";cx.beginPath();cx.arc(a,b,3,0,Math.PI*2);cx.fill();}
  if(G.leder){const[a,b]=ss(VD.hastX,VD.hastY);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.save();cx.translate(a,b);cx.rotate(-VD.hastRikt);
    cx.beginPath();cx.ellipse(0,0,s*1.1,s*0.5,0,0,Math.PI*2);cx.fill();cx.restore();}
  ritaSpelare2D(ss(VD.px,VD.py),-VD.rikt,Math.max(s*0.9,2.2));
}

/* ── Stallet invändigt: 3D ────────────────────────────────────── */
function ritaStall3D(){
  const S=STALLINNE, k=kamera(); k.hor=CH*0.50;
  cx.fillStyle="#211D18";cx.fillRect(0,0,CW,k.hor);
  cx.fillStyle=S.golv;cx.fillRect(0,k.hor,CW,CH-k.hor);
  const vx=S.bredd/2;
  const items=[];
  // gångens marksten
  items.push({d:-1e9, rita(){
    ritaPoly3D(k,[[vx-S.ganghalva,0,0.01],[vx+S.ganghalva,0,0.01],
      [vx+S.ganghalva,S.langd,0.01],[vx-S.ganghalva,S.langd,0.01]],
      S.gangGolv,null);
    for(let y=2;y<S.langd;y+=2)
      ritaLinje3D(k,[vx-S.ganghalva,y,0.02],[vx+S.ganghalva,y,0.02],"rgba(0,0,0,.10)",1);
  }});
  // ytterväggar (klubbdelen pärlspont, resten stallvitt)
  const vagg=(p0,p1,farg)=>({d:-avst2([(p0[0]+p1[0])/2,(p0[1]+p1[1])/2]), rita(){
    ritaPoly3D(k,[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],S.tak],[p0[0],p0[1],S.tak]],farg,null);}});
  items.push(vagg([0,0],[0,S.langd],fargSkala(S.vagg,0.84)));
  items.push(vagg([S.bredd,0],[S.bredd,S.langd],fargSkala(S.vagg,0.72)));
  items.push(vagg([0,S.langd],[vx-1.4,S.langd],fargSkala(S.vagg,0.9)));
  items.push(vagg([vx+1.4,S.langd],[S.bredd,S.langd],fargSkala(S.vagg,0.9)));
  items.push(vagg([0,0],[vx-1.4,0],fargSkala(VCOL.parlspont,0.92)));
  items.push(vagg([vx+1.4,0],[S.bredd,0],fargSkala(VCOL.parlspont,0.92)));
  // gaveldörröppningarna: ljus utsikt
  for(const dy of[0,S.langd]) items.push({d:-avst2([vx,dy]), rita(){
    ritaPoly3D(k,[[vx-1.4,dy,0],[vx+1.4,dy,0],[vx+1.4,dy,2.8],[vx-1.4,dy,2.8]],
      "#5A626D",VCOL.knut);}});
  // tvärväggar med dörrgap (branddörren mot klubbdelen)
  for(const tv of S.tvarvaggar){
    for(const [x0,x1] of [[0,vx-tv.gap/2],[vx+tv.gap/2,S.bredd]]){
      items.push({d:-avst2([(x0+x1)/2,tv.y]), rita(){
        ritaPoly3D(k,[[x0,tv.y,0],[x1,tv.y,0],[x1,tv.y,S.tak],[x0,tv.y,S.tak]],
          fargSkala(tv.brand?VCOL.parlspont:S.vagg,0.88),null);}});
    }
    items.push({d:-avst2([vx,tv.y]), rita(){
      // dörrkarm + öppen grå branddörr
      ritaPoly3D(k,[[vx-tv.gap/2,tv.y,2.5],[vx+tv.gap/2,tv.y,2.5],
        [vx+tv.gap/2,tv.y,S.tak],[vx-tv.gap/2,tv.y,S.tak]],
        fargSkala(tv.brand?VCOL.parlspont:S.vagg,0.85),null);
      if(tv.brand)ritaText3D(k,vx,tv.y,2.75,"STALLET",1.4,"#8E877A");
    }});
  }
  // boxfronter
  for(const sida of["W","E"]){
    const rad=S.boxar[sida], fx=sida==="W"?vx-S.ganghalva:vx+S.ganghalva;
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB, y1=y0+S.boxB;
      if(y1>S.serviceY)break;
      const h=boxHast(rad[i]), my=(y0+y1)/2;
      items.push({d:-avst2([fx,my]), rita(){
        // antracit komposit nedtill, galvad ram
        ritaPoly3D(k,[[fx,y0,0],[fx,y1,0],[fx,y1,1.35],[fx,y0,1.35]],
          fargSkala(VCOL.boxFront,sida==="W"?1:0.85),VCOL.boxRam);
        ritaLinje3D(k,[fx,y0,0],[fx,y0,2.15],VCOL.boxRam,2);
        ritaLinje3D(k,[fx,y1,0],[fx,y1,2.15],VCOL.boxRam,2);
        ritaLinje3D(k,[fx,y0,2.15],[fx,y1,2.15],VCOL.boxRam,2);
        const gN=9;
        for(let g2=1;g2<gN;g2++){
          const gy=y0+(y1-y0)*g2/gN;
          ritaLinje3D(k,[fx,gy,1.35],[fx,gy,2.15],VCOL.galler,1);
        }
        // hästhuvud över boxdörren
        if(h){
          const p=tillKam(k,fx,my,1.6);
          if(p.d>=K3.nara){
            const s=projK(k,p), sz=clamp(0.75*k.f/p.d,4,120);
            const nick=Math.sin(VD.tid*0.9+i*1.7+(sida==="E"?2:0))*sz*0.05;
            cx.fillStyle=h.farg;
            cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.2+nick,sz*0.34,sz*0.5,sida==="W"?-0.25:0.25,0,Math.PI*2);cx.fill();
            cx.beginPath();cx.ellipse(s[0]+(sida==="W"?sz*0.26:-sz*0.26),s[1]+sz*0.16+nick,sz*0.2,sz*0.3,sida==="W"?-0.3:0.3,0,Math.PI*2);cx.fill();
            cx.fillStyle=h.man;
            cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.62+nick,sz*0.22,sz*0.13,0,0,Math.PI*2);cx.fill();
            const öra=(d2)=>{cx.beginPath();
              cx.moveTo(s[0]+d2*sz*0.12,s[1]-sz*0.62+nick);
              cx.lineTo(s[0]+d2*sz*0.22,s[1]-sz*0.95+nick);
              cx.lineTo(s[0]+d2*sz*0.30,s[1]-sz*0.60+nick);cx.closePath();cx.fill();};
            cx.fillStyle=h.farg;öra(-1);öra(1);
          }
        }
        // namnskylt
        const np=tillKam(k,fx,my,2.4);
        if(np.d>=K3.nara&&np.d<15&&Math.abs(np.s)<np.d*1.2){
          const s=projK(k,np), b=clamp(2.6*k.f/np.d,26,150), hh=b*0.24;
          cx.fillStyle=VCOL.skylt;cx.fillRect(s[0]-b/2,s[1]-hh/2,b,hh);
          cx.strokeStyle="#3A3E44";cx.strokeRect(s[0]-b/2,s[1]-hh/2,b,hh);
          cx.fillStyle=h?"#E6E4DE":"#5A5F66";
          cx.font=`600 ${hh*0.55}px "IBM Plex Mono"`;cx.textAlign="center";
          cx.fillText(h?h.namn.toUpperCase():"—",s[0],s[1]+hh*0.2);
        }
      }});
    }
  }
  // rummen (klubbdel + service) — väggar mot gången med etiketter
  for(const grupp of [S.rum,S.service]) for(const r of grupp){
    const rekt=r.rekt;
    const gx=rekt.x<vx?rekt.x+rekt.w:rekt.x;   // väggen som vetter mot gången
    items.push({d:-avst2([gx,rekt.y+rekt.h/2]), rita(){
      ritaPoly3D(k,[[gx,rekt.y,0],[gx,rekt.y+rekt.h,0],
        [gx,rekt.y+rekt.h,S.tak],[gx,rekt.y,S.tak]],
        fargSkala(rekt.y<10?VCOL.parlspont:S.vagg,rekt.x<vx?0.95:0.8),"#8A8377");
      ritaText3D(k,gx,rekt.y+rekt.h/2,2.2,r.label,1.6,"#7C756A");
    }});
  }
  // limträbalkar + taklanterniner
  for(let y=4;y<S.langd;y+=4){
    items.push({d:-avst2([vx,y])-1e6, rita(){
      ritaPoly3D(k,[[0.2,y-0.15,S.tak],[S.bredd-0.2,y-0.15,S.tak],
        [S.bredd-0.2,y+0.15,S.tak],[0.2,y+0.15,S.tak]],"#8A6B4A",null);}});
  }
  items.push({d:-1e8, rita(){ // lanterninerna: ljusband längs nocken
    ritaPoly3D(k,[[vx-0.5,2,S.tak+0.01],[vx+0.5,2,S.tak+0.01],
      [vx+0.5,S.langd-2,S.tak+0.01],[vx-0.5,S.langd-2,S.tak+0.01]],"#707B86",null);}});
  // props: storsäck, brandsläckare, hjärtstartare
  items.push({d:-avst2([vx-1.9,22]), rita(){
    const B=billboard(k,vx-1.9,22,1.1); if(!B)return;
    const {s,sz}=B;
    cx.fillStyle="#E4E2DC";
    cx.beginPath();cx.moveTo(s[0]-sz*0.5,s[1]);cx.lineTo(s[0]-sz*0.42,s[1]-sz*0.9);
    cx.lineTo(s[0]+sz*0.42,s[1]-sz*0.9);cx.lineTo(s[0]+sz*0.5,s[1]);cx.closePath();cx.fill();}});
  items.push({d:-avst2([vx+1.9,30]), rita(){
    const B=billboard(k,vx+1.9,30,0.9); if(!B)return;
    const {s,sz}=B;
    cx.fillStyle="#C0392B";cx.fillRect(s[0]-sz*0.09,s[1]-sz*0.6,sz*0.18,sz*0.5);}});
  // ridläraren
  if(!G.hastId){
    const rl=S.ridlarare;
    items.push({d:-avst2(rl.pos), rita(){ritaPerson3D(k,rl.pos[0],rl.pos[1]);}});
  }
  if(G.leder) items.push({d:-avst2([VD.hastX,VD.hastY]), rita(){ritaLeddHast3D(k);}});
  const mb=G.hastId&&!G.skotselRes&&hittaBox(G.hastId);
  if(mb) items.push({d:-avst2(mb.dorr), rita(){ritaMarkor3D(k,mb.dorr);}});
  for(const d of S.dorrar) items.push({d:-avst2(d.pos), rita(){ritaMarkor3D(k,d.pos);}});
  items.sort((a,b)=>a.d-b.d);
  for(const o of items)o.rita();
  ritaSpelare3D();
}
function ritaPerson3D(k,x,y){
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.72*k.f/p.d,6,220);
  cx.fillStyle="rgba(0,0,0,.25)";
  cx.beginPath();cx.ellipse(s[0],s[1],sz*0.2,sz*0.06,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#2E4638";
  cx.beginPath();cx.moveTo(s[0]-sz*0.16,s[1]);cx.lineTo(s[0]-sz*0.14,s[1]-sz*0.62);
  cx.quadraticCurveTo(s[0],s[1]-sz*0.70,s[0]+sz*0.14,s[1]-sz*0.62);
  cx.lineTo(s[0]+sz*0.16,s[1]);cx.closePath();cx.fill();
  cx.fillStyle="#C9A882";
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.80,sz*0.11,sz*0.13,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#3A3128";
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.88,sz*0.12,sz*0.07,0,0,Math.PI,true);cx.fill();
}

/* ── Huvudingång från spelloopen ─────────────────────────────── */
function ritaVandring(){
  if(G.scen==="gard"){ if(G.vy==="2d")ritaGard2D(); else ritaGard3D(); }
  else { if(G.vy==="2d")ritaStall2D(); else ritaStall3D(); }
  const ap=document.getElementById("approach");
  ap.textContent=VD.prompt&&!overlayUppe()?`Tryck E — ${VD.prompt.text}`:"";
  if(G.sagaT>0){G.sagaT-=1/60;if(G.sagaT<=0)document.getElementById("saga").classList.remove("on");}
  const mål=!G.hastId
    ? (G.scen==="gard"?["Gå till stallet","Stallentrén är den gula dörren under verandan, bortom parkeringen."]
                      :["Prata med ridläraren","Hon står i stallgången och fördelar hästarna."])
    : !G.skotselRes
    ? [`Gör i ordning ${HORSES[G.hastId].namn}`,
       G.scen==="gard"?"Boxen är inne i stallet.":"Gå till boxen med den gula markören."]
    : [`Led ${HORSES[G.hastId].namn} till ridhuset`,
       G.scen==="stallinne"?"Ut genom stalldörren och över gräsgården.":"In genom durkplåtdörrarna på ridhusets gårdssida."];
  visaUppgift(mål[0],mål[1]);
}
