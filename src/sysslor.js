/* ══════════════════════════════════════════════════════════════════
   STALLSYSSLORNA — steg 2: boxen är ditt ansvar, inte bara sadeln.
   Vid hästens box väljer du: mocka, fodra och vattna, eller göra
   i ordning för lektion. Sysslorna påverkar stallron, och stallron
   påverkar både skötselresultatet och hästen under ridningen —
   samma kedja som på en riktig ridskola. Foderschemat sitter i
   plastfickan på boxdörren, precis som på fotona.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* Foderschema per häst: hö (kg), kraftfoder, och en rad ur verkligheten. */
const FODERSCHEMA={
  toblerone:{ho:2, kraft:"inget", notis:"Lättfödd fjording — inget kraftfoder, han blir rund av luft."},
  cosmo:    {ho:3, kraft:"müsli", notis:"Stor kropp, stort jobb — full giva."},
  air:      {ho:2, kraft:"betfor", notis:"Betfor blötläggs. Han sörplar."},
  larry:    {ho:3, kraft:"müsli", notis:"Hoppar bäst med bränsle i tanken."},
  hamilton: {ho:2, kraft:"müsli", notis:"Känslig mage — müslin ska vara blötlagd."},
  conor:    {ho:2, kraft:"betfor", notis:"Lugn mat till en känslig häst."},
  crokino:  {ho:3, kraft:"pellets", notis:"Stor häst, standardgiva."},
  lydia:    {ho:2, kraft:"inget", notis:"Barnponny på dietlista sedan i våras."},
  dexter:   {ho:2, kraft:"pellets", notis:"Mer fart än foder — snåla med pelletsen."},
  lady:     {ho:2, kraft:"inget", notis:"Welsh cob på gräns till rund — höet räcker gott."},
  chip:     {ho:1, kraft:"inget", notis:"Russ. Ge honom mer och han rullar till lektionen."},
  tina:     {ho:2, kraft:"betfor", notis:"Blötlagd betfor — och stå på hennes vänstra sida."},
  westside: {ho:3, kraft:"pellets", notis:"Stor kropp, standardgiva, inga konstigheter."},
  makadu:   {ho:3, kraft:"betfor", notis:"Äter lugnt. Gjorda om honom EFTER fodringen."},
  mara:     {ho:2, kraft:"müsli", notis:"Sur min vid krubban är normalläge. Ge och backa."},
  husky:    {ho:3, kraft:"müsli", notis:"Bränner allt han får — full giva."},
  kennedy:  {ho:2, kraft:"müsli", notis:"Unghäst under uppbyggnad — müslin blötläggs."},
};
const KRAFTVAL=["inget","müsli","betfor","pellets"];

/* ── Sadelkammaren ────────────────────────────────────────────────
   Varje ridskolehäst har sin egen sadel på egen bygel och sitt träns
   på egen krok, båda med namnskylt. Att hämta rätt utrustning är
   första handgreppet — fel sadel passar inte ryggen den ska ligga på.
   ── */
function visaSadelkammare(){
  if(!G.hastId){
    saga("Sadelkammaren: sadelbyglar i två rader, träns på krokar och en vit pegboard med putsgrejer. Du hämtar din utrustning när du fått veta vilken häst du rider.",5);
    return;
  }
  const h=HORSES[G.hastId];
  /* Åtta byglar runt din häst — samma urval varje gång för samma frö. */
  const alla=Object.keys(HORSES);
  const mig=alla.indexOf(G.hastId);
  const grannar=[];
  for(let i=0;i<8;i++)grannar.push(alla[(mig+i+alla.length-3)%alla.length]);
  if(!grannar.includes(G.hastId))grannar[3]=G.hastId;
  const bygel=(id,typ)=>`<button class="btn ghost sk-val" data-typ="${typ}" data-id="${id}"
    style="padding:8px 12px;font-size:12.5px;font-family:'IBM Plex Mono',monospace">${HORSES[id].namn}</button>`;
  overlay(true,`
  <span class="lbl">Sadelkammaren · innanför uppehållsrummet</span>
  <h1 style="margin-top:6px">Din sadel, ditt träns</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">Varje häst har sin egen sadel på egen bygel — en sadel som
  passar en annan rygg gör ingen nytta på ${h.namn}s. Namnskyltarna sitter på byglarna.</p>
  <div style="margin-top:14px">
    <div class="lbl" style="margin-bottom:6px">Sadelbyglarna</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${grannar.map(id=>bygel(id,"sadel")).join("")}</div>
    <div class="lbl" style="margin:14px 0 6px">Tränskrokarna</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${grannar.map(id=>bygel(id,"trans")).join("")}</div>
  </div>
  <div class="note" id="skStatus" style="font-size:13px;margin-top:14px">
    Du rider <b style="color:var(--ink)">${h.namn}</b> i dag. Ta hans sadel och hans träns.</div>
  <div class="btnrow">
    <button class="btn" id="bSkKlar">Ta med utrustningen</button>
    <button class="btn ghost" id="bSkStang">Stäng</button>
  </div>`);
  const val={sadel:null,trans:null};
  if(!document.getElementById("skStil")){
    const st=document.createElement("style");st.id="skStil";
    st.textContent=`.sk-val.sk-pa{background:var(--gold);color:#17140A;border-color:var(--gold)}`;
    document.head.appendChild(st);
  }
  for(const b of document.querySelectorAll(".sk-val"))
    b.onclick=()=>{
      const typ=b.dataset.typ; val[typ]=b.dataset.id;
      for(const b2 of document.querySelectorAll(`.sk-val[data-typ="${typ}"]`))
        b2.classList.toggle("sk-pa",b2===b);
    };
  document.getElementById("bSkStang").onclick=()=>overlay(false);
  document.getElementById("bSkKlar").onclick=()=>{
    const st=document.getElementById("skStatus");
    if(!val.sadel||!val.trans){
      st.className="note bad";st.style.fontSize="13px";
      st.textContent="Ta både sadel och träns — de hänger på var sin plats.";
      return;
    }
    if(val.sadel!==G.hastId||val.trans!==G.hastId){
      const fel=[val.sadel!==G.hastId?"sadeln":null,val.trans!==G.hastId?"tränset":null]
        .filter(Boolean).join(" och ");
      st.className="note bad";st.style.fontSize="13px";
      /* Varför det spelar roll, inte bara att det är fel. En elev som
         bara får "fel" lär sig leta efter rätt namn; en som får skälet
         lär sig varför namnskylten finns. */
      const varfor=val.sadel!==G.hastId
        ? `En sadel är formad efter en bestämd rygg. På fel häst trycker den
           antingen på manken eller på njurarna, och då kan ${h.namn} inte gå
           igenom ryggen hur bra du än rider.`
        : `Ett träns är inställt efter ett bestämt huvud. På fel häst hamnar
           bettet för högt eller för lågt i munnen och skaver i mungiporna.`;
      st.innerHTML=`Fel ${fel}. Det där är <b>${HORSES[val.sadel!==G.hastId?val.sadel:val.trans].namn}</b>s.
        ${varfor} Läs namnskylten en gång till — ${h.namn}s hänger på sin egen plats.`;
      G.felUtrustning=(G.felUtrustning||0)+1;
      return;
    }
    G.utrustning=true;
    saga(`Sadel, träns och ryktväska med dig. ${h.namn} väntar i boxen.`,3.5);
    overlay(false);
  };
}

/* ── Spolspiltan ──────────────────────────────────────────────────
   Hästar som stått i hagen kommer in leriga, särskilt när det regnat.
   Leran spolas av innan skötseln — genom lera går det varken att
   visitera eller borsta, och lera under sadelgjorden ger skav.
   ── */
const SP={zoner:[],slang:false,cv:null,cx:null,sista:null};
const SPOLZONER=[[0.44,0.72],[0.49,0.74],[0.68,0.74],[0.735,0.72],
                 [0.46,0.85],[0.70,0.85],[0.57,0.66],[0.62,0.63]];
function visaSpolning(){
  const h=HORSES[G.hastId];
  SP.zoner=SPOLZONER.map(()=>0);SP.slang=false;SP.sista=null;
  overlay(true,`
  <span class="lbl">Spolspiltan · gummimattor och slangvinda</span>
  <h1 style="margin-top:6px">Spola av leran</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">Ta slangen och dra över benen och magen —
  nerifrån och upp, ljummet vatten. Genom lera går det varken att visitera eller borsta ${h.namn} ordentligt.</p>
  <canvas id="spolCanvas" style="width:100%;aspect-ratio:16/9;background:var(--sunk);
    border:1px solid var(--rule);border-radius:3px;cursor:crosshair;touch-action:none;display:block"></canvas>
  <div class="btnrow">
    <span class="lbl" id="spolStatus" style="letter-spacing:.08em"></span>
    <button class="btn" id="bSpolKlar">Tillbaka till stallgången</button>
  </div>`);
  SP.cv=document.getElementById("spolCanvas");SP.cx=SP.cv.getContext("2d");
  const fit=()=>{const r=SP.cv.getBoundingClientRect();
    SP.cv.width=r.width*DPR;SP.cv.height=r.height*DPR;
    SP.cx.setTransform(DPR,0,0,DPR,0,0);ritaSpolning();};
  fit();new ResizeObserver(fit).observe(SP.cv);
  const pos=e=>{const r=SP.cv.getBoundingClientRect();
    return[(e.clientX-r.left)/r.width,(e.clientY-r.top)/r.height];};
  const dra=p=>{
    const[x,y]=p;
    for(let i=0;i<SPOLZONER.length;i++){
      const[zx,zy]=SPOLZONER[i];
      if(Math.hypot(x-zx,y-zy)<0.075)SP.zoner[i]=Math.min(1,SP.zoner[i]+0.16);
    }
    uppdSpol();ritaSpolning();
  };
  SP.cv.addEventListener("pointerdown",e=>{SP.slang=true;dra(pos(e));e.preventDefault();});
  SP.cv.addEventListener("pointermove",e=>{if(SP.slang)dra(pos(e));});
  addEventListener("pointerup",()=>{SP.slang=false;});
  document.getElementById("bSpolKlar").onclick=()=>{
    G.spolad=SP.zoner.reduce((a,b)=>a+b,0)/SP.zoner.length;
    if(G.spolad>=0.8){G.lerig=false;
      saga(`${h.namn} skakar av sig vattnet och ser ut som en häst igen.`,3.5);}
    else saga("Det sitter lera kvar. Ridläraren kommer att se den.",3.5);
    overlay(false);
  };
  uppdSpol();
}
function uppdSpol(){
  const kvar=SP.zoner.filter(v=>v<0.99).length;
  document.getElementById("spolStatus").textContent=
    kvar?`${SP.zoner.length-kvar} / ${SP.zoner.length} områden rena`:"Ren. Skrapa av vattnet och gå ut.";
}
function ritaSpolning(){
  const c=SP.cx,W=SP.cv.clientWidth,H=SP.cv.clientHeight,h=HORSES[G.hastId];
  c.clearRect(0,0,W,H);
  // spiltan: kompositplank i galvade ramar, gummimatta på golvet
  const gr=c.createLinearGradient(0,0,0,H);
  gr.addColorStop(0,"#3E4247");gr.addColorStop(0.70,"#4A4E53");
  gr.addColorStop(0.71,"#37383A");gr.addColorStop(1,"#2E2F31");
  c.fillStyle=gr;c.fillRect(0,0,W,H);
  c.strokeStyle="rgba(255,255,255,.05)";c.lineWidth=1;
  for(let i=1;i<7;i++){c.beginPath();c.moveTo(0,H*0.10*i);c.lineTo(W,H*0.10*i);c.stroke();}
  // slangvinda och blandare på väggen
  c.strokeStyle="#8E939B";c.lineWidth=3;
  c.beginPath();c.arc(W*0.09,H*0.15,W*0.035,0,Math.PI*2);c.stroke();
  c.strokeStyle="#C4622E";c.lineWidth=4;
  c.beginPath();c.moveTo(W*0.09,H*0.19);
  c.quadraticCurveTo(W*0.12,H*0.62,W*0.30,H*0.84);c.stroke();
  c.fillStyle="#8E939B";                                   // strålmunstycket
  c.beginPath();c.ellipse(W*0.305,H*0.845,W*0.012,H*0.02,0.7,0,Math.PI*2);c.fill();
  ritaHastSida(c,W*0.55,H*0.88,H*0.52,-1,h.farg,h.man,{pose:"sta"});
  // leran och det avspolade
  for(let i=0;i<SPOLZONER.length;i++){
    const[zx,zy]=SPOLZONER[i], v=SP.zoner[i];
    c.fillStyle=v>=0.99?"rgba(127,180,137,.40)"
      :`rgba(92,74,52,${0.72-0.55*v})`;
    c.beginPath();c.arc(W*zx,H*zy,W*0.036,0,Math.PI*2);c.fill();
  }
  // vattenpöl på mattan
  c.fillStyle="rgba(120,150,170,.16)";
  const blott=SP.zoner.reduce((a,b)=>a+b,0)/SP.zoner.length;
  c.beginPath();c.ellipse(W*0.56,H*0.93,W*0.20*blott+W*0.04,H*0.035,0,0,Math.PI*2);c.fill();
}

/* ── Boxmenyn ─────────────────────────────────────────────────── */
function visaBoxmeny(){
  const h=HORSES[G.hastId];
  const s=G.sysslor||(G.sysslor={mockat:0,fodrat:0});
  const bock=v=>v>=0.99?'<span class="grn">✓ klart</span>'
    :v>0?`<span class="gold">${Math.round(v*100)} %</span>`:'<span class="dim">—</span>';
  overlay(true,`
  <span class="lbl">${h.namn}s box · foderschemat sitter på dörren</span>
  <h1 style="margin-top:8px">Boxen först, sadeln sen</h1>
  <p class="dim" style="font-size:13.5px">Stallro byggs i boxen: en mockad box och rätt
  foder ger en lugnare häst på lektionen. Ridläraren ser om du slarvar.</p>
  <div style="display:grid;gap:10px;margin-top:14px">
    ${G.tackePa?`<button class="btn ghost" id="bTacke" style="justify-content:space-between;width:100%">
      <span>0 · Ta av täcket och häng upp det</span><span class="gold">täcket är på</span></button>`:""}
    <button class="btn ghost" id="bMocka" style="justify-content:space-between;width:100%">
      <span>1 · Mocka boxen</span><span>${bock(s.mockat)}</span></button>
    <button class="btn ghost" id="bFodra" style="justify-content:space-between;width:100%">
      <span>2 · Fodra och vattna</span><span>${bock(s.fodrat)}</span></button>
    <button class="btn" id="bSkots" style="justify-content:space-between;width:100%">
      <span>3 · Visitera, rykta, kratsa, sadla</span>
      <span>${G.utrustning?"":'<span class="gold">sadeln saknas</span>'}</span></button>
  </div>
  <div class="btnrow"><button class="btn ghost" id="bStang">Stäng</button></div>`);
  const bT=document.getElementById("bTacke");
  if(bT)bT.onclick=()=>{G.tackePa=false;
    saga("Täcket av och upphängt över boxkanten. Han skakar på sig.",3);visaBoxmeny();};
  document.getElementById("bMocka").onclick=visaMockning;
  document.getElementById("bFodra").onclick=visaFodring;
  document.getElementById("bSkots").onclick=()=>{
    if(G.tackePa){saga("Täcket hänger i vägen — ta av det först.",3);return;}
    if(!G.utrustning){overlay(false);
      saga(`Du har varken sadel eller träns här. ${h.namn}s hänger på sin bygel i sadelkammaren, innanför uppehållsrummet.`,4.5);
      return;}
    visaSkotsel();};
  document.getElementById("bStang").onclick=()=>overlay(false);
}

/* ── Whiteboarden — dagens schema som checklista ─────────────── */
function visaSchema(){
  const s=G.sysslor||{mockat:0,fodrat:0};
  const v=G.vader||{typ:"sol",temp:12,tacke:false};
  const vtxt={sol:"Sol",mulet:"Mulet",regn:"Regn"}[v.typ]+` · ${v.temp} °C`
    +(v.tacke?" — hästarna går med täcke":"");
  const hast=G.hastId?HORSES[G.hastId].namn:"—";
  const rad=(klar,txt)=>`<li style="display:flex;gap:10px;align-items:baseline">
    <span class="${klar?'grn':'dim'}" style="font-family:'IBM Plex Mono',monospace">${klar?"✓":"○"}</span>
    <span class="${klar?'':'dim'}">${txt}</span></li>`;
  overlay(true,`
  <span class="lbl">Whiteboarden i servicedelen · dagens schema</span>
  <h1 style="margin-top:8px">${vtxt}</h1>
  <p class="dim" style="font-size:13.5px">Din häst i dag: <b style="color:var(--ink)">${hast}</b>.
  Schemat gäller tills lektionen börjar — ridläraren bockar av resten.</p>
  <ul style="list-style:none;padding:0;margin:14px 0;display:grid;gap:9px;font-size:14.5px">
    ${rad(!!G.hastId,"Prata med ridläraren — dagens häst")}
    ${rad(!!G.hamtad,"Hämta hästen i hagen och led till boxen")}
    ${G.lerig||G.spolad>0?rad(!G.lerig,"Spola av leriga ben i spolspiltan"):""}
    ${v.tacke?rad(G.hamtad&&!G.tackePa,"Ta av täcket och häng upp det"):""}
    ${rad(!!G.utrustning,"Hämta sadel och träns i sadelkammaren")}
    ${rad(s.mockat>=0.99,"Mocka boxen och strö nytt spån")}
    ${rad(s.fodrat>=0.99,"Fodra och vattna efter schemat")}
    ${rad(!!G.skotselRes,"Visitera, rykta, kratsa och sadla")}
    ${rad(false,"Lektion — sitt upp vid sargporten i ridhuset")}
  </ul>
  ${(()=>{ // hörnet av tavlan: hästar som inte går i dag
    const hand=(typeof dagensHandelser==="function")?dagensHandelser():{};
    const rader=Object.entries(hand)
      .map(([id,e])=>`<li><b style="color:var(--ink)">${HORSES[id]?HORSES[id].namn:id}</b> — ${e.text}</li>`);
    return rader.length?`<div class="note" style="font-size:13px">
      <b class="lbl" style="display:block;margin-bottom:4px;color:var(--gold-2)">Går ej i dag</b>
      <ul style="list-style:none;padding:0;margin:0;display:grid;gap:4px">${rader.join("")}</ul></div>`:"";
  })()}
  <div class="btnrow"><button class="btn" id="bSchemaOk">Tillbaka till stallet</button></div>`);
  document.getElementById("bSchemaOk").onclick=()=>overlay(false);
}

/* ── Mockningen — plocka högarna, strö nytt ──────────────────── */
const MO={hogar:[],kvar:0,strott:false,cv:null,cx:null};
function visaMockning(){
  const h=HORSES[G.hastId];
  overlay(true,`
  <span class="lbl">Mocka · ${h.namn}s box</span>
  <h1 style="margin-top:6px">Grepen i högarna, inte i spånet</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">Tryck på varje hög för att skyffla
  den i kärran. Strö nytt när boxen är ren.</p>
  <canvas id="mockCanvas" style="width:100%;aspect-ratio:16/9;background:var(--sunk);
    border:1px solid var(--rule);border-radius:3px;cursor:pointer;touch-action:none;display:block"></canvas>
  <div class="btnrow">
    <span class="lbl" id="mockStatus" style="letter-spacing:.08em"></span>
    <button class="btn ghost" id="bStro" disabled>Strö nytt spån</button>
    <button class="btn" id="bMockKlar">Tillbaka till boxen</button>
  </div>`);
  // 7 högar, deterministiskt utspridda per häst
  let seed=0;for(const c of G.hastId)seed=seed*31+c.charCodeAt(0);
  MO.hogar=[];MO.strott=false;
  for(let i=0;i<7;i++){
    seed=(seed*16807)%2147483647;
    const a=(seed%1000)/1000; seed=(seed*16807)%2147483647;
    const b=(seed%1000)/1000;
    MO.hogar.push({x:0.12+a*0.76,y:0.35+b*0.5,tag:false});
  }
  MO.kvar=7;
  MO.cv=document.getElementById("mockCanvas");MO.cx=MO.cv.getContext("2d");
  const fit=()=>{const r=MO.cv.getBoundingClientRect();
    MO.cv.width=r.width*DPR;MO.cv.height=r.height*DPR;
    MO.cx.setTransform(DPR,0,0,DPR,0,0);ritaMock();};
  fit();new ResizeObserver(fit).observe(MO.cv);
  MO.cv.addEventListener("pointerdown",e=>{
    const r=MO.cv.getBoundingClientRect();
    const x=(e.clientX-r.left)/r.width,y=(e.clientY-r.top)/r.height;
    for(const hog of MO.hogar){
      if(!hog.tag&&Math.hypot(x-hog.x,y-hog.y)<0.075){hog.tag=true;MO.kvar--;}}
    uppdMock();ritaMock();e.preventDefault();});
  document.getElementById("bStro").onclick=()=>{MO.strott=true;uppdMock();ritaMock();};
  document.getElementById("bMockKlar").onclick=()=>{sparaMock();visaBoxmeny();};
  uppdMock();
}
function uppdMock(){
  document.getElementById("mockStatus").textContent=
    MO.kvar>0?`${7-MO.kvar} / 7 högar i kärran`
    :MO.strott?"Rent och nystrött. Fint.":"Rent! Strö nytt spån.";
  document.getElementById("bStro").disabled=MO.kvar>0||MO.strott;
}
function sparaMock(){
  const s=G.sysslor||(G.sysslor={mockat:0,fodrat:0});
  s.mockat=Math.max(s.mockat,clamp((7-MO.kvar)/7*(MO.strott?1:0.8),0,1));
}
function ritaMock(){
  const c=MO.cx,W=MO.cv.clientWidth,H=MO.cv.clientHeight;
  c.clearRect(0,0,W,H);
  // boxen: väggar och spån
  c.fillStyle="#4A4D50";c.fillRect(0,0,W,H*0.28);            // boxvägg (komposit)
  c.fillStyle="#9CA0A4";c.fillRect(0,H*0.27,W,H*0.015);      // galvad överliggare
  c.fillStyle=MO.strott?"#E4D8B8":"#D6C9A4";                 // spånbädd
  c.fillRect(0,H*0.285,W,H*0.715);
  c.fillStyle="rgba(0,0,0,.05)";
  for(let i=0;i<24;i++){const a=(i*97)%W,b2=H*0.3+((i*53)%(H*0.65));
    c.fillRect(a,b2,14,3);}
  // krubba och hink i hörnet
  c.fillStyle="#3E6E4E";c.fillRect(W*0.02,H*0.30,W*0.10,H*0.10);
  c.fillStyle="#2F5C8F";c.beginPath();c.arc(W*0.965,H*0.36,W*0.028,0,Math.PI*2);c.fill();
  // högarna
  for(const hog of MO.hogar){
    if(hog.tag)continue;
    c.fillStyle="#5A4A34";
    c.beginPath();c.ellipse(hog.x*W,hog.y*H,W*0.032,H*0.045,0,0,Math.PI*2);c.fill();
    c.fillStyle="#4A3C2A";
    c.beginPath();c.ellipse(hog.x*W-W*0.008,hog.y*H-H*0.02,W*0.018,H*0.025,0,0,Math.PI*2);c.fill();
  }
  // skottkärran
  c.fillStyle="#6E7276";
  c.beginPath();c.moveTo(W*0.86,H*0.86);c.lineTo(W*0.985,H*0.86);
  c.lineTo(W*0.965,H*0.96);c.lineTo(W*0.885,H*0.96);c.closePath();c.fill();
  c.beginPath();c.arc(W*0.925,H*0.975,W*0.014,0,Math.PI*2);c.fill();
  c.fillStyle="#5A4A34";
  const iKarran=7-MO.kvar;
  for(let i=0;i<iKarran;i++)
    c.beginPath(),c.ellipse(W*(0.885+i*0.014),H*0.85,W*0.010,H*0.014,0,0,Math.PI*2),c.fill();
}

/* ── Fodringen — läs schemat på dörren, ge rätt ──────────────── */
const FO={ho:null,kraft:null,vatten:false};
function visaFodring(){
  const h=HORSES[G.hastId], schema=FODERSCHEMA[G.hastId]||{ho:2,kraft:"inget",notis:""};
  FO.ho=null;FO.kraft=null;FO.vatten=false;
  const val=(id,txt,grupp)=>`<button class="btn ghost fo-val" data-g="${grupp}" data-v="${id}"
    style="padding:8px 14px">${txt}</button>`;
  overlay(true,`
  <span class="lbl">Fodra och vattna · ${h.namn}</span>
  <h1 style="margin-top:6px">Läs schemat — sedan händerna</h1>
  <div class="note" style="font-size:13.5px">
    <b class="lbl" style="display:block;margin-bottom:4px;color:var(--gold-2)">Foderschemat på boxdörren</b>
    ${h.namn}: <b>${schema.ho} kg hö</b> · kraftfoder: <b>${schema.kraft}</b> · vatten: fyll hinken<br>
    <span class="dim" style="font-style:italic">”${schema.notis}”</span>
  </div>
  <div style="margin-top:14px">
    <div class="lbl" style="margin-bottom:6px">Hö</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${[1,2,3].map(k=>val(k,k+" kg","ho")).join("")}</div>
    <div class="lbl" style="margin:12px 0 6px">Kraftfoder</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${KRAFTVAL.map(k=>val(k,k,"kraft")).join("")}</div>
    <div class="lbl" style="margin:12px 0 6px">Vatten</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${val("fyll","Fyll hinken","vatten")}</div>
  </div>
  <div class="btnrow">
    <button class="btn" id="bFodraKlar">Ge fodret</button>
    <button class="btn ghost" id="bFodraAvbryt">Tillbaka</button>
  </div>`);
  for(const b of document.querySelectorAll(".fo-val"))
    b.onclick=()=>{
      const g=b.dataset.g;
      if(g==="vatten"){FO.vatten=!FO.vatten;b.classList.toggle("fo-pa",FO.vatten);}
      else{
        FO[g]=g==="ho"?+b.dataset.v:b.dataset.v;
        for(const b2 of document.querySelectorAll(`.fo-val[data-g="${g}"]`))
          b2.classList.toggle("fo-pa",b2===b);
      }
    };
  if(!document.getElementById("foStil")){
    const st=document.createElement("style");st.id="foStil";
    st.textContent=`.fo-val.fo-pa{background:var(--gold);color:#17140A;border-color:var(--gold)}`;
    document.head.appendChild(st);
  }
  document.getElementById("bFodraKlar").onclick=()=>{
    const schema2=FODERSCHEMA[G.hastId]||{ho:2,kraft:"inget"};
    let poang=0;
    if(FO.ho===schema2.ho)poang+=0.4;
    if(FO.kraft===schema2.kraft)poang+=0.4;
    if(FO.vatten)poang+=0.2;
    const s=G.sysslor||(G.sysslor={mockat:0,fodrat:0});
    s.fodrat=Math.max(s.fodrat,poang);
    saga(poang>=0.99?`${h.namn} kastar sig över höet. Rätt giva.`
      :poang>=0.6?"Nästan rätt — läs schemat en gång till nästa gång."
      :"Fel foder. Ridläraren byter ut det innan hästen hinner smaka.",3.5);
    visaBoxmeny();
  };
  document.getElementById("bFodraAvbryt").onclick=visaBoxmeny;
}
