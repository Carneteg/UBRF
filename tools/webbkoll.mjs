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
import fs from "node:fs";
import { chromium } from "playwright";

const port = process.argv[2] || 8931;
const SCENER = [
  ["gard",        { x: 150, y: 100, rikt: 0 }],
  ["stallinne",   { x: 5.6, y: 1.6,  rikt: Math.PI / 2 }],
  ["ridhusinne",  { x: 10.6, y: 20,  rikt: 0 }],
];

/* Chromium HITTAS, den antas inte.
 *
 * Här stod sökvägen hårdkodad utan reservutgång:
 *
 *     executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
 *
 * Det är en väg som bara finns i en Linux-container. Utanför den dog
 * verktyget på `Failed to launch chromium because executable doesn't
 * exist` innan en enda scen laddats — alltså exakt samma klass av
 * portabilitetsfel som #159 rättade för sökvägarna, fast för browsern.
 *
 * Mönstret nedan är det de sjutton andra QA-verktygen redan använder:
 * `CHROMIUM` ur miljön om den är satt, containervägen om den finns, och
 * annars `undefined` — vilket låter Playwright hitta sin egen browser.
 * Det sista ledet är hela poängen; utan det går grinden inte att köra
 * någon annanstans än där den skrevs. */
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const b = await chromium.launch({
  executablePath: fs.existsSync(exe) ? exe : undefined,
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
