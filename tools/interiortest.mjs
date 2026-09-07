#!/usr/bin/env node
/* F02-C: source-driven finishes and existing furnishing details.
   Node-only runtime test, with a deliberately small renderer harness.
   This is not a substitute for an actual browser or Roblox Studio test. */
import fs from 'node:fs';
import vm from 'node:vm';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const ctx={console,Math,JSON,window:{}};
vm.createContext(ctx);
vm.runInContext(['model','data','site','inredning'].map(x=>read(`src/${x}.js`)).join('\n'),ctx);
const get=expression=>vm.runInContext(expression,ctx);
const {ANL,STALLINNE:S,RIDHUSINNE:R,INREDNING:I,INTERIORYTOR:Y,SPELABSTRAKTIONER:A}=get('({ANL,STALLINNE,RIDHUSINNE,INREDNING,INTERIORYTOR,SPELABSTRAKTIONER})');
const same=(a,b)=>assert.deepEqual(JSON.parse(JSON.stringify(a)),JSON.parse(JSON.stringify(b)));
function check(name,fn){fn();console.log('OK',name);}
const geo=()=>({buildings:ANL.byggnader,stall:{bredd:S.bredd,langd:S.langd,klubb:S.klubb,gangytor:S.gangytor},ridhus:{bredd:R.bredd,langd:R.langd,bana:R.bana,dressyr:R.dressyr,laktare:R.laktare,domarbas:R.domarbas,trappor:R.trappor,ovreGang:R.ovreGang,ovreGangV:R.ovreGangV,entrehall:R.entrehall},steg:A.ridhus.laktarSteg});
const sha=o=>crypto.createHash('sha256').update(JSON.stringify(o)).digest('hex');
const lock=JSON.parse(read('docs/INTERIOR-GEOMETRY-LOCK.json'));
check('accepted architecture and grandstand geometry unchanged',()=>assert.equal(sha(geo()),lock.sha256));
check('geometry mutation is rejected',()=>{
 const old=R.laktare.dackZ;R.laktare.dackZ=old+.1;
 try{assert.notEqual(sha(geo()),lock.sha256);}finally{R.laktare.dackZ=old;}
});
check('both finishes are sourced, non-tiled and distinct',()=>{
 same(Object.keys(Y).sort(),['ridhusEntre','stallKlubb']);
 for(const y of Object.values(Y)){
  assert.equal(y.fogar,false);assert.equal(y.fargKlass,'UPPSKATTNING');
  assert.ok(y.kalla&&/^#[0-9A-F]{6}$/i.test(y.farg));
 }
 assert.notEqual(Y.stallKlubb.farg,Y.ridhusEntre.farg);
});
const lockers=I.ridhus.filter(o=>o.typ==='skapbank');
check('all sourced locker footprints and locations remain unchanged',()=>{
 const expected=lock.lockers;
 same(lockers.map(o=>({id:o.id,pos:o.pos,matt:o.matt,rikt:o.rikt,kolliderar:o.kolliderar})),expected);
});
check('source-defined doors and material are exported',()=>{
 const out=read('roblox/buildings/UBRFKomplex.luau');
 assert.ok(out.includes('interiorytor = {'));
 for(const y of Object.values(Y))assert.ok(out.includes(y.kalla));
 for(const o of lockers){assert.equal(o.ytmaterial,'Metal');assert.ok(o.detaljer.profil&&o.detaljer.beslag&&o.detaljer.ventilation);}
 assert.equal(I.ridhus.find(o=>o.id==='skap_grona').detaljer.kolumner,4);
 assert.equal(I.ridhus.find(o=>o.id==='skap_vita_2v').detaljer.kolumner,5);
 assert.ok(out.includes('kolumner = 5'));
});
// Execute the actual furniture renderer with a recording mesh implementation.
const source=read('src/varld3d.js');
const section=(a,b)=>source.slice(source.indexOf(a),source.indexOf(b));
class Bygge{
 constructor(){this.calls=[];}
 lada(...args){this.calls.push({kind:'box',args});return this;}
 cyl(...args){this.calls.push({kind:'cylinder',args});return this;}
 klot(...args){this.calls.push({kind:'sphere',args});return this;}
}
const M4={translation:(...a)=>a,rotY:a=>a,rotX:a=>a,rotZ:a=>a,ny:()=>null,mul:(a,b)=>[a,b]};
const renderer={console,Math,Bygge,M4,GL:{nat:b=>b},S3:{statiskt:[]},v3dBox:()=>({}),inredningFor:()=>[],};
vm.createContext(renderer);
vm.runInContext(section('function v3dInredning(', '/* ── Siktprovet'),renderer);
function render(o){
 renderer.S3.statiskt=[];renderer.inredningFor=()=>[o];
 const out=[];renderer.v3dInredning('ridhusinne',(b)=>out.push(...b.calls));
 return [...out,...renderer.S3.statiskt.flatMap(x=>x.nat.calls)];
}
check('actual web renderer emits correct locker faces and hardware',()=>{
 for(const [id,count] of [['skap_grona',8],['skap_vita_2v',10]]){
  const o=I.ridhus.find(x=>x.id===id), calls=render(o);
  assert.equal(calls.filter(x=>x.args[3]===o.fargor[0]).length,count);
  assert.equal(calls.filter(x=>x.args[3]==='#8E9395').length,count);
  assert.equal(calls.filter(x=>x.args[3]==='#4D5152').length,count*3);
  for(const c of calls.filter(x=>x.kind==='box'))for(const d of c.args.slice(0,3))assert.ok(d>0,id+' invalid dimension');
 }
});
check('missing material/detail mutation is rejected',()=>{
 const o=I.ridhus.find(x=>x.id==='skap_grona');
 const old=o.detaljer;delete o.detaljer;
 try{assert.notEqual(render(o).filter(x=>x.args[3]==='#8E9395').length,8);}finally{o.detaljer=old;}
});
check('no invented pentry or room geometry',()=>{
 assert.equal([...I.stall,...I.ridhus].some(o=>o.id.startsWith('pentry')),false);
 assert.equal(S.klubb.rum.some(r=>r.id==='pentry'),false);
});
console.log('ALLA OK — F02-C source/runtime checks');
