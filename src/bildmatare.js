/* ══ REALISM-STRÖMBRYTAREN OCH BILDRUTEMÄTAREN (Batch 1.2, kodhalvan) ══

   Två saker som måste finnas INNAN någon ny rendering byggs, och som i
   sig inte ändrar någonting spelaren ser:

   1. STRÖMBRYTAREN `?realism=1`. Allt i Fas 1 (bildtexturer, bakat
      ljus, linjär färg) ska gå att slå på och av, så att gammalt och
      nytt utseende kan jämföras sida vid sida från samma kamera. AV är
      standard. I den här batchen läser ingenting brytaren utom mätaren
      nedan — rörledningen är tom, och tools/bildmataretest.mjs faller om
      någon annan fil börjar läsa den utan att provet uppdateras.

   2. BILDRUTEMÄTAREN `?fps=1`. Varje prestandasiffra i planen är ett
      antagande tills den är mätt på Tobias egen iPad och iPhone. Mätaren
      visar det som behövs för den mätningen, ingenting annat:
        · bilder per sekund, medel över de senaste 60 rutorna,
        · den sämsta rutan i fönstret, i millisekunder,
        · hur många rutor som slog i spelets dt-tak (0,05 s). Under 20
          bilder i sekunden klipps tidssteget och hästen rider kortare
          än klockan säger — det var så FXAA-försöket i Batch 0.1 fällde
          lektionsprovet i CI. Talet ska vara noll på en enhet som räknas
          som stödd.
      Mätaren syns bara när den är påslagen, och skriver om sin text
      högst fyra gånger i sekunden så att den inte själv kostar rutor.

   Båda läses ur adressraden, samma sätt som `?abstraktion=1` i
   src/varld3d.js. Ingen lagring, inga inställningar, ingen knapp. ── */
const REALISM = (() => {
  const har = namn => typeof location !== "undefined" && !!location.search
    && new RegExp("(^|[?&])" + namn + "=1(&|$)").test(location.search);
  return { pa: har("realism"), matare: har("fps") };
})();

const BILDMATARE = { pa: REALISM.matare, rutor: [], klipp: 0, antal: 0, sistText: 0, el: null,
  FONSTER: 60, DT_TAK: 0.05 };

/* En bildruta. `ra` är rutans verkliga längd i sekunder, FÖRE spelets
   dt-tak; `nu` är samma klocka som loopen fick. Rör ingenting i spelet. */
function bildmatareSteg(ra, nu) {
  const B = BILDMATARE;
  if (!B.pa || !(ra > 0)) return;
  B.rutor.push(ra);
  if (B.rutor.length > B.FONSTER) B.rutor.shift();
  B.antal++;
  if (ra > B.DT_TAK) B.klipp++;
  if (nu - B.sistText < 250) return;
  B.sistText = nu;
  if (!B.el && typeof document !== "undefined") {
    B.el = document.createElement("div");
    B.el.id = "bildmatare";
    B.el.setAttribute("aria-hidden", "true");
    B.el.style.cssText = "position:fixed;top:max(6px,env(safe-area-inset-top,0px));"
      + "right:max(6px,env(safe-area-inset-right,0px));z-index:9999;pointer-events:none;"
      + "font:600 12px/1.35 ui-monospace,Menlo,Consolas,monospace;color:#fff;"
      + "background:rgba(0,0,0,.62);padding:4px 7px;border-radius:5px;white-space:pre";
    document.body.appendChild(B.el);
  }
  if (B.el) B.el.textContent = bildmatareText();
}
/* Mätvärdena, också för provet. */
function bildmatareLas() {
  const B = BILDMATARE, n = B.rutor.length;
  if (!n) return { fps: 0, samst: 0, klipp: B.klipp, antal: B.antal };
  let s = 0, m = 0;
  for (const r of B.rutor) { s += r; if (r > m) m = r; }
  return { fps: n / s, samst: m * 1000, klipp: B.klipp, antal: B.antal };
}
function bildmatareText() {
  const v = bildmatareLas();
  return v.fps.toFixed(0) + " b/s · sämst " + v.samst.toFixed(0) + " ms\n"
    + "klippta " + v.klipp + " av " + v.antal + (REALISM.pa ? " · realism PÅ" : " · realism av");
}
if (typeof window !== "undefined") { window.REALISM = REALISM; window.BILDMATARE = BILDMATARE; }
