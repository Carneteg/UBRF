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
   kommer — de sista tiondelarna ska kosta, och därför dämpas växten med
   (1−f)³ och inte (1−f). Med de gamla talen tog en enda felfri lektion
   en nybörjare från 0,12 till nästan 1,00; det syntes först när
   efter-passet började redovisa vad som faktiskt växte. */
const VAXT={sits:0.020, hand:0.022, kansla:0.017, skotsel:0.045};

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
    /* Att hålla ihop hästen. En van ryttare låter henne inte glida iväg
       från början, så avdriften dämpas. Det här är skillnaden mellan att
       rätta till hela tiden och att bara rida — och den märks direkt i
       hur många korrigeringar ett moment kostar. */
    halla: 0.48*f.sits+0.34*f.kansla,
    /* Spänningen sjunker undan snabbare. Bara egenskapen Lugn rör den
       här — färdigheterna verkar på pressen, inte på återhämtningen. */
    spanningFall: 1,
  };
}

/* Egenskaperna ovanpå färdigheterna. De valda tre lutar samma
   toleranser som färdigheterna, men de växer inte — de är det du bar
   med dig när du kom hit. Additivt, och medvetet mycket mindre än vad
   ett halvt liv i sadeln ger. */
function fardighetsModMedJag(){
  const m=fardighetsMod();
  const j=(typeof jagMod==="function")?jagMod():{};
  if(j.halla)       m.halla       += j.halla;
  if(j.mjukhetFart) m.mjukhetFart += j.mjukhetFart;
  if(j.lugn)        m.lugn        += j.lugn;
  if(j.tygelband)   m.tygelband   += j.tygelband;
  if(j.amplitud)    m.amplitud    += j.amplitud;
  if(j.spanningFall)m.spanningFall+= j.spanningFall;
  if(j.skygghet)    m.skygghet     = (m.skygghet||0)+j.skygghet;
  if(j.hhFonster)   m.hhFonster   += j.hhFonster;
  if(j.hhAmplitud)  m.hhAmplitud  += j.hhAmplitud;
  return m;
}

/* ── Växten ───────────────────────────────────────────────────────
   Anropas varje bildruta under ridning. Mäter det som pågår och låter
   färdigheten krypa uppåt. Returnerar id på en färdighet som just
   passerade ett helt tiondels steg, för att kunna visa det.

   Ingen färdighet växer medan hästen är spänd över 0,7 — då lär man
   sig fel saker, och det ska spelet inte belöna. */
function stegaFardighet(ride,aids,dt){
  if(!SPAR||!ride||ride.spanning>0.70)return null;
  /* Man lär sig inte rida av att stå still. Utan det här villkoret
     växte sits och hand som mest i halt, där hjälperna ligger stilla av
     sig själva och ingenting kan gå fel — precis den strategi resten av
     spelet är byggt för att inte belöna. */
  if(ride.tempo<0.45)return null;
  /* Och växten kräver samma sak som momentet: att du håller henne i
     tempot. Utan det räckte det att sitta blick stilla medan hon sprang
     ifrån bandet — hjälperna låg still, mjukheten låg på 1,00, och
     färdigheterna växte alltså som snabbast när ridningen var som
     sämst. Att rida är att korrigera; det ska växten också mäta. */
  if(typeof iTempoBand==="function"&&!iTempoBand(ride,G.grupp))return null;
  const f=fard(), fore={...f};
  /* Kontinuerligt lärande snabbar på växten — men villkoren ovan gäller
     fortfarande. Egenskapen ger ingenting gratis; den gör bara att det du
     faktiskt gör bra fastnar lite fortare. */
  dt*=1+(((typeof jagMod==="function")&&jagMod().larande)||0);

  /* Sits: låg spänning i dina egna sitsutslag och en häst som inte
     stör sig. Mäts som mjukhet, som redan är amplitud mot medel. */
  if(ride.mjukhet>0.62)
    f.sits=clamp(f.sits+VAXT.sits*dt*(ride.mjukhet-0.62)*(1-f.sits)**3*1.6,0,1);

  /* Hand: tygeln i det mjuka bandet, varken slak eller hård. */
  const t=aids.tygel;
  if(t>K.TYGEL_BAND_MIN&&t<K.TYGEL_BAND_MAX&&ride.skala.kontakt>0.35)
    f.hand=clamp(f.hand+VAXT.hand*dt*(1-f.hand)**3*1.4,0,1);

  /* Känsla: spänningen sjunker medan du rider. Det är den enda
     färdighet som mäter en förändring i stället för ett tillstånd — och
     därför den lättaste att lura. Med "sjönk sedan förra bildrutan" gav
     en ryttare som hackade med hjälperna mest känsla av alla, eftersom
     spänningen studsade upp och ned hela passet och varje nedstuds
     räknades. Bara NY mark räknas nu: referensen är det lägsta hon
     varit på, och den kryper långsamt uppåt så att nästa moment kan
     förtjäna sitt eget. */
  if(ride._spanningRef===undefined)ride._spanningRef=ride.spanning;
  ride._spanningRef=Math.min(ride._spanningRef+0.010*dt,1);
  if(ride.spanning<ride._spanningRef-0.001&&ride.skala.losgjordhet>0.30){
    const vinst=ride._spanningRef-ride.spanning;
    f.kansla=clamp(f.kansla+VAXT.kansla*vinst*40*dt*(1-f.kansla)**3,0,1);
    ride._spanningRef=ride.spanning;
  }

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
    f.skotsel=clamp(f.skotsel+VAXT.skotsel*(kvalitet-0.55)*(1-f.skotsel)**3*2.2,0,1);
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

/* ── Tempobandet ──────────────────────────────────────────────────
   Kvalitetskravet ensamt räcker inte. Utbildningsskalans takt mäter hur
   JÄMNT du rider, inte om tempot är rätt, så en häst som glider bort i
   jämn takt får full pott — och då blir stillasittande optimalt igen.

   Därför måste momentet också kräva ett tempo. Då biter avdriften: hon
   vandrar ut ur bandet och du måste hämta hem henne. Det är det som gör
   ridning till att korrigera i stället för att vänta.

   Bandet är brett för nybörjaren och smalnar uppåt i grupperna. Jämför
   med avdriften: en nöjd, lydig häst glider ±0,35 m/s och håller sig
   mest inne av sig själv; en sur häst glider ±0,63 och kräver att du
   rider varje steg. Det är meningen att en bra dag ska kännas som en
   bra dag. */
function tempoBand(gangart,grupp){
  const g=Gait.G[gangart];
  if(!g||g.norm<=0)return null;
  const forv=Skala.FORVANTAN[grupp]||0.55;
  const bredd=0.30+0.30*(1-forv);
  return {min:g.norm-bredd, max:g.norm+bredd, norm:g.norm, bredd};
}

/* Rider du inom bandet just nu? Halt räknas alltid som inne — man kan
   inte hålla ett tempo man inte har. */
function iTempoBand(ride,grupp){
  if(!ride)return false;
  const b=tempoBand(ride.gangart,grupp);
  if(!b)return true;
  return ride.tempo>=b.min&&ride.tempo<=b.max;
}

/* Texten som står under stapeln, så att spelaren vet vad som mäts. */
function momentMalText(m,grupp){
  const mal=momentMal(m,grupp);
  if(!mal)return "";
  const b=G.ride&&tempoBand(G.ride.gangart,grupp);
  const tempoDel=b?` och tempot mellan ${b.min.toFixed(1).replace(".",",")}`
    +` och ${b.max.toFixed(1).replace(".",",")} m/s`:"";
  return `Håll inverkan över ${mal.krav.toFixed(2).replace(".",",")}${tempoDel}`
    +` i ${Math.round(mal.hall)} s`;
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
