#!/usr/bin/env node
// One-time, idempotent extension of the existing canonical exporter.
// All values come from the same web modules; no duplicate riding rules.
import fs from 'node:fs';
const path='tools/exportera-ridkanon.mjs';
let s=fs.readFileSync(path,'utf8');
const marker='rader.push("return RidKanon");';
if(!s.includes('RIDANALYS_CANON_EXPORT')){
  const load='las("src/riding/ovningsdef.js")';
  if(!s.includes(load))throw new Error('Exercise definition loading changed');
  s=s.replace(load,load+'\n  + "\\n" + las("src/riding/inspelning.js")');
  const addition=`/* RIDANALYS_CANON_EXPORT — generated definitions and recording bounds. */
const rd = vm.runInContext("({schema:INSPELNING_SCHEMA,ovningSchema:OVNING_SCHEMA,hz:INSPELNING_HZ,maxSek:INSPELNING_MAX_SEK,maxSampel:INSPELNING_MAX_SAMPEL,maxHandelser:INSPELNING_MAX_HANDELSER,ovningar:OVNINGAR_DEF})",ctx);
function rdLua(v){
  if(v===null||v===undefined)return 'false';
  if(typeof v==='number')return Number.isFinite(v)?tal(v):'nil';
  if(typeof v==='string')return str(v);
  if(typeof v==='boolean')return String(v);
  if(Array.isArray(v))return '{'+v.map(rdLua).join(', ')+'}';
  if(typeof v==='object')return '{'+Object.keys(v).sort().map(k=>'['+str(k)+'] = '+rdLua(v[k])).join(', ')+'}';
  throw new Error('Unsupported canon value');
}
rader.push('-- G02-D: generated recording contract; false denotes absent reference.');
rader.push('RidKanon.RIDANALYS = '+rdLua(rd));
rader.push('');
`;
  if(!s.includes(marker))throw new Error('Exporter return marker changed');
  s=s.replace(marker,addition+marker);
  fs.writeFileSync(path,s);
}
console.log('Ridanalys canonical exporter ready');
