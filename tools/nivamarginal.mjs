#!/usr/bin/env node
/* NIVÅMARGINALEN VID UPPGÅNGENS TOPP — deterministiskt, utan promenad.

   Falsifieringen av bandningen via poflode visade sig otillräcklig: den
   obandade rampen gick igenom ändå, eftersom felet den orsakar är
   intermittent. Ett prov som bara ibland blir rött bevisar ingenting.

   Felet är däremot inte statistiskt utan aritmetiskt, och då ska det mätas
   som aritmetik. Räkningen: när figuren tar sista steget AV rampen jämförs
   däckets nivå i landningspunkten med hennes egen z på rampen. Är
   skillnaden större än NIVA_STEG spärras steget, och hon står kvar strax
   under toppen — precis det reviewn mätte som "x ≈ 3,00, z ≈ 0,73".

   Här räknas marginalen för varje x tvärs uppgången, med ett steg som
   motsvarar en frames förflyttning. Kravet är att INGEN punkt tvärs
   uppgången får ha en marginal som spärrar. */
import fs from "node:fs"; import path from "node:path"; import vm from "node:vm";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const NIVA_STEG = 0.36;
const STEG = 0.15;            // en frames förflyttning i gånghastighet
const ctx = vm.createContext({ console, Math, JSON, STEG, clamp:(v,a,b)=>Math.max(a,Math.min(b,v)) });
for (const f of ["src/model.js", "src/data.js", "src/site.js"])
  vm.runInContext(fs.readFileSync(path.join(ROT, f), "utf8"), ctx, { filename: f });

const bild = vm.runInContext(`(() => {
  const R=RIDHUSINNE, L=R.laktare, S=SPELABSTRAKTIONER.ridhus, bank=L.x0+L.dackDjup;
  const band=[S.laktarSteg, S.laktarStegRad1].filter(t=>t&&t.x1>t.x0);
  const rader=laktarRader(L);
  /* Däckets nivå i en punkt söder om uppgången, samma regel som world.js. */
  const dackNiva=(x)=>{ let z=L.dackZ; const inn=bank-x;
    for(const r of rader) if(inn>=r.in0&&inn<=r.in1) z=r.z; return z; };
  /* Rampens nivå i (x,y): det band punkten ligger i. */
  const rampNiva=(x,y)=>{ for(const t of band)
    if(x>=t.x0&&x<=t.x1&&y>=t.y0&&y<=t.y1) return t.z1*(t.y1-y)/(t.y1-t.y0);
    return null; };
  return { x0:Math.min(...band.map(b=>b.x0)), x1:Math.max(...band.map(b=>b.x1)),
    y0:band[0].y0, dackNiva:dackNiva.toString(), rampNiva:rampNiva.toString(),
    prov:(()=>{ const ut=[];
      for(let x=Math.min(...band.map(b=>b.x0))+0.05; x<=Math.max(...band.map(b=>b.x1))-0.05; x+=0.10){
        /* Sista punkten PÅ rampen innan steget tar henne av den. */
        const yAv=band[0].y0, yPa=yAv+STEG;
        const zPa=rampNiva(x,yPa), zMal=dackNiva(x);
        if(zPa===null) continue;
        ut.push({x:+x.toFixed(2), zPa:+zPa.toFixed(3), zMal:+zMal.toFixed(2), d:+(zMal-zPa).toFixed(3)});
      } return ut; })() };
})()`, ctx);

let varst = null;
for (const p of bild.prov) if (!varst || p.d > varst.d) varst = p;
const spärrade = bild.prov.filter(p => p.d > NIVA_STEG);
console.log(`uppgången x ${bild.x0.toFixed(2)}–${bild.x1.toFixed(2)}, ${bild.prov.length} punkter provade`);
console.log(`värsta steget av rampen: x ${varst.x}  z ${varst.zPa} → däck ${varst.zMal}  = ${varst.d} m`);
console.log(`nivåregeln tillåter ${NIVA_STEG} m`);
if (spärrade.length) {
  console.log(`  FEL  ${spärrade.length} av ${bild.prov.length} punkter tvärs uppgången spärras:`);
  for (const p of spärrade.slice(0, 8)) console.log(`         x ${p.x}: ${p.d} m > ${NIVA_STEG}`);
  process.exit(1);
}
console.log(`  OK   hela uppgångens bredd går att lämna uppåt (marginal ${(NIVA_STEG - varst.d).toFixed(3)} m kvar)`);
