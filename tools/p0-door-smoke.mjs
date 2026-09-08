#!/usr/bin/env node
/* Read-only gameplay QA: one genuine touch at the courtyard stable door.
   No direct writes to game state, navigation, progression or input levels. */
import {chromium,devices} from 'playwright';
import {invantaP0Karta} from './p0-map-ready.mjs';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';

const target='f2b527533f79a31b157b3f4bb6b4d719f546da6e';
const out=path.resolve(process.env.QA_OUT||'qa/p0-door-smoke');
fs.mkdirSync(out,{recursive:true});
const report={target,checks:[],events:[],errors:[],states:[]};
let server,browser,page;
function check(name,ok,details={}){
  report.checks.push({name,status:ok?'PASS':'FAIL',details});
  console.log(`${ok?'PASS':'FAIL'} ${name}`,JSON.stringify(details));
  if(!ok)throw Error(name);
}
async function state(){return page.evaluate(()=>({
  scene:G.scen,view:G.vy,overlay:!document.getElementById('ov').classList.contains('hide'),
  player:{x:VD.px,y:VD.py},prompt:VD.prompt?{text:VD.prompt.text,pos:VD.prompt.pos}:null,
  map:{ox:V2T.ox,oy:V2T.oy,s:V2T.s,h:V2T.hojd,scene:V2T.scen},
  pending:typeof InputImpulse!=='undefined'&&InputImpulse.has('KeyE'),
  keyDown:!!IN.ned.KeyE,doors:ANL.dorrar.filter(d=>d.mot==='stallinne').map(d=>({text:d.text,pos:d.pos}))
}));}
async function snap(name){
  const s=await state();report.states.push({name,...s});
  await page.screenshot({path:path.join(out,`${name}.png`),fullPage:true});
  return s;
}
async function main(){
  const dist=path.resolve('dist');
  server=http.createServer((req,res)=>{
    let file;
    try{file=path.resolve(dist,'.'+(decodeURIComponent(req.url.split('?')[0])==='/'?'/ridskolan.html':decodeURIComponent(req.url.split('?')[0])));
      if(!file.startsWith(dist+path.sep))throw Error('Bad path');
    }catch{res.writeHead(400);res.end();return;}
    fs.readFile(file,(e,data)=>{if(e){res.writeHead(404);res.end();return;}
      res.setHeader('Content-Type',file.endsWith('.html')?'text/html':file.endsWith('.js')?'text/javascript':'application/octet-stream');res.end(data);});
  });
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--no-sandbox','--enable-unsafe-swiftshader']});
  const context=await browser.newContext({...devices['iPad (gen 7) landscape'],serviceWorkers:'block'});
  page=await context.newPage();
  page.on('pageerror',e=>report.errors.push({type:'pageerror',message:e.message}));
  page.on('console',m=>{if(m.type()==='error')report.errors.push({type:'console',message:m.text()});});
  page.on('requestfailed',r=>report.errors.push({type:'request',url:r.url(),message:r.failure()?.errorText}));
  await page.goto(`http://127.0.0.1:${server.address().port}/ridskolan.html`,{waitUntil:'networkidle'});
  check('Real touch-capable Chromium',await page.evaluate(()=>PEKSKARM&&'ontouchstart'in window));
  const guest=page.locator('#bSkapHoppa');
  if(await guest.isVisible())await guest.click();
  await page.locator('#bStart').click();
  await page.waitForFunction(()=>G.scen==='gard'&&document.getElementById('ov').classList.contains('hide'),null,{timeout:10000});
  const initial=await snap('01-courtyard');
  check('Guest reaches courtyard through UI',initial.scene==='gard'&&!initial.overlay);
  const door=initial.doors.find(d=>d.text?.includes('stallet'))||initial.doors[0];
  check('Canonical stable door exists',!!door&&door.pos?.length===2,{door});
  if(initial.view!=='2d')await page.locator('#viewToggle [data-v="2d"]').click();
  await invantaP0Karta(page,'gard');
  const point=await page.evaluate(pos=>{
    const r=cv.getBoundingClientRect();return {x:r.left+V2T.ox+pos[0]*V2T.s,y:r.top+V2T.oy+(V2T.hojd-pos[1])*V2T.s,
      left:r.left,top:r.top,right:r.right,bottom:r.bottom};
  },door.pos);
  check('Door lies inside current map',point.x>=point.left&&point.x<=point.right&&point.y>=point.top&&point.y<=point.bottom,{point});
  await page.touchscreen.tap(point.x,point.y);
  await page.waitForFunction(pos=>G.scen==='gard'&&Math.hypot(VD.px-pos[0],VD.py-pos[1])<1.65,door.pos,{timeout:90000,polling:'raf'});
  await page.waitForFunction(()=>VD.prompt&&VD.prompt.text.includes('stallet'),null,{timeout:3000});
  const before=await snap('02-door-before');
  const distance=Math.hypot(before.player.x-door.pos[0],before.player.y-door.pos[1]);
  check('Player is in genuine interaction range',distance<2.4&&before.scene==='gard'&&!before.overlay,{distance,prompt:before.prompt});
  const use=page.locator('#pekGang [data-tap="KeyE"]');
  check('ANVÄND is visible and finger-sized',await use.isVisible()&&await use.evaluate(e=>e.getBoundingClientRect().height>=44));
  await page.evaluate(()=>{
    window.__doorQaEvents=[];
    const b=document.querySelector('#pekGang [data-tap="KeyE"]');
    for(const type of ['pointerdown','pointerup','pointercancel'])b.addEventListener(type,e=>window.__doorQaEvents.push({type:e.type,pointerType:e.pointerType}),{capture:true});
    for(const type of ['keydown','keyup'])window.addEventListener(type,e=>{if(e.code==='KeyE')window.__doorQaEvents.push({type:e.type,code:e.code,repeat:e.repeat});},{capture:true});
  });
  await use.tap();
  await page.waitForFunction(()=>G.scen==='stallinne',null,{timeout:3000,polling:'raf'});
  await page.waitForTimeout(180);
  const after=await snap('03-door-after');
  report.events=await page.evaluate(()=>window.__doorQaEvents);
  check('One short touch opens stable',after.scene==='stallinne'&&!after.pending,{scene:after.scene,events:report.events});
  check('Touch uses real pointer and keyboard event path',report.events.some(e=>e.type==='pointerdown'&&e.pointerType==='touch')&&report.events.some(e=>e.type==='pointerup')&&report.events.filter(e=>e.type==='keydown').length===1&&report.events.filter(e=>e.type==='keyup').length===1,{events:report.events});
  check('No stale action or unexpected page errors',report.errors.length===0,{errors:report.errors});
}
try{await main();}catch(e){report.failure=e.stack||String(e);console.error(report.failure);if(page)try{await snap('failure');}catch{}}
finally{report.status=report.failure||report.checks.some(c=>c.status==='FAIL')?'FAIL':'PASS';fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));if(browser)await browser.close();if(server)await new Promise(r=>server.close(r));}
if(report.status!=='PASS')process.exitCode=1;
