#!/usr/bin/env node
/* Screenshot-pack (issue #78 § 2 och § 5): renderar de fasta reviewkamerorna
   i qa/visual-gate/kameror.json från EXAKT den kod som ligger i arbetsträdet
   och skriver ett reviewpaket:

       <ut>/<ID>.png           en bild per kamera
       <ut>/ref/…              kopior av referensbilderna kameran pekar på
       <ut>/pack.json          head-SHA, kameralägen, siktprov, granskningsstatus
       <ut>/index.html         side-by-side: referens · implementation · status · gap

   Automation sätter ALDRIG någon visuell status: statusen i paketet är den
   som ChatGPT (senior visual QA) skrivit i kameror.json, annars EJ_GRANSKAD.
   Grön CI betyder inte visual fidelity — paketet finns för att ChatGPT ska
   kunna göra reviewn innan Tobias ser något.

   Kör: python3 tools/build.py && node tools/screenshot-pack.mjs [--ut qa/screenshot-pack] [--utan-referenser]
   Avslutar med 1 om siktprovet säger att figuren är DOLD i någon kamera
   (samma regel som tools/siktgrind.mjs) eller om sidan kastade fel. */
import fs from "node:fs";
import path from "node:path";
import { ROT, lasKameror, gitHead, oppnaWebb, stallKamera, lasLage } from "./qa-webb.mjs";

const arg = (n, d) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : d; };
const UT = path.resolve(ROT, arg("--ut", "qa/screenshot-pack"));
const utanRef = process.argv.includes("--utan-referenser");
const kameror = lasKameror();
const head = gitHead();
fs.mkdirSync(path.join(UT, "ref"), { recursive: true });

const w = await oppnaWebb({ port: 8792, siktprov: true });
const pack = { head: head.sha, smutsigt: head.smutsigt, renderad: new Date().toISOString(), kameror: {} };
let dolda = 0;
for (const k of kameror) {
  const lage = await stallKamera(w.page, k);
  const info = await lasLage(w.page);
  const sikt = await w.page.evaluate(() => v3dSiktProv());
  await w.page.screenshot({ path: path.join(UT, `${k.id}.png`) });
  const refs = [];
  for (const r of k.referenser || []) {
    const src = path.join(ROT, r);
    const finns = fs.existsSync(src);
    let kopia = null;
    if (finns && !utanRef && /\.(jpe?g|png)$/i.test(r)) {
      kopia = path.join("ref", path.basename(r));
      fs.copyFileSync(src, path.join(UT, kopia));
    }
    refs.push({ id: r, finns, kopia });
  }
  if (sikt.dold) dolda++;
  pack.kameror[k.id] = { ...k, lage, ...info, sikt: { dold: sikt.dold, delvis: sikt.delvis, tonade: sikt.tonade, skymmande: sikt.skymmande.length, blockerade: sikt.blockerade }, referenser: refs };
  console.log(`${k.id.padEnd(20)} spelare ${JSON.stringify(info.spelare)} kamera ${JSON.stringify(info.kamera)} tonade ${info.tonade} ${sikt.dold ? "DOLD" : sikt.delvis ? "delvis skymd" : "synlig"}`);
}
await w.stang();
fs.writeFileSync(path.join(UT, "pack.json"), JSON.stringify(pack, null, 2) + "\n");

/* Side-by-side-paketet. Statusen kommer ur kameror.json, aldrig härifrån. */
const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;");
const rad = k => {
  const c = pack.kameror[k.id];
  const refHtml = c.referenser.length ? c.referenser.map(r => r.kopia
    ? `<figure><img src="${esc(r.kopia)}" alt=""><figcaption>${esc(r.id)}</figcaption></figure>`
    : `<figure class="txt"><figcaption>${esc(r.id)}${r.finns ? "" : " — SAKNAS I REPOT"}</figcaption></figure>`).join("")
    : `<p class="gap">Ingen referensbild — REFERENCE GAP</p>`;
  const g = c.granskning || {};
  return `<section id="${esc(k.id)}">
<h2>${esc(k.id)} — ${esc(k.namn)}</h2>
<p>${esc(k.text)}</p>
<div class="par">
  <div><h3>Referens</h3>${refHtml}</div>
  <div><h3>Implementation @ <code>${esc(head.sha.slice(0, 7))}</code></h3><img src="${esc(k.id)}.png" alt="">
    <p class="meta">spelare ${esc(JSON.stringify(c.spelare))} · kamera ${esc(JSON.stringify(c.kamera))} · tonade väggar ${c.tonade} · siktprov: <b>${c.sikt.dold ? "DOLD" : c.sikt.delvis ? "delvis skymd" : "synlig"}</b></p></div>
</div>
<table><tr><th>Mismatch-status (ChatGPT)</th><td><b>${esc(g.status || "EJ_GRANSKAD")}</b>${g.head ? ` på <code>${esc(g.head)}</code>` : ""}${g.av ? ` av ${esc(g.av)}` : ""}</td></tr>
<tr><th>Mismatch</th><td>${esc(g.mismatch || "—")}</td></tr>
<tr><th>REFERENCE GAP</th><td>${(k.gap || []).length ? (k.gap || []).map(esc).join("<br>") : "—"}</td></tr></table>
</section>`;
};
fs.writeFileSync(path.join(UT, "index.html"), `<!doctype html><meta charset="utf-8"><title>UBRF screenshot-pack ${esc(head.sha.slice(0, 7))}</title>
<style>body{font:14px system-ui;margin:1.5rem;max-width:1400px}section{border-top:1px solid #ccc;padding:1rem 0}.par{display:grid;grid-template-columns:1fr 1fr;gap:1rem}img{max-width:100%;border:1px solid #999}figure{margin:0 0 .5rem}figcaption,.meta{font-size:12px;color:#444}table{margin-top:.5rem;border-collapse:collapse}th,td{text-align:left;padding:.2rem .6rem;vertical-align:top;border:1px solid #ddd}.gap{color:#a00}code{font-size:12px}</style>
<h1>UBRF — Visual Fidelity Gate, screenshot-pack</h1>
<p>Head <code>${esc(head.sha)}</code>${head.smutsigt ? " <b>(SMUTSIGT ARBETSTRÄD — inte PR-evidens)</b>" : ""} · renderad ${esc(pack.renderad)} · ${kameror.length} kameror · figuren dold i ${dolda}.</p>
<p><b>Statuskedja:</b> IMPLEMENTED → AUTOMATED_GREEN → VISUAL_PACK_READY → CHATGPT_VISUAL_PASS → READY_FOR_PRODUCT_ACCEPTANCE → PRODUCT_ACCEPTED. Det här paketet är <b>VISUAL_PACK_READY</b> som mest. Ingen automation sätter en visuell status; grön CI är inte visual fidelity. Se docs/VISUAL-FIDELITY-GATE.md.</p>
<nav>${kameror.map(k => `<a href="#${esc(k.id)}">${esc(k.id)}</a>`).join(" · ")}</nav>
${kameror.map(rad).join("\n")}
`);
console.log(`\nSkrev ${kameror.length} bilder + index.html + pack.json till ${path.relative(ROT, UT)} (head ${head.sha.slice(0, 7)}${head.smutsigt ? ", SMUTSIGT" : ""})`);
if (w.fel.length) { console.log("SIDFEL:"); for (const f of w.fel) console.log("  " + f); process.exit(1); }
if (dolda) { console.log(`FEL: figuren är dold i ${dolda} kamera/kameror`); process.exit(1); }
