/* ══════════════════════════════════════════════════════════════════
   UGNETAS ÅTERKOPPLING NÄR EN ÖVNING ÄR SLUT — port av
   roblox/src/client/LektionsAterkoppling.luau (P3 § 6).

   EN liten formaterare för ridlektionerna. Den bygger bara på det FRYSTA
   resultatet för det visade försöket och lägger till ett nästa övnings-
   steg. Inget betyg, ingen gemensam mätare, ingen belöning. Texten räknas
   fram vid varje ritning ur aktuell bild och aktuellt språk och sparas
   aldrig — ett språkbyte kan därför aldrig lämna en gammal sammanfattning.

   BEVIS ÄR BEVIS. Ett fält som saknas, har fel typ eller inte är ett
   ändligt tal är INTE ett uppmätt noll — då blir texten ärlig
   (`aterkoppling.okant`). Ledningslektionen (`leda`) hör till P1/P2 och
   har ingen webbproducent här; grenen finns inte. ── */

const LektionAterkoppling = (() => {
  const t = (k, ...a) => (typeof tSpr === "function" ? tSpr(k, ...a) : k);
  const sprakNu = () => (typeof SPRAKET !== "undefined" ? SPRAKET
    : typeof window !== "undefined" && window.SPRAKET ? window.SPRAKET : "sv");
  const inst = () => (typeof LararInstallning !== "undefined" ? LararInstallning : null);
  const kort = () => { const I = inst(); return !!I && I.detalj() === "kort"; };

  const fin = x => typeof x === "number" && isFinite(x);
  const ickeNeg = x => fin(x) && x >= 0;
  const heltal = x => ickeNeg(x) && x % 1 === 0;
  const lista = x => Array.isArray(x);
  function tal(x, dec) {
    const s = x.toFixed(dec == null ? 1 : dec);
    return sprakNu() === "sv" ? s.replace(".", ",") : s;
  }

  function sammanfattning(typ, r) {
    if (typ === "volt") {
      const a = r.avsnitt;
      if (!a || !a.referens) return null;
      if (!(heltal(a.varv) && a.varv >= 1 && fin(a.referens.radie) && a.referens.radie > 0
        && ickeNeg(a.medelAvvikelse) && ickeNeg(a.tid))) return null;
      return t("aterkoppling.volt.klar", String(a.varv), tal(a.referens.radie, 0), tal(a.medelAvvikelse), tal(a.tid, 0));
    } else if (typ === "halt") {
      if (r.mal !== "X" || !(ickeNeg(r.skrittMeter) && ickeNeg(r.haltSekunder))) return null;
      return t("aterkoppling.halt.klar", tal(r.skrittMeter), tal(r.haltSekunder));
    } else if (typ === "overgang") {
      if (r.mal !== "T1->T2" || !(ickeNeg(r.travMeter) && ickeNeg(r.skrittMeter))) return null;
      return t("aterkoppling.overgang.klar", tal(r.travMeter), tal(r.skrittMeter));
    } else if (typ === "serpentin") {
      if (r.rutt !== "serpentin-3" || !(ickeNeg(r.meter) && lista(r.korsningar))) return null;
      return t("aterkoppling.serpentin.klar", tal(r.meter, 0), String(r.korsningar.length));
    } else if (typ === "tempo") {
      if (r.ovning !== "jamn_skritt" || r.enhet !== "m/s") return null;
      if (!(ickeNeg(r.meter) && ickeNeg(r.sekunder) && fin(r.medelFart) && r.medelFart > 0 && ickeNeg(r.spridning))) return null;
      return t("aterkoppling.tempo.klar", tal(r.meter), tal(r.sekunder), tal(r.medelFart, 2), tal(r.spridning * 100, 0));
    } else if (typ === "vag_mitt" || typ === "vag_diag") {
      if (r.figur !== typ || !(ickeNeg(r.meter) && fin(r.langd) && r.langd > 0)) return null;
      return t("aterkoppling." + typ + ".klar", tal(r.meter), tal(r.langd));
    } else if (typ === "halvvolt") {
      if (r.figur !== "halvvolt" || !(ickeNeg(r.meter) && lista(r.skarvar) && fin(r.skuld))) return null;
      let text = t("aterkoppling.halvvolt.klar", tal(r.meter), String(r.skarvar.length));
      if (r.skuld > 0.05) text += " " + t("aterkoppling.halvvolt.skuld", tal(r.skuld));
      return text;
    } else if (typ === "galopp") {
      if (r.ovning !== "galoppfattning" || r.galoppsida !== "ej_bedomd") return null;
      if (!(ickeNeg(r.travMeter) && ickeNeg(r.galoppMeter))) return null;
      return t("aterkoppling.galopp.klar", tal(r.travMeter), tal(r.galoppMeter));
    } else if (typ === "markbom") {
      if (r.ovning !== "markbom" || r.passage !== "rotplan") return null;
      if (!(ickeNeg(r.inridningM) && ickeNeg(r.utridningM))) return null;
      return t("aterkoppling.markbom.klar", tal(r.inridningM), tal(r.utridningM));
    } else if (typ === "hornet") {
      if (r.figur !== "hornet" || r.mitt !== true || !(ickeNeg(r.meter) && fin(r.langd) && r.langd > 0)) return null;
      return t("aterkoppling.hornet.klar", tal(r.meter), tal(r.langd));
    } else if (typ === "clearround") {
      /* Den FÖRENKLADE bedömningen: aldrig "felfri", aldrig rosett. */
      if (r.ovning !== "clearround" || r.bedomning !== "forenklad" || !(r.forsokNr === 1 || r.forsokNr === 2)) return null;
      if (r.tid != null && !ickeNeg(r.tid)) return null;
      const tid = r.tid != null ? tal(r.tid, 0) : "–";
      let rad = null;
      if (r.utfall === "inga_observerade_fel") rad = t("aterkoppling.clearround.inga_fel", tid);
      else if (r.utfall === "observerade_fel") {
        if (!heltal(r.olydnader)) return null;
        rad = r.fel != null && heltal(r.fel)
          ? t("aterkoppling.clearround.fel", String(r.olydnader), String(r.fel), tid)
          : t("aterkoppling.clearround.fel_okand", String(r.olydnader), tid);
      } else if (r.utfall === "utesluten") {
        rad = r.orsak === "fel_vag" ? t("aterkoppling.clearround.utesluten_fel_vag")
          : r.orsak === "tillaten_tid" ? t("aterkoppling.clearround.utesluten_tid")
          : r.orsak === "olydnader" ? t("aterkoppling.clearround.utesluten_olydnader") : null;
      } else if (r.utfall === "utesluten_ej_faststalld") rad = t("aterkoppling.clearround.utesluten_okand");
      else if (r.utfall === "ej_startad") rad = t("aterkoppling.clearround.ej_startad");
      else if (r.utfall === "ej_bedomd") rad = t("aterkoppling.clearround.ej_bedomd");
      else if (r.utfall === "avbruten") rad = t("aterkoppling.clearround.avbruten");
      if (!rad) return null;
      if (r.omstartMojlig === true) rad += " " + t("aterkoppling.clearround.omstart");
      return rad + " " + t("aterkoppling.clearround.forenklad");
    }
    return null;
  }

  const NARMARE = {
    volt: { narmare: "aterkoppling.volt.narmare", forra: "aterkoppling.volt.forra", kort: "aterkoppling.volt.narmare_kort" },
    halt: { narmare: "aterkoppling.halt.narmare", forra: "aterkoppling.halt.forra", kort: "aterkoppling.halt.narmare_kort" },
  };

  /* Hör resultatet till det VISADE försöket i den här ritten och typen? */
  function tillhor(b, kontext) {
    const r = b && b.resultat;
    if (!r) return false;
    return b.forsokId != null && r.forsokId === b.forsokId && b.rittId != null && r.rittId === b.rittId
      && b.rittId === kontext.ritt && (b.typ || "volt") === kontext.typ;
  }

  /* Texten för ett avslutat försök, eller null när bilden inte är avslutad
     (då gäller lektionens vanliga text). `kontext` = { typ, ritt }. */
  function text(b, kontext) {
    if (!b || !kontext) return null;
    const typ = kontext.typ;
    if (b.lage === "complete") {
      let s = tillhor(b, kontext) ? sammanfattning(typ, b.resultat) : null;
      if (!s) return t("aterkoppling.okant");
      if (kort() && typ !== "clearround") s = t("aterkoppling." + typ + ".kort");
      const j = b.jamforelse;
      if (typ === "tempo" && j && j.forsokId === b.forsokId && j.forraForsokId !== b.forsokId
        && fin(j.spridning) && j.spridning >= 0 && fin(j.forraSpridning) && j.forraSpridning >= 0) {
        const nu = Math.floor(j.spridning * 100 + 0.5), forr = Math.floor(j.forraSpridning * 100 + 0.5);
        if (kort()) { if (nu < forr) s += " " + t("tempocoach.jamnare_kort"); }
        else s += " " + t(nu < forr ? "tempocoach.jamnare" : "tempocoach.forra", String(forr), String(nu));
      }
      const n = NARMARE[typ];
      if (n && j && j.forsokId === b.forsokId && j.forraForsokId !== b.forsokId
        && ickeNeg(j.avvikelse) && ickeNeg(j.forraAvvikelse)) {
        const nu = Math.floor(j.avvikelse * 10 + 0.5), forr = Math.floor(j.forraAvvikelse * 10 + 0.5);
        if (kort()) { if (nu < forr) s += " " + t(n.kort); }
        else s += " " + t(nu < forr ? n.narmare : n.forra, tal(forr / 10), tal(nu / 10));
      }
      s += " " + t("aterkoppling." + typ + ".nasta");
      /* Efter clear round-resultatet pekar kortet vidare till eftervården.
         #273 S3 (T1): den är ett VAL — stallet eller själv — inte fem
         moment som väntar. Raden räknar därför inte upp dem längre; den
         visas när bilden säger att eftervården finns. */
      if (typ === "clearround" && Array.isArray(b.eftervard) && b.eftervard.length > 0)
        s += " " + t("aterkoppling.clearround.eftervard");
      return s;
    } else if (b.lage === "timeout") {
      if (kort()) return t("aterkoppling.timeout_kort") + " " + t("aterkoppling." + typ + ".igen");
      const procent = fin(b.progress) ? Math.max(0, Math.min(99, Math.floor(b.progress))) : 0;
      return t("aterkoppling.timeout", String(procent)) + " " + t("aterkoppling." + typ + ".igen");
    }
    return null;
  }

  return { text, _sammanfattning: sammanfattning };
})();

if (typeof window !== "undefined") window.LektionAterkoppling = LektionAterkoppling;
