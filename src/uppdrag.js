/* ══════════════════════════════════════════════════════════════════
   UPPDRAG — spelets enda objective/navigation-sanning.

   PO-order 2026-09-06: spelaren ska inom 1–2 sekunder kunna svara på
   tre frågor — VAD ska jag göra, VAR är det, HUR tar jag mig dit — och
   alla ytor ska läsa samma tillstånd. Förut ägde varje yta sin egen
   uppfattning: uppgiftspanelen hade en kedja av if-satser, ridlärarens
   replik en annan, whiteboarden en tredje, och markören en fjärde. Då
   kunde de säga emot varandra, och det gjorde de.

   Här ligger kedjan EN gång:

     prata med ridläraren → hitta hästen → hämta sadel + träns →
     tillbaka till hästen (sköt om och sadla) → sitt upp

   Varje steg bär sin egen rubrik, sina punkter och sitt mål i världen.
   Rubrik + högst tre punkter — texten ska gå att skanna, inte läsas.

   Ingen text här hittar på en UBRF-detalj. Boxen har inget verifierat
   nummer i repot, så uppdraget säger "boxen" och pekar på dörren i
   stället för att uppfinna "Box 12". Pronomen kommer ur hästdatan
   (HORSES[...].pronomen); saknas källa används namnet.
   ══════════════════════════════════════════════════════════════════ */

const UPPDRAG={
  /* Vägvisaren tonas bort när man är framme — då tar den lokala
     markören och interaktionstexten över. */
  NARA:3.0, FJARRAN:8.0,
  färg:"#E8B54A",
};

/* ── Pronomen ur hästdatan, aldrig gissade ────────────────────── */
function hastPron(id,form){
  const h=(typeof HORSES!=="undefined")&&HORSES[id]; if(!h)return "hästen";
  const p=h.pronomen||{};
  if(form==="poss")return p.poss||`${h.namn}s`;
  return p[form==="obj"?"obj":"subj"]||h.namn;
}
function hastNamn(id){
  const h=(typeof HORSES!=="undefined")&&HORSES[id||G.hastId];
  return h?h.namn:"hästen";
}

/* ── AKTIV HÄST — en sanning, ett ställe som får byta den ─────── */
/* PO-order 2026-09-06: spelaren ska kunna byta häst före ridmomentet,
   och hela vägledningskedjan ska följa med direkt. `G.hastId` ÄR den
   aktiva hästen; det här är enda funktionen som får ändra den, så att
   inget kan lämnas kvar från den förra. Tilldelningen och bytet går
   genom samma rad kod — annars vore "en sanning" bara en avsikt.

   Allt som hänger på hästen nollas: platsen, mötet, utrustningen,
   skötseln, sysslorna, täcket, leran och spåret efter den förra
   hästen. Missas ett fält blir det ett spöke: sadeln till Lydia i
   handen medan uppdraget pekar på en annan häst. */
function sattAktivHast(id){
  if(typeof HORSES==="undefined"||!HORSES[id])return false;
  G.hastId=id;
  G.hastPlats="box";          // hästen står i sin box när dagen börjar
  G.hastMott=false;
  G.utrustning=false; G.felUtrustning=0;
  G.skotselRes=null; G.sysslor={mockat:0,fodrat:0};
  G.tackePa=false; G.fangstForsok=false; G.lerig=false; G.spolad=0;
  if(typeof VD!=="undefined"&&VD.spår)VD.spår.length=0;
  return true;
}

/* Hästar som går att välja: de som FAKTISKT står uppstallade i en box.
   Utan box finns ingen punkt att peka på, och då kan vägledningen inte
   svara på "var är det". Ingen häst hittas på. */
function valbaraHastar(){
  if(typeof STALLINNE==="undefined")return [];
  const ut=[];
  for(const rad of STALLINNE.rader)
    for(const id of (STALLINNE.boxar[rad.id]||[]))
      if(id&&HORSES[id]&&!ut.includes(id))ut.push(id);
  return ut;
}

/* ── Punkterna i världen ──────────────────────────────────────── */
function uppdragHastPunkt(){
  if(!G.hastId)return null;
  if(G.hastPlats==="hage")
    return {scen:"gard", pos:ANL.hamtHage.grind, var:"Hagen öster om stallet"};
  if(G.hastPlats==="leds")
    return {scen:G.scen, pos:[VD.hastX,VD.hastY], var:"Vid din hand"};
  const b=(typeof hittaBox==="function")&&hittaBox(G.hastId);
  return b?{scen:"stallinne", pos:b.dorr, var:"Boxen i stallet"}:null;
}
function uppdragSadelkammare(){
  const i=((typeof STALLINNE!=="undefined"&&STALLINNE.info)||[]).find(i=>i.sadelkammare);
  return i?{scen:"stallinne", pos:i.pos, var:"Sadelkammaren"}:null;
}
function uppdragUppsittning(){
  if(typeof SPELABSTRAKTIONER==="undefined")return null;
  const sp=SPELABSTRAKTIONER.ridhus.sargport, R=RIDHUSINNE;
  return {scen:"ridhusinne", pos:[(sp.x0+sp.x1)/2, R.bana.y+R.bana.h],
    var:"Ridhuset — sargporten"};
}

/* ── Kedjan ───────────────────────────────────────────────────── */
/* Ett steg: {id, rubrik, punkter[], mal:{scen,pos,var}, hastId}.
   `hastId` sätts bara när målet ÄR hästen — det är det markören på
   den tilldelade hästen frågar efter. */
function uppdragMal(){
  if(G.scen!=="gard"&&G.scen!=="stallinne"&&G.scen!=="ridhusinne")return null;
  const n=hastNamn();
  if(!G.hastId){
    const p=(typeof STALLINNE!=="undefined")&&STALLINNE.ridlarare;
    return {id:"ridlarare", rubrik:"Prata med ridläraren",
      punkter:["Stallgången, rakt in genom entrén"],
      mal:p?{scen:"stallinne", pos:p.pos, var:"Stallgången"}:null};
  }
  const hast=uppdragHastPunkt();
  if(G.hastPlats==="hage")
    return {id:"hamta_hast", rubrik:`Hämta ${n} i hagen`,
      punkter:["Grinden på hagens västra sida","Öppna med E"],
      mal:hast, hastId:G.hastId};
  if(G.hastPlats==="leds"&&!G.skotselRes)
    return {id:"led_till_box", rubrik:`Led ${n} till boxen`,
      punkter:[G.lerig?"Spolspiltan först — leriga ben":"In genom stalldörren",
        "Släpp in i boxen med E"],
      mal:(typeof hittaBox==="function"&&hittaBox(G.hastId))
        ?{scen:"stallinne", pos:hittaBox(G.hastId).dorr, var:"Boxen i stallet"}:null};
  if(!G.skotselRes){
    if(!G.hastMott)
      return {id:"hitta_hast", rubrik:`Hitta ${n}`,
        punkter:["Boxen i stallet — namnskylten på dörren","Följ den gula vägvisaren"],
        mal:hast, hastId:G.hastId};
    if(!G.utrustning)
      return {id:"utrustning", rubrik:"Hämta sadel + träns",
        punkter:["Sadelkammaren, innanför uppehållsrummet",
          `Ta ${hastPron(G.hastId,"poss")} egen bygel — namnskylten`],
        mal:uppdragSadelkammare()};
    return {id:"skotsel", rubrik:`Sköt om och sadla ${n}`,
      punkter:["Tillbaka till boxen","Mocka, fodra, visitera, sadla (E)"],
      mal:hast, hastId:G.hastId};
  }
  return {id:"sitt_upp", rubrik:`Sitt upp på ${n}`,
    punkter:["Led hästen till sargporten i ridhuset",
      "När “Sitt upp” visas: tryck E / Interagera"],
    mal:uppdragUppsittning()};
}

/* ── Vägvisaren: målet, eller dörren dit ──────────────────────── */
/* Ligger målet i en annan scen är svaret på "hur tar jag mig dit" inte
   målet självt utan dörren ut. Vägvisaren pekar därför på en punkt i
   den scen spelaren FAKTISKT står i. */
function uppdragDorrMot(malScen){
  const via=(G.scen==="gard")?malScen:"gard";
  const lista=G.scen==="gard"?ANL.dorrar
    :G.scen==="stallinne"?STALLINNE.dorrar
    :(typeof RIDHUSINNE!=="undefined"?RIDHUSINNE.dorrar:[]);
  return (lista||[]).find(d=>d.mot===via)||null;
}
function uppdragVagvisare(){
  const u=uppdragMal();
  if(!u||!u.mal)return null;
  let pos=u.mal.pos, iScen=(u.mal.scen===G.scen), viaDorr=null;
  if(!iScen){
    viaDorr=uppdragDorrMot(u.mal.scen);
    if(!viaDorr)return null;
    pos=viaDorr.pos;
  }
  const avstand=Math.hypot(VD.px-pos[0], VD.py-pos[1]);
  /* Tonas ned ju närmare man kommer — framme tar den lokala markören
     och E-prompten över, och en pil kvar då är bara brus. */
  const alfa=clamp((avstand-UPPDRAG.NARA)/(UPPDRAG.FJARRAN-UPPDRAG.NARA),0,1);
  /* Framme vid målet ska VÄGVISAREN vara borta och den lokala
     markören över själva objektet ta över (PO 2026-09-06). `nara`
     är samma räckvidd som interaktionen (2,4 m) — där E biter. */
  return {id:u.id, rubrik:u.rubrik, pos:[pos[0],pos[1]], iScen,
    viaDorr:viaDorr?viaDorr.text:null, avstand, alfa, synlig:alfa>0.01,
    nara:iScen&&avstand<=2.4};
}

/* Ska DEN HÄR hästen bära markören? Renderarna frågar, de avgör inte
   själva — annars går det inte att prova att bara rätt häst märks. */
function uppdragGallerFor(hastId){
  const u=uppdragMal();
  if(!u||!u.hastId||!hastId||u.hastId!==hastId)return false;
  const v=uppdragVagvisare();
  return !!(v&&v.iScen);
}

/* Uppgiftspanelens text: rubrik + högst tre punkter. */
function uppdragText(){
  const u=uppdragMal();
  if(!u)return null;
  const v=uppdragVagvisare();
  const punkter=u.punkter.slice(0,3);
  /* Står målet i en annan byggnad är FÖRSTA punkten vägen dit — det är
     svaret på "hur tar jag mig dit", och det ska stå först. */
  if(v&&!v.iScen&&v.viaDorr)punkter.unshift(v.viaDorr);
  return {rubrik:u.rubrik, punkter:punkter.slice(0,3), id:u.id};
}

/* ══════════════════════════════════════════════════════════════════
   SENIOR UX HOTFIX — alltid synlig vägvisare ovanpå canvasen.

   Canvas-pilen visade sig vara för subtil i faktisk gameplay. Den här
   HUD-markören läser exakt samma `uppdragVagvisare()` och lägger inget
   nytt state ovanpå spelet. Skillnaden är presentationen: spelaren ska
   inte behöva leta efter själva hjälpsystemet.
   ══════════════════════════════════════════════════════════════════ */
function installeraTydligVagvisare(){
  if(typeof document==="undefined"||document.getElementById("ubrfVagvisare"))return;

  const stil=document.createElement("style");
  stil.id="ubrfVagvisareStil";
  stil.textContent=`
    #ubrfVagvisare{position:fixed;left:0;top:0;width:0;height:0;z-index:70;pointer-events:none;
      font-family:'IBM Plex Sans',system-ui,sans-serif;display:none}
    #ubrfVagvisare .pin{position:absolute;transform:translate(-50%,-100%);display:flex;flex-direction:column;
      align-items:center;gap:4px;filter:drop-shadow(0 2px 5px rgba(0,0,0,.65))}
    #ubrfVagvisare .pil{width:28px;height:28px;border-radius:50%;background:#E8B54A;color:#17140A;
      display:grid;place-items:center;font-size:20px;font-weight:900;border:3px solid rgba(255,255,255,.9);
      animation:ubrfPuls 1.1s ease-in-out infinite}
    #ubrfVagvisare .etikett{white-space:nowrap;background:rgba(20,20,18,.94);color:#fff;border:2px solid #E8B54A;
      border-radius:999px;padding:6px 10px;font-size:13px;font-weight:800;letter-spacing:.01em}
    #ubrfVagvisare.nara .pil{width:34px;height:34px;font-size:22px}
    #ubrfVagvisare.nara .etikett{background:#E8B54A;color:#17140A;font-size:14px}
    @keyframes ubrfPuls{0%,100%{transform:translateY(0) scale(1)}50%{transform:translateY(-5px) scale(1.08)}}
  `;
  document.head.appendChild(stil);

  const rot=document.createElement("div");
  rot.id="ubrfVagvisare";
  rot.innerHTML='<div class="pin"><div class="pil">▼</div><div class="etikett"></div></div>';
  document.body.appendChild(rot);
  const pin=rot.querySelector(".pin"), etikett=rot.querySelector(".etikett"), pil=rot.querySelector(".pil");

  function skarmPos(v){
    if(typeof cx==="undefined"||!cx||!cx.canvas)return null;
    const canvas=cx.canvas, rect=canvas.getBoundingClientRect();
    if(!rect.width||!rect.height)return null;
    let sx=null,sy=null,bakom=false;
    try{
      if(G.vy==="2d"&&typeof V2T!=="undefined"&&V2T&&V2T.scen===G.scen){
        sx=V2T.ox+v.pos[0]*V2T.s;
        sy=V2T.oy+(V2T.hojd-v.pos[1])*V2T.s;
      }else if(typeof kamera==="function"&&typeof tillKam==="function"&&typeof projK==="function"){
        const k=kamera(), pk=tillKam(k,v.pos[0],v.pos[1],1.7);
        if(typeof K3!=="undefined"&&pk.d<K3.nara){sx=CW/2;sy=CH*0.35;bakom=true;}
        else {const p=projK(k,pk);sx=p[0];sy=p[1];}
      }
    }catch(_){return null;}
    if(!Number.isFinite(sx)||!Number.isFinite(sy))return null;
    const px=rect.left+(sx/CW)*rect.width, py=rect.top+(sy/CH)*rect.height;
    const m=44;
    return {x:clamp(px,rect.left+m,rect.right-m),y:clamp(py,rect.top+m,rect.bottom-m),
      utanför:bakom||px<rect.left+m||px>rect.right-m||py<rect.top+m||py>rect.bottom-m};
  }

  function tick(){
    let v=null,u=null;
    try{
      u=(typeof uppdragMal==="function")?uppdragMal():null;
      v=(typeof uppdragVagvisare==="function")?uppdragVagvisare():null;
    }catch(_){}
    const dolj=!u||!v||(typeof overlayUppe==="function"&&overlayUppe());
    if(dolj){rot.style.display="none";requestAnimationFrame(tick);return;}
    const p=skarmPos(v);
    if(!p){rot.style.display="none";requestAnimationFrame(tick);return;}

    rot.style.display="block";
    rot.classList.toggle("nara",!!v.nara);
    pin.style.left=`${p.x}px`; pin.style.top=`${p.y}px`;
    const av=Math.max(0,Math.round(v.avstand));
    const namn=(u.hastId&&typeof HORSES!=="undefined"&&HORSES[u.hastId])?HORSES[u.hastId].namn:null;
    etikett.textContent=v.nara
      ? (namn?`HÄR · ${namn}`:`HÄR · ${u.rubrik}`)
      : `${u.rubrik} · ${av} m`;
    pil.textContent=p.utanför?"➜":"▼";
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}

if(typeof window!=="undefined"){
  if(document.readyState==="complete")installeraTydligVagvisare();
  else window.addEventListener("load",installeraTydligVagvisare,{once:true});
}
