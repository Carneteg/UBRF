/* BOM PÅ MARKEN I SKRITT — port av roblox/src/server/MarkbomLektion.luau.
   Inridning i skritt, en OBSERVERAD passage av den befintliga markbommens
   plan (`ridhus_hinder_rod_50`, src/site.js) mot C, och en kort bit
   skritt efteråt. Samma korridor, armering, färskhet och tal. */
LEKTION_TYPER.markbom = (() => {
  const M = LektionMotor;
  const HINDER_ID = "ridhus_hinder_rod_50";
  const DEADLINE = 150;
  const SIDA_EXTRA = 0.5;
  const DJUP = 10;
  const INRIDNING_M = 4.0;
  const INRIDNING_SLUT = -0.5;
  const UTRIDNING_M = 1.0;
  const BAKAT_M = 1.0;
  const MARK_TOPP = 0.25;
  const AKTIVA = { approach: true, crossing: true, exit: true };

  function ny(rittId) {
    return { typ: "markbom", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro" };
  }
  function bild(s) {
    return Object.freeze({ typ: "markbom", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens });
  }
  /* Bommens geometri i ramen ur registrets FAKTISKA post för just detta id. */
  function bomGeometri(plats, hs) {
    if (!plats) return null;
    const h = hs && hs.reg && hs.reg.hinder[HINDER_ID];
    if (!h || h.flyttad) return null;
    if (h.topp > MARK_TOPP) return null;
    /* W: normalen mot C (+v). */
    const mot = h.nv >= 0 ? 1 : -1;
    return Object.freeze({ u: h.u, v: h.v, au: h.au, av: h.av, wu: h.nu * mot, wv: h.nv * mot, bredd: h.bredd,
      riktning: mot > 0 ? "fram" : "bak", generation: h.generation,
      nyckel: `${h.generation}|${h.u}|${h.v}|${h.bredd}|${h.topp}` });
  }
  function lokal(g, q) {
    const du = q.u - g.u, dv = q.v - g.v;
    return [du * g.au + dv * g.av, du * g.wu + dv * g.wv];
  }
  const iKorridor = (g, a, w) => Math.abs(a) <= g.bredd / 2 + SIDA_EXTRA && w >= -DJUP && w <= DJUP;
  function hogstaNr(hsBild) {
    let n = 0;
    for (const f of (hsBild && hsBild.forsok) || []) if (f.hinderId === HINDER_ID && f.nr > n) n = f.nr;
    return n;
  }
  function stang(s, orsak, X) {
    if (!M.aktiv(s)) return false;
    if (!M.slutfor(s, orsak, X)) return false;
    if (orsak === "slutford") {
      s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, ovning: "markbom", hinderId: HINDER_ID,
        generation: s.geo.generation, riktning: s.geo.riktning, hinderForsokNr: s.passageNr,
        inridningM: s.inridning, utridningM: s.utridning, passage: "rotplan", kontakt: "otillganglig",
        rivning: false, start: s.forsok.start });
      s.progress = 100;
      s.revision++;
      M.andra(s, "complete", "complete");
      if (typeof s.vidKlar === "function") s.vidKlar(s);
    } else M.andra(s, "timeout", "timeout");
    return true;
  }
  function tillInridning(s, tips) {
    s.armerad = false; s.frontW = null; s.inridning = 0; s.utridning = 0;
    s.passageNr = null; s.passageW = null;
    M.andra(s, "approach", tips);
    M.satProgress(s, 0);
  }
  function nyBaslinje(s, X) {
    const { o, p, logg } = X;
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    s.loggSett = logg.handelser.length;
    const geo = bomGeometri(X.plats, X.hinder);
    const fore = s.referens ? s.referens.nyckel : null;
    if (p.ramId != null && geo) {
      s.ramId = p.ramId; s.geo = geo;
      s.referens = Object.freeze({ ramId: p.ramId, nyckel: geo.nyckel, u: geo.u, v: geo.v, au: geo.au, av: geo.av,
        wu: geo.wu, wv: geo.wv, bredd: geo.bredd, sida: SIDA_EXTRA, djup: DJUP, plats: X.plats });
    } else { s.ramId = null; s.geo = null; s.referens = null; }
    const efter = s.referens ? s.referens.nyckel : null;
    if (efter !== fore) s.revision++;
  }

  function steg(s, X) {
    if (!AKTIVA[s.lage]) return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    if (X.now >= s.deadline) { stang(s, "tidsgrans", X); return; }
    const { o, p, logg, gangart, ryggar } = X;
    const hs = HinderObs.ogonblick(X.hinder);
    if (!hs) return;
    const geoNu = bomGeometri(X.plats, X.hinder);
    const brott = M.brottAntal(o) !== s.sistaBrott;
    const ramFel = p.ramId == null || p.ramId !== s.ramId;
    const lageFel = p.punkt == null || (p.status !== "segment" && p.status !== "baslinje");
    const bomFel = geoNu == null || s.geo == null || geoNu.nyckel !== s.geo.nyckel;
    if (brott || ramFel || lageFel || logg.overflode || hs.overflode || bomFel) {
      const redanNollad = s.lage === "approach" && !s.armerad && !brott && !bomFel && s.ramId != null
        && p.ramId === s.ramId && !logg.overflode && !hs.overflode;
      nyBaslinje(s, X);
      if (!redanNollad) tillInridning(s, geoNu == null ? "pole_missing" : "unknown");
      return;
    }
    if (o.tid === s.sistaT) return;
    const observerad = o.obsTid > s.sistaObs;
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    const handelser = logg.handelser.length > s.loggSett;
    s.loggSett = logg.handelser.length;
    const g = s.geo;
    const seg = p.status === "segment" && observerad ? p.segment : null;
    const skritt = gangart === "walk" && ryggar !== true && !handelser;
    if (!seg || !seg.fran || !seg.till) { if (s.armerad) tillInridning(s, "unknown"); return; }
    const [a0, w0] = lokal(g, seg.fran);
    const [a1, w1] = lokal(g, seg.till);
    const inne = iKorridor(g, a0, w0) && iKorridor(g, a1, w1);
    if (s.armerad && !skritt) {
      tillInridning(s, gangart === "halt" && ryggar !== true ? "walk_on" : "walk_only"); return;
    }
    if (s.armerad && !inne) { tillInridning(s, "off_line"); return; }
    if (s.armerad && w1 < s.frontW - BAKAT_M) { tillInridning(s, "reverse"); return; }
    if (s.lage === "approach") {
      if (!s.armerad) {
        if (skritt && inne && w1 < INRIDNING_SLUT) {
          s.armerad = true; s.frontW = w1; s.inridning = 0; s.utridning = 0;
          s.nrBas = hogstaNr(hs); s.tBas = o.tid;
          M.andra(s, "approach", "walk_to_pole");
        }
        return;
      }
      const tak = Math.min(w1, INRIDNING_SLUT);
      if (tak > s.frontW) { s.inridning += tak - s.frontW; s.frontW = tak; }
      if (w1 > s.frontW) s.frontW = w1;
      M.satProgress(s, 40 * Math.min(s.inridning / INRIDNING_M, 1));
      if (s.inridning >= INRIDNING_M) M.andra(s, "crossing", "over_pole");
      else if (w1 >= INRIDNING_SLUT) tillInridning(s, "approach_longer");
      return;
    }
    if (w1 > s.frontW) s.frontW = w1;
    if (s.lage === "crossing") {
      let funnen = null;
      for (const f of hs.forsok) if (f.hinderId === HINDER_ID && f.nr > s.nrBas && f.tIn > s.tBas) funnen = f;
      if (funnen && funnen.giltighet !== "pagar") {
        if (funnen.giltighet !== "fullstandig") { tillInridning(s, "unknown"); return; }
        if (funnen.utfall === "sidan_om") { tillInridning(s, "beside_pole"); return; }
        if (funnen.utfall !== "passage") { tillInridning(s, "no_passage"); return; }
        if (funnen.riktning !== g.riktning) { tillInridning(s, "wrong_direction"); return; }
        s.passageNr = funnen.nr; s.passageW = w1;
        s.utridning = 0;
        M.andra(s, "exit", "walk_on_after");
        M.satProgress(s, 80);
      }
      return;
    }
    s.utridning = Math.max(s.utridning, w1 - s.passageW);
    M.satProgress(s, 80 + 19 * Math.min(s.utridning / UTRIDNING_M, 1));
    if (s.utridning >= UTRIDNING_M) stang(s, "slutford", X);
  }

  function platsFel(s, X) {
    const p = X.p;
    if (!(p && p.punkt && p.iBana === true && p.ramId != null && X.hinder)) return "place";
    if (bomGeometri(X.plats, X.hinder) == null) return "pole";
    return null;
  }
  function starta(s, X) {
    s.resultat = null;
    nyBaslinje(s, X);
    s.armerad = false; s.frontW = null; s.inridning = 0; s.utridning = 0;
    s.passageNr = null; s.passageW = null; s.nrBas = 0; s.tBas = 0;
    s.progress = 0;
    s.revision++;
    M.andra(s, "approach", "to_approach");
  }

  return { OVNING: "markbom", VERSION: "server-markbom-1", HINDER_ID, DEADLINE, AKTIVA,
    GRANSER: Object.freeze({ SIDA_EXTRA, DJUP, INRIDNING_M, INRIDNING_SLUT, UTRIDNING_M, BAKAT_M, MARK_TOPP, DEADLINE }),
    ny, bild, steg, platsFel, starta };
})();
