/* ══════════════════════════════════════════════════════════════════
   MODELLEN — rak port av Luau-modulerna. Samma konstanter, samma
   formler, samma pyramidregel. Om något känns annorlunda än i
   Roblox-versionen är det en bugg här, inte ett designbeslut.
   ══════════════════════════════════════════════════════════════════ */
"use strict";
const clamp=(v,lo,hi)=>v<lo?lo:v>hi?hi:v;
const approach=(nuv,mal,upp,ner,dt)=> mal>nuv ? nuv+Math.min(mal-nuv,upp*dt) : nuv-Math.min(nuv-mal,ner*dt);

/* ── Utbildningsskalan ── */
const Skala={
  ORDER:["takt","losgjordhet","kontakt","schvung","rakriktning","samling"],
  LABEL:{takt:"Takt",losgjordhet:"Lösgjordhet",kontakt:"Kontakt",schvung:"Schvung",rakriktning:"Rakriktning",samling:"Samling"},
  TOL:0.12,
  FORVANTAN:{ledlektion:.25,knatte:.35,minior:.42,grupp1:.52,grupp2:.58,grupp3:.64,grupp4:.70,grupp5:.76,hoppgrupp:.72},
  VIKTER:{
    grupp2:{takt:.28,losgjordhet:.26,kontakt:.22,schvung:.16,rakriktning:.08},
    grupp3:{takt:.22,losgjordhet:.22,kontakt:.22,schvung:.18,rakriktning:.16},
    grupp4:{takt:.18,losgjordhet:.18,kontakt:.20,schvung:.20,rakriktning:.18,samling:.06},
    hoppgrupp:{takt:.30,losgjordhet:.15,kontakt:.18,schvung:.20,rakriktning:.17},
  },
  tom(){const t={};for(const k of this.ORDER)t[k]=0;return t;},
  /* Taket sätts av den SVAGASTE nivån under — golvregeln. */
  pyramid(s){let golv=1.0;for(const k of this.ORDER){let v=s[k]||0;const tak=golv+this.TOL;
    if(v>tak)v=tak; s[k]=clamp(v,0,1); if(s[k]<golv)golv=s[k];}return s;},
  inverkan(s,niva){const w=this.VIKTER[niva]||this.VIKTER.grupp3;let su=0,vi=0;
    for(const k in w){su+=(s[k]||0)*w[k];vi+=w[k];}return vi>0?su/vi:0;},
  svagaste(s,niva){const w=this.VIKTER[niva]||this.VIKTER.grupp3;
    const krav=(this.FORVANTAN[niva]||0.55)*0.85;
    for(const k of this.ORDER) if(w[k]!==undefined && (s[k]||0)<krav) return k;
    let varst="takt",lo=9;for(const k of this.ORDER)if(w[k]!==undefined&&(s[k]||0)<lo){lo=s[k];varst=k;}
    return varst;},
};

/* ── GaitConfig ── */
const Gait={
  SPRANG:{hast:3.50,D:3.25,C:3.00,B:2.75},
  G:{
    halt:{namn:"Halt",min:0,max:0.20,norm:0,steg:0},
    skritt:{namn:"Skritt",min:0.90,max:2.00,norm:1.45,steg:0.46},
    trav:{namn:"Trav",min:2.40,max:4.30,norm:3.20,steg:0.63},
    galopp:{namn:"Galopp",min:4.60,max:8.00,norm:5.60,steg:1.00},
  },
  HYST:0.35,
  forTempo(t,nuv){const h=this.HYST,k=nuv&&this.G[nuv];
    if(k&&t>=k.min-h&&t<=k.max+h)return nuv;
    if(t<0.25)return"halt"; if(t<2.20)return"skritt"; if(t<4.45)return"trav"; return"galopp";},
  /* CYKELLÄNGD: sträckan hästen färdas under ETT helt fasvarv (fas 0→1),
     alltså ett helt gångartsvarv — inte ett enskilt hovnedslag. Samma
     storhet som Gaits.cycleLength i Roblox (norm ÷ cycles). Vid normtempo
     och neutral häst: skritt 1,61 m, trav 2,21 m, galopp 3,50 m, mot
     Roblox 1,45 / 2,13 / 3,20. Den som driver gångartsfasen ska dela
     sträckan med DEN HÄR siffran och ingenting annat. */
  steglangd(kat,g,schvung,spanning){const bas=this.SPRANG[kat]||3.5,gg=this.G[g];
    if(!gg||gg.steg===0)return 0;
    return bas*gg.steg*clamp(1+0.22*(schvung-0.5)-0.18*spanning,0.72,1.28);},
};

/* ── RideModel ── */
const K={
  AMPLITUD_SKALA:0.22, AIDS_TAU:0.30, MJUKHET_EMA:3.0,
  TYGEL_BAND_MIN:0.22, TYGEL_BAND_MAX:0.58, TYGEL_HART:0.72,
  SKANKEL_TROSKEL:0.28, SKANKEL_FOR_MYCKET:0.85,
  HH_FONSTER:0.45, HH_MIN_AMPLITUD:0.18, HH_COOLDOWN:1.2,
  BAS_STIGNING:0.55, BAS_FALL:0.95,
  SPANNING_STIGNING:1.10, SPANNING_FALL:0.42,
  /* ── GRUNDHJÄLPEN ÄR EN CUE, INTE EN GASPEDAL (PO 2026-09-05) ──
     Förut låg skänkeln som en konstant term ovanpå hästens egen norm:
     `begäran = (skänkel − tygel·0,9)·3,2`. Etablerade du skritt och höll
     kvar skänkeln hamnade målet över skrittens tak och hon travade iväg;
     släppte du helt föll takten. Skritt gick alltså bara att hålla genom
     att balansera skänkeln på ett exakt värde — en bilgas.

     Nu ber en FRAMÅTDRIVANDE IMPULS om nästa gångart. Hästen bär den
     därefter själv tills ryttaren ber om något annat: halvhalt, tygel
     eller sits tar henne ner ett steg. Det som mäts är alltså ändringen
     i hjälpen, inte dess nivå.

     Trösklarna ligger över handens normala darr (mjukheten mäter samma
     storhet med K.AMPLITUD_SKALA 0,22) så att en ostadig hand inte råkar
     be om galopp. Spärren hindrar att en enda rörelse räknas två gånger
     och ger övergången tid att bli klar innan nästa kan begäras. */
  CUE_UPP:0.16, CUE_NER:0.13, CUE_SPARR:0.9, SITS_PARAD:0.78,
  /* Kvar av den gamla termen: hjälpen får fortfarande variera tempot
     INOM gångarten — det är skillnaden mellan en samlad och en utsträckt
     skritt — men inte längre bära över ett gångartsband. Skrittens band
     är 1,10 brett, så 0,6 räcker till nyans och inte till att byta. */
  HALL_BAND:0.60,
};
/* Gångarterna i ordning. Cue:n stegar i den här listan, ett steg i taget. */
const GANGORDNING=["halt","skritt","trav","galopp"];

function nyState(dagsform,rang,sadellage){
  return {skala:Skala.tom(),spanning:0.15,tempo:0,gangart:"halt",steglangd:0,
    /* Den gångart ryttaren senast BAD om. Hästen bär den tills hon ombeds
       något annat; `gangart` är vad hon faktiskt går just nu, och de två
       skiljer sig under en övergång. */
    malGangart:"halt", cue:null, cueTid:-99, overgang:null, senasteOvergang:0,
    rang:rang??0.5,dagsform:dagsform??0.7,sadellage:sadellage??0.8,mjukhet:0.5,
    _prev:null,_medel:null,_hist:[],_hh:{fas:0,t:0,kval:0},_senasteHH:-99,_tid:0,
    _cueSparr:0,_overgangStart:-99};
}

function stepRide(s,a,h,ctx,dt){
  if(dt<=0)return s; s._tid+=dt;
  // mjukhet: amplitud mot glidande medel
  /* `_prev` sås med INGEN hjälp, inte med den första bildrutans hjälp.
     Innan ryttaren lägger på skänkeln finns ingen skänkel, så en hjälp
     som ligger på redan från början är en pålagd hjälp och ska räknas som
     impuls. Såddes den med sig själv blev första bildrutans ändring noll
     och en häst som satt still med full skänkel stod kvar för evigt.
     Glidande medelvärdet sås däremot med den faktiska hjälpen — det
     mäter handens darr, och där är utgångsläget inte noll utan det hon
     håller. */
  if(!s._medel){s._medel={skankel:a.skankel,tygel:a.tygel,sits:a.sits,styrning:a.styrning};
    s._prev={skankel:0,tygel:0,sits:0,styrning:0,spo:false,lattridning:false,diagonal:0};}
  else{
    const m=s._medel,beta=clamp(dt/K.AIDS_TAU,0,1);
    const avvik=Math.abs(a.skankel-m.skankel)+Math.abs(a.tygel-m.tygel)
      +0.7*Math.abs(a.sits-m.sits)+0.7*Math.abs(a.styrning-m.styrning);
    m.skankel+=(a.skankel-m.skankel)*beta; m.tygel+=(a.tygel-m.tygel)*beta;
    m.sits+=(a.sits-m.sits)*beta; m.styrning+=(a.styrning-m.styrning)*beta;
    /* Färdigheten vidgar fönstret: en van hand får darra mer innan
       mjukheten faller, och hittar tillbaka snabbare efter ett ryck.
       Saknas F gäller nybörjarens värden — modellen fungerar utan. */
    const F=ctx.fard||{};
    const kvot=avvik/(K.AMPLITUD_SKALA*(F.amplitud||1)), tick=1/(1+kvot*kvot);
    s.mjukhet+= (tick-s.mjukhet)*clamp(K.MJUKHET_EMA*(F.mjukhetFart||1)*dt,0,1);
  }
  // halvhalt
  let hhKval=0;
  {const hh=s._hh,p=s._prev;
   if(p){const dS=a.sits-p.sits,dK=a.skankel-p.skankel,dT=a.tygel-p.tygel;
    if(hh.fas===0){
      const hhMin=K.HH_MIN_AMPLITUD*((ctx.fard&&ctx.fard.hhAmplitud)||1);
      if(dS>0&&dK>0&&dT>0&&(dS+dK+dT)>=hhMin&&(s._tid-s._senasteHH)>K.HH_COOLDOWN){
        hh.fas=1;hh.t=0;const m=(dS+dK+dT)/3;
        const av=(Math.abs(dS-m)+Math.abs(dK-m)+Math.abs(dT-m))/3;
        hh.kval=clamp(1-av/Math.max(m,0.05),0,1);}
    }else{hh.t+=dt;
      if(hh.t>K.HH_FONSTER*((ctx.fard&&ctx.fard.hhFonster)||1)){hh.fas=0;hhKval=-0.35;}
      else if(dT<-0.02&&a.tygel<=p.tygel){hh.fas=0;s._senasteHH=s._tid;hhKval=hh.kval;}}}
  }
  /* ── CUE: ryttaren BER om en gångart, hästen bär den ──────────────
     Uppåt av en framåtdrivande impuls — skänkeln ökar tydligt medan
     tygeln inte håller emot. Nedåt av en fullbordad halvhalt, eller av
     tygel eller sits som tas på. Halvhalten är den ridmässigt rätta
     nedåtgående hjälpen och får därför gälla även när den är svag.

     Spärren gör att en enda rörelse inte räknas två gånger, och att
     hästen hinner göra klart övergången innan nästa kan begäras. */
  {const p=s._prev;
   s._cueSparr=Math.max(0,(s._cueSparr||0)-dt);
   if(p&&s._cueSparr<=0){
     const dK=a.skankel-p.skankel, dT=a.tygel-p.tygel, dS=a.sits-p.sits;
     let i=GANGORDNING.indexOf(s.malGangart||s.gangart); if(i<0)i=0;
     let cue=null;
     /* ASYMMETRIN ÄR AVSIKTLIG, och den är ridmässig.

        UPPÅT krävs en NY impuls varje gång. En hållen skänkel är inte en
        fortsatt begäran om mer fart — man rider framåt med skänkeln på
        utan att hästen accelererar. Det var precis den gaspedalen
        beslutet tog bort.

        NEDÅT räcker det att den starka hjälpen LIGGER KVAR. En tygel som
        hålls an är en fortsatt begäran om att komma tillbaka, och en
        parad från galopp till halt är en sammanhängande hjälp, inte tre
        separata ryck. En lätt halvhalt ger däremot ett steg och sedan
        inget mer — den är en impuls till sin natur. */
     const hallerAn=a.tygel>=K.TYGEL_BAND_MAX||a.sits>=K.SITS_PARAD;
     if(dK>=K.CUE_UPP&&a.tygel<=K.TYGEL_BAND_MAX&&i<GANGORDNING.length-1){
       i++; cue="framåt";
     }else if((hhKval>0||dT>=K.CUE_NER||dS>=K.CUE_NER||hallerAn)&&i>0){
       i--; cue=hhKval>0?"halvhalt":(hallerAn&&dT<K.CUE_NER&&dS<K.CUE_NER?"parad":(dT>=K.CUE_NER?"tygel":"sits"));
     }
     if(cue){
       s.malGangart=GANGORDNING[i]; s.cue=cue; s.cueTid=s._tid;
       s._cueSparr=K.CUE_SPARR; s._overgangStart=s._tid;
       s.overgang={fran:s.gangart,till:s.malGangart,klar:false};
     }
   }
  }
  // spänning
  {const kf=0.55+0.9*h.kanslighet;let press=0;
   const bandExtra=(ctx.fard&&ctx.fard.tygelband)||0;
   if(a.tygel>K.TYGEL_HART)press+=(a.tygel-K.TYGEL_HART)*2.6;
   else if(a.tygel>K.TYGEL_BAND_MAX+bandExtra)press+=(a.tygel-K.TYGEL_BAND_MAX-bandExtra)*0.9;
   press+=(1-s.mjukhet)*0.85;
   if(a.skankel>K.SKANKEL_FOR_MYCKET)press+=(a.skankel-K.SKANKEL_FOR_MYCKET)*1.1;
   if(a.sits>0.75&&s.gangart==="galopp")press+=(a.sits-0.75)*0.7;
   if(a.spo&&h.flaggor.radd_for_spo)press+=1.6; else if(a.spo)press+=0.15;
   press+=(1-ctx.stallro)*0.5+(1-s.sadellage)*0.7+(1-ctx.underlag)*0.25;
   /* Skyggheten: en ryttare med pondus tar udden av den. Hon slutar
      inte vara skygg — hon reagerar mindre på dig som ledare. */
   const damp=1-clamp((ctx.fard&&ctx.fard.skygghet)||0,0,0.5);
   press+=h.skygghet*0.18*(ctx.utomhus?1.5:1)*damp;
   const lugn=s.rang*0.6+h.forlatande*0.5+s.mjukhet*0.6+s.dagsform*0.3
     +((ctx.fard&&ctx.fard.lugn)||0);
   const mal=clamp(press*kf-lugn*0.45,0,1);
   /* Fallet är hur fort spänningen släpper när pressen lättar. En lugn
      ryttare får den att sjunka undan fortare — hon smittar av sig. */
   const fall=(ctx.fard&&ctx.fard.spanningFall)||1;
   s.spanning=clamp(approach(s.spanning,mal,K.SPANNING_STIGNING*(0.6+0.8*h.kanslighet),
     K.SPANNING_FALL*(0.5+1.0*h.forlatande)*fall,dt),0,1);
  }
  // tempo — förhandling, inte kommando
  {const g=Gait.G[s.gangart]||Gait.G.halt;
   /* Avdriften: hästens eget tempo ligger inte still. Hon glider sakta
      åt sitt håll och rycker till ibland, och hur mycket beror på
      lydnaden och dagens humör. Det är den här termen som gör att
      stillasittande inte längre är optimalt — släpper du henne faller
      takten, och takten är det inverkan mäter.

      Två frekvenser med olika period, så att vandringen aldrig blir en
      förutsägbar sinus man lär sig utantill. */
   const D=ctx.avdrift||{glid:0,ryck:0,tröghet:1};
   const t=s._tid;
   const vandring=D.glid*(0.62*Math.sin(t*0.41)+0.38*Math.sin(t*0.97+1.3))
     + D.ryck*Math.max(0,Math.sin(t*0.23+2.1))**6;
   /* Hästen bär den gångart hon senast ombads, inte den hon råkar ha.
      Det är skillnaden mot förr: `eget` läste `s.gangart`, så tempot
      hade ingen minneskälla utom sig självt och föll tillbaka så fort
      hjälpen släpptes. */
   const gm=Gait.G[s.malGangart]||g;
   const eget=gm.norm*(0.80+0.40*h.framatbjudning)+vandring*(gm.norm>0?1:0);
   /* Hjälpen nyanserar INOM gångarten — samlad eller utsträckt skritt —
      men bär inte längre över ett band. Se K.HALL_BAND. */
   const begaran=(a.skankel-a.tygel*0.9)*K.HALL_BAND;
   const mal=clamp(eget+begaran+s.spanning*0.8*h.framatbjudning,0,9);
   /* Trögheten: en olydig häst svarar segare på skänkeln. Hon blir inte
      omöjlig, hon kräver att du ber tydligare och håller kvar. */
   const tr=(1.6+1.4*h.tyngd)*D.tröghet;
   s.tempo=approach(s.tempo,mal,8.8/tr,11/tr,dt);
   s._avdrift=vandring;
   const forra=s.gangart;
   s.gangart=Gait.forTempo(s.tempo,s.gangart);
   /* ÖVERGÅNGSTIDEN: från att ryttaren bad till att hästen faktiskt går
      i den gångarten. Det är måttet G02-B/C ska kunna bygga på, och det
      enda som säger om en övergång var mjuk eller ryckig. */
   if(s.gangart!==forra&&s.overgang&&!s.overgang.klar&&s.gangart===s.malGangart){
     s.overgang.klar=true; s.senasteOvergang=s._tid-s._overgangStart;
   }
   s._hist.push(s.tempo); if(s._hist.length>12)s._hist.shift();
  }
  // målvärden
  const mal={};
  {let stab=1;const n=s._hist.length;
   if(n>=3){let me=0;for(const v of s._hist)me+=v;me/=n;
     let sp=0;for(const v of s._hist)sp+=Math.abs(v-me);sp/=n;stab=clamp(1-sp/0.9,0,1);}
   let svang=0;
   if(s.tempo>0.5&&ctx.svangradie<40){
     const krav=(s.tempo*s.tempo)/Math.max(ctx.svangradie,1);
     svang=clamp((krav-3.0)/9.0,0,0.55);}
   let diag=0;
   if(s.gangart==="trav"&&a.lattridning)diag=(1-clamp(a.diagonal,0,1))*0.30;
   if(s.gangart==="trav"&&!a.lattridning&&s.spanning>0.5)diag+=0.10;
   mal.takt=clamp(0.15+0.42*stab+0.28*s.mjukhet+0.15*h.utbildning-svang-diag-0.30*s.spanning,0,1);
   const handMjuk=1-clamp((a.tygel-K.TYGEL_BAND_MAX-((ctx.fard&&ctx.fard.tygelband)||0))/0.35,0,1);
   mal.losgjordhet=clamp(0.10+0.55*(1-s.spanning)+0.20*handMjuk+0.18*s.dagsform
     +0.12*s.sadellage+0.10*h.forlatande-0.15*(1-s.mjukhet),0,1);
   const mitt=(K.TYGEL_BAND_MIN+K.TYGEL_BAND_MAX)/2,halv=(K.TYGEL_BAND_MAX-K.TYGEL_BAND_MIN)/2;
   const iband=clamp(1-Math.abs(a.tygel-mitt)/(halv*1.6),0,1);
   mal.kontakt=clamp(0.05+0.48*iband+0.32*s.mjukhet+0.20*mal.losgjordhet-0.25*s.spanning,0,1);
   const kravS=K.SKANKEL_TROSKEL+0.35*h.tyngd;
   let driv=clamp((a.skankel-kravS)/0.45,0,1);
   if(a.skankel>K.SKANKEL_FOR_MYCKET)driv*=clamp(1-(a.skankel-K.SKANKEL_FOR_MYCKET)*2,0.25,1);
   mal.schvung=clamp(0.02+0.50*Math.min(driv,iband+0.25)+0.22*mal.kontakt
     +0.16*h.framatbjudning-0.28*s.spanning,0,1);
   const sb=Math.abs(a.styrning);let rak;
   if(ctx.svangradie>100)rak=clamp(1-sb*2.2,0,1);
   else{const onskad=clamp(12/Math.max(ctx.svangradie,4),0,1);
     rak=clamp(1-Math.abs(sb-onskad)*1.8,0,1)*clamp(0.45+a.skankel*0.9,0,1);}
   mal.rakriktning=clamp(0.02+0.46*rak+0.26*mal.schvung+0.20*s.mjukhet-0.20*s.spanning,0,1);
   if(hhKval>0)mal.samling=clamp(s.skala.samling+hhKval*0.22*(0.5+0.7*h.utbildning),0,1);
   else if(hhKval<0)mal.samling=clamp(s.skala.samling+hhKval*0.4,0,1);
   else mal.samling=clamp(s.skala.samling-0.16,0,1);
  }
  // KÄNSLIGHET ÄR KONTRAST
  {const kontrast=0.78+0.85*h.kanslighet,PIVOT=0.44;
   for(const k of Skala.ORDER)if(k!=="samling")mal[k]=clamp(PIVOT+(mal[k]-PIVOT)*kontrast,0,1);
   const gain=0.55+0.95*h.kanslighet;
   const upp=K.BAS_STIGNING*gain, ner=K.BAS_FALL*gain*(1.35-0.70*h.forlatande);
   for(const k of Skala.ORDER)s.skala[k]=approach(s.skala[k],mal[k],upp,ner,dt);
   Skala.pyramid(s.skala);
  }
  s.steglangd=Gait.steglangd(h.kategori,s.gangart,s.skala.schvung,s.spanning);
  s.rang=clamp(s.rang+((s.mjukhet-0.55)*0.020-s.spanning*0.012)*dt,0,1);
  s._prev={...a};
  return s;
}

/* ROP och ridlararRop låg här: bildrutans lägsta tal på
   utbildningsskalan slogs upp i en replikbank och lästes upp var
   trettonde sekund. Det bytte ämne så fort den lägsta siffran bytte,
   och det är inte undervisning — det är en felrapport uppläst högt.
   Ridläraren bor numera i src/larare.js och håller ETT tema per
   lektion. Skala.svagaste finns kvar; den är en modellfråga och inte
   en pedagogisk. */

/* ── ApproachSolver ── */
const Approach={
  zon(steg,hojd){return clamp(0.50*steg+0.35*hojd,0.90,2.60);},
  los(avstand,steg,hojd){
    if(steg<=0)return{sprang:0,fel:0,kvalitet:0,mojlig:false,rad:"Du står still framför hindret."};
    const zon=this.zon(steg,hojd),eff=avstand-zon;
    if(eff<0)return{sprang:0,fel:-0.5,kvalitet:0,mojlig:false,rad:"För nära! Du red rakt in i hindret."};
    const n=Math.max(1,Math.round(eff/steg)),rest=eff-n*steg,fel=rest/steg;
    const kval=clamp(1-Math.abs(fel)/0.42,0,1),just=rest/n,mojlig=Math.abs(just)<=steg*0.22;
    let rad;
    if(Math.abs(fel)<0.08)rad=`Perfekt. ${n} språng och du är där.`;
    else if(rest>0)rad=mojlig?`Sträck ut — ${n} språng, ${Math.round(just*100)} cm mer per språng.`
      :`Du kommer långt. Rid på ordentligt.`;
    else rad=mojlig?`Vänta — ${n} språng, ta bort ${Math.round(-just*100)} cm per språng.`
      :`Du kommer för nära. Sitt still och låt henne lösa det.`;
    return{sprang:n,fel,kvalitet:kval,mojlig,rad};
  },
  kvalitet(losning,skala,spanning,dagsform){
    let q=0.46*losning.kvalitet+0.20*(skala.takt||0)+0.14*(skala.rakriktning||0)
      +0.12*(skala.kontakt||0)+0.08*(skala.schvung||0);
    q*=(1-0.35*spanning); q*=(0.70+0.30*dagsform);
    return clamp(q,0,1);
  },
  utfall(kval,hojd,hoppk,hoppl,maxh,rang,rng){
    if(hoppk<=0.001)return{resultat:"vagran",kommentar:"Den här hästen hoppar inte."};
    const bel=hojd/Math.max(maxh,0.20),over=Math.max(0,bel-1),dalig=1-kval;
    let pV=0.40*dalig*dalig*(1.45-hoppl)+0.55*(1-Math.exp(-2.2*over))-rang*0.10;
    pV=clamp(pV,0,0.85);
    let pR=(0.30*Math.pow(dalig,1.5)+0.95*(1-Math.exp(-3.2*over))+0.14*(1-hoppk))*(1-pV);
    pR=clamp(pR,0,0.95);
    const r=rng();
    if(r<pV)return{resultat:"vagran",kommentar:over>0?"Hindret var för högt för hästen."
      :"Hon läste inte hindret — inridningen gav inget att hoppa på."};
    if(r<pV+pR)return{resultat:"rivning",kommentar:kval<0.4?"Fel avstånd. Bommen följde med.":"Snuddade bara."};
    return{resultat:"felfritt",kommentar:kval>0.8?"Precis där du ville ha honom.":"Igenom."};
  },
  rng(seed){let s=seed%2147483647;if(s<=0)s+=2147483646;
    return()=>{s=(s*16807)%2147483647;return(s-1)/2147483646;};},
};

/* ── GroomingModel (utvärdering) ── */
function utvarderaSkotsel(sk,forlatande,stallro){
  const risker=[];
  let hovM=0,samst=1;for(const h of sk.hovar){hovM+=h;if(h<samst)samst=h;}
  hovM/=sk.hovar.length;
  if(samst<0.35)risker.push("sten_i_hoven");
  let gjordFel=0;
  if(sk.gjord<0.42){gjordFel=(0.42-sk.gjord)/0.42;if(sk.gjord<0.25)risker.push("sadeln_glider");}
  else if(sk.gjord>0.74)gjordFel=(sk.gjord-0.74)/0.26;
  const sadel=clamp(sk.sadellage*(1-0.55*gjordFel),0,1);
  if(sk.sadellage<0.4)risker.push("gar_inte_igenom_ryggen");
  if(sk.betsling<0.4)risker.push("skav_i_mungipan");
  if(sk.visitering<0.3)risker.push("missat_skav");
  const tid=Math.pow(clamp(sk.tid/240,0,1),0.6);
  let df=0.30*sk.ryktning+0.22*hovM+0.18*sadel+0.12*sk.betsling+0.08*sk.visitering+0.10*tid;
  df*=(0.80+0.20*stallro); df=clamp(0.25+0.75*df,0,1);
  df=clamp(df+(forlatande-0.5)*0.14,0,1);
  let omdome;
  if(risker.includes("skrammd_bakifran"))omdome="Du kom rakt bakifrån. Hon är på helspänn nu — gå fram där hon ser dig nästa gång, och säg något.";
  else if(risker.includes("gar_inte_igenom_ryggen"))omdome="Sadeln ligger på bogbladet. Lägg om den, annars kan han inte gå igenom ryggen.";
  else if(risker.includes("sadeln_glider"))omdome="Dra åt gjorden ett hål till innan du sitter upp.";
  else if(risker.includes("sten_i_hoven"))omdome="Kratsa hovarna ordentligt — alla fyra.";
  else if(risker.length)omdome="Visitera henne innan du sadlar. Mungipor och skav.";
  else if(df>0.82)omdome="Fint skött. Det syns på honom.";
  else if(df>0.62)omdome="Godkänt. Rykta lite noggrannare där sadeln ligger.";
  else omdome="Du hade bråttom idag. Det märks.";
  return{dagsform:df,sadellage:sadel,risker,omdome};
}

/* ── CourseJudge (bedömning A, låg klass) ── */
function domaRitt(handelser,tid,lagKlass){
  const r={hinderfel:0,tidsfel:0,totalfel:0,utesluten:false,anledning:null,
    olydnader:0,nedslag:0,tid,tillatenTid:180,protokoll:[]};
  const uteslut=v=>{if(!r.utesluten){r.utesluten=true;r.anledning=v;r.protokoll.push("UTESLUTEN — "+v);}};
  for(const h of handelser){
    if(r.utesluten)break;
    if(h.typ==="nedslag"){r.nedslag++;r.hinderfel+=4;
      r.protokoll.push(`Hinder ${h.hinder}: nedslag, 4 fel`);}
    else if(h.typ==="olydnad"){r.olydnader++;
      if(r.olydnader===1){r.hinderfel+=4;r.protokoll.push(`Hinder ${h.hinder}: första olydnaden, 4 fel`);}
      else if(r.olydnader===2){
        if(lagKlass){r.hinderfel+=8;r.protokoll.push(`Hinder ${h.hinder}: andra olydnaden, 8 fel — ritten fortsätter (låg klass)`);}
        else uteslut("andra olydnaden");}
      else uteslut("tredje olydnaden");}
    else if(h.typ==="avfallning")uteslut("avfallning");
    if(!r.utesluten&&r.hinderfel>16)uteslut("mer än 16 hinderfel");
  }
  if(!r.utesluten&&tid>r.tillatenTid)uteslut("överskriden tillåten tid");
  r.totalfel=r.hinderfel+r.tidsfel;
  if(!r.utesluten&&r.totalfel===0)r.protokoll.push(`Felfritt på ${tid.toFixed(1)} sekunder.`);
  return r;
}
