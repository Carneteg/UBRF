/* ══════════════════════════════════════════════════════════════════
   EFTER PASSET — redovisningen som gör växten läsbar.

   Allt det här mäts redan. Hästens humör sätts när du hämtar henne,
   spänningen rör sig medan du rider, färdigheterna kryper uppåt av det
   du gör, och toleranserna de ger tillbaka avgör hur mycket du behöver
   korrigera. Problemet var att inget av det syntes: lektionen tog slut
   och du fick en tabell med inverkanssiffror.

   Den här filen sparar tillståndet före passet, mäter under, och gör
   skillnaden till meningar. Tre saker ska stå där, i den ordningen:

     1. Vad hände med hästen. Kom hon ut spänd och gick hem lös?
     2. Vad växte hos dig, och AV VAD. En färdighet som stiger utan att
        man vet varför är en siffra, inte ett framsteg.
     3. Vad det betyder nästa gång, i samma enhet som passet kostade —
        antal gånger du fick hämta hem henne.

   Punkt 3 är den viktiga. "Sits 34 → 38" säger ingenting. "Du fick
   hämta hem henne tjugotre gånger, nästa pass blir det ungefär arton"
   säger allt, och det är dessutom räknat ur samma formel som styr
   ridningen — inte påhittat för att låta uppmuntrande.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const PASS={aktiv:false, klart:false};

/* Ett tal som procent med tecken, för de små deltamärkena. */
function pTecken(x){ return (x>=0?"+":"−")+Math.abs(Math.round(x)); }
function kommatal(x,d){ return x.toFixed(d===undefined?2:d).replace(".",","); }

/* ── Skötseln, före ritten ────────────────────────────────────────
   Hästkunskapen växer när du sköter henne, alltså innan passet börjar.
   Anropas från visaSkotsel med värdet före och efter. */
function passSkotsel(fore,efter,res){
  PASS.skotselFore=fore; PASS.skotselEfter=efter; PASS.skotselRes=res;
}

/* ── Start ────────────────────────────────────────────────────────
   Anropas när lektionen börjar. Tar en avskrift av allt som ska
   jämföras efteråt. */
function passStart(){
  const f=(typeof fard==="function")?{...fard()}:null;
  const mod=(typeof fardighetsMod==="function")?fardighetsMod():null;
  Object.assign(PASS,{
    aktiv:true, klart:false,
    hastId:G.hastId, grupp:G.grupp,
    fardFore:f, fardEfter:null,
    hallaFore:mod?mod.halla:0, ampFore:mod?mod.amplitud:1,
    hallaEfter:0, ampEfter:1,
    humorFore:(G.humor===undefined?0.6:G.humor),
    rangFore:((typeof hastminne==="function"&&hastminne(G.hastId))||{}).rang??0.45,
    tid:0,
    losgjordFore:null, spanningFore:null,
    losgjordSlut:0, spanningSlut:0, spanningTopp:0,
    mjukhetSum:0, mjukhetTid:0,
    hamtningar:0, tidUte:0, _ute:0, _varUte:false,
  });
}

/* ── Under passet ─────────────────────────────────────────────────
   En bildruta i taget. Det enda som är klurigt är hemhämtningarna:
   hon glider ut ur tempobandet och du hämtar hem henne igen. En halv
   sekund utanför krävs innan det räknas — annars skulle varje studs i
   bruset bli en korrigering, och siffran skulle säga mer om
   modellens noggrannhet än om ridningen. */
function passSteg(dt){
  if(!PASS.aktiv||!G.ride)return;
  const r=G.ride;
  PASS.tid+=dt;
  if(PASS.losgjordFore===null&&PASS.tid>1.5){
    PASS.losgjordFore=r.skala.losgjordhet;
    PASS.spanningFore=r.spanning;
  }
  PASS.losgjordSlut=r.skala.losgjordhet;
  PASS.spanningSlut=r.spanning;
  if(r.spanning>PASS.spanningTopp)PASS.spanningTopp=r.spanning;
  PASS.mjukhetSum+=r.mjukhet*dt; PASS.mjukhetTid+=dt;

  const inne=(typeof iTempoBand==="function")?iTempoBand(r,G.grupp,G.moment):true;
  if(!inne){
    PASS._ute+=dt; PASS.tidUte+=dt;
    if(PASS._ute>0.5)PASS._varUte=true;
  }else{
    if(PASS._varUte)PASS.hamtningar++;
    PASS._ute=0; PASS._varUte=false;
  }
}

/* ── Slut ─────────────────────────────────────────────────────────
   Anropas när sista momentet är klart, före registreraPass så att
   färdigheterna inte hunnit röras av något annat. */
function passSlut(){
  if(!PASS.aktiv)return;
  PASS.aktiv=false; PASS.klart=true;
  PASS.fardEfter=(typeof fard==="function")?{...fard()}:null;
  const mod=(typeof fardighetsMod==="function")?fardighetsMod():null;
  PASS.hallaEfter=mod?mod.halla:0;
  PASS.ampEfter=mod?mod.amplitud:1;
  if(PASS.losgjordFore===null){          // passet hoppades över direkt
    PASS.losgjordFore=PASS.losgjordSlut;
    PASS.spanningFore=PASS.spanningSlut;
  }
}

/* ── Hästens sida ─────────────────────────────────────────────────
   Vad som hände med henne, i ord. Siffrorna står bredvid för den som
   vill se dem, men meningen är det som ska läsas. */
function efterHastRader(){
  const h=HORSES[PASS.hastId]||{namn:"Hästen"};
  const namn=h.namn, rad=[];

  rad.push({txt:(typeof humorText==="function")
    ? humorText(PASS.hastId,PASS.humorFore)
    : `${namn} kom ut i stallgången.`, ton:"in"});

  const dSp=(PASS.spanningFore??0)-(PASS.spanningSlut??0);
  if(dSp>0.08)
    rad.push({txt:`Spänningen sjönk från ${kommatal(PASS.spanningFore)} till `
      +`${kommatal(PASS.spanningSlut)} under passet. Det är du som fick ned den.`,
      ton:"bra", tal:pTecken(-dSp*100)});
  else if(dSp<-0.08)
    rad.push({txt:`Spänningen steg från ${kommatal(PASS.spanningFore)} till `
      +`${kommatal(PASS.spanningSlut)}. Nästa gång: sakta ned innan hon hinner låsa sig.`,
      ton:"dalig", tal:pTecken(-dSp*100)});
  else
    rad.push({txt:`Spänningen låg still kring ${kommatal(PASS.spanningSlut)}.`, ton:"in"});

  const dL=(PASS.losgjordSlut??0)-(PASS.losgjordFore??0);
  if(dL>0.06)
    rad.push({txt:`Lösgjordheten gick ${kommatal(PASS.losgjordFore)} → `
      +`${kommatal(PASS.losgjordSlut)}. Hon släppte ryggen.`,
      ton:"bra", tal:pTecken(dL*100)});
  else if(dL<-0.06)
    rad.push({txt:`Lösgjordheten föll ${kommatal(PASS.losgjordFore)} → `
      +`${kommatal(PASS.losgjordSlut)}. Hon höll emot mot slutet.`,
      ton:"dalig", tal:pTecken(dL*100)});

  /* Relationen. Den rör sig av både ridningen och skötseln, och priset
     nedåt är större än vinsten uppåt — det är meningen. */
  const P=G.passRes||{};
  if(typeof P.rangEfter==="number"&&typeof P.rangFore==="number"){
    const d=P.rangEfter-P.rangFore;
    if(d>0.004)
      rad.push({txt:`Hon minns passet. Förtroendet er emellan steg till `
        +`${kommatal(P.rangEfter)}.`, ton:"bra", tal:pTecken(d*100)});
    else if(d<-0.004)
      rad.push({txt:`Förtroendet sjönk till ${kommatal(P.rangEfter)}. `
        +`Det byggs långsamt och tappas fort — som hos människor.`,
        ton:"dalig", tal:pTecken(d*100)});
  }

  const risker=(PASS.skotselRes&&PASS.skotselRes.risker)||[];
  if(risker.length)
    rad.push({txt:`Du lämnade ${risker.join(" och ").replaceAll("_"," ")} i morse. `
      +`Det följer med henne till imorgon.`, ton:"dalig"});

  return rad;
}

/* ── Din sida ─────────────────────────────────────────────────────
   Varje färdighet som växte, med anledningen. En siffra som stiger
   utan att man vet varför är ingen lärdom. */
const VARFOR={
  sits:  "Du satt still. Mjukheten låg över 0,62 stora delar av passet.",
  hand:  "Tygeln låg i det mjuka bandet — varken slak eller hård.",
  kansla:"Du fick ned hennes spänning medan du red. Det är timing.",
  skotsel:"Skötseln i morse höll måttet.",
};
function efterDuRader(){
  const rad=[];
  if(!PASS.fardFore||!PASS.fardEfter)return rad;
  /* Skötseln växte före ritten och har därför en egen avskrift. */
  const fore={...PASS.fardFore}, efter={...PASS.fardEfter};
  if(typeof PASS.skotselFore==="number"){
    fore.skotsel=PASS.skotselFore; efter.skotsel=PASS.skotselEfter;
  }
  for(const k of (typeof FARDIGHETER!=="undefined"?FARDIGHETER:[])){
    const d=(efter[k.id]??0)-(fore[k.id]??0);
    if(d<0.004)continue;
    rad.push({namn:k.namn, id:k.id, fore:fore[k.id], efter:efter[k.id],
      txt:VARFOR[k.id]||k.text, tal:pTecken(d*100)});
  }
  return rad;
}

/* ── Vad det betyder nästa gång ───────────────────────────────────
   Här räknas det på riktigt. Avdriften dämpas med faktorn
   (1 − 0,45·halla), samma formel som humor.js använder när hon glider
   i väg, och antalet hemhämtningar följer den nästan rakt av. Så en
   höjd hållförmåga går att räkna om till färre korrigeringar — i
   samma enhet som passet nyss kostade.

   Det är en uppskattning och sägs som en. Men den är härledd, inte
   påhittad för att låta uppmuntrande. */
function efterLoftet(){
  const n=PASS.hamtningar;
  if(!PASS.klart)return null;
  const dFore=1-0.45*clamp(PASS.hallaFore,0,1);
  const dEfter=1-0.45*clamp(PASS.hallaEfter,0,1);
  const ut={hamtningar:n, tidUte:PASS.tidUte,
    mjukhet:PASS.mjukhetTid>0?PASS.mjukhetSum/PASS.mjukhetTid:0};
  /* Vad samma pass hade kostat en nybörjare, som inte håller ihop
     henne alls. Jämförelsen gör den egna siffran läsbar. */
  if(dEfter<0.985&&n>=4)
    ut.nyborjare=Math.round(n/dEfter);
  /* Och vad nästa pass bör kosta, om färdigheten växte. */
  if(dEfter<dFore-0.0015&&n>=4){
    const nasta=Math.round(n*dEfter/dFore);
    if(nasta<n)ut.nasta=nasta;
  }
  /* Handens tolerans, i procent mot passets början. */
  if(PASS.ampEfter>PASS.ampFore+0.002)
    ut.amplitud=Math.round((PASS.ampEfter/PASS.ampFore-1)*100);
  return ut;
}

/* ── Skärmen ──────────────────────────────────────────────────────
   Läggs överst i resultatrutan, före protokoll och tabeller. Raderna
   fälls in en och en — inte som pynt, utan för att man ska hinna läsa
   dem i den ordning de betyder något. */
function efterPassHTML(){
  if(!PASS.klart)return "";
  const h=HORSES[PASS.hastId]||{namn:"Hästen"};
  const hRad=efterHastRader(), dRad=efterDuRader(), L=efterLoftet();
  let i=0;
  const rad=(inner,ton)=>`<li class="eRad${ton?" "+ton:""}" style="--i:${i++}">${inner}</li>`;

  const hastLi=hRad.map(r=>rad(
    `<span class="eTxt">${r.txt}</span>`
    +(r.tal?`<span class="eTal ${r.ton==="dalig"?"ned":"upp"}">${r.tal}</span>`:""),
    r.ton)).join("");

  const duLi=dRad.length
    ? dRad.map(r=>rad(
        `<span class="eNamn">${r.namn}</span>`
        /* Stapeln börjar på värdet före passet och växer till efter,
           när raden fällts in. Det är hela poängen: man ska se den röra
           sig, inte läsa av var den hamnade. */
        +`<span class="eStapel"><i style="width:${(r.fore*100).toFixed(1)}%"`
        +` data-mal="${(r.efter*100).toFixed(1)}"></i>`
        +`<u style="left:${(r.fore*100).toFixed(1)}%"></u></span>`
        +`<span class="eTal upp">${r.tal}</span>`
        +`<span class="eTxt">${r.txt}</span>`,"vaxte")).join("")
    : rad(`<span class="eTxt">Ingenting växte den här gången. `
        +`Färdigheter växer inte medan hästen är spänd över 0,70 — `
        +`då lär man sig fel saker.</span>`,"in");

  let loftet="";
  if(L){
    const bitar=[];
    bitar.push(`<b>${L.hamtningar}</b> gånger fick du hämta hem henne`
      +(L.tidUte>2?`, och ${Math.round(L.tidUte)} sekunder red du utanför tempobandet`:""));
    let txt=bitar.join("")+".";
    if(L.nyborjare&&L.nyborjare>L.hamtningar)
      txt+=` Samma häst, samma dag, utan din sits och känsla: ungefär `
        +`<b>${L.nyborjare}</b>.`;
    if(L.nasta)
      txt+=` Nästa pass, med det du lärde dig idag: ungefär <b>${L.nasta}</b>.`;
    if(L.amplitud)
      txt+=` Handen får darra <b>${L.amplitud} %</b> mer innan mjukheten faller.`;
    loftet=`<p class="eLofte eRad" style="--i:${i++}">${txt}</p>`;
  }

  /* Var passet förberett av ridläraren ska det stå här, inte bara
     försvinna. Annars undrar spelaren nästa gång varför hästen plötsligt
     är sämre. */
  if(G.forberettPass)
    loftet+=`<p class="eLofte eRad" style="--i:${i++}">Idag hade ridläraren `
      +`gjort i ordning ${h.namn} åt dig. <b>Nästa gång gör du det själv</b> — `
      +`visitera, rykta, kratsa och sadla. Det du gör där avgör hur hon går.</p>`;

  return `<div class="efterPass" id="efterPass">
    <div class="eKol">
      <div class="lbl">${h.namn} idag</div>
      <ul class="eLista">${hastLi}</ul>
    </div>
    <div class="eKol">
      <div class="lbl">${(typeof jagNamn==="function"?jagNamn():"Du")} växte</div>
      <ul class="eLista">${duLi}</ul>
    </div>
    <div class="eBred">${loftet}</div>
  </div>`;
}

/* Fäller in raderna. Anropas när resultatrutan just lagts in i DOM:en. */
function kopplaEfterPass(){
  const el=document.getElementById("efterPass");
  if(!el)return;
  requestAnimationFrame(()=>requestAnimationFrame(()=>{
    el.classList.add("pa");
    for(const i of el.querySelectorAll(".eStapel i[data-mal]"))
      i.style.width=i.dataset.mal+"%";
  }));
  if(efterDuRader().length&&typeof ljudStot==="function")
    setTimeout(()=>{ljudStot(660,"sine",0.10,0.05);
      setTimeout(()=>ljudStot(990,"sine",0.16,0.045),110);},520);
}
