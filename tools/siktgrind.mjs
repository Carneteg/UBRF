#!/usr/bin/env node
/* Siktgrinden (issue #78 § 3): spelaren får inte bli DOLD bakom
   förgrundsgeometri under normal inomhusnavigation.

   Mätningen är v3dSiktProv i src/varld3d.js: sträckor från kameran till
   höft, bröst och huvud genom varje opak statisk triangel, med samma
   toningsregel (v3dTonas) som ritningen. Ett nät som skymmer och INTE
   tonas är ett fel; två av tre kroppspunkter bakom sådant = DOLD = rött.

   Provet tas (1) i varje reviewkamera och (2) längs gångrutterna genom
   interiörerna, med figuren teleporterad i steg om ~1 m och kameran
   snappad bakom henne som vid ett scenbyte. Det är spelets egen kamera,
   inte en fri kamera.

   NEGATIV KONTROLL, varje körning: toningen stängs av i sidan
   (v3dTonas = () => false) och provet körs om — då MÅSTE minst en punkt
   bli DOLD, annars mäter grinden ingenting och avslutar rött. Det är
   "minst en avsiktlig visibility-regression ger röd gate" (#78 Acceptance).

   Grinden ändrar ingen geometri: rummen får inte flyttas för att lösa
   skymning (CLAUDE.md), det är renderingen som ska ge vika.

   Kör: python3 tools/build.py && node tools/siktgrind.mjs */
import { lasKameror, oppnaWebb, stallKamera, lasLage } from "./qa-webb.mjs";

/* Gångrutterna: punkter i husets meter (uttryck i S/R/SA), i rät linje
   mellan varandra, med figuren vänd i färdriktningen. z = nivån hon står
   på (trappor/bänkrader/läktardäck), tolkad som i gaTill. */
const RUTTER = [
  { id: "stall: entrén → uppehållsrummet → inre entrén → gång A → hästgången", scen: "stallinne", steg: 1.0, punkter: [
    { x: "4.55", y: "S.langd - 1.55" }, { x: "4.55", y: "60.5" }, { x: "4.55", y: "56.5" },
    { x: "(S.gangar.A.x0+S.gangar.A.x1)/2", y: "52.0" }, { x: "(S.gangar.A.x0+S.gangar.A.x1)/2", y: "S.dorrar.find(d=>d.id==='hastgang').pos[1]" },
    { x: "1.6", y: "S.dorrar.find(d=>d.id==='hastgang').pos[1]" } ] },
  { id: "stall: gång A söderut till servicedelen", scen: "stallinne", steg: 1.5, punkter: [
    { x: "(S.gangar.A.x0+S.gangar.A.x1)/2", y: "S.klubbY - 1" }, { x: "(S.gangar.A.x0+S.gangar.A.x1)/2", y: "S.serviceY + 1" } ] },
  { id: "ridhus: huvudentrén → hallen → sargporten → banan", scen: "ridhusinne", steg: 1.0, punkter: [
    { x: "1.3", y: "67.0" }, { x: "2.8", y: "69.5" }, { x: "2.8", y: "75.0" }, { x: "(SA.ridhus.sargport.x0+SA.ridhus.sargport.x1)/2", y: "71.0" },
    { x: "(SA.ridhus.sargport.x0+SA.ridhus.sargport.x1)/2", y: "SA.ridhus.sargport.y - 3" } ] },
  { id: "ridhus: hallen → bänkradssteg → raderna → c_trappa_v → övre gången", scen: "ridhusinne", steg: 0.8, punkter: [
    { x: "SA.ridhus.bankradSteg.x0 - 0.6", y: "(SA.ridhus.bankradSteg.y0+SA.ridhus.bankradSteg.y1)/2" },
    { x: "SA.ridhus.bankradSteg.x1 + 0.6", y: "(SA.ridhus.bankradSteg.y0+SA.ridhus.bankradSteg.y1)/2", z: "SA.ridhus.bankradSteg.z1" },
    { x: "(R.trappor[0].x0+R.trappor[0].x1)/2", y: "R.kortanda.y0 + 0.5", z: "SA.ridhus.bankradSteg.z1" },
    { x: "(R.trappor[0].x0+R.trappor[0].x1)/2", y: "R.kortanda.y1 - R.kortanda.trappB - 0.3", z: "(R.kortanda.sockelH||0)+R.kortanda.steg*R.kortanda.stegH" },
    { x: "R.trappor[0].x1 - 0.3", y: "(R.trappor[0].y0+R.trappor[0].y1)/2", z: "R.trappor[0].z0" },
    { x: "R.trappor[0].x0 + 0.3", y: "(R.trappor[0].y0+R.trappor[0].y1)/2", z: "R.trappor[0].z1" },
    { x: "R.trappor[0].x0 + 0.3", y: "R.ovreGang.y0 + 1.2", z: "R.ovreGang.z" },
    { x: "R.ovreGang.x1 - 4", y: "R.ovreGang.y0 + 1.2", z: "R.ovreGang.z" } ] },
  { id: "ridhus: hallen → läktarsteg → däcket → läktartrappan vid H → övre gångens västarm", scen: "ridhusinne", steg: 0.8, punkter: [
    { x: "R.laktare.x0 + R.laktare.dackDjup - 0.5", y: "R.laktare.y1 + 1.8" },
    { x: "R.laktare.x0 + R.laktare.dackDjup - 0.5", y: "R.laktare.y1 - 0.6", z: "R.laktare.dackZ" },
    { x: "R.laktare.x0 + 0.5", y: "R.laktare.y1 - 0.6", z: "R.laktare.dackZ + R.laktare.rader.antal*R.laktare.rader.stegH" },
    { x: "R.laktare.x0 + 0.5", y: "R.laktare.y1 + 0.4", z: "R.cafe.z0" },
    { x: "R.laktare.x0 + 0.5", y: "R.ovreGang.y0 + 0.6", z: "R.cafe.z0" } ] },
  { id: "ridhus: läktardäcket", scen: "ridhusinne", steg: 4.0, punkter: [
    { x: "R.laktare.x0 + R.laktare.dackDjup/2", y: "R.laktare.y0 + 3", z: "R.laktare.dackZ" },
    { x: "R.laktare.x0 + R.laktare.dackDjup/2", y: "R.laktare.y1 - 3", z: "R.laktare.dackZ" } ] },
];

const w = await oppnaWebb({ port: 8793, siktprov: true });
const varde = async (scen, e) => w.page.evaluate(({ e }) => {
  const S = STALLINNE, R = RIDHUSINNE, SA = SPELABSTRAKTIONER, A = ANL;
  return e === undefined ? 0 : (typeof e === "number" ? e : Function("S", "R", "SA", "A", "Math", `return (${e})`)(S, R, SA, A, Math));
}, { e });

/* Provpunkterna: kamerorna + rutterna utsamplade. */
const prov = [];
for (const k of lasKameror()) prov.push({ id: `kamera ${k.id}`, scen: k.scen, lage: k.lage });
for (const r of RUTTER) {
  const P = [];
  for (const p of r.punkter) P.push({ x: await varde(r.scen, p.x), y: await varde(r.scen, p.y), z: await varde(r.scen, p.z) });
  for (let i = 0; i + 1 < P.length; i++) {
    const a = P[i], b = P[i + 1], L = Math.hypot(b.x - a.x, b.y - a.y), n = Math.max(1, Math.round(L / r.steg));
    const rikt = Math.atan2(b.y - a.y, b.x - a.x);
    for (let j = (i === 0 ? 0 : 1); j <= n; j++) {
      const t = j / n;
      prov.push({ id: `${r.id} [${i}.${j}]`, scen: r.scen, lage: { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t, z: a.z + (b.z - a.z) * t, rikt } });
    }
  }
}

async function kor(sabotage) {
  if (sabotage) await w.page.evaluate(() => { window.__tonasOrig = v3dTonas; v3dTonas = () => false; });
  const ut = [];
  for (const p of prov) {
    await stallKamera(w.page, p, 100);
    /* En ruttpunkt som hamnar INNE i ett hinder (en stolpe, ett räcke)
       är teleportens artefakt — dit går man inte i spelet. Hoppas över,
       räknas. */
    const knuff = await w.page.evaluate(() => { const [x, y] = vandringKollision(VD.px, VD.py, GA.radie, VD.px, VD.py); return Math.hypot(x - VD.px, y - VD.py); });
    if (knuff > 0.15) { ut.push({ id: p.id, hoppad: true, knuff }); continue; }
    const s = await w.page.evaluate(() => v3dSiktProv());
    const info = await lasLage(w.page);
    ut.push({ id: p.id, spelare: info.spelare, kamera: info.kamera, dold: s.dold, delvis: s.delvis, tonade: s.tonade, skymmande: s.skymmande, utanData: s.utanData });
  }
  if (sabotage) await w.page.evaluate(() => { v3dTonas = window.__tonasOrig; });
  return ut;
}

console.log(`Siktgrinden: ${prov.length} provpunkter (${lasKameror().length} kameror + ${prov.length - lasKameror().length} ruttpunkter)`);
const res = await kor(false);
let dolda = 0, delvis = 0, utanData = 0, hoppade = 0;
for (const r of res) {
  if (r.hoppad) { hoppade++; continue; }
  if (r.dold) { dolda++; console.log(`  FEL  DOLD    ${r.id} — spelare ${JSON.stringify(r.spelare)} kamera ${JSON.stringify(r.kamera)} skymmande nät ${JSON.stringify(r.skymmande.map(s => ({ nat: s.nat, punkter: s.punkter, vid: s.vid[0] })))}`); }
  else if (r.delvis) { delvis++; console.log(`  obs  delvis  ${r.id} — ${JSON.stringify(r.skymmande.map(s => ({ nat: s.nat, punkter: s.punkter })))}`); }
  utanData += r.utanData;
}
console.log(`  ${res.length - dolda - delvis - hoppade} synliga, ${delvis} delvis skymda (tillåtet), ${dolda} DOLDA, ${hoppade} inne i hinder (hoppade)${utanData ? `, ${utanData} nät utan triangeldata (SIKTPROV saknades?)` : ""}`);
if (utanData) { console.log("FEL: nät utan triangeldata — SIKTPROV sattes inte före scenbygget"); await w.stang(); process.exit(1); }

/* Negativ kontroll. */
const neg = await kor(true);
const negDolda = neg.filter(r => !r.hoppad && r.dold).length;
console.log(`Negativ kontroll (toningen avstängd): ${negDolda} DOLDA av ${neg.length} — ${negDolda > 0 ? "grinden kan bli röd" : "GRINDEN MÄTER INGENTING"}`);
await w.stang();
if (w.fel.length) { console.log("SIDFEL:"); for (const f of w.fel) console.log("  " + f); process.exit(1); }
if (dolda > 0 || negDolda === 0) { console.log(dolda > 0 ? `FEL: figuren dold i ${dolda} provpunkt(er)` : "FEL: den negativa kontrollen blev inte röd"); process.exit(1); }
console.log("ALLA OK — figuren syns i alla provpunkter och grinden kan bli röd");
