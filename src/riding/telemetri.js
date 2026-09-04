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
