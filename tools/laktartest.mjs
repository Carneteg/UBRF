#!/usr/bin/env node
/* Läktartest — issue #81 (P0). Kör spelets RIKTIGA movement-loop i 3D-vyn,
   bildruta för bildruta, med tangent OCH touch/joystick. Anropar aldrig
   vägsökaren: det var precis luckan i gangtest.mjs, som växlar till
   2D-kartvyn och därför aldrig provade den runtime PO faktiskt spelar.

   Bevisar per fall: spelaren går från golvnivå (z 0) upp på läktardäcket
   utan teleport (inget hopp > NIVA_STEG mellan bildrutor) och kan sedan
   röra sig minst 10 m längs läktargången.

   Kör: python3 tools/build.py && node tools/laktartest.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8812;
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

async function sida(mobil) {
  const page = await browser.newPage(mobil
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  page.on("pageerror", e => console.log("PAGEERROR", e.message));
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(1800);
  await page.evaluate(() => startaVandring());
  await page.waitForTimeout(600);
  await page.evaluate(() => { if (G.vy !== "3d") vaxlaVy(); });   // PO:s vy
  await page.waitForTimeout(400);
  return page;
}
/* Går med spelets riktiga loop och loggar VARJE prov: läge, nivå och att
   nivåbytet aldrig överstiger NIVA_STEG (ingen teleport). `touch` matar
   IN.joy som mobil.js gör; annars trycks riktiga tangenter (W + A/D).
   INGEN rad skriver spelarens kurs — styrningen går genom spelets egen
   inputväg, se blocket längre ned. */
async function ga(page, { x, y, z = 0, rikt, mot, ms, touch, klar, fortsatt }) {
  /* `fortsatt`: gå vidare från nuvarande läge i stället för att placeras om.
     Behövs för rutter i flera ben — en spelare som kommer in genom dörren
     går först fram till stegen och SEDAN upp för dem. Ett enda rakt ben
     från dörren till stegens mitt går inte in på stegen alls; det mäter
     däckets kant, inte stegen. */
  if (!fortsatt) {
    await page.evaluate(({ x, y, z, rikt }) => { slutaGa(); gaTill("ridhusinne", { x, y, rikt, z }); }, { x, y, z, rikt });
    await page.waitForTimeout(500);
  } else {
    await page.evaluate(() => slutaGa());
    await page.waitForTimeout(150);
  }
  /* ENDA stället kursen sätts, och bara vid PLACERING: åt vilket håll
     figuren råkar titta när hon ställs ned. Motsvarar var en spelare har
     kameran när hon börjar gå. Under själva gåendet skrivs kursen aldrig
     — den kommer ur tangenterna respektive joysticken. */
  if (!fortsatt) await page.evaluate(({ rikt }) => { VD.rikt = rikt; if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; }, { rikt });
  await page.waitForTimeout(400);
  await page.evaluate(() => { window.__spar = []; window.__hopp = 0; let f = (VD.pz || 0);
    window.__tick = () => { const z = VD.pz || 0; if (Math.abs(z - f) > NIVA_STEG + 1e-6) window.__hopp++; f = z;
      window.__spar.push([+VD.px.toFixed(2), +VD.py.toFixed(2), +z.toFixed(2)]);
      if (window.__gar) requestAnimationFrame(window.__tick); };
    window.__gar = true; requestAnimationFrame(window.__tick); });
  /* ── STYRNINGEN GÅR GENOM SPELARENS EGEN INPUTVÄG ─────────────────
     Senior re-review av #85: testet skrev förut `VD.rikt` direkt var
     16:e ms. Då bevisades kollision, nivå och rörelse — men inte
     styrningen, som är halva det #81 handlar om. Ingen rad skriver
     längre spelarens kurs.

     DATOR: riktiga tangenthändelser genom Playwright, W plus A/D. Spelet
     läser `IN.ned.KeyW/KeyA/KeyD` och räknar ut kursen själv, precis som
     när en människa spelar. Testharnessen väljer bara VILKA tangenter som
     hålls — det är samma beslut en spelare fattar.

     MOBIL: bara `IN.joy`, genom samma väg som mobil.js matar.

     Kursvalet: spelet räknar `ix = D − A`, `iy = W − S` och roterar det
     med kameran, så att den resulterande kursen blir `v − atan2(ix, iy)`.
     Med W plus A/D finns alltså fem kurser att välja mellan, 45° isär.
     Harnessen tar den som ligger närmast riktningen mot vägpunkten och
     trycker om när valet ändras — inte varje tick, bara vid byte. */
  const TANGENTVAL = [
    { ix: 0, iy: 1, tangenter: ["KeyW"] },                    // rakt fram
    { ix: 1, iy: 1, tangenter: ["KeyW", "KeyD"] },            // fram-höger, −45°
    { ix: -1, iy: 1, tangenter: ["KeyW", "KeyA"] },           // fram-vänster, +45°
    { ix: 1, iy: 0, tangenter: ["KeyD"] },                    // rakt höger, −90°
    { ix: -1, iy: 0, tangenter: ["KeyA"] },                   // rakt vänster, +90°
  ];
  const vinkelDiff = a => Math.atan2(Math.sin(a), Math.cos(a));

  let nere = [];
  const tryck = async val => {
    const vill = val.tangenter;
    for (const t of nere) if (!vill.includes(t)) await page.keyboard.up(t);
    for (const t of vill) if (!nere.includes(t)) await page.keyboard.down(t);
    nere = vill.slice();
  };

  if (touch) {
    await page.evaluate(({ rikt, mot }) => { window.__joy = setInterval(() => {
      const k = mot ? Math.atan2(mot[1] - VD.py, mot[0] - VD.px) : rikt;
      const v = vandringYaw(), w = v - k;
      IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); }, { rikt, mot });
  } else if (mot) {
    await tryck(TANGENTVAL[0]);
  } else {
    await page.keyboard.down("KeyW");
    nere = ["KeyW"];
  }

  /* Tidsoberoende: headless SwiftShader ger få bildrutor per sekund, så
     villkoret avgör, inte klockan (samma princip som gangtest.mjs). `ms`
     är bara taket. Samma avläsning bär både klar-villkoret och
     tangentbeslutet, så styrningen kostar inga extra anrop. */
  const t0 = Date.now();
  for (;;) {
    await page.waitForTimeout(touch || !mot ? 250 : 60);
    if (Date.now() - t0 > ms) break;
    const lage = await page.evaluate(({ f }) => ({
      p: { x: VD.px, y: VD.py, z: VD.pz || 0 },
      yaw: vandringYaw(),
      klar: f ? (new Function("p", "return " + f))({ x: VD.px, y: VD.py, z: VD.pz || 0 }) : false,
    }), { f: klar });
    if (lage.klar) break;
    if (!touch && mot) {
      const mal = Math.atan2(mot[1] - lage.p.y, mot[0] - lage.p.x);
      let bast = TANGENTVAL[0], bd = Infinity;
      for (const val of TANGENTVAL) {
        const kurs = lage.yaw - Math.atan2(val.ix, val.iy);
        const d = Math.abs(vinkelDiff(kurs - mal));
        if (d < bd) { bd = d; bast = val; }
      }
      if (bast.tangenter.join() !== nere.join()) await tryck(bast);
    }
  }
  if (touch) await page.evaluate(() => { clearInterval(window.__joy); IN.joy = null; });
  else for (const t of nere) await page.keyboard.up(t);
  nere = [];
  return await page.evaluate(() => { window.__gar = false;
    return { spar: window.__spar, hopp: window.__hopp, n: window.__spar.length,
      x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }; });
}
const S = Math.PI / -2;
for (const mobil of [false, true]) {
  const page = await sida(mobil);
  const namn = mobil ? "MOBIL/touch" : "DATOR/tangent";
  const I = await page.evaluate(() => { const R = RIDHUSINNE, L = R.laktare, ls = SPELABSTRAKTIONER.ridhus.laktarSteg;
    const d = R.dorrar.find(d => d.id === "ut_ridhus_W_9");
    /* Läktartrappan vid H upptar däckets nordvästra hörn och är ingen
       ingång — den går uppåt mot caféplanet. Allt ÖSTER om den, fram till
       däckets bortre kant, är däck som spelaren ska kunna nå. */
    const t = R.trappor.find(t => t.id === "laktar_trappa_h");
    return { dorr: d.pos, ls: { x0: ls.x0, x1: ls.x1, y0: ls.y0, y1: ls.y1, z0: ls.z0, z1: ls.z1 },
      L: { dackZ: L.dackZ, y1: L.y1, x0: L.x0, d: L.dackDjup },
      rader: { antal: L.rader.antal, stegH: L.rader.stegH },
      /* Högsta bänkrad man faktiskt kan STÅ på. Den översta radens band
         ligger under läktartrappan vid H (`foten på översta radens nivå`,
         ridhus-inne-39) — där tar trappan över nivån, så den raden är
         trappans fot och ingen sittplats. Räknas ur datan, inte antaget. */
      toppRad: (() => {
        const lE = (R.sidor && R.sidor.laktare === "E");
        let b = L.dackZ;
        for (const rad of laktarRader(L)) {
          const mitt = lE ? L.x0 + (rad.in0 + rad.in1) / 2
                          : L.x0 + L.dackDjup - (rad.in0 + rad.in1) / 2;
          if (t && mitt >= t.x0 && mitt <= t.x1) continue;    // trappans fot
          b = Math.max(b, rad.z);
        }
        return b;
      })(),
      /* Gångbrädan: den enda däcksytan som ligger på dackZ. Läktarens nivå
         beror på avståndet in från bankanten, så det är hit — och bara hit
         — stegen kan landa plant. */
      brada: { x0: L.x0 + L.dackDjup - L.gangbrada.djup, x1: L.x0 + L.dackDjup },
      gavel: { x0: t ? t.x1 : L.x0, x1: L.x0 + L.dackDjup } }; });
  /* 1. HELA KEDJAN I EN ENDA SAMMANHÄNGANDE KÖRNING:
     huvudentrén → fram till stegen → upp på däcket → minst 10 m längs
     läktargången. Figuren placeras EN gång, på dörrens faktiska position,
     och därefter bara går. Inga `gaTill` mellan benen, ingen teleport upp
     på däcket.

     Efter senior review av #85: förra versionen började på dörrens x men
     på en y strax norr om stegen, och bevisade 10-metersgången separat
     genom att först placera figuren på däcksnivå. Båda gjorde kedjan
     kortare än acceptanskravet. Nu byter benen bara riktning — kroppen,
     nivån och kollisionen bärs vidare hela vägen. */
  const mittX = (I.ls.x0 + I.ls.x1) / 2;
  const ben = [];

  /* Ben 1: in genom dörren och fram till stegens ingång — figuren styr mot
     punkten, precis som en spelare går mot den trappa hon ser. */
  const ingang = [mittX, I.ls.y1 + 0.9];
  let q = await ga(page, { x: I.dorr[0], y: I.dorr[1], rikt: S, mot: ingang, ms: 60000, touch: mobil,
    klar: `Math.hypot(p.x - ${ingang[0]}, p.y - ${ingang[1]}) <= 0.35` });
  ben.push(`dörr (${I.dorr[0].toFixed(2)}, ${I.dorr[1].toFixed(2)}) → (${q.x}, ${q.y})`);
  const nadeHallen = q.y <= I.ls.y1 + 1.5;
  const nadeStegen = q.x >= I.ls.x0 && q.x <= I.ls.x1;

  /* Ben 2: UPP FÖR STEGEN, mot samma x men bortom deras topp. */
  q = await ga(page, { rikt: S, mot: [mittX, I.ls.y0 - 1.5], ms: 60000, touch: mobil, fortsatt: true,
    klar: `p.z >= ${I.L.dackZ - 0.02}` });
  ben.push(`upp för stegen → (${q.x}, ${q.y}) z ${q.z}`);
  const uppe = q.z >= I.L.dackZ - 0.02;
  const yUppe = q.y, hoppUpp = q.hopp;
  /* Kravet är inte bara en höjd — det är att STÅ PÅ LÄKTAREN. En figur som
     drivit iväg österut och hamnat 1,03 m upp på något annat är inte uppe
     på läktaren, och det ska inte kunna passera som grönt. */
  const paLaktaren = q.x >= I.L.x0 - 0.05 && q.x <= I.L.x0 + I.L.d + 0.05;

  /* Ben 3: vidare minst 10 m längs läktargången — SAMMA körning, ingen
     omplacering, ingen teleport till däcksnivå. */
  q = await ga(page, { rikt: S, mot: [mittX, yUppe - 11.5], ms: 90000, touch: mobil, fortsatt: true,
    klar: `p.y <= ${yUppe - 10.4}` });
  const langd = yUppe - q.y;
  ben.push(`${langd.toFixed(1)} m längs gången → (${q.x}, ${q.y}) z ${q.z}`);

  const helKedja = nadeHallen && nadeStegen && uppe && paLaktaren
    && langd >= 10 && q.z >= I.L.dackZ - 0.02 && hoppUpp === 0 && q.hopp === 0;
  prova(`${namn}: HELA kedjan i en körning — huvudentrén → stegen → däcket → ${langd.toFixed(1)} m`,
    helKedja,
    ben.join("  ·  ") + `  · teleporthopp ${hoppUpp + q.hopp}` +
    (paLaktaren ? "" : "  ⟵ UTANFÖR läktarens fotavtryck") +
    (nadeHallen ? "" : "  ⟵ kom aldrig ned i hallen") +
    (nadeStegen ? "" : "  ⟵ nådde aldrig stegens bredd"));

  /* 2. Angreppssvep över HELA STEGENS BREDD, med däckets nivåer som
     ankare — inte över stegen relativt sig själva.

     Det här är rättelsen av en svaghet jag själv flaggade i PR #85: svepet
     gick förut från `ls.x0` till `ls.x1`. Krympte man stegen följde svepet
     med, och testet kunde aldrig bli rött — det mätte bara att stegen
     fungerar där stegen finns. Ankaret är nu GÅNGBRÄDAN, som är den enda
     yta stegen kan möta plant (läktarens nivå beror på avståndet in från
     bankanten: gångbräda 0,80, sedan bänkrader 1,10 / 1,40 / 1,70).

     SVÄLT ÄR INTE GEOMETRI. Headless SwiftShader ger ibland så få
     bildrutor att spelaren inte hinner fram innan taket löper ut, och en
     körning som aldrig NÅDDE stegen säger ingenting om stegen. En punkt
     räknas därför som oåtkomlig först när spelaren faktiskt tog sig fram
     till stegets norra kant och ändå stod kvar på z 0. Kom hon inte ens
     dit görs ett försök till; händer det igen rapporteras det som OKLART —
     aldrig omskrivet till vare sig pass eller fail. (Min första mätning i
     #81 var delvis just svält, och det ska inte kunna hända tyst igen.) */
  const bredd = [], missade = [], oklara = [];
  const framme = r => r.y <= I.ls.y1 + 0.25;          // nådde stegets norra kant
  for (let x = I.ls.x0 + 0.15; x <= I.ls.x1 - 0.15; x += 0.2) {
    const px = +x.toFixed(2), etikett = +x.toFixed(2);
    let r = await ga(page, { x: px, y: I.ls.y1 + 1.0, rikt: S, ms: 20000, touch: mobil,
      klar: `p.z >= ${I.L.dackZ - 0.02}` });
    if (r.z < I.L.dackZ - 0.02 && !framme(r)) {
      r = await ga(page, { x: px, y: I.ls.y1 + 1.0, rikt: S, ms: 30000, touch: mobil,
        klar: `p.z >= ${I.L.dackZ - 0.02}` });
    }
    if (r.z >= I.L.dackZ - 0.02) bredd.push(etikett);
    else if (framme(r)) missade.push(etikett);
    else oklara.push(`${etikett} (stannade på y ${r.y}, ${r.n} bildrutor)`);
  }
  const antalProv = bredd.length + missade.length + oklara.length;
  prova(`${namn}: HELA stegens bredd (x ${I.ls.x0.toFixed(1)}–${I.ls.x1.toFixed(1)}) går att gå upp på`,
    missade.length === 0 && oklara.length === 0,
    `${bredd.length} av ${antalProv} angreppspunkter kom upp` +
    (missade.length ? ` — OÅTKOMLIGA: ${JSON.stringify(missade)}` : "") +
    (oklara.length ? ` — OKLART, nådde aldrig stegen (bildrutesvält?): ${oklara.join("; ")}` : ""));

  /* 2b. UPP FÖR BÄNKRADERNA. Att stå på gångbrädan är inte att vara på
     läktaren — man ska kunna gå västerut upp för raderna, 0,30 m i taget.
     Det var här felet satt: stegen slutade förut mot SIDAN av en rad, ett
     hopp på 0,62 m mot nivåregelns 0,36. Kravet är översta radens nivå,
     nådd utan ett enda teleporthopp. */
  {
    const V = Math.PI;                                  // västerut
    const topp = I.toppRad;
    const r = await ga(page, { x: (I.brada.x0 + I.brada.x1) / 2, y: I.ls.y0 - 0.6,
      z: I.L.dackZ, rikt: V, ms: 45000, touch: mobil, klar: `p.z >= ${topp - 0.02}` });
    prova(`${namn}: vidare upp för bänkraderna till översta STÅBARA raden (${topp.toFixed(2)} m)`,
      r.z >= topp - 0.02 && r.hopp === 0,
      `(${r.x}, ${r.y}) z ${r.z} av ${topp.toFixed(2)}, teleporthopp ${r.hopp}`);
  }
  /* 2c. STEGENS TOPP MÅSTE MÖTA DÄCKET PLANT ÖVER HELA SIN BREDD.
     Det här är felet i #81 uttryckt som en invariant i stället för som en
     promenad, och det är den kontroll som inte går att luras av att stegen
     krymper: den läser däckets verkliga nivå strax söder om stegens topp,
     för varje x stegen täcker, och kräver att språnget håller sig under
     nivåregeln. Förut var det 0,62 m mot tillåtna 0,36 väster om
     gångbrädan, eftersom läktarens nivå beror på avståndet in från
     bankanten och stegen hade en enda topphöjd. */
  {
    const brott = await page.evaluate(({ ls }) => {
      const ut = [];
      for (let x = ls.x0 + 0.05; x <= ls.x1 - 0.05; x += 0.1) {
        const under = ridhusNiva(x, ls.y0 - 0.05, ls.z1);
        if (Math.abs(under - ls.z1) > NIVA_STEG + 1e-9)
          ut.push({ x: +x.toFixed(2), topp: ls.z1, dack: +under.toFixed(2), d: +(under - ls.z1).toFixed(2) });
      }
      return ut;
    }, { ls: I.ls });
    prova(`${namn}: stegens topp möter däcket plant över hela bredden (≤ NIVA_STEG)`,
      brott.length === 0,
      brott.length ? `${brott.length} x-lägen bryter nivåregeln, värst ${JSON.stringify(brott[0])}`
                   : `topp ${I.ls.z1.toFixed(2)} m möter däcket inom nivåregeln på hela x ${I.ls.x0.toFixed(1)}–${I.ls.x1.toFixed(1)}`);
  }

  /* MÄTNING, inte pass-krav (#81, öppen fråga till PO/ChatGPT): den som
     kliver in genom huvudentrén (x 1,6) och går RAKT söderut stannar
     fortfarande mot läktartrappan vid H, som når caféplanet (z 3,68) vid
     däckets nordvästra hörn. Det är arkitektur, inte en bugg — men det är
     också precis vad en spelare gör. Redovisas som siffra så att beslutet
     tas av PO, inte tyst av mig. */
  const rakt = await ga(page, { x: I.dorr[0], y: I.dorr[1], rikt: S, ms: 15000, touch: mobil,
    klar: `p.z >= ${I.L.dackZ - 0.02}` });
  console.log(`  mät  ${namn}: rakt söderut från dörren utan att sikta → (${rakt.x}, ${rakt.y}) z ${rakt.z}` +
    `${rakt.z >= I.L.dackZ - 0.02 ? " (kom upp)" : " (stoppas av trappan till caféet — öppen fråga i #81)"}`);
  await page.close();
}
await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
