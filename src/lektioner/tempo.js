/* JÄMN FART I SKRITT — port av roblox/src/server/TempoLektion.luau.
   Jämn OBSERVERAD fart i skritt, inom dressyrlayouten. Samma band,
   samma spridning, samma provkrav och samma coachningshändelser. */
LEKTION_TYPER.tempo = (() => {
  const M = LektionMotor;
  const DEADLINE = 120;
  const MPS = 1;
  const GOLV = 0.90;
  const TAK = 2.20;
  const SPRIDNING = 0.25;
  const MIN_PROV = 30;
  const MIN_TID = 8.0;
  const MIN_M = 10.0;
  const AKTIVA = { steady: true };
  const pos = x => typeof x === "number" && isFinite(x) && x > 0;
  const ickeNeg = x => typeof x === "number" && isFinite(x) && x >= 0;

  function ny(rittId) {
    return { typ: "tempo", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro",
      coachNr: 0, coachSkal: null, forraKlar: null, jamforelse: null };
  }
  function bild(s) {
    const j = s.jamforelse;
    return Object.freeze({ typ: "tempo", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat,
      coachNr: s.coachNr || 0, coachSkal: s.coachSkal,
      jamforelse: s.lage === "complete" && j && j.forsokId === s.forsokId ? j : null });
  }
  function tomSerie(s) { s.prov = 0; s.sek = 0; s.meter = 0; s.summa = 0; s.minFart = Infinity; s.maxFart = -Infinity; }
  function omSerie(s, tips) { s.coachSkal = null; tomSerie(s); M.andra(s, "steady", tips); M.satProgress(s, 0); }
  function coach(s, skal) { s.coachNr = (s.coachNr || 0) + 1; s.coachSkal = skal; s.revision++; }
  function nyBaslinje(s, o, p, logg) {
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaSeg = M.segmentAntal(o);
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    s.ramId = p.ramId;
    s.sistaInne = p.iDressyr === true;
    s.hoppa = true;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      const medel = s.summa / s.prov;
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, ovning: "jamn_skritt",
        prov: s.prov, sekunder: s.sek, meter: s.meter, medelFart: medel,
        spridning: (s.maxFart - s.minFart) / medel, enhet: "m/s", start: s.forsok.start });
      const nyR = s.resultat, forra = s.forraKlar;
      s.jamforelse = null;
      if (forra && forra.forsokId !== nyR.forsokId && forra.rittId === nyR.rittId && forra.ovning === nyR.ovning
        && ickeNeg(forra.spridning) && ickeNeg(nyR.spridning) && pos(forra.medelFart) && pos(nyR.medelFart)) {
        s.jamforelse = Object.freeze({ forsokId: nyR.forsokId, forraForsokId: forra.forsokId,
          forraSpridning: forra.spridning, spridning: nyR.spridning });
      }
      if (ickeNeg(nyR.spridning) && pos(nyR.medelFart)) s.forraKlar = nyR;
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }

  function steg(s, X) {
    if (s.lage !== "steady") return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    if (X.now >= s.deadline) { stang(s, "tidsgrans", X); return; }
    const { o, p, logg, gangart, ryggar } = X;
    const brott = M.brottAntal(o) !== s.sistaBrott;
    const ramFel = p.ramId == null || p.ramId !== s.ramId;
    const lageFel = p.punkt == null || (p.status !== "segment" && p.status !== "baslinje");
    if (brott || ramFel || lageFel || logg.overflode) {
      const hadeKredit = s.prov > 0;
      nyBaslinje(s, o, p, logg);
      if (hadeKredit || brott || ramFel || logg.overflode) omSerie(s, "unknown");
      return;
    }
    if (o.tid === s.sistaT) return;
    const dt = o.tid - s.sistaT;
    const meter = (o.distans - s.sistaD) / MPS;
    const nyaSeg = M.segmentAntal(o) - s.sistaSeg;
    const varInne = s.sistaInne;
    let nyaHandelser = false;
    for (let i = s.loggSett; i < logg.handelser.length; i++) if (logg.handelser[i].typ === "gangart") nyaHandelser = true;
    const hoppa = s.hoppa;
    s.sistaT = o.tid; s.sistaD = o.distans; s.sistaSeg = M.segmentAntal(o);
    s.loggSett = logg.handelser.length;
    s.sistaInne = p.iDressyr === true;
    s.hoppa = false;
    if (ryggar === true || gangart !== "walk") {
      omSerie(s, gangart === "halt" && ryggar !== true ? "walk_on" : "walk_only");
      return;
    }
    if (!(varInne && p.iDressyr === true)) { omSerie(s, "stay_inside"); return; }
    if (hoppa) return;
    if (nyaHandelser) { omSerie(s, "walk_on"); return; }
    const f = o.fonster;
    const sist = Array.isArray(f) ? f[f.length - 1] : null;
    if (nyaSeg !== 1 || !sist || sist.t !== o.tid || sist.gangart !== "walk" || sist.ryggar || !(dt > 0)) {
      omSerie(s, "unknown"); return;
    }
    const fart = meter / dt;
    if (fart < GOLV) { omSerie(s, "too_slow"); coach(s, "too_slow"); return; }
    if (fart > TAK) { omSerie(s, "too_fast"); coach(s, "too_fast"); return; }
    const lo = Math.min(s.minFart, fart), hi = Math.max(s.maxFart, fart);
    const medel = (s.summa + fart) / (s.prov + 1);
    if (s.prov > 0 && (hi - lo) / medel > SPRIDNING) {
      tomSerie(s);
      s.prov = 1; s.sek = dt; s.meter = meter; s.summa = fart; s.minFart = fart; s.maxFart = fart;
      M.andra(s, "steady", "steadier");
      coach(s, "steadier");
    } else {
      s.prov++; s.sek += dt; s.meter += meter; s.summa += fart; s.minFart = lo; s.maxFart = hi;
      s.coachSkal = null;
      M.andra(s, "steady", "keep_going");
    }
    M.satProgress(s, 99 * Math.min(s.prov / MIN_PROV, s.sek / MIN_TID, s.meter / MIN_M, 1));
    if (s.prov >= MIN_PROV && s.sek >= MIN_TID && s.meter >= MIN_M) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.iDressyr === true && p.ramId != null ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null;
    s.coachNr = 0; s.coachSkal = null; s.jamforelse = null;
    nyBaslinje(s, X.o, X.p, X.logg);
    tomSerie(s);
    s.progress = 0;
    s.revision++;
    M.andra(s, "steady", "walk_on");
  }

  return { OVNING: "jamn_skritt", VERSION: "server-tempo-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ GOLV, TAK, SPRIDNING, MIN_PROV, MIN_TID, MIN_M, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
