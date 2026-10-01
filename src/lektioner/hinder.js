/* HINDEROBSERVATIONEN PÅ WEBBEN — port av roblox/src/server/
   HinderObservation.luau, den del lektionerna läser: registret över
   ridhusets BEFINTLIGA hinder och försöken vid dem (passage, sidan om,
   ingen passage, riktning, neutral olydnadsevidens).

   KÄLLAN ÄR DELAD: src/site.js RIDHUSINNE.hinder, samma lista som Roblox
   bygger (Anlaggningen.luau). Bommen ligger längs banans x med mitten i
   (x, y) och bredden `b`; planet är alltså tvärs `y`. I lektionsramen:
   breddaxeln är u, normalen är v.

   ENHETER. Roblox räknar zonen i studs (ZON_SIDA 1,5, ZON_DJUP 6, SID_TOL
   0,25, STOPP_FART 0,3 studs/s, BAKAT_TOL 1,0). Här i meter, samma
   storheter delat med 3 studs per meter.

   Luftfas, landning, nedslag och överlapp portas inte: webbens bommar kan
   inte falla och webben har ingen FloorMaterial. Som i Roblox i dag är
   `nedslag` därför alltid "okand" och `rivning` alltid false. ── */
const HinderObs = (() => {
  const SPM = 3;
  const ZON_SIDA = 1.5 / SPM;
  const ZON_DJUP = 6 / SPM;
  const SID_TOL = 0.25 / SPM;
  const STOPP_FART = 0.3 / SPM;
  const BAKAT_TOL = 1.0 / SPM;
  const MAX_FORSOK = 64;

  /* Registret i lektionsramen (u, v), ur den delade källan. */
  function register() {
    const lista = (typeof RIDHUSINNE !== "undefined" && RIDHUSINNE.hinder) || [];
    const hinder = {};
    const sett = {};
    for (const h of lista) {
      if (!h || typeof h.id !== "string") continue;
      sett[h.id] = (sett[h.id] || 0) + 1;
    }
    for (const h of lista) {
      if (!h || typeof h.id !== "string" || sett[h.id] !== 1) continue;
      if (![h.x, h.y, h.b].every(n => typeof n === "number" && isFinite(n)) || !(h.b > 0)) continue;
      /* u = 10 − x vänder x-axeln: breddaxeln i ramen är (−1, 0), normalen
         (0, 1). Samma som Roblox `tvars`/`motC`-projektion av bommens axlar. */
      hinder[h.id] = Object.freeze({ id: h.id, u: LektionObs.tillU(h.x), v: LektionObs.tillV(h.y),
        bredd: h.b, au: -1, av: 0, nu: 0, nv: 1, topp: Math.max(0.02, h.h || 0) + 0.09,
        tjocklek: 0.09, farg: h.farg, flyttad: false, generation: 1 });
    }
    return { hinder };
  }

  function ny(rittId) {
    return { rittId, oppen: true, overflode: false, tappade: 0, forsok: [], aktiva: {}, nr: {}, tSist: null,
      reg: register() };
  }

  function lokal(h, q) {
    const du = q.u - h.u, dv = q.v - h.v;
    return [du * h.au + dv * h.av, du * h.nu + dv * h.nv];
  }
  const iZon = (h, a, w) => Math.abs(a) <= h.bredd / 2 + ZON_SIDA && Math.abs(w) <= ZON_DJUP;

  function stangForsok(r, f, giltighet, t) {
    f.giltighet = giltighet;
    f.tUt = t;
    if (giltighet !== "fullstandig") { f.utfall = "okant"; f.riktning = null; }
    else if (f._korsat) f.utfall = "passage";
    else if (f._sidanOm) f.utfall = "sidan_om";
    else f.utfall = "ingen_passage";
    f.luftfas = "okand"; f.landning = "okand"; f.bom = "ligger"; f.rivning = false;
    f.nedslag = "okand"; f.nedslagGrund = giltighet !== "fullstandig" ? "ej_fullstandigt" : "bom_ej_fysisk";
    f.inSida = f._inSida == null ? null : f._inSida < 0 ? "fram" : "bak";
    f.stoppObserverat = f._stoppV != null;
    f.bakatEfterStopp = f._bakat;
    f.sidanOm = f._sidanOm;
    f.evidensGrund = giltighet !== "fullstandig" ? "ofullstandigt" : null;
    delete r.aktiva[f.hinderId];
  }

  function nyttForsok(r, h, t) {
    if (r.forsok.length >= MAX_FORSOK) { r.overflode = true; r.tappade++; return null; }
    r.nr[h.id] = (r.nr[h.id] || 0) + 1;
    const f = { hinderId: h.id, nr: r.nr[h.id], tIn: t, tUt: null, tPassage: null, utfall: "pagar",
      riktning: null, giltighet: "pagar", sampel: 0, kontakt: "otillganglig", rivning: false,
      stoppObserverat: false, tStopp: null, bakatEfterStopp: false, sidanOm: false, inSida: null,
      _stoppV: null, _bakat: false, _inSida: null, _korsat: false, _sidanOm: false, _sida: null, _kandU: null };
    r.forsok.push(f);
    r.aktiva[h.id] = f;
    return f;
  }

  /* Ett giltigt segment fran → till (i ramen) vid ritt-tid t. */
  function segment(r, fran, till, t) {
    if (!r || !r.oppen) return false;
    const dt = r.tSist != null ? t - r.tSist : null;
    let fart = null;
    if (dt != null && dt > 0) fart = Math.hypot(till.u - fran.u, till.v - fran.v) / dt;
    r.tSist = t;
    for (const id in r.reg.hinder) {
      const h = r.reg.hinder[id];
      const [u0, v0] = lokal(h, fran);
      const [u1, v1] = lokal(h, till);
      const korsar = (v0 < 0 && v1 >= 0) || (v0 > 0 && v1 <= 0);
      let uK = null;
      if (korsar) { const k = v0 / (v0 - v1); uK = u0 + k * (u1 - u0); }
      let f = r.aktiva[id];
      const korsarNara = uK != null && Math.abs(uK) <= h.bredd / 2 + ZON_SIDA;
      if (!f && (iZon(h, u1, v1) || korsarNara)) f = nyttForsok(r, h, t);
      if (!f) continue;
      const forst = f.sampel === 0;
      f.sampel++;
      if ((v0 <= 0 && v1 >= 0) || (v0 >= 0 && v1 <= 0)) {
        const k = v0 === v1 ? 1 : v0 / (v0 - v1);
        f._kandU = u0 + k * (u1 - u0);
      }
      if (forst && Math.abs(v0) > SID_TOL) f._sida = v0 > 0 ? 1 : -1;
      const sida = v1 > SID_TOL ? 1 : v1 < -SID_TOL ? -1 : 0;
      if (sida !== 0) {
        if (f._sida != null && sida !== f._sida) {
          const uX = f._kandU;
          if (Math.abs(uX) <= h.bredd / 2) {
            if (!f._korsat) { f._korsat = true; f.tPassage = t; f.riktning = f._sida < 0 ? "fram" : "bak"; }
          } else f._sidanOm = true;
        }
        f._sida = sida;
      }
      if (f._inSida == null && f._sida != null) f._inSida = f._sida;
      if (!f._korsat && !f._sidanOm && f._inSida != null && v1 * f._inSida > SID_TOL) {
        if (f._stoppV == null) {
          if (fart != null && fart <= STOPP_FART && iZon(h, u1, v1)) { f._stoppV = Math.abs(v1); f.tStopp = t; }
        } else if (!f._bakat && Math.abs(v1) - f._stoppV > BAKAT_TOL) f._bakat = true;
      }
      if (!iZon(h, u1, v1)) stangForsok(r, f, "fullstandig", t);
    }
    return true;
  }

  function brott(r, t) {
    if (!r || !r.oppen) return;
    for (const id in r.aktiva) stangForsok(r, r.aktiva[id], "brott", t);
    r.tSist = null;
  }
  function avsluta(r, t) {
    if (!r || !r.oppen) return;
    for (const id in r.aktiva) stangForsok(r, r.aktiva[id], "ritten_slut", t);
    r.oppen = false;
  }
  function ogonblick(r) {
    if (!r) return null;
    return { rittId: r.rittId, overflode: r.overflode,
      forsok: r.forsok.map(f => Object.freeze({ ...f })) };
  }

  return { ZON_SIDA, ZON_DJUP, SID_TOL, STOPP_FART, BAKAT_TOL, register, ny, segment, brott, avsluta, ogonblick };
})();
