/* FÖRENKLINGEN — #273 SIMPLIFY i en riktig webbläsare mot dist/.

   Tobias beslut 2026-10-01 (T1–T4). En ny spelare ska bara behöva förstå
   styra, snabbare, långsammare/stanna och interagera/sitta av.

     A. S1 tangentbord: kontrollistan öppnas aldrig av sig själv; kärnan är
        fyra rader med ETT reglage var; S/↓ är ett steg ned per tryck, och
        att släppa tangenten är ingen framåtimpuls,
     B. S1 pek (T3): spak + DRIV + BROMS + SITT AV — inga av de sex
        hjälpknapparna; DRIV och BROMS stegar; spaken styr och ingenting annat,
     C. T4: den som bara styr tappar ingen balans — genom tangenterna,
     D. S3 (T1): efter avsittningen ETT val. «Stallet» — passet klart, ingen
        straffavgift. «Själv» — tre handlingar i kanonens ordning och en
        liten positiv effekt. Passet räknas och sparas FÖRST när valet är
        gjort: den som lämnar vid valet har inte avslutat passet. Clear
        round-raden lovar valet, inte fem moment,
     E. S2 (A3): «Samma häst igen» och «Rid igen — ny häst» leder till
        stegkortet vid boxen, aldrig till den gamla skötseln eller
        ridlärarens tilldelning; en vilande häst delas inte ut,
     F. S2 (T2): den manuella vägen är EN handling per fas — hälsa → kolla
        → rykta → kratsa → sadla → tränsa — med EN kort rad per kort,
        detaljmeningarna i kunskapslagret, samma checklista som 23 klick,
        och ett fynd som stoppar kollen.

   Fler mätningar av samma kedja finns i tools/stegkorttest.mjs, och
   grindarna i tools/forberedelsetest.mjs och tools/valfardstest.mjs.

   Ritten stegas med fast dt inne i sidan — samma väg som tools/ridtest.mjs:
   riktiga tangenthändelser → inputlagret → stegaRitt. Ingenting skrivs i
   ridmodellens tillstånd.

   NOT_TESTED: känslan. Den avgör Tobias i ett riktigt speltest.

   Kör: python3 tools/build.py && node tools/simplifytest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8937;
let fel = 0, antal = 0;
const prova = (namn, ok, detalj = "") => {
  antal++;
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": f.endsWith(".html") ? "text/html" : "application/octet-stream" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

/* Uppsutten den väg en ny spelare kommer dit: First Ride, pass 0. */
async function sittUppNy(vp = { width: 1366, height: 768 }, opt = {}) {
  const ctx = await browser.newContext({ viewport: vp, hasTouch: !!opt.pek, isMobile: false, locale: "sv-SE" });
  await ctx.route(/supabase\.co/, r => r.abort());
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  await page.evaluate(() => {
    overlay(false); window.SPRAKET = "sv";
    SPAR.pass = 0; SPAR_BETRODD = true; startaVandring();
  });
  await page.waitForTimeout(700);
  /* Panelen ritas i spelloopen, och första bildrutan i en ny scen bygger
     3D-världen — med mjukvarurendering i CI tar den över en sekund. En fast
     väntan läste panelen innan den fanns (rött i CI på f3a40bf, grönt
     lokalt). Vänta på villkoret; finns panelen aldrig faller proven nedan. */
  await page.waitForFunction(() => { const el = document.getElementById("ridpanel"); return !!el && !el.hidden; },
    null, { timeout: 20000 }).catch(() => {});
  return page;
}
const vanta = (page, ms = 300) => page.waitForTimeout(ms);

/* Hjälpare som körs INNE i sidan. `kor` stegar ritten med fast dt;
   `tangent` skickar riktiga tangenthändelser runt en hållen tid. */
const SIDHJALP = () => {
  window.__kor = sek => { for (let i = 0; i < Math.round(sek * 60); i++) stegaRitt(1 / 60); };
  window.__tangent = (code, sek) => {
    dispatchEvent(new KeyboardEvent("keydown", { code }));
    __kor(sek);
    dispatchEvent(new KeyboardEvent("keyup", { code }));
  };
  window.__nyRitt = () => {
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; G.npcs = [];
    ridNollstallHjalp();
  };
};

/* ── A. S1 tangentbord ────────────────────────────────────────────── */
console.log("\n── A. S1: tangentbord — listan stängd, fyra kärnrader, ett steg per tryck ──");
{
  const page = await sittUppNy();
  await page.evaluate(SIDHJALP);
  const l = await page.evaluate(() => ({
    scen: G.scen, p3: G.p3, kh: kontrollHjalpSynlig(),
    vidUpp: typeof kontrollHjalpVidUppsittning,
    karna: [...document.querySelectorAll("#ridpanel .rpK > .rpRad")].map(r => r.innerText.replace(/\s+/g, " ").trim()),
    avancerade: kontrollRader("tangentbord").filter(r => r.avancerat).map(r => r.vad),
    karnaAv: kontrollRidrader("tangentbord").filter(r => r.avancerat).length,
    lista: kontrollListrader("tangentbord").map(r => (r.rubrik ? "§" : "") + r.vad),
  }));
  prova("uppsutten i huvudvägen", l.scen === "lektion" && l.p3 === true, `${l.scen}`);
  prova("kontrollistan är INTE öppen vid första uppsittningen", l.kh === false);
  prova("funktionen som öppnade den finns inte längre", l.vidUpp === "undefined", l.vidUpp);
  prova("ridpanelen visar exakt fyra kärnrader", l.karna.length === 4, l.karna.join(" | "));
  prova("ett steg upp [W / ↑], ett steg ned [S / ↓], styr [A / D], sitt upp/av [E] — ETT reglage var",
    /^Ett steg upp i gångarterna \[W \/ ↑\]$/.test(l.karna[0]) && /^Ett steg ned i gångarterna \[S \/ ↓\]$/.test(l.karna[1])
      && /^Styr \[A \/ D\]$/.test(l.karna[2]) && /^Sitt upp \/ sitt av \[E\]$/.test(l.karna[3]), l.karna.join(" | "));
  prova("ingen kärnrad är en avancerad hjälp", l.karnaAv === 0);
  const iR = l.lista.findIndex(t => t.startsWith("§"));
  prova("listan bakom H: kärnan först, sedan «Avancerat» med tygel, halvhalt, sits, lättridning, diagonal, spö",
    iR >= 4 && l.lista[iR] === "§Avancerat" && l.avancerade.length === 6
      && l.lista.slice(iR + 1).join("|") === l.avancerade.join("|")
      && l.lista.slice(0, iR).every(t => !l.avancerade.includes(t)), l.lista.join(" | "));
  await page.keyboard.press("KeyH"); await vanta(page);
  prova("H öppnar listan", await page.evaluate(() => kontrollHjalpSynlig()));
  await page.keyboard.press("KeyH"); await vanta(page);
  prova("H stänger den", !(await page.evaluate(() => kontrollHjalpSynlig())));

  /* ETT STEG PER TRYCK. Riktiga tangenthändelser genom inputlagret. */
  const r = await page.evaluate(() => {
    const ut = { upp: [], ned: [] };
    __nyRitt();
    for (let i = 0; i < 3; i++) { __tangent("KeyW", 0.30); __kor(1.6); ut.upp.push(G.ride.gangart); }
    for (let i = 0; i < 3; i++) { __tangent("KeyS", 0.20); __kor(1.7); ut.ned.push(G.ride.gangart + "/" + G.ride.cue); }
    /* Pilarna är samma två handlingar. */
    __nyRitt(); __tangent("ArrowUp", 0.30); __kor(1.6); ut.pilUpp = G.ride.gangart;
    __tangent("ArrowUp", 0.30); __kor(1.6);
    __tangent("ArrowDown", 0.20); __kor(1.7); ut.pilNed = G.ride.gangart;
    /* EN LÅNG tryckning är fortfarande EN hjälp — och att släppa den är
       ingen framåtimpuls. Förut: trav, S i 0,6 s, släpp → galopp. */
    __nyRitt(); __tangent("KeyW", 0.30); __kor(1.6); __tangent("KeyW", 0.30); __kor(1.6);
    ut.foreLang = G.ride.gangart;
    __tangent("KeyS", 1.5); ut.underLang = G.ride.gangart; __kor(2.5);
    ut.efterLang = G.ride.gangart;
    /* I halt finns inget steg ned — och inget händer. */
    __nyRitt(); __tangent("KeyS", 0.2); __kor(1.5); ut.halt = G.ride.gangart;
    return ut;
  });
  prova("W tre gånger: skritt → trav → galopp, ett steg per tryck", r.upp.join(" → ") === "skritt → trav → galopp", r.upp.join(" → "));
  prova("S tre gånger utan något annat: trav → skritt → halt, ett steg per tryck",
    r.ned.map(x => x.split("/")[0]).join(" → ") === "trav → skritt → halt", r.ned.join(" → "));
  prova("↑ och ↓ är samma två handlingar", r.pilUpp === "skritt" && r.pilNed === "skritt", `${r.pilUpp} · ${r.pilNed}`);
  prova("ett LÅNGT tryck på S är ett steg ned — och släppet driver inte upp igen",
    r.foreLang === "trav" && r.efterLang === "skritt", `${r.foreLang} → ${r.underLang} → ${r.efterLang}`);
  prova("S i halt gör ingenting", r.halt === "halt", r.halt);

  /* ── C. T4: den som bara styr tappar ingen balans ── */
  console.log("\n── C. T4: avancerade hjälper är neutrala i grundridningen ──");
  const b = await page.evaluate(() => {
    const volt = extra => { __nyRitt();
      __tangent("KeyW", 0.30); __kor(1.6); __tangent("KeyW", 0.30); __kor(1.6);
      if (extra) dispatchEvent(new KeyboardEvent("keydown", { code: extra }));
      dispatchEvent(new KeyboardEvent("keydown", { code: "KeyD" }));
      __kor(20);
      const ut = { gang: G.ride.gangart, balans: G.ride.balans, kappa: Math.abs(G.kappa), rak: G.ride.skala.rakriktning,
        stod: G.telemetri && G.telemetri.hjalper ? G.telemetri.hjalper.ytterstod : null };
      dispatchEvent(new KeyboardEvent("keyup", { code: "KeyD" }));
      if (extra) dispatchEvent(new KeyboardEvent("keyup", { code: extra }));
      return ut; };
    /* Samma ritt med kravet PÅSLAGET — det enda som skiljer är om den
       utelämnade yttertygeln får kosta. */
    const bara = volt(null);
    return { krav: SVAR_KANON.HJALP_KRAV, bara };
  });
  prova("kanonens krav på de avancerade hjälperna är 0", b.krav === 0, String(b.krav));
  prova("full volt i trav med BARA styrning: balansen står kvar",
    b.bara.gang === "trav" && b.bara.balans > 0.95, `${b.bara.gang} · balans ${b.bara.balans.toFixed(3)}`);
  prova("…fast yttertygelstödet inte är fullt — det är inte längre ett dolt krav",
    b.bara.stod !== null && b.bara.stod < 0.95, `stöd ${b.bara.stod === null ? "—" : b.bara.stod.toFixed(2)}`);
  /* Rakriktningen (granskning R1) mäts i tools/ridtest.mjs, där volten rids
     med den skänkel som gör att skalans lägre nivåer inte kapar den. */
  await page.context().close();
}

/* ── B. S1 pek (T3) ───────────────────────────────────────────────── */
console.log("\n── B. S1: pek — spak + DRIV + BROMS + SITT AV ──");
{
  const page = await sittUppNy({ width: 844, height: 390 }, { pek: true });
  await page.evaluate(SIDHJALP);
  /* mobil.js byter knappsats var 250 ms — vänta på satsen, inte på klockan. */
  await page.waitForFunction(() => { const r = document.getElementById("pekRitt");
    return !!r && getComputedStyle(r).display !== "none" && r.getBoundingClientRect().height > 0; },
    null, { timeout: 20000 }).catch(() => {});
  await vanta(page, 300);
  const k = await page.evaluate(() => {
    const syns = e => !!e && getComputedStyle(e).display !== "none" && e.getBoundingClientRect().height > 0;
    const ritt = document.getElementById("pekRitt");
    return {
      pek: document.body.classList.contains("pek"), rittSyns: syns(ritt),
      tavlingSyns: syns(document.getElementById("pekTavling")),
      synligaAlla: [...document.querySelectorAll("#pekUI button")].filter(syns).map(b => b.textContent.trim()),
      synliga: [...ritt.querySelectorAll("button")].filter(syns).map(b => b.textContent.trim()),
      alla: [...ritt.querySelectorAll("button")].map(b => b.textContent.trim()),
      hojd: [...ritt.querySelectorAll("#pekDriv,#pekBroms,#pekSittAv")].map(b => Math.round(b.getBoundingClientRect().height)),
      spak: syns(document.getElementById("joy")),
      rader: kontrollRader("touch").map(r => `${r.vad} [${r.reglage}]`),
      lista: kontrollListrader("touch").filter(r => r.rubrik).length,
      karna: kontrollRidrader("touch").map(r => r.reglage),
    };
  });
  prova("pekytan är uppe i sadeln, med spaken", k.pek && k.rittSyns && k.spak);
  prova("synliga knappar: VY, SITT AV, BROMS, DRIV — och inga andra",
    [...k.synliga].sort().join("|") === ["BROMS", "DRIV", "SITT AV", "VY"].join("|"), k.synliga.join(" | "));
  prova("TYGEL, HALVHALT, LÄTT, DJUP, LÄTTR. och DIAG finns inte i ridsatsen alls",
    !k.alla.some(t => /TYGEL|HALVHALT|^LÄTT$|DJUP|LÄTTR|DIAG/.test(t)), k.alla.join(" | "));
  prova("…och ingen av dem syns någonstans på pekytan i huvudvägen (tävlingens sats är släckt)",
    !k.tavlingSyns && !k.synligaAlla.some(t => /TYGEL|HALVHALT|^LÄTT$|DJUP|LÄTTR|DIAG|NÄSTA/.test(t)), k.synligaAlla.join(" | "));
  prova("DRIV, BROMS och SITT AV är fingerstora (≥ 44 px)", k.hojd.length === 3 && k.hojd.every(h => h >= 44), k.hojd.join(", "));
  prova("hjälplistan på pek: inga avancerade rader, ingen rubrik, kärnan DRIV / BROMS / spaken / SITT AV",
    k.lista === 0 && !k.rader.some(t => /Tygel|Halvhalt|Sits|Lättridning|diagonal|Spö/.test(t))
      && k.karna.join("|") === "DRIV|BROMS|Spaken|SITT AV", k.rader.join(" | "));

  const r = await page.evaluate(() => {
    const ner = id => document.getElementById(id).dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerId: 7 }));
    const upp = id => document.getElementById(id).dispatchEvent(new PointerEvent("pointerup", { bubbles: true, pointerId: 7 }));
    const tryck = id => { ner(id); __kor(0.1); upp(id); __kor(1.7); return G.ride.gangart; };
    const ut = {};
    __nyRitt();
    ut.driv = [tryck("pekDriv"), tryck("pekDriv"), tryck("pekDriv")];
    ut.broms = [tryck("pekBroms"), tryck("pekBroms"), tryck("pekBroms")];
    /* SPAKEN STYR, och bara det. Rakt fram och rakt bak ska inte röra
       gångarten; åt sidan ska ge styrning. */
    const joy = document.getElementById("joy"), q = joy.getBoundingClientRect();
    const dra = (dx, dy, sek) => {
      const p = { bubbles: true, pointerId: 9, clientX: q.left + q.width / 2 + dx * q.width / 2, clientY: q.top + q.height / 2 + dy * q.height / 2 };
      joy.dispatchEvent(new PointerEvent("pointerdown", p)); joy.dispatchEvent(new PointerEvent("pointermove", p));
      __kor(sek);
      const l = { skankel: RIDIN.skankel, styr: RIDIN.styr, gang: G.ride.gangart };
      joy.dispatchEvent(new PointerEvent("pointerup", p)); __kor(1.5);
      l.efter = G.ride.gangart; return l;
    };
    __nyRitt(); tryck("pekDriv");
    ut.fram = dra(0, -0.95, 1.5); ut.bak = dra(0, 0.95, 1.5); ut.hoger = dra(0.95, 0, 0.5);
    return ut;
  });
  prova("DRIV tre gånger: skritt → trav → galopp", r.driv.join(" → ") === "skritt → trav → galopp", r.driv.join(" → "));
  prova("BROMS tre gånger: trav → skritt → halt", r.broms.join(" → ") === "trav → skritt → halt", r.broms.join(" → "));
  prova("spaken rakt fram skriver ingen skänkel och byter ingen gångart",
    r.fram.skankel === 0 && r.fram.gang === "skritt" && r.fram.efter === "skritt", JSON.stringify(r.fram));
  prova("spaken rakt bak likaså — och släppet driver inte upp",
    r.bak.skankel === 0 && r.bak.gang === "skritt" && r.bak.efter === "skritt", JSON.stringify(r.bak));
  prova("spaken åt höger styr", r.hoger.styr > 0.5 && r.hoger.gang === "skritt", JSON.stringify(r.hoger));
  await page.context().close();
}

/* ── D + E. Eftervårdens val, och vägen tillbaka till stegkortet ───── */
const overlayLage = page => page.evaluate(() => {
  const ov = document.getElementById("ov");
  return { uppe: !ov.classList.contains("hide"), text: ov.innerText,
    knappar: [...ov.querySelectorAll("button")].map(b => b.textContent.trim()),
    utfall: (document.getElementById("efterUtfall") || {}).textContent || "" };
});
/* Räknar anrop till de två gamla skärmarna utan att ändra dem. */
const bevakaGamla = page => page.evaluate(() => {
  window.__gamla = { skotsel: 0, tilldelning: 0 };
  const s = window.visaSkotsel, t = window.visaTilldelning;
  window.visaSkotsel = function () { __gamla.skotsel++; return s.apply(this, arguments); };
  window.visaTilldelning = function () { __gamla.tilldelning++; return t.apply(this, arguments); };
});
/* Stegkortet ritas i spelloopen; den nya scenens första bildruta kan ta
   över en sekund i CI. Vänta på kortet, inte på klockan. */
const vantaStegkort = page => page.waitForFunction(() => { const el = document.getElementById("stegkort"); return !!el && !el.hidden; },
  null, { timeout: 20000 }).catch(() => {});
const efterKnappen = page => page.evaluate(() => {
  const el = document.getElementById("stegkort");
  return { scen: G.scen, hastId: G.hastId, plats: G.hastPlats, utrustning: G.utrustning,
    overlay: !document.getElementById("ov").classList.contains("hide"),
    kort: el && !el.hidden ? el.dataset.kort : null,
    forbOrord: !!G.forb && Object.keys(G.forb.gjorda).length === 0 && Object.keys(G.forb.klara).length === 0,
    forbHast: G.forb && G.forb.hastId, forbPass: G.forb && G.forb.pass, pass: SPAR.pass,
    efter: G.efter, gamla: window.__gamla, vilar: hastVilarForSkada(G.hastId) };
});

console.log("\n── D. S3: «Stallet tar hand om henne» ──");
{
  const page = await sittUppNy();
  await bevakaGamla(page);
  const fore = await page.evaluate(() => ({ hast: G.hastId, pass: SPAR.pass }));
  await page.keyboard.press("KeyE"); await vanta(page, 500);
  let o = await overlayLage(page);
  const sparat = () => page.evaluate(() => { try { return (JSON.parse(localStorage.getItem("ubrf-ridskolan-v1") || "{}").pass) || 0; } catch (_) { return -1; } });
  prova("avsittningen öppnar valet «Ta hand om henne»", o.uppe && o.text.toLowerCase().includes("vill du ta hand om henne själv, eller ska stallet göra det?"), o.text.slice(0, 80).replace(/\n/g, " ¦ "));
  prova("EXAKT två val: «Stallet tar hand om henne» och «Ta hand om henne själv»",
    o.knappar.length === 2 && o.knappar[0] === "Stallet tar hand om henne" && o.knappar[1] === "Ta hand om henne själv",
    o.knappar.join(" | "));
  prova("inga av de fem eftervårdsmomenten står som obligatoriska steg",
    !/Lossa gjorden|Känn igenom benen|Grimma på först/.test(o.text));
  /* GRANSKNING R1: passet räknas INTE vid avsittningen. Valet avslutar det. */
  const vidValet = await page.evaluate(() => ({ pass: SPAR.pass, passRes: G.passRes, raknat: !!(G.domare && G.domare.raknat) }));
  prova("vid valet är passet ÄNNU INTE räknat — varken i minnet eller i sparfilen",
    vidValet.pass === fore.pass && vidValet.passRes === null && vidValet.raknat === false && (await sparat()) === fore.pass,
    JSON.stringify(vidValet));
  await page.click("#bEfterStallet"); await vanta(page);
  o = await overlayLage(page);
  const efterVal = await page.evaluate(h => ({ pass: SPAR.pass, rang: SPAR.fortroende[h] && SPAR.fortroende[h].rang,
    passRang: G.passRes && G.passRes.rangEfter, bonus: G.efter.bonus, raknat: !!G.domare.raknat }), fore.hast);
  prova("«Stallet» räknar passet — en gång, och det är sparat", efterVal.pass === fore.pass + 1 && efterVal.raknat
    && (await sparat()) === fore.pass + 1, JSON.stringify(efterVal));
  const rang0 = efterVal.passRang, rang1 = efterVal.rang;
  prova("stallet: passet är klart, och det sägs", o.uppe && o.utfall === "Stallet tar hand om henne. Passet är klart."
    && o.text.toLowerCase().includes("passet är klart och sparat"), o.utfall);
  prova("ingen straffavgift och ingen bonus: förtroendet är exakt det passet gav", rang1 === rang0 && efterVal.bonus === 0,
    `${rang0} → ${rang1}`);
  prova("vägen vidare: «Rid igen — ny häst» och «Samma häst igen»",
    o.knappar.includes("Rid igen — ny häst") && o.knappar.includes("Samma häst igen"), o.knappar.join(" | "));
  prova("ett andra anrop räknar inte passet en gång till",
    (await page.evaluate(() => { raknaPass(G.domare); efterKlar(G.domare); return SPAR.pass; })) === fore.pass + 1);

  console.log("\n── E. S2 (A3): «Samma häst igen» leder till stegkortet ──");
  await page.click("#bSamma"); await vanta(page, 700); await vantaStegkort(page);
  const s = await efterKnappen(page);
  prova("ingen overlay: varken den gamla skötseln eller tilldelningen öppnades",
    !s.overlay && s.gamla.skotsel === 0 && s.gamla.tilldelning === 0, JSON.stringify(s.gamla));
  prova("samma häst, i sin box i stallet", s.hastId === fore.hast && s.plats === "box" && s.scen === "stallinne",
    `${s.hastId} · ${s.plats} · ${s.scen}`);
  prova("stegkortet står uppe — samma väg som första gången", ["ga_till", "valj", "fynd"].includes(s.kort), String(s.kort));
  prova("förberedelsen är NY och orörd, för nästa pass", s.forbOrord && s.forbHast === fore.hast && s.forbPass === s.pass + 1,
    `pass ${s.forbPass}`);
  prova("sadeln är INTE redan hämtad — ingenting ärvs från den gamla vägen", s.utrustning === false);
  await page.context().close();
}

console.log("\n── D2. S3: «Ta hand om henne själv» ──");
{
  const page = await sittUppNy();
  await bevakaGamla(page);
  const fore = await page.evaluate(() => ({ hast: G.hastId }));
  /* Ordningen är kanonens, och regeln nekar fel tur. */
  const regel = await page.evaluate(() => {
    const e = Efter.nyState("x");
    const fel = Efter.utforHandling(e, "transa_av");
    return { h: Efter.handlingar().map(x => x.id + ":" + x.moment.map(m => m.id).join("+")),
      fel, orord: Object.keys(e.gjorda).length === 0, bonus: Efter.BONUS };
  });
  prova("tre handlingar bär kanonens fem moment: sadla_av, transa_av, ta_hand",
    regel.h.join(" | ") === "sadla_av:gjord+sadel | transa_av:trans | ta_hand:ben+vatten", regel.h.join(" | "));
  prova("tränset före sadeln nekas med fel tur, och inget blir gjort",
    regel.fel[0] === false && regel.fel[1] === "pass.fel_tur" && regel.orord, JSON.stringify(regel.fel.slice(0, 2)));
  await page.keyboard.press("KeyE"); await vanta(page, 500);
  const passFore = await page.evaluate(() => SPAR.pass);
  await page.click("#bEfterSjalv"); await vanta(page);
  const steg = [];
  for (let i = 0; i < 3; i++) {
    const o = await overlayLage(page);
    steg.push({ knappar: o.knappar, text: o.text, pass: await page.evaluate(() => SPAR.pass) });
    await page.click("#bEfterHandling"); await vanta(page);
  }
  prova("under den egna eftervården är passet ännu inte räknat", steg.every(s => s.pass === passFore), steg.map(s => s.pass).join(","));
  prova("själv: en handling i taget — Ta av sadeln → Ta av tränset → Vatten och hö",
    steg.map(s => s.knappar[0]).join(" → ") === "Ta av sadeln → Ta av tränset → Vatten och hö", steg.map(s => s.knappar[0]).join(" → "));
  prova("och stallet finns kvar som väg ut vid varje steg", steg.every(s => s.knappar[1] === "Stallet tar hand om resten"));
  prova("varje steg bär EN kort rad; detaljmeningarna ligger bakom «Så gör man»",
    steg[0].text.includes("Lossa gjorden och lyft av sadeln.") && steg.every(s => s.text.includes("Så gör man")));
  const o = await overlayLage(page);
  const slut = await page.evaluate(h => ({ pass: SPAR.pass, rang: SPAR.fortroende[h].rang, passRang: G.passRes.rangEfter, bonus: G.efter.bonus }), fore.hast);
  const rang0 = slut.passRang, rang1 = slut.rang;
  prova("när den egna eftervården är klar räknas passet — en gång", slut.pass === passFore + 1, String(slut.pass));
  prova("efter tredje handlingen: passet är klart, och hennes egen omsorg sägs",
    o.utfall === "Du tog hand om henne själv. Det märker hon.", o.utfall);
  prova("liten positiv effekt: förtroendet +0,02 ovanpå det passet gav — inte mer",
    Math.abs((rang1 - rang0) - regel.bonus) < 1e-9 && regel.bonus === 0.02 && Math.abs(slut.bonus - 0.02) < 1e-9,
    `${rang0.toFixed(4)} → ${rang1.toFixed(4)}`);

  console.log("\n── E2. S2 (A3): «Rid igen — ny häst» leder till stegkortet ──");
  await page.click("#bIgen"); await vanta(page, 700); await vantaStegkort(page);
  const s = await efterKnappen(page);
  prova("ingen overlay: varken tilldelningen eller den gamla skötseln öppnades",
    !s.overlay && s.gamla.skotsel === 0 && s.gamla.tilldelning === 0, JSON.stringify(s.gamla));
  prova("en ANNAN häst är utdelad, och hon vilar inte", !!s.hastId && s.hastId !== fore.hast && !s.vilar, `${fore.hast} → ${s.hastId}`);
  prova("hon står i sin box, stegkortet är uppe och förberedelsen är orörd",
    s.plats === "box" && s.scen === "stallinne" && ["ga_till", "valj", "fynd"].includes(s.kort) && s.forbOrord && s.forbHast === s.hastId,
    `${s.plats} · ${s.kort}`);
  await page.context().close();
}

console.log("\n── D3. S3: den som lämnar vid valet har inte avslutat passet ──");
{
  const page = await sittUppNy();
  const fore = await page.evaluate(() => SPAR.pass);
  await page.keyboard.press("KeyE"); await vanta(page, 500);
  const o = await overlayLage(page);
  const lagrat = await page.evaluate(() => { try { return (JSON.parse(localStorage.getItem("ubrf-ridskolan-v1") || "{}").pass) || 0; } catch (_) { return -1; } });
  await page.reload({ waitUntil: "load" }); await vanta(page, 700);
  const efter = await page.evaluate(() => SPAR.pass);
  prova("valet stod uppe, fliken laddades om utan val: passet är INTE räknat",
    o.knappar.length === 2 && lagrat === fore && efter === fore, `före ${fore} · sparfil ${lagrat} · efter omladdning ${efter}`);

  /* Clear round-raden lovar VALET, inte de fem momenten — sv och en. */
  const rad = await page.evaluate(() => {
    const bild = { typ: "clearround", lage: "complete", forsokId: "f1", rittId: "r1", eftervard: EFTERVARD.map(e => ({ id: e.id, namn: e.namn, namnEn: e.namnEn })),
      resultat: { forsokId: "f1", rittId: "r1", ovning: "clearround", bedomning: "forenklad", forsokNr: 1, utfall: "inga_observerade_fel", tid: 31 } };
    const ut = {}; const fore = window.SPRAKET;
    for (const sp of ["sv", "en"]) { window.SPRAKET = sp; ut[sp] = LektionAterkoppling.text(bild, { typ: "clearround", ritt: "r1" }); }
    window.SPRAKET = fore;
    ut.namn = EFTERVARD.flatMap(e => [e.namn, e.namnEn]);
    return ut; });
  prova("clear round-raden säger valet på svenska och engelska",
    String(rad.sv).includes("Sedan väljer du om stallet tar hand om henne eller om du gör det själv.")
      && String(rad.en).includes("Then you choose whether the stable looks after her or you do it yourself."), `${rad.sv} ¦ ${rad.en}`);
  prova("…och räknar inte upp de fem momenten, på något språk",
    !rad.namn.some(n => String(rad.sv).includes(n) || String(rad.en).includes(n))
      && !/väntar|is waiting/.test(String(rad.sv) + String(rad.en)), rad.namn.join(" · "));
  await page.context().close();
}

/* ── F. S2 (T2): en handling per fas ──────────────────────────────── */
console.log("\n── F. S2: en handling per fas genom stegkortet ──");
async function vidBoxen(page, pass) {
  return page.evaluate(pass => {
    overlay(false); window.SPRAKET = "sv";
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    let p = pass;
    if (p === null) { p = 1; while (Forb.fyndFor(id, p + 1)) p++; }
    SPAR.pass = p;
    startaVandring();
    sattAktivHast(id);
    const b = hittaBox(id);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1], rikt: 0 });
    return new Promise(klar => requestAnimationFrame(() => requestAnimationFrame(
      () => klar({ id, namn: HORSES[id].namn }))));
  }, pass);
}
const kortet = page => page.evaluate(() => {
  const el = document.getElementById("stegkort");
  return { id: el.dataset.kort, synlig: !el.hidden, text: el.innerText,
    rubrik: (el.querySelector(".skR") || {}).textContent || "",
    instr: (el.querySelector(".skUi") || {}).textContent || "",
    ater: (el.querySelector(".skA") || {}).textContent || "",
    val: [...el.querySelectorAll(".skV button")].filter(b => !b.closest(".skF")).map(b => ({ id: b.dataset.id, text: b.textContent.trim() })),
    rader: [...el.querySelectorAll(".skRader button")].map(b => b.dataset.id),
    kunskap: [...el.querySelectorAll(".skKun li")].map(li => li.textContent),
    kunskapsknapp: !!el.querySelector("button[data-kunskap]") };
});
const tryckVal = async (page, id) => {
  await page.evaluate(id => { const b = [...document.querySelectorAll("#stegkort .skV button")].find(x => x.dataset.id === id); if (b) b.click(); }, id);
  await vanta(page, 250);
};
const tryckRad = async (page, id) => {
  await page.evaluate(id => { const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true })); }, id);
  await vanta(page, 500);
};
{
  const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 }, locale: "sv-SE" });
  await ctx.route(/supabase\.co/, r => r.abort());
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  await vidBoxen(page, null);
  await vanta(page);
  await tryckVal(page, "start:sjalv");
  const detaljer = await page.evaluate(() => [...HALSNING.map(x => x.text), ...VISITPUNKT.map(x => x.ok),
    ...RYKTREDSKAP.map(x => x.text), ...HOVAR.map(x => x.text), ...SADELFAS.map(x => x.t)]);
  const KEDJA = [
    { kort: "halsa", handling: "halsa", knapp: "Hälsa", rad: "Hon ska se och höra dig innan du rör henne.", moment: 3 },
    { kort: "visitera", handling: "kolla", knapp: "Kolla henne", rad: "Se efter att hon mår bra innan ni börjar.", moment: 5 },
    { kort: "rykta", handling: "rykta", knapp: "Rykta", rad: "Borsta henne ren innan sadeln läggs på.", moment: 6 },
    { kort: "hovar", handling: "kratsa", knapp: "Kratsa hovarna", rad: "Lyft och rensa alla fyra hovarna.", moment: 4 },
    { kort: "sadla", handling: "sadla", knapp: "Sadla", rad: "Underlägg och sadel på, sedan gjorden.", moment: 4, hamta: "tack:sadel" },
    { kort: "transa", handling: "transa", knapp: "Tränsa", rad: "Tränset kommer sist.", moment: 1, hamta: "tack:trans" },
  ];
  let klick = 0, hamtningar = 0, allaEn = true, allaKorta = true, allaKunskap = true, ingenDetalj = true;
  const sedda = [];
  for (const st of KEDJA) {
    let k = await kortet(page);
    if (st.hamta && k.id !== st.kort) {
      /* Hämtningen är en handling i världen: ingen momentknapp, bara prompten. */
      if (k.val.length !== 0 || !k.rader.includes(st.hamta)) allaEn = false;
      sedda.push(k.id);
      await tryckRad(page, st.hamta); hamtningar++;
      k = await kortet(page);
    }
    sedda.push(k.id);
    if (!(k.id === st.kort && k.val.length === 1 && k.val[0].id === "handling:" + st.handling && k.val[0].text === st.knapp)) allaEn = false;
    if (k.instr !== st.rad) allaKorta = false;
    if (detaljer.some(d => k.text.includes(d))) ingenDetalj = false;
    await page.evaluate(() => document.querySelector("#stegkort button[data-kunskap]").click());
    await vanta(page, 200);
    const oppen = await kortet(page);
    if (!(oppen.kunskap.length === st.moment)) allaKunskap = false;
    await tryckVal(page, "handling:" + st.handling); klick++;
  }
  const slut = await kortet(page);
  const lista = await page.evaluate(() => {
    const ut = { egna: 0, totalt: 0 };
    for (const f of Forb.stegFaser()) { if (f.id === "leda") continue;
      for (const m of Forb.moment(f.id)) { if (m.fel) continue; ut.totalt++;
        if ((G.forb.gjorda[f.id] || {})[m.id] === true) ut.egna++; } }
    return ut; });
  prova("varje kort i kedjan har EN handling, med rätt knapp", allaEn, sedda.join(" → "));
  prova("korten kommer i ordning: hälsa → kolla → rykta → kratsa → hämta sadeln → sadla → hämta tränset → tränsa",
    sedda.join(" → ") === "halsa → visitera → rykta → hovar → hamta_sadel → sadla → hamta_trans → transa", sedda.join(" → "));
  prova("varje kort bär EN kort rad", allaKorta);
  prova("inget kort i huvudflödet bär en detaljmening om hovar, mungipor eller gjord", ingenDetalj && detaljer.length === 20,
    `${detaljer.length} detaljmeningar i kanonen`);
  prova("«Så gör man» visar handlingens alla moment — 3, 5, 6, 4, 4 och 1", allaKunskap);
  prova("sex handlingar och två hämtningar räcker till ledningen", klick === 6 && hamtningar === 2 && slut.id === "leda",
    `${klick} + ${hamtningar} → ${slut.id}`);
  prova("checklistan är densamma som 23 klick gav: 23 moment, alla spelarens egna", lista.totalt === 23 && lista.egna === 23,
    JSON.stringify(lista));
  await page.context().close();

  /* FYNDET stoppar kollen — välfärden är inte förenklad. */
  const ctx2 = await browser.newContext({ viewport: { width: 1600, height: 900 }, locale: "sv-SE" });
  await ctx2.route(/supabase\.co/, r => r.abort());
  const p2 = await ctx2.newPage();
  p2.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await p2.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await p2.waitForTimeout(700);
  const fyndPass = await p2.evaluate(() => {
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    for (let p = 2; p < 40; p++) if (Forb.fyndFor(id, p)) return p - 1;
    return -1; });
  await vidBoxen(p2, fyndPass);
  await vanta(p2);
  await tryckVal(p2, "start:sjalv");
  await tryckVal(p2, "handling:halsa");
  await tryckVal(p2, "handling:kolla");
  let f = await kortet(p2);
  const st = await p2.evaluate(() => ({ sett: G.forb.fyndSett, rapp: G.forb.fyndRapporterat, klar: !!G.forb.klara.visitera,
    efter: (() => { const ps = VISITPUNKT.map(p => "vis:" + p.id), i = ps.indexOf("vis:" + G.forb.fynd);
      return ps.slice(i + 1).filter(id => (G.forb.gjorda.visitera || {})[id]).length; })(),
    fore: (() => { const ps = VISITPUNKT.map(p => "vis:" + p.id), i = ps.indexOf("vis:" + G.forb.fynd);
      return ps.slice(0, i + 1).filter(id => (G.forb.gjorda.visitera || {})[id]).length === i + 1; })(),
    nasta: Forb.utforHandling(G.forb, "rykta", G.hastId) }));
  prova("«Kolla» med ett fynd: kortet blir «Du hittade något» med tre svar", fyndPass > 0 && f.id === "fynd" && f.val.length === 3,
    `${f.id} · ${f.val.map(v => v.text).join(" / ")}`);
  /* Fyndets eget kort talar. Handlingen GICK IGENOM fram till fyndet: det
     ska varken stå en kvittens («Allt ser bra ut») eller ett nej där. */
  prova("kollen gick fram TILL fyndet och stannade där — ingen kvittens och inget nej",
    st.sett && !st.rapp && !st.klar && st.fore && st.efter === 0 && f.ater === "",
    JSON.stringify({ fore: st.fore, efter: st.efter, ater: f.ater }));
  prova("ett öppet fynd blockerar nästa handling", st.nasta[0] === false && st.nasta[1] === "forb.oppet_fynd", JSON.stringify(st.nasta));
  await tryckVal(p2, "svar:3");
  f = await kortet(p2);
  prova("fel svar nekas: inte ditt beslut, frågan står kvar", f.id === "fynd" && f.ater.startsWith("Det är inte ditt beslut"), f.ater);
  await tryckVal(p2, "svar:1");
  f = await kortet(p2);
  const ridas = await p2.evaluate(() => Forb.provaUppsittning(G.forb, G.hastId));
  prova("rätt svar: ridläraren tar över, och hästen rids inte", f.id === "stopp" && ridas[0] === false && ridas[1] === "forb.lararen_tar_over",
    `${f.id} · ${ridas[1]}`);
  await p2.context().close();
}

await browser.close();
srv.close();
console.log("");
if (fel > 0) { console.log(`${fel} FEL av ${antal} mätningar`); process.exit(1); }
console.log(`simplifytest: ${antal} mätningar, alla gröna`);
