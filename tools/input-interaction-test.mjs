import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const read=p=>fs.readFileSync(new URL('../'+p,import.meta.url),'utf8');
const game=read('src/game.js'),world=read('src/world.js'),scenes=read('src/scenes.js');
function between(s,a,b){const i=s.indexOf(a),j=s.indexOf(b,i+a.length);assert(i>=0&&j>i,`missing ${a}`);return s.slice(i,j);}
function mount(){
  const events={};let calls=0,overlay=false,near=true;
  const c={console,Math,InputFeel:{ride:x=>x},HJALP_KANON:{STYR_FULLT:.72},
    clamp:(x,a,b)=>Math.max(a,Math.min(b,x)),
    G:{scen:'gard',hastId:null,hastMott:false},
    addEventListener:(n,f)=>(events[n]??=[]).push(f),
    /* G02-D: game.js registrerar sedan `document.addEventListener(
       "visibilitychange", ...)` i samma utdrag den här bänken kör (focus
       loss-fixet, "Focus loss lämnade hjälperna på"). Provet här handlar
       om E-interaktionens engångssemantik, inte om fliksynlighet — en
       tom lyssnare räcker för att utdraget ska gå att köra utan att
       provets egen mätning ändras. visibilitychange-beteendet har sitt
       eget prov i tools/inputsemantiktest.mjs. */
    document:{getElementById:()=>({classList:{contains:()=>!overlay}}),
      addEventListener(){}},
    ov:{classList:{toggle:(_,hidden)=>{overlay=!hidden;}}},sheet:{innerHTML:''},
    interaktioner:()=>near?[{pos:[0,0],text:'Dörr',gor(){calls++;}}]:[{pos:[20,0],text:'Dörr',gor(){calls++;}}],
    overlayUppe:()=>overlay,navBygg(){},slutaGa(){},kameraNollstall(){},ridSittAv(){},hudLage(){},saga(){},
    nivaHojd:()=>0,ANL:{spawn:{x:0,y:0,rikt:0}},
    SPAR:{pass:0},vaxlaVy(){},ljudToggle(){},visaTraningsbok(){},
  };
  vm.createContext(c);
  vm.runInContext(read('src/input-impulse.js'),c);
  vm.runInContext(between(world,'const VD={','/* ── GÅ HIT'),c);
  vm.runInContext(between(game,'const RIDIN=','/* ── Speltillstånd'),c);
  vm.runInContext(between(world,'function interagera(){','/* Boxarnas'),c);
  vm.runInContext(between(world,'function gaTill(scen,spawn){','function startaVandring(){'),c);
  vm.runInContext(between(world,'function startaVandring(){','function hudLage('),c);
  vm.runInContext(between(scenes,'function overlay(on,html){','/* ── Meny'),c);
  vm.runInContext('this.IN=IN;this.RIDIN=RIDIN;this.VD=VD;this.interact=interagera;this.go=gaTill;this.start=startaVandring;this.show=overlay;this.rideStep=stegaInput;',c);
  c.key=(type,code='KeyE',repeat=false)=>{for(const f of events[type]||[])f({code,repeat,preventDefault(){}});};
  c.sample=()=>c.interact();
  c.calls=()=>calls;c.near=x=>{near=x;};
  return c;
}
let count=0;
function test(name,fn){fn();count++;console.log('OK',name);}
test('kort keydown och keyup mellan bildrutor ger exakt en interaktion',()=>{
  const c=mount();c.key('keydown');c.key('keyup');assert.equal(c.IN.ned.KeyE,false);
  c.sample();c.sample();assert.equal(c.calls(),1);
});
test('långt håll och autorepeat ger ingen dubbelinteraktion',()=>{
  const c=mount();c.key('keydown');c.sample();c.key('keydown','KeyE',true);c.key('keydown');c.sample();c.key('keyup');c.sample();assert.equal(c.calls(),1);
});
test('två tryck före sampling följer Del 1:s koalesceringskontrakt',()=>{
  const c=mount();for(let i=0;i<2;i++){c.key('keydown');c.key('keyup');}c.sample();c.sample();assert.equal(c.calls(),1);
});
test('overlay blockerar tryck och rensar väntande impuls',()=>{
  const c=mount();c.show(true);c.key('keydown');c.key('keyup');c.show(false);c.sample();assert.equal(c.calls(),0);
  c.key('keydown');c.key('keyup');c.show(true);c.show(false);c.sample();assert.equal(c.calls(),0);
});
test('fel scen och återkomst till samma scen återupplivar inte tryck',()=>{
  const c=mount();c.key('keydown');c.key('keyup');c.G.scen='stallinne';c.sample();c.G.scen='gard';c.sample();assert.equal(c.calls(),0);
  c.key('keydown');c.key('keyup');c.go('stallinne');c.go('gard');c.sample();assert.equal(c.calls(),0);
});
test('tryck utanför räckvidd får inte sparas tills spelaren närmar sig',()=>{
  const c=mount();c.near(false);c.key('keydown');c.key('keyup');c.sample();c.near(true);c.sample();assert.equal(c.calls(),0);
});
test('scenbyte och hållen E skapar ingen ny handling förrän nytt tryck',()=>{
  const c=mount();c.key('keydown');c.sample();c.go('stallinne');c.sample();c.go('gard');c.sample();assert.equal(c.calls(),1);
  c.key('keyup');c.key('keydown');c.key('keyup');c.sample();assert.equal(c.calls(),2);
});
test('ridningens parad och kontinuerliga nivå förblir oförändrade',()=>{
  const c=mount();c.G.scen='lektion';c.key('keydown');assert.equal(c.RIDIN.parad,1);assert.equal(c.IN.ned.KeyE,true);
  c.key('keyup');assert.equal(c.RIDIN.parad,0);assert.equal(c.IN.ned.KeyE,false);
  c.G.scen='gard';c.sample();assert.equal(c.calls(),0);
});
console.log(`ALLA OK (${count} mätningar)`);
