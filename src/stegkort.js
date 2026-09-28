/* ══════════════════════════════════════════════════════════════════
   STEGKORTET — webbens Näromrade-panel (roblox/src/client/Naromrade.luau)

   Paritetspasset 2026-09-28 (#264, docs/WEB-P1A-STABLE-FLOW-CONTRACT.md):
   Roblox är facit. Samma hierarki som panelen där — rubrik, instruktion,
   högst fyra val, "+ Fler handlingar", guldfärgad återkoppling — och samma
   kort i samma ordning som `Naromrade.guideSteg`:

     ga_till → valj (Rida nu / själv) → halsa → visitera → rykta → hovar →
     hamta_sadel → sadla → hamta_trans → transa → leda → leder → sittupp

   med fyndet och välfärdsstoppet före allt annat.

   Reglerna bor i src/forberedelse.js (porten av Preparation.luau). Den här
   filen RITAR och skickar handlingar — den bestämmer ingenting själv.

   All text går genom tSpr (src/spel/sprak.js) eller skötselkanonens
   engelska syskonfält. Ingen svensk sträng står här.
   ══════════════════════════════════════════════════════════════════ */

const STEGKORT = { sjalv: {}, fler: false, aterkoppling: "", aterT: 0, sig: "", ridaNu: false };

const skSv = () => typeof SPRAKET === "undefined" || SPRAKET !== "en";
/* Kanonens text på spelarens språk: `text`/`textEn`, `namn`/`namnEn`. */
function skKanon(obj, falt) {
  if (!obj) return "";
  return (!skSv() && obj[falt + "En"]) || obj[falt] || "";
}
function skFyndText(punkt) {
  const t = skSv() ? VISITFYND[punkt] : VISITFYND_EN[punkt];
  return t || tSpr("forb.nagot_ar_fel");
}
function skNamn() { return typeof hastNamn === "function" ? hastNamn() : ""; }

/* Hästens närhet: boxfronten, där hon står och där utrustningen hänger. */
function stegkortNara() {
  if (!G.hastId || G.scen !== "stallinne" || G.hastPlats !== "box") return false;
  const b = typeof hittaBox === "function" && hittaBox(G.hastId);
  return !!b && Math.hypot(VD.px - b.dorr[0], VD.py - b.dorr[1]) <= 2.4;
}

/* Inget ännu gjort — startvalet gäller (Naromrade.arStartskarm). */
function stegkortOrort(s) {
  for (const f in s.gjorda) for (const m in s.gjorda[f]) if (s.gjorda[f][m]) return false;
  return !s.hand.sadel && !s.hand.trans;
}

/* Svaret på ett nej, i spelarens språk. */
function skAvslag(r) {
  if (r[1] === "kanon") return skKanon(r[2], "text");
  if (r[1] === "forb.lararen_tar_over") return tSpr("forb.lararen_tar_over", skFyndText(r[2]));
  const arg = r[2] != null ? (typeof r[2] === "string" ? skKanonNamn(r[2]) : skKanon(r[2], "namn")) : undefined;
  return arg !== undefined ? tSpr(r[1], arg) : tSpr(r[1]);
}
/* Ett fas- eller momentnamn som kom tillbaka som svensk sträng (`fel tur —
   %s står på tur`) slås upp i kanonen och skrivs på spelarens språk. */
function skKanonNamn(sv) {
  for (const f of FASER) if (f.namn === sv) return skKanon(f, "namn");
  for (const f of Forb.stegFaser())
    for (const m of Forb.moment(f.id)) if (m.namn === sv) return skMomentNamn(m);
  return sv;
}
function skMomentNamn(m) {
  if (m.utr) return tSpr("forb.utrustning_steg", m.utr, SADELFAS.length);
  return skKanon(m, "namn");
}

function skAterkoppla(text) { STEGKORT.aterkoppling = text || ""; STEGKORT.aterT = 6; stegkortRita(true); }

function skUtfor(fasId, m) {
  const s = G.forb;
  const r = Forb.utforMoment(s, fasId, m.id, G.hastId);
  if (!r[0]) { skAterkoppla(skAvslag(r)); return; }
  if (r[2] === "fynd") { skAterkoppla(""); return; }
  if (fasId === "halsa" || fasId === "visitera") skAterkoppla(skKanon(m, "text"));
  else skAterkoppla("✓  " + tSpr("hud.bra"));
}

/* Förberedelsen är klar till ledningen: hästens dag sätts EN gång, av
   samma regel som GameplayService.dagsformFor, och ridtillståndet byggs
   — det avslutaSkotsel gjorde efter webbens gamla utvärderingstabell. */
function stegkortForberedd() {
  const s = G.forb;
  G.utrustning = true; G.tackePa = false;
  G.dagsform = Forb.dagsform(s);
  G.sadellage = SVAR_START.SADELLAGE;
  G.skotselRes = { dagsform: G.dagsform, sadellage: G.sadellage, risker: [], omdome: "",
    egenAndel: Forb.egenAndel(s), ridaNu: STEGKORT.ridaNu };
  if (typeof dagensHumor === "function") G.humor = dagensHumor(G.hastId);
  G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
  if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
  if (typeof initNPC === "function") initNPC();
  G.px = 10; G.py = 52; G.rikt = -Math.PI / 2;
}

/* Sargporten — där Roblox «Rida nu» ställer hästen och ryttaren
   (LedService.placeraVidMal), och där uppsittningen i ridhuset sker. */
function skSargport() {
  const sp = SPELABSTRAKTIONER.ridhus.sargport, R = RIDHUSINNE;
  return [(sp.x0 + sp.x1) / 2, R.bana.y + R.bana.h];
}

/* «Rida nu»: stallet gör i ordning henne genom de RIKTIGA momenten och
   leder henne till ridhuset. Ett fynd stoppar stallet — beslutet är
   spelarens (Preparation.autoForbered). */
function stegkortRidaNu() {
  const s = G.forb;
  if (!s) return;
  if (Forb.redo(s)) { skAterkoppla(tSpr("spel.redan_redo")); return; }
  const r = Forb.autoForbered(s);
  if (!r[0]) { skAterkoppla(r[1] === "forb.oppet_fynd" ? "" : skAvslag(r)); return; }
  STEGKORT.ridaNu = true;
  stegkortForberedd();
  const [x, y] = skSargport();
  G.hastPlats = "leds";
  gaTill("ridhusinne", { x, y: y + 1.2, rikt: -Math.PI / 2 });
  VD.hastX = x + 1.1; VD.hastY = y + 1.6; VD.spår.length = 0;
  Forb.utforMoment(s, "leda", "leda", G.hastId, "auto");
  skAterkoppla("");
}

/* Den manuella ledningen kvitteras när hästen FYSISKT är framme i
   ridhuset (GameplayService.kvitteraLedning) — aldrig av en knapp. */
function stegkortKvitteraLedning() {
  const s = G.forb;
  if (!s || G.hastPlats !== "leds" || s.klara.leda) return;
  const n = Forb.nasta(s);
  if (!n || n.id !== "leda") return;
  if (G.scen === "ridhusinne" && Forb.utforMoment(s, "leda", "leda", G.hastId)[0]) stegkortDagsform();
}

/* Dagsformen läses när hon är framme — som Roblox, där dagsformFor frågas
   vid uppsittningen. Ledningen är spelarens eget arbete och räknas med. */
function stegkortDagsform() {
  if (!G.forb || !G.skotselRes) return;
  G.dagsform = Forb.dagsform(G.forb);
  G.skotselRes.dagsform = G.dagsform;
  G.skotselRes.egenAndel = Forb.egenAndel(G.forb);
  G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
  if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
}

/* ── Kortet ──────────────────────────────────────────────────────── */
/* {id, rubrik, text, val:[{id,text,primar,gor}], fler:[…]} eller null. */
function stegkortKort(antaNara) {
  if (!G.hastId || !G.forb || G.scen === "lektion" || G.scen === "meny" || G.scen === "resultat") return null;
  const s = G.forb, n = skNamn();

  if (s.stoppad)
    return { id: "stopp", rubrik: tSpr("hud.lararen_tar_over"),
      text: tSpr("forb.lararen_tar_over", skFyndText(s.stoppad)), val: [] };

  if (s.fyndSett && !s.fyndRapporterat)
    return { id: "fynd", rubrik: tSpr("hud.du_hittade_nagot"), text: skFyndText(s.fynd),
      val: Forb.fyndSvar().map(v => ({ id: v.id, text: skKanon(v, "namn"), primar: false,
        gor() { const r = Forb.svaraFynd(s, v.id); skAterkoppla(r[0] ? "" : skAvslag(r)); } })) };

  if (G.hastPlats === "leds") {
    if (Forb.redo(s))
      return { id: "sittupp", rubrik: tSpr("guide.sittupp_rubrik", n), text: tSpr("guide.sittupp_text"), val: [] };
    return { id: "leder", rubrik: tSpr("guide.leder_rubrik", n), text: tSpr("guide.leder_text", n), val: [] };
  }

  const nara = antaNara || stegkortNara();
  if (!nara)
    return { id: "ga_till", rubrik: tSpr("guide.ga_till_rubrik", n), text: tSpr("guide.ga_till_text"), val: [] };

  const fler = [{ id: "fler:boxen", text: tSpr("guide.fler_boxen"), gor() { visaBoxmeny(); } }];

  if (stegkortOrort(s) && !STEGKORT.sjalv[G.hastId])
    return { id: "valj", rubrik: tSpr("guide.valj_rubrik"), text: tSpr("guide.valj_kort", n), fler: [],
      val: [
        { id: "start:rida_nu", text: tSpr("guide.val_rida_nu", n), primar: true, gor: stegkortRidaNu },
        { id: "start:sjalv", text: tSpr("guide.val_sjalv", n), primar: false,
          gor() { STEGKORT.sjalv[G.hastId] = true; stegkortRita(true); } },
      ] };

  const fas = Forb.nasta(s);
  if (!fas) return null;
  const knapp = (m, fasId) => ({ id: m.id, text: skMomentNamn(m), primar: true, gor() { skUtfor(fasId, m); } });
  const raknare = fasId => {
    const alla = Forb.moment(fasId).filter(m => !m.fel);
    const gjorda = alla.filter(m => s.gjorda[fasId]?.[m.id]).length;
    return `  ·  ${gjorda}/${alla.length}`;
  };

  if (fas.id === "halsa")
    return { id: "halsa", rubrik: tSpr("guide.halsa_rubrik", n), text: skKanon(fas, "text"), fler,
      val: Forb.moment("halsa").map(m => ({ id: m.id, text: skKanon(m, "namn"), primar: false,
        gor() { skUtfor("halsa", m); } })) };

  const m = Forb.nastaMoment(s, fas.id);
  if (fas.id === "visitera")
    return { id: "visitera", rubrik: tSpr("guide.visitera_rubrik", n) + raknare("visitera"),
      text: skKanon(fas, "text"), val: [knapp(m, "visitera")], fler };
  if (fas.id === "rykta")
    return { id: "rykta", rubrik: tSpr("guide.rykta_rubrik", n) + raknare("rykta"),
      text: skKanon(m, "text"), val: [knapp(m, "rykta")], fler };
  if (fas.id === "iordning") {
    if (!m.utr)
      return { id: "hovar", rubrik: tSpr("guide.hovar_rubrik"), text: skKanon(m, "text"),
        val: [knapp(m, "iordning")], fler };
    const trans = m.utr === SADELFAS.length;
    if (!s.hand[trans ? "trans" : "sadel"])
      return trans
        ? { id: "hamta_trans", rubrik: tSpr("guide.hamta_trans_rubrik"), text: tSpr("guide.hamta_trans_text"), fler,
            val: [{ id: "tack:trans", text: tSpr("tack.ta_transet"), primar: true,
              gor() { s.hand.trans = true; skAterkoppla(""); } }] }
        : { id: "hamta_sadel", rubrik: tSpr("guide.hamta_sadel_rubrik"), text: tSpr("guide.hamta_sadel_text", n), fler,
            val: [{ id: "tack:sadel", text: tSpr("tack.ta_sadeln"), primar: true,
              gor() { s.hand.sadel = true; skAterkoppla(""); } }] };
    return { id: trans ? "transa" : "sadla", rubrik: tSpr(trans ? "guide.transa_rubrik" : "guide.sadla_rubrik"),
      text: skKanon(m, "text"), val: [knapp(m, "iordning")], fler };
  }
  if (fas.id === "leda")
    return { id: "leda", rubrik: tSpr("guide.leda_rubrik", n), text: tSpr("guide.leda_text"), fler,
      val: [{ id: "leda", text: tSpr("led.borja_namn", n), primar: true,
        gor() { stegkortForberedd(); G.hastPlats = "leds"; VD.spår.length = 0; skAterkoppla(""); } }] };
  return null;
}

/* Kortets primära handling — det E gör vid hästen (webbens motsvarighet
   till den prompt Roblox rankar först). Frågas SOM OM spelaren stod vid
   hästen: prompten sitter på boxen, och `interagera()` avgör räckvidden —
   precis som en ProximityPrompt finns på hästen och visas inom räckhåll. */
function stegkortPrimar() {
  const k = stegkortKort(true);
  const v = k && (k.val || []).find(x => x.primar);
  return v ? { text: v.text, gor: v.gor } : null;
}

/* ── Ritningen ───────────────────────────────────────────────────── */
function stegkortInstallera() {
  if (typeof document === "undefined" || document.getElementById("stegkort")) return;
  const stil = document.createElement("style");
  stil.id = "stegkortStil";
  /* Roblox-panelen: 300 px bred, mörk 24,27,33 vid 0,12 transparens,
     radie 8, guld 236,196,92 för återkopplingen, accent 92,76,38 bara på
     den primära handlingen. Mörkt formspråk i båda temana — panelen ligger
     över spelvyn, inte över sidan. */
  stil.textContent = `
  #stegkort{position:fixed;left:max(14px,env(safe-area-inset-left,0px));bottom:calc(14px + env(safe-area-inset-bottom,0px));
    width:300px;max-width:min(34vw,300px);min-width:220px;z-index:14;box-sizing:border-box;
    background:rgba(24,27,33,.88);color:#EDEAE3;border-radius:8px;padding:12px 12px 10px;
    font:14px/1.35 system-ui,-apple-system,"Segoe UI",sans-serif;box-shadow:0 6px 24px rgba(0,0,0,.35)}
  #stegkort[hidden]{display:none!important}
  #stegkort .skR{font-weight:650;font-size:15px;margin:0 0 4px}
  #stegkort .skT{margin:0 0 8px;color:#D6D2C8}
  #stegkort .skV{display:grid;gap:6px}
  #stegkort button{all:unset;box-sizing:border-box;display:block;width:100%;cursor:pointer;padding:8px 10px;
    border-radius:6px;background:rgba(255,255,255,.07);color:#EDEAE3;font:inherit;line-height:1.25;min-height:36px}
  #stegkort button:hover,#stegkort button:focus-visible{background:rgba(255,255,255,.13);outline:none}
  #stegkort button.primar{background:rgb(92,76,38);color:#FFF6E0}
  #stegkort button.primar:hover{background:rgb(112,93,47)}
  #stegkort .skF{margin-top:6px;font-size:12.5px;color:#BFB8A8}
  #stegkort .skA{margin-top:8px;color:rgb(236,196,92);min-height:0}
  #stegkort .skA:empty{display:none}
  @media (max-width:760px){#stegkort{max-width:calc(100vw - 28px);width:auto;right:14px}}`;
  document.head.appendChild(stil);
  const el = document.createElement("div");
  el.id = "stegkort"; el.hidden = true;
  el.setAttribute("role", "region");
  document.getElementById("app").appendChild(el);
}

function stegkortRita(tvinga) {
  const el = document.getElementById("stegkort");
  if (!el) return;
  if (STEGKORT.aterT > 0) { STEGKORT.aterT -= 1 / 60; if (STEGKORT.aterT <= 0) STEGKORT.aterkoppling = ""; }
  const k = stegkortKort();
  const oppen = typeof overlayUppe === "function" && overlayUppe();
  if (!k || oppen) { el.hidden = true; STEGKORT.sig = ""; return; }
  const fler = k.fler || [];
  const sig = [k.id, k.rubrik, k.text, (k.val || []).map(v => v.id + v.text).join("|"),
    fler.length, STEGKORT.fler, STEGKORT.aterkoppling, typeof SPRAKET !== "undefined" ? SPRAKET : ""].join("§");
  el.hidden = false;
  if (!tvinga && sig === STEGKORT.sig) return;
  STEGKORT.sig = sig;
  const esc = t => String(t).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const val = (k.val || []).slice(0, 4);
  el.dataset.kort = k.id;
  el.innerHTML = `<div class="skR">${esc(k.rubrik)}</div>`
    + (k.text ? `<div class="skT">${esc(k.text)}</div>` : "")
    + (val.length ? `<div class="skV">${val.map((v, i) =>
        `<button data-i="${i}" data-id="${esc(v.id)}" class="${v.primar ? "primar" : ""}">${esc(v.text)}</button>`).join("")}</div>` : "")
    + (fler.length ? `<div class="skF"><button data-fler="1">+  ${esc(tSpr("panel.fler"))}</button>${
        STEGKORT.fler ? `<div class="skV" style="margin-top:6px">${fler.map((v, i) =>
          `<button data-f="${i}" data-id="${esc(v.id)}">${esc(v.text)}</button>`).join("")}</div>` : ""}</div>` : "")
    + `<div class="skA">${esc(STEGKORT.aterkoppling)}</div>`;
  for (const b of el.querySelectorAll("button[data-i]"))
    b.onclick = () => { const v = val[+b.dataset.i]; if (v) v.gor(); stegkortRita(true); };
  for (const b of el.querySelectorAll("button[data-f]"))
    b.onclick = () => { const v = fler[+b.dataset.f]; STEGKORT.fler = false; if (v) v.gor(); };
  const fb = el.querySelector("button[data-fler]");
  if (fb) fb.onclick = () => { STEGKORT.fler = !STEGKORT.fler; stegkortRita(true); };
}

if (typeof window !== "undefined") {
  window.STEGKORT = STEGKORT;
  window.stegkortKort = stegkortKort;
}
stegkortInstallera();
