#!/usr/bin/env node
/* RIDKÄNSLANS MÄTVÄRDEN — G02-A.1 P1.

   Arbetsordern är tydlig på punkten: mät FÖRE du trimmar. Utan en
   baslinje går det inte att visa att en ändring gjorde något, och en
   trimning som inte kan mätas är en åsikt.

   Verktyget kör den kanoniska ridmodellen rakt, utan webbläsare, med
   avdriften avstängd så att samma indata alltid ger samma tal. Det gör
   det snabbt nog att ligga i `grindar`-jobbet och kort nog att läsas som
   en tabell i en PR-kommentar.

   Mäter, per gångart och riktning:
     · cue→respons   tiden från hjälp till att tempot börjar röra sig
     · övergångstid  tiden från hjälp till att gångarten faktiskt bytt
     · insvängning   tiden tills tempot lagt sig inom 5 % av sitt slutvärde
     · överslag      hur mycket tempot skjuter över slutvärdet
     · acceleration  största tempoändring per sekund
     · stoppsträcka  meter från paradens början till stillastående

   Kurvaturens tidskonstanter läses ur kanonen och redovisas som
   konfigurerade värden — de mäts i den ridna banan av ridtest, inte här.

   Kör: node tools/ridkansla.mjs [--json] */
import fs from "node:fs"; import path from "node:path"; import vm from "node:vm";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const ctx = vm.createContext({ console, Math, JSON });
for (const f of ["src/model.js", "src/riding/hjalper.js", "src/riding/telemetri.js"])
  vm.runInContext(fs.readFileSync(path.join(ROT, f), "utf8"), ctx, { filename: f });

const DT = 1 / 120;                     // fin upplösning: tiderna mäts, inte bildrutorna
const HAST = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.4, skygghet: 0.2, flaggor: {} };
const MILJO = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false, fard: {},
                avdrift: { glid: 0, ryck: 0, tröghet: 1 } };

/* Kör en följd av (hjälp, sekunder) och returnera hela spåret. */
const spela = (steg) => vm.runInContext(`(() => {
  const s = nyState(0.7, 0.5, 0.8), spar = [];
  const A = (o) => ({ skankel:0, tygel:0, sits:0, styrning:0, spo:false, lattridning:false, diagonal:0, ...o });
  for (const [aid, sek] of ${JSON.stringify(steg)}) {
    const a = A(aid);
    for (let i = 0; i < Math.round(sek / ${DT}); i++) {
      stepRide(s, a, ${JSON.stringify(HAST)}, ${JSON.stringify(MILJO)}, ${DT});
      spar.push({ t: s._tid, tempo: s.tempo, gangart: s.gangart, bad: s.malGangart,
        iOvergang: !!s._ov });
    }
  }
  return spar;
})()`, ctx);

/* Mätvärdena ur ett spår, räknat från tidpunkten `t0` då hjälpen gavs. */
/* `t1` AVGRÄNSAR FÖNSTRET. Utan den sträckte sig varje mätning till
   spårets slut, så skrittens "jämvikt" blev galoppens tempo och
   insvängningen mättes till nästa gångart i stället för till sin egen.
   Talen såg rimliga ut och var fel — precis den sortens baslinje som
   hade gjort hela trimningen meningslös. */
function matt(spar, t0, malGangart, t1, kort) {
  const efter = spar.filter(p => p.t >= t0 && (t1 === undefined || p.t < t1));
  if (!efter.length) return null;
  const start = efter[0].tempo;
  const slut = efter[efter.length - 1].tempo;
  const spann = Math.abs(slut - start);
  /* Slutvärdet tas som medel över sista sekunden — tempot vandrar en
     aning även med avdriften av, och ett enda sista värde vore brus. */
  const sista = efter.filter(p => p.t >= efter[efter.length - 1].t - 1.0);
  const jamvikt = sista.reduce((a, p) => a + p.tempo, 0) / sista.length;

  const rorde = efter.find(p => Math.abs(p.tempo - start) > Math.max(0.02 * spann, 0.01));
  const bytte = malGangart ? efter.find(p => p.gangart === malGangart) : null;
  /* KLAR är när förloppet är slut, inte när etiketten byter. Etiketten
     byter vid BYTPUNKT (55 %) — mäter man den tror man att övergången är
     nästan halva så lång som den är, och trimmar mot fel tal. Båda
     redovisas, för de betyder olika saker: `etikett` är när travet SYNS,
     `övergång` är när hon är etablerad i det. */
  const iOv = efter.find(p => p.iOvergang);
  const klar = iOv ? efter.find(p => p.t > iOv.t && !p.iOvergang) : null;
  const inom = efter.find(p => Math.abs(p.tempo - jamvikt) <= 0.05 * Math.max(jamvikt, 0.1)
    && p.t > (rorde ? rorde.t : t0));
  let overslag = 0;
  for (const p of efter) {
    const over = slut >= start ? p.tempo - jamvikt : jamvikt - p.tempo;
    if (over > overslag) overslag = over;
  }
  let topp = 0;
  for (let i = 1; i < efter.length; i++) {
    const d = Math.abs(efter[i].tempo - efter[i - 1].tempo) / DT;
    if (d > topp) topp = d;
  }
  return {
    respons: rorde ? +(rorde.t - t0).toFixed(3) : null,
    etikett: bytte ? +(bytte.t - t0).toFixed(2) : null,
    overgang: klar ? +(klar.t - t0).toFixed(2) : null,
    /* KORT FÖNSTER: jämvikten hinner aldrig bli en jämvikt, och då blir
       överslag och insvängning tal utan innebörd — skritt→halt gav
       "100 % överslag" enbart för att medelvärdet låg mitt i förloppet.
       Hellre tomt än osant. Överslaget för hela paraden mäts i svepraden,
       som har fönster nog. */
    insvangning: kort ? null : (inom ? +(inom.t - t0).toFixed(2) : null),
    overslag: kort ? null : +(overslag / Math.max(jamvikt, 0.1) * 100).toFixed(1),
    acceleration: +topp.toFixed(2),
    jamvikt: kort ? null : +jamvikt.toFixed(2),
  };
}

/* Stoppsträckan: metrarna från paradens början tills hon står. */
function stoppstracka(spar, t0) {
  let s = 0, stod = null;
  const efter = spar.filter(p => p.t >= t0);
  for (let i = 1; i < efter.length; i++) {
    s += efter[i].tempo * (efter[i].t - efter[i - 1].t);
    if (efter[i].tempo < 0.05) { stod = { m: s, t: efter[i].t - t0 }; break; }
  }
  return stod ? { m: +stod.m.toFixed(2), t: +stod.t.toFixed(2) } : null;
}

const HALL = { skankel: 0.35, tygel: 0.15, sits: 0.2 };
const rader = [];
/* UPPÅT, en gångart i taget. Hjälpen höjs, sedan hålls den. */
{
  const niva = [0.35, 0.60, 0.85], mal = ["skritt", "trav", "galopp"];
  const steg = [[{ ...HALL, skankel: 0 }, 2]];
  const cueT = [];
  let t = 2;
  for (let i = 0; i < 3; i++) { cueT.push(t); steg.push([{ ...HALL, skankel: niva[i] }, 10]); t += 10; }
  const spar = spela(steg);
  for (let i = 0; i < 3; i++)
    rader.push({ moment: `${i === 0 ? "halt" : mal[i-1]}→${mal[i]}`, ...matt(spar, cueT[i], mal[i], cueT[i] + 10) });
}
/* NEDÅT, ETT STEG I TAGET. Kuvertet 0,6–1,2 s gäller per övergång, inte
   galopp→halt i ett svep: en parad genom gångarterna är tre övergångar
   och tar med spärren emellan naturligt längre. Mätte jag hela svepet mot
   ett ensteg-kuvert skulle jag trimma bort spärren, som finns av ett
   annat skäl. */
{
  const HH = { skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 };
  const upp = [[0.35, 8], [0.60, 8], [0.85, 10]];
  const steg = [[{ ...HALL, skankel: 0 }, 2]];
  let t = 2;
  for (const [n, sek] of upp) { steg.push([{ ...HALL, skankel: n }, sek]); t += sek; }
  steg.push([HH, 25]);
  const spar = spela(steg);
  for (const [namn, mal, forskjut] of [["galopp→trav", "trav", 0], ["trav→skritt", "skritt", 0.95], ["skritt→halt", "halt", 1.9]])
    rader.push({ moment: namn, ...matt(spar, t + forskjut, mal, t + forskjut + 0.95, true) });
}
/* NEDÅT från galopp med en hållen parad, hela svepet. */
{
  const steg = [[{ ...HALL, skankel: 0 }, 2], [{ ...HALL, skankel: 0.35 }, 8],
    [{ ...HALL, skankel: 0.60 }, 8], [{ ...HALL, skankel: 0.85 }, 10],
    [{ skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 }, 25]];
  const spar = spela(steg);
  const t0 = 28;
  rader.push({ moment: "galopp→halt (hållen parad)", ...matt(spar, t0, "halt") });
  const st = stoppstracka(spar, t0);
  rader.push({ moment: "  stoppsträcka från galopp", stracka: st ? `${st.m} m på ${st.t} s` : "stannade inte" });
}
/* STOPPSTRÄCKA från skritt och trav var för sig. */
for (const [namn, upp] of [["skritt", [[0.35, 8]]], ["trav", [[0.35, 8], [0.60, 8]]]]) {
  const steg = [[{ ...HALL, skankel: 0 }, 2]];
  let t = 2;
  for (const [n, sek] of upp) { steg.push([{ ...HALL, skankel: n }, sek]); t += sek; }
  steg.push([{ skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 }, 20]);
  const st = stoppstracka(spela(steg), t);
  rader.push({ moment: `  stoppsträcka från ${namn}`, stracka: st ? `${st.m} m på ${st.t} s` : "stannade inte" });
}

/* ── INOM GÅNGARTEN (G02-A.1 P3) ────────────────────────────────────
   Karaktären syns inte i övergångarna utan i hur hon svarar när hon
   REDAN går i gångarten: en skritt ska rätta sig kvickt och lugnt, en
   galopp bära sin rörelsemängd. Mäts som svaret på en höjd skänkel som
   varierar tempot inom bandet, utan att be om nästa gångart. */
{
  const etabl = { skritt: [[0.35, 10]], trav: [[0.35, 8], [0.60, 10]],
                  galopp: [[0.35, 8], [0.60, 8], [0.85, 10]] };
  for (const g of ["skritt", "trav", "galopp"]) {
    const steg = [[{ ...HALL, skankel: 0 }, 2]];
    let t = 2, sista = 0;
    for (const [n, sek] of etabl[g]) { steg.push([{ ...HALL, skankel: n }, sek]); t += sek; sista = n; }
    /* En liten höjning: under CUE_UPP, så den ber inte om nästa gångart —
       den ber om mer inom den hon går i. */
    steg.push([{ ...HALL, skankel: sista + 0.12 }, 8]);
    const m = matt(spela(steg), t, null, t + 8);
    rader.push({ moment: `  inom ${g} (hjälp +0,12)`, respons: m.respons,
      insvangning: m.insvangning, overslag: m.overslag, acceleration: m.acceleration, jamvikt: m.jamvikt });
  }
}

const kanon = vm.runInContext("ridKanon()", ctx);
if (process.argv.includes("--json")) { console.log(JSON.stringify({ rader, kanon }, null, 2)); process.exit(0); }

console.log("RIDKÄNSLANS MÄTVÄRDEN — kanonisk modell, avdrift av, dt " + DT.toFixed(4) + " s\n");
const kol = ["moment", "respons", "etikett", "overgang", "insvangning", "overslag", "acceleration", "jamvikt", "stracka"];
const rubrik = { moment: "moment", respons: "cue→resp", etikett: "etikett", overgang: "övergång", insvangning: "insvängn",
  overslag: "överslag", acceleration: "accel", jamvikt: "jämvikt", stracka: "stoppsträcka" };
const bredd = {};
for (const k of kol) bredd[k] = Math.max(rubrik[k].length, ...rader.map(r => String(r[k] ?? "").length));
const rad = (o) => kol.map(k => String(o[k] ?? "").padEnd(bredd[k])).join("  ");
console.log(rad(rubrik));
console.log(kol.map(k => "─".repeat(bredd[k])).join("  "));
for (const r of rader) console.log(rad(r));
console.log("\nenheter: sekunder · överslag i % av jämvikt · accel i m/s² · jämvikt i m/s");
console.log(`styrningen (kanon, mäts i banan av ridtest): κ-tak ${kanon.KAPPA_MAX} 1/m`);
console.log(`  hur SNÄVT per gångart (GANGSVANG):  ${JSON.stringify(kanon.GANGSVANG)}`);
console.log(`  hur TRÖGT per gångart (SVANGTAU):   ${JSON.stringify(kanon.SVANGTAU || {})}`);
