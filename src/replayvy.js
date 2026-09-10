/* REPLAYVYN — spelaren ser sin egen ritt igen.

   G02-D (#137): "Replay must support play/pause, speed reduction,
   scrubbing, camera choice where supported, ghost visibility and a
   return to the next attempt. A reduced-motion-friendly alternative and
   readable route/metric comparison must be available."

   Vyn LÄSER en inspelning. Den rör aldrig G.ride, G.px, progression
   eller något annat levande — uppspelningen är read-only, och det är
   provat i tools/replaytest.mjs.

   FRIVILLIG. Den öppnas bara när spelaren väljer det. Specen är tydlig
   med att ritten inte får avbrytas av en automatisk replay, och att
   spelaren ska få ett uttryckligt val: Fortsätt · Prova igen · Se ritten.

   REDUCED MOTION: rörelsen är inte enda vägen till innehållet. Samma
   uppgifter finns som text bredvid banan, och när användaren har bett om
   mindre rörelse startar uppspelningen inte av sig själv.

   Ritar med canvas 2D. Ingen ny renderare, ingen WebGL-kontext till,
   ingenting som konkurrerar med spelets egen loop. */

const REPLAY = {
  up: null,          // Uppspelning
  analys: null,      // analysVolt-resultat
  jamfor: null,      // jamforRitter mot föregående försök
  overgang: null,    // analysOvergang när övningen är en övergång
  canvas: null,
  ctx: null,
  raf: 0,
  sist: 0,
  ovningId: null,
};

function replayMindreRorelse(){
  return typeof matchMedia === "function"
    && matchMedia("(prefers-reduced-motion: reduce)").matches;
}

/* Banans utsträckning i postens koordinater, med marginal. Räknas ur
   PUNKTERNA — inte ur en antagen bana. En ritt som gick utanför den
   tänkta volten ska synas som det, inte klippas bort. */
function replayRam(post, ghost){
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
  const in_ = p => {
    if (p.x === null || p.y === null) return;
    x0 = Math.min(x0, p.x); x1 = Math.max(x1, p.x);
    y0 = Math.min(y0, p.y); y1 = Math.max(y1, p.y);
  };
  for (const p of (post && post.sampel) || []) in_(p);
  for (const p of (ghost && ghost.sampel) || []) in_(p);
  if (!Number.isFinite(x0)) return null;
  const mx = Math.max(1, (x1 - x0) * 0.12), my = Math.max(1, (y1 - y0) * 0.12);
  return { x0: x0 - mx, x1: x1 + mx, y0: y0 - my, y1: y1 + my };
}

function replayRita(){
  const c = REPLAY.canvas, ctx = REPLAY.ctx, up = REPLAY.up;
  if (!c || !ctx || !up || !up.post) return;
  const post = up.post, ghost = REPLAY.ghost;
  const ram = replayRam(post, ghost);
  const W = c.width, H = c.height;
  ctx.clearRect(0, 0, W, H);
  if (!ram) return;

  /* Samma skala i x och y — en volt får inte se ut som en ellips för att
     rutan är bredare än den är hög. */
  const s = Math.min(W / (ram.x1 - ram.x0), H / (ram.y1 - ram.y0));
  const ox = (W - (ram.x1 - ram.x0) * s) / 2, oy = (H - (ram.y1 - ram.y0) * s) / 2;
  const px = p => ox + (p.x - ram.x0) * s;
  const py = p => H - (oy + (p.y - ram.y0) * s);   // y uppåt i banan, nedåt i canvas

  const drag = (sampel, farg, bredd, streck) => {
    ctx.save();
    ctx.strokeStyle = farg; ctx.lineWidth = bredd; ctx.lineJoin = "round"; ctx.lineCap = "round";
    if (streck) ctx.setLineDash(streck);
    ctx.beginPath();
    let uppe = false;
    for (const p of sampel) {
      if (p.x === null || p.y === null) { uppe = false; continue; }   // hål bryter linjen
      if (!uppe) { ctx.moveTo(px(p), py(p)); uppe = true; }
      else ctx.lineTo(px(p), py(p));
    }
    ctx.stroke(); ctx.restore();
  };

  /* Referens/tidigare försök först, under spelarens egen väg. */
  if (ghost && REPLAY.ghostSyns) drag(ghost.sampel, "rgba(214,174,60,.55)", 2, [6, 5]);
  drag(post.sampel, "#7FB489", 3, null);

  /* Var är hästen just nu? */
  const nu = up.vid(up.lage);
  if (nu && nu.x !== null && nu.y !== null) {
    ctx.save();
    ctx.fillStyle = "#FFF9EC"; ctx.strokeStyle = "#33413B"; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(px(nu), py(nu), 5, 0, Math.PI * 2);
    ctx.fill(); ctx.stroke();
    ctx.restore();
  }
}

function replaySteg(nu){
  const dt = REPLAY.sist ? (nu - REPLAY.sist) / 1000 : 0;
  REPLAY.sist = nu;
  if (REPLAY.up && REPLAY.up.spelar) {
    REPLAY.up.steg(dt);
    replaySynk();
  }
  replayRita();
  REPLAY.raf = requestAnimationFrame(replaySteg);
}

/* Håller reglaget och tidstexten i takt med uppspelningen. */
function replaySynk(){
  const up = REPLAY.up; if (!up) return;
  const skjut = document.getElementById("replaySkjut");
  const tid = document.getElementById("replayTid");
  const spela = document.getElementById("replaySpela");
  if (skjut && document.activeElement !== skjut)
    skjut.value = String(up.langd() > 0 ? (up.lage / up.langd()) * 1000 : 0);
  if (tid) tid.textContent = `${up.lage.toFixed(1)} / ${up.langd().toFixed(1)} s`;
  if (spela) spela.textContent = up.spelar ? "Pausa" : "Spela";
}

/* Den läsbara jämförelsen — reduced-motion-alternativet. Siffror, inte
   rörelse, och samma uppgifter som banan visar. */
/* Är det här en övergångsövning? Då mäts TIDEN och gångartsbytet, inte
   en cirkel. Utan den frågan skrev vyn "Din volt blev 14,2 m i radie"
   om en trav–skritt-övergång — en anpassad cirkel genom en nästan rak
   väg är ett tal, men det är inte ett SVAR på vad spelaren red. */
function replayArOvergang(post){
  if (!post || typeof ovningsDef !== "function") return false;
  const d = ovningsDef(post.ovning);
  return !!(d && d.gangart);
}

function replayOvergangHTML(){
  const o = REPLAY.overgang;
  if (!o || !o.ok)
    return `<p style="font-size:14px">Ingen gångartsändring finns i den här inspelningen${
      o && o.skal ? ` — ${o.skal}` : ""}.</p>`;
  const f = o.forsta;
  const rader = [
    `<tr><td>Övergång</td><td class="num">${f.fran} → ${f.till}</td></tr>`,
    `<tr><td>Skedde efter</td><td class="num">${f.t.toFixed(1).replace(".", ",")} s</td></tr>`,
  ];
  if (f.fartFore !== null && f.fartEfter !== null)
    rader.push(`<tr><td>Fart före → efter</td><td class="num">${
      f.fartFore.toFixed(2).replace(".", ",")} → ${f.fartEfter.toFixed(2).replace(".", ",")} m/s</td></tr>`);
  if (o.antal > 1)
    rader.push(`<tr><td>Gångartsbyten totalt</td><td class="num">${o.antal}</td></tr>`);
  return `<table><tbody>${rader.join("")}</tbody></table>`;
}

function replayTextHTML(){
  if (REPLAY.up && replayArOvergang(REPLAY.up.post)) return replayOvergangHTML();
  const a = REPLAY.analys, j = REPLAY.jamfor;
  const rader = [];
  if (a && a.ok) {
    rader.push(`<tr><td>Voltens radie</td><td class="num">${a.radie.toFixed(1).replace(".", ",")} m</td></tr>`);
    if (a.mal !== null && a.mal !== undefined)
      rader.push(`<tr><td>Övningens mål</td><td class="num">${String(a.mal).replace(".", ",")} m</td></tr>`);
    rader.push(`<tr><td>Formens spridning</td><td class="num">${a.avvikelse.rms.toFixed(2).replace(".", ",")} m</td></tr>`);
    rader.push(`<tr><td>Ridd sträcka</td><td class="num">${a.stracka.toFixed(1).replace(".", ",")} m</td></tr>`);
    rader.push(`<tr><td>Varv</td><td class="num">${a.varv.toFixed(2).replace(".", ",")}</td></tr>`);
  }
  if (j && j.ok) {
    const d = j.radie.diff;
    rader.push(`<tr><td>Radie mot förra försöket</td><td class="num">${(d >= 0 ? "+" : "") + d.toFixed(1).replace(".", ",")} m</td></tr>`);
  }
  const ord = (typeof voltIOrd === "function" && a) ? voltIOrd(a) : null;
  /* Ingen analys är ett giltigt svar — och ska stå som det, inte som en
     tom tabell som ser trasig ut. */
  if (!rader.length)
    return `<p style="font-size:14px">Den här ritten gick inte att mäta som en volt${a && a.skal ? ` — ${a.skal}` : ""}.</p>`;
  return (ord ? `<p style="font-size:14px;margin-bottom:8px">${ord}</p>` : "")
    + `<table><tbody>${rader.join("")}</tbody></table>`;
}

/* Öppnar vyn för ett bestämt försök. `nr` är försöksnumret; utan det
   tas det senaste. Returnerar false när det inte finns någon ritt att
   visa — då ska knappen inte heller ha erbjudits. */
function visaReplay(ovningId, nr){
  if (typeof ugnetaForsokPost !== "function" || typeof Uppspelning !== "function") return false;
  const post = ugnetaForsokPost(ovningId, nr);
  if (!post || !post.sampel || !post.sampel.length) return false;

  REPLAY.ovningId = ovningId;
  REPLAY.up = new Uppspelning(post);
  REPLAY.ghost = (nr && nr > 1) ? ugnetaForsokPost(ovningId, nr - 1) : null;
  REPLAY.ghostSyns = !!REPLAY.ghost;
  const overgang = replayArOvergang(post);
  REPLAY.analys = (!overgang && typeof analysVolt === "function") ? analysVolt(post) : null;
  REPLAY.overgang = (overgang && typeof analysOvergang === "function") ? analysOvergang(post) : null;
  REPLAY.jamfor = (!overgang && REPLAY.ghost && typeof jamforRitter === "function")
    ? jamforRitter(REPLAY.ghost, post) : null;

  const mindre = replayMindreRorelse();
  overlay(true, `
  <span class="lbl">Din ritt</span>
  <h1 style="margin-top:8px">Se ritten igen</h1>
  <!-- Rutnätet ligger i index.html som #replayRutnat, INTE som inline-stil.
       En inline-regel kan ingen media query ta över, och kolumnerna låg
       därför kvar ner till 320 px där canvasen blev 122 px bred. -->
  <div id="replayRutnat">
    <div>
      <canvas id="replayBana" width="520" height="360"
        style="width:100%;height:auto;background:#181B21;border:1px solid rgba(214,174,60,.35);border-radius:8px"
        role="img" aria-label="Din ridna väg, uppspelad"></canvas>
      <div class="btnrow" style="margin-top:10px;flex-wrap:wrap;gap:8px">
        <button class="btn" id="replaySpela">${mindre ? "Spela" : "Pausa"}</button>
        <button class="btn ghost" id="replayLangsam">Halv fart</button>
        ${REPLAY.ghost ? `<button class="btn ghost" id="replayGhost">Dölj förra försöket</button>` : ""}
        <span id="replayTid" style="font-family:'IBM Plex Mono',monospace;font-size:12px;align-self:center"></span>
      </div>
      <input type="range" id="replaySkjut" min="0" max="1000" value="0" step="1"
        aria-label="Spola i uppspelningen"
        style="width:100%;margin-top:8px">
    </div>
    <div>
      <div class="lbl" style="margin-bottom:6px">Det här mätte vi</div>
      ${replayTextHTML()}
      ${REPLAY.ghost ? `<p style="font-size:12px;opacity:.75;margin-top:8px">Streckad linje är ditt förra försök.</p>` : ""}
      ${mindre ? `<p style="font-size:12px;opacity:.75;margin-top:8px">Uppspelningen startar inte av sig själv eftersom du bett om mindre rörelse.</p>` : ""}
    </div>
  </div>
  <div class="btnrow" style="margin-top:16px">
    <button class="btn" id="replayTillbaka">Tillbaka</button>
  </div>`);

  REPLAY.canvas = document.getElementById("replayBana");
  REPLAY.ctx = REPLAY.canvas ? REPLAY.canvas.getContext("2d") : null;
  if (!mindre) REPLAY.up.spela();
  REPLAY.sist = 0;
  cancelAnimationFrame(REPLAY.raf);
  REPLAY.raf = requestAnimationFrame(replaySteg);
  replaySynk(); replayRita();

  const kn = (id, fn) => { const e = document.getElementById(id); if (e) e.onclick = fn; };
  kn("replaySpela", () => { REPLAY.up.spelar ? REPLAY.up.pausa() : REPLAY.up.spela(); replaySynk(); });
  kn("replayLangsam", () => {
    const e = document.getElementById("replayLangsam");
    const halv = REPLAY.up.fart !== 0.5;
    REPLAY.up.sattFart(halv ? 0.5 : 1);
    if (e) e.textContent = halv ? "Normal fart" : "Halv fart";
  });
  kn("replayGhost", () => {
    REPLAY.ghostSyns = !REPLAY.ghostSyns;
    const e = document.getElementById("replayGhost");
    if (e) e.textContent = REPLAY.ghostSyns ? "Dölj förra försöket" : "Visa förra försöket";
    replayRita();
  });
  kn("replayTillbaka", stangReplay);
  const forst = document.getElementById("replaySpela");
  if (forst && typeof forst.focus === "function") forst.focus();
  const skjut = document.getElementById("replaySkjut");
  if (skjut) skjut.oninput = () => {
    REPLAY.up.pausa();
    REPLAY.up.hoppa((Number(skjut.value) / 1000) * REPLAY.up.langd());
    replaySynk(); replayRita();
  };
  return true;
}

function stangReplay(){
  cancelAnimationFrame(REPLAY.raf);
  REPLAY.raf = 0; REPLAY.sist = 0;
  if (REPLAY.up) REPLAY.up.pausa();
  REPLAY.up = null; REPLAY.ghost = null; REPLAY.analys = null; REPLAY.jamfor = null;
  REPLAY.overgang = null; REPLAY.canvas = null; REPLAY.ctx = null;
  /* Kom spelaren hit från valet är hon inte färdig: hon ska tillbaka
     till Prova igen / Gå vidare, inte kastas ut i en pausad lektion
     utan väg vidare. */
  if (VAL.moment) { ritaForsokVal(); return; }
  overlay(false);
}

/* ══════════════════════════════════════════════════════════════════
   VALET EFTER ETT FÖRSÖK — Prova igen · Se ritten · Gå vidare
   ══════════════════════════════════════════════════════════════════
   G02-D (#137): omridningen ska vara ett uttryckligt beslut, och
   replayen frivillig. Lifecyclen i game.js red förut om momentet
   automatiskt; nu stannar den här och frågar.

   Panelen BEDÖMER INGENTING. Den visar Ugnetas redan satta återkoppling
   och kallar tillbaka på momentProvaIgen()/momentGaVidare() — samma kod
   lifecyclen själv körde. */
const VAL = { moment: null, forsokNr: 1, ovningId: null, slut: false };

function valOvningId(m){
  if (typeof ugnetaOvningFor !== "function") return null;
  const o = ugnetaOvningFor(m);
  return o ? o.id : null;
}

function ritaForsokVal(){
  const m = VAL.moment; if (!m) return false;
  const fb = (typeof LARARE !== "undefined" && LARARE.sistaFeedback) || null;
  const finns = (typeof replayFinns === "function") && replayFinns(VAL.ovningId, VAL.forsokNr);
  const punkter = (fb && fb.punkter && fb.punkter.length) ? fb.punkter : [];
  const slut = VAL.slut;
  overlay(true, `
  <span class="lbl">Ugneta · ridinstruktör</span>
  <h1 style="margin-top:8px">${(fb && fb.rubrik) || (slut ? "Momentet är klart" : "Försöket är klart")}</h1>
  ${punkter.length
    ? `<ul style="font-size:15px;margin-top:8px;padding-left:18px">${
        punkter.map(r => `<li>${r}</li>`).join("")}</ul>`
    : `<p style="font-size:15px;margin-top:4px">Du har ridit ${
        slut ? "klart" : "ett försök på"} ${m.namn || "momentet"}.</p>`}
  <div class="btnrow" style="margin-top:16px;flex-wrap:wrap;gap:8px">
    ${slut ? "" : `<button class="btn" id="valIgen">Prova igen</button>`}
    ${finns ? `<button class="btn${slut ? "" : " ghost"}" id="valSe">Se ritten${
      slut && VAL.forsokNr > 1 ? " och jämför" : ""}</button>` : ""}
    <button class="btn ghost" id="valVidare">Gå vidare</button>
  </div>
  ${finns ? "" : `<p class="dim" style="font-size:12px;margin-top:8px">Den här ritten spelades inte in, så det finns inget att se om.</p>`}`);
  const kn = (id, fn) => { const e = document.getElementById(id); if (e) e.onclick = fn; };
  kn("valIgen", () => { const mm = VAL.moment; valStang(); momentProvaIgen(mm); });
  /* Betyget är redan satt när panelen visas efter sista försöket. Då går
     vägen ut via momentNasta() — momentGaVidare() hade betygsatt en gång
     till. */
  kn("valVidare", () => { const mm = VAL.moment, si = VAL.slut; valStang();
    if (si) momentNasta(); else momentGaVidare(mm); });
  kn("valSe", () => { visaReplay(VAL.ovningId, VAL.forsokNr); });
  /* Fokus på det första valet. Utan det måste den som spelar med
     tangentbord eller handkontroll först tabba sig in i panelen för att
     kunna svara på en fråga spelet just ställt. */
  const forst = document.getElementById(slut ? "valSe" : "valIgen")
    || document.getElementById("valVidare");
  if (forst && typeof forst.focus === "function") forst.focus();
  return true;
}

function valStang(){
  VAL.moment = null; VAL.ovningId = null; VAL.slut = false;
  overlay(false);
}

/* Anropas av lifecyclen. Returnerar true bara när panelen FAKTISKT står
   uppe och pausen är satt — annars måste game.js köra det automatiska
   försöket, så att en lektion aldrig fastnar på en panel som inte gick
   att rita. */
function visaForsokVal(moment, forsokNr, slut){
  if (typeof document === "undefined" || typeof overlay !== "function") return false;
  if (typeof momentProvaIgen !== "function" || typeof momentGaVidare !== "function"
      || typeof momentNasta !== "function") return false;
  if (!moment) return false;
  VAL.moment = moment;
  VAL.forsokNr = forsokNr || 1;
  VAL.slut = !!slut;
  VAL.ovningId = valOvningId(moment);
  /* Efter sista försöket har panelen bara något att erbjuda om ritten
     gick att spela upp. Annars vore den en ruta som säger "Gå vidare"
     och ingenting mer — då är det bättre att lektionen bara fortsätter. */
  if (VAL.slut && !((typeof replayFinns === "function") && replayFinns(VAL.ovningId, VAL.forsokNr))) {
    VAL.moment = null; return false;
  }
  if (!ritaForsokVal()) { VAL.moment = null; return false; }
  /* Panelen SÄGER redan det Ugneta ville säga. Kortet i HUD:en skulle
     annars upprepa samma två meningar när pausen släpper. */
  if (typeof LARARE !== "undefined") LARARE.vantaFeedback = null;
  if (typeof G !== "undefined") G.paus = true;
  return true;
}

/* Finns det något att visa för den här övningen? Knappen ska inte
   erbjudas när svaret är nej — ett val som inte leder någonstans är
   sämre än inget val. */
function replayFinns(ovningId, nr){
  if (typeof ugnetaForsokPost !== "function") return false;
  const p = ugnetaForsokPost(ovningId, nr);
  return !!(p && p.sampel && p.sampel.length);
}

if (typeof window !== "undefined") {
  window.visaReplay = visaReplay;
  window.stangReplay = stangReplay;
  window.replayFinns = replayFinns;
  window.visaForsokVal = visaForsokVal;
}
