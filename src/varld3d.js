/* ══════════════════════════════════════════════════════════════════
   ANLÄGGNINGEN I 3D — gården, stallgången och ridhuset invändigt
   renderade med samma WebGL-motor som ridscenen. Geometrin läses ur
   ANL, STALLINNE och RIDHUSINNE: byggnadernas mått, sadeltakens
   resning, fasadöppningarna, staketen, träden och rekvisitan är
   samma siffror som kartvyn ritar — inget är dubbellagrat.
   Koordinater: anläggningens x → X, y → Z, upp = Y.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const V3D={ plats:null, nyckel:null, statiskt:[], oppningar:null,
  kam:{x:0,y:2.2,z:0, tx:0,ty:1.3,tz:0, satt:false} };

/* ── Extra texturer för anläggningen ──────────────────────────── */
function v3dTexturer(){
  const T=S3.tex;
  if(T.falu)return;
  T.falu=glCanvasTex(128,128,(c,w,h)=>{           // liggande träpanel, otonad
    c.fillStyle="#FFFFFF";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(0,0,0,.22)";c.lineWidth=1;
    for(let i=0;i<9;i++){c.beginPath();c.moveTo(0,i*14+6);c.lineTo(w,i*14+6);c.stroke();}
    c.strokeStyle="rgba(255,255,255,.55)";
    for(let i=0;i<9;i++){c.beginPath();c.moveTo(0,i*14+8);c.lineTo(w,i*14+8);c.stroke();}
  },true);
  /* Korrugerad plåt: en stående rand per 12 cm. Kontrasten hålls låg —
     med en kraftig vit rand blir den mörkt vinröda plåten skär. */
  T.korr=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#FFFFFF";c.fillRect(0,0,w,h);
    for(let i=0;i<16;i++){
      c.fillStyle=i%2?"rgba(255,255,255,.20)":"rgba(0,0,0,.16)";
      c.fillRect(i*8,0,4,h);
    }
  },true);
  T.ridhusplat=T.korr; T.takplat=T.korr;
  T.aker=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#B08F55";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(140,110,60,.35)";c.lineWidth=2;
    for(let i=0;i<10;i++){c.beginPath();c.moveTo(0,i*13);c.lineTo(w,i*13);c.stroke();}
  },true);
  T.asfalt=glCanvasTex(64,64,(c,w,h)=>{
    c.fillStyle="#54524E";c.fillRect(0,0,w,h);
    for(let i=0;i<500;i++){c.fillStyle="rgba(0,0,0,.15)";
      c.fillRect(Math.random()*w,Math.random()*h,1,1);}
  },true);
  T.betong=glCanvasTex(64,64,(c,w,h)=>{
    c.fillStyle="#A09A8C";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(0,0,0,.10)";c.lineWidth=1;
    c.strokeRect(0.5,0.5,w-1,h-1);
  },true);
  T.parlspont=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#F0EADC";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(0,0,0,.07)";c.lineWidth=1;
    for(let i=0;i<12;i++){c.beginPath();c.moveTo(i*11,0);c.lineTo(i*11,h);c.stroke();}
  },true);
  T.marksten=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#9A968E";c.fillRect(0,0,w,h);
    c.strokeStyle="rgba(0,0,0,.14)";c.lineWidth=1.5;
    for(let i=0;i<7;i++){c.beginPath();c.moveTo(0,i*18);c.lineTo(w,i*18);c.stroke();}
    for(let r=0;r<7;r++)for(let i=0;i<5;i++){
      const x=i*26+(r%2?13:0);
      c.beginPath();c.moveTo(x,r*18);c.lineTo(x,r*18+18);c.stroke();}
  },true);
  T.span=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#D6C9A4";c.fillRect(0,0,w,h);
    for(let i=0;i<700;i++){c.fillStyle="rgba(150,132,96,.30)";
      c.fillRect(Math.random()*w,Math.random()*h,4,1);}
  },true);
  /* Namnskyltar på boxdörrarna. */
  T.namn={};
}
function v3dNamnTex(namn){
  const T=S3.tex;
  if(T.namn[namn])return T.namn[namn];
  return T.namn[namn]=glCanvasTex(256,64,(c,w,h)=>{
    c.fillStyle="#2A2E34";c.fillRect(0,0,w,h);
    c.strokeStyle="#B4B8BB";c.lineWidth=3;c.strokeRect(2,2,w-4,h-4);
    c.fillStyle="#E6E4DE";c.textAlign="center";c.textBaseline="middle";
    let px=34;c.font=`600 ${px}px "IBM Plex Mono", monospace`;
    while(c.measureText(namn).width>w-24&&px>10){px-=2;
      c.font=`600 ${px}px "IBM Plex Mono", monospace`;}
    c.fillText(namn,w/2,h/2+1);
  });
}
function v3dEtikettTex(text){
  const T=S3.tex;
  T.etikett=T.etikett||{};
  if(T.etikett[text])return T.etikett[text];
  return T.etikett[text]=glCanvasTex(256,64,(c,w,h)=>{
    c.fillStyle="#E9E5DC";c.fillRect(0,0,w,h);
    c.fillStyle="#5A5F66";c.textAlign="center";c.textBaseline="middle";
    let px=30;c.font=`600 ${px}px "IBM Plex Mono", monospace`;
    while(c.measureText(text).width>w-20&&px>9){px-=2;
      c.font=`600 ${px}px "IBM Plex Mono", monospace`;}
    c.fillText(text,w/2,h/2+1);
  });
}

/* Textskylt som läses rätt från båda hållen: två paneler rygg mot
   rygg, var och en vänd utåt. Då behövs ingen avstängd kullning och
   ingen text hamnar spegelvänd. */
function v3dTextPanel(bygge,w,h,mat){
  bygge.panel(w,h,"#FFFFFF",M4.mul(mat,M4.translation(0,0,0.005)));
  bygge.panel(w,h,"#FFFFFF",
    M4.mul(M4.mul(mat,M4.translation(0,0,-0.005)),M4.rotY(Math.PI)));
}
/* Fasadöppningarnas djup i tre steg, så att karm, ruta och spröjs inte
   z-slåss mot varandra på håll. Väggen ligger på 0. */
const OPPDJUP={karm:0.05, ruta:0.11, sprojs:0.15};

/* En triangel (gavelspetsar) — Bygge har bara slutna kroppar. */
function v3dTriangel(b,p0,p1,p2,farg,varv){
  const ux=p1[0]-p0[0], uy=p1[1]-p0[1], uz=p1[2]-p0[2];
  const vx=p2[0]-p0[0], vy=p2[1]-p0[1], vz=p2[2]-p0[2];
  let nx=uy*vz-uz*vy, ny=uz*vx-ux*vz, nz=ux*vy-uy*vx;
  const l=Math.hypot(nx,ny,nz)||1; nx/=l;ny/=l;nz/=l;
  /* Texturen mäts i meter, som på väggen under, så att korrugeringen
     löper obruten upp i gavelspetsen. */
  const v=varv||1.92;
  const uv=p=>[(Math.abs(nz)>0.5?p[0]:p[2])/v, p[1]/v];
  /* Lådorna i GEO.lada lagrar normalen åt motsatt håll mot vindningen,
     och kullningen går på vindningen. Triangeln måste följa samma
     konvention, annars får gavelspetsen normalen inåt huset och lyses
     upp som om solen stod bakom väggen — den blir ljusare än plåten
     rakt under, vilket syns som ett skarvband vid takfoten. */
  const U=[...uv(p0),...uv(p1),...uv(p2)];
  b.las([...p0,...p1,...p2],[-nx,-ny,-nz,-nx,-ny,-nz,-nx,-ny,-nz],U,[0,1,2],farg,null);
  b.las([...p0,...p2,...p1],[nx,ny,nz,nx,ny,nz,nx,ny,nz],
    [...uv(p0),...uv(p2),...uv(p1)],[0,1,2],farg,null);
}
/* Matris för en panel längs en fasad: +X längs väggen, +Z utåt. */
function v3dFasadMat(p0,ux,uy,u,z,ut){
  const nx=uy, nz=-ux;                       // utåtriktad normal
  return new Float32Array([
    ux,0,uy,0,  0,1,0,0,  nx*1,0,nz*1,0,
    p0[0]+ux*u+nx*ut, z, p0[1]+uy*u+nz*ut, 1]);
}

/* En plan polygon i sitt eget XY-plan, vänd mot +Z. Bygge har bara
   slutna kroppar och rektangulära paneler; valvbågarna och skärm-
   takens gavelspetsar behöver en fri kontur. */
function v3dPolygon(b,pts,farg,mat){
  const p=[],n=[],u=[],idx=[];
  for(const q of pts){p.push(q[0],q[1],0); n.push(0,0,1); u.push(0.5+q[0]*0.3,0.5+q[1]*0.3);}
  for(let i=1;i<pts.length-1;i++)idx.push(0,i,i+1);
  return b.las(p,n,u,idx,farg,mat);
}
/* Konturen till ett valvbågat fönster: rak nedre del, halvcirkel
   överst. Så ser de ut på både stallet och caféannexet — flerrutiga
   med vit karm. Origo i mitten, moturs sett framifrån. */
function v3dValvKontur(b,h,seg){
  const r=b/2, ym=h/2-r, pts=[[-r,-h/2],[r,-h/2],[r,ym]];
  const n=seg||7;
  for(let i=1;i<n;i++){const a=i/n*Math.PI; pts.push([r*Math.cos(a),ym+r*Math.sin(a)]);}
  pts.push([-r,ym]);
  return pts;
}
/* Cirkelkontur — stallets bullseye-fönster. */
function v3dRundKontur(d,seg){
  const r=d/2, n=seg||12, pts=[];
  for(let i=0;i<n;i++){const a=i/n*Math.PI*2; pts.push([r*Math.cos(a),r*Math.sin(a)]);}
  return pts;
}
/* Spröjsen: tunna vita lister över rutan. */
function v3dSprojs(b,br,h,mat,rader,kol){
  for(let i=1;i<(kol||2);i++)
    b.lada(0.035,h*0.92,0.02,"#EEEEE8",M4.mul(mat,M4.translation(-br/2+br*i/(kol||2),0,0)));
  for(let i=1;i<(rader||3);i++)
    b.lada(br*0.94,0.035,0.02,"#EEEEE8",M4.mul(mat,M4.translation(0,-h/2+h*i/(rader||3),0)));
}

/* Det vita skärmtaket över ridhusets dörrar: en liten sadelform med
   nocken ut från väggen, så att man ser gavelspetsen rakt framifrån.
   Det är husets näst tydligaste kännetecken efter den svarta listen.
   mat har +X längs fasaden, +Y uppåt, +Z utåt, med origo vid dörrens
   överkant. */
function v3dSkarmtak(b,mat,bredd,ut,res){
  const halv=bredd/2, hyp=Math.hypot(halv,res), vin=Math.atan2(res,halv);
  const V="#EEEEE8";
  for(const s of [-1,1])
    b.lada(hyp,0.08,ut,V,
      M4.mul(M4.mul(mat,M4.translation(s*halv/2,res/2,ut/2)),M4.rotZ(-s*vin)));
  v3dPolygon(b,[[-halv,0],[halv,0],[0,res]],V,
    M4.mul(mat,M4.translation(0,0,ut+0.015)));
  b.lada(bredd+0.10,0.13,0.10,V,M4.mul(mat,M4.translation(0,-0.06,ut-0.05)));
  for(const s of [-1,1]){                       // konsolerna ner mot dörrfodret
    b.lada(0.11,0.62,0.11,V,M4.mul(mat,M4.translation(s*(halv-0.12),-0.36,0.07)));
    b.lada(0.09,0.09,ut,"#232326",M4.mul(mat,M4.translation(s*(halv+0.10),-0.02,ut/2)));
  }
}

/* ── Gården ───────────────────────────────────────────────────── */
function v3dGard(lagg,opp){
  const T=S3.tex;
  const markTex={gras:T.gras, aker:T.aker, asfalt:T.asfalt, grus:T.grus,
    betong:T.betong, sand:T.sand, slant:T.gras};
  /* Marken: gräs överallt, sedan ytorna i ordning. */
  lagg(new Bygge().yta(420,420,"#FFFFFF",M4.translation(105,0,85),84),T.gras);
  let niva=0.01;
  for(const m of ANL.mark){
    if(m.typ==="gras")continue;
    const r=m.rekt;
    const b=new Bygge().yta(r.w,r.h,"#FFFFFF",
      M4.translation(r.x+r.w/2,niva,r.y+r.h/2), Math.max(2,Math.round(Math.max(r.w,r.h)/6)));
    lagg(b,markTex[m.typ]||T.grus);
    niva+=0.008;
  }
  for(const c of (ANL.cirklar||[])){
    const b=new Bygge().cyl(c.r,c.r,0.05,"#FFFFFF",M4.translation(c.c[0],niva,c.c[1]),20);
    lagg(b,T.sand); niva+=0.008;
  }
  /* Byggnaderna: väggar, sadeltak, gavelspetsar. husD samlar de
     omålade detaljerna — svarta lister, vindskivor, plåtbeslag —
     som ska ligga ovanpå fasadtexturen utan att ta upp den. */
  const husV=new Bygge(), husT=new Bygge(), husP=new Bygge(), husD=new Bygge();
  for(const bg of ANL.byggnader){
    const r=bg.rekt, hV=bg.hV, hN=bg.hN;
    const vt=bg.plat?husP:husV;
    /* Väggarna med texturen mätt i meter: plåtens korrugering blir
       ~12 cm bred och står upp, träpanelens brädor ~20 cm och ligger. */
    const VARV=bg.plat?1.92:1.80;
    vt.ladaM(r.w,hV,r.h,bg.fargV,M4.translation(r.x+r.w/2,hV/2,r.y+r.h/2),VARV);
    const cx=r.x+r.w/2, cz=r.y+r.h/2;
    const SVART=bg.svart||"#202022";
    const TAKF=typeof bg.takfot==="string"?bg.takfot:SVART;
    /* Takutsprånget: 25 cm, med en svart vindskiva i kanten. Utan den
       läser plåttaket som en pappskiva ovanpå en låda. */
    const UT=bg.takfot?0.25:0.0;
    if(bg.nock==="NS"){                       // nocken längs y
      const halv=r.w/2, res=hN-hV, len=Math.hypot(halv,res), vin=Math.atan2(res,halv);
      const cv=Math.cos(vin), sv=Math.sin(vin);
      /* Takfallet lutar NEDÅT ut mot takfoten. rotZ vrider lokal +X mot
         +Y, så östra fallet (s=+1) ska ha negativ vinkel — annars blir
         sadeltaket en dalgång i stället för en nock. */
      for(const s of [-1,1])
        husT.lada(len+2*UT,0.11,r.h+0.5+2*UT,bg.fargT,
          M4.mul(M4.translation(cx+s*(halv/2+UT*cv),hV+res/2-UT*sv,cz),M4.rotZ(-s*vin)));
      for(const s of [-1,1]){                 // gavelspetsarna i söder och norr
        const z=s<0?r.y:r.y+r.h;
        v3dTriangel(vt,[r.x,hV,z],[r.x+r.w,hV,z],[cx,hN,z],bg.fargV,VARV);
      }
      if(bg.takfot){
        for(const s of [-1,1]){               // takfoten längs långsidorna
          husD.lada(0.10,0.22,r.h+0.5+2*UT,TAKF,
            M4.translation(cx+s*(halv+UT*cv),hV-UT*sv-0.10,cz));
          for(const zs of [r.y-0.25-UT,r.y+r.h+0.25+UT])   // vindskivorna på gavlarna
            husD.lada(len+2*UT,0.16,0.11,TAKF,
              M4.mul(M4.translation(cx+s*(halv/2+UT*cv),hV+res/2-UT*sv-0.19,zs),M4.rotZ(-s*vin)));
        }
      }
    }else{                                    // nocken längs x
      const halv=r.h/2, res=hN-hV, len=Math.hypot(halv,res), vin=Math.atan2(res,halv);
      for(const s of [-1,1])
        husT.lada(r.w+0.5,0.14,len,bg.fargT,
          M4.mul(M4.translation(cx,hV+res/2,cz+s*halv/2),M4.rotX(s*vin)));
      for(const s of [-1,1]){
        const x=s<0?r.x:r.x+r.w;
        v3dTriangel(vt,[x,hV,r.y],[x,hV,r.y+r.h],[x,hN,cz],bg.fargV,VARV);
      }
    }
    /* Ljusgrå betongsockel — stallets vägg står inte i marken. */
    if(bg.sockel){
      const u=0.06;
      husD.lada(r.w+2*u,bg.sockel,r.h+2*u,"#B8B4AA",
        M4.translation(cx,bg.sockel/2,cz));
    }
    /* Den svarta listen som delar plåtfasaden i två våder. På
       ridhuset är den det första ögat fastnar på från parkeringen —
       den ligger i övre bjälklagets höjd, samma nivå som balkongen. */
    if(bg.list){
      const u=0.07, lh=0.22;
      husD.lada(r.w+2*u,lh,u,SVART,M4.translation(cx,bg.list,r.y-u/2));
      husD.lada(r.w+2*u,lh,u,SVART,M4.translation(cx,bg.list,r.y+r.h+u/2));
      husD.lada(u,lh,r.h,SVART,M4.translation(r.x-u/2,bg.list,cz));
      husD.lada(u,lh,r.h,SVART,M4.translation(r.x+r.w+u/2,bg.list,cz));
    }
    /* Vita knutar på trähusen. */
    if(!bg.plat)for(const[dx,dz]of[[0,0],[r.w,0],[0,r.h],[r.w,r.h]])
      husV.lada(0.18,hV,0.18,"#EEECE4",M4.translation(r.x+dx,hV/2,r.y+dz));
    /* Fasadöppningar. */
    const FARG={dorr:"#1A1A1C", dorrgul:"#A87650", dorrvit:"#E8E2D4",
      dorrgra:"#A2A4A6", dorrmork:"#463F38", portplat:"#B4B7B9",
      portsilver:"#C4C7C9", portbla:"#7E93A6", fonster:"#3A4A5C", valv:"#3A4A5C", rund:"#3A4A5C"};
    for(const o of (bg.oppningar||[])){
      const P=(function(sida){
        const{x,y,w,h}=r;
        if(sida==="S")return[[x,y],[x+w,y]];
        if(sida==="E")return[[x+w,y],[x+w,y+h]];
        if(sida==="N")return[[x+w,y+h],[x,y+h]];
        return[[x,y+h],[x,y]];
      })(o.sida);
      const L=Math.hypot(P[1][0]-P[0][0],P[1][1]-P[0][1]);
      const ux=(P[1][0]-P[0][0])/L, uy=(P[1][1]-P[0][1])/L;
      const F=(z,ut)=>v3dFasadMat(P[0],ux,uy,o.u+o.b/2,z,ut);
      const F2=(du,z,ut)=>v3dFasadMat(P[0],ux,uy,o.u+o.b/2+du,z,ut);
      const mat=F(o.z0+o.h/2,OPPDJUP.ruta);
      const glas=FARG[o.typ]||"#33291F";
      /* Vitt foder som en ram runt öppningen, inte en skiva bakom den.
         En skiva gör dörr och foder till ett enda blekt block; ramen är
         det man ser på fotona: smal vit list, mörk dörr innanför. */
      const foder=(tj,sockel)=>{
        opp.lada(o.b+2*tj,tj,0.07,"#EEEEE8",F2(0,o.z0+o.h+tj/2,OPPDJUP.karm));
        for(const sd of [-1,1])
          opp.lada(tj,o.h+tj,0.07,"#EEEEE8",F2(sd*(o.b+tj)/2,o.z0+(o.h+tj)/2,OPPDJUP.karm));
        if(sockel)opp.lada(o.b+2*tj,tj,0.07,"#EEEEE8",F2(0,o.z0-tj/2,OPPDJUP.karm));
      };
      if(o.typ==="valv"){                     // valvbågat, flerrutigt
        v3dPolygon(opp,v3dValvKontur(o.b+0.20,o.h+0.20),"#EEEEE8",F(o.z0+o.h/2+0.06,OPPDJUP.karm));
        v3dPolygon(opp,v3dValvKontur(o.b,o.h),glas,mat);
        v3dSprojs(opp,o.b*0.9,o.h*0.72,F(o.z0+o.h*0.36,OPPDJUP.sprojs),3,2);
      }else if(o.typ==="rund"){               // bullseye
        v3dPolygon(opp,v3dRundKontur(o.b+0.26,16),"#EEEEE8",F(o.z0+o.h/2,OPPDJUP.karm));
        v3dPolygon(opp,v3dRundKontur(o.b,16),glas,mat);
        v3dSprojs(opp,o.b*0.68,o.b*0.68,F(o.z0+o.h/2,OPPDJUP.sprojs),2,2);
      }else{
        opp.panel(o.b,o.h,glas,mat);
        if(o.typ==="fonster"){foder(0.10,true);
          v3dSprojs(opp,o.b*0.94,o.h*0.94,F(o.z0+o.h/2,OPPDJUP.sprojs),2,2);}
        if(o.typ==="dorr"||o.typ==="dorrgul"||o.typ==="dorrvit"||o.typ==="dorrmork")
          foder(0.12,false);
        if(o.typ==="dorrvit"){                // glasade rutor i dubbeldörren
          for(const sd of [-1,1])
            opp.panel(o.b*0.30,o.h*0.22,"#3A4A5C",
              F2(sd*o.b*0.24,o.z0+o.h*0.72,OPPDJUP.sprojs));
          opp.lada(0.05,o.h*0.92,0.05,"#EEEEE8",F2(0,o.z0+o.h/2,OPPDJUP.sprojs));
        }
        if(o.typ==="dorrgul")                 // solfjäderfönstret överst
          v3dPolygon(opp,v3dValvKontur(o.b*0.74,o.h*0.30),"#C8D6DE",
            F(o.z0+o.h*0.79,OPPDJUP.sprojs));
        if(o.typ==="dorr"||o.typ==="dorrmork") // handtag
          opp.lada(0.05,0.16,0.05,"#C4C7C9",F2(o.b*0.34,o.z0+1.05,OPPDJUP.sprojs));
      }
      /* Skärmtaket: sadelform med nocken ut från väggen. */
      if(o.skarm)
        v3dSkarmtak(husD,F(o.z0+o.h+0.30,0.02),o.skarm,0.80,0.42);
    }
    if(bg.detalj==="ridhus")v3dRidhusYttre(bg,husD,opp);
    else if(bg.detalj==="stall")v3dStallYttre(bg,husD,opp);
  }
  lagg(husV,T.falu); lagg(husP,T.ridhusplat); lagg(husT,T.takplat); lagg(husD,null);

  /* Staketen. */
  const stak=new Bygge();
  for(const st of ANL.staket){
    for(let i=0;i<st.p.length-1;i++){
      const a=st.p[i], b=st.p[i+1];
      const dx=b[0]-a[0], dz=b[1]-a[1], len=Math.hypot(dx,dz);
      if(len<0.01)continue;
      const vin=Math.atan2(dz,dx);
      const mitt=M4.mul(M4.translation((a[0]+b[0])/2,0,(a[1]+b[1])/2),M4.rotY(-vin));
      if(st.typ==="tra"){
        for(const y of [0.62,1.14])
          stak.lada(len,0.10,0.05,"#B0A184",M4.mul(mitt,M4.translation(0,y,0)));
        const n=Math.max(1,Math.round(len/2.6));
        for(let k=0;k<=n;k++)
          stak.lada(0.11,1.30,0.11,"#8A7A5E",
            M4.mul(mitt,M4.translation(-len/2+len*k/n,0.65,0)));
      }else if(st.typ==="el"){
        for(const y of [0.70,1.05])
          stak.lada(len,0.03,0.02,"#8C8578",M4.mul(mitt,M4.translation(0,y,0)));
        const n=Math.max(1,Math.round(len/6));
        for(let k=0;k<=n;k++)
          stak.lada(0.07,1.15,0.07,"#6E6A5E",
            M4.mul(mitt,M4.translation(-len/2+len*k/n,0.58,0)));
      }else{
        /* Rödbrunt tvåregelsstaket, som det framför ridhuset på fotona. */
        for(const y of [0.70,1.12])
          stak.lada(len,0.12,0.06,"#7A2E28",M4.mul(mitt,M4.translation(0,y,0)));
        const n=Math.max(1,Math.round(len/3));
        for(let k=0;k<=n;k++)
          stak.lada(0.12,1.24,0.12,"#6A2822",
            M4.mul(mitt,M4.translation(-len/2+len*k/n,0.62,0)));
      }
    }
  }
  lagg(stak,null);

  /* Träden. */
  const skog=new Bygge();
  for(let i=0;i<ANL.trad.length;i++){
    const[tx,tz,tr]=ANL.trad[i];
    const f=TRADFARG[i%TRADFARG.length], h=tr*2.2+2.5;
    if(STIL==="kloss"){ klossTrad(skog,tx,tz,h,f[0],glMorka(f[0],0.86)); continue; }
    skog.cyl(tr*0.16,tr*0.11,h*0.45,"#5E4A34",M4.translation(tx,0,tz),7);
    skog.klot(1,f[0],M4.mul(M4.translation(tx,h*0.66,tz),
      M4.skala(tr*0.95,tr*1.05,tr*0.95)),10);
    skog.klot(1,f[1],M4.mul(M4.translation(tx+tr*0.3,h*0.86,tz-tr*0.2),
      M4.skala(tr*0.6,tr*0.62,tr*0.6)),9);
  }
  lagg(STIL==="kloss"?glPlatta(skog):skog,null);

  /* Rekvisitan. I lågpolyläget dras segmentantalet ner så att
     cylindrarna läser som fasetterade prismor. */
  const SEG=(hog,lag)=>STIL==="kloss"?lag:hog;
  const pr=new Bygge();
  for(const p of ANL.props){
    const[x,z]=p.pos;
    switch(p.typ){
      case"silo":
        pr.cyl(1.5,1.5,7.5,"#C4C7C9",M4.translation(x,0,z),SEG(14,7));
        pr.cyl(1.55,0.2,1.8,"#A2A4A6",M4.translation(x,7.5,z),SEG(14,7));
        pr.cyl(0.9,0.9,1.2,"#8A8C90",M4.translation(x,-0.0,z-1.8),SEG(10,6));
        break;
      case"balar":
        for(let i=0;i<3;i++)for(let j=0;j<2;j++)
          pr.cyl(0.65,0.65,1.2,"#E4E2DA",
            M4.mul(M4.translation(x+i*1.4,0.65,z+j*1.5),M4.rotZ(Math.PI/2)),SEG(10,6));
        break;
      case"grushog": pr.cyl(1.8,0.1,1.3,"#BCA179",M4.translation(x,0,z),SEG(12,6)); break;
      case"transport":{                       // hästtransporten
        const m=M4.mul(M4.translation(x,0,z),M4.rotY(-(p.rikt||0)));
        pr.lada(2.2,1.75,5.4,"#E8E6E0",M4.mul(m,M4.translation(0,1.35,0)));
        pr.lada(2.24,0.34,4.2,"#8A8C90",M4.mul(m,M4.translation(0,1.95,-0.3)));
        pr.lada(2.05,0.34,3.0,"#3A4A5C",M4.mul(m,M4.translation(0,1.62,0.4)));
        pr.lada(1.9,1.25,0.10,"#B9BCC0",M4.mul(m,M4.translation(0,1.05,2.72)));
        for(const dx of [-1.12,1.12])for(const dz of [-1.0,0.3])
          pr.cyl(0.36,0.36,0.24,"#2E3238",
            M4.mul(M4.mul(m,M4.translation(dx,0.36,dz)),M4.rotZ(Math.PI/2)),SEG(10,6));
        pr.lada(0.12,0.5,1.6,"#8A8C90",M4.mul(m,M4.translation(0,0.28,-3.4)));
        break;}
      case"bord":
        pr.lada(1.5,0.08,0.8,"#8A7250",M4.translation(x,0.74,z));
        for(const[dx,dz]of[[-0.6,0],[0.6,0]])
          pr.lada(0.10,0.74,0.7,"#6B5540",M4.translation(x+dx,0.37,z+dz));
        for(const dz of [-0.62,0.62])
          pr.lada(1.5,0.07,0.30,"#8A7250",M4.translation(x,0.46,z+dz));
        break;
      case"bank":
        pr.lada(1.6,0.07,0.36,"#8A7250",M4.translation(x,0.46,z));
        for(const dx of [-0.66,0.66])
          pr.lada(0.09,0.46,0.34,"#6B5540",M4.translation(x+dx,0.23,z));
        break;
      case"stol":
        pr.lada(0.46,0.06,0.46,"#8A7250",M4.translation(x,0.45,z));
        pr.lada(0.46,0.5,0.06,"#8A7250",M4.translation(x,0.70,z-0.20));
        break;
      case"mast":
        pr.cyl(0.13,0.09,7.5,"#8C8F92",M4.translation(x,0,z),8);
        pr.lada(0.7,0.16,0.4,"#C8CBD0",M4.translation(x,7.55,z));
        break;
      case"flagga":
        pr.cyl(0.09,0.06,7.0,"#E8E6E0",M4.translation(x,0,z),8);
        pr.panel(1.4,0.9,"#2F5C8F",M4.translation(x+0.72,6.2,z));
        break;
      case"stenhast":
        pr.klot(1,"#9A968E",M4.mul(M4.translation(x,0.52,z),M4.skala(0.46,0.24,0.20)),8);
        pr.cyl(0.09,0.07,0.42,"#9A968E",M4.translation(x+0.30,0.60,z),6);
        pr.klot(1,"#9A968E",M4.mul(M4.translation(x+0.36,1.02,z),M4.skala(0.16,0.09,0.08)),8);
        for(const[dx,dz]of[[-0.3,0.14],[-0.3,-0.14],[0.24,0.14],[0.24,-0.14]])
          pr.cyl(0.05,0.045,0.42,"#9A968E",M4.translation(x+dx,0.10,z+dz),6);
        break;
      case"sopstation":
        for(let i=0;i<3;i++)
          pr.lada(1.0,1.2,1.0,i===1?"#3E6E4E":"#4A4E52",M4.translation(x+i*1.15,0.6,z));
        break;
      case"ac": pr.lada(0.9,0.7,0.35,"#C8CBD0",M4.translation(x,0.8,z)); break;
      case"busskylt":
        pr.cyl(0.06,0.06,2.4,"#8C8F92",M4.translation(x,0,z),6);
        pr.panel(0.5,0.7,"#2F5C8F",M4.translation(x,2.2,z+0.05));
        break;
      case"vagvisare":                        // vägvisaren framför stallet
        pr.cyl(0.07,0.07,3.15,"#4A4E52",M4.translation(x,0,z),8);
        for(let i=0;i<8;i++)
          pr.lada(1.05,0.17,0.045,"#2A2E34",
            M4.translation(x+(i%2?0.58:-0.58),2.86-i*0.27,z));
        break;
      case"skyltstolpe":
        pr.cyl(0.08,0.08,2.6,"#6B5540",M4.translation(x,0,z),6);
        pr.panel(1.5,0.42,"#EFE8D8",M4.translation(x,2.3,z+0.05));
        break;
      default: break;
    }
  }
  /* Skyltarna med text. */
  for(const p of ANL.props){
    if(p.typ!=="skylt"&&p.typ!=="cafeskylt")continue;
    const[x,z]=p.pos, n=p.norm||[0,-1];
    const vin=Math.atan2(n[0],n[1]);
    const txt=p.typ==="skylt"?(p.text||""):"CAFÉ KRUBBAN";
    const b=new Bygge();
    v3dTextPanel(b, p.typ==="skylt"?5.0:1.6, p.typ==="skylt"?0.7:0.4,
      M4.mul(M4.translation(x,p.typ==="skylt"?3.4:3.0,z),M4.rotY(vin)));
    S3.statiskt.push({nat:GL.nat(b), tex:v3dEtikettTex(txt)});
  }
  lagg(STIL==="kloss"?glPlatta(pr):pr,null);
}


/* ── Ridhuset utvändigt ────────────────────────────────────────────
   Byggt efter references/buildings/ridhus/KORT.md, som är läst ur
   fotona i samma mapp. Volymen, den svarta listen och takfoten sköts
   av den generella slingan ovan; här läggs det som bara det här huset
   har, och som är själva igenkänningen från parkeringen:

     · gallren högt uppe på gaveln — det runda, jalusigallret och den
       svarta fläktlådan med sin kanal
     · caféannexets balkong med pulpettak, stålräcke och den utvändiga
       trappan upp till Café Krubban
     · stuprören i hörnen och strålkastarna under takfoten

   Alla mått i meter, u räknat västerut längs norra gaveln från husets
   nordöstra hörn (moturs) — samma u som fasadöppningarna i site.js.
   Gaveln mot parkeringen är den NORRA: grusplanen ligger vid husets
   norra ände, precis som i verkligheten (SITEPLAN.md).
   ── */
function v3dRidhusYttre(bg,d,opp){
  const r=bg.rekt, hV=bg.hV;
  const SVART=bg.svart||"#202022", STAL="#B4B9BE", MORK="#3A3E44";
  /* u längs norra gaveln, +Y uppåt, +Z ut mot parkeringen i norr. */
  const F=(u,z,ut)=>v3dFasadMat([r.x+r.w,r.y+r.h],-1,0,u,z,ut);

  /* Runt ventilationsgaller, ensamt på en tom fasadyta. */
  d.cyl(0.27,0.27,0.09,"#8C9096",M4.mul(F(5.3,5.65,0.02),M4.rotX(Math.PI/2)),12);
  d.cyl(0.21,0.21,0.05,MORK,M4.mul(F(5.3,5.65,0.10),M4.rotX(Math.PI/2)),12);
  /* Rektangulärt jalusigaller strax väster om nocklinjen. */
  d.lada(0.52,1.05,0.09,"#4C4A44",F(12.5,5.60,0.045));
  for(let i=0;i<7;i++)
    d.lada(0.46,0.06,0.06,"#7A6E5C",F(12.5,5.16+i*0.145,0.10));
  /* Fläktlådan med rund kanal — den är stor på fotot, nästan en halv
     kvadratmeter svart plåt mitt på den tomma väggen. */
  d.lada(1.10,0.74,0.18,SVART,F(16.0,5.65,0.09));
  d.cyl(0.19,0.19,0.42,"#141416",M4.mul(F(16.3,5.60,0.16),M4.rotX(Math.PI/2)),10);
  /* Kameran vid nocken och strålkastarna under takfoten. */
  d.lada(0.16,0.15,0.20,SVART,F(12.9,6.55,0.12));
  for(const u of [6.9,16.9]){
    d.lada(0.30,0.10,0.20,SVART,F(u,5.30,0.12));
    d.lada(0.09,0.22,0.09,SVART,F(u,5.44,0.06));
  }
  /* Entrékvisten på västra långsidan, mot vägen: ett långt pulpettak på
     vita stolpar, med ramp och räcke fram till dubbeldörrarna. Det är
     det man ser från Enköpingsvägen, näst efter skylten. */
  {
    const FW=(u,z,ut)=>v3dFasadMat([r.x,r.y+r.h],0,-1,u,z,ut);
    /* Kvisten sitter närmast caféets gavel — den norra (Street View
       från Enköpingsvägen). W-sidans u räknas från norra gaveln. */
    const ku0=2, ku1=16, kut=2.6, kz=3.05, kmitt=(ku0+ku1)/2, klen=ku1-ku0;
    d.lada(klen,0.12,kut+0.25,MORK,FW(kmitt,kz,kut/2));
    d.lada(klen+0.1,0.17,0.13,"#EEEEE8",FW(kmitt,kz-0.13,kut+0.07));
    for(let u=ku0+0.7;u<=ku1-0.5;u+=3.2)
      d.lada(0.13,kz-0.13,0.13,"#EEEEE8",FW(u,(kz-0.13)/2,kut-0.24));
    d.lada(klen-1.0,0.11,kut-0.5,"#B4B7B9",FW(kmitt,0.11,kut/2-0.1));
    for(const y of [0.56,1.00])
      d.lada(klen-1.0,0.05,0.05,STAL,FW(kmitt,y+0.16,kut-0.38));
    for(let u=ku0+0.9;u<ku1-0.6;u+=0.52)
      d.lada(0.03,0.90,0.03,STAL,FW(u,0.63,kut-0.38));
  }
  /* Stuprören i gavelns båda hörn. */
  for(const u of [0.22,r.w-0.22]){
    d.cyl(0.06,0.06,hV-0.25,SVART,F(u,0,0.12),8);
    d.lada(0.34,0.10,0.10,SVART,F(u,hV-0.28,0.12));
  }

  /* ── Caféannexet: balkongen och trappan upp till Café Krubban ──
     Balkonggolvet ligger i samma höjd som den svarta listen, alltså i
     övre bjälklaget. Över balkongen ett pulpettak på två stolpar —
     i fotot syns dess mörka framkant över räcket. */
  const bz=3.95, bu0=20.5, bu1=24.9, bdj=1.50;
  d.lada(bu1-bu0,0.18,bdj,MORK,F((bu0+bu1)/2,bz-0.09,bdj/2));
  d.lada(bu1-bu0,0.10,0.10,SVART,F((bu0+bu1)/2,bz-0.20,bdj-0.05));
  for(const y of [bz+0.54,bz+1.02])            // räckets liggande rör
    d.lada(bu1-bu0,0.05,0.05,STAL,F((bu0+bu1)/2,y,bdj-0.06));
  for(let u=bu0+0.18;u<bu1-0.1;u+=0.40)        // spjälorna
    d.lada(0.035,1.02,0.035,STAL,F(u,bz+0.51,bdj-0.06));
  for(const u of [bu0+0.05,bu1-0.05]){         // räcket på balkongens kortsidor
    for(const y of [bz+0.54,bz+1.02])
      d.lada(0.05,0.05,bdj,STAL,F(u,y,bdj/2));
    d.lada(0.035,1.02,0.035,STAL,F(u,bz+0.51,bdj-0.14));
  }
  const tz=5.55, tdj=1.65;                     // pulpettaket över balkongen
  d.lada(bu1-bu0+0.20,0.10,tdj,MORK,F((bu0+bu1)/2,tz,tdj/2-0.1));
  d.lada(bu1-bu0+0.20,0.12,0.09,SVART,F((bu0+bu1)/2,tz-0.09,tdj-0.15));
  for(const u of [bu0+0.30,bu1-0.30])
    d.lada(0.10,tz-bz,0.10,SVART,F(u,(bz+tz)/2,bdj-0.20));

  /* Den utvändiga ståltrappan. Stiger västerut längs fasaden (mot
     caféhörnet) och landar på balkongen — precis som på fotot från
     grusplanen, där den delar gaveln diagonalt under caféskylten. */
  const su0=12.9, su1=bu0, sbr=1.10, sut=0.62, steg=22;
  const lut=Math.atan2(bz,su1-su0), hyp=Math.hypot(bz,su1-su0);
  for(let i=0;i<steg;i++){
    const u=su0+(su1-su0)*(i+0.5)/steg, y=bz*(i+1)/steg;
    d.lada((su1-su0)/steg+0.03,0.05,sbr,"#C6CACE",F(u,y-0.03,sut+sbr/2));
    d.lada((su1-su0)/steg+0.03,0.16,0.04,"#9AA0A6",F(u,y-0.12,sut+0.04));
  }
  for(const ut of [sut+0.03,sut+sbr-0.03])     // vangstyckena
    d.lada(hyp,0.24,0.05,"#9AA0A6",
      M4.mul(F((su0+su1)/2,bz/2-0.22,ut),M4.rotZ(lut)));
  for(const y of [0.62,1.06])                  // ledstängerna
    d.lada(hyp,0.05,0.05,STAL,
      M4.mul(F((su0+su1)/2,bz/2+y,sut+sbr-0.03),M4.rotZ(lut)));
  for(let i=1;i<steg;i+=3){
    const u=su0+(su1-su0)*i/steg, y=bz*i/steg;
    d.lada(0.035,1.06,0.035,STAL,F(u,y+0.53,sut+sbr-0.03));
  }
  d.lada(0.09,1.06,0.09,STAL,F(su0,0.53,sut+sbr-0.03));   // nedersta stolpen
  d.lada(0.09,1.30,0.09,STAL,F(su1-0.05,bz+0.65,sut+sbr-0.03));
}


/* ── Stallet utvändigt ─────────────────────────────────────────────
   Byggt efter references/buildings/stall/KORT.md. Volymen, fönster-
   raden och den vita takfoten sköts av den generella slingan ovan;
   här läggs det som bara stallet har:

     · huvraden på nocken — en huv per box, och den börjar först efter
       förstukvisten, inte vid gaveln. Det är byggnadens tydligaste
       drag på håll.
     · snörasskyddet, ett svart streck tvärs över det stora grå taket,
       och den svarta hängrännan med stuprör
     · förstukvisten med sitt vita ribbräcke och den ockragula dörren
     · norra gavelns balkong och svarta spiraltrappa — klubbgaveln
       mot grusplanen, den man ser när man kommer (stall-fasad-04)
     · södra gavelns raka ståltrappa mot gårdsplanen (Street View)

   u räknas moturs runt huset, alltså från norra gaveln på västra
   långsidan och från östra hörnet på norra gaveln — samma u som
   fasadöppningarna i site.js.
   ── */
function v3dStallYttre(bg,d,opp){
  const r=bg.rekt, hV=bg.hV, hN=bg.hN;
  const cx=r.x+r.w/2, cz=r.y+r.h/2, halv=r.w/2, res=hN-hV;
  const SVART=bg.svart||"#26292E", VIT="#EEECE4", GRA=bg.fargT;
  const HUV=glMorka(GRA,0.86);
  /* Fasadramar: +Y uppåt, +Z utåt. */
  const FN=(u,z,ut)=>v3dFasadMat([r.x+r.w,r.y+r.h],-1,0,u,z,ut); // norra gaveln (klubbgaveln)
  const FS=(u,z,ut)=>v3dFasadMat([r.x,r.y],1,0,u,z,ut);          // södra gaveln
  const FW=(u,z,ut)=>v3dFasadMat([r.x,r.y+r.h],0,-1,u,z,ut);     // västra långsidan

  /* Huvraden. Boxarna börjar 10,4 m från klubbgaveln i norr och är
     3,5 m breda (STALLINNE); en huv sitter mitt över varje box. */
  for(let i=0;i<11;i++){
    const z=r.y+r.h-(10.4+3.5*i+1.75);
    d.lada(0.44,0.62,0.44,HUV,M4.translation(cx,hN+0.28,z));
    d.lada(0.50,0.06,0.50,glMorka(GRA,0.7),M4.translation(cx,hN+0.58,z));
    d.lada(0.66,0.09,0.66,HUV,M4.translation(cx,hN+0.66,z));
  }
  /* Snörasskyddet på båda takfallen, en tredjedel upp, och hängrännan
     med stuprör i hörnen. */
  for(const s of [-1,1]){
    const px=cx+s*halv*0.70, py=hV+res*0.30;
    d.cyl(0.035,0.035,r.h-1.2,SVART,
      M4.mul(M4.translation(px,py+0.17,r.y+0.6),M4.rotX(Math.PI/2)),6);
    for(let z=r.y+1.4;z<r.y+r.h-1;z+=2.2)
      d.lada(0.06,0.24,0.05,SVART,M4.translation(px,py+0.08,z));
    d.lada(0.14,0.14,r.h+0.4,SVART,M4.translation(cx+s*(halv+0.17),hV-0.13,cz));
    for(const z of [r.y+0.9,r.y+r.h-0.9])
      d.cyl(0.055,0.055,hV-0.22,SVART,M4.translation(cx+s*(halv+0.15),0,z),6);
  }

  /* ── Förstukvisten, 5,6 m från klubbgaveln i norr ──
     Sadeltak med nocken ut från väggen, vita stolpar, och ett räcke av
     liggande ribbor — det är räcket man ser först när man går fram. */
  const PU=5.6, bw=5.2, but=2.8, be=2.95, br=1.05;
  const F2=(du,z,ut)=>FW(PU+du,z,ut);
  const hh=bw/2, hyp=Math.hypot(hh,br), pv=Math.atan2(br,hh);
  d.lada(bw+0.4,0.14,but+0.2,"#C2BFB6",F2(0,0.07,but/2));        // betonggolvet
  for(const s of [-1,1]){
    d.lada(hyp,0.10,but+0.45,GRA,
      M4.mul(M4.mul(F2(0,be+br/2,but/2-0.05),M4.translation(s*hh/2,0,0)),M4.rotZ(-s*pv)));
    d.lada(hyp,0.17,0.10,VIT,                                     // vindskivorna
      M4.mul(M4.mul(F2(0,be+br/2,but+0.10),M4.translation(s*hh/2,0,0)),M4.rotZ(-s*pv)));
    d.lada(0.12,0.19,but+0.35,VIT,F2(s*(hh+0.05),be-0.07,but/2)); // takfoten på sidorna
    d.lada(0.15,be-0.14,0.15,VIT,F2(s*(hh-0.14),(be-0.14)/2+0.14,but-0.20));
  }
  /* Kvistens gavelspets är röd panel med vita vindskivor, inte vit. */
  v3dPolygon(d,[[-hh,0],[hh,0],[0,br]],bg.fargV,F2(0,be,but+0.06));
  d.lada(bw+0.2,0.13,0.14,VIT,F2(0,be-0.03,but+0.12));   // fris under spetsen
  for(let y=0.26;y<1.22;y+=0.125){                                // ribbräcket
    d.lada(bw-0.34,0.072,0.042,VIT,F2(0,y+0.14,but-0.20));
    for(const s of [-1,1])
      d.lada(0.042,0.072,but-0.75,VIT,F2(s*(hh-0.14),y+0.14,but/2+0.16));
  }
  d.lada(bw-0.34,0.07,0.11,VIT,F2(0,1.46,but-0.20));              // handledaren
  for(const s of [-1,1])
    d.lada(0.11,0.07,but-0.75,VIT,F2(s*(hh-0.14),1.46,but/2+0.16));
  d.lada(0.10,0.24,0.10,SVART,F2(0,2.52,0.09));                   // vägglampan
  d.cyl(0.17,0.11,0.13,"#E4E0D6",M4.mul(F2(0,2.40,0.20),M4.rotX(-Math.PI/2)),10);

  /* ── Norra gaveln — klubbgaveln: balkongen och spiraltrappan ── */
  const bz=4.55;
  d.lada(2.2,0.12,1.10,"#4A4E52",FN(7.5,bz-0.06,0.55));
  for(const y of [bz+0.42,bz+0.88]){
    d.lada(2.2,0.05,0.05,SVART,FN(7.5,y,1.06));
    for(const s of [-1,1])d.lada(0.05,0.05,1.10,SVART,FN(7.5+s*1.08,y,0.55));
  }
  for(let u=6.55;u<8.5;u+=0.24)d.lada(0.028,0.92,0.028,SVART,FN(u,bz+0.46,1.06));
  const sr=0.70, steg=18, sh=bz/steg, su=5.2, sut=0.62;
  d.cyl(0.085,0.085,bz+0.50,SVART,FN(su,0,sut),8);
  for(let i=0;i<steg;i++){
    const m=M4.mul(FN(su,(i+1)*sh,sut),M4.rotY(i*0.40));
    d.lada(sr,0.05,0.30,"#3A3E44",M4.mul(m,M4.translation(sr/2,0,0)));
    d.lada(0.035,0.92,0.035,SVART,M4.mul(m,M4.translation(sr-0.05,0.46,0)));
  }
  d.cyl(0.23,0.23,0.10,"#F0C24A",M4.mul(FN(6.3,6.10,0.03),M4.rotX(-Math.PI/2)),10);

  /* ── Södra gaveln mot gårdsplanen: den raka ståltrappan upp till
     trappdörren (Street View från infartsvägen). Skärmtaken över de
     två entrédörrarna ritas av den generella öppningsslingan. ── */
  {
    const tz=4.35, tu0=8.6, tu1=12.4, tbr=1.00, tut=0.55, tsteg=14;
    const tlut=Math.atan2(tz,tu1-tu0), thyp=Math.hypot(tz,tu1-tu0);
    for(let i=0;i<tsteg;i++){
      const u=tu0+(tu1-tu0)*(i+0.5)/tsteg, y=tz*(i+1)/tsteg;
      d.lada((tu1-tu0)/tsteg+0.03,0.05,tbr,"#C6CACE",FS(u,y-0.03,tut+tbr/2));
    }
    for(const ut of [tut+0.03,tut+tbr-0.03])
      d.lada(thyp,0.22,0.05,"#9AA0A6",
        M4.mul(FS((tu0+tu1)/2,tz/2-0.20,ut),M4.rotZ(tlut)));
    for(const y of [0.60,1.04])
      d.lada(thyp,0.05,0.05,"#B4B9BE",
        M4.mul(FS((tu0+tu1)/2,tz/2+y,tut+tbr-0.03),M4.rotZ(tlut)));
    d.lada(1.5,0.10,tbr,"#C6CACE",FS(tu1+0.6,tz-0.05,tut+tbr/2));   // avsatsen
    d.lada(0.09,tz+1.1,0.09,"#9AA0A6",FS(tu0,0.55,tut+tbr-0.03));
    d.lada(0.09,1.15,0.09,"#9AA0A6",FS(tu1+1.3,tz+0.58,tut+tbr-0.03));
  }
}

/* ── Stallet invändigt ────────────────────────────────────────── */
function v3dStall(lagg,opp){
  const S=STALLINNE, T=S3.tex, vx=S.bredd/2;
  /* Golvet, efter IMG_0249: en markstensgång i mitten — smalare än
     hela gången — och en ljus spånremsa längs boxfronterna på båda
     sidor. Remsan är det första ögat läser i filmen; utan den blir
     gången en enfärgad korridor. */
  const gangSten=S.ganghalva*0.72;
  lagg(new Bygge().yta(gangSten*2,S.langd,"#FFFFFF",
    M4.translation(vx,0.02,S.langd/2),10),T.marksten);
  {const remsa=new Bygge(), rb=S.ganghalva-gangSten;
   for(const sida of [-1,1])
     remsa.yta(rb,S.langd,"#D8C9A4",
       M4.translation(vx+sida*(gangSten+rb/2),0.025,S.langd/2),4);
   lagg(remsa,T.span);}
  const span=new Bygge();
  for(const sida of["W","E"]){
    const rad=S.boxar[sida];
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB;
      if(y0+S.boxB>S.klubbY)break;
      const x=sida==="W"?vx-S.ganghalva-S.boxDjup/2:vx+S.ganghalva+S.boxDjup/2;
      span.yta(S.boxDjup,S.boxB-0.1,"#FFFFFF",M4.translation(x,0.03,y0+S.boxB/2),3);
    }
  }
  lagg(span,T.span);
  lagg(new Bygge().yta(S.bredd,S.langd,"#FFFFFF",
    M4.translation(vx,0.005,S.langd/2),14),T.betong);

  /* Ytterväggar och tak. */
  const vagg=new Bygge();
  vagg.lada(S.bredd+0.4,S.tak,0.25,"#FFFFFF",M4.translation(vx,S.tak/2,-0.1));
  vagg.lada(S.bredd+0.4,S.tak,0.25,"#FFFFFF",M4.translation(vx,S.tak/2,S.langd+0.1));
  vagg.lada(0.25,S.tak,S.langd,"#FFFFFF",M4.translation(-0.1,S.tak/2,S.langd/2));
  vagg.lada(0.25,S.tak,S.langd,"#FFFFFF",M4.translation(S.bredd+0.1,S.tak/2,S.langd/2));
  lagg(vagg,T.parlspont);
  /* Taket, efter IMG_0249 och IMG_0250. Det är inte ett platt vitt
     innertak med limträbalkar utan ett SADELTAK: galvaniserad
     korrugerad plåt som undertak, tvärgående balkar i tegelrött var
     fjärde meter, en rad takfönster högt i västra takfallet, och
     galvade dragstag som hänger ner från varje balk till boxarnas
     överkant. Det är stagen och de röda balkarna man känner igen
     stallet på inifrån. */
  const RESN=2.1, NOCK=S.tak+RESN, halvB=S.bredd/2;
  const takL=Math.hypot(halvB,RESN), takV=Math.atan2(RESN,halvB);
  const tak=new Bygge();
  for(const sida of [-1,1])                         // takfallen i galvad plåt
    tak.lada(takL,0.14,S.langd+0.5,"#D9DDE1",
      M4.mul(M4.translation(vx+sida*halvB/2,S.tak+RESN/2,S.langd/2),
             M4.rotZ(-sida*takV)));
  /* Undersidan av ett tak får bara ambient och blev nästan svart, fast
     filmen visar ljus galvplåt hela vägen upp i nocken — armaturerna
     lyser den jämnt. Den ritas därför obelyst, med sin egen ton. */
  S3.statiskt.push({nat:GL.nat(tak), tex:T.takplat, platt:true});
  const stomme=new Bygge();
  for(let z=2;z<S.langd;z+=4){
    /* Tvärbalken i tegelrött, precis under takfoten. */
    stomme.lada(S.bredd,0.26,0.22,"#9C4A32",M4.translation(vx,S.tak-0.13,z));
    /* Nockbalken och snedstagen upp mot nocken. */
    for(const sida of [-1,1])
      stomme.lada(takL*0.9,0.16,0.14,"#9C4A32",
        M4.mul(M4.translation(vx+sida*halvB*0.45,S.tak+RESN*0.45,z),
               M4.rotZ(-sida*takV)));
  }
  stomme.lada(0.20,0.24,S.langd,"#9C4A32",M4.translation(vx,NOCK-0.2,S.langd/2));
  lagg(stomme,T.tra);
  const galv=new Bygge();
  for(let z=2;z<S.langd;z+=4)                       // dragstagen ner till boxarna
    for(const sida of [-1,1])
      galv.cyl(0.035,0.035,S.tak-2.3,"#B4B9BE",
        M4.translation(vx+sida*S.ganghalva,2.3,z),6);
  lagg(galv,null);
  /* Takfönstren i västra takfallet — ljuset som gör gången läsbar. */
  const lykt=new Bygge();
  for(let z=5;z<S.langd-3;z+=4.5)
    lykt.lada(1.5,0.10,0.85,"#F8F5E8",
      M4.mul(M4.translation(vx-halvB*0.52,S.tak+RESN*0.52,z),M4.rotZ(takV)));
  /* Runda pendelarmaturer i rad över vardera boxraden. */
  for(let z=3;z<S.langd;z+=4.5)
    for(const sida of [-1,1]){
      const ax=vx+sida*S.ganghalva*0.62;
      lykt.cyl(0.012,0.012,0.55,"#8E939B",M4.translation(ax,S.tak-0.55,z),5);
      lykt.cyl(0.20,0.20,0.09,"#FBF6E4",M4.translation(ax,S.tak-0.62,z),10);
    }
  lagg(lykt,null);

  /* Boxfronterna: komposit, galvad ram, galler och namnskylt. */
  const front=new Bygge(), galler=new Bygge();
  for(const sida of["W","E"]){
    const rad=S.boxar[sida], fx=sida==="W"?vx-S.ganghalva:vx+S.ganghalva;
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB, y1=y0+S.boxB;
      if(y1>S.klubbY)break;
      const my=(y0+y1)/2;
      front.lada(0.12,1.35,S.boxB-0.04,"#4A4D50",M4.translation(fx,0.675,my));
      front.lada(0.16,0.10,S.boxB,"#B4B8BB",M4.translation(fx,1.38,my));
      for(const dy of [y0,y1])
        galler.lada(0.14,2.15,0.14,"#B4B8BB",M4.translation(fx,1.07,dy));
      for(let g=1;g<8;g++)
        galler.cyl(0.022,0.022,0.78,"#989CA0",
          M4.translation(fx,1.43,y0+(y1-y0)*g/8),6);
      galler.lada(0.14,0.10,S.boxB,"#B4B8BB",M4.translation(fx,2.20,my));
      /* Skiljeväggar mellan boxarna. */
      const ut=sida==="W"?-1:1;
      front.lada(S.boxDjup,1.35,0.10,"#4A4D50",
        M4.translation(fx+ut*S.boxDjup/2,0.675,y0));
      const h=boxHast(rad[i]);
      const b=new Bygge();
      v3dTextPanel(b,0.85,0.22,
        M4.mul(M4.translation(fx+ut*0.09,1.62,my),M4.rotY(ut>0?-Math.PI/2:Math.PI/2)));
      S3.statiskt.push({nat:GL.nat(b), tex:v3dNamnTex(h?h.namn.toUpperCase():"—")});
    }
  }
  lagg(front,null); lagg(galler,null);

  /* Rummen i klubbdelen och servicedelen. */
  const rum=new Bygge();
  for(const grupp of [S.rum,S.service]) for(const r of grupp){
    const k=r.rekt;
    const gx=k.x<vx?k.x+k.w:k.x;                    // väggen mot gången
    rum.lada(0.16,2.6,k.h,"#FFFFFF",M4.translation(gx,1.3,k.y+k.h/2));
    rum.lada(k.w,2.6,0.16,"#FFFFFF",M4.translation(k.x+k.w/2,1.3,k.y));
    rum.lada(k.w,2.6,0.16,"#FFFFFF",M4.translation(k.x+k.w/2,1.3,k.y+k.h));
    const b=new Bygge();
    v3dTextPanel(b,Math.min(k.h*0.8,2.6),0.5,
      M4.mul(M4.translation(gx+(k.x<vx?0.09:-0.09),1.9,k.y+k.h/2),
        M4.rotY(k.x<vx?Math.PI/2:-Math.PI/2)));
    S3.statiskt.push({nat:GL.nat(b), tex:v3dEtikettTex(r.label)});
  }
  /* Tvärväggarna med dörrgap. */
  for(const tv of S.tvarvaggar){
    const gap=tv.gap;
    rum.lada(vx-gap/2,2.8,0.16,"#FFFFFF",M4.translation((vx-gap/2)/2,1.4,tv.y));
    rum.lada(S.bredd-vx-gap/2,2.8,0.16,"#FFFFFF",
      M4.translation(vx+gap/2+(S.bredd-vx-gap/2)/2,1.4,tv.y));
  }
  lagg(rum,T.parlspont);
  /* Whiteboarden. */
  const wb=new Bygge();
  wb.panel(1.6,1.0,"#F6F4EE",M4.mul(M4.translation(S.whiteboard.pos[0]+0.2,1.7,
    S.whiteboard.pos[1]),M4.rotY(-Math.PI/2)));
  lagg(wb,null);
}

/* ── Ridhuset invändigt ───────────────────────────────────────── */
function v3dRidhus(lagg,opp){
  const R=RIDHUSINNE, ba=R.bana, T=S3.tex;
  lagg(new Bygge().yta(R.bredd,R.langd,"#FFFFFF",
    M4.translation(R.bredd/2,0.01,R.langd/2),8),T.grus);
  /* Underlaget inne är brunt och träfiberbemängt — inte utebanans gula
     sand. Tonen tas ner på plats i stället för att göra en egen textur. */
  lagg(new Bygge().yta(ba.w,ba.h,"#9C8663",
    M4.translation(ba.x+ba.w/2,0.03,ba.y+ba.h/2),9),T.sand);
  /* Sargen med svart sockel — porten vid A lämnas öppen. */
  const sarg=new Bygge();
  const bit=(x0,z0,x1,z1)=>{
    const dx=x1-x0, dz=z1-z0, len=Math.hypot(dx,dz);
    if(len<0.05)return;
    const vin=Math.atan2(dz,dx);
    const m=M4.mul(M4.translation((x0+x1)/2,0,(z0+z1)/2),M4.rotY(-vin));
    sarg.lada(len,0.26,0.16,"#2E2E2C",M4.mul(m,M4.translation(0,0.13,0)));
    sarg.lada(len,R.sargH-0.26,0.14,"#E9E5DC",M4.mul(m,M4.translation(0,0.26+(R.sargH-0.26)/2,0)));
    sarg.lada(len,0.07,0.18,"#CFC8BC",M4.mul(m,M4.translation(0,R.sargH+0.03,0)));
  };
  bit(ba.x,ba.y+ba.h,R.port.x0,ba.y+ba.h); bit(R.port.x1,ba.y+ba.h,ba.x+ba.w,ba.y+ba.h);
  bit(ba.x,ba.y,ba.x+ba.w,ba.y);
  bit(ba.x,ba.y,ba.x,ba.y+ba.h); bit(ba.x+ba.w,ba.y,ba.x+ba.w,ba.y+ba.h);
  lagg(sarg,null);
  /* Ytterväggar, sadeltak och limträstolar. */
  const hall=new Bygge();
  hall.lada(R.bredd,R.tak,0.3,"#FFFFFF",M4.translation(R.bredd/2,R.tak/2,-0.15));
  hall.lada(R.bredd,R.tak,0.3,"#FFFFFF",M4.translation(R.bredd/2,R.tak/2,R.langd+0.15));
  hall.lada(0.3,R.tak,R.langd,"#FFFFFF",M4.translation(-0.15,R.tak/2,R.langd/2));
  hall.lada(0.3,R.tak,R.langd,"#FFFFFF",M4.translation(R.bredd+0.15,R.tak/2,R.langd/2));
  const halvS=R.bredd/2, resn=2.8;
  const takL=Math.hypot(halvS,resn), takV=Math.atan2(resn,halvS);
  /* Takfallen lutar ned mot väggarna — samma teckenregel som utvändigt. */
  for(const s of [-1,1])
    hall.lada(takL,0.18,R.langd+0.6,"#3A3E44",
      M4.mul(M4.translation(R.bredd/2+s*halvS/2,R.tak+resn/2,R.langd/2),M4.rotZ(-s*takV)));
  for(let z=1;z<R.langd;z+=6){
    hall.lada(R.bredd,0.26,0.24,"#7A5C3E",M4.translation(R.bredd/2,R.tak-0.2,z));
    hall.lada(0.22,2.7,0.22,"#7A5C3E",M4.translation(R.bredd/2,R.tak+1.3,z));
  }
  for(let z=4;z<R.langd;z+=7)
    for(const x of [R.bredd*0.3,R.bredd*0.7])
      hall.lada(1.3,0.10,0.26,"#F6F2E4",M4.translation(x,R.tak-0.35,z));
  lagg(hall,null);
  /* Läktaren, domarbåset, cafeterian och trappan. */
  /* Läktaren är en trästomme: fyrkantsstolpar, balkar och plankbänkar i
     ljus furu — inte gjutna trappsteg. Under den finns ett mörkt utrymme
     där bommar och stöd förvaras, och på översta bänken ligger elons
     svarta dynor. Allt ur interiörfotona. */
  const lak=new Bygge(), L=R.laktare, LL=L.y1-L.y0, Lm=(L.y0+L.y1)/2;
  for(let i=0;i<L.steg;i++){
    const x=L.x0+i*L.stegD+L.stegD/2, y=L.stegH*(i+1);
    lak.lada(L.stegD-0.04,0.07,LL,"#D8C7A4",M4.translation(x,y,Lm));      // sittplankan
    lak.lada(L.stegD-0.04,0.06,LL,"#C4B08C",M4.translation(x,y-0.20,Lm)); // fotplankan
    for(let z=L.y0;z<=L.y1;z+=2.5)                                        // stommen
      lak.lada(0.10,y,0.10,"#A98F68",M4.translation(x-L.stegD/2+0.08,y/2,z));
  }
  {const xt=L.x0+L.steg*L.stegD;                    // översta däcket och räckesbalk
   lak.lada(0.9,0.09,LL,"#D8C7A4",M4.translation(xt+0.4,L.steg*L.stegH,Lm));
   for(let z=L.y0;z<=L.y1;z+=2.5)
     lak.lada(0.12,L.steg*L.stegH,0.12,"#A98F68",
       M4.translation(xt+0.8,L.steg*L.stegH/2,z));}
  for(let i=0;i<(R.dynor||0);i++){                  // elon-dynorna
    const z=L.y0+2.0+i*((LL-4)/Math.max(1,R.dynor-1));
    lak.lada(0.44,0.06,0.34,"#26282C",
      M4.translation(L.x0+(L.steg-1)*L.stegD+L.stegD/2,L.stegH*L.steg+0.06,z));
  }
  for(const z of [L.y0+6,L.y0+8.4,L.y1-7]){         // stolarna på översta däcket
    const x=L.x0+L.steg*L.stegD+0.4;
    lak.lada(0.42,0.06,0.42,"#D4551E",M4.translation(x,0.45+L.steg*L.stegH,z));
    lak.lada(0.42,0.46,0.06,"#D4551E",M4.translation(x,0.68+L.steg*L.stegH,z-0.18));
    for(const d of [-0.16,0.16])
      lak.lada(0.04,0.45,0.04,"#8C8F92",M4.translation(x+d,0.22+L.steg*L.stegH,z));
  }
  {const L2=R.laktare;                              // räcket längs läktarens framkant
   for(const y of [0.62,1.02])
     lak.lada(0.09,0.09,L2.y1-L2.y0,"#8A6A44",
       M4.translation(L2.x0-0.10,y+L2.steg*L2.stegH,(L2.y0+L2.y1)/2));
   for(let z=L2.y0;z<=L2.y1;z+=2.4)
     lak.lada(0.09,1.05,0.09,"#8A6A44",
       M4.translation(L2.x0-0.10,0.52+L2.steg*L2.stegH,z));}
  lak.lada(1.9,2.2,1.9,"#FFFFFF",M4.translation(R.domarbas.x,1.1,R.domarbas.y));
  lak.lada(2.1,0.14,2.1,"#C8BCA8",M4.translation(R.domarbas.x,2.25,R.domarbas.y));
  for(let i=0;i<8;i++)                                  // trappan upp till caféet
    lak.lada(1.2,0.19,0.30,"#FFFFFF",
      M4.translation(R.trappa.x,0.19*i+0.10,R.trappa.y+0.30*i));
  lagg(lak,T.tra);
  /* Entré- och trapphusdelen i norra gaveln, mot parkeringen.
     Utrymningsplanen visar en
     djup del med två trapphus, hiss och rum — inte en tre meter grund
     överbyggnad. Kommer man in från parkeringen står man i en hall och
     ser banan genom öppningen, i stället för att kliva rakt ut på den. */
  /* Hela entré-delen är byggd i gavelns lokala ände z∈[0,E] och vrids
     180° runt husets mitt, så att den hamnar i den NORRA gaveln och
     speglingen stämmer med utsidans dörrar (entrén i öster, caféets
     trappa i väster). En rotation, inte en spegling — normalerna
     behåller sin riktning. */
  const RT=m=>M4.mul(M4.mul(M4.translation(R.bredd/2,0,R.langd/2),M4.rotY(Math.PI)),
    M4.mul(M4.translation(-R.bredd/2,0,-R.langd/2),m));
  const RTt=(x,y,z)=>RT(M4.translation(x,y,z));   // som M4.translation, fast vriden
  const cafe=new Bygge(), E=R.entre||R.cafe.djup;
  cafe.lada(R.bredd,0.26,E,"#CFC8BC",                   // caféets golv, banans tak
    RTt(R.bredd/2,R.cafe.z0,E/2));
  cafe.lada(R.bredd,R.cafe.z1-R.cafe.z0-0.26,0.16,"#E9E5DC",
    RTt(R.bredd/2,(R.cafe.z0+R.cafe.z1)/2,E));
  for(let x=2;x<R.bredd-1;x+=3.2)                       // fönsterbandet mot banan
    cafe.panel(2.4,1.1,"#3A4A5C",RTt(x,R.cafe.z0+1.3,E+0.10));
  /* Skiljeväggen mot banan. Öppningen är bred och går ända upp — man
     ska se banan från dörren, annars blir hallen en återvändsgränd. */
  {/* Öppningen anges i det ovridna systemet så att den efter
      180°-vridningen hamnar mitt för sargporten. */
   const op0=R.bredd-R.port.x1-2.6, op1=R.bredd-R.port.x0+2.6;
   cafe.lada(op0,R.cafe.z0,0.18,"#EFEBE2",RTt(op0/2,R.cafe.z0/2,E));
   cafe.lada(R.bredd-op1,R.cafe.z0,0.18,"#EFEBE2",
     RTt((op1+R.bredd)/2,R.cafe.z0/2,E));
   cafe.lada(op1-op0,0.22,0.22,"#8A6A44",RTt((op0+op1)/2,R.cafe.z0-0.11,E));}
  /* Rummen: kansliet till vänster, omklädningen till höger, trapphusen
     i bortre hörnen. Väggarna är antydda, inte ritade rum för rum —
     planen går inte att läsa så noga. */
  cafe.lada(0.16,2.6,E-3.4,"#EFEBE2",RTt(6.4,1.3,E/2-0.2));
  cafe.lada(5.2,2.6,0.16,"#EFEBE2",RTt(3.8,1.3,E-3.4));
  cafe.lada(0.16,2.6,4.4,"#EFEBE2",RTt(18.6,1.3,E-2.4));
  for(let i=0;i<9;i++)                                   // andra trapphuset
    cafe.lada(1.3,0.17,0.30,"#D8CFC0",RTt(19.6,0.17*i+0.09,E-4.4+0.30*i));
  lagg(cafe,null);

  /* ── Hallen möblerad ──────────────────────────────────────────────
     En tom hall med lågt tak läser som en tunnel. Det som gör den till
     en entré är ljuset i taket, ett golv som skiljer sig från banan,
     och saker man känner igen: disken, bänkarna, anslagstavlan och
     hyllan med hjälmar. ── */
  lagg(new Bygge().yta(R.bredd-0.4,E-0.4,"#FFFFFF",
    RTt(R.bredd/2,0.02,E/2),6),T.marksten);
  const mob=new Bygge();
  for(let x=3;x<R.bredd-1;x+=4.4)                        // takarmaturerna
    for(let z=2.2;z<E-1;z+=4.0)
      mob.lada(1.5,0.09,0.34,"#FBF6E6",RTt(x,R.cafe.z0-0.16,z));
  /* Receptionsdisken innanför dörren. */
  mob.lada(3.2,1.08,0.70,"#8A6A44",RTt(9.8,0.54,3.4));
  mob.lada(3.4,0.09,0.86,"#C4A87E",RTt(9.8,1.12,3.4));
  /* Bänkar längs väggen, och hyllan med hjälmar ovanför. */
  for(const z of [5.4,7.6,9.8]){
    mob.lada(0.44,0.07,1.70,"#C4A87E",RTt(1.1,0.46,z));
    for(const d of [-0.7,0.7])
      mob.lada(0.09,0.46,0.09,"#8A6A44",RTt(1.1,0.23,z+d));
    mob.lada(0.50,0.07,1.70,"#C4A87E",RTt(1.2,1.62,z));
    for(let i=0;i<3;i++)
      mob.klot(0.14,"#3A4A5C",M4.mul(RTt(1.2,1.78,z-0.6+i*0.6),
        M4.skala(1,0.72,1)),8);
  }
  /* Anslagstavlan och en pokalhylla mot kansliväggen. */
  mob.lada(0.10,1.10,2.40,"#6B4A34",RTt(6.28,1.55,E/2-0.2));
  mob.lada(0.09,0.90,2.20,"#F2EDE2",RTt(6.22,1.55,E/2-0.2));
  mob.lada(0.34,0.07,2.00,"#C4A87E",RTt(6.55,2.15,E/2-2.6));
  for(let i=0;i<5;i++)
    mob.cyl(0.07,0.05,0.22,"#D6AE3C",RTt(6.55,2.22,E/2-3.4+i*0.42),8);
  lagg(mob,T.tra);
  /* Glaspartiet mot parkeringen, så att hallen får dager norrifrån. */
  const glas=new Bygge();
  for(const x of [3.1,4.4])
    glas.panel(1.1,2.2,"#BFD4DE",M4.mul(RTt(x,1.15,0.14),M4.ny()));
  glas.panel(1.5,1.5,"#BFD4DE",M4.mul(RTt(3.4,3.6,0.14),M4.ny()));
  S3.statiskt.push({nat:GL.nat(glas), tex:null, baksidor:true});
  /* Hindren som står framme, konerna och uppsittningspallen. Vita stöd
     med kupor, bommar i blå-vitt eller röd-vitt — det som ligger och
     står i ridhuset mellan lektionerna och gör det till en arbetsplats
     i stället för en tom låda. */
  const hind=new Bygge();
  for(const hi of (R.hinder||[])){
    const bx=ba.x+hi.x, bz=ba.y+hi.y;
    const fa=hi.farg==="rod"?"#B0332E":"#3E7FB8";
    for(const s of [-1,1]){
      hind.lada(0.10,1.28,0.10,"#EFEAE0",M4.translation(bx+s*hi.b/2,0.64,bz));
      hind.lada(0.46,0.07,0.46,"#EFEAE0",M4.translation(bx+s*hi.b/2,0.035,bz));
    }
    const y=hi.h>0.02?hi.h:0.055, n=6;
    for(let i=0;i<n;i++)
      hind.lada(hi.b/n,0.10,0.10,i%2?fa:"#F2EDE2",
        M4.translation(bx-hi.b/2+hi.b/n*(i+0.5),y,bz));
  }
  for(const k of (R.koner||[]))
    hind.cyl(0.17,0.035,0.44,"#D4551E",M4.translation(ba.x+k[0],0,ba.y+k[1]),8);
  if(R.pall){                                       // uppsittningspallen vid sargen
    const px=ba.x+R.pall.x, pz=ba.y+R.pall.y;
    for(let i=0;i<3;i++)
      hind.lada(0.90-i*0.02,0.19,0.34,"#C4A87E",M4.translation(px,0.19*i+0.095,pz+0.34*i));
    for(const d of [-0.42,0.42])
      hind.lada(0.06,0.57,0.06,"#A98F68",M4.translation(px+d,0.285,pz+0.55));
  }
  lagg(hind,null);
  /* Sponsorväggen med speglar och banderoller. */
  const panel=new Bygge();
  for(const sp of R.speglar){                       // speglar i träram
    panel.lada(0.08,1.9,sp.b,"#8E969E",M4.translation(ba.x-0.22,2.25,sp.y));
    panel.lada(0.11,0.14,sp.b+0.24,"#7A5636",M4.translation(ba.x-0.24,3.27,sp.y));
    panel.lada(0.11,0.14,sp.b+0.24,"#7A5636",M4.translation(ba.x-0.24,1.23,sp.y));
    for(const d of [-1,1])
      panel.lada(0.11,2.18,0.12,"#7A5636",M4.translation(ba.x-0.24,2.25,sp.y+d*(sp.b/2+0.06)));
    panel.lada(0.06,1.9,0.05,"#7A5636",M4.translation(ba.x-0.26,2.25,sp.y));
  }
  panel.lada(0.12,0.9,R.langd*0.8,"#6B4A34",M4.translation(ba.x-0.24,3.7,R.langd/2));
  lagg(panel,null);
  for(const s of R.skyltar){
    const b=new Bygge();
    v3dTextPanel(b,s.b,s.b*0.25,
      M4.mul(M4.translation(ba.x-0.30,2.6,s.y),M4.rotY(Math.PI/2)));
    S3.statiskt.push({nat:GL.nat(b), tex:(S3.tex.skyltar||[])[R.skyltar.indexOf(s)]
      ||v3dEtikettTex(s.text)});
  }
  /* Dressyrbokstäverna på sargen. Banans A ska stå vid sargporten,
     som nu sitter i norra kortsidan — hela bokstavsringen vrids
     därför 180° (en vridning bevarar varvriktningen A-K-V-E-...). */
  for(const bo of DRESSYRBOKSTAVER){
    const lx=20-bo.x, ly=60-bo.y;
    const bx=ba.x+lx, bz=ba.y+ly;
    let mat;
    if(lx===0)      mat=M4.mul(M4.translation(bx+0.12,1.05,bz),M4.rotY(Math.PI/2));
    else if(lx===20)mat=M4.mul(M4.translation(bx-0.12,1.05,bz),M4.rotY(-Math.PI/2));
    else if(ly===0) mat=M4.mul(M4.translation(bx,1.05,bz+0.12),M4.ny());
    else            mat=M4.mul(M4.translation(bx,1.05,bz-0.12),M4.rotY(Math.PI));
    const b=new Bygge(); v3dTextPanel(b,0.62,0.31,mat);
    S3.statiskt.push({nat:GL.nat(b), tex:(S3.tex.bokstav||{})[bo.b]});
  }
}

/* ── Bygg om scenen ───────────────────────────────────────────── */
function v3dBygg(scen){
  for(const s of S3.statiskt)GL.fritt(s.nat);
  S3.statiskt=[];
  if(V3D.oppningar){GL.fritt(V3D.oppningar.nat);V3D.oppningar=null;}
  v3dTexturer();
  if(!S3.tex.skyltar)s3Texturer();
  const lagg=(bygge,tex)=>S3.statiskt.push({nat:GL.nat(bygge),tex});
  const opp=new Bygge();
  if(scen==="gard")v3dGard(lagg,opp);
  else if(scen==="stallinne")v3dStall(lagg,opp);
  else v3dRidhus(lagg,opp);
  if(opp.antal)V3D.oppningar={nat:GL.nat(opp)};
  /* Himlen byggs av ridscenens kod, med gårdens ljus. */
  s3Himmel(scen==="gard"?[105,85]:[10,30]);
  V3D.plats=scen;
  V3D.nyckel=(G.vader&&G.vader.typ)||"sol";
}

/* ── Kameran bakom vandraren ──────────────────────────────────── */
function v3dKamera(dt){
  const fram=[Math.cos(VD.rikt),0,Math.sin(VD.rikt)];
  const bak=3.6, hojd=2.25;
  let mx=VD.px-fram[0]*bak, mz=VD.py-fram[2]*bak;
  /* På gården knuffas kameran ut ur byggnaderna, annars fylls bilden
     av en vägg när man går tätt intill en fasad. */
  if(G.scen==="gard"){
    for(const bg of ANL.byggnader){
      const r=bg.rekt, m=0.7;
      if(mx>r.x-m&&mx<r.x+r.w+m&&mz>r.y-m&&mz<r.y+r.h+m){
        const dV=mx-(r.x-m), dO=(r.x+r.w+m)-mx, dS=mz-(r.y-m), dN=(r.y+r.h+m)-mz;
        const minst=Math.min(dV,dO,dS,dN);
        if(minst===dV)mx=r.x-m; else if(minst===dO)mx=r.x+r.w+m;
        else if(minst===dS)mz=r.y-m; else mz=r.y+r.h+m;
      }
    }
  }
  /* Inomhus hålls kameran innanför väggarna. */
  if(G.scen==="stallinne"){
    mx=clamp(mx,0.6,STALLINNE.bredd-0.6); mz=clamp(mz,0.6,STALLINNE.langd-0.6);
  }else if(G.scen==="ridhusinne"){
    mx=clamp(mx,0.6,RIDHUSINNE.bredd-0.6); mz=clamp(mz,0.6,RIDHUSINNE.langd-0.6);
  }
  const k=V3D.kam;
  if(!k.satt){k.x=mx;k.y=hojd;k.z=mz;k.tx=VD.px;k.ty=1.3;k.tz=VD.py;k.satt=true;}
  const f=1-Math.pow(0.0015,Math.min(dt,0.05));
  k.x+=(mx-k.x)*f; k.y+=(hojd-k.y)*f; k.z+=(mz-k.z)*f;
  k.tx+=((VD.px+fram[0]*2.6)-k.tx)*f;
  k.ty+=(1.35-k.ty)*f;
  k.tz+=((VD.py+fram[2]*2.6)-k.tz)*f;
  return k;
}

/* ── Vandraren i tredjeperson ─────────────────────────────────────
   Figuren byggs som en kropp och inte som staplade klossar: bröstkorg
   som smalnar mot midjan, sluttande axlar, leder som kulor så att
   armar och ben hänger ihop, och armbåge och knä som verkligen viker
   sig i gången. ── */
/* Ett lem som svept kropp: radien anges där den betyder något —
   axel, armbåge, handled — och ytan går i ett stycke däremellan.
   Byggs i enhetsramen y 0→1 så att s3Segment kan lägga den mellan
   två punkter. bredd() ger halva bredden, djup() halva djupet. */
function v3dLem(st, seg){
  return s3Svep(new Bygge(),"#FFFFFF",seg||16,10,(t,u)=>{
    const a=u*Math.PI*2;
    const r=ROND2(t);
    return [Math.sin(a)*s3Stn(t,st.b)*r, t, Math.cos(a)*s3Stn(t,st.d)*r];
  });
}
/* Rundar av lemmens ändar så att den sluter sig. */
function ROND2(t){
  const k=0.06;
  if(t<k)return Math.sqrt(Math.max(0,1-Math.pow((k-t)/k,2)));
  if(t>1-k)return Math.sqrt(Math.max(0,1-Math.pow((t-(1-k))/k,2)));
  return 1;
}

function v3dBygFigur(){
  if(S3.del.gTorso)return;
  const D=S3.del, JEANS="#3C4A63", HUD="#E0B892", HAR="#5E4028";

  /* Bålen sveps i ett stycke i figurens egna mått, fötterna i y=0:
     höften bred, midjan indragen, bröstkorgen djup, axlarna sluttande.
     Jackan bakas vit så att varje figur får sin egen färg via ton. */
  D.gTorso=GL.nat(s3Svep(new Bygge(),"#FFFFFF",26,16,(t,u)=>{
    const y=0.855+t*0.575;                       // höftkam → nackgrop
    const a=u*Math.PI*2, r=ROND2(t);
    const B=[[0,0.152],[0.12,0.130],[0.34,0.146],[0.58,0.180],
             [0.78,0.212],[0.90,0.204],[1,0.088]];
    const Dj=[[0,0.114],[0.12,0.098],[0.34,0.112],[0.58,0.130],
              [0.78,0.126],[0.90,0.112],[1,0.078]];
    /* bröstkorgen buktar framåt, ryggen är rakare */
    const fram=Math.max(0,Math.cos(a))*s3Stn(t,[[0,0],[0.5,0.012],[0.75,0.026],[1,0.004]]);
    return [Math.sin(a)*s3Stn(t,B)*r, y, Math.cos(a)*s3Stn(t,Dj)*r + fram];
  }));

  /* Höften och skärpet i byxans färg. */
  D.gHoft=GL.nat((()=>{
    const b=s3Svep(new Bygge(),JEANS,14,14,(t,u)=>{
      const y=0.70+t*0.185, a=u*Math.PI*2, r=ROND2(t);
      const B=[[0,0.118],[0.45,0.140],[1,0.152]];
      const Dj=[[0,0.098],[0.45,0.108],[1,0.115]];
      return [Math.sin(a)*s3Stn(t,B)*r, y, Math.cos(a)*s3Stn(t,Dj)*r];
    });
    b.lada(0.315,0.042,0.238,"#2A2620",M4.translation(0,0.878,0));   // skärp
    b.cyl(0.048,0.044,0.075,HUD,M4.translation(0,1.418,0),12);       // hals
    return b;})());

  /* Armarna: överarm med axelmuskel, underarm som smalnar mot handleden. */
  D.gArmO=GL.nat(v3dLem({b:[[0,0.058],[0.25,0.052],[1,0.041]],
                         d:[[0,0.056],[0.25,0.050],[1,0.040]]},14));
  D.gArmU=GL.nat(v3dLem({b:[[0,0.045],[0.30,0.043],[1,0.030]],
                         d:[[0,0.044],[0.30,0.041],[1,0.029]]},14));
  D.gAxel=GL.nat(new Bygge().klot(1,"#FFFFFF",M4.skala(0.048,0.042,0.046),12));
  D.gLedA=GL.nat(new Bygge().klot(0.036,"#FFFFFF",null,10));
  /* Handen: en formad kupa, inte ett klot. */
  D.gHand=GL.nat(s3Svep(new Bygge(),HUD,10,10,(t,u)=>{
    const a=u*Math.PI*2, r=ROND2(t);
    const b=(0.036+0.014*Math.sin(t*Math.PI))*r, d=(0.024+0.006*Math.sin(t*Math.PI))*r;
    return [Math.sin(a)*b, -t*0.115, Math.cos(a)*d];
  }));

  /* Benen: låret tjockt upptill, vaden med muskelbuk, smalben. */
  D.gLar=GL.nat(v3dLem({b:[[0,0.092],[0.30,0.082],[1,0.056]],
                        d:[[0,0.088],[0.30,0.080],[1,0.055]]},14));
  D.gVad=GL.nat(v3dLem({b:[[0,0.058],[0.28,0.062],[0.72,0.042],[1,0.033]],
                        d:[[0,0.057],[0.28,0.060],[0.72,0.041],[1,0.032]]},14));
  D.gKna=GL.nat(new Bygge().klot(1,JEANS,M4.skala(0.052,0.046,0.050),10));
  /* Kängan med klack och tå. */
  D.gKanga=GL.nat((()=>{
    const b=s3Svep(new Bygge(),"#2B211A",12,10,(t,u)=>{
      const a=u*Math.PI*2, r=ROND2(t);
      const br=(0.052+0.006*Math.sin(t*Math.PI))*r;
      return [ -0.055+t*0.225, 0.052+Math.cos(a)*0.044*r - t*t*0.012,
               Math.sin(a)*br ];
    });
    b.lada(0.075,0.030,0.092,"#181310",M4.translation(-0.028,0.015,0)); // klack
    b.lada(0.215,0.022,0.104,"#181310",M4.translation(0.030,0.011,0));  // sula
    return b;})());

  /* Huvudet: pannben, kindben, haka — och ett ansikte. */
  D.gHuvud=GL.nat((()=>{
    const b=s3Svep(new Bygge(),HUD,18,14,(t,u)=>{
      const x=-0.092+t*0.184, a=u*Math.PI*2, r=ROND2(t);
      const H=[[0,0.086],[0.28,0.108],[0.55,0.106],[0.80,0.082],[1,0.058]];
      const B=[[0,0.080],[0.28,0.092],[0.55,0.086],[0.80,0.062],[1,0.044]];
      const yc=s3Stn(t,[[0,0.004],[0.55,-0.004],[1,-0.030]]);
      return [x, yc+Math.cos(a)*s3Stn(t,H)*r, Math.sin(a)*s3Stn(t,B)*r];
    });
    for(const s of [-1,1]){                                        // ögonen
      b.klot(1,"#FFFFFF",M4.mul(M4.translation(0.058,0.004,s*0.033),
        M4.skala(0.015,0.019,0.016)),7);
      b.klot(1,"#2B2118",M4.mul(M4.translation(0.068,0.002,s*0.034),
        M4.skala(0.010,0.013,0.011)),7);
    }
    b.klot(1,"#B9755E",M4.mul(M4.translation(0.076,-0.054,0),
      M4.skala(0.010,0.008,0.024)),6);                             // munnen
    b.klot(1,HUD,M4.mul(M4.translation(0.030,-0.078,0),
      M4.skala(0.036,0.030,0.048)),9);                             // hakan
    return b;})());

  /* Håret: en kalott som täcker hjässa, sidor och nacke men lämnar
     ansiktet fritt, plus en hästsvans som faller från nacken.
     fi mäts från hjässan, te runt lodaxeln med 0 rakt fram. */
  D.gHar=GL.nat((()=>{
    const rx=0.100, ry=0.114, rz=0.096;
    const b=s3Yta(new Bygge(),HAR,14,16,(t,v)=>{
      const fi=t*1.34;                       // hjässa → nacke
      const te=0.78+v*(Math.PI*2-1.56);      // lämnar en kil fri åt ansiktet
      return [rx*Math.sin(fi)*Math.cos(te),
              0.010+ry*Math.cos(fi),
              rz*Math.sin(fi)*Math.sin(te)];
    },0.013);
    /* hästsvansen faller från nacken */
    for(let i=0;i<=9;i++){
      const t=i/9, w=0.042*(1-0.36*t)+0.016*Math.sin(t*Math.PI);
      b.klot(1,HAR,M4.mul(
        M4.translation(-0.108-0.062*t*t, -0.034-0.170*t, 0),
        M4.skala(w*1.15,0.048,w)),9);
    }
    return b;})());
  D.gHjalm=GL.nat((()=>{
    const b=new Bygge();
    b.klot(1,"#23282F",M4.mul(M4.translation(-0.012,0,0),
      M4.skala(0.108,0.078,0.104)),14);
    b.klot(1,"#2E343C",M4.mul(M4.translation(0.086,-0.012,0),
      M4.skala(0.072,0.011,0.082)),12);
    b.klot(1,"#3E6B47",M4.mul(M4.translation(-0.02,0.072,0),
      M4.skala(0.068,0.026,0.078)),10);                            // klubbens färg
    return b;})());
}
function v3dRitaSpelare(){
  v3dFigur({x:VD.px,z:VD.py,rikt:VD.rikt,fas:VD.fas,jacka:"#3E5F7A",hjalm:true});
}

/* En figur till fots — spelaren och stallets folk ritas likadant, med
   egen jackfärg. Går i takt med fas och svänger armarna mot benen. */
/* ══════════════════════════════════════════════════════════════════
   KLOSSFIGUREN — Roblox-stil.

   Sex delar: huvud, bål, två armar, två ben. Inga leder, inga knän,
   ingen hals. Delarna är rätblock som svänger stelt kring axel och
   höft. Poängen är att klossigheten är avsikten och inte ett
   misslyckat försök till en skulpterad kropp — därför läser den som
   rätt i stället för som ofärdig.

   Måtten är R6:s proportioner skalade till 1,72 m: benen och bålen
   lika höga, armarna lika långa som bålen, huvudet en bredare kloss
   ovanpå utan hals.
   ══════════════════════════════════════════════════════════════════ */
const KLOSS={
  /* B = bredd i sidled (Z), D = djup framåt (X). Figuren tittar mot +X,
     så det är B som ska vara axelbredden — inte D. */
  benH:0.64, benB:0.205, benD:0.205,
  balH:0.66, balB:0.420, balD:0.215,
  armH:0.64, armB:0.195, armD:0.200,
  huvB:0.380, huvH:0.360, huvD:0.340,
  stovel:0.40,             // andel av benet som är stövel
  hand:0.17,               // andel av armen som är hand
};

function v3dBygKloss(){
  if(S3.del.kBal)return;
  const D=S3.del, K=KLOSS, V="#FFFFFF";
  const lada=(d,h,b,mat)=>GL.nat(new Bygge().lada(d,h,b,V,mat));

  D.kBal   = lada(K.balD,K.balH,K.balB);
  D.kArm   = lada(K.armD,K.armH*(1-K.hand),K.armB);
  D.kHand  = lada(K.armD,K.armH*K.hand,K.armB);
  D.kBen   = lada(K.benD,K.benH*(1-K.stovel),K.benB);
  D.kStovel= lada(K.benD*1.04,K.benH*K.stovel,K.benB*1.04);
  D.kHuvud = lada(K.huvD,K.huvH,K.huvB);

  D.kHjalm=GL.nat((()=>{
    const b=new Bygge();
    b.lada(K.huvD*1.10,0.170,K.huvB*1.10,"#2B3038",
      M4.translation(0,K.huvH*0.32,0));                      // kåpan ned över pannan
    b.lada(0.105,0.032,K.huvB*0.82,"#20252C",
      M4.translation(K.huvD*0.58,K.huvH*0.25,0));            // skärmen fram
    b.lada(K.huvD*0.45,0.036,K.huvB*0.34,"#3E6B47",
      M4.translation(0,K.huvH*0.32+0.085,0));                // klubbens färg överst
    return b;})());

  /* Håret: en lugg runt hjässan och en hästsvans rakt bakåt. */
  D.kHar=GL.nat((()=>{
    const b=new Bygge(), H="#5E4028";
    b.lada(K.huvD*1.01,0.080,K.huvB*1.01,H,M4.translation(0,K.huvH*0.39,0));
    b.lada(0.105,0.300,K.huvB*0.44,H,
      M4.translation(-(K.huvD/2+0.050),-K.huvH*0.12,0));    // hästsvansen hänger ned
    b.lada(0.085,0.075,K.huvB*0.52,"#4A3120",
      M4.translation(-(K.huvD/2+0.040),K.huvH*0.16,0));     // snodden
    return b;})());

  /* Ansiktet ligger som en panel strax framför huvudets framsida.
     Texturen är vit i botten och tonas med hudfärgen. */
  D.kAnsikte=GL.nat(new Bygge().panel(K.huvB*0.98,K.huvH*0.98,V,
    M4.mul(M4.translation(K.huvD/2+0.004,0,0),M4.rotY(Math.PI/2))));
  S3.tex.ansikte=glCanvasTex(128,128,(c,w,h)=>{
    c.fillStyle="#FFFFFF"; c.fillRect(0,0,w,h);
    c.fillStyle="#241A14";
    for(const x of [42,86]){ c.beginPath(); c.ellipse(x,52,8.5,12,0,0,Math.PI*2); c.fill(); }
    c.strokeStyle="#241A14"; c.lineWidth=7; c.lineCap="round";
    c.beginPath(); c.arc(64,72,21,0.34,Math.PI-0.34); c.stroke();
  });

  /* Jackan: krage upptill, skärp nertill. Vit botten så att varje
     person kan få sin egen färg genom uTon. */
  S3.tex.klossJacka=glCanvasTex(64,64,(c,w,h)=>{
    c.fillStyle="#FFFFFF"; c.fillRect(0,0,w,h);
    c.fillStyle="#E4E4E4"; c.fillRect(0,0,w,5);              // krage
    c.fillStyle="#5A5A5A"; c.fillRect(0,h-14,w,7);           // skärp
    c.fillStyle="#D2D2D2"; c.fillRect(0,h-4,w,4);            // fållen
  });
}

/* Ritar klossfiguren. Armar och ben svänger stelt kring axel och höft,
   precis som R6 gör — inga knän, ingen hals. */
function v3dFigurKloss(o){
  v3dBygKloss();
  const D=S3.del, K=KLOSS;
  const bas=M4.mul(M4.translation(o.x,0,o.z),M4.rotY(-o.rikt));
  const fas=o.fas||0, rr=o.rorlig===false?0:1;
  const sv=Math.sin(fas*Math.PI*2)*rr*0.42;       // benens utslag i radianer
  const gung=0.022*Math.abs(Math.sin(fas*Math.PI*2))*rr;
  const jacka=o.jacka||"#3E5F7A", byxa=o.byxa||"#38455C",
        stovel="#4A3524", hud=o.hud||"#F0C083";
  const rita=(nat,mat,ton,tex)=>GL.rita(nat,M4.mul(bas,mat),{ton,tex});

  const hoftY=K.benH+gung;                        // höftlinjen = benets topp
  const axelY=hoftY+K.balH;                       // bålens topp

  rita(D.kBal,M4.translation(0,hoftY+K.balH/2,0),jacka,S3.tex.klossJacka);

  for(const s of [-1,1]){
    /* Benet svänger kring höften: rotZ(-v) för ned (0,-h) till
       (-h·sin v, -h·cos v), så delens mitt hamnar på svängens båge. */
    const v=s>0?sv:-sv, bz=s*K.benB/2;
    const bl=K.benH*(1-K.stovel), st=K.benH*K.stovel;
    const led=(niva,hojd)=>M4.mul(
      M4.translation(-Math.sin(v)*niva, hoftY-Math.cos(v)*niva, bz),M4.rotZ(-v));
    rita(D.kBen,led(bl/2),byxa);
    rita(D.kStovel,led(bl+st/2),stovel);

    /* Armen svänger motsatt det egna benet, med kortare utslag. */
    const a=(s>0?-sv:sv)*0.70, az=s*(K.balB/2+K.armB/2);
    const ar=K.armH*(1-K.hand), hd=K.armH*K.hand;
    const skuldra=(niva)=>M4.mul(
      M4.translation(-Math.sin(a)*niva, axelY-Math.cos(a)*niva, az),M4.rotZ(-a));
    rita(D.kArm,skuldra(ar/2),jacka,S3.tex.klossJacka);
    rita(D.kHand,skuldra(ar+hd/2),hud);
  }

  const huvY=axelY+K.huvH/2;
  rita(D.kHuvud,M4.translation(0,huvY,0),hud);
  rita(D.kAnsikte,M4.translation(0,huvY,0),hud,S3.tex.ansikte);
  rita(D.kHar,M4.translation(0,huvY,0),"#FFFFFF");
  if(o.hjalm!==false)rita(D.kHjalm,M4.translation(0,huvY,0),"#FFFFFF");

  /* En mjuk fläck under figuren i stället för tio projicerade skuggor. */
  if(typeof s3Skuggflack==="function")s3Skuggflack(o.x,o.z,0.42,0.85);
}

function v3dFigur(o){
  if(STIL==="kloss")return v3dFigurKloss(o);
  v3dBygFigur();
  const D=S3.del;
  const bas=M4.mul(M4.translation(o.x,0,o.z),M4.rotY(-o.rikt));
  const fas=o.fas||0, rr=o.rorlig===false?0:1;
  const g=Math.sin(fas*Math.PI*2)*rr, g2=Math.cos(fas*Math.PI*2)*rr;
  const gung=0.018*Math.abs(Math.sin(fas*Math.PI*2))*rr;
  const jacka=o.jacka||"#3E5F7A", BYXA="#3C4A63";
  const rita=(nat,mat,ton)=>{const m=M4.mul(bas,mat);
    GL.rita(nat,m,{ton}); GL.skugga(nat,m,0);};
  const H=1.02+gung;                       // midjans höjd
  /* Bålen och höften är byggda i figurens egna mått med fötterna i
     y=0, så de flyttas bara med gungningen och lutas kring höften. */
  const kropp=M4.mul(M4.mul(M4.translation(0,gung,0),
    M4.mul(M4.translation(0,0.86,0),M4.rotZ(0.045))),
    M4.translation(0,-0.86,0));
  rita(D.gHoft,kropp,"#FFFFFF");
  rita(D.gTorso,kropp,jacka);
  const hy=H+0.505;
  const huv=M4.mul(M4.translation(0.015,hy,0),M4.skala(1.12));
  rita(D.gHar,huv,"#FFFFFF");
  rita(D.gHuvud,huv,"#FFFFFF");
  if(o.hjalm!==false)rita(D.gHjalm,M4.mul(M4.translation(0.015,hy+0.108,0),M4.skala(1.12)),"#FFFFFF");
  for(const s of [-1,1]){
    const sv=s>0?g:-g, av=s>0?-g2:g2;
    /* Benen: höft → knä → fot. */
    const hoft=[0,H-0.17,s*0.082];
    const kna=[sv*0.17,0.49+gung*0.4,s*0.092];
    const fot=[sv*0.25,0.13,s*0.092];
    rita(D.gLar,s3Segment(hoft,kna,1),BYXA);
    rita(D.gKna,M4.translation(kna[0],kna[1],kna[2]),"#FFFFFF");
    rita(D.gVad,s3Segment(kna,fot,1),BYXA);
    rita(D.gKanga,M4.translation(fot[0],fot[1]-0.13,fot[2]),"#FFFFFF");
    /* Armarna hänger tätt intill kroppen och svänger mot benen. */
    const axel=[0,H+0.315,s*0.172];
    const bage=[av*0.08,H+0.085,s*0.180];
    const hand=[av*0.15+0.02,H-0.16,s*0.160];
    rita(D.gAxel,M4.translation(axel[0],axel[1],axel[2]),jacka);
    rita(D.gArmO,s3Segment(axel,bage,1),jacka);
    rita(D.gArmU,s3Segment(bage,hand,1),jacka);
    rita(D.gHand,M4.translation(hand[0],hand[1]-0.03,hand[2]),"#FFFFFF");
  }
}

/* ── Markör vid det närmaste du kan använda ───────────────────── */
function v3dRitaMarkor(){
  if(!VD.prompt)return;
  const p=VD.prompt.pos;
  const puls=0.55+0.25*Math.sin(VD.tid*3.2);
  if(!V3D.ring)V3D.ring={nat:GL.nat(new Bygge().cyl(0.62,0.62,0.03,"#D6AE3C",null,18))};
  GL.rita(V3D.ring.nat,M4.translation(p[0],0.05,p[1]),{alfa:puls,platt:true,ton:"#D6AE3C"});
}

/* ── Bildrutan ────────────────────────────────────────────────── */
let v3dSist=0;
function ritaVandring3D(){
  if(S3.trasig)return false;
  if(!S3.redo){
    if(S3.forsokt&&!S3.redo)return false;
    S3.forsokt=true;
    const c=document.getElementById("gl");
    if(!c||!GL.init(c)){S3.trasig=true;return false;}
    S3.canvas=c;
    try{ s3Texturer(); s3BygHast(); }
    catch(e){console.warn("3D-uppbyggnad misslyckades:",e);S3.trasig=true;return false;}
    S3.redo=true;
  }
  try{
    const nu=performance.now(), dt=v3dSist?Math.min((nu-v3dSist)/1000,0.1):0.016;
    v3dSist=nu;
    const vader=(G.vader&&G.vader.typ)||"sol";
    if(V3D.plats!==G.scen||V3D.nyckel!==vader){S3.plats=null;v3dBygg(G.scen);}
    const inne=G.scen!=="gard";
    const L=s3Ljus(inne?"ridhus":"ute");
    GL.start(CW,CH,DPR,L);
    const k=v3dKamera(dt);
    GL.kamera([k.x,k.y,k.z],[k.tx,k.ty,k.tz],1.05);
    const gl=GL.gl;
    GL.himmel(L);                                 // gradient och sol
    gl.depthMask(false);
    GL.rita(S3.himmel.nat,M4.translation(k.x-S3.himmelC[0],0,k.z-S3.himmelC[1]),
      {platt:true,baksidor:true});                // molnen
    gl.depthMask(true);
    for(const s of S3.statiskt)GL.rita(s.nat,M4.ny(),{tex:s.tex,baksidor:s.baksidor,platt:s.platt});
    if(V3D.oppningar)GL.rita(V3D.oppningar.nat,M4.ny(),{baksidor:true});
    /* Levande figurer och hästar. */
    if(G.scen==="gard"){
      for(const hg of ANL.hagar)for(let i=0;i<hg.hastar.length;i++){
        const id=hg.hastar[i];
        if(id===G.hastId&&!G.hamtad)continue;
        const h=HORSES[id]; if(!h)continue;
        const r=hg.rekt;
        const hx=r.x+4+((i*7)%Math.max(1,r.w-8)), hz=r.y+4+((i*11)%Math.max(1,r.h-8));
        const beta=Math.sin(VD.tid*0.22+i*2.1)>-0.25;   // betar mest, tittar upp ibland
        s3RitaHast({hast:h,x:hx,z:hz,rikt:1.2+i*0.9,gangart:"halt",
          fas:(VD.tid*0.2+i)%1, samling:-0.3, beta, skugga:true,
          tacke:!!(G.vader&&G.vader.tacke)});
      }
      if(G.hastId&&!G.hamtad&&!G.leder){
        const f=ANL.hamtHage.falt, h=HORSES[G.hastId];
        s3RitaHast({hast:h,x:f[0],z:f[1],rikt:Math.PI,gangart:"halt",fas:0,
          samling:-0.3,beta:true,skugga:true,tacke:!!(G.vader&&G.vader.tacke)});
      }
      for(const p of gardsFolk())
        v3dFigur({x:p.x,z:p.y,rikt:p.rikt===undefined?2.1:p.rikt,
          fas:(VD.tid*0.5+p.x*0.3)%1,jacka:p.farg,hjalm:false});
    }else if(G.scen==="stallinne"){
      const S=STALLINNE, vx=S.bredd/2;
      for(const sida of["W","E"]){                 // hästhuvuden över boxdörrarna
        const rad=S.boxar[sida], fx=sida==="W"?vx-S.ganghalva:vx+S.ganghalva;
        for(let i=0;i<rad.length;i++){
          const y0=S.boxStartY+i*S.boxB, y1=y0+S.boxB;
          if(y1>S.klubbY)break;
          const h=boxHast(rad[i]); if(!h)continue;
          const my=(y0+y1)/2, ut=sida==="W"?-1:1;
          const nick=Math.sin(VD.tid*0.9+i*1.7+(sida==="E"?2:0))*0.06;
          const m=M4.mul(M4.mul(M4.translation(fx+ut*0.22,1.62+nick*0.4,my),
            M4.rotY(ut>0?-Math.PI/2:Math.PI/2)),M4.rotZ(-0.55));
          GL.rita(S3.del.huvud,m,{ton:h.farg});
          for(const s of [-1,1])
            GL.rita(S3.del.ora,M4.mul(M4.mul(m,M4.translation(-0.12,0.10,s*0.08)),
              M4.rotZ(0.2)),{ton:h.man});
          /* Rosetten på boxdörren. */
          const ro=(typeof hastRosett==="function")&&hastRosett(rad[i]);
          if(ro){
            GL.rita(S3.del.krona,M4.mul(M4.translation(fx+ut*0.16,1.30,my+0.9),
              M4.skala(0.10)),{ton:ro.farg});
            if(ro.farg2)GL.rita(S3.del.krona,M4.mul(M4.translation(fx+ut*0.19,1.30,my+0.9),
              M4.skala(0.055)),{ton:ro.farg2});
          }
        }
      }
      if(!G.hastId)
        v3dFigur({x:S.ridlarare.pos[0],z:S.ridlarare.pos[1],rikt:Math.PI,
          fas:0,rorlig:false,jacka:"#2E4638",hjalm:false});
      for(const f of stallFolk()){
        const fy=S.boxStartY+f.ix*S.boxB+S.boxB/2;
        if(fy>S.klubbY-1)continue;
        const fx2=f.sida==="W"?vx-S.ganghalva+0.6:vx+S.ganghalva-0.6;
        v3dFigur({x:fx2,z:fy,rikt:f.sida==="W"?-Math.PI/2:Math.PI/2,
          fas:(VD.tid*0.4+f.ix)%1,rorlig:false,jacka:f.farg,hjalm:false});
      }
    }
    /* Hästen du leder. */
    if(G.leder&&G.hastId)
      s3RitaHast({hast:HORSES[G.hastId], x:VD.hastX, z:VD.hastY, rikt:VD.hastRikt,
        gangart:"skritt", fas:VD.fas, samling:-0.1, skugga:true,
        sadel:!!G.skotselRes, tacke:!!G.tackePa});
    v3dRitaMarkor();
    v3dRitaSpelare();
    GL.efter();          // glöd och mättnad
    if(G.scen==="gard"&&G.vader&&G.vader.typ==="regn"){
      cx.clearRect(0,0,CW,CH); ritaRegn();
    }else cx.clearRect(0,0,CW,CH);
    return true;
  }catch(e){
    console.warn("3D-vandring misslyckades:",e);
    S3.trasig=true;
    return false;
  }
}

/* Vyväxlaren för gå-läget: 3D när kortet räcker, annars målarvyn. */
function ritaVandringVy(){
  if(G.vy!=="2d"&&ritaVandring3D()){gl3dLage(true);return;}
  gl3dLage(false);
  if(G.scen==="gard"){ if(G.vy==="2d")ritaGard2D(); else ritaGard3D(); }
  else if(G.scen==="ridhusinne"){ if(G.vy==="2d")ritaRidhus2D(); else ritaRidhus3D(); }
  else { if(G.vy==="2d")ritaStall2D(); else ritaStall3D(); }
}
