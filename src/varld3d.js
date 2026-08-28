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
  T.korr=glCanvasTex(128,128,(c,w,h)=>{           // korrugerad plåt, otonad
    c.fillStyle="#FFFFFF";c.fillRect(0,0,w,h);
    for(let i=0;i<16;i++){
      c.fillStyle=i%2?"rgba(255,255,255,.6)":"rgba(0,0,0,.20)";
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

/* En triangel (gavelspetsar) — Bygge har bara slutna kroppar. */
function v3dTriangel(b,p0,p1,p2,farg){
  const ux=p1[0]-p0[0], uy=p1[1]-p0[1], uz=p1[2]-p0[2];
  const vx=p2[0]-p0[0], vy=p2[1]-p0[1], vz=p2[2]-p0[2];
  let nx=uy*vz-uz*vy, ny=uz*vx-ux*vz, nz=ux*vy-uy*vx;
  const l=Math.hypot(nx,ny,nz)||1; nx/=l;ny/=l;nz/=l;
  b.las([...p0,...p1,...p2],[nx,ny,nz,nx,ny,nz,nx,ny,nz],
    [0,0,1,0,0.5,1],[0,1,2],farg,null);
  b.las([...p0,...p2,...p1],[-nx,-ny,-nz,-nx,-ny,-nz,-nx,-ny,-nz],
    [0,0,0.5,1,1,0],[0,1,2],farg,null);
}
/* Matris för en panel längs en fasad: +X längs väggen, +Z utåt. */
function v3dFasadMat(p0,ux,uy,u,z,ut){
  const nx=uy, nz=-ux;                       // utåtriktad normal
  return new Float32Array([
    ux,0,uy,0,  0,1,0,0,  nx*1,0,nz*1,0,
    p0[0]+ux*u+nx*ut, z, p0[1]+uy*u+nz*ut, 1]);
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
  /* Byggnaderna: väggar, sadeltak, gavelspetsar. */
  const husV=new Bygge(), husT=new Bygge(), husP=new Bygge();
  for(const bg of ANL.byggnader){
    const r=bg.rekt, hV=bg.hV, hN=bg.hN;
    const vt=bg.plat?husP:husV;
    vt.lada(r.w,hV,r.h,bg.fargV,M4.translation(r.x+r.w/2,hV/2,r.y+r.h/2));
    const cx=r.x+r.w/2, cz=r.y+r.h/2;
    if(bg.nock==="NS"){                       // nocken längs y
      const halv=r.w/2, res=hN-hV, len=Math.hypot(halv,res), vin=Math.atan2(res,halv);
      for(const s of [-1,1])
        husT.lada(len,0.14,r.h+0.5,bg.fargT,
          M4.mul(M4.translation(cx+s*halv/2,hV+res/2,cz),M4.rotZ(s*vin)));
      for(const s of [-1,1]){                 // gavelspetsarna i söder och norr
        const z=s<0?r.y:r.y+r.h;
        v3dTriangel(vt,[r.x,hV,z],[r.x+r.w,hV,z],[cx,hN,z],glMorka(bg.fargV,0.88));
      }
    }else{                                    // nocken längs x
      const halv=r.h/2, res=hN-hV, len=Math.hypot(halv,res), vin=Math.atan2(res,halv);
      for(const s of [-1,1])
        husT.lada(r.w+0.5,0.14,len,bg.fargT,
          M4.mul(M4.translation(cx,hV+res/2,cz+s*halv/2),M4.rotX(-s*vin)));
      for(const s of [-1,1]){
        const x=s<0?r.x:r.x+r.w;
        v3dTriangel(vt,[x,hV,r.y],[x,hV,r.y+r.h],[x,hN,cz],glMorka(bg.fargV,0.88));
      }
    }
    /* Vita knutar på trähusen. */
    if(!bg.plat)for(const[dx,dz]of[[0,0],[r.w,0],[0,r.h],[r.w,r.h]])
      husV.lada(0.34,hV,0.34,"#EFE8D8",M4.translation(r.x+dx,hV/2,r.y+dz));
    /* Ventilationshuvar på stallet. */
    if(bg.huvar)for(let z=r.y+6;z<r.y+r.h-4;z+=8){
      husT.lada(0.9,0.5,0.9,"#3A3E44",M4.translation(cx,hN+0.25,z));
      husT.cyl(0.20,0.20,0.5,"#2E3238",M4.translation(cx,hN+0.5,z),8);
    }
    /* Fasadöppningar. */
    const FARG={dorr:"#33291F", dorrgul:"#D9A13E", dorrvit:"#E8E2D4",
      dorrgra:"#A2A4A6", dorrmork:"#463F38", portplat:"#B4B7B9",
      portsilver:"#C4C7C9", fonster:"#3A4A5C", valv:"#3A4A5C", rund:"#3A4A5C"};
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
      const mat=v3dFasadMat(P[0],ux,uy,o.u+o.b/2,o.z0+o.h/2,0.09);
      opp.panel(o.b,o.h,FARG[o.typ]||"#33291F",mat);
      if(o.typ==="fonster"||o.typ==="valv"||o.typ==="rund")   // vit foderlist
        opp.panel(o.b+0.22,o.h+0.22,"#EFE8D8",
          v3dFasadMat(P[0],ux,uy,o.u+o.b/2,o.z0+o.h/2,0.06));
      if(o.typ==="dorrgul"||o.typ==="dorrvit")
        opp.panel(o.b+0.26,o.h+0.16,"#EFE8D8",
          v3dFasadMat(P[0],ux,uy,o.u+o.b/2,o.z0+o.h/2,0.06));
    }
  }
  lagg(husV,T.falu); lagg(husP,T.ridhusplat); lagg(husT,T.takplat);

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
        stak.lada(len,0.12,0.06,"#8A3129",M4.mul(mitt,M4.translation(0,0.75,0)));
        const n=Math.max(1,Math.round(len/3));
        for(let k=0;k<=n;k++)
          stak.lada(0.12,0.86,0.12,"#7A2B24",
            M4.mul(mitt,M4.translation(-len/2+len*k/n,0.43,0)));
      }
    }
  }
  lagg(stak,null);

  /* Träden. */
  const skog=new Bygge();
  for(let i=0;i<ANL.trad.length;i++){
    const[tx,tz,tr]=ANL.trad[i];
    const f=TRADFARG[i%TRADFARG.length], h=tr*2.2+2.5;
    if(STIL==="kloss"){ klossTrad(skog,tx,tz,h,f[0],glMorka(f[0],0.88)); continue; }
    skog.cyl(tr*0.16,tr*0.11,h*0.45,"#5E4A34",M4.translation(tx,0,tz),7);
    skog.klot(1,f[0],M4.mul(M4.translation(tx,h*0.66,tz),
      M4.skala(tr*0.95,tr*1.05,tr*0.95)),10);
    skog.klot(1,f[1],M4.mul(M4.translation(tx+tr*0.3,h*0.86,tz-tr*0.2),
      M4.skala(tr*0.6,tr*0.62,tr*0.6)),9);
  }
  lagg(skog,null);

  /* Rekvisitan. */
  const pr=new Bygge();
  for(const p of ANL.props){
    const[x,z]=p.pos;
    switch(p.typ){
      case"silo":
        if(STIL==="kloss"){
          pr.lada(2.7,7.5,2.7,"#C4C7C9",M4.translation(x,3.75,z));
          pr.lada(2.9,0.55,2.9,"#A2A4A6",M4.translation(x,7.80,z));
          pr.lada(1.9,0.90,1.9,"#A2A4A6",M4.translation(x,8.45,z));   // toppen i två steg
          pr.lada(1.6,1.20,1.6,"#8A8C90",M4.translation(x,0.60,z-1.9));
          break;
        }
        pr.cyl(1.5,1.5,7.5,"#C4C7C9",M4.translation(x,0,z),14);
        pr.cyl(1.55,0.2,1.8,"#A2A4A6",M4.translation(x,7.5,z),14);
        pr.cyl(0.9,0.9,1.2,"#8A8C90",M4.translation(x,-0.0,z-1.8),10);
        break;
      case"balar":
        for(let i=0;i<3;i++)for(let j=0;j<2;j++){
          const m=M4.translation(x+i*1.4,0.65,z+j*1.5);
          if(STIL==="kloss"){ pr.lada(1.3,1.3,1.2,"#E4E2DA",m); continue; }
          pr.cyl(0.65,0.65,1.2,"#E4E2DA",M4.mul(m,M4.rotZ(Math.PI/2)),10);
        }
        break;
      case"grushog":
        if(STIL==="kloss"){
          pr.lada(3.4,0.70,3.4,"#BCA179",M4.translation(x,0.35,z));
          pr.lada(2.0,0.60,2.0,"#BCA179",M4.translation(x,0.95,z));
          break;
        }
        pr.cyl(1.8,0.1,1.3,"#BCA179",M4.translation(x,0,z),12); break;
      case"transport":
        pr.lada(2.2,1.9,5.4,"#E8E6E0",M4.mul(M4.translation(x,1.25,z),M4.rotY(-(p.rikt||0))));
        pr.lada(2.0,0.5,2.0,"#4A4E52",M4.mul(M4.translation(x,0.3,z),M4.rotY(-(p.rikt||0))));
        break;
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
      case"trappa":
        for(let i=0;i<7;i++)
          pr.lada(2.6,0.18,0.32,"#B4B7B9",M4.translation(x,0.18*i+0.09,z+0.32*i));
        pr.lada(0.08,1.1,2.3,"#8A8C90",M4.translation(x-1.25,1.2,z+1.1));
        pr.lada(0.08,1.1,2.3,"#8A8C90",M4.translation(x+1.25,1.2,z+1.1));
        break;
      case"veranda":
        pr.lada(5.2,0.18,2.4,"#7E8288",M4.translation(x,2.55,z));
        for(const dx of [-2.3,2.3])
          pr.lada(0.16,2.5,0.16,"#EFE8D8",M4.translation(x+dx,1.25,z-1.0));
        pr.lada(5.2,0.10,0.10,"#EFE8D8",M4.translation(x,2.42,z-1.05));
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
  lagg(pr,null);
}

/* ── Stallet invändigt ────────────────────────────────────────── */
function v3dStall(lagg,opp){
  const S=STALLINNE, T=S3.tex, vx=S.bredd/2;
  /* Golvet: marksten i gången, spån i boxarna. */
  lagg(new Bygge().yta(S.ganghalva*2,S.langd,"#FFFFFF",
    M4.translation(vx,0.02,S.langd/2),10),T.marksten);
  const span=new Bygge();
  for(const sida of["W","E"]){
    const rad=S.boxar[sida];
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB;
      if(y0+S.boxB>S.serviceY)break;
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
  const tak=new Bygge();
  tak.lada(S.bredd+0.6,0.16,S.langd+0.4,"#B8BCC0",M4.translation(vx,S.tak,S.langd/2));
  for(let z=2;z<S.langd;z+=4)                       // limträbalkar
    tak.lada(S.bredd,0.22,0.20,"#7A5C3E",M4.translation(vx,S.tak-0.22,z));
  for(let z=6;z<S.langd;z+=9)                       // taklanterniner
    tak.lada(1.6,0.10,1.2,"#F6F2E4",M4.translation(vx,S.tak-0.10,z));
  lagg(tak,null);

  /* Boxfronterna: komposit, galvad ram, galler och namnskylt. */
  const front=new Bygge(), galler=new Bygge();
  for(const sida of["W","E"]){
    const rad=S.boxar[sida], fx=sida==="W"?vx-S.ganghalva:vx+S.ganghalva;
    for(let i=0;i<rad.length;i++){
      const y0=S.boxStartY+i*S.boxB, y1=y0+S.boxB;
      if(y1>S.serviceY)break;
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
  lagg(new Bygge().yta(ba.w,ba.h,"#FFFFFF",
    M4.translation(ba.x+ba.w/2,0.03,ba.y+ba.h/2),7),T.sand);
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
  bit(ba.x,ba.y,R.port.x0,ba.y); bit(R.port.x1,ba.y,ba.x+ba.w,ba.y);
  bit(ba.x,ba.y+ba.h,ba.x+ba.w,ba.y+ba.h);
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
  for(const s of [-1,1])
    hall.lada(takL,0.18,R.langd+0.6,"#3A3E44",
      M4.mul(M4.translation(R.bredd/2+s*halvS/2,R.tak+resn/2,R.langd/2),M4.rotZ(s*takV)));
  for(let z=1;z<R.langd;z+=6){
    hall.lada(R.bredd,0.26,0.24,"#7A5C3E",M4.translation(R.bredd/2,R.tak-0.2,z));
    hall.lada(0.22,2.7,0.22,"#7A5C3E",M4.translation(R.bredd/2,R.tak+1.3,z));
  }
  for(let z=4;z<R.langd;z+=7)
    for(const x of [R.bredd*0.3,R.bredd*0.7])
      hall.lada(1.3,0.10,0.26,"#F6F2E4",M4.translation(x,R.tak-0.35,z));
  lagg(hall,null);
  /* Läktaren, domarbåset, cafeterian och trappan. */
  const lak=new Bygge(), L=R.laktare;
  for(let i=0;i<L.steg;i++){
    lak.lada(L.stegD,L.stegH,L.y1-L.y0,"#FFFFFF",
      M4.translation(L.x0+i*L.stegD+L.stegD/2,L.stegH/2+i*L.stegH,(L.y0+L.y1)/2));
    lak.lada(L.stegD,0.08,L.y1-L.y0,"#F0EAE0",
      M4.translation(L.x0+i*L.stegD+L.stegD/2,L.stegH*(i+1),(L.y0+L.y1)/2));
  }
  lak.lada(1.9,2.2,1.9,"#FFFFFF",M4.translation(R.domarbas.x,1.1,R.domarbas.y));
  lak.lada(2.1,0.14,2.1,"#C8BCA8",M4.translation(R.domarbas.x,2.25,R.domarbas.y));
  for(let i=0;i<8;i++)                                  // trappan upp till caféet
    lak.lada(1.2,0.19,0.30,"#FFFFFF",
      M4.translation(R.trappa.x,0.19*i+0.10,R.trappa.y+0.30*i));
  lagg(lak,T.tra);
  const cafe=new Bygge();
  cafe.lada(R.bredd,0.26,R.cafe.djup,"#CFC8BC",
    M4.translation(R.bredd/2,R.cafe.z0,R.cafe.djup/2));
  cafe.lada(R.bredd,R.cafe.z1-R.cafe.z0-0.26,0.16,"#E9E5DC",
    M4.translation(R.bredd/2,(R.cafe.z0+R.cafe.z1)/2,R.cafe.djup));
  for(let x=2;x<R.bredd-1;x+=3.2)                       // fönsterbandet
    cafe.panel(2.4,1.1,"#3A4A5C",M4.translation(x,R.cafe.z0+1.3,R.cafe.djup+0.10));
  lagg(cafe,null);
  /* Sponsorväggen med speglar och banderoller. */
  const panel=new Bygge();
  for(const sp of R.speglar)
    panel.lada(0.10,1.9,sp.b,"#7E858C",M4.translation(ba.x-0.22,2.2,sp.y));
  panel.lada(0.12,0.9,R.langd*0.8,"#6B4A34",M4.translation(ba.x-0.24,3.7,R.langd/2));
  lagg(panel,null);
  for(const s of R.skyltar){
    const b=new Bygge();
    v3dTextPanel(b,s.b,s.b*0.25,
      M4.mul(M4.translation(ba.x-0.30,2.6,s.y),M4.rotY(Math.PI/2)));
    S3.statiskt.push({nat:GL.nat(b), tex:(S3.tex.skyltar||[])[R.skyltar.indexOf(s)]
      ||v3dEtikettTex(s.text)});
  }
  /* Dressyrbokstäverna på sargen. */
  for(const bo of DRESSYRBOKSTAVER){
    const bx=ba.x+bo.x, bz=ba.y+bo.y;
    let mat;
    if(bo.x===0)      mat=M4.mul(M4.translation(bx+0.12,0.95,bz),M4.rotY(Math.PI/2));
    else if(bo.x===20)mat=M4.mul(M4.translation(bx-0.12,0.95,bz),M4.rotY(-Math.PI/2));
    else if(bo.y===0) mat=M4.mul(M4.translation(bx,0.95,bz+0.12),M4.ny());
    else              mat=M4.mul(M4.translation(bx,0.95,bz-0.12),M4.rotY(Math.PI));
    const b=new Bygge(); v3dTextPanel(b,0.5,0.5,mat);
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
    for(const s of S3.statiskt)GL.rita(s.nat,M4.ny(),{tex:s.tex,baksidor:s.baksidor});
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
          if(y1>S.serviceY)break;
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
        if(fy>S.serviceY-1)continue;
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
