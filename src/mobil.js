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
  .pek .hud.bl{bottom:172px}
  .pek .hud.br{bottom:172px}
  .pek .hud.bc{bottom:132px; width:min(420px,64vw)}
  #pekUI{position:fixed; inset:0; pointer-events:none; z-index:12}
  #joy{position:absolute; left:18px; bottom:20px; width:132px; height:132px;
    border-radius:50%; background:rgba(24,27,33,.55); border:1.5px solid var(--rule);
    pointer-events:auto; touch-action:none}
  #joyKnopp{position:absolute; left:50%; top:50%; width:56px; height:56px;
    border-radius:50%; background:rgba(214,174,60,.85); border:2px solid #17140A;
    transform:translate(-50%,-50%); transition:transform .06s}
  .pekKnappar{position:absolute; right:14px; bottom:20px; display:flex;
    flex-direction:column; gap:10px; align-items:flex-end; pointer-events:none}
  .pekKnapp{pointer-events:auto; touch-action:none; user-select:none;
    -webkit-user-select:none; min-width:64px; height:56px; padding:0 16px;
    border-radius:28px; background:rgba(24,27,33,.82); border:1.5px solid var(--rule);
    color:var(--ink); font-family:"IBM Plex Mono",monospace; font-size:12px;
    letter-spacing:.06em; display:flex; align-items:center; justify-content:center}
  .pekKnapp.ner{background:var(--gold); color:#17140A; border-color:var(--gold)}
  .pekKnapp.stor{height:64px; min-width:76px; font-size:13px; font-weight:600}
  .pekSmaRad{display:flex; gap:8px}
  .pekKnapp.liten{min-width:44px; height:40px; padding:0 10px; font-size:10.5px}
  @media(max-width:430px){
    #joy{width:112px;height:112px}
    .pekKnapp.stor{height:56px;min-width:64px}
  }`;
  document.head.appendChild(stil);

  const ui=document.createElement("div"); ui.id="pekUI";
  ui.innerHTML=`
    <div id="joy"><div id="joyKnopp"></div></div>
    <div class="pekKnappar" id="pekGang">
      <div class="pekSmaRad">
        <button class="pekKnapp liten" data-tap="KeyV">VY</button>
        <button class="pekKnapp liten" data-tap="KeyT">BOK</button>
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

  /* Joysticken: upp=W, ner=S, vänster=A, höger=D. */
  const joy=document.getElementById("joy"), knopp=document.getElementById("joyKnopp");
  let joyPek=null;
  function joyLage(e){
    const r=joy.getBoundingClientRect();
    const dx=(e.clientX-(r.left+r.width/2))/(r.width/2);
    const dy=(e.clientY-(r.top+r.height/2))/(r.height/2);
    const l=Math.hypot(dx,dy), k=l>1?1/l:1;
    knopp.style.transform=`translate(calc(-50% + ${dx*k*36}px), calc(-50% + ${dy*k*36}px))`;
    tangent("KeyW", dy<-0.28);
    tangent("KeyS", dy> 0.45);
    tangent("KeyA", dx<-0.32);
    tangent("KeyD", dx> 0.32);
  }
  function joySlapp(){
    joyPek=null;
    knopp.style.transform="translate(-50%,-50%)";
    for(const c of ["KeyW","KeyS","KeyA","KeyD"]) tangent(c,false);
  }
  joy.addEventListener("pointerdown",e=>{joyPek=e.pointerId;
    try{joy.setPointerCapture(e.pointerId);}catch(_){}
    joyLage(e); e.preventDefault();});
  joy.addEventListener("pointermove",e=>{if(e.pointerId===joyPek)joyLage(e);});
  joy.addEventListener("pointerup",joySlapp);
  joy.addEventListener("pointercancel",joySlapp);

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
