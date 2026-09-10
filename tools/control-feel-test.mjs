#!/usr/bin/env node
import fs from 'node:fs';import vm from 'node:vm';import assert from 'node:assert/strict';import path from 'node:path';
const root=path.resolve(new URL('..',import.meta.url).pathname);
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const source=read('src/input-feel.js'),game=read('src/game.js'),world=read('src/world.js');
const checks=[];function test(name,fn){fn();checks.push(name);console.log('PASS',name);}
function block(s,name){const p=s.indexOf('function '+name+'(');assert(p>=0,name);const i=s.indexOf('{',p);let d=0;for(let j=i;j<s.length;j++){if(s[j]==='{')d++;if(s[j]==='}'&&!--d)return s.slice(p,j+1)}throw Error(name);}
/* Bänken kör spelkoden i en bar vm-kontext, så varje webb-API som koden
   rör måste finnas här. `document` saknades och sidan registrerar sedan
   #151 en `visibilitychange`-lyssnare — provet dog på
   `ReferenceError: document is not defined` innan en enda mätning hann
   köras. Stubben nedan är alltså en komplettering av testmiljön, inte en
   uppmjukning: `visibilityState` går att sätta och `doldFlik()` fyrar
   lyssnaren på riktigt, så att kontraktet nedan kan MÄTAS i stället för
   att bara sluta krascha. */
function mounted(){const events={},docEvents={};
  const doc={visibilityState:'visible',addEventListener:(n,f)=>(docEvents[n]??=[]).push(f)};
  const c={console,Math,clamp,HJALP_KANON:{STYR_FULLT:.72},G:{},document:doc,
    addEventListener:(n,f)=>(events[n]??=[]).push(f)};
  vm.createContext(c);vm.runInContext(source+game.slice(game.indexOf('const RIDIN='),game.indexOf('/* ── Speltillstånd'))+'\nthis.RIDIN=RIDIN;this.IN=IN;this.stegaInput=stegaInput;this.reset=ridNollstallHjalp;',c);
  c.key=(type,code)=>{for(const f of events[type]||[])f({code,repeat:false,preventDefault(){}})};
  c.fonster=(n)=>{for(const f of events[n]||[])f({});};
  c.doldFlik=()=>{doc.visibilityState='hidden';for(const f of docEvents.visibilitychange||[])f({});};
  return c;}
function walking(){const c={console,Math,clamp,G:{scen:'gard',vy:'2d'},IN:{ned:{},joy:null},overlayUppe:()=>false,vandringYaw:()=>Math.PI/2,vandringKollision:(x,y)=>[x,y],nivaHojd:()=>0,ljudFotsteg(){},ledHasten(){},interagera(){},slutaGa(){}};vm.createContext(c);vm.runInContext(source+world.match(/const GA=\{[^;]+;/)[0]+world.match(/const VD=\{[\s\S]*?\n\};/)[0]+block(world,'stegaVandring')+'\nthis.VD=VD;this.GA=GA;this.step=stegaVandring;',c);return c;}
function runWalk(fps,segments){const c=walking(),dt=1/fps,rows=[];for(const [seconds,keys,joy] of segments){Object.assign(c.IN.ned,{KeyW:false,KeyS:false,KeyA:false,KeyD:false,ShiftLeft:false},keys);c.IN.joy=joy||null;for(let i=0;i<Math.round(seconds*fps);i++){const prev=c.VD.rikt;c.step(dt);rows.push({x:c.VD.px,y:c.VD.py,angle:c.VD.rikt,speed:c.VD.fart,delta:c.VD.rikt-prev});}}return {c,rows};}
function runRide(fps,segments){const c=mounted(),dt=1/fps,rows=[];for(const [seconds,keys] of segments){for(const [key,down] of Object.entries(keys||{}))c.key(down?'keydown':'keyup',key);for(let i=0;i<Math.round(seconds*fps);i++){c.stegaInput(dt);rows.push(c.IN.kan.styrning.v);}}return {c,rows};}
test('Digital ridstyrning dämpar korta tryck',()=>{const r=runRide(60,[[.1,{KeyD:true}]]);assert(r.rows.at(-1)>0);assert(r.rows.at(-1)<.20);});
test('Digital styrning har begränsat normalt utslag',()=>{const r=runRide(60,[[2,{KeyD:true}]]);assert(Math.abs(r.rows.at(-1)-.72*.42)<.005);});
test('Analog och direkta modellprov behåller hela omfånget',()=>{const c=mounted();c.RIDIN.pek=true;c.RIDIN.styr=1;for(let i=0;i<120;i++)c.stegaInput(1/60);assert(Math.abs(c.IN.kan.styrning.v-.72)<.001);c.reset();assert.equal(c.RIDIN.styr,0);assert.equal(c.IN.styrKansla.v,0);});
test('Släpp och riktningsbyte ger ingen kvarhängande styrning',()=>{const r=runRide(60,[[.4,{KeyD:true}],[.4,{KeyD:false,KeyA:true}],[.8,{KeyA:false}]]);assert(r.rows.at(-1)<.001&&r.rows.at(-1)>-.001);assert(r.rows.some(v=>v<-.1));assert(Math.max(...r.rows)<.31);});
test('Digital styrning är bildrutetaksoberoende',()=>{const a=runRide(30,[[.5,{KeyD:true}],[.5,{KeyD:false}]]).rows.at(-1),b=runRide(120,[[.5,{KeyD:true}],[.5,{KeyD:false}]]).rows.at(-1);assert(Math.abs(a-b)<.02);});
test('Fotstyrningens första tiondel är lugnare',()=>{const r=runWalk(60,[[.1,{KeyW:true,KeyD:true}]]);assert(r.rows.at(-1).angle>0);assert(r.rows.at(-1).angle*180/Math.PI<20);});
test('Ingen eftersväng när spelaren släpper',()=>{const r=runWalk(60,[[.5,{KeyW:true,KeyD:true}],[.4,{}]]);assert(Math.abs(r.rows.at(29).angle-r.rows.at(-1).angle)<1e-8);assert(r.rows.at(-1).speed<.01);});
test('Joystickens dödzon stoppar oavsiktlig drift',()=>{const r=runWalk(60,[[1,{}, {x:.04,y:.03,styrka:.05}]]);assert(Math.hypot(r.c.VD.px,r.c.VD.py)<1e-8);});
test('Analog styrning är proportionell och diagonalen normaliseras',()=>{const half=runWalk(60,[[2,{}, {x:.5,y:0,styrka:.5}]]).rows.at(-1).speed;const full=runWalk(60,[[2,{}, {x:1,y:0,styrka:1}]]).rows.at(-1).speed;assert(half>0&&half<full);const diag=runWalk(60,[[2,{KeyW:true,KeyD:true}]]).rows.at(-1).speed;assert(diag<=1.801);});
test('Gångstyrning är stabil vid 30 och 120 FPS',()=>{const a=runWalk(30,[[1,{KeyW:true,KeyD:true}],[1,{KeyW:true}]]).rows.at(-1),b=runWalk(120,[[1,{KeyW:true,KeyD:true}],[1,{KeyW:true}]]).rows.at(-1);assert(Math.hypot(a.x-b.x,a.y-b.y)<.15);assert(Math.abs(a.angle-b.angle)<.03);});
/* Lyssnaren ska inte bara FINNAS — den ska släppa hjälperna. Utan de här
   mätningarna hade stubben ovan bara dolt kraschen: provet blivit grönt
   och hästen ändå fortsatt gå medan spelaren bytt app.

   VILOLÄGET LÄSES UR MODULEN, inte ur en siffra jag skriver hit. Första
   utkastet krävde `skankel < .001` och blev rött — men 0,42 visade sig
   vara skänkelns NEUTRALLÄGE: en orörd kontext ligger där, och ett
   riktigt keyup återvänder dit. Hade jag "rättat" produktionskoden mot
   den gissningen hade jag gått sönder ridkänslan för att blidka ett
   felskrivet prov. Kravet är därför det enda som betyder något: focus
   loss ska landa på SAMMA värde som ett äkta tangentsläpp. */
const neutralSkankel=(()=>{const c=mounted();
  for(let i=0;i<60;i++)c.stegaInput(1/60);return c.IN.kan.skankel.v;})();
function slappProv(namn,utlos){
  test(namn,()=>{const c=mounted();
    c.key('keydown','KeyW');for(let i=0;i<30;i++)c.stegaInput(1/60);
    assert(c.IN.ned.KeyW===true,'tangenten ska räknas som nere före bytet');
    assert(c.IN.kan.skankel.v>neutralSkankel+.05,
      `skänkeln ska ligga på före bytet (${c.IN.kan.skankel.v} mot neutral ${neutralSkankel})`);
    utlos(c);for(let i=0;i<60;i++)c.stegaInput(1/60);
    assert(!c.IN.ned.KeyW,'ingen tangent får stå kvar som nere');
    assert(Math.abs(c.IN.kan.skankel.v-neutralSkankel)<1e-9,
      `skänkeln ska tillbaka till neutral ${neutralSkankel}, blev ${c.IN.kan.skankel.v}`);
    assert.equal(c.RIDIN.pek,false);});
}
slappProv('Dold flik släpper hjälperna',c=>c.doldFlik());
slappProv('Focus loss släpper hjälperna',c=>c.fonster('blur'));
/* Kontrollmätning: ett ÄKTA tangentsläpp landar på samma neutral. Utan
   den vore raden ovan bara "något värde blev något annat". */
test('och det är samma neutral som ett äkta tangentsläpp',()=>{const c=mounted();
  c.key('keydown','KeyW');for(let i=0;i<30;i++)c.stegaInput(1/60);
  c.key('keyup','KeyW');for(let i=0;i<60;i++)c.stegaInput(1/60);
  assert(Math.abs(c.IN.kan.skankel.v-neutralSkankel)<1e-9);});
test('Fysikens kanon är oförändrad av inputpatchen',()=>{const t=read('src/riding/telemetri.js');assert(t.includes('KAPPA_MAX: 0.42'));assert(t.includes('KAPPA_RAT_TID: 0.32'));});
console.log(`${checks.length} inputkänslatester gröna.`);
