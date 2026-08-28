/* ══════════════════════════════════════════════════════════════════
   FRAMSTEGEN — att bli bättre, och att det märks.

   Gruppstegen i ryttare.js säger vilken nivå du rider på. Den här filen
   säger vad du faktiskt *kan*, och ser till att det får konsekvenser i
   ridningen.

   Fyra färdigheter, alla 0–1. De växer aldrig av en knapp — de växer av
   det du gör medan du rider och sköter, mätt i modellen som redan finns:

     sits     lugn i sitsen. Växer när du inte kastar med kroppen.
     hand     mjuk hand. Växer när tygeln ligger i bandet och handen
              inte rycker.
     kansla   timing. Växer på lyckade halvhalter och när du får ned
              hästens spänning.
     skotsel  hästkunskap. Växer av skötsel som blir bra.

   Och det viktiga: färdigheterna matas TILLBAKA in i ridmodellen som
   toleranser. En van ryttare får ett bredare band att träffa inom — inte
   en bonus på slutbetyget. Samma övning blir alltså faktiskt lättare att
   rida, av samma skäl som den blir det i verkligheten: du behöver inte
   längre vara exakt för att hästen ska förstå dig.

   Kravet stiger samtidigt med gruppen. De två rör sig mot varandra, och
   det är meningen — annars vore det antingen tröstlöst eller trivialt.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const FARDIGHETER=[
  {id:"sits",    namn:"Sits",     text:"Lugn i sadeln"},
  {id:"hand",    namn:"Hand",     text:"Mjuk tygelkontakt"},
  {id:"kansla",  namn:"Känsla",   text:"Timing och halvhalter"},
  {id:"skotsel", namn:"Hästkunskap", text:"Skötsel och omvårdnad"},
];

/* Hur snabbt en färdighet får växa. Medvetet långsamt: den ska märkas
   över ett pass, inte över en långsida. Taket sjunker ju högre du
   kommer — de sista tiondelarna ska kosta. */
const VAXT={sits:0.055, hand:0.060, kansla:0.045, skotsel:0.080};

function nyFardighet(){ return {sits:0.12, hand:0.10, kansla:0.08, skotsel:0.15}; }

/* Färdigheterna bor i ryttarprofilen och sparas med den. */
function fard(){
  if(!SPAR)return nyFardighet();
  if(!SPAR.fardighet)SPAR.fardighet=nyFardighet();
  for(const f of FARDIGHETER)
    if(typeof SPAR.fardighet[f.id]!=="number")SPAR.fardighet[f.id]=nyFardighet()[f.id];
  return SPAR.fardighet;
}

/* ── Toleranserna som skickas in i ridmodellen ────────────────────
   Varje rad är ett löfte: så här mycket lättare blir det av att kunna.
   Håll dem små. Går de för högt blir hästen en cykel. */
function fardighetsMod(){
  const f=fard();
  return {
    /* Bredare amplitudfönster: handen får darra mer innan mjukheten
       faller. Det här är den enskilt tydligaste lättnaden. */
    amplitud: 1+0.85*f.hand,
    /* Tygelbandets övre kant flyttas upp — du får ta mer tygel utan
       att hästen tolkar det som hårdhet. */
    tygelband: 0.12*f.hand,
    /* Halvhaltens tidsfönster vidgas och gesten får vara mindre. */
    hhFonster: 1+0.55*f.kansla,
    hhAmplitud: 1-0.35*f.kansla,
    /* En lugn sits och läst känsla håller ned spänningen. */
    lugn: 0.55*f.sits+0.35*f.kansla,
    /* Mjukheten hittar tillbaka snabbare efter ett misstag. */
    mjukhetFart: 1+0.60*f.sits,
  };
}

/* ── Växten ───────────────────────────────────────────────────────
   Anropas varje bildruta under ridning. Mäter det som pågår och låter
   färdigheten krypa uppåt. Returnerar id på en färdighet som just
   passerade ett helt tiondels steg, för att kunna visa det.

   Ingen färdighet växer medan hästen är spänd över 0,7 — då lär man
   sig fel saker, och det ska spelet inte belöna. */
function stegaFardighet(ride,aids,dt){
  if(!SPAR||!ride||ride.spanning>0.70)return null;
  const f=fard(), fore={...f};

  /* Sits: låg spänning i dina egna sitsutslag och en häst som inte
     stör sig. Mäts som mjukhet, som redan är amplitud mot medel. */
  if(ride.mjukhet>0.62)
    f.sits=clamp(f.sits+VAXT.sits*dt*(ride.mjukhet-0.62)*(1-f.sits)*1.6,0,1);

  /* Hand: tygeln i det mjuka bandet, varken slak eller hård. */
  const t=aids.tygel;
  if(t>K.TYGEL_BAND_MIN&&t<K.TYGEL_BAND_MAX&&ride.skala.kontakt>0.35)
    f.hand=clamp(f.hand+VAXT.hand*dt*(1-f.hand)*1.4,0,1);

  /* Känsla: spänningen sjunker medan du rider. Det är den enda
     färdighet som mäter en förändring i stället för ett tillstånd. */
  if(ride._spanningFore===undefined)ride._spanningFore=ride.spanning;
  const dSp=ride._spanningFore-ride.spanning;
  ride._spanningFore=ride.spanning;
  if(dSp>0&&ride.skala.losgjordhet>0.30)
    f.kansla=clamp(f.kansla+VAXT.kansla*dSp*40*dt*(1-f.kansla),0,1);

  for(const k of FARDIGHETER){
    const id=k.id;
    if(Math.floor(f[id]*10)>Math.floor(fore[id]*10))return id;
  }
  return null;
}

/* Skötseln ger hästkunskap. Anropas när ett skötselmoment bedömts. */
function fardighetSkotsel(kvalitet){
  if(!SPAR)return null;
  const f=fard(), fore=f.skotsel;
  if(kvalitet>0.55)
    f.skotsel=clamp(f.skotsel+VAXT.skotsel*(kvalitet-0.55)*(1-f.skotsel)*2.2,0,1);
  sparaRyttare();
  return Math.floor(f.skotsel*10)>Math.floor(fore*10)?"skotsel":null;
}

/* Ett tal att visa: hur mycket lättare det har blivit, i procent mot
   en nybörjare. Används i profilen och efter passet. */
function fardighetSammanfattning(){
  const f=fard();
  const snitt=(f.sits+f.hand+f.kansla+f.skotsel)/4;
  return {
    snitt,
    niva: snitt<0.20?"Nybörjare" : snitt<0.40?"Van nybörjare"
        : snitt<0.60?"Rutinerad" : snitt<0.80?"Säker" : "Erfaren",
    lattnad: Math.round(fardighetsMod().amplitud*100-100),
  };
}

/* ── Momentets mål ────────────────────────────────────────────────
   Vad som krävs för att ett moment ska räknas som gjort. Kravet kommer
   från gruppen och stiger när du flyttas upp; din färdighet gör det
   lättare att nå. De två rör sig mot varandra med flit.

   Momenten som inte har ett mätbart mål — hoppbanan, avsittningen —
   returnerar null och behåller sin klocka. */
function momentMal(m,grupp){
  if(!m||m.id==="bana"||m.bedoms===false)return null;
  const forvantan=Skala.FORVANTAN[grupp]||0.55;
  /* Kravet ligger strax under gruppens förväntan: målet är att visa att
     du kan hålla nivån, inte att prestera över den. */
  const krav=clamp(forvantan*0.88,0.12,0.85);
  /* Hålltiden är kortare än den gamla klockan. Ett moment som kräver
     tjugo sekunders hållen kvalitet är svårare än fyrtio sekunders
     väntan, och tar ändå halva tiden. */
  const hall=clamp((m.tid||30)*0.45,8,26);
  return {krav,hall,vad:"inverkan"};
}

/* Texten som står under stapeln, så att spelaren vet vad som mäts. */
function momentMalText(m,grupp){
  const mal=momentMal(m,grupp);
  if(!mal)return "";
  return `Håll inverkan över ${mal.krav.toFixed(2).replace(".",",")} i ${Math.round(mal.hall)} s`;
}

/* ── Det som syns ─────────────────────────────────────────────────
   Två rader i HUD:en, uppdaterade varje bildruta. Den ena visar hästen,
   den andra dig. Poängen är att de rör sig medan man rider — ett värde
   som bara syns efteråt lär ingen någonting. */
function ritaVaxer(){
  const ruta=document.getElementById("vaxer");
  if(!ruta)return;
  const rid=(G.scen==="lektion"||G.scen==="bana")&&G.ride;
  ruta.style.display=rid?"":"none";
  if(!rid)return;

  /* Hästen: lösgjordheten upp och spänningen ned, sammanvägt. Det är
     det spelaren känner som "hon börjar slappna av". */
  const hast=clamp(G.ride.skala.losgjordhet*0.65+(1-G.ride.spanning)*0.35,0,1);
  /* Du: mjukheten just nu, alltså hur stilla dina hjälper ligger. */
  const du=clamp(G.ride.mjukhet,0,1);

  const h=document.querySelector("#vHast i"), d=document.querySelector("#vDu i");
  if(h)h.style.width=(hast*100).toFixed(0)+"%";
  if(d)d.style.width=(du*100).toFixed(0)+"%";
}

let _blixtT=0;
function visaFardighetsSteg(id){
  const k=FARDIGHETER.find(f=>f.id===id); if(!k)return;
  sparaRyttare();
  let el=document.getElementById("fardBlixt");
  if(!el){
    el=document.createElement("div"); el.id="fardBlixt"; document.body.appendChild(el);
  }
  const v=Math.round(fard()[id]*100);
  el.textContent=`${k.namn} ${v} — ${k.text}`;
  el.classList.add("pa"); _blixtT=performance.now();
  /* Två stötar en kvint isär — kort, och bara när något faktiskt hänt. */
  if(typeof ljudStot==="function"){
    ljudStot(660,"sine",0.10,0.05);
    setTimeout(()=>ljudStot(990,"sine",0.14,0.045),90);
  }
  setTimeout(()=>{ if(performance.now()-_blixtT>1700)el.classList.remove("pa"); },1800);
}
