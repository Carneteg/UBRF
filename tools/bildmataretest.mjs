/* STRÖMBRYTAREN OCH BILDRUTEMÄTAREN — Batch 1.2, kodhalvan.

   Batchen ska INTE ändra något spelaren ser. Provet mäter just det:

   1. Rörledningen är tom: ingen fil utom src/bildmatare.js läser
      strömbrytaren, och spelloopen gör inget annat med mätaren än att ge
      den bildrutans längd.
   2. Mätarens räkning: bilder per sekund, sämsta rutan och antalet rutor
      som slog i dt-taket — och att ingenting räknas när den är av.
   3. I en riktig webbläsare: utan parametrar finns ingen mätare och
      brytaren är av; `?fps=1` visar mätaren; `?realism=1` slår på
      brytaren; nästan-rätta parametrar gör ingenting.

   Falsifiering: --muter-pa (brytaren på som standard), --muter-synlig
   (mätaren alltid på), --muter-klipp (klippen räknas inte) ska bli röda.

   Hela ridsviten med brytaren PÅ körs för sig:
     UBRF_FRAGA='?realism=1&fps=1' node tools/ridtest.mjs

   Kör: python3 tools/build.py && node tools/bildmataretest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const las = rel => fs.readFileSync(path.join(ROT, rel), "utf8");

function kalla() {
  let s = las("src/bildmatare.js");
  const byt = (fran, till) => {
    if (!s.includes(fran)) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
    s = s.replace(fran, till);
  };
  if (arg.has("--muter-pa")) byt('pa: har("realism")', "pa: true");
  if (arg.has("--muter-synlig")) byt('matare: har("fps")', "matare: true");
  if (arg.has("--muter-klipp")) byt("if (ra > B.DT_TAK) B.klipp++;", "");
  return s;
}
const muterad = [...arg].some(a => a.startsWith("--muter-"));

console.log("1  rörledningen är tom");
{
  const filer = [];
  const ga = d => { for (const f of fs.readdirSync(path.join(ROT, d), { withFileTypes: true })) {
    const rel = d + "/" + f.name;
    if (f.isDirectory()) ga(rel); else if (rel.endsWith(".js")) filer.push(rel);
  } };
  ga("src");
  const lasare = filer.filter(f => f !== "src/bildmatare.js" && /\bREALISM\b/.test(las(f)));
  prova("ingen annan källfil läser REALISM", lasare.length === 0, lasare.join(", ") || `${filer.length} filer genomsökta`);
  const anv = filer.filter(f => f !== "src/bildmatare.js" && /bildmatare|BILDMATARE/.test(las(f)));
  prova("bara spelloopen rör mätaren", JSON.stringify(anv) === JSON.stringify(["src/game.js"]), anv.join(", "));
  const g = las("src/game.js");
  const rader = g.split("\n").filter(r => /bildmatare/i.test(r) && !/^\s*(\/\*|\*|\/\/)/.test(r) && !/Batch 1\.2/.test(r));
  prova("och gör det på EN rad, som bara lämnar över bildrutans längd",
    rader.length === 1 && rader[0].trim() === 'if(typeof bildmatareSteg==="function")bildmatareSteg((now-last)/1000,now);',
    rader.map(r => r.trim()).join(" | "));
  prova("spelets dt räknas som förut", g.includes("const dt=Math.min((now-last)/1000,0.05);last=now;G.t+=dt;"));
}

console.log("2  mätarens räkning");
{
  const ny = sok => {
    const ctx = vm.createContext({ console, Math, RegExp, location: { search: sok } });
    vm.runInContext(kalla() + "\n;globalThis.B=BILDMATARE;globalThis.R=REALISM;globalThis.steg=bildmatareSteg;globalThis.lasM=bildmatareLas;globalThis.txt=bildmatareText;", ctx);
    return ctx;
  };
  const av = ny("");
  prova("utan parametrar: brytaren av, mätaren av", av.R.pa === false && av.R.matare === false, JSON.stringify(av.R));
  for (let i = 0; i < 100; i++) av.steg(1 / 60, i * 16.7);
  prova("en avstängd mätare räknar ingenting", av.B.antal === 0 && av.B.rutor.length === 0, `${av.B.antal} rutor`);
  const pa = ny("?fps=1");
  let t = 0;
  for (let i = 0; i < 60; i++) { t += 1000 / 60; pa.steg(1 / 60, t); }
  let v = pa.lasM();
  prova("60 rutor på 1/60 s ger 60 b/s och 16,7 ms som sämst", Math.abs(v.fps - 60) < 0.01 && Math.abs(v.samst - 16.667) < 0.01 && v.klipp === 0,
    `${v.fps.toFixed(2)} b/s, ${v.samst.toFixed(2)} ms, ${v.klipp} klippta`);
  t += 100; pa.steg(0.1, t); v = pa.lasM();
  prova("en ruta på 100 ms syns som sämst och räknas som klippt", Math.abs(v.samst - 100) < 0.01 && v.klipp === 1, `${v.samst.toFixed(0)} ms, ${v.klipp} klippt`);
  for (let i = 0; i < 60; i++) { t += 1000 / 60; pa.steg(1 / 60, t); }
  v = pa.lasM();
  prova("fönstret glider: den dåliga rutan faller ur, men klippet står kvar", Math.abs(v.samst - 16.667) < 0.01 && v.klipp === 1 && v.antal === 121,
    `${v.samst.toFixed(1)} ms, ${v.klipp} av ${v.antal}`);
  prova("en ruta precis på taket (50 ms) är inte klippt", (() => { const c = ny("?fps=1"); c.steg(0.05, 50); return c.lasM().klipp === 0; })());
  prova("texten säger om brytaren är på", /realism av/.test(pa.txt()) && /realism PÅ/.test(ny("?realism=1&fps=1").txt()));
  const fall = { "?realism=1": [true, false], "?fps=1": [false, true], "?a=2&realism=1&fps=1": [true, true],
    "?realism=10": [false, false], "?xrealism=1": [false, false], "?realism=true": [false, false], "?fps=0": [false, false] };
  const felaktiga = Object.entries(fall).filter(([s, [r, m]]) => { const c = ny(s).R; return c.pa !== r || c.matare !== m; });
  prova("bara exakt `realism=1` och `fps=1` slår på", felaktiga.length === 0, felaktiga.map(f => f[0]).join(", ") || `${Object.keys(fall).length} fall`);
}

if (arg.has("--bara-regeln")) { console.log(fel ? `\nBILDMATARETEST: ${fel} FEL` : "\nBILDMATARETEST (utan webbläsare): alla gröna"); process.exit(fel ? 1 : 0); }

console.log("3  i webbläsaren");
const { chromium } = await import("playwright");
const DIST = path.join(ROT, "dist"), PORT = 8939;
const srv = http.createServer((q, s) => {
  if (q.url.split("?")[0] !== "/") { s.writeHead(404); s.end(); return; }
  let html = fs.readFileSync(path.join(DIST, "ridskolan.html"), "utf8");
  /* Mutationen byts in i den SERVERADE sidan; dist rörs inte. */
  if (muterad) {
    const orig = las("src/bildmatare.js");
    if (!html.includes(orig)) { console.error("FEL  dist innehåller inte src/bildmatare.js ordagrant — bygg om"); process.exit(2); }
    html = html.replace(orig, kalla());
  }
  s.writeHead(200, { "content-type": "text/html" }); s.end(html);
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
async function oppna(fraga) {
  const page = await (await browser.newContext({ viewport: { width: 1180, height: 820 } })).newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/${fraga}`, { waitUntil: "load" });
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  /* Vänta i BILDRUTOR, inte i väggklocka: CI ritar långsamt. */
  await page.evaluate(() => new Promise(klar => { let n = 0; (function r() { if (++n > 40) klar(); else requestAnimationFrame(r); })(); }));
  await page.waitForTimeout(400);
  return page;
}
const tillstand = page => page.evaluate(() => ({ r: REALISM, el: !!document.getElementById("bildmatare"),
  text: (document.getElementById("bildmatare") || {}).textContent || "", v: bildmatareLas(), scen: G.scen }));
{
  const p = await oppna("");
  const a = await tillstand(p);
  prova("utan parametrar: ingen mätare på skärmen och brytaren av", a.el === false && a.r.pa === false && a.r.matare === false && a.v.antal === 0,
    JSON.stringify({ el: a.el, r: a.r, antal: a.v.antal }));
  prova("KONTROLL: spelet går (scenen är gården)", a.scen === "gard", a.scen);
  await p.context().close();
}
{
  const p = await oppna("?fps=1");
  const a = await tillstand(p);
  prova("?fps=1 visar mätaren", a.el === true && /^\d+ b\/s · sämst \d+ ms\nklippta \d+ av \d+ · realism av$/.test(a.text), JSON.stringify(a.text));
  prova("och den mäter riktiga bildrutor", a.v.antal >= 40 && a.v.fps > 0.5 && a.v.fps < 1000, `${a.v.antal} rutor, ${a.v.fps.toFixed(1)} b/s`);
  prova("men brytaren är fortfarande av", a.r.pa === false);
  const stil = await p.evaluate(() => { const e = document.getElementById("bildmatare"); const c = getComputedStyle(e); return { pe: c.pointerEvents, pos: c.position }; });
  prova("mätaren tar inga tryck från spelet", stil.pe === "none" && stil.pos === "fixed", JSON.stringify(stil));
  await p.context().close();
}
{
  const p = await oppna("?realism=1&fps=1");
  const a = await tillstand(p);
  prova("?realism=1 slår på brytaren, och mätaren säger det", a.r.pa === true && /realism PÅ$/.test(a.text), JSON.stringify(a.text));
  prova("KONTROLL: spelet går likadant (scenen är gården)", a.scen === "gard", a.scen);
  await p.context().close();
}
await browser.close(); srv.close();
console.log(fel ? `\nBILDMATARETEST: ${fel} FEL` : "\nBILDMATARETEST: alla gröna");
process.exit(fel ? 1 : 0);
