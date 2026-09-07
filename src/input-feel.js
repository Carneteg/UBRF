/* P0 — inputkänsla. Endast spelarens avsikt formas här.
   Hästens fysik, gångarter, kurvaturtak och bedömning ändras inte. */
"use strict";
const InputFeel = Object.freeze({
  WALK: Object.freeze({turn:3.0, accel:5.5, brake:9.0, tau:0.12, dead:0.12}),
  RIDE: Object.freeze({digitalGain:0.42, tau:0.16, release:0.10}),
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
  ride(raw,dt,state){
    const target=Math.max(-1,Math.min(1,raw))*this.RIDE.digitalGain;
    state.v=this.axis(state.v||0,target,dt,target===0?this.RIDE.release:this.RIDE.tau);
    if(target===0&&Math.abs(state.v)<1e-4)state.v=0;
    return state.v;
  }
});
