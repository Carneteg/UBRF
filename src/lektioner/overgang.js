/* ÖVERGÅNGSLEKTIONEN — port av roblox/src/server/OvergangLektion.luau.
   Skritt → trav vid T1 → trav → skritt vid T2 → skritt. En övergång
   räknas bara om BÅDA ändpunkterna i stegets segment ligger i målzonen. */
LEKTION_TYPER.overgang = (() => {
  const M = LektionMotor;
  const DEADLINE = 180;
  const MPS = 1;
  const T1_V = 18, T2_V = 42;
  const ZON_HALV = 3.0;
  const SKRITT_FORE = 3.0;
  const TRAV_M = 6.0;
  const SKRITT_EFTER = 2.0;
  const AKTIVA = { walk1: true, trot: true, walk2: true };

  function ny(rittId) {
    return { typ: "overgang", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro" };
  }
  function bild(s) {
    return Object.freeze({ typ: "overgang", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens,
      malSida: s.lage === "walk1" && (s.tips === "trot_outside" || s.tips === "walk_outside")
        && s.malForsok != null && s.malForsok === s.forsokId ? s.malSida : null });
  }
  function referens(p) {
    return Object.freeze({ ramId: p.ramId, u: p.dressyrMitt.u, v1: T1_V, v2: T2_V, halv: ZON_HALV,
      plats: LektionObs.PLATS });
  }
  function tillSkritt(s, tips, sida) {
    s.skritt1 = 0; s.trav = 0; s.skritt2 = 0;
    s.malSida = sida || null;
    s.malForsok = sida ? s.forsokId : null;
    M.andra(s, "walk1", tips);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, o, p, logg) {
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    if (p.ramId != null && p.dressyrMitt != null) { s.ramId = p.ramId; s.referens = referens(p); }
    else s.ramId = null;
  }
  function iMal(s, p, malV) {
    const seg = p.segment;
    if (!seg || !seg.fran || !seg.till || !s.referens) return false;
    const inne = q => Math.abs(q.u - s.referens.u) <= ZON_HALV && Math.abs(q.v - malV) <= ZON_HALV;
    return inne(seg.fran) && inne(seg.till);
  }
  function malSida(s, p, malV) {
    const seg = p.segment;
    if (!seg || !seg.fran || !seg.till || !s.referens) return null;
    const dv = seg.till.v - seg.fran.v;
    if (!(dv === dv) || dv === 0) return null;
    const riktning = dv > 0 ? 1 : -1;
    let fore = true, efter = true;
    for (const q of [seg.fran, seg.till]) {
      if (!(Math.abs(q.u - s.referens.u) <= ZON_HALV)) return null;
      const d = (q.v - malV) * riktning;
      if (!(d < -ZON_HALV)) fore = false;
      if (!(d > ZON_HALV)) efter = false;
    }
    return fore ? "fore" : efter ? "efter" : null;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, mal: "T1->T2", travMeter: s.trav,
        skrittMeter: s.skritt2, vidT1: s.vidT1, vidT2: s.vidT2, start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function overgang(s, p, d) {
    const hjalp = d.orsak === "hjalp" && !d.tillRyggar && !d.franRyggar;
    if (s.lage === "walk1") {
      if (d.till === "trot" && hjalp && d.fran === "walk" && s.skritt1 >= SKRITT_FORE && iMal(s, p, T1_V)) {
        s.vidT1 = Object.freeze({ u: p.segment.till.u, v: p.segment.till.v });
        s.trav = 0;
        M.andra(s, "trot", "trot_on");
        return true;
      } else if (d.till === "trot") {
        if (s.skritt1 < SKRITT_FORE) tillSkritt(s, "walk_first");
        else tillSkritt(s, "trot_outside", malSida(s, p, T1_V));
        return false;
      } else if (d.till !== "walk" || d.tillRyggar) {
        tillSkritt(s, "walk_only");
        return false;
      }
      return true;
    } else if (s.lage === "trot") {
      if (d.till === "walk" && hjalp && d.fran === "trot" && s.trav >= TRAV_M && iMal(s, p, T2_V)) {
        s.vidT2 = Object.freeze({ u: p.segment.till.u, v: p.segment.till.v });
        s.skritt2 = 0;
        M.andra(s, "walk2", "walk_calm");
        return true;
      } else if (d.till === "walk" && d.orsak === "trotthet") {
        tillSkritt(s, "tired"); return false;
      } else if (d.till === "walk") {
        if (s.trav < TRAV_M) tillSkritt(s, "trot_longer");
        else tillSkritt(s, "walk_outside", malSida(s, p, T2_V));
        return false;
      }
      tillSkritt(s, "trot_only");
      return false;
    }
    tillSkritt(s, "walk_only");
    return false;
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
      const redanNollad = s.lage === "walk1" && s.skritt1 === 0 && !brott && s.ramId != null
        && p.ramId === s.ramId && !logg.overflode;
      nyBaslinje(s, o, p, logg);
      if (!redanNollad) tillSkritt(s, "unknown");
      return;
    }
    if (o.tid === s.sistaT) return;
    const observerad = o.obsTid > s.sistaObs;
    const meter = (o.distans - s.sistaD) / MPS;
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid;
    if (logg.handelser.length > s.loggSett) {
      const giltigt = p.status === "segment" && !!p.segment;
      for (let i = s.loggSett; i < logg.handelser.length; i++) {
        const e = logg.handelser[i];
        if (e.typ === "gangart" && e.data) {
          if (!giltigt) { s.loggSett = logg.handelser.length; tillSkritt(s, "unknown"); return; }
          if (!overgang(s, p, e.data)) break;
        }
      }
      s.loggSett = logg.handelser.length;
      return;
    }
    if (!observerad || ryggar) return;
    if (s.lage === "walk1") {
      if (gangart === "walk") s.skritt1 += meter;
      let tips = s.tips;
      if (s.skritt1 >= SKRITT_FORE) tips = "trot_at_t1";
      else if (gangart === "walk" && meter > 0) tips = "walk_on";
      M.andra(s, "walk1", tips);
      M.satProgress(s, 20 * Math.min(s.skritt1 / SKRITT_FORE, 1));
    } else if (s.lage === "trot") {
      if (gangart === "trot") s.trav += meter;
      if (s.trav >= TRAV_M) M.andra(s, "trot", "walk_at_t2");
      M.satProgress(s, 25 + 45 * Math.min(s.trav / TRAV_M, 1));
    } else if (s.lage === "walk2") {
      if (gangart === "walk") s.skritt2 += meter;
      M.satProgress(s, 75 + 25 * Math.min(s.skritt2 / SKRITT_EFTER, 1));
      if (s.skritt2 >= SKRITT_EFTER) stang(s, "slutford", X);
    }
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null; s.vidT1 = null; s.vidT2 = null;
    nyBaslinje(s, X.o, X.p, X.logg);
    s.skritt1 = 0; s.trav = 0; s.skritt2 = 0;
    s.malSida = null; s.malForsok = null;
    s.progress = 0;
    M.andra(s, "walk1", "walk_on");
  }

  return { OVNING: "overgangar", VERSION: "server-overgang-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ T1_V, T2_V, ZON_HALV, SKRITT_FORE, TRAV_M, SKRITT_EFTER, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
