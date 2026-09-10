#!/usr/bin/env node
/* SPRÅKGRINDEN PÅ WEBBEN (#162).

   Roblox-sidan mäts i roblox/tests/sprak.spec.luau. Den här mäter att
   webben läser SAMMA katalog och samma regel — paritetsregeln gäller
   texten precis som den gäller hästlogiken: en spelare som byter yta ska
   läsa samma ord.

   Vad som mäts:
     1. katalogen finns i det byggda spelet (den är inte bara en fil i
        repot — den ska ha kommit MED i dist/ridskolan.html),
     2. `tSpr()` ger svenska respektive engelska enligt samma regel,
     3. samma nycklar och samma text som den GENERERADE Luau-tabellen,
        annars har de två ytorna glidit isär,
     4. `SPRAK_BACKLOG` finns med källa och skäl.

   Kör: python3 tools/build.py && node tools/sprakgrind.mjs */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let fel = 0;
const saga = (ok, t, d) => { if (!ok) fel++; console.log(`  ${ok ? "OK  " : "FEL "} ${t}${d ? "  " + d : ""}`); };

/* 1. Katalogen ska ha kommit med i det byggda spelet. */
const dist = fs.readFileSync(path.join(ROT, "dist/ridskolan.html"), "utf8");
saga(dist.includes("window.tSpr") && dist.includes("\"hud.du_rider\""),
  "språkkanonen följde med in i dist/ridskolan.html");

/* 2. Regeln och uppslaget, ur källan. */
const ctx = { window: {}, navigator: { language: "sv-SE" } };
const kod = fs.readFileSync(path.join(ROT, "src/spel/sprak.js"), "utf8");
new Function("window", "navigator", kod)(ctx.window, ctx.navigator);
const W = ctx.window;

saga(W.sprakFor("sv-se") === "sv" && W.sprakFor("sv-FI") === "sv",
  "sv* ger svenska");
saga(W.sprakFor("en-us") === "en" && W.sprakFor("de-de") === "en" && W.sprakFor("") === "en",
  "allt annat ger engelska");
saga(W.sprakText("hud.du_rider", "sv") !== W.sprakText("hud.du_rider", "en"),
  "samma nyckel ger olika text i de två språken",
  `${W.sprakText("hud.du_rider", "sv")} / ${W.sprakText("hud.du_rider", "en")}`);
saga(W.sprakText("stall.star_har", "en", "Blackrock Jack").includes("Blackrock Jack"),
  "hästens egennamn står ordagrant i den engelska texten",
  W.sprakText("stall.star_har", "en", "Blackrock Jack"));
saga(W.sprakSaknade("sv").length === 0 && W.sprakSaknade("en").length === 0,
  "ingen nyckel saknar något av språken");

/* 3. SAMMA sanning som Roblox. Den genererade Luau-tabellen jämförs
      nyckel för nyckel — det är hela poängen med att generera den. */
const luau = fs.readFileSync(path.join(ROT, "roblox/game/UBRFSprak.luau"), "utf8");
const luauNycklar = new Set([...luau.matchAll(/\["([A-Za-z0-9_.]+)"\] = \{/g)].map(m => m[1]));
const jsNycklar = new Set(Object.keys(W.SPRAK));
const bara = (a, b) => [...a].filter(k => !b.has(k));
saga(bara(jsNycklar, luauNycklar).length === 0 && bara(luauNycklar, jsNycklar).length === 0,
  "webben och Roblox har exakt samma nycklar",
  `webb ${jsNycklar.size} · roblox ${luauNycklar.size}` +
  (bara(jsNycklar, luauNycklar).length ? ` · bara webb: ${bara(jsNycklar, luauNycklar).join(", ")}` : "") +
  (bara(luauNycklar, jsNycklar).length ? ` · bara roblox: ${bara(luauNycklar, jsNycklar).join(", ")}` : ""));

/* …och samma TEXT, inte bara samma nycklar. En generering som tappat ett
   ä eller en platshållare är precis den sorts glidning som gör att två
   ytor säger olika saker. */
const olika = [];
for (const nyckel of jsNycklar) {
  for (const sprak of ["sv", "en"]) {
    const vantad = W.SPRAK[nyckel][sprak];
    const block = luau.split(`["${nyckel}"] = {`)[1] || "";
    const rad = new RegExp(`${sprak} = "((?:[^"\\\\]|\\\\.)*)"`).exec(block.split("}")[0]);
    const funnen = rad ? rad[1].replace(/\\"/g, '"').replace(/\\n/g, "\n").replace(/\\\\/g, "\\") : null;
    if (funnen !== vantad) olika.push(`${nyckel}.${sprak}`);
  }
}
saga(olika.length === 0, "och exakt samma text i båda tabellerna",
  olika.length ? olika.slice(0, 6).join(", ") : `${jsNycklar.size} nycklar jämförda`);

/* 4. Översättningsskulden. */
saga(Array.isArray(W.SPRAK_BACKLOG) && W.SPRAK_BACKLOG.length > 0
  && W.SPRAK_BACKLOG.every(p => p.kalla && p.vad && p.skal && p.skal.length > 20),
  "översättningsskulden är redovisad med källa, vad och skäl",
  `${W.SPRAK_BACKLOG.length} poster`);

console.log(fel ? `\n${fel} FEL` : "\nSpråkgrinden (webb): katalogen är EN sanning på båda ytorna.");
process.exit(fel ? 1 : 0);
