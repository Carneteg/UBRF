#!/usr/bin/env node
/* Negativa kontroller för P0:s kartberedskap. Ingen spelkod ändras. */
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { chromium } from 'playwright';
import { p0KartaRedo, invantaP0Karta } from './p0-map-ready.mjs';

let antal = 0;
function kontroll(namn, fn) { fn(); antal++; console.log('OK', namn); }
const context = () => ({
 G: {scen:'gard',vy:'2d'},
 V2T:{scen:'gard',ox:10,oy:20,s:3,hojd:170},
 cv:{width:1280,height:720,getBoundingClientRect(){return {width:1280,height:720};}}
});
function ready(c,expected='gard') {
 return vm.runInNewContext(`(${p0KartaRedo.toString()})`,c)(expected);
}
kontroll('giltig ritad karta',()=>assert.equal(ready(context()),true));
kontroll('saknad transform är inte redo',()=>{const c=context();c.V2T.scen=null;assert.equal(ready(c),false);});
kontroll('gammal scen är inte redo',()=>{const c=context();c.V2T.scen='stallinne';assert.equal(ready(c),false);});
kontroll('förväntad scen måste vara aktuell',()=>{const c=context();c.G.scen='stallinne';assert.equal(ready(c),false);});
kontroll('3D är inte en färdig karta',()=>{const c=context();c.G.vy='3d';assert.equal(ready(c),false);});
for(const value of [0,-1,NaN,Infinity,-Infinity,'3'])
 kontroll(`ogiltig skala ${String(value)}`,()=>{const c=context();c.V2T.s=value;assert.equal(ready(c),false);});
for(const field of ['ox','oy','hojd'])
 kontroll(`ogiltigt ${field}`,()=>{const c=context();c.V2T[field]=NaN;assert.equal(ready(c),false);});
kontroll('nollhöjd är inte redo',()=>{const c=context();c.V2T.hojd=0;assert.equal(ready(c),false);});
kontroll('osynlig canvas är inte redo',()=>{const c=context();c.cv.getBoundingClientRect=()=>({width:0,height:0});assert.equal(ready(c),false);});
kontroll('saknad canvas är inte redo',()=>{const c=context();delete c.cv;assert.equal(ready(c),false);});
kontroll('beredskapskontroll muterar inte speltillstånd',()=>{
 const c=context(),before=JSON.stringify({G:c.G,V2T:c.V2T});ready(c);
 assert.equal(JSON.stringify({G:c.G,V2T:c.V2T}),before);
});

if(process.argv.includes('--unit')){
 console.log(`ALLA OK (${antal} enhetstester; browserprov ej körda)`);
}else{
 const browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--no-sandbox','--enable-unsafe-swiftshader']});
 try{
  const page=await browser.newPage();
  await page.setContent('<canvas id="cv" width="1280" height="720" style="width:100%;height:100%"></canvas>');
  await page.addScriptTag({content:`
   let G={scen:'gard',vy:'2d'};
   const V2T={scen:null,ox:0,oy:0,s:1,hojd:0};
   const cv=document.getElementById('cv');
  `});
  await page.evaluate(()=>setTimeout(()=>{
   V2T.scen='gard';V2T.ox=10;V2T.oy=20;V2T.s=3;V2T.hojd=170;
  },120));
  await invantaP0Karta(page,'gard',2000);
  antal++;console.log('OK', 'verklig browser väntar på färsk transform');
  await page.evaluate(()=>{V2T.scen=null;});
  await assert.rejects(invantaP0Karta(page,'gard',250),/Timeout/);
  antal++;console.log('OK', 'saknad transform ger timeout, inte PASS');
  await page.evaluate(()=>{V2T.scen='stallinne';});
  await assert.rejects(invantaP0Karta(page,'gard',250),/Timeout/);
  antal++;console.log('OK', 'fel scen ger timeout, inte PASS');
  await page.evaluate(()=>{V2T.scen='gard';V2T.s=0;});
  await assert.rejects(invantaP0Karta(page,'gard',250),/Timeout/);
  antal++;console.log('OK', 'ogiltig skala ger timeout, inte PASS');
  await page.close();
  console.log(`ALLA OK (${antal} mätningar)`);
 }finally{await browser.close();}
}
