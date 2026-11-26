/* ══════════════════════════════════════════════════════════════════
   LJUDET — steg 8: anläggningen låter. Allt syntetiseras med Web
   Audio (inga filer, ingen CDN): hovslag med olika klang per
   underlag, fotsteg till fots, gnägg och fnysningar, fåglar på
   gården och domarklockan på tävlingsdagen.

   DEN LOOPADE BRUSAMBIENSEN ÄR AV sedan Tobias produkttest
   2026-09-06: ett filtrerat brusloop hördes som ett konstant hum, inte
   som ett stall. Maskineriet ligger kvar bakom `LJUD.ambiens` för den
   dag en riktig inspelning finns. Se flaggan nedan.
   M stänger av och på allt. Inget ljud är ett krav: spelet är
   detsamma med ljudet av.

   INGEN RIDLÄRARRÖST. Här fanns `ljudRost(text)`, som läste upp
   lärarens repliker med webbläsarens svenska talsyntes
   (`SpeechSynthesisUtterance`, `sv-SE`) medan man satt i sadeln.

   Tobias produktbeslut 2026-09-10 (issue #161): **det ska inte finnas
   någon röst som agerar ridlärare.** Funktionen, flaggan `LJUD.rost`
   och båda anropsställena är borta ur spelet — inte gömda bakom en
   avstängd flagga, för en avstängd flagga är en funktion som väntar på
   att slås på igen.

   Beslutet gäller ROSTEN, inte undervisningen: varje replik som
   tidigare lästes upp står kvar som skriven text i lärarytan. Det som
   togs bort var uppläsningen, inte innehållet.

   Ersätt den inte. Varken med inspelad röst, en annan talsyntes,
   Roblox egen uppläsning eller en AI-röst. `tools/rostgrind.mjs`
   faller om något av det kommer tillbaka i produktionskoden.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const LJUD={
  ctx:null, pa:true,
  /* ── AMBIENSEN ÄR AV SOM DEFAULT ────────────────────────────────
     Tobias produkttest 2026-09-06, blocker 4: den loopade syntetiska
     brusbädden hördes som ett konstant brus/hum så fort man rört
     tangentbordet. Ett filtrerat brusloop ÄR ett hum — den efterliknar
     inte stallets ljud, den lägger på en ton.

     Maskineriet står kvar orört bakom flaggan, så en riktig
     ambiensinspelning kan tändas här den dag det finns en. Att riva
     koden hade betytt att nästa försök börjar om från noll; att låta
     den ligga på hade betytt att previewn brummar. Diskreta ljud —
     hovslag, fotsteg, gnägg, fnys — är kvar, och M styr fortfarande
     allt ljud. */
  ambiens:false,
  master:null, ambGain:null, ambKalla:null, ambFilter:null, ambTyp:null,
  brus:null,
  hovMonster:null, hovFas:0, hovLage:0, gangAvstand:0,
  /* Rumsklangen (ljud-grind 0.9). `rum` är strömbrytaren: stängs den
     går allt torrt, som förut. */
  rum:true, torr:null, rumNod:{}, rumNu:null, kalla:null,
  gnaggT:14, stallT:5, fagelT:3,
};

/* Väcks av första gesten — webbläsare kräver det. */
function ljudInit(){
  if(LJUD.ctx)return;
  try{
    const AC=window.AudioContext||window.webkitAudioContext;
    if(!AC)return;
    LJUD.ctx=new AC();
    LJUD.master=LJUD.ctx.createGain();
    LJUD.master.gain.value=0.5;
    LJUD.master.connect(LJUD.ctx.destination);
    LJUD.ambGain=LJUD.ctx.createGain();
    LJUD.ambGain.gain.value=0;
    LJUD.ambGain.connect(LJUD.master);
    ljudByggRum(LJUD.ctx);
    // brunt brus som råvara för allt som susar
    const n=LJUD.ctx.sampleRate*2, buf=LJUD.ctx.createBuffer(1,n,LJUD.ctx.sampleRate);
    const d=buf.getChannelData(0); let v=0;
    for(let i=0;i<n;i++){v=(v+(Math.random()*2-1)*0.02)*0.985;d[i]=v*8;}
    LJUD.brus=buf;
  }catch(_){LJUD.ctx=null;}
}
/* ── RUMMET (ljud-grind 0.9, F4) ───────────────────────────────────
   Förut kopplades varje ljud rakt till huvudvolymen: torrt, i mitten,
   på fast nivå. Ridhuset, stallet och gården lät identiskt.

   Nu går varje ljud ut genom EN väg (ljudUt):
     · torrt till `LJUD.torr`,
     · och en sändning till rummets efterklang.
   Tre rum: HALLEN (ridhuset — stort, hård plåt, lång och mörk
   efterklang), STALLET (trä, spån och hästar — kort och ljus) och UTE,
   som inte har någon: sändningen är noll.

   IMPULSERNA ÄR GENERERADE, INTE INSPELADE. Avklingande brus med en
   längd och en mörkhet per rum. Talen nedan är uttalade [ANTAGANDE] —
   de är inte uppmätta i UBRF:s ridhus och inte trimmade på gehör, för
   det kan ingen kod göra. De ska ersättas av en riktig klappinspelning
   (G7, Batch 6.6); då byts bara bufferten, inte kopplingen.

   Noderna byggs EN gång här. Inget ljud skapar en egen efterklang. */
const LJUD_RUM={
  hall: {sek:1.6,  mork:0.30, sand:0.30},
  stall:{sek:0.35, mork:0.85, sand:0.18},
};
function ljudImpuls(c,sek,mork){
  const n=Math.max(1,Math.round(sek*c.sampleRate));
  const buf=c.createBuffer(2,n,c.sampleRate);
  for(let k=0;k<2;k++){
    const d=buf.getChannelData(k); let lp=0;
    for(let i=0;i<n;i++){
      /* −60 dB vid `sek`; `mork` är ett enpoligt lågpass (lägre = dovare). */
      lp+=((Math.random()*2-1)-lp)*mork;
      d[i]=lp*Math.exp(-6.9*i/n);
    }
  }
  return buf;
}
function ljudByggRum(c){
  LJUD.torr=c.createGain();
  LJUD.torr.connect(LJUD.master);
  LJUD.rumNod={}; LJUD.rumNu=null;
  if(typeof c.createConvolver!=="function")return;     // äldre webbläsare: torrt
  for(const namn in LJUD_RUM){
    const R=LJUD_RUM[namn];
    const sand=c.createGain(); sand.gain.value=0;
    const eko=c.createConvolver(); eko.buffer=ljudImpuls(c,R.sek,R.mork);
    sand.connect(eko); eko.connect(LJUD.master);
    LJUD.rumNod[namn]={sand,eko};
  }
}
/* Vilket rum hon är i, ur samma scenvillkor som resten av filen. */
function ljudRumFor(scen,plats){
  if(scen==="stallinne")return "stall";
  if(scen==="ridhusinne")return "hall";
  if((scen==="lektion"||scen==="bana")&&plats==="ridhus")return "hall";
  return null;
}
/* Byter rum. Sändningarna tonas över 0,3 s på ljudklockan, så att ett
   scenbyte inte knäpper och en efterklang som redan ljuder får klinga ut. */
function ljudRum(namn){
  if(!LJUD.ctx)return;
  if(!LJUD.rum)namn=null;
  if(namn===LJUD.rumNu)return;
  LJUD.rumNu=namn;
  const t=LJUD.ctx.currentTime;
  for(const n in LJUD.rumNod){
    const g=LJUD.rumNod[n].sand.gain, mal=n===namn?LJUD_RUM[n].sand:0;
    if(typeof g.cancelScheduledValues==="function"){
      g.cancelScheduledValues(t); g.setValueAtTime(g.value,t); g.linearRampToValueAtTime(mal,t+0.3);
    }
    g.value=mal;
  }
}
/* VAR ETT LJUD KOMMER IFRÅN. Lyssnaren står i (lx, ly) och ser åt
   `rikt`; källan står i (kx, ky). Panoreringen är källans läge längs
   lyssnarens högervektor — (sin rikt, −cos rikt), samma kartregel som
   gangVarv och GL.kamera — och styrkan avtar med avståndet. Nära inpå
   dras panoreringen mot mitten: en häst en halv meter bort låter inte i
   ena örat. Ren funktion. [ANTAGANDE]: 6 m till halv styrka. */
function ljudPlacera(lx,ly,rikt,kx,ky){
  const dx=kx-lx, dy=ky-ly, d=Math.hypot(dx,dy);
  const hoger=(dx*Math.sin(rikt)-dy*Math.cos(rikt))/Math.max(d,1.5);
  return {pan:Math.max(-1,Math.min(1,hoger))*0.85, styrka:Math.max(0.15,1/(1+d/6))};
}
/* ENDA VÄGEN UT för ett ljud i världen. `LJUD.kalla` ({pan, styrka})
   sätts av den som vet var ljudet hör hemma; utan den ligger ljudet i
   mitten — egna hovslag och fotsteg. Saknas StereoPannerNode (äldre
   Safari) spelas ljudet opanorerat, aldrig tyst. */
function ljudUt(nod){
  const c=LJUD.ctx, k=LJUD.kalla;
  let ut=nod;
  if(k){
    const g=c.createGain(); g.gain.value=k.styrka; nod.connect(g); ut=g;
    if(typeof c.createStereoPanner==="function"){
      const p=c.createStereoPanner(); p.pan.value=k.pan; g.connect(p); ut=p;
    }
  }
  ut.connect(LJUD.torr);
  if(LJUD.rum)for(const n in LJUD.rumNod)ut.connect(LJUD.rumNod[n].sand);
}

/* ── UPPLÅSNING OCH AVBROTT (ljud-grind 0.7, F2) ───────────────────
   Förut väcktes ljudet bara på `pointerdown` och `keydown`. Det räcker
   inte på iPhone: Safari räknar inte `pointerdown` som en gest som får
   starta ljud — det gör `touchend`, `pointerup` och `click`. Resultatet
   var ett spel som var tyst på telefon tills man råkade trycka på en
   tangent, vilket ingen gör på en telefon.

   Ljudet återupptogs inte heller efter ett avbrott. iOS ställer
   kontexten i `interrupted` vid ett samtal, ett låst lås eller en
   bakgrundad flik, och den kommer inte tillbaka av sig själv: man måste
   be om det när sidan syns igen (`visibilitychange`, och `pageshow` för
   en sida som hämtas ur bakåt-cachen).

   EN kontext, alltid: ljudInit skapar den en gång och alla vägar hit
   återanvänder den.

   INTE AVGJORT HÄR: om spelljudet ska lyda telefonens ljudlös-knapp.
   Web Audio gör det av sig självt på iOS, och den här koden försöker
   inte kringgå det. Vill Tobias ha det annorlunda är det ett eget
   beslut. */
function ljudVack(){
  ljudInit();
  const c=LJUD.ctx;
  if(c&&c.state!=="running"&&c.state!=="closed"&&typeof c.resume==="function"){
    const p=c.resume(); if(p&&typeof p.catch==="function")p.catch(()=>{});
  }
}
for(const typ of ["pointerdown","pointerup","touchend","click"])
  addEventListener(typ,ljudVack,{passive:true});
addEventListener("keydown",ljudVack);
/* Tillbaka efter ett avbrott: bara om ljudet redan väckts av en gest —
   en sida som aldrig rörts får inte börja låta för att den blev synlig. */
function ljudAteruppta(){
  if(!LJUD.ctx)return;
  if(typeof document!=="undefined"&&document.visibilityState==="hidden")return;
  ljudVack();
}
if(typeof document!=="undefined"&&document.addEventListener)
  document.addEventListener("visibilitychange",ljudAteruppta);
addEventListener("pageshow",ljudAteruppta);

function ljudToggle(){
  LJUD.pa=!LJUD.pa;
  /* Här stod också ett `speechSynthesis.cancel()`, som tystade
     ridlärarrösten när ljudet slogs av. Rösten finns inte längre — se
     filhuvudet — så det finns inget att avbryta. */
  if(!LJUD.pa)ljudAmbiens(null);
  if(typeof saga==="function")saga(LJUD.pa?"Ljudet är på. M stänger av.":"Ljudet är av.",2);
}

/* En kort brusstöt genom filter — grunden för slag och steg. */
/* `nar` är en tidpunkt på ljudklockan (AudioContext.currentTime). Utan
   den spelas ljudet nu. */
function ljudStot(freq,typ,tid,vol,startFreq,nar){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=nar>c.currentTime?nar:c.currentTime;
  const src=c.createBufferSource();src.buffer=LJUD.brus;
  src.playbackRate.value=0.8+Math.random()*0.4;
  const f=c.createBiquadFilter();f.type=typ;f.frequency.value=startFreq||freq;
  if(startFreq)f.frequency.exponentialRampToValueAtTime(Math.max(freq,30),t+tid);
  f.Q.value=1.1;
  const g=c.createGain();
  g.gain.setValueAtTime(vol,t);
  g.gain.exponentialRampToValueAtTime(0.001,t+tid);
  src.connect(f);f.connect(g);ljudUt(g);
  src.start(t);src.stop(t+tid+0.05);
}
/* EN REN TON — gränssnittets signaler (ljud-grind 0.7, F2).
   De ställen som ville ha en ton anropade brusstöten (ljudStot) med
   «sine» som filtertyp. Det är en vågform för en oscillator, inte en
   filtertyp: filtret
   behöll sitt lågpass och det som hördes var en brusstöt, lika för 240
   och 990 Hz. Rätt och fel svar lät alltså likadant.

   Det här är en riktig sinuston med mjuk in- och uttoning (ingen knäpp),
   på ljudklockan som allt annat. */
function ljudTon(freq,tid,vol,nar){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=nar>c.currentTime?nar:c.currentTime;
  const o=c.createOscillator();o.type="sine";
  o.frequency.setValueAtTime(freq,t);
  const g=c.createGain();
  g.gain.setValueAtTime(0.0001,t);
  g.gain.exponentialRampToValueAtTime(Math.max(vol,0.0002),t+0.012);
  g.gain.exponentialRampToValueAtTime(0.0001,t+tid);
  /* TORRT: gränssnittets toner är inte i rummet. En knapp ska inte eka. */
  o.connect(g);g.connect(LJUD.torr);
  o.start(t);o.stop(t+tid+0.05);
}
/* Dov puls — hovens tyngd. */
function ljudPulsslag(freq,tid,vol,nar){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=nar>c.currentTime?nar:c.currentTime;
  const o=c.createOscillator();o.type="sine";
  o.frequency.setValueAtTime(freq,t);
  o.frequency.exponentialRampToValueAtTime(Math.max(freq*0.45,25),t+tid);
  const g=c.createGain();
  g.gain.setValueAtTime(vol,t);
  g.gain.exponentialRampToValueAtTime(0.001,t+tid);
  o.connect(g);ljudUt(g);
  o.start(t);o.stop(t+tid+0.05);
}

/* ── UNDERLAGENS KLANG (ljud-grind 0.8, F3) ────────────────────────
   En rad per ytnyckel ur ytaVid (src/site.js). `hov` är pulsen (frekvens,
   längd, styrka) och bruset över den (frekvens, filter, längd, styrka,
   startfrekvens); `fot` är ett fotsteg (samma brusfält).

   Fiber, grus och det våta gruset har EXAKT de värden de hade förut, och
   stallets fotsteg är det gamla «sten»: ridhuset, gården och stallgången
   låter som de gjorde. Det nya är att sand, gräs, asfalt, betong och spån
   inte längre låter som grus.

   Klangerna är syntetiska och stiliserade [ANTAGANDE] — mjukt och dovt
   för det som ger efter, kort och ljust för det som är hårt. De ska
   ersättas av riktiga inspelningar (Batch 6.6). "okand" är grus, alltså
   det som lät förut där inget underlag är belagt. */
const LJUD_YTA={
  fiber:    {hov:[95,0.13,0.20, 300,"lowpass",0.09,0.10],        fot:[380,"lowpass",0.07,0.05]},
  sand:     {hov:[88,0.13,0.18, 420,"lowpass",0.10,0.11],        fot:[440,"lowpass",0.08,0.055]},
  span:     {hov:[78,0.14,0.14, 240,"lowpass",0.10,0.06],        fot:[280,"lowpass",0.08,0.035]},
  gras:     {hov:[80,0.14,0.15, 260,"lowpass",0.10,0.07],        fot:[300,"lowpass",0.08,0.04]},
  aker:     {hov:[76,0.15,0.15, 230,"lowpass",0.11,0.07],        fot:[270,"lowpass",0.09,0.04]},
  grus:     {hov:[110,0.10,0.16, 1200,"bandpass",0.08,0.14,1900], fot:[500,"lowpass",0.07,0.06]},
  gatsten:  {hov:[125,0.08,0.16, 1300,"bandpass",0.07,0.15,2100], fot:[900,"bandpass",0.06,0.07,1400]},
  betong:   {hov:[130,0.08,0.15, 1500,"bandpass",0.06,0.15,2300], fot:[850,"bandpass",0.06,0.065,1300]},
  asfalt:   {hov:[140,0.07,0.15, 1800,"bandpass",0.05,0.16,2600], fot:[1000,"bandpass",0.05,0.06,1500]},
};
LJUD_YTA.okand=LJUD_YTA.grus;
/* Äldre namn som anropare kan bära med sig. */
LJUD_YTA.sten=LJUD_YTA.gatsten;
/* Det våta gruset, som det lät förut. */
const LJUD_VATT_GRUS=[75,0.16,0.18, 1500,"bandpass",0.12,0.09,2600];
/* Vilka ytor regnet når. Inomhus och i ridhuset är det torrt. */
const LJUD_UTE=new Set(["grus","sand","gras","aker","asfalt","betong","okand"]);

/* Hovslag i sadeln: klangen följer underlaget. `vat` lägger regnet
   OVANPÅ underlaget i stället för att ersätta det: vått grus låter som
   förut, och våt sand, vått gräs och våt asfalt behåller sin egen klang
   under plasket. */
function ljudHov(underlag,tung,nar,vat){
  const v=tung?1.25:1;
  if(underlag==="vat"){underlag="grus";vat=true;}       // gamla anropare
  const y=LJUD_YTA[underlag]||LJUD_YTA.okand;
  const blott=vat&&LJUD_UTE.has(underlag in LJUD_YTA?underlag:"okand");
  const h=blott&&(y===LJUD_YTA.grus)?LJUD_VATT_GRUS:y.hov;
  ljudPulsslag(h[0],h[1],h[2]*v,nar);
  ljudStot(h[3],h[4],h[5],h[6]*v,h[7],nar);
  if(blott&&h!==LJUD_VATT_GRUS)ljudStot(1500,"bandpass",0.12,0.05*v,2600,nar);
}
/* ── HOVSLAGENS TAKT (ljud-grind 0.6, F1) ──────────────────────────
   Anropas varje bildruta under ritt. Förut delades fasen jämnt i
   `beats` delar: skritten fick TVÅ slag per cykel (den har fyra) och
   galoppen tre LIKA långa (den har tre slag och en paus). Ljudet hade
   ingen koppling till vilka hovar som faktiskt sattes i.

   Nu läser ljudet samma rad i GANGFAS som benen, med samma fas: ett slag
   hörs när en isättning passeras, och ett diagonalpar är ETT slag. Port
   av Roblox SoundController.

     · Läget bärs som ett LÖPANDE tal (cykler + fas), så att flera slag i
       en lång bildruta räknas i ordning och en faswrap inte tappar något.
     · Byter raden — halt, skritt, trav, galopp eller galoppens sida —
       SEEDAS läget om utan att slå. Inga dubbla eller kvarhängande steg.
     · Slagen läggs på LJUDKLOCKAN, inte på bildrutan: ett slag som
       passerades mitt i bildrutan spelas lika långt in i nästa. Hela
       takten får då en bildrutas fördröjning, men avstånden mellan
       slagen blir tabellens — annars hackar rytmen i bildrutornas takt,
       och det hörs tydligast i en galopp vid låg bildfrekvens.

   Betoningen på galoppens första slag är kvar som förut [ANTAGANDE]. */
function ljudRittSteg(fas,gangart,underlag,fattning,dt,vat){
  const namn=gangMonsterNamn(gangart,fattning), m=namn&&GANGFAS[namn];
  if(!m){LJUD.hovMonster=null;LJUD.hovFas=fas;return;}
  let steg=(fas-(LJUD.hovFas||0))%1; if(steg<0)steg+=1;
  LJUD.hovFas=fas;
  if(LJUD.hovMonster!==namn){LJUD.hovMonster=namn;LJUD.hovLage=fas;return;}
  const fran=LJUD.hovLage, till=fran+steg;
  LJUD.hovLage=till>1e6?till%1:till;
  if(!(steg>0))return;
  const nu=LJUD.ctx?LJUD.ctx.currentTime:0, ruta=dt>0?Math.min(dt,0.1):0;
  for(const sl of gangPasserade(m,fran,till))
    ljudHov(underlag,m.takt===3&&sl.fas===0,nu+ruta*(sl.lage-fran)/steg,vat);
}
/* Fotsteg till fots: ett steg var 0,8 m, med underlagets klang. */
function ljudFotsteg(avstand,underlag){
  LJUD.gangAvstand+=avstand;
  if(LJUD.gangAvstand>=0.8){
    LJUD.gangAvstand=0;
    const f=(LJUD_YTA[underlag]||LJUD_YTA.okand).fot;
    ljudStot(f[0],f[1],f[2],f[3],f[4]);
  }
}

/* Gnägg: fallande ton med vibrato — stiliserat men omisskännligt. */
function ljudGnagg(){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=c.currentTime,dur=1.0+Math.random()*0.3;
  const o=c.createOscillator();o.type="sawtooth";
  o.frequency.setValueAtTime(760+Math.random()*160,t);
  o.frequency.exponentialRampToValueAtTime(320,t+dur);
  const vib=c.createOscillator();vib.frequency.value=24;
  const vibG=c.createGain();vibG.gain.setValueAtTime(70,t);
  vibG.gain.linearRampToValueAtTime(12,t+dur);
  vib.connect(vibG);vibG.connect(o.frequency);
  const f=c.createBiquadFilter();f.type="bandpass";f.frequency.value=900;f.Q.value=0.8;
  const g=c.createGain();
  g.gain.setValueAtTime(0.001,t);
  g.gain.exponentialRampToValueAtTime(0.16,t+0.08);
  g.gain.exponentialRampToValueAtTime(0.001,t+dur);
  o.connect(f);f.connect(g);ljudUt(g);
  o.start(t);vib.start(t);o.stop(t+dur+0.1);vib.stop(t+dur+0.1);
}
/* Fnysning och stamp — stallets småprat. */
function ljudFnys(){
  ljudStot(420,"bandpass",0.28,0.09,700);
  /* Den andra stöten kommer från SAMMA häst, även om pulsen hunnit
     släppa källan däremellan. */
  const k=LJUD.kalla;
  setTimeout(()=>{const f=LJUD.kalla;LJUD.kalla=k;ljudStot(380,"bandpass",0.18,0.06,600);LJUD.kalla=f;},140);
}
function ljudStamp(){ljudPulsslag(70,0.18,0.16);}
/* Fågelkvitter: två snabba fallande blip. */
function ljudFagel(){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx;let t=c.currentTime;
  for(let i=0;i<2+Math.floor(Math.random()*2);i++){
    const o=c.createOscillator();o.type="sine";
    const f0=2600+Math.random()*900;
    o.frequency.setValueAtTime(f0,t);
    o.frequency.exponentialRampToValueAtTime(f0*0.72,t+0.09);
    const g=c.createGain();
    g.gain.setValueAtTime(0.001,t);
    g.gain.exponentialRampToValueAtTime(0.05,t+0.02);
    g.gain.exponentialRampToValueAtTime(0.001,t+0.1);
    o.connect(g);ljudUt(g);
    o.start(t);o.stop(t+0.12);
    t+=0.13+Math.random()*0.1;
  }
}
/* Domarklockan: slagen metall, tre deltoner som klingar av. */
function ljudKlocka(){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=c.currentTime;
  for(const[fr,vol]of[[880,0.16],[1180,0.09],[1760,0.05]]){
    const o=c.createOscillator();o.type="sine";o.frequency.value=fr*(1+Math.random()*0.01);
    const g=c.createGain();
    g.gain.setValueAtTime(vol,t);
    g.gain.exponentialRampToValueAtTime(0.001,t+1.6);
    o.connect(g);ljudUt(g);
    o.start(t);o.stop(t+1.7);
  }
}

/* Ambiensen: en fortlöpande brusbädd per plats. */
function ljudAmbiens(typ){
  if(!LJUD.ctx)return;
  if(typ===LJUD.ambTyp)return;
  LJUD.ambTyp=typ;
  if(LJUD.ambKalla){try{LJUD.ambKalla.stop();}catch(_){}LJUD.ambKalla=null;}
  if(!typ||!LJUD.pa){if(LJUD.ambGain)LJUD.ambGain.gain.value=0;return;}
  const c=LJUD.ctx;
  const src=c.createBufferSource();src.buffer=LJUD.brus;src.loop=true;
  const f=c.createBiquadFilter();
  let vol;
  if(typ==="regn"){f.type="bandpass";f.frequency.value=2400;f.Q.value=0.4;vol=0.10;src.playbackRate.value=2.5;}
  else if(typ==="stall"){f.type="lowpass";f.frequency.value=320;vol=0.05;}
  else{f.type="lowpass";f.frequency.value=520;vol=0.035;src.playbackRate.value=0.7;} // gard: vind
  LJUD.ambFilter=f;
  src.connect(f);f.connect(LJUD.ambGain);
  LJUD.ambGain.gain.cancelScheduledValues(c.currentTime);
  LJUD.ambGain.gain.setValueAtTime(LJUD.ambGain.gain.value,c.currentTime);
  LJUD.ambGain.gain.linearRampToValueAtTime(vol,c.currentTime+1.2);
  src.start();
  LJUD.ambKalla=src;
}

/* Hur många hästar spelaren kan SE där hon står: boxarnas hästar i
   stallet, hagarnas på gården. Samma data som ritar dem (boxHast,
   ANL.hagar) — ett fnys utan häst vore ett ljud utan källa. */
function ljudSynligaHastar(){
  if(G.scen==="stallinne"&&typeof STALLINNE!=="undefined"&&typeof boxHast==="function"){
    let n=0;
    for(const k in STALLINNE.boxar)for(const id of STALLINNE.boxar[k]||[])if(boxHast(id))n++;
    return n;
  }
  if(G.scen==="gard"&&typeof ANL!=="undefined"){
    let n=0; for(const hg of ANL.hagar||[])n+=(hg.hastar||[]).length; return n;
  }
  return 0;
}

/* EN av de synliga hästarna, och var hon står — ljudet ska komma från
   en häst, inte från mitten av huvudet. Boxens mitt i stallet, hagens
   mitt på gården. Ger null när ingen häst syns eller lyssnarens läge är
   okänt; då ligger ljudet i mitten. */
function ljudKallaHast(){
  if(typeof VD==="undefined"||!VD)return null;
  const lage=[];
  if(G.scen==="stallinne"&&typeof STALLINNE!=="undefined"&&typeof boxHast==="function"){
    const S=STALLINNE;
    for(const rad of S.rader||[]){
      const lista=S.boxar[rad.id]||[];
      for(let i=0;i<lista.length;i++)if(boxHast(lista[i]))
        lage.push([rad.x0+rad.djup/2, S.boxStartY+(i+0.5)*S.boxB]);
    }
  }else if(G.scen==="gard"&&typeof ANL!=="undefined"){
    for(const hg of ANL.hagar||[])if((hg.hastar||[]).length&&hg.rekt)
      lage.push([hg.rekt.x+hg.rekt.w/2, hg.rekt.y+hg.rekt.h/2]);
  }
  if(!lage.length)return null;
  const p=lage[Math.floor(Math.random()*lage.length)];
  return ljudPlacera(VD.px,VD.py,VD.rikt||0,p[0],p[1]);
}

/* Pulsen: väljer ambiens efter scen och strör ut engångsljud.

   ENGÅNGSLJUDEN HÄNGER INTE LÄNGRE PÅ BRUSBÄDDEN (ljud-grind 0.8, F3).
   Bädden är avstängd med flit (se LJUD.ambiens), och fnys, stamp, gnägg
   och fågel låg bakom bäddens `typ` — de spelades alltså aldrig: noll
   händelser på tjugo sekunder, i varje scen. Nu väljs de ur scenen. Bädden
   är fortfarande AV.

   Varje ljud har en synlig källa: stalljuden kräver en häst i en box,
   gnägget på gården en häst i en hage. Fågeln sjunger inte i regn.
   Ridhusets inre har inga engångsljud — där står inga hästar som inte
   rids. */
function ljudPuls(dt){
  if(!LJUD.ctx)return;
  const regn=G.vader&&G.vader.typ==="regn";
  const ute=(G.scen==="lektion"||G.scen==="bana")&&G.plats!=="ridhus";
  const plats=G.scen==="stallinne"?"stall":(G.scen==="gard"||ute)?"gard":null;
  let typ=null;
  /* Brusbädden begärs bara om den uttryckligen är påslagen. Beräkningen
     nedan står kvar så att platsvalet inte hinner ruttna medan flaggan
     är av — den är en rad att tända igen, inte en funktion att skriva om. */
  if(!LJUD.pa||!LJUD.ambiens)typ=null;
  else if(G.scen==="stallinne")typ="stall";
  else if(G.scen==="gard"||ute)typ=regn?"regn":"gard";
  else if(G.scen==="ridhusinne")typ="stall";
  ljudAmbiens(typ);
  ljudRum(ljudRumFor(G.scen,G.plats));
  if(!LJUD.pa||!plats)return;
  const hastar=ljudSynligaHastar();
  if(plats==="stall"&&hastar>0){
    LJUD.stallT-=dt;
    if(LJUD.stallT<=0){
      LJUD.stallT=4+Math.random()*8;
      const r=Math.random();
      LJUD.kalla=ljudKallaHast();
      if(r<0.35)ljudFnys(); else if(r<0.6)ljudStamp();
      else if(r<0.72)ljudGnagg();
      else ljudStot(2200,"bandpass",0.1,0.04,3200);   // grimskaft mot galler
      LJUD.kalla=null;
    }
  }
  if(plats==="gard"){
    if(!regn){
      LJUD.fagelT-=dt;
      if(LJUD.fagelT<=0){LJUD.fagelT=3+Math.random()*7;ljudFagel();}
    }
    if(hastar>0){
      LJUD.gnaggT-=dt;
      if(LJUD.gnaggT<=0){LJUD.gnaggT=18+Math.random()*22;
        LJUD.kalla=ljudKallaHast();ljudGnagg();LJUD.kalla=null;}
    }
  }
}
