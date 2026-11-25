/* P0 — inputkänsla. Endast spelarens avsikt formas här.
   Hästens fysik, gångarter, kurvaturtak och bedömning ändras inte. */
"use strict";
const InputFeel = Object.freeze({
  WALK: Object.freeze({turn:3.0, accel:5.5, brake:9.0, tau:0.12, dead:0.12}),
  /* D3 (ridmekanik-grind 0.3): digitalGain (0,42) var en FAST nivå för
     tangentbordsstyrning, oavsett hur länge tangenten hölls — en 10 m
     volt går inte att rida på 42 % av full styrning, hur länge man än
     håller A/D, eftersom kurvaturtaket (kappaTak i src/game.js) aldrig
     nås. holdThreshold/holdRampTau lägger till trappningen: ett kort
     tryck (under holdThreshold) ger fortfarande bara digitalGain — en
     liten korrigering, precis som förut — men ett tryck som HÅLLS
     trappar upp mot full styrka. [ANTAGANDE] Exakt ramptid är
     designintention (DERIVED), inte en enhetsmätning — se
     tools/control-feel-test.mjs. */
  RIDE: Object.freeze({digitalGain:0.42, tau:0.16, release:0.10,
    holdThreshold:0.3, holdRampTau:0.25}),
  axis(v,target,dt,tau){
    const t=Math.max(0,Number.isFinite(dt)?dt:0);
    const goal=Number.isFinite(target)?Math.max(-1,Math.min(1,target)):0;
    return v+(goal-v)*(1-Math.exp(-t/tau));
  },
  walk(x,y,dt,state,analog=false){
    let length=Math.hypot(x,y);
    if(analog){
      const dead=this.WALK.dead;
      const strength=length<=dead?0:Math.min(1,(length-dead)/(1-dead));
      if(length>0){x=x/length*strength;y=y/length*strength;}
      else{x=0;y=0;}
    }else if(length>1){x/=length;y/=length;}
    const moving=Math.hypot(x,y)>1e-4;
    // Släppet får aldrig ge en oönskad eftersväng. Farten bromsas separat.
    if(!moving){state.x=0;state.y=0;return {x:0,y:0,strength:0,moving:false};}
    state.x=this.axis(state.x||0,x,dt,this.WALK.tau);
    state.y=this.axis(state.y||0,y,dt,this.WALK.tau);
    return {x:state.x,y:state.y,strength:Math.min(1,Math.hypot(state.x,state.y)),moving:true};
  },
  /* Hur stor andel av full styrka ett hållet tryck ger just nu. Ett
     kort tryck (heldSeconds under holdThreshold) ligger kvar på
     digitalGain — bara en nyansering, precis som förut, så korta tryck
     förblir små korrigeringar. Hålls tangenten längre trappar den
     exponentiellt upp mot 1,0. */
  digitalStyrka(heldSeconds){
    const R=this.RIDE;
    if(!Number.isFinite(heldSeconds)||heldSeconds<=R.holdThreshold)return R.digitalGain;
    const u=1-Math.exp(-(heldSeconds-R.holdThreshold)/R.holdRampTau);
    return R.digitalGain+(1-R.digitalGain)*u;
  },
  ride(raw,dt,state,heldSeconds){
    const styrka=this.digitalStyrka(heldSeconds);
    const target=Math.max(-1,Math.min(1,raw))*styrka;
    state.v=this.axis(state.v||0,target,dt,target===0?this.RIDE.release:this.RIDE.tau);
    if(target===0&&Math.abs(state.v)<1e-4)state.v=0;
    return state.v;
  }
});
