/* ══════════════════════════════════════════════════════════════════
   FRI TRÄNING MED ÅTERSPELNING — port av roblox/src/client/
   LektionController.luau och roblox/src/shared/HorseCore/Lektion.luau
   (P3 § 1.4, docs/FREE-PRACTICE-FRAMING-CONTRACT.md).

   Passet går från uppsittningen så länge ingen lektion är vald: Ugnetas
   sex övningar i kanonens ordning (UGNETA_OVNINGAR i src/larare.js — samma
   rader som RidKanon.UGNETA.ORDNING), rundor på FORSOK_SEK = 22 s, två
   försök per övning.

   LÄGEN (Roblox `lage`):
     "ny"           en övning ska presenteras
     "presentation" kortet uppe; spelaren väljer när rundan börjar
     "rider"        DET ENDA läget där något mäts
     "efter"        återkopplingen uppe; spelaren väljer att gå vidare
     "ingen"        passet är slut — ritten fortsätter tills hon sitter av

   ETT KORT ÄR INGET RÖRELSELÅS. En hjälp (skänkeln upp, en parad ned)
   besvarar kortet och verkar i samma bildruta — som Roblox init.client
   (#263 P1). Bara återspelningen pausar ridningen.

   MÄTNINGEN är webbens egen och oförändrad: ugnetaKvalitet/ugnetaForsokSteg
   i src/larare.js mäter och spelar in försöket, och observationerna efter
   rundan rangordnas med Roblox HorseCore/Ugneta.observationer — med
   språknycklar (ugneta.obs.*, ugneta.dim.*), aldrig svenska literaler. ── */

const FriPass = (() => {
  const t = (k, ...a) => (typeof tSpr === "function" ? tSpr(k, ...a) : k);
  const FORSOK_SEK = 22;
  const MAX_OBS = 2;
  const ordning = () => (typeof UGNETA_OVNINGAR !== "undefined" ? UGNETA_OVNINGAR.map(o => o.id) : []);
  const P = { pass: null, lage: "ingen", kort: null, liveCd: 0, liveSagt: "", brasedan: 0 };

  function ovningId() { const p = P.pass; return p ? ordning()[p.ix - 1] || null : null; }
  const finns = k => typeof SPRAK !== "undefined" && !!SPRAK[k];
  function kortText(id, del, reserv) { const k = "ugneta.ovning." + id + "." + del; return finns(k) ? t(k) : reserv; }

  /* Momentet G.moment pekar på — webbens Ugneta-mätning läser det. */
  function sattMoment() {
    const id = ovningId();
    const o = id && typeof ugnetaOvningMed === "function" ? ugnetaOvningMed(id) : null;
    G.moment = o ? { id: "fri_" + id, ovning: id, namn: kortText(id, "rubrik", o.rubrik), tid: FORSOK_SEK,
      bedoms: false, fri: true } : null;
    G.momentT = 0; G.momentKlart = false;
  }

  function nyttPass() {
    P.pass = { ix: 1, forsokNr: 1, klar: false };
    P.lage = "ny"; P.kort = null; P.liveCd = 0; P.liveSagt = ""; P.brasedan = 0;
    if (typeof lararNollstall === "function") lararNollstall();
    if (typeof lararValjFokus === "function") lararValjFokus();
    G.momentIx = 0; G.momentForsok = 1;
    sattMoment();
  }

  /* ── Rangordningen: HorseCore/Ugneta.observationer, samma tal ─────── */
  function observationer(id, nu, fore) {
    const KV = typeof UGNETA_KVALITET !== "undefined" ? UGNETA_KVALITET : { BATTRE: 0.045, SVAG: 0.68, BRA: 0.55 };
    const dims = (typeof UGNETA_OVNING_DIM !== "undefined" && UGNETA_OVNING_DIM[id]) || ["rytm", "balans", "mjukhet"];
    const har = v => v !== null && v !== undefined && isFinite(v);
    const ut = [];
    if (fore) {
      let bast = null, bastD = KV.BATTRE;
      for (const k of dims) if (har(nu[k]) && har(fore[k])) { const d = nu[k] - fore[k]; if (d >= bastD) { bast = k; bastD = d; } }
      if (bast) ut.push({ dim: bast, sort: "battre" });
      let svag = null, svagV = KV.SVAG;
      for (const k of dims) { const v = nu[k]; if (har(v) && k !== bast && v < svagV) { svag = k; svagV = v; } }
      if (svag) ut.push({ dim: svag, sort: "kvar" });
    } else {
      let bast = null, bastV = KV.BRA;
      for (const k of dims) { const v = nu[k]; if (har(v) && v >= bastV) { bast = k; bastV = v; } }
      if (bast) ut.push({ dim: bast, sort: "bra" });
      let svag = null, svagV = Infinity;
      for (const k of dims) { const v = nu[k]; if (har(v) && k !== bast && v < svagV) { svag = k; svagV = v; } }
      if (svag) ut.push({ dim: svag, sort: "forbattra" });
    }
    return ut.slice(0, MAX_OBS);
  }
  const OBS_NYCKEL = { battre: "ugneta.obs.battre", kvar: "ugneta.obs.kvar", bra: "ugneta.obs.bra", forbattra: "ugneta.obs.jobba" };

  /* Kortet är en BYGGARE: texten slås upp vid varje ritning, på det språk
     som gäller då (Roblox #264). */
  function presentera() {
    const id = ovningId();
    const o = id && typeof ugnetaOvningMed === "function" ? ugnetaOvningMed(id) : null;
    if (!o) return;
    P.kort = () => ({ rubrik: kortText(id, "rubrik", o.rubrik),
      punkter: o.punkter.map((r, i) => kortText(id, "p" + (i + 1), r)),
      knapp: t("ugneta.borja_fri_traning", FORSOK_SEK), replay: false, vidare: false });
    /* ÖVNINGEN står kvar som vägledning medan rundan rids (Roblox: bannerns
       etiketter står kvar när bannern tonat ut). */
    P.ovning = P.kort;
    P.lage = "presentation";
  }

  /* Lektion.avslutaForsok: `fore` är historikens förra post för övningen
     (Roblox `lista[#lista]` före insättningen); ett försök utan underlag
     läggs aldrig in, så posten räknas ur listans längd — inte ur numret. */
  function avslutaForsok() {
    const p = P.pass, id = ovningId();
    const historik = () => (typeof ugnetaForsokHistorik === "function" ? ugnetaForsokHistorik(id) : []);
    const fore0 = historik().length;
    if (typeof ugnetaStangForsok === "function") ugnetaStangForsok();
    const lista = historik();
    const matt = lista.length > fore0 ? lista[lista.length - 1] : null;
    const forraPost = matt && lista.length >= 2 ? lista[lista.length - 2] : null;
    const forsta = p.forsokNr < 2;
    P.replayNr = matt ? lista.length : null;
    const kanSe = !!matt && typeof replayFinns === "function" && replayFinns(id, lista.length);
    if (matt) {
      const nu = {}, fore = forraPost ? {} : null;
      for (const k in matt) if (k !== "__post") nu[k] = matt[k];
      if (fore) for (const k in forraPost) if (k !== "__post") fore[k] = forraPost[k];
      const obs = observationer(id, nu, fore);
      P.kort = () => {
        const punkter = obs.map(o => t(OBS_NYCKEL[o.sort], t("ugneta.dim." + o.dim)));
        if (!punkter.length) punkter.push(t("ugneta.jamnare_forsok"));
        return { rubrik: t("ugneta.runda_slut", p.forsokNr, FORSOK_SEK), punkter,
          knapp: t(forsta ? "ugneta.prova_igen" : "ugneta.nasta_ovning"), replay: kanSe, vidare: forsta };
      };
    } else {
      P.kort = () => ({ rubrik: t("ugneta.ej_bedomd.rubrik"), punkter: [t("ugneta.ej_bedomd.punkt")],
        knapp: t(forsta ? "ugneta.prova_igen" : "ugneta.nasta_ovning"), replay: kanSe, vidare: forsta });
    }
    P.lage = "efter";
    P.liveCd = 0; P.liveSagt = "";
  }

  /* Lektion.vidare: nästa försök på samma övning, eller nästa övning. */
  function vidare() {
    const p = P.pass;
    if (p.forsokNr < 2) p.forsokNr++;
    else { p.ix++; p.forsokNr = 1; if (p.ix > ordning().length) p.klar = true; }
  }
  /* Lektion.hoppaOver: spelaren nöjer sig med försöket. */
  function hoppaOver() {
    const p = P.pass;
    p.ix++; p.forsokNr = 1;
    if (p.ix > ordning().length) p.klar = true;
  }

  function borjaRunda() {
    const p = P.pass;
    G.momentForsok = p.forsokNr;
    sattMoment();
    if (typeof ugnetaNyttForsok === "function" && G.moment) ugnetaNyttForsok(G.moment, p.forsokNr);
    P.lage = "rider";
  }

  /* Kortets huvudknapp — eller en hjälp. */
  function fortsatt() {
    if (!P.pass || !P.kort) return false;
    const p = P.pass;
    if (P.lage === "presentation") { P.kort = null; borjaRunda(); return true; }
    if (P.lage === "efter") {
      const forra = p.ix;
      P.kort = null;
      vidare();
      if (p.klar) { P.lage = "ingen"; G.moment = null; }
      else if (p.ix === forra) borjaRunda();
      else { P.lage = "ny"; G.momentIx = p.ix - 1; sattMoment(); }
      P.liveCd = 0; P.liveSagt = "";
      return true;
    }
    return false;
  }
  function gaVidare() {
    if (!P.pass || P.lage !== "efter" || !P.kort || !P.kort().vidare) return false;
    P.kort = null;
    hoppaOver();
    if (P.pass.klar) { P.lage = "ingen"; G.moment = null; }
    else { P.lage = "ny"; G.momentIx = P.pass.ix - 1; sattMoment(); }
    P.liveCd = 0; P.liveSagt = "";
    return true;
  }
  function seRitten() {
    if (!P.pass || !P.kort || !P.kort().replay) return false;
    /* Återspelningen är det enda som pausar ritten (Roblox init.client). */
    const ok = typeof visaReplay === "function" && visaReplay(ovningId(), P.replayNr);
    if (ok) G.paus = true;
    return ok;
  }

  /* ── Live-registret: några ord, aldrig ett kort (lararSteg, med nycklar) ─ */
  function live(dt) {
    const L = typeof LARARE !== "undefined" ? LARARE : null;
    if (!L || !L.fokus || !G.ride) return;
    P.liveCd -= dt;
    const F = L.fokus;
    const bra = !!(F.bra && F.bra());
    P.brasedan = bra ? P.brasedan + dt : 0;
    if (P.liveCd > 0) return;
    const braNu = bra && P.brasedan > 6;
    const nyckel = "ugneta.live." + F.id + "." + (braNu ? "bra" : "fel");
    if (!finns(nyckel) || nyckel === P.liveSagt) return;
    const CD = typeof UGNETA_LIVE_CD !== "undefined" ? UGNETA_LIVE_CD : { bra: 14, fel: 8, visa: 2.6 };
    P.liveCd = braNu ? CD.bra : CD.fel;
    P.liveSagt = nyckel;
    if (typeof LararInstallning !== "undefined" && !LararInstallning.valfriKommentar()) return;
    P.chip = { nyckel, bra: braNu, kvar: CD.visa };
  }

  /* En bildruta. `hjalp` = ryttaren gav en gångartshjälp just nu. */
  function steg(dt, hjalp) {
    if (P.chip) { P.chip.kvar -= dt; if (P.chip.kvar <= 0) P.chip = null; }
    const p = P.pass;
    if (!p || p.klar) return;
    if (P.lage === "ny") { presentera(); return; }
    if (hjalp && P.kort) fortsatt();
    if (P.lage !== "rider") return;
    G.momentT += dt;
    if (typeof ugnetaForsokSteg === "function") ugnetaForsokSteg(dt);
    live(dt);
    if (G.momentT < FORSOK_SEK) return;
    G.momentKlart = true;
    avslutaForsok();
  }

  function avbryt() {
    P.pass = null; P.lage = "ingen"; P.kort = null; P.chip = null;
    G.moment = null;
    if (typeof stangReplay === "function" && typeof REPLAY !== "undefined" && REPLAY.up) stangReplay();
  }

  /* Ugnetas kortknappar, i Roblox ordning: huvudknappen, Se ritten, Gå vidare. */
  function knappar() {
    if (!P.kort) return [];
    const k = P.kort(), ut = [];
    ut.push({ text: k.knapp, gor: fortsatt, paTur: true, nyckel: "fri.fortsatt" });
    if (k.replay) ut.push({ text: t("ugneta.se_ritten"), gor: seRitten, nyckel: "ugneta.se_ritten" });
    if (k.vidare) ut.push({ text: t("ugneta.ga_vidare"), gor: gaVidare, nyckel: "ugneta.ga_vidare" });
    return ut;
  }
  /* Bannerns text: «rubrik — punkter». */
  function kortRad() {
    if (!P.kort) return null;
    const k = P.kort();
    const d = k.punkter.filter(Boolean).join(" ");
    return d ? k.rubrik + " — " + d : k.rubrik;
  }
  const chip = () => (P.chip ? t(P.chip.nyckel) : null);
  function ovningsRad() {
    if (P.lage !== "rider" || !P.ovning) return null;
    const k = P.ovning();
    const d = k.punkter.filter(Boolean).join(" ");
    return d ? k.rubrik + " — " + d : k.rubrik;
  }

  return { FORSOK_SEK, nyttPass, steg, fortsatt, gaVidare, seRitten, avbryt, knappar, kortRad, chip, ovningsRad,
    lage: () => P.lage, pagar: () => !!P.pass && !P.pass.klar, vantar: () => !!P.kort,
    ovningId, observationer, _P: P };
})();

if (typeof window !== "undefined") window.FriPass = FriPass;
