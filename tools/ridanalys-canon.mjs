#!/usr/bin/env node
// Extend the existing canonical exporter without duplicating exercise data.
// This migration is idempotent and modifies only the exporter. The generated
// RidKanon.luau is then produced by the normal export command.
import fs from 'node:fs';
const path='tools/exportera-ridkanon.mjs';
let s=fs.readFileSync(path,'utf8');
const marker='rader.push("return RidKanon");';
if(!s.includes('RIDANALYS_CANON_EXPORT')){
  const load='  + "\\n" + las("src/spel/hastar.js")';
  // The recording module contains no DOM or simulation side effects.
  const context='  + "\\n" + las("src/riding/ovningsdef.js")';
  if(!s.includes(context))throw new Error('Exercise definition loading changed');
  s=s.replace(context,context+'\n  + "\\n" + las("src/riding/inspelning.js")');
  const addition=`/* RIDANALYS_CANON_EXPORT — one definition, two platform adapters. */
const rd = vm.runInContext("({schema:INSPELNING_SCHEMA,ovningSchema:OVNING_SCHEMA,hz:INSPELNING_HZ,maxSek:INSPELNING_MAX_SEK,maxSampel:INSPELNING_MAX_SAMPEL,maxHandelser:INSPELNING_MAX_HANDELSER,ovningar:OVNINGAR_DEF})",ctx);
// JSON-compatible data -> deterministic Luau, never executable source input.
function rdLua(v){
  if(v===null||v===undefined)return 'false';
  if(typeof v==='number')return Number.isFinite(v)?tal(v):'nil';
  if(typeof v==='string')return str(v);
  if(typeof v==='boolean')return String(v);
  if(Array.isArray(v))return '{'+v.map(rdLua).join(', ')+'}';
  if(typeof v==='object')return '{'+Object.keys(v).sort().map(k=>'['+str(k)+'] = '+rdLua(v[k])).join(', ')+'}';
  throw new Error('Unsupported canon value');
}
// Only stable semantic data is exported. Geometry numbers remain owned by
// the existing arena and Ugneta canon; no second site plan is introduced.
const rdDefinitions={};
for(const [id,d] of Object.entries(rd.ovningar)){
  rdDefinitions[id]={id:d.id,version:d.version,rubrik:d.rubrik,ram:d.ram,
    matt:d.matt,bedomer:d.bedomer,bedomerInte:d.bedomerInte,gangart:d.gangart,
    referens:d.referens,referensStatus:d.referens?'UNVERIFIED':'REFERENCE_GAP',
    niva:'alla',hastprofiler:null};
}
rader.push('-- G02-D: generated recording contract; false means absent reference.');
rader.push('RidKanon.RIDANALYS = '+rdLua({...rd,ovningar:rdDefinitions}));
rader.push('');
`;
  if(!s.includes(marker))throw new Error('Exporter return marker changed');
  s=s.replace(marker,addition+marker);
  fs.writeFileSync(path,s);
}
console.log('Ridanalys canonical exporter ready');
