/* ══════════════════════════════════════════════════════════════════
   LJUDET — steg 8: anläggningen låter. Allt syntetiseras med Web
   Audio (inga filer, ingen CDN): hovslag med olika klang per
   underlag, fotsteg till fots, gnägg och fnysningar, stallets
   ambiens, vind och fåglar på gården, regn på plåttaken och
   domarklockan på tävlingsdagen. Ridlärarens röst talar genom
   webbläsarens svenska talsyntes under lektionen.
   M stänger av och på allt. Inget ljud är ett krav: spelet är
   detsamma med ljudet av.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const LJUD={
  ctx:null, pa:true, rost:true,
  master:null, ambGain:null, ambKalla:null, ambFilter:null, ambTyp:null,
  brus:null,
  hovBeat:-1, gangAvstand:0,
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
    // brunt brus som råvara för allt som susar
    const n=LJUD.ctx.sampleRate*2, buf=LJUD.ctx.createBuffer(1,n,LJUD.ctx.sampleRate);
    const d=buf.getChannelData(0); let v=0;
    for(let i=0;i<n;i++){v=(v+(Math.random()*2-1)*0.02)*0.985;d[i]=v*8;}
    LJUD.brus=buf;
  }catch(_){LJUD.ctx=null;}
}
addEventListener("pointerdown",()=>{ljudInit();if(LJUD.ctx&&LJUD.ctx.state==="suspended")LJUD.ctx.resume().catch(()=>{});},{passive:true});
addEventListener("keydown",()=>{ljudInit();if(LJUD.ctx&&LJUD.ctx.state==="suspended")LJUD.ctx.resume().catch(()=>{});});

function ljudToggle(){
  LJUD.pa=!LJUD.pa;
  if(!LJUD.pa){
    ljudAmbiens(null);
    try{if("speechSynthesis"in window)speechSynthesis.cancel();}catch(_){}
  }
  if(typeof saga==="function")saga(LJUD.pa?"Ljudet är på. M stänger av.":"Ljudet är av.",2);
}

/* En kort brusstöt genom filter — grunden för slag och steg. */
function ljudStot(freq,typ,tid,vol,startFreq){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=c.currentTime;
  const src=c.createBufferSource();src.buffer=LJUD.brus;
  src.playbackRate.value=0.8+Math.random()*0.4;
  const f=c.createBiquadFilter();f.type=typ;f.frequency.value=startFreq||freq;
  if(startFreq)f.frequency.exponentialRampToValueAtTime(Math.max(freq,30),t+tid);
  f.Q.value=1.1;
  const g=c.createGain();
  g.gain.setValueAtTime(vol,t);
  g.gain.exponentialRampToValueAtTime(0.001,t+tid);
  src.connect(f);f.connect(g);g.connect(LJUD.master);
  src.start(t);src.stop(t+tid+0.05);
}
/* Dov puls — hovens tyngd. */
function ljudPulsslag(freq,tid,vol){
  if(!LJUD.ctx||!LJUD.pa)return;
  const c=LJUD.ctx,t=c.currentTime;
  const o=c.createOscillator();o.type="sine";
  o.frequency.setValueAtTime(freq,t);
  o.frequency.exponentialRampToValueAtTime(Math.max(freq*0.45,25),t+tid);
  const g=c.createGain();
  g.gain.setValueAtTime(vol,t);
  g.gain.exponentialRampToValueAtTime(0.001,t+tid);
  o.connect(g);g.connect(LJUD.master);
  o.start(t);o.stop(t+tid+0.05);
}

/* Hovslag i sadeln: klangen följer underlaget. */
function ljudHov(underlag,tung){
  const v=tung?1.25:1;
  if(underlag==="fiber"){ ljudPulsslag(95,0.13,0.20*v); ljudStot(300,"lowpass",0.09,0.10*v); }
  else if(underlag==="vat"){ ljudPulsslag(75,0.16,0.18*v); ljudStot(1500,"bandpass",0.12,0.09*v,2600); }
  else { ljudPulsslag(110,0.10,0.16*v); ljudStot(1200,"bandpass",0.08,0.14*v,1900); }
}
/* Anropas varje bildruta under ritt: slår när gångartsfasen passerar taktslagen. */
function ljudRittSteg(fas,gangart,underlag){
  const beats={skritt:2,trav:2,galopp:3,halt:0}[gangart]||0;
  if(!beats){LJUD.hovBeat=-1;return;}
  const b=Math.floor(fas*beats);
  if(b!==LJUD.hovBeat){LJUD.hovBeat=b;ljudHov(underlag,gangart==="galopp"&&b===0);}
}
/* Fotsteg till fots: ett steg var 0,8 m. */
function ljudFotsteg(avstand,underlag){
  LJUD.gangAvstand+=avstand;
  if(LJUD.gangAvstand>=0.8){
    LJUD.gangAvstand=0;
    if(underlag==="sten")ljudStot(900,"bandpass",0.06,0.07,1400);
    else ljudStot(500,"lowpass",0.07,0.06);
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
  o.connect(f);f.connect(g);g.connect(LJUD.master);
  o.start(t);vib.start(t);o.stop(t+dur+0.1);vib.stop(t+dur+0.1);
}
/* Fnysning och stamp — stallets småprat. */
function ljudFnys(){
  ljudStot(420,"bandpass",0.28,0.09,700);
  setTimeout(()=>ljudStot(380,"bandpass",0.18,0.06,600),140);
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
    o.connect(g);g.connect(LJUD.master);
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
    o.connect(g);g.connect(LJUD.master);
    o.start(t);o.stop(t+1.7);
  }
}

/* Ridlärarens röst — webbläsarens svenska talsyntes, bara i sadeln. */
function ljudRost(text){
  if(!LJUD.pa||!LJUD.rost)return;
  if(!(G.scen==="lektion"||G.scen==="bana"))return;
  try{
    if(!("speechSynthesis"in window))return;
    speechSynthesis.cancel();
    const u=new SpeechSynthesisUtterance(text);
    /* Varje ledare har sin egen röst: Sofie ljus och snabb, Bengt mörk
       och långsam. Samma talsyntes, olika människor. */
    const led=(typeof dagensLedare==="function")?dagensLedare():null;
    u.lang="sv-SE";u.rate=led?led.rost.rate:1.04;u.pitch=led?led.rost.pitch:1.0;u.volume=0.85;
    const sv=speechSynthesis.getVoices().find(v=>v.lang&&v.lang.startsWith("sv"));
    if(sv)u.voice=sv;
    speechSynthesis.speak(u);
  }catch(_){}
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

/* Pulsen: väljer ambiens efter scen och strör ut engångsljud. */
function ljudPuls(dt){
  if(!LJUD.ctx)return;
  const regn=G.vader&&G.vader.typ==="regn";
  const ute=(G.scen==="lektion"||G.scen==="bana")&&G.plats!=="ridhus";
  let typ=null;
  if(!LJUD.pa)typ=null;
  else if(G.scen==="stallinne")typ="stall";
  else if(G.scen==="gard"||ute)typ=regn?"regn":"gard";
  else if(G.scen==="ridhusinne")typ="stall";
  ljudAmbiens(typ);
  if(!LJUD.pa)return;
  if(typ==="stall"){
    LJUD.stallT-=dt;
    if(LJUD.stallT<=0){
      LJUD.stallT=4+Math.random()*8;
      const r=Math.random();
      if(r<0.35)ljudFnys(); else if(r<0.6)ljudStamp();
      else if(r<0.72)ljudGnagg();
      else ljudStot(2200,"bandpass",0.1,0.04,3200);   // grimskaft mot galler
    }
  }
  if(typ==="gard"){
    LJUD.fagelT-=dt;
    if(LJUD.fagelT<=0){LJUD.fagelT=3+Math.random()*7;ljudFagel();}
    LJUD.gnaggT-=dt;
    if(LJUD.gnaggT<=0){LJUD.gnaggT=18+Math.random()*22;ljudGnagg();}
  }
}
