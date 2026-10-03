/* RIDVÄGAR: MITTLINJEN OCH DIAGONALEN — port av roblox/src/server/
   VagLektion.luau. Figuren är lektionstypen (`vag_mitt`, `vag_diag`).
   Mittlinjen (0, 6) → (0, 54); diagonalen (−7, 8) → (7, 52), alltså från
   F-sidan (u < 0) till H-sidan (u > 0) — i webbens bana (17, 8) → (3, 52). */
LEKTION_TYPER.vag = (() => {
  const M = LektionMotor;
  const DEADLINE = 120;
  const KORR = 2.0;
  const ZON = 2.0;
  const GROV_M = 4.0;
  const BAKAT_M = 1.0;
  const SLUT_M = 0.5;
  const FIGURER = Object.freeze({
    vag_mitt: Object.freeze({ du0: 0, v0: 6, du1: 0, v1: 54 }),
    vag_diag: Object.freeze({ du0: -7, v0: 8, du1: 7, v1: 52 }),
  });
  const AKTIVA = { to_start: true, route: true };

  function ny(rittId, typ) {
    const figur = typ === "vag_diag" ? "vag_diag" : "vag_mitt";
    return { typ: figur, rittId, lage: "ready", revision: 0, progress: 0, tips: "intro", delmal: 0 };
  }
  function bild(s) {
    return Object.freeze({ typ: s.typ, rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, delmal: s.delmal, resultat: s.resultat,
      referens: s.referens });
  }
  function ryms(plats) {
    const l = M.layout(plats);
    return !!l && l.halvBredd >= 7 + KORR + 1 && l.langd >= 54 + ZON;
  }
  function referens(s, p, plats) {
    const f = FIGURER[s.typ];
    const u0 = p.dressyrMitt.u;
    const a = { u: u0 + f.du0, v: f.v0 }, b = { u: u0 + f.du1, v: f.v1 };
    const L = Math.hypot(b.u - a.u, b.v - a.v);
    return Object.freeze({ ramId: p.ramId, figur: s.typ, u0: a.u, v0: a.v, u1: b.u, v1: b.v, langd: L,
      korr: KORR, ring: ZON, plats });
  }
  function linje(ref, q) {
    const du = (ref.u1 - ref.u0) / ref.langd, dv = (ref.v1 - ref.v0) / ref.langd;
    const x = q.u - ref.u0, y = q.v - ref.v0;
    return [x * du + y * dv, Math.abs(x * dv - y * du)];
  }
  function iKorridor(ref, q) {
    const [sL, e] = linje(ref, q);
    return e <= KORR && sL >= -ZON && sL <= ref.langd + ZON;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, figur: s.typ, meter: s.langst - s.armS,
        armS: s.armS, slutS: s.langst, langd: s.referens.langd, start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function tillStart(s, tips) {
    s.armS = null; s.langst = null; s.sistaPunkt = null;
    M.andra(s, "to_start", tips);
    M.satDelmal(s, 0);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, o, p, logg, plats) {
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    s.sistaInne = p.iDressyr === true;
    if (p.ramId != null && p.dressyrMitt != null && ryms(plats)) { s.ramId = p.ramId; s.referens = referens(s, p, plats); }
    else s.ramId = null;
  }
  function ridTips(s) {
    if (s.langst != null && s.langst >= s.referens.langd - 4) return "to_end";
    return s.typ === "vag_diag" ? "ride_diag" : "ride_mitt";
  }

  function steg(s, X) {
    if (!AKTIVA[s.lage]) return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    if (X.now >= s.deadline) { stang(s, "tidsgrans", X); return; }
    const { o, p, logg, gangart, ryggar } = X;
    const brott = M.brottAntal(o) !== s.sistaBrott;
    const ramFel = p.ramId == null || p.ramId !== s.ramId;
    const lageFel = p.punkt == null || (p.status !== "segment" && p.status !== "baslinje");
    if (brott || ramFel || lageFel || logg.overflode) {
      const redanNollad = s.lage === "to_start" && !brott && s.ramId != null && p.ramId === s.ramId && !logg.overflode;
      nyBaslinje(s, o, p, logg, X.plats);
      if (!redanNollad) tillStart(s, "unknown");
      return;
    }
    if (o.tid === s.sistaT) return;
    const observerad = o.obsTid > s.sistaObs;
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    const varInne = s.sistaInne;
    s.sistaInne = p.iDressyr === true;
    let fel = ryggar === true || (gangart !== "walk" && gangart !== "trot" && gangart !== "halt");
    for (let i = s.loggSett; i < logg.handelser.length; i++) {
      const e = logg.handelser[i];
      if (e.typ === "gangart" && e.data && (e.data.tillRyggar
        || (e.data.till !== "walk" && e.data.till !== "trot" && e.data.till !== "halt"))) fel = true;
    }
    s.loggSett = logg.handelser.length;
    const ref = s.referens;
    const seg = p.status === "segment" && observerad ? p.segment : null;
    if (s.lage === "to_start") {
      if (fel || !seg || !seg.till) return;
      const q = seg.till;
      const [sL] = linje(ref, q);
      const iRing = Math.hypot(q.u - ref.u0, q.v - ref.v0) <= ZON;
      if (iRing && iKorridor(ref, q) && sL <= ZON && p.iDressyr === true) {
        s.armS = sL; s.langst = sL;
        s.sistaPunkt = { u: q.u, v: q.v };
        M.andra(s, "route", ridTips(s));
        M.satDelmal(s, 1);
      }
      return;
    }
    if (fel) { tillStart(s, "walk_or_trot"); return; }
    if (!seg || !seg.fran || !seg.till) { tillStart(s, "unknown"); return; }
    const fr = seg.fran, ti = seg.till;
    const sp = s.sistaPunkt;
    if (!sp || Math.hypot(sp.u - fr.u, sp.v - fr.v) > 0.05) { tillStart(s, "unknown"); return; }
    if (Math.hypot(ti.u - fr.u, ti.v - fr.v) > GROV_M) { tillStart(s, "unknown"); return; }
    if (!(iKorridor(ref, fr) && iKorridor(ref, ti) && varInne && p.iDressyr === true)) { tillStart(s, "off_route"); return; }
    const [sL] = linje(ref, ti);
    if (sL < s.langst - BAKAT_M) { tillStart(s, "reverse"); return; }
    if ((gangart === "walk" || gangart === "trot") && sL > s.langst) s.langst = Math.min(sL, ref.langd);
    s.sistaPunkt = { u: ti.u, v: ti.v };
    M.andra(s, "route", ridTips(s));
    const fran = Math.max(s.armS, 0);
    M.satProgress(s, 99 * Math.max(s.langst - fran, 0) / (ref.langd - fran));
    const iSlut = Math.hypot(ti.u - ref.u1, ti.v - ref.v1) <= ZON;
    if (s.langst >= ref.langd - SLUT_M && iSlut) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null && ryms(X.plats) ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null;
    nyBaslinje(s, X.o, X.p, X.logg, X.plats);
    s.progress = 0; s.delmal = 0;
    s.armS = null; s.langst = null; s.sistaPunkt = null;
    s.revision++;
    M.andra(s, "to_start", "to_start");
  }

  return { OVNING: "ridvag", VERSION: "server-vag-1", DEADLINE, AKTIVA, FIGURER,
    GRANSER: Object.freeze({ KORR, ZON, GROV_M, BAKAT_M, SLUT_M, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
