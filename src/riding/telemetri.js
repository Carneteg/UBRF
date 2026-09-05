/* ══════════════════════════════════════════════════════════════════
   G02-A — RIDNINGENS TELEMETRI OCH TILLSTÅNDSKONTRAKT (issue #82)

   Det här lagret UPPFINNER INGEN RIDKÄNSLA. Gate 01 byggde redan
   ridkärnan — `Gait`/`stepRide` i src/model.js, ridinputkontraktet
   `RIDIN`/`ridAvsiktTillHjalp` och kurvaturstyrningen i src/game.js,
   den analoga spaken i src/mobil.js, kameran i src/scen3d.js och
   MovementController/Gaits på Roblox-sidan. Ordern i #82 är
   konsolidering, inte omskrivning: "bygg inte om Gate 01 från noll".

   Modulen gör därför tre saker och inget mer:

   1. LÄSER ut den telemetri G02-B/C behöver (gångart, faktisk och
      önskad fart, kurvatur/svängradie, rytm, balans, spänning/fokus,
      hjälperna) ur tillstånd som redan finns. Ren avläsning — den
      ändrar ingenting och kan inte påverka känslan.
   2. Namnger UPPSUTTEN/AVSUTTEN som ett riktigt tillstånd i stället
      för något som bara framgår av vilken scen som är igång.
   3. Skriver ned gångartsövergångarnas kontrakt, så att ett olagligt
      hopp (halt → galopp) går att UPPTÄCKA. Gångarten kommer fortsatt
      ur `Gait.forTempo` med hysteres — kontraktet dömer, det styr
      inte, och kan alltså inte ändra hur ridningen känns.

   Allt som mäts i tiondelar här är samma storheter som Gate 01 mätte,
   så att G02-B/C kan bedöma utförande i stället för att gissa. ── */

/* Lagliga gångartsbyten. Grannbyten i ordningen, plus halt från vad som
   helst (en häst kan stanna ur galopp). Att hoppa halt → trav → galopp
   uppåt utan mellansteg är däremot inte en övergång utan ett glapp. */
const RID_ORDNING = ["halt", "skritt", "trav", "galopp"];
const RID_TILLSTAND = {
  uppsutten: false,
  hast: null,
  plats: null,
  /* Senast sedda gångart, för övergångskontraktet. */
  gangart: "halt",
  glapp: 0,          // räknare: olagliga gångartshopp sedan uppsittning
};

function ridLagligtByte(fran, till) {
  if (fran === till) return true;
  if (till === "halt") return true;                     // stanna får man alltid
  const i = RID_ORDNING.indexOf(fran), j = RID_ORDNING.indexOf(till);
  if (i < 0 || j < 0) return false;
  return Math.abs(i - j) === 1;                         // bara grannsteg uppåt/nedåt
}

function ridSittUpp(hastId, plats) {
  RID_TILLSTAND.uppsutten = true;
  RID_TILLSTAND.hast = hastId || null;
  RID_TILLSTAND.plats = plats || null;
  RID_TILLSTAND.gangart = "halt";
  RID_TILLSTAND.glapp = 0;
  return RID_TILLSTAND;
}
function ridSittAv() {
  RID_TILLSTAND.uppsutten = false;
  RID_TILLSTAND.hast = null;
  RID_TILLSTAND.plats = null;
  return RID_TILLSTAND;
}

/* Följ gångarten och räkna glapp. Anropas av den som redan stegar
   ritten; returnerar den gångart som gäller nu. Dömer, styr inte. */
function ridFoljGangart(gangart) {
  const fran = RID_TILLSTAND.gangart;
  if (gangart !== fran && !ridLagligtByte(fran, gangart)) RID_TILLSTAND.glapp++;
  RID_TILLSTAND.gangart = gangart;
  return gangart;
}

/* TELEMETRIN. `ride` är RideModel-tillståndet (nyState/stepRide), `aids`
   de utjämnade hjälpvärdena, `extra` det som bara den körande scenen
   känner till: kurvatur, gångartsfas och önskat tempo.

   Fälten är de #82 räknar upp. `balans` och `fokus` finns ännu inte som
   egna storheter i modellen — de härleds ur mjukhet och spänning och är
   märkta som härledda, inte påhittade mätvärden. G02-B ger dem riktiga
   källor; tills dess ljuger de inte om sin proveniens. */
function ridTelemetri(ride, aids, extra) {
  const e = extra || {};
  const g = (typeof Gait !== "undefined" && Gait.G[ride.gangart]) || null;
  const kappa = e.kappa || 0;
  return {
    uppsutten: RID_TILLSTAND.uppsutten,
    hast: RID_TILLSTAND.hast,
    gangart: ride.gangart,
    gangartGlapp: RID_TILLSTAND.glapp,
    fart: ride.tempo,                                   // m/s, faktisk
    onskadFart: e.onskadFart !== undefined ? e.onskadFart : (g ? g.norm : 0),
    kurvatur: kappa,                                    // 1/m, tecknad
    svangradie: Math.abs(kappa) > 0.002 ? 1 / Math.abs(kappa) : Infinity,
    vridhastighet: kappa * ride.tempo,                  // rad/s, faller ur kurvatur × tempo
    rytm: e.fas !== undefined ? e.fas : 0,              // gångartsfas 0–1, ur markförflyttning
    steglangd: ride.steglangd || 0,
    spanning: ride.spanning,
    mjukhet: ride.mjukhet,
    balans: clamp(1 - Math.abs(kappa) / 0.42 * 0.5 - ride.spanning * 0.3, 0, 1),   // härledd
    fokus: clamp(1 - ride.spanning, 0, 1),                                          // härledd
    hjalper: aids ? { skankel: aids.skankel, tygel: aids.tygel,
                      sits: aids.sits, styrning: aids.styrning } : null,
    _harledda: ["balans", "fokus"],                     // ärlig märkning för G02-B
  };
}

/* ══════════════════════════════════════════════════════════════════
   G02-A — REVIEW-ONLY A/B FÖR DE FYRA BLOCKERANDE PARAMETRARNA

   Senior re-review av #86: G02-A fick TECHNICAL_REVIEW_PASS men
   PRODUCT_DECISION_REQUIRED. Fyra skillnader i kärnrörelsen påverkar
   faktisk känsla, och Tobias ska kunna jämföra dem på webben innan
   någon harmoniserar något.

   HÄR ÄNDRAS INGEN PRODUKTKANON. `A` är exakt dagens webbvärden och är
   det enda som körs om ingen uttryckligen ber om annat. `B` finns bara
   för jämförelsen. Uppsättningen byts med `?ridab=B` i adressfältet
   eller `ridSattAB("B")` från en testharness — aldrig av spelet självt.

   Att välja A eller B, eller en tredje trimning, är ett produktbeslut.
   Den här filen mäter, den bestämmer inte. ── */

const RID_AB = {
  A: {
    namn: "A — webb (Gate 01)",
    kallа: "src/game.js @ 33559d9, src/model.js",
    KAPPA_MAX: 0.42,
    GANGSVANG: { halt: 1.00, skritt: 1.00, trav: 0.82, galopp: 0.52 },
    galoppMax: 8.00,
    /* Cykellängd: SPRANG[kat] × gångartens steg-faktor. */
    cykel: null,
  },
  B: {
    namn: "B — Roblox (HorseCore)",
    kallа: "roblox/src/shared/HorseCore/Config.luau, Gaits.luau @ 58a8030",
    KAPPA_MAX: 0.30,
    GANGSVANG: { halt: 1.00, skritt: 1.00, trav: 0.82, galopp: 0.62 },
    galoppMax: 7.00,
    /* Roblox cycleLength = norm ÷ cycles, i meter. */
    cykel: { skritt: 1.45, trav: 2.1333333, galopp: 3.20 },
  },
};

/* Aktiv uppsättning. PRODUKTION KÖR ALLTID A. */
let RID_AKTIV = "A";
function ridAB() { return RID_AB[RID_AKTIV]; }

/* Byter uppsättning genom att skriva om de fyra värdena i den kanoniska
   modellen. Returnerar vilken som nu gäller. Reversibel: A skriver
   tillbaka Gate 01:s värden, som ligger kvar oförändrade i RID_AB.A. */
function ridSattAB(vilken) {
  const s = RID_AB[vilken];
  if (!s) return RID_AKTIV;
  RID_AKTIV = vilken;
  if (typeof Gait !== "undefined") {
    Gait.G.galopp.max = s.galoppMax;
    if (!Gait._steglangdA) Gait._steglangdA = Gait.steglangd;
    Gait.steglangd = s.cykel
      ? function (kat, g, schvung, spanning) {
          const c = s.cykel[g];
          if (!c) return 0;
          return c * clamp(1 + 0.22 * (schvung - 0.5) - 0.18 * spanning, 0.72, 1.28);
        }
      : Gait._steglangdA;
  }
  return RID_AKTIV;
}

/* Adressfältet — bara läsning, bara en gång, bara om den finns. */
if (typeof location !== "undefined" && location.search) {
  const m = /[?&]ridab=([AB])\b/.exec(location.search);
  if (m) ridSattAB(m[1]);
}
