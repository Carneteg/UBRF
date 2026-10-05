/* ══════════════════════════════════════════════════════════════════
   UGNETAS TEXTINSTÄLLNINGAR — port av roblox/src/client/LararInstallning.luau
   (P3 § 5, docs/INSTRUCTOR-TEXT-CONTROLS-CONTRACT.md).

   Två val, spelarens egna, i sessionens minne — inte i sparfilen, precis
   som Roblox (ingen DataStore, inget attribut):
     · `kommentarer`: "normal" | "farre" | "inga" — de VALFRIA
       kommentarerna (live-chipet, starthälsningen, tempocoachningen).
       Obligatorisk text — uppgiften, tipsen, framstegen — rörs aldrig.
     · `detalj`: "detaljerad" | "kort" — texten när en övning är slut.

   `valfriKommentar` är Roblox UgnetaController.valfriKommentar: Normalt
   släpper igenom, Färre släpper var andra (en delad räknare), Inga
   släpper ingenting. Ett nej är en förbrukad kommentar, ingen kö. ── */

const LararInstallning = (() => {
  const KOMMENTARER = { normal: true, farre: true, inga: true };
  const DETALJ = { detaljerad: true, kort: true };
  let kommentarer = "normal";
  let detalj = "detaljerad";
  let farreRaknare = 0;
  const lyssnare = new Map();
  let nasta = 0;

  function meddela() { for (const fn of [...lyssnare.values()]) fn(); }

  /* true om valet ändrades; ett okänt värde avvisas. */
  function satKommentarer(v) {
    if (!KOMMENTARER[v] || v === kommentarer) return false;
    kommentarer = v; meddela(); return true;
  }
  function satDetalj(v) {
    if (!DETALJ[v] || v === detalj) return false;
    detalj = v; meddela(); return true;
  }
  /* En prenumeration; svaret är dess frånkoppling. */
  function vidByte(fn) {
    const id = ++nasta;
    lyssnare.set(id, fn);
    return () => lyssnare.delete(id);
  }
  function valfriKommentar() {
    if (kommentarer === "inga") return false;
    if (kommentarer === "farre") { farreRaknare++; if (farreRaknare % 2 === 0) return false; }
    return true;
  }
  function _aterstallForProv() { kommentarer = "normal"; detalj = "detaljerad"; farreRaknare = 0; }

  return { kommentarer: () => kommentarer, detalj: () => detalj, satKommentarer, satDetalj, vidByte,
    valfriKommentar, _aterstallForProv, _antalLyssnare: () => lyssnare.size };
})();

if (typeof window !== "undefined") window.LararInstallning = LararInstallning;
