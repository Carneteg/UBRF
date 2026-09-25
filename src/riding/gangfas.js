/* GÅNGARTERNAS BENFÖLJD — en tabell, exporterad till Roblox.

   #264 GAIT_READABILITY_AND_UGNETA. Skritt, trav och galopp ska synas och
   höras olika: vilket ben som sätts i marken när, och hur länge det bär.
   Tabellen är den enda sanningen om det; Roblox läser den genom
   tools/exportera-ridkanon.mjs (RidKanon.GANGFAS) och ritar ben och hovslag
   ur samma rad.

   Ben: LF/RF/LH/RH = vänster/höger fram/bak. `td` är fasen (0..1) då hoven
   sätts i marken, `stod` hur stor del av cykeln den bär. En cykel går från
   en hovs isättning till samma hovs nästa.

   Anatomin (Svenska Ridsportförbundets dressyrbilaga): skritt är fyrtakt,
   trav tvåtakt med diagonala benpar och svävmoment, galopp tretakt med
   svävmoment. Höger galopp: LH, sedan RH+LF, sedan RF, sedan sväv.
   Vänster galopp är spegelbilden.

   TALEN ÄR STILISERADE FÖRSTA VÄRDEN (ChatGPT:s underlag 2026-09-25,
   avsnitt 5), inte uppmätta normer. De ska granskas av ridkunnig person i
   rörelse. Ändra dem här, aldrig i Roblox-koden.

   Webben läser inte tabellen ännu: webbens egen benmodell (scen3d.js)
   flyttas hit i ett separat, senare beställt steg. */

const GANGFAS = (() => {
  const ben = (td, stod) => ({ td, stod });
  const skritt = {
    takt: 4,
    ben: { LH: ben(0.00, 0.65), LF: ben(0.25, 0.65), RH: ben(0.50, 0.65), RF: ben(0.75, 0.65) },
  };
  /* Diagonala par: LH+RF, sedan RH+LF. Stödet är kortare än en halv cykel,
     och det är det som ger svävmomentet mellan paren. */
  const trav = {
    takt: 2,
    ben: { LH: ben(0.00, 0.42), RF: ben(0.00, 0.42), RH: ben(0.50, 0.42), LF: ben(0.50, 0.42) },
  };
  const galoppHoger = {
    takt: 3,
    ben: { LH: ben(0.00, 0.30), RH: ben(0.25, 0.32), LF: ben(0.25, 0.32), RF: ben(0.50, 0.25) },
  };
  /* Spegelbilden räknas, den skrivs inte av: vänster galopp ÄR höger
     galopp med sidorna bytta, och två handskrivna rader kunde glida isär. */
  const spegla = g => ({
    takt: g.takt,
    ben: { LH: g.ben.RH, RH: g.ben.LH, LF: g.ben.RF, RF: g.ben.LF },
  });
  /* Ryggning är en tvåtaktig diagonal gångart, men hon går BAKÅT. Egen rad
     så att framåtgångens kontaktmodell inte används av misstag. */
  const rygga = {
    takt: 2,
    ben: { LH: ben(0.00, 0.50), RF: ben(0.00, 0.50), RH: ben(0.50, 0.50), LF: ben(0.50, 0.50) },
  };
  return { skritt, trav, galopp_hoger: galoppHoger, galopp_vanster: spegla(galoppHoger), rygga };
})();

/* Lättridning: EN uppresning per hel travcykel. Ryttaren reser sig medan
   det YTTRE frambenet förs fram och sitter ned när det sätts i. */
const LATTRIDNING = { upp_per_cykel: 1, hojd_m: 0.11 };

if (typeof window !== "undefined") {
  window.GANGFAS = GANGFAS;
  window.LATTRIDNING = LATTRIDNING;
}
