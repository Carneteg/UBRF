#!/usr/bin/env node
import { chromium, devices } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
const mode=process.argv[2]||'first-day';
const sha=process.env.QA_TARGET_SHA||'unknown';
const out=path.resolve(process.env.QA_OUT||`qa/p0-${mode}`);
fs.mkdirSync(out,{recursive:true});
const results=[];let page,browser,server,stage='boot';
function record(name,status,details={}){const x={name,status,details};results.push(x);console.log(JSON.stringify(x));}
async function state(){return page.evaluate(()=>({
 scene:G.scen,horse:G.hastId,horseName:HORSES[G.hastId]?.namn||null,
 horsePlace:G.hastPlats,met:G.hastMott,equipment:G.utrustning,care:!!G.skotselRes,
 ride:!!G.ride,pass:SPAR.pass,
 objective:typeof uppdragMal==='function'?(()=>{const u=uppdragMal();return u?{id:u.id,scene:u.mal?.scen,pos:u.mal?.pos,text:uppdragText()?.rubrik}:null;})():null,
 player:{x:VD.px,y:VD.py,z:VD.pz},
 prompt:VD.prompt?{text:VD.prompt.text,pos:VD.prompt.pos}:null,
 overlay:!document.getElementById('ov').classList.contains('hide'),
 buttons:[...document.querySelectorAll('#sheet button')].filter(e=>e.getClientRects().length).map(e=>({id:e.id,text:e.innerText,disabled:e.disabled})),
 view:G.vy,map:typeof V2T==='undefined'?null:{ox:V2T.ox,oy:V2T.oy,s:V2T.s,h:V2T.hojd,scene:V2T.scen},
 sceneDoors:(G.scen==='gard'?ANL.dorrar:G.scen==='stallinne'?STALLINNE.dorrar:G.scen==='ridhusinne'?RIDHUSINNE.dorrar:[]).filter(d=>d.mot&&d.mot!=='info').map(d=>({to:d.mot,pos:d.pos,text:d.text})),
 box:typeof hittaBox==='function'&&G.hastId?hittaBox(G.hastId):null
}));}
async function snap(name){const s=await state();fs.writeFileSync(path.join(out,`${name}.json`),JSON.stringify(s,null,2));await page.screenshot({path:path.join(out,`${name}.png`),fullPage:true});return s;}
async function button(selector){const b=page.locator(selector).first();if(await b.count()&&await b.isVisible()){await b.click();return true;}return false;}
async function key(code){await page.keyboard.press(code);await page.waitForTimeout(130);}
async function mapOn(){if((await state()).view!=='2d'&&!await button('#viewToggle [data-v="2d"]'))throw Error('Karta-knappen saknas');await page.waitForTimeout(250);}
async function walk(pos,label){
 await mapOn();const s=await state();if(!s.map||s.map.scene!==s.scene)throw Error('Kartan saknar aktuell transform');
 const t=await page.evaluate(p=>{const r=cv.getBoundingClientRect();return {x:r.left+V2T.ox+p[0]*V2T.s,y:r.top+V2T.oy+(V2T.hojd-p[1])*V2T.s,left:r.left,top:r.top,right:r.right,bottom:r.bottom};},pos);
 if(t.x<t.left||t.x>t.right||t.y<t.top||t.y>t.bottom)throw Error(`Målet ${label} ligger utanför kartan: ${JSON.stringify(t)}`);
 await page.mouse.click(t.x,t.y);let previous=s.player,still=0;
 for(let elapsed=0;elapsed<90000;elapsed+=250){
  await page.waitForTimeout(250);const q=await state();const d=Math.hypot(q.player.x-pos[0],q.player.y-pos[1]);
  if(d<1.65)return q;if(q.overlay)throw Error(`Overlay stoppar vandringen till ${label}`);
  if(Math.hypot(q.player.x-previous.x,q.player.y-previous.y)<0.02)still+=250;else still=0;
  if(still>6500)throw Error(`Fastnad på väg till ${label}: avstånd ${d.toFixed(2)}, ${JSON.stringify(q.player)}`);
  previous=q.player;
 }throw Error(`Timeout på väg till ${label}`);
}
async function interact(){const s=await state();if(!s.prompt)throw Error(`Ingen E-prompt vid ${stage}`);
 if(mode==='touch'){const b=page.locator('#pekGang [data-tap="KeyE"]');if(!await b.count()||!await b.isVisible())throw Error('Synlig ANVÄND-knapp saknas');await b.tap();}
 else await key('KeyE');await page.waitForTimeout(250);
}
async function goToScene(target){
 for(let i=0;i<5;i++){
  const s=await state();if(s.scene===target)return;
  const graph=await page.evaluate(()=>({gard:ANL.dorrar,stallinne:STALLINNE.dorrar,ridhusinne:RIDHUSINNE.dorrar}));
  const queue=[[s.scene,[]]],seen=new Set([s.scene]);let route=null;
  while(queue.length){const [current,p]=queue.shift();if(current===target){route=p;break;}
   for(const d of graph[current]||[]){if(!graph[d.mot]||seen.has(d.mot))continue;seen.add(d.mot);queue.push([d.mot,[...p,d.mot]]);}}
  if(!route?.length)throw Error(`Ingen scenrutt ${s.scene} → ${target}`);
  const d=s.sceneDoors.filter(x=>x.to===route[0]).sort((a,b)=>Math.hypot(a.pos[0]-s.player.x,a.pos[1]-s.player.y)-Math.hypot(b.pos[0]-s.player.x,b.pos[1]-s.player.y))[0];
  if(!d)throw Error(`Ingen dörr till ${route[0]}`);await walk(d.pos,d.text);await interact();
  if((await state()).scene===s.scene)throw Error(`Dörren ${d.text} bytte inte scen`);
 }throw Error(`För många scenbyten till ${target}`);
}
async function actOverlay(){
 const s=await state();if(!s.overlay)return false;
 if(await button('#bGroom')||await button('#bLek'))return true;
 if(await page.locator('.sk-val').count()){
  for(const typ of ['sadel','trans'])if(!await button(`.sk-val[data-id="${s.horse}"][data-typ="${typ}"]`))throw Error(`Rätt ${typ} för ${s.horse} saknas`);
  return button('#bSkKlar');
 }
 if(await button('#bHbStang')||await button('#bStart'))return true;
 for(const label of ['Sitt upp','Börja','Fortsätt','Gör i ordning','Sköt om','Klar','Tillbaka till stallgången']){
  const b=page.locator('#sheet button').filter({hasText:label}).first();if(await b.count()&&await b.isVisible()&&!await b.isDisabled()){await b.click();return true;}}
 return false;
}
async function firstDay(){
 stage='start';let s=await snap('00-menu');if(!s.overlay)throw Error('Startmenyn saknas');
 if(!await button('#bStart'))throw Error('Rid nu-knappen saknas');s=await snap('01-start');record('Gäststart via Rid nu','PASS',{scene:s.scene});
 if(mode==='touch'){
  const b=page.locator('#pekGang [data-tap="KeyE"]');record('Touch ANVÄND är synlig och fingerstor',await b.count()&&await b.isVisible()&&await b.evaluate(e=>e.getBoundingClientRect().height>=44)?'PASS':'FAIL');
 }
 for(let i=0;i<24;i++){
  s=await state();stage=`day-${i}-${s.objective?.id||s.scene}`;
  if(s.scene==='lektion'||s.scene==='bana'){
   record('Uppsittning genom verkligt flöde',s.ride?'PASS':'FAIL',{scene:s.scene,horse:s.horse,ride:s.ride});return s;
  }
  if(s.overlay){if(!await actOverlay())throw Error(`Ingen fortsättning i overlay: ${JSON.stringify(s.buttons)}`);await snap(`step-${String(i).padStart(2,'0')}`);continue;}
  const u=s.objective;if(!u?.pos||!u.scene)throw Error(`Uppdragsmål saknas: ${JSON.stringify(u)}`);
  await goToScene(u.scene);await walk(u.pos,u.text||u.id);await interact();await snap(`step-${String(i).padStart(2,'0')}`);
  const next=await state();if(next.horse&&!next.box)record('Aktiv häst har placerad box','FAIL',{horse:next.horse});
 }throw Error('Första dagen nådde inte ridning inom 24 spelarhandlingar');
}
async function riding(){
 const s=await firstDay();if(s.scene!=='lektion'||!s.ride)throw Error('Ridtest BLOCKED: ingen uppsittning');stage='riding';
 for(const c of ['KeyW','KeyW','KeyA','KeyD','KeyS','KeyE']){await key(c);await page.waitForTimeout(600);}
 const r=await snap('riding-input');record('Ridinput och aktiv ridloop',r.ride?'PASS':'FAIL',{scene:r.scene,horse:r.horse});
 await key('KeyT');await snap('riding-training-book');record('Träningsboken öppnas från sadeln',(await state()).overlay?'PASS':'FAIL');
}
async function main(){
 const url=process.env.QA_URL;
 if(!url){const dist=path.resolve('dist');server=http.createServer((req,res)=>{let file;try{file=path.resolve(dist,'.'+decodeURIComponent(req.url.split('?')[0]==='/'?'/ridskolan.html':req.url.split('?')[0]));if(!file.startsWith(dist+path.sep))throw Error();}catch{res.writeHead(400);res.end();return;}fs.readFile(file,(e,d)=>{if(e){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':file.endsWith('.html')?'text/html':'application/octet-stream');res.end(d);});});await new Promise(r=>server.listen(0,'127.0.0.1',r));}
 browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--no-sandbox','--enable-unsafe-swiftshader']});
 const context=await browser.newContext(mode==='touch'?{...devices['iPad (gen 7) landscape'],serviceWorkers:'block'}:{viewport:{width:1280,height:720},serviceWorkers:'block'});
 await context.clearCookies();page=await context.newPage();
 page.on('pageerror',e=>record('PAGEERROR','FAIL',{message:e.message,stage}));
 page.on('console',m=>{if(m.type()==='error')record('CONSOLE_ERROR','FAIL',{message:m.text(),stage});});
 page.on('requestfailed',r=>record('REQUEST_FAILED','FAIL',{url:r.url(),error:r.failure()?.errorText}));
 await page.goto(url||`http://127.0.0.1:${server.address().port}/ridskolan.html`,{waitUntil:'networkidle'});await page.waitForTimeout(700);
 const boot=await state();record('Exakt testversion','INFO',{sha,mode,scene:boot.scene,horseCount:await page.evaluate(()=>Object.keys(HORSES).length)});
 if(mode==='riding')await riding();else await firstDay();
}
try{await main();}catch(e){record(stage==='boot'?'Testmiljö':'Spelflöde','FAIL',{stage,error:e.stack||String(e)});if(page)try{await snap('failure');}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({sha,mode,results},null,2));if(browser)await browser.close();if(server)await new Promise(r=>server.close(r));}
if(results.some(r=>r.status==='FAIL'))process.exitCode=1;
