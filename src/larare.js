/* ══════════════════════════════════════════════════════════════════
   UGNETA — ridinstruktör för barn och ungdomar

   Pedagogisk regel:
   - en sak i taget
   - högst två korta punkter
   - feedback ska komma från faktisk riddata
   - beröm ska säga VAD som blev bättre
   - säkerhetsrop går fortfarande före all undervisning

   UX-regel:
   - läsbart på mobil, surfplatta och dator
   - ingen lång brödtext under aktiv ridning
   - Ugneta visas med en enkel porträttmarkör: äldre kvinna,
     grått hår och glasögon
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const RIDLARARE={
  namn:"Ugneta",
  beskrivning:"Äldre ridinstruktör med grått hår och glasögon",
  har:"grått",
  glasogon:true,
};

/* Den fysiska ridlärarpunkten finns redan i stallkanon. Namnet och
   utseendet hör däremot till lärarrollen och sätts här, på ett ställe. */
if(typeof STALLINNE!=="undefined"&&STALLINNE.ridlarare){
  STALLINNE.ridlarare.namn=RIDLARARE.namn;
  STALLINNE.ridlarare.utseende={alder:"äldre",har:"grått",glasogon:true};
}

/* ── Responsiv lärar-UX ───────────────────────────────────────── */
function installeraUgnetaUX(){
  if(typeof document==="undefined"||document.getElementById("ugneta-style"))return;
  const st=document.createElement("style");
  st.id="ugneta-style";
  st.textContent=`
    .hudh.bc.ugneta-wrap{width:min(640px,94vw);bottom:14px}
    #saga.ugneta-kort{display:grid!important;grid-template-columns:52px minmax(0,1fr);
      gap:11px;align-items:center;width:100%;max-width:640px;text-align:left;
      padding:10px 13px!important;border-radius:10px!important;
      background:rgba(12,14,18,.92)!important;border:1px solid rgba(214,174,60,.48);
      box-shadow:0 8px 30px -10px rgba(0,0,0,.9)!important;
      font-family:"IBM Plex Sans",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif!important;
      font-style:normal!important;text-shadow:none!important;color:#F6F2E8!important}
    .ugneta-portratt{width:48px;height:48px;border-radius:50%;position:relative;overflow:hidden;
      background:#D7C2AD;border:2px solid #D6AE3C;box-shadow:inset 0 -12px 0 #33413B}
    .ugneta-har{position:absolute;left:4px;right:4px;top:2px;height:19px;border-radius:22px 22px 9px 9px;
      background:#B9BDC3;border-bottom:2px solid #8C9198}
    .ugneta-glas{position:absolute;left:7px;top:20px;width:14px;height:9px;border:2px solid #2B2E34;
      border-radius:5px;box-shadow:18px 0 0 -2px #D7C2AD,18px 0 0 0 #2B2E34}
    .ugneta-glas:after{content:"";position:absolute;left:12px;top:2px;width:8px;border-top:2px solid #2B2E34}
    .ugneta-namn{font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:10px;line-height:1.2;
      letter-spacing:.12em;text-transform:uppercase;color:#E7C86B;font-weight:700}
    .ugneta-rubrik{font-family:Petrona,Georgia,serif;font-size:clamp(16px,2.4vw,20px);
      line-height:1.15;margin-top:2px;color:#FFF9EC;font-weight:650}
    .ugneta-punkter{display:grid;gap:2px;margin-top:4px;font-size:clamp(13px,1.8vw,15px);line-height:1.28;color:#E6E4DE}
    .ugneta-punkt{display:grid;grid-template-columns:12px 1fr;gap:3px;min-width:0}
    .ugneta-punkt:before{content:"•";color:#D6AE3C;font-weight:800}
    #saga.ugneta-kort.bra{border-color:rgba(127,180,137,.7)}
    #saga.ugneta-kort.bra .ugneta-punkt:before{color:#7FB489}
    #saga.ugneta-kort.sakerhet{border-color:rgba(208,101,90,.82)}
    @media(max-width:560px){
      .hudh.bc.ugneta-wrap{width:94vw;bottom:8px}
      #saga.ugneta-kort{grid-template-columns:40px minmax(0,1fr);gap:8px;padding:8px 10px!important}
      .ugneta-portratt{width:38px;height:38px}
      .ugneta-har{height:15px}.ugneta-glas{left:5px;top:16px;transform:scale(.82);transform-origin:left top}
      .ugneta-namn{font-size:9px}.ugneta-rubrik{font-size:15px}.ugneta-punkter{font-size:13px}
    }
    @media(max-height:560px) and (orientation:landscape){
      .hudh.bc.ugneta-wrap{width:min(620px,68vw);bottom:6px}
      #saga.ugneta-kort{grid-template-columns:36px minmax(0,1fr);padding:6px 9px!important}
      .ugneta-portratt{width:34px;height:34px}.ugneta-rubrik{font-size:14px}.ugneta-punkter{font-size:12px}
    }
  `;
  document.head.appendChild(st);
}

function ugnetaKort(meta,txt,dur){
  if(typeof document==="undefined")return false;
  installeraUgnetaUX();
  const s=document.getElementById("saga"); if(!s)return false;
  const wrap=s.closest(".hudh.bc"); if(wrap)wrap.classList.add("ugneta-wrap");
  s.className="on ugneta-kort "+(meta.ton||"");
  s.textContent="";
  const p=document.createElement("div"); p.className="ugneta-portratt";
  const h=document.createElement("i");h.className="ugneta-har";
  const g=document.createElement("i");g.className="ugneta-glas";p.append(h,g);
  const t=document.createElement("div");
  const n=document.createElement("div");n.className="ugneta-namn";n.textContent="Ugneta · ridinstruktör";
  const r=document.createElement("div");r.className="ugneta-rubrik";r.textContent=meta.rubrik||"Nästa steg";
  const ps=document.createElement("div");ps.className="ugneta-punkter";
  const punkter=(meta.punkter&&meta.punkter.length?meta.punkter:[txt]).slice(0,2);
  for(const rad of punkter){const d=document.createElement("div");d.className="ugneta-punkt";d.textContent=rad;ps.appendChild(d);}
  t.append(n,r,ps);s.append(p,t);
  if(typeof G!=="undefined")G.sagaT=dur||4;
  if(typeof ljudRost==="function")ljudRost(txt);
  return true;
}

/* game.js äger den vanliga saga()-funktionen. Vi behåller den för alla
   andra system och fångar bara den replik som lararSteg precis märkt
   som Ugneta. Därmed påverkas inte säkerhetsrop, stalltext eller UI. */
let UGNETA_ORIGINAL_SAGA=null;
function installeraUgnetaSaga(){
  if(typeof window==="undefined"||typeof saga!=="function"||UGNETA_ORIGINAL_SAGA)return;
  UGNETA_ORIGINAL_SAGA=saga;
  window.saga=function(txt,dur){
    const m=LARARE.ugnetaNasta;
    if(m&&m.txt===txt){LARARE.ugnetaNasta=null;ugnetaKort(m,txt,dur);return;}
    return UGNETA_ORIGINAL_SAGA(txt,dur);
  };
}

/* ── Övningen: vad ska eleven göra just nu? ───────────────────── */
function ugnetaOvning(){
  const m=G&&G.moment?G.moment:null;
  const id=String((m&&m.id)||"").toLowerCase();
  const namn=String((m&&m.namn)||"").toLowerCase();
  if(id.includes("halt_skritt")||namn.includes("halt")&&namn.includes("skritt"))
    return {rubrik:"Halt → skritt",punkter:["Titta dit du ska.","En tydlig skänkel — vänta på svaret."]};
  if(namn.includes("skritt")&&namn.includes("trav")&&!namn.includes("halt"))
    return {rubrik:"Skritt → trav",punkter:["Behåll lugn kontakt.","Driv en gång tydligt fram i trav."]};
  if(id.includes("storvolt")||namn.includes("20")&&namn.includes("volt"))
    return {rubrik:"20 m volt",punkter:["Titta runt volten.","Inre skänkel — yttre tygel håller storleken."]};
  if(namn.includes("hörn")||namn.includes("horn"))
    return {rubrik:"Rid genom hörnet",punkter:["Behåll samma rytm.","Balansera före hörnet — inte mitt i."]};
  if(id.includes("trav_skritt")||namn.includes("trav")&&namn.includes("skritt"))
    return {rubrik:"Trav → skritt",punkter:["Sitt ner och förbered.","Behåll skänkeln genom övergången."]};
  if(id.includes("galoppfattning")||namn.includes("galopp"))
    return {rubrik:"Galoppfattning",punkter:["Balansera först.","Be tydligt — och låt hästen svara."]};
  return null;
}

/* ── Fokusområden. Feedbacken är deterministisk från riddata. ── */
const FOKUS=[
  {id:"hand",namn:"Handen",
   vikt:f=>1-f.hand,
   bra:()=>{const t=G.aids?G.aids.tygel:0;return t>K.TYGEL_BAND_MIN&&t<K.TYGEL_BAND_MAX&&G.ride.mjukhet>0.62&&G.ride.skala.kontakt>0.45;},
   feedback:()=>{const t=G.aids?G.aids.tygel:0;if(t>=K.TYGEL_BAND_MAX)return "Lätta lite i handen.";if(t<=K.TYGEL_BAND_MIN)return "Ta en mjuk, jämn kontakt.";return "Håll handen still och mjuk.";},
   berom:()=>"Bra — kontakten blev mjuk och jämn."},
  {id:"sits",namn:"Sitsen",vikt:f=>1-f.sits,
   bra:()=>G.ride.mjukhet>0.72&&G.ride.spanning<0.45,
   feedback:()=>G.ride.spanning>0.5?"Släpp axlarna och sitt still.":"Följ rörelsen utan att kasta kroppen.",
   berom:()=>"Bra sits — hästen blev lugnare."},
  {id:"framat",namn:"Framåtbjudning",vikt:(f,h)=>0.55+0.45*(1-(h.framatbjudning||0.5))-0.30*f.sits,
   bra:()=>{const b=(typeof tempoBand==="function")&&tempoBand((G.moment&&G.moment.gangart)||G.ride.gangart,G.grupp);const ok=b?G.ride.tempo>=b.min&&G.ride.tempo<=b.max:G.ride.tempo>0.9;return ok&&G.ride.skala.schvung>0.40;},
   feedback:()=>{const b=(typeof tempoBand==="function")&&tempoBand((G.moment&&G.moment.gangart)||G.ride.gangart,G.grupp);if(b&&G.ride.tempo<b.min)return "En tydlig skänkel — vänta på svaret.";if(b&&G.ride.tempo>b.max)return "Sakta med sätet. Behåll rytmen.";return "Rid framåt utan att jaga.";},
   berom:()=>"Bra — jämn rytm och bättre framåtbjudning."},
  {id:"timing",namn:"Timingen",vikt:f=>1-f.kansla,
   bra:()=>G.ride.skala.samling>0.34,
   feedback:()=>"Förbered först. Be sedan en gång.",
   berom:()=>"Bra timing — du väntade på svaret."},
  {id:"lugn",namn:"Lugnet",vikt:(f,h)=>0.35+0.75*(h.kanslighet||0.5)-0.25*f.sits,
   bra:()=>G.ride.spanning<0.30,
   feedback:()=>G.ride.spanning>0.55?"Andas ut. Mjukna i hand och axlar.":"Behåll lugnet och låt hästen sträcka sig.",
   berom:()=>"Bra — spänningen sjönk."},
  {id:"vagen",namn:"Vägen",vikt:f=>0.45+0.35*(1-f.kansla),
   bra:()=>G.ride.skala.rakriktning>0.45,
   feedback:()=>"Titta dit du ska. Rid med kropp och skänkel.",
   berom:()=>"Bra väg — jämnare linje och balans."},
];

const LARARE={fokus:null,start:null,sagt:"",cd:0,brasedan:0,beromt:0,bytt:0,
  attributCd:0,upprepad:null,inled:false,bratid:0,tid:0,ugnetaNasta:null};

function lararNollstall(){
  LARARE.fokus=null;LARARE.start=null;LARARE.sagt="";LARARE.cd=0;LARARE.brasedan=0;
  LARARE.beromt=0;LARARE.bytt=0;LARARE.attributCd=0;LARARE.upprepad=null;
  LARARE.inled=false;LARARE.bratid=0;LARARE.tid=0;LARARE.ugnetaNasta=null;
}

function lararValjFokus(){
  const f=(typeof fard==="function")?fard():{sits:.3,hand:.3,kansla:.3,skotsel:.3};
  const h=HORSES[G.hastId]||{};const forra=(SPAR.historik&&SPAR.historik[0])||null;
  const forraOk=forra?(typeof forra.fokusAndel==="number"?forra.fokusAndel>=0.55:forra.snitt>=0.66):false;
  let bast=null,bastV=-99;
  for(let i=0;i<FOKUS.length;i++){
    const F=FOKUS[i];let v=F.vikt(f,h);
    if(forra&&forra.fokus===F.id)v+=forraOk?-0.30:0.22;
    /* Ingen slump i undervisningsvalet. Vid lika värde vinner ordningen. */
    if(v>bastV){bastV=v;bast=F;}
  }
  LARARE.fokus=bast;LARARE.start=bast;LARARE.upprepad=!!(forra&&forra.fokus===bast.id&&!forraOk);LARARE.inled=true;
  return bast;
}

function lararInledning(){
  const F=LARARE.fokus||lararValjFokus();
  if(LARARE.upprepad)return `Vi fortsätter med ${F.namn.toLowerCase()} från förra gången.`;
  return `Idag fokuserar vi på ${F.namn.toLowerCase()}.`;
}

function lararRad(lista){return Array.isArray(lista)&&lista.length?lista[0]:"";}

function lararMeddelande(txt,rubrik,punkter,ton){
  LARARE.sagt=txt;
  LARARE.ugnetaNasta={txt,rubrik:rubrik||"Ugneta",punkter:(punkter||[txt]).slice(0,2),ton:ton||""};
  return txt;
}

function lararSteg(dt){
  if(!G.ride||!LARARE.fokus)return "";
  const F=LARARE.fokus;LARARE.cd-=dt;LARARE.attributCd-=dt;

  if(LARARE.inled){
    LARARE.inled=false;LARARE.cd=12;
    const o=ugnetaOvning();
    if(o)return lararMeddelande(o.punkter.join(" "),o.rubrik,o.punkter,"");
    const t=lararInledning();
    return lararMeddelande(t,"Dagens fokus",[F.namn],"");
  }

  const bra=!!F.bra();LARARE.brasedan=bra?LARARE.brasedan+dt:0;LARARE.tid+=dt;if(bra)LARARE.bratid+=dt;

  /* Skilj hästens reaktion från elevens misstag när källan stödjer det. */
  if(LARARE.attributCd<=0&&G.ride.spanning>0.55){
    const h=HORSES[G.hastId]||{};const hastEgen=(h.skygghet||0)>0.28||G.dagsform<0.55;
    if(hastEgen){
      LARARE.attributCd=26;LARARE.cd=Math.max(LARARE.cd,7);
      const n=h.namn||"Hästen";
      const t=`Det där kom från ${n}.`;
      return lararMeddelande(t,"Lugn",[t,"Sitt still och rid vidare."],"");
    }
  }

  if(LARARE.brasedan>20&&LARARE.beromt<3){
    LARARE.brasedan=0;LARARE.beromt++;LARARE.cd=24;
    const t=F.berom();return lararMeddelande(t,"Bra!",[t],"bra");
  }

  if(LARARE.cd>0)return "";LARARE.cd=14;

  if(LARARE.beromt>=3&&LARARE.bytt<1&&bra&&LARARE.tid>210){
    LARARE.bytt++;
    const f=(typeof fard==="function")?fard():{sits:.3,hand:.3,kansla:.3,skotsel:.3};
    const h=HORSES[G.hastId]||{};let next=null,nv=-99;
    for(const x of FOKUS){if(x.id===F.id)continue;const v=x.vikt(f,h);if(v>nv){nv=v;next=x;}}
    LARARE.fokus=next||F;LARARE.beromt=0;LARARE.brasedan=0;
    const t=`${F.namn} sitter bättre.`;
    return lararMeddelande(t,"Nytt fokus",[t,`Nu: ${LARARE.fokus.namn}.`],"bra");
  }
  if(bra)return "";
  const t=F.feedback();
  return lararMeddelande(t,"Prova detta",[t],"");
}

function lararFokusId(){return LARARE.fokus?LARARE.fokus.id:null;}
function lararFokusNamn(){return LARARE.fokus?LARARE.fokus.namn:"";}
function lararDagensId(){return LARARE.start?LARARE.start.id:null;}
function lararAndel(){return LARARE.tid>4?LARARE.bratid/LARARE.tid:0;}

function lararOmdome(){
  if(!LARARE.start||LARARE.tid<8)return "";
  const n=LARARE.start.namn.toLowerCase(),a=lararAndel();
  if(LARARE.bytt>0)return `<b>${n}</b> blev tydligt bättre. Nästa pass går vi vidare.`;
  if(a>=0.62)return `<b>${n}</b> fungerade större delen av passet. Bra grund.`;
  if(a>=0.30)return `<b>${n}</b> fungerade ibland. Nästa gång tränar vi samma sak igen.`;
  return `<b>${n}</b> behöver mer tid. Vi tar en sak i taget nästa pass.`;
}

installeraUgnetaSaga();
