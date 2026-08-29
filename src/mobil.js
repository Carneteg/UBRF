/* ══════════════════════════════════════════════════════════════════
   PEKSKÄRM — virtuell styrning för mobil och surfplatta.
   Joysticken till vänster och knapparna till höger skickar samma
   tangenthändelser som tangentbordet, så all spellogik är orörd:
   joystick upp = W (skänkel/gå), sida = A/D, knapparna mappas till
   Space, E, Shift och togglarna. Kontexten (gå/ridning) avgör vilka
   knappar som visas. Syns bara på enheter med pekskärm.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const PEKSKARM = matchMedia("(pointer:coarse)").matches || "ontouchstart" in window;

(function initPek(){
  if(!PEKSKARM) return;
  document.body.classList.add("pek");

  const stil=document.createElement("style");
  stil.textContent=`
  .pek .hudh.bl{bottom:calc(172px + env(safe-area-inset-bottom,0px))}
  .pek .hudh.br{bottom:calc(172px + env(safe-area-inset-bottom,0px))}
  /* Ridlärarens replik ska ligga ovanför knapparna, inte under dem. */
  .pek .hudh.bc{bottom:calc(272px + env(safe-area-inset-bottom,0px)); width:min(420px,88vw)}
  .pek #viewToggle{bottom:auto; top:calc(8px + env(safe-area-inset-top,0px)); left:auto;
    right:calc(14px + env(safe-area-inset-right,0px)); transform:none}
  @media(max-height:560px) and (orientation:landscape){
    .pek .hudh.bc{bottom:96px; width:min(360px,52vw)}
    .pek .hudh.bl, .pek .hudh.br{bottom:150px}
  }
  #pekUI{position:fixed; inset:0; pointer-events:none; z-index:12}
  /* Joystickens ZON är hela nedre vänstra hörnet — man behöver inte
     pricka spaken, den flyttar sig dit fingret landar. */
  #joyZon{position:absolute; left:0; bottom:0; width:min(46vw,340px);
    height:min(44vh,380px); pointer-events:auto; touch-action:none}
  #joy{position:absolute; left:calc(18px + env(safe-area-inset-left,0px));
    bottom:calc(20px + env(safe-area-inset-bottom,0px)); width:132px; height:132px;
    border-radius:50%; background:rgba(24,27,33,.55); border:1.5px solid var(--rule);
    touch-action:none}
  #joyKnopp{position:absolute; left:50%; top:50%; width:56px; height:56px;
    border-radius:50%; background:rgba(214,174,60,.85); border:2px solid #17140A;
    transform:translate(-50%,-50%); transition:transform .06s}
  .pekKnappar{position:absolute; right:calc(14px + env(safe-area-inset-right,0px));
    bottom:calc(20px + env(safe-area-inset-bottom,0px)); display:flex;
    flex-direction:column; gap:10px; align-items:flex-end; pointer-events:none}
  .pekKnapp{pointer-events:auto; touch-action:none; user-select:none;
    -webkit-user-select:none; min-width:64px; height:56px; padding:0 16px;
    border-radius:28px; background:rgba(24,27,33,.82); border:1.5px solid var(--rule);
    color:var(--ink); font-family:"IBM Plex Mono",monospace; font-size:12px;
    letter-spacing:.06em; display:flex; align-items:center; justify-content:center}
  .pekKnapp.ner{background:var(--gold); color:#17140A; border-color:var(--gold)}
  .pekKnapp.stor{height:64px; min-width:76px; font-size:13px; font-weight:600}
  .pekSmaRad{display:flex; gap:8px}
  /* Minst 44×44 CSS-pixlar per knapp — även de "små". */
  .pekKnapp.liten{min-width:44px; height:44px; padding:0 10px; font-size:11.5px}
  @media(max-width:430px){
    #joy{width:112px;height:112px}
    .pekKnapp.stor{height:56px;min-width:64px}
  }
  /* Surfplattan är sin egen layout: större spak och knappar, mer luft —
     inte mobilens uppsättning uppförstorad. */
  @media(min-width:760px) and (min-height:600px){
    #joy{width:168px;height:168px}
    #joyKnopp{width:68px;height:68px}
    .pekKnapp{height:62px;min-width:76px;font-size:13px}
    .pekKnapp.liten{min-width:52px;height:48px;font-size:11.5px}
    .pekKnapp.stor{height:72px;min-width:96px;font-size:15px}
    .pekKnappar{gap:12px}
    .pek .hudh.bl,.pek .hudh.br{bottom:calc(200px + env(safe-area-inset-bottom,0px))}
  }`;
  document.head.appendChild(stil);

  const ui=document.createElement("div"); ui.id="pekUI";
  ui.innerHTML=`
    <div id="joyZon"><div id="joy"><div id="joyKnopp"></div></div></div>
    <div class="pekKnappar" id="pekGang">
      <div class="pekSmaRad">
        <button class="pekKnapp liten" data-tap="KeyV">VY</button>
        <button class="pekKnapp liten" data-tap="KeyT">BOK</button>
        <button class="pekKnapp liten" data-tap="KeyM">LJUD</button>
      </div>
      <button class="pekKnapp liten" data-hall="ShiftLeft">JOGGA</button>
      <button class="pekKnapp stor" data-tap="KeyE">ANVÄND</button>
    </div>
    <div class="pekKnappar" id="pekRitt" style="display:none">
      <div class="pekSmaRad">
        <button class="pekKnapp liten" data-tap="KeyV">VY</button>
        <button class="pekKnapp liten" data-tap="KeyR">LÄTTR.</button>
        <button class="pekKnapp liten" data-tap="KeyQ">DIAG</button>
        <button class="pekKnapp liten" data-tap="KeyN">NÄSTA</button>
      </div>
      <div class="pekSmaRad">
        <button class="pekKnapp" data-hall="ShiftLeft">LÄTT</button>
        <button class="pekKnapp" data-hall="ControlLeft">DJUP</button>
      </div>
      <button class="pekKnapp" data-tap="KeyE">HALVHALT</button>
      <button class="pekKnapp stor" data-hall="Space">TYGEL</button>
    </div>`;
  document.body.appendChild(ui);

  /* Syntetiska tangenter — samma väg in som tangentbordet. */
  const nere={};
  function tangent(code,on){
    if(on&&!nere[code]){nere[code]=1;
      dispatchEvent(new KeyboardEvent("keydown",{code}));}
    else if(!on&&nere[code]){delete nere[code];
      dispatchEvent(new KeyboardEvent("keyup",{code}));}
  }

  /* Joysticken. Två saker gör den lätt i handen:

     1. Den utgår från FINGRET. Trycker man var som helst i zonen
        (nedre vänstra hörnet) flyttar sig spaken dit — ingen behöver
        pricka en cirkel på 132 px medan man tittar på hästen.
     2. Den är ANALOG till fots: liten lutning ger sakta gång, mer ger
        full gång, och längst ut övergår gången i jogg utan extra
        knapp. Värdena läses av stegaVandring via IN.analog.

     I sadeln synteseras samma tangenter som förut (W/S/A/D) — hjälperna
     är avsiktligt av/på: ridningens känsla ligger i modellen, inte i
     spakens vinkel. */
  const zon=document.getElementById("joyZon"),
        joy=document.getElementById("joy"), knopp=document.getElementById("joyKnopp");
  let joyPek=null, joyCX=0, joyCY=0;
  function joyPlacera(e){
    const zr=zon.getBoundingClientRect(), r=joy.getBoundingClientRect().width/2;
    joyCX=clamp(e.clientX, zr.left+r, zr.right-r);
    joyCY=clamp(e.clientY, zr.top+r, zr.bottom-r);
    joy.style.left=(joyCX-zr.left-r)+"px";
    joy.style.top=(joyCY-zr.top-r)+"px";
    joy.style.bottom="auto";
  }
  function joyLage(e){
    const r=joy.getBoundingClientRect().width/2;
    const dx=(e.clientX-joyCX)/r, dy=(e.clientY-joyCY)/r;
    const l=Math.hypot(dx,dy), k=l>1?1/l:1;
    knopp.style.transform=`translate(calc(-50% + ${dx*k*r*0.55}px), calc(-50% + ${dy*k*r*0.55}px))`;
    /* Analogt till fots: fram 0→1 (dödzon 0,15), över 0,85 börjar
       joggen fasas in. Bakåt och sväng har sina egna dödzoner. */
    let fram=0;
    if(dy<-0.15)fram=Math.min((-dy-0.15)/0.60,1.30);
    else if(dy>0.30)fram=-0.6*Math.min((dy-0.30)/0.50,1);
    const sv=Math.abs(dx)>0.18
      ? Math.sign(dx)*Math.min((Math.abs(dx)-0.18)/0.55,1) : 0;
    IN.analog={fram:Math.min(fram,1), jogg:clamp((fram-0.85)/0.45,0,1), sv};
    /* Tangenterna för ridningen (och allt annat som lyssnar på dem). */
    tangent("KeyW", dy<-0.28);
    tangent("KeyS", dy> 0.45);
    tangent("KeyA", dx<-0.32);
    tangent("KeyD", dx> 0.32);
  }
  function joySlapp(){
    joyPek=null;
    IN.analog=null;
    knopp.style.transform="translate(-50%,-50%)";
    joy.style.left=""; joy.style.top=""; joy.style.bottom="";   // åter till viloplatsen
    for(const c of ["KeyW","KeyS","KeyA","KeyD"]) tangent(c,false);
  }
  zon.addEventListener("pointerdown",e=>{joyPek=e.pointerId;
    try{zon.setPointerCapture(e.pointerId);}catch(_){}
    joyPlacera(e); joyLage(e); e.preventDefault();});
  zon.addEventListener("pointermove",e=>{if(e.pointerId===joyPek)joyLage(e);});
  zon.addEventListener("pointerup",joySlapp);
  zon.addEventListener("pointercancel",joySlapp);

  /* Knapparna: data-hall hålls, data-tap är ett tryck. */
  for(const b of ui.querySelectorAll("[data-hall]")){
    const code=b.dataset.hall;
    b.addEventListener("pointerdown",e=>{b.classList.add("ner");
      tangent(code,true); e.preventDefault();});
    for(const ev of ["pointerup","pointercancel","pointerleave"])
      b.addEventListener(ev,()=>{b.classList.remove("ner"); tangent(code,false);});
  }
  for(const b of ui.querySelectorAll("[data-tap]")){
    const code=b.dataset.tap;
    b.addEventListener("pointerdown",e=>{b.classList.add("ner");
      tangent(code,true); e.preventDefault();});
    for(const ev of ["pointerup","pointercancel"])
      b.addEventListener(ev,()=>{b.classList.remove("ner");
        setTimeout(()=>tangent(code,false),60);});
  }

  /* Visa rätt knappuppsättning för scenen; göm allt under overlay. */
  const gang=document.getElementById("pekGang"), ritt=document.getElementById("pekRitt");
  setInterval(()=>{
    const ov2=document.getElementById("ov");
    const overlayUppe=ov2&&!ov2.classList.contains("hide");
    const rider=G.scen==="lektion"||G.scen==="bana";
    const gar=G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne";
    ui.style.display=overlayUppe||(!rider&&!gar)?"none":"";
    gang.style.display=gar?"":"none";
    ritt.style.display=rider?"":"none";
  },250);
})();
