import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const src=fs.readFileSync(new URL('../src/input-impulse.js',import.meta.url),'utf8');
vm.runInThisContext(src,{filename:'src/input-impulse.js'});
const I=globalThis.InputImpulse;

function reset(){ I.clearAll(); }
function test(name,fn){ reset(); fn(); console.log(`OK ${name}`); }

test('kort tryck överlever tills det konsumeras',()=>{
  I.press('KeyE','gard');
  assert.equal(I.consume('KeyE','gard'),true);
  assert.equal(I.consume('KeyE','gard'),false);
});

test('långt håll representeras fortfarande som en enda impuls',()=>{
  I.press('KeyE','gard');
  assert.equal(I.has('KeyE'),true);
  assert.equal(I.consume('KeyE','gard'),true);
  assert.equal(I.consume('KeyE','gard'),false);
});

test('dubbeltryck före nästa sampling kollapsar till exakt en impuls',()=>{
  I.press('KeyE','gard');
  I.press('KeyE','gard');
  assert.equal(I.consume('KeyE','gard'),true);
  assert.equal(I.consume('KeyE','gard'),false);
});

test('impuls från gammal scen får inte läcka till ny scen',()=>{
  I.press('KeyE','gard');
  assert.equal(I.consume('KeyE','stallinne'),false);
  assert.equal(I.has('KeyE'),false);
});

test('clear tar bort väntande impuls',()=>{
  I.press('KeyE','gard');
  I.clear('KeyE');
  assert.equal(I.consume('KeyE','gard'),false);
});

test('olika knappar hålls separata',()=>{
  I.press('KeyE','gard');
  I.press('KeyV','gard');
  assert.equal(I.consume('KeyV','gard'),true);
  assert.equal(I.consume('KeyE','gard'),true);
});

console.log('ALLA OK (6 mätningar)');
