/* ══════════════════════════════════════════════════════════════════
   UGNETA — ridinstruktör för barn och ungdomar

   Pedagogisk regel:
   - en sak i taget
   - högst två korta punkter
   - feedback ska komma från faktisk riddata
   - beröm ska säga VAD som blev bättre
   - säkerhetsrop går fortfarande före all undervisning

   G02-C:
   - varje känt övningsförsök samlar samma telemetry som ridkärnan publicerar
   - kvalitetsmått är alltid 0–1 och högre är bättre
   - försök 2 jämförs med försök 1, aldrig med slump eller generiska poäng
   - 20 m volt: linje + rytm + balans
   - övergångar: timing + mjukhet + hästens respons

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
    .ugneta-knapp{margin-top:6px;display:inline-block;font-family:"IBM Plex Sans",system-ui,sans-serif;
      font-size:12px;font-weight:800;letter-spacing:.02em;color:#17140A;background:#E8B54A;
      border-radius:999px;padding:4px 11px}
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
    #momentText.ugneta-korttext{white-space:pre-line;max-width:52ch;line-height:1.35}
    @media(max-width:760px){#momentText.ugneta-korttext{font-size:13px;max-height:3.1em;overflow:hidden}}
    @media(max-width:560px){
      .hudh.bc.ugneta-wrap{width:94vw;bottom:8px}
      #saga.ugneta-kort{grid-template-columns:40px minmax(0,1fr);gap:8px;padding:8px 10px!important}
      .ugneta-portratt{width:38px;height:38px}
      .ugneta-har{height:15px}.ugneta-glas{left:5px;top:16px;transform:scale(.82);transform-origin:left top}
      .ugneta-knapp{margin-top:6px;display:inline-block;font-family:"IBM Plex Sans",system-ui,sans-serif;
      font-size:12px;font-weight:800;letter-spacing:.02em;color:#17140A;background:#E8B54A;
      border-radius:999px;padding:4px 11px}
    .ugneta-namn{font-size:9px}.ugneta-rubrik{font-size:15px}.ugneta-punkter{font-size:13px}
      #momentText.ugneta-korttext{display:none}
    }
    @media(max-height:560px) and (orientation:landscape){
      .hudh.bc.ugneta-wrap{width:min(620px,68vw);bottom:6px}
      #saga.ugneta-kort{grid-template-columns:36px minmax(0,1fr);padding:6px 9px!important}
      .ugneta-portratt{width:34px;height:34px}.ugneta-rubrik{font-size:14px}.ugneta-punkter{font-size:12px}
      #momentText.ugneta-korttext{display:none}
    }
  `;
  document.head.appendChild(st);
}

function ugnetaAterstallSagaUX(){
  if(typeof document==="undefined")return;
  const s=document.getElementById("saga");
  if(s)s.classList.remove("ugneta-kort","bra","sakerhet");
  const wrap=s&&s.closest(".hudh.bc");if(wrap)wrap.classList.remove("ugneta-wrap");
  /* Ett säkerhetsrop tar över hela lärarytan: live-chipet släcks också,
     annars kan "Bra rytm" stå kvar bredvid en varning. */
  const live=document.getElementById("ugnetaLive");
  if(live){live.className="";}
  LARARE.liveT=0;LARARE.liveSagt="";
}

function ugnetaKort(meta,txt,dur){
  if(typeof document==="undefined")return false;
  installeraUgnetaUX();
  const s=document.getElementById("saga"); if(!s)return false;
  const wrap=s.closest(".hudh.bc"); if(wrap)wrap.classList.add("ugneta-wrap");
  s.className="on ugneta-kort "+(meta.ton||"");
  s.setAttribute("role","status");s.setAttribute("aria-live","polite");
  s.setAttribute("aria-label","Ugneta, ridinstruktör");
  s.textContent="";
  const p=document.createElement("div"); p.className="ugneta-portratt";
  p.setAttribute("aria-hidden","true");
  const h=document.createElement("i");h.className="ugneta-har";
  const g=document.createElement("i");g.className="ugneta-glas";p.append(h,g);
  const t=document.createElement("div");
  const n=document.createElement("div");n.className="ugneta-namn";n.textContent="Ugneta · ridinstruktör";
  const r=document.createElement("div");r.className="ugneta-rubrik";r.textContent=meta.rubrik||"Nästa steg";
  const ps=document.createElement("div");ps.className="ugneta-punkter";
  const punkter=(meta.punkter&&meta.punkter.length?meta.punkter:[txt]).slice(0,2);
  for(const rad of punkter){const d=document.createElement("div");d.className="ugneta-punkt";d.textContent=rad;ps.appendChild(d);}
  t.append(n,r,ps);
  /* "Prova igen" är en tydlig uppmaning, inte en knapp som gör något
     eget: momentet startas om av lifecycle i game.js. Etiketten säger
     vad som faktiskt händer härnäst. */
  if(meta.knapp){
    const k=document.createElement("div");k.className="ugneta-knapp";k.textContent=meta.knapp;
    t.appendChild(k);
  }
  s.append(p,t);
  if(typeof G!=="undefined")G.sagaT=dur||4;
  if(typeof ljudRost==="function")ljudRost(txt);
  return true;
}

/* game.js äger saga(). Ugneta fångar bara lärarrepliken. Alla andra
   meddelanden återställs först så ett säkerhetsrop aldrig ser ut som Ugneta. */
let UGNETA_ORIGINAL_SAGA=null;
function installeraUgnetaSaga(){
  if(typeof window==="undefined"||typeof saga!=="function"||UGNETA_ORIGINAL_SAGA)return;
  UGNETA_ORIGINAL_SAGA=saga;
  window.saga=function(txt,dur){
    const m=LARARE.ugnetaNasta;
    if(m&&m.txt===txt){LARARE.ugnetaNasta=null;ugnetaKort(m,txt,dur);return;}
    ugnetaAterstallSagaUX();
    return UGNETA_ORIGINAL_SAGA(txt,dur);
  };
}

/* ── Övningen: vad ska eleven göra just nu? ───────────────────── */
/* Ugneta är närvarande när en lektion faktiskt pågår. Under tävling
   står en domare där i stället, och då ska hon inte dubbleras in. */
function ugnetaNarvarande(){
  if(typeof G==="undefined")return false;
  return G.scen==="lektion"&&!G.tavling&&!!G.moment;
}

/* Övningarnas ORDNING OCH TEXT på ett ställe. Låg tidigare inbakad i
   if-kedjan nedan, och en Roblox-modul som skulle undervisa samma sex
   övningar hade då fått skriva av dem. Nu exporteras listan till
   RidKanon.UGNETA.OVNINGAR och båda ytorna läser samma rader. */
const UGNETA_OVNINGAR=[
  {id:"halt_skritt",rubrik:"Halt → skritt",punkter:["Titta dit du ska.","En tydlig skänkel — vänta på svaret."]},
  {id:"skritt_trav",rubrik:"Skritt → trav",punkter:["Behåll lugn kontakt.","Driv en gång tydligt fram i trav."]},
  {id:"storvolt",rubrik:"20 m volt",punkter:["Titta runt volten.","Inre skänkel — yttre tygel håller storleken."]},
  {id:"horn",rubrik:"Rid genom hörnet",punkter:["Behåll samma rytm.","Balansera före hörnet — inte mitt i."]},
  {id:"trav_skritt",rubrik:"Trav → skritt",punkter:["Sitt ner och förbered.","Behåll skänkeln genom övergången."]},
  {id:"galoppfattning",rubrik:"Galoppfattning",punkter:["Balansera först.","Be tydligt — och låt hästen svara."]},
];
function ugnetaOvningMed(id){
  const o=UGNETA_OVNINGAR.find(x=>x.id===id);
  return o?{id:o.id,rubrik:o.rubrik,punkter:o.punkter.slice()}:null;
}
function ugnetaOvning(){return ugnetaOvningFor(G&&G.moment?G.moment:null);}
function ugnetaOvningFor(mIn){
  const m=mIn||null;
  const id=String((m&&m.ovning)||(m&&m.id)||"").toLowerCase();
  const namn=String((m&&m.namn)||"").toLowerCase();
  if(id.includes("halt_skritt")||namn.includes("halt")&&namn.includes("skritt"))
    return ugnetaOvningMed("halt_skritt");
  if(id.includes("skritt_trav")||namn.includes("skritt")&&namn.includes("trav")&&!namn.includes("halt")&&!namn.includes("trav–skritt"))
    return ugnetaOvningMed("skritt_trav");
  if(id.includes("storvolt")||namn.includes("20")&&namn.includes("volt"))
    return ugnetaOvningMed("storvolt");
  if(id.includes("horn")||id.includes("hörn")||namn.includes("hörn")||namn.includes("horn"))
    return ugnetaOvningMed("horn");
  if(id.includes("trav_skritt")||namn.includes("trav")&&namn.includes("skritt"))
    return ugnetaOvningMed("trav_skritt");
  if(id.includes("galoppfattning")||namn.includes("galopp"))
    return ugnetaOvningMed("galoppfattning");
  return null;
}

/* Momentpanelen är sekundär till ridningen. För G02-C:s sex moment byts
   äldre brödtext mot samma två punkter som Ugneta använder. */
let UGNETA_ORIGINAL_VISA_MOMENT=null;
function installeraUgnetaMoment(){
  if(typeof window==="undefined"||typeof visaMoment!=="function"||UGNETA_ORIGINAL_VISA_MOMENT)return;
  UGNETA_ORIGINAL_VISA_MOMENT=visaMoment;
  window.visaMoment=function(){
    UGNETA_ORIGINAL_VISA_MOMENT();
    const o=ugnetaOvning(),el=document.getElementById("momentText");
    if(el){el.classList.toggle("ugneta-korttext",!!o);if(o)el.textContent=o.punkter.map(x=>"• "+x).join("\n");}
  };
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

/* ══ UX-BESLUT 1 + 3 (Tobias 2026-09-06 på #119) ═══════════════════
   Två register, aldrig samma:

   LIVE, under ridning — bara när det verkligen behövs, och bara några
   ord: "Mjukare hand", "Bra rytm", "Precis så". Ingen panel, ingen
   ström, inget porträtt. Ridningen ska vinna över UI:t.

   MELLAN FÖRSÖKEN — här sker den riktiga pedagogiken. Efter försök 1:
   högst en sak som var bra, en att förbättra, och ett tydligt
   "Prova igen". Efter försök 2: en konkret jämförelse mot försök 1.

   Det som fanns före den här rundan var i praktiken variant 2: ett helt
   kort med porträtt, rubrik och två punkter mitt under ridningen.
   Tobias valde inte den. ═══════════════════════════════════════════ */

/* Övningar som rids i två försök. Bara G02-C:s sex kända övningar —
   en okänd övning ska inte tyst få en ny lifecycle. */
function ugnetaVillRepetera(moment,forsokNr){
  if(!moment||(forsokNr||1)>=2)return false;
  const o=ugnetaOvningFor(moment);
  return !!o;
}
/* Ett nytt försök nollställer försökets mätning explicit. Ingen sen
   patch av tillstånd efter att momentet byggts (läktarlärdomen, #114):
   ackumulatorn byts ut här, inte i nästa bildruta. */
function ugnetaNyttForsok(moment,forsokNr){
  const o=ugnetaOvningFor(moment);
  LARARE.aktivForsok=o?ugnetaTomForsok(o):null;
  LARARE.forsokNr=forsokNr||1;
  LARARE.liveCd=0;LARARE.liveSagt="";
}

/* ── Live-registret: kort cue, inget kort ─────────────────────── */
const UGNETA_LIVE={
  hand:{fel:"Mjukare hand",bra:"Mjuk hand"},
  framat:{fel:"Rid framåt",bra:"Bra rytm"},
  sits:{fel:"Sitt stilla",bra:"Bra sits"},
  lugn:{fel:"Andas ut",bra:"Fint lugn"},
  timing:{fel:"Vänta på svaret",bra:"Precis så"},
  vagen:{fel:"Titta dit du ska",bra:"Bra linje"},
};
/* Hur ofta hon säger något live, och hur länge chipet står kvar. Talen
   låg i lararSteg respektive ugnetaLive; de exporteras nu så att Roblox
   får samma tempo i stället för ett eget. */
const UGNETA_LIVE_CD={bra:14,fel:8,visa:2.6};
function ugnetaLiveText(fokusId,bra){
  const r=UGNETA_LIVE[fokusId];
  if(!r)return bra?"Precis så":"";
  return bra?r.bra:r.fel;
}
function installeraUgnetaLiveUX(){
  if(typeof document==="undefined"||document.getElementById("ugneta-live-style"))return;
  const st=document.createElement("style");
  st.id="ugneta-live-style";
  /* Chipet ligger uppe vid kanten, inte över ridvägen, och tar ingen
     plats i layouten. På låg skärm krymper det ytterligare — ridningen
     vinner alltid över UI:t. */
  st.textContent=`
    #ugnetaLive{position:fixed;left:50%;transform:translateX(-50%);top:calc(env(safe-area-inset-top,0px) + 10px);
      z-index:64;pointer-events:none;opacity:0;transition:opacity .22s ease;
      font-family:"IBM Plex Sans",-apple-system,system-ui,sans-serif;font-weight:700;
      font-size:14px;letter-spacing:.01em;line-height:1;color:#F6F2E8;
      background:rgba(12,14,18,.82);border:1px solid rgba(214,174,60,.5);
      border-radius:999px;padding:7px 14px;white-space:nowrap;
      box-shadow:0 6px 18px -8px rgba(0,0,0,.8)}
    #ugnetaLive.pa{opacity:1}
    #ugnetaLive.bra{border-color:rgba(140,196,120,.6);color:#E8F5E2}
    @media (max-height:520px){#ugnetaLive{font-size:12px;padding:5px 10px;top:6px}}
    @media (max-width:430px){#ugnetaLive{font-size:12.5px;padding:6px 11px}}`;
  document.head.appendChild(st);
  const el=document.createElement("div");
  el.id="ugnetaLive";el.setAttribute("role","status");el.setAttribute("aria-live","polite");
  el.setAttribute("aria-label","Ugneta säger");
  document.body.appendChild(el);
}
function ugnetaLive(txt,bra){
  if(typeof document==="undefined")return false;
  installeraUgnetaLiveUX();
  const el=document.getElementById("ugnetaLive");if(!el)return false;
  el.textContent=txt;
  el.className="pa"+(bra?" bra":"");
  LARARE.liveSagt=txt;LARARE.liveT=UGNETA_LIVE_CD.visa;
  return true;
}
function ugnetaLiveSteg(dt){
  if(typeof document==="undefined")return;
  if(LARARE.liveT>0){
    LARARE.liveT-=dt;
    if(LARARE.liveT<=0){const el=document.getElementById("ugnetaLive");if(el)el.className="";}
  }
}

/* ── Ugneta står vid sargen ───────────────────────────────────── */
/* Variant 1: hon är fysiskt närvarande i lektionen, inte bara en röst i
   ett HUD-kort. Samma punkt läses av 2D-kartan, 3D-vyn OCH Roblox, så
   det är EN sanning (läktarlärdomen: rendering och logik får inte ha
   var sin uppfattning om var något står).

   PLATSEN FLYTTADES FRÅN A TILL C i och med Roblox-gestalten. Skälet är
   inte estetiskt utan geometriskt, och det hör hemma här: webbens
   lektionsscen är en abstrakt 20 × 60-bana där det finns gott om plats
   1,4 m bortom kortsidan vid A — men i den VERIFIERADE byggnaden ligger
   banans A-ände 0,15 m från gavelväggen (roblox/buildings, R.bana.y).
   Där ryms ingen människa. Vid C är förhållandet det omvända: den
   fysiska ridytan fortsätter 5,5 m bortom dressyrlayoutens 60-m-linje,
   vilket DRESSYRBOKSTAVER redan dokumenterar för C ("layoutens
   60-m-linje ligger 5,5 m söder om sargen"). Punkten finns alltså på
   riktigt i huset, och verkligheten är facit — inte abstraktionen.

   [antagande] Att UBRF:s instruktör står just vid C är inte belagt i
   referensmaterialet. Det är ridbanans konvention (läraren vid kortsidan
   där hon ser hela ekipaget), och den ytan finns verifierat. Ersätts av
   verklig evidens när sådan finns. */
const UGNETA_PLATS={
  /* Andel av banbredden — 0,5 = mitt på kortsidan. */
  u:0.5,
  /* Meter bortom dressyrlayoutens C-linje. Positivt = utanför
     ridvägen, inne i den zon som fortsätter fram till norra sargen. */
  bortomC:1.4,
};
function ugnetaPlats(){
  /* Banans mått läses ur ridkanonen (RID_KANON.BANA_BREDD/LANGD) —
     samma tal som kollisionen och telemetrin använder. Ingen egen
     uppfattning om var sargen går. */
  const KB=(typeof ridKanon==="function")?ridKanon():null;
  const bredd=KB&&KB.BANA_BREDD?KB.BANA_BREDD:20;
  const langd=KB&&KB.BANA_LANGD?KB.BANA_LANGD:60;
  return {x:bredd*UGNETA_PLATS.u, y:langd+UGNETA_PLATS.bortomC, rikt:-Math.PI/2};
}

/* ── G02-C försök och kvalitetsbedömning ──────────────────────── */
const UGNETA_DIMENSIONER=["linje","rytm","balans","timing","mjukhet","respons","tempo"];
const UGNETA_DIM_LABEL={linje:"linjen",rytm:"rytmen",balans:"balansen",timing:"timingen",mjukhet:"mjukheten",respons:"hästens svar",tempo:"tempot"};
/* Vilka dimensioner bedöms i vilken övning.

   G02-D: de två övningar som har en VERSIONERAD definition i
   src/riding/ovningsdef.js hämtar sin lista därifrån i stället för att ha
   en andra kopia här. De övriga fyra har ingen definition ännu och står
   kvar oförändrade — en definition är ett produktbeslut per övning, inte
   något den här filen ska hitta på i förbifarten.

   Ordningen spelar roll: ugnetaForstaForsok rankar på VÄRDE, men
   fallbacken när inget är mätbart tar dims[0]. */
const UGNETA_OVNING_DIM={
  halt_skritt:["timing","mjukhet","respons"],
  skritt_trav:["timing","mjukhet","respons"],
  storvolt:ovningsMatt("storvolt"),
  horn:["rytm","balans","linje"],
  trav_skritt:ovningsMatt("trav_skritt"),
  galoppfattning:["timing","balans","respons"],
};
function ugClamp(v){return Math.max(0,Math.min(1,Number.isFinite(v)?v:0));}
/* KVALITETENS TAL, samlade. De låg tidigare inbakade i formeln nedan,
   vilket gjorde dem omöjliga att exportera — och en Roblox-modul som
   skrev av dem för hand hade blivit en andra sanning. Nu står de här,
   webben läser dem härifrån, och tools/exportera-ridkanon.mjs skickar
   samma tal till RidKanon.UGNETA.KVALITET. */
const UGNETA_KVALITET={
  VOLT_RADIE:10, VOLT_SPANN:7,          // 20 m volt = 10 m radie
  LINJE_RADIE:0.65, LINJE_RAK:0.35,
  SVARSTID_TAK:0.55, ETABLERING_TAK:2.6,
  TIMING_SVAR:0.40, TIMING_ETABLERING:0.40, TIMING_PARAD:0.20,
  RESPONS_FOKUS:0.40, RESPONS_LUGN:0.35, RESPONS_SVAR:0.25,
  TEMPO_GOLV:0.15, TEMPO_NAMNARE:0.8,
  OMATT:0.5,                            // varken beröm eller kritik
  /* Trösklarna som avgör VAD Ugneta säger efter ett försök. Låg tidigare
     som literaler i ugnetaJamfor/ugnetaForstaForsok — och som avskrivna
     kopior i Ugneta.luau. Nu står de en gång. */
  BATTRE:0.045,                         // så mycket ska en dimension ha stigit
  SVAG:0.68,                            // under detta är den värd att nämna
  BRA:0.55,                             // över detta är den värd att berömma
};
/* Vilken live-cue hör till vilken dimension? Ordförrådet är detsamma på
   båda ytorna (UGNETA_LIVE), och kopplingen dimension → cue står här så
   att Roblox kan välja samma ord för samma brist.

   DEKLARERAD SKILLNAD, inte en smygande: webben VÄLJER cue ur passets
   fokus (LARARE.fokus), för den har en ryttarmodell (`fard()`) att välja
   fokus ur. Roblox har ingen sådan modell ännu och väljer i stället ur
   den svagaste MÄTTA dimensionen i övningens kontrakt. Olika ingång,
   samma ordförråd och samma tabell — och skillnaden står i
   HorseCore/Lektion.SKILLNAD så den inte kan glömmas bort. */
const UGNETA_DIM_CUE={linje:"vagen",rytm:"framat",balans:"sits",
  timing:"timing",mjukhet:"hand",respons:"lugn",tempo:"framat"};
/* ETT MÄTVÄRDE, ELLER INGET.

   G02-D-specen: "If a metric is unavailable, say so or use a valid
   qualitative observation; do not turn missing data into a neutral or
   positive score."

   `ugTal` skiljer saknat, NaN och oändlighet från en uppmätt nolla —
   samma disciplin som `tal()` i HorseCore/Lektion.luau, som Roblox fick
   i #128 och webben aldrig fick. Osymmetrin var mätbar i den byggda
   sidan: en ritt utan mätvärden gav linje/rytm/balans/mjukhet = 0
   (sämsta betyg) och samtidigt tempo = 1,0 (full pott). Samma tomma
   försök kunde alltså både sågas på fyra dimensioner och berömmas på en,
   och Ugneta kunde säga "Bra tempot" om en ritt hon aldrig sett.

   FORMLERNA ÄR OFÖRÄNDRADE. Det som tillkommit är kravet på underlag. */
function ugTal(v){
  const n=typeof v==="number"?v:Number(v);
  return Number.isFinite(n)?n:null;
}
/* Fanns minst ett delvärde? En sammansatt dimension bedöms bara om
   någon av dess beståndsdelar faktiskt mättes. */
function ugNagot(){
  for(let i=0;i<arguments.length;i++)if(arguments[i]!==null)return true;
  return false;
}

function ugnetaKvalitet(){
  const UK=UGNETA_KVALITET;
  const tm=(typeof G!=="undefined"&&G.telemetri)||{};
  const r=(typeof G!=="undefined"&&G.ride)||{};
  const s=r.skala||{};

  const rakriktning=ugTal(s.rakriktning);
  const rad=ugTal(tm.svangradie);
  /* Radien: mätt svängradie först, annars rakriktningen som ersättare —
     men saknas BÅDA finns ingen linje att bedöma. */
  const radie=rad!==null?ugClamp(1-Math.abs(rad-UK.VOLT_RADIE)/UK.VOLT_SPANN)
    :(rakriktning!==null?ugClamp(rakriktning):null);
  const linje=(radie===null&&rakriktning===null)?null
    :ugClamp(UK.LINJE_RADIE*(radie===null?0:radie)
      +UK.LINJE_RAK*(rakriktning===null?0:ugClamp(rakriktning)));

  const takt=ugTal(s.takt);
  const rytm=takt===null?null:ugClamp(takt);

  const balansT=ugTal(tm.balans!==undefined?tm.balans:r.balans);
  const balans=balansT===null?null:ugClamp(balansT);

  const mjukT=ugTal(tm.mjukhet!==undefined?tm.mjukhet:r.mjukhet);
  const mjukhet=mjukT===null?null:ugClamp(mjukT);

  const fokusT=ugTal(tm.fokus!==undefined?tm.fokus:r.fokus);
  const spanT=ugTal(tm.spanning!==undefined?tm.spanning:r.spanning);
  const fokus=fokusT===null?null:ugClamp(fokusT);
  const lugn=spanT===null?null:1-ugClamp(spanT);

  /* Tiderna: 0 betyder "ingen övergång mätt", inte "svarade omedelbart".
     Det var redan avsikten (`tm.svarstid>0`), men fallbacken var OMATT —
     ett tal mitt emellan som såg ut som ett betyg. Nu är den null. */
  const svarT=ugTal(tm.svarstid);
  const svar=(svarT!==null&&svarT>0)?ugClamp(1-svarT/UK.SVARSTID_TAK):null;
  const etabT=ugTal(tm.etableringstid);
  const etablering=(etabT!==null&&etabT>0)?ugClamp(1-etabT/UK.ETABLERING_TAK):null;
  const paradT=ugTal(tm.paradKvalitet);
  const parad=paradT===null?null:ugClamp(paradT);

  const timing=ugNagot(svar,etablering,parad)
    ?ugClamp(UK.TIMING_SVAR*(svar||0)+UK.TIMING_ETABLERING*(etablering||0)
      +UK.TIMING_PARAD*(parad||0)):null;
  const respons=ugNagot(fokus,lugn,svar)
    ?ugClamp(UK.RESPONS_FOKUS*(fokus||0)+UK.RESPONS_LUGN*(lugn||0)
      +UK.RESPONS_SVAR*(svar||0)):null;

  /* Tempot krävde förut ingenting alls och gav 1,0 när önskad fart
     saknades — den enskilt värsta raden i den gamla funktionen. Nu krävs
     både en mätt fart OCH en mätt önskad fart. */
  const fart=ugTal(tm.fart!==undefined?tm.fart:r.tempo);
  const onskad=ugTal(tm.onskadFart);
  const tempo=(fart===null||onskad===null||!(onskad>UK.TEMPO_GOLV))?null
    :ugClamp(1-Math.abs(fart-onskad)/Math.max(onskad,UK.TEMPO_NAMNARE));

  return {linje,rytm,balans,timing,mjukhet,respons,tempo};
}
/* Ett försök räknar numera PER DIMENSION: summa, antal sampel och
   uppmätta sekunder. Förut fanns bara ett gemensamt `n`, och en dimension
   som aldrig kunde mätas fick ändå dela nämnare med dem som mättes hela
   tiden — vilket är samma sak som att kalla ett hål för en nolla. */
function ugnetaTomForsok(o){
  const sum={},antal={},sek={};
  for(const k of UGNETA_DIMENSIONER){sum[k]=0;antal[k]=0;sek[k]=0;}
  return {id:o.id,momentIx:G.momentIx,n:0,sum,antal,sek,klar:false};
}
/* Medelvärdet för de dimensioner som HAR underlag. Övriga blir null.

   Kravet är Roblox-sidans, via ovningsdef.OVNING_GILTIG: minst två sampel
   OCH minst en uppmätt sekund. Sekunder och inte bildrutor, så att 120 fps
   inte ger fyra gånger så mycket underlag som 30. */
function ugnetaForsokMedel(a){
  const KRAV=(typeof OVNING_GILTIG!=="undefined")?OVNING_GILTIG:{MIN_MATNINGAR:2,MIN_SEK:1.0};
  const ut={};
  for(const k in a.sum){
    const n=a.antal?a.antal[k]:a.n, sek=a.sek?a.sek[k]:0;
    ut[k]=(n>=KRAV.MIN_MATNINGAR&&sek>=KRAV.MIN_SEK)?a.sum[k]/n:null;
  }
  return ut;
}
/* Kortet när försöket inte gick att bedöma. Sanningen är ett bättre
   besked än ett påhittat betyg — och samma svar som Roblox-sidan ger
   (LektionController: "Försöket kunde inte bedömas"). */
function ugnetaEjBedomt(nr){
  return {rubrik:"Försöket kunde inte bedömas",
    punkter:["Det fanns inte tillräckligt mätt underlag den här gången."],
    ton:"", forsok:nr||1, knapp:(nr||1)<2?"Prova igen":"Nästa övning"};
}
function ugnetaJamfor(id,fore,nu,nr){
  const dims=UGNETA_OVNING_DIM[id]||["rytm","balans","mjukhet"];
  /* Bara dimensioner som mättes i BÅDA försöken går att jämföra. Att
     jämföra ett mätvärde mot ett hål är att hitta på en förbättring
     eller en försämring som ingen har sett. */
  const d=dims.filter(k=>nu[k]!==null&&nu[k]!==undefined
      &&fore[k]!==null&&fore[k]!==undefined)
    .map(k=>({k,d:nu[k]-fore[k],v:nu[k]})).sort((a,b)=>b.d-a.d);
  /* Dimensioner som mättes NU men inte förra gången går inte att
     jämföra, men de går att beskriva. */
  const bara=dims.filter(k=>nu[k]!==null&&nu[k]!==undefined
      &&(fore[k]===null||fore[k]===undefined))
    .map(k=>({k,v:nu[k]})).sort((a,b)=>a.v-b.v);
  if(!d.length&&!bara.length)return ugnetaEjBedomt(nr);
  const punkter=[];
  const upp=d.find(x=>x.d>=UGNETA_KVALITET.BATTRE);
  if(upp)punkter.push(`Bättre ${UGNETA_DIM_LABEL[upp.k]} den här gången.`);
  const kandidater=[...d,...bara].sort((a,b)=>a.v-b.v);
  const kvar=kandidater.find(x=>!upp||x.k!==upp.k);
  if(kvar&&kvar.v<UGNETA_KVALITET.SVAG)punkter.push(`Fortsätt med ${UGNETA_DIM_LABEL[kvar.k]}.`);
  if(!punkter.length)punkter.push("Jämnare försök. Behåll samma känsla.");
  return {rubrik:`Försök ${nr}`,punkter:punkter.slice(0,2),ton:upp?"bra":""};
}
/* EFTER FÖRSÖK 1 (UX-variant 3): högst en sak som var bra, en att
   förbättra, och ett tydligt "Prova igen". Båda punkterna kommer ur
   försökets egna mätvärden — den starkaste och den svagaste dimensionen
   i övningens kontrakt. Inget påhittat procenttal, ingen slumptext. */
function ugnetaForstaForsok(id,medel){
  const dims=UGNETA_OVNING_DIM[id]||["rytm","balans","mjukhet"];
  /* Endast MÄTTA dimensioner rankas. En obedömd dimension får varken bli
     "bäst" (falskt beröm) eller "sämst" (falsk kritik). */
  const rank=dims.filter(k=>medel[k]!==null&&medel[k]!==undefined)
    .map(k=>({k,v:medel[k]})).sort((a,b)=>b.v-a.v);
  if(!rank.length)return ugnetaEjBedomt(1);
  const bast=rank[0], samst=rank[rank.length-1];
  const punkter=[];
  if(bast&&bast.v>=UGNETA_KVALITET.BRA)punkter.push(`Bra ${UGNETA_DIM_LABEL[bast.k]}.`);
  if(samst&&(!bast||samst.k!==bast.k))punkter.push(`Jobba på ${UGNETA_DIM_LABEL[samst.k]}.`);
  if(!punkter.length)punkter.push(`Jobba på ${UGNETA_DIM_LABEL[rank[0].k]}.`);
  return {rubrik:"Prova igen",punkter:punkter.slice(0,2),ton:"",
    forsok:1,knapp:"Prova igen"};
}

/* ── G02-D: INSPELNINGEN AV FÖRSÖKET ────────────────────────────────
   Ritten skrivs ned EN gång och återanvänds för uppspelning och
   jämförelse. Bedömningen ligger kvar i ugnetaKvalitet() — inspelningen
   är ett vittne, inte en andra domare.

   Startar när ett försök startar, avslutas när försöket avslutas, och
   posten följer med försöket in i historiken så att "spela upp mitt förra
   försök" betyder just det försöket och inte något annat. */
function ugnetaSpelaIn(){
  return (typeof Inspelning!=="undefined")?(LARARE.inspelare||(LARARE.inspelare=new Inspelning())):null;
}
function ugnetaInspelningStarta(o){
  const ins=ugnetaSpelaIn();if(!ins)return;
  const d=(typeof ovningsDef==="function")?ovningsDef(o.id):null;
  /* Bara övningar med en VERSIONERAD definition spelas in. G02-D:s första
     leverans är 20 m volten och en övergång; de fyra övriga har ingen
     definition ännu, och en post utan version kan varken läsas tillbaka
     säkert eller jämföras — `inspelningLasbar` skulle avvisa den som
     okänd övning. Att spela in något vi inte kan analysera vore just den
     tysta meningslösa datan specen varnar för.

     Upptäckt av replay-provet: lektionens första G02-övning är
     `halt_skritt`, inte volten, så utan det här villkoret blev den
     allra första posten oläsbar av sin egen kontroll. */
  if(!d){if(ins.aktiv)ins.avsluta();return;}
  const h=(typeof HORSES!=="undefined"&&G.hastId)?HORSES[G.hastId]:null;
  ins.starta(o.id,G.hastId||null,(h&&h.profil)||null,
    {gangart:(G.ride&&G.ride.gangart)||null,fart:(G.ride&&G.ride.tempo)||null,
     x:G.px,y:G.py,kurs:G.rikt},
    d?d.version:null);
}
function ugnetaInspelningSampla(dt){
  const ins=LARARE.inspelare;if(!ins||!ins.aktiv)return;
  const tm=G.telemetri||{},r=G.ride||{};
  ins.sampla(dt,{
    x:G.px,y:G.py,kurs:G.rikt,
    gangart:r.gangart,fas:tm.rytm,fart:tm.fart!==undefined?tm.fart:r.tempo,
    kurvatur:tm.kurvatur,balans:tm.balans!==undefined?tm.balans:r.balans,
    hjalper:tm.hjalper||null,
  });
}

function ugnetaForsokAvsluta(){
  const a=LARARE.aktivForsok;if(!a||a.klar||a.n<2)return null;
  a.klar=true;const medel=ugnetaForsokMedel(a);
  /* Posten hämtas ur inspelaren och läggs i försöket. Finns ingen
     inspelare (äldre bygge, eller modulen inte laddad) blir den null —
     jämförelsen och återkopplingen fungerar ändå, de har aldrig behövt
     inspelningen. */
  const ins=LARARE.inspelare;
  medel.__post=(ins&&ins.aktiv)?ins.avsluta():null;
  const lista=LARARE.forsok[a.id]||(LARARE.forsok[a.id]=[]);lista.push(medel);
  /* Första försöket får sin egen återkoppling i stället för tystnad —
     det är den som ska leda fram till försök 2. */
  if(lista.length<2)return ugnetaForstaForsok(a.id,medel);
  return ugnetaJamfor(a.id,lista[lista.length-2],lista[lista.length-1],lista.length);
}
function ugnetaForsokSteg(dt){
  const o=ugnetaOvning();
  if(!o){if(LARARE.aktivForsok)ugnetaForsokAvsluta();LARARE.aktivForsok=null;return;}
  if(!LARARE.aktivForsok||LARARE.aktivForsok.id!==o.id||LARARE.aktivForsok.momentIx!==G.momentIx){
    const j=ugnetaForsokAvsluta();if(j)LARARE.vantaFeedback=j;
    LARARE.aktivForsok=ugnetaTomForsok(o);
    ugnetaInspelningStarta(o);
  }
  const q=ugnetaKvalitet(),a=LARARE.aktivForsok;a.n++;
  /* Bara uppmätta värden räknas — med sin egen nämnare och sin egen tid.
     `dt` kan saknas i äldre anropsvägar; då räknas sampel men inga
     sekunder, och dimensionen blir obedömd i stället för att smyga in på
     ett antagande om bildrutetakt. */
  const dsek=(typeof dt==="number"&&isFinite(dt)&&dt>0&&dt<0.5)?dt:0;
  for(const k in a.sum){
    if(q[k]===null||q[k]===undefined)continue;
    a.sum[k]+=q[k];a.antal[k]++;a.sek[k]+=dsek;
  }
  ugnetaInspelningSampla(dt);
  const m=G.moment||{};
  if(G.momentKlart||G.momentT>=((m.tid||0)*2.2)){const j=ugnetaForsokAvsluta();if(j)LARARE.vantaFeedback=j;}
}
/* Posten för ett tidigare försök — 1 är det första. Returnerar null när
   försöket inte finns eller inte spelades in, aldrig ett tomt objekt som
   ser ut som en ritt. */
function ugnetaForsokPost(id,nr){
  const lista=ugnetaForsokHistorik(id);
  const a=lista[(nr||lista.length)-1];
  return (a&&a.__post)||null;
}
function ugnetaForsokHistorik(id){return (LARARE.forsok&&LARARE.forsok[id])||[];}

const LARARE={fokus:null,start:null,sagt:"",cd:0,brasedan:0,beromt:0,bytt:0,
  attributCd:0,upprepad:null,inled:false,bratid:0,tid:0,ugnetaNasta:null,
  forsok:Object.create(null),aktivForsok:null,vantaFeedback:null,inspelare:null,
  forsokNr:1,liveT:0,liveCd:0,liveSagt:""};

function lararNollstall(){
  LARARE.fokus=null;LARARE.start=null;LARARE.sagt="";LARARE.cd=0;LARARE.brasedan=0;
  LARARE.beromt=0;LARARE.bytt=0;LARARE.attributCd=0;LARARE.upprepad=null;
  LARARE.inled=false;LARARE.bratid=0;LARARE.tid=0;LARARE.ugnetaNasta=null;
  LARARE.forsok=Object.create(null);LARARE.aktivForsok=null;LARARE.vantaFeedback=null;
  /* Inspelaren nollställs med resten: en avbruten ritt får inte lämna en
     halv post som nästa lektion råkar avsluta och lägga i historiken. */
  if(LARARE.inspelare)LARARE.inspelare.avsluta();
}

function lararValjFokus(){
  const f=(typeof fard==="function")?fard():{sits:.3,hand:.3,kansla:.3,skotsel:.3};
  const h=HORSES[G.hastId]||{};const forra=(SPAR.historik&&SPAR.historik[0])||null;
  const forraOk=forra?(typeof forra.fokusAndel==="number"?forra.fokusAndel>=0.55:forra.snitt>=0.66):false;
  let bast=null,bastV=-99;
  for(let i=0;i<FOKUS.length;i++){
    const F=FOKUS[i];let v=F.vikt(f,h);
    if(forra&&forra.fokus===F.id)v+=forraOk?-0.30:0.22;
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
function lararMeddelande(txt,rubrik,punkter,ton,extra){
  LARARE.sagt=txt;
  LARARE.ugnetaNasta={txt,rubrik:rubrik||"Ugneta",
    punkter:(punkter||[txt]).slice(0,2),ton:ton||"",
    knapp:(extra&&extra.knapp)||null};
  return txt;
}

function lararSteg(dt){
  if(!G.ride||!LARARE.fokus)return "";
  ugnetaForsokSteg(dt);
  ugnetaLiveSteg(dt);
  const F=LARARE.fokus;LARARE.cd-=dt;LARARE.attributCd-=dt;LARARE.liveCd-=dt;

  /* MELLAN FÖRSÖKEN — här, och bara här, visas hela kortet. Efter
     försök 1 en bra + en att förbättra + "Prova igen"; efter försök 2
     jämförelsen mot försök 1. Det är den pedagogiska återkopplingen. */
  if(LARARE.vantaFeedback){
    const j=LARARE.vantaFeedback;LARARE.vantaFeedback=null;LARARE.inled=false;LARARE.cd=12;
    const txt=j.punkter.join(" ");return lararMeddelande(txt,j.rubrik,j.punkter,j.ton,j);
  }

  if(LARARE.inled){
    LARARE.inled=false;LARARE.cd=12;
    const o=ugnetaOvning();
    if(o)return lararMeddelande(o.punkter.join(" "),o.rubrik,o.punkter,"");
    const t=lararInledning();return lararMeddelande(t,"Dagens fokus",[F.namn],"");
  }

  const bra=!!F.bra();LARARE.brasedan=bra?LARARE.brasedan+dt:0;LARARE.tid+=dt;if(bra)LARARE.bratid+=dt;

  /* LIVE-REGISTRET — under aktiv ridning säger hon några ord, inte ett
     kort. Bara när något faktiskt behöver sägas, och aldrig samma sak
     två gånger i rad. Ridningen ska vinna över UI:t. */
  if(ugnetaNarvarande()&&LARARE.liveCd<=0){
    const txt=ugnetaLiveText(F.id,bra&&LARARE.brasedan>6);
    if(txt&&txt!==LARARE.liveSagt){
      LARARE.liveCd=bra?UGNETA_LIVE_CD.bra:UGNETA_LIVE_CD.fel;
      ugnetaLive(txt,bra);
      return "";
    }
  }

  if(LARARE.attributCd<=0&&G.ride.spanning>0.55){
    const h=HORSES[G.hastId]||{};const hastEgen=(h.skygghet||0)>0.28||G.dagsform<0.55;
    if(hastEgen){
      LARARE.attributCd=26;LARARE.cd=Math.max(LARARE.cd,7);
      const n=h.namn||"Hästen",t=`Det där kom från ${n}.`;
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
    const t=`${F.namn} sitter bättre.`;return lararMeddelande(t,"Nytt fokus",[t,`Nu: ${LARARE.fokus.namn}.`],"bra");
  }
  if(bra)return "";
  const t=F.feedback();return lararMeddelande(t,"Prova detta",[t],"");
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
installeraUgnetaMoment();
