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

   Webben läser tabellen sedan rörelse-grind 0.4 (C1): `s3Ben`,
   lättridningen och galoppens fattning i src/scen3d.js slår upp sina
   faser här, genom uppslagsfunktionerna sist i filen. De är en port av
   roblox/src/shared/HorseCore/Gangfas.luau, namn för namn, så att båda
   plattformarna räknar stöd, sväng och uppresning på samma sätt. */

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

/* ── UPPSLAGEN ─────────────────────────────────────────────────────
   Rena funktioner: samma indata ger samma svar. Ingen av dem ändrar
   tabellen ovan.

   Benens namn i rigg-ordning, som i Gangfas.BEN: fram vänster/höger, bak
   vänster/höger. Webbens häst är byggd mot +X med VÄNSTER sida på +Z
   (uppmätt i tools/gangposetest.mjs, inte antaget), och s3RitaHast
   ritar benen i just den här ordningen. */
const GANGBEN = ["LF", "RF", "LH", "RH"];

/* Vilken rad en rörelse läser. Halt har ingen: då bär alla fyra och
   ingen benföljd ska ritas. Fattningen avgör galoppens rad; okänd
   fattning ritas som höger, aldrig som något påhittat tredje. */
function gangMonsterNamn(gangart, fattning) {
  if (gangart === "skritt") return "skritt";
  if (gangart === "trav") return "trav";
  if (gangart === "galopp") return fattning === "vanster" ? "galopp_vanster" : "galopp_hoger";
  if (gangart === "galopp_hoger" || gangart === "galopp_vanster" || gangart === "rygga") return gangart;
  return null;
}

/* Ett bens läge i cykeln: `u` är hur långt efter sin isättning det är
   (0..1), `stod` hur stor del av cykeln det bär. u < stod betyder stöd. */
function gangBen(m, ben, fas) {
  const b = m && m.ben[ben];
  if (!b) return { u: 0, stod: 1 };
  let u = (fas - b.td) % 1;
  if (u < 0) u += 1;
  return { u, stod: b.stod };
}

/* LÄTTRIDNINGEN: hur högt ryttaren står, 0..1. EN uppresning per hel
   travcykel — hon reser sig medan det YTTRE frambenet förs fram (dess
   svängfas) och sitter ned när det sätts i. Bålens två vertikala
   impulser per cykel är hästens, inte ryttarens. */
function gangLattridning(m, fas, yttreFram) {
  const b = m && m.ben[yttreFram];
  if (!b) return 0;
  const sving = 1 - b.stod;
  if (sving <= 0) return 0;
  let u = (fas - (b.td + b.stod)) % 1;
  if (u < 0) u += 1;
  if (u >= sving) return 0;
  return Math.sin(Math.PI * u / sving);
}

/* VILKET VARV hon rider: ligger banans mitt till höger eller vänster om
   kursen? Kartans koordinater (+x öster, +y norr): högervektorn till en
   kurs (fx, fy) är (fy, −fx), samma regel som GL.kamera och world.js.
   Rakt mot eller från mitten finns inget svar (null), och då behåller
   den som frågar det senast giltiga. */
function gangVarv(px, py, rikt, mittX, mittY) {
  const cx = mittX - px, cy = mittY - py;
  const langd = Math.hypot(cx, cy);
  if (langd < 1e-3) return null;
  const d = (cx * Math.sin(rikt) - cy * Math.cos(rikt)) / langd;
  if (Math.abs(d) < 0.25) return null;
  return d > 0 ? "hoger" : "vanster";
}

/* Det yttre frambenet på ett varv. På höger varv ligger mitten till
   höger, och då är VÄNSTER fram det yttre. Okänt varv: null. */
function gangYttreFram(varv) {
  if (varv === "hoger") return "LF";
  if (varv === "vanster") return "RF";
  return null;
}

/* TAKTSLAGEN: de SKILDA isättningsfaserna, sorterade. Ett diagonalpar är
   ETT slag, inte två — trav har två slag per cykel, galopp tre, skritt
   fyra. Benen som sätts i samtidigt följer med. */
function gangSlag(m) {
  const per = new Map();
  for (const namn of GANGBEN) {
    const b = m.ben[namn];
    if (!b) continue;
    if (!per.has(b.td)) per.set(b.td, []);
    per.get(b.td).push(namn);
  }
  return [...per.keys()].sort((a, b) => a - b).map(fas => ({ fas, ben: per.get(fas) }));
}

/* Slagen som PASSERATS mellan två löpande lägen (cykler + fas), i
   ordning. `fran` räknas inte med, `till` gör det — ett slag som ligger
   exakt på en bildrutegräns hörs en gång, inte noll eller två gånger.
   Taket skyddar mot en ljudsalva när lägena ligger långt isär. */
const GANG_MAX_SLAG = 6;
function gangPasserade(m, fran, till) {
  const ut = [];
  if (!(till > fran)) return ut;
  const slag = gangSlag(m);
  for (let c = Math.floor(fran); c <= Math.floor(till); c++)
    for (const s of slag) {
      const t = c + s.fas;
      if (t > fran && t <= till) {
        ut.push({ fas: s.fas, ben: s.ben, lage: t });
        if (ut.length >= GANG_MAX_SLAG) return ut;
      }
    }
  return ut;
}

if (typeof window !== "undefined") {
  window.GANGFAS = GANGFAS;
  window.LATTRIDNING = LATTRIDNING;
}
