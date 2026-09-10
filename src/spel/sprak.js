/* ═══════════════════════════════════════════════════════════════════════
   SPRÅKKANONEN — spelarens text på ett enda ställe, svenska och engelska.

   Produktkravet i #162: spelet ska visa svenska för svenska spelare och
   engelska annars, utan hårdkodad text i logiken. Filen är KÄLLAN till
   båda plattformarna, precis som `hastar.js` och `skotsel.js`:

     src/spel/sprak.js  →  roblox/game/UBRFSprak.luau   (tools/exportera-spel.js)
                        →  webben läser samma tabell direkt

   Två sanningar hade varit värre än ingen: en spelare som byter platta
   ska läsa samma ord, och en ny text ska inte kunna finnas på en yta men
   inte på den andra.

   ── VAD SOM LIGGER HÄR OCH VAD SOM INTE GÖR DET ────────────────────────
   Här ligger spelets EGEN text: prompter, HUD-rubriker, nej-svar,
   hjälpen, läraren, sparstatus. Alltså det spelet SÄGER.

   Här ligger INTE:
     · UBRF:s verkliga fakta (hästarnas namn, raser, beskrivningar) —
       de är verkligheten och kommer ur `hastar.js`,
     · skötselkanonens undervisande text (`skotsel.js`) — den är hämtad
       ur ridhandbokens struktur och är innehåll, inte gränssnitt.

   Båda är svenska idag. Att jag skulle översätta hästkunskapens
   terminologi till engelska på eget initiativ vore precis det som
   CLAUDE.md förbjuder: att hitta på innehåll för att fylla ett hål.
   De står därför som en redovisad ÖVERSÄTTNINGSSKULD i
   `SPRAK_BACKLOG` nedan, och grinden räknar dem — de faller tillbaka
   på svenska, aldrig tyst.

   ── FORMEN ─────────────────────────────────────────────────────────────
   Varje nyckel: { sv, en }. Platshållare skrivs som %s och %d i BÅDA
   språken, i samma ordning, så att samma formatering fungerar på båda
   plattformarna. Grinden fäller om ordningen skiljer sig.
   ═══════════════════════════════════════════════════════════════════════ */

const SPRAK = {
  /* ── Dörrar och prompter i världen ─────────────────────────────────── */
  "dorr.oppna": { sv: "Öppna", en: "Open" },
  "dorr.stang": { sv: "Stäng", en: "Close" },
  "dorr.objekt": { sv: "Dörr", en: "Door" },
  "stall.titta_in": { sv: "Titta in", en: "Look in" },
  "stall.star_har": { sv: "%s står här", en: "%s is in here" },
  "interaktion.sitt_upp": { sv: "Sitt upp", en: "Mount" },
  "interaktion.sitt_av": { sv: "SITT AV", en: "DISMOUNT" },

  /* ── Uppsittning och avsittning (HorseService) ─────────────────────── */
  "hast.inte_redo": { sv: "Hästen är inte färdig att sitta upp på",
    en: "The horse is not ready to be ridden" },
  "hast.oregistrerad": { sv: "Hästen är inte registrerad",
    en: "The horse is not registered" },
  "hast.upptagen": { sv: "Hästen är redan upptagen", en: "The horse is already taken" },
  "hast.rider_redan": { sv: "Du rider redan", en: "You are already riding" },
  "hast.ingen_karaktar": { sv: "Ingen karaktär", en: "No character" },
  "hast.for_langt": { sv: "För långt bort", en: "Too far away" },
  "hast.ingen_levande": { sv: "Ingen levande karaktär", en: "No living character" },
  "hast.sitsen_tog_inte": { sv: "Sitsen tog inte", en: "The seat did not take" },
  "hast.ogiltig": { sv: "Ogiltig häst", en: "Invalid horse" },

  /* ── Loopen (GameplayService) ──────────────────────────────────────── */
  "spel.ingen_hast": { sv: "Du har ingen tilldelad häst",
    en: "You have not been given a horse" },
  "spel.hast_saknas": { sv: "Din häst finns inte i världen än",
    en: "Your horse is not in the world yet" },
  "spel.for_langt": { sv: "Du står för långt bort", en: "You are standing too far away" },
  "spel.ogiltigt_steg": { sv: "Ogiltigt steg", en: "Invalid step" },
  "spel.ogiltigt_svar": { sv: "Ogiltigt svar", en: "Invalid answer" },
  "spel.inget_pass": { sv: "Du har inget pass igång", en: "You have no session going" },
  "spel.ingen_sparning": { sv: "Sparningen är inte igång", en: "Saving is not running" },
  "spel.inte_din_hast": { sv: "Det är inte din häst", en: "That is not your horse" },
  "spel.redan_ridit": { sv: "Du har redan ridit idag", en: "You have already ridden today" },
  "spel.gammal_klient": { sv: "Skötseln görs moment för moment nu — uppdatera klienten.",
    en: "Care is done step by step now — please update your client." },

  /* ── Passet (Pass.luau) ────────────────────────────────────────────── */
  "pass.sitter_redan": { sv: "du sitter redan upp", en: "you are already mounted" },
  "pass.redan_igang": { sv: "passet är redan igång", en: "the session is already going" },
  "pass.rider_inte": { sv: "du rider inte", en: "you are not riding" },
  "pass.redan_raknat": { sv: "passet är redan räknat", en: "the session is already counted" },
  "pass.sitt_av_forst": { sv: "sitt av först", en: "dismount first" },
  "pass.inte_dags": { sv: "det är inte dags för eftervård", en: "it is not time for aftercare" },
  "pass.okant_moment": { sv: "okänt moment", en: "unknown step" },
  "pass.redan_gjort": { sv: "redan gjort", en: "already done" },
  "pass.fel_tur": { sv: "fel tur — %s står på tur", en: "wrong turn — %s is next" },
  "pass.sitter_fortfarande": { sv: "du sitter fortfarande upp", en: "you are still mounted" },
  "pass.inte_ridit": { sv: "du har inte ridit än", en: "you have not ridden yet" },
  "pass.aterstar": { sv: "%s återstår", en: "%s remains" },
  "pass.eftervarden": { sv: "eftervården", en: "the aftercare" },

  /* ── Förberedelsen (Preparation.luau) ──────────────────────────────── */
  "forb.fel_hast": { sv: "fel häst", en: "wrong horse" },
  "forb.oppet_fynd": { sv: "Du hittade något. Bestäm vad du gör åt det först.",
    en: "You found something. Decide what to do about it first." },
  "forb.okand_fas": { sv: "okänd fas", en: "unknown phase" },
  "forb.uppsittning_inte_steg": { sv: "uppsittningen är inget förberedelsesteg",
    en: "mounting is not a preparation step" },
  "forb.redan_gjort": { sv: "redan gjort", en: "already done" },
  "forb.fel_tur": { sv: "fel tur — %s står på tur", en: "wrong turn — %s is next" },
  "forb.inget_kvar": { sv: "inget kvar", en: "nothing left" },
  "forb.nagot_annat": { sv: "något annat", en: "something else" },
  "forb.okant_moment": { sv: "okänt moment", en: "unknown step" },
  "forb.inget_att_rapportera": { sv: "det finns inget att rapportera",
    en: "there is nothing to report" },
  "forb.redan_rapporterat": { sv: "redan rapporterat", en: "already reported" },
  "forb.okant_svar": { sv: "okänt svar", en: "unknown answer" },
  "forb.inte_ditt_beslut": { sv: "Det är inte ditt beslut att ta. Säg till ridläraren.",
    en: "That is not your decision to make. Tell the instructor." },
  "forb.lararen_tar_over": { sv: "%s Ridläraren tar över — hon ska inte arbeta idag. Du har gjort precis rätt.",
    en: "%s The instructor takes over — she is not to work today. You did exactly the right thing." },
  "forb.inte_din_hast": { sv: "det är inte din häst", en: "that is not your horse" },
  "forb.utrustning_av": { sv: "Utrustning %d/%d", en: "Tack %d/%d" },

  /* ── Skötsel-HUD:en (PreparationController) ────────────────────────── */
  "hud.gor_i_ordning": { sv: "Gör i ordning din häst", en: "Get your horse ready" },
  "hud.lararen_tar_over": { sv: "Ridläraren tar över", en: "The instructor takes over" },
  "hud.du_hittade_nagot": { sv: "Du hittade något", en: "You found something" },
  "hud.ta_hand_om_henne": { sv: "Ta hand om henne", en: "Take care of her" },
  "hud.passet_sparat": { sv: "Passet är klart och sparat", en: "The session is done and saved" },
  "hud.bra_jobbat": { sv: "Bra jobbat. Du har ridit ditt pass idag.",
    en: "Well done. You have ridden your session today." },
  "hud.vantar_pa_hast": { sv: "Väntar på din häst", en: "Waiting for your horse" },
  "hud.hast_inte_i_varlden": { sv: "Hon är tilldelad men står inte i världen än.",
    en: "She has been assigned to you but is not in the world yet." },
  "hud.du_rider": { sv: "Du rider", en: "You are riding" },
  "hud.klar_sitt_upp": { sv: "Klar — du kan sitta upp", en: "Ready — you can mount" },
  "hud.kolla_gjorden": { sv: "Kontrollera gjorden en sista gång.",
    en: "Check the girth one last time." },
  "hud.gick_inte_nu": { sv: "Det gick inte just nu", en: "That did not work just now" },

  /* ── Hjälpen och kontrollerna (KontrollHjalp) ─────────────────────── */
  "hjalp.rubrik": { sv: "Kontroller", en: "Controls" },
  "hjalp.styrkors_upp": { sv: "Styrkors upp", en: "D-pad up" },
  "hjalp.styrkors_ned": { sv: "Styrkors ned", en: "D-pad down" },
  "hjalp.styrkors_vanster": { sv: "Styrkors vänster", en: "D-pad left" },
  "hjalp.styrkors_hoger": { sv: "Styrkors höger", en: "D-pad right" },
  "hjalp.namnlos_knapp": { sv: "(namnlös knapp: %s)", en: "(unnamed button: %s)" },
  "hjalp.sitt_upp_av": { sv: "Sitt upp / sitt av", en: "Mount / dismount" },
  "hjalp.framat_bakat": { sv: "Framåt / bakåt", en: "Forward / back" },
  "hjalp.vanster_hoger": { sv: "Vänster / höger", en: "Left / right" },
  "hjalp.vanster_spak": { sv: "Vänster spak", en: "Left stick" },
  "hjalp.hogre_gangart": { sv: "Högre gångart", en: "Faster gait" },
  "hjalp.lagre_gangart": { sv: "Lägre gångart", en: "Slower gait" },
  "hjalp.tygel": { sv: "Tygel (kontakt)", en: "Rein (contact)" },
  "hjalp.djupare_sits": { sv: "Djupare sits", en: "Deeper seat" },
  "hjalp.denna_hjalp": { sv: "Den här hjälpen", en: "This help" },
  "hjalp.stang": { sv: "Stäng", en: "Close" },
  "hjalp.stang_tangent": { sv: "Stäng  (%s)", en: "Close  (%s)" },
  "hjalp.styr": { sv: "Styr", en: "Steer" },
  "hjalp.halvhalt": { sv: "Halvhalt", en: "Half-halt" },
  "hjalp.hoppa": { sv: "Hoppa", en: "Jump" },
  "hjalp.spaken": { sv: "Spaken", en: "The stick" },
  "hjalp.pek": { sv: "pek", en: "touch" },

  /* ── Pekknapparnas EGNA etiketter (TouchControls) ──────────────────
     Versalerna hör till knappen: de är små ytor på en telefonskärm och
     läses i förbifarten. Samma form i båda språken. */
  "touch.sitt_av": { sv: "SITT AV", en: "DISMOUNT" },
  "touch.hoppa": { sv: "HOPP", en: "JUMP" },
  "touch.lugnare": { sv: "▼ LUGNARE", en: "▼ SLOWER" },
  "touch.framat": { sv: "▲ FRAMÅT", en: "▲ FORWARD" },
  "touch.tygel": { sv: "TYGEL", en: "REIN" },
  "touch.halvhalt": { sv: "HALVHALT", en: "HALF-HALT" },
  "touch.djup_sits": { sv: "DJUP SITS", en: "DEEP SEAT" },

  /* ── Ugneta, ridläraren ────────────────────────────────────────────── */
  "ugneta.rubrik": { sv: "UGNETA · RIDINSTRUKTÖR", en: "UGNETA · RIDING INSTRUCTOR" },
  "ugneta.hastens_svar": { sv: "hästens svar", en: "the horse's response" },
  "ugneta.prova_igen": { sv: "Prova igen", en: "Try again" },
  "ugneta.se_ritten": { sv: "Se ritten", en: "Watch the ride" },
  "ugneta.ga_vidare": { sv: "Gå vidare", en: "Move on" },
  "ugneta.precis_sa": { sv: "Precis så", en: "Just like that" },
  "ugneta.jamnare_forsok": { sv: "Jämnare försök. Behåll samma känsla.",
    en: "A steadier attempt. Keep the same feel." },
  "ugneta.nasta_ovning": { sv: "Nästa övning", en: "Next exercise" },
  "ugneta.forsok": { sv: "Försök %d", en: "Attempt %d" },
  /* Dimensionsorden läraren pekar på. Ridtermer, men korta och entydiga —
     de hör till gränssnittet och inte till undervisningstexten, som står
     i översättningsskulden. */
  "ugneta.dim.linje": { sv: "linjen", en: "the line" },
  "ugneta.dim.rytm": { sv: "rytmen", en: "the rhythm" },
  "ugneta.dim.balans": { sv: "balansen", en: "the balance" },
  "ugneta.dim.timing": { sv: "timingen", en: "the timing" },
  "ugneta.dim.mjukhet": { sv: "mjukheten", en: "the softness" },
  "ugneta.dim.respons": { sv: "hästens svar", en: "the horse's response" },
  "ugneta.dim.tempo": { sv: "tempot", en: "the tempo" },

  /* ── Sparningen: status spelaren ska kunna förstå ──────────────────── */
  "spar.inget_datalager": { sv: "inget datalager", en: "no data store" },
  "spar.lasfel": { sv: "läsfel", en: "read error" },
  "spar.framtida_sparfil": { sv: "framtida sparfil i lagret",
    en: "a newer save file in the store" },
  "spar.sparas_inte": { sv: "Framstegen sparas inte den här sessionen: %s",
    en: "Progress is not being saved this session: %s" },
  "spar.forsoker_igen": { sv: "Kunde inte spara nu. Framstegen ligger kvar och försöks igen.",
    en: "Could not save just now. Your progress is kept and will be retried." },
};

/* ÖVERSÄTTNINGSSKULD, redovisad. Innehåll som är svenskt idag och som
   INTE får maskinöversättas av en builder — se filhuvudet. Grinden läser
   listan och kräver att posterna faller tillbaka på svenska, inte att de
   låtsas vara engelska. */
const SPRAK_BACKLOG = [
  { kalla: "src/spel/hastar.js", vad: "hästarnas namn, raser och beskrivningar",
    skal: "UBRF:s verkliga fakta — verkligheten är facit och får inte översättas av en agent" },
  { kalla: "src/spel/skotsel.js", vad: "skötselkanonens moment- och undervisningstext",
    skal: "hämtad ur ridhandbokens struktur; hästkunskapens terminologi är Tobias beslut, inte mitt" },
];

/* Språkvalet: svenska för svenska spelare, engelska annars. Regeln står
   här så att båda plattformarna svarar likadant på samma locale-sträng. */
function sprakFor(localeId) {
  const kod = String(localeId || "").toLowerCase();
  return kod.startsWith("sv") ? "sv" : "en";
}

/* Slår upp och formaterar. Saknas den engelska texten faller den tillbaka
   på svenska — synligt, för `sprakSaknade()` räknar dem. */
function sprakText(nyckel, sprak, ...args) {
  const post = SPRAK[nyckel];
  if (!post) return nyckel;
  let text = post[sprak] || post.sv;
  if (args.length) {
    let i = 0;
    text = text.replace(/%[sd]/g, () => String(args[i++]));
  }
  return text;
}

function sprakSaknade(sprak) {
  return Object.keys(SPRAK).filter(n => !SPRAK[n][sprak]);
}

if (typeof window !== "undefined") {
  window.SPRAK = SPRAK;
  window.SPRAK_BACKLOG = SPRAK_BACKLOG;
  window.sprakFor = sprakFor;
  window.sprakText = sprakText;
  window.sprakSaknade = sprakSaknade;
  /* Webbens eget språkval: spelarens webbläsarspråk, med samma regel. */
  window.SPRAKET = sprakFor(typeof navigator !== "undefined" ? navigator.language : "sv-SE");
  window.tSpr = (nyckel, ...args) => sprakText(nyckel, window.SPRAKET, ...args);
}
