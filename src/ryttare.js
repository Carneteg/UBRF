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
/* Från vilket steg varje TUNAD häst anförtros. Det här är gameplay, inte
   verklighetsfakta. S2c neutraliserar Lady, Westside och Kennedy eftersom
   deras gamla profiler hörde till felaktig identitetsdata; nya hästar är
   också UNTUNED. De ska därför inte smygas in i en elevgrupp förrän en
   separat tuning-slice har bestämt deras gameplayroll. */
const HAST_MINGRUPP={toblerone:0, lydia:0, cosmo:3, air:3, larry:5, dexter:5,
  hamilton:6, crokino:6, conor:7};
const UPPFLYTT_KRAV=2;   // godkända pass för uppflyttning

const SPAR_NYCKEL="ubrf-ridskolan-v1";
let SPAR=null;

function nyProfil(){
  return {grupp:"ledlektion", poang:0, pass:0, fortroende:{}, historik:[], rosetter:[]};
}
function laddaRyttare(){
  SPAR=nyProfil();
  try{
    const s=localStorage.getItem(SPAR_NYCKEL);
    if(s){
      const d=JSON.parse(s);
      /* Vakterna kollar TYP, inte bara sanningsvärde. En sparning där
         fortroende är strängen "trasig" är truthy och slank förut
         igenom — sedan kraschade registreraPass permanent på
         SPAR.fortroende[id]=..., och varje pass därefter med. En trasig
         sparning ska ge ett spelbart spel, inte ett dött. */
      const obj=v=>(v&&typeof v==="object"&&!Array.isArray(v))?v:{};
      const arr=v=>Array.isArray(v)?v:[];
      if(d&&GRUPPSTEGE.includes(d.grupp))
        SPAR={...nyProfil(),...d, fortroende:obj(d.fortroende),
          historik:arr(d.historik), rosetter:arr(d.rosetter),
          fardighet:obj(d.fardighet), jag:obj(d.jag),
          poang:+d.poang||0, pass:+d.pass||0};
    }
  }catch(_){/* privat läge eller blockerad lagring — spela från noll */}
  G.grupp=SPAR.grupp;
}
function sparaRyttare(){
  /* Stämpeln avgör vem som vinner när två enheter har olika versioner.
     Den sätts här, vid varje sparning, och ingen annanstans. */
  SPAR.uppdaterad=new Date().toISOString();
  try{localStorage.setItem(SPAR_NYCKEL,JSON.stringify(SPAR));}catch(_){}
  if(typeof synkKnuffa==="function")synkKnuffa();
}
function nollstallRyttare(){
  SPAR=nyProfil(); G.grupp=SPAR.grupp;
  try{localStorage.removeItem(SPAR_NYCKEL);}catch(_){}
}

/* Dagens händelser i stallet: hovslagaren och veterinären roterar
   över listan efter dagens frö, och skadade hästar står på vila.
   En häst med händelse går inte i rotationen den dagen. */
function dagensHandelser(){
  const alla=Object.keys(HORSES), n=alla.length;
  const s=((typeof G!=="undefined"&&G.seed)||0)>>>0;
  const ut={};
  if(s%3===0) ut[alla[(s*7+3)%n]]={typ:"hovslagare", text:"skos om — hovslagaren är här"};
  if(s%5===2){ const id=alla[(s*11+5)%n];
    if(!ut[id]) ut[id]={typ:"veterinar", text:"veterinärbesök — vaccination och tandkoll"}; }
  for(const id of alla){ const m=hastminne(id);
    if(m.skada&&m.skada.passKvar>0)
      ut[id]={typ:"skada", text:`vila — ${m.skada.namn} (${m.skada.passKvar} pass kvar)`}; }
  return ut;
}
/* Hästpoolen för en grupp: bara hästar som både finns i den aktuella kanonen,
   har en avsiktlig gameplay-tröskel och är i tjänst i dag. */
function hastpool(grupp){
  const idx=GRUPPSTEGE.indexOf(grupp);
  const enligtGrupp=Object.keys(HAST_MINGRUPP)
    .filter(id=>HORSES[id]&&HAST_MINGRUPP[id]<=idx);
  const borta=dagensHandelser();
  const pool=enligtGrupp.filter(id=>!borta[id]);
  return pool.length?pool:(enligtGrupp.length?enligtGrupp:["toblerone"]);
}
/* Hästens sparade minne av dig — rang, pass, gårdagens form och
   eventuell skada eller rehab. */
function hastminne(id){
  return (SPAR&&SPAR.fortroende[id])||{rang:0.45, pass:0};
}

/* Efter varje ritt: uppdatera minnet, historiken och gruppstegen. */
function registreraPass(dom){
  const riddenGrupp=G.grupp, riddenNamn=GRUPPNAMN[riddenGrupp]||riddenGrupp;
  const inv=Object.values(G.betyg);
  const snitt=inv.length?inv.reduce((a,b)=>a+b,0)/inv.length:0;
  const forv=Skala.FORVANTAN[G.grupp]??0.55;
  /* Godkänt kräver att du KLARADE minst hälften av de bedömda momenten,
     inte bara att snittet blev högt. Utan det räckte det att låta hästen
     driva: hon hamnar av sig själv i skritt, betyget blir delvis, och
     snittet slog kravet i ledlektion, knatte och grupp2 — alltså gick
     man upp ur nybörjargrupperna utan att röra en tangent.

     Betyget får fortsätta vara gradvis; det är UPPFLYTTNINGEN som ska
     kräva att man faktiskt kan göra övningarna. Så säger en ridlärare
     också: du flyttas upp när du klarar momenten, inte när hästen råkar
     bete sig. */
  const bedomda=G.bedomda||0, klarade=G.klarade||0;
  /* MINST hälften, uppåt avrundat: 1 av 2, 2 av 3, 2 av 4.

     Först skrev jag "över hälften" — och det degenererar till ALLA när
     det bara finns två bedömda moment, vilket är precis vad ledlektion,
     knatte och minior har. Noll av tjugofem simulerade nybörjarpass blev
     godkända, och en fullt kompetent ryttare med snitt 0,335 mot kravet
     0,25 föll på att 1 inte är större än 1. Regeln låste alltså just den
     del av spelet som ska vara mest förlåtande.

     Det som faktiskt stänger den passiva vägen är kontaktkravet i
     stegaLektion, inte den här kvoten. Passivt spel klarar 0 av 2 och
     faller på raden nedan ändå. */
  const nogKlarade=bedomda===0||klarade>=Math.ceil(bedomda/2);
  const godkand=!dom.utesluten&&snitt>=forv&&nogKlarade;
  const m=hastminne(G.hastId);
  SPAR.pass++;
  /* Hästen minns passet: rang, form och att den gick nyss. Efter en
     ridd rehab-dag är vägen tillbaka avklarad. */
  /* Skötseln väger in i relationen, inte bara i dagsformen. Sköter du
     henne väl minns hon det; slarvar du minns hon det också, och den
     skulden rider man inte av sig på ett pass. Priset är medvetet
     större nedåt än uppåt — förtroende byggs långsamt och tappas fort,
     hos hästar som hos människor. */
  let rangEfterRitt=clamp(G.ride?G.ride.rang:m.rang,0,1);
  {const sk=G.skotselRes;
   if(sk){
     const form=clamp(sk.dagsform??0.7,0,1);
     const slarv=(sk.risker||[]).length;
     const skotselDelta=(form-0.62)*0.12-slarv*0.035;
     rangEfterRitt=clamp(rangEfterRitt+skotselDelta,0,1);
   }}
  /* Taket per pass. Ridningens rang stiger snabbt inom ett pass, och så
     ska det vara — det är känslan i sadeln av att ni hittar varandra.
     Men som MINNE är det för snabbt: efter-passet visade en relation
     som gick från 0,45 till 1,00 på en lektion, och då betyder den
     ingenting. Nedåt är taket större än uppåt, som förut. */
  {const TAK=0.06;
   /* Tålamod skyddar nedåt, inte uppåt: ett dåligt pass river mindre av
      det ni byggt, men det bygger inget snabbare. */
   const skydd=1-clamp(((typeof jagMod==="function")&&jagMod().fortroendeskydd)||0,0,0.6);
   const d=clamp(rangEfterRitt-m.rang,-TAK*1.6*skydd,TAK);
   rangEfterRitt=clamp(m.rang+d,0,1);}
  const ny={...m, rang:rangEfterRitt, pass:m.pass+1,
    sistaPassNr:SPAR.pass, sistaForm:Math.round(G.dagsform*100)/100, rehab:false};
  delete ny.skada;
  /* Slarv i skötseln har ett pris dagen efter — sten i hoven eller
     missat skav blir en skada som kräver vila. */
  const risker=(G.skotselRes&&G.skotselRes.risker)||[];
  let nySkada=null;
  if(risker.includes("sten_i_hoven"))
    nySkada={namn:"känning efter sten i hoven", passKvar:2};
  else if(risker.includes("missat_skav"))
    nySkada={namn:"skav under sadelgjorden", passKvar:1};
  if(nySkada)ny.skada=nySkada;
  SPAR.fortroende[G.hastId]=ny;
  /* De andra hästarnas skador läker med vilan — ett pass i taget.
     När vilan är slut väntar ett rehab-pass: bara skritt och trav. */
  for(const id in SPAR.fortroende){
    if(id===G.hastId)continue;
    const f=SPAR.fortroende[id];
    if(f.skada&&f.skada.passKvar>0){
      f.skada.passKvar--;
      if(f.skada.passKvar<=0){delete f.skada; f.rehab=true;}
    }
  }
  /* Dagens tema följer med. Nästa pass läser det: satt det går hon
     vidare, satt det inte tar hon om det och SÄGER att hon gör det.
     Det är hela skillnaden mellan en lärare och en främling. */
  SPAR.historik.unshift({hast:G.hastId, grupp:G.grupp,
    snitt:Math.round(snitt*100)/100, fel:dom.totalfel, utesluten:dom.utesluten,
    fokus:(typeof lararDagensId==="function")?lararDagensId():null,
    fokusAndel:(typeof lararAndel==="function")?Math.round(lararAndel()*100)/100:null});
  if(SPAR.historik.length>20)SPAR.historik.length=20;
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
    riddenGrupp, riddenNamn, skada:nySkada,
    /* Efter-passet visar hur förtroendet rörde sig — både ridningen och
       skötseln väger in, och båda ska kunna läsas i en mening. */
    rangFore:clamp(m.rang??0.45,0,1), rangEfter:rangEfterRitt};
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