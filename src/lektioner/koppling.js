/* ══════════════════════════════════════════════════════════════════
   KOPPLINGEN — webbens motsvarighet till HorseService-delen som matar
   lektionerna (P3 § 6). En uppsättning observationer PER RITT:

     · LektionObs  (RidObservation + RidPlatsObservation + RidLogg),
     · VoltObs     (VoltObservation),
     · HinderObs   (HinderObservation, den del lektionerna läser),

   stegade i serverns uthållighetstakt (~0,25 s, se observation.js). Efter
   varje steg stegas den aktiva lektionen EN gång — samma ordning som
   servern: sampla, sedan lektionen.

   ── VAD SOM LÄSES UR WEBBENS RITT ─────────────────────────────────
     läge      G.px, G.py (ridbanans meter; ramen bara i ridhuset)
     gångart   G.ride.gangart → Roblox namn (halt/walk/trot/canter)
     hjälp     G.ride.cueTid/beddGangart: ryttarens EGEN hjälp bad om en
               ny gångart → en gångartshändelse med orsak "hjalp", precis
               som RidLogg får av HorseService.loggaSteg. `fran`/`till` är
               den begärda gångarten före och efter, som Roblox trappsteg.
     ryggar    webben har ingen ryggning: alltid false.

   ── IDENTITET ──────────────────────────────────────────────────────
   En ny ritt (uppsittning) får ett nytt rittId och nya observationer.
   Avsittning stänger allt: ett pågående försök blir "avbrutet" (clear
   round: utfallet "avbruten"), aldrig framgång.

   Modulen är REN mot DOM:en och kan köras i Node (tools/lektionstest.mjs)
   genom att mata `steg` med egna lägen i stället för G. ── */

const RittLektion = (() => {
  const GANG = { halt: "halt", skritt: "walk", trav: "trot", galopp: "canter" };
  const tillRoblox = g => GANG[g] || null;
  let nr = 0;
  let R = null;          // { rittId, O, volt, hinder, bedd, cueTid, teleport }

  function start(rittId) {
    nr++;
    const id = rittId || ("webb:" + nr);
    R = { rittId: id, O: LektionObs.ny(id), volt: VoltObs.ny(id), hinder: HinderObs.ny(id),
      bedd: null, cueTid: null, teleport: true, sistaSteg: null };
    return id;
  }
  function aktiv() { return !!R; }
  function rittId() { return R ? R.rittId : null; }

  /* Spelet flyttade hästen (Rida nu, dörr, ny ritt): nästa läge är en
     teleport, aldrig ett segment. */
  function teleport() { if (R) R.teleport = true; }

  /* Kontexten en lektion stegas med — samma tre bilder servern läser. */
  function kontext(now, gangart) {
    if (!R) return null;
    const b = LektionObs.bilder(R.O);
    return { now, o: b.o, p: b.p, logg: b.logg, gangart: gangart || null, ryggar: false,
      plats: b.p && b.p.ramId != null ? LektionObs.PLATS : null, volt: R.volt, hinder: R.hinder };
  }

  /* En gångartsbegäran ur ryttarens hjälp. `ride` är webbens ridtillstånd. */
  function lasHjalp(ride) {
    if (!R || !ride) return;
    const bedd = tillRoblox(ride.beddGangart || ride.malGangart || ride.gangart);
    if (R.bedd == null) { R.bedd = bedd; R.cueTid = ride.cueTid; return; }
    if (ride.cueTid !== R.cueTid) {
      R.cueTid = ride.cueTid;
      if (bedd && bedd !== R.bedd) {
        LektionObs.handelse(R.O, { fran: R.bedd, till: bedd, orsak: "hjalp", handling: ride.cue || null });
        R.bedd = bedd;
      }
    } else if (bedd && bedd !== R.bedd) {
      /* Den begärda gångarten ändrades utan en ny hjälp (modellen själv). */
      LektionObs.handelse(R.O, { fran: R.bedd, till: bedd, orsak: "annat" });
      R.bedd = bedd;
    }
  }

  /* En bildruta ridning. `lage` = { x, y, gangart (webbens namn), ridhus }.
     `vidSteg(X)` anropas efter varje observationssteg med lektionskontexten. */
  function steg(dt, lage, ride, now, vidSteg) {
    if (!R) return 0;
    lasHjalp(ride);
    const gangart = tillRoblox(lage && lage.gangart);
    const tp = R.teleport; R.teleport = false;
    const in_ = lage ? { x: lage.x, y: lage.y, gangart, ryggar: false, ram: lage.ridhus ? "ridhus" : null,
      teleport: tp } : null;
    return LektionObs.mata(R.O, dt, in_, O => {
      const p = O.plats;
      VoltObs.sampla(R.volt, p);
      if (p.status === "segment" && p.segment) HinderObs.segment(R.hinder, p.segment.fran, p.segment.till, O.tid);
      else if (p.status !== "baslinje") HinderObs.brott(R.hinder, O.tid);
      if (typeof vidSteg === "function") vidSteg(kontext(now, gangart));
    });
  }

  function slut() {
    if (!R) return;
    VoltObs.stang(R.volt);
    HinderObs.avsluta(R.hinder, R.O.tid);
    R = null;
  }

  return { start, aktiv, rittId, teleport, kontext, steg, slut, tillRoblox,
    _R: () => R };
})();

if (typeof window !== "undefined") window.RittLektion = RittLektion;
