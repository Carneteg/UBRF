#!/usr/bin/env node
/* F02-C: preserve source-backed A-gable identities before visual polish.
   Source/geometry guard only: not a rendered-image or Studio acceptance. */
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const ctx={console,Math,JSON,window:{}};
vm.createContext(ctx);
vm.runInContext(['model','data','site','inredning'].map(n=>read(`src/${n}.js`)).join('\n'),ctx);
const get=e=>vm.runInContext(e,ctx);
const {ANL,RIDHUSINNE:R,INREDNING:I,SPELABSTRAKTIONER:A}=get('({ANL,RIDHUSINNE,INREDNING,SPELABSTRAKTIONER})');
const same=(a,b)=>assert.deepEqual(JSON.parse(JSON.stringify(a)),JSON.parse(JSON.stringify(b)));
const lock=JSON.parse(read('docs/INTERIOR-GEOMETRY-LOCK.json'));
const crypto=await import('node:crypto');
const geo=()=>({buildings:ANL.byggnader,stall:(()=>{const S=get('STALLINNE');return {bredd:S.bredd,langd:S.langd,klubb:S.klubb,gangytor:S.gangytor};})(),ridhus:{bredd:R.bredd,langd:R.langd,bana:R.bana,dressyr:R.dressyr,laktare:R.laktare,domarbas:R.domarbas,trappor:R.trappor,ovreGang:R.ovreGang,ovreGangV:R.ovreGangV,entrehall:R.entrehall},steg:A.ridhus.laktarSteg});
const hash=o=>crypto.createHash('sha256').update(JSON.stringify(o)).digest('hex');
assert.equal(hash(geo()),lock.sha256,'Accepted architecture/grandstand changed');
const house=ANL.byggnader.find(b=>b.id==='ridhus');
assert.ok(house,'Missing riding hall');
const south=house.oppningar.filter(o=>o.sida==='S'&&(o.z0||0)<0.5&&/^(dorr|port)/.test(o.typ));
assert.ok(south.length>0,'Missing canonical A-gable opening');
for(const o of south){
 assert.ok(o.b>0&&o.h>0,'Invalid source opening');
 assert.ok(o.u>=0&&o.u+o.b<=R.bredd+0.001,'Opening outside facade');
}
const mirrors=I.ridhus.filter(o=>o.id==='spegel_A_v'||o.id==='spegel_A_o');
assert.equal(mirrors.length,2,'A-gable must reuse its two existing mirrors');
same(mirrors.map(o=>o.id).sort(),['spegel_A_o','spegel_A_v']);
for(const o of mirrors){
 assert.equal(o.typ,'spegel');
 assert.equal(o.klass,'VERIFIED');
 assert.equal(o.lage,'DERIVED');
 assert.ok(o.kalla.includes('ridhus-inne-23'));
 assert.ok(o.matt.b>0&&o.matt.h>0);
}
const src=read('src/varld3d.js');
assert.ok(src.includes('function v3dDorrarInifran('),'Canonical interior-door renderer missing');
assert.ok(src.includes('v3dDorrarInifran(d,hus,R.bredd,R.langd,0.14)'),'Riding hall must reuse facade openings');
assert.ok(src.includes('function v3dInredning('),'Canonical furniture renderer missing');
// Any new static A-gable door must be reviewed against the canonical opening.
// This guard deliberately does not assert that the entire facade is visually correct.
console.log('OK F02-C A-gable source identities, openings and accepted geometry');