/* ══════════════════════════════════════════════════════════════════
   VÄRLDEN — gå-läget. Du börjar längst ner i kedjan: till fots vid
   infarten från Husbyvägen. Två scener ("gard", "stallinne") med
   W/S fram/back, A/D sväng, Shift jogg, E interagera, V växlar
   karta/tredjeperson. Geometrin ligger i site.js — den här filen
   vet bara hur man går, krockar och ritar det fotona visar.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const GA={fart:1.8, jogg:3.4, svangMax:5.5, accel:8, broms:13, radie:0.35};
const VD={
  px:0, py:0, rikt:0, fart:0, fas:0, tid:0,
  spår:[], hastX:0, hastY:0, hastRikt:0,
  prompt:null, ePrev:false, _ov:null,
  /* Klickmålet på kartan: {x, y, namn} eller null. Se GÅ HIT nedan. */
  mal:null, malT:0, malAvst:0, vag:null,
};

/* ── GÅ HIT ────────────────────────────────────────────────────────
   Kartan visade var man var men gick inte att använda till något: man
   såg ridhuset i andra änden av tomten och fick ändå hålla W nedtryckt
   i tjugo sekunder. En karta man inte kan peka på är en bild.

   Klicka någonstans och figuren går dit. Klickar du på ett hus eller en
   dörr siktar den på dörren i stället för på väggen — annars går man
   fram till fasaden och står där, vilket är precis det kartan skulle
   slippa. Framme dyker den vanliga E-prompten upp; gåendet öppnar
   ingenting av sig självt, för ett scenbyte man inte bad om är värre än
   ett steg för mycket.

   Vilken som helst av W/A/S/D avbryter direkt. Målet ska aldrig ta ifrån
   någon styrningen — det är en genväg, inte en autopilot. */
const V2T={ox:0, oy:0, s:1, hojd:0, scen:null};   // senaste 2D-vyns transform
function v2tSatt(ox,oy,s,hojd){ V2T.ox=ox; V2T.oy=oy; V2T.s=s;
  V2T.hojd=hojd; V2T.scen=G.scen; }
function v2tVarld(sx,sy){ return [(sx-V2T.ox)/V2T.s, V2T.hojd-(sy-V2T.oy)/V2T.s]; }

/* Närmaste dörr/interaktion till en punkt, inom `max` meter. */
function malNaraDorr(x,y,max){
  let bast=null, bd=max;
  for(const i of interaktioner()){
    const d=Math.hypot(x-i.pos[0], y-i.pos[1]);
    if(d<bd){bd=d; bast=i;}
  }
  return bast;
}
/* Ligger punkten inne i ett hus? Då menade man huset, inte väggen. */
function malIHus(x,y){
  if(G.scen!=="gard")return null;
  for(const b of ANL.byggnader){
    const r=b.rekt;
    if(x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h)return b;
  }
  return null;
}
function satMal(x,y){
  if(G.scen!=="gard"&&G.scen!=="stallinne"&&G.scen!=="ridhusinne")return;
  let namn="";
  const hus=malIHus(x,y);
  if(hus){
    /* Klick på ett hus → närmaste dörr TILL det huset. Utan det gick man
       in i fasaden och blev stående. */
    let bast=null, bd=1e9;
    for(const i of interaktioner()){
      const r=hus.rekt, p=i.pos;
      const nara=p[0]>=r.x-4&&p[0]<=r.x+r.w+4&&p[1]>=r.y-4&&p[1]<=r.y+r.h+4;
      if(!nara)continue;
      const d=Math.hypot(x-p[0],y-p[1]);
      if(d<bd){bd=d;bast=i;}
    }
    if(bast){x=bast.pos[0]; y=bast.pos[1]; namn=hus.label||"";}
  }else{
    const d=malNaraDorr(x,y,3.0);
    if(d){x=d.pos[0]; y=d.pos[1];}
  }
  VD.mal={x, y, namn};
  VD.malT=0;
  VD.malAvst=Math.hypot(x-VD.px, y-VD.py);
  /* Vägen räknas ut EN gång, vid klicket. Går ingen väg att hitta får
     den raka linjen försöka ändå — då fångar fastnadsvakten det, och
     spelaren får ett besked i stället för en figur som maler mot en
     vägg. */
  VD.vag=navVag(VD.px,VD.py,x,y);
}
function slutaGa(){ VD.mal=null; VD.vag=null; }

/* Klick och tryck på kartan. Bara i 2D — i 3D är det ingen karta, och
   ett klick där skulle betyda något annat. */
if(typeof cv!=="undefined"&&cv&&cv.addEventListener)
  cv.addEventListener("pointerdown",e=>{
    if(G.vy!=="2d")return;
    if(G.scen!=="gard"&&G.scen!=="stallinne"&&G.scen!=="ridhusinne")return;
    if(typeof overlayUppe==="function"&&overlayUppe())return;
    if(V2T.scen!==G.scen)return;                  // vyn har inte ritats än
    const [x,y]=v2tVarld(e.offsetX,e.offsetY);
    satMal(x,y);
  });

const VCOL={
  gras:"#5D6C39", grasLj:"#6C7C44", grus:"#BCA179", asfalt:"#54524E",
  sand:"#DCC9A0", sandKant:"#9C8B66", aker:"#B08F55", betong:"#A09A8C",
  slant:"#54663A",
  tak:"#41454C", vit:"#F0EADC", knut:"#EFE8D8",
  fonster:"#3A4A5C", fonsterLj:"#93A9BC",
  dorrgul:"#D9A13E", dorrvit:"#E8E2D4", dorrgra:"#A2A4A6", dorrmork:"#463F38",
  portplat:"#B4B7B9", portsilver:"#C4C7C9", dorr:"#33291F",
  himmel0:"#6F9BC4", himmel1:"#F4DFB2", skog:"#44502B",
  staketTra:"#B0A184", staketEl:"#8C8578", staketRail:"#8A3129",
  galv:"#B9BDC0",
  stallVagg:"#CFC8BC", boxFront:"#4A4D50", boxRam:"#B4B8BB", galler:"#989CA0",
  skylt:"#2A2E34", parlspont:"#F0EADC",
  moln:"#FBF6EA", molnSkugga:"#E4D2B4", sol:"#FFE9B0",
  stam:"#5E4A34",
};
/* Höstlövverk — färg per träd ur hash. */
const TRADFARG=[
  ["#4E6B33","#5E7B3C"],["#5A7438","#6B8542"],["#C1762F","#D28A3C"],
  ["#B0512E","#C4653A"],["#C99B3A","#D9AE4C"],["#54703A","#648044"],
  ["#A8622C","#BC7838"],
];

function fargSkala(hex,f){
  const n=parseInt(hex.slice(1),16);
  const r=Math.min(255,(n>>16)*f)|0, g=Math.min(255,((n>>8)&255)*f)|0, b=Math.min(255,(n&255)*f)|0;
  return `rgb(${r},${g},${b})`;
}
/* Kvällssol i sydväst — västfasader glöder, norr i skugga. */
const SKUGGA={S:0.98,W:1.08,E:0.72,N:0.60,takW:1.02,takE:0.74,platt:0.94};
const SOLRIKT=[0.62,0.38];   // skuggor faller mot nordost
function fargVarm(hex,f){    // solbelysta ytor drar åt guld
  const n=parseInt(hex.slice(1),16);
  const r=Math.min(255,((n>>16)&255)*f*1.06)|0;
  const g=Math.min(255,((n>>8)&255)*f)|0;
  const b=Math.min(255,(n&255)*f*0.90)|0;
  return `rgb(${r},${g},${b})`;
}

/* ── Gå-fysik ─────────────────────────────────────────────────── */
function kollideraRekt(nx,ny,r,rekt){
  const cx2=clamp(nx,rekt.x,rekt.x+rekt.w), cy=clamp(ny,rekt.y,rekt.y+rekt.h);
  const dx=nx-cx2, dy=ny-cy, d2=dx*dx+dy*dy;
  if(d2>=r*r) return [nx,ny];
  if(d2<1e-9){ // inne i rektangeln — knuffa ut åt närmsta kant
    const v=[nx-rekt.x, rekt.x+rekt.w-nx, ny-rekt.y, rekt.y+rekt.h-ny];
    const i=v.indexOf(Math.min(...v));
    if(i===0)return[rekt.x-r,ny]; if(i===1)return[rekt.x+rekt.w+r,ny];
    if(i===2)return[nx,rekt.y-r]; return[nx,rekt.y+rekt.h+r];
  }
  const d=Math.sqrt(d2);
  return [cx2+dx/d*r, cy+dy/d*r];
}
function kollideraSeg(nx,ny,r,ax,ay,bx,by){
  const abx=bx-ax,aby=by-ay,len2=abx*abx+aby*aby;
  const t=len2>0?clamp(((nx-ax)*abx+(ny-ay)*aby)/len2,0,1):0;
  const cx2=ax+abx*t, cy=ay+aby*t, dx=nx-cx2, dy=ny-cy, d2=dx*dx+dy*dy;
  if(d2>=r*r||d2<1e-9) return [nx,ny];
  const d=Math.sqrt(d2);
  return [cx2+dx/d*r, cy+dy/d*r];
}

function overlayUppe(){
  if(!VD._ov)VD._ov=document.getElementById("ov");
  return !VD._ov.classList.contains("hide");
}

function stegaVandring(dt){
  VD.tid+=dt;
  if(overlayUppe())return;
  /* Styrningen är KAMERARELATIV: W går dit kameran tittar, A/D i sidled,
     S mot kameran — figuren vrider sig mjukt mot rörelseriktningen och
     går dit. I kartvyn är referensen norr, så W alltid är uppåt på
     kartan. Det gamla tankläget (A/D roterar, W ger gas) är borta: det
     var det som gjorde att höger och vänster kändes slumpartade, och
     varje rättning bara flyttade felet. Kursen är atan2-vinkel där
     VÄXANDE vinkel är moturs — höger om en kurs v är därför
     (sin v, −cos v). */
  /* Pekskärmens joystick är analog: riktningen och styrkan kommer
     därifrån när den används, annars från tangenterna. Diagonalen
     normaliseras av att farten sätts separat från riktningen — den
     blir aldrig snabbare än en rak linje. */
  let ix=(IN.ned.KeyD?1:0)-(IN.ned.KeyA?1:0);
  let iy=(IN.ned.KeyW?1:0)-(IN.ned.KeyS?1:0);
  let styrka=1;
  if(IN.joy){ ix=IN.joy.x; iy=-IN.joy.y; styrka=IN.joy.styrka; }
  const jogg=IN.ned.ShiftLeft||IN.ned.ShiftRight;
  let onskad=null, malFart=0;
  if(ix||iy){
    const v=vandringYaw();
    const rx=Math.cos(v)*iy+Math.sin(v)*ix;
    const ry=Math.sin(v)*iy-Math.cos(v)*ix;
    onskad=Math.atan2(ry,rx);
    malFart=IN.joy ? GA.fart+(GA.jogg-GA.fart)*Math.max(0,styrka-0.55)/0.45
                   : (jogg?GA.jogg:GA.fart);
  }

  /* GÅ HIT: klickmålet styr — men bara så länge spelaren håller
     fingrarna borta. Minsta tangenttryck avbryter. */
  if(VD.mal){
    /* Nästa punkt på vägen, inte målet självt — det är skillnaden
       mellan att gå runt ridhuset och att gå in i det. */
    while(VD.vag&&VD.vag.length>1&&
      Math.hypot(VD.vag[0][0]-VD.px,VD.vag[0][1]-VD.py)<1.1)VD.vag.shift();
    const delmal=(VD.vag&&VD.vag.length)?VD.vag[0]:[VD.mal.x,VD.mal.y];
    const avst=Math.hypot(VD.mal.x-VD.px, VD.mal.y-VD.py);
    if(ix||iy||avst<0.9){
      slutaGa();
    }else{
      onskad=Math.atan2(delmal[1]-VD.py, delmal[0]-VD.px);
      malFart=GA.fart;
      /* Fastnar man bakom ett hörn ska gåendet SLUTA, inte stå och
         trycka mot en vägg. Kommer man inte 0,2 m närmare på två
         sekunder är vägen inte fri, och då får spelaren styra själv. */
      VD.malT+=dt;
      if(VD.malT>2){
        if(VD.malAvst-avst<0.2){ slutaGa(); saga("Du kommer inte fram den vägen.",2.6); }
        VD.malT=0; VD.malAvst=avst;
      }
    }
  }

  /* Vrid mjukt mot önskad kurs, och håll igen på farten i skarpa
     svängar — figuren går i en båge i stället för att kana i sidled. */
  if(onskad!==null){
    let d=onskad-VD.rikt;
    while(d>Math.PI)d-=2*Math.PI; while(d<-Math.PI)d+=2*Math.PI;
    VD.rikt+=clamp(d*10,-GA.svangMax,GA.svangMax)*dt;
    if(Math.abs(d)>1.4)malFart*=0.25;
    else if(Math.abs(d)>0.6)malFart*=0.6;
  }
  /* Ansats och broms i stället för tvärstart och tvärstopp. */
  VD.fart+=clamp(malFart-VD.fart,-GA.broms*dt,GA.accel*dt);
  if(!malFart&&VD.fart<0.04)VD.fart=0;

  let nx=VD.px+Math.cos(VD.rikt)*VD.fart*dt;
  let ny=VD.py+Math.sin(VD.rikt)*VD.fart*dt;
  [nx,ny]=vandringKollision(nx,ny,GA.radie);
  VD.px=nx; VD.py=ny;
  if(VD.fart>0.05){
    ljudFotsteg(VD.fart*dt,G.scen==="stallinne"?"sten":"grus");
    VD.fas=(VD.fas+VD.fart*dt*1.9)%1;
    const sp=VD.spår;
    if(!sp.length||Math.hypot(nx-sp[sp.length-1][0],ny-sp[sp.length-1][1])>0.35)
      sp.push([nx,ny]); if(sp.length>40)sp.shift();
  }
  ledHasten();
  interagera();
}

/* Styrningens referenskurs: GL-kamerans blick i 3D, norr i kartvyn,
   och figurens egen kurs i målarvyn (vars kamera sitter fast bakom
   ryggen — där är kamerarelativt och figurrelativt samma sak). */
function vandringYaw(){
  if(G.vy==="2d")return Math.PI/2;
  if(typeof V3D!=="undefined"&&V3D.kam&&V3D.kam.satt){
    const k=V3D.kam, dx=VD.px-k.x, dy=VD.py-k.z;
    if(dx*dx+dy*dy>0.04)return Math.atan2(dy,dx);
  }
  return VD.rikt;
}

/* Scenens väggar, i ETT anrop. Både gåendet och vägsökningen frågar den
   här funktionen, så att en väg aldrig kan gå genom något gåendet stoppas
   av — två beskrivningar av samma hus blir förr eller senare oense. */
function vandringKollision(nx,ny,r){
  if(G.scen==="gard"){
    for(const b of ANL.byggnader) [nx,ny]=kollideraRekt(nx,ny,r+0.2,b.rekt);
    for(const st of ANL.staket) for(let i=0;i<st.p.length-1;i++)
      [nx,ny]=kollideraSeg(nx,ny,r,st.p[i][0],st.p[i][1],st.p[i+1][0],st.p[i+1][1]);
    nx=clamp(nx,1,ANL.bredd-1); ny=clamp(ny,1,ANL.djup-1);
  }else if(G.scen==="ridhusinne"){
    const R=RIDHUSINNE, ba=R.bana;
    nx=clamp(nx,0.5,R.bredd-0.5); ny=clamp(ny,0.5,R.langd-0.5);
    /* Sargen som väggar. Gapet i norra sargen är SPELABSTRAKTIONEN sargport
       (src/site.js) — inte fidelity; ingen bild visar en grind där. */
    const sp=SPELABSTRAKTIONER.ridhus.sargport;
    [nx,ny]=kollideraSeg(nx,ny,r,ba.x,ba.y+ba.h,sp.x0,ba.y+ba.h);
    [nx,ny]=kollideraSeg(nx,ny,r,sp.x1,ba.y+ba.h,ba.x+ba.w,ba.y+ba.h);
    [nx,ny]=kollideraSeg(nx,ny,r,ba.x,ba.y,ba.x+ba.w,ba.y);
    [nx,ny]=kollideraSeg(nx,ny,r,ba.x,ba.y,ba.x,ba.y+ba.h);
    /* Östra långsidan i två stycken: grinden mot hästgången är gapet.
       Utan den går det inte att leda hästen mellan banan och gången, och
       vägsökningen hittar ingen väg dit — det var precis vad den sa. */
    {const gr=R.sargGrind;
     if(gr){
       [nx,ny]=kollideraSeg(nx,ny,r,ba.x+ba.w,ba.y,ba.x+ba.w,gr.y0);
       [nx,ny]=kollideraSeg(nx,ny,r,ba.x+ba.w,gr.y1,ba.x+ba.w,ba.y+ba.h);
     }else{
       [nx,ny]=kollideraSeg(nx,ny,r,ba.x+ba.w,ba.y,ba.x+ba.w,ba.y+ba.h);
     }}
    // läktaren och domarbåset är solida. Läktaren läses i sektioner ifall
    // den någon gång får ett gap igen; utan gap är den ett stycke.
    for(const sek of laktarSektioner(R.laktare))
      [nx,ny]=kollideraRekt(nx,ny,r,{x:R.laktare.x0,y:sek.y0,
        w:R.laktare.dackDjup,h:sek.y1-sek.y0});
    [nx,ny]=kollideraRekt(nx,ny,r,{x:R.domarbas.x-R.domarbas.b/2,y:R.domarbas.y-R.domarbas.b/2,
      w:R.domarbas.b,h:R.domarbas.b});
    /* C-blocket vid norra änden är ett bänkblock man inte går igenom. */
    {const K=R.kortanda; if(K) [nx,ny]=kollideraRekt(nx,ny,r,{x:K.x0,y:K.y0,w:K.x1-K.x0,h:K.y1-K.y0});}
    /* Entrédelen ur planen: väggarna segment för segment med planens
       luckor, och de slutna rummen (toaletterna, schaktet) som lådor. Samma
       regel som stallets klubbdel. */
    if(R.entrehall){
      for(const v of R.entrehall.vaggar){
        const t=(v.tjock||0.16)/2;
        for(const [a0,a1] of klubbVaggBitar(v)){
          if(v.typ==="tvar") [nx,ny]=kollideraRekt(nx,ny,r,{x:a0,y:v.y-t,w:a1-a0,h:2*t});
          else               [nx,ny]=kollideraRekt(nx,ny,r,{x:v.x-t,y:a0,w:2*t,h:a1-a0});
        }
      }
      for(const rum of R.entrehall.rum) if(rum.stangt) [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
    }
  }else{ // stallinne
    /* Dubbelstallet går inte att uttrycka som ett intervall. Förut kläm-
       des spelaren in mellan två boxfronter, vilket bara fungerar när det
       finns exakt en gång. Nu frågas listan över gångytor: ett steg gäller
       om det landar i någon av dem, annars provas axlarna var för sig så
       att man glider längs en boxfront i stället för att fastna i den. */
    const S=STALLINNE;
    nx=clamp(nx,0.5,S.bredd-0.5); ny=clamp(ny,0.5,S.langd-0.5);
    let bast=null, bastD=Infinity;
    for(const g of S.gangytor){
      /* En gång smalare än figuren skulle annars bli oframkomlig; då
         klamras hon till mitten i stället för att spärras ute. */
      const kx=clamp(nx, Math.min(g.x+r, g.x+g.w/2), Math.max(g.x+g.w-r, g.x+g.w/2));
      const ky=clamp(ny, Math.min(g.y+r, g.y+g.h/2), Math.max(g.y+g.h-r, g.y+g.h/2));
      const d=(kx-nx)*(kx-nx)+(ky-ny)*(ky-ny);
      if(d<bastD){ bastD=d; bast=[kx,ky]; }
    }
    /* Ligger steget redan i en gångyta är avståndet noll och punkten
       lämnas orörd. Annars glider den till närmaste yta — vilket både ger
       en mjuk glidning längs en boxfront och säger rätt sak till
       vägsökningens rutnät, som frågar samma funktion. */
    if(bast) [nx,ny]=bast;
    /* Tvärväggarna i boxhallen: solida utom där en gång passerar.
       Gångytorna släpper redan igenom där, så det räcker att hålla kvar
       spelaren i dem. */
    for(const rum of S.rum)     [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
    for(const rum of S.service) [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
    /* KLUBBDELEN: golvet är EN gångyta, och det är väggarna som spärrar —
       segment för segment, med planens dörrar som luckor. Samma bitar som
       Roblox bygger ur Geometri.vaggBitar. De slutna rummen (den namnlösa
       volymen, Ö-toaletten, det lilla rummet) är hela lådor. */
    for(const v of S.klubb.vaggar){
      const t=(v.tjock||0.16)/2;
      for(const [a0,a1] of klubbVaggBitar(v)){
        if(v.typ==="tvar") [nx,ny]=kollideraRekt(nx,ny,r,{x:a0,y:v.y-t,w:a1-a0,h:2*t});
        else               [nx,ny]=kollideraRekt(nx,ny,r,{x:v.x-t,y:a0,w:2*t,h:a1-a0});
      }
    }
    for(const rum of S.klubb.rum) if(rum.stangt) [nx,ny]=kollideraRekt(nx,ny,r,rum.rekt);
  }
  return [nx,ny];
}

/* ── Vägsökning ────────────────────────────────────────────────────
   Ett klick i andra änden av tomten dög inte med en rak linje: figuren
   gick in i ridhusets långsida och blev stående 24 m från dörren, och
   fastnadsvakten stängde av gåendet. En genväg som bara fungerar när
   ingenting står i vägen är ingen genväg.

   Därför ett grovt rutnät och A*. Rutnätet frågar `vandringKollision` om
   varje ruta, alltså exakt samma väggar som gåendet självt stoppas av —
   ingen andra beskrivning av husen som kan bli osams med den första.
   Rutnätet byggs om bara när scenen byts; geometrin står still.

   210 × 170 m med 1,6-metersrutor blir 131 × 106 = knappt 14 000 rutor.
   A* över det tar under en millisekund och körs en gång per klick. */
const NAV={scen:null, cell:1.6, nx:0, ny:0, fri:null};

function navBygg(){
  const matt=G.scen==="gard" ? [ANL.bredd,ANL.djup]
    : G.scen==="ridhusinne" ? [RIDHUSINNE.bredd,RIDHUSINNE.langd]
    : [STALLINNE.bredd,STALLINNE.langd];
  NAV.cell=G.scen==="gard"?1.2:0.6;              // inomhus är gångarna smala
  NAV.nx=Math.ceil(matt[0]/NAV.cell); NAV.ny=Math.ceil(matt[1]/NAV.cell);
  NAV.fri=new Uint8Array(NAV.nx*NAV.ny);
  /* Rutan provas med en radie som täcker HELA rutan, inte bara dess
     mitt. Med enbart mittpunkten gled ett staket rakt mellan mätpunkterna
     och rutnätet svor på att vägen var fri: figuren gick 20 m och stod
     sedan still mot ett räcke vid y=42,0 som inga prov hade sett.
     Rutnätet får hellre vara för försiktigt än för optimistiskt — en väg
     som inte finns är värre än en väg som går en meter från väggen. */
  const r=GA.radie+NAV.cell*0.71;
  for(let j=0;j<NAV.ny;j++)for(let i=0;i<NAV.nx;i++){
    const x=(i+0.5)*NAV.cell, y=(j+0.5)*NAV.cell;
    const [kx,ky]=vandringKollision(x,y,r);
    NAV.fri[j*NAV.nx+i]=(Math.abs(kx-x)<1e-6&&Math.abs(ky-y)<1e-6)?1:0;
  }
  NAV.scen=G.scen;
}
function navRedo(){ if(NAV.scen!==G.scen)navBygg(); }
function navIx(x,y){
  const i=clamp(Math.floor(x/NAV.cell),0,NAV.nx-1);
  const j=clamp(Math.floor(y/NAV.cell),0,NAV.ny-1);
  return [i,j];
}
function navPunkt(i,j){ return [(i+0.5)*NAV.cell,(j+0.5)*NAV.cell]; }

/* Dörrar ligger i väggen och hamnar därför i en spärrad ruta. Sikta på
   den närmaste fria i stället — annars går ingen väg alls att hitta. */
function navNarmasteFri(x,y){
  let [i,j]=navIx(x,y);
  if(NAV.fri[j*NAV.nx+i])return [i,j];
  for(let rad=1;rad<=8;rad++){
    let bast=null,bd=1e9;
    for(let dj=-rad;dj<=rad;dj++)for(let di=-rad;di<=rad;di++){
      if(Math.max(Math.abs(di),Math.abs(dj))!==rad)continue;
      const a=i+di, b=j+dj;
      if(a<0||b<0||a>=NAV.nx||b>=NAV.ny||!NAV.fri[b*NAV.nx+a])continue;
      const [px,py]=navPunkt(a,b), d=Math.hypot(px-x,py-y);
      if(d<bd){bd=d;bast=[a,b];}
    }
    if(bast)return bast;
  }
  return null;
}

/* Fri sikt mellan två punkter? Används för att räta ut trapporna som
   ett rutnät alltid ger. */
function navFriSikt(ax,ay,bx,by){
  /* Mot de RIKTIGA väggarna, inte mot rutnätet. Rutnätet är avsiktligt
     försiktigt (se ovan) och skulle annars vägra den sista metern fram
     till en dörr, som per definition ligger i en vägg. */
  const d=Math.hypot(bx-ax,by-ay), steg=Math.max(1,Math.ceil(d/0.25));
  for(let k=1;k<steg;k++){
    const t=k/steg, x=ax+(bx-ax)*t, y=ay+(by-ay)*t;
    const [kx,ky]=vandringKollision(x,y,GA.radie);
    if(Math.abs(kx-x)>1e-6||Math.abs(ky-y)>1e-6)return false;
  }
  return true;
}

/* A* med oktilheuristik. Returnerar en lista världspunkter, eller null. */
function navVag(sx,sy,mx,my){
  navRedo();
  const start=navNarmasteFri(sx,sy), mal=navNarmasteFri(mx,my);
  if(!start||!mal)return null;
  const N=NAV.nx*NAV.ny, si=start[1]*NAV.nx+start[0], mi=mal[1]*NAV.nx+mal[0];
  if(si===mi)return [[mx,my]];
  const g=new Float32Array(N).fill(Infinity), fr=new Int32Array(N).fill(-1);
  const stangd=new Uint8Array(N);
  const h=(i)=>{const a=i%NAV.nx,b=(i/NAV.nx)|0;
    const dx=Math.abs(a-mal[0]),dy=Math.abs(b-mal[1]);
    return (dx+dy)+(Math.SQRT2-2)*Math.min(dx,dy);};
  /* En enkel binärhög räcker gott — kön blir aldrig stor. */
  const hog=[[h(si),si]];
  const putt=(v)=>{hog.push(v);let i=hog.length-1;
    while(i>0){const p=(i-1)>>1; if(hog[p][0]<=hog[i][0])break;
      [hog[p],hog[i]]=[hog[i],hog[p]]; i=p;}};
  const ta=()=>{const t=hog[0], sist=hog.pop();
    if(hog.length){hog[0]=sist;let i=0;
      for(;;){const l=2*i+1,r=l+1;let m=i;
        if(l<hog.length&&hog[l][0]<hog[m][0])m=l;
        if(r<hog.length&&hog[r][0]<hog[m][0])m=r;
        if(m===i)break; [hog[m],hog[i]]=[hog[i],hog[m]]; i=m;}}
    return t;};
  g[si]=0;
  while(hog.length){
    const [,cur]=ta();
    if(stangd[cur])continue;
    stangd[cur]=1;
    if(cur===mi)break;
    const a=cur%NAV.nx, b=(cur/NAV.nx)|0;
    for(let dj=-1;dj<=1;dj++)for(let di=-1;di<=1;di++){
      if(!di&&!dj)continue;
      const na=a+di, nb=b+dj;
      if(na<0||nb<0||na>=NAV.nx||nb>=NAV.ny)continue;
      const ni=nb*NAV.nx+na;
      if(!NAV.fri[ni]||stangd[ni])continue;
      /* Ingen genväg diagonalt förbi ett hörn. */
      if(di&&dj&&(!NAV.fri[b*NAV.nx+na]||!NAV.fri[nb*NAV.nx+a]))continue;
      const ny2=g[cur]+((di&&dj)?Math.SQRT2:1);
      if(ny2<g[ni]){ g[ni]=ny2; fr[ni]=cur; putt([ny2+h(ni),ni]); }
    }
  }
  if(fr[mi]<0&&si!==mi)return null;
  const rutor=[]; for(let i=mi;i>=0;i=fr[i]){rutor.push(i); if(i===si)break;}
  rutor.reverse();
  const pkt=rutor.map(i=>navPunkt(i%NAV.nx,(i/NAV.nx)|0));
  pkt.push([mx,my]);
  /* Räta ut: hoppa så långt fram fri sikt räcker. */
  const ut=[]; let i=0;
  while(i<pkt.length-1){
    let j=pkt.length-1;
    while(j>i+1&&!navFriSikt(pkt[i][0],pkt[i][1],pkt[j][0],pkt[j][1]))j--;
    ut.push(pkt[j]); i=j;
  }
  return ut;
}

/* Hästen följer 2,2 m bakom i spåret när du leder. */
function ledHasten(){
  if(G.leder){
    let kvar=2.2, hx=VD.px, hy=VD.py, vin=VD.rikt;
    const s=VD.spår;
    let fx=VD.px, fy=VD.py;
    for(let i=s.length-1;i>=0;i--){
      const d=Math.hypot(fx-s[i][0],fy-s[i][1]);
      if(d>=kvar){const t=kvar/Math.max(d,1e-6);
        hx=fx+(s[i][0]-fx)*t; hy=fy+(s[i][1]-fy)*t;
        vin=Math.atan2(fy-s[i][1],fx-s[i][0]); kvar=0; break;}
      kvar-=d; fx=s[i][0]; fy=s[i][1];
    }
    if(kvar>0){hx=fx-Math.cos(VD.rikt)*kvar; hy=fy-Math.sin(VD.rikt)*kvar;}
    VD.hastX=hx; VD.hastY=hy; VD.hastRikt=vin;
  }
}

/* Målmarkören: en ring som drar ihop sig, plus en streckad linje från
   figuren. Linjen är den som gör att man förstår att klicket TOG — utan
   den ser en ensam ring ut som pynt. */
function ritaMal2D(proj){
  if(!VD.mal)return;
  const [a,b]=proj(VD.mal.x,VD.mal.y);
  const puls=0.6+0.4*Math.sin(VD.tid*4);
  const r=Math.max(V2T.s*0.9,7);
  cx.save();
  cx.strokeStyle="rgba(240,206,110,.45)"; cx.lineWidth=1.5; cx.setLineDash([5,5]);
  cx.beginPath();
  {const [pa,pb]=proj(VD.px,VD.py); cx.moveTo(pa,pb);}
  /* Hela vägen, inte en rak linje till målet — annars ser det ut som att
     figuren tänker gå rakt genom huset, och det tänker den inte. */
  for(const q of (VD.vag||[[VD.mal.x,VD.mal.y]])){
    const [qa,qb]=proj(q[0],q[1]); cx.lineTo(qa,qb);
  }
  cx.stroke();
  cx.setLineDash([]);
  cx.strokeStyle="rgba(240,206,110,.95)"; cx.lineWidth=2.2;
  cx.beginPath(); cx.arc(a,b,r*puls,0,Math.PI*2); cx.stroke();
  cx.fillStyle="rgba(240,206,110,.9)";
  cx.beginPath(); cx.arc(a,b,2.4,0,Math.PI*2); cx.fill();
  if(VD.mal.namn){
    cx.font="600 12px system-ui,sans-serif"; cx.textAlign="center";
    cx.fillStyle="rgba(255,240,200,.95)";
    cx.fillText(VD.mal.namn,a,b-r-6);
  }
  cx.restore();
}

/* ── Interaktion ──────────────────────────────────────────────── */
function interaktioner(){
  const L=[];
  if(G.scen==="gard"){
    for(const d of ANL.dorrar){
      if(d.mot==="info"){
        L.push({pos:d.pos, text:d.text, gor(){saga(d.info,4);}});
      }else{
        L.push({pos:d.pos, text:d.text, gor(){gaTill(d.mot,d.spawn);}});
      }
    }
    /* Med sadlad häst vid handen kan lektionen ridas utomhus:
       uteridbanan nordost om stallet, eller skogsstigen från grupp 3. */
    if(G.leder&&G.skotselRes&&G.hastId){
      L.push({pos:[174,126], text:G.tavling&&G.tavling.typ==="dressyr"
          ?`Sitt upp — Dressyr LC börjar här`
          :`Sitt upp på uteridbanan — lektion utomhus`,
        gor(){sittUpp("utebana");}});
      const gIdx=GRUPPSTEGE.indexOf(G.grupp);
      L.push({pos:[114,118], text:gIdx>=5
          ?`Sitt upp för uteritt — skogsstigen`
          :`Skogsstigen (uteritt rids från grupp 3)`,
        gor(){
          if(gIdx>=5)sittUpp("stig");
          else saga("Uteritt får du följa med på från grupp 3 — skogen kräver en säker ryttare.",4);
        }});
    }
    if(G.hastId&&!G.hamtad&&!G.leder){
      const h=HORSES[G.hastId];
      L.push({pos:ANL.hamtHage.grind, text:`Öppna grinden och hämta ${h.namn}`,
        gor(){
          /* Egenhet: en svårfångad häst drar sig undan första försöket. */
          if(h.flaggor&&h.flaggor.svarfangad&&!G.fangstForsok){
            G.fangstForsok=true;
            saga(`${h.namn} lyfter huvudet och drar sig undan — precis som det står på listan. Stå still en stund och gå lugnt fram igen.`,4.5);
            return;
          }
          G.leder=true; G.tackePa=!!(G.vader&&G.vader.tacke); VD.spår.length=0;
          ljudGnagg();
          /* Hagen är blöt i regn och lerig i slasket — benen ska spolas. */
          G.lerig=!!(G.vader&&(G.vader.typ==="regn"||G.vader.temp<9));
          G.spolad=0;
          saga(G.tackePa
            ?`${h.namn} har täcket på i det här vädret. Grimman på — led honom till boxen.`
            :`Grimman på. Led ${h.namn} till boxen i stallet.`,4);
        }});
    }
  }else if(G.scen==="ridhusinne"){
    const R=RIDHUSINNE;
    for(const d of R.dorrar) L.push({pos:d.pos, text:d.text,
      gor(){gaTill(d.mot,d.spawn);}});
    for(const i of R.info) L.push({pos:i.pos, text:i.text, gor(){saga(i.svar,4.5);}});
    const sp=SPELABSTRAKTIONER.ridhus.sargport, portX=(sp.x0+sp.x1)/2;
    L.push({pos:[portX,R.bana.y+R.bana.h], text:G.leder
        ? (G.tavling&&G.tavling.typ==="hoppning"
          ? `Sitt upp — Påskhoppet, ${G.tavling.klass.namn}`
          : `Sitt upp på ${HORSES[G.hastId].namn} — lektionen börjar`)
        : "Sargporten",
      gor(){ if(G.leder)sittUpp("ridhus");
             else saga("Genom sargporten går man ut på banan. Hästarna kommer in genom hästgången från stallet.",3.5); }});
  }else{
    const S=STALLINNE;
    for(const d of S.dorrar) L.push({pos:d.pos,
      text:G.leder?`Led hästen ${d.text.toLowerCase().replace("ut ","ut ")}`:d.text,
      gor(){gaTill(d.mot,d.spawn);}});
    if(!G.hastId) L.push({pos:S.ridlarare.pos, text:"Prata med ridläraren",
      gor(){visaTilldelning();}});
    if(G.hastId&&!G.skotselRes){
      const b=hittaBox(G.hastId);
      if(b&&G.leder&&!G.hamtad){
        L.push({pos:b.dorr, text:G.lerig
            ?`Släpp in ${HORSES[G.hastId].namn} (leriga ben — spolspiltan ligger i söder)`
            :`Släpp in ${HORSES[G.hastId].namn} i boxen`,
          gor(){G.leder=false;G.hamtad=true;ljudFnys();
            saga(G.lerig
              ?"Han går in med leran kvar på benen. Ridläraren kommer att se den."
              :"Han går in och drar en tugga hö. Nu: boxen, fodret och sadeln.",3.5);}});
      }else if(b&&G.hamtad){
        L.push({pos:b.dorr, text:`Sköt om ${HORSES[G.hastId].namn} vid boxen`,
          gor(){visaBoxmeny();}});
      }
    }
    L.push({pos:S.whiteboard.pos, text:"Dagens schema (whiteboarden)",
      gor(){visaSchema();}});
    for(const i of (S.info||[])){
      /* Spolspiltan används med hästen vid handen, på väg in från hagen. */
      if(i.spolspilta){
        const kanSpola=G.hastId&&G.leder&&!G.hamtad;
        L.push({pos:i.pos, text:kanSpola
            ?(G.lerig?`Spola av leran på ${HORSES[G.hastId].namn}`
              :`Spola av ${HORSES[G.hastId].namn} i spiltan`)
            :"Spolspiltan",
          gor(){ if(kanSpola)visaSpolning();
            else saga("Spolspiltan: gummimattor, duschblandare och slangvinda på väggen. Hit leds hästen in från hagen när benen är leriga.",4.5); }});
        continue;
      }
      if(i.sadelkammare){
        L.push({pos:i.pos, text:G.hastId&&!G.utrustning
            ?`Hämta ${HORSES[G.hastId].namn}s sadel och träns`:"Sadelkammaren",
          gor(){visaSadelkammare();}});
        continue;
      }
      L.push({pos:i.pos, text:i.text,
        gor(){ if(i.teori)visaTeori();
          else if(i.klubb&&typeof visaKlubbrum==="function")visaKlubbrum();
          else saga(i.svar,4.5); }});
    }
  }
  return L;
}
function interagera(){
  const L=interaktioner(); let bast=null,bd=2.4;
  for(const i of L){const d=Math.hypot(VD.px-i.pos[0],VD.py-i.pos[1]); if(d<bd){bd=d;bast=i;}}
  VD.prompt=bast;
  const e=!!IN.ned.KeyE;
  if(e&&!VD.ePrev&&bast&&!overlayUppe()) bast.gor();
  VD.ePrev=e;
}
/* Boxarnas mitt-y, per rad. Facken läses ur STALLINNE.fack — samma lista
   som Roblox bygger ur — och där saknas det fack hästförbindelsen går
   igenom i västra raden. Förut räknades här en tvärkorridor in i ALLA
   rader; planen har ingen sådan. Utan rad-id faller den tillbaka på den
   längsta radens fack, vilket bara är rätt för de obrutna raderna. */
function boxY(i, radId){
  const S=STALLINNE, f=(S.fack[radId]||S.fack.MA)[i];
  return f ? (f.y0+f.y1)/2 : NaN;
}
function antalFack(radId){ return (STALLINNE.fack[radId]||[]).length; }
/* En klubbdelsvägg i bitar, öppningarna bortdragna. Samma regel som
   Geometri.vaggBitar i Roblox: `tvar` löper i x, `langs` i y, och bitarna
   ges i den koordinat väggen löper i. */
/* Var en dressyrbokstav hänger i husets koordinater. Layouten 20 × 60
   (`R.dressyr`) är förankrad i A på södra sargen; långsidesbokstäverna
   sitter på sargen vid sin layout-y. C är undantaget: fotot visar den på
   NORRA SARGEN framför C-blocket (`paSarg:"N"`), och den fysiska banan är
   längre än 60 m — då hänger skylten där fotot visar den, inte 5,5 m ut
   på sanden. `sida` säger vilken sarg (W/E/S/N) skylten sitter på. */
function bokstavLage(R,B){
  const dr=R.dressyr, ba=R.bana;
  let x=dr.x+B.x, y=dr.y+B.y, sida=B.x===0?"W":B.x===dr.w?"E":B.y===0?"S":"N";
  if(B.paSarg==="N"){ y=ba.y+ba.h; sida="N"; }
  else if(B.paSarg==="S"){ y=ba.y; sida="S"; }
  return {x,y,sida};
}
function klubbVaggBitar(v){
  const tvar=v.typ==="tvar";
  const a0=tvar?v.x0:v.y0, a1=tvar?v.x1:v.y1;
  const hal=(v.oppningar||[]).map(o=>tvar?[o.x0,o.x1]:[o.y0,o.y1]).sort((p,q)=>p[0]-q[0]);
  const ut=[]; let a=a0;
  for(const [h0,h1] of hal){ if(h0-a>0.05) ut.push([a,h0]); if(h1>a) a=h1; }
  if(a1-a>0.05) ut.push([a,a1]);
  return ut;
}
/* Boxfrontens x för en länga: radens kant mot sin gång. */
function boxFrontX(rad){
  /* Radens djup kommer ur planens uppmätta andel och skiljer sig mellan
     längorna — de yttre är djupare än de två i mitten. */
  return rad.vetter>0 ? rad.x0+rad.djup : rad.x0;
}
function hittaBox(hastId){
  const S=STALLINNE;
  for(const rad of S.rader){
    const lista=S.boxar[rad.id]||[];
    for(let i=0;i<Math.min(lista.length,antalFack(rad.id));i++) if(lista[i]===hastId){
      const y=boxY(i, rad.id);
      return {sida:rad.id, rad, i, y, dorr:[boxFrontX(rad), y]};
    }
  }
  return null;
}
/* Boxens skylt/häst: HORSES-id, "#NAMN" (riktig skylt, sällskapshäst)
   eller null (tom box). */
const SALLSKAPSFARG=["#5C4633","#6E5138","#4A3A2C","#7A5C40","#3E3128","#8A6E4E"];
function boxHast(id){
  if(!id)return null;
  if(id[0]==="#"){
    let h=0;for(const c of id)h=(h*31+c.charCodeAt(0))%997;
    return {namn:id.slice(1), farg:SALLSKAPSFARG[h%SALLSKAPSFARG.length], man:"#241A12", spelbar:false};
  }
  const h=HORSES[id];
  return h?{namn:h.namn, farg:h.farg, man:h.man, spelbar:true}:null;
}

/* ── Scenbyten ────────────────────────────────────────────────── */
/* Kameran ska SNAPPA vid scenbyte, inte flyga. Utan det svävar den
   genom väggar i en halv sekund, och — värre — den kamerarelativa
   styrningen läser den gamla blickriktningen så länge flygningen pågår,
   så W bär iväg åt fel håll precis när man kommit in genom en dörr. */
function kameraNollstall(){
  if(typeof V3D!=="undefined"&&V3D.kam)V3D.kam.satt=false;
}
function gaTill(scen,spawn){
  G.scen=scen;
  if(spawn){VD.px=spawn.x;VD.py=spawn.y;VD.rikt=spawn.rikt;VD.spår.length=0;VD.fart=0;}
  slutaGa();                       // ett mål i förra scenen betyder inget här
  /* Rutnätet byggs vid dörren, inte vid första klicket. Gården kostar
     69 ms att rasta, och den pausen hör hemma i scenbytet — där det redan
     hackar — och inte i ett klick som ska kännas omedelbart. */
  navBygg();
  kameraNollstall();
}
function startaVandring(){
  overlay(false);
  G.scen="gard"; G.hastId=null; G.skotselRes=null; G.leder=false;
  G.sysslor={mockat:0,fodrat:0}; G.hamtad=false; G.tackePa=false;
  G.fangstForsok=false; G.utrustning=false; G.lerig=false; G.spolad=0;
  // dagens väder — avgör om hästarna går med täcke i hagen
  const v=(G.seed*2654435761>>>0)%100;
  G.vader={typ:v<52?"sol":v<80?"mulet":"regn", temp:7+(v%11)};
  G.vader.tacke=G.vader.typ==="regn"||G.vader.temp<10;
  const s=ANL.spawn; VD.px=s.x;VD.py=s.y;VD.rikt=s.rikt;VD.spår.length=0;
  VD.fart=0; kameraNollstall();
  hudLage("gang");
  const vtext={sol:"Kvällssolen ligger över åkrarna.",
    mulet:"Mulet och stilla över Bro.",
    regn:"Regnet trummar på plåttaken."}[G.vader.typ];
  saga(`Du är framme på Husbyvägen 1A. ${vtext} Ridläraren väntar i stallgången.`,4.5);
}
function hudLage(lage){
  const gang=lage==="gang";
  for(const id of ["pyr","aids","gait"]){
    const el=document.getElementById(id);
    if(el){const hud=el.closest(".hudh")||el; hud.style.display=gang?"none":"";}
  }
  const vt=document.getElementById("viewToggle");
  vt.hidden=false;
  vt.querySelector('[data-v="2d"]').textContent=gang?"Karta":"Bana";
  vt.querySelector('[data-v="3d"]').textContent=gang?"Bakom dig":"Sidovy";
}
function visaUppgift(rubrik,text){
  document.getElementById("momentLbl").textContent="Uppgift";
  document.getElementById("momentNamn").textContent=rubrik;
  document.getElementById("momentText").textContent=text||"";
  document.querySelector("#momentBar i").style.width="0%";
}

/* ── 3D-maskineri: kamera, near-klipp, painter ────────────────── */
const K3={hojd:1.62, bak:3.6, fov:1.02, horisont:0.52, nara:0.35};
function kamera(){
  let kx=VD.px-Math.cos(VD.rikt)*K3.bak, ky=VD.py-Math.sin(VD.rikt)*K3.bak;
  if(G.scen==="gard")
    for(const b of ANL.byggnader)[kx,ky]=kollideraRekt(kx,ky,0.4,b.rekt);
  return {x:kx, y:ky,
    z:K3.hojd+0.5, fx:Math.cos(VD.rikt), fy:Math.sin(VD.rikt),
    f:(CH*0.92)/K3.fov, hor:CH*K3.horisont};
}
function tillKam(k,x,y,z){
  // s är höger-axeln: öster hamnar till höger när man tittar norrut,
  // så att 3D-vyn stämmer med kartan och verkligheten.
  const dx=x-k.x, dy=y-k.y;
  return {d:dx*k.fx+dy*k.fy, s:dx*k.fy-dy*k.fx, h:z-k.z};
}
function projK(k,p){ return [CW/2+p.s/p.d*k.f, k.hor-p.h/p.d*k.f]; }
function klippPoly(pts){ // Sutherland–Hodgman mot d >= K3.nara
  const ut=[];
  for(let i=0;i<pts.length;i++){
    const a=pts[i], b=pts[(i+1)%pts.length];
    const ain=a.d>=K3.nara, bin=b.d>=K3.nara;
    if(ain)ut.push(a);
    if(ain!==bin){
      const t=(K3.nara-a.d)/(b.d-a.d);
      ut.push({d:K3.nara, s:a.s+(b.s-a.s)*t, h:a.h+(b.h-a.h)*t});
    }
  }
  return ut;
}
function ritaPoly3D(k,varldPts,fill,kant){
  let pts=varldPts.map(p=>tillKam(k,p[0],p[1],p[2]));
  pts=klippPoly(pts); if(pts.length<3)return;
  cx.beginPath();
  const s0=projK(k,pts[0]); cx.moveTo(s0[0],s0[1]);
  for(let i=1;i<pts.length;i++){const s=projK(k,pts[i]);cx.lineTo(s[0],s[1]);}
  cx.closePath();
  if(fill){cx.fillStyle=fill;cx.fill();}
  if(kant){cx.strokeStyle=kant;cx.lineWidth=1;cx.stroke();}
}
function ritaLinje3D(k,a,b,farg,bredd){
  const p0=tillKam(k,a[0],a[1],a[2]), p1=tillKam(k,b[0],b[1],b[2]);
  if(p0.d<K3.nara&&p1.d<K3.nara)return;
  let A=p0,B=p1;
  if(A.d<K3.nara){const t=(K3.nara-A.d)/(B.d-A.d);
    A={d:K3.nara,s:A.s+(B.s-A.s)*t,h:A.h+(B.h-A.h)*t};}
  if(B.d<K3.nara){const t=(K3.nara-B.d)/(A.d-B.d);
    B={d:K3.nara,s:B.s+(A.s-B.s)*t,h:B.h+(A.h-B.h)*t};}
  const s0=projK(k,A), s1=projK(k,B);
  cx.strokeStyle=farg; cx.lineWidth=bredd;
  cx.beginPath();cx.moveTo(s0[0],s0[1]);cx.lineTo(s1[0],s1[1]);cx.stroke();
}
function ritaText3D(k,x,y,z,txt,storlek,farg,font){
  const p=tillKam(k,x,y,z); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(storlek*k.f/(p.d*38),7,42);
  cx.fillStyle=farg; cx.font=`600 ${sz}px ${font||'"IBM Plex Mono",monospace'}`;
  cx.textAlign="center"; cx.fillText(txt,s[0],s[1]);
}
function avst2(p){return (p[0]-VD.px)**2+(p[1]-VD.py)**2;}

/* ── Byggnader ────────────────────────────────────────────────── */
function byggnadsYtor(b){
  const {x,y,w,h}=b.rekt, hV=b.hV, hN=b.hN, mx=x+w/2, my=y+h/2, ytor=[];
  const hörn={SW:[x,y],SE:[x+w,y],NE:[x+w,y+h],NW:[x,y+h]};
  const vagg=(p0,p1,sida)=>{
    const gavel=(b.nock==="NS"&&(sida==="S"||sida==="N"))||(b.nock==="EW"&&(sida==="E"||sida==="W"));
    const pts=[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],hV]];
    if(gavel){
      const m=[(p0[0]+p1[0])/2,(p0[1]+p1[1])/2];
      pts.push([m[0],m[1],hN]);
    }
    pts.push([p0[0],p0[1],hV]);
    const solig=sida==="W"||sida==="S";
    ytor.push({mitt:[(p0[0]+p1[0])/2,(p0[1]+p1[1])/2], pts,
      farg:(solig?fargVarm:fargSkala)(b.fargV,SKUGGA[sida]), sida, p0, p1, gavel});
  };
  vagg(hörn.SW,hörn.SE,"S"); vagg(hörn.SE,hörn.NE,"E");
  vagg(hörn.NE,hörn.NW,"N"); vagg(hörn.NW,hörn.SW,"W");
  if(b.nock==="NS"){
    ytor.push({mitt:[x+w*0.25,my], tak:true, farg:fargVarm(b.fargT,SKUGGA.takW),
      pts:[[x,y,hV],[x,y+h,hV],[mx,y+h,hN],[mx,y,hN]]});
    ytor.push({mitt:[x+w*0.75,my], tak:true, farg:fargSkala(b.fargT,SKUGGA.takE),
      pts:[[x+w,y,hV],[x+w,y+h,hV],[mx,y+h,hN],[mx,y,hN]]});
  }else{
    ytor.push({mitt:[mx,y+h*0.25], tak:true, farg:fargSkala(b.fargT,SKUGGA.takE),
      pts:[[x,y,hV],[x+w,y,hV],[x+w,my,hN],[x,my,hN]]});
    ytor.push({mitt:[mx,y+h*0.75], tak:true, farg:fargVarm(b.fargT,SKUGGA.takW),
      pts:[[x,y+h,hV],[x+w,y+h,hV],[x+w,my,hN],[x,my,hN]]});
  }
  return ytor;
}
/* Fasaddetaljer: plåtprofiler eller träpanel, vita knutar, sockel,
   takfotsskugga. Ritas ovanpå väggfyllningen. */
function ritaFasadDetalj(k,b,y){
  const p0=y.p0, p1=y.p1, hV=b.hV;
  const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]);
  const ux=(p1[0]-p0[0])/L, uy=(p1[1]-p0[1])/L;
  const P=(t,z)=>[p0[0]+ux*t, p0[1]+uy*t, z];
  const mitt=tillKam(k,y.mitt[0],y.mitt[1],1);
  if(mitt.d<K3.nara) return;
  const nara=mitt.d<40;
  if(b.plat){                       // korrugerad plåt: vertikala profiler
    if(nara){const steg=Math.max(0.9,mitt.d*0.05);
      for(let t=steg;t<L;t+=steg)
        ritaLinje3D(k,P(t,0.12),P(t,hV-0.1),"rgba(0,0,0,.10)",1);}
  }else{                            // liggande träpanel
    if(nara){const steg=Math.max(0.5,mitt.d*0.035);
      for(let z=steg;z<hV-0.15;z+=steg)
        ritaLinje3D(k,P(0.05,z),P(L-0.05,z),"rgba(40,20,10,.12)",1);}
    // vita knutar i hörnen
    ritaPoly3D(k,[P(0,0),P(0.16,0),P(0.16,hV),P(0,hV)],VCOL.knut,null);
    ritaPoly3D(k,[P(L-0.16,0),P(L,0),P(L,hV),P(L-0.16,hV)],VCOL.knut,null);
    // vit takfotslist (inte över gavelfältet)
    if(!y.gavel)
      ritaPoly3D(k,[P(0,hV-0.14),P(L,hV-0.14),P(L,hV),P(0,hV)],VCOL.knut,null);
  }
  // sockel + takfotsskugga
  ritaPoly3D(k,[P(0,0),P(L,0),P(L,0.22),P(0,0.22)],"rgba(60,58,54,.35)",null);
  if(!y.gavel)
    ritaPoly3D(k,[P(0,hV-0.30),P(L,hV-0.30),P(L,hV-0.16),P(0,hV-0.16)],"rgba(20,12,6,.18)",null);
}
function ritaTakDetalj(k,b,y){
  const mitt=tillKam(k,y.mitt[0],y.mitt[1],b.hV);
  if(mitt.d<K3.nara||mitt.d>60) return;
  // falsade skarvar längs fallriktningen + nockplåt
  const [e0,e1,r1,r0]=y.pts;   // takyta: [takfot0, takfot1, nock1, nock0]
  const n=Math.max(3,Math.round(Math.hypot(e1[0]-e0[0],e1[1]-e0[1])/2.2));
  for(let i=1;i<n;i++){
    const t=i/n;
    ritaLinje3D(k,[e0[0]+(e1[0]-e0[0])*t,e0[1]+(e1[1]-e0[1])*t,e0[2]],
      [r0[0]+(r1[0]-r0[0])*t,r0[1]+(r1[1]-r0[1])*t,r0[2]],"rgba(0,0,0,.10)",1);
  }
  ritaLinje3D(k,r0,r1,fargSkala(b.fargT,1.35),2);
  ritaLinje3D(k,e0,e1,"rgba(0,0,0,.30)",1.5);
}
function vaggPunkt(b,sida){ // fasadens p0→p1 (medurs sedd utifrån)
  const {x,y,w,h}=b.rekt;
  if(sida==="S")return[[x,y],[x+w,y]];
  if(sida==="E")return[[x+w,y],[x+w,y+h]];
  if(sida==="N")return[[x+w,y+h],[x,y+h]];
  return[[x,y+h],[x,y]];
}
function ritaOppning(k,b,o){
  const [p0,p1]=vaggPunkt(b,o.sida);
  const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]), ux=(p1[0]-p0[0])/L, uy=(p1[1]-p0[1])/L;
  const P=(u,z)=>[p0[0]+ux*u, p0[1]+uy*u, z];
  const FARG={dorr:VCOL.dorr, dorrgul:VCOL.dorrgul, dorrvit:VCOL.dorrvit,
    dorrgra:VCOL.dorrgra, dorrmork:VCOL.dorrmork, portplat:VCOL.portplat,
    portsilver:VCOL.portsilver, fonster:VCOL.fonster, valv:VCOL.fonster,
    rund:VCOL.fonster};
  const farg=FARG[o.typ]||VCOL.dorr;
  if(o.typ==="valv"){       // välvt spröjsfönster med vit karm
    const båge=(u0,b0,z0,h0)=>{
      const pts=[P(u0,z0),P(u0+b0,z0),P(u0+b0,z0+h0*0.7)];
      for(let i=1;i<5;i++){const t=i/5;
        pts.push(P(u0+b0*(1-t), z0+h0*(0.7+0.3*Math.sin(Math.PI*t))));}
      pts.push(P(u0,z0+h0*0.7));
      return pts;
    };
    ritaPoly3D(k,båge(o.u-0.08,o.b+0.16,o.z0-0.08,o.h+0.16),VCOL.knut,null);
    ritaPoly3D(k,båge(o.u,o.b,o.z0,o.h),farg,null);
    // himmelspegling i glasets övre del + spröjs
    ritaPoly3D(k,båge(o.u+0.06,o.b-0.12,o.z0+o.h*0.42,o.h*0.52),VCOL.fonsterLj,null);
    ritaLinje3D(k,P(o.u+o.b/2,o.z0),P(o.u+o.b/2,o.z0+o.h*0.94),VCOL.knut,1.2);
    ritaLinje3D(k,P(o.u,o.z0+o.h*0.5),P(o.u+o.b,o.z0+o.h*0.5),VCOL.knut,1.2);
  }else if(o.typ==="rund"){ // bullseye-fönster
    const cu=o.u+o.b/2, cz=o.z0+o.h/2, pts=[];
    for(let i=0;i<10;i++){const v=i/10*Math.PI*2;
      pts.push(P(cu+Math.cos(v)*o.b/2, cz+Math.sin(v)*o.h/2));}
    ritaPoly3D(k,pts,farg,VCOL.knut);
  }else if(o.typ==="fonster"){
    // vit karm, glas med himmelspegling, spröjs
    const m=0.07;
    ritaPoly3D(k,[P(o.u-m,o.z0-m),P(o.u+o.b+m,o.z0-m),
      P(o.u+o.b+m,o.z0+o.h+m),P(o.u-m,o.z0+o.h+m)],VCOL.knut,null);
    ritaPoly3D(k,[P(o.u,o.z0),P(o.u+o.b,o.z0),P(o.u+o.b,o.z0+o.h),P(o.u,o.z0+o.h)],farg,null);
    ritaPoly3D(k,[P(o.u,o.z0+o.h*0.45),P(o.u+o.b,o.z0+o.h*0.45),
      P(o.u+o.b,o.z0+o.h),P(o.u,o.z0+o.h)],VCOL.fonsterLj,null);
    ritaLinje3D(k,P(o.u+o.b/2,o.z0),P(o.u+o.b/2,o.z0+o.h),VCOL.knut,1.2);
    ritaLinje3D(k,P(o.u,o.z0+o.h/2),P(o.u+o.b,o.z0+o.h/2),VCOL.knut,1.2);
  }else{
    ritaPoly3D(k,[P(o.u,o.z0),P(o.u+o.b,o.z0),P(o.u+o.b,o.z0+o.h),P(o.u,o.z0+o.h)],
      farg, o.typ==="portplat"?"#5A5C5E":VCOL.knut);
    if(o.typ==="portplat"||o.typ==="portsilver"){ // durkplåtens skarv + trycke
      ritaLinje3D(k,P(o.u+o.b/2,o.z0+0.05),P(o.u+o.b/2,o.z0+o.h-0.05),"#6E7072",1.5);
    }else if(o.typ!=="dorrmork"){ // spegeldörr med handtag
      const m2=0.12;
      ritaPoly3D(k,[P(o.u+m2,o.z0+0.25),P(o.u+o.b-m2,o.z0+0.25),
        P(o.u+o.b-m2,o.z0+o.h-0.2),P(o.u+m2,o.z0+o.h-0.2)],
        fargSkala(farg,0.88),null);
      const hp=tillKam(k,...(()=>{const q=P(o.u+o.b*0.82,o.z0+o.h*0.5);return [q[0],q[1]];})(),o.z0+o.h*0.48);
      if(hp.d>=K3.nara&&hp.d<25){const hs=projK(k,hp);
        cx.fillStyle="#2A2C2E"; cx.beginPath();
        cx.arc(hs[0],hs[1],Math.max(1.2,k.f*0.02/hp.d),0,Math.PI*2); cx.fill();}
    }
  }
}
function ritaHuvar(k,b){ // stallets rad av svarta ventilationshuvar på nocken
  const {x,y,w,h}=b.rekt, mx=x+w/2;
  for(let yy=y+3;yy<y+h-2;yy+=4.6){
    ritaPoly3D(k,[[mx-0.35,yy,b.hN],[mx+0.35,yy,b.hN],
      [mx+0.35,yy,b.hN+0.8],[mx-0.35,yy,b.hN+0.8]],"#1C1E20",null);
    ritaPoly3D(k,[[mx-0.5,yy,b.hN+0.8],[mx+0.5,yy,b.hN+0.8],
      [mx+0.5,yy,b.hN+0.95],[mx-0.5,yy,b.hN+0.95]],"#26282A",null);
  }
}

/* ── Rekvisita i 3D ───────────────────────────────────────────── */
function billboard(k,x,y,storlek){
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return null;
  const s=projK(k,p);
  return {s, sz:clamp(storlek*k.f/p.d,2,CH), d:p.d};
}
function ritaProp3D(k,p){
  const [x,y]=p.pos;
  if(p.norm && (k.x-x)*p.norm[0]+(k.y-y)*p.norm[1] < 0) return; // fasadprop, fel sida
  switch(p.typ){
    case "silo":{ const B=billboard(k,x,y,5.6); if(!B)return;
      const {s,sz}=B, br=sz*0.24;
      cx.fillStyle="#9EA2A6";
      cx.fillRect(s[0]-br/2,s[1]-sz,br,sz*0.62);
      cx.beginPath();cx.moveTo(s[0]-br/2,s[1]-sz*0.38);cx.lineTo(s[0]+br/2,s[1]-sz*0.38);
      cx.lineTo(s[0]+br*0.12,s[1]-sz*0.16);cx.lineTo(s[0]-br*0.12,s[1]-sz*0.16);cx.closePath();cx.fill();
      cx.strokeStyle="#6E7276";cx.lineWidth=Math.max(1,sz*0.014);
      cx.beginPath();cx.moveTo(s[0]-br*0.4,s[1]);cx.lineTo(s[0]-br*0.4,s[1]-sz*0.3);
      cx.moveTo(s[0]+br*0.4,s[1]);cx.lineTo(s[0]+br*0.4,s[1]-sz*0.3);cx.stroke();
      cx.beginPath();cx.moveTo(s[0]-br/2,s[1]-sz,br,sz*0.62);cx.stroke();
      break;}
    case "balar":{ // ensilagebalar i två lager
      for(let i=0;i<5;i++){const B=billboard(k,x+ (i%3)*1.6, y+((i/3)|0)*1.4, 1.3);
        if(!B)continue;const {s,sz}=B;
        cx.fillStyle="#DDDBD4";
        cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.55,sz*0.45,0,0,Math.PI*2);cx.fill();
        cx.strokeStyle="#B9B7B0";cx.lineWidth=1;
        cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.34,sz*0.28,0,0,Math.PI*2);cx.stroke();}
      break;}
    case "torvbalar":{ // vitplastade torvpaket, staplade tre högt
      for(let i=0;i<2;i++)for(let k2=0;k2<3;k2++){
        const B=billboard(k,x+i*1.30,y+0.39,0.62+k2*0.62); if(!B)continue;
        const {s,sz}=B;
        cx.fillStyle="#EDEBE6";
        cx.fillRect(s[0]-sz*0.5,s[1]-sz*0.5,sz*1.0,sz*0.5);
        cx.fillStyle="#B03028";
        cx.fillRect(s[0]-sz*0.5,s[1]-sz*0.34,sz*1.0,sz*0.16);}
      break;}
    case "grushog":{ const B=billboard(k,x,y,1.4); if(!B)return;
      const {s,sz}=B; cx.fillStyle="#7C7870";
      cx.beginPath();cx.moveTo(s[0]-sz*0.8,s[1]);cx.quadraticCurveTo(s[0],s[1]-sz*1.0,s[0]+sz*0.8,s[1]);
      cx.closePath();cx.fill(); break;}
    case "transport":{ const B=billboard(k,x,y,2.4); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="rgba(0,0,0,.25)";
      cx.beginPath();cx.ellipse(s[0],s[1],sz*0.7,sz*0.1,0,0,Math.PI*2);cx.fill();
      cx.fillStyle="#E4E2DC";
      cx.beginPath();cx.moveTo(s[0]-sz*0.65,s[1]);cx.lineTo(s[0]-sz*0.65,s[1]-sz*0.62);
      cx.quadraticCurveTo(s[0],s[1]-sz*0.82,s[0]+sz*0.65,s[1]-sz*0.62);
      cx.lineTo(s[0]+sz*0.65,s[1]);cx.closePath();cx.fill();
      cx.fillStyle="#B9B7B0";cx.fillRect(s[0]-sz*0.65,s[1]-sz*0.14,sz*1.3,sz*0.05);
      cx.fillStyle="#2A2C2E";
      cx.beginPath();cx.arc(s[0]-sz*0.3,s[1],sz*0.09,0,Math.PI*2);
      cx.arc(s[0]+sz*0.3,s[1],sz*0.09,0,Math.PI*2);cx.fill();
      break;}
    case "bord":{ const B=billboard(k,x,y,1.0); if(!B)return;
      const {s,sz}=B; cx.strokeStyle="#5E5648";cx.lineWidth=Math.max(1.5,sz*0.08);
      cx.beginPath();cx.moveTo(s[0]-sz*0.7,s[1]-sz*0.5);cx.lineTo(s[0]+sz*0.7,s[1]-sz*0.5);
      cx.moveTo(s[0]-sz*0.5,s[1]-sz*0.5);cx.lineTo(s[0]-sz*0.8,s[1]);
      cx.moveTo(s[0]+sz*0.5,s[1]-sz*0.5);cx.lineTo(s[0]+sz*0.8,s[1]);
      cx.moveTo(s[0]-sz*0.9,s[1]-sz*0.28);cx.lineTo(s[0]+sz*0.9,s[1]-sz*0.28);
      cx.stroke(); break;}
    case "bank": case "stol":{ const B=billboard(k,x,y,0.9); if(!B)return;
      const {s,sz}=B, br=p.typ==="bank"?0.8:0.3;
      cx.strokeStyle="#8C8474";cx.lineWidth=Math.max(1.5,sz*0.09);
      cx.beginPath();cx.moveTo(s[0]-sz*br,s[1]-sz*0.45);cx.lineTo(s[0]+sz*br,s[1]-sz*0.45);
      cx.moveTo(s[0]-sz*br,s[1]-sz*0.85);cx.lineTo(s[0]-sz*br,s[1]);
      cx.moveTo(s[0]+sz*br,s[1]-sz*0.85);cx.lineTo(s[0]+sz*br,s[1]);cx.stroke();
      break;}
    case "trappa":{ // cafétrappan i galvat stål på södra gaveln
      const steg=7;
      for(let i=0;i<=steg;i++){
        const t=i/steg;
        ritaLinje3D(k,[x-2.6+t*2.6,y,0.1+t*3.6],[x-2.6+t*2.6,y-0.9,0.1+t*3.6],VCOL.galv,2);
      }
      ritaLinje3D(k,[x-2.6,y-0.45,1.1],[x,y-0.45,4.6],VCOL.galv,2.5);
      ritaLinje3D(k,[x,y,3.8],[x+1.4,y,3.8],VCOL.galv,2.5);   // avsatsen
      ritaLinje3D(k,[x,y-0.9,3.8],[x+1.4,y-0.9,3.8],VCOL.galv,1.5);
      ritaLinje3D(k,[x+1.4,y-0.9,3.8],[x+1.4,y-0.9,4.8],VCOL.galv,1.5);
      break;}
    case "skylt":{ // UBRF-skylten: vitt band med text på fasaden
      const b=ANL.byggnader.find(bb=>bb.id==="ridhus");
      ritaPoly3D(k,[[x-0.05,y-5,3.4],[x-0.05,y+5,3.4],[x-0.05,y+5,4.4],[x-0.05,y-5,4.4]],
        "#E8E4DA","#B9B5AB");
      ritaText3D(k,x-0.1,y,3.75,p.text,2.6,"#5A5F66");
      break;}
    case "cafeskylt":
      ritaPoly3D(k,[[x-0.5,y,2.6],[x+0.5,y,2.6],[x+0.5,y,3.0],[x-0.5,y,3.0]],"#E8E4DA","#3A3E44");
      ritaText3D(k,x,y,2.72,"CAFÉ KRUBBAN",1.6,"#2F5C8F");
      break;
    case "flagga":{
      ritaLinje3D(k,[x,y,0],[x,y,7],"#D8D2C6",2.5);
      ritaPoly3D(k,[[x,y,7],[x+1.6,y,6.7],[x,y,6.2]],"#3A6EA5",null);
      break;}
    case "skyltstolpe":{
      ritaLinje3D(k,[x,y,0],[x,y,2.6],"#2A2C2E",3);
      const namn=["Framridning","Ridhus","Information","Stallentré","Toaletter","Utebana"];
      for(let i=0;i<namn.length;i++){
        const z=2.5-i*0.3;
        ritaPoly3D(k,[[x,y,z-0.12],[x+1.3,y,z-0.12],[x+1.3,y,z+0.12],[x,y,z+0.12]],"#22242A",null);
        ritaText3D(k,x+0.65,y,z,namn[i],1.0,"#D8D2C6");
      }
      break;}
    case "stenhast":{ const B=billboard(k,x,y,0.9); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle=["#C9C2B4","#A8A29A","#3A3A3A","#C9C2B4"][(x*7|0)%4];
      cx.beginPath();cx.ellipse(s[0],s[1]-sz*0.45,sz*0.42,sz*0.26,0,0,Math.PI*2);cx.fill();
      cx.beginPath();cx.ellipse(s[0]+sz*0.34,s[1]-sz*0.66,sz*0.13,sz*0.2,0.4,0,Math.PI*2);cx.fill();
      cx.fillRect(s[0]-sz*0.3,s[1]-sz*0.3,sz*0.09,sz*0.3);
      cx.fillRect(s[0]+sz*0.18,s[1]-sz*0.3,sz*0.09,sz*0.3);
      break;}
    case "mast":{
      ritaLinje3D(k,[x,y,0],[x,y,8],"#6E7276",2.5);
      ritaPoly3D(k,[[x-0.5,y,8],[x+0.5,y,8],[x+0.5,y,8.35],[x-0.5,y,8.35]],"#D8D8CC",null);
      break;}
    case "sopstation":{ const B=billboard(k,x,y,1.6); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="#7A7C72";cx.fillRect(s[0]-sz*0.9,s[1]-sz*0.8,sz*1.2,sz*0.8);
      cx.fillStyle="#4E6E4E";cx.fillRect(s[0]+sz*0.35,s[1]-sz*0.65,sz*0.6,sz*0.65);
      break;}
    case "ac":{ const B=billboard(k,x,y,0.8); if(!B)return;
      const {s,sz}=B;
      cx.fillStyle="#DDDBD4";cx.fillRect(s[0]-sz*0.5,s[1]-sz*0.9,sz,sz*0.6);
      cx.strokeStyle="#9A988E";cx.strokeRect(s[0]-sz*0.5,s[1]-sz*0.9,sz,sz*0.6);
      break;}
    case "veranda":{ // vita stolpar, räcke och skärmtak vid stallentrén
      const b=3.4, dj=1.6;
      for(const [px,py] of [[x-b/2,y-dj],[x+b/2,y-dj]]){
        ritaLinje3D(k,[px,py,0],[px,py,2.5],"#E3DDD1",3);
      }
      ritaPoly3D(k,[[x-b/2-0.2,y-dj-0.2,2.5],[x+b/2+0.2,y-dj-0.2,2.5],
        [x+b/2+0.2,y+0.4,2.9],[x-b/2-0.2,y+0.4,2.9]],"#C9C4B8","#9A968C");
      for(const sida of [-1,1]){
        ritaLinje3D(k,[x+sida*b/2,y-dj,1.0],[x+sida*b/2,y,1.0],"#E3DDD1",2);
        for(let i=1;i<4;i++)
          ritaLinje3D(k,[x+sida*b/2,y-dj+i*dj/4,0.15],[x+sida*b/2,y-dj+i*dj/4,1.0],"#E3DDD1",1.2);
      }
      break;}
    case "busskylt":{
      ritaLinje3D(k,[x,y,0],[x,y,2.4],"#6E7276",2);
      ritaPoly3D(k,[[x-0.3,y,2.4],[x+0.3,y,2.4],[x+0.3,y,2.9],[x-0.3,y,2.9]],"#3E6E4E",null);
      break;}
  }
}

/* ── Gården i 3D ──────────────────────────────────────────────── */
function markFarg(typ){
  return typ==="gras"?VCOL.grasLj:typ==="grus"?VCOL.grus:typ==="asfalt"?VCOL.asfalt
    :typ==="aker"?VCOL.aker:typ==="betong"?VCOL.betong:typ==="slant"?VCOL.slant:VCOL.sand;
}
/* Himlen: azimutlåsta moln och kvällssol i sydväst. */
const MOLN=[{az:0.6,h:0.66,s:1.25},{az:1.9,h:0.80,s:0.9},{az:3.1,h:0.58,s:1.5},
            {az:4.3,h:0.74,s:1.0},{az:5.4,h:0.62,s:1.3}];
function azX(az){
  let d=az-VD.rikt;
  while(d>Math.PI)d-=Math.PI*2; while(d<-Math.PI)d+=Math.PI*2;
  return CW/2 - d/K3.fov*CW*0.85;   // moturs vinkel = vänster på skärmen
}
function ritaHimmel(k){
  const vader=G.vader?G.vader.typ:"sol";
  const gr=cx.createLinearGradient(0,0,0,k.hor);
  if(vader==="sol"){
    gr.addColorStop(0,VCOL.himmel0); gr.addColorStop(0.75,"#BFC9BE");
    gr.addColorStop(1,VCOL.himmel1);
  }else if(vader==="mulet"){
    gr.addColorStop(0,"#7C8894"); gr.addColorStop(1,"#C4C8C4");
  }else{
    gr.addColorStop(0,"#5C6670"); gr.addColorStop(1,"#9AA0A2");
  }
  cx.fillStyle=gr; cx.fillRect(0,0,CW,k.hor);
  // solen i sydväst
  const sx=azX(Math.atan2(-1,-1));
  if(vader==="sol"&&sx>-CW*0.3&&sx<CW*1.3){
    const sg=cx.createRadialGradient(sx,k.hor*0.86,0,sx,k.hor*0.86,CH*0.30);
    sg.addColorStop(0,"rgba(255,238,190,.95)"); sg.addColorStop(0.25,"rgba(255,226,160,.45)");
    sg.addColorStop(1,"rgba(255,226,160,0)");
    cx.fillStyle=sg; cx.beginPath(); cx.arc(sx,k.hor*0.86,CH*0.30,0,Math.PI*2); cx.fill();
  }
  for(const m of MOLN){
    const x=azX(m.az); if(x<-CW*0.3||x>CW*1.3)continue;
    const y=k.hor*(1-m.h*0.72), s=CH*0.05*m.s*(vader==="sol"?1:1.6);
    if(vader!=="sol"){ // tunga moln i grått
      cx.fillStyle=vader==="regn"?"#6E767E":"#A6ACB0";
      for(const [ox,oy,r] of [[-1.2,0.1,0.9],[-0.2,-0.35,1.1],[0.7,-0.1,0.95],[1.4,0.2,0.75]]){
        cx.beginPath(); cx.ellipse(x+ox*s,y+oy*s,r*s,r*s*0.7,0,0,Math.PI*2); cx.fill();}
      continue;
    }
    cx.fillStyle=VCOL.molnSkugga;
    cx.beginPath(); cx.ellipse(x,y+s*0.35,s*2.1,s*0.55,0,0,Math.PI*2); cx.fill();
    cx.fillStyle=VCOL.moln;
    for(const [ox,oy,r] of [[-1.2,0.1,0.8],[-0.3,-0.4,1.0],[0.6,-0.15,0.9],[1.3,0.15,0.7]]){
      cx.beginPath(); cx.ellipse(x+ox*s,y+oy*s,r*s,r*s*0.8,0,0,Math.PI*2); cx.fill();}
  }
  // skogsbrynet vid horisonten — höstkulor
  cx.fillStyle=VCOL.skog; cx.fillRect(0,k.hor-CH*0.030,CW,CH*0.030);
  for(let i=0;i<26;i++){
    const x=((i*127)%29)/29*CW*1.1-CW*0.05 + ((VD.rikt*80)%(CW/13));
    const f=TRADFARG[(i*7)%TRADFARG.length][0];
    cx.fillStyle=f;
    cx.beginPath(); cx.ellipse(x,k.hor-CH*0.026,CW*0.026,CH*0.020,0,0,Math.PI*2); cx.fill();
  }
}
function ritaGard3D(){
  const k=kamera();
  ritaHimmel(k);
  cx.fillStyle=VCOL.gras; cx.fillRect(0,k.hor,CW,CH-k.hor);
  for(const m of ANL.mark){ if(m.typ==="gras")continue;
    const r=m.rekt;
    ritaPoly3D(k,[[r.x,r.y,0.01],[r.x+r.w,r.y,0.01],[r.x+r.w,r.y+r.h,0.01],[r.x,r.y+r.h,0.01]],
      fargSkala(markFarg(m.typ),SKUGGA.platt),null);
  }
  for(const c of ANL.cirklar){
    const pts=[];
    for(let i=0;i<14;i++){const v=i/14*Math.PI*2;
      pts.push([c.c[0]+Math.cos(v)*c.r, c.c[1]+Math.sin(v)*c.r, 0.015]);}
    ritaPoly3D(k,pts,fargSkala(markFarg(c.typ),SKUGGA.platt),c.kant?VCOL.sandKant:null);
  }
  // slagskuggor mot nordost
  for(const b of ANL.byggnader){
    const {x,y,w,h}=b.rekt, ox=b.hN*SOLRIKT[0], oy=b.hN*SOLRIKT[1];
    ritaPoly3D(k,[[x,y,0.02],[x+w,y,0.02],[x+w+ox,y+oy,0.02],
      [x+w+ox,y+h+oy,0.02],[x+ox,y+h+oy,0.02],[x,y+h,0.02]],
      "rgba(28,26,14,.26)",null);
  }
  for(const t of ANL.trad){
    ritaPoly3D(k,(()=>{const pts=[];
      for(let i=0;i<8;i++){const v=i/8*Math.PI*2;
        pts.push([t[0]+t[2]*1.6*SOLRIKT[0]*0.9+Math.cos(v)*t[2]*0.9,
                  t[1]+t[2]*1.6*SOLRIKT[1]*0.9+Math.sin(v)*t[2]*0.55,0.02]);}
      return pts;})(),"rgba(28,26,14,.20)",null);
  }
  const items=[];
  for(const b of ANL.byggnader){
    for(const y of byggnadsYtor(b))
      items.push({d:-avst2(y.mitt), rita(){
        ritaPoly3D(k,y.pts,y.farg,fargSkala(y.farg,0.8));
        if(y.tak){ ritaTakDetalj(k,b,y); }
        else{
          ritaFasadDetalj(k,b,y);
          for(const o of (b.oppningar||[])) if(o.sida===y.sida) ritaOppning(k,b,o);
        }
      }});
    if(b.huvar) items.push({d:-avst2([b.rekt.x+b.rekt.w/2,b.rekt.y+b.rekt.h/2])+1,
      rita(){ritaHuvar(k,b);}});
  }
  for(const st of ANL.staket) for(let i=0;i<st.p.length-1;i++){
    const a=st.p[i], c=st.p[i+1];
    items.push({d:-avst2([(a[0]+c[0])/2,(a[1]+c[1])/2]), rita(){ritaStaket3D(k,a,c,st.typ,st.sandkant);}});
  }
  for(const t of ANL.trad) items.push({d:-avst2(t), rita(){ritaTrad3D(k,t);}});
  for(const p of ANL.props) items.push({d:-avst2(p.pos), rita(){ritaProp3D(k,p);}});
  for(const hg of ANL.hagar) for(let i=0;i<hg.hastar.length;i++){
    if(hg.hastar[i]===G.hastId&&!G.hamtad)continue;   // din häst står vid grinden
    const h=HORSES[hg.hastar[i]]; if(!h)continue;
    const hx=hg.rekt.x+hg.rekt.w*(0.25+0.5*((i*0.618)%1));
    const hy=hg.rekt.y+hg.rekt.h*(0.3+0.45*((i*0.377)%1));
    items.push({d:-avst2([hx,hy]), rita(){ritaHage3DHast(k,hx,hy,h,i);}});
  }
  if(G.hastId&&!G.hamtad&&!G.leder){
    const f=ANL.hamtHage.falt, h=HORSES[G.hastId];
    items.push({d:-avst2(f), rita(){
      const p=tillKam(k,f[0],f[1],0); if(p.d<K3.nara)return;
      const s=projK(k,p), sz=clamp(1.6*k.f/p.d,3,140);
      ritaHastSida(cx,s[0],s[1],sz,-1,h.farg,h.man,
        {pose:"beta", tacke:!!(G.vader&&G.vader.tacke)});
    }});
    items.push({d:-avst2(ANL.hamtHage.grind),
      rita(){ritaMarkor3D(k,ANL.hamtHage.grind);}});
  }
  for(const d of ANL.dorrar) items.push({d:-avst2(d.pos), rita(){ritaMarkor3D(k,d.pos);}});
  if(G.leder) items.push({d:-avst2([VD.hastX,VD.hastY]), rita(){ritaLeddHast3D(k);}});
  for(const f of gardsFolk())
    items.push({d:-avst2([f.x,f.y]), rita(){ritaPerson3D(k,f.x,f.y,f);}});
  items.sort((a,b)=>a.d-b.d);
  for(const o of items)o.rita();
  if(G.vader&&G.vader.typ==="regn")ritaRegn();
  ritaSpelare3D();
}
function ritaRegn(){
  cx.strokeStyle="rgba(210,222,232,.30)"; cx.lineWidth=1;
  cx.beginPath();
  for(let i=0;i<70;i++){
    const x=Math.random()*CW, y=Math.random()*CH;
    cx.moveTo(x,y); cx.lineTo(x-CH*0.008,y+CH*0.026);
  }
  cx.stroke();
}
function ritaStaket3D(k,a,c,typ,sandkant){
  const L=Math.hypot(c[0]-a[0],c[1]-a[1]); if(L<0.01)return;
  const n=Math.max(1,Math.round(L/BANOMRADE.staket.stolpDelning));
  const hj=typ==="tra"?BANOMRADE.staket.stolpH:typ==="rail"?0.85:1.0;
  const farg=typ==="tra"?VCOL.staketTra:typ==="rail"?VCOL.staketRail:VCOL.staketEl;
  for(let i=0;i<=n;i++){
    const t=i/n, px=a[0]+(c[0]-a[0])*t, py=a[1]+(c[1]-a[1])*t;
    const p0=tillKam(k,px,py,0), p1=tillKam(k,px,py,hj);
    if(p0.d<K3.nara||p1.d<K3.nara)continue;
    const s0=projK(k,p0), s1=projK(k,p1);
    cx.strokeStyle=farg; cx.lineWidth=Math.max(1,k.f*0.06/p0.d);
    cx.beginPath();cx.moveTo(s0[0],s0[1]);cx.lineTo(s1[0],s1[1]);cx.stroke();
  }
  if(typ==="tra"){
    /* Toppregel, eltråd och (vid sand) syllen — samma sanning som 3D-vyn. */
    const S=BANOMRADE.staket;
    ritaLinje3D(k,[a[0],a[1],S.toppregel.z],[c[0],c[1],S.toppregel.z],farg,2.4);
    for(const y of S.tradar)
      ritaLinje3D(k,[a[0],a[1],y],[c[0],c[1],y],"#3A362E",1);
    if(sandkant)
      ritaLinje3D(k,[a[0],a[1],S.sandsyll.z],[c[0],c[1],S.sandsyll.z],"#9C8A6E",3);
  }else{
    ritaLinje3D(k,[a[0],a[1],hj],[c[0],c[1],hj],farg,typ==="el"?1:2.2);
    if(typ!=="el")ritaLinje3D(k,[a[0],a[1],hj*0.55],[c[0],c[1],hj*0.55],farg,1.6);
  }
}
function ritaTrad3D(k,t){
  const p=tillKam(k,t[0],t[1],0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=t[2]*k.f/p.d;
  const hash=(t[0]*13+t[1]*7)|0;
  const [mork,ljus]=TRADFARG[hash%TRADFARG.length];
  cx.strokeStyle=VCOL.stam; cx.lineWidth=Math.max(1.5,sz*0.10);
  cx.beginPath();cx.moveTo(s[0],s[1]);cx.lineTo(s[0]+sz*0.05,s[1]-sz*1.05);cx.stroke();
  cx.lineWidth=Math.max(1,sz*0.06);
  cx.beginPath();cx.moveTo(s[0]+sz*0.03,s[1]-sz*0.7);cx.lineTo(s[0]+sz*0.35,s[1]-sz*1.2);
  cx.moveTo(s[0]+sz*0.02,s[1]-sz*0.8);cx.lineTo(s[0]-sz*0.3,s[1]-sz*1.25);cx.stroke();
  // lövklungor: mörk bas + två ljusare kullar + solkant
  cx.fillStyle=mork;
  cx.beginPath();cx.ellipse(s[0],s[1]-sz*1.42,sz*0.72,sz*0.62,0,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(s[0]-sz*0.42,s[1]-sz*1.22,sz*0.42,sz*0.38,0,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(s[0]+sz*0.44,s[1]-sz*1.25,sz*0.40,sz*0.36,0,0,Math.PI*2);cx.fill();
  cx.fillStyle=ljus;
  cx.beginPath();cx.ellipse(s[0]-sz*0.22,s[1]-sz*1.58,sz*0.40,sz*0.34,0,0,Math.PI*2);cx.fill();
  cx.beginPath();cx.ellipse(s[0]+sz*0.24,s[1]-sz*1.40,sz*0.32,sz*0.28,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="rgba(255,236,190,.18)";
  cx.beginPath();cx.ellipse(s[0]-sz*0.34,s[1]-sz*1.66,sz*0.26,sz*0.20,0,0,Math.PI*2);cx.fill();
}
function ritaHage3DHast(k,x,y,h,i){
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.6*k.f/p.d,3,110);
  const beta=Math.sin(VD.tid*0.35+i*2.1)>-0.1;   // betar mest, tittar upp ibland
  const dir=(i%2===0)?1:-1;
  ritaHastSida(cx,s[0],s[1],sz,dir,h.farg,h.man,{pose:beta?"beta":"sta"});
}
function ritaMarkor3D(k,pos){
  const p=tillKam(k,pos[0],pos[1],2.6+0.15*Math.sin(VD.tid*3));
  if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(0.4*k.f/p.d,4,18);
  cx.fillStyle="rgba(214,174,60,.85)";
  cx.beginPath();cx.moveTo(s[0],s[1]+sz);cx.lineTo(s[0]-sz*0.6,s[1]-sz*0.4);
  cx.lineTo(s[0]+sz*0.6,s[1]-sz*0.4);cx.closePath();cx.fill();
}
function ritaLeddHast3D(k){
  const h=HORSES[G.hastId]; if(!h)return;
  const p=tillKam(k,VD.hastX,VD.hastY,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.7*k.f/p.d,6,260);
  // profilsida efter hästens kurs relativt kameran
  let rel=VD.hastRikt-VD.rikt;
  while(rel>Math.PI)rel-=Math.PI*2; while(rel<-Math.PI)rel+=Math.PI*2;
  const dir=Math.abs(rel)<Math.PI/2 ? (rel>=0?-1:1) : (rel>=0?1:-1);
  const rorSig=VD.spår.length>1;
  ritaHastSida(cx,s[0],s[1],sz,dir,h.farg,h.man,
    {pose:rorSig?"ga":"sta", fas:VD.fas, grimma:true,
     sadel:!!G.skotselRes, tacke:!!G.tackePa});
  // grimskaftet mot din hand
  const mx=s[0]+dir*sz*0.84, my=s[1]-sz*1.05;
  cx.strokeStyle="#8A6A4C"; cx.lineWidth=Math.max(1.5,sz*0.015);
  cx.beginPath(); cx.moveTo(mx,my);
  cx.quadraticCurveTo((mx+CW/2)/2,Math.max(my,CH*0.82)+sz*0.1, CW/2+CH*0.04,CH*0.90);
  cx.stroke();
}
function ritaSpelare3D(){
  const y0=CH*0.995, x0=CW/2, s=CH*0.30;
  const gung=Math.sin(VD.fas*Math.PI*2)*s*0.03;
  const sväng=Math.sin(VD.fas*Math.PI*2)*s*0.02;
  // jeans
  cx.fillStyle="#46566E";
  cx.beginPath();
  cx.moveTo(x0-s*0.24+sväng,CH+2);
  cx.lineTo(x0-s*0.26,y0-s*0.30+gung); cx.lineTo(x0+s*0.26,y0-s*0.30+gung);
  cx.lineTo(x0+s*0.24-sväng,CH+2); cx.closePath(); cx.fill();
  cx.strokeStyle="rgba(20,24,34,.4)"; cx.lineWidth=Math.max(1,s*0.012);
  cx.beginPath(); cx.moveTo(x0,y0-s*0.28+gung); cx.lineTo(x0,CH); cx.stroke();
  // vit t-shirt med axlar och armar
  cx.fillStyle="#EFEAE0";
  cx.beginPath();
  cx.moveTo(x0-s*0.28,y0-s*0.30+gung);
  cx.quadraticCurveTo(x0-s*0.33,y0-s*0.52+gung,x0-s*0.26,y0-s*0.62+gung);
  cx.quadraticCurveTo(x0,y0-s*0.70+gung,x0+s*0.26,y0-s*0.62+gung);
  cx.quadraticCurveTo(x0+s*0.33,y0-s*0.52+gung,x0+s*0.28,y0-s*0.30+gung);
  cx.closePath(); cx.fill();
  cx.fillStyle="rgba(120,110,95,.25)";
  cx.beginPath(); cx.ellipse(x0,y0-s*0.33+gung,s*0.26,s*0.045,0,0,Math.PI*2); cx.fill();
  // armar
  cx.fillStyle="#E4C9A8";
  cx.beginPath(); cx.ellipse(x0-s*0.30,y0-s*0.44+gung-sväng,s*0.05,s*0.14,0.12,0,Math.PI*2); cx.fill();
  cx.beginPath(); cx.ellipse(x0+s*0.30,y0-s*0.44+gung+sväng,s*0.05,s*0.14,-0.12,0,Math.PI*2); cx.fill();
  // nacke + hår
  cx.fillStyle="#E4C9A8";
  cx.fillRect(x0-s*0.045,y0-s*0.70+gung,s*0.09,s*0.06);
  cx.fillStyle="#8A5A32";
  cx.beginPath(); cx.ellipse(x0,y0-s*0.76+gung,s*0.145,s*0.15,0,0,Math.PI*2); cx.fill();
  cx.beginPath();
  cx.moveTo(x0-s*0.13,y0-s*0.74+gung);
  cx.quadraticCurveTo(x0-s*0.16,y0-s*0.62+gung,x0-s*0.10,y0-s*0.56+gung);
  cx.lineTo(x0-s*0.05,y0-s*0.62+gung); cx.closePath(); cx.fill();
  // grön ridhjälm med ventilation
  cx.fillStyle="#4E7A3C";
  cx.beginPath(); cx.ellipse(x0,y0-s*0.82+gung,s*0.15,s*0.115,0,Math.PI,0); cx.fill();
  cx.fillStyle="#3E6230";
  cx.beginPath(); cx.ellipse(x0,y0-s*0.775+gung,s*0.155,s*0.035,0,0,Math.PI*2); cx.fill();
  cx.strokeStyle="rgba(240,240,225,.5)"; cx.lineWidth=Math.max(1,s*0.012);
  cx.beginPath(); cx.moveTo(x0-s*0.07,y0-s*0.90+gung);
  cx.quadraticCurveTo(x0,y0-s*0.94+gung,x0+s*0.07,y0-s*0.90+gung); cx.stroke();
}

/* ── Gården i 2D (karta) ─────────────────────────────────────── */
const V2G={s:4,ox:0,oy:0};
function g2fit(){
  const m=26;
  V2G.s=Math.min((CW-2*m)/ANL.bredd,(CH-2*m)/ANL.djup);
  V2G.ox=(CW-ANL.bredd*V2G.s)/2; V2G.oy=(CH-ANL.djup*V2G.s)/2;
}
function gs(x,y){return [V2G.ox+x*V2G.s, V2G.oy+(ANL.djup-y)*V2G.s];}
function gsRekt(r){const[a,b]=gs(r.x,r.y+r.h);return[a,b,r.w*V2G.s,r.h*V2G.s];}
function ritaGard2D(){
  g2fit();
  v2tSatt(V2G.ox,V2G.oy,V2G.s,ANL.djup);
  cx.fillStyle=VCOL.gras; cx.fillRect(0,0,CW,CH);
  const s=V2G.s;
  for(const m of ANL.mark){const[a,b,w,h]=gsRekt(m.rekt);
    cx.fillStyle=markFarg(m.typ); cx.fillRect(a,b,w,h);
    if(m.typ==="sand"){cx.strokeStyle=VCOL.sandKant;cx.lineWidth=1.5;cx.strokeRect(a,b,w,h);}}
  for(const c of ANL.cirklar){const[a,b]=gs(c.c[0],c.c[1]);
    cx.fillStyle=markFarg(c.typ);
    cx.beginPath();cx.arc(a,b,c.r*s,0,Math.PI*2);cx.fill();
    if(c.kant){cx.strokeStyle=VCOL.sandKant;cx.lineWidth=1.5;cx.stroke();}}
  for(const st of ANL.staket){
    cx.strokeStyle=st.typ==="tra"?VCOL.staketTra:st.typ==="rail"?VCOL.staketRail:VCOL.staketEl;
    cx.lineWidth=st.typ==="el"?1.2:2;
    cx.beginPath();
    for(let i=0;i<st.p.length;i++){const[a,b]=gs(st.p[i][0],st.p[i][1]);
      i?cx.lineTo(a,b):cx.moveTo(a,b);}
    cx.stroke();}
  for(const t of ANL.trad){const[a,b]=gs(t[0],t[1]);
    const hash=(t[0]*13+t[1]*7)|0, [mork,ljus]=TRADFARG[hash%TRADFARG.length];
    cx.fillStyle="rgba(28,26,14,.25)";
    cx.beginPath();cx.arc(a+t[2]*s*0.5,b+t[2]*s*0.3,t[2]*s*0.75,0,Math.PI*2);cx.fill();
    cx.fillStyle=mork;cx.beginPath();cx.arc(a,b,t[2]*s*0.8,0,Math.PI*2);cx.fill();
    cx.fillStyle=ljus;cx.beginPath();cx.arc(a-t[2]*s*0.25,b-t[2]*s*0.25,t[2]*s*0.45,0,Math.PI*2);cx.fill();}
  for(const p of ANL.props){const[a,b]=gs(p.pos[0],p.pos[1]);
    if(p.typ==="silo"){cx.fillStyle="#9EA2A6";cx.beginPath();cx.arc(a,b,s*1.2,0,Math.PI*2);cx.fill();}
    else if(p.typ==="balar"){cx.fillStyle="#DDDBD4";
      for(let i=0;i<5;i++)cx.fillRect(a+(i%3)*s*1.4,b-((i/3)|0)*s*1.2,s*1.2,s*1.0);}
    else if(p.typ==="transport"){cx.fillStyle="#E4E2DC";
      cx.save();cx.translate(a,b);cx.rotate(-(p.rikt||0));cx.fillRect(-s*1.8,-s*0.9,s*3.6,s*1.8);cx.restore();}
    else if(p.typ==="stenhast"){cx.fillStyle="#A8A29A";cx.beginPath();cx.arc(a,b,s*0.45,0,Math.PI*2);cx.fill();}
    else if(p.typ==="mast"||p.typ==="flagga"){cx.fillStyle="#B9BCBE";cx.beginPath();cx.arc(a,b,s*0.35,0,Math.PI*2);cx.fill();}
  }
  for(const hg of ANL.hagar)for(let i=0;i<hg.hastar.length;i++){
    if(hg.hastar[i]===G.hastId&&!G.hamtad)continue;
    const h=HORSES[hg.hastar[i]];if(!h)continue;
    const hx=hg.rekt.x+hg.rekt.w*(0.25+0.5*((i*0.618)%1));
    const hy=hg.rekt.y+hg.rekt.h*(0.3+0.45*((i*0.377)%1));
    const[a,b]=gs(hx,hy);
    cx.fillStyle=h.farg;cx.beginPath();cx.ellipse(a,b,s*0.9,s*0.5,i,0,Math.PI*2);cx.fill();}
  if(G.hastId&&!G.hamtad&&!G.leder){
    const[a,b]=gs(ANL.hamtHage.falt[0],ANL.hamtHage.falt[1]);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.beginPath();cx.ellipse(a,b,s*1.1,s*0.6,0,0,Math.PI*2);cx.fill();
    const[ga2,gb]=gs(ANL.hamtHage.grind[0],ANL.hamtHage.grind[1]);
    cx.strokeStyle="rgba(214,174,60,.85)";cx.lineWidth=2;
    cx.beginPath();cx.arc(ga2,gb,s*1.4+Math.sin(VD.tid*3)*2,0,Math.PI*2);cx.stroke();
  }
  for(const f of gardsFolk()){const[a,b]=gs(f.x,f.y);
    cx.fillStyle=f.farg;cx.beginPath();cx.arc(a,b,Math.max(2,s*0.4),0,Math.PI*2);cx.fill();}
  for(const b of ANL.byggnader){
    const[a,c,w,h]=gsRekt(b.rekt);
    cx.fillStyle=fargSkala(b.fargT,0.95); cx.fillRect(a,c,w,h);
    cx.strokeStyle=fargSkala(b.fargV,0.7); cx.lineWidth=2; cx.strokeRect(a,c,w,h);
    cx.strokeStyle="rgba(0,0,0,.3)"; cx.lineWidth=1;
    cx.beginPath();
    if(b.nock==="NS"){const mx=a+w/2;cx.moveTo(mx,c);cx.lineTo(mx,c+h);}
    else{const my=c+h/2;cx.moveTo(a,my);cx.lineTo(a+w,my);}
    cx.stroke();
    if(b.label&&s>1.8){cx.fillStyle="#C7C2B6";cx.font=`500 ${Math.max(9,s*2.4)}px "IBM Plex Mono",monospace`;
      cx.textAlign="center";cx.fillText(b.label,a+w/2,c+h/2+3);}
  }
  for(const d of ANL.dorrar){const[a,b]=gs(d.pos[0],d.pos[1]);
    cx.fillStyle="rgba(214,174,60,.9)";cx.beginPath();cx.arc(a,b,3.5,0,Math.PI*2);cx.fill();}
  const[sx,sy]=gs(ANL.skylt.pos[0],ANL.skylt.pos[1]);
  cx.fillStyle="#8E939B";cx.font=`500 ${Math.max(9,s*2.0)}px "IBM Plex Mono",monospace`;
  cx.textAlign="center";cx.fillText(ANL.skylt.text,sx,sy);
  if(G.leder){const[a,b]=gs(VD.hastX,VD.hastY);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.save();cx.translate(a,b);cx.rotate(-VD.hastRikt);
    cx.beginPath();cx.ellipse(0,0,s*1.3,s*0.55,0,0,Math.PI*2);cx.fill();cx.restore();}
  ritaMal2D(gs);
  ritaSpelare2D(gs(VD.px,VD.py),-VD.rikt,Math.max(s,2.2));
}
function ritaSpelare2D(pos,rikt,s){
  const[a,b]=pos;
  cx.save();cx.translate(a,b);cx.rotate(rikt);
  cx.fillStyle="rgba(0,0,0,.3)";
  cx.beginPath();cx.ellipse(1,1,s*0.55,s*0.55,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#D6AE3C";
  cx.beginPath();cx.moveTo(s*0.9,0);cx.lineTo(-s*0.5,-s*0.55);cx.lineTo(-s*0.5,s*0.55);
  cx.closePath();cx.fill();
  cx.restore();
}

/* ── Stallet invändigt: 2D ────────────────────────────────────── */
function ritaStall2D(){
  const S=STALLINNE, m=30;
  /* Avdraget lämnar plats åt HUD-rutorna på en bred skärm. På en telefon
     (CW 390) blev (390−60−340)/15 = −0,67 och hela kartan ritades ut och
     in — spelaren, boxarna och gången hamnade utanför duken. Avdraget
     görs därför bara när det får plats, och skalan har ett golv. */
  const sido=CW>=820?340:0;
  const s=Math.max(Math.min((CW-2*m-sido)/S.bredd,(CH-2*m)/S.langd),0.5);
  const ox=(CW-S.bredd*s)/2, oy=(CH-S.langd*s)/2;
  const ss=(x,y)=>[ox+x*s, oy+(S.langd-y)*s];
  v2tSatt(ox,oy,s,S.langd);
  cx.fillStyle="#14171B";cx.fillRect(0,0,CW,CH);
  const[fa,fb]=ss(0,S.langd);
  cx.fillStyle=S.golv;cx.fillRect(fa,fb,S.bredd*s,S.langd*s);
  /* Gångytorna i ljusare golv: två gångar, tvärkorridoren och hallarna. */
  cx.fillStyle=S.gangGolv;
  for(const g of S.gangytor){
    const[a,b]=ss(g.x,g.y+g.h);
    cx.fillRect(a,b,g.w*s,g.h*s);
  }
  /* Tvärväggarna är solida utom där en gång går igenom. */
  for(const tv of S.tvarvaggar){
    cx.strokeStyle="#4A4438";cx.lineWidth=2;
    let x=0;
    const hal=Object.values(S.gangar).sort((p,q)=>p.x0-q.x0);
    for(const h of hal){
      const[a,b]=ss(x,tv.y), [a2]=ss(h.x0,tv.y);
      cx.beginPath();cx.moveTo(a,b);cx.lineTo(a2,b);cx.stroke();
      x=h.x1;
    }
    const[a,b]=ss(x,tv.y), [a2]=ss(S.bredd,tv.y);
    cx.beginPath();cx.moveTo(a,b);cx.lineTo(a2,b);cx.stroke();
  }
  for(const rad of S.rader){
    const lista=S.boxar[rad.id]||[];
    for(let i=0;i<antalFack(rad.id);i++){
      const yc=boxY(i, rad.id), y0=yc-S.boxB/2;
      if(y0+S.boxB>S.klubbY)break;
      const[a,b]=ss(rad.x0,y0+S.boxB);
      cx.strokeStyle="#4A4438";cx.lineWidth=1.5;
      cx.strokeRect(a,b,rad.djup*s,S.boxB*s);
      const h=boxHast(lista[i]);
      if(h){cx.fillStyle=h.farg;
        cx.beginPath();
        cx.ellipse(a+rad.djup*s/2,b+S.boxB*s/2,s*1.1,s*0.5,
          rad.vetter>0?0.4:-0.4,0,Math.PI*2);cx.fill();
        if(s>6){cx.fillStyle=h.spelbar?"#E6E4DE":"#8E877A";
          cx.font=`500 ${Math.max(8,s*0.6)}px "IBM Plex Mono",monospace`;
          /* Namnet skrivs ut mot gången, alltså åt det håll boxdörren
             öppnar — annars hamnar det inne i grannboxen. */
          cx.textAlign=rad.vetter>0?"left":"right";
          cx.fillText(h.namn,
            rad.vetter>0?a+rad.djup*s+6:a-6, b+S.boxB*s/2+3);}}
    }
  }
  for(const grupp of [S.rum,S.service]) for(const r of grupp){
    const[a,b]=ss(r.rekt.x,r.rekt.y+r.rekt.h);
    cx.strokeStyle="#4A4438";cx.lineWidth=1.5;cx.strokeRect(a,b,r.rekt.w*s,r.rekt.h*s);
    cx.fillStyle="#8E877A";cx.font=`500 ${Math.max(7,s*0.45)}px "IBM Plex Mono",monospace`;cx.textAlign="center";
    cx.fillText(r.label,a+r.rekt.w*s/2,b+r.rekt.h*s/2);}
  /* Klubbdelen: väggarna som linjer med luckor, de slutna rummen fyllda,
     och rumsnamnen på golvet. */
  cx.strokeStyle="#4A4438";cx.lineWidth=2;
  for(const v of S.klubb.vaggar) for(const [a0,a1] of klubbVaggBitar(v)){
    const p=v.typ==="tvar"?ss(a0,v.y):ss(v.x,a0), q=v.typ==="tvar"?ss(a1,v.y):ss(v.x,a1);
    cx.beginPath();cx.moveTo(p[0],p[1]);cx.lineTo(q[0],q[1]);cx.stroke();
  }
  for(const r of S.klubb.rum){
    const[a,b]=ss(r.rekt.x,r.rekt.y+r.rekt.h);
    if(r.stangt){cx.fillStyle="rgba(74,68,56,.35)";cx.fillRect(a,b,r.rekt.w*s,r.rekt.h*s);}
    if(r.label&&s>4){cx.fillStyle="#8E877A";cx.font=`500 ${Math.max(7,s*0.45)}px "IBM Plex Mono",monospace`;
      cx.textAlign="center";cx.fillText(r.label,a+r.rekt.w*s/2,b+r.rekt.h*s/2);}
  }
  const rl=S.ridlarare;
  if(!G.hastId){const[a,b]=ss(rl.pos[0],rl.pos[1]);
    cx.fillStyle="#D6AE3C";cx.beginPath();cx.arc(a,b,s*0.5,0,Math.PI*2);cx.fill();
    cx.fillStyle="#C7C2B6";cx.font=`500 ${Math.max(8,s*0.55)}px "IBM Plex Mono",monospace`;
    cx.textAlign="left";cx.fillText(rl.namn,a+s*0.8,b+3);}
  const mb=G.hastId&&!G.skotselRes&&hittaBox(G.hastId);
  if(mb){const[a,b]=ss(mb.dorr[0],mb.dorr[1]);
    cx.strokeStyle="rgba(214,174,60,.8)";cx.lineWidth=2;
    cx.beginPath();cx.arc(a,b,s*0.9+Math.sin(VD.tid*3)*2,0,Math.PI*2);cx.stroke();}
  for(const d of S.dorrar){const[a,b]=ss(d.pos[0],d.pos[1]);
    cx.fillStyle="rgba(214,174,60,.9)";cx.beginPath();cx.arc(a,b,3,0,Math.PI*2);cx.fill();}
  if(G.leder){const[a,b]=ss(VD.hastX,VD.hastY);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.save();cx.translate(a,b);cx.rotate(-VD.hastRikt);
    cx.beginPath();cx.ellipse(0,0,s*1.1,s*0.5,0,0,Math.PI*2);cx.fill();cx.restore();}
  for(const f of stallFolk()){
    const rad=S.rader.find(r=>r.id===f.rad), fy=boxY(f.ix, f.rad);
    if(!rad||fy>S.klubbY-1)continue;
    const fx2=boxFrontX(rad)+rad.vetter*0.55;
    const[a,b]=ss(fx2,fy);
    cx.fillStyle=f.farg;cx.beginPath();cx.arc(a,b,Math.max(2,s*0.35),0,Math.PI*2);cx.fill();
  }
  ritaMal2D(ss);
  ritaSpelare2D(ss(VD.px,VD.py),-VD.rikt,Math.max(s*0.9,2.2));
}

/* ── Stallet invändigt: 3D ────────────────────────────────────── */
function ritaStall3D(){
  const S=STALLINNE, k=kamera(); k.hor=CH*0.50;
  cx.fillStyle="#211D18";cx.fillRect(0,0,CW,k.hor);
  cx.fillStyle=S.golv;cx.fillRect(0,k.hor,CW,CH-k.hor);
  const vx=S.bredd/2;
  const items=[];
  // gångens marksten
  items.push({d:-1e9, rita(){
    for(const g of S.gangytor){
      ritaPoly3D(k,[[g.x,g.y,0.01],[g.x+g.w,g.y,0.01],
        [g.x+g.w,g.y+g.h,0.01],[g.x,g.y+g.h,0.01]],S.gangGolv,null);
      for(let y=g.y+2;y<g.y+g.h;y+=2)
        ritaLinje3D(k,[g.x,y,0.02],[g.x+g.w,y,0.02],"rgba(0,0,0,.10)",1);
    }
  }});
  // ytterväggar (klubbdelen pärlspont, resten stallvitt)
  const vagg=(p0,p1,farg)=>({d:-avst2([(p0[0]+p1[0])/2,(p0[1]+p1[1])/2]), rita(){
    ritaPoly3D(k,[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],S.tak],[p0[0],p0[1],S.tak]],farg,null);}});
  items.push(vagg([0,0],[0,S.langd],fargSkala(S.vagg,0.84)));
  items.push(vagg([S.bredd,0],[S.bredd,S.langd],fargSkala(S.vagg,0.72)));
  items.push(vagg([0,S.langd],[vx-1.4,S.langd],fargSkala(VCOL.parlspont,0.92)));
  items.push(vagg([vx+1.4,S.langd],[S.bredd,S.langd],fargSkala(VCOL.parlspont,0.92)));
  items.push(vagg([0,0],[vx-1.4,0],fargSkala(S.vagg,0.9)));
  items.push(vagg([vx+1.4,0],[S.bredd,0],fargSkala(S.vagg,0.9)));
  // gaveldörröppningarna: ljus utsikt
  for(const dy of[0,S.langd]) items.push({d:-avst2([vx,dy]), rita(){
    ritaPoly3D(k,[[vx-1.4,dy,0],[vx+1.4,dy,0],[vx+1.4,dy,2.8],[vx-1.4,dy,2.8]],
      "#5A626D",VCOL.knut);}});
  /* Tvärväggar med en dörröppning per gång. Med två gångar blir väggen
     tre stycken i stället för två. */
  const halOrd=Object.values(S.gangar).sort((a,b)=>a.x0-b.x0);
  for(const tv of S.tvarvaggar){
    const bitar=[]; let x=0;
    for(const h of halOrd){ bitar.push([x,h.x0]); x=h.x1; }
    bitar.push([x,S.bredd]);
    for(const [x0,x1] of bitar){
      if(x1-x0<0.05)continue;
      items.push({d:-avst2([(x0+x1)/2,tv.y]), rita(){
        ritaPoly3D(k,[[x0,tv.y,0],[x1,tv.y,0],[x1,tv.y,S.tak],[x0,tv.y,S.tak]],
          fargSkala(tv.brand?VCOL.parlspont:S.vagg,0.88),null);}});
    }
    for(const h of halOrd){
      const hm=(h.x0+h.x1)/2;
      items.push({d:-avst2([hm,tv.y]), rita(){
        // dörrkarm + öppen grå branddörr över öppningen
        ritaPoly3D(k,[[h.x0,tv.y,2.5],[h.x1,tv.y,2.5],
          [h.x1,tv.y,S.tak],[h.x0,tv.y,S.tak]],
          fargSkala(tv.brand?VCOL.parlspont:S.vagg,0.85),null);
        if(tv.brand&&h===halOrd[0])ritaText3D(k,hm,tv.y,2.75,"STALLET",1.4,"#8E877A");
      }});
    }
  }
  /* Klubbdelens väggar ur planen, bit för bit med dörrarna som luckor, och
     de slutna rummen som hela lådor. Rumsnamnen står på den vägg som vetter
     mot rummets mitt. */
  for(const v of S.klubb.vaggar){
    const t=(v.tjock||0.16)/2;
    for(const [a0,a1] of klubbVaggBitar(v)){
      const tvar=v.typ==="tvar";
      const p0=tvar?[a0,v.y]:[v.x,a0], p1=tvar?[a1,v.y]:[v.x,a1];
      items.push({d:-avst2([(p0[0]+p1[0])/2,(p0[1]+p1[1])/2]), rita(){
        ritaPoly3D(k,[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],S.tak],[p0[0],p0[1],S.tak]],
          fargSkala(v.brand?VCOL.parlspont:S.vagg,tvar?0.88:0.95),"#8A8377");
        if(t>0.1) ritaPoly3D(k,[[p0[0]+(tvar?0:2*t),p0[1]+(tvar?2*t:0),0],[p1[0]+(tvar?0:2*t),p1[1]+(tvar?2*t:0),0],
          [p1[0]+(tvar?0:2*t),p1[1]+(tvar?2*t:0),S.tak],[p0[0]+(tvar?0:2*t),p0[1]+(tvar?2*t:0),S.tak]],
          fargSkala(S.vagg,0.9),"#8A8377");
      }});
    }
  }
  for(const r of S.klubb.rum){
    const q=r.rekt, cxm=q.x+q.w/2, cym=q.y+q.h/2;
    if(r.stangt){
      for(const [x0,y0,x1,y1] of [[q.x,q.y,q.x+q.w,q.y],[q.x+q.w,q.y,q.x+q.w,q.y+q.h],
                                   [q.x+q.w,q.y+q.h,q.x,q.y+q.h],[q.x,q.y+q.h,q.x,q.y]])
        items.push({d:-avst2([(x0+x1)/2,(y0+y1)/2]), rita(){
          ritaPoly3D(k,[[x0,y0,0],[x1,y1,0],[x1,y1,S.tak],[x0,y0,S.tak]],fargSkala(S.vagg,0.82),"#8A8377");}});
    }
    if(r.label) items.push({d:-avst2([cxm,cym]), rita(){ritaText3D(k,cxm,cym,2.2,r.label,1.4,"#7C756A");}});
  }
  // boxfronter
  for(const rad2 of S.rader){
    const rad=S.boxar[rad2.id]||[], fx=boxFrontX(rad2), sida=rad2.vetter>0?"W":"E";
    for(let i=0;i<antalFack(rad2.id);i++){
      const my=boxY(i, rad2.id), y0=my-S.boxB/2, y1=my+S.boxB/2;
      if(y1>S.klubbY)break;
      const h=boxHast(rad[i]);
      items.push({d:-avst2([fx,my]), rita(){
        // antracit komposit nedtill, galvad ram
        ritaPoly3D(k,[[fx,y0,0],[fx,y1,0],[fx,y1,1.35],[fx,y0,1.35]],
          fargSkala(VCOL.boxFront,sida==="W"?1:0.85),VCOL.boxRam);
        ritaLinje3D(k,[fx,y0,0],[fx,y0,2.15],VCOL.boxRam,2);
        ritaLinje3D(k,[fx,y1,0],[fx,y1,2.15],VCOL.boxRam,2);
        ritaLinje3D(k,[fx,y0,2.15],[fx,y1,2.15],VCOL.boxRam,2);
        const gN=9;
        for(let g2=1;g2<gN;g2++){
          const gy=y0+(y1-y0)*g2/gN;
          ritaLinje3D(k,[fx,gy,1.35],[fx,gy,2.15],VCOL.galler,1);
        }
        // hästhuvud över boxdörren
        if(h){
          const p=tillKam(k,fx,my,1.75);
          if(p.d>=K3.nara){
            const s=projK(k,p), sz=clamp(0.62*k.f/p.d,4,150);
            const nick=Math.sin(VD.tid*0.9+i*1.7+(sida==="E"?2:0))*sz*0.06;
            ritaHastHuvudFront(cx,s[0],s[1],sz,h.farg,h.man,nick);
          }
        }
        // namnskylt
        const np=tillKam(k,fx,my,2.4);
        if(np.d>=K3.nara&&np.d<15&&Math.abs(np.s)<np.d*1.2){
          const s=projK(k,np), b=clamp(2.6*k.f/np.d,26,150), hh=b*0.24;
          cx.fillStyle=VCOL.skylt;cx.fillRect(s[0]-b/2,s[1]-hh/2,b,hh);
          cx.strokeStyle="#3A3E44";cx.strokeRect(s[0]-b/2,s[1]-hh/2,b,hh);
          cx.fillStyle=h?"#E6E4DE":"#5A5F66";
          cx.font=`600 ${hh*0.55}px "IBM Plex Mono",monospace`;cx.textAlign="center";
          cx.fillText(h?h.namn.toUpperCase():"—",s[0],s[1]+hh*0.2);
        }
        // hästens finaste rosett hänger på boxdörren
        if(typeof hastRosett==="function"){
          const ro=hastRosett(rad[i]);
          if(ro){
            const rp=tillKam(k,fx,my+1.15,2.05);
            if(rp.d>=K3.nara&&rp.d<12){
              const sp=projK(k,rp), r=clamp(0.30*k.f/rp.d,3,26);
              cx.fillStyle=ro.farg;
              cx.fillRect(sp[0]-r*0.5,sp[1]+r*0.6,r*0.36,r*1.15);
              cx.fillStyle=ro.farg2||ro.farg;
              cx.fillRect(sp[0]+r*0.14,sp[1]+r*0.6,r*0.36,r*1.15);
              cx.fillStyle=ro.farg;cx.beginPath();cx.arc(sp[0],sp[1],r,0,Math.PI*2);cx.fill();
              if(ro.farg2){cx.fillStyle=ro.farg2;cx.beginPath();cx.arc(sp[0],sp[1],r*0.55,0,Math.PI*2);cx.fill();}
              cx.strokeStyle="rgba(0,0,0,.4)";cx.lineWidth=1;
              cx.beginPath();cx.arc(sp[0],sp[1],r,0,Math.PI*2);cx.stroke();
            }
          }
        }
      }});
    }
  }
  // rummen (klubbdel + service) — väggar mot gången med etiketter
  for(const grupp of [S.rum,S.service]) for(const r of grupp){
    const rekt=r.rekt;
    const gx=rekt.x<vx?rekt.x+rekt.w:rekt.x;   // väggen som vetter mot gången
    items.push({d:-avst2([gx,rekt.y+rekt.h/2]), rita(){
      ritaPoly3D(k,[[gx,rekt.y,0],[gx,rekt.y+rekt.h,0],
        [gx,rekt.y+rekt.h,S.tak],[gx,rekt.y,S.tak]],
        fargSkala(rekt.y>40?VCOL.parlspont:S.vagg,rekt.x<vx?0.95:0.8),"#8A8377");
      ritaText3D(k,gx,rekt.y+rekt.h/2,2.2,r.label,1.6,"#7C756A");
    }});
  }
  // limträbalkar + taklanterniner
  for(let y=4;y<S.langd;y+=4){
    items.push({d:-avst2([vx,y])-1e6, rita(){
      ritaPoly3D(k,[[0.2,y-0.15,S.tak],[S.bredd-0.2,y-0.15,S.tak],
        [S.bredd-0.2,y+0.15,S.tak],[0.2,y+0.15,S.tak]],"#8A6B4A",null);}});
  }
  items.push({d:-1e8, rita(){ // lanterninerna: ljusband längs nocken
    ritaPoly3D(k,[[vx-0.5,2,S.tak+0.01],[vx+0.5,2,S.tak+0.01],
      [vx+0.5,S.langd-2,S.tak+0.01],[vx-0.5,S.langd-2,S.tak+0.01]],"#707B86",null);}});
  // props: storsäck, brandsläckare, hjärtstartare
  items.push({d:-avst2([vx-1.9,22]), rita(){
    const B=billboard(k,vx-1.9,22,1.1); if(!B)return;
    const {s,sz}=B;
    cx.fillStyle="#E4E2DC";
    cx.beginPath();cx.moveTo(s[0]-sz*0.5,s[1]);cx.lineTo(s[0]-sz*0.42,s[1]-sz*0.9);
    cx.lineTo(s[0]+sz*0.42,s[1]-sz*0.9);cx.lineTo(s[0]+sz*0.5,s[1]);cx.closePath();cx.fill();}});
  items.push({d:-avst2([vx+1.9,30]), rita(){
    const B=billboard(k,vx+1.9,30,0.9); if(!B)return;
    const {s,sz}=B;
    cx.fillStyle="#C0392B";cx.fillRect(s[0]-sz*0.09,s[1]-sz*0.6,sz*0.18,sz*0.5);}});
  // ridläraren
  if(!G.hastId){
    const rl=S.ridlarare;
    items.push({d:-avst2(rl.pos), rita(){ritaPerson3D(k,rl.pos[0],rl.pos[1]);}});
  }
  // elever som sköter sina hästar i gången
  for(const f of stallFolk()){
    const rad=S.rader.find(r=>r.id===f.rad), fy=boxY(f.ix, f.rad);
    if(!rad||fy>S.klubbY-1)continue;
    const fx2=boxFrontX(rad)+rad.vetter*0.55;
    items.push({d:-avst2([fx2,fy]), rita(){ritaPerson3D(k,fx2,fy,{farg:f.farg,fasel:f.ix,rorlig:true});}});
  }
  if(G.leder) items.push({d:-avst2([VD.hastX,VD.hastY]), rita(){ritaLeddHast3D(k);}});
  const mb=G.hastId&&!G.skotselRes&&hittaBox(G.hastId);
  if(mb) items.push({d:-avst2(mb.dorr), rita(){ritaMarkor3D(k,mb.dorr);}});
  for(const d of S.dorrar) items.push({d:-avst2(d.pos), rita(){ritaMarkor3D(k,d.pos);}});
  items.sort((a,b)=>a.d-b.d);
  for(const o of items)o.rita();
  ritaSpelare3D();
}
function ritaPerson3D(k,x,y,opts){
  const o=opts||{};
  const p=tillKam(k,x,y,0); if(p.d<K3.nara)return;
  const s=projK(k,p), sz=clamp(1.72*k.f/p.d,6,220);
  const sv=Math.sin(VD.tid*1.5+(o.fasel||0))*sz*(o.rorlig?0.03:0.012);
  cx.fillStyle="rgba(0,0,0,.25)";
  cx.beginPath();cx.ellipse(s[0],s[1],sz*0.2,sz*0.06,0,0,Math.PI*2);cx.fill();
  cx.fillStyle=o.farg||"#2E4638";
  cx.beginPath();cx.moveTo(s[0]-sz*0.16,s[1]);cx.lineTo(s[0]-sz*0.14+sv,s[1]-sz*0.62);
  cx.quadraticCurveTo(s[0]+sv,s[1]-sz*0.70,s[0]+sz*0.14+sv,s[1]-sz*0.62);
  cx.lineTo(s[0]+sz*0.16,s[1]);cx.closePath();cx.fill();
  cx.fillStyle="#C9A882";
  cx.beginPath();cx.ellipse(s[0]+sv,s[1]-sz*0.80,sz*0.11,sz*0.13,0,0,Math.PI*2);cx.fill();
  cx.fillStyle="#3A3128";
  cx.beginPath();cx.ellipse(s[0]+sv,s[1]-sz*0.88,sz*0.12,sz*0.07,0,0,Math.PI,true);cx.fill();
}
/* Livet på anläggningen: elever som sköter sina hästar i stallgången
   och folk på gården — en på väg längs grusvägen, andra vid borden
   och lekhagen. Deterministiskt ur dagens frö. */
function stallFolk(){
  const s=((G.seed||1)*29+7)>>>0;
  const farger=["#5C4A6E","#7A3E36","#3E5C74","#6B5E3C"];
  /* Eleverna står i den gång spelets hästar bor i, alltså gång A. */
  return [{rad:"W",  ix:(s%7)+1,     farg:farger[s%4]},
          {rad:"MA", ix:((s>>3)%6)+2, farg:farger[(s+1)%4]}];
}
function gardsFolk(){
  const t=VD.tid*0.55, span=42;
  const tri=Math.abs((t%(span*2))-span);
  return [
    {x:115.5, y:52+tri, farg:"#3E5C74", rorlig:true},   // på väg längs grusvägen
    {x:150.5, y:60.8, farg:"#7A3E36"},                  // vid picknickborden
    {x:101.5, y:127.2, farg:"#5C4A6E"},                 // förälder vid lekhagen
  ];
}

/* ── Ridhuset invändigt: 2D ───────────────────────────────────── */
function ritaRidhus2D(){
  const R=RIDHUSINNE, ba=R.bana, m=30;
  const sido=CW>=820?320:0;                    // se ritaStall2D
  const s=Math.max(Math.min((CW-2*m-sido)/R.bredd,(CH-2*m)/R.langd),0.5);
  const ox=(CW-R.bredd*s)/2, oy=(CH-R.langd*s)/2;
  const ss=(x,y)=>[ox+x*s, oy+(R.langd-y)*s];
  v2tSatt(ox,oy,s,R.langd);
  cx.fillStyle="#14171B";cx.fillRect(0,0,CW,CH);
  const[fa,fb]=ss(0,R.langd);
  cx.fillStyle=R.gangFarg;cx.fillRect(fa,fb,R.bredd*s,R.langd*s);
  const[bx,by]=ss(ba.x,ba.y+ba.h);
  cx.fillStyle=R.sandFarg;cx.fillRect(bx,by,ba.w*s,ba.h*s);
  cx.strokeStyle=R.vagg;cx.lineWidth=Math.max(2.5,s*0.5);
  cx.strokeRect(bx,by,ba.w*s,ba.h*s);
  // spelets sargport (SPELABSTRAKTION, inte fidelity) i norra sargen
  const sp=SPELABSTRAKTIONER.ridhus.sargport;
  const[pa]=ss(sp.x0,0),[pb]=ss(sp.x1,0),[,py]=ss(0,ba.y+ba.h);
  cx.strokeStyle=R.sandFarg;cx.lineWidth=Math.max(3,s*0.6);
  cx.beginPath();cx.moveTo(pa,py);cx.lineTo(pb,py);cx.stroke();
  // läktaren, på den sida `sidor` pekar ut, däckets djup bred
  cx.fillStyle="#7A6248";
  for(const sek of laktarSektioner(R.laktare)){
    const[sa,sb]=ss(R.laktare.x0,sek.y1);
    cx.fillRect(sa,sb,R.laktare.dackDjup*s,(sek.y1-sek.y0)*s);
  }
  const[la,lb]=ss(R.laktare.x0,R.laktare.y1);
  if(s>4){cx.save();cx.translate(la+R.laktare.dackDjup*s/2,lb+(R.laktare.y1-R.laktare.y0)*s/2);
    cx.rotate(-Math.PI/2);cx.fillStyle="#2A241C";
    cx.font=`500 ${Math.max(9,s*1.6)}px "IBM Plex Mono",monospace`;cx.textAlign="center";
    cx.fillText("LÄKTAREN",0,3);cx.restore();}
  // C-blocket vid norra änden, och caféet ovanpå entrédelen
  {const K=R.kortanda; if(K){const[ka,kb]=ss(K.x0,K.y1);
    cx.fillStyle="#8A6F50";cx.fillRect(ka,kb,(K.x1-K.x0)*s,(K.y1-K.y0)*s);
    if(s>4){cx.fillStyle="#2A241C";cx.font=`500 ${Math.max(8,s*1.2)}px "IBM Plex Mono",monospace`;
      cx.textAlign="center";cx.fillText("C-BLOCKET · CAFÉ OVANPÅ",ka+(K.x1-K.x0)*s/2,kb+(K.y1-K.y0)*s/2+3);}}}
  const[ca,cb]=ss(0,R.langd);
  cx.fillStyle="rgba(233,229,220,.20)";cx.fillRect(ca,cb,R.bredd*s,R.cafe.djup*s);
  // entrédelens väggar ur planen, med luckorna, och de slutna rummen
  if(R.entrehall){
    cx.strokeStyle="#4A4438";cx.lineWidth=2;
    for(const v of R.entrehall.vaggar) for(const [a0,a1] of klubbVaggBitar(v)){
      const p=v.typ==="tvar"?ss(a0,v.y):ss(v.x,a0), q=v.typ==="tvar"?ss(a1,v.y):ss(v.x,a1);
      cx.beginPath();cx.moveTo(p[0],p[1]);cx.lineTo(q[0],q[1]);cx.stroke();
    }
    for(const rm of R.entrehall.rum){
      const[a,b]=ss(rm.rekt.x,rm.rekt.y+rm.rekt.h);
      if(rm.stangt){cx.fillStyle="rgba(74,68,56,.35)";cx.fillRect(a,b,rm.rekt.w*s,rm.rekt.h*s);}
      if(rm.label&&s>4){cx.fillStyle="#8E877A";cx.font=`500 ${Math.max(7,s*0.45)}px "IBM Plex Mono",monospace`;
        cx.textAlign="center";cx.fillText(rm.label,a+rm.rekt.w*s/2,b+rm.rekt.h*s/2);}
    }
  }
  // speglar och skyltar på panelens långsida
  {const px=(R.spegelSida==="E")?R.bredd-0.9:0.4;
   for(const sp of R.speglar){const[a,b]=ss(px,sp.y+sp.b/2);
     cx.fillStyle="#93A9BC";cx.fillRect(a,b,s*0.5,sp.b*s);}
   for(const sk of R.skyltar){const[a,b]=ss(px,sk.y+sk.b/2);
     cx.fillStyle=sk.bg;cx.fillRect(a,b,s*0.4,sk.b*s);}}
  // bokstäverna ur DRESSYRBOKSTAVER via bokstavLage — A i söder, C i norr
  cx.fillStyle="#C9BFA6";cx.font=`600 ${Math.max(9,s*1.3)}px Petrona,serif`;cx.textAlign="center";
  for(const B of DRESSYRBOKSTAVER){
    const L=bokstavLage(R,B);
    const[a,c]=ss(L.x+(L.sida==="W"?-1:L.sida==="E"?1:0), L.y+(L.sida==="S"?-1.4:L.sida==="N"?1.4:0));
    cx.fillText(B.b,a,c+4);}
  for(const d of R.dorrar){const[a,b]=ss(d.pos[0],d.pos[1]);
    cx.fillStyle="rgba(214,174,60,.9)";cx.beginPath();cx.arc(a,b,3.5,0,Math.PI*2);cx.fill();}
  for(const i of R.info){const[a,b]=ss(i.pos[0],i.pos[1]);
    cx.fillStyle="rgba(214,174,60,.5)";cx.beginPath();cx.arc(a,b,2.5,0,Math.PI*2);cx.fill();}
  if(G.leder){const[a,b]=ss(VD.hastX,VD.hastY);
    cx.fillStyle=HORSES[G.hastId].farg;
    cx.save();cx.translate(a,b);cx.rotate(-VD.hastRikt);
    cx.beginPath();cx.ellipse(0,0,s*1.1,s*0.5,0,0,Math.PI*2);cx.fill();cx.restore();}
  ritaMal2D(ss);
  ritaSpelare2D(ss(VD.px,VD.py),-VD.rikt,Math.max(s*0.9,2.2));
}

/* ── Ridhuset invändigt: 3D ───────────────────────────────────── */
function ritaRidhus3D(){
  const R=RIDHUSINNE, ba=R.bana, k=kamera(); k.hor=CH*0.50;
  cx.fillStyle="#DDD9D0";cx.fillRect(0,0,CW,k.hor);           // vitt innertak
  cx.fillStyle=R.gangFarg;cx.fillRect(0,k.hor,CW,CH-k.hor);
  const items=[];
  // fibersanden
  items.push({d:-1e9, rita(){
    ritaPoly3D(k,[[ba.x,ba.y,0.01],[ba.x+ba.w,ba.y,0.01],
      [ba.x+ba.w,ba.y+ba.h,0.01],[ba.x,ba.y+ba.h,0.01]],R.sandFarg,null);
    for(let y=ba.y+5;y<ba.y+ba.h;y+=5)
      ritaLinje3D(k,[ba.x,y,0.02],[ba.x+ba.w,y,0.02],"rgba(0,0,0,.06)",1);
  }});
  // sargen: vit mur med svart sockel, port vid A
  const sarg=(x0,y0,x1,y1)=>{
    items.push({d:-avst2([(x0+x1)/2,(y0+y1)/2]), rita(){
      ritaPoly3D(k,[[x0,y0,0],[x1,y1,0],[x1,y1,R.sargH],[x0,y0,R.sargH]],R.vagg,"#C4BFB4");
      ritaPoly3D(k,[[x0,y0,0],[x1,y1,0],[x1,y1,0.25],[x0,y0,0.25]],R.sockel,null);
      ritaLinje3D(k,[x0,y0,R.sargH],[x1,y1,R.sargH],"#FFFFFF",1.5);
    }});
  };
  {const sp=SPELABSTRAKTIONER.ridhus.sargport;   // gapet är spelabstraktion, inte fidelity
   sarg(ba.x,ba.y+ba.h, sp.x0,ba.y+ba.h);
   sarg(sp.x1,ba.y+ba.h, ba.x+ba.w,ba.y+ba.h);}
  sarg(ba.x,ba.y, ba.x+ba.w,ba.y);
  sarg(ba.x,ba.y, ba.x,ba.y+ba.h);
  /* Östra långsidan delad av grinden mot hästgången. */
  {const gr=R.sargGrind;
   if(gr){ sarg(ba.x+ba.w,ba.y, ba.x+ba.w,gr.y0);
           sarg(ba.x+ba.w,gr.y1, ba.x+ba.w,ba.y+ba.h); }
   else sarg(ba.x+ba.w,ba.y, ba.x+ba.w,ba.y+ba.h);}
  // ytterväggar: vit panel med lodräta läkt
  const yttervagg=(p0,p1,ljus)=>{
    items.push({d:-avst2([(p0[0]+p1[0])/2,(p0[1]+p1[1])/2])-2e6, rita(){
      ritaPoly3D(k,[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],R.tak],[p0[0],p0[1],R.tak]],
        fargSkala(R.vagg,ljus),null);
      const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]);
      for(let t=1.2;t<L;t+=1.2)
        ritaLinje3D(k,[p0[0]+(p1[0]-p0[0])*t/L,p0[1]+(p1[1]-p0[1])*t/L,0.2],
          [p0[0]+(p1[0]-p0[0])*t/L,p0[1]+(p1[1]-p0[1])*t/L,R.tak-0.3],"rgba(60,55,45,.10)",1);
    }});
  };
  yttervagg([0,0],[0,R.langd],0.88);
  yttervagg([R.bredd,0],[R.bredd,R.langd],0.80);
  yttervagg([0,R.langd],[R.bredd,R.langd],0.92);
  yttervagg([0,0],[R.bredd,0],0.92);
  // sponsorväggen på panelens långsida: brun panel med vita lister, skyltar, speglar, fönsterband
  {const pE=(R.spegelSida==="E"), px=pE?R.bredd-0.05:0.05, pin=pE?-1:1;
  items.push({d:-avst2([px,VD.py])-1e6, rita(){
    ritaPoly3D(k,[[px,4,1.35],[px,R.langd-2,1.35],[px,R.langd-2,3.7],[px,4,3.7]],
      fargSkala(R.panel,0.9),null);
    for(const z of [1.9,2.5,3.1])
      ritaLinje3D(k,[px+pin*0.01,4,z],[px+pin*0.01,R.langd-2,z],R.panelList,1.5);
    // högt fönsterband som släpper in kvällsljus
    ritaPoly3D(k,[[px,4,4.6],[px,R.langd-2,4.6],[px,R.langd-2,5.4],[px,4,5.4]],
      "#E8D9AE",null);
    for(const sk of R.skyltar){
      const x=px+pin*0.05;
      ritaPoly3D(k,[[x,sk.y,2.0],[x,sk.y+sk.b,2.0],[x,sk.y+sk.b,3.0],[x,sk.y,3.0]],
        sk.bg,"#8A857A");
      ritaText3D(k,x+pin*0.02,sk.y+sk.b/2,2.55,sk.text,1.7,sk.fg);
    }
    for(const sp of R.speglar){
      const x=px+pin*0.05;
      ritaPoly3D(k,[[x,sp.y-0.15,1.5],[x,sp.y+sp.b+0.15,1.5],
        [x,sp.y+sp.b+0.15,3.35],[x,sp.y-0.15,3.35]],"#5A4634",null);
      ritaPoly3D(k,[[x+pin*0.02,sp.y,1.6],[x+pin*0.02,sp.y+sp.b,1.6],
        [x+pin*0.02,sp.y+sp.b,3.25],[x+pin*0.02,sp.y,3.25]],"#9FB3C4",null);
    }
  }});}
  // läktaren: plant däck med solid front mot banan, på den sida `sidor` pekar ut
  {const lk=R.laktare, lE=(R.sidor&&R.sidor.laktare==="E");
   const fx=lE?lk.x0:lk.x0+lk.dackDjup;        // fronten står mot banan
   const bx=lE?lk.x0+lk.dackDjup:lk.x0;        // bakkanten mot väggen
   for(const sek of laktarSektioner(lk)){
     const y0=sek.y0, y1=sek.y1;
     items.push({d:-avst2([fx,VD.py])-5e5, rita(){
       ritaPoly3D(k,[[fx,y0,0],[fx,y1,0],[fx,y1,lk.frontTopp],[fx,y0,lk.frontTopp]],
         fargSkala("#5A4634",0.9),null);                       // fronten
       ritaPoly3D(k,[[fx,y0,lk.dackZ],[fx,y1,lk.dackZ],[bx,y1,lk.dackZ],[bx,y0,lk.dackZ]],
         "#9A7C58",null);                                       // däcket
     }});
   }}
  // domarbåset — trälåda med öppen front mot banan
  {const db=R.domarbas, dE=(R.sidor&&R.sidor.laktare==="E"), fs=dE?-1:1;
  items.push({d:-avst2([db.x,db.y]), rita(){
    const b2=db.b/2, fxx=db.x+fs*b2;
    ritaPoly3D(k,[[fxx,db.y-b2,0.3],[fxx,db.y+b2,0.3],
      [fxx,db.y+b2,0.3+db.h],[fxx,db.y-b2,0.3+db.h]],"#7A5C3E","#4A3826");
    ritaPoly3D(k,[[db.x-b2,db.y-b2,0.3],[db.x+b2,db.y-b2,0.3],
      [db.x+b2,db.y-b2,0.3+db.h],[db.x-b2,db.y-b2,0.3+db.h]],fargSkala("#7A5C3E",0.85),null);
    ritaPoly3D(k,[[fxx,db.y-b2,1.1],[fxx,db.y+b2,1.1],
      [fxx,db.y+b2,1.9],[fxx,db.y-b2,1.9]],"#3A4A5C",null); // rutan
    ritaText3D(k,fxx+fs*0.05,db.y,2.5,"DOMARE",1.4,"#5C554A");
  }});}
  // entré- och caféöverbyggnaden i norr: golvplatta, fönsterband mot banan, trappan
  items.push({d:-avst2([R.bredd/2,R.langd])-1.5e6, rita(){
    const dj=R.langd-R.cafe.djup;   // väggen mot banan
    ritaPoly3D(k,[[0,dj,R.cafe.z0],[R.bredd,dj,R.cafe.z0],
      [R.bredd,dj,R.cafe.z1],[0,dj,R.cafe.z1]],fargSkala(R.vagg,0.95),"#B9B4A9");
    // fönsterband in mot caféet
    ritaPoly3D(k,[[1.5,dj+0.02,R.cafe.z0+0.5],[R.bredd-4,dj+0.02,R.cafe.z0+0.5],
      [R.bredd-4,dj+0.02,R.cafe.z1-0.6],[1.5,dj+0.02,R.cafe.z1-0.6]],"#3A4A5C",null);
    for(let x=3.5;x<R.bredd-4;x+=2)
      ritaLinje3D(k,[x,dj+0.03,R.cafe.z0+0.5],[x,dj+0.03,R.cafe.z1-0.6],"#8A6F50",1.5);
    // undersidan över lobbyn
    ritaPoly3D(k,[[0,dj,R.cafe.z0],[R.bredd,dj,R.cafe.z0],
      [R.bredd,R.langd,R.cafe.z0],[0,R.langd,R.cafe.z0]],"#C9C4B8",null);
    ritaText3D(k,R.bredd/2-2,dj+0.05,R.cafe.z1-0.25,"CAFÉ KRUBBAN",1.8,"#5C554A");
  }});
  // C-blocket vid norra änden: bänkblocket som en låda med steg antydda,
  // sett från banan. Trapporna upp till caféet går härifrån.
  {const K=R.kortanda; if(K){
    const H=(K.sockelH||0)+K.steg*K.stegH, front=K.vand==="S"?K.y0:K.y1;
    items.push({d:-avst2([(K.x0+K.x1)/2,front]), rita(){
      ritaPoly3D(k,[[K.x0,front,0],[K.x1,front,0],[K.x1,front,H],[K.x0,front,H]],"#86715B","#6F5C49");
      for(let i=1;i<K.steg;i++){const z=(K.sockelH||0)+K.stegH*i, d=K.vand==="S"?K.stegD*i:-K.stegD*i;
        ritaLinje3D(k,[K.x0,front+d,z],[K.x1,front+d,z],"#6F5C49",1);}
      ritaText3D(k,(K.x0+K.x1)/2,front+(K.vand==="S"?0.3:-0.3),H+0.6,"C-BLOCKET · CAFÉ KRUBBAN OVANPÅ",1.5,"#5C554A");
    }});
  }}
  // entrédelens väggar ur planen, bit för bit med luckorna, och de slutna rummen
  if(R.entrehall){
    for(const v of R.entrehall.vaggar){
      const t=(v.tjock||0.16)/2;
      for(const [a0,a1] of klubbVaggBitar(v)){
        const tvar=v.typ==="tvar";
        const p0=tvar?[a0,v.y]:[v.x,a0], p1=tvar?[a1,v.y]:[v.x,a1];
        items.push({d:-avst2([(p0[0]+p1[0])/2,(p0[1]+p1[1])/2]), rita(){
          ritaPoly3D(k,[[p0[0],p0[1],0],[p1[0],p1[1],0],[p1[0],p1[1],R.cafe.z0],[p0[0],p0[1],R.cafe.z0]],
            fargSkala(R.vagg,tvar?0.88:0.95),"#B9B4A9");
        }});
      }
    }
    for(const rm of R.entrehall.rum){
      const q=rm.rekt, cxm=q.x+q.w/2, cym=q.y+q.h/2;
      if(rm.stangt){
        for(const [x0,y0,x1,y1] of [[q.x,q.y,q.x+q.w,q.y],[q.x+q.w,q.y,q.x+q.w,q.y+q.h],
                                     [q.x+q.w,q.y+q.h,q.x,q.y+q.h],[q.x,q.y+q.h,q.x,q.y]])
          items.push({d:-avst2([(x0+x1)/2,(y0+y1)/2]), rita(){
            ritaPoly3D(k,[[x0,y0,0],[x1,y1,0],[x1,y1,R.cafe.z0],[x0,y0,R.cafe.z0]],fargSkala(R.vagg,0.82),"#B9B4A9");}});
      }
      if(rm.label) items.push({d:-avst2([cxm,cym]), rita(){ritaText3D(k,cxm,cym,2.1,rm.label,1.3,"#7C756A");}});
    }
  }
  // hinderförrådet i söder: färgade bommar och koner
  items.push({d:-avst2([R.bredd/2,0])-1e5, rita(){
    const fargor=["#3A6EA5","#C0392B","#E8E4DA","#C9A23C"];
    for(let i2=0;i2<7;i2++){
      ritaLinje3D(k,[4+i2*2.4,0.3,0.15],[6+i2*2.4,0.4,1.7],
        fargor[i2%fargor.length],3);}
    for(let i2=0;i2<4;i2++){
      const K2=billboard(k,7+i2*3,1.2,0.45); if(!K2)continue;
      cx.fillStyle="#E8E4DA";
      cx.beginPath();cx.moveTo(K2.s[0]-K2.sz*0.4,K2.s[1]);
      cx.lineTo(K2.s[0],K2.s[1]-K2.sz);cx.lineTo(K2.s[0]+K2.sz*0.4,K2.s[1]);
      cx.closePath();cx.fill();}
  }});
  // limträbalkar, lysrörsrader och ventilationstrumman
  for(let y=6;y<R.langd-2;y+=6){
    items.push({d:-avst2([R.bredd/2,y])-3e6, rita(){
      ritaPoly3D(k,[[0.5,y-0.2,R.tak],[R.bredd-0.5,y-0.2,R.tak],
        [R.bredd-0.5,y+0.2,R.tak],[0.5,y+0.2,R.tak]],"#8A6B4A",null);
      for(let x=4;x<R.bredd-2;x+=4.5)
        ritaPoly3D(k,[[x,y-1.6,R.tak-0.05],[x+1.6,y-1.6,R.tak-0.05],
          [x+1.6,y-1.3,R.tak-0.05],[x,y-1.3,R.tak-0.05]],"#F5F2E6",null);
    }});
  }
  items.push({d:-2.9e6, rita(){ // silverisolerade trumman längs nocken
    ritaPoly3D(k,[[R.bredd/2-0.5,3,R.tak-0.4],[R.bredd/2+0.5,3,R.tak-0.4],
      [R.bredd/2+0.5,R.langd-3,R.tak-0.4],[R.bredd/2-0.5,R.langd-3,R.tak-0.4]],"#B9BDC0",null);
  }});
  // dressyrbokstäverna på sargen, samma läge som 3D-vyn (bokstavLage)
  for(const B of DRESSYRBOKSTAVER){
    const L=bokstavLage(R,B);
    const wx=L.x, wy=L.y;
    const ux=L.sida==="W"?-0.35:L.sida==="E"?0.35:0, uy=L.sida==="S"?-0.35:L.sida==="N"?0.35:0;
    items.push({d:-avst2([wx,wy])+1e4, rita(){
      ritaText3D(k,wx+ux,wy+uy,1.15,B.b,2.4,"#6E6450","Petrona,serif");
    }});
  }
  for(const d of R.dorrar) items.push({d:-avst2(d.pos), rita(){ritaMarkor3D(k,d.pos);}});
  if(G.leder){
    items.push({d:-avst2([VD.hastX,VD.hastY]), rita(){ritaLeddHast3D(k);}});
    const sp=SPELABSTRAKTIONER.ridhus.sargport;
    items.push({d:-avst2([(sp.x0+sp.x1)/2,ba.y+ba.h]),
      rita(){ritaMarkor3D(k,[(sp.x0+sp.x1)/2,ba.y+ba.h]);}});
  }
  items.sort((a,b)=>a.d-b.d);
  for(const o of items)o.rita();
  ritaSpelare3D();
}

/* ── Huvudingång från spelloopen ─────────────────────────────── */
function ritaVandring(){
  ritaVandringVy();
  const ap=document.getElementById("approach");
  ap.textContent=VD.prompt&&!overlayUppe()?`Tryck E — ${VD.prompt.text}`:"";
  if(G.sagaT>0){G.sagaT-=1/60;if(G.sagaT<=0)document.getElementById("saga").classList.remove("on");}
  const mål=!G.hastId
    ? (G.scen==="gard"?["Gå till stallet","Stallentrén är den gula dörren under verandan, bortom parkeringen."]
      :G.scen==="ridhusinne"?["Titta dig omkring","Läktaren, speglarna, Café Krubban — lektionen börjar i stallet."]
      :["Prata med ridläraren","Hon står i stallgången och fördelar hästarna."])
    : !G.hamtad
    ? (G.leder?[`Led ${HORSES[G.hastId].namn} till boxen`,
         G.scen==="gard"?"In genom stalldörren och fram till boxen."
         :G.lerig?"Leriga ben efter hagen — spola av honom i spiltan i södra änden först."
         :"Fram till boxen och släpp in honom (E)."]
       :[`Hämta ${HORSES[G.hastId].namn} i hagen`,
         "Grinden sitter på hagens västra sida, öster om stallet."])
    : !G.skotselRes
    ? [`Sköt om ${HORSES[G.hastId].namn}`,
       G.scen!=="stallinne"?"Boxen är inne i stallet."
       :!G.utrustning?"Hämta sadel och träns i sadelkammaren (klubbdelen) — sedan boxen."
       :"Vid boxen (E): mocka, fodra och sadla."]
    : G.tavling
    ? [`Led ${HORSES[G.hastId].namn} till tävlingen`,
       G.scen==="stallinne"?"Ut genom stalldörren — tävlingsdagen väntar."
       :G.tavling.typ==="hoppning"
         ?(G.scen==="ridhusinne"?"Sekretariatet ropar upp startordningen vid sargporten."
           :"Påskhoppet rids i ridhuset — in genom durkplåtdörrarna.")
         :"Dressyren rids på uteridbanan i väster. Domaren sitter i kuren."]
    : [`Led ${HORSES[G.hastId].namn} till lektionen`,
       G.scen==="stallinne"?"Ut genom stalldörren och över gården."
       :G.scen==="ridhusinne"?"Fram till sargporten vid A — sitt upp där."
       :"Ridhuset genom durkplåtdörrarna — eller uteridbanan bortom hagarna. Skogsstigen (uteritt) börjar vid åkerkanten i nordväst."];
  visaUppgift(mål[0],mål[1]);
}
