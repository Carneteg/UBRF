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
  .pek .hudh.bl{bottom:172px}
  .pek .hudh.br{bottom:172px}
  /* Ridlärarens replik ska ligga ovanför knapparna, inte under dem —
     och inte heller mitt över figuren, vilket 272 px gjorde på en hög
     porträttskärm. Den läggs precis ovanför knappraden i stället, och
     hålls smal så att den inte täcker vägen framåt. */
  .pek .hudh.bc{bottom:200px; width:min(360px,84vw); font-size:13px}
  .pek #viewToggle{bottom:auto; top:8px; left:auto; right:14px; transform:none}
  /* Touchmål: fingret behöver 44 px, inte 26. Knapparna växer på
     pekskärm i stället för att alla enheter få desktopens mått. */
  .pek #viewToggle button{min-height:44px; min-width:64px; font-size:12px;
    padding:0 16px; display:flex; align-items:center; justify-content:center}
  /* Samma golv för menyernas knappar. Höjden sätts som min-height och inte
     som padding, eftersom flera av de små spökknapparna bär sin padding
     inline — min-height vinner utan att någon inline-regel behöver rivas,
     och inline-flex centrerar texten i den nya höjden. Bredden rörs inte:
     knapparna är redan bredare än 44 px och ska inte tvingas isär. */
  .pek .btn{min-height:44px; min-width:44px;
    display:inline-flex; align-items:center; justify-content:center}
  @supports(padding:max(0px)){        /* hakens och hemknappens säkra zon */
    .pek #viewToggle{top:max(8px,env(safe-area-inset-top))}
    .pek #pekUI{padding-bottom:env(safe-area-inset-bottom)}
    .pek #joy{left:max(18px,env(safe-area-inset-left))}
    .pek .pekKnappar{right:max(14px,env(safe-area-inset-right))}
  }
  @media(max-height:560px) and (orientation:landscape){
    .pek .hudh.bc{bottom:96px; width:min(360px,52vw)}
    .pek .hudh.bl, .pek .hudh.br{bottom:150px}
  }
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
  .pekKnapp.liten{min-width:48px; height:44px; padding:0 12px; font-size:11px}
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

  /* Joysticken: upp=W, ner=S, vänster=A, höger=D. */
  const joy=document.getElementById("joy"), knopp=document.getElementById("joyKnopp");
  let joyPek=null;
  function joyLage(e){
    const r=joy.getBoundingClientRect();
    const dx=(e.clientX-(r.left+r.width/2))/(r.width/2);
    const dy=(e.clientY-(r.top+r.height/2))/(r.height/2);
    const l=Math.hypot(dx,dy), k=l>1?1/l:1;
    knopp.style.transform=`translate(calc(-50% + ${dx*k*36}px), calc(-50% + ${dy*k*36}px))`;
    /* Analogt: hur långt man drar styr styrkan, inte bara riktningen.
       Dödzonen finns för att tummen alltid darrar en aning. */
    const langd=Math.min(l,1);
    IN.joy=langd>0.14?{x:dx*k, y:dy*k, styrka:(langd-0.14)/0.86}:null;

    /* RIDNINGEN får spakens värden rakt, inte som syntetiska tangenter.
       Förut passerade joysticken trösklar och skickade W/A/S/D, så
       spaken såg analog ut medan hästen fick tre lägen: 25, 50 och 100
       procents utslag gav samma sväng. Nu går utslaget in i samma
       normaliserade ridinputlager som tangentbordet skriver till, och
       hästen svarar på hur mycket man ber om.

       Kurvan ger precision nära mitten utan att äta upp de små utslagen.
       En rent kvadratisk kurva gjorde det: ett kvarts spakutslag blev två
       procents styrning, alltså rakt fram i praktiken, och de tre nivåerna
       25/50/100 gav inte tre användbara svängar. Den här formen —
       andelen EXPO rak, resten kubisk — ger ungefär 10, 26 och 100
       procent, vilket är en linjekorrigering, en mjuk båge och en full
       volt. Samma form som radiosändare för modellflyg använder, av
       samma skäl: tummen är inte exakt nära mitten. */
    const EXPO=0.35;
    const kurva=v=>{const a=Math.abs(v);
      return Math.sign(v)*a*(EXPO+(1-EXPO)*a*a);};
    const dodzon=(v,d)=>Math.abs(v)<=d?0:Math.sign(v)*(Math.abs(v)-d)/(1-d);
    if(typeof RIDIN!=="undefined"){
      RIDIN.styr=kurva(dodzon(dx*k,0.07));
      RIDIN.skankel=kurva(dodzon(-dy*k,0.12));
      RIDIN.pek=true;
    }

    /* GÅ-LÄGET läser IN.joy direkt (se stegaVandring), så de syntetiska
       tangenterna behövs inte längre för rörelsen. Kvar är bara knappar
       som VY och BOK, som fortfarande är riktiga tryck. */
  }
  function joySlapp(){
    joyPek=null; IN.joy=null;
    knopp.style.transform="translate(-50%,-50%)";
    for(const c of ["KeyW","KeyS","KeyA","KeyD"]) tangent(c,false);
    if(typeof RIDIN!=="undefined"&&RIDIN.pek){
      RIDIN.styr=0; RIDIN.skankel=0;
    }
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
  /* Håll-knapparna skickar tangenthändelser, och tangentlyssnaren i
     game.js skriver dem till ridinputlagret — TYGEL, LÄTT och DJUP
     hamnar alltså i samma kontrakt som spaken utan egen kod här. */
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
