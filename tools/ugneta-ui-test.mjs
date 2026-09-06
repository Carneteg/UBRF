#!/usr/bin/env node
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT=path.resolve(new URL(".",import.meta.url).pathname,"..");
const DIST=path.join(ROT,"dist"),PORT=8831;
const srv=http.createServer((q,s)=>{
  const raw=q.url.split("?")[0];
  const fil=raw==="/"?"/ridskolan.html":raw;
  const p=path.join(DIST,decodeURIComponent(fil));
  fs.readFile(p,(e,d)=>{if(e){s.writeHead(404);s.end();return;}s.writeHead(200,{"content-type":p.endsWith(".js")?"text/javascript":p.endsWith(".css")?"text/css":"text/html"});s.end(d);});
});
await new Promise(r=>srv.listen(PORT,r));

let fel=0;
function prova(ok,namn,detalj=""){
  if(ok)console.log(`OK   ${namn}${detalj?` — ${detalj}`:""}`);
  else{console.error(`FEL  ${namn}${detalj?` — ${detalj}`:""}`);fel++;}
}

const browser=await chromium.launch({headless:true,args:["--no-sandbox","--enable-unsafe-swiftshader"]});
const vyer=[
  {namn:"desktop",width:1366,height:768,minFont:13},
  {namn:"tablet",width:1024,height:768,minFont:13},
  {namn:"mobil",width:390,height:844,minFont:13},
  {namn:"landscape",width:844,height:390,minFont:12},
];

for(const vy of vyer){
  const page=await browser.newPage({viewport:{width:vy.width,height:vy.height}});
  page.on("pageerror",e=>console.error("PAGEERROR",vy.namn,e.message));
  await page.goto(`http://localhost:${PORT}/`,{waitUntil:"load"});
  await page.waitForTimeout(400);
  const r=await page.evaluate(()=>{
    if(typeof ugnetaKort!=="function")return {saknas:"ugnetaKort"};
    ugnetaKort({rubrik:"20 m volt",punkter:["Titta runt volten.","Inre skänkel — yttre tygel håller storleken."]},"test",4);
    const s=document.getElementById("saga"),wrap=s.closest(".hudh.bc");
    const box=s.getBoundingClientRect(),punkt=s.querySelector(".ugneta-punkt");
    const font=punkt?parseFloat(getComputedStyle(punkt).fontSize):0;
    const fore={
      punkter:s.querySelectorAll(".ugneta-punkt").length,
      klass:s.className,
      wrap:wrap?wrap.className:"",
      role:s.getAttribute("role"),label:s.getAttribute("aria-label"),
      font,box:{left:box.left,right:box.right,top:box.top,bottom:box.bottom,width:box.width,height:box.height},
      inner:{w:innerWidth,h:innerHeight},
      overflowX:document.documentElement.scrollWidth>innerWidth+1,
    };
    LARARE.ugnetaNasta=null;
    saga("STANNA – håll avstånd!",3);
    const efter={text:s.textContent,klass:s.className,wrap:wrap?wrap.className:""};
    return {fore,efter};
  });
  prova(!r.saknas,`${vy.namn}: Ugneta finns i byggd sida`,r.saknas||"");
  if(r.saknas){await page.close();continue;}
  const f=r.fore;
  prova(f.punkter===2,`${vy.namn}: exakt två korta punkter`,String(f.punkter));
  prova(f.font>=vy.minFont,`${vy.namn}: läsbar textstorlek`,`${f.font}px`);
  prova(!f.overflowX,`${vy.namn}: ingen horisontell overflow`);
  prova(f.box.left>=-1&&f.box.right<=f.inner.w+1&&f.box.top>=-1&&f.box.bottom<=f.inner.h+1,
    `${vy.namn}: lärarkortet ryms i viewport`,JSON.stringify(f.box));
  prova(f.role==="status"&&f.label&&f.label.includes("Ugneta"),`${vy.namn}: tillgänglig avsändare`);
  prova(!r.efter.klass.includes("ugneta-kort")&&!r.efter.wrap.includes("ugneta-wrap"),
    `${vy.namn}: säkerhetsmeddelande återställer vanlig UI`);
  prova(r.efter.text==="STANNA – håll avstånd!",`${vy.namn}: säkerhetsmeddelandet vinner`);
  await page.close();
}

await browser.close();
await new Promise(r=>srv.close(r));
if(fel){console.error(`\n${fel} Ugneta browser-kontroller föll.`);process.exit(1);}
console.log("\nALLA UGNETA BROWSER-KONTROLLER OK");
