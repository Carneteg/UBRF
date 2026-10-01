/* RIDPANELEN — P3 § 2, § 3, § 4, § 5 i en riktig webbläsare mot dist/.

   Provet sitter upp den väg en spelare gör (First Ride, pass 0) och läser
   sedan bara det som står på skärmen och det panelens egna knappar gör.

     A. hierarkin: Ugnetas ruta överst (titel, Text, flagga, ETT
        meddelande) → rubrik med `?` → fyra kärnrader → högst fyra val;
        den gamla fyrahörns-HUD:en är borta ur huvudvägen,
     B. första uppsittningen öppnar reglagelistan en gång per session;
        H stänger och öppnar den,
     C. `?` fäller ut hela listan och de fyra hjälpmätarna,
     D. menyn: varje sida, varje etikett och Tillbaka — mot Roblox-porten
        (Lektionsmeny.panel) och mot kortknappens kompakta ingång,
     E. Text: Inga tystar starthälsningen men aldrig uppgiften; Kort ger
        slutets korta text,
     F. tangenterna: E sitter av, F är halvhalt, G spö — i sadeln; till
        fots är E fortfarande «använd»,
     G. fri träning: kortet besvaras av en hjälp, inte av en tygel,
     H. layout: 1366×768, iPad liggande 1180×820 och pek — panelen ryms och
        ligger aldrig under spaken.

   Kör: python3 tools/build.py && node tools/ridpaneltest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8911;
let fel = 0;
const prova = (namn, ok, detalj = "") => {
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

async function sittUppNy(vp = { width: 1366, height: 768 }, opt = {}) {
  const ctx = await browser.newContext({ viewport: vp, hasTouch: !!opt.pek, isMobile: false });
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  await page.evaluate(sprak => {
    overlay(false); window.SPRAKET = sprak || "sv";
    SPAR.pass = 0; SPAR_BETRODD = true; startaVandring();
  }, opt.sprak);
  await page.waitForTimeout(700);
  return page;
}
const vanta = (page, ms = 250) => page.waitForTimeout(ms);
const panel = page => page.evaluate(() => {
  const el = document.getElementById("ridpanel");
  const block = el ? [...el.children].map(c => c.className.split(" ")[0]) : [];
  return {
    synlig: !!el && !el.hidden, block,
    titel: (el.querySelector(".skUt") || {}).textContent || "",
    medd: (el.querySelector(".skUi") || {}).textContent || "",
    rubrik: (el.querySelector(".rpHt") || {}).textContent || "",
    karna: [...el.querySelectorAll(".rpK > .rpRad")].map(r => r.innerText.replace(/\s+/g, " ").trim()),
    alla: [...el.querySelectorAll(".rpAlla .rpRad")].length,
    matare: [...el.querySelectorAll(".rpAlla .rpM")].length,
    knappar: [...el.querySelectorAll(".skV button")].map(b => b.textContent),
    text: !!el.querySelector("button[data-text]"), flagga: !!el.querySelector("button[data-sprak] .skFl"),
    fraga: !!el.querySelector("button[data-hjalp]"),
    hud: ["pyr", "aids", "gait", "moment"].map(id => getComputedStyle(document.getElementById(id).closest(".hudh")).display),
    rect: el.getBoundingClientRect().toJSON(), vp: { w: innerWidth, h: innerHeight },
  };
});
const klick = (page, borjar) => page.evaluate(t => {
  const b = [...document.querySelectorAll("#ridpanel .skV button")].find(x => x.textContent.startsWith(t));
  if (b) b.click();
  return !!b;
}, borjar);

/* ── A + B: hierarkin och första uppsittningen ───────────────────── */
{
  console.log("A · B  hierarkin och reglagen vid första uppsittningen");
  const page = await sittUppNy();
  const p = await panel(page);
  const scen = await page.evaluate(() => ({ scen: G.scen, p3: G.p3, kh: kontrollHjalpSynlig(),
    karnaKalla: kontrollRidrader().map(r => `${r.vad} [${r.reglage}]`), namn: HORSES[G.hastId].namn }));
  prova("uppsutten i huvudvägen (P3)", scen.scen === "lektion" && scen.p3 === true, JSON.stringify(scen).slice(0, 80));
  prova("ridpanelen syns", p.synlig);
  prova("blockordningen är Naromrades: Ugneta → rubrik → kärna → val",
    JSON.stringify(p.block.slice(0, 4)) === JSON.stringify(["skU", "rpH", "rpK", "skV"]), p.block.join(" → "));
  prova("Ugnetas ruta: titeln, Text och flaggan", p.titel === "Ugneta · Ridinstruktör" && p.text && p.flagga, p.titel);
  prova("ETT meddelande i Ugnetas ruta", !!p.medd, p.medd);
  prova("rubriken bär hästens namn och gångarten, med `?`", p.rubrik.startsWith(scen.namn + "  ·  ") && p.fraga, p.rubrik);
  prova("fyra kärnrader ur KontrollHjalp, i Roblox ordning", p.karna.length === 4
    && p.karna.every((r, i) => r === scen.karnaKalla[i].replace(/\s+/g, " ")), p.karna.join(" | "));
  prova("kärnraderna: driv, bromsa, styr, sitt av", /W \/ ↑/.test(p.karna[0]) && /S \/ ↓/.test(p.karna[1])
    && /A \/ D/.test(p.karna[2]) && /\[E\]/.test(p.karna[3]), p.karna.join(" | "));
  prova("högst fyra val", p.knappar.length >= 1 && p.knappar.length <= 4, p.knappar.join(" | "));
  prova("fyrahörns-HUD:en är borta ur huvudvägen", p.hud.every(d => d === "none"), p.hud.join(","));
  /* #273 S1: listan öppnas ALDRIG av sig själv. H är vägen in. */
  prova("reglagelistan öppnas INTE av sig själv vid första uppsittningen", scen.kh === false);
  await page.keyboard.press("KeyH"); await vanta(page);
  prova("H öppnar reglagelistan", await page.evaluate(() => kontrollHjalpSynlig()));
  {
    const l = await page.evaluate(() => [...document.querySelectorAll("#kontrollhjalp .khRad")].map(r =>
      ({ t: r.textContent.replace(/\s+/g, " ").trim(), av: r.classList.contains("khAvancerat") })));
    const iAv = l.findIndex(r => r.av);
    prova("listan: kärnan först, hjälperna under «Avancerat»", iAv >= 4
      && /W \/ ↑/.test(l[0].t) && /S \/ ↓/.test(l[1].t) && /A \/ D/.test(l[2].t) && /E$/.test(l[3].t)
      && l.slice(0, iAv).every(r => !/Tygel|Halvhalt|Sits|Lättridning|diagonal|Spö/.test(r.t))
      && ["Tygel", "Halvhalt", "Sits", "Lättridning", "diagonal", "Spö"].every(o => l.slice(iAv + 1).some(r => r.t.includes(o))),
      l.map(r => (r.av ? "§" : "") + r.t).join(" | "));
  }
  await page.keyboard.press("KeyH"); await vanta(page);
  prova("H stänger den igen", !(await page.evaluate(() => kontrollHjalpSynlig())));
  /* En andra uppsittning i samma session öppnar den inte heller. */
  await page.keyboard.press("KeyE"); await vanta(page, 500);
  const andra = await page.evaluate(() => { overlay(false); SPAR.pass = 0; startaVandring(); return true; });
  await vanta(page, 700);
  prova("andra uppsittningen i sessionen öppnar inte listan igen", andra
    && !(await page.evaluate(() => kontrollHjalpSynlig())) && await page.evaluate(() => G.scen === "lektion"));

  /* ── C: `?` ─────────────────────────────────────────────────────── */
  console.log("C  `?`");
  await page.click("#ridpanel button[data-hjalp]"); await vanta(page);
  const q = await panel(page);
  prova("`?` fäller ut hela listan", q.alla >= 6, `${q.alla} rader`);
  prova("…och de fyra hjälpmätarna (webbens inmatning ÄR hjälperna)", q.matare === 4, `${q.matare}`);
  await page.click("#ridpanel button[data-hjalp]"); await vanta(page);
  prova("`?` igen fäller in", (await panel(page)).alla === 0);

  /* ── G: fri träning — kortet besvaras av en hjälp ─────────────────── */
  console.log("G  fri träning");
  const fore = await page.evaluate(() => FriPass.lage());
  await page.keyboard.down("Space"); await vanta(page, 400); await page.keyboard.up("Space"); await vanta(page, 300);
  const efterTygel = await page.evaluate(() => FriPass.lage());
  prova("presentationskortet står uppe vid uppsittningen", fore === "presentation", fore);
  prova("en tygel är inget svar — kortet står kvar", efterTygel === "presentation", efterTygel);
  const k0 = await panel(page);
  prova("kortets knapp säger rundans längd", k0.knappar[0] === "Börja fri träning – rundor på 22 s", k0.knappar[0]);
  prova("kortknapp + kompakt «Välj övning» när allt inte ryms", k0.knappar.includes("Välj övning") && k0.knappar.length === 2,
    k0.knappar.join(" | "));
  await page.keyboard.down("KeyW"); await vanta(page, 350); await page.keyboard.up("KeyW"); await vanta(page, 600);
  const efterDriv = await page.evaluate(() => ({ lage: FriPass.lage(), gang: G.ride.gangart, bedd: G.ride.beddGangart }));
  prova("en hjälp (W) besvarar kortet OCH verkar — rundan börjar och hästen går", efterDriv.lage === "rider"
    && efterDriv.bedd === "skritt", JSON.stringify(efterDriv));

  /* ── D: menyn ──────────────────────────────────────────────────── */
  console.log("D  menyn");
  const topp = await panel(page);
  prova("toppnivån: volt, gångarter, ridvägar, förslag", topp.knappar.length === 4 && topp.knappar[0] === "Träna volt"
    && topp.knappar[1].startsWith("Gångarter och fart") && topp.knappar[2].startsWith("Ridvägar")
    && topp.knappar[3].startsWith("Förslag:"), topp.knappar.join(" | "));
  const sidor = [
    ["Gångarter och fart", ["Träna start och halt", "Rid i jämn fart", "Övergångar", "Tillbaka"]],
    ["Övergångar", ["Träna övergångar", "Galoppfattning", "Tillbaka"]],
  ];
  const lika = (vis, vantat) => vis.length === vantat.length && vis.every((t, i) => t.startsWith(vantat[i]));
  for (const [grupp, vantat] of sidor) {
    prova(`klick: ${grupp}`, await klick(page, grupp)); await vanta(page, 120);
    const s = await panel(page);
    prova(`sidan ${grupp}`, lika(s.knappar, vantat), s.knappar.join(" | "));
    prova(`sidan ${grupp}: texten «Välj en övning.»`, s.medd.startsWith("Välj en övning."), s.medd);
  }
  await klick(page, "Tillbaka"); await vanta(page, 120);
  prova("Tillbaka från Övergångar leder till Gångarter", (await panel(page)).knappar[0].startsWith("Träna start och halt"));
  await klick(page, "Tillbaka"); await vanta(page, 120);
  prova("Tillbaka från Gångarter leder till toppnivån", (await panel(page)).knappar[0] === "Träna volt");
  await klick(page, "Ridvägar"); await vanta(page, 120);
  const v = await panel(page);
  prova("Ridvägar: böjda, raka, clear round, Tillbaka", lika(v.knappar, ["Böjda vägar", "Raka linjer och markbom", "Clear round", "Tillbaka"]),
    v.knappar.join(" | "));
  await klick(page, "Böjda vägar"); await vanta(page, 120);
  prova("Böjda vägar: serpentin, halvvolt, hörnet, Tillbaka",
    lika((await panel(page)).knappar, ["Rid en serpentin", "Halvvolt", "Genom hörnet", "Tillbaka"]), (await panel(page)).knappar.join(" | "));
  await klick(page, "Tillbaka"); await vanta(page, 120);
  await klick(page, "Raka linjer"); await vanta(page, 120);
  prova("Raka linjer: mittlinjen, diagonalen, bom på marken, Tillbaka",
    lika((await panel(page)).knappar, ["Mittlinjen", "Diagonalen", "Bom på marken", "Tillbaka"]), (await panel(page)).knappar.join(" | "));
  const port = await page.evaluate(() => Lektionsmeny.panel().knappar.map(k => k.text));
  prova("DOM:en visar exakt Roblox-portens knappar", JSON.stringify(port) === JSON.stringify((await panel(page)).knappar));
  await klick(page, "Tillbaka"); await vanta(page, 120); await klick(page, "Tillbaka"); await vanta(page, 120);

  /* ── E: Text ───────────────────────────────────────────────────── */
  console.log("E  Text");
  await page.click("#ridpanel button[data-text]"); await vanta(page);
  const inst = await page.evaluate(() => [...document.querySelectorAll("#ridpanel .rpInstG button")].map(b => b.textContent));
  prova("Text öppnar inställningarna i Ugnetas ruta", JSON.stringify(inst) === JSON.stringify(["Normalt", "Färre", "Inga", "Detaljerad", "Kort"]), inst.join(","));
  await page.click('#ridpanel button[data-inst="kommentarer:inga"]'); await vanta(page);
  await page.click('#ridpanel button[data-inst="detalj:kort"]'); await vanta(page);
  prova("valen sätts", await page.evaluate(() => LararInstallning.kommentarer() === "inga" && LararInstallning.detalj() === "kort"));
  await page.click("#ridpanel button[data-instklar]"); await vanta(page);
  await klick(page, "Gångarter"); await vanta(page, 120); await klick(page, "Träna start och halt"); await vanta(page, 150);
  await klick(page, "Starta övningen"); await vanta(page, 400);
  const utanHalsning = await panel(page);
  prova("Inga: ingen starthälsning — men uppgiften och framstegen står", !/Nu övar vi/.test(utanHalsning.medd)
    && /Stå helt still|halt/i.test(utanHalsning.medd) && /\d+%$/.test(utanHalsning.medd), utanHalsning.medd);
  const kort = await page.evaluate(() => {
    const s = Lektionsmeny._S.lektioner.halt;
    const b = { ...LektionMotor.bild(s), lage: "complete", resultat: { forsokId: s.forsokId, rittId: s.rittId, mal: "X", skrittMeter: 4.2, haltSekunder: 2 } };
    b.forsokId = s.forsokId;
    return LektionAterkoppling.text(b, { typ: "halt", ritt: s.rittId });
  });
  prova("Kort: slutets korta text (aterkoppling.halt.kort + nästa)", kort && kort.startsWith(await page.evaluate(() => tSpr("aterkoppling.halt.kort"))), kort);
  await page.evaluate(() => { LararInstallning.satKommentarer("normal"); LararInstallning.satDetalj("detaljerad"); });
  await klick(page, "Avsluta"); await vanta(page, 150);
  await klick(page, "Träna start och halt").catch(() => {});
  const efterAvsluta = await panel(page);
  prova("Avsluta ger toppnivån med «Fri träning med återspelning»", efterAvsluta.knappar.some(t => t.startsWith("Fri träning")),
    efterAvsluta.knappar.join(" | "));

  /* ── F: tangenterna ────────────────────────────────────────────── */
  console.log("F  tangenterna");
  await page.keyboard.down("KeyF"); await vanta(page, 60);
  const f = await page.evaluate(() => ({ parad: RIDIN.parad, spo: IN.spo }));
  await page.keyboard.up("KeyF");
  await page.keyboard.down("KeyG"); await vanta(page, 60);
  const g = await page.evaluate(() => ({ parad: RIDIN.parad, spo: IN.spo }));
  await page.keyboard.up("KeyG");
  prova("F är halvhalten i sadeln", f.parad === 1 && f.spo === false, JSON.stringify(f));
  prova("G är spöt", g.spo === true && g.parad === 0, JSON.stringify(g));
  await page.keyboard.press("KeyE"); await vanta(page, 500);
  const e = await page.evaluate(() => ({ scen: G.scen, p3: G.p3, ov: overlayUppe() }));
  prova("E sitter av — ritten lämnas till vägen efter ritten", e.scen === "resultat" && e.p3 === false && e.ov, JSON.stringify(e));
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  await vanta(page, 500);
  await page.keyboard.down("KeyF"); await vanta(page, 60);
  const fot = await page.evaluate(() => ({ scen: G.scen, parad: RIDIN.parad }));
  await page.keyboard.up("KeyF");
  prova("till fots är F ingen halvhalt", fot.scen !== "lektion" && fot.parad === 0, JSON.stringify(fot));
  await page.context().close();
}

/* ── H: layouten ───────────────────────────────────────────────────── */
{
  console.log("H  layout");
  for (const [namn, vp, pek] of [["1366×768", { width: 1366, height: 768 }, false],
    ["iPad liggande 1180×820", { width: 1180, height: 820 }, false], ["pek 1180×820", { width: 1180, height: 820 }, true]]) {
    const page = await sittUppNy(vp, { pek });
    await page.evaluate(() => doljKontrollHjalp());
    await page.click("#ridpanel button[data-hjalp]"); await vanta(page);
    const p = await panel(page);
    const inne = p.rect.left >= 0 && p.rect.top >= 0 && p.rect.right <= p.vp.w && p.rect.bottom <= p.vp.h;
    prova(`${namn}: panelen ryms, även utfälld`, p.synlig && inne, JSON.stringify(p.rect));
    prova(`${namn}: högst 34 % av bredden`, p.rect.width <= Math.max(300, 0.34 * p.vp.w) + 1, `${p.rect.width.toFixed(0)} px`);
    if (pek) {
      const joy = await page.evaluate(() => { const j = document.getElementById("joy"); return j ? j.getBoundingClientRect().toJSON() : null; });
      const over = joy && !(p.rect.bottom <= joy.top || p.rect.left >= joy.right);
      prova(`${namn}: aldrig under spaken`, !!joy && !over, JSON.stringify({ panel: p.rect.bottom, spak: joy && joy.top }));
      const sittAv = await page.evaluate(() => { const b = document.getElementById("pekSittAv"); return b && getComputedStyle(b).display !== "none" ? b.textContent : null; });
      prova(`${namn}: pekknappen SITT AV finns i sadeln`, sittAv === "SITT AV", String(sittAv));
    }
    await page.context().close();
  }
}

/* ── Engelska: panelen på spelarens språk ─────────────────────────── */
{
  console.log("engelska");
  const page = await sittUppNy({ width: 1366, height: 768 }, { sprak: "en" });
  const p = await panel(page);
  prova("titeln på engelska", p.titel === "Ugneta · Riding instructor", p.titel);
  prova("kärnraderna på engelska", /One step up/.test(p.karna[0]) && /One step down/.test(p.karna[1]) && !/Space/.test(p.karna[1])
    && /Mount \/ dismount/.test(p.karna[3]),
    p.karna.join(" | "));
  await page.click("#ridpanel button[data-sprak]"); await vanta(page);
  prova("flaggan byter till svenska på plats", (await panel(page)).titel === "Ugneta · Ridinstruktör");
  await page.context().close();
}

await browser.close(); srv.close();
console.log(fel ? `RIDPANELEN: ${fel} FEL` : "RIDPANELEN: alla gröna");
process.exit(fel ? 1 : 0);
