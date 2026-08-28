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
        pr.cyl(1.5,1.5,7.5,"#C4C7C9",M4.translation(x,0,z),14);
        pr.cyl(1.55,0.2,1.8,"#A2A4A6",M4.translation(x,7.5,z),14);
        pr.cyl(0.9,0.9,1.2,"#8A8C90",M4.translation(x,-0.0,z-1.8),10);
        break;
      case"balar":
        for(let i=0;i<3;i++)for(let j=0;j<2;j++)
          pr.cyl(0.65,0.65,1.2,"#E4E2DA",
            M4.mul(M4.translation(x+i*1.4,0.65,z+j*1.5),M4.rotZ(Math.PI/2)),10);
        break;
      case"grushog": pr.cyl(1.8,0.1,1.3,"#BCA179",M4.translation(x,0,z),12); break;
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
function v3dBygFigur(){
  if(S3.del.gTorso)return;
  const D=S3.del, JEANS="#3C4A63", HUD="#E0B892";
  /* Bålen är en enda avsmalnande form, inte staplade klot: midjan
     smal, bröstkorgen bred, axlarna rundade. Jackan bakas vit så att
     varje figur kan få sin egen färg via ton. */
  D.gTorso=GL.nat((()=>{
    const b=new Bygge(), V="#FFFFFF";
    b.cyl(0.120,0.162,0.36,V,M4.mul(M4.translation(0,0.02,0),
      M4.skala(1,1,0.78)),18);                                     // midja → bröst
    b.klot(1,V,M4.mul(M4.translation(0,0.35,0),M4.skala(0.168,0.092,0.112)),16);
    b.klot(1,V,M4.mul(M4.translation(-0.02,0.375,0),
      M4.skala(0.105,0.070,0.098)),12);                            // kragen
    return b;})());
  /* Höften och skärpet behåller sin egen färg. */
  D.gHoft=GL.nat((()=>{
    const b=new Bygge();
    b.lada(0.29,0.048,0.220,"#2A2620",M4.translation(0,0.005,0));  // skärp
    b.cyl(0.150,0.126,0.21,JEANS,M4.mul(M4.translation(0,-0.20,0),
      M4.skala(1,1,0.80)),16);
    b.cyl(0.050,0.050,0.11,HUD,M4.translation(0,0.39,0),10);       // hals
    return b;})());
  D.gAxel=GL.nat(new Bygge().klot(0.046,"#FFFFFF",null,11));
  D.gArmO=GL.nat(new Bygge().cyl(0.049,0.042,1,"#FFFFFF",null,14));
  D.gArmU=GL.nat(new Bygge().cyl(0.042,0.036,1,"#FFFFFF",null,14));
  D.gLedA=GL.nat(new Bygge().klot(0.038,"#FFFFFF",null,10));
  D.gHand=GL.nat(new Bygge().klot(1,HUD,M4.skala(0.044,0.052,0.036),10));
  D.gLar=GL.nat(new Bygge().cyl(0.080,0.062,1,JEANS,null,14));
  D.gVad=GL.nat(new Bygge().cyl(0.058,0.046,1,JEANS,null,14));
  D.gKna=GL.nat(new Bygge().klot(0.046,JEANS,null,10));
  D.gKanga=GL.nat((()=>{
    const b=new Bygge();
    b.klot(1,"#2B211A",M4.mul(M4.translation(0.025,0.05,0),M4.skala(0.118,0.058,0.060)),11);
    b.lada(0.215,0.035,0.108,"#181310",M4.translation(0.025,0.020,0));
    return b;})());
  D.gHuvud=GL.nat((()=>{
    const b=new Bygge();
    b.klot(1,HUD,M4.skala(0.093,0.108,0.088),14);
    b.klot(1,HUD,M4.mul(M4.translation(0.055,-0.042,0),
      M4.skala(0.042,0.050,0.056)),10);                            // hakan
    for(const s of [-1,1]){                                        // ögonen
      b.klot(1,"#FFFFFF",M4.mul(M4.translation(0.060,0.004,s*0.033),
        M4.skala(0.015,0.019,0.016)),7);
      b.klot(1,"#2B2118",M4.mul(M4.translation(0.070,0.002,s*0.034),
        M4.skala(0.010,0.013,0.011)),7);
    }
    b.klot(1,"#B9755E",M4.mul(M4.translation(0.080,-0.052,0),
      M4.skala(0.010,0.008,0.024)),6);                             // munnen
    return b;})());
  /* Håret: nacklugg och hästsvans — samma siluett som i ridscenen. */
  D.gHar=GL.nat((()=>{
    const b=new Bygge(), H="#5E4028";
    b.klot(1,H,M4.mul(M4.translation(-0.048,0.012,0),M4.skala(0.088,0.100,0.094)),12);
    for(let i=0;i<6;i++){
      const t=i/5;
      b.klot(1,H,M4.mul(M4.translation(-0.088-0.030*t*t,-0.070-0.105*t,0),
        M4.skala(0.052,0.066,0.058)),9);
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
function v3dFigur(o){
  v3dBygFigur();
  const D=S3.del;
  const bas=M4.mul(M4.translation(o.x,0,o.z),M4.rotY(-o.rikt));
  const fas=o.fas||0, rr=o.rorlig===false?0:1;
  const g=Math.sin(fas*Math.PI*2)*rr, g2=Math.cos(fas*Math.PI*2)*rr;
  const gung=0.018*Math.abs(Math.sin(fas*Math.PI*2))*rr;
  const jacka=o.jacka||"#3E5F7A";
  const rita=(nat,mat,ton)=>{const m=M4.mul(bas,mat);
    GL.rita(nat,m,{ton}); GL.skugga(nat,m,0);};
  const H=1.02+gung;                       // midjans höjd
  const kropp=M4.mul(M4.translation(0,H,0),M4.rotZ(0.045));
  rita(D.gHoft,kropp,"#FFFFFF");
  rita(D.gTorso,kropp,jacka);
  const hy=H+0.53;
  const huv=M4.translation(0.015,hy,0);
  rita(D.gHar,huv,"#FFFFFF");
  rita(D.gHuvud,huv,"#FFFFFF");
  if(o.hjalm!==false)rita(D.gHjalm,M4.translation(0.015,hy+0.098,0),"#FFFFFF");
  for(const s of [-1,1]){
    const sv=s>0?g:-g, av=s>0?-g2:g2;
    /* Benen: höft → knä → fot. */
    const hoft=[0,H-0.17,s*0.082];
    const kna=[sv*0.17,0.49+gung*0.4,s*0.092];
    const fot=[sv*0.25,0.13,s*0.092];
    rita(D.gLar,s3Segment(hoft,kna,1),"#FFFFFF");
    rita(D.gVad,s3Segment(kna,fot,1),"#FFFFFF");
    rita(D.gKanga,M4.translation(fot[0],fot[1]-0.07,fot[2]),"#FFFFFF");
    /* Armarna hänger tätt intill kroppen och svänger mot benen. */
    const axel=[0,H+0.325,s*0.150];
    const bage=[av*0.08,H+0.09,s*0.162];
    const hand=[av*0.15+0.02,H-0.15,s*0.146];
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
    gl.depthMask(false);
    GL.rita(S3.himmel.nat,M4.translation(k.x-S3.himmelC[0],0,k.z-S3.himmelC[1]),
      {platt:true,baksidor:true});
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
