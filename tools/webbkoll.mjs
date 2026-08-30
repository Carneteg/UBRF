/* Bygger inte, utan KÖR den byggda webben och säger ifrån ordentligt.
 *
 * Fanns inte förut, och det kostade: mina QA-skript lyssnade på
 * `pageerror` och på console-rader av typen "error". Ett undantag inne i
 * scenbyggaren FÅNGAS av spelet och loggas som en VARNING —
 * "3D-vandring misslyckades" — så det passerade som grönt.
 *
 * Följden blev att ett ReferenceError i v3dRidhus stod obemärkt genom flera
 * commits. Halva ridhusinteriören byggdes aldrig, och jag tog skärmdumpar av
 * en trasig scen och trodde att geometrin låg fel.
 *
 * Kör: node tools/webbkoll.mjs [port]
 */
import { chromium } from "playwright";

const port = process.argv[2] || 8931;
const SCENER = [
  ["gard",        { x: 150, y: 100, rikt: 0 }],
  ["stallinne",   { x: 5.6, y: 1.6,  rikt: Math.PI / 2 }],
  ["ridhusinne",  { x: 10.6, y: 20,  rikt: 0 }],
];

const b = await chromium.launch({
  executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"],
});
const p = await b.newPage({ viewport: { width: 1280, height: 800 } });

const klagomal = [];
/* ALLA nivåer räknas, inte bara "error". Det är hela poängen med filen. */
p.on("console", m => {
  const t = m.text();
  if (/misslyckades|is not defined|undefined is not|cannot read|TypeError|ReferenceError|SyntaxError/i.test(t))
    klagomal.push(`${m.type()}: ${t.slice(0, 200)}`);
});
p.on("pageerror", e => klagomal.push(`pageerror: ${e.message}`));

await p.goto(`http://127.0.0.1:${port}/ridskolan.html`, { waitUntil: "networkidle" });
await p.waitForTimeout(700);
await p.evaluate(() => startaVandring());

for (const [scen, spawn] of SCENER) {
  await p.evaluate(([s, sp]) => gaTill(s, sp), [scen, spawn]);
  await p.waitForTimeout(1600);
  const n = await p.evaluate(() => (typeof S3 !== "undefined" ? S3.statiskt.length : -1));
  if (n <= 0) klagomal.push(`${scen}: scenen byggde ${n} statiska objekt`);
  else console.log(`${scen.padEnd(12)} OK  ${n} statiska objekt`);
}

await b.close();
if (klagomal.length) {
  console.log("\nKLAGOMÅL:");
  for (const k of klagomal) console.log("  " + k);
  process.exit(1);
}
console.log("\nInga fel, inga varningar, alla scener byggde.");
