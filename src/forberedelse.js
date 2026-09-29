/* ══════════════════════════════════════════════════════════════════
   FÖRBEREDELSEN — webbens port av roblox/src/shared/HorseCore/Preparation.luau

   Paritetspasset 2026-09-28 (#264, docs/WEB-P1A-STABLE-FLOW-CONTRACT.md):
   Roblox är facit. Den här filen portar AVSIKT, REGLER OCH PARAMETRAR —
   inte Luau-koden rad för rad. All kunskap kommer ur src/spel/skotsel.js,
   samma tabeller som exporteras till Roblox; ingenting skrivs av här.

   Samma regler som Preparation.luau:
     · faserna i FASER-ordning, uppsittningen är inget steg,
     · momenten härleds ur kanonen (hälsning = val, visitation = 5 punkter i
       ordning, ryktning = redskap × zontyp med redskapets index som steg,
       iordning = hovarna och sedan utr:1–5, leda = ett moment),
     · nejen prövas i samma ordning: stopp → fel häst → öppet fynd → fas →
       redan gjort → felaktigt alternativ → fel tur,
     · "auto" (stallets hand) skiljs från spelarens egen, och ett manuellt
       moment nedgraderas aldrig,
     · fyndet är deterministiskt ur (häst, pass) med SAMMA konstanter, och
       första passet är alltid rent,
     · rätt svar på ett fynd STOPPAR arbetet — hästen rids inte.
   ══════════════════════════════════════════════════════════════════ */

const Forb = (() => {
  const U32 = 4294967296;
  const FYNDCHANS = 0.42;

  const stegFaser = () => FASER.filter(f => !f.sitt);
  const fas = id => FASER.find(f => f.id === id) || null;

  /* Zontyperna i den ordning de först förekommer i RYKTZON — samma
     härledning som Preparation.zontyper, så att en ny zontyp i kanonen
     blir ett moment i stället för att försvinna. */
  function zontyper() {
    const ut = [];
    for (const z of RYKTZON) if (!ut.includes(z.typ)) ut.push(z.typ);
    return ut;
  }

  const cache = {};
  function moment(fasId) {
    if (cache[fasId]) return cache[fasId];
    const f = fas(fasId);
    if (!f) return [];
    let ut;
    if (fasId === "halsa") {
      /* UI-2: handlingar i ordning. `text` = Ugnetas instruktion för
         handlingen, `kvittens` = det som sägs när den är gjord — som
         Preparation.halsMoment i Roblox. */
      ut = HALSNING.map((h, i) => ({ id: "halsa" + (i + 1), namn: h.t, namnEn: h.tEn,
        text: h.text || h.svar, textEn: h.textEn || h.svarEn,
        kvittens: h.svar, kvittensEn: h.svarEn, steg: i + 1, fel: !h.ratt }));
    } else if (fasId === "visitera") {
      ut = VISITPUNKT.map((p, i) => ({ id: "vis:" + p.id, namn: p.namn, namnEn: p.namnEn,
        text: p.ok, textEn: p.okEn, steg: i + 1, punkt: p.id }));
    } else if (fasId === "rykta") {
      ut = [];
      const typer = zontyper();
      RYKTREDSKAP.forEach((r, ri) => {
        for (const typ of typer) {
          if (!(RYKTKRAV[typ] || []).includes(r.id)) continue;
          ut.push({ id: `rykt:${r.id}:${typ}`,
            namn: `${r.namn} — ${RYKTZONNAMN[typ]}`,
            namnEn: `${r.namnEn} — ${RYKTZONNAMN_EN[typ]}`,
            text: r.text, textEn: r.textEn, steg: ri + 1 });
        }
      });
    } else if (fasId === "iordning") {
      ut = HOVAR.map((h, i) => ({ id: "hov:" + h.id, namn: h.namn, namnEn: h.namnEn,
        text: h.text, textEn: h.textEn, steg: i + 1 }));
      const bas = ut.length;
      SADELFAS.forEach((s, i) => ut.push({ id: "utr:" + (i + 1), utr: i + 1,
        text: s.t, textEn: s.tEn, steg: bas + i + 1 }));
    } else {
      ut = [{ id: fasId, namn: f.namn, namnEn: f.namnEn, text: f.text, textEn: f.textEn, steg: 1 }];
    }
    cache[fasId] = ut;
    return ut;
  }

  /* Ett val har ett felaktigt alternativ — härlett ur kanonens `ratt`,
     aldrig en lista av fas-id här. */
  const arVal = fasId => moment(fasId).some(m => m.fel);
  const harValt = (s, fasId) => moment(fasId).some(m => !m.fel && s.gjorda[fasId]?.[m.id]);

  function nastaMoment(s, fasId) {
    if (arVal(fasId) && harValt(s, fasId)) return null;
    const gjort = s.gjorda[fasId] || {};
    return moment(fasId).find(m => !m.fel && !gjort[m.id]) || null;
  }
  const fasKlar = (s, fasId) => nastaMoment(s, fasId) === null;

  /* FNV-start, ×31 och Numerical Recipes-LCG — samma tal som
     Preparation.fro/nasta, så att samma häst samma pass ger samma fynd
     på båda plattformarna. Alla mellanled ryms exakt i en double. */
  function fro(hastId, pass) {
    let h = 2166136261;
    for (let i = 0; i < hastId.length; i++) h = (h * 31 + hastId.charCodeAt(i)) % U32;
    return (h + pass * 104729) % U32;
  }
  const lcg = f => (1664525 * f + 1013904223) % U32;

  function fyndFor(hastId, pass) {
    if (typeof hastId !== "string" || !hastId) return null;
    if (typeof pass !== "number" || pass <= 1) return null;
    let f = lcg(fro(hastId, pass));
    if (f / U32 >= FYNDCHANS) return null;
    f = lcg(f);
    const i = Math.min(VISITPUNKT.length - 1, Math.max(0, Math.floor(f / U32 * VISITPUNKT.length)));
    return VISITPUNKT[i].id;
  }

  const fyndSvar = () => VISITSVAR.map((s, i) => ({ id: "svar:" + (i + 1),
    namn: s.t, namnEn: s.tEn, steg: 1, fel: !s.ratt }));

  function nyState(hastId, pass) {
    const p = typeof pass === "number" && pass >= 1 ? pass : 1;
    return { hastId, pass: p, klara: {}, gjorda: {}, fynd: fyndFor(hastId, p),
      fyndSett: false, fyndRapporterat: false, stoppad: null,
      /* Utrustningen i handen, hämtad från boxfronten (Roblox:
         valdUtrustning). utr:1–4 kräver sadeln, utr:5 tränset. */
      hand: { sadel: false, trans: false } };
  }

  const nasta = s => stegFaser().find(f => !s.klara[f.id]) || null;
  const redo = s => !s.stoppad && nasta(s) === null;

  function provaSteg(s, fasId, hastId) {
    if (s.stoppad) return [false, "forb.lararen_tar_over", s.stoppad];
    if (hastId !== s.hastId) return [false, "forb.fel_hast"];
    if (s.fyndSett && !s.fyndRapporterat) return [false, "forb.oppet_fynd"];
    const f = fas(fasId);
    if (!f) return [false, "forb.okand_fas"];
    if (f.sitt) return [false, "forb.uppsittning_inte_steg"];
    if (s.klara[fasId]) return [false, "forb.redan_gjort"];
    const n = nasta(s);
    if (!n || n.id !== fasId) return [false, "forb.fel_tur", n ? n.namn : null];
    return [true];
  }

  function provaMoment(s, fasId, momentId, hastId) {
    const st = provaSteg(s, fasId, hastId);
    if (!st[0]) return st;
    const m = moment(fasId).find(x => x.id === momentId);
    if (!m) return [false, "forb.okant_moment"];
    const gjort = s.gjorda[fasId] || {};
    if (gjort[momentId]) return [false, "forb.redan_gjort"];
    /* Ett felaktigt alternativ flyttar ingenting — kanonens egen
       konsekvens är svaret. */
    if (m.fel) return [false, "kanon", m];
    let lagsta = null;
    for (const x of moment(fasId))
      if (!x.fel && !gjort[x.id] && (lagsta === null || x.steg < lagsta)) lagsta = x.steg;
    if (lagsta !== null && m.steg > lagsta) {
      const paTur = nastaMoment(s, fasId);
      return [false, "forb.fel_tur", paTur ? paTur.namn : null];
    }
    /* Utrustningen måste finnas i handen innan den kan läggas på. */
    if (m.utr) {
      const kravs = m.utr === SADELFAS.length ? "trans" : "sadel";
      if (!s.hand[kravs]) return [false, "tack.hamta_forst"];
    }
    return [true, null, m];
  }

  /* Returnerar [ok, skäl, arg/händelse]. `utforare === "auto"` är
     stallets hand; allt annat är spelarens. */
  function utforMoment(s, fasId, momentId, hastId, utforare) {
    const r = provaMoment(s, fasId, momentId, hastId);
    if (!r[0]) return r;
    s.gjorda[fasId] = s.gjorda[fasId] || {};
    if (s.gjorda[fasId][momentId] !== true)
      s.gjorda[fasId][momentId] = utforare === "auto" ? "auto" : true;
    let handelse = null;
    if (fasId === "visitera" && s.fynd && momentId === "vis:" + s.fynd) {
      s.fyndSett = true; handelse = "fynd";
    }
    if (fasKlar(s, fasId)) {
      if (fasId === "visitera" && s.fynd && !s.fyndRapporterat) return [true, null, handelse];
      s.klara[fasId] = true;
    }
    return [true, null, handelse];
  }

  function svaraFynd(s, svarId) {
    if (!s.fyndSett) return [false, "forb.inget_att_rapportera"];
    if (s.fyndRapporterat) return [false, "forb.redan_rapporterat"];
    const v = fyndSvar().find(x => x.id === svarId);
    if (!v) return [false, "forb.okant_svar"];
    if (v.fel) return [false, "forb.inte_ditt_beslut"];
    s.fyndRapporterat = true;
    /* Stoppet bär fyndets id; meningen slås upp i spelarens språk när den
       skrivs (VISITFYND / VISITFYND_EN), som Roblox kanontext. */
    s.stoppad = s.fynd || "okant";
    return [true];
  }

  function provaUppsittning(s, hastId) {
    if (hastId !== s.hastId) return [false, "forb.inte_din_hast"];
    if (s.stoppad) return [false, "forb.lararen_tar_over", s.stoppad];
    for (const f of stegFaser())
      if (!fasKlar(s, f.id) || !s.klara[f.id]) return [false, "pass.aterstar", f.namn];
    return [true];
  }

  /* Stallets förberedelse. Går genom den RIKTIGA vägen (utforMoment med
     "auto") och respekterar varje nej — fail closed. `leda` rörs aldrig:
     den fasen kvitteras när hästen fysiskt är framme. Felaktiga
     alternativ markeras aldrig. Ett fynd stannar processen: stallet har
     sett det, men beslutet är spelarens. */
  function autoForbered(s) {
    if (!s) return [false, "spel.ingen_hast"];
    s.hand.sadel = true; s.hand.trans = true;   // hennes egen, från boxfronten
    for (const f of stegFaser()) {
      if (f.id === "leda") continue;
      const val = arVal(f.id);
      for (const m of moment(f.id)) {
        if (m.fel) continue;
        const r = utforMoment(s, f.id, m.id, s.hastId, "auto");
        if (!r[0] && r[1] !== "forb.redan_gjort") return r;
        if (s.fyndSett && !s.fyndRapporterat) return [false, "forb.oppet_fynd"];
        if (val && fasKlar(s, f.id)) break;
      }
    }
    return [true];
  }

  /* Hur stor del spelaren gjorde SJÄLV, 0–1. Ett val är ett arbete. */
  function egenAndel(s) {
    if (!s) return 0;
    let totalt = 0, egna = 0;
    for (const f of stegFaser()) {
      const gjort = s.gjorda[f.id] || {};
      if (arVal(f.id)) {
        totalt += 1;
        if (moment(f.id).some(m => !m.fel && gjort[m.id] === true)) egna += 1;
      } else {
        for (const m of moment(f.id)) {
          if (m.fel) continue;
          totalt += 1;
          if (gjort[m.id] === true) egna += 1;
        }
      }
    }
    return totalt ? egna / totalt : 0;
  }

  /* GameplayService.dagsformFor: bas + 0,06 × egen andel. */
  const DAGSFORM_BONUS = 0.06;
  const dagsform = s => Math.min(1, Math.max(0,
    (typeof SVAR_START !== "undefined" ? SVAR_START.DAGSFORM : 0.7) + DAGSFORM_BONUS * egenAndel(s)));

  return { stegFaser, fas, moment, arVal, nastaMoment, fasKlar, fyndFor, fyndSvar,
    nyState, nasta, redo, provaSteg, provaMoment, utforMoment, svaraFynd,
    provaUppsittning, autoForbered, egenAndel, dagsform, DAGSFORM_BONUS, FYNDCHANS };
})();

if (typeof window !== "undefined") window.Forb = Forb;
