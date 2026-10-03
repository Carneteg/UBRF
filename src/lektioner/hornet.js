/* GENOM HÖRNET — port av roblox/src/server/HornLektion.luau.
   Inridning längs spåret (+u-sidan, 1,5 m innanför kanten), en kvartsvolt
   med R = 5 i hörnet vid C-änden och utridning längs kortsidan. I webbens
   bana ligger hörnet vid H (x = 0, y = 60). */
LEKTION_TYPER.hornet = (() => {
  const M = LektionMotor;
  const DEADLINE = 120;
  const T = 1.5;
  const R = 5.0;
  const IN_M = 10.0;
  const UT_M = 6.0;
  const KORR = 1.2;
  const ZON = 2.0;
  const MITT = 1.0;
  const GROV_M = 4.0;
  const BAKAT_M = 1.0;
  const SLUT_M = 0.5;
  const AKTIVA = { to_start: true, route: true };
  const BAGE = R * Math.PI / 2;

  function ny(rittId) {
    return { typ: "hornet", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro", delmal: 0 };
  }
  function bild(s) {
    return Object.freeze({ typ: "hornet", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, delmal: s.delmal, resultat: s.resultat,
      referens: s.referens });
  }
  function matt(plats) {
    if (!plats || !plats.dressyr) return [null, null];
    const spm = plats.studsPerMeter;
    if (typeof spm !== "number" || spm <= 0) return [null, null];
    return [plats.dressyr.halvTvars / spm, 2 * plats.dressyr.halvLangs / spm];
  }
  function ryms(plats) {
    const [W, L] = matt(plats);
    if (W == null || L == null) return false;
    return 2 * W >= R + T + UT_M + 2 * KORR + 1 && L >= T + R + IN_M + ZON;
  }
  function referens(p, plats) {
    const [W, L] = matt(plats);
    const uT = p.dressyrMitt.u + W - T;
    const cu = uT - R, cv = L - T - R;
    return Object.freeze({ ramId: p.ramId, figur: "hornet", uT, cu, cv, r: R,
      p0u: uT, p0v: cv - IN_M, p3u: cu - UT_M, p3v: cv + R,
      nyckel: `hornet|${uT.toFixed(6)}|${cu.toFixed(6)}|${cv.toFixed(6)}|${R.toFixed(6)}`,
      mu: cu + R * Math.cos(Math.PI / 4), mv: cv + R * Math.sin(Math.PI / 4),
      inM: IN_M, utM: UT_M, langd: IN_M + BAGE + UT_M, korr: KORR, ring: ZON, mitt: MITT, plats });
  }
  function projektion(ref, q) {
    const tA = q.v - ref.p0v;
    let sA, eA;
    if (tA <= 0) { sA = tA; eA = Math.abs(q.u - ref.uT); }
    else if (tA >= ref.inM) { sA = ref.inM; eA = Math.hypot(q.u - ref.uT, q.v - ref.cv); }
    else { sA = tA; eA = Math.abs(q.u - ref.uT); }
    let th = Math.atan2(q.v - ref.cv, q.u - ref.cu);
    th = M.klamp(th, 0, Math.PI / 2);
    const bu = ref.cu + ref.r * Math.cos(th), bv = ref.cv + ref.r * Math.sin(th);
    const sB = ref.inM + ref.r * th, eB = Math.hypot(q.u - bu, q.v - bv);
    const tC = ref.cu - q.u;
    let sC, eC;
    if (tC <= 0) { sC = ref.inM + BAGE; eC = Math.hypot(q.u - ref.cu, q.v - ref.p3v); }
    else { sC = ref.inM + BAGE + tC; eC = Math.abs(q.v - ref.p3v); }
    if (eA <= eB && eA <= eC) return [sA, eA];
    if (eB <= eC) return [sB, eB];
    return [sC, eC];
  }
  function iKorridor(ref, q) {
    const [sL, e] = projektion(ref, q);
    return e <= KORR && sL >= -ZON && sL <= ref.langd + ZON;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, figur: "hornet",
        meter: s.langst - Math.max(s.armS, 0), armS: s.armS, slutS: s.langst, langd: s.referens.langd,
        mitt: s.mittNadd === true, radie: R, start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function tillStart(s, tips) {
    s.armS = null; s.langst = null; s.sistaPunkt = null; s.mittNadd = null;
    M.andra(s, "to_start", tips);
    M.satDelmal(s, 0);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, o, p, logg, plats) {
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    s.sistaInne = p.iDressyr === true;
    if (p.ramId != null && p.dressyrMitt != null && ryms(plats)) { s.ramId = p.ramId; s.referens = referens(p, plats); }
    else s.ramId = null;
  }
  function delFor(s) {
    const l = s.langst || 0;
    if (l < IN_M) return 1;
    if (l < IN_M + BAGE) return 2;
    return 3;
  }
  function ridTips(s) { const d = delFor(s); return d === 1 ? "ride_in" : d === 2 ? "bend" : "ride_out"; }

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
      const [sL] = projektion(ref, q);
      const iRing = Math.hypot(q.u - ref.p0u, q.v - ref.p0v) <= ZON;
      if (iRing && iKorridor(ref, q) && sL <= ZON && p.iDressyr === true) {
        s.armS = sL; s.langst = sL;
        s.mittNadd = false;
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
    const mid = { u: (fr.u + ti.u) / 2, v: (fr.v + ti.v) / 2 };
    if (!(iKorridor(ref, fr) && iKorridor(ref, mid) && iKorridor(ref, ti) && varInne && p.iDressyr === true)) {
      tillStart(s, "off_route"); return;
    }
    const [sL] = projektion(ref, ti);
    if (sL < s.langst - BAKAT_M) { tillStart(s, "reverse"); return; }
    if ((gangart === "walk" || gangart === "trot") && sL > s.langst) s.langst = Math.min(sL, ref.langd);
    if (!s.mittNadd && s.langst >= IN_M && (gangart === "walk" || gangart === "trot")) {
      for (const q of [mid, ti]) if (Math.hypot(q.u - ref.mu, q.v - ref.mv) <= MITT) s.mittNadd = true;
    }
    s.sistaPunkt = { u: ti.u, v: ti.v };
    M.andra(s, "route", ridTips(s));
    M.satDelmal(s, delFor(s));
    const fran = Math.max(s.armS, 0);
    M.satProgress(s, 99 * Math.max(s.langst - fran, 0) / (ref.langd - fran));
    const iSlut = Math.hypot(ti.u - ref.p3u, ti.v - ref.p3v) <= ZON;
    if (s.mittNadd && s.langst >= ref.langd - SLUT_M && iSlut) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null && ryms(X.plats) ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null;
    nyBaslinje(s, X.o, X.p, X.logg, X.plats);
    s.progress = 0; s.delmal = 0;
    s.armS = null; s.langst = null; s.sistaPunkt = null; s.mittNadd = null;
    s.revision++;
    M.andra(s, "to_start", "to_start");
  }

  return { OVNING: "genom_hornet", VERSION: "server-horn-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ T, R, IN_M, UT_M, KORR, ZON, MITT, GROV_M, BAKAT_M, SLUT_M, DEADLINE }),
    ny, bild, steg, platsFel, starta, _projektion: projektion, _referens: referens };
})();
