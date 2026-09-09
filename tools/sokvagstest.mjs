#!/usr/bin/env node
/* SÖKVÄGSGRINDEN — #153 fix 2, P3-5.

   ChatGPT:s audit rapporterade Windows-fil-URL-fel och föreslog
   `fileURLToPath`. Auditens egen Windows-körning hade harnessfel, så
   fyndet var inte bevisat — därför det här provet, som reproducerar
   samma fel på Linux där CI faktiskt kör.

   Felet: `new URL(".", import.meta.url).pathname` ger PROCENTKODAD text.
   Ligger repot i en katalog vars namn innehåller mellanslag, ett svenskt
   tecken eller ett procenttecken blir repo-roten

       .../UBRF%20h%C3%A4st/src/model.js          ENOENT

   och verktyget dör innan en enda mätning körts. Det är alltså inte bara
   ett Windows-fel: "UBRF häst" räcker. På Windows är skadan dessutom
   större, för `.pathname` ger `/C:/...` med inledande snedstreck.

   Provet mäter TVÅ saker, och den andra är den viktiga:

     1. ett riktigt verktyg körs ur en katalog med mellanslag och ä,
     2. samma verktyg med det GAMLA mönstret måste fortfarande dö där.

   Utan (2) vore ett grönt (1) värdelöst — det skulle inte gå att skilja
   "rättelsen håller" från "katalognamnet var aldrig kodat".

   Kör: node tools/sokvagstest.mjs */
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const resultat = [];
function prova(namn, ok, detalj) {
  resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj);
}

/* Katalognamnet bär exakt de tecken som `.pathname` kodar: mellanslag
   (%20), ä (%C3%A4) och procent (%25). "UBRF häst" är inte ett påhittat
   specialfall — det är ett fullt rimligt namn på den här mappen. */
const KATALOG = `UBRF häst 100% ${process.pid}`;
const bo = fs.mkdtempSync(path.join(os.tmpdir(), "ubrf-sokvag-"));
const prov = path.join(bo, KATALOG);

/* kolla-ankare.mjs valdes för att det är ett RIKTIGT verktyg ur CI som
   läser tre filer via repo-roten och inte behöver någon webbläsare. */
const FILER = ["tools/kolla-ankare.mjs", "src/model.js", "src/site.js",
  "references/spatial/UBRF-SPATIAL-ANCHORS.json"];

try {
  for (const f of FILER) {
    const mal = path.join(prov, f);
    fs.mkdirSync(path.dirname(mal), { recursive: true });
    fs.copyFileSync(path.join(ROT, f), mal);
  }

  const kor = (fil) => spawnSync(process.execPath, [fil], { cwd: prov, encoding: "utf8" });

  /* ══ 1. VERKTYGET KÖR UR EN KODAD SÖKVÄG ═════════════════════════ */
  const nu = kor("tools/kolla-ankare.mjs");
  prova("ett riktigt verktyg kör ur en katalog med mellanslag och ä",
    nu.status === 0,
    `exit ${nu.status} · ${KATALOG}`);

  /* ══ 2. KONTROLLMÄTNING: DET GAMLA MÖNSTRET MÅSTE DÖ DÄR ═════════
     Samma fil, samma katalog, bara ROT-raden bytt tillbaka. Blir den
     här grön mäter provet ingenting — då är katalognamnet inte kodat
     och mätning 1 är ett falskt positivt. */
  const kalla = fs.readFileSync(path.join(prov, "tools/kolla-ankare.mjs"), "utf8");
  const gammal = kalla.replace(
    'path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")',
    'path.resolve(new URL(".", import.meta.url).pathname, "..")');
  prova("kontrollmätningen bytte faktiskt ut ROT-raden",
    gammal !== kalla, gammal !== kalla ? "mutationen tog" : "ingen träff — provet mäter fel fil");
  fs.writeFileSync(path.join(prov, "tools/gammal.mjs"), gammal);
  const da = kor("tools/gammal.mjs");
  const kodad = /%20|%C3%A4|%25/.test((da.stderr || "") + (da.stdout || ""));
  prova("det gamla mönstret dör fortfarande i samma katalog",
    da.status !== 0 && kodad,
    `exit ${da.status} · procentkodad sökväg i felet: ${kodad}`);

  /* ══ 3. INGEN ÅTERFALL I tools/ ══════════════════════════════════
     Den här filen undantas, och bara den: den citerar det förbjudna
     mönstret på två ställen — i kommentaren överst och i mutationen på
     rad 2 — och ett prov som inte får beskriva felet det vaktar vore
     ett sämre prov. Undantaget är farligt bara om regeln inte biter,
     så nästa mätning provar regeln mot en känd trasig rad. */
  const REGEL = /import\.meta\.url\s*\)\s*\.pathname/;
  const SJALV = "sokvagstest.mjs";
  const tools = fs.readdirSync(path.join(ROT, "tools"))
    .filter(f => (f.endsWith(".mjs") || f.endsWith(".js")) && f !== SJALV);
  const kvar = tools.filter(f =>
    REGEL.test(fs.readFileSync(path.join(ROT, "tools", f), "utf8")));
  prova("inget verktyg läser repo-roten ur .pathname längre",
    kvar.length === 0, kvar.length ? kvar.join(", ") : `${tools.length} filer genomsökta`);

  /* Kontrollmätning för regeln ovan: den ska träffa en trasig rad.
     Raden byggs ihop av två halvor så att den inte själv står som ett
     sammanhängande mönster i filen. */
  const TRASIG = 'const ROT = path.resolve(new URL(".", import.meta.url)' + '.pathname, "..");';
  prova("regeln träffar faktiskt en trasig rad",
    REGEL.test(TRASIG) && !REGEL.test(TRASIG.replace(".pathname", "")),
    "regeln är inte tom");

  /* ══ 4. ROTEN KOMMER UR MODULEN, INTE UR ARBETSKATALOGEN ═════════
     Den enkla vägen runt regel 3 är att sluta räkna ut roten alls och
     ta `process.cwd()` i stället. Linten blir grön, verktyget verkar
     funka — men bara så länge man råkar stå i repo-roten när man kör
     det. Här körs verktyget med arbetskatalogen någon annanstans, med
     absolut sökväg till skriptet. Håller roten är den modulens egen.

     (Ett första utkast mätte i stället HUR MÅNGA filer som nämner
     fileURLToPath, med tröskeln 18. Den mätningen kunde inte bli röd:
     mutationen som bytte tre filer mot process.cwd() lämnade 20 kvar
     och passerade. En tröskel som redan är uppfylld mäter ingenting.) */
  const annanKatalog = spawnSync(process.execPath,
    [path.join(prov, "tools/kolla-ankare.mjs")], { cwd: os.tmpdir(), encoding: "utf8" });
  prova("verktyget hittar sin rot även när arbetskatalogen är en annan",
    annanKatalog.status === 0,
    `exit ${annanKatalog.status} · cwd ${os.tmpdir()}`);

} finally {
  fs.rmSync(bo, { recursive: true, force: true });
}

const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `\n${fel} FEL` : `\nAlla ${resultat.length} mätningar gröna.`);
process.exit(fel ? 1 : 0);
