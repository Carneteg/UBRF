/* ══════════════════════════════════════════════════════════════════
   TÄVLINGEN — steg 7: klubbtävlingen som säsongsmål.
   Påskhoppet rids i ridhuset med klasser, startordning och publik
   på läktaren; dressyr LC rids på uteridbanan med domare vid C och
   protokoll i procent. Startfältet är ridskolans egna ekipage och
   deras rundor simuleras genom samma slumpkälla som hoppmodellen.
   Rosetterna följer svensk färgordning — 1:a blågul, 2:a blå,
   3:a röd, 4:a vit, 5:a grön — och sparas med resultatlistan i
   klubbrummet. En tävling ger ingen uppflyttning: rosetten är lönen.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const TAVLINGSKLASSER=[
  {id:1, namn:"Klass 1 · 0,60 m", hojd:0.60},
  {id:2, namn:"Klass 2 · 0,75 m", hojd:0.75},
  {id:3, namn:"Klass 3 · 0,85 m", hojd:0.85},
];
const ROSETTER=[
  {namn:"1:a pris", farg:"#2F5C8F", farg2:"#E8C33C"},
  {namn:"2:a pris", farg:"#2F5C8F"},
  {namn:"3:e pris", farg:"#C0392B"},
  {namn:"4:e pris", farg:"#E8E4DA"},
  {namn:"5:e pris", farg:"#3E6E4E"},
];

/* Guider för dressyrprogrammets egna moment (banskissen). */
OVNINGSGUIDE.halsning={typ:"punkter", p:[[10,58.5],[10,30]]};
OVNINGSGUIDE.halsning2={typ:"punkter", p:[[10,30],[10,1.5]]};
OVNINGSGUIDE.friskritt={typ:"diagonal", fran:[18.2,54], till:[1.8,6]};

/* Startfältet: ridskolans ekipage utom din häst. */
function startfalt(){
  const F=[["Alva","lydia",.62],["Vera","air",.48],["Hugo","cosmo",.71],
    ["Elsa","lady",.55],["Molly","westside",.66],["Ines","larry",.74]];
  return F.filter(([,hast])=>hast!==G.hastId)
    .map(([namn,hast,skick])=>({namn,hast,skick}));
}

/* Simulerade rundor: skickliga ryttare river mindre, höga klasser mer. */
function simHopp(f,klass,seed){
  const rng=Approach.rng(seed*977+Math.round(f.skick*100)+klass.id*31);
  const hcap=HORSES[f.hast]?HORSES[f.hast].maxhojd:0.8;
  let fel=0;
  for(let i=0;i<6;i++){
    const p=clamp(0.30-0.28*f.skick+(klass.hojd-0.60)*0.9+(klass.hojd>hcap?0.25:0),0.02,0.75);
    if(rng()<p)fel+=4;
  }
  const ute=rng()<clamp(0.08-0.07*f.skick+(klass.hojd>hcap?0.15:0),0.01,0.3);
  const tid=Math.round((84-f.skick*12+rng()*14)*10)/10;
  return {fel,tid,ute};
}
function simDressyr(f,seed){
  const rng=Approach.rng(seed*769+Math.round(f.skick*100));
  return Math.round((55+f.skick*15+(rng()*8-4))*10)/10;
}

/* ── Tävlingsvalet från menyn ─────────────────────────────────── */
function visaTavlingsval(){
  const gIdx=GRUPPSTEGE.indexOf(G.grupp);
  const hopp=gIdx>=8, dressyr=gIdx>=5;
  overlay(true,`
  <span class="lbl">Klubbtävling · anmälan i sekretariatet</span>
  <h1 style="margin-top:8px">Tävlingsdag på UBRF</h1>
  <p class="dim" style="font-size:13.5px">Du rider den häst ridläraren ger dig, och hela stalldagen
  gäller som vanligt: hämta, mocka, fodra, sköta. Domarna ser allt — även det som hände före ritten.</p>
  <div style="margin-top:14px">
    <div class="lbl" style="margin-bottom:6px">Påskhoppet — bedömning A, i ridhuset</div>
    ${hopp?`<div style="display:flex;gap:8px;flex-wrap:wrap">
      ${TAVLINGSKLASSER.map(k2=>`<button class="btn ghost tav-klass" data-k="${k2.id}"
        style="padding:9px 14px">${k2.namn}</button>`).join("")}</div>`
      :`<p class="dim" style="font-size:13px">Rids av hoppgruppen. Du rider i ${GRUPPNAMN[G.grupp]||G.grupp} —
        vägen dit går genom lektionerna.</p>`}
    <div class="lbl" style="margin:14px 0 6px">Dressyr LC — på uteridbanan</div>
    ${dressyr?`<button class="btn ghost" id="bTavDress" style="padding:9px 14px">Starta i Dressyr LC</button>`
      :`<p class="dim" style="font-size:13px">Öppen från grupp 3. Programmet kräver säkra fattningar.</p>`}
  </div>
  <div class="btnrow"><button class="btn ghost" id="bTavTillbaka">Tillbaka</button></div>`);
  for(const b of document.querySelectorAll(".tav-klass"))
    b.onclick=()=>{
      G.tavling={typ:"hoppning", klass:TAVLINGSKLASSER.find(k2=>k2.id===+b.dataset.k)};
      startaVandring();
    };
  const bd=document.getElementById("bTavDress");
  if(bd)bd.onclick=()=>{G.tavling={typ:"dressyr"};startaVandring();};
  document.getElementById("bTavTillbaka").onclick=visaMeny;
}

/* ── Uppsittning — ett ställe för alla tre platserna ──────────── */
function sittUpp(plats){
  if(G.tavling){
    const ratt=G.tavling.typ==="hoppning"?"ridhus":"utebana";
    if(plats!==ratt){
      saga(G.tavling.typ==="hoppning"
        ?"Tävlingsdag — Påskhoppet rids i ridhuset. Led honom dit."
        :"Tävlingsdag — dressyren rids på uteridbanan. Led honom dit.",4);
      return;
    }
    G.plats=plats;
    visaSekretariat(()=>{G.leder=false;hudLage("ritt");startaLektion();
      ridSittUpp(G.hastId,plats);});   // G02-A: samma tillstånd på tävlingsvägen
    return;
  }
  G.leder=false;G.plats=plats;hudLage("ritt");startaLektion();
  ridSittUpp(G.hastId,plats);          // G02-A: uppsutten som tillstånd, inte bara scen
}

/* ── Sekretariatet: startordningen ropas upp ──────────────────── */
function visaSekretariat(vidare){
  const t=G.tavling, falt=startfalt();
  const plats=(G.seed+SPAR.pass)%(falt.length+1);
  const lista=[...falt.slice(0,plats),{namn:"Du",hast:G.hastId,du:true},...falt.slice(plats)];
  const rubrik=t.typ==="hoppning"?`Påskhoppet · ${t.klass.namn}`:"Dressyr LC · uteridbanan";
  const rad=(f,i)=>`<tr${f.du?' style="color:var(--gold-2);font-weight:600"':""}>
    <td>${i+1}</td><td>${f.namn}${f.du?" (DU)":""}</td>
    <td class="num">${HORSES[f.hast]?HORSES[f.hast].namn:f.hast}</td></tr>`;
  overlay(true,`
  <span class="lbl">Sekretariatet · ${rubrik}</span>
  <h1 style="margin-top:8px">Startordning</h1>
  <table style="margin-top:8px"><tbody>
    <tr><td class="lbl">Nr</td><td class="lbl">Ryttare</td><td class="lbl" style="text-align:right">Häst</td></tr>
    ${lista.map(rad).join("")}
  </tbody></table>
  <p class="dim" style="font-size:13.5px;margin-top:10px">${t.typ==="hoppning"
    ?"Publiken har satt sig på läktaren och sorlet lägger sig när klockan ringer. Banan får besiktigas till fots — sedan är framridningen din."
    :"Domaren sitter i kuren vid C. När klockan ringer har du en minut på dig att komma in på medellinjen."}</p>
  <div class="btnrow"><button class="btn" id="bTillStart">Framridning — till start</button></div>`);
  document.getElementById("bTillStart").onclick=()=>{overlay(false);vidare();};
}

/* ── Tävlingsprogrammen ───────────────────────────────────────── */
function byggTavlingsprogram(t){
  if(t.typ==="hoppning"){
    BANA.hojd=t.klass.hojd;
    const hcm=Math.round(t.klass.hojd*100);
    return [
      {id:"skritt", namn:"Framridning i skritt", tid:18, bedoms:false, ovning:"langtygel",
       text:"Skritta fram hästen på framridningen. Andas — det är samma ridning som hemma."},
      {id:"framridning", namn:"Framridning i trav och galopp", tid:30, bedoms:false, ovning:"storvolt",
       text:"Trav och galopp på storvolt. Känn av dagsformen innan klockan ringer."},
      {id:"bana", namn:t.klass.namn, tid:0, bedoms:true, ovning:"ridvagar",
       text:`Din tur. Sex hinder på ${hcm} cm — rid vägen, inte hindret. Publiken sköter sig själv.`},
    ];
  }
  return [
    {id:"halsning", namn:"Halt och hälsning på medellinjen", tid:14, bedoms:true, ovning:"halsning",
     text:"In vid A i skritt, halt vid X. Hälsa på domaren — ta god tid på dig."},
    {id:"storvolt", namn:"Trav, stora volten", tid:32, bedoms:true, ovning:"storvolt",
     text:"Arbetstrav på stora volten. Rund volt, jämn takt — det är det domaren tittar på."},
    {id:"serpentin", namn:"Serpentin genom banan", tid:32, bedoms:true, ovning:"serpentin",
     text:"Serpentin, tre bågar. Byt böjning över medellinjen och behåll takten."},
    {id:"friskritt", namn:"Fri skritt på lång tygel", tid:24, bedoms:true, ovning:"friskritt",
     text:"Fri skritt över diagonalen. Ge tygeln — sträcker han sig framåt-nedåt är poängen din."},
    {id:"galoppfattning", namn:"Galoppfattning och storvolt", tid:30, bedoms:true, ovning:"galoppfattning",
     text:"Fatta galopp i hörnet och rid storvolt. Ren fattning väger tyngst."},
    {id:"halsning2", namn:"Avslutande halt och hälsning", tid:12, bedoms:true, ovning:"halsning2",
     text:"Åter på medellinjen, halt och hälsning. Programmet är slut — klappa om hästen."},
  ];
}

/* ── Resultatet: placeringar, rosett och sparad lista ─────────── */
function visaTavlingsResultat(dom){
  const t=G.tavling, h=HORSES[G.hastId];
  const inv=Object.values(G.betyg);
  const snitt=inv.length?inv.reduce((a,b)=>a+b,0)/inv.length:0;
  const seed=G.seed*7+SPAR.pass, falt=startfalt();
  let rader, resultatText;
  if(t.typ==="hoppning"){
    rader=falt.map((f,i)=>({...f,...simHopp(f,t.klass,seed+i)}));
    rader.push({namn:"Du",hast:G.hastId,du:true,
      fel:dom.totalfel, tid:Math.round(dom.tid*10)/10, ute:dom.utesluten});
    rader.sort((a,b)=>(a.ute-b.ute)||(a.fel-b.fel)||(a.tid-b.tid));
  }else{
    rader=falt.map((f,i)=>({...f,proc:simDressyr(f,seed+i)}));
    rader.push({namn:"Du",hast:G.hastId,du:true,proc:Math.round(snitt*1000)/10});
    rader.sort((a,b)=>b.proc-a.proc);
  }
  const plac=rader.findIndex(r=>r.du)+1;
  const uteJag=t.typ==="hoppning"&&dom.utesluten;
  const ro=!uteJag&&plac<=5?ROSETTER[plac-1]:null;
  const tavNamn=t.typ==="hoppning"?`Påskhoppet · ${t.klass.namn}`:"Dressyr LC";
  resultatText=t.typ==="hoppning"
    ?(uteJag?"uteslutning":`${dom.totalfel} fel · ${String(Math.round(dom.tid*10)/10).replace(".",",")} s`)
    :`${String(Math.round(snitt*1000)/10).replace(".",",")} %`;
  SPAR.rosetter=SPAR.rosetter||[];
  SPAR.rosetter.push({tavling:tavNamn, hast:G.hastId, plac:uteJag?0:plac,
    resultat:resultatText, pass:SPAR.pass});
  sparaRyttare();
  const rad=(r,i)=>`<tr${r.du?' style="color:var(--gold-2);font-weight:600"':""}>
    <td>${t.typ==="hoppning"&&r.ute?"—":i+1}</td>
    <td>${r.namn}${r.du?" (DU)":""} · ${HORSES[r.hast]?HORSES[r.hast].namn:r.hast}</td>
    <td class="num">${t.typ==="hoppning"
      ?(r.ute?"UTESL.":`${r.fel} fel · ${String(r.tid).replace(".",",")} s`)
      :r.proc.toFixed(1).replace(".",",")+" %"}</td></tr>`;
  const momRows=t.typ==="dressyr"
    ?Object.keys(G.betyg).map(k2=>{const m=(G.lektion||[]).find(x=>x.id===k2);
      return `<tr><td>${m?m.namn:k2}</td><td class="num">${(G.betyg[k2]*10).toFixed(1).replace(".",",")}</td></tr>`;}).join("")
    :"";
  const omdome=uteJag?`Inte er dag. ${h.namn} förtjänar en lugn hemritt — och du en ny chans nästa tävling.`
    :plac===1?`Ni vann. ${h.namn} visste om det innan resultatet lästes upp.`
    :plac<=3?`Placerade! Rosetten hängs på ${h.namn}s boxdörr — han har förtjänat den lika mycket som du.`
    :plac<=5?`En rosett på första försöket är inget att fnysa åt. Vidare mot nästa.`
    :`Ingen rosett i dag — men ridningen håller. Domarna såg samma sak som jag.`;
  overlay(true,`
  <span class="lbl">${tavNamn} · resultat</span>
  <h1 style="margin-top:8px">”${omdome}”</h1>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-top:10px">
    <div>
      <div class="lbl" style="margin-bottom:6px">Resultatlista</div>
      <table><tbody>${rader.map(rad).join("")}</tbody></table>
    </div>
    <div>
      ${ro?`<div class="note" style="display:flex;align-items:center;gap:14px">
        ${rosettHTML(ro)}<span><b class="gold">${ro.namn}.</b><br>
        <span class="dim" style="font-size:12.5px">Rosetten hängs i klubbrummet — och på boxdörren.</span></span></div>`
        :`<div class="note dim" style="font-size:13px">Rosett till placering 1–5. ${uteJag?"Uteslutna placeras inte.":"Din placering: "+plac+" av "+rader.length+"."}</div>`}
      ${t.typ==="hoppning"
        ?`<div class="lbl" style="margin:12px 0 6px">Protokoll — bedömning A</div>
          <ul style="font-size:12.5px;font-family:'IBM Plex Mono',monospace;line-height:1.7">${
            dom.protokoll.map(r2=>`<li>${r2}</li>`).join("")||"<li>Felfri runda.</li>"}</ul>`
        :`<div class="lbl" style="margin:12px 0 6px">Protokoll — betyg per moment (0–10)</div>
          <table><tbody>${momRows}
          <tr><td><b style="color:var(--ink)">Totalt</b></td>
          <td class="num">${(snitt*100).toFixed(1).replace(".",",")} %</td></tr></tbody></table>`}
    </div>
  </div>
  <div class="btnrow"><button class="btn" id="bTavKlar">Tillbaka till stallet</button></div>`);
  document.getElementById("bTavKlar").onclick=()=>{
    G.seed++;nollstall();
    G.hastId=null;G.skotselRes=null;overlay(false);hudLage("gang");
    gaTill("stallinne",{x:7.5,y:40,rikt:-Math.PI/2});
    saga(ro?"Rosetten sitter på boxdörren. Resultatlistan hänger i klubbrummet.":"Resultatlistan hänger i klubbrummet. Nästa tävling kommer.",4);
  };
}

/* Rosettmärket som HTML (resultat och klubbrum). */
function rosettHTML(ro,liten){
  const d=liten?24:44;
  return `<span style="display:inline-flex;flex-direction:column;align-items:center;flex:none">
    <span style="width:${d}px;height:${d}px;border-radius:50%;
      background:radial-gradient(circle, ${ro.farg2||ro.farg} 0 36%, ${ro.farg} 36% 100%);
      border:2px solid rgba(0,0,0,.35)"></span>
    <span style="display:flex;gap:${Math.max(2,d*0.07)}px;margin-top:-2px">
      <span style="width:${d*0.16}px;height:${d*0.5}px;background:${ro.farg}"></span>
      <span style="width:${d*0.16}px;height:${d*0.5}px;background:${ro.farg2||ro.farg}"></span>
    </span></span>`;
}
/* Hästens finaste rosett — för boxdörren. */
function hastRosett(id){
  if(!id||!SPAR||!SPAR.rosetter)return null;
  let bast=null;
  for(const r of SPAR.rosetter)
    if(r.hast===id&&r.plac>=1&&r.plac<=5&&(bast===null||r.plac<bast))bast=r.plac;
  return bast?ROSETTER[bast-1]:null;
}

/* ── Klubbrummet: rosettväggen och resultatlistan ─────────────── */
function visaKlubbrum(){
  const ros=(SPAR&&SPAR.rosetter)||[];
  if(!ros.length){
    saga("Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Rosettväggen är tom ännu — klubbtävlingen väntar.",4.5);
    return;
  }
  const rad=r=>`<tr>
    <td style="width:34px">${r.plac>=1&&r.plac<=5?rosettHTML(ROSETTER[r.plac-1],true):'<span class="dim">—</span>'}</td>
    <td>${r.tavling}<br><span class="dim" style="font-size:12px">${HORSES[r.hast]?HORSES[r.hast].namn:r.hast} · pass ${r.pass}</span></td>
    <td class="num">${r.plac===0?"utesl.":r.plac+":a"}<br><span class="dim" style="font-size:12px">${r.resultat}</span></td></tr>`;
  overlay(true,`
  <span class="lbl">Klubbrummet · rosettväggen</span>
  <h1 style="margin-top:8px">Resultat att peka på</h1>
  <table style="margin-top:8px"><tbody>${ros.slice().reverse().map(rad).join("")}</tbody></table>
  <p class="dim" style="font-size:13px;margin-top:10px">Rosetterna sitter kvar mellan passen — och hästens finaste hänger på boxdörren.</p>
  <div class="btnrow"><button class="btn" id="bKlubbOk">Tillbaka till stallet</button></div>`);
  document.getElementById("bKlubbOk").onclick=()=>overlay(false);
}
