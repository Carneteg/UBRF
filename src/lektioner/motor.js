/* ══════════════════════════════════════════════════════════════════
   LEKTIONSMOTORN — webbens port av Roblox-lektionernas gemensamma
   livscykel (P3, docs/P3-RIDING-PANEL-LESSON-MENU-CONTRACT.md § 6).

   ROBLOX ÄR FACIT. Varje lektion finns i roblox/src/server/*Lektion.luau
   och bedöms där av servern. Webben har ingen server, så lektionsobjektet
   lever här — men med SAMMA regler:

     · en lektion = ett objekt med `lage`, `tips`, `progress`, `delmal`,
       `revision`, `resultat` och `referens` (Roblox `bild`),
     · ett aktivt försök åt gången (RidForsok): Start från ready/closed,
       Prova igen bara efter complete/timeout, Avsluta när som helst,
     · varje lektion stegas EN gång per observationssteg (~0,25 s, se
       lektioner/observation.js), med samma tre ögonblicksbilder som
       servern läser: ridobservationen `o`, ridplatsbilden `p` och
       ridloggen `logg`,
     · talen, zonerna, tipsen och resultatens fält är Roblox egna och
       kontrolleras mot Luau-källan av tools/lektionsparitet.mjs.

   Det som INTE portas är serverns transportlager: begärannummer,
   dublettsvar, ägarprov mellan spelare och nätverksfel. En webbspelare
   är ensam om sin ritt, och en begäran är ett funktionsanrop.

   Modulen är REN: inget DOM, ingen G. Den kan köras i Node (tools/
   lektionstest.mjs) precis som i webbläsaren. ── */

const LEKTION_TYPER = {};

const LektionMotor = (() => {
  const klamp = (x, a, b) => Math.max(a, Math.min(b, x));

  /* Försöket (RidForsok i miniatyr). `aktiv` är hela frågan servern
     ställer: finns ett försök i tillståndet "aktivt" för den här
     lektionen? */
  function aktiv(s) { return !!(s && s.forsok && s.forsok.tillstand === "aktivt"); }

  function andra(s, lage, tips) {
    if (s.lage === lage && s.tips === tips) return;
    s.lage = lage; s.tips = tips;
    s.revision++;
  }
  function satProgress(s, p) {
    p = klamp(Math.floor(p), 0, 99);
    if (p !== s.progress) { s.progress = p; s.revision++; }
  }
  function satDelmal(s, d) {
    if (d !== s.delmal) { s.delmal = d; s.revision++; }
  }
  /* Stänger försöket: "slutford", "tidsgrans" eller "avbruten". */
  function slutfor(s, orsak, X) {
    if (!aktiv(s)) return false;
    s.forsok.tillstand = orsak === "slutford" ? "slutfort" : orsak === "tidsgrans" ? "tidsgrans" : "avbrutet";
    s.forsok.slut = X ? X.o.tid : null;
    return true;
  }
  function startaForsok(s, X, ovning, version) {
    s.forsokNr = (s.forsokNr || 0) + 1;
    s.forsokId = s.rittId + ":" + s.forsokNr;
    s.forsok = { id: s.forsokId, tillstand: "aktivt", ovning, version,
      start: { tid: X.o.tid, voltHogsta: X.volt ? X.volt.nr : 0 } };
    return s.forsokId;
  }

  /* En ny lektion av typen `typ`, i ritten `rittId`. `vidKlar` anropas
     vid övergången till "complete" (lektionsminnet, C4). */
  function ny(typ, rittId, vidKlar) {
    const T = typFor({ typ });
    if (!T) return null;
    const s = T.ny(rittId, typ);
    s.typ = s.typ || typ;
    s.rittId = rittId;
    s.vidKlar = vidKlar || null;
    s.forsokNr = 0;
    return s;
  }

  /* Bilden klienten ritar ur — Roblox `bild`. */
  function bild(s) {
    const T = typFor(s);
    return T && T.bild ? T.bild(s) : {
      typ: s.typ, forsokId: s.forsokId, revision: s.revision, lage: s.lage,
      progress: s.progress, tips: s.tips, delmal: s.delmal, resultat: s.resultat, referens: s.referens };
  }

  function typFor(s) {
    return LEKTION_TYPER[s.typ] || (s.typ === "vag_mitt" || s.typ === "vag_diag" ? LEKTION_TYPER.vag : null);
  }

  /* Ett observationssteg. */
  function steg(s, X) {
    const T = typFor(s);
    if (!T || !T.AKTIVA[s.lage]) return;
    T.steg(s, X);
  }

  /* Spelarens begäran: "start", "retry" eller "finish". Returnerar
     [ok, fel]. Samma grenar och samma felord som Roblox `begar`. */
  function begar(s, op, X) {
    const T = typFor(s);
    if (!T) return [false, "unknown"];
    if (op !== "start" && op !== "retry" && op !== "finish" && !(T.extraOp && T.extraOp(op)))
      return [false, "unknown"];
    if (T.begar) return T.begar(s, op, X);
    if (op !== "finish") steg(s, X);
    if (op === "finish") {
      if (aktiv(s)) slutfor(s, "avbruten", X);
      andra(s, "closed", "closed");
      return [true, null];
    }
    if (aktiv(s)) return [false, "active"];
    if (op === "retry" && s.lage !== "complete" && s.lage !== "timeout") return [false, "request"];
    if (op === "start" && s.lage !== "ready" && s.lage !== "closed") return [false, "request"];
    const fel = T.platsFel(s, X);
    if (fel) return [false, fel];
    startaForsok(s, X, T.OVNING, T.VERSION);
    s.deadline = X.now + T.DEADLINE;
    T.starta(s, X);
    return [true, null];
  }

  /* Ritten tar slut (avsittning, scenbyte): ett aktivt försök avbryts. */
  function avbryt(s, X) {
    if (aktiv(s)) slutfor(s, "avbruten", X);
    const T = typFor(s);
    if (T && T.vidRittslut) T.vidRittslut(s, X);
  }

  /* Hjälpare som flera lektioner delar — samma som i varje Luau-modul. */
  function brottAntal(o) {
    const g = o && o.giltighet;
    if (!g || typeof g !== "object") return -1;
    return (g.luckor || 0) + (g.saknade || 0) + (g.teleporter || 0) + (g.ogiltigaDt || 0);
  }
  function segmentAntal(o) {
    const g = o && o.giltighet;
    return g && typeof g.segment === "number" ? g.segment : -1;
  }
  function andligt(x) { return typeof x === "number" && isFinite(x); }

  /* Ryms en figur i den lösta layouten? Samma fråga som varje `ryms`. */
  function layout(plats) {
    if (!plats || !plats.dressyr) return null;
    return { halvBredd: plats.dressyr.halvTvars / plats.studsPerMeter,
      langd: 2 * plats.dressyr.halvLangs / plats.studsPerMeter };
  }

  return { ny, bild, steg, begar, avbryt, aktiv, andra, satProgress, satDelmal, slutfor,
    startaForsok, brottAntal, segmentAntal, andligt, layout, klamp };
})();
