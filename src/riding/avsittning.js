/* ══ AVSITTNING BARA FRÅN HALT (Batch 0.11, E2) ═══════════════════════

   Man sitter av en häst som står. Det är ridskolans regel och den är
   inte förhandlingsbar: att kliva av i trav eller galopp är hur ryttare
   skadar sig, och spelet ska inte lära ut det för att spara tre sekunder.

   REGELN, samma på webben och i Roblox
   (roblox/src/shared/HorseCore/Avsittning.luau är samma tre funktioner):

     · Står hästen — gångarten är halt och markfarten är under STILLA —
       sker avsittningen DIREKT, som förut.
     · Rör hon sig BER knappen om halt: stallet tar ner henne genom de
       nedåtgående övergångar som redan finns, en rad säger vad som
       händer, och avsittningen sker när hon står.
     · Efter NODUTGANG_S sekunder sitter spelaren av ändå. Ingen ska bli
       fast i sadeln.

   Modulen är REN: den läser gångart och fart och svarar med ett ord.
   Den bromsar ingenting, ritar ingenting och river ingen ritt — det gör
   den som anropar. Därför går samma regel att mäta utan webbläsare
   (tools/avsittningtest.mjs) och att spegla rad för rad i Luau.

   Ett andra tryck medan hon bromsar startar INTE om klockan och sitter
   inte av i förtid: nödutgången räknas från den första begäran. ── */
const Avsittning = (() => {
  const K = () => RID_KANON.AVSITTNING;
  function ny() { return { vantar: false, tid: 0 }; }
  function star(gangart, fart) {
    return gangart === "halt" && Math.abs(fart || 0) <= K().STILLA;
  }
  /* Spelaren tryckte. "nu" = sitt av i den här bildrutan; "vantar" =
     hästen ska först till halt. */
  function begar(A, gangart, fart) {
    if (star(gangart, fart)) { A.vantar = false; A.tid = 0; return "nu"; }
    if (!A.vantar) { A.vantar = true; A.tid = 0; }
    return "vantar";
  }
  /* En bildruta. null = ingen begäran; "bromsa" = håll nedtagningen
     igång; "sitt_av" = hon står, eller nödutgången har löst ut. */
  function steg(A, gangart, fart, dt) {
    if (!A.vantar) return null;
    A.tid += dt;
    if (star(gangart, fart) || A.tid >= K().NODUTGANG_S) {
      A.vantar = false; A.tid = 0;
      return "sitt_av";
    }
    return "bromsa";
  }
  return { ny, star, begar, steg };
})();
if (typeof window !== "undefined") window.Avsittning = Avsittning;
