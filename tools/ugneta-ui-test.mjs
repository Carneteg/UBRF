#!/usr/bin/env node
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT=path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
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

/* Samma binärupplösning som repots övriga browsertester (gardtest,
   ridtest, uppdragstest): en förinstallerad Chromium används när den
   finns, annars Playwrights egen. CI installerar sin egen och träffar
   fallbacken; lokalt finns bara /opt/pw-browsers, och utan det här
   kunde provet inte köras alls före push. Inget villkor är ändrat. */
const PW_EXE=process.env.CHROMIUM||"/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser=await chromium.launch({headless:true,
  executablePath:fs.existsSync(PW_EXE)?PW_EXE:undefined,
  args:["--no-sandbox","--enable-unsafe-swiftshader"]});
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

  /* ── KONTROLLHJÄLPEN (G02-D, review på #151) ────────────────────
     Tobias frågade hur man sitter upp, byter gångart och hoppar. Hjälpen
     svarar — och den ska svara med webbens EGNA reglage, rymmas i
     viewporten och gå att stänga utan tangentbord.

     De två raderna utan reglage är avsiktliga och provas som sådana:
     webben har ingen gångartsknapp (gångarten följer skänkel och tygel)
     och inget hoppreglage (avsprånget kommer ur anridningen). En hjälp
     som hittade på en tangent för dem hade påstått en paritet med Roblox
     som inte finns. */
  const h=await page.evaluate(()=>{
    if(typeof visaKontrollHjalp!=="function")return {saknas:"visaKontrollHjalp"};
    visaKontrollHjalp();
    const el=document.getElementById("kontrollhjalp");
    if(!el)return {saknas:"#kontrollhjalp"};
    const rader=kontrollRader();
    const box=el.getBoundingClientRect();
    const kn=el.querySelector("#khStang");
    const knBox=kn?kn.getBoundingClientRect():null;
    const karta={};for(const r of rader)karta[r.vad]=r.reglage;
    return {
      synlig:kontrollHjalpSynlig(), antal:rader.length, karta,
      inmatning:kontrollInmatning(),
      utan:rader.filter(r=>!r.reglage).map(r=>r.vad),
      box:{l:box.left,r:box.right,t:box.top,b:box.bottom},
      inner:{w:innerWidth,h:innerHeight},
      knHojd:knBox?knBox.height:0,
      knText:kn?kn.textContent:"",
      overflowX:document.documentElement.scrollWidth>innerWidth+1,
    };
  });
  prova(!h.saknas,`${vy.namn}: kontrollhjälpen finns i byggd sida`,h.saknas||"");
  if(!h.saknas){
    prova(h.synlig&&h.antal>=8,`${vy.namn}: hjälpen visar reglagen`,
      `${h.antal} rader`);
    prova(h.karta["Sitt upp / använd"]==="E",
      `${vy.namn}: hjälpen svarar hur man sitter upp`,h.karta["Sitt upp / använd"]);
    prova(h.karta["Tygel (kontakt)"]==="Mellanslag",
      `${vy.namn}: …och vad tygeln är`,h.karta["Tygel (kontakt)"]);
    /* Gångart och hopp SKA sakna reglage på webben. */
    prova(h.utan.includes("Gångart")&&h.utan.includes("Hoppa"),
      `${vy.namn}: gångart och hopp anges utan uppfunnen tangent`,
      h.utan.join(", "));
    prova(h.box.l>=-1&&h.box.r<=h.inner.w+1&&h.box.t>=-1&&h.box.b<=h.inner.h+1,
      `${vy.namn}: hjälpen ryms i viewporten`,JSON.stringify(h.box));
    prova(!h.overflowX,`${vy.namn}: hjälpen ger ingen horisontell overflow`);
    prova(h.knHojd>=44,`${vy.namn}: stängknappen är minst 44 px`,
      `${Math.round(h.knHojd)}px`);
    const dolt=await page.evaluate(()=>{
      document.getElementById("khStang").click();
      return kontrollHjalpSynlig();
    });
    prova(dolt===false,`${vy.namn}: knappen stänger hjälpen utan tangentbord`);
  }
  await page.close();
}

await browser.close();
await new Promise(r=>srv.close(r));
if(fel){console.error(`\n${fel} Ugneta browser-kontroller föll.`);process.exit(1);}
console.log("\nALLA UGNETA BROWSER-KONTROLLER OK");
