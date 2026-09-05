#!/usr/bin/env node
/* PO-FLÖDET — den VERKLIGA vägen till läktaren, från spelstart.

   Senior review av #85 hittade luckan: tools/laktartest.mjs kör
   `startaVandring()` och placerar sedan figuren med `gaTill("ridhusinne",
   …)` på dörrens innerkoordinat. Det är inte vad en spelare gör. Testet
   kunde alltså vara grönt medan den faktiska webbrutten var trasig — och
   det var precis vad som hände: PO kunde inte gå på läktaren i previewn.

   Här finns INGEN gaTill in i ridhusinne. Kedjan är spelarens:

     spelstart på gården  →  gå till entrémarkören  →  E  →  ridhusinne
     →  hitta vägen upp  →  läktardäcket

   Allt gås med riktiga tangenter genom spelets inputväg.

   Kör: python3 tools/build.py && node tools/poflode.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8871;
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": "text/html" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
/* --endast=fysisk | ux
   Fysisk framkomlighet och diskoverbarhet är två olika fynd, och senior
   review var tydlig med att det andra inte får användas för att förklara
   det första. Körs de i samma CI-steg blir jobbet rött av UX-fallet och
   döljer att fysiken är lagad. Flaggan låter dem grinda var för sig. */
const ENDAST = (process.argv.find(a => a.startsWith("--endast=")) || "").split("=")[1] || "allt";
const korFysisk = ENDAST === "allt" || ENDAST === "fysisk";
const korUX = ENDAST === "allt" || ENDAST === "ux";

const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };
const mat = (namn, detalj) => console.log("  mät ", namn, "—", detalj);

for (const mobil of [false, true]) {
  const namn = mobil ? "MOBIL/touch" : "DATOR/tangent";
  const page = await browser.newPage(mobil
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  page.on("pageerror", e => console.log("PAGEERROR", e.message));
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(1600);
  await page.evaluate(() => startaVandring());
  await page.waitForTimeout(600);
  await page.evaluate(() => { if (G.vy !== "3d") vaxlaVy(); });
  await page.waitForTimeout(400);

  const F = await page.evaluate(() => {
    const d = ANL.dorrar.find(d => d.id === "ridhus_n");
    const ls = SPELABSTRAKTIONER.ridhus.laktarSteg, L = RIDHUSINNE.laktare;
    return { start: { x: VD.px, y: VD.py }, markor: d.pos, spawn: d.spawn,
      steg: { x0: ls.x0, x1: ls.x1, y0: ls.y0, y1: ls.y1 },
      dack: { z: L.dackZ, x0: L.x0, d: L.dackDjup } };
  });

  /* Går mot en punkt med riktiga tangenter, som spelaren: spelet räknar
     ix = D − A, iy = W − S och roterar med kameran. Harnessen väljer bara
     vilka tangenter som hålls. */
  const VAL = [{ ix: 0, iy: 1, k: ["KeyW"] }, { ix: 1, iy: 1, k: ["KeyW", "KeyD"] },
    { ix: -1, iy: 1, k: ["KeyW", "KeyA"] }, { ix: 1, iy: 0, k: ["KeyD"] }, { ix: -1, iy: 0, k: ["KeyA"] }];
  const vd = a => Math.atan2(Math.sin(a), Math.cos(a));
  let nere = [], joy = false;
  const tryck = async v => {
    if (mobil) { await page.evaluate(({ ix, iy }) => { window.__mal = { ix, iy }; }, v); return; }
    for (const t of nere) if (!v.k.includes(t)) await page.keyboard.up(t);
    for (const t of v.k) if (!nere.includes(t)) await page.keyboard.down(t);
    nere = v.k.slice();
  };
  const slapp = async () => {
    if (mobil) { await page.evaluate(() => { if (window.__joy) clearInterval(window.__joy); window.__joy = null; IN.joy = null; }); joy = false; return; }
    for (const t of nere) await page.keyboard.up(t); nere = [];
  };
  async function gaMot(mal, maxMs) {
    /* Målet ligger på window.__mal och LÄSES varje tick. Först skapade jag
       intervallet en gång och fångade `mal` i stängningen, så alla ben
       styrde mot det första benets mål — ett fel i harnessen som såg ut
       som ett fel i spelet. */
    await page.evaluate(({ mal }) => { window.__mal = mal; }, { mal });
    if (mobil && !joy) {
      await page.evaluate(() => { window.__joy = setInterval(() => {
        const m = window.__mal; if (!m) return;
        const k = Math.atan2(m[1] - VD.py, m[0] - VD.px);
        const v = vandringYaw(), w = v - k;
        IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); });
      joy = true;
    }
    const t0 = Date.now(); let forra = null, still = 0, st = null;
    for (;;) {
      await page.waitForTimeout(120);
      st = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2),
        yaw: vandringYaw(), scen: G.scen }));
      if (Math.hypot(st.x - mal[0], st.y - mal[1]) < 0.7) return { ...st, slut: "framme" };
      const fl = forra ? Math.hypot(st.x - forra.x, st.y - forra.y) : Infinity;
      still = fl < 0.03 ? still + 1 : 0; forra = st;
      if (still >= 8) return { ...st, slut: "STOPP" };
      if (Date.now() - t0 > maxMs) return { ...st, slut: "tid slut" };
      if (!mobil) {
        const m = Math.atan2(mal[1] - st.y, mal[0] - st.x);
        let b = VAL[0], bd = Infinity;
        for (const v of VAL) { const d = Math.abs(vd(st.yaw - Math.atan2(v.ix, v.iy) - m)); if (d < bd) { bd = d; b = v; } }
        if (b.k.join() !== nere.join()) await tryck(b);
      }
    }
  }

  /* 1. Gården → entrémarkören → in. Ingen gaTill. */
  let r = await gaMot(F.markor, 120000); await slapp();
  const vidEntre = r.slut === "framme";
  if (vidEntre) { await page.keyboard.down("KeyE"); await page.waitForTimeout(200);
    await page.keyboard.up("KeyE"); await page.waitForTimeout(900); }
  const inne = await page.evaluate(() => ({ scen: G.scen, x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
  prova(`${namn}: spelstart på gården → entrén → inne i ridhuset (ingen gaTill)`,
    vidEntre && inne.scen === "ridhusinne",
    `gården (${F.start.x}, ${F.start.y}) → markören → scen ${inne.scen} vid (${inne.x}, ${inne.y})`);

  /* 2. DISKOVERBARHET — den fråga PO:s repro ställer.
     Spelaren landar 20 m öster om läktaren och vet inte var uppgången är.
     Finns någon ledtråd i spelet som pekar dit? Markörerna räknas upp och
     mäts; kravet är att MINST EN av dem leder till läktaren eller dess
     uppgång. Utan det finns vägen men går inte att hitta, och det är
     precis vad "kan inte gå på läktaren" betyder för en spelare. */
  const cue = await page.evaluate(({ steg, dack }) => {
    const L = interaktioner();
    const nara = L.map(i => ({ text: i.text, pos: i.pos,
      avst: +Math.hypot(VD.px - i.pos[0], VD.py - i.pos[1]).toFixed(1) })).sort((a, b) => a.avst - b.avst);
    /* En markör "leder till läktaren" om den står på däcket eller vid
       uppgången — inte om den råkar nämna något annat. */
    /* En markör LEDER TILL LÄKTAREN bara om den står PÅ den — alltså på
       däcksnivå — eller uttryckligen nämner den. Att en dörr råkar ligga
       inom däckets x-intervall räcker inte: «Ut» vid (1,6, 67,2) står på
       hallgolvet och leder ut ur huset, inte upp. Första versionen av det
       här filtret godkände den, och det var ett falskt positivt i mitt
       eget test. */
    const pekar = nara.filter(m =>
      /läktar/i.test(m.text) || ridhusNiva(m.pos[0], m.pos[1], 0) >= dack.z - 0.02);
    return { alla: nara.slice(0, 6), pekar };
  }, F);
  mat(`${namn}: markörer inom räckhåll vid ankomsten`,
    cue.alla.map(m => `${m.avst} m «${m.text}»`).join("  ·  "));
  if (korUX) prova(`${namn}: spelet pekar ut vägen upp på läktaren från entrén`,
    cue.pekar.length > 0,
    cue.pekar.length ? cue.pekar.map(m => `«${m.text}» @ ${m.avst} m`).join(", ")
      : "INGEN markör leder till läktaren eller dess uppgång — vägen finns men går inte att hitta");

  /* 3. FYSISK FRAMKOMLIGHET MED MÄNSKLIG FELMARGINAL.

     Senior review av b5239be, och den träffade rätt: förra fallet styrde
     mot exakta koordinater och korrigerade kursen varje tick. Det bevisar
     att en idealiserad agent hittar en smal passage — inte att en spelare
     kan gå upp. Och Tobias sa inte att han inte HITTAR läktaren; han sa
     att det inte GÅR att gå upp. Diskoverbarhet får inte förklara bort
     hans repro.

     Här ställs figuren några meter norr om uppgången på en rad
     sidolägen, och går sedan RAKT SÖDERUT med fast kurs. Ingen
     waypointkorrigering, ingen styrning under approachen — det är en
     spelare som siktar ungefär och går. Varje stopp loggas med allt som
     behövs för att se varför: läge, nivå, nivåerna i punkten, kurs och
     vilken tangent/spak som hölls. */
  const mittX = (F.steg.x0 + F.steg.x1) / 2;
  const approach = [];
  /* Sidolägena hålls INOM rampen. Rampen är 0,9 m bred, alltså ±0,45 m
     från mitten. Att pröva ±0,6 m vore att sikta utanför uppgången och
     kalla bommen ett fel — första versionen gjorde det, och mätte då
     kortändans block i stället för uppgången. */
  for (const dx of [-0.4, -0.2, 0, 0.2, 0.4]) {
    const x0 = +(mittX + dx).toFixed(2), y0 = +(F.steg.y1 + 3.0).toFixed(2);
    /* Ställ figuren på startläget via en STYRD promenad dit — det är
       hallgolvet, inte uppgången, och att gå dit är inte det som mäts.
       UPPSTÄLLNINGEN VERIFIERAS: kom hon inte fram redovisas det som just
       det, i stället för att mäta en rak approach från fel plats. Så gick
       det fel förra gången — startlägena hamnade öster om rampen och jag
       mätte kortändan. */
    let start = null;
    for (let f = 0; f < 2; f++) {
      /* RUTTEN, inte fågelvägen. Harnessen går greedy mot en punkt och kan
         inte runda ett hinder på egen hand, så uppställningen får
         vägpunkterna: genom skåppassagen, västerut, sedan söderut. Det är
         vägen en spelare tar; det som MÄTS är den sista raka approachen
         mot rampen, utan korrigering. */
      for (const wp of [[5.6, 73.4], [3.6, 73.4], [x0, 71.0]]) {
        await gaMot(wp, 40000); await slapp();
      }
      await gaMot([x0, y0], 60000); await slapp();
      start = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
      /* Toleransen måste vara vidare än gaMot:s egen ankomstradie (0,7 m),
         annars underkänns en uppställning som walkern anser färdig — så
         var det först, och det gav fyra falska "kunde inte ställa upp".
         För en rak promenad söderut är det X som betyder något; y får
         gärna ligga någon meter längre norrut. */
      if (Math.abs(start.x - x0) < 0.35 && Math.abs(start.y - y0) < 1.2) break;
    }
    if (!(Math.abs(start.x - x0) < 0.35 && Math.abs(start.y - y0) < 1.2)) {
      approach.push({ dx, start, x: start.x, y: start.y, z: 0, niva: null, nivaer: [],
        kurs: null, slut: "KUNDE INTE STÄLLA UPP", input: mobil ? "IN.joy" : "KeyW",
        mal: [x0, y0] });
      continue;
    }

    /* Rakt söderut, fast kurs, ingen korrigering. */
    await page.evaluate(() => { window.__mal = null;
      if (window.__joy) { clearInterval(window.__joy); window.__joy = null; }
      VD.rikt = -Math.PI / 2; if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; });
    await page.waitForTimeout(350);
    if (mobil) await page.evaluate(() => { window.__joy = setInterval(() => {
        const v = vandringYaw(), w = v - (-Math.PI / 2);
        IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); });
    else await page.keyboard.down("KeyW");
    let p = null, f = null, still = 0;
    const t0 = Date.now();
    for (;;) {
      await page.waitForTimeout(140);
      p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2),
        niva: +ridhusNiva(VD.px, VD.py, VD.pz || 0).toFixed(2),
        nivaer: ridhusNivaer(VD.px, VD.py).map(v => +v.toFixed(2)),
        kurs: +(VD.rikt * 180 / Math.PI).toFixed(1) }));
      if (p.z >= F.dack.z - 0.02) { p.slut = "uppe"; break; }
      const fl = f ? Math.hypot(p.x - f.x, p.y - f.y) : Infinity;
      still = fl < 0.03 ? still + 1 : 0; f = p;
      if (still >= 7) { p.slut = "STOPP"; break; }
      if (Date.now() - t0 > 20000) { p.slut = "tid slut"; break; }
    }
    if (mobil) await page.evaluate(() => { clearInterval(window.__joy); window.__joy = null; IN.joy = null; });
    else await page.keyboard.up("KeyW");
    approach.push({ dx, start, ...p, input: mobil ? "IN.joy (0,-1)" : "KeyW" });
  }
  for (const a of approach)
    mat(`${namn}: rak approach ${a.dx >= 0 ? "+" : ""}${a.dx} m från mitten` +
      (a.start && a.slut !== "KUNDE INTE STÄLLA UPP"
        ? ` (verkligt x ${a.start.x}, alltså ${(a.start.x - mittX >= 0 ? "+" : "")}${(a.start.x - mittX).toFixed(2)} m)` : ""),
      `start (${a.start.x}, ${a.start.y}) → (${a.x}, ${a.y}) z ${a.z} · ${a.slut}` +
      ` · nivå ${a.niva} av ${JSON.stringify(a.nivaer)} · kurs ${a.kurs}° · ${a.input}`);
  /* KRAVET GÄLLER APPROACHER SOM FAKTISKT SIKTAR PÅ UPPGÅNGEN. Rampen är
     0,9 m bred; en approach som hamnar utanför den missar av samma skäl
     som man missar en dörr man inte går mot, och att räkna det som ett
     fel vore att mäta uppställningens precision i stället för spelet.
     Utanförliggande fall redovisas ändå, som mätvärden — de är underlag
     till den öppna frågan om uppgångens BREDD, inte till framkomligheten. */
  const inomRampen = a => a.start && a.start.x >= F.steg.x0 && a.start.x <= F.steg.x1;
  const provade = approach.filter(a => a.slut !== "KUNDE INTE STÄLLA UPP" && inomRampen(a));
  const utanfor = approach.filter(a => a.slut !== "KUNDE INTE STÄLLA UPP" && !inomRampen(a));
  if (utanfor.length)
    mat(`${namn}: approacher utanför rampens bredd (x ${F.steg.x0}–${F.steg.x1})`,
      utanfor.map(a => `x ${a.start.x}: ${a.slut === "uppe" ? "upp ändå" : "kom inte upp"}`).join("; "));
  const uppe = provade.filter(a => a.slut === "uppe");
  const ejUppstalld = approach.filter(a => a.slut === "KUNDE INTE STÄLLA UPP");
  if (ejUppstalld.length)
    mat(`${namn}: uppställningen misslyckades`,
      ejUppstalld.map(a => `${a.dx} m: ville (${a.mal}) men stod (${a.start.x}, ${a.start.y})`).join("; "));
  if (korFysisk) prova(`${namn}: uppgången tål mänsklig felmarginal — rak approach utan korrigering`,
    provade.length >= 3 && uppe.length === provade.length,
    `${uppe.length} av ${provade.length} approacher inom rampen kom upp` +
    (provade.length < 3 ? "  ⟵ för få uppställningar lyckades för att vara ett prov" : "") +
    (uppe.length === provade.length ? ""
      : ` — FÖLL på ${provade.filter(a => a.slut !== "uppe").map(a => `x ${a.start.x} (stopp ${a.x}, ${a.y} z ${a.z}, nivå ${a.niva})`).join("; ")}`));

  /* 4. NAIV SPELARE: går rakt fram från ankomsten, som den som inte vet. */
  /* HELT ostyrd: bara framåt, ingen A/D, ingen joystickkorrigering. Det
     är vad någon gör som inte vet vart hon ska. Styr man mot en punkt är
     promenaden inte naiv, och då mäter fallet fel sak — så var det i
     första versionen av det här testet. */
  await page.evaluate(({ sp }) => { window.__mal = null; if (window.__joy) { clearInterval(window.__joy); window.__joy = null; }
    slutaGa(); gaTill("ridhusinne", { x: sp.x, y: sp.y, rikt: sp.rikt });
    if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; }, { sp: F.spawn });
  await page.waitForTimeout(500);
  let naiv = null;
  if (mobil) {
    await page.evaluate(() => { window.__joy = setInterval(() => {
      IN.joy = { x: 0, y: -1, styrka: 0.95 }; }, 16); });
  } else await page.keyboard.down("KeyW");
  {
    const t0 = Date.now(); let f = null, st = 0;
    for (;;) {
      await page.waitForTimeout(150);
      naiv = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }));
      const fl = f ? Math.hypot(naiv.x - f.x, naiv.y - f.y) : Infinity;
      st = fl < 0.03 ? st + 1 : 0; f = naiv;
      if (st >= 8) { naiv.slut = "STOPP"; break; }
      if (Date.now() - t0 > 25000) { naiv.slut = "tid slut"; break; }
    }
  }
  if (mobil) await page.evaluate(() => { clearInterval(window.__joy); window.__joy = null; IN.joy = null; });
  else await page.keyboard.up("KeyW");
  mat(`${namn}: bara framåt från ankomsten, ingen styrning alls`,
    `stannade (${naiv.x}, ${naiv.y}) z ${naiv.z} — ${naiv.slut}` +
    (naiv.z >= F.dack.z - 0.02 ? "  (hamnade ändå på däcket)" : "  (kom aldrig upp)"));

  await page.close();
}
await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
