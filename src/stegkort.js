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

   #273 S2 (T2): EN HANDLING PER KORT. Hälsa, kolla, rykta, kratsa, sadla
   och tränsa är var sin knapp; servern/regelmodulen utför fasens moment i
   ordning (Forb.utforHandling). Kortet bär EN kort rad. Detaljmeningarna
   — hovarna, mungiporna, gjorden i tre tag — står ordagrant kvar, men i
   det frivilliga kunskapslagret bakom «Så gör man».

   All text går genom tSpr (src/spel/sprak.js) eller skötselkanonens
   engelska syskonfält. Ingen svensk sträng står här.
   ══════════════════════════════════════════════════════════════════ */

const STEGKORT = { sjalv: {}, fler: false, kunskap: false, aterkoppling: "", aterT: 0, sig: "", ridaNu: false };

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

/* #273 S2: handlingens knapp, korta rad och kvittens. VARJE NYCKEL ÄR EN
   LITERAL — språkgrinden ska kunna se dem. */
const SK_HANDLING = {
  halsa:  { knapp: () => tSpr("handling.halsa"),  text: () => tSpr("handling.halsa_text"),  klar: () => tSpr("handling.halsa_klar") },
  kolla:  { knapp: () => tSpr("handling.kolla"),  text: () => tSpr("handling.kolla_text"),  klar: () => tSpr("handling.kolla_klar") },
  rykta:  { knapp: () => tSpr("handling.rykta"),  text: () => tSpr("handling.rykta_text"),  klar: () => tSpr("hud.bra") },
  kratsa: { knapp: () => tSpr("handling.kratsa"), text: () => tSpr("handling.kratsa_text"), klar: () => tSpr("hud.bra") },
  sadla:  { knapp: () => tSpr("handling.sadla"),  text: () => tSpr("handling.sadla_text"),  klar: () => tSpr("hud.bra") },
  transa: { knapp: () => tSpr("handling.transa"), text: () => tSpr("handling.transa_text"), klar: () => tSpr("hud.bra") },
};
function skHandling(id) {
  const r = Forb.utforHandling(G.forb, id, G.hastId);
  if (!r[0]) { skAterkoppla(skAvslag(r)); return; }
  STEGKORT.kunskap = false;
  if (r[2] === "fynd") { skAterkoppla(""); return; }
  skAterkoppla("✓  " + SK_HANDLING[id].klar());
}
/* Det frivilliga kunskapslagret: handlingens moment med kanonens egna
   meningar, ordagrant. Läses bara av den som öppnar det. */
function skKunskap(h) {
  return h.moment.map(m => {
    const namn = skMomentNamn(m), text = skKanon(m, "text");
    return namn && namn !== text ? `${namn} — ${text}` : text;
  });
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

/* ── FIRST RIDE — port av Roblox ForstaRitten ─────────────────────
   Gäller bara en betrodd läsning, första passet (webbens 0 = Roblox 1),
   en vanlig dag och en tilldelad häst. Hästen och spelaren ställs vid
   sargporten, utrustningen sitter på och spelaren sätts upp.

   FÖRBEREDELSEN RÖRS INTE: inget moment blir gjort, inte ens som "auto"
   — exakt Roblox «skötselchecklistan står kvar ogjord» (ForstaRitten
   bokför ingenting; LedService.stallFram kvitterar inte ledningen).
   Dagsformen är därför 0,70: egen andel 0. */
function forstaRittenGaller() {
  return typeof SPAR !== "undefined" && !!SPAR && SPAR.pass === 0
    && typeof SPAR_BETRODD !== "undefined" && SPAR_BETRODD === true
    && !G.tavling && !!G.hastId && !!G.forb;
}
/* Grinden före First Rides uppsittning (P1b R1, #266 L1). First Ride
   hoppar över EN sak: att skötselchecklistan inte är gjord. Allt annat i
   `Forb.provaUppsittning` gäller fortfarande — rätt häst och inget
   välfärdsstopp — och utrustningen ska sitta på, webbens motsvarighet
   till Roblox `TackService.ridklar` som läser modellen. Välfärden håller
   alltså av konstruktion, inte för att pass 1 råkar sakna fynd. */
function forstaRittenKanSittaUpp() {
  const s = G.forb;
  if (!s || s.hastId !== G.hastId) return [false, "forb.inte_din_hast"];
  if (s.stoppad) return [false, "forb.lararen_tar_over", s.stoppad];
  if (G.utrustning !== true) return [false, "guide.sadla_rubrik"];
  return [true];
}
function forstaRitten() {
  if (!forstaRittenGaller()) return false;
  const [x, y] = skSargport();
  STEGKORT.ridaNu = false;
  G.hastPlats = "leds";
  gaTill("ridhusinne", { x, y: y + 1.2, rikt: -Math.PI / 2 });
  VD.hastX = x + 1.1; VD.hastY = y + 1.6; VD.spår.length = 0;
  stegkortForberedd();
  G.skotselRes.forstaRitten = true;
  const r = forstaRittenKanSittaUpp();
  if (!r[0]) { saga(typeof skAvslag === "function" ? skAvslag(r) : tSpr(r[1]), 4); return false; }
  sittUppDirekt("ridhus");
  return true;
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

  /* «Rida nu» är en prompt på hästen i Roblox (RidaNuPrompt, R 0,35 s) och
     finns i världen även när startvalet står i panelen — panelen visar den
     bara inte som rad där (UI-1: exakt två knappar). */
  const ridaNuVarld = { id: "rad:rida_nu", text: tSpr("guide.val_rida_nu", n), tangent: "KeyR", hall: 0.35,
    gor: stegkortRidaNu };
  if (stegkortOrort(s) && !STEGKORT.sjalv[G.hastId])
    return { id: "valj", rubrik: tSpr("guide.valj_rubrik"), text: tSpr("guide.valj_kort", n), fler: [],
      rader: [], varld: [ridaNuVarld],
      val: [
        { id: "start:rida_nu", text: tSpr("guide.val_rida_nu", n), primar: true, gor: stegkortRidaNu },
        { id: "start:sjalv", text: tSpr("guide.val_sjalv", n), primar: false,
          gor() { STEGKORT.sjalv[G.hastId] = true; stegkortRita(true); } },
      ] };

  const fas = Forb.nasta(s);
  if (!fas) return null;
  /* #273 S2: handlingen som står på tur — EN knapp, EN kort rad. */
  const hd = Forb.nastaHandling(s, fas.id);
  const knapp = () => ({ id: "handling:" + hd.id, text: SK_HANDLING[hd.id].knapp(), primar: true,
    gor() { skHandling(hd.id); } });
  const hText = () => SK_HANDLING[hd.id].text();

  /* PROMPTRADERNA — Roblox ProximityPrompts vid hästen, med samma tangent
     och hålltid som InteractionController (RidaNuPrompt R 0,35 s,
     LedPrompt L 0,2 s, Sadla/Tränsa F 0,35 s, tack på boxfronten 0 s).
     Den kortspecifika prompten rankas först, «Rida nu» sist — samma
     ordning som Naromrade ger under utr:- och leda-stegen. */
  const ridaNuRad = { id: "rad:rida_nu", text: tSpr("guide.val_rida_nu", n), tangent: "KeyR", hall: 0.35,
    gor: stegkortRidaNu };
  const kort = (id, rubrik, text, val, egna) => ({ id, rubrik, text, val: val || [], fler,
    kunskap: hd ? skKunskap(hd) : [],
    rader: [...(egna || []), ridaNuRad].slice(0, 3) });

  const m = Forb.nastaMoment(s, fas.id);
  if (fas.id === "halsa")
    return kort("halsa", tSpr("guide.halsa_rubrik", n), hText(), [knapp()]);
  if (fas.id === "visitera")
    return kort("visitera", tSpr("guide.visitera_rubrik", n), hText(), [knapp()]);
  if (fas.id === "rykta")
    return kort("rykta", tSpr("guide.rykta_rubrik", n), hText(), [knapp()]);
  if (fas.id === "iordning") {
    if (!m.utr)
      return kort("hovar", tSpr("guide.hovar_rubrik"), hText(), [knapp()]);
    const trans = m.utr === SADELFAS.length;
    if (!s.hand[trans ? "trans" : "sadel"])
      return trans
        ? kort("hamta_trans", tSpr("guide.hamta_trans_rubrik"), tSpr("guide.hamta_trans_text"), [],
            [{ id: "tack:trans", text: tSpr("tack.ta_transet"), tangent: "KeyE", hall: 0,
              gor() { s.hand.trans = true; skAterkoppla(""); } }])
        : kort("hamta_sadel", tSpr("guide.hamta_sadel_rubrik"), tSpr("guide.hamta_sadel_text", n), [],
            [{ id: "tack:sadel", text: tSpr("tack.ta_sadeln"), tangent: "KeyE", hall: 0,
              gor() { s.hand.sadel = true; skAterkoppla(""); } }]);
    return kort(trans ? "transa" : "sadla", tSpr(trans ? "guide.transa_rubrik" : "guide.sadla_rubrik"),
      hText(), [knapp()],
      [{ id: trans ? "rad:transa" : "rad:sadla", text: tSpr(trans ? "interaktion.transa_namn" : "interaktion.sadla_namn", n),
        tangent: "KeyF", hall: 0.35, gor() { skHandling(hd.id); } }]);
  }
  if (fas.id === "leda")
    return kort("leda", tSpr("guide.leda_rubrik", n), tSpr("guide.leda_text"), [],
      [{ id: "leda", text: tSpr("led.borja_namn", n), tangent: "KeyL", hall: 0.2,
        gor() { stegkortForberedd(); G.hastPlats = "leds"; VD.spår.length = 0; skAterkoppla(""); } }]);
  return null;
}

/* Tangentens namn i raden och prompten: "R", "L", "F", "E". */
const skTangent = kod => String(kod || "KeyE").replace(/^Key/, "");
/* "[Håll inne R]" för en hållprompt, "[E]" för en omedelbar. */
function skTangentText(r) {
  return r.hall > 0 ? `${tSpr("interaktion.hall_inne")} ${skTangent(r.tangent)}` : skTangent(r.tangent);
}

/* Promptraderna vid boxen — det `interagera()` erbjuder i världen, med
   varsin tangent och hålltid. Frågas SOM OM spelaren stod vid hästen:
   prompten sitter på hästen och `interagera()` avgör räckvidden, precis
   som en ProximityPrompt finns på hästen och visas inom räckhåll.
   Valknapparna (startvalet, hälsningen, momenten) har ingen tangent —
   i Roblox är de knappar i panelen, inte prompter. */
function stegkortRader() {
  const k = stegkortKort(true);
  return k ? [...(k.rader || []), ...(k.varld || [])] : [];
}
function stegkortPrimar() {
  const r = stegkortRader()[0];
  return r ? { text: r.text, gor: r.gor, tangent: r.tangent, hall: r.hall } : null;
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
  #stegkort .skU{margin:-4px -4px 10px;padding:6px 8px 8px;border-radius:6px;background:rgba(255,255,255,.06);
    border-left:3px solid rgb(236,196,92)}
  #stegkort .skUh{display:flex;align-items:center;gap:8px;min-height:32px}
  #stegkort .skUt{flex:1;font-weight:650;font-size:13px;color:rgb(236,196,92);letter-spacing:.01em}
  #stegkort button.skSprak{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:6px;cursor:pointer;
    min-height:32px;padding:4px 8px;border-radius:6px;background:rgba(255,255,255,.07);font-size:12.5px;color:#EDEAE3;width:auto}
  #stegkort button.skSprak:hover,#stegkort button.skSprak:focus-visible{background:rgba(255,255,255,.14)}
  #stegkort .skFl{display:inline-block;width:20px;height:13px;border-radius:2px;flex:none}
  #stegkort .skFl.sv{background:linear-gradient(90deg,transparent 6px,#FECC02 6px,#FECC02 9px,transparent 9px),
    linear-gradient(0deg,transparent 5px,#FECC02 5px,#FECC02 8px,transparent 8px),#006AA7}
  #stegkort .skFl.en{background:linear-gradient(90deg,transparent 8px,#C8102E 8px,#C8102E 12px,transparent 12px),
    linear-gradient(0deg,transparent 5px,#C8102E 5px,#C8102E 8px,transparent 8px),
    linear-gradient(90deg,transparent 7px,#fff 7px,#fff 13px,transparent 13px),
    linear-gradient(0deg,transparent 4px,#fff 4px,#fff 9px,transparent 9px),#012169}
  #stegkort .skUi{margin-top:4px;color:#EDEAE3}
  #stegkort .skR{font-weight:650;font-size:15px;margin:0 0 4px}
  #stegkort .skT{margin:0 0 8px;color:#D6D2C8}
  #stegkort .skV{display:grid;gap:6px}
  #stegkort button{all:unset;box-sizing:border-box;display:block;width:100%;cursor:pointer;padding:8px 10px;
    border-radius:6px;background:rgba(255,255,255,.07);color:#EDEAE3;font:inherit;line-height:1.25;min-height:36px}
  #stegkort button:hover,#stegkort button:focus-visible{background:rgba(255,255,255,.13);outline:none}
  #stegkort button.primar{background:rgb(92,76,38);color:#FFF6E0}
  #stegkort button.primar:hover{background:rgb(112,93,47)}
  #stegkort .skRader{margin-top:6px;display:grid;gap:6px}
  #stegkort button.rad{position:relative;overflow:hidden;display:flex;gap:8px;align-items:center;
    background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.10);touch-action:none;user-select:none}
  #stegkort button.rad .skRt{flex:1;position:relative}
  #stegkort button.rad .skK{position:relative;font-size:12px;color:#BFB8A8;white-space:nowrap}
  #stegkort button.rad .skFyll{position:absolute;left:0;top:0;bottom:0;width:0%;background:rgba(236,196,92,.28)}
  #stegkort .skF{margin-top:6px;font-size:12.5px;color:#BFB8A8}
  #stegkort .skKun{margin:6px 0 0;padding-left:18px;color:#BFB8A8;font-size:12.5px;display:grid;gap:4px}
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
    (k.rader || []).map(r => r.id + r.text).join("|"),
    fler.length, STEGKORT.fler, STEGKORT.kunskap, (k.kunskap || []).length,
    STEGKORT.aterkoppling, typeof SPRAKET !== "undefined" ? SPRAKET : ""].join("§");
  el.hidden = false;
  if (!tvinga && sig === STEGKORT.sig) return;
  STEGKORT.sig = sig;
  const esc = t => String(t).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const val = (k.val || []).slice(0, 4);
  const rader = (k.rader || []).slice(0, 3);
  const kunskap = k.kunskap || [];
  el.dataset.kort = k.id;
  /* UI-2 (docs/P2-UGNETA-INSTRUCTION-CONTRACT.md § 4): Ugneta överst —
     hennes titel, språkflaggan och hennes instruktion. Handlingarna under.
     Samma ordning som Roblox, där hennes yta dockas som panelens första
     block. Kortets instruktion står EN gång, i hennes ruta. */
  const sv = typeof SPRAKET === "undefined" || SPRAKET !== "en";
  el.innerHTML = `<div class="skU"><div class="skUh"><span class="skUt">${esc(tSpr("ugneta.titel"))}</span>`
    + `<button class="skSprak" data-sprak="1" aria-label="${esc(tSpr("sprak.byt"))}" title="${esc(tSpr("sprak.byt"))}">`
    + `<span class="skFl ${sv ? "sv" : "en"}"></span>${esc(tSpr("sprak.nuvarande"))}</button></div>`
    + (k.text ? `<div class="skUi">${esc(k.text)}</div>` : "") + `</div>`
    + `<div class="skR">${esc(k.rubrik)}</div>`
    + (val.length ? `<div class="skV">${val.map((v, i) =>
        `<button data-i="${i}" data-id="${esc(v.id)}" class="${v.primar ? "primar" : ""}">${esc(v.text)}</button>`).join("")}</div>` : "")
    + (rader.length ? `<div class="skRader">${rader.map((r, i) =>
        `<button data-r="${i}" data-id="${esc(r.id)}" class="rad"><span class="skFyll"></span><span class="skRt">${esc(r.text)}</span><span class="skK">[${esc(skTangentText(r))}]</span></button>`).join("")}</div>` : "")
    + (fler.length ? `<div class="skF"><button data-fler="1">+  ${esc(tSpr("panel.fler"))}</button>${
        STEGKORT.fler ? `<div class="skV" style="margin-top:6px">${fler.map((v, i) =>
          `<button data-f="${i}" data-id="${esc(v.id)}">${esc(v.text)}</button>`).join("")}</div>` : ""}</div>` : "")
    /* #273 S2: det frivilliga kunskapslagret. Stängt tills spelaren öppnar det. */
    + (kunskap.length ? `<div class="skF"><button data-kunskap="1">${STEGKORT.kunskap ? "−" : "+"}  ${esc(tSpr("handling.kunskap"))}</button>${
        STEGKORT.kunskap ? `<ul class="skKun">${kunskap.map(t => `<li>${esc(t)}</li>`).join("")}</ul>` : ""}</div>` : "")
    + `<div class="skA">${esc(STEGKORT.aterkoppling)}</div>`;
  for (const b of el.querySelectorAll("button[data-i]"))
    b.onclick = () => { const v = val[+b.dataset.i]; if (v) v.gor(); stegkortRita(true); };
  for (const b of el.querySelectorAll("button[data-f]"))
    b.onclick = () => { const v = fler[+b.dataset.f]; STEGKORT.fler = false; if (v) v.gor(); };
  /* En rad är en prompt: den HÅLLS, som när man trycker på en
     ProximityPrompt i Roblox — pekaren nere lika länge som promptens
     HoldDuration, med en synlig fyllning. Hålltid 0 är ett vanligt klick. */
  for (const b of el.querySelectorAll("button[data-r]")) {
    const r = rader[+b.dataset.r];
    if (!r) continue;
    const fyll = b.querySelector(".skFyll");
    let t0 = 0, raf = 0;
    const slapp = () => { t0 = 0; cancelAnimationFrame(raf); if (fyll) fyll.style.width = "0%"; };
    const steg = () => {
      if (!t0) return;
      const andel = Math.min(1, (performance.now() - t0) / (r.hall * 1000));
      if (fyll) fyll.style.width = (andel * 100).toFixed(0) + "%";
      if (andel >= 1) { slapp(); r.gor(); stegkortRita(true); return; }
      raf = requestAnimationFrame(steg);
    };
    b.onpointerdown = e => {
      e.preventDefault();
      if (!(r.hall > 0)) { r.gor(); stegkortRita(true); return; }
      t0 = performance.now(); raf = requestAnimationFrame(steg);
    };
    b.onpointerup = slapp; b.onpointerleave = slapp; b.onpointercancel = slapp;
    b.onclick = e => e.preventDefault();
  }
  const kb = el.querySelector("button[data-kunskap]");
  if (kb) kb.onclick = () => { STEGKORT.kunskap = !STEGKORT.kunskap; stegkortRita(true); };
  const fb = el.querySelector("button[data-fler]");
  if (fb) fb.onclick = () => { STEGKORT.fler = !STEGKORT.fler; stegkortRita(true); };
  const sb = el.querySelector("button[data-sprak]");
  if (sb) sb.onclick = () => stegkortVaxlaSprak();
}

/* Språkflaggan (UI-2/P2): samma som Roblox `vaxlaSprak` — sv ↔ en, för
   den här sessionen (Roblox sparar inte heller valet; attributet
   UBRFSprak lever tills spelaren går). Utgångsläget är fortfarande
   webbläsarens språk. Allt som ritas med tSpr följer med vid nästa
   ritning; kortet ritas om direkt. */
function stegkortVaxlaSprak() {
  if (typeof window === "undefined") return;
  window.SPRAKET = window.SPRAKET === "en" ? "sv" : "en";
  STEGKORT.aterkoppling = "";
  stegkortRita(true);
}

if (typeof window !== "undefined") {
  window.STEGKORT = STEGKORT;
  window.stegkortKort = stegkortKort;
  window.stegkortVaxlaSprak = stegkortVaxlaSprak;
}
stegkortInstallera();
