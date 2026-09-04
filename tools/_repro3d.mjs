import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const DIST="/home/user/UBRF/dist", PORT=8811;
const M={".html":"text/html",".js":"text/javascript",".css":"text/css",".png":"image/png",".jpg":"image/jpeg",".json":"application/json"};
const srv=http.createServer((q,s)=>{const p=path.join(DIST,decodeURIComponent(q.url.split("?")[0]==="/"?"/ridskolan.html":q.url.split("?")[0]));fs.readFile(p,(e,d)=>{if(e){s.writeHead(404);s.end();return;}s.writeHead(200,{"content-type":M[path.extname(p)]||"application/octet-stream"});s.end(d);});});
await new Promise(r=>srv.listen(PORT,r));
const b=await chromium.launch({executablePath:"/opt/pw-browsers/chromium-1194/chrome-linux/chrome",args:["--use-angle=swiftshader","--no-sandbox","--enable-unsafe-swiftshader"]});
const page=await b.newPage({viewport:{width:1280,height:720}});
page.on("pageerror",e=>console.log("PAGEERROR",e.message));
await page.goto(`http://localhost:${PORT}/`,{waitUntil:"load"}); await page.waitForTimeout(1800);
await page.evaluate(()=>startaVandring()); await page.waitForTimeout(600);
await page.evaluate(()=>{ if(G.vy!=="3d") vaxlaVy(); }); await page.waitForTimeout(400);
const I=await page.evaluate(()=>{const R=RIDHUSINNE,L=R.laktare,ls=SPELABSTRAKTIONER.ridhus.laktarSteg;
  return {ls:{x0:+ls.x0.toFixed(2),x1:+ls.x1.toFixed(2),y0:+ls.y0.toFixed(2),y1:+ls.y1.toFixed(2)},
          L:{dackZ:L.dackZ,y1:+L.y1.toFixed(2),x0:+L.x0.toFixed(2),d:+L.dackDjup.toFixed(2)}};});
console.log("stegremsa x", I.ls.x0, "→", I.ls.x1, `(bredd ${(I.ls.x1-I.ls.x0).toFixed(2)} m)`, "y", I.ls.y0, "→", I.ls.y1, "| däck x", I.L.x0, "→", (I.L.x0+I.L.d).toFixed(2), "dackZ", I.L.dackZ);
console.log("Går söderut med W i 3D från y=", (I.ls.y1+1.0).toFixed(2), "vid olika x:");
for (let x=0.8; x<=6.2; x+=0.4){
  await page.evaluate(({x,y})=>{ slutaGa(); gaTill("ridhusinne",{x,y,rikt:-Math.PI/2,z:0}); },{x:+x.toFixed(2),y:I.ls.y1+1.0});
  await page.waitForTimeout(450);
  await page.evaluate(()=>{ VD.rikt=-Math.PI/2; if(V3D&&V3D.kam) V3D.kam.satt=false; }); await page.waitForTimeout(350);
  await page.keyboard.down("KeyW");
  const t0=Date.now(); let mz=0, sl=null;
  while(Date.now()-t0<4200){ await page.waitForTimeout(300);
    sl=await page.evaluate(()=>({x:+VD.px.toFixed(2),y:+VD.py.toFixed(2),z:+(VD.pz||0).toFixed(2)})); if(sl.z>mz)mz=sl.z; }
  await page.keyboard.up("KeyW"); await page.waitForTimeout(120);
  console.log(`  x=${x.toFixed(1)}  → (${sl.x}, ${sl.y}) z=${sl.z} maxZ=${mz.toFixed(2)}  ${mz>=I.L.dackZ-0.02?"UPP ✔":"blockerad ✘"}`);
}
await b.close(); srv.close();
