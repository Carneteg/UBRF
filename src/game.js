/* ══════════════════════════════════════════════════════════════════
   SPELET — scener, input, fysik på planen, lektion, hoppning, betyg.
   ══════════════════════════════════════════════════════════════════ */

/* ── Input: tryck är handlingar, inte tillstånd ── */
const IN={
  kan:{skankel:{v:.15,mal:.15},tygel:{v:0,mal:0},sits:{v:.2,mal:.2},styrning:{v:0,mal:0}},
  latt:true,diagonal:1,spo:false,hh:-1,ned:{},
};
const STIG=0.28,FALL=0.22;
addEventListener("keydown",e=>{
  if(e.repeat)return; IN.ned[e.code]=true;
  const k=IN.kan;
  switch(e.code){
    case"KeyW":k.skankel.mal=0.78;break;
    case"KeyS":k.skankel.mal=0.05;break;
    case"Space":k.tygel.mal=0.80;e.preventDefault();break;
    case"ShiftLeft":case"ShiftRight":k.sits.mal=-0.6;break;
    case"ControlLeft":case"ControlRight":k.sits.mal=0.85;e.preventDefault();break;
    case"KeyA":k.styrning.mal=-0.72;break;
    case"KeyD":k.styrning.mal=0.72;break;
    case"KeyR":IN.latt=!IN.latt;break;
    case"KeyQ":IN.diagonal=1-IN.diagonal;break;
    case"KeyF":IN.spo=true;break;
    case"KeyE":if(IN.hh<0)IN.hh=0;break;
    case"KeyN":G.hoppaMoment=true;break;
    case"KeyP":G.auto=!G.auto;saga(G.auto?"Jag visar. Titta på vägen jag väljer.":"Din tur.",2.5);break;
    case"KeyV":vaxlaVy();break;
    case"KeyT":{
      const ov2=document.getElementById("ov");
      if(!ov2.classList.contains("hide"))break;
      if(G.scen==="lektion"||G.scen==="bana"){
        const oid=G.moment&&MOMENT_OVNING[G.moment.id];
        if(oid)visaOvning(oid,"spel");
      }else if(G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne")visaTraningsbok("spel");
      break;}
  }
});
addEventListener("keyup",e=>{
  IN.ned[e.code]=false;const k=IN.kan;
  switch(e.code){
    case"KeyW":case"KeyS":k.skankel.mal=0.42;break;
    case"Space":k.tygel.mal=0.34;break;
    case"ShiftLeft":case"ShiftRight":case"ControlLeft":case"ControlRight":k.sits.mal=0.2;break;
    case"KeyA":if(!IN.ned.KeyD)k.styrning.mal=0;break;
    case"KeyD":if(!IN.ned.KeyA)k.styrning.mal=0;break;
    case"KeyF":IN.spo=false;break;
  }
});
function stegaInput(dt){
  for(const n in IN.kan){const k=IN.kan[n];
    const fart=(k.mal>k.v?1/STIG:1/FALL)*dt;
    if(Math.abs(k.mal-k.v)<=fart)k.v=k.mal;else k.v+=k.mal>k.v?fart:-fart;}
  let hS=0,hK=0,hT=0;
  if(IN.hh>=0){IN.hh+=dt;const t=IN.hh;let st=0;
    if(t<0.14)st=t/0.14;else if(t<0.24)st=1;else if(t<0.42)st=1-(t-0.24)/0.18;else IN.hh=-1;
    hS=st*0.28;hK=st*0.26;hT=st*0.27;}
  return{skankel:clamp(IN.kan.skankel.v+hK,0,1),tygel:clamp(IN.kan.tygel.v+hT,0,1),
    sits:clamp(IN.kan.sits.v+hS,-1,1),styrning:clamp(IN.kan.styrning.v,-1,1),
    lattridning:IN.latt,diagonal:IN.diagonal,spo:IN.spo};
}

/* ── Speltillstånd ── */
const G={
  scen:"meny",vy:"2d",t:0,
  hastId:null,ride:null,aids:null,leder:false,skotselRes:null,
  px:10,py:52,rikt:-Math.PI/2,gaitFas:0,
  dagsform:0.7,sadellage:0.8,stallro:0.9,
  moment:null,momentIx:0,momentT:0,
  betyg:{},npcs:[],
  hinderAktiva:false,nastaHinder:0,rivna:new Set(),handelser:[],banTid:0,banStart:0,
  vagranStopp:0,sisteHopp:0,luft:0,auto:false,
  rngHopp:null,spanningPuls:0,hoppaMoment:false,
  sagaT:0,sagaCd:8,seed:1,
};
function vaxlaVy(){G.vy=G.vy==="2d"?"3d":"2d";
  document.querySelectorAll("#viewToggle button").forEach(b=>b.classList.toggle("on",b.dataset.v===G.vy));}
document.querySelectorAll("#viewToggle button").forEach(b=>b.addEventListener("click",()=>{
  if(b.dataset.v!==G.vy)vaxlaVy();}));

/* ── NPC-ekipage: rider fyrkantspåret olika bra ── */
function initNPC(){
  G.npcs=NPC_ELEVER.map((n,i)=>({...n,farg:HORSES[n.hast].farg,
    s:15+i*19, fart:1.2+n.skick*1.6, x:0,y:0,rikt:0}));
}
function stegaNPC(dt){
  // fyrkantspåret som sluten bana: omkrets 2*(17+57)=148 m
  for(const n of G.npcs){
    if(G.scen==="bana"){ // står på medellinjen och tittar på
      n.x=4+G.npcs.indexOf(n)*2.2;n.y=56.5;n.rikt=-Math.PI/2;continue;}
    n.s=(n.s+n.fart*dt*(0.95+0.1*Math.sin(G.t*0.5+n.skick*9)))%148;
    const s=n.s;
    if(s<57){n.x=1.5;n.y=58.5-s;n.rikt=-Math.PI/2;}
    else if(s<74){n.x=1.5+(s-57);n.y=1.5;n.rikt=0;}
    else if(s<131){n.x=18.5;n.y=1.5+(s-74);n.rikt=Math.PI/2;}
    else{n.x=18.5-(s-131);n.y=58.5;n.rikt=Math.PI;}
  }
}

/* ── Ritt-fysik på planen ── */
let kursHist=[];
function stegaRitt(dt){
  G.aids=stegaInput(dt);
  if(G.auto)autopilot(dt);
  const h=HORSES[G.hastId];
  // svängradie ur faktisk kursändring
  const omega=G.aids.styrning*clamp(0.5+G.ride.tempo*0.22,0.4,2.2);
  const radie=Math.abs(omega)>0.02?Math.abs(G.ride.tempo/omega):1000;
  stepRide(G.ride,G.aids,h,{svangradie:clamp(radie,3,1000),underlag:.92,stallro:G.stallro,utomhus:false},dt);
  G.rikt+=omega*dt*(G.ride.tempo>0.2?1:0);
  // väggkollision: mjuk knuff in
  let nx=G.px+Math.cos(G.rikt)*G.ride.tempo*dt;
  let ny=G.py+Math.sin(G.rikt)*G.ride.tempo*dt;
  if(nx<0.8){nx=0.8;G.rikt=lerpAngle(G.rikt,ny>G.py?Math.PI/2:-Math.PI/2,0.06);}
  if(nx>19.2){nx=19.2;G.rikt=lerpAngle(G.rikt,ny>G.py?Math.PI/2:-Math.PI/2,0.06);}
  if(ny<0.8){ny=0.8;G.rikt=lerpAngle(G.rikt,nx>G.px?0:Math.PI,0.06);}
  if(ny>59.2){ny=59.2;G.rikt=lerpAngle(G.rikt,nx>G.px?0:Math.PI,0.06);}
  G.px=nx;G.py=ny;
  // gångartsfas för animation
  const stegFrek=G.ride.gangart==="skritt"?1.0:G.ride.gangart==="trav"?1.5:G.ride.gangart==="galopp"?1.75:0;
  G.gaitFas=(G.gaitFas+stegFrek*dt*(0.6+G.ride.tempo*0.12))%1;
  G.spanningPuls=clamp(G.ride.spanning-0.55,0,1)/0.45;
}
function lerpAngle(a,b,t){let d=b-a;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;return a+d*t;}

/* Autopilot — "ridläraren visar". Styr mot nästa hinders anridningslinje,
   håller arbetstempo och mjuka hjälper. Finns för demo och för test;
   den använder samma hjälper som spelaren, inga genvägar i modellen. */
function autopilot(dt){
  let mx=10,my=30;
  const h=G.hinderAktiva?BANA.hinder.find(x=>x.nr===G.nastaHinder):null;
  if(h){
    // Tvåfas, som en riktig inridning: först TILL anridningspunkten
    // (12 m ut på hindrets linje), checka in där, och först därefter
    // rakt mot hindret. Utan incheckningen orbitar man — sikta direkt
    // på ett mål som kräver mindre svängradie än hästen har, och du
    // cirklar runt det för evigt. Precis som på riktigt, för övrigt.
    if(!G._ap||G._ap.nr!==h.nr)G._ap={nr:h.nr,inne:false};
    const S={x:clamp(h.x-Math.cos(h.rot)*12,1.5,18.5),
             y:clamp(h.y-Math.sin(h.rot)*12,1.5,58.5)};
    if(!G._ap.inne&&Math.hypot(S.x-G.px,S.y-G.py)<3.2)G._ap.inne=true;
    if(G._ap.inne){mx=h.x+Math.cos(h.rot)*2;my=h.y+Math.sin(h.rot)*2;}
    else{mx=S.x;my=S.y;}
  }else{ // rid fyrkantspåret
    const mal=[[1.8,1.8],[18.2,1.8],[18.2,58.2],[1.8,58.2]];
    let bi=0,bd=1e9;
    for(let i=0;i<4;i++){const d=Math.hypot(mal[i][0]-G.px,mal[i][1]-G.py);
      if(d<bd&&d>3){bd=d;bi=i;}}
    [mx,my]=mal[bi];
  }
  const onskad=Math.atan2(my-G.py,mx-G.px);
  let d=onskad-G.rikt;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;
  G.aids.styrning=clamp(d*1.4,-0.8,0.8);
  G.aids.skankel=0.62; G.aids.tygel=0.37; G.aids.sits=0.2;
  G.aids.lattridning=true; G.aids.diagonal=1; G.aids.spo=false;
}

/* ── Hoppningen ── */
function startaBana(){
  G.hinderAktiva=true;G.nastaHinder=1;G.rivna.clear();G.handelser=[];
  G.banStart=G.t;G.vagranStopp=0;
  G.rngHopp=Approach.rng(G.seed*7919+13);
  document.getElementById("protWrap").hidden=false;
  uppdateraProt();
}
function hinderRel(h){
  // avstånd längs hindrets anridningsriktning + sidled
  // rot är SPRÅNGETS riktning. Vektorn spelare→hinder projicerad på den
  // är positiv så länge hindret ligger framför — dvs. före avsprånget.
  const ax=Math.cos(h.rot),ay=Math.sin(h.rot);
  const dx=h.x-G.px,dy=h.y-G.py;
  const fram=dx*ax+dy*ay;
  const sida=-dx*ay+dy*ax;
  return{fram,sida};
}
let protT=0;
function stegaBana(dt){
  protT+=dt; if(protT>0.5){protT=0;uppdateraProt();}
  if(G.t-G.banStart>180){avslutaBana(domaRitt(G.handelser,G.t-G.banStart,true));return;}
  if(G.vagranStopp>0){G.vagranStopp-=dt;return;}
  const h=BANA.hinder.find(x=>x.nr===G.nastaHinder);
  if(!h)return;
  const rel=hinderRel(h);
  const avst=rel.fram; // >0 = före hindret
  const ap=document.getElementById("approach");
  // heading-koll: rider vi mot hindret?
  const riktMot=Math.abs(angDiff(G.rikt,h.rot))<1.1;
  if(avst>0&&avst<26&&Math.abs(angDiff(G.rikt,h.rot))<1.1&&Math.abs(rel.sida)<4&&G.ride.tempo>1.2){
    const los=Approach.los(avst,Math.max(G.ride.steglangd,0.6),BANA.hojd);
    ap.textContent=los.rad;
    G._losning=los;
  } else ap.textContent="";
  // passage av avsprångszonen?
  const zon=Approach.zon(Math.max(G.ride.steglangd,0.6),BANA.hojd);
  if(avst<zon&&avst>-1&&riktMot&&Math.abs(rel.sida)<2.6&&G.t-G.sisteHopp>1.2){
    G.sisteHopp=G.t;
    const los=G._losning||Approach.los(Math.max(avst,zon),Math.max(G.ride.steglangd,0.6),BANA.hojd);
    const q=Approach.kvalitet(los,G.ride.skala,G.ride.spanning,G.dagsform);
    const hh=HORSES[G.hastId];
    const utfall=Approach.utfall(q,BANA.hojd,hh.hoppkapacitet,hh.hopplust,hh.maxhojd,G.ride.rang,G.rngHopp);
    if(utfall.resultat==="vagran"){
      G.handelser.push({typ:"olydnad",hinder:h.nr});
      G.ride.tempo=0;G.vagranStopp=1.4;
      flash("VÄGRAN");saga(utfall.kommentar,3.2);
      const dom=domaRitt(G.handelser,G.t-G.banStart,true);
      if(dom.utesluten){avslutaBana(dom);return;}
    }else{
      G.luft=0.55; // hopp-animation
      if(utfall.resultat==="rivning"){G.rivna.add(h.nr);G.handelser.push({typ:"nedslag",hinder:h.nr});
        flash("4 FEL");saga(utfall.kommentar,2.6);}
      else if(q>0.8)saga(utfall.kommentar,2.2);
      G.nastaHinder++;
      if(G.nastaHinder>BANA.hinder.length){
        avslutaBana(domaRitt(G.handelser,G.t-G.banStart,true));return;}
    }
    uppdateraProt();
  }
}
function angDiff(a,b){let d=a-b;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;return Math.abs(d);}
function uppdateraProt(){
  const dom=domaRitt(G.handelser,G.t-G.banStart,true);
  const el=document.getElementById("prot");
  let rows=`<div class="lbl" style="margin-bottom:6px">Protokoll · 0,60 m</div>`;
  rows+=`<div class="r"><span>Hinder</span><b>${Math.min(G.nastaHinder,6)} / 6</b></div>`;
  rows+=`<div class="r ${dom.hinderfel?"bad":""}"><span>Fel</span><b>${dom.hinderfel}</b></div>`;
  rows+=`<div class="r"><span>Olydnader</span><b>${dom.olydnader}</b></div>`;
  rows+=`<div class="r"><span>Tid</span><b>${(G.t-G.banStart).toFixed(0)} s</b></div>`;
  el.innerHTML=rows;
}
function flash(txt){const f=document.getElementById("faults");
  f.textContent=txt;f.style.opacity=1;f.style.transform="translate(-50%,-50%) scale(1.06)";
  setTimeout(()=>{f.style.opacity=0;f.style.transform="translate(-50%,-50%) scale(1)";},900);}
function saga(txt,dur){const s=document.getElementById("saga");
  s.textContent=txt;s.classList.add("on");G.sagaT=dur||3;}

/* ── Lektionen ── */
function startaLektion(){
  G.scen="lektion";G.momentIx=0;G.momentT=0;G.betyg={};
  G.moment=LEKTION[0];visaMoment();
  overlay(false);document.getElementById("viewToggle").hidden=false;
}
function visaMoment(){
  const m=G.moment;
  document.getElementById("momentLbl").textContent=`Moment ${G.momentIx+1} av ${LEKTION.length}`;
  document.getElementById("momentNamn").textContent=m.namn;
  document.getElementById("momentText").textContent=
    m.text+(MOMENT_OVNING[m.id]?" · T öppnar övningen i träningsboken.":"");
  saga(m.text,4);
}
function stegaLektion(dt){
  const m=G.moment;if(!m)return;
  G.momentT+=dt;
  if(m.id==="bana"){
    if(!G.hinderAktiva)startaBana();
    stegaBana(dt);
    document.querySelector("#momentBar i").style.width=(G.nastaHinder-1)/6*100+"%";
  }else{
    document.querySelector("#momentBar i").style.width=clamp(G.momentT/m.tid*100,0,100)+"%";
    // ridlärartillsägelser
    G.sagaCd-=dt;
    if(G.sagaCd<=0&&G.momentT>6){
      const[rop]=ridlararRop(G.ride,"grupp2",Math.floor(G.t));
      saga(rop,3.4);G.sagaCd=11+Math.random()*5;
    }
    if(G.momentT>=m.tid||G.hoppaMoment){
      G.hoppaMoment=false;
      if(m.bedoms)G.betyg[m.id]=Skala.inverkan(G.ride.skala,"grupp2");
      G.momentIx++;
      if(G.momentIx<LEKTION.length){G.moment=LEKTION[G.momentIx];G.momentT=0;visaMoment();}
    }
  }
}
function avslutaBana(dom){
  G.betyg.bana=Skala.inverkan(G.ride.skala,"grupp2");
  G.domare=dom;G.scen="resultat";
  document.getElementById("protWrap").hidden=true;
  document.getElementById("viewToggle").hidden=true;
  visaResultat(dom);
}

/* ── HUD ── */
const PCOL={takt:"#4A737E",losgjordhet:"#56888A",kontakt:"#5F9C85",schvung:"#86AE79",rakriktning:"#C0B063",samling:"#D6AE3C"};
(function initHUD(){
  const pr=document.getElementById("pyrRows");
  for(const k of [...Skala.ORDER].reverse()){
    const d=document.createElement("div");d.className="prow";d.dataset.k=k;
    d.innerHTML=`<span class="pname">${Skala.LABEL[k]}</span>
      <span class="ptrack"><i class="pfill" style="background:${PCOL[k]}"></i><i class="pcap"></i></span>`;
    pr.appendChild(d);}
  const ar=document.getElementById("aidRows");
  const rows=[["skankel","Skänkel","W/S"],["tygel","Tygel","Space"],["sits","Sits","⇧/Ctrl"],["styrning","Styr","A/D"]];
  for(const[k,n,key]of rows){
    const d=document.createElement("div");d.className="arow";d.dataset.k=k;
    let band="";
    if(k==="tygel")band=`<i class="band" style="left:22%;width:36%"></i>`;
    if(k==="skankel")band=`<i class="band" style="left:28%;width:45%"></i>`;
    d.innerHTML=`<span class="aname">${n}</span><span class="atrack">${band}<i class="v"></i></span><span class="akey">${key}</span>`;
    ar.appendChild(d);}
})();
function ritaHUD(){
  if(!G.ride)return;
  for(const k of Skala.ORDER){
    const row=document.querySelector(`.prow[data-k="${k}"]`);if(!row)continue;
    const v=G.ride.skala[k];
    row.querySelector(".pfill").style.width=(v*100).toFixed(1)+"%";
    // takmarkering: kapas nivån av golvet under?
    let golv=1;for(const kk of Skala.ORDER){if(kk===k)break;if(G.ride.skala[kk]<golv)golv=G.ride.skala[kk];}
    const kapad=v>=golv+Skala.TOL-0.005&&golv<0.98;
    const cap=row.querySelector(".pcap");
    cap.classList.toggle("on",kapad);
    if(kapad)cap.style.width=((golv+Skala.TOL)*100).toFixed(1)+"%";
  }
  document.querySelector("#inverkan b").textContent=
    Skala.inverkan(G.ride.skala,"grupp2").toFixed(2).replace(".",",");
  const g=Gait.G[G.ride.gangart];
  document.getElementById("gait").textContent=g.namn+(G.ride.gangart==="trav"?(IN.latt?" · lättridning":" · nedsittning"):"");
  document.getElementById("tempo").textContent=G.ride.tempo.toFixed(1).replace(".",",")+" m/s";
  document.getElementById("gaitWarn").textContent=
    G.ride.spanning>0.6?"SPÄND":(G.ride.gangart==="trav"&&IN.latt&&IN.diagonal===0?"FEL DIAGONAL (Q)":"");
  if(G.aids)for(const k in IN.kan){
    const row=document.querySelector(`.arow[data-k="${k}"] .v`);if(!row)continue;
    const v=k==="sits"?(G.aids[k]+1)/2:k==="styrning"?(G.aids[k]+1)/2:G.aids[k];
    if(k==="styrning"){row.style.left=(v*100-2)+"%";row.style.width="4%";}
    else{row.style.left=0;row.style.width=(v*100)+"%";}
  }
  if(G.sagaT>0){G.sagaT-=1/60;if(G.sagaT<=0)document.getElementById("saga").classList.remove("on");}
}

/* ── Huvudloop ── */
let last=performance.now();
function loop(now){
  const dt=Math.min((now-last)/1000,0.05);last=now;G.t+=dt;
  if(G.scen==="lektion"||G.scen==="bana"){
    stegaRitt(dt);stegaNPC(dt);stegaLektion(dt);
    if(G.luft>0)G.luft-=dt;
    if(G.vy==="2d")draw2D(G);else draw3D(G);
    ritaHUD();
  } else if(G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne"){
    stegaVandring(dt);ritaVandring();
  } else if(G.scen==="resultat"){
    if(G.vy==="2d")draw2D(G);else draw3D(G);
  }
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
