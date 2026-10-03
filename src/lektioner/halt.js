/* START/HALT-LEKTIONEN — port av roblox/src/server/HaltLektion.luau.
   Halt, skritt på spelarens hjälp, halt vid X. Samma tal och tips. */
LEKTION_TYPER.halt = (() => {
  const M = LektionMotor;
  const DEADLINE = 120;
  const MPS = 1; // webbens ritt mäts redan i meter (Roblox: 3 studs per meter)
  const ZON_R = 1.5;
  const STILLA_M = 0.15;
  const HALT_FORE = 1.0;
  const SKRITT_M = 4.0;
  const HALT_EFTER = 2.0;
  const AKTIVA = { halt1: true, walk: true };
  const andligt = M.andligt;

  function ny(rittId) {
    return { typ: "halt", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro",
      forraKlar: null, jamforelse: null };
  }
  function bild(s) {
    return Object.freeze({ typ: "halt", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens,
      jamforelse: s.lage === "complete" && s.jamforelse && s.jamforelse.forsokId === s.forsokId
        ? s.jamforelse : null });
  }
  function jamforbar(s) {
    const sp = s.slutpunkt, r = s.referens;
    if (!sp || !r || !(andligt(sp.u) && andligt(sp.v) && andligt(r.u) && andligt(r.v))) return null;
    const avstand = Math.hypot(sp.u - r.u, sp.v - r.v);
    if (!andligt(avstand)) return null;
    return { forsokId: s.forsokId, rittId: s.rittId, version: "server-halt-1", ramId: r.ramId,
      u: r.u, v: r.v, avstand };
  }
  function referens(p) {
    return Object.freeze({ ramId: p.ramId, u: p.dressyrMitt.u, v: p.dressyrMitt.v, radie: ZON_R,
      plats: LektionObs.PLATS });
  }
  function nyBaslinje(s, o, p, logg) {
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    if (p.ramId != null && p.dressyrMitt != null) { s.ramId = p.ramId; s.referens = referens(p); }
    else s.ramId = null;
    s.stilla1 = 0; s.haltTid = 0; s.skritt = 0;
    s.harSkritt = false; s.haltHjalp = false; s.okant = false;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, mal: "X", zonRadie: ZON_R,
        skrittMeter: s.skritt, haltSekunder: s.haltTid, slutpunkt: s.slutpunkt, start: s.forsok.start });
      const nyJ = jamforbar(s), forra = s.forraKlar;
      s.jamforelse = null;
      if (nyJ && forra && forra.forsokId !== nyJ.forsokId && forra.rittId === nyJ.rittId
        && forra.version === nyJ.version && forra.ramId != null && forra.ramId === nyJ.ramId
        && forra.u === nyJ.u && forra.v === nyJ.v) {
        s.jamforelse = Object.freeze({ forsokId: nyJ.forsokId, forraForsokId: forra.forsokId,
          forraAvvikelse: forra.avstand, avvikelse: nyJ.avstand });
      }
      if (nyJ) s.forraKlar = Object.freeze(nyJ);
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function lasOvergangar(s, logg) {
    for (let i = s.loggSett; i < logg.handelser.length; i++) {
      const e = logg.handelser[i], d = e.data;
      if (e.typ === "gangart" && d) {
        if (d.till === "walk" && !d.tillRyggar) s.harSkritt = d.orsak === "hjalp";
        else if (d.till === "halt" && !d.tillRyggar) s.haltHjalp = d.orsak === "hjalp";
        else { s.harSkritt = false; s.haltHjalp = false; s.skritt = 0; }
      }
    }
    s.loggSett = logg.handelser.length;
    if (logg.overflode) s.okant = true;
  }

  function steg(s, X) {
    if (!AKTIVA[s.lage]) return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    if (X.now >= s.deadline) { stang(s, "tidsgrans", X); return; }
    const { o, p, logg, gangart, ryggar } = X;
    const brott = M.brottAntal(o) !== s.sistaBrott;
    const ramFel = p.ramId == null || p.ramId !== s.ramId;
    const lageFel = p.punkt == null || (p.status !== "segment" && p.status !== "baslinje");
    if (brott || ramFel || lageFel) {
      const redanNollad = s.lage === "halt1" && s.stilla1 === 0 && !brott && s.ramId != null && p.ramId === s.ramId;
      nyBaslinje(s, o, p, logg);
      if (!redanNollad) { M.andra(s, "halt1", "unknown"); M.satProgress(s, 0); }
      return;
    }
    if (o.tid === s.sistaT) return;
    lasOvergangar(s, logg);
    const dt = o.tid - s.sistaT;
    const observerad = o.obsTid > s.sistaObs;
    const meter = (o.distans - s.sistaD) / MPS;
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid;
    const platsOk = p.punkt != null && p.ramId === s.ramId && (p.status === "segment" || p.status === "baslinje");
    const halt = gangart === "halt" && !ryggar;
    const stilla = observerad && platsOk && halt && meter <= STILLA_M;
    let iZon = false;
    if (platsOk) iZon = Math.hypot(p.punkt.u - s.referens.u, p.punkt.v - s.referens.v) <= ZON_R;

    if (s.lage === "halt1") {
      s.stilla1 = stilla ? s.stilla1 + dt : 0;
      M.satProgress(s, 15 * Math.min(s.stilla1 / HALT_FORE, 1));
      M.andra(s, "halt1", s.okant ? "unknown" : "halt_first");
      if (s.stilla1 >= HALT_FORE && !s.okant) {
        s.harSkritt = false; s.haltHjalp = false; s.skritt = 0;
        M.andra(s, "walk", "walk_on");
      }
      return;
    }
    if (observerad && gangart === "walk" && !ryggar && s.harSkritt) s.skritt += meter;
    if (s.okant) { s.haltTid = 0; M.andra(s, "walk", "unknown"); }
    else if (ryggar || (gangart !== "walk" && gangart !== "halt")) { s.haltTid = 0; M.andra(s, "walk", "walk_only"); }
    else if (s.skritt < SKRITT_M) { s.haltTid = 0; M.andra(s, "walk", s.harSkritt ? "to_x" : "walk_on"); }
    else if (halt && s.haltHjalp && stilla && iZon) {
      s.haltTid += dt;
      s.slutpunkt = Object.freeze({ u: p.punkt.u, v: p.punkt.v });
      M.andra(s, "walk", "hold");
    } else if (halt && platsOk && !iZon) { s.haltTid = 0; M.andra(s, "walk", "halt_outside"); }
    else { s.haltTid = 0; M.andra(s, "walk", "halt_at_x"); }
    M.satProgress(s, 15 + 45 * Math.min(s.skritt / SKRITT_M, 1) + 40 * Math.min(s.haltTid / HALT_EFTER, 1));
    if (s.haltTid >= HALT_EFTER) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null; s.slutpunkt = null; s.progress = 0; s.jamforelse = null;
    nyBaslinje(s, X.o, X.p, X.logg);
    M.andra(s, "halt1", "halt_first");
  }

  return { OVNING: "starthalt", VERSION: "server-halt-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ ZON_R, STILLA_M, HALT_FORE, SKRITT_M, HALT_EFTER, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
