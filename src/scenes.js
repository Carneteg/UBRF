/* ══════════════════════════════════════════════════════════════════
   SCENER — meny, hästtilldelning, skötsel, resultat. Overlay-ark.
   ══════════════════════════════════════════════════════════════════ */
const ov=document.getElementById("ov"),sheet=document.getElementById("sheet");
function overlay(on,html){ov.classList.toggle("hide",!on);if(html!==undefined)sheet.innerHTML=html;}

/* ── Meny ── */
function visaMeny(){
  G.scen="meny";
  overlay(true,`
  <span class="lbl">POC · utanför Roblox · byggd på ubrf.se</span>
  <h1 style="margin-top:8px">Ridskolan</h1>
  <p style="font-size:17px">Du styr inte hästen. Du styr fyra hjälper — skänkel, tygel, sits och styrning —
  och hjälperna flyttar hästens tillstånd på <em>utbildningsskalan</em>. Tillståndet avgör vad hästen gör.
  Det finns ingen hoppknapp.</p>
  <div class="keys">
    <div><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> gå — till fots</div>
    <div><kbd>E</kbd> interagera (dörrar, ridlärare, box)</div>
    <div><kbd>Shift</kbd> jogga (till fots)</div>
    <div><kbd>T</kbd> träningsboken (även mitt i momentet)</div>
    <div><kbd>W</kbd><kbd>S</kbd> skänkel på / av</div>
    <div><kbd>Space</kbd> tygeltag (håll)</div>
    <div><kbd>A</kbd><kbd>D</kbd> styrning</div>
    <div><kbd>E</kbd> halvhalt</div>
    <div><kbd>Shift</kbd> lätt sits</div>
    <div><kbd>Ctrl</kbd> djup nedsittning</div>
    <div><kbd>R</kbd> lättridning av/på</div>
    <div><kbd>Q</kbd> byt diagonal</div>
    <div><kbd>V</kbd> växla vy (bana / bakom hästen)</div>
    <div><kbd>M</kbd> ljud av/på (hovslag, stall, röst)</div>
    <div><kbd>N</kbd> nästa moment (POC-genväg)</div>
    <div><kbd>P</kbd> ridläraren visar (autopilot)</div>
    <div><kbd>F</kbd> spö — men läs hästlistan först</div>
  </div>
  <div class="note">Håll tygeln i det <b>gröna bandet</b> på mätaren — inte noll, inte max.
  Kontakt är en förbindelse, inte ett grepp. Och en halvhalt (E) är det enda som bygger samling.</div>
  ${profilHTML()}
  ${typeof synkPanelHTML==="function"?synkPanelHTML():""}
  <div class="btnrow">
    <button class="btn" id="bStart">Till stallet</button>
    <button class="btn ghost" id="bTavling">Tävlingsdag</button>
    <button class="btn ghost" id="bBok">Träningsboken</button>
    <span class="dim" style="font-size:13px">Dagens lektion: ${GRUPPNAMN[G.grupp]||G.grupp} · sex hinder på 0,60 m</span>
  </div>`);
  document.getElementById("bStart").onclick=()=>{G.tavling=null;startaVandring();};
  document.getElementById("bTavling").onclick=visaTavlingsval;
  document.getElementById("bBok").onclick=()=>visaTraningsbok("meny");
  kopplaProfil();
  if(typeof kopplaSynkPanel==="function")kopplaSynkPanel();
}

/* ── Ridläraren tilldelar häst ── */
function visaTilldelning(){
  // rotation ur gruppens hästpool — känsligare hästar på högre nivåer.
  // På tävlingsdag startar ingen häst som är mitt i sin rehab.
  let kandidater=hastpool(G.grupp);
  if(G.tavling){
    const friska=kandidater.filter(id=>!hastminne(id).rehab);
    if(friska.length)kandidater=friska;
  }
  const val=kandidater[G.seed%kandidater.length];
  G.hastId=val;G.skotselRes=null;G.sysslor={mockat:0,fodrat:0};
  G.hamtad=false;G.tackePa=false;G.fangstForsok=false;
  G.utrustning=false;G.lerig=false;G.spolad=0;G.felUtrustning=0;
  const h=HORSES[val];
  const motiv={toblerone:"Han förlåter det mesta — och du ska få jobba på följsamheten idag.",
    lydia:"Lydia tar hand om dig. Lyssna på henne, så lär hon dig takten.",
    cosmo:"Snäll och okomplicerad. Bra dag att träna vägen till hindret.",
    air:"Air går i alla grupper — idag går han med dig. Rid framåt.",
    larry:"Han hoppar gärna. Ge honom en rak linje så gör han resten.",
    dexter:"Håll i dig. Han har lite mer fart — låt honom inte bestämma tempot.",
    hamilton:"Arbetsvillig men känslig — sitt stilla, så växer han.",
    crokino:"Stor men lättriden. Och du såg lappen om spöet, va?",
    conor:"Du får Conor idag. Mjuk hand, balanserad sits. Han ger tillbaka exakt vad du ger honom.",
    lady:"Lady kan det här bättre än vi båda. Din uppgift är att inte störa henne.",
    chip:"Chip testar dig direkt — var vänlig men bestämd, annars bestämmer han.",
    tina:"Tina har stallets finaste trav. Rykta försiktigt, hon är kittlig.",
    westside:"Westside gör jobbet om du gör ditt. Rak och ärlig — som en lektionshäst ska vara.",
    makadu:"Makadu är snäll som få. Men kolla gjorden en extra gång innan du sitter upp.",
    mara:"Bry dig inte om minen i boxen. Mara ger dig allt när ni väl är på banan.",
    husky:"Om du får med dig Husky från hagen är halva lektionen redan vunnen.",
    kennedy:"Kennedy är ung och allt är på riktigt för honom. Visa honom att världen är ofarlig."}[val]
    ||"Rid som du red senast — fast bättre.";
  const tavMotiv=G.tavling?(G.tavling.typ==="hoppning"
    ?`Tävlingsdag — ${G.tavling.klass.namn} i Påskhoppet. Du rider ${h.namn}. Sköt honom extra noga, domarna ser allt.`
    :`Tävlingsdag — dressyr LC på uteridbanan. Du rider ${h.namn}. Ren ridning slår djärv ridning i dag.`):null;
  const minne=hastminne(val);
  const EGENHET={radd_for_spo:"är rädd för spö — det står på hästlistan. Låt bli F-tangenten.",
    blaser_upp_magen:"blåser upp magen när du gjordar. Vänta en stund och dra åt igen innan du sitter upp.",
    kittlig:"är kittlig — rykta med lugna, långsamma drag, annars registreras de inte.",
    svarfangad:"är svårfångad i hagen. Drar han sig undan: stå still och gå lugnt fram en gång till."};
  const egenheter=Object.keys(h.flaggor||{}).map(f=>EGENHET[f]).filter(Boolean);
  const trott=minne.pass>0&&minne.sistaPassNr===SPAR.pass;
  const rehab=!!minne.rehab;
  overlay(true,`
  <span class="lbl">${G.tavling?"Tävlingsdag · ridläraren fördelar hästarna":"Ridläraren fördelar hästarna"}</span>
  <h1 style="margin-top:8px">Du får ${h.namn}</h1>
  <div class="hcard">
    <div style="flex:1">
      <div class="n">${h.namn}</div>
      <div class="k">”${h.besk}”</div>
      <div class="tr">
        <span>Känslighet <b>${h.kanslighet.toFixed(2).replace(".",",")}</b></span>
        <span>Förlåter <b>${h.forlatande.toFixed(2).replace(".",",")}</b></span>
        <span>Framåt <b>${h.framatbjudning.toFixed(2).replace(".",",")}</b></span>
        <span>Maxhöjd <b>${h.maxhojd.toFixed(2).replace(".",",")} m</b></span>
      </div>
      <div class="why">”${tavMotiv||motiv}”</div>
      ${minne.pass>0?`<div class="dim" style="font-size:12px;margin-top:8px">Ni har ridit ${minne.pass} pass ihop — han minns dig (rang ${minne.rang.toFixed(2).replace(".",",")})${
        typeof minne.sistaForm==="number"?` · dagsform senast ${minne.sistaForm.toFixed(2).replace(".",",")}`:""}.</div>`
        :`<div class="dim" style="font-size:12px;margin-top:8px">Första gången ni möts.</div>`}
    </div>
  </div>
  ${egenheter.map(e=>`<div class="note bad">${h.namn} ${e}</div>`).join("")}
  ${rehab?`<div class="note" style="font-size:13px"><b class="gold">Vägen tillbaka:</b> ${h.namn} är åter i tjänst efter sin skada. Första passet rids försiktigt — bara skritt och trav, säger ridläraren.</div>`:""}
  ${trott?`<div class="note" style="font-size:13px">${h.namn} gick lektion alldeles nyss och är inte utvilad — det kommer märkas på dagsformen.</div>`:""}
  <p class="dim" style="font-size:13.5px">Du väljer inte häst på en ridskola. Ridläraren tilldelar —
  att få rida en bättre häst är belöningen. Nästa gång du spelar får du en annan.</p>
  <div class="btnrow">
    <button class="btn" id="bGroom">Hämta honom i hagen</button>
    <button class="btn ghost" id="bAnnan">Fråga om en annan häst</button>
  </div>`);
  document.getElementById("bGroom").onclick=()=>{overlay(false);
    saga(`${h.namn} går i hagen öster om stallet${G.vader&&G.vader.tacke?" — med täcke i det här vädret":""}. Ta grimman och hämta honom.`,4);};
  document.getElementById("bAnnan").onclick=()=>{G.seed++;visaTilldelning();
    setTimeout(()=>{const w=document.querySelector(".why");
      if(w&&G.seed%3===0)w.textContent="”Nej. Du rider den du fått. Så fungerar det här.”";},50);};
}

/* ── Skötseln — fyra handgrepp på en canvas ── */
const SK={steg:0,ryktning:new Set(),hovar:[0,0,0,0],sadelX:0.5,gjord:0.1,visitering:0,betsling:0,
  start:0,drar:false,sista:null};
function visaSkotsel(){
  SK.steg=0;SK.ryktning.clear();SK.hovar=[0,0,0,0];SK.sadelX=0.42;SK.gjord=0.10;
  SK.visitering=0;SK.betsling=0;SK.start=performance.now();
  ryktNollstall();sadelNollstall();visitNollstall();
  const h=HORSES[G.hastId];
  /* Egenhet: en häst som blåser upp magen släpper sakta ut luften —
     gjorden glider ner igen tills du drar åt en gång till. */
  if(SK.magTimer){clearInterval(SK.magTimer);SK.magTimer=null;}
  if(h.flaggor&&h.flaggor.blaser_upp_magen)
    SK.magTimer=setInterval(()=>{
      if(SK.gjord>0.30&&!SK.drar){
        SK.gjord=Math.max(0.30,SK.gjord-0.025);
        if(SK.steg===3){dok3();ritaGroom();}
      }},900);
  overlay(true,`
  <span class="lbl">Före lektionen · stallregel 10</span>
  <h1 style="margin-top:6px">Visitera, rykta, kratsa, sadla</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">Skickligt, inte länge. Det du gör nu avgör hur ${h.namn} går på lektionen.</p>
  <div id="groom">
    <div>
      <canvas id="groomCanvas"></canvas>
      <div id="groomHint"></div>
    </div>
    <div>
      <div class="gstep" data-s="0"><span><span class="gn">1 · Visitera</span><br>mungipor och skav</span><span class="gv" id="gv0">—</span></div>
      <div class="gstep" data-s="1"><span><span class="gn">2 · Rykta</span><br>dra över hela kroppen</span><span class="gv" id="gv1">0 %</span></div>
      <div class="gstep" data-s="2"><span><span class="gn">3 · Kratsa hovar</span><br>alla fyra</span><span class="gv" id="gv2">0/4</span></div>
      <div class="gstep" data-s="3"><span><span class="gn">4 · Sadla</span><br>läge + gjord i bandet</span><span class="gv" id="gv3">—</span></div>
      <div style="margin-top:14px"><button class="btn" id="bKlar">Sitt upp</button></div>
      <div class="dim" style="font-size:12px;margin-top:10px">Du kan sitta upp när du vill.<br>Hästen märker vad du hoppade över.</div>
    </div>
  </div>`);
  for(const el of document.querySelectorAll(".gstep"))
    el.onclick=()=>{SK.steg=+el.dataset.s;hovStang();VIS.oppen=null;
      momentKamTill(SK.steg);groomHint();};
  document.getElementById("bKlar").onclick=avslutaSkotsel;
  initGroomCanvas();momentKamTill(0,true);groomHint();
}
function groomHint(){
  const h=HORSES[G.hastId];
  let t=["Klicka på de fem ringarna: ögon, mungipor, sadelläge, gjordläge och ben. De flesta dagar är allt bra — det är därför man slutar titta.",
    "Håll och dra över kroppen, i pälsens riktning (framifrån och bak). Täckning räknas per område.",
    "Klicka på en hov för att lyfta den, dra sedan nedåt över den för att kratsa. Alla fyra.",
    "Dra sadeln till rätt läge — precis bakom manken — och dra sedan gjordreglaget till det gröna bandet."][SK.steg];
  if(SK.steg===1&&h.flaggor&&h.flaggor.kittlig)
    t+=` OBS: ${h.namn} är kittlig — bara lugna, långsamma drag räknas.`;
  if(SK.steg===3&&h.flaggor&&h.flaggor.blaser_upp_magen)
    t+=` OBS: ${h.namn} blåser upp magen — gjorden glider ner igen. Dra åt en sista gång precis innan du sitter upp.`;
  document.getElementById("groomHint").textContent=t;
  document.querySelectorAll(".gstep").forEach(e=>e.classList.toggle("on",+e.dataset.s===SK.steg));
}
let gcv,gcx,lyftHov=-1;
/* Ankarpunkter på hästen (normaliserade canvaskoordinater) — hästen
   ritas med ritaHastSida: mitt 0.55W, mark 0.88H, mankhöjd 0.52H,
   huvudet åt vänster. */
const RYKTZONER=[[0.44,0.31],[0.45,0.46],[0.55,0.39],[0.55,0.54],
                 [0.66,0.52],[0.73,0.44],[0.43,0.57],[0.70,0.59]];
const HOVP=[[0.44,0.85],[0.49,0.85],[0.68,0.85],[0.735,0.85]];
const MUNGIPA=[0.267,0.33], SADELPLATS=[0.57,0.34], SADEL_RATT=0.565;
function initGroomCanvas(){
  gcv=document.getElementById("groomCanvas");gcx=gcv.getContext("2d");
  const fit=()=>{const r=gcv.getBoundingClientRect();gcv.width=r.width*DPR;gcv.height=r.height*DPR;
    gcx.setTransform(DPR,0,0,DPR,0,0);ritaGroom();};
  fit();new ResizeObserver(fit).observe(gcv);
  const pos=e=>{const r=gcv.getBoundingClientRect();
    const p=e.touches?e.touches[0]:e;return[(p.clientX-r.left)/r.width,(p.clientY-r.top)/r.height];};
  const ned=e=>{SK.drar=true;SK.sista=pos(e);hantera(pos(e),true);e.preventDefault();};
  const rr=e=>{if(!SK.drar)return;hantera(pos(e),false);SK.sista=pos(e);e.preventDefault();};
  const upp=()=>{SK.drar=false;HOV.sista=null;if(HOV.i<0)lyftHov=-1;ritaGroom();};
  gcv.addEventListener("pointerdown",ned);gcv.addEventListener("pointermove",rr);
  addEventListener("pointerup",upp);
}
function hantera(p,klick){
  /* Hoven först: när närbilden är uppe är det den som tar dragen. */
  if(HOV.i>=0){
    const r=gcv.getBoundingClientRect();
    if(SK.drar)hovDrag(hovTillLokal(p[0],p[1],r.width,r.height));
    dok(2,SK.hovar.filter(v=>v>0.6).length+"/4");
    ritaGroom(); return;
  }
  if(SK.steg===0&&klick){
    const r0=gcv.getBoundingClientRect();
    if(visitKlick(p[0],p[1],r0.width,r0.height)){
      SK.visitering=visitAndel();
      dok(0,visitKlar()?"klart":`${VIS.sedd.size}/${VISITPUNKT.length}`);
      ritaGroom(); return;
    }
  }
  if(SK.steg===1&&klick){
    const r0=gcv.getBoundingClientRect();
    if(ryktKlickChipp(p[0],p[1],r0.width,r0.height)){ritaGroom();return;}
  }
  const[x,y]=momentTillBild(p[0],p[1]);
  if(SK.steg===0&&klick){
    let b=null,bd=0.085;
    for(const v of VISITPUNKT){const d=Math.hypot(x-v.x,y-v.y);if(d<bd){bd=d;b=v;}}
    if(b)visitOppna(b.id);
    SK.visitering=visitAndel();
    SK.betsling=VIS.sedd.has("mun")?0.9:0.2;
    dok(0,visitKlar()?"klart":`${VIS.sedd.size}/${VISITPUNKT.length}`);
  }
  if(SK.steg===1){
    const fs=SK.sista?momentTillBild(SK.sista[0],SK.sista[1]):null;
    if(SK.drar)ryktDrag([x,y],fs);
    SK.ryktning=new Set();                       // för utvärderingen
    for(let i=0;i<RYKTZON.length;i++)
      if(RY.gjort[i]&&RY.gjort[i].size>=RYKTKRAV[RYKTZON[i].typ].length)SK.ryktning.add(i);
    dok(1,Math.round(ryktAndel()*100)+" %");
  }
  if(SK.steg===2&&klick){
    /* Klicka på en hov: bilden zoomar in på sulan och kratsandet sker
       där, inte som ett drag längs benet i profil. */
    let bi=-1,bd=0.075;
    for(let i=0;i<4;i++){const d=Math.hypot(x-HOVP[i][0],y-HOVP[i][1]);
      if(d<bd){bd=d;bi=i;}}
    if(bi>=0&&SK.hovar[bi]<0.6){lyftHov=bi;hovOppna(bi);}
    dok(2,SK.hovar.filter(v=>v>0.6).length+"/4");
  }
  if(SK.steg===3){
    const fs=SK.sista?momentTillBild(SK.sista[0],SK.sista[1]):null;
    sadelDrag([x,y],SK.drar?fs:null,klick);
    dok3();
  }
  ritaGroom();
}
function dok(i,v){const el=document.getElementById("gv"+i);if(el)el.textContent=v;}
function dok3(){
  const lage=1-clamp(Math.abs(SK.sadelX-SADEL_RATT)/0.16,0,1);
  const gOk=SK.gjord>=0.42&&SK.gjord<=0.74;
  dok(3,(lage>0.7?"läge ✓":"läge ✗")+(SA.mankfri?" manke ✓":" manke ✗")
    +(gOk&&SA.tag>=3?" gjord ✓":" gjord ✗"));
}
function ritaGroom(){
  const W=gcv.clientWidth,H=gcv.clientHeight,h=HORSES[G.hastId];
  gcx.clearRect(0,0,W,H);
  // stallmiljö bakom: varmt golv och väggpanel
  const gr=gcx.createLinearGradient(0,0,0,H);
  gr.addColorStop(0,"#3A342C"); gr.addColorStop(0.72,"#4A423A"); gr.addColorStop(0.73,"#6E6152"); gr.addColorStop(1,"#5E5346");
  gcx.fillStyle=gr; gcx.fillRect(0,0,W,H);
  gcx.strokeStyle="rgba(0,0,0,.12)"; gcx.lineWidth=1;
  for(let i=1;i<8;i++){gcx.beginPath();gcx.moveTo(W*i/8,0);gcx.lineTo(W*i/8,H*0.72);gcx.stroke();}
  /* Utsnittet för momentet. Allt som ritas i bildens koordinater ligger
     innanför — hästen, zonerna och markörerna. */
  gcx.save();
  gcx.translate(W/2,H/2); gcx.scale(KAM.s,KAM.s); gcx.translate(-KAM.x*W,-KAM.y*H);
  // hästen i profil, huvudet åt vänster
  ritaHastSida(gcx, W*0.55, H*0.88, H*0.52, -1, h.farg, h.man, {pose:"sta"});
  /* Ryktzonerna. Varje zon är en ring delad i lika många bågar som den
     kräver redskap, och bågen tänds när det redskapet varit där. */
  if(SK.steg===1)for(let i=0;i<RYKTZON.length;i++){
    const z=RYKTZON[i], krav=RYKTKRAV[z.typ], r=W*0.040;
    gcx.fillStyle="rgba(230,228,222,.09)";
    gcx.beginPath();gcx.arc(W*z.x,H*z.y,r,0,Math.PI*2);gcx.fill();
    for(let k=0;k<krav.length;k++){
      const gjort=RY.gjort[i]&&RY.gjort[i].has(krav[k]);
      const red=RYKTREDSKAP.find(v=>v.id===krav[k]);
      gcx.beginPath();
      gcx.arc(W*z.x,H*z.y,r*1.22,-Math.PI/2+k*2*Math.PI/krav.length+0.10,
        -Math.PI/2+(k+1)*2*Math.PI/krav.length-0.10);
      gcx.lineWidth=3.2; gcx.strokeStyle=gjort?red.farg:"rgba(230,228,222,.16)";
      gcx.stroke();
    }
  }

  // hovar
  if(SK.steg===2){
    for(let i=0;i<4;i++){const[hx,hy]=HOVP[i];
      gcx.fillStyle=SK.hovar[i]>0.6?"rgba(127,180,137,.85)":lyftHov===i?"rgba(214,174,60,.9)":"rgba(240,238,232,.35)";
      gcx.beginPath();gcx.arc(W*hx,H*hy+(lyftHov===i?-H*0.05:0),W*0.024,0,Math.PI*2);gcx.fill();}}
  // sadel
  if(SK.steg===3){
    /* Underlägget ligger först, sadeln kommer i fas 1. */
    gcx.fillStyle=SA.fas>=1?"rgba(240,238,232,.90)":"rgba(240,238,232,.65)";
    gcx.beginPath();
    gcx.ellipse(W*(SA.fas>=1?SADEL_RATT:SA.ux),H*0.352,W*0.088,H*0.070,0,0,Math.PI*2);
    gcx.fill();
    if(SA.fas<1){ gcx.restore(); ritaSadel(gcx,W,H); return; }
    const sx=W*SK.sadelX;
    const ok=Math.abs(SK.sadelX-SADEL_RATT)<0.11;
    gcx.fillStyle=ok?"rgba(107,160,117,.92)":"rgba(214,174,60,.92)";
    gcx.beginPath();gcx.ellipse(sx,H*0.345,W*0.068,H*0.055,0,0,Math.PI*2);gcx.fill();
    gcx.strokeStyle=gcx.fillStyle;gcx.lineWidth=5;
    gcx.beginPath();gcx.moveTo(sx,H*0.39);gcx.quadraticCurveTo(sx-W*0.01,H*0.52,sx,H*0.62);gcx.stroke();
    // rätt läge-markering
    gcx.strokeStyle="rgba(240,238,232,.4)";gcx.setLineDash([4,5]);gcx.lineWidth=1.5;
    gcx.beginPath();gcx.moveTo(W*SADEL_RATT,H*0.22);gcx.lineTo(W*SADEL_RATT,H*0.56);gcx.stroke();gcx.setLineDash([]);
    // gjordmätare
    gcx.fillStyle="rgba(11,13,16,.85)";gcx.fillRect(W*0.2,H*0.90,W*0.6,10);
    gcx.fillStyle="rgba(127,180,137,.35)";gcx.fillRect(W*0.2+W*0.6*0.42,H*0.90,W*0.6*0.32,10);
    gcx.fillStyle="#D6AE3C";gcx.fillRect(W*0.2,H*0.90,W*0.6*SK.gjord,10);
    gcx.fillStyle="#8E939B";gcx.font='10px "IBM Plex Mono"';gcx.textAlign="center";
    gcx.fillText("GJORD — dra hit",W*0.5,H*0.90-6);
    if(SA.mankfri){                              // manken fri: bommen markerad
      gcx.strokeStyle="rgba(127,180,137,.85)";gcx.lineWidth=2.5;
      gcx.beginPath();gcx.arc(sx,H*0.315,W*0.030,0,Math.PI*2);gcx.stroke();
    }
  }
  gcx.restore();
  if(SK.steg===0)ritaVisit(gcx,W,H);
  if(SK.steg===1)ritaRykt(gcx,W,H);
  if(SK.steg===3)ritaSadel(gcx,W,H);
  /* Hovens närbild ligger över allt annat — den är ett eget moment. */
  ritaHov(gcx,W,H);
}
function avslutaSkotsel(){
  if(SK.magTimer){clearInterval(SK.magTimer);SK.magTimer=null;}
  const tid=(performance.now()-SK.start)/1000;
  // stallron byggs i boxen: mockat och rätt foder ger en lugnare häst
  const sys=G.sysslor||{mockat:0,fodrat:0};
  G.stallro=clamp(0.72+0.14*sys.mockat+0.14*sys.fodrat,0,1);
  const res=utvarderaSkotsel({
    visitering:SK.visitering, ryktning:ryktAndel(),
    hovar:SK.hovar,
    /* Sadelläget är inte bara var sadeln hamnade. En sadel som ligger
       rätt men med underlägget nedtryckt i manken, eller en gjord som
       drogs i ett enda tag, är inte en sadlad häst. */
    sadellage:(1-clamp(Math.abs(SK.sadelX-SADEL_RATT)/0.16,0,1))
      *(SA.mankfri?1:0.62)*(SA.tag>=3?1:SA.tag>=2?0.86:0.70),
    gjord:SK.gjord, betsling:SK.betsling, tid,
  },HORSES[G.hastId].forlatande,G.stallro);
  /* Individen: gårdagens skötsel sitter i kroppen, och en häst som
     gick lektion nyss är inte utvilad. */
  const m0=hastminne(G.hastId);
  const trott=m0.pass>0&&m0.sistaPassNr===SPAR.pass;
  let igarRad="första passet på länge", vilaRad="utvilad";
  if(typeof m0.sistaForm==="number"){
    res.dagsform=clamp(res.dagsform+(m0.sistaForm-0.66)*0.18,0,1);
    igarRad=m0.sistaForm.toFixed(2).replace(".",",")
      +(m0.sistaForm>=0.72?" — det sitter i":m0.sistaForm<0.55?" — slarvet sitter i":"");
  }
  if(trott){res.dagsform=clamp(res.dagsform-0.08,0,1);vilaRad="gick lektion nyss (−0,08)";}
  /* Leran från hagen: spolad häst går att sköta, olerad gör det inte. */
  let lerRad="torr efter hagen";
  if(G.spolad>=0.8&&!G.lerig){res.dagsform=clamp(res.dagsform+0.03,0,1);
    lerRad="avspolad i spiltan (+0,03)";}
  else if(G.lerig){res.dagsform=clamp(res.dagsform-0.09,0,1);
    res.risker.push("lera_kvar");
    lerRad="lera kvar på benen (−0,09)";
    res.omdome="Du sköter ingen häst genom leran. Spola av benen i spiltan innan du borstar nästa gång.";}
  /* Fel utrustning räknades men kostade ingenting. Nu gör den det: varje
     vända tillbaka till sadelkammaren är en häst som står uppbunden och
     väntar, och det syns på dagsformen. Priset är litet — poängen är att
     misstaget inte glöms bort utan får ett skäl. */
  let utrRad="rätt sadel och träns direkt";
  if(G.felUtrustning>0){
    res.dagsform=clamp(res.dagsform-0.03*Math.min(G.felUtrustning,3),0,1);
    utrRad=`fel utrustning ${G.felUtrustning} gång${G.felUtrustning>1?"er":""} `
      +`(−${(0.03*Math.min(G.felUtrustning,3)).toFixed(2).replace(".",",")}) — `
      +`hon stod uppbunden och väntade`;
  }
  /* Visiteringen ska löna sig, inte bara straffa. Hittade du något och
     sa till får hon en bättre dag — det är hela poängen med att titta. */
  let visRad="inget att anmärka";
  if(visitMissat()){
    if(!res.risker.includes("missat_skav"))res.risker.push("missat_skav");
    visRad=VIS.sedd.has(VIS.fynd)?"du såg det och lät det vara"
      :"du hann inte gå igenom allt";
  }else if(VIS.fynd){
    res.dagsform=clamp(res.dagsform+0.05,0,1);
    visRad="du hittade det och sa till (+0,05)";
  }
  G.dagsform=res.dagsform;G.sadellage=res.sadellage;G.skotselRes=res;
  /* Skötseln ger hästkunskap. Måttet är dagsformen du lyckades lämna
     hästen i — det är den enda siffra som säger något om hur väl du
     faktiskt skötte henne, och den syns redan på skärmen. */
  {const foreSk=(typeof fard==="function")?fard().skotsel:0;
   const steg=fardighetSkotsel(res.dagsform);
   if(typeof passSkotsel==="function")
     passSkotsel(foreSk,(typeof fard==="function")?fard().skotsel:0,res);
   if(steg&&typeof visaFardighetsSteg==="function")
     setTimeout(()=>visaFardighetsSteg(steg),900);}
  /* Humöret sätts en gång, här, av skötseln du just gjort och av vad ni
     har ihop sedan tidigare. Sedan ligger det fast under passet. */
  G.humor=dagensHumor(G.hastId);
  G.ride=nyState(G.dagsform,hastminne(G.hastId).rang,G.sadellage);
  initNPC();
  G.px=10;G.py=52;G.rikt=-Math.PI/2;
  overlay(true,`
  <span class="lbl">Ridläraren tittar på ${HORSES[G.hastId].namn}</span>
  <p class="humor">${humorText(G.hastId,G.humor)}</p>
  <h1 style="margin-top:8px" ${res.dagsform<0.55?'class="red"':""}>”${res.omdome}”</h1>
  <table><tbody>
    <tr><td>Dagsform</td><td class="num">${res.dagsform.toFixed(2).replace(".",",")}</td></tr>
    <tr><td>Sadelläge</td><td class="num">${res.sadellage.toFixed(2).replace(".",",")}</td></tr>
    <tr><td>Risker under lektionen</td><td class="num">${res.risker.length?res.risker.join(", ").replaceAll("_"," "):"inga"}</td></tr>
    <tr><td>Gårdagens dagsform</td><td class="num">${igarRad}</td></tr>
    <tr><td>Vila</td><td class="num">${vilaRad}</td></tr>
    <tr><td>Benen efter hagen</td><td class="num">${lerRad}</td></tr>
    <tr><td>Utrustningen</td><td class="num">${utrRad}</td></tr>
    <tr><td>Visiteringen</td><td class="num">${visRad}</td></tr>
    <tr><td>Boxen mockad</td><td class="num">${Math.round(sys.mockat*100)} %</td></tr>
    <tr><td>Fodrat efter schema</td><td class="num">${Math.round(sys.fodrat*100)} %</td></tr>
    <tr><td>Stallro</td><td class="num">${G.stallro.toFixed(2).replace(".",",")}</td></tr>
    <tr><td>Tid i stallet</td><td class="num">${Math.round(tid)} s</td></tr>
  </tbody></table>
  ${sys.mockat<0.99||sys.fodrat<0.99?`<div class="note bad" style="font-size:13px">${
    sys.mockat<0.99?"Boxen är inte färdigmockad. ":""}${
    sys.fodrat<0.99?"Fodringen stämmer inte med schemat. ":""}Det sänker stallron — hästen känner av oredan.</div>`:""}
  <p class="dim" style="font-size:13.5px">Dagsformen skalar hela avsprångskvaliteten i hoppningen,
  och sadelläget sätter tak på lösgjordheten. Det är därför de tjugo minuterna före lektionen finns.</p>
  <div class="btnrow"><button class="btn" id="bLek">Led honom ut till lektionen</button></div>`);
  document.getElementById("bLek").onclick=()=>{overlay(false);
    G.leder=true;VD.spår.length=0;
    const gIdx=GRUPPSTEGE.indexOf(G.grupp);
    saga("Led hästen ut. I dag kan ni ta ridhuset eller uteridbanan"+
      (gIdx>=5?" — eller sitta upp för uteritt på skogsstigen.":"."),4.5);};
}

/* ── Resultatet ── */
function visaResultat(dom){
  const h=HORSES[G.hastId];
  const inv=Object.values(G.betyg);
  const snitt=inv.length?inv.reduce((a,b)=>a+b,0)/inv.length:0;
  const P=G.passRes||{forv:Skala.FORVANTAN[G.grupp]??0.55,godkand:false,uppflyttad:false,
    gruppNamn:GRUPPNAMN[G.grupp]||G.grupp,poang:0};
  const forv=P.forv;
  const radNamn=k=>{const m=(G.lektion||[]).find(x=>x.id===k);return m?m.namn:k;};
  let momRows="";
  for(const k in G.betyg)momRows+=`<tr><td>${radNamn(k)}</td><td class="num">${G.betyg[k].toFixed(2).replace(".",",")}</td></tr>`;
  const domRows=dom.protokoll.map(r=>`<li>${r}</li>`).join("");
  const omdome= P.uppflyttad?`Det där satt. Från och med nästa vecka rider du i ${P.gruppNamn}.`
    : dom.utesluten?`Det blev inte er dag. ${h.namn} förtjänade en lugnare ritt — vi tar det igen nästa vecka.`
    : !G.hadeBana?(snitt>=forv?`Bra ridet. Ridningen håller för din grupp — fortsätt så.`
      :`Vi jobbar vidare. Snittet nådde inte gruppens förväntan idag — läs övningarna i träningsboken.`)
    : dom.totalfel===0&&snitt>=forv?`Felfritt, och du red vägen — inte hindren. Jag flyttar upp dig en grupp efter jul.`
    : dom.totalfel===0?`Felfritt! Men ridningen mellan hindren var stökigare än resultatet. Vi jobbar vidare där.`
    : snitt>=forv?`${dom.totalfel} fel, men ridningen håller. Felen försvinner när distanserna sätter sig.`
    : `${dom.totalfel} fel. Titta mindre på hindret och mer på vägen dit.`;
  overlay(true,`
  <span class="lbl">Efter lektionen</span>
  <h1 style="margin-top:8px">”${omdome}”</h1>
  ${typeof efterPassHTML==="function"?efterPassHTML():""}
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-top:10px">
    <div>
      ${G.hadeBana?`<div class="lbl" style="margin-bottom:6px">Protokoll — bedömning A, låg klass</div>
      <ul style="font-size:13px;font-family:'IBM Plex Mono',monospace;line-height:1.7">${domRows||"<li>—</li>"}</ul>
      <table><tbody>
        <tr><td>Hinderfel</td><td class="num">${dom.hinderfel}</td></tr>
        <tr><td>Tid</td><td class="num">${dom.tid.toFixed(1).replace(".",",")} s</td></tr>
        <tr><td>Resultat</td><td class="num">${dom.utesluten?"UTESLUTEN":dom.totalfel+" fel"}</td></tr>
      </tbody></table>`
      :`<div class="lbl" style="margin-bottom:6px">Dagens lektion — ${GRUPPNAMN[P.riddenGrupp||G.grupp]||G.grupp}${
        {utebana:" · uteridbanan",stig:" · uteritt på skogsstigen"}[G.plats]||""}</div>
      <ul style="font-size:13px;line-height:1.8">${(G.lektion||[]).map(m=>`<li>${m.namn}</li>`).join("")}</ul>
      <p class="dim" style="font-size:12.5px">Hoppning kommer först i hoppgruppen — vägen dit går genom utbildningsskalan.</p>`}
    </div>
    <div>
      <div class="lbl" style="margin-bottom:6px">Inverkan per moment (förväntan ${P.riddenNamn||GRUPPNAMN[G.grupp]||G.grupp}: ${forv.toFixed(2).replace(".",",")})</div>
      <table><tbody>${momRows}
        <tr><td><b style="color:var(--ink)">Snitt</b></td><td class="num" style="color:${snitt>=forv?"var(--ok)":"var(--crit)"}">${snitt.toFixed(2).replace(".",",")}</td></tr>
      </tbody></table>
      ${P.uppflyttad?`<div class="note" style="font-size:14px"><b class="gold">UPPFLYTTAD.</b>
        Du rider nu i <b>${P.gruppNamn}</b> — nya hästar väntar i rotationen.</div>`
        :`<div class="note" style="font-size:13px">${P.godkand
          ?`Godkänt pass — snittet höll gruppens förväntan. Uppflyttning: <b class="gold">${P.poang}/2</b>.`
          :`Uppflyttning kräver snitt över gruppens förväntan (${forv.toFixed(2).replace(".",",")}) utan uteslutning. Just nu: ${P.poang}/2.`}</div>`}
      ${P.skada?`<div class="note bad" style="font-size:13px">Efter lektionen visar ${h.namn} <b>${P.skada.namn}</b>.
        Han sätts på vila i ${P.skada.passKvar} pass — och första passet tillbaka blir bara skritt och trav.
        Nästa gång: visitera och kratsa ordentligt <em>före</em> lektionen.</div>`:""}
    </div>
  </div>
  <div class="btnrow">
    <button class="btn" id="bIgen">Rid igen — ny häst</button>
    <button class="btn ghost" id="bSamma">Samma häst igen</button>
  </div>`);
  if(typeof kopplaEfterPass==="function")kopplaEfterPass();
  document.getElementById("bIgen").onclick=()=>{G.seed++;nollstall();
    G.hastId=null;G.skotselRes=null;overlay(false);hudLage("gang");
    gaTill("stallinne",{x:7.5,y:12,rikt:Math.PI/2});
    saga("Tillbaka i stallgången. Ridläraren fördelar hästarna.",3.5);};
  document.getElementById("bSamma").onclick=()=>{
    const mS=hastminne(G.hastId);
    if(mS.skada&&mS.skada.passKvar>0){
      G.seed++;nollstall();G.hastId=null;G.skotselRes=null;overlay(false);hudLage("gang");
      gaTill("stallinne",{x:7.5,y:12,rikt:Math.PI/2});
      saga(`${h.namn} står på vila — ${mS.skada.namn}. Ridläraren ger dig en annan häst.`,4);
      return;
    }
    nollstall();
    G.skotselRes=null;G.hamtad=true;G.tackePa=false;
    G.utrustning=true;G.lerig=false;G.spolad=0;   // sadeln är redan hämtad
    overlay(false);hudLage("gang");
    const b=hittaBox(G.hastId)||{dorr:[7.5,12]};
    gaTill("stallinne",{x:7.5,y:b.dorr[1],rikt:0});
    visaSkotsel();};
}
function nollstall(){
  G.auto=false;G.leder=false;G.sysslor={mockat:0,fodrat:0};G.plats="ridhus";
  G.tavling=null;BANA.hojd=0.60;
  G.hinderAktiva=false;G.rivna.clear();G.handelser=[];G.nastaHinder=0;
  G.momentIx=0;G.moment=null;G.betyg={};G.scen="meny";
  document.getElementById("protWrap").hidden=true;
  document.getElementById("approach").textContent="";
}
visaMeny();
