/* SERPENTINLEKTIONEN — port av roblox/src/server/SerpentinLektion.luau.
   Tre halvcirkelbågar (R = 8 m) som växlar sida, från startringen på
   mittlinjen nära A till slutringen nära C, två korsningar däremellan. */
LEKTION_TYPER.serpentin = (() => {
  const M = LektionMotor;
  const DEADLINE = 240;
  const R = 8.0;
  const V0 = 6.0;
  const SIDOR = [1, -1, 1];
  const BAGE = Math.PI * R;
  const LANGD = 3 * BAGE;
  const KORR = 2.5;
  const RING = 3.0;
  const STEG_M = 0.5;
  const GROV_M = 4.0;
  const TVETYDIG_M = 3.0;
  const BAKAT_M = 1.5;
  const KORS_R = 3.5;
  const KORS_SLACK = 1.0;
  const SLUT_M = 0.5;
  const AKTIVA = { to_start: true, route: true };

  function ny(rittId) {
    return { typ: "serpentin", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro", delmal: 0 };
  }
  function bild(s) {
    return Object.freeze({ typ: "serpentin", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, delmal: s.delmal, resultat: s.resultat,
      referens: s.referens });
  }
  function ryms(plats) {
    const l = M.layout(plats);
    return !!l && l.halvBredd >= R + 1 && l.langd >= V0 + 6 * R + RING;
  }
  function referens(p, plats) {
    return Object.freeze({ ramId: p.ramId, u: p.dressyrMitt.u, v0: V0, r: R, korr: KORR, ring: RING,
      sidor: Object.freeze(SIDOR.slice()), plats });
  }
  const korsV = k => V0 + 2 * R * k;
  function projicera(u0, u, v) {
    let minS = Infinity, maxS = -Infinity, basta = null, bastaD = Infinity;
    for (let k = 1; k <= 3; k++) {
      const c = V0 + R + (k - 1) * 2 * R;
      const side = SIDOR[k - 1];
      const du = u - u0, dv = v - c;
      let S, d;
      if (side * du >= 0) {
        const r = Math.sqrt(du * du + dv * dv);
        const th = Math.max(0, Math.min(Math.PI, Math.atan2(Math.abs(du), -dv)));
        S = (k - 1) * BAGE + th * R;
        d = Math.abs(r - R);
      } else {
        const d1 = Math.sqrt(du * du + (dv + R) * (dv + R));
        const d2 = Math.sqrt(du * du + (dv - R) * (dv - R));
        if (d1 <= d2) { S = (k - 1) * BAGE; d = d1; } else { S = k * BAGE; d = d2; }
      }
      if (d <= KORR) {
        minS = Math.min(minS, S); maxS = Math.max(maxS, S);
        if (d < bastaD) { basta = S; bastaD = d; }
      }
    }
    if (basta == null) return [null, false];
    return [basta, maxS - minS > TVETYDIG_M];
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, rutt: "serpentin-3", meter: s.front,
        korsningar: Object.freeze(s.korsningar.slice()), start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.satDelmal(s, 4);
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function tillStart(s, tips) {
    s.front = 0; s.sistaS = null; s.sistaPunkt = null;
    s.korsningar = [];
    M.andra(s, "to_start", tips);
    M.satDelmal(s, 0);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, o, p, logg, plats) {
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    if (p.ramId != null && p.dressyrMitt != null && ryms(plats)) { s.ramId = p.ramId; s.referens = referens(p, plats); }
    else s.ramId = null;
  }
  function delmalFor(s) {
    const k = Math.min(3, Math.floor(s.front / BAGE) + 1);
    return Math.min(k, s.korsningar.length + 1);
  }
  function vagTips(s) {
    if (s.front >= LANGD - 4) return "to_end";
    const k = delmalFor(s);
    return k === 1 ? "loop1" : k === 2 ? "loop2" : "loop3";
  }
  function paVagen(s, seg, kredit) {
    const u0 = s.referens.u;
    const fu = seg.fran.u, fv = seg.fran.v, tu = seg.till.u, tv = seg.till.v;
    const langd = Math.hypot(tu - fu, tv - fv);
    if (langd > GROV_M) { tillStart(s, "unknown"); return false; }
    const n = Math.max(1, Math.ceil(langd / STEG_M));
    let fore = s.sistaPunkt || { u: fu, v: fv };
    if (Math.hypot(fore.u - fu, fore.v - fv) > 0.05) { tillStart(s, "unknown"); return false; }
    for (let i = 0; i <= n; i++) {
      const u = i === n ? tu : fu + (tu - fu) * i / n;
      const v = i === n ? tv : fv + (tv - fv) * i / n;
      const [S, tvetydig] = projicera(u0, u, v);
      if (S == null) { tillStart(s, "off_route"); return false; }
      if (tvetydig) { tillStart(s, "unknown"); return false; }
      const d = Math.hypot(u - fore.u, v - fore.v);
      if (s.sistaS != null && Math.abs(S - s.sistaS) > 1.6 * d + 0.3) { tillStart(s, "unknown"); return false; }
      if (S < s.front - BAKAT_M) { tillStart(s, "reverse"); return false; }
      const nasta = s.korsningar.length + 1;
      if (nasta <= 2) {
        const kv = korsV(nasta);
        const nara = q => Math.hypot(q.u - u0, q.v - kv) <= KORS_R;
        const punkt = { u, v };
        if ((fore.u - u0) * (u - u0) <= 0 && nara(fore) && nara(punkt)
          && s.front >= nasta * BAGE - KORS_SLACK - BAKAT_M) {
          s.korsningar.push(Object.freeze({ u, v }));
        }
      }
      if (kredit && S > s.front) {
        const tak = s.korsningar.length < 2 ? (s.korsningar.length + 1) * BAGE + KORS_SLACK : LANGD;
        s.front = Math.min(S, tak);
      }
      s.sistaS = S; fore = { u, v };
    }
    s.sistaPunkt = fore;
    return true;
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
    let fel = ryggar === true || (gangart !== "walk" && gangart !== "trot" && gangart !== "halt");
    for (let i = s.loggSett; i < logg.handelser.length; i++) {
      const e = logg.handelser[i];
      if (e.typ === "gangart" && e.data && (e.data.tillRyggar
        || (e.data.till !== "walk" && e.data.till !== "trot" && e.data.till !== "halt"))) fel = true;
    }
    s.loggSett = logg.handelser.length;
    const seg = p.status === "segment" && observerad ? p.segment : null;
    if (s.lage === "to_start") {
      if (fel || !seg || !seg.till) return;
      const u0 = s.referens.u;
      const q = seg.till;
      const [S, tvetydig] = projicera(u0, q.u, q.v);
      const iRing = Math.hypot(q.u - u0, q.v - V0) <= RING;
      if (iRing && S != null && !tvetydig && S <= RING) {
        s.front = Math.max(S, 0); s.sistaS = S;
        s.sistaPunkt = { u: q.u, v: q.v };
        s.korsningar = [];
        M.andra(s, "route", "loop1");
        M.satDelmal(s, 1);
      }
      return;
    }
    if (fel) { tillStart(s, "walk_or_trot"); return; }
    if (!seg || !seg.fran || !seg.till) { tillStart(s, "unknown"); return; }
    if (!paVagen(s, seg, gangart === "walk" || gangart === "trot")) return;
    const tips = vagTips(s);
    M.satDelmal(s, tips === "to_end" ? 4 : delmalFor(s));
    M.andra(s, "route", tips);
    M.satProgress(s, 99 * s.front / LANGD);
    const q = seg.till;
    const iSlut = Math.hypot(q.u - s.referens.u, q.v - korsV(3)) <= RING;
    if (s.front >= LANGD - SLUT_M && s.korsningar.length >= 2 && iSlut) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null && ryms(X.plats) ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null;
    nyBaslinje(s, X.o, X.p, X.logg, X.plats);
    s.progress = 0; s.delmal = 0;
    s.front = 0; s.sistaS = null; s.sistaPunkt = null; s.korsningar = [];
    s.revision++;
    M.andra(s, "to_start", "to_start");
  }

  return { OVNING: "serpentin", VERSION: "server-serpentin-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ R, V0, LANGD, KORR, RING, STEG_M, GROV_M, TVETYDIG_M, BAKAT_M,
      KORS_R, KORS_SLACK, SLUT_M, DEADLINE }),
    ny, bild, steg, platsFel, starta, _projicera: projicera };
})();
