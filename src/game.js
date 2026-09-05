/* ══════════════════════════════════════════════════════════════════
   SPELET — scener, input, fysik på planen, lektion, hoppning, betyg.
   ══════════════════════════════════════════════════════════════════ */

/* ── Input: tryck är handlingar, inte tillstånd ── */

/* ── Ridinputkontraktet ───────────────────────────────────────────
   ETT normaliserat lager mellan enheten och ridmodellen. Tangentbord
   och pekskärm skriver båda hit, och ridningen läser bara härifrån —
   den vet inte vilken enhet spelaren har.

   Förut översattes joysticken till syntetiska W/A/S/D när dess axlar
   passerade en tröskel. Spaken såg analog ut men ridningen fick tre
   lägen, och 25, 50 och 100 procents utslag gav samma sväng. Det är
   den buggen det här lagret finns för.

   Fälten är avsikter, inte hjälper: hur mycket spelaren ber om, i
   spannet −1 till 1. Översättningen till skänkel, tygel och sits sker
   i stegaInput, på ett ställe. ]] */
const RIDIN={
  skankel:0,      // −1 håll tillbaka … 0 neutral … 1 be om framåt
  styr:0,         // −1 vänster … 0 rakt … 1 höger   (styraxeln)
  tygel:0,        // 0 lös … 1 tagen
  sits:0,         // −1 lätt (avlastad) … 0 normal … 1 djup
  pek:false,      // sant när spaken senast rörde värdena
};

/* Utgångsvärdena SKRIVS INTE HÄR. De sätts av ridNollstallHjalp() längre
   ned, ur samma mittvärden som ridAvsiktTillHjalp() ger — se raden efter
   den funktionen.

   Före G02-A.1 P4 stod det .15 i skänkelraden medan neutralläget i
   ridAvsiktTillHjalp() är 0,42. Första ridsekunden rampade hjälpen
   alltså 0,15 → 0,42 av sig själv, och ridmodellen läste den resan som
   en framåtimpuls: hästen gick i skritt så fort man satt upp, utan att
   ryttaren rört någonting. Höll man sedan in W låg resan kvar och gav
   ett andra steg, så en enda tangent tog ekipaget till trav.

   Nollorna nedan är alltså platshållare som skrivs över innan första
   bildrutan. Att skriva neutralläget på två ställen och sedan prova att
   de är lika vore att bevaka en dubblett som inte behöver finnas. */
const IN={
  kan:{skankel:{v:0,mal:0},tygel:{v:0,mal:0},sits:{v:0,mal:0},styrning:{v:0,mal:0}},
  latt:true,diagonal:1,spo:false,hh:-1,ned:{},
  joy:null,          // pekskärmens analoga spak: {x,y,styrka} eller null
};

/* Avsikt → hjälpvärde. Neutralläget — det som gäller när ingenting
   hålls — är inte noll skänkel: en häst rids inte med släppt skänkel.
   Det är därför nollan i varje rad nedan är ett mittvärde och inte 0. Samma kurva för tangent och spak, så att ett
   halvt spakutslag ger precis halva vägen mot tangentens läge. */
/* Sätt hjälpfiltret i neutralläget. Körs när en ritt börjar: annars
   följer förra passets utslag med in i det nya, och en kvarliggande
   skänkel läses som en impuls av en häst som just satt sig i sadeln. */
function ridNollstallHjalp(){
  RIDIN.skankel=0; RIDIN.tygel=0; RIDIN.sits=0; RIDIN.styr=0; RIDIN.pek=false;
  ridAvsiktTillHjalp();
  for(const n in IN.kan)IN.kan[n].v=IN.kan[n].mal;
  IN.hh=-1;
}

function ridAvsiktTillHjalp(){
  const r=RIDIN, k=IN.kan;
  k.skankel.mal = r.skankel>=0
    ? 0.42+r.skankel*(0.78-0.42)
    : 0.42+r.skankel*(0.42-0.05);
  k.tygel.mal   = 0.34+clamp(r.tygel,0,1)*(0.80-0.34);
  k.sits.mal    = r.sits>=0 ? 0.2+r.sits*(0.85-0.2) : 0.2+r.sits*(0.2-(-0.6));
  k.styrning.mal= clamp(r.styr,-1,1)*0.72;
}
/* Och sätt filtret i neutralläge NU, vid inläsningen. Utan den här raden
   startar hjälpen på noll och rampar upp till sitt mittvärde av sig
   själv — en resa som ridmodellen med rätta läser som en framåtimpuls. */
ridNollstallHjalp();
const STIG=0.28,FALL=0.22;
addEventListener("keydown",e=>{
  if(e.repeat)return; IN.ned[e.code]=true;
  switch(e.code){
    case"KeyW":RIDIN.skankel=1;RIDIN.pek=false;break;
    case"KeyS":RIDIN.skankel=-1;RIDIN.pek=false;break;
    case"Space":RIDIN.tygel=1;e.preventDefault();break;
    case"ShiftLeft":case"ShiftRight":RIDIN.sits=-1;break;
    case"ControlLeft":case"ControlRight":RIDIN.sits=1;e.preventDefault();break;
    case"KeyA":RIDIN.styr=-1;RIDIN.pek=false;break;
    case"KeyD":RIDIN.styr=1;RIDIN.pek=false;break;
    case"KeyR":IN.latt=!IN.latt;break;
    case"KeyQ":IN.diagonal=1-IN.diagonal;break;
    case"KeyF":IN.spo=true;break;
    case"KeyE":if(IN.hh<0)IN.hh=0;break;
    case"KeyN":G.hoppaMoment=true;break;
    case"KeyP":G.auto=!G.auto;saga(G.auto?"Jag visar. Titta på vägen jag väljer.":"Din tur.",2.5);break;
    case"KeyV":vaxlaVy();break;
    case"KeyM":ljudToggle();break;
    case"KeyT":{
      const ov2=document.getElementById("ov");
      if(!ov2.classList.contains("hide"))break;
      if(G.scen==="lektion"||G.scen==="bana"){
        const oid=G.moment&&(G.moment.ovning||MOMENT_OVNING[G.moment.id]);
        if(oid)visaOvning(oid,"spel");
      }else if(G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne")visaTraningsbok("spel");
      break;}
  }
});
addEventListener("keyup",e=>{
  IN.ned[e.code]=false;
  switch(e.code){
    case"KeyW":RIDIN.skankel=IN.ned.KeyS?-1:0;break;
    case"KeyS":RIDIN.skankel=IN.ned.KeyW?1:0;break;
    case"Space":RIDIN.tygel=0;break;
    case"ShiftLeft":case"ShiftRight":case"ControlLeft":case"ControlRight":RIDIN.sits=0;break;
    case"KeyA":RIDIN.styr=IN.ned.KeyD?1:0;break;
    case"KeyD":RIDIN.styr=IN.ned.KeyA?-1:0;break;
    case"KeyF":IN.spo=false;break;
  }
});
function stegaInput(dt){
  ridAvsiktTillHjalp();          // avsikt → hjälpmål, en gång per bildruta
  for(const n in IN.kan){const k=IN.kan[n];
    const fart=(k.mal>k.v?1/STIG:1/FALL)*dt;
    if(Math.abs(k.mal-k.v)<=fart)k.v=k.mal;else k.v+=k.mal>k.v?fart:-fart;}
  let hS=0,hK=0,hT=0;
  if(IN.hh>=0){IN.hh+=dt;const t=IN.hh;let st=0;
    if(t<0.14)st=t/0.14;else if(t<0.24)st=1;else if(t<0.42)st=1-(t-0.24)/0.18;else IN.hh=-1;
    hS=st*0.28;hK=st*0.26;hT=st*0.27;}
  return{skankel:clamp(IN.kan.skankel.v+hK,0,1),tygel:clamp(IN.kan.tygel.v+hT,0,1),
    sits:clamp(IN.kan.sits.v+hS,-1,1),styrning:clamp(IN.kan.styrning.v,-1,1),
    lattridning:IN.latt,diagonal:IN.diagonal,spo:IN.spo};
}

/* ── Speltillstånd ── */
const G={
  scen:"meny",vy:"3d",t:0,grupp:"grupp2",plats:"ridhus",tavling:null,
  hastId:null,ride:null,aids:null,leder:false,skotselRes:null,
  utrustning:false,lerig:false,spolad:0,felUtrustning:0,
  px:10,py:52,rikt:-Math.PI/2,gaitFas:0,
  dagsform:0.7,sadellage:0.8,stallro:0.9,humor:0.6,
  moment:null,momentIx:0,momentT:0,momentHall:0,momentKlart:false,
  betyg:{},npcs:[],
  hinderAktiva:false,nastaHinder:0,rivna:new Set(),handelser:[],banTid:0,banStart:0,
  vagranStopp:0,sisteHopp:0,luft:0,auto:false,
  rngHopp:null,spanningPuls:0,hoppaMoment:false,
  sagaT:0,sagaCd:8,naraRop:0,seed:1,
  kappa:0,           // aktuell kurvatur, 1/m — se svängmodellen i stegaRitt
  banLut:0,          // kroppens lutning i svängen, radianer
  accel:0,           // utjämnad tempoderivata, m/s² — ryttarens tröghet
  forraTempo:0,      // förra bildrutans tempo, för derivatan
  ryttarPitch:0,     // ryttarens tröghet framåt/bakåt, radianer
  ryttarRoll:0,      // ryttarens balans i svängen, radianer
  gaitSpar:0,        // tillryggalagd sträcka i m, driver gångartsfasen
};
/* Standardvyn är 3D bakom figuren: det är så spelet är tänkt att
   spelas, och kartan är ett uppslag man tar när man vill orientera
   sig. Med kartan som förval landade en ny spelare i en ovanifrånvy
   där styrningen har en annan referens än den hon strax byter till. */
function vaxlaVy(){G.vy=G.vy==="2d"?"3d":"2d";
  document.querySelectorAll("#viewToggle button").forEach(b=>b.classList.toggle("on",b.dataset.v===G.vy));}
document.querySelectorAll("#viewToggle button").forEach(b=>b.addEventListener("click",()=>{
  if(b.dataset.v!==G.vy)vaxlaVy();}));

/* ── NPC-ekipage: rider fyrkantspåret olika bra ── */
function initNPC(){
  G.npcs=NPC_ELEVER.map((n,i)=>({...n,farg:HORSES[n.hast].farg,
    s:15+i*19, fart:1.2+n.skick*1.6, x:0,y:0,rikt:0}));
}
/* ── Trafiken på fyrkantspåret ────────────────────────────────────
   Ett hästlängds avstånd är en riktig stallregel, inte en spelregel, och
   den gäller alla på spåret — även dig. Förut red alla i konstant fart
   rakt igenom varandra; en NPC kunde stå mitt i kameran med huvudet över
   halva bilden.

   Ekipagen KROCKAR inte, de BROMSAR. Det är vad man gör på en lektion:
   kommer man ikapp den framför så saktar man ner, man kör inte in i
   henne. Bromsningen är mjuk och proportionell mot luckan, så en NPC som
   hinner ikapp lägger sig på avstånd i stället för att tvärstanna. */
const HASTLANGD=3.2;      // avståndet man håller på spåret
const HASTRUM=2.1;        // närmare än så kommer ingen — hästen är i vägen

/* Hur mycket ska n sakta ner för det som ligger framför? Returnerar
   0 (stilla) till 1 (fri väg). Bara det som ligger i färdriktningen
   räknas — man bromsar inte för någon man just passerat. */
function npcBroms(n){
  let minsta=Infinity;
  const fx=Math.cos(n.rikt), fy=Math.sin(n.rikt);
  const kolla=(x,y)=>{
    const dx=x-n.x, dy=y-n.y, d=Math.hypot(dx,dy);
    if(d<0.001||d>HASTLANGD*2)return;
    /* Framförkonen: 0,55 ≈ 57° åt vardera hållet. Bredare än så och man
       bromsar för ekipage på andra långsidan. */
    if((dx*fx+dy*fy)/d<0.55)return;
    if(d<minsta)minsta=d;
  };
  for(const m of G.npcs)if(m!==n)kolla(m.x,m.y);
  if(G.scen==="lektion"||G.scen==="bana")kolla(G.px,G.py);
  if(minsta===Infinity)return 1;
  return clamp((minsta-HASTRUM)/(HASTLANGD-HASTRUM),0,1);
}

function stegaNPC(dt){
  // fyrkantspåret som sluten bana: omkrets 2*(17+57)=148 m
  for(const n of G.npcs){
    if(G.scen==="bana"){ // står på medellinjen och tittar på
      n.x=4+G.npcs.indexOf(n)*2.2;n.y=56.5;n.rikt=-Math.PI/2;continue;}
    /* Bromsen glider mot sitt mål i stället för att slå till — en häst
       som saktar ner gör det över ett par steg. */
    const mal=npcBroms(n);
    n.broms=(n.broms===undefined?1:n.broms)+(mal-(n.broms===undefined?1:n.broms))
      *Math.min(1,dt*2.6);
    n.s=(n.s+n.fart*n.broms*dt*(0.95+0.1*Math.sin(G.t*0.5+n.skick*9)))%148;
    const s=n.s;
    if(s<57){n.x=1.5;n.y=58.5-s;n.rikt=-Math.PI/2;}
    else if(s<74){n.x=1.5+(s-57);n.y=1.5;n.rikt=0;}
    else if(s<131){n.x=18.5;n.y=1.5+(s-74);n.rikt=Math.PI/2;}
    else{n.x=18.5-(s-131);n.y=58.5;n.rikt=Math.PI;}
    /* Att bara bromsa räcker inte: står någon still på spåret köar alla
       bakom och stannar för gott. Tre hästar frös i en hög i provet.
       Det man gör på riktigt är att gå om på INSIDAN — så ekipaget
       skjuts inåt banan medan det är blockerat och söker sig ut mot
       spåret igen när vägen är fri. */
    const blockad=n.broms<0.55;
    /* Taket måste vara större än HASTRUM, annars räcker sidosteget inte
       för att komma förbi någon som står still på spåret — då lägger sig
       hela gruppen i en klunga bredvid hindret i stället. */
    n.sido=clamp((n.sido||0)+(blockad?1.1:-0.7)*dt,0,2.8);
    if(n.sido>0.001){
      const ix=10-n.x, iy=30-n.y, il=Math.hypot(ix,iy)||1;
      n.x+=ix/il*n.sido; n.y+=iy/il*n.sido;
    }
  }
}

/* ── Ritt-fysik på planen ── */
let kursHist=[];
function stegaRitt(dt){
  G.aids=stegaInput(dt);
  if(G.auto)autopilot(dt);
  const h=HORSES[G.hastId];

  /* ── Svängen som KURVATUR, inte som vridhastighet ────────────────
     Förut: omega = styrning × (0,5 + 0,22 × tempo). Vridhastigheten
     växte alltså med farten — i fyrsprång kunde hästen snurra 2,2 rad/s,
     alltså 126° i sekunden. Det ger snäva, fordonslika kurvor och gör
     att man kan vika hästen genom en sväng i stället för att rida en
     båge.

     Nu ber styraxeln om en KURVATUR: hur snävt hästen ska böja sig, i
     1/meter. Vridhastigheten faller ut som kurvatur × tempo, vilket är
     samma sak som att svängradien blir 1/kurvatur oavsett fart. Varje
     gångart har ett tak för hur snävt den kan böja — en häst i fyrsprång
     böjer sig inte som en häst i skritt — och taken är samma siffror som
     Roblox-spårets turn-faktorer, så designen bara översätts. */
  /* STYRKANONEN ligger i RID_KANON i src/riding/telemetri.js. Värdena är
     Gate 01:s, oförändrade sedan 33559d9 — PO-beslutet 2026-09-05 valde
     dem till kanon, det ändrade dem inte. Fallbacken finns kvar för att
     modellen ska gå att köra utan telemetrimodulen. */
  const KAN=(typeof ridKanon==="function")?ridKanon():null;
  const GANGSVANG=KAN?KAN.GANGSVANG:{halt:1.00, skritt:1.00, trav:0.82, galopp:0.52};
  const KAPPA_MAX=KAN?KAN.KAPPA_MAX:0.42;   // 1/m vid full styrning i skritt ≈ 2,4 m radie
  const gv=GANGSVANG[G.ride.gangart]||1.00;
  /* Smidigheten sitter i hästen och i ryttarens hand: en vig häst böjer
     sig snävare, och den som rider mjukt får mer båge för samma utslag. */
  const kappaTak=KAPPA_MAX*gv*(0.78+0.44*clamp(h.kanslighet,0,1));
  const kappaBegard=clamp(G.aids.styrning,-1,1)*kappaTak;
  /* Kurvaturen tar tag och släpper mjukt, dt-baserat. Utan den snäpper
     bågen till sin nya radie i samma bildruta som fingret rör sig.
     Att lägga sig i en båge går fortare än att räta upp sig ur den —
     det är så en häst gör, och det är också vad som känns rätt. */
  /* Gångartens egen tröghet i svängen (G02-A.1 P3). Galoppen lägger sig
     i bågen långsammare och känns därför vidare, skritten rättar sig
     kvickast. Faktorn ligger i kanonen så Roblox speglar samma tal. */
  const svangTau=(KAN&&KAN.SVANGTAU&&KAN.SVANGTAU[G.ride.gangart])||1.00;
  const kappaTau=(Math.abs(kappaBegard)>Math.abs(G.kappa)?0.13:0.19)*svangTau;
  /* ── BÅGEN MÅSTE UR KROPPEN INNAN DEN LÄGGS ÅT ANDRA HÅLLET (P4) ──
     Kurvaturen får inte ändras fortare än hästen lägger sig i en båge
     från rakt. Taket är gångartens kurvaturtak delat med KAPPA_RAT_TID
     och skalar därför med både gångart och hästens smidighet.

     Uppmätt före: ett riktningsbyte svepte bågen igenom 1,4 gånger
     snabbare än den hårdaste insvängningen — full vänster till full
     höger på 0,30 s i skritt, alltså en halv meter av en tvåochenhalv
     meter lång häst. Det är rycket man känner som skating, och det är
     det enda i styrningen som gjorde det.

     En vanlig insvängning ligger under taket och rörs inte. */
  const kappaRat=kappaTak/((KAN&&KAN.KAPPA_RAT_TID)||0.32);
  let dKappa=(kappaBegard-G.kappa)*(1-Math.exp(-dt/kappaTau));
  const takSteg=kappaRat*dt;
  if(Math.abs(dKappa)>takSteg)dKappa=dKappa>0?takSteg:-takSteg;
  G.kappa+=dKappa;
  if(Math.abs(G.kappa)<0.0015)G.kappa=0;
  const omega=G.kappa*G.ride.tempo;
  const radie=Math.abs(G.kappa)>0.002?1/Math.abs(G.kappa):1000;
  /* Utomhus väger skyggheten tyngre (modellen har faktorn), och regn
     gör underlaget tyngre än ridhusets harvade fiber. */
  const ute=G.plats!=="ridhus";
  const underlag=ute?(G.vader&&G.vader.typ==="regn"?0.76:0.88):0.92;
  /* Färdigheter plus de valda egenskaperna, i ett anrop — modellen ska
     inte behöva veta att lutningen har två källor. */
  const F=fardighetsModMedJag();
  stepRide(G.ride,G.aids,h,{svangradie:clamp(radie,3,1000),underlag,stallro:G.stallro,
    utomhus:ute,fard:F,
    avdrift:hastAvdrift(h,G.humor===undefined?0.6:G.humor,F.halla)},dt);
  /* Färdigheterna växer av det som just hände. Returnerar ett id när en
     färdighet passerar ett helt tiondelssteg, så att det går att visa. */
  {const steg=stegaFardighet(G.ride,G.aids,dt);
   if(steg)visaFardighetsSteg(steg);}
  passSteg(dt);
  /* MINUS, inte plus. Kursen är atan2-vinkeln i ett y-uppåt-plan
     (framåt = cos, sin), och där betyder VÄXANDE vinkel moturs — alltså
     vänster. D gav styrning +0,72 och därmed en vänstersväng: höger och
     vänster har varit spegelvända i hela spelet.

     Uppmätt före rättningen: med nosen rakt norrut (90°) och D nedtryckt
     en halv sekund gick kursen till 130° i ridningen och 167° i gå-läget
     — bägge moturs, alltså vänster.

     Rättningen ligger HÄR och inte i tangentborden, så att styrning > 0
     genomgående betyder höger: det är vad D ger, vad pekstyrningens
     högerdrag ger, och vad HUD:ens markör visar. Kameran var oskyldig —
     en punkt rakt öster om spelaren projiceras till NDC-x +13,9, alltså
     höger på skärmen, precis som den ska. */
  /* Ingen extra fartgrind behövs: omega är kurvatur × tempo, så en
     stillastående häst svänger inte av sig själv. Det är också kravet
     om att inga vridningar på stället får ske under rörelse. */
  G.rikt-=omega*dt;
  /* ── Väggen: glid längs den, snäpp inte ──────────────────────────
     Korrigeringen mot sargen använde en fast lerp-faktor per bildruta,
     alltså 0,06 oavsett om spelet gick i 30 eller 144 Hz. Samma vägg
     kändes då olika hård på olika datorer. Faktorn är nu dt-baserad med
     samma tidskonstant som resten av rörelsen.

     Hästen vrids mot väggens riktning i stället för att stoppas mot den,
     så att man glider längs sargen — det är vad som händer när en häst
     rider på spåret, och det är också vad kravet ber om. */
  let nx=G.px+Math.cos(G.rikt)*G.ride.tempo*dt;
  let ny=G.py+Math.sin(G.rikt)*G.ride.tempo*dt;
  const VAGG_TAU=0.55;                      // sekunder att lägga sig längs sargen
  const vaggT=1-Math.exp(-dt/VAGG_TAU);
  if(nx<0.8){nx=0.8;G.rikt=lerpAngle(G.rikt,ny>G.py?Math.PI/2:-Math.PI/2,vaggT);}
  if(nx>19.2){nx=19.2;G.rikt=lerpAngle(G.rikt,ny>G.py?Math.PI/2:-Math.PI/2,vaggT);}
  if(ny<0.8){ny=0.8;G.rikt=lerpAngle(G.rikt,nx>G.px?0:Math.PI,vaggT);}
  if(ny>59.2){ny=59.2;G.rikt=lerpAngle(G.rikt,nx>G.px?0:Math.PI,vaggT);}
  /* Ekipagen framför är också väggar. Man kan inte rida genom en häst,
     och kommer man för nära blir hon spänd — avståndsregeln i ridhuset
     är till för hästarnas skull, inte för ordningens. */
  for(const n of G.npcs){
    const dx=nx-n.x, dy=ny-n.y, d=Math.hypot(dx,dy);
    if(d>=HASTRUM||d<0.001)continue;
    const k=(HASTRUM-d)/d;
    nx+=dx*k; ny+=dy*k;                       // mjuk utknuffning
    /* Hästen tvärnitar inte, men hon vägrar gå in i en annan häst: farten
       bryts och spänningen stiger. Utan farttappet gick det att stå och
       trycka mot ekipaget framför utan att märka något. */
    G.ride.tempo*=0.90;
    G.ride.spanning=clamp(G.ride.spanning+1.1*dt,0,1);
    if(G.t-(G.narkontaktT||-99)>9){
      G.narkontaktT=G.t; G.narkontakter=(G.narkontakter||0)+1;
      G.naraRop=G.t;                          // repliken köas, se nedan
    }
  }
  /* Tillsägelsen om avståndet köas i stället för att sägas på fläcken.
     Ridläraren har numera ett tema och säger få saker, och mätt över tre
     pass landade avståndsropet gång på gång en till fyra tiondelar efter
     hennes rättelse och skrev över den innan den gick att läsa — sju till
     åtta gånger per pass. Nu väntar ropet tills rutan hunnit läsas, som
     mest sex sekunder; är man fortfarande för nära då kommer nästa
     tillsägelse ändå på sin egen niosekunderstakt.

     Straffet — farttappet, spänningen och räkningen — ligger kvar där
     uppe och tas ut i samma bildruta som förut. Det är bara repliken som
     väntar, aldrig regeln. */
  if(G.naraRop){
    if(G.t-G.naraRop>6)G.naraRop=0;           // för gammal att säga
    else if(G.sagaT<=0.9){
      G.naraRop=0;
      /* Och hon tystnar en stund efteråt: säkerheten har sin egen röst
         och ska inte trängas med en rättelse om handen. */
      if(typeof LARARE!=="undefined")LARARE.cd=Math.max(LARARE.cd,4.5);
      saga("För nära! Håll en hästlängd till ekipaget framför.",3.2);
    }
  }
  /* ── Gångartsfasen följer MARKEN, inte klockan ────────────────────
     Förut drevs fasen av en frekvens gånger tempot, vilket är nästan
     rätt men inte riktigt: samma sträcka i samma gångart kunde ge olika
     många hovnedslag beroende på hur tempot råkade variera på vägen, och
     hovarna gled synligt mot underlaget.

     Nu räknas den tillryggalagda sträckan, och fasen är sträckan delad
     med gångartens CYKELLÄNGD. Då landar hovarna på samma ställen varje
     varv, och stillastående häst rör inte fasen alls: står man still går
     man inte på stället.

     CYKELLÄNGD betyder EN sak, på båda plattformarna: sträckan hästen
     färdas under ett helt normaliserat fasvarv, fas 0 → 1. Det är inte
     samma sak som en hovs kliv. S3FAS i scen3d.js lägger alla fyra ben
     inuti samma fasvarv med var sin förskjutning — vf 0, hf 0,25, vb
     0,50, hb 0,75 i skritt — så ett ben hinner precis en stance och en
     sving per varv. Antalet hovnedslag är alltså redan inbakat i
     benens förskjutningar och får inte multipliceras in en gång till.

     Gait.steglangd är just den sträckan: SPRANG-basen gånger gångartens
     steg-faktor, med hästens schvung och spänning inräknade. Den låg
     tidigare multiplicerad med antalet hovnedslag, vilket gjorde
     fasvarvet 2,7–4 gånger för långt — hovarna gled fortfarande, bara
     långsammare. Roblox räknar samma storhet som norm ÷ cycles. */
  const strackaSteg=Math.hypot(nx-G.px, ny-G.py);
  G.px=nx;G.py=ny;
  G.gaitSpar+=strackaSteg;
  {const cykelLangd=G.ride.steglangd;
   if(cykelLangd>0.05){
     G.gaitFas=(G.gaitFas+strackaSteg/cykelLangd)%1;
   }else if(G.ride.gangart!=="halt"){
     /* Har modellen ingen steglängd att ge (första bildrutan efter ett
        gångartsbyte) faller fasen tillbaka på tempot, så att den aldrig
        fryser mitt i ett steg. */
     G.gaitFas=(G.gaitFas+G.ride.tempo*dt*0.5)%1;
   }}
  /* G02-A: gångarten följs av övergångskontraktet och telemetrin läggs
     på G.telemetri, så att G02-B/C har en enda avläsningspunkt. Ren
     avläsning — inget här får påverka ridkänslan. */
  if(typeof ridFoljGangart==="function"&&G.ride){
    ridFoljGangart(G.ride.gangart);
    G.telemetri=ridTelemetri(G.ride,G.aids,{kappa:G.kappa,fas:G.gaitFas});
  }
  ljudRittSteg(G.gaitFas,G.ride.gangart,
    G.plats==="ridhus"?"fiber":(G.vader&&G.vader.typ==="regn"?"vat":"grus"));
  G.spanningPuls=clamp(G.ride.spanning-0.55,0,1)/0.45;

  /* ── Kroppens lutning i svängen ───────────────────────────────────
     Centripetalaccelerationen är kurvatur gånger tempo i kvadrat. Den
     storheten är noll när hästen står still hur mycket man än styr, växer
     med farten i en given böj, och är densamma oavsett vilken enhet
     spelaren håller i — allt tre är precis vad lutningen ska göra.

     Utjämningen är dt-baserad och trögare än styrningen: kroppen lägger
     sig i böjen efter att riktningen ändrats, inte samtidigt. Taket på
     0,075 rad är knappt fyra och en halv grad, vilket är mycket på en
     häst; mer läser som motorcykel. */
  {const centripetal=G.kappa*G.ride.tempo*G.ride.tempo;
   const mal=clamp(centripetal*0.012,-0.075,0.075);
   G.banLut=(G.banLut||0)+(mal-(G.banLut||0))*(1-Math.exp(-dt/0.22));}

  /* ── Ryttarens tröghetssignaler ───────────────────────────────────
     En ryttare är en massa ovanpå en annan massa. Accelererar hästen
     hamnar hon en aning efter; bromsar hästen kommer hon en aning före.
     I en sväng söker hon balansen inåt, men mindre än hästen gör.

     Här räknas bara SIGNALERNA — själva rörelsen ritas i scen3d.js, så
     att den pedagogiska sitslogiken (Ctrl djupt, Shift lätt) inte blandas
     ihop med den ofrivilliga. Accelerationen jämnas ut hårt: rå
     tempoderivata hackar, och en ryttare som ryckte per bildruta skulle
     läsa som ragdoll. */
  {const dTempo=(G.ride.tempo-(G.forraTempo||0))/Math.max(dt,1e-4);
   G.forraTempo=G.ride.tempo;
   G.accel=(G.accel||0)+(clamp(dTempo,-6,6)-(G.accel||0))*(1-Math.exp(-dt/0.18));
   /* Signalerna räknas HÄR och inte i ritfunktionen, så att de går att
      mäta och så att konstanterna finns på ett ställe. Skalan är satt
      så att det mest extrema fallet — full skänkel ur halt, drygt
      4 m/s² — landar strax under taket i stället för att klippa mot
      det, och en vanlig övergång ger drygt en grad.

      Ryttaren följer hästen i svängen men lägger sig inte som hästen:
      en tredjedel av banlutningen. Kroppen ska följa, inte tävla. */
   G.ryttarPitch=clamp(-G.accel*0.014,-0.055,0.055);
   G.ryttarRoll=clamp((G.banLut||0)*0.34,-0.030,0.030);}
}
function lerpAngle(a,b,t){let d=b-a;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;return a+d*t;}

/* Autopilot — "ridläraren visar". Styr mot nästa hinders anridningslinje,
   håller arbetstempo och mjuka hjälper. Finns för demo och för test;
   den använder samma hjälper som spelaren, inga genvägar i modellen. */
function autopilot(dt){
  let mx=10,my=30;
  const h=G.hinderAktiva?BANA.hinder.find(x=>x.nr===G.nastaHinder):null;
  if(h){
    // Tvåfas, som en riktig inridning: först TILL anridningspunkten
    // (12 m ut på hindrets linje), checka in där, och först därefter
    // rakt mot hindret. Utan incheckningen orbitar man — sikta direkt
    // på ett mål som kräver mindre svängradie än hästen har, och du
    // cirklar runt det för evigt. Precis som på riktigt, för övrigt.
    if(!G._ap||G._ap.nr!==h.nr)G._ap={nr:h.nr,inne:false};
    const S={x:clamp(h.x-Math.cos(h.rot)*12,1.5,18.5),
             y:clamp(h.y-Math.sin(h.rot)*12,1.5,58.5)};
    if(!G._ap.inne&&Math.hypot(S.x-G.px,S.y-G.py)<3.2)G._ap.inne=true;
    if(G._ap.inne){mx=h.x+Math.cos(h.rot)*2;my=h.y+Math.sin(h.rot)*2;}
    else{mx=S.x;my=S.y;}
  }else{ // rid fyrkantspåret
    const mal=[[1.8,1.8],[18.2,1.8],[18.2,58.2],[1.8,58.2]];
    let bi=0,bd=1e9;
    for(let i=0;i<4;i++){const d=Math.hypot(mal[i][0]-G.px,mal[i][1]-G.py);
      if(d<bd&&d>3){bd=d;bi=i;}}
    [mx,my]=mal[bi];
  }
  const onskad=Math.atan2(my-G.py,mx-G.px);
  let d=onskad-G.rikt;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;
  /* Minustecknet följer av rättningen ovan: d är hur mycket kursen ska
     ÖKA för att peka på målet, och sedan kursen räknas moturs betyder en
     ökning vänster — alltså negativ styrning. */
  G.aids.styrning=clamp(-d*1.4,-0.8,0.8);
  G.aids.skankel=0.62; G.aids.tygel=0.37; G.aids.sits=0.2;
  G.aids.lattridning=true; G.aids.diagonal=1; G.aids.spo=false;
}

/* ── Hoppningen ── */
function startaBana(){
  G.hinderAktiva=true;G.nastaHinder=1;G.rivna.clear();G.handelser=[];
  G.banStart=G.t;G.vagranStopp=0;
  G.rngHopp=Approach.rng(G.seed*7919+13);
  document.getElementById("protWrap").hidden=false;
  uppdateraProt();
}
function hinderRel(h){
  // avstånd längs hindrets anridningsriktning + sidled
  // rot är SPRÅNGETS riktning. Vektorn spelare→hinder projicerad på den
  // är positiv så länge hindret ligger framför — dvs. före avsprånget.
  const ax=Math.cos(h.rot),ay=Math.sin(h.rot);
  const dx=h.x-G.px,dy=h.y-G.py;
  const fram=dx*ax+dy*ay;
  const sida=-dx*ay+dy*ax;
  return{fram,sida};
}
let protT=0;
function stegaBana(dt){
  protT+=dt; if(protT>0.5){protT=0;uppdateraProt();}
  if(G.t-G.banStart>180){avslutaBana(domaRitt(G.handelser,G.t-G.banStart,true));return;}
  if(G.vagranStopp>0){G.vagranStopp-=dt;return;}
  const h=BANA.hinder.find(x=>x.nr===G.nastaHinder);
  if(!h)return;
  const rel=hinderRel(h);
  const avst=rel.fram; // >0 = före hindret
  const ap=document.getElementById("approach");
  // heading-koll: rider vi mot hindret?
  const riktMot=Math.abs(angDiff(G.rikt,h.rot))<1.1;
  if(avst>0&&avst<26&&Math.abs(angDiff(G.rikt,h.rot))<1.1&&Math.abs(rel.sida)<4&&G.ride.tempo>1.2){
    const los=Approach.los(avst,Math.max(G.ride.steglangd,0.6),BANA.hojd);
    ap.textContent=los.rad;
    G._losning=los;
  } else ap.textContent="";
  // passage av avsprångszonen?
  const zon=Approach.zon(Math.max(G.ride.steglangd,0.6),BANA.hojd);
  if(avst<zon&&avst>-1&&riktMot&&Math.abs(rel.sida)<2.6&&G.t-G.sisteHopp>1.2){
    G.sisteHopp=G.t;
    const los=G._losning||Approach.los(Math.max(avst,zon),Math.max(G.ride.steglangd,0.6),BANA.hojd);
    const q=Approach.kvalitet(los,G.ride.skala,G.ride.spanning,G.dagsform);
    const hh=HORSES[G.hastId];
    const utfall=Approach.utfall(q,BANA.hojd,hh.hoppkapacitet,hh.hopplust,hh.maxhojd,G.ride.rang,G.rngHopp);
    if(utfall.resultat==="vagran"){
      G.handelser.push({typ:"olydnad",hinder:h.nr});
      G.ride.tempo=0;G.vagranStopp=1.4;
      flash("VÄGRAN");saga(utfall.kommentar,3.2);
      const dom=domaRitt(G.handelser,G.t-G.banStart,true);
      if(dom.utesluten){avslutaBana(dom);return;}
    }else{
      G.luft=0.55; // hopp-animation
      if(utfall.resultat==="rivning"){G.rivna.add(h.nr);G.handelser.push({typ:"nedslag",hinder:h.nr});
        flash("4 FEL");saga(utfall.kommentar,2.6);
        /* Vägran prövade uteslutning direkt, nedslag gjorde det inte —
           man kunde riva sig långt förbi gränsen och hoppa färdigt hela
           banan, och fick beskedet retroaktivt på resultatskärmen.
           Uteslutning ska komma när den inträffar. */
        const domR=domaRitt(G.handelser,G.t-G.banStart,true);
        if(domR.utesluten){avslutaBana(domR);return;}}
      else if(q>0.8)saga(utfall.kommentar,2.2);
      G.nastaHinder++;
      if(G.nastaHinder>BANA.hinder.length){
        avslutaBana(domaRitt(G.handelser,G.t-G.banStart,true));return;}
    }
    uppdateraProt();
  }
}
function angDiff(a,b){let d=a-b;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;return Math.abs(d);}
function uppdateraProt(){
  const dom=domaRitt(G.handelser,G.t-G.banStart,true);
  const el=document.getElementById("prot");
  /* Höjden ur banan, inte hårdkodad — Klass 2 och 3 rids på 0,75 och
     0,85 m och protokollet påstod 0,60 hela ritten. */
  const hojd=((BANA&&BANA.hojd)||0.60).toFixed(2).replace(".",",");
  let rows=`<div class="lbl" style="margin-bottom:6px">Protokoll · ${hojd} m</div>`;
  rows+=`<div class="r"><span>Hinder</span><b>${Math.min(G.nastaHinder,6)} / 6</b></div>`;
  rows+=`<div class="r ${dom.hinderfel?"bad":""}"><span>Fel</span><b>${dom.hinderfel}</b></div>`;
  rows+=`<div class="r"><span>Olydnader</span><b>${dom.olydnader}</b></div>`;
  rows+=`<div class="r"><span>Tid</span><b>${(G.t-G.banStart).toFixed(0)} s</b></div>`;
  el.innerHTML=rows;
}
function flash(txt){const f=document.getElementById("faults");
  f.textContent=txt;f.style.opacity=1;f.style.transform="translate(-50%,-50%) scale(1.06)";
  setTimeout(()=>{f.style.opacity=0;f.style.transform="translate(-50%,-50%) scale(1)";},900);}
function saga(txt,dur){const s=document.getElementById("saga");
  s.textContent=txt;s.classList.add("on");G.sagaT=dur||3;
  if(typeof ljudRost==="function")ljudRost(txt);}

/* ── Lektionen ── */
function startaLektion(){
  G.scen="lektion";G.momentIx=0;G.momentT=0;G.betyg={};
  G.narkontakter=0; G.narkontaktT=-99; G.naraRop=0;
  G.bedomda=0; G.klarade=0;
  if(typeof lararNollstall==="function")lararNollstall();
  /* HUD:en tillbaka i ridläge. Gå-läget döljer pyramiden, hjälpmätarna
     och gångartsrutan, och bara tävlingsvägen slog på dem igen — en
     vanlig lektion reds alltså helt utan utbildningsskalan, som är den
     återkoppling hela modellen vilar på. Menyn hänvisade till och med
     till "mätaren" som inte fanns på skärmen. Anropet hör hemma här, i
     lektionen, inte hos varje anropare. */
  if(typeof hudLage==="function")hudLage("ritt");
  passStart();                       // avskrift av allt som ska jämföras efteråt
  document.getElementById("approach").textContent="";
  if(G.tavling){
    G.lektion=byggTavlingsprogram(G.tavling);
    G.hadeBana=G.lektion.some(m=>m.id==="bana");
    G.moment=G.lektion[0];visaMoment();
    saga(G.tavling.typ==="hoppning"
      ?`Framridning. Sedan är det din tur i ${G.tavling.klass.namn} — publiken sitter på läktaren.`
      :"Domaren sitter i kuren vid C. In på medellinjen när klockan ringer.",4.5);
    ljudKlocka();
    overlay(false);document.getElementById("viewToggle").hidden=false;
    return;
  }
  G.lektion=byggLektion(G.grupp,G.seed,G.plats);
  /* Vägen tillbaka: första passet efter en skada rids utan galopp
     och utan bana — stegrande arbete, som efter en hälta. */
  const mReh=hastminne(G.hastId);
  if(mReh.rehab){
    G.lektion=G.lektion.filter(m=>{
      if(m.id==="bana")return false;
      const o=OVNINGAR.find(o=>o.id===m.ovning);
      return !o||o.gangart!=="galopp";
    });
  }
  G.hadeBana=G.lektion.some(m=>m.id==="bana");
  /* Ridläraren bestämmer dagens tema INNAN första momentet visas. Hon
     säger det själv några sekunder in (se lararSteg) — en tävling har
     en domare i stället och får inget tema alls, därför står valet här
     och inte högre upp. */
  if(typeof lararValjFokus==="function")lararValjFokus();
  G.moment=G.lektion[0];visaMoment();
  if(mReh.rehab)
    saga(`${HORSES[G.hastId].namn} är på väg tillbaka efter sin skada — bara skritt och trav i dag, säger ridläraren.`,4.5);
  else if(G.plats!=="ridhus"&&G.vader&&G.vader.typ==="regn")
    saga("Regnet gör underlaget tungt — räkna med mindre schvung och rid med marginal.",4.5);
  else if(G.plats==="stig")
    saga("Uteritt på skogsstigen. Lydighetsövningar behöver ingen bana — grusvägar duger.",4.5);
  overlay(false);document.getElementById("viewToggle").hidden=false;
}
function visaMoment(){
  const m=G.moment;
  const platsTxt=G.plats==="utebana"?" · uteridbanan":G.plats==="stig"?" · skogsstigen":"";
  /* Dagens tema står kvar i rubriken hela lektionen. Hon säger det en
     gång, sex sekunder in, och sedan är det borta — men det är den enda
     saken hon bedömer, så det ska gå att läsa av när som helst. En
     tävling har en domare i stället för ett tema och får ingen. */
  const tema=(typeof lararFokusNamn==="function")?lararFokusNamn():"";
  document.getElementById("momentLbl").textContent=
    `Moment ${G.momentIx+1} av ${G.lektion.length} · ${GRUPPNAMN[G.grupp]||G.grupp}${platsTxt}`
    +(tema?` · tema: ${tema.toLowerCase()}`:"");
  document.getElementById("momentNamn").textContent=m.namn;
  document.getElementById("momentText").textContent=
    m.text+((m.ovning||MOMENT_OVNING[m.id])?" · T öppnar övningen i träningsboken.":"");
  document.getElementById("momentMal").textContent=momentMalText(m,G.grupp);
  saga(m.text,4);
}
function stegaLektion(dt){
  /* Passet är slut när scenen bytt. Utan den här raden räknar ett extra
     anrop in ett helt nytt pass: avslutaBana registrerar, men G.moment
     ligger kvar och G.momentKlart är fortfarande sant, så nästa anrop
     registrerar igen. I dag skyddas det av att loopen slutar anropa vid
     scenbytet — det är ett skydd på fel ställe. */
  if(G.scen!=="lektion"&&G.scen!=="bana")return;
  const m=G.moment;if(!m)return;
  /* Den ledda genomgången först. Så länge den pågår tickar inte
     momentets stapel — annars mäts spelaren mot ett krav hon inte fått
     höra än. */
  if(typeof introRittSteg==="function"&&introRittSteg(dt))return;
  G.momentT+=dt;
  if(m.id==="bana"){
    if(!G.hinderAktiva)startaBana();
    stegaBana(dt);
    document.querySelector("#momentBar i").style.width=(G.nastaHinder-1)/6*100+"%";
  }else{
    /* Momentet klaras genom att HÅLLA kvaliteten, inte genom att vänta ut
       en klocka. Stapeln visar hållen tid, inte förfluten. Sjunker du under
       kravet rinner den tillbaka — långsammare än den fylls, för att ett
       ögonblicks slarv inte ska radera en hel långsida. */
    const mal=momentMal(m,G.grupp);
    if(mal){
      /* Både kvaliteten OCH tempot måste hållas. Kvaliteten ensam går
         att nå genom att sitta still; tempobandet gör att hon glider
         ur det om du inte rider henne. */
      const kval=Skala.inverkan(G.ride.skala,G.grupp);
      /* Och du måste ha KONTAKT. Ett moment mäter hästens tillstånd, och
         hästen kan hamna rätt av sig själv — en häst som driver in i
         skritt låg i skrittens band utan att någon rörde en tangent, och
         tre grupper gick att bli uppflyttad ur på det viset.

         Kravet är medvetet LÅGT: tygeln ska ligga över slakgränsen.
         Vilovärdet efter ett släppt Space är 0,34, alltså mitt i bandet
         — har du en gång tagit upp tyglarna har du kontakt, och så är
         det på riktigt också. Kravet fångar därför den som ALDRIG tagit
         upp dem, inte den som släpper mellan tagen. Det är hela
         avsikten: att stänga rent passivt spel, inte att kräva att man
         håller nere en tangent i tre minuter. */
      const kontakt=G.aids&&G.aids.tygel>K.TYGEL_BAND_MIN;
      const over=kval>=mal.krav&&kontakt&&iTempoBand(G.ride,G.grupp,m);
      G.momentHall=clamp((G.momentHall||0)+(over?dt:-dt*0.45),0,mal.hall);
      document.querySelector("#momentBar i").style.width=G.momentHall/mal.hall*100+"%";
      document.querySelector("#momentBar").classList.toggle("haller",over);
      G.momentKlart=G.momentHall>=mal.hall;
    }else{
      document.querySelector("#momentBar i").style.width=clamp(G.momentT/m.tid*100,0,100)+"%";
      G.momentKlart=G.momentT>=m.tid;
    }
    {const mt=document.getElementById("momentMal");
     if(mt)mt.textContent=momentMalText(m,G.grupp);}
    /* Ridläraren. Förr lästes den lägsta siffran på utbildningsskalan
       upp var trettonde sekund, och bytte den lägsta siffran bytte hon
       ämne mitt i meningen — en felrapport, inte en instruktör. Nu
       håller hon ETT tema hela lektionen och tiger när det går bra.
       Hon räknar sin egen paus, så G.sagaCd behövs inte här. */
    if(G.momentT>6&&typeof lararSteg==="function"){
      const rop=lararSteg(dt);
      if(rop)saga(rop,4.2);
    }
    /* Taket: även ett moment man inte klarar tar slut till slut, så att
       ingen fastnar. Då blir det underkänt, inte oändligt. */
    if(G.momentKlart||G.momentT>=m.tid*2.2||G.hoppaMoment){
      G.hoppaMoment=false;
      /* Betyget vägs med hur mycket av hålltiden du faktiskt klarade.
         Utan det gick hela lektionen att sitta av i HALT: kvaliteten
         driver upp mot 0,72 när ingenting händer, taket m.tid*2.2 tvingar
         fram varje moment ändå, och passet blev godkänt med
         uppflyttningspoäng utan en meter ridning. Ett moment man aldrig
         höll är inte ett ridet moment.

         Golvet på 0,25 finns för att en ryttare som kämpar och nästan
         lyckas inte ska nollas — men 0,72 × 0,25 = 0,18 ligger under
         varje grupps krav, så att stå still räcker aldrig. */
      if(m.bedoms){
        const mal2=momentMal(m,G.grupp);
        const andel=mal2?clamp((G.momentHall||0)/mal2.hall,0,1):1;
        G.betyg[m.id]=Skala.inverkan(G.ride.skala,G.grupp)*(0.25+0.75*andel);
        G.bedomda=(G.bedomda||0)+1;
        if(andel>=0.999)G.klarade=(G.klarade||0)+1;
      }
      G.momentIx++;
      if(G.momentIx<G.lektion.length){G.moment=G.lektion[G.momentIx];G.momentT=0;
        G.momentHall=0;G.momentKlart=false;visaMoment();}
      else{ // pass utan hoppning: inget hopprotokoll, ingen tidsregel
        const dom=domaRitt([],0,true);
        dom.tid=G.lektion.reduce((a,m)=>a+m.tid,0);
        G.moment=null; G.momentKlart=false;   // passet är över, inte pausat
        avslutaBana(dom);
      }
    }
  }
}
function avslutaBana(dom){
  passSlut();                        // före registreraPass — färdigheterna ska stå still
  if(G.hadeBana)G.betyg.bana=Skala.inverkan(G.ride.skala,G.grupp);
  if(G.tavling){ // tävlingen ger placering och rosett, inte uppflyttning
    G.domare=dom;G.scen="resultat";
    document.getElementById("protWrap").hidden=true;
    document.getElementById("viewToggle").hidden=true;
    visaTavlingsResultat(dom);
    return;
  }
  G.passRes=registreraPass(dom);
  /* Molnet är frivilligt och får misslyckas tyst — resultatrutan visas
     likadant vare sig raden kom fram eller inte. */
  if(typeof synkSparaPass==="function"){synkSparaPass(dom);synkTryck();}
  G.domare=dom;G.scen="resultat";
  document.getElementById("protWrap").hidden=true;
  document.getElementById("viewToggle").hidden=true;
  visaResultat(dom);
}

/* ── HUD ── */
const PCOL={takt:"#4A737E",losgjordhet:"#56888A",kontakt:"#5F9C85",schvung:"#86AE79",rakriktning:"#C0B063",samling:"#D6AE3C"};
(function initHUD(){
  const pr=document.getElementById("pyrRows");
  for(const k of [...Skala.ORDER].reverse()){
    const d=document.createElement("div");d.className="prow";d.dataset.k=k;
    d.innerHTML=`<span class="pname">${Skala.LABEL[k]}</span>
      <span class="ptrack"><i class="pfill" style="background:${PCOL[k]}"></i><i class="pcap"></i></span>`;
    pr.appendChild(d);}
  const ar=document.getElementById("aidRows");
  const rows=[["skankel","Skänkel","W/S"],["tygel","Tygel","Space"],["sits","Sits","⇧/Ctrl"],["styrning","Styr","A/D"]];
  for(const[k,n,key]of rows){
    const d=document.createElement("div");d.className="arow";d.dataset.k=k;
    let band="";
    if(k==="tygel")band=`<i class="band" style="left:22%;width:36%"></i>`;
    if(k==="skankel")band=`<i class="band" style="left:28%;width:45%"></i>`;
    d.innerHTML=`<span class="aname">${n}</span><span class="atrack">${band}<i class="v"></i></span><span class="akey">${key}</span>`;
    ar.appendChild(d);}
})();
function ritaHUD(){
  if(!G.ride)return;
  for(const k of Skala.ORDER){
    const row=document.querySelector(`.prow[data-k="${k}"]`);if(!row)continue;
    const v=G.ride.skala[k];
    row.querySelector(".pfill").style.width=(v*100).toFixed(1)+"%";
    // takmarkering: kapas nivån av golvet under?
    let golv=1;for(const kk of Skala.ORDER){if(kk===k)break;if(G.ride.skala[kk]<golv)golv=G.ride.skala[kk];}
    const kapad=v>=golv+Skala.TOL-0.005&&golv<0.98;
    const cap=row.querySelector(".pcap");
    cap.classList.toggle("on",kapad);
    if(kapad)cap.style.width=((golv+Skala.TOL)*100).toFixed(1)+"%";
  }
  document.querySelector("#inverkan b").textContent=
    Skala.inverkan(G.ride.skala,G.grupp).toFixed(2).replace(".",",");
  const g=Gait.G[G.ride.gangart];
  document.getElementById("gait").textContent=g.namn+(G.ride.gangart==="trav"?(IN.latt?" · lättridning":" · nedsittning"):"");
  document.getElementById("tempo").textContent=G.ride.tempo.toFixed(1).replace(".",",")+" m/s";
  /* Känsla är information, inte kraft: har du den ser du spänningen
     hela tiden, inte bara när den redan är för hög. */
  {const w=document.getElementById("gaitWarn"), sp=G.ride.spanning;
   const diag=G.ride.gangart==="trav"&&IN.latt&&IN.diagonal===0;
   const kanner=(typeof jagHar==="function")&&jagHar("kansla");
   let txt, ton="";
   if(sp>0.6){ txt="SPÄND"+(kanner?" "+sp.toFixed(2).replace(".",","):""); ton="hog"; }
   else if(diag) txt="FEL DIAGONAL (Q)";
   else if(kanner){ txt="SPÄNNING "+sp.toFixed(2).replace(".",",");
     ton=sp>0.40?"mitt":"lag"; }
   else txt="";
   w.textContent=txt;
   w.className=ton;}
  if(G.aids)for(const k in IN.kan){
    const row=document.querySelector(`.arow[data-k="${k}"] .v`);if(!row)continue;
    const v=k==="sits"?(G.aids[k]+1)/2:k==="styrning"?(G.aids[k]+1)/2:G.aids[k];
    if(k==="styrning"){row.style.left=(v*100-2)+"%";row.style.width="4%";}
    else{row.style.left=0;row.style.width=(v*100)+"%";}
  }
  if(typeof ritaIntroTangenter==="function")ritaIntroTangenter();
  if(G.sagaT>0){G.sagaT-=1/60;if(G.sagaT<=0)document.getElementById("saga").classList.remove("on");}
}

/* ── Huvudloop ── */
let last=performance.now();
function loop(now){
  /* 3D-modulerna laddas efter den här filen — vänta tills de finns. */
  if(typeof gl3dLage!=="function"){requestAnimationFrame(loop);return;}
  const dt=Math.min((now-last)/1000,0.05);last=now;G.t+=dt;
  ljudPuls(dt);
  if(G.scen==="lektion"||G.scen==="bana"){
    stegaRitt(dt);stegaNPC(dt);stegaLektion(dt);
    if(G.luft>0)G.luft-=dt;
    if(G.vy==="2d"){gl3dLage(false);draw2D(G);}else draw3D(G);
    ritaHUD(); ritaVaxer();
  } else if(G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne"){
    gl3dLage(false);
    stegaVandring(dt);ritaVandring();
  } else if(G.scen==="resultat"){
    if(G.vy==="2d"){gl3dLage(false);draw2D(G);}else draw3D(G);
  } else gl3dLage(false);
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
