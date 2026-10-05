/* VOLTLEKTIONEN — port av roblox/src/server/VoltObservation.luau och
   roblox/src/server/VoltLektion.luau (P3 § 6). Samma referens (20 m-
   volten runt dressyrlayoutens mitt, radie RidKanon.UGNETA.KVALITET.
   VOLT_RADIE = 10), samma avsnitt, samma nollställningar, samma tal. */

/* ── VOLTOBSERVATIONEN (VoltObservation.luau) ── */
const VoltObs = (() => {
  const OVNING = "storvolt";
  const VERSION = "server-referens-1";
  const RADIE = 10;
  const R_MIN = 1.0;
  const MIN_TID = 1.0;
  const MIN_SEGMENT = 4;
  const MIN_STRACKA = 2.0;
  const TOL_VARV = 1e-6;
  const MAX_AVSNITT = 8;
  const andligt = x => typeof x === "number" && isFinite(x);

  function ny(rittId) {
    return { rittId, oppen: true, pagar: null, avslutade: [], nr: 0, bild: null, sistaIn: null,
      sistaT: null, baslinje: false };
  }

  function sammanfatta(a) {
    const skal = [];
    let underlag = "tillrackligt";
    if (a.obestamt) { underlag = "okant"; skal.push("for_nara_centrum"); }
    else if (a.tid < MIN_TID || a.segment < MIN_SEGMENT) { underlag = "otillrackligt"; skal.push("for_kort"); }
    else if (a.stracka < MIN_STRACKA) { underlag = "otillrackligt"; skal.push("for_lite_rorelse"); }
    const ok = underlag === "tillrackligt";
    const riktning = a.netto > 0 ? "positiv" : a.netto < 0 ? "negativ" : "ingen";
    const motriktning = a.netto >= 0 ? a.negativ : a.positiv;
    const varv = Math.floor((Math.abs(a.netto) + TOL_VARV) / (2 * Math.PI));
    return Object.freeze({
      nr: a.nr, ramId: a.ramId, referens: Object.freeze({ u: a.cu, v: a.cv, radie: RADIE }),
      tid: a.tid, stracka: a.stracka, segment: a.segment, obestamda: a.obestamda,
      medelAvvikelse: ok ? a.viktAbs / a.stracka : null,
      rmsAvvikelse: ok ? Math.sqrt(a.viktKvad / a.stracka) : null,
      maxAvvikelse: ok ? a.maxAvvikelse : null,
      netto: ok ? a.netto : null, riktning: ok ? riktning : null,
      motriktning: ok ? motriktning : null, varv: ok ? varv : null,
      aterkomst: ok ? Math.hypot(a.sistU - a.startU, a.sistV - a.startV) : null,
      underlag, skal: Object.freeze(skal), status: a.slut ? "avslutat" : "pagar", slut: a.slut || null,
    });
  }

  function avsluta(r, skal) {
    const a = r.pagar;
    if (!a) return;
    a.slut = skal;
    r.avslutade.push(a);
    while (r.avslutade.length > MAX_AVSNITT) r.avslutade.shift();
    r.pagar = null;
  }

  function bygg(r, status) {
    r.bild = Object.freeze({ ovning: OVNING, version: VERSION, rittId: r.rittId, status,
      pagar: r.pagar ? sammanfatta(r.pagar) : null,
      avslutade: Object.freeze(r.avslutade.map(sammanfatta)) });
  }

  function sampla(r, plats) {
    if (!r || !r.oppen || !plats || typeof plats !== "object") return false;
    if (plats === r.sistaIn) return false;
    r.sistaIn = plats;
    const tFore = r.sistaT;
    r.sistaT = andligt(plats.t) ? plats.t : null;
    if (r.baslinje) { r.baslinje = false; bygg(r, "lektions_baslinje"); return true; }
    const seg = plats.segment, mitt = plats.dressyrMitt, ramId = plats.ramId;
    if (plats.status !== "segment" || !seg || !mitt || typeof ramId !== "number") {
      const st = String(plats.status || "okant");
      avsluta(r, typeof plats.skal === "string" ? st + ":" + plats.skal : st);
      bygg(r, st);
      return true;
    }
    const cu = mitt.u, cv = mitt.v;
    let a = r.pagar;
    if (a && (a.ramId !== ramId || a.cu !== cu || a.cv !== cv)) { avsluta(r, "ram_eller_referens_bytt"); a = null; }
    const fu = seg.fran.u, fv = seg.fran.v, tu = seg.till.u, tv = seg.till.v;
    if (![fu, fv, tu, tv, cu, cv].every(andligt)) { avsluta(r, "ogiltigt_segment"); bygg(r, "ogiltigt_segment"); return true; }
    const du = tu - fu, dv = tv - fv;
    const langd = Math.sqrt(du * du + dv * dv);
    const au = fu - cu, avc = fv - cv, bu = tu - cu, bvc = tv - cv;
    let narmast = Math.min(Math.hypot(au, avc), Math.hypot(bu, bvc));
    if (langd > 0) {
      const k = Math.max(0, Math.min(1, -(au * du + avc * dv) / (langd * langd)));
      narmast = Math.min(narmast, Math.hypot(au + du * k, avc + dv * k));
    }
    const obestamt = narmast < R_MIN;
    if (a && a.obestamt !== obestamt) { avsluta(r, obestamt ? "obestamd_vinkel" : "vinkel_bestamd_igen"); a = null; }
    if (!a) {
      r.nr++;
      a = { nr: r.nr, ramId, cu, cv, tid: 0, stracka: 0, segment: 0, obestamda: 0, obestamt,
        viktAbs: 0, viktKvad: 0, maxAvvikelse: 0, netto: 0, positiv: 0, negativ: 0,
        startU: fu, startV: fv, sistU: fu, sistV: fv, slut: null };
      r.pagar = a;
    }
    if (tFore != null && r.sistaT != null && r.sistaT > tFore) a.tid += r.sistaT - tFore;
    a.segment++;
    a.stracka += langd;
    const mu = (fu + tu) / 2 - cu, mv = (fv + tv) / 2 - cv;
    const avv = Math.abs(Math.hypot(mu, mv) - RADIE);
    a.viktAbs += avv * langd;
    a.viktKvad += avv * avv * langd;
    if (avv > a.maxAvvikelse) a.maxAvvikelse = avv;
    if (obestamt) a.obestamda++;
    const d = Math.atan2(au * bvc - avc * bu, au * bu + avc * bvc);
    a.netto += d;
    if (d > 0) a.positiv += d; else a.negativ -= d;
    a.sistU = tu; a.sistV = tv;
    bygg(r, "segment");
    return true;
  }

  function lektionsGrans(r) {
    if (!r || !r.oppen) return null;
    avsluta(r, "lektions_grans");
    r.baslinje = true;
    bygg(r, "lektions_grans");
    return r.nr;
  }

  function stang(r) { if (r && r.oppen) { avsluta(r, "ritten_slut"); r.oppen = false; bygg(r, "stangd"); } }
  function ogonblick(r) { return r ? r.bild : null; }

  return { OVNING, VERSION, RADIE, R_MIN, MIN_TID, MIN_SEGMENT, MIN_STRACKA, ny, sampla,
    lektionsGrans, stang, ogonblick };
})();

/* ── VOLTLEKTIONEN (VoltLektion.luau) ── */
LEKTION_TYPER.volt = (() => {
  const M = LektionMotor;
  const DEADLINE = 120;
  const AKTIVA = { approach: true, baseline: true, riding: true };
  const andligtIckeNeg = x => typeof x === "number" && isFinite(x) && x >= 0;
  const andligtPositivt = x => andligtIckeNeg(x) && x > 0;

  function ny(rittId) {
    return { typ: "volt", rittId, lage: "ready", revision: 0, progress: 0, tips: "approach",
      forraKlar: null, jamforelse: null };
  }
  function bild(s) {
    const j = s.jamforelse;
    return Object.freeze({ typ: "volt", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens,
      jamforelse: s.lage === "complete" && j && j.forsokId === s.forsokId ? j : null,
      linjeSida: s.lage === "approach" && s.tips === "line" && s.linjeForsok != null
        && s.linjeForsok === s.forsokId ? s.linjeSida : null });
  }
  function jamforbar(s, a) {
    if (!a || !a.referens) return null;
    if (!(andligtIckeNeg(a.medelAvvikelse) && andligtPositivt(a.referens.radie))) return null;
    return { forsokId: s.forsokId, rittId: s.rittId, version: VoltObs.VERSION, radie: a.referens.radie,
      avvikelse: a.medelAvvikelse };
  }
  function referens(s, p) {
    return Object.freeze({ ramId: p.ramId, u: p.dressyrMitt.u, v: p.dressyrMitt.v, radie: VoltObs.RADIE,
      plats: LektionObs.PLATS });
  }
  function stang(s, orsak, a, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, armAfter: s.armAfter,
        start: s.forsok.start, avsnitt: a });
      const nyJ = jamforbar(s, a), forra = s.forraKlar;
      s.jamforelse = null;
      if (nyJ && forra && forra.forsokId !== nyJ.forsokId && forra.rittId === nyJ.rittId
        && forra.version === nyJ.version && forra.radie === nyJ.radie) {
        s.jamforelse = Object.freeze({ forsokId: nyJ.forsokId, forraForsokId: forra.forsokId,
          forraAvvikelse: forra.avvikelse, avvikelse: nyJ.avvikelse });
      }
      if (nyJ) s.forraKlar = Object.freeze(nyJ);
      s.progress = 100;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else {
      M.andra(s, "timeout", "timeout");
    }
    return true;
  }
  function punkt(p) {
    return !!p && p.iDressyr === true && p.punkt != null && p.dressyrMitt != null && p.ramId != null
      && (p.status === "segment" || p.status === "baslinje");
  }
  function radieFel(p) { return Math.hypot(p.punkt.u - p.dressyrMitt.u, p.punkt.v - p.dressyrMitt.v) - VoltObs.RADIE; }
  function avvikelse(p) { return Math.abs(radieFel(p)); }
  function disarm(s, X, tips, sida) {
    VoltObs.lektionsGrans(X.volt);
    s.armAfter = null; s.avsnitt = null; s.progress = 0;
    s.linjeSida = sida || null;
    s.linjeForsok = sida ? s.forsokId : null;
    M.andra(s, "approach", tips);
  }

  function steg(s, X) {
    if (!AKTIVA[s.lage]) return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    if (X.now >= s.deadline) { stang(s, "tidsgrans", null, X); return; }
    const p = X.p;
    if (p === s.sistaP) return;
    s.sistaP = p;
    const v = VoltObs.ogonblick(X.volt);
    if (!v || v.version !== VoltObs.VERSION) { disarm(s, X, "unknown"); return; }
    if (s.lage === "approach") {
      if (punkt(p) && avvikelse(p) <= 2) {
        s.armAfter = VoltObs.lektionsGrans(X.volt);
        if (s.armAfter == null) return;
        s.referens = referens(s, p);
        s.avsnitt = null;
        s.linjeSida = null; s.linjeForsok = null;
        M.andra(s, "baseline", "ride");
      }
      return;
    }
    const r = s.referens;
    if (!punkt(p) || p.ramId !== r.ramId || p.dressyrMitt.u !== r.u || p.dressyrMitt.v !== r.v) {
      disarm(s, X, "unknown"); return;
    }
    if (avvikelse(p) > 4) { disarm(s, X, "line", radieFel(p) > 0 ? "ut" : "in"); return; }
    if (s.lage === "baseline") {
      if (v.status !== "lektions_baslinje") { disarm(s, X, "unknown"); return; }
      M.andra(s, "riding", "ride");
      return;
    }
    const a = v.pagar;
    if (!a || a.nr <= Math.max(s.armAfter, s.forsok.start.voltHogsta)
      || a.ramId !== r.ramId || a.referens.u !== r.u || a.referens.v !== r.v
      || a.referens.radie !== r.radie || a.underlag === "okant"
      || (s.avsnitt != null && s.avsnitt !== a.nr)) { disarm(s, X, "unknown"); return; }
    s.avsnitt = a.nr;
    if (a.underlag !== "tillrackligt") return;
    if (a.maxAvvikelse > 4 || a.motriktning > Math.PI / 4) { disarm(s, X, "line"); return; }
    if (a.varv >= 1) {
      if (a.medelAvvikelse <= 2 && a.aterkomst <= 3) stang(s, "slutford", a, X);
      else disarm(s, X, "line");
      return;
    }
    const progress = Math.max(0, Math.min(90, Math.floor(Math.abs(a.netto) / (2 * Math.PI) * 10) * 10));
    if (progress !== s.progress) { s.progress = progress; s.revision++; }
  }

  function platsFel(s, X) { return punkt(X.p) ? null : "place"; }
  function starta(s, X) {
    const p = X.p;
    s.startP = p; s.sistaP = p; s.armAfter = null; s.avsnitt = null; s.resultat = null;
    s.jamforelse = null; s.linjeSida = null; s.linjeForsok = null;
    s.referens = referens(s, p);
    s.progress = 0;
    M.andra(s, "approach", "approach");
  }

  return { OVNING: "storvolt", VERSION: VoltObs.VERSION, DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ DEADLINE, ZON: 2, NOLL: 4, MEDEL: 2, ATERKOMST: 3 }),
    ny, bild, steg, platsFel, starta };
})();
