/* ══════════════════════════════════════════════════════════════════
   LEKTIONSMENYN OCH LEKTIONENS SIDA — port av
   roblox/src/client/VoltLektionController.luau (P3 § 4).

   ROBLOX ÄR FACIT. Samma sidor (topp, gangart, overgangar, vagar, bojda,
   linjer), samma nycklar, samma ordning, samma `ersatt`-regel, samma
   förslag och markeringar, samma val efter ett försök (Prova igen /
   Avsluta / Rid utan streck ↔ Visa vägen), samma starthälsning och
   tempocoachning. tools/lektionsparitet.mjs läser menyträdet och
   MINNE_ORDNING ur Luau-källan och faller om den här filen avviker.

   SKILLNADEN ÄR TRANSPORTEN, inte regeln. Roblox skickar en begäran till
   servern och väntar på svaret (`pending`); webben har ingen server, så
   en begäran är ett funktionsanrop in i LektionMotor och svaret kommer i
   samma bildruta. Vänteläget och nätverksfelet finns därför aldrig här.

   LEKTIONSMINNET är spelarens eget, i webbens sparfil (SPAR.lektionsminne,
   samma sparobjekt som resten av profilen), med Roblox nycklar
   `lektion:<typ>:<VERSION>`. Clear round sparas inte (Roblox MINNE_TYPER).
   En sparning som inte gick att lita på (SPAR_BETRODD falskt) ger okänd
   historik — inget förslag, alla lektioner går att välja. Webben kan inte
   läsa Roblox DataStore och tvärtom: den deklarerade sparskillnaden. ── */

const Lektionsmeny = (() => {
  const t = (k, ...a) => (typeof tSpr === "function" ? tSpr(k, ...a) : k);
  const inst = () => (typeof LararInstallning !== "undefined" ? LararInstallning : null);
  const valfri = () => { const I = inst(); return I ? I.valfriKommentar() : true; };
  const kommentarer = () => { const I = inst(); return I ? I.kommentarer() : "normal"; };

  const MINNE_TYPER = { volt: true, halt: true, overgang: true, serpentin: true, tempo: true,
    vag_mitt: true, vag_diag: true, halvvolt: true, galopp: true, markbom: true, hornet: true };
  const MINNE_ORDNING = ["halt", "tempo", "volt", "overgang", "vag_mitt", "vag_diag", "serpentin",
    "halvvolt", "hornet", "markbom", "galopp"];
  const MINNE_GRUPP = { halt: "gangart", tempo: "gangart", overgang: "gangart", galopp: "gangart",
    serpentin: "vagar", halvvolt: "vagar", vag_mitt: "vagar", vag_diag: "vagar", markbom: "vagar",
    hornet: "vagar" };
  const MINNE_UNDERGRUPP = { overgang: "overgangar", galopp: "overgangar", vag_mitt: "linjer",
    vag_diag: "linjer", markbom: "linjer", serpentin: "bojda", halvvolt: "bojda", hornet: "bojda" };
  const HALSNING_S = 6;
  const COACH_SKAL = { too_slow: true, too_fast: true, steadier: true };
  /* RidKanon.UGNETA.LIVE_CD — samma tal som webbens UGNETA_LIVE_CD. */
  const COACH_CD = () => (typeof UGNETA_LIVE_CD !== "undefined" ? UGNETA_LIVE_CD : { bra: 14, fel: 8, visa: 2.6 });
  const AKTIVA_LAGEN = { approach: true, baseline: true, riding: true, halt1: true, walk: true,
    walk1: true, trot: true, walk2: true, to_start: true, route: true, steady: true,
    canter: true, crossing: true, exit: true, course: true, to_finish: true };
  const GUIDE_LAGEN = { approach: true, baseline: true, riding: true, halt1: true, walk: true,
    walk1: true, trot: true, walk2: true, to_start: true, route: true, canter: true,
    crossing: true, exit: true, course: true, to_finish: true, banskiss: true };
  const PROCENT_LAGEN = { riding: true, halt1: true, walk: true, walk1: true, trot: true, walk2: true,
    route: true, steady: true, canter: true, approach: true, crossing: true, exit: true,
    course: true, to_finish: true };
  const TYPER = ["volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
    "galopp", "markbom", "hornet", "clearround"];

  /* ── Texterna: samma fallkedja som Roblox `text(key)` ─────────────── */
  const EGNA = {
    markbom: ["markbomlektion", "start finish intro to_approach walk_to_pole approach_longer over_pole walk_on_after walk_on walk_only off_line reverse beside_pole no_passage wrong_direction pole_missing unknown complete timeout closed place mindre_stod",
      { pole: "markbomlektion.pole_missing", visa_vagen: "vaglektion.visa_vagen" }],
    galopp: ["galopplektion", "start finish intro trot_on trot_first canter_at_k canter_outside canter_on canter_longer tired unknown complete timeout closed place", {}],
    clearround: ["clearround", "anmal ga_banan start finish retry intro to_start to_finish closed place",
      { course: "clearround.course_missing" }],
    hornet: ["hornlektion", "start finish intro to_start ride_in bend ride_out off_route reverse walk_or_trot unknown complete timeout closed place mindre_stod",
      { visa_vagen: "vaglektion.visa_vagen" }],
    halvvolt: ["halvvoltlektion", "start finish intro to_start track half_circle return to_end off_route reverse halt_moved walk_or_trot unknown complete timeout closed place mindre_stod",
      { visa_vagen: "vaglektion.visa_vagen" }],
    vag_mitt: ["vaglektion", "start finish to_start ride_mitt ride_diag to_end off_route reverse walk_or_trot utan_streck visa_vagen unknown complete timeout closed place",
      { intro: "vaglektion.intro_mitt" }],
    vag_diag: ["vaglektion", "start finish to_start ride_mitt ride_diag to_end off_route reverse walk_or_trot utan_streck visa_vagen unknown complete timeout closed place",
      { intro: "vaglektion.intro_diag" }],
    tempo: ["tempolektion", "start finish intro walk_on keep_going too_slow too_fast steadier walk_only stay_inside unknown complete timeout closed place", {}],
    serpentin: ["serpentinlektion", "start finish intro to_start loop1 loop2 loop3 to_end off_route reverse walk_or_trot unknown complete timeout closed place", {}],
    overgang: ["overganglektion", "start finish intro walk_on walk_first trot_at_t1 trot_outside trot_on trot_longer walk_at_t2 walk_outside walk_calm tired walk_only trot_only unknown complete timeout closed place", {}],
    halt: ["haltlektion", "start finish intro halt_first walk_on walk_only to_x hold halt_outside halt_at_x unknown complete timeout closed place", {}],
  };
  const EGEN_NYCKEL = {};
  for (const typ in EGNA) {
    const [pre, lista, extra] = EGNA[typ];
    const m = {};
    for (const k of lista.split(" ")) m[k] = pre + "." + k;
    Object.assign(m, extra);
    EGEN_NYCKEL[typ] = m;
  }
  const VAL_NYCKEL = {
    choose_markbom: "markbomlektion.choose", choose_galopp: "galopplektion.choose",
    choose_clearround: "clearround.choose", choose_hornet: "hornlektion.choose",
    choose_halvvolt: "halvvoltlektion.choose", choose_vag_mitt: "vaglektion.choose_mitt",
    choose_vag_diag: "vaglektion.choose_diag", choose_tempo: "tempolektion.choose",
    choose_serpentin: "serpentinlektion.choose", choose_overgang: "overganglektion.choose",
    choose_halt: "haltlektion.choose", choose: "voltlektion.choose",
    group_bojda: "lektionsval.bojda", group_gangart: "lektionsval.gangart", group_vagar: "lektionsval.vagar",
    back: "lektionsval.tillbaka", pick: "lektionsval.valj", choose_lesson: "lektionsval.oppna",
    group_linjer: "lektionsval.linjer", group_overgangar: "lektionsval.overgangar",
    lessons: "voltlektion.fri_traning",
  };
  const VOLT_NYCKEL = {};
  for (const k of "start retry finish sync intro approach ride line unknown complete timeout closed pending place active".split(" "))
    VOLT_NYCKEL[k] = "voltlektion." + k;

  /* Nyckeln en sidtext slås upp med — exponerad för paritets- och språkproven. */
  function nyckel(key, typNu) {
    if (VAL_NYCKEL[key]) return VAL_NYCKEL[key];
    const egen = EGEN_NYCKEL[typNu];
    if (egen && egen[key]) return egen[key];
    if (VOLT_NYCKEL[key]) return VOLT_NYCKEL[key];
    return "voltlektion.network";
  }
  const text = key => t(nyckel(key, S.typ));

  /* ── Tillståndet (Roblox modulens lokala) ──────────────────────────── */
  const S = {
    ritt: null, attached: false, valt: false, fri: false, meny: null, typ: "volt",
    bild: null, fel: null, lektioner: {}, gaLektion: null,
    halsning: null, halsadForsok: null, valGen: 0,
    coachForsok: null, coachSedd: 0, coachCd: 0, coachning: null,
    utanStreck: false, installLyssnare: null, minne: null,
  };

  /* ── Lektionsminnet ────────────────────────────────────────────────── */
  function minneNyckel(typ) {
    const T = LEKTION_TYPER[typ === "vag_mitt" || typ === "vag_diag" ? "vag" : typ];
    return T ? "lektion:" + typ + ":" + T.VERSION : null;
  }
  function lasMinne() {
    const betrodd = typeof SPAR !== "undefined" && !!SPAR && typeof SPAR_BETRODD !== "undefined" && SPAR_BETRODD === true;
    const lagrat = betrodd && SPAR.lektionsminne && typeof SPAR.lektionsminne === "object" ? SPAR.lektionsminne : {};
    const lektioner = {};
    for (const typ in MINNE_TYPER) {
      const k = minneNyckel(typ);
      lektioner[typ] = betrodd ? (k && lagrat[k] === true ? "sparad" : "ej_klarad") : "okand";
    }
    S.minne = { historik: betrodd ? "betrodd" : "okand", lektioner };
  }
  /* C4: övergången till "complete" — minnet noterar. Webbens sparning är
     synkron, så "vantar" (klarad men inte sparad än) uppstår aldrig. */
  /* LektionsMinne DEF.ok: resultatets identitet måste stämma för att en
     fullföljning ska räknas (Roblox LektionsMinne.luau). */
  const MINNE_OK = {
    volt: r => !!r.avsnitt && typeof r.avsnitt === "object",
    halt: r => r.mal === "X",
    overgang: r => r.mal === "T1->T2",
    serpentin: r => r.rutt === "serpentin-3",
    tempo: r => r.ovning === "jamn_skritt",
    vag_mitt: r => r.figur === "vag_mitt",
    vag_diag: r => r.figur === "vag_diag",
    halvvolt: r => r.figur === "halvvolt",
    galopp: r => r.ovning === "galoppfattning" && r.galoppsida === "ej_bedomd",
    markbom: r => r.ovning === "markbom" && r.passage === "rotplan",
    hornet: r => r.figur === "hornet" && r.mitt === true,
  };
  function vidKlar(s) {
    const typ = s && s.typ;
    if (!MINNE_TYPER[typ]) return;
    if (!s.resultat || !MINNE_OK[typ] || !MINNE_OK[typ](s.resultat)) return;
    if (!(typeof SPAR !== "undefined" && SPAR && typeof SPAR_BETRODD !== "undefined" && SPAR_BETRODD === true)) return;
    const k = minneNyckel(typ);
    if (!k) return;
    if (!SPAR.lektionsminne || typeof SPAR.lektionsminne !== "object") SPAR.lektionsminne = {};
    if (SPAR.lektionsminne[k] === true) { lasMinne(); return; }
    SPAR.lektionsminne[k] = true;
    if (typeof sparaRyttare === "function") sparaRyttare();
    lasMinne();
  }
  function klarad(typ) {
    const l = S.minne && S.minne.lektioner[typ];
    return l === "sparad" || l === "vantar";
  }
  function forslag() {
    const m = S.minne;
    if (!m || m.historik !== "betrodd") return [null, false];
    for (const typ of MINNE_ORDNING) if (!klarad(typ)) return [typ, false];
    return [MINNE_ORDNING[0], true];
  }

  /* ── Lektionsobjekten, ett per typ och ritt (serverns) ─────────────── */
  function lektion(typ) {
    let s = S.lektioner[typ];
    if (!s) { s = LektionMotor.ny(typ, S.ritt, vidKlar); S.lektioner[typ] = s; }
    return s;
  }
  function kontext() {
    if (typeof RittLektion === "undefined" || !RittLektion.aktiv()) return null;
    const g = typeof G !== "undefined" && G.ride ? G.ride.gangart : null;
    return RittLektion.kontext(typeof G !== "undefined" ? G.t : 0, RittLektion.tillRoblox(g));
  }
  const vagTyp = x => x === "vag_mitt" || x === "vag_diag";

  function mottag(b) {
    if (!S.attached || !S.ritt || !b || b.rittId !== S.ritt) return;
    if ((b.typ || "volt") !== S.typ) return;
    if (S.bild && b.revision < S.bild.revision) return;
    S.bild = b;
    if (S.typ === "tempo" && b.forsokId != null) {
      const nr = typeof b.coachNr === "number" && b.coachNr === b.coachNr ? b.coachNr : 0;
      const cg0 = S.coachning;
      if (cg0 && (b.forsokId !== cg0.forsokId || b.lage !== "steady" || b.tips !== cg0.skal)) S.coachning = null;
      if (S.coachForsok !== b.forsokId) { S.coachForsok = b.forsokId; S.coachSedd = nr; S.coachning = null; }
      else if (nr > S.coachSedd) {
        S.coachSedd = nr;
        const halsar = S.halsning != null && S.halsning.forsokId === b.forsokId;
        if (b.lage === "steady" && COACH_SKAL[b.coachSkal] && b.tips === b.coachSkal && S.coachCd <= 0 && !halsar && !S.fel) {
          S.coachCd = COACH_CD().fel;
          if (valfri()) S.coachning = { forsokId: b.forsokId, ritt: S.ritt, skal: b.coachSkal, kvar: COACH_CD().visa };
        }
      }
    }
  }

  function skicka(op) {
    if (!S.ritt) return;
    const typVid = S.typ, valVid = S.valGen;
    S.fel = null;
    S.halsning = null;
    S.coachning = null;
    const s = lektion(S.typ);
    const X = kontext();
    if (op === "sync") {
      if (X) LektionMotor.steg(s, X);
      mottag(LektionMotor.bild(s));
      return;
    }
    let ok = false, reason = null;
    /* RidForsok: ett aktivt försök per ritt, oavsett lektion. */
    const annan = Object.keys(S.lektioner).some(k => k !== S.typ && LektionMotor.aktiv(S.lektioner[k]));
    if (op !== "finish" && annan) reason = "active";
    else if (!X && op !== "finish") reason = "place";
    else [ok, reason] = LektionMotor.begar(s, op, X || {});
    const b = LektionMotor.bild(s);
    mottag(b);
    if (ok && (op === "start" || op === "retry") && S.typ === typVid && S.valGen === valVid
      && b.forsokId != null && S.bild && S.bild.forsokId === b.forsokId && AKTIVA_LAGEN[S.bild.lage]
      && S.halsadForsok !== b.forsokId) {
      S.halsadForsok = b.forsokId;
      if (valfri()) S.halsning = { forsokId: b.forsokId, typ: typVid, ritt: S.ritt, kvar: HALSNING_S };
    }
    if (!ok) S.fel = reason === "place" || reason === "pole" || reason === "course" ? reason
      : reason === "active" ? "active" : "network";
    else if (op === "finish") { S.valt = false; S.fri = true; S.meny = null; }
  }

  function valj(vald) {
    if (!S.ritt) return;
    const ny = TYPER.includes(vald) ? vald : "volt";
    if (ny !== S.typ) { S.typ = ny; S.bild = null; S.utanStreck = false; }
    S.halsning = null;
    S.valGen++;
    S.coachning = null; S.coachForsok = null;
    S.valt = true; S.fri = false; S.fel = null; S.meny = null;
    skicka("sync");
  }

  /* ── Knappar och sidor (V.panel) ───────────────────────────────────── */
  const val = (key, fn) => ({ text: text(key), gor: fn, nyckel: nyckel(key, S.typ) });
  const valNyckel = typ => (typ === "volt" ? "choose" : "choose_" + typ);
  function valLektion(typ) {
    const k = val(valNyckel(typ), () => valj(typ));
    const l = S.minne && S.minne.lektioner[typ];
    if (l === "sparad") k.text += t("lektionsminne.markering.sparad");
    else if (l === "vantar") k.text += t("lektionsminne.markering.vantar");
    if (forslag()[0] === typ) k.text += t("lektionsminne.markering.forslag");
    k.lektion = typ;
    return k;
  }
  function valGrupp(key, grupp, fn) {
    const k = val(key, fn);
    const typ = forslag()[0];
    if (typ && (MINNE_GRUPP[typ] === grupp || MINNE_UNDERGRUPP[typ] === grupp))
      k.text += t("lektionsminne.markering.forslag");
    k.grupp = grupp;
    return k;
  }
  function forslagsRad() {
    const [typ, igen] = forslag();
    if (!typ) return null;
    const namn = text(valNyckel(typ));
    const grupp = MINNE_GRUPP[typ];
    if (grupp) return t(igen ? "lektionsminne.igen_var" : "lektionsminne.forslag_var", namn,
      text(grupp === "gangart" ? "group_gangart" : "group_vagar"));
    return t(igen ? "lektionsminne.igen_rad" : "lektionsminne.forslag_rad", namn);
  }
  function minnesRad() {
    const m = S.minne;
    if (!m || m.historik !== "betrodd") return t("lektionsminne.okand");
    for (const typ in m.lektioner) if (m.lektioner[typ] === "vantar") return t("lektionsminne.vantar_info");
    return null;
  }
  const medMinne = x => { const r = minnesRad(); return r ? x + " " + r : x; };
  function forslagsKnapp() {
    const [typ, igen] = forslag();
    if (!typ) return null;
    const k = val(valNyckel(typ), () => { if (forslag()[0] === typ) valj(typ); });
    k.text = t(igen ? "lektionsminne.igen" : "lektionsminne.forslag", text(valNyckel(typ)));
    k.lektion = typ;
    return k;
  }
  const sida = (knappar, txt) => ({ ersatt: true, text: txt, knappar, meny: S.meny });

  function panel() {
    if (!S.attached || !S.ritt) return null;
    if (!S.valt) {
      if (S.meny === "gangart")
        return sida([valLektion("halt"), valLektion("tempo"),
          valGrupp("group_overgangar", "overgangar", () => { S.meny = "overgangar"; }),
          val("back", () => { S.meny = null; })], medMinne(text("pick")));
      if (S.meny === "overgangar")
        return sida([valLektion("overgang"), valLektion("galopp"),
          val("back", () => { S.meny = "gangart"; })], medMinne(text("pick")));
      if (S.meny === "vagar")
        return sida([valGrupp("group_bojda", "bojda", () => { S.meny = "bojda"; }),
          valGrupp("group_linjer", "linjer", () => { S.meny = "linjer"; }),
          valLektion("clearround"),
          val("back", () => { S.meny = null; })], medMinne(text("pick")));
      if (S.meny === "bojda")
        return sida([valLektion("serpentin"), valLektion("halvvolt"), valLektion("hornet"),
          val("back", () => { S.meny = "vagar"; })], medMinne(text("pick")));
      if (S.meny === "linjer")
        return sida([valLektion("vag_mitt"), valLektion("vag_diag"), valLektion("markbom"),
          val("back", () => { S.meny = "vagar"; })], medMinne(text("pick")));
      if (S.meny === "topp") {
        const rad = forslagsRad();
        const x = medMinne(text("pick"));
        return sida([valLektion("volt"),
          valGrupp("group_gangart", "gangart", () => { S.meny = "gangart"; }),
          valGrupp("group_vagar", "vagar", () => { S.meny = "vagar"; }),
          val("back", () => { S.meny = null; })], rad ? x + " " + rad : x);
      }
      const knappar = [valLektion("volt"),
        valGrupp("group_gangart", "gangart", () => { S.meny = "gangart"; }),
        valGrupp("group_vagar", "vagar", () => { S.meny = "vagar"; })];
      let forslagsText = null;
      if (S.fri) {
        knappar.push(val("lessons", () => { S.fri = false; if (S.gaLektion) S.gaLektion(); }));
        const rad = forslagsRad(), mt = minnesRad();
        if (rad || mt) forslagsText = [rad || "", mt || ""].filter(Boolean).join(" ");
      } else {
        const fk = forslagsKnapp();
        if (fk) knappar.push(fk);
      }
      return { ersatt: S.fri, knappar, text: forslagsText, meny: null,
        kompakt: S.fri ? null : [val("choose_lesson", () => { S.meny = "topp"; })] };
    }
    const b = S.bild || { lage: "ready", progress: 0, tips: "approach" };
    const key = S.fel ? S.fel : b.lage === "ready" || b.lage === "closed" ? "intro" : b.tips;
    let txt = text(key);
    if (key === "line" && S.typ === "volt") {
      if (b.linjeSida === "ut") txt = t("voltlektion.line_ut");
      else if (b.linjeSida === "in") txt = t("voltlektion.line_in");
    }
    if (S.typ === "clearround" && key === "intro" && b.forraAvbruten && b.forraAvbruten.utfall === "avbruten")
      txt = t(b.forraAvbruten.orsak === "avsittning" ? "clearround.forra_avbruten_avsittning" : "clearround.forra_avbruten") + " " + txt;
    const svenska = () => (typeof SPRAKET === "undefined" || SPRAKET !== "en");
    if (S.typ === "clearround" && key === "startlista" && b.anmalan && typeof b.anmalan.startnummer === "number"
      && typeof b.anmalan.anmalda === "number" && typeof b.anmalan.hojdM === "number") {
      let hojd = b.anmalan.hojdM.toFixed(2);
      if (svenska()) hojd = hojd.replace(".", ",");
      txt = t("clearround.startlista", hojd, b.anmalan.startnummer, b.anmalan.anmalda);
    } else if (S.typ === "clearround" && key === "banskiss" && b.referens && Array.isArray(b.referens.hinder)
      && b.referens.hinder.length > 0) {
      const delar = b.referens.hinder.map((h, i) => t("clearround.banskiss_hinder", i + 1,
        h.farg === "rod" ? t("clearround.farg_rod") : t("clearround.farg_bla"), h.mot === "A" ? "A" : "C"));
      txt = t("clearround.banskiss", delar.join(" · "), b.referens.hinder.length);
    }
    if (S.typ === "clearround" && key === "jump" && b.nasta && typeof b.nasta.nr === "number")
      txt = t("clearround.hopp", b.nasta.nr, b.nasta.farg === "rod" ? t("clearround.farg_rod") : t("clearround.farg_bla"),
        b.nasta.mot === "A" ? "A" : "C");
    if (S.typ === "overgang" && key === "trot_outside") {
      if (b.malSida === "fore") txt = t("overganglektion.trot_early");
      else if (b.malSida === "efter") txt = t("overganglektion.trot_late");
    } else if (S.typ === "overgang" && key === "walk_outside") {
      if (b.malSida === "fore") txt = t("overganglektion.walk_early");
      else if (b.malSida === "efter") txt = t("overganglektion.walk_late");
    } else if (S.typ === "galopp" && key === "canter_outside") {
      if (b.malSida === "fore") txt = t("galopplektion.canter_early");
      else if (b.malSida === "efter") txt = t("galopplektion.canter_late");
    }
    if (!S.fel) {
      const at = LektionAterkoppling.text(b, { typ: S.typ, ritt: S.ritt });
      if (at) txt = at;
    }
    if (S.halsning && kommentarer() === "inga") S.halsning = null;
    if (S.coachning && kommentarer() === "inga") S.coachning = null;
    const cg = S.coachning;
    if (cg) {
      if (cg.ritt === S.ritt && S.typ === "tempo" && b.forsokId === cg.forsokId && b.lage === "steady"
        && b.tips === cg.skal && !S.fel && S.halsning == null)
        txt = t("tempocoach." + cg.skal) + " " + txt;
      else if (S.fel || cg.ritt !== S.ritt || S.typ !== "tempo" || b.forsokId !== cg.forsokId
        || b.lage !== "steady" || b.tips !== cg.skal) S.coachning = null;
    }
    const h = S.halsning;
    if (h) {
      if (h.ritt === S.ritt && h.typ === S.typ && b.forsokId === h.forsokId && AKTIVA_LAGEN[b.lage] && !S.fel)
        txt = t("halsning." + h.typ) + " " + txt;
      else if (S.fel || h.ritt !== S.ritt || h.typ !== S.typ || b.forsokId !== h.forsokId || !AKTIVA_LAGEN[b.lage])
        S.halsning = null;
    }
    if (PROCENT_LAGEN[b.lage] && !S.fel) txt += " " + String(b.progress) + "%";
    const knappar = [];
    if (S.fel === "network") knappar.push(val("sync", () => skicka("sync")));
    else if (S.typ === "clearround" && (b.lage === "ready" || b.lage === "closed"))
      /* D5, webben: bara «Egna kläder» (P3 § 11.1, godkänt plattformsundantag).
         Klädknappen visas inte — serverns val-lista är tom här, precis som
         Roblox när katalogen saknar set. */
      knappar.push(val("anmal", () => skicka("anmal")));
    else if (S.typ === "clearround" && b.lage === "startlista") knappar.push(val("ga_banan", () => skicka("ga_banan")));
    else if (S.typ === "clearround" && b.lage === "banskiss") knappar.push(val("start", () => skicka("start")));
    else if (b.lage === "ready" || b.lage === "closed") knappar.push(val("start", () => skicka("start")));
    else if ((b.lage === "complete" || b.lage === "timeout")
      && (S.typ !== "clearround" || (b.resultat && b.resultat.omstartMojlig === true)))
      knappar.push(val("retry", () => skicka("retry")));
    if ((vagTyp(S.typ) || S.typ === "hornet" || S.typ === "halvvolt" || S.typ === "markbom")
      && (S.utanStreck || klarad(S.typ))) {
      const k2 = S.utanStreck ? "visa_vagen"
        : S.typ === "hornet" || S.typ === "halvvolt" || S.typ === "markbom" ? "mindre_stod" : "utan_streck";
      knappar.push(val(k2, () => { S.utanStreck = !S.utanStreck; }));
    }
    knappar.push(val("finish", () => skicka("finish")));
    return { ersatt: true, knappar, text: txt, ovning: txt, meny: null };
  }

  /* ── Livscykeln ────────────────────────────────────────────────────── */
  function start(ritt, gaLektion) {
    const samma = S.ritt === ritt;
    S.halsning = null;
    S.valGen++;
    S.coachning = null; S.coachForsok = null;
    if (!samma) S.halsadForsok = null;
    if (!S.installLyssnare && inst())
      S.installLyssnare = inst().vidByte(() => {
        if (kommentarer() === "inga") { S.halsning = null; S.coachning = null; }
      });
    if (!samma) {
      S.valt = false; S.fri = false; S.bild = null; S.meny = null; S.utanStreck = false;
      S.lektioner = {};
    }
    S.ritt = ritt; S.gaLektion = gaLektion || null; S.fel = null;
    S.attached = true;
    lasMinne();
    if (S.valt) skicka("sync");
  }

  function steg(dt) {
    const d = typeof dt === "number" && dt === dt && dt > 0 ? Math.min(dt, 1) : 0;
    if (S.coachCd > 0) S.coachCd -= d;
    if (S.coachning) { S.coachning.kvar -= d; if (S.coachning.kvar <= 0) S.coachning = null; }
    if (S.halsning) { S.halsning.kvar -= d; if (S.halsning.kvar <= 0) S.halsning = null; }
  }

  /* Ett observationssteg: den valda lektionen stegas en gång (servern). */
  function observation(X) {
    if (!S.attached || !S.ritt || !X) return;
    for (const typ in S.lektioner) {
      const s = S.lektioner[typ];
      if (LektionMotor.aktiv(s) || typ === S.typ) LektionMotor.steg(s, X);
    }
    if (S.valt && S.lektioner[S.typ]) mottag(LektionMotor.bild(S.lektioner[S.typ]));
  }

  const tarOver = () => S.attached && (S.valt || S.fri);
  const valtNu = () => S.attached && S.valt;

  /* Ritten tar slut (avsittning, scenbyte): ett aktivt försök avbryts, med
     clear rounds eget utfall «avbruten». Valet behålls bara för samma ritt. */
  function avbryt(X) {
    for (const typ in S.lektioner) LektionMotor.avbryt(S.lektioner[typ], X || kontext() || { o: { tid: 0 } });
    S.attached = false;
    S.utanStreck = false;
    S.halsning = null;
    S.valGen++;
    S.coachning = null; S.coachForsok = null;
  }

  /* Vägvisningen som ska ritas — samma villkor som Roblox `mottag`. */
  function guide() {
    if (!S.attached || !S.valt || !S.bild || !GUIDE_LAGEN[S.bild.lage]) return null;
    const b = S.bild;
    if (!b.referens) return null;
    const delmal = S.typ === "serpentin" || vagTyp(S.typ) || S.typ === "halvvolt" || S.typ === "hornet"
      || S.typ === "clearround" ? b.delmal
      : S.typ === "markbom" ? (b.lage === "exit" ? 2 : b.lage === "crossing" ? 1 : 0) : null;
    const utan = S.utanStreck && (vagTyp(S.typ) || S.typ === "hornet" || S.typ === "halvvolt" || S.typ === "markbom");
    return { typ: S.typ, referens: b.referens, delmal, utan };
  }

  return { start, steg, observation, panel, valj, skicka, avbryt, guide, tarOver, lektion: valtNu,
    nyckel, forslag, lasMinne,
    MINNE_ORDNING, MINNE_TYPER, MINNE_GRUPP, MINNE_UNDERGRUPP,
    _S: S, _minneNyckel: minneNyckel };
})();

if (typeof window !== "undefined") window.Lektionsmeny = Lektionsmeny;
