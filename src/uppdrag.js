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
        punkter:["Boxen i stallet — namnskylten på dörren","Följ pilen"],
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
  return {id:"sitt_upp", rubrik:"Sitt upp",
    punkter:[G.tavling?"Tävlingen rids i ridhuset":"Ridhuset — sargporten vid A",
      "Tryck E vid porten"],
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
