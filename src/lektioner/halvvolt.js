/* HALVVOLT TILLBAKA TILL SPÅRET — port av roblox/src/server/
   HalvvoltLektion.luau. Spåret längs +u-långsidan (K–E–H-sidan, webbens
   x = 1,5) mot C, en halvvolt på 10 m in mot mitten och tillbaka till
   spåret mot A. Samma korridor, skarvar, haltankare och tal. */
LEKTION_TYPER.halvvolt = (() => {
  const M = LektionMotor;
  const DEADLINE = 150;
  const SPAR_DU = 8.5;
  const P0_V = 16, T1_V = 26;
  const R = 5;
  const E_V = 8;
  const L1 = T1_V - P0_V;
  const L2 = Math.PI * R;
  const L3 = Math.sqrt((2 * R) ** 2 + (T1_V - E_V) ** 2);
  const LANGD = L1 + L2 + L3;
  const KORR = 1.5;
  const RING = 2.0;
  const STEG_M = 0.5;
  const GROV_M = 4.0;
  const TVETYDIG_M = 3.0;
  const BAKAT_M = 1.0;
  const SKARV_R = 1.5;
  const SKARV_SLACK = 1.0;
  const SLUT_M = 0.5;
  const HALT_R = 0.5;
  const AKTIVA = { to_start: true, route: true };
  const klamp = M.klamp;

  function ny(rittId) {
    return { typ: "halvvolt", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro", delmal: 0 };
  }
  function bild(s) {
    return Object.freeze({ typ: "halvvolt", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, delmal: s.delmal, resultat: s.resultat,
      referens: s.referens });
  }
  function ryms(plats) {
    const l = M.layout(plats);
    return !!l && l.halvBredd >= SPAR_DU + KORR && l.langd >= T1_V + R + RING;
  }
  function referens(p, plats) {
    const uT = p.dressyrMitt.u + SPAR_DU;
    return Object.freeze({ ramId: p.ramId, uT, p0v: P0_V, t1v: T1_V, r: R, ev: E_V, korr: KORR, ring: RING,
      langd: LANGD, plats });
  }
  function rak(au, av, bu, bv, smin, u, v) {
    const lx = bu - au, ly = bv - av;
    const L = Math.sqrt(lx * lx + ly * ly);
    const dx = lx / L, dy = ly / L;
    const s = klamp((u - au) * dx + (v - av) * dy, smin, L);
    const pu = au + dx * s, pv = av + dy * s;
    return [s, Math.hypot(u - pu, v - pv)];
  }
  function projicera(ref, u, v) {
    const uT = ref.uT;
    let minS = Infinity, maxS = -Infinity, basta = null, bastaD = Infinity;
    const kandidat = (S, d) => {
      if (d <= KORR) {
        minS = Math.min(minS, S); maxS = Math.max(maxS, S);
        if (d < bastaD) { basta = S; bastaD = d; }
      }
    };
    const [s1, d1] = rak(uT, P0_V, uT, T1_V, -RING, u, v);
    kandidat(s1, d1);
    const cu = uT - R, cv = T1_V;
    const du = u - cu, dv = v - cv;
    if (dv >= 0) {
      const th = klamp(Math.atan2(Math.abs(dv), du), 0, Math.PI);
      kandidat(L1 + th * R, Math.abs(Math.sqrt(du * du + dv * dv) - R));
    } else {
      const dT = Math.hypot(u - uT, v - T1_V);
      const dH = Math.hypot(u - (uT - 2 * R), v - T1_V);
      if (dT <= dH) kandidat(L1, dT); else kandidat(L1 + L2, dH);
    }
    const [s3, d3] = rak(uT - 2 * R, T1_V, uT, E_V, 0, u, v);
    kandidat(L1 + L2 + s3, d3);
    if (basta == null) return [null, false];
    return [basta, maxS - minS > TVETYDIG_M];
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, figur: "halvvolt", armS: s.armS,
        slutS: s.framst, meter: s.kreditM, skuld: (s.framst - s.armS) - s.kreditM, langd: LANGD,
        skarvar: Object.freeze(s.skarvar.slice()), start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function tillStart(s, tips) {
    s.armS = null; s.framst = null; s.kreditM = 0; s.sistaS = null; s.sistaPunkt = null; s.haltAnkare = null;
    s.skarvar = [];
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
  const delFor = S => S < L1 ? 1 : S < L1 + L2 ? 2 : 3;
  function vagTips(s) {
    if (s.framst >= LANGD - 4) return "to_end";
    const d = delFor(s.framst);
    return d === 1 ? "track" : d === 2 ? "half_circle" : "return";
  }
  function paVagen(s, seg, kredit) {
    const ref = s.referens;
    const fu = seg.fran.u, fv = seg.fran.v, tu = seg.till.u, tv = seg.till.v;
    const langd = Math.hypot(tu - fu, tv - fv);
    if (langd > GROV_M) { tillStart(s, "unknown"); return false; }
    let fore = s.sistaPunkt;
    if (!fore || Math.hypot(fore.u - fu, fore.v - fv) > 0.05) { tillStart(s, "unknown"); return false; }
    if (!kredit) {
      const a = s.haltAnkare || { u: fu, v: fv };
      s.haltAnkare = a;
      if (Math.hypot(tu - a.u, tv - a.v) > HALT_R) { tillStart(s, "halt_moved"); return false; }
    } else s.haltAnkare = null;
    const n = Math.max(1, Math.ceil(langd / STEG_M));
    const skarvPunkter = [{ u: ref.uT, v: T1_V, S: L1 }, { u: ref.uT - 2 * R, v: T1_V, S: L1 + L2 }];
    for (let i = 0; i <= n; i++) {
      const u = i === n ? tu : fu + (tu - fu) * i / n;
      const v = i === n ? tv : fv + (tv - fv) * i / n;
      const [S, tvetydig] = projicera(ref, u, v);
      if (S == null) { tillStart(s, "off_route"); return false; }
      if (tvetydig) { tillStart(s, "unknown"); return false; }
      const d = Math.hypot(u - fore.u, v - fore.v);
      if (s.sistaS != null && Math.abs(S - s.sistaS) > 1.6 * d + 0.3) { tillStart(s, "unknown"); return false; }
      if (S < s.framst - BAKAT_M) { tillStart(s, "reverse"); return false; }
      const nasta = skarvPunkter[s.skarvar.length];
      if (kredit && nasta && Math.hypot(u - nasta.u, v - nasta.v) <= SKARV_R) s.skarvar.push(Object.freeze({ u, v }));
      const tak = s.skarvar.length < 2 ? skarvPunkter[s.skarvar.length].S + SKARV_SLACK : LANGD;
      const nyS = Math.min(S, tak);
      if (nyS > s.framst) {
        if (kredit) s.kreditM += nyS - s.framst;
        s.framst = nyS;
        if ((s.framst - s.armS) - s.kreditM > HALT_R) { tillStart(s, "halt_moved"); return false; }
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
      const [S, tvetydig] = projicera(ref, q.u, q.v);
      const iRing = Math.hypot(q.u - ref.uT, q.v - P0_V) <= RING;
      if (iRing && S != null && !tvetydig && S >= -RING && S <= RING && p.iDressyr === true) {
        s.armS = S; s.framst = S; s.kreditM = 0; s.sistaS = S; s.haltAnkare = null;
        s.sistaPunkt = { u: q.u, v: q.v };
        s.skarvar = [];
        M.andra(s, "route", "track");
        M.satDelmal(s, 1);
      }
      return;
    }
    if (fel) { tillStart(s, "walk_or_trot"); return; }
    if (!seg || !seg.fran || !seg.till) { tillStart(s, "unknown"); return; }
    if (!(varInne && p.iDressyr === true)) { tillStart(s, "off_route"); return; }
    if (!paVagen(s, seg, gangart === "walk" || gangart === "trot")) return;
    const tips = vagTips(s);
    M.andra(s, "route", tips);
    M.satDelmal(s, tips === "to_end" ? 4 : delFor(s.framst));
    const fran = Math.max(s.armS, 0);
    M.satProgress(s, 99 * Math.max(s.framst - fran, 0) / (LANGD - fran));
    const q = seg.till;
    const iSlut = Math.hypot(q.u - ref.uT, q.v - E_V) <= RING;
    if (s.framst >= LANGD - SLUT_M && s.skarvar.length >= 2 && iSlut) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    return p && p.punkt && p.dressyrMitt && p.iDressyr === true && p.ramId != null && ryms(X.plats) ? null : "place";
  }
  function starta(s, X) {
    s.resultat = null;
    nyBaslinje(s, X.o, X.p, X.logg, X.plats);
    s.progress = 0; s.delmal = 0;
    s.armS = null; s.framst = null; s.kreditM = 0; s.sistaS = null; s.sistaPunkt = null; s.skarvar = [];
    s.revision++;
    M.andra(s, "to_start", "to_start");
  }

  return { OVNING: "halvvolt", VERSION: "server-halvvolt-1", DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ SPAR_DU, P0_V, T1_V, R, E_V, L1, L2, L3, LANGD, KORR, RING, STEG_M, GROV_M,
      TVETYDIG_M, BAKAT_M, SKARV_R, SKARV_SLACK, SLUT_M, HALT_R, DEADLINE }),
    ny, bild, steg, platsFel, starta, _projicera: projicera };
})();
