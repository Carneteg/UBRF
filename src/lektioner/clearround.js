/* CLEAR ROUND (UBRF-TRÄNING), FÖRENKLAD BEDÖMNING — port av
   roblox/src/server/ClearRoundLektion.luau och klassprofilen
   roblox/src/shared/HorseCore/Klassprofil.luau (D1).

   Banan blå → C, röd → C, blå → A, röd → C över ridhusets befintliga
   hinder (src/site.js). Anmäl dig → startlista → Gå banan (banskiss) →
   Start → startlinjen inom 45 s → banan i ordning → mållinjen. Tillåten
   tid 180 s. Fel enligt SvRF TR III 2025 moment 381. Nedslag bedöms INTE
   (bommarna kan inte rivas): resultatet säger "inga observerade fel",
   aldrig "felfri", och ingen rosett delas ut.

   Tävlingskläderna (D5) är Roblox-avatarens egna set. Webben har inga
   klädset — valet är därför alltid "egna kläder" (P3 § 11, begärt
   plattformsundantag). Allt annat är samma. */

/* ── KLASSPROFILEN (Klassprofil.luau, D1) ── */
const Klassprofil = (() => {
  const REGEL = "SvRF TR III 2025";
  const MOMENT = Object.freeze(["314.1", "314.1.1", "301.3.1.2", "381", "384.1", "388.2"]);
  const heltal = x => typeof x === "number" && isFinite(x) && x >= 0 && x % 1 === 0;
  const ickeNeg = x => typeof x === "number" && isFinite(x) && x >= 0;
  const ogiltig = skal => Object.freeze({ profil: "A_CLEAR_ROUND", regel: REGEL, moment: MOMENT, giltig: false, skal });

  function clearRound(r) {
    if (!r || typeof r !== "object") return ogiltig("indata");
    if (!(r.forsok === 1 || r.forsok === 2)) return ogiltig("indata");
    if (typeof r.ponny !== "boolean" || typeof r.avfallning !== "boolean" || typeof r.felVag !== "boolean"
      || typeof r.overTillatenTid !== "boolean") return ogiltig("indata");
    if (!(heltal(r.nedslag) && heltal(r.olydnader) && ickeNeg(r.overMaxtidS))) return ogiltig("indata");
    if (r.ponny) return ogiltig("ponny_klassordning_okand");
    if (!ickeNeg(r.hojdM)) return ogiltig("indata");
    if (r.hojdM > 0.90 + 1e-9) return ogiltig("klass_over_090");
    const nedslagFel = 4 * r.nedslag;
    const tidsFel = Math.ceil(r.overMaxtidS / 4);
    let hinderLag, hinderHog;
    if (r.olydnader === 0) { hinderLag = nedslagFel; hinderHog = nedslagFel; }
    else if (r.olydnader === 1) { hinderLag = nedslagFel + 4; hinderHog = nedslagFel + 4; }
    else { hinderLag = nedslagFel + 8; hinderHog = nedslagFel + 12; }
    let utesluten = false;
    if (r.olydnader >= 3 || r.avfallning || r.felVag || r.overTillatenTid) utesluten = true;
    else if (hinderLag > 16) utesluten = true;
    else if (hinderHog > 16) utesluten = null;
    let fel = null;
    if (utesluten === false && r.olydnader <= 1) fel = hinderLag + tidsFel;
    const felfri = utesluten === false && fel === 0;
    return Object.freeze({ profil: "A_CLEAR_ROUND", regel: REGEL, moment: MOMENT, giltig: true, utesluten, felfri, fel,
      rosett: felfri && r.forsok === 1 ? "clear_round" : null, omstartMojlig: r.forsok === 1 && !felfri,
      omstartRaknasSomStart: false });
  }
  return { REGEL, MOMENT, clearRound };
})();

/* ── LEKTIONEN (ClearRoundLektion.luau) ── */
LEKTION_TYPER.clearround = (() => {
  const M = LektionMotor;
  const BANA = Object.freeze([
    Object.freeze({ id: "ridhus_hinder_bla_24", mot: "C", farg: "bla" }),
    Object.freeze({ id: "ridhus_hinder_rod_38", mot: "C", farg: "rod" }),
    Object.freeze({ id: "ridhus_hinder_bla_24", mot: "A", farg: "bla" }),
    Object.freeze({ id: "ridhus_hinder_rod_38", mot: "C", farg: "rod" }),
  ]);
  /* Riktningsidn i banan (`mot`): A-änden / C-änden, men också dressyrbokstavs-id
     som ska finnas i DRESSYRBOKSTAVER. Kontrolleras när modulen laddas, så ett
     okänt id stoppar start i stället för att köras tyst (som ClearRoundLektion). */
  const RIKTNINGSID = Object.freeze(["A", "C"]);
  function kravBokstaver(bana, riktningsid, lista) {
    const finns = id => Array.isArray(lista) && lista.some(p => p && p.b === id);
    for (const id of riktningsid) {
      if (!finns(id)) throw new Error("okand_dressyrbokstav:" + id);
    }
    for (const h of bana) {
      if (!finns(h.mot)) throw new Error("okand_dressyrbokstav:" + h.mot);
      if (!riktningsid.includes(h.mot)) throw new Error("okant_riktningsid:" + h.mot);
    }
  }
  kravBokstaver(BANA, RIKTNINGSID, DRESSYRBOKSTAVER);
  const HOJD_M = 0.68;
  const LINJE_M = 8;
  const LINJE_HALV = 4;
  const START_S = 45;
  const TILLATEN_S = 180;
  const AKTIVA = { to_start: true, course: true, to_finish: true };
  /* Tävlingskläderna: webben har inga set (se huvudet). */
  const KLADER_VAL = Object.freeze([]);
  /* Förra rittens avbrutna utfall, sessionslokalt, aldrig sparat. */
  let senaste = null;

  function ny(rittId) {
    return { typ: "clearround", rittId, lage: "ready", revision: 0, progress: 0, tips: "intro", forsokNr: 0 };
  }
  function nasta(s) {
    if (s.lage !== "course") return null;
    const b = BANA[s.steg - 1];
    return b ? Object.freeze({ nr: s.steg, farg: b.farg, mot: b.mot }) : null;
  }
  function eftervardBild() {
    const E = typeof EFTERVARD !== "undefined" ? EFTERVARD : [];
    return Object.freeze(E.map(e => Object.freeze({ id: e.id, namn: e.namn, namnEn: e.namnEn })));
  }
  function bild(s) {
    return Object.freeze({ typ: "clearround", rittId: s.rittId, forsokId: s.forsokId, revision: s.revision,
      lage: s.lage, progress: s.progress, tips: s.tips, resultat: s.resultat, referens: s.referens,
      forsokNr: s.forsokNr,
      forraAvbruten: (s.lage === "ready" || s.lage === "closed") && senaste ? senaste : null,
      anmalan: s.anmalan || null, klader: null,
      kladerVal: s.lage === "ready" || s.lage === "closed" ? KLADER_VAL : null,
      eftervard: s.lage === "complete" && s.resultat ? eftervardBild() : null,
      nasta: nasta(s),
      delmal: s.lage === "to_start" || s.lage === "banskiss" ? 0 : s.lage === "course" ? s.steg
        : s.lage === "to_finish" ? 5 : null });
  }
  function hinderGeo(hs, id) {
    const h = hs && hs.reg && hs.reg.hinder[id];
    if (!h || h.flyttad) return null;
    return { u: h.u, v: h.v, motC: h.nv >= 0 ? "fram" : "bak", nyckel: `${id}|${h.generation}|${h.u}|${h.v}|${h.bredd}` };
  }
  function banGeometri(hs) {
    if (!hs) return null;
    const hinder = [], nycklar = [];
    for (const b of BANA) {
      const g = hinderGeo(hs, b.id);
      if (!g) return null;
      const riktning = b.mot === "C" ? g.motC : g.motC === "fram" ? "bak" : "fram";
      hinder.push(Object.freeze({ id: b.id, u: g.u, v: g.v, riktning, farg: b.farg, mot: b.mot }));
      nycklar.push(g.nyckel);
    }
    const h1 = hinder[0], h4 = hinder[hinder.length - 1];
    return Object.freeze({ hinder: Object.freeze(hinder), start: Object.freeze({ u: h1.u, v: h1.v - LINJE_M }),
      mal: Object.freeze({ u: h4.u, v: h4.v + LINJE_M }), halv: LINJE_HALV, nyckel: nycklar.join(";") });
  }
  function korsarMotC(seg, L) {
    if (!seg || !seg.fran || !seg.till) return false;
    const v0 = seg.fran.v, v1 = seg.till.v;
    if (!(v0 < L.v && v1 >= L.v)) return false;
    const t = (L.v - v0) / (v1 - v0);
    const u = seg.fran.u + (seg.till.u - seg.fran.u) * t;
    return Math.abs(u - L.u) <= LINJE_HALV;
  }
  function hogstaNr(hsBild, id) {
    let n = 0;
    for (const f of (hsBild && hsBild.forsok) || []) if (f.hinderId === id && f.nr > n) n = f.nr;
    return n;
  }
  function avsluta(s, X, utfall, orsak) {
    const tid = s.tStart != null ? Math.max(0, X.o.tid - s.tStart) : null;
    let profil = null;
    if (utfall === "bedomd") {
      profil = Klassprofil.clearRound({ forsok: s.forsokNr, hojdM: HOJD_M, ponny: false, nedslag: 0,
        olydnader: s.olydnader, avfallning: false, felVag: orsak === "fel_vag", overMaxtidS: 0,
        overTillatenTid: orsak === "tillaten_tid" });
    }
    const utesluten = profil && profil.utesluten;
    const resultatUtfall = utfall !== "bedomd" ? utfall : utesluten === true ? "utesluten"
      : utesluten == null ? "utesluten_ej_faststalld" : profil.fel === 0 ? "inga_observerade_fel" : "observerade_fel";
    const omstart = s.forsokNr === 1 && utfall === "bedomd" && resultatUtfall !== "inga_observerade_fel";
    s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, ovning: "clearround", forsokNr: s.forsokNr,
      bedomning: "forenklad", utfall: resultatUtfall, orsak: orsak || null, olydnader: s.olydnader,
      fel: profil ? profil.fel : null, nedslag: "bedoms_inte", tid, hojdM: HOJD_M, bana: "traningsbana",
      omstartMojlig: omstart, regel: profil ? profil.regel : null });
    M.slutfor(s, utfall === "ej_bedomd" ? "avbruten" : utfall === "ej_startad" ? "tidsgrans" : "slutford", X);
    s.progress = 100;
    s.revision++;
    M.andra(s, "complete", resultatUtfall);
  }
  function nyBaslinje(s, X) {
    const { o, p } = X;
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    s.sistaBrott = M.brottAntal(o);
    const geo = banGeometri(X.hinder);
    if (p.ramId != null && geo) {
      s.ramId = p.ramId; s.geo = geo;
      s.referens = Object.freeze({ ramId: p.ramId, nyckel: geo.nyckel, plats: X.plats, start: geo.start, mal: geo.mal,
        halv: geo.halv, hinder: geo.hinder });
    } else { s.ramId = null; s.geo = null; s.referens = null; }
  }

  function steg(s, X) {
    if (!AKTIVA[s.lage]) return;
    if (!M.aktiv(s)) { M.andra(s, "closed", "closed"); return; }
    const { o, p } = X;
    const hs = HinderObs.ogonblick(X.hinder);
    if (!hs) return;
    const geoNu = banGeometri(X.hinder);
    if (M.brottAntal(o) !== s.sistaBrott || p.ramId == null || p.ramId !== s.ramId || hs.overflode
      || geoNu == null || s.geo == null || geoNu.nyckel !== s.geo.nyckel) {
      avsluta(s, X, "ej_bedomd", "observation"); return;
    }
    if (o.tid === s.sistaT) return;
    const observerad = o.obsTid > s.sistaObs;
    s.sistaT = o.tid; s.sistaObs = o.obsTid;
    const seg = p.status === "segment" && observerad ? p.segment : null;
    if (s.lage === "to_start") {
      if (o.tid - s.tSignal > START_S) { avsluta(s, X, "ej_startad", "start_45"); return; }
      if (korsarMotC(seg, s.geo.start)) {
        s.tStart = o.tid;
        s.nrBas = {};
        for (const b of BANA) s.nrBas[b.id] = hogstaNr(hs, b.id);
        s.sett = {};
        s.steg = 1; s.olydnader = 0;
        M.andra(s, "course", "jump");
      }
      return;
    }
    if (o.tid - s.tStart > TILLATEN_S) { avsluta(s, X, "bedomd", "tillaten_tid"); return; }
    if (s.lage === "course") {
      const nya = [];
      for (const f of hs.forsok) {
        const nyckel = f.hinderId + "#" + f.nr;
        if (s.nrBas[f.hinderId] != null && f.nr > s.nrBas[f.hinderId] && f.giltighet !== "pagar" && !s.sett[nyckel]) nya.push(f);
      }
      nya.sort((a, b) => (a.tUt || 0) - (b.tUt || 0));
      for (const f of nya) {
        s.sett[f.hinderId + "#" + f.nr] = true;
        if (f.giltighet !== "fullstandig") { avsluta(s, X, "ej_bedomd", "observation"); return; }
        const mal = s.geo.hinder[s.steg - 1];
        if (f.hinderId === mal.id) {
          if (f.utfall === "passage") {
            if (f.riktning !== mal.riktning) { avsluta(s, X, "bedomd", "fel_vag"); return; }
            s.steg++;
            s.progress = Math.floor(90 * (s.steg - 1) / BANA.length); s.revision++;
            if (s.steg > BANA.length) { M.andra(s, "to_finish", "to_finish"); return; }
            M.andra(s, "course", "jump");
          } else if (f.utfall === "sidan_om") {
            s.olydnader++;
            s.revision++;
            if (s.olydnader >= 3) { avsluta(s, X, "bedomd", "olydnader"); return; }
          }
        } else if (f.utfall === "passage") { avsluta(s, X, "bedomd", "fel_vag"); return; }
      }
      return;
    }
    if (korsarMotC(seg, s.geo.mal)) avsluta(s, X, "bedomd", null);
  }

  /* Rittslut mitt i banan: ETT utfall, "avbruten" — aldrig ett fall,
     aldrig framgång. Visas nästa gång clear round öppnas. */
  function vidRittslut(s, X, orsak) {
    if (!s || !AKTIVA[s.lage]) return;
    const tid = s.tStart != null && X ? Math.max(0, X.o.tid - s.tStart) : null;
    s.resultat = Object.freeze({ forsokId: s.forsokId, rittId: s.rittId, ovning: "clearround", forsokNr: s.forsokNr,
      bedomning: "forenklad", utfall: "avbruten", orsak: orsak || "avsittning", olydnader: s.olydnader, fel: null,
      nedslag: "bedoms_inte", tid, hojdM: HOJD_M, bana: "traningsbana", omstartMojlig: false });
    s.revision++;
    M.andra(s, "complete", "avbruten");
    senaste = s.resultat;
  }

  const arAnmal = op => op === "anmal";

  function begar(s, op, X) {
    if (op !== "start" && op !== "retry" && op !== "finish" && !arAnmal(op) && op !== "ga_banan") return [false, "unknown"];
    if (op !== "finish") M.steg(s, X);
    if (op === "finish") {
      if (M.aktiv(s)) M.slutfor(s, "avbruten", X);
      s.anmalan = null;
      M.andra(s, "closed", "closed");
      return [true, null];
    }
    if (M.aktiv(s)) return [false, "active"];
    if (op === "ga_banan") {
      if (s.lage === "startlista") { M.andra(s, "banskiss", "banskiss"); return [true, null]; }
      return [false, "request"];
    }
    if (op === "retry" && !(s.lage === "complete" && s.resultat && s.resultat.omstartMojlig)) return [false, "request"];
    if (op === "start" && s.lage !== "banskiss") return [false, "request"];
    if (arAnmal(op) && s.lage !== "ready" && s.lage !== "closed") return [false, "request"];
    const p = X.p;
    if (!(p && p.punkt && p.iBana === true && p.ramId != null && X.hinder)) return [false, "place"];
    if (banGeometri(X.hinder) == null) return [false, "course"];
    if (arAnmal(op)) {
      senaste = null;
      s.resultat = null; s.forsokNr = 0;
      nyBaslinje(s, X);
      s.anmalan = Object.freeze({ startnummer: 1, anmalda: 1, klass: "clearround_traning", hojdM: HOJD_M });
      s.progress = 0;
      s.revision++;
      M.andra(s, "startlista", "startlista");
      return [true, null];
    }
    senaste = null;
    M.startaForsok(s, X, "clearround", "server-clearround-1");
    s.forsokNr = op === "retry" ? 2 : 1;
    s.resultat = null;
    nyBaslinje(s, X);
    s.tSignal = X.o.tid; s.tStart = null; s.steg = 0; s.olydnader = 0;
    s.progress = 0;
    s.revision++;
    M.andra(s, "to_start", "to_start");
    return [true, null];
  }

  return { OVNING: "clearround", VERSION: "server-clearround-1", DEADLINE: TILLATEN_S, AKTIVA, BANA, RIKTNINGSID, kravBokstaver,
    GRANSER: Object.freeze({ HOJD_M, LINJE_M, LINJE_HALV, START_S, TILLATEN_S }),
    ny, bild, steg, begar, vidRittslut, extraOp: op => op === "anmal" || op === "ga_banan",
    _nollstallSenaste: () => { senaste = null; } };
})();
