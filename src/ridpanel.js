/* ══════════════════════════════════════════════════════════════════
   RIDPANELEN — webbens port av Roblox Naromrade-panelens uppsuttna gren
   (P3 § 2, docs/P3-RIDING-PANEL-LESSON-MENU-CONTRACT.md).

   EN panel nere till vänster, i Naromrades LayoutOrder:
     0  Ugnetas ruta — titel, Text, språkflaggan och EXAKT ett meddelande
        (lararMeddelande: lektionens sida → live-chipet → kortets rad →
        övningen som pågår → ridraden utanför en lektion),
     1  rubriken «{häst}  ·  {gångart}» och `?`,
     2  de fyra kärnraderna ur KontrollHjalp (src/kontrollhjalp.js);
        `?` fäller ut hela listan och de fyra hjälpmätarna — webbens
        inmatning ÄR hjälperna,
     3  högst fyra val (Naromrade MAX_VAL): Ugnetas kortknappar först,
        sedan lektionens val; ryms de inte och lektionen har en kompakt
        lista används den (UgnetaController.panel).

   Ugnetas ruta har samma formspråk som P2-kortet till fots (#stegkort
   .skU): samma titel, samma flagga, samma färger. Text-knappen öppnar
   inställningarna INNE i rutan (Roblox byggInstallning).

   Allt spelaren läser går genom tSpr. ── */

const RIDPANEL = { hjalpUt: false, installOppen: false, sig: "", rad: null };

/* ── UGNETAS RIDRAD — port av roblox/src/client/UgnetaRad.luau ──────── */
const UgnetaRad = (() => {
  const ETABLERAD = 3.0, ETABLERAD_KORT = 1.2, BEROM_TID = 6.0, PAUS = 8.0, START_VANTA = 1.5;
  const ORDNING = { halt: 0, walk: 1, trot: 2, canter: 3, gallop: 4 };
  const ny = () => ({ gait: null, sedan: 0, forra: null, nedat: false, haftRorelse: false, sagt: {},
    berom: null, beromKvar: 0, sedanTips: Infinity, lektion: null });
  function steg(s, dt, inn) {
    if (!inn.uppsutten) { Object.assign(s, ny()); return null; }
    const gait = inn.gait || "halt";
    s.sedanTips += dt;
    if (gait !== s.gait) {
      const fore = s.gait;
      s.forra = fore;
      s.nedat = fore != null && (ORDNING[gait] || 0) < (ORDNING[fore] || 0);
      s.gait = gait; s.sedan = 0; s.sagt = {};
      s.berom = null; s.beromKvar = 0;
    } else s.sedan += dt;
    if (gait !== "halt") s.haftRorelse = true;
    if (s.beromKvar > 0) s.beromKvar -= dt;
    if (s.beromKvar <= 0) s.berom = null;
    const iLektion = inn.lektion === true;
    if (iLektion !== (s.lektion === true)) { s.berom = null; s.beromKvar = 0; s.lektion = iLektion; }
    if (iLektion) return null;
    const berom = (nyckel, args) => {
      if (s.sagt[nyckel] || s.sedanTips < PAUS) return;
      s.sagt[nyckel] = true;
      s.berom = { nyckel, args: args || [] };
      s.beromKvar = BEROM_TID; s.sedanTips = 0;
    };
    if (s.nedat && s.sedan >= ETABLERAD_KORT) { berom("ugneta.rad.fin_overgang"); s.nedat = false; }
    if (gait === "walk" && s.sedan >= ETABLERAD) berom("ugneta.rad.bra_skritt");
    else if (gait === "trot" && s.sedan >= ETABLERAD_KORT) berom("ugneta.rad.lattridning");
    else if ((gait === "canter" || gait === "gallop") && s.sedan >= ETABLERAD_KORT) berom("ugneta.rad.galopp");
    if (s.berom) return s.berom;
    const driv = inn.driv;
    if (gait === "halt" && !s.haftRorelse && s.sedan >= START_VANTA && typeof driv === "string" && driv !== "")
      return { nyckel: "ugneta.rad.borja_skritt", args: [driv] };
    if (gait === "walk" && s.sagt["ugneta.rad.bra_skritt"] && inn.travTillaten && typeof driv === "string" && driv !== "")
      return { nyckel: "ugneta.rad.be_om_trav", args: [driv] };
    return null;
  }
  return { ny, steg, ETABLERAD, ETABLERAD_KORT, BEROM_TID, PAUS, START_VANTA };
})();

function rpT(k, ...a) { return typeof tSpr === "function" ? tSpr(k, ...a) : k; }

/* Uppsuttet i huvudvägen: ridpanelen gäller. Tävlingen har sin egen HUD. */
function ridpanelAktiv() {
  return typeof G !== "undefined" && (G.scen === "lektion") && !G.tavling && !!G.ride && !!G.p3;
}

/* Rubriken — Roblox rubrikFor + Naromrades gångartsrad. */
function ridpanelRubrik() {
  const h = typeof HORSES !== "undefined" && G.hastId ? HORSES[G.hastId] : null;
  const namn = h ? h.namn : "";
  const GANG = { halt: "gangart.halt", skritt: "gangart.walk", trav: "gangart.trot", galopp: "gangart.canter" };
  const r = G.ride || {};
  const g = r.gangart, mal = r.beddGangart;
  let txt = GANG[g] ? rpT(GANG[g]) : rpT("hud.du_rider");
  if (GANG[g] && GANG[mal] && mal !== g && mal !== "halt" && g !== "halt")
    txt = rpT("gangart.byte", rpT(GANG[g]), rpT(GANG[mal]).toLowerCase());
  else if (g === "trav")
    txt += "  ·  " + rpT(typeof IN !== "undefined" && IN.latt ? "sits.lattridning" : "sits.sittande");
  if (!namn) return txt;
  return txt.includes(namn) ? txt : namn + "  ·  " + txt;
}

/* Meddelandet — Roblox lararMeddelande, i samma ordning. */
function ridpanelMeddelande(extra) {
  if (extra && extra.ersatt) return extra.text || null;
  const chip = typeof FriPass !== "undefined" ? FriPass.chip() : null;
  if (chip) return chip;
  const kort = typeof FriPass !== "undefined" ? FriPass.kortRad() : null;
  if (kort) return kort;
  const pagar = typeof FriPass !== "undefined" ? FriPass.ovningsRad() : null;
  if (pagar) return pagar;
  const r = RIDPANEL.rad;
  if (r) return rpT(r.nyckel, ...(r.args || []));
  return null;
}

/* Knapparna — UgnetaController.panel(MAX_VAL). */
function ridpanelKnappar(extra) {
  const MAX_VAL = 4;
  if (extra && extra.ersatt) return (extra.knappar || []).slice(0, MAX_VAL);
  const knappar = typeof FriPass !== "undefined" ? FriPass.knappar() : [];
  if (extra) {
    let lista = extra.knappar || [];
    if (extra.kompakt && knappar.length + lista.length > MAX_VAL) lista = extra.kompakt;
    knappar.push(...lista);
  }
  return knappar.slice(0, MAX_VAL);
}

/* Ridraden stegas varje bildruta, som i Roblox init.client. */
function ridpanelSteg(dt) {
  if (!ridpanelAktiv()) { RIDPANEL.radLage = null; RIDPANEL.rad = null; return; }
  if (!RIDPANEL.radLage) RIDPANEL.radLage = UgnetaRad.ny();
  const lektion = typeof Lektionsmeny !== "undefined" && Lektionsmeny.tarOver()
    ? Lektionsmeny.lektion() : typeof FriPass !== "undefined" && FriPass.pagar();
  const rehab = typeof hastminne === "function" && G.hastId && hastminne(G.hastId).rehab;
  RIDPANEL.rad = UgnetaRad.steg(RIDPANEL.radLage, dt, { uppsutten: true, lektion,
    gait: typeof RittLektion !== "undefined" ? RittLektion.tillRoblox(G.ride && G.ride.gangart) : null,
    driv: typeof kontrollReglageFor === "function" ? kontrollReglageFor("hjalp.webb.driv") : null,
    travTillaten: !rehab });
}

function ridpanelInstallera() {
  if (typeof document === "undefined" || document.getElementById("ridpanel")) return;
  const stil = document.createElement("style");
  stil.id = "ridpanelStil";
  /* Samma formspråk som #stegkort (P2): mörk 24,27,33, radie 8, guld
     236,196,92, accent 92,76,38 på knappen som står på tur. */
  stil.textContent = `
  #ridpanel{position:fixed;left:max(14px,env(safe-area-inset-left,0px));bottom:calc(14px + env(safe-area-inset-bottom,0px));
    width:300px;max-width:min(34vw,300px);min-width:220px;z-index:14;box-sizing:border-box;
    max-height:calc(100vh - 28px);overflow:auto;
    color:#EDEAE3;display:flex;flex-direction:column;gap:8px;
    font:14px/1.35 system-ui,-apple-system,"Segoe UI",sans-serif}
  /* #274: TVÅ KORT — Ugneta (bara coachning) och statuskortet (häst, läge, val),
     vart och ett med eget fält. Förut var de ett block i samma ruta. */
  #ridpanel .skU,#ridpanel .rpS{background:rgba(24,27,33,.88);border-radius:8px;padding:10px 12px;
    box-shadow:0 6px 24px rgba(0,0,0,.35)}
  #ridpanel[hidden]{display:none!important}
  .pek #ridpanel{bottom:calc(172px + env(safe-area-inset-bottom,0px));max-height:calc(100vh - 190px)}
  #ridpanel .skU{border:1px solid rgba(236,196,92,.45);border-left:3px solid rgb(236,196,92)}
  #ridpanel .skUh{display:flex;align-items:center;gap:6px;min-height:32px}
  #ridpanel .skUt{flex:1;font-weight:650;font-size:13px;color:rgb(236,196,92);letter-spacing:.01em}
  #ridpanel button.skSmal{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:6px;cursor:pointer;
    min-height:32px;padding:4px 8px;border-radius:6px;background:rgba(255,255,255,.07);font-size:12.5px;color:#EDEAE3}
  #ridpanel button.skSmal.pa{background:rgb(236,196,92);color:#17140A}
  #ridpanel button.skSmal:hover,#ridpanel button.skSmal:focus-visible{background:rgba(255,255,255,.14)}
  #ridpanel .skFl{display:inline-block;width:20px;height:13px;border-radius:2px;flex:none}
  #ridpanel .skFl.sv{background:linear-gradient(90deg,transparent 6px,#FECC02 6px,#FECC02 9px,transparent 9px),
    linear-gradient(0deg,transparent 5px,#FECC02 5px,#FECC02 8px,transparent 8px),#006AA7}
  #ridpanel .skFl.en{background:linear-gradient(90deg,transparent 8px,#C8102E 8px,#C8102E 12px,transparent 12px),
    linear-gradient(0deg,transparent 5px,#C8102E 5px,#C8102E 8px,transparent 8px),
    linear-gradient(90deg,transparent 7px,#fff 7px,#fff 13px,transparent 13px),
    linear-gradient(0deg,transparent 4px,#fff 4px,#fff 9px,transparent 9px),#012169}
  #ridpanel .skUi{margin-top:4px;color:#EDEAE3}
  #ridpanel .rpInst{margin-top:6px;display:grid;gap:4px}
  #ridpanel .rpInstR{font-weight:650;font-size:12.5px;color:rgb(236,196,92)}
  #ridpanel .rpInstG{display:flex;gap:4px}
  #ridpanel .rpInstG button{flex:1;min-height:36px;font-size:12.5px;text-align:center}
  #ridpanel .rpH{display:flex;align-items:center;gap:8px;margin:0 0 4px}
  #ridpanel .rpHt{flex:1;font-weight:650;font-size:15px}
  #ridpanel button.rpQ{all:unset;box-sizing:border-box;cursor:pointer;min-width:32px;min-height:32px;border-radius:6px;
    text-align:center;font-weight:700;color:#AAACB0;background:rgba(255,255,255,.05)}
  #ridpanel button.rpQ.pa{color:#17140A;background:rgb(236,196,92)}
  #ridpanel .rpK{margin:0 0 8px;color:#D6D2C8;font-size:13px;display:grid;gap:2px}
  #ridpanel .rpRad{display:flex;justify-content:space-between;gap:8px}
  #ridpanel .rpRad b{font-weight:600;color:#BFB8A8;white-space:nowrap}
  #ridpanel .rpAvancerat{margin-top:4px;font-size:10px;letter-spacing:.08em;text-transform:uppercase;opacity:.7}
  #ridpanel .rpAlla{margin:4px 0 8px;padding-top:6px;border-top:1px solid rgba(255,255,255,.10);display:grid;gap:2px;
    font-size:12.5px;color:#BFB8A8}
  #ridpanel .rpM{display:grid;grid-template-columns:62px 1fr;gap:6px;align-items:center;font-size:12px}
  #ridpanel .rpM i{display:block;height:6px;border-radius:3px;background:rgba(255,255,255,.12);position:relative;overflow:hidden}
  #ridpanel .rpM i s{position:absolute;left:0;top:0;bottom:0;background:rgb(214,174,60)}
  #ridpanel .skV{display:grid;gap:6px}
  #ridpanel .skV button,#ridpanel .rpInstG button,#ridpanel .rpKlar{all:unset;box-sizing:border-box;display:block;width:100%;cursor:pointer;
    padding:8px 10px;border-radius:6px;background:rgba(255,255,255,.07);color:#EDEAE3;font:inherit;line-height:1.25;min-height:36px}
  #ridpanel .skV button:hover,#ridpanel .skV button:focus-visible{background:rgba(255,255,255,.13);outline:none}
  #ridpanel .skV button.primar{background:rgb(92,76,38);color:#FFF6E0}
  #ridpanel .rpInstG button.vald{background:rgb(236,196,92);color:#17140A;font-weight:700}
  #ridpanel .rpKlar{text-align:center;background:rgb(60,72,68)}
  @media (max-width:760px){#ridpanel{max-width:calc(100vw - 28px);width:auto;right:14px}}
  /* Reglagelistan (H) står till vänster på mitten, som Roblox KontrollHjalp.
     Med ridpanelen uppe skulle den täcka panelens knappar — då läggs den
     till höger om panelen, och på smal skärm överst. Bara placeringen. */
  body.ridpanelUppe #kontrollhjalp{left:calc(max(14px,env(safe-area-inset-left,0px)) + min(34vw,300px) + 12px)}
  @media (max-width:760px){body.ridpanelUppe #kontrollhjalp{left:12px;top:12px;transform:none;max-height:42vh}}`;
  document.head.appendChild(stil);
  const el = document.createElement("div");
  el.id = "ridpanel"; el.hidden = true;
  el.setAttribute("role", "region");
  document.getElementById("app").appendChild(el);
}

/* Ritningen — varje bildruta, men DOM:en rörs bara när något ändrats. */
function ridpanelRita(tvinga) {
  const el = typeof document !== "undefined" ? document.getElementById("ridpanel") : null;
  if (!el) return;
  const oppen = typeof overlayUppe === "function" && overlayUppe();
  const uppe = ridpanelAktiv() && !oppen;
  if (document.body.classList.contains("ridpanelUppe") !== uppe) document.body.classList.toggle("ridpanelUppe", uppe);
  if (!uppe) { el.hidden = true; RIDPANEL.sig = ""; return; }
  const extra = typeof Lektionsmeny !== "undefined" ? Lektionsmeny.panel() : null;
  const medd = ridpanelMeddelande(extra);
  const knappar = ridpanelKnappar(extra);
  const rubrik = ridpanelRubrik();
  const karna = typeof kontrollRidrader === "function" ? kontrollRidrader() : [];
  /* Bakom `?`: det vardagliga först, hjälperna under «Avancerat» (#273 S1). */
  const alla = RIDPANEL.hjalpUt && typeof kontrollListrader === "function"
    ? kontrollListrader().filter(r => !(typeof KONTROLL_KARNA !== "undefined" && KONTROLL_KARNA.includes(r.nyckel))) : [];
  const I = typeof LararInstallning !== "undefined" ? LararInstallning : null;
  const sv = typeof SPRAKET === "undefined" || SPRAKET !== "en";
  const matare = RIDPANEL.hjalpUt && G.aids ? [
    ["hjalp.webb.m_skankel", G.aids.skankel], ["hjalp.webb.m_tygel", G.aids.tygel],
    ["hjalp.webb.m_sits", (G.aids.sits + 1) / 2], ["hjalp.styr", (G.aids.styrning + 1) / 2]] : [];
  const sig = [medd, rubrik, knappar.map(k => k.text + (k.paTur ? "*" : "")).join("|"), karna.map(r => r.vad + r.reglage).join("|"),
    alla.map(r => r.vad + r.reglage).join("|"), RIDPANEL.hjalpUt, RIDPANEL.installOppen, I ? I.kommentarer() + I.detalj() : "",
    sv, matare.map(m => Math.round(m[1] * 40)).join(",")].join("§");
  el.hidden = false;
  if (!tvinga && sig === RIDPANEL.sig) return;
  RIDPANEL.sig = sig;
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  let inst = "";
  if (RIDPANEL.installOppen && I) {
    const grupp = (namn, varden, nu) => `<div class="rpInstG">${varden.map(v =>
      `<button data-inst="${namn}:${v}" class="${v === nu ? "vald" : ""}">${esc(rpT("installning." + namn + "." + v))}</button>`).join("")}</div>`;
    inst = `<div class="rpInst"><div class="rpInstR">${esc(rpT("installning.rubrik_kommentarer"))}</div>`
      + grupp("kommentarer", ["normal", "farre", "inga"], I.kommentarer())
      + `<div class="rpInstR">${esc(rpT("installning.rubrik_detalj"))}</div>`
      + grupp("detalj", ["detaljerad", "kort"], I.detalj())
      + `<button class="rpKlar" data-instklar="1">${esc(rpT("installning.klar"))}</button></div>`;
  }
  el.innerHTML = `<div class="skU"><div class="skUh"><span class="skUt">${esc(rpT("ugneta.titel"))}</span>`
    + `<button class="skSmal${RIDPANEL.installOppen ? " pa" : ""}" data-text="1" title="${esc(rpT("installning.tips"))}" aria-label="${esc(rpT("installning.tips"))}">${esc(rpT("installning.knapp"))}</button>`
    + `<button class="skSmal" data-sprak="1" aria-label="${esc(rpT("sprak.byt"))}" title="${esc(rpT("sprak.byt"))}">`
    + `<span class="skFl ${sv ? "sv" : "en"}"></span>${esc(rpT("sprak.nuvarande"))}</button></div>`
    + (medd ? `<div class="skUi">${esc(medd)}</div>` : "") + inst + `</div>`
    + `<div class="rpS"><div class="rpH"><span class="rpHt">${esc(rubrik)}</span>`
    + `<button class="rpQ${RIDPANEL.hjalpUt ? " pa" : ""}" data-hjalp="1" aria-label="${esc(rpT("panel.hjalp"))}" title="${esc(rpT("panel.hjalp"))}">?</button></div>`
    + `<div class="rpK">${karna.map(r => `<div class="rpRad"><span>${esc(r.vad)}</span><b>[${esc(r.reglage)}]</b></div>`).join("")}`
    + (RIDPANEL.hjalpUt ? `<div class="rpAlla">${alla.map(r => r.rubrik
        ? `<div class="rpRad rpAvancerat"><span>${esc(r.vad)}</span></div>`
        : `<div class="rpRad"><span>${esc(r.vad)}</span><b>[${esc(r.reglage)}]</b></div>`).join("")}`
      + matare.map(m => `<div class="rpM"><span>${esc(rpT(m[0]))}</span><i><s style="width:${Math.round(Math.max(0, Math.min(1, m[1])) * 100)}%"></s></i></div>`).join("")
      + `</div>` : "") + `</div>`
    + (knappar.length ? `<div class="skV">${knappar.map((k, i) =>
        `<button data-i="${i}" class="${k.paTur ? "primar" : ""}">${esc(k.text)}</button>`).join("")}</div>` : "")
    + `</div>`;
  for (const b of el.querySelectorAll("button[data-i]"))
    b.onclick = () => { const k = knappar[+b.dataset.i]; if (k && k.gor) k.gor(); ridpanelRita(true); };
  const q = el.querySelector("button[data-hjalp]");
  if (q) q.onclick = () => { RIDPANEL.hjalpUt = !RIDPANEL.hjalpUt; ridpanelRita(true); };
  const tb = el.querySelector("button[data-text]");
  if (tb) tb.onclick = () => { RIDPANEL.installOppen = !RIDPANEL.installOppen; ridpanelRita(true); };
  const kl = el.querySelector("button[data-instklar]");
  if (kl) kl.onclick = () => { RIDPANEL.installOppen = false; ridpanelRita(true); };
  for (const b of el.querySelectorAll("button[data-inst]")) b.onclick = () => {
    const [grupp, v] = b.dataset.inst.split(":");
    if (I) { if (grupp === "kommentarer") I.satKommentarer(v); else I.satDetalj(v); }
    ridpanelRita(true);
  };
  const sb = el.querySelector("button[data-sprak]");
  if (sb) sb.onclick = () => {
    if (typeof stegkortVaxlaSprak === "function") stegkortVaxlaSprak();
    else if (typeof window !== "undefined") window.SPRAKET = window.SPRAKET === "en" ? "sv" : "en";
    if (typeof kontrollHjalpSprak === "function") kontrollHjalpSprak();
    if (typeof sprakEtiketter === "function") sprakEtiketter();
    ridpanelRita(true);
  };
}

if (typeof window !== "undefined") {
  window.RIDPANEL = RIDPANEL;
  window.UgnetaRad = UgnetaRad;
  window.ridpanelRita = ridpanelRita;
  window.ridpanelAktiv = ridpanelAktiv;
  window.ridpanelMeddelande = ridpanelMeddelande;
  window.ridpanelKnappar = ridpanelKnappar;
}
ridpanelInstallera();
