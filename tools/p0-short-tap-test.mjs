#!/usr/bin/env node
/* P0 #146: test the actual keyboard handlers and walking interaction code.
   No gameplay state is rewritten to obtain a PASS. The baseline is expected
   to FAIL the short-tap assertion; --baseline-red verifies that exact defect. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const game = fs.readFileSync(new URL('../src/game.js', import.meta.url), 'utf8');
const world = fs.readFileSync(new URL('../src/world.js', import.meta.url), 'utf8');
const inputStart = game.indexOf('const RIDIN=');
const inputEnd = game.indexOf('/* ── Speltillstånd', inputStart);
assert(inputStart >= 0 && inputEnd > inputStart, 'Production input region not found');
const interactionStart = world.indexOf('function interagera(){');
const interactionEnd = world.indexOf('/* Boxarnas', interactionStart);
assert(interactionStart >= 0 && interactionEnd > interactionStart, 'Production interaction region not found');

function harness() {
  const listeners = new Map();
  let overlay = false, inRange = true, actions = 0;
  const ctx = vm.createContext({
    Math, console, Set, clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),
    InputFeel:{ride:(v)=>v},
    addEventListener:(type,fn)=>listeners.set(type,fn),
    G:{scen:'gard',hastId:null,hastMott:false},
    VD:{px:0,py:0,prompt:null,ePrev:false},
    interaktioner:()=>[{pos:inRange?[1,0]:[10,0],text:'Stalldörr',gor:()=>{actions++;}}],
    overlayUppe:()=>overlay,
  });
  vm.runInContext(game.slice(inputStart,inputEnd)+'\n'+world.slice(interactionStart,interactionEnd),ctx,{filename:'production-input-and-interaction.js'});
  const read=expression=>vm.runInContext(expression,ctx);
  const emit=(type,code='KeyE',repeat=false)=>listeners.get(type)({code,repeat,preventDefault(){}});
  return {
    read,emit,frame:()=>read('interagera()'),
    down:(code='KeyE',repeat=false)=>emit('keydown',code,repeat),
    up:(code='KeyE')=>emit('keyup',code),
    tap(code='KeyE'){emit('keydown',code);emit('keyup',code);},
    get actions(){return actions;},
    overlay(value){overlay=value;},range(value){inRange=value;},
    scene(value){read(`G.scen=${JSON.stringify(value)}`);},
  };
}

const cases = [
  ['short-tap-between-frames',()=>{
    const h=harness();h.frame();h.tap();h.frame();
    assert.equal(h.actions,1,'SHORT_TAP_LOST: a complete KeyE press between frames must interact once');
    h.frame();assert.equal(h.actions,1,'A consumed tap must not replay');
  }],
  ['held-key-once',()=>{
    const h=harness();h.down();h.frame();h.frame();h.down('KeyE',true);h.frame();
    assert.equal(h.actions,1,'Holding or repeating KeyE must not repeat the action');
    h.up();h.frame();assert.equal(h.actions,1);
  }],
  ['two-distinct-taps',()=>{
    const h=harness();h.frame();h.tap();h.frame();h.tap();h.frame();
    assert.equal(h.actions,2,'Two distinct presses must produce two actions');
  }],
  ['overlay-blocks-interaction',()=>{
    const h=harness();h.overlay(true);h.tap();h.frame();
    assert.equal(h.actions,0,'An overlay must block interaction');
  }],
  ['range-blocks-interaction',()=>{
    const h=harness();h.range(false);h.tap();h.frame();
    assert.equal(h.actions,0,'Existing 2.4 m range must remain enforced');
  }],
  ['held-key-retains-riding-level',()=>{
    const h=harness();h.down('KeyW');
    assert.equal(h.read('RIDIN.skankel'),1);
    h.up('KeyW');assert.equal(h.read('RIDIN.skankel'),0);
    h.down('KeyE');assert.equal(h.read('RIDIN.parad'),1);
    h.up('KeyE');assert.equal(h.read('RIDIN.parad'),0);
  }],
];

let failures=0;const failedNames=[];
for(const [name,run] of cases){
  try{run();console.log(`PASS ${name}`);}
  catch(e){failures++;failedNames.push(name);console.error(`FAIL ${name}: ${e.message}`);}
}
if(process.argv.includes('--baseline-red')){
  // A green baseline would mean the premise has changed. Do not claim the
  // old bug is reproduced if another change has already fixed it.
  assert.deepEqual(failedNames,['short-tap-between-frames','two-distinct-taps'],
    `Unexpected baseline result: ${failedNames.join(', ')}`);
  console.log('EXPECTED RED: production loses short taps; no gameplay fix applied.');
}else if(failures){process.exitCode=1;}
else console.log(`ALL PASS (${cases.length} production-path checks)`);
