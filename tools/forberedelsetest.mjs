/* FÖRBEREDELSEN — webbens port (src/forberedelse.js) mot Roblox facit.

   docs/WEB-P1A-STABLE-FLOW-CONTRACT.md, acceptans 1. Två delar:
     A. Regler i webbens port, provade direkt (nejens ordning, felaktiga
        alternativ, auto skilt från spelaren, välfärdsstoppet, andelen).
     B. PARITET: roblox/tests/forberedelse-webb.spec.luau körs genom
        test-banken och varje rad (moment, fynd per häst och pass,
        andelar) jämförs mot webbens svar på samma fråga. Glider
        plattformarna isär blir det rött. Saknas luau i miljön redovisas
        B som NOT_TESTED — aldrig som grönt.

   Körs: node tools/forberedelsetest.mjs */
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

const ctx = vm.createContext({ console });
for (const f of ["src/spel/skotsel.js", "src/riding/svar.js", "src/forberedelse.js"])
  vm.runInContext(fs.readFileSync(path.join(ROT, f), "utf8"), ctx, { filename: f });
const F = vm.runInContext("Forb", ctx);

/* P1b: tilldelningen och boxarna. hastar.js, data.js och site.js laddas
   i ett eget sammanhang; ur uppdrag.js tas bara tilldelningsregeln (filen
   bygger annars DOM vid laddning). */
const vctx = vm.createContext({ console, clamp: (x, a, b) => Math.max(a, Math.min(b, x)) });
for (const f of ["src/spel/hastar.js", "src/data.js", "src/site.js"])
  vm.runInContext(fs.readFileSync(path.join(ROT, f), "utf8"), vctx, { filename: f });
{
  const u = fs.readFileSync(path.join(ROT, "src/uppdrag.js"), "utf8");
  const a = u.indexOf("const FORSTA_DAGEN_HAST_ID"), b = u.indexOf("/* Dagens häst för den här spelaren.");
  if (a < 0 || b < a) throw new Error("tilldelningsregeln saknas i src/uppdrag.js");
  vm.runInContext(u.slice(a, b) + ";this.tilldelaLedig=tilldelaLedig;this.kontoTilldelningsId=kontoTilldelningsId;"
    + "this.tilldelningsId=tilldelningsId;", vctx, { filename: "uppdrag.js (utdrag)" });
}
const W = { tilldela: vctx.tilldelaLedig, S: vm.runInContext("STALLINNE", vctx),
  antal: vm.runInContext("Object.keys(HORSES).length", vctx) };

/* ── M1 (P1b R1): rotationens nummer följer KONTOT, som Roblox UserId ── */
{
  const konto = "3f1c2a9e-6b1d-4c7a-9f0e-2d5b8a1c4e77";
  const enhet = (spelarId, inloggad) => {           // en enhet = ett eget sammanhang
    const c = vm.createContext({});
    const u = fs.readFileSync(path.join(ROT, "src/uppdrag.js"), "utf8");
    const a = u.indexOf("function kontoTilldelningsId"), b = u.indexOf("/* Dagens häst för den här spelaren.");
    if (a < 0 || b < a) throw new Error("tilldelningsId saknas i src/uppdrag.js");
    vm.runInContext(u.slice(a, b) + ";this.tilldelningsId=tilldelningsId;", c);
    c.SPAR = { spelarId };
    c.SYNK = inloggad ? { session: { access_token: "x", user: { id: konto } } } : { session: null };
    vm.runInContext("var SPAR=this.SPAR, SYNK=this.SYNK;", c);
    return c.tilldelningsId();
  };
  const ipad = enhet(111, true), dator = enhet(987654321, true);
  prova("M1: samma konto på två enheter ger samma nummer", ipad === dator, `${ipad} · ${dator}`);
  prova("M1: numret är ett heltal ≥ 0 under 2^32", Number.isInteger(ipad) && ipad >= 0 && ipad < 2 ** 32, String(ipad));
  prova("M1: samma konto ger samma häst på båda enheterna",
    W.tilldela(ipad, {}, {}, null) === W.tilldela(dator, {}, {}, null), W.tilldela(ipad, {}, {}, null));
  prova("M1: utloggad spelare behåller profilens nummer", enhet(111, false) === 111 && enhet(987654321, false) === 987654321);
  prova("M1: ett annat konto ger (i regel) ett annat nummer",
    vctx.kontoTilldelningsId(konto) !== vctx.kontoTilldelningsId(konto.replace(/7$/, "8")));
}
const VILANDE = { inga: {}, jack: { blackrock_jack: true }, tre: { air: true, allan: true, troy: true } };
const START = vm.runInContext("SVAR_START", ctx);

/* ── A. Reglerna ─────────────────────────────────────────────────── */
console.log("\n── A. Webbens port ──");
const helaKedjan = (s, utforare) => {
  for (const f of F.stegFaser()) {
    if (f.id === "leda") continue;
    for (let m = F.nastaMoment(s, f.id); m; m = F.nastaMoment(s, f.id)) {
      if (m.utr === 1) s.hand.sadel = true;
      if (m.utr === 5) s.hand.trans = true;
      const r = F.utforMoment(s, f.id, m.id, s.hastId, utforare);
      if (!r[0]) return r;
    }
  }
  return F.utforMoment(s, "leda", "leda", s.hastId, utforare);
};

{
  const s = F.nyState("troy", 1);
  prova("första passet har inget fynd", s.fynd === null);
  prova("uppsittning nekas innan något är gjort", F.provaUppsittning(s, "troy")[1] === "pass.aterstar");
  const fel3 = F.utforMoment(s, "halsa", "halsa3", "troy");
  prova("felaktigt alternativ (rakt bakifrån) flyttar ingenting",
    !fel3[0] && fel3[1] === "kanon" && !s.gjorda.halsa?.halsa3 && !s.klara.halsa,
    `svar ${fel3[1]}`);
  prova("fel tur: visitera före hälsning nekas", F.utforMoment(s, "visitera", "vis:ogon", "troy")[1] === "forb.fel_tur");
  prova("fel häst nekas före turordningen", F.utforMoment(s, "visitera", "vis:ogon", "lydia")[1] === "forb.fel_hast");
  F.utforMoment(s, "halsa", "halsa1", "troy");
  prova("ett rätt val klarar hälsningen", s.klara.halsa === true);
  prova("visitation i ordning: mun före ögon nekas", F.utforMoment(s, "visitera", "vis:mun", "troy")[1] === "forb.fel_tur");
}
{
  const s = F.nyState("troy", 1);
  const r = helaKedjan(s);
  prova("hela kedjan manuellt → redo", r[0] && F.redo(s) && F.provaUppsittning(s, "troy")[0], JSON.stringify(r));
  prova("allt manuellt: andel 1, dagsform 0,76", F.egenAndel(s) === 1 && Math.abs(F.dagsform(s) - 0.76) < 1e-9,
    `${F.egenAndel(s)} / ${F.dagsform(s)}`);
}
{
  const s = F.nyState("troy", 1);
  F.utforMoment(s, "halsa", "halsa1", "troy");
  F.utforMoment(s, "visitera", "vis:ogon", "troy");
  F.utforMoment(s, "visitera", "vis:mun", "troy");
  F.utforMoment(s, "visitera", "vis:sadel", "troy");
  F.utforMoment(s, "visitera", "vis:gjord", "troy");
  F.utforMoment(s, "visitera", "vis:ben", "troy");
  for (const m of F.moment("rykta")) F.utforMoment(s, "rykta", m.id, "troy");
  for (const id of ["hov:vf", "hov:vb", "hov:hb", "hov:hf"]) F.utforMoment(s, "iordning", id, "troy");
  const r = F.utforMoment(s, "iordning", "utr:1", "troy");
  prova("sadeln måste hämtas från boxfronten först", !r[0] && r[1] === "tack.hamta_forst", r[1]);
}
{
  const s = F.nyState("troy", 1);
  F.utforMoment(s, "halsa", "halsa2", "troy");
  const r = F.autoForbered(s);
  prova("autoForbered klarar allt utom leda", r[0] && !s.klara.leda && F.nasta(s).id === "leda", JSON.stringify(r));
  prova("autoForbered markerar aldrig ett felaktigt alternativ", !s.gjorda.halsa.halsa3);
  prova("ett manuellt moment nedgraderas aldrig", s.gjorda.halsa.halsa2 === true);
  prova("stallets hand räknas inte som spelarens", F.egenAndel(s) > 0 && F.egenAndel(s) < 0.2, String(F.egenAndel(s)));
  const t = F.nyState("troy", 1); F.autoForbered(t);
  prova("allt stallets: andel 0, dagsform = START.DAGSFORM", F.egenAndel(t) === 0 && F.dagsform(t) === START.DAGSFORM);
}
{
  /* Ett fyndpass: första (häst, pass) som ger ett fynd. */
  let hp = null;
  for (let p = 2; !hp && p < 40; p++) if (F.fyndFor("troy", p)) hp = p;
  const s = F.nyState("troy", hp);
  const r = F.autoForbered(s);
  prova("stallet stannar vid fyndet — beslutet är spelarens", !r[0] && r[1] === "forb.oppet_fynd" && s.fyndSett, `pass ${hp} ${s.fynd}`);
  const fel2 = F.svaraFynd(s, "svar:2");
  prova("fel svar: «inte ditt beslut», fyndet står kvar", !fel2[0] && fel2[1] === "forb.inte_ditt_beslut" && !s.fyndRapporterat);
  prova("allt annat nekas medan fyndet står öppet", F.utforMoment(s, "rykta", "rykt:skrapa:kropp", "troy")[1] === "forb.oppet_fynd");
  const ratt = F.svaraFynd(s, "svar:1");
  prova("rätt svar STOPPAR arbetet", ratt[0] && s.stoppad === s.fynd);
  prova("ett stoppat arbete kan inte sittas upp på", F.provaUppsittning(s, "troy")[1] === "forb.lararen_tar_over");
  prova("och ingen annan handling går igenom", F.utforMoment(s, "rykta", "rykt:skrapa:kropp", "troy")[1] === "forb.lararen_tar_over");
}

/* ── B. Paritet mot Roblox ───────────────────────────────────────── */
console.log("\n── B. Paritet mot Preparation.luau ──");
let luau = null;
try {
  execFileSync("python", ["roblox/tests/build.py", "tests/forberedelse-webb.spec.luau"], { cwd: ROT, stdio: "pipe" });
  luau = execFileSync("luau", ["roblox/tests/.build/forberedelse-webb.spec.luau"], { cwd: ROT, encoding: "utf8" });
} catch (e) {
  console.log("  NOT_TESTED paritet mot Luau — " + String(e.message).split("\n")[0]);
}
if (luau) {
  const rader = luau.split(/\r?\n/).filter(Boolean);
  let jamforda = 0;
  for (const r of rader) {
    const d = r.split(" ");
    if (d[0] === "MOMENT") {
      const webb = F.moment(d[1]).map(m => (m.fel ? "!" : "") + m.id).join(",");
      jamforda++;
      if (webb !== d[2]) prova(`momenten i ${d[1]}`, false, `webb ${webb} · roblox ${d[2]}`);
    } else if (d[0] === "FYND") {
      const webb = String(F.fyndFor(d[1], Number(d[2])) ?? "nil");
      jamforda++;
      if (webb !== d[3]) prova(`fynd ${d[1]} pass ${d[2]}`, false, `webb ${webb} · roblox ${d[3]}`);
    } else if (d[0] === "TILLDELA") {
      const webb = String(W.tilldela(Number(d[1]), {}, VILANDE[d[2]], d[3] === "nil" ? null : d[3]) ?? "nil");
      jamforda++;
      if (webb !== d[4]) prova(`tilldelning uid ${d[1]} vilande ${d[2]} önskan ${d[3]}`, false, `webb ${webb} · roblox ${d[4]}`);
    } else if (d[0] === "BOX") {
      let rad = "nil", plats = 0, y = 0;
      for (const r of W.S.rader) {
        const i = (W.S.boxar[r.id] || []).indexOf(d[1]);
        if (i >= 0) { rad = r.id; plats = i + 1; const f = W.S.fack[r.id][i]; y = (f.y0 + f.y1) / 2; }
      }
      jamforda++;
      const sammaY = d[2] === "nil" || Math.abs(y - Number(d[4])) < 0.01;
      if (rad !== d[2] || plats !== Number(d[3]) || !sammaY)
        prova(`box ${d[1]}`, false, `webb ${rad} ${plats} y ${y.toFixed(3)} · roblox ${d[2]} ${d[3]} y ${d[4]}`);
    } else if (d[0] === "ANTAL") {
      jamforda++;
      if (Number(d[1]) !== W.antal) prova("hästordningens längd", false, `webb ${W.antal} · roblox ${d[1]}`);
    } else if (d[0] === "ANDEL") {
      let s = F.nyState("troy", 1);
      if (d[1] === "blandad") {
        F.utforMoment(s, "halsa", "halsa2", "troy");
        for (const m of F.moment("visitera")) F.utforMoment(s, "visitera", m.id, "troy");
      }
      F.autoForbered(s);
      jamforda++;
      if (F.egenAndel(s).toFixed(6) !== d[2]) prova(`andel ${d[1]}`, false, `webb ${F.egenAndel(s).toFixed(6)} · roblox ${d[2]}`);
    }
  }
  const fynd = rader.filter(r => r.startsWith("FYND") && !r.endsWith("nil")).length;
  const tilldelningar = rader.filter(r => r.startsWith("TILLDELA")).length;
  const boxar = rader.filter(r => r.startsWith("BOX")).length;
  /* L2/L3 (P1b R1): varje startrest ska ha jämförts, och boxarna ska vara
     lika många som kanonens hästar — inte ett avskrivet tal. */
  const rester = new Set(rader.filter(r => r.startsWith("TILLDELA"))
    .map(r => ((Number(r.split(" ")[1]) % W.antal) + W.antal) % W.antal));
  const negativa = rader.some(r => r.startsWith("TILLDELA -"));
  prova("tilldelningen jämförd för VARJE startrest och för negativa uid", rester.size === W.antal && negativa,
    `${rester.size}/${W.antal} rester · negativa ${negativa}`);
  prova("alla Roblox-rader har samma svar på webben",
    fel === 0 && jamforda >= 100 && tilldelningar >= 100 && boxar === W.antal && rader.some(r => r.startsWith("ANTAL")),
    `${jamforda} rader jämförda: ${fynd} fynddagar, ${tilldelningar} tilldelningar, ${boxar} boxar`);
}

console.log(fel ? `\n${fel} fel.` : "\nalla gröna");
process.exit(fel ? 1 : 0);
