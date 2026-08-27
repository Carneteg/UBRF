/* ══════════════════════════════════════════════════════════════════
   RYTTAREN — steg 3: du börjar längst ner och utvecklas, på riktigt.
   Framstegen sparas i webbläsaren (localStorage): grupp, antal pass,
   uppflyttningspoäng och hästminnet — rang och pass per häst, så att
   förtroendet ni byggt består till nästa gång. Gruppstegen följer
   ridskolans: ledlektion → knatte → minior → grupp 1–5 → hoppgrupp,
   och skickligare ryttare anförtros känsligare hästar. Två godkända
   pass i rad med snitt över gruppens förväntan ger uppflyttning.
   Ingen lagring får vara ett krav: utan sparat spelar man från noll.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const GRUPPSTEGE=["ledlektion","knatte","minior","grupp1","grupp2","grupp3","grupp4","grupp5","hoppgrupp"];
const GRUPPNAMN={ledlektion:"Ledlektion",knatte:"Knattegruppen",minior:"Miniorgruppen",
  grupp1:"Grupp 1",grupp2:"Grupp 2",grupp3:"Grupp 3",grupp4:"Grupp 4",grupp5:"Grupp 5",
  hoppgrupp:"Hoppgruppen"};
/* Från vilket steg varje häst anförtros — de förlåtande först,
   de känsliga som belöning. */
const HAST_MINGRUPP={toblerone:0, lydia:0, cosmo:3, air:3, larry:5, dexter:5,
  hamilton:6, crokino:6, conor:7};
const UPPFLYTT_KRAV=2;   // godkända pass för uppflyttning

const SPAR_NYCKEL="ubrf-ridskolan-v1";
let SPAR=null;

function nyProfil(){
  return {grupp:"ledlektion", poang:0, pass:0, fortroende:{}, historik:[]};
}
function laddaRyttare(){
  SPAR=nyProfil();
  try{
    const s=localStorage.getItem(SPAR_NYCKEL);
    if(s){
      const d=JSON.parse(s);
      if(d&&GRUPPSTEGE.includes(d.grupp))
        SPAR={...nyProfil(),...d, fortroende:d.fortroende||{}, historik:d.historik||[]};
    }
  }catch(_){/* privat läge eller blockerad lagring — spela från noll */}
  G.grupp=SPAR.grupp;
}
function sparaRyttare(){
  try{localStorage.setItem(SPAR_NYCKEL,JSON.stringify(SPAR));}catch(_){}
}
function nollstallRyttare(){
  SPAR=nyProfil(); G.grupp=SPAR.grupp;
  try{localStorage.removeItem(SPAR_NYCKEL);}catch(_){}
}

/* Hästpoolen för en grupp: alla hästar som anförtros på den nivån. */
function hastpool(grupp){
  const idx=GRUPPSTEGE.indexOf(grupp);
  const pool=Object.keys(HAST_MINGRUPP).filter(id=>HAST_MINGRUPP[id]<=idx);
  return pool.length?pool:["toblerone"];
}
/* Hästens sparade minne av dig. */
function hastminne(id){
  return (SPAR&&SPAR.fortroende[id])||{rang:0.45, pass:0};
}

/* Efter varje ritt: uppdatera minnet, historiken och gruppstegen. */
function registreraPass(dom){
  const riddenGrupp=G.grupp, riddenNamn=GRUPPNAMN[riddenGrupp]||riddenGrupp;
  const inv=Object.values(G.betyg);
  const snitt=inv.length?inv.reduce((a,b)=>a+b,0)/inv.length:0;
  const forv=Skala.FORVANTAN[G.grupp]??0.55;
  const godkand=!dom.utesluten&&snitt>=forv;
  const m=hastminne(G.hastId);
  SPAR.fortroende[G.hastId]={rang:clamp(G.ride?G.ride.rang:m.rang,0,1), pass:m.pass+1};
  SPAR.historik.unshift({hast:G.hastId, grupp:G.grupp,
    snitt:Math.round(snitt*100)/100, fel:dom.totalfel, utesluten:dom.utesluten});
  if(SPAR.historik.length>20)SPAR.historik.length=20;
  SPAR.pass++;
  let uppflyttad=false;
  if(godkand){
    SPAR.poang++;
    const idx=GRUPPSTEGE.indexOf(SPAR.grupp);
    if(SPAR.poang>=UPPFLYTT_KRAV&&idx<GRUPPSTEGE.length-1){
      SPAR.grupp=GRUPPSTEGE[idx+1]; SPAR.poang=0; uppflyttad=true;
      G.grupp=SPAR.grupp;
    }
  }else if(dom.utesluten&&SPAR.poang>0){
    SPAR.poang--;   // en uteslutning kostar ett intjänat pass
  }
  sparaRyttare();
  return {snitt, forv, godkand, uppflyttad, grupp:SPAR.grupp,
    gruppNamn:GRUPPNAMN[SPAR.grupp], poang:SPAR.poang,
    riddenGrupp, riddenNamn};
}

/* Profilrutan i menyn. */
function profilHTML(){
  const m=SPAR.historik[0];
  const senast=m?`Senast: ${HORSES[m.hast]?HORSES[m.hast].namn:m.hast} — ${
    m.utesluten?"uteslutning":m.fel+" fel"}, snitt ${String(m.snitt).replace(".",",")}`
    :"Första passet väntar.";
  const kanda=Object.entries(SPAR.fortroende).filter(([,v])=>v.pass>0).length;
  return `<div class="note" style="display:flex;justify-content:space-between;gap:14px;flex-wrap:wrap;align-items:baseline">
    <span><b class="gold">${GRUPPNAMN[SPAR.grupp]}</b>
      <span class="dim"> · ${SPAR.pass} pass · uppflyttning ${SPAR.poang}/${UPPFLYTT_KRAV}
      · ${kanda} hästar du känner</span><br>
      <span class="dim" style="font-size:12.5px">${senast}</span></span>
    <button class="btn ghost" id="bNollstall" style="padding:6px 12px;font-size:12px">Nollställ ryttaren</button>
  </div>`;
}
function kopplaProfil(){
  const b=document.getElementById("bNollstall");
  if(!b)return;
  b.onclick=()=>{
    if(b.dataset.arm){nollstallRyttare();visaMeny();}
    else{b.dataset.arm="1";b.textContent="Säker? Allt raderas";b.classList.add("bad");}
  };
}

laddaRyttare();
