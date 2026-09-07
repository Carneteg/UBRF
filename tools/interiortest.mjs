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
check('theory-room source details share data and render without a fallback board',()=>{
 const boards=I.stall.filter(o=>o.rum==='teorisal'&&o.typ==='whiteboard');
 const posters=I.stall.filter(o=>o.rum==='teorisal'&&o.typ==='tavlor');
  const tables=I.stall.filter(o=>o.rum==='teorisal'&&o.typ==='bord');
  const chairs=I.stall.filter(o=>o.rum==='teorisal'&&o.typ==='stol');
  const lights=I.stall.filter(o=>o.rum==='teorisal'&&o.typ==='lysror');
 const duct=I.stall.find(o=>o.id==='teori_ventkanal');
 assert.equal(boards.length,2);
  assert.ok(boards.every(o=>o.kalla==='stall-inne-04'&&o.detaljer.ram&&o.detaljer.hylla&&o.detaljer.arbetsmarken==='icke-semantiska'));
  assert.ok(boards.every(o=>render(o).filter(x=>x.args[3]==='#506A70'||x.args[3]==='#65705A').length===6));
 assert.equal(posters.length,2);
  assert.ok(posters.every(o=>o.kalla==='stall-inne-04'&&o.detaljer.motiv==='hastanatomi'&&o.detaljer.etiketter===false));
  assert.equal(tables.length,3);
  assert.ok(tables.every(o=>o.ytmaterial==='Wood'&&o.detaljer.tra&&render(o).filter(x=>x.args[3]===o.farg2).length===4));
  assert.equal(chairs.length,10);
  assert.ok(chairs.every(o=>o.detaljer.vitSits&&o.detaljer.traram&&render(o).filter(x=>x.args[3]===o.farg2).length>=6));
  assert.equal(lights.length,2);
  assert.ok(lights.every(o=>o.detaljer.upphangd&&o.detaljer.holje&&render(o).filter(x=>x.args[3]==='#777A7B').length===2));
 assert.equal(duct.kalla,'stall-inne-04');
  assert.deepEqual(JSON.parse(JSON.stringify(duct.detaljer)),{perforerad:true,halrader:2,profil:'rektangular_ranna'});
 assert.ok(render(boards[0]).some(x=>x.args[3]==='#AEB3B5'));
 assert.ok(render(posters[0]).some(x=>x.args[3]==='#A86F68'));
 assert.equal(render(duct).filter(x=>x.args[3]==='#5F6264').length,28);
 const stallBuild=source.slice(source.indexOf('function v3dStall('),source.indexOf('/* ── Ridhuset invändigt'));
 assert.equal(stallBuild.includes('S.whiteboard.pos'),false);
 const out=read('roblox/buildings/UBRFKomplex.luau');
 assert.ok(out.includes('motiv = "hastanatomi"'));
  assert.ok(out.includes('arbetsmarken = "icke-semantiska"'));
  assert.ok(out.includes('etiketter = false'));
 assert.ok(out.includes('perforerad = true'));
});
check('theory-room object footprints, positions and collision remain locked',()=>{
  const now=I.stall.filter(o=>o.rum==='teorisal')
    .map(o=>({id:o.id,pos:o.pos,z0:o.z0||0,matt:o.matt,rikt:o.rikt,kolliderar:o.kolliderar||false}));
  assert.equal(now.length,24);
  assert.equal(sha(now),'bef903faf92b18517b123ef7a007d287b9cab244eaa30796844a6b032d1f03cc');
});
check('web uses a dedicated seamless matt interior floor texture',()=>{
  assert.ok(source.includes('T.mattBetong=glCanvasTex'));
  assert.ok(source.includes('T.interiorytor[id]=T.mattBetong'));
  const block=source.slice(source.indexOf('T.mattBetong='),source.indexOf('T.interiorytor={}'));
  assert.ok(block.includes('Math.sin')&&block.includes('Math.cos')&&block.includes('tau*x/w'));
  assert.equal(/stroke|lineTo|marksten|createRadialGradient/i.test(block),false);
});
check('no invented pentry or room geometry',()=>{
 assert.equal([...I.stall,...I.ridhus].some(o=>o.id.startsWith('pentry')),false);
 assert.equal(S.klubb.rum.some(r=>r.id==='pentry'),false);
});
console.log('ALLA OK — F02-C source/runtime checks');
