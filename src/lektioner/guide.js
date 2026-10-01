/* ══════════════════════════════════════════════════════════════════
   VÄGVISNINGEN — port av guidefunktionerna i roblox/src/client/
   VoltLektionController.luau (P3 § 6: «the green reference lines Roblox
   draws from `referens` are drawn on the web in the 3D riding view and the
   2D arena plan from the same `referens` numbers»).

   Modulen räknar STRECKEN, inte pixlarna: en lista av streck i lektions-
   ramen (u, v i meter), var och ett med mittpunkt, riktning, halva
   längden och om det är det starka (nästa mål) eller det svaga. 3D-vyn
   (src/scen3d.js) och kartan (src/render.js) ritar samma lista.

   Samma regler som Roblox:
     · ett streck ritas bara om HELA strecket ligger inom banan
       (`streck`: ±1,1 × halva längden i båda axlarna),
     · delmålet lyser starkt, resten svagt,
     · mindre vägvisning (`utan`) tar bort samma delar som i Roblox.
   Måtten är Roblox, i meter: `0,5 * studsPerMeter` blir 0,5 m. ── */

const LektionGuide = (() => {
  const BANA_B = 20, BANA_L = 60;
  const X = u => 10 - u, Y = v => v;   // ramen → webbens bana (observation.js)

  function inom(u, v, bound) {
    const x = X(u), y = Y(v);
    return x - bound >= 0 && x + bound <= BANA_B && y - bound >= 0 && y + bound <= BANA_L;
  }
  function streck(ut, u, v, du, dv, half, stark) {
    if (!inom(u, v, half * 1.1)) return;
    const l = Math.hypot(du, dv) || 1;
    ut.push({ u, v, du: du / l, dv: dv / l, half, bredd: half * 0.65, stark: !!stark });
  }
  function ring(ut, cu, cv, r, antal, half, stark) {
    for (let i = 0; i < antal; i++) {
      const a = 2 * Math.PI * i / antal;
      const u = cu + r * Math.cos(a), v = cv + r * Math.sin(a);
      streck(ut, u, v, -Math.sin(a), Math.cos(a), half, stark);
    }
  }
  function rak(ut, au, av, bu, bv, stark, forstaPil, pilSteg, slutMarg, halfLinje) {
    const L = Math.hypot(bu - au, bv - av);
    if (L <= 0) return;
    const du = (bu - au) / L, dv = (bv - av) / L;
    const antal = Math.max(2, Math.floor(L / 1.5));
    for (let i = 1; i < antal; i++) {
      const t = L * i / antal;
      streck(ut, au + du * t, av + dv * t, du, dv, halfLinje == null ? 0.45 : halfLinje, stark);
    }
    if (forstaPil == null) return;
    for (let t = forstaPil; t < L - slutMarg; t += pilSteg) {
      const su = au + du * t, sv = av + dv * t;
      for (const sida of [1, -1]) {
        const fu = su - du * 0.8 + dv * 0.8 * sida, fv = sv - dv * 0.8 - du * 0.8 * sida;
        streck(ut, (su + fu) / 2, (sv + fv) / 2, su - fu, sv - fv, 0.4, stark);
      }
    }
  }

  function serpentin(ref, delmal) {
    const ut = [];
    for (let k = 1; k <= 3; k++) {
      const c = ref.v0 + ref.r + (k - 1) * 2 * ref.r;
      const side = ref.sidor[k - 1];
      const antal = 20;
      for (let i = 0; i < antal; i++) {
        const th = Math.PI * (i + 0.5) / antal;
        const u = ref.u + side * ref.r * Math.sin(th), v = c - ref.r * Math.cos(th);
        const u2 = ref.u + side * ref.r * Math.sin(th + 0.05), v2 = c - ref.r * Math.cos(th + 0.05);
        streck(ut, u, v, u2 - u, v2 - v, 0.5, delmal === k);
      }
    }
    [ref.v0, ref.v0 + 6 * ref.r].forEach((v, j) =>
      ring(ut, ref.u, v, ref.ring, 12, 0.3, (j === 0 && delmal === 0) || (j === 1 && delmal === 4)));
    return ut;
  }
  function vag(ref, delmal, utan) {
    const ut = [];
    const du = (ref.u1 - ref.u0) / ref.langd, dv = (ref.v1 - ref.v0) / ref.langd;
    const ridning = delmal != null && delmal >= 1;
    const antal = Math.max(2, Math.floor(ref.langd / 1.5));
    if (!utan) for (let i = 1; i < antal; i++) {
      const t = ref.langd * i / antal;
      streck(ut, ref.u0 + du * t, ref.v0 + dv * t, du, dv, 0.45, ridning);
    }
    if (!utan) for (let t = 6; t < ref.langd - 3; t += 6) {
      const su = ref.u0 + du * t, sv = ref.v0 + dv * t;
      for (const sida of [1, -1]) {
        const fu = su - du * 0.8 + dv * 0.8 * sida, fv = sv - dv * 0.8 - du * 0.8 * sida;
        streck(ut, (su + fu) / 2, (sv + fv) / 2, su - fu, sv - fv, 0.4, ridning);
      }
    }
    [[ref.u0, ref.v0], [ref.u1, ref.v1]].forEach((c, j) =>
      ring(ut, c[0], c[1], ref.ring, 12, 0.3, (j === 0 && !ridning) || (j === 1 && ridning)));
    return ut;
  }
  function halvvolt(ref, delmal, utan) {
    const ut = [];
    if (!utan) rak(ut, ref.uT, ref.p0v, ref.uT, ref.t1v, delmal === 1, 4, 5, 2);
    const cu = ref.uT - ref.r, cv = ref.t1v;
    for (let i = 0; i < 16; i++) {
      const th = Math.PI * (i + 0.5) / 16;
      const u = cu + ref.r * Math.cos(th), v = cv + ref.r * Math.sin(th);
      const u2 = cu + ref.r * Math.cos(th + 0.05), v2 = cv + ref.r * Math.sin(th + 0.05);
      streck(ut, u, v, u2 - u, v2 - v, 0.45, delmal === 2);
    }
    rak(ut, ref.uT - 2 * ref.r, ref.t1v, ref.uT, ref.ev, delmal === 3 || delmal === 4, 4, 5, 2);
    [[ref.uT, ref.p0v], [ref.uT, ref.ev]].forEach((c, j) =>
      ring(ut, c[0], c[1], ref.ring, 12, 0.3, (j === 0 && delmal === 0) || (j === 1 && delmal === 4)));
    return ut;
  }
  function markbom(ref, delmal, utan) {
    const ut = [];
    const lok = (a, w) => [ref.u + ref.au * a + ref.wu * w, ref.v + ref.av * a + ref.wv * w];
    const fram = [ref.wu, ref.wv], sid = [ref.au, ref.av];
    const kant = ref.bredd / 2 + ref.sida;
    for (let w = utan ? 0 : -ref.djup; w < -0.6; w += 1.2)
      for (const a of [-kant, kant]) { const [u, v] = lok(a, w); streck(ut, u, v, fram[0], fram[1], 0.35, delmal === 0); }
    for (let w = utan ? 0 : -ref.djup + 1; w < -1.5; w += 2.5) {
      const [su, sv] = lok(0, w);
      for (const sida of [1, -1]) {
        const fu = su - fram[0] * 0.7 + sid[0] * 0.7 * sida, fv = sv - fram[1] * 0.7 + sid[1] * 0.7 * sida;
        streck(ut, (su + fu) / 2, (sv + fv) / 2, su - fu, sv - fv, 0.35, delmal === 0);
      }
    }
    for (const a of [-(ref.bredd / 2 + 0.3), ref.bredd / 2 + 0.3]) {
      const [u, v] = lok(a, 0); streck(ut, u, v, fram[0], fram[1], 0.3, delmal === 1);
    }
    for (let w = utan ? Infinity : 0.6; w <= 3; w += 1.2)
      for (const a of [-kant, kant]) { const [u, v] = lok(a, w); streck(ut, u, v, fram[0], fram[1], 0.35, delmal === 2); }
    return ut;
  }
  function horn(ref, delmal, utan) {
    const ut = [];
    if (!utan) rak(ut, ref.p0u, ref.p0v, ref.uT, ref.cv, delmal === 1, 3, 4, 1);
    for (let i = 0; i < 10; i++) {
      const th = (Math.PI / 2) * (i + 0.5) / 10;
      const u = ref.cu + ref.r * Math.cos(th), v = ref.cv + ref.r * Math.sin(th);
      const u2 = ref.cu + ref.r * Math.cos(th + 0.05), v2 = ref.cv + ref.r * Math.sin(th + 0.05);
      streck(ut, u, v, u2 - u, v2 - v, 0.45, delmal === 2);
    }
    if (!utan) rak(ut, ref.cu, ref.cv + ref.r, ref.p3u, ref.p3v, delmal === 3, 3, 4, 1);
    [[ref.p0u, ref.p0v], [ref.p3u, ref.p3v]].forEach((c, j) =>
      ring(ut, c[0], c[1], ref.ring, 12, 0.3, (j === 0 && delmal === 0) || (j === 1 && delmal === 3)));
    return ut;
  }
  function clearround(ref, delmal) {
    const ut = [];
    [ref.start, ref.mal].forEach((L, j) => {
      const antal = Math.max(2, Math.floor(2 * ref.halv / 0.8));
      for (let i = 0; i <= antal; i++) {
        const u = L.u - ref.halv + 2 * ref.halv * i / antal;
        streck(ut, u, L.v, 1, 0, 0.3, (j === 0 && delmal === 0) || (j === 1 && delmal === 5));
      }
    });
    return ut;
  }
  /* Volten, haltet, övergångarna och galoppen: ringar. */
  function ringar(typ, ref) {
    const ut = [];
    const lista = typ === "overgang" ? [[ref.u, ref.v1, ref.halv], [ref.u, ref.v2, ref.halv]]
      : typ === "galopp" || typ === "halt" ? [[ref.u, ref.v, ref.radie]]
      : [[ref.u, ref.v, ref.radie - 1]];
    const antal = typ === "volt" ? 72 : 16, half = typ === "volt" ? 0.8 : 0.3;
    for (const [cu, cv, r] of lista) ring(ut, cu, cv, r, antal, half, false);
    for (const s of ut) s.ring = true;
    return ut;
  }

  /* Strecken för en guide ur Lektionsmeny.guide(), eller []. */
  function streckFor(g) {
    if (!g || !g.referens) return [];
    const ref = g.referens;
    if (g.typ === "serpentin") return serpentin(ref, g.delmal);
    if (g.typ === "vag_mitt" || g.typ === "vag_diag") return vag(ref, g.delmal, g.utan);
    if (g.typ === "halvvolt") return halvvolt(ref, g.delmal, g.utan);
    if (g.typ === "markbom") return markbom(ref, g.delmal, g.utan);
    if (g.typ === "hornet") return horn(ref, g.delmal, g.utan);
    if (g.typ === "clearround") return clearround(ref, g.delmal);
    if (g.typ === "tempo") return [];
    return ringar(g.typ, ref);
  }

  /* Cache: samma guide ger samma lista (Roblox ritar bara om vid ändring). */
  let sistaNyckel = null, sistaLista = [];
  function aktuella() {
    const g = typeof Lektionsmeny !== "undefined" ? Lektionsmeny.guide() : null;
    if (!g) { sistaNyckel = null; sistaLista = []; return sistaLista; }
    const nyckel = [g.typ, g.delmal, g.utan, JSON.stringify(g.referens, (k, v) => (k === "plats" ? undefined : v))].join("|");
    if (nyckel !== sistaNyckel) { sistaNyckel = nyckel; sistaLista = streckFor(g); }
    return sistaLista;
  }

  return { streckFor, aktuella, X, Y };
})();

if (typeof window !== "undefined") window.LektionGuide = LektionGuide;
