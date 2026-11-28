/* STALLGÅNGENS TAK BAKOM STRÖMBRYTAREN — Batch 1.6 (webb).

   Kortet (references/buildings/stall/KORT.md, rättat i Batch 1.1) säger:
   lutande limträsparrar som följer takfallet, lanternin längs nocken,
   inga vågräta tvärbalkar. Spelet bygger en vågrät tvärbalk var fjärde
   meter, en nockbalk och takfönster i västra fallet.

   Med `?realism=1` byggs taket efter kortet. UTAN brytaren ska stallet
   byggas exakt som förut — det är det provet framför allt mäter.

   Mätmetod: provet lyssnar på varje `Bygge.lada` och `Bygge.cyl` medan
   stallscenen byggs och läser alltså GEOMETRIN som byggs, inte en bild.

     1. AV: den gamla stommen finns kvar (tvärbalkar, nockbalk,
        takfönster), och två byggen ger samma fingeravtryck.
     2. PÅ: inga vågräta tvärbalkar, ingen nockbalk, inga takfönster i
        fallet; sparrar på båda takfallen som följer lutningen; en
        lanternin i nocken; takskivorna lämnar nocken öppen.
     3. Allt som INTE är tak är detsamma i båda lägena.

   Fingeravtrycket för AV-läget skrivs ut. Det jämfördes för hand mot
   bygget före ändringen (se docs/ACTIVE-GATE.md); den löpande vakten för
   standardutseendet är den visuella grinden, kamera STALL-GANG-A.

   Falsifiering:
     --muter-lacka   brytaren läcker: taket byggs om även utan parametern
     --muter-balk    realism-läget bygger ändå de vågräta tvärbalkarna

   Kör: python3 tools/build.py && node tools/stalltaktest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const byt = (s, fran, till) => {
  if (!s.includes(fran)) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
  return s.replace(fran, till);
};
const DIST = path.join(ROT, "dist"), PORT = 8947;
const srv = http.createServer((q, s) => {
  if (q.url.split("?")[0] !== "/") { s.writeHead(404); s.end(); return; }
  let html = fs.readFileSync(path.join(DIST, "ridskolan.html"), "utf8");
  if (arg.has("--muter-lacka")) html = byt(html, "const REALTAK=(typeof REALISM!==\"undefined\")&&REALISM.pa;", "const REALTAK=true;");
  if (arg.has("--muter-balk")) html = byt(html, "if(!REALTAK)stomme.lada(S.bredd,0.26,0.22,", "stomme.lada(S.bredd,0.26,0.22,");
  s.writeHead(200, { "content-type": "text/html" }); s.end(html);
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });

/* Bygg stallscenen och lämna tillbaka varje låda och cylinder som byggdes. */
async function bygg(fraga) {
  const page = await (await browser.newContext({ viewport: { width: 1180, height: 820 } })).newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/${fraga}`, { waitUntil: "load" });
  const ut = await page.evaluate(() => new Promise(klar => {
    const logg = [], r = v => Math.round(v * 1000) / 1000;
    const lada0 = Bygge.prototype.lada, cyl0 = Bygge.prototype.cyl;
    Bygge.prototype.lada = function (w, h, d, farg, mat) {
      logg.push(["lada", r(w), r(h), r(d), String(farg), mat ? Array.from(mat, r) : null]);
      return lada0.apply(this, arguments);
    };
    Bygge.prototype.cyl = function (r1, r2, h, farg, mat) {
      logg.push(["cyl", r(r1), r(r2), r(h), String(farg), mat ? Array.from(mat, r) : null]);
      return cyl0.apply(this, arguments);
    };
    overlay(false); SPAR.pass = 3; startaVandring();
    let n = 0, start = -1, stilla = 0, forra = -1;
    (function ruta() {
      n++;
      if (n === 8) { start = logg.length; const d = STALLINNE.dorrar[0]; gaTill("stallinne", { x: d.pos[0], y: d.pos[1], rikt: 0 }); }
      if (n > 8) { stilla = logg.length === forra ? stilla + 1 : 0; forra = logg.length; }
      if (n > 8 && stilla >= 6 && logg.length > start) {
        const S = STALLINNE;
        return klar({ logg: logg.slice(start), scen: G.scen, realism: REALISM.pa,
          S: { bredd: S.bredd, langd: S.langd, tak: S.tak, resn: S.takresning, limtra: IDENTITET.stall.stallgang.limtra } });
      }
      if (n > 400) return klar({ logg: logg.slice(Math.max(start, 0)), scen: G.scen, realism: REALISM.pa, tog_slut: true, S: {} });
      requestAnimationFrame(ruta);
    })();
  }));
  await page.context().close();
  return ut;
}
const avtryck = logg => crypto.createHash("sha256").update(JSON.stringify(logg)).digest("hex").slice(0, 16);
const nara = (a, b, t = 0.011) => Math.abs(a - b) <= t;

/* Läs ut takets delar ur byggloggen. `mat` är kolumnordnad 4×4: läget står
   i [12],[13],[14]; lutningen kring z-axeln är atan2(mat[1], mat[0]). */
function tak(B) {
  const S = B.S, L = B.logg.filter(x => x[0] === "lada");
  const halvB = S.bredd / 2, takV = Math.atan2(S.resn, halvB), nock = S.tak + S.resn;
  const lut = m => Math.atan2(m[1], m[0]);
  const tvarbalkar = L.filter(x => nara(x[1], S.bredd) && nara(x[2], 0.26) && nara(x[3], 0.22));
  const nockbalk = L.filter(x => nara(x[1], 0.20) && nara(x[2], 0.24) && nara(x[3], S.langd));
  const takfonster = L.filter(x => nara(x[1], 1.5) && nara(x[2], 0.10) && nara(x[3], 0.85));
  /* Lutande träbalkar: smala (djup ≤ 0,2 m), långa (≥ 3 m), lutade som takfallet. */
  const lutande = L.filter(x => x[5] && x[3] <= 0.2 && x[1] >= 3 && nara(Math.abs(lut(x[5])), takV, 0.02));
  const skivor = L.filter(x => x[5] && nara(x[2], 0.14) && x[3] >= S.langd && nara(Math.abs(lut(x[5])), takV, 0.02));
  /* Ljusa stående ytor nära nocken = lanterninens glas. */
  const lanternin = L.filter(x => x[5] && x[3] >= S.langd * 0.5 && x[2] >= 0.2 && x[1] <= 0.12
    && x[5][13] > nock - 1.0 && /^#F[0-9A-F]F[0-9A-F]/i.test(x[4]));
  return { tvarbalkar, nockbalk, takfonster, lutande, skivor, lanternin, halvB, takV, nock, lut };
}
/* Allt som inte hör till taket: rader vars höjdläge ligger under takfoten. */
const underTak = B => B.logg.filter(x => !x[5] || x[5][13] < B.S.tak - 0.6);

console.log("1  AV: stallet byggs som förut");
const av = await bygg(""), av2 = await bygg("");
{
  const T = tak(av);
  prova("KONTROLL: stallscenen byggdes och brytaren är av", av.scen === "stallinne" && av.realism === false && av.logg.length > 200 && !av.tog_slut,
    `${av.logg.length} delar`);
  prova("den gamla stommen finns kvar: vågräta tvärbalkar", T.tvarbalkar.length >= 10, `${T.tvarbalkar.length} st`);
  prova("nockbalken finns kvar", T.nockbalk.length === 1, `${T.nockbalk.length}`);
  prova("takfönstren i fallet finns kvar", T.takfonster.length >= 8, `${T.takfonster.length} st`);
  prova("ingen lanternin", T.lanternin.length === 0, `${T.lanternin.length}`);
  prova("takskivorna når nocken", T.skivors === undefined && T.skivor.length === 2 && T.skivor.every(x => nara(x[1], Math.hypot(T.halvB, av.S.resn), 0.02)),
    T.skivor.map(x => x[1]).join(" · "));
  prova("två byggen ger samma fingeravtryck", avtryck(av.logg) === avtryck(av2.logg), `${avtryck(av.logg)} / ${avtryck(av2.logg)}`);
  console.log(`     fingeravtryck AV: ${avtryck(av.logg)} (${av.logg.length} delar)`);
}

console.log("2  PÅ: taket byggs efter kortet");
const pa = await bygg("?realism=1");
{
  const T = tak(pa), S = pa.S;
  prova("KONTROLL: stallscenen byggdes och brytaren är på", pa.scen === "stallinne" && pa.realism === true && pa.logg.length > 200 && !pa.tog_slut,
    `${pa.logg.length} delar`);
  prova("inga vågräta tvärbalkar", T.tvarbalkar.length === 0, `${T.tvarbalkar.length} st`);
  prova("ingen nockbalk", T.nockbalk.length === 0, `${T.nockbalk.length}`);
  prova("inga takfönster i fallet", T.takfonster.length === 0, `${T.takfonster.length}`);
  const v = T.lutande.filter(x => x[5][12] < S.bredd / 2), h = T.lutande.filter(x => x[5][12] > S.bredd / 2);
  prova("sparrar på BÅDA takfallen, lika många", v.length >= 10 && v.length === h.length, `${v.length} + ${h.length}`);
  prova("sparrarna lutar som taket, åt var sitt håll", v.length > 0 && h.length > 0
    && Math.sign(T.lut(v[0][5])) === -Math.sign(T.lut(h[0][5])) && T.lutande.every(x => nara(Math.abs(T.lut(x[5])), T.takV, 0.02)),
    `takfall ${(T.takV * 180 / Math.PI).toFixed(1)}°`);
  prova("sparrarna är grövre på höjden än de gamla snedstagen (≥ 0,3 m)", T.lutande.length > 0 && T.lutande.every(x => x[2] >= 0.3),
    [...new Set(T.lutande.map(x => x[2]))].join(" · ") + " m");
  const z = [...new Set(v.map(x => x[5][14]))].sort((a, b) => a - b), steg = z.slice(1).map((q, i) => q - z[i]);
  prova("jämn delning längs gången", steg.length > 5 && steg.every(s => nara(s, steg[0], 0.02)), `${steg[0]} m, ${z.length} sparrar per fall`);
  prova("en lanternin i nocken: två ljusa stående glas", T.lanternin.length === 2
    && T.lanternin.some(x => x[5][12] < S.bredd / 2) && T.lanternin.some(x => x[5][12] > S.bredd / 2),
    `${T.lanternin.length} glas, överkant ${T.lanternin.map(x => (x[5][13] + x[2] / 2).toFixed(2)).join(" / ")} m (nock ${T.nock.toFixed(2)})`);
  const full = Math.hypot(T.halvB, S.resn);
  prova("takskivorna lämnar nocken öppen under lanterninen", T.skivor.length === 2 && T.skivor.every(x => x[1] < full - 0.5),
    `${T.skivor.map(x => x[1].toFixed(2)).join(" · ")} m av ${full.toFixed(2)}`);
}

console.log("3  det som inte är tak har samma FORM i båda lägena");
{
  /* Brytaren byter medvetet FÄRGEN på boxfrontens panel och ram (se
     nedan). Formen — typ, mått och läge — ska fortfarande vara exakt
     densamma, och ingen ANNAN del under takfoten får ha bytt färg. */
  const form = L => L.map(x => [x[0], x[1], x[2], x[3], x[5]]);
  const a = underTak(av), p = underTak(pa);
  prova("samma delar under takfoten (typ, mått och läge)", avtryck(form(a)) === avtryck(form(p)),
    `${a.length} / ${p.length} delar, ${avtryck(form(a))} / ${avtryck(form(p))}`);
  const bytt = a.map((x, i) => [x, p[i]]).filter(([x, y]) => y && x[4] !== y[4]);
  /* Två medvetna färgbyten med brytaren, inget annat:
     · Batch 1.5: panelens lyft mot det gamla ljuset kopplas förbi;
     · Batch 1.4: panelen och den galvade ramen får sina foton, som bär
       färgen — ytorna blir då VITA.
     Kravet: varje del som bytt färg var panel eller ram utan brytaren och är
     vit med den, och båda slagen finns med. */
  const PANEL_AV = "#6d757d", RAM_AV = "#9A9B93";
  const avvik = bytt.filter(([x, y]) => ![PANEL_AV, RAM_AV].includes(x[4]) || y[4] !== "#FFFFFF");
  const slag = new Set(bytt.map(([x]) => x[4]));
  prova("bara boxfrontens panel och galvade ram har bytt färg, och då till vitt (fotot bär färgen)",
    bytt.length > 0 && avvik.length === 0 && slag.has(PANEL_AV) && slag.has(RAM_AV),
    `${bytt.length} delar · ${[...new Set(bytt.map(([x, y]) => x[4] + " → " + y[4]))].join(" | ")}${avvik.length ? " · AVVIKER: " + avvik.slice(0, 3).map(([x, y]) => x[4] + "→" + y[4]).join(", ") : ""}`);
}

await browser.close(); srv.close();
console.log(fel ? `\nSTALLTAKTEST: ${fel} FEL` : "\nSTALLTAKTEST: alla gröna");
process.exit(fel ? 1 : 0);
