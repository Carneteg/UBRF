/* GALOPPFATTNINGEN — port av roblox/src/server/GaloppLektion.luau.
   Trav minst TRAV_M, galopp på spelarens hjälp inne i galoppringen (30 m
   från A på mittlinjen), sedan galopp GALOPP_M. Galoppsidan bedöms inte. */
LEKTION_TYPER.galopp = (() => {
  const M = LektionMotor;
  const DEADLINE = 150;
  const MPS = 1;
  const RING_V = 30;
  const ZON_R = 3.0;
  const TRAV_M = 8.0;
  const GALOPP_M = 6.0;
  const AKTIVA = { trot: true, canter: true };

  function ny(rittId) {
    return { typ: "galopp", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro" };
  }
  function bild(s) {
    return Object.freeze({ typ: "galopp", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens,
      malSida: s.lage === "trot" && s.tips === "canter_outside" && s.malForsok != null
        && s.malForsok === s.forsokId ? s.malSida : null });
  }
  function ryms(plats) {
    const l = M.layout(plats);
    return !!l && l.halvBredd >= ZON_R + 1 && l.langd >= RING_V + GALOPP_M;
  }
  function referens(p, plats) {
    return Object.freeze({ ramId: p.ramId, u: p.dressyrMitt.u, v: RING_V, radie: ZON_R, plats });
  }
  function tillTrav(s, tips, sida) {
    s.trav = 0; s.galopp = 0;
    s.malSida = sida || null;
    s.malForsok = sida ? s.forsokId : null;
    M.andra(s, "trot", tips);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, o, p, logg, plats) {
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.sistaSeg = M.segmentAntal(o);
    s.loggSett = logg.handelser.length;
    s.sistaInne = p.iDressyr === true;
    if (p.ramId != null && p.dressyrMitt != null && ryms(plats)) { s.ramId = p.ramId; s.referens = referens(p, plats); }
    else s.ramId = null;
  }
  function iRingen(s, p) {
    const seg = p.segment;
    if (!seg || !seg.fran || !seg.till || !s.referens) return false;
    const inne = q => Math.hypot(q.u - s.referens.u, q.v - RING_V) <= ZON_R;
    return inne(seg.fran) && inne(seg.till);
  }
  function malSida(s, p) {
    const seg = p.segment;
    if (!seg || !seg.fran || !seg.till || !s.referens) return null;
    const dv = seg.till.v - seg.fran.v;
    if (!(dv === dv) || dv === 0) return null;
    const riktning = dv > 0 ? 1 : -1;
    let fore = true, efter = true;
    for (const q of [seg.fran, seg.till]) {
      if (!(Math.abs(q.u - s.referens.u) <= ZON_R)) return null;
      const d = (q.v - RING_V) * riktning;
      if (!(d < -ZON_R)) fore = false;
      if (!(d > ZON_R)) efter = false;
    }
    return fore ? "fore" : efter ? "efter" : null;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, ovning: "galoppfattning", mal: "galoppring",
        vidRingen: s.vidRingen, travMeter: s.travVid, galoppMeter: s.galopp, galoppsida: "ej_bedomd", start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function overgang(s, p, d) {
    const hjalp = d.orsak === "hjalp" && !d.tillRyggar && !d.franRyggar;
    if (s.lage === "trot") {
      if (d.till === "canter" && d.fran === "trot" && hjalp) {
        if (s.trav < TRAV_M) { tillTrav(s, "trot_first"); return false; }
        if (!iRingen(s, p)) { tillTrav(s, "canter_outside", malSida(s, p)); return false; }
        s.vidRingen = Object.freeze({ u: p.segment.till.u, v: p.segment.till.v });
        s.travVid = s.trav; s.galopp = 0;
        M.andra(s, "canter", "canter_on");
        return true;
      } else if (d.fran === "trot") { tillTrav(s, "trot_on"); return false; }
      return true;
    }
    tillTrav(s, d.orsak === "trotthet" ? "tired" : "canter_longer");
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
      const redanNollad = s.lage === "trot" && s.trav === 0 && !brott && s.ramId != null
        && p.ramId === s.ramId && !logg.overflode;
      nyBaslinje(s, o, p, logg, X.plats);
      if (!redanNollad) tillTrav(s, "unknown");
      return;
    }
    if (o.tid === s.sistaT) return;
    const observerad = o.obsTid > s.sistaObs;
    const meter = (o.distans - s.sistaD) / MPS;
    const nyaSeg = M.segmentAntal(o) - s.sistaSeg;
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaObs = o.obsTid; s.sistaSeg = M.segmentAntal(o);
    const varInne = s.sistaInne;
    s.sistaInne = p.iDressyr === true;
    if (logg.handelser.length > s.loggSett) {
      const giltigt = p.status === "segment" && !!p.segment && observerad && nyaSeg === 1;
      for (let i = s.loggSett; i < logg.handelser.length; i++) {
        const e = logg.handelser[i];
        if (e.typ === "gangart" && e.data) {
          if (!giltigt) { s.loggSett = logg.handelser.length; tillTrav(s, "unknown"); return; }
          if (!overgang(s, p, e.data)) break;
        }
      }
      s.loggSett = logg.handelser.length;
      return;
    }
    if (!observerad || ryggar || !(varInne && p.iDressyr === true)) return;
    if (s.lage === "trot") {
      if (gangart === "trot") s.trav += meter;
      let tips = s.tips;
      if (s.trav >= TRAV_M) tips = "canter_at_k";
      else if (gangart === "trot" && meter > 0) tips = "trot_on";
      M.andra(s, "trot", tips);
      M.satProgress(s, 50 * Math.min(s.trav / TRAV_M, 1));
    } else if (s.lage === "canter") {
      if (gangart === "canter") s.galopp += meter;
      M.satProgress(s, 60 + 39 * Math.min(s.galopp / GALOPP_M, 1));
      if (s.galopp >= GALOPP_M) stang(s, "slutford", X);
    }
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null && ryms(X.plats) ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null; s.vidRingen = null; s.travVid = null;
    nyBaslinje(s, X.o, X.p, X.logg, X.plats);
    s.trav = 0; s.galopp = 0;
    s.malSida = null; s.malForsok = null;
    s.progress = 0;
    s.revision++;
    M.andra(s, "trot", "trot_on");
  }

  return { OVNING: "galoppfattning", VERSION: "server-galopp-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ RING_V, ZON_R, TRAV_M, GALOPP_M, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
