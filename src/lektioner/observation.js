/* ══════════════════════════════════════════════════════════════════
   RIDOBSERVATIONEN PÅ WEBBEN — samma tre bilder som Roblox-servern läser
   (P3 § 6): RidObservation (`o`), RidPlatsObservation (`p`) och RidLogg
   (`logg`), byggda ur webbens egen ritt.

   ── TAKTEN ────────────────────────────────────────────────────────
   Servern observerar i sitt uthållighetssteg, normalt ~0,25 s
   (RidObservation.luau: "normalt steg är ~0,25 s"). Lektionernas
   provkrav räknas i STEG (Tempo: 30 prov, Volt: 4 segment), så webben
   observerar i samma takt och inte per bildruta. Det gör också
   bedömningen bildfrekvensoberoende.

   ── RAMEN ─────────────────────────────────────────────────────────
   Roblox dömer i dressyrlayoutens ram (Ridhusplats.luau): origo mitt på
   A-kanten, `v` mot C, `u = motC × upp` — positivt mot K–E–H-sidan.
   Webbens ridbana är 20 × 60 med A i (10, 0), C i (10, 60) och K–E–H på
   x = 0 (src/data.js DRESSYRBOKSTAVER). Alltså:

       v = y          u = 10 − x

   Webbens bana ÄR dressyrlayouten (BANA_BREDD × BANA_LANGD = 20 × 60),
   så `iBana` och `iDressyr` sammanfaller här. Utanför ridhuset
   (uteridbanan, skogsstigen) finns ingen lektionsram: `ingen_plats`.

   ── GILTIGHET (RidObservation.sampla) ─────────────────────────────
     dt ≤ 0 eller icke-ändligt  → ogiltigaDt, brott
     dt > MAX_DT (1,0 s)        → luckor, brott, ny baslinje
     inget läge                 → saknade, brott
     första läget               → baslinje
     plan > TELEPORT · dt       → teleporter, brott, ny baslinje
     annars                     → ett giltigt segment
   Teleportgränsen är serverns 33 studs/s = 11 m/s. Webben säger dessutom
   UTTRYCKLIGEN till när spelet flyttar hästen (`teleport: true`), så en
   kort flytt inte kan bli ett segment. ── */

const LektionObs = (() => {
  const STEG_S = 0.25;
  const MAX_DT = 1.0;
  const TELEPORT_MS = 33 / 3;
  const FONSTER = 40;
  const MITT = Object.freeze({ u: 0, v: 30 });
  const PLATS = Object.freeze({ dressyr: Object.freeze({ halvTvars: 10, halvLangs: 30 }),
    studsPerMeter: 1 });

  const tillU = x => 10 - x;
  const tillV = y => y;
  /* Tillbaka till webbens bana — för guiderna som ritas. */
  const tillX = u => 10 - u;
  const tillY = v => v;

  function ny(rittId) {
    return {
      rittId, tid: 0, distans: 0, obsTid: 0, oobsTid: 0, ack: 0,
      giltighet: { luckor: 0, saknade: 0, teleporter: 0, ogiltigaDt: 0, segment: 0 },
      fonster: [], bas: null, ramId: 0, ramNyckel: null,
      plats: { status: "baslinje", punkt: null, segment: null, iDressyr: false, iBana: false,
        ramId: null, dressyrMitt: null, t: 0 },
      logg: { handelser: [], overflode: false },
      steg: 0,
    };
  }

  function inneI(u, v) { return Math.abs(u) <= 10 && v >= 0 && v <= 60; }

  /* En gångartshändelse i ridloggen — en ACCEPTERAD ändring av det
     ryttaren bett om. `orsak` = "hjalp" när ryttarens egen hjälp bad om
     den (webbens cue), annars något annat. Samma fält som
     HorseService.loggaSteg. */
  function handelse(O, data) {
    if (!O) return;
    O.logg.handelser.push({ n: O.logg.handelser.length + 1, t: O.tid, typ: "gangart",
      data: Object.freeze({ fran: data.fran, franRyggar: !!data.franRyggar, till: data.till,
        tillRyggar: !!data.tillRyggar, orsak: data.orsak || "hjalp", handling: data.handling || null }) });
  }

  /* Ett obrutet avsnitt tar slut: nästa läge blir en ny baslinje. */
  function brott(O) { O.fonster.length = 0; }

  /* Ett uthållighetssteg. `lage` = { x, y, gangart, ryggar, ram, teleport }.
     `ram` är null när ritten inte är i ridhuset. Returnerar true när ett
     steg togs. */
  function steg(O, dt, lage) {
    O.steg++;
    const p0 = O.plats;
    if (!(typeof dt === "number" && isFinite(dt)) || dt <= 0) {
      O.giltighet.ogiltigaDt++; brott(O);
      O.plats = Object.freeze({ ...p0, status: "brott", segment: null });
      return true;
    }
    O.tid += dt;
    const har = lage && typeof lage.x === "number" && isFinite(lage.x) && isFinite(lage.y);
    let status;
    let fran = null;
    if (dt > MAX_DT) {
      O.giltighet.luckor++; O.oobsTid += dt; brott(O); status = "brott";
      O.bas = har ? { x: lage.x, y: lage.y } : O.bas;
    } else if (!har) {
      O.giltighet.saknade++; O.oobsTid += dt; brott(O); status = "brott";
    } else if (!O.bas) {
      O.bas = { x: lage.x, y: lage.y }; O.oobsTid += dt; status = "baslinje";
    } else {
      const dx = lage.x - O.bas.x, dy = lage.y - O.bas.y;
      const plan = Math.hypot(dx, dy);
      if (lage.teleport || plan > TELEPORT_MS * dt) {
        O.giltighet.teleporter++; O.oobsTid += dt; brott(O); status = "brott";
        O.bas = { x: lage.x, y: lage.y };
      } else {
        fran = O.bas;
        O.bas = { x: lage.x, y: lage.y };
        O.giltighet.segment++;
        O.obsTid += dt;
        O.distans += plan;
        const fart = plan / dt;
        O.fonster.push({ t: O.tid, fart, gangart: lage.gangart, ryggar: !!lage.ryggar });
        if (O.fonster.length > FONSTER) O.fonster.shift();
        status = "segment";
      }
    }

    /* RIDPLATSBILDEN. En ny ram (ny plats) bryter kontinuiteten. */
    const ram = lage && lage.ram;
    if (ram !== O.ramNyckel) { O.ramNyckel = ram; if (ram) O.ramId++; }
    if (!ram || !har) {
      O.plats = Object.freeze({ status: ram ? "brott" : "ingen_plats", skal: ram ? null : "ingen_byggnad",
        punkt: null, segment: null, iDressyr: false, iBana: false, ramId: ram ? O.ramId : null,
        dressyrMitt: null, t: O.tid });
      return true;
    }
    const u = tillU(lage.x), v = tillV(lage.y);
    const punkt = Object.freeze({ u, h: 0, v });
    let pst = status;
    let segment = null;
    if (status === "segment") {
      if (p0.ramId !== O.ramId || !p0.punkt) pst = "ram_ny";
      else segment = Object.freeze({ fran: Object.freeze({ u: tillU(fran.x), h: 0, v: tillV(fran.y) }), till: punkt });
    }
    O.plats = Object.freeze({ status: pst, punkt, segment, iDressyr: inneI(u, v), iBana: inneI(u, v),
      ramId: O.ramId, dressyrMitt: MITT, t: O.tid });
    return true;
  }

  /* Matar observationen med en bildrutas dt. Tar steg i serverns takt;
     returnerar antalet steg som togs. `vidSteg` anropas efter VARJE steg —
     där stegar volt- och hinderobservationen och lektionen, i samma
     uthållighetssteg som på servern (HorseService). */
  function mata(O, dt, lage, vidSteg) {
    if (!O) return 0;
    const efter = () => { if (typeof vidSteg === "function") vidSteg(O); };
    if (lage && lage.teleport) {
      /* En flytt tas som ett eget steg direkt, så att den aldrig slås ihop
         med nästa kvarts sekund av riktig ridning. */
      steg(O, Math.max(O.ack + dt, 1e-3), lage);
      O.ack = 0;
      efter();
      return 1;
    }
    O.ack += dt;
    /* Ett glapp längre än MAX_DT är EN lucka, inte fyra hopslagna steg. */
    if (O.ack > MAX_DT) { steg(O, O.ack, lage); O.ack = 0; efter(); return 1; }
    let n = 0;
    while (O.ack >= STEG_S) { steg(O, STEG_S, lage); O.ack -= STEG_S; n++; efter(); }
    return n;
  }

  /* Ögonblicksbilderna lektionerna läser. `o` motsvarar
     RidObservation.ogonblick, `p` RidPlatsObservation.ogonblick. */
  function bilder(O) {
    return {
      o: { tid: O.tid, distans: O.distans, obsTid: O.obsTid, giltighet: { ...O.giltighet },
        fonster: O.fonster.slice() },
      p: O.plats,
      logg: { rittId: O.rittId, handelser: O.logg.handelser, overflode: O.logg.overflode },
      plats: PLATS,
    };
  }

  return { STEG_S, MAX_DT, TELEPORT_MS, MITT, PLATS, ny, steg, mata, handelse, bilder,
    tillU, tillV, tillX, tillY };
})();
