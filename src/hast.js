/* ══════════════════════════════════════════════════════════════════
   HÄSTEN — parametrisk sidoprofil med riktig anatomi: manke, kors,
   bog, has, fyra ben med kotor och hovar, hals med nacke, huvud med
   mule, ganascher, öron och öga. En funktion, många användningar:
   hagarna, hästen du leder, skötselvyn. Måttenhet: mankhöjden u.
   Poser: "sta" (stilla), "ga" (skritt, fas 0–1), "beta" (betar).
   ══════════════════════════════════════════════════════════════════ */
"use strict";

function hastMorkare(hex,f){
  const n=parseInt(hex.slice(1),16);
  const r=Math.min(255,(n>>16)*f)|0,g=Math.min(255,((n>>8)&255)*f)|0,b=Math.min(255,(n&255)*f)|0;
  return `rgb(${r},${g},${b})`;
}

/* c: 2d-kontext. (x0,y0): markpunkt under kroppens mitt. u: mankhöjd
   i pixlar. dir: +1 huvud åt höger, −1 åt vänster. o: {fas, pose,
   sadel, grimma, skugga}. */
function ritaHastSida(c,x0,y0,u,dir,farg,man,o){
  o=o||{};
  const fas=o.fas||0, pose=o.pose||"sta", beta=pose==="beta";
  const P=(x,y)=>[x0+dir*x*u, y0+y*u];
  const M=p=>c.moveTo(p[0],p[1]);
  const B=(p1,p2,p3)=>c.bezierCurveTo(p1[0],p1[1],p2[0],p2[1],p3[0],p3[1]);
  const gunga=pose==="ga"?Math.sin(fas*Math.PI*4)*0.012:0;
  const K=(x,y)=>P(x,y-gunga); // kroppspunkter gungar lätt i skritt

  if(o.skugga!==false){
    c.fillStyle="rgba(30,25,15,.28)";
    c.beginPath();
    c.ellipse(x0-dir*0.06*u, y0+0.02*u, 0.72*u, 0.09*u, 0, 0, Math.PI*2);
    c.fill();
  }

  /* Ben: två segment med led, kota och hov. sving i skritt. */
  const ben=(bx,bakben,nara,svFas)=>{
    const sv=pose==="ga"?Math.sin(fas*Math.PI*2+svFas)*0.07:0;
    const lyft=pose==="ga"?Math.max(0,Math.sin(fas*Math.PI*2+svFas))*0.05:0;
    const f2=nara?farg:hastMorkare(farg,0.68);
    const kx=bx+sv*0.5, fx=bx+sv;           // knä och hov driver med
    c.fillStyle=f2;
    c.beginPath();
    M(K(bx-0.055,-0.62)); B(K(bx-0.05,-0.45),P(kx-0.035,-0.34),P(kx-0.03,-0.28));
    B(P(fx-0.025,-0.16),P(fx-0.022,-0.10),P(fx-0.024,-0.05+lyft));
    c.lineTo(...P(fx+0.024,-0.05+lyft));
    B(P(fx+0.022,-0.10),P(fx+0.028,-0.16),P(kx+0.035,-0.28));
    B(P(kx+0.045,-0.34),K(bx+0.06,-0.45),K(bx+0.065,-0.62));
    c.closePath(); c.fill();
    // hov
    c.fillStyle="#2E241C";
    c.beginPath();
    M(P(fx-0.035,-0.05+lyft)); c.lineTo(...P(fx+0.035,-0.05+lyft));
    c.lineTo(...P(fx+0.042,0.0+lyft)); c.lineTo(...P(fx-0.042,0.0+lyft));
    c.closePath(); c.fill();
  };
  // bortre benpar först (mörkare)
  ben(0.20,false,false,Math.PI); ben(-0.55,true,false,0);
  // svans
  c.fillStyle=man;
  c.beginPath();
  M(K(-0.68,-0.93));
  B(K(-0.84,-0.85),P(-0.92,-0.60),P(-0.88,-0.34));
  B(P(-0.86,-0.28),P(-0.82,-0.30),P(-0.80,-0.38));
  B(P(-0.80,-0.55),K(-0.72,-0.75),K(-0.62,-0.88));
  c.closePath(); c.fill();
  // bakdelens lår (bortre sidan syns bakom kroppen)
  c.fillStyle=hastMorkare(farg,0.82);
  c.beginPath(); c.ellipse(...K(-0.48,-0.62),0.17*u,0.22*u,-0.15*dir,0,Math.PI*2); c.fill();

  /* Kroppen */
  c.fillStyle=farg;
  c.beginPath();
  M(K(-0.05,-1.00));                                    // manken
  B(K(0.15,-1.01),K(0.32,-0.94),K(0.40,-0.80));         // bog
  B(K(0.46,-0.66),K(0.45,-0.56),K(0.40,-0.50));         // bröst
  B(K(0.28,-0.42),K(0.10,-0.40),K(-0.02,-0.42));        // buklinje fram
  B(K(-0.20,-0.44),K(-0.38,-0.44),K(-0.50,-0.50));      // buk → flank
  B(K(-0.64,-0.56),K(-0.70,-0.68),K(-0.72,-0.78));      // has upp
  B(K(-0.74,-0.90),K(-0.66,-0.99),K(-0.52,-1.00));      // korset
  B(K(-0.34,-1.01),K(-0.20,-0.96),K(-0.05,-1.00));      // ryggens svank
  c.closePath(); c.fill();

  // närmaste benpar
  ben(0.30,false,true,0); ben(-0.42,true,true,Math.PI);
  // närmaste lår över benfästet
  c.fillStyle=farg;
  c.beginPath(); c.ellipse(...K(-0.44,-0.66),0.155*u,0.21*u,-0.12*dir,0,Math.PI*2); c.fill();

  /* Hals och huvud — två poser */
  const H = beta
    ? {crest1:[0.30,-0.95],crest2:[0.48,-0.72],nacke:[0.56,-0.52],
       panna:[0.66,-0.42],nosrygg:[0.76,-0.24],mule:[0.80,-0.12],
       mun:[0.76,-0.07],kake:[0.66,-0.20],strupe:[0.52,-0.42],
       hals1:[0.40,-0.62],hals2:[0.30,-0.72],
       ora:[0.55,-0.56],oga:[0.66,-0.35],nos:[0.785,-0.15]}
    : {crest1:[0.32,-1.12],crest2:[0.50,-1.30],nacke:[0.58,-1.38],
       panna:[0.70,-1.38],nosrygg:[0.82,-1.20],mule:[0.87,-1.08],
       mun:[0.83,-1.02],kake:[0.70,-1.06],strupe:[0.52,-1.10],
       hals1:[0.42,-0.90],hals2:[0.30,-0.76],
       ora:[0.585,-1.40],oga:[0.685,-1.30],nos:[0.845,-1.10]};
  c.fillStyle=farg;
  c.beginPath();
  M(K(0.10,-0.99));
  B(K(H.crest1[0],H.crest1[1]),K(H.crest2[0],H.crest2[1]),K(H.nacke[0],H.nacke[1]));
  B(K(H.panna[0],H.panna[1]),K(H.nosrygg[0],H.nosrygg[1]),K(H.mule[0],H.mule[1]));
  B(K(H.mule[0]+0.005,H.mule[1]+0.045),K(H.mun[0],H.mun[1]+0.02),K(H.mun[0]-0.02,H.mun[1]));
  B(K(H.kake[0],H.kake[1]),K(H.strupe[0],H.strupe[1]),K(H.hals1[0],H.hals1[1]));
  B(K(H.hals2[0],H.hals2[1]),K(0.22,-0.68),K(0.18,-0.62));
  B(K(0.14,-0.72),K(0.10,-0.86),K(0.10,-0.99));
  c.closePath(); c.fill();
  // ganasch (rund kind)
  c.beginPath(); c.ellipse(...K(H.kake[0]-0.035,H.kake[1]-0.055),0.075*u,0.085*u,0,0,Math.PI*2); c.fill();
  // öron
  const ora=(off)=>{
    c.beginPath();
    M(K(H.ora[0]+off,H.ora[1]));
    c.lineTo(...K(H.ora[0]+off+0.035,H.ora[1]-0.13));
    c.lineTo(...K(H.ora[0]+off+0.075,H.ora[1]+0.005));
    c.closePath(); c.fill();
  };
  c.fillStyle=hastMorkare(farg,0.85); ora(-0.055);
  c.fillStyle=farg; ora(0.0);
  // öga, mule, näsborre, mungipa
  c.fillStyle="#1A140F";
  c.beginPath(); c.ellipse(...K(H.oga[0],H.oga[1]),0.022*u,0.027*u,0,0,Math.PI*2); c.fill();
  c.fillStyle=hastMorkare(farg,0.72);
  c.beginPath(); c.ellipse(...K(H.mule[0]-0.015,H.mule[1]+0.015),0.05*u,0.06*u,0.3*dir,0,Math.PI*2); c.fill();
  c.fillStyle="#241A12";
  c.beginPath(); c.ellipse(...K(H.nos[0],H.nos[1]),0.013*u,0.018*u,0,0,Math.PI*2); c.fill();

  /* Man — vågig kam längs halsen + pannlugg */
  c.fillStyle=man;
  c.beginPath();
  M(K(0.08,-1.01));
  B(K(H.crest1[0]-0.02,H.crest1[1]-0.05),K(H.crest2[0]-0.02,H.crest2[1]-0.05),K(H.nacke[0]-0.01,H.nacke[1]-0.04));
  B(K(H.nacke[0]+0.02,H.nacke[1]+0.02),K(H.crest2[0]+0.05,H.crest2[1]+0.10),K(H.crest2[0]-0.02,H.crest2[1]+0.14));
  B(K(H.crest1[0]+0.03,H.crest1[1]+0.16),K(0.16,-0.98),K(0.06,-0.90));
  B(K(0.02,-0.95),K(0.04,-1.0),K(0.08,-1.01));
  c.closePath(); c.fill();
  c.beginPath(); c.ellipse(...K(H.ora[0]+0.01,H.ora[1]+0.06),0.05*u,0.028*u,0.6*dir,0,Math.PI*2); c.fill();

  /* Skuggning och lyster */
  c.fillStyle="rgba(20,14,8,.16)";
  c.beginPath();
  M(K(0.34,-0.50)); B(K(0.16,-0.40),K(-0.30,-0.42),K(-0.52,-0.52));
  B(K(-0.36,-0.52),K(0.12,-0.50),K(0.34,-0.50));
  c.closePath(); c.fill();
  c.fillStyle="rgba(255,240,210,.13)";
  c.beginPath();
  M(K(-0.50,-0.99)); B(K(-0.25,-0.94),K(0.05,-0.98),K(0.24,-1.00));
  B(K(0.05,-1.04),K(-0.30,-1.04),K(-0.50,-0.99));
  c.closePath(); c.fill();

  /* Grimma */
  if(o.grimma&&!beta){
    c.strokeStyle="#7A3B2A"; c.lineWidth=Math.max(1,u*0.018);
    c.beginPath();
    M(K(0.80,-1.14)); B(K(0.76,-1.06),K(0.74,-1.04),K(0.72,-1.03)); // nosgrimma
    c.stroke();
    c.beginPath(); M(K(0.78,-1.16)); c.lineTo(...K(0.62,-1.32)); c.stroke(); // sidostycke
  }
  /* Sadel med vojlock och gjord */
  if(o.sadel){
    c.fillStyle="#3E5C38";
    c.beginPath(); c.ellipse(...K(-0.06,-1.00),0.20*u,0.075*u,-0.06*dir,0,Math.PI*2); c.fill();
    c.fillStyle="#5A4330";
    c.beginPath();
    M(K(0.10,-1.00)); B(K(0.13,-1.06),K(0.06,-1.08),K(-0.02,-1.06)); // sadelbom
    B(K(-0.16,-1.08),K(-0.24,-1.04),K(-0.22,-0.98));
    B(K(-0.14,-0.86),K(-0.02,-0.84),K(0.05,-0.88));
    B(K(0.10,-0.92),K(0.11,-0.96),K(0.10,-1.00));
    c.closePath(); c.fill();
    c.strokeStyle="#4A3626"; c.lineWidth=Math.max(1,u*0.022);
    c.beginPath(); M(K(-0.04,-0.86)); B(K(-0.05,-0.66),K(-0.05,-0.56),K(-0.04,-0.44)); c.stroke();
  }
}

/* Huvud framifrån — boxdörrarna i stallet. */
function ritaHastHuvudFront(c,x,y,sz,farg,man,nick){
  nick=nick||0;
  c.fillStyle=farg;
  // hals bakom
  c.beginPath(); c.ellipse(x,y+sz*0.30+nick,sz*0.30,sz*0.42,0,0,Math.PI*2); c.fill();
  // skalle: bred panna, smalnande nosrygg
  c.beginPath();
  c.moveTo(x-sz*0.26,y-sz*0.28+nick);
  c.bezierCurveTo(x-sz*0.30,y+nick, x-sz*0.16,y+sz*0.34+nick, x-sz*0.10,y+sz*0.46+nick);
  c.bezierCurveTo(x-sz*0.05,y+sz*0.54+nick, x+sz*0.05,y+sz*0.54+nick, x+sz*0.10,y+sz*0.46+nick);
  c.bezierCurveTo(x+sz*0.16,y+sz*0.34+nick, x+sz*0.30,y+nick, x+sz*0.26,y-sz*0.28+nick);
  c.bezierCurveTo(x+sz*0.14,y-sz*0.42+nick, x-sz*0.14,y-sz*0.42+nick, x-sz*0.26,y-sz*0.28+nick);
  c.closePath(); c.fill();
  // öron
  const ora=(d)=>{c.beginPath();
    c.moveTo(x+d*sz*0.14,y-sz*0.36+nick);
    c.lineTo(x+d*sz*0.26,y-sz*0.66+nick);
    c.lineTo(x+d*sz*0.32,y-sz*0.34+nick);
    c.closePath(); c.fill();};
  ora(-1); ora(1);
  // pannlugg
  c.fillStyle=man;
  c.beginPath(); c.ellipse(x,y-sz*0.34+nick,sz*0.20,sz*0.13,0,0,Math.PI*2); c.fill();
  // ögon
  c.fillStyle="#16100B";
  c.beginPath(); c.ellipse(x-sz*0.17,y-sz*0.10+nick,sz*0.035,sz*0.05,0,0,Math.PI*2); c.fill();
  c.beginPath(); c.ellipse(x+sz*0.17,y-sz*0.10+nick,sz*0.035,sz*0.05,0,0,Math.PI*2); c.fill();
  // mule + näsborrar
  c.fillStyle=hastMorkare(farg,0.72);
  c.beginPath(); c.ellipse(x,y+sz*0.44+nick,sz*0.13,sz*0.10,0,0,Math.PI*2); c.fill();
  c.fillStyle="#241A12";
  c.beginPath(); c.ellipse(x-sz*0.05,y+sz*0.43+nick,sz*0.020,sz*0.028,0,0,Math.PI*2); c.fill();
  c.beginPath(); c.ellipse(x+sz*0.05,y+sz*0.43+nick,sz*0.020,sz*0.028,0,0,Math.PI*2); c.fill();
  // bläs
  c.fillStyle="rgba(240,235,225,.25)";
  c.beginPath(); c.ellipse(x,y+sz*0.10+nick,sz*0.045,sz*0.30,0,0,Math.PI*2); c.fill();
}
