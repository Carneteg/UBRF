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
  /* Stora skjut-/slagportar. Öppningstypen i geometrin skiljer `port*` från
     `dorr*`, och den skillnaden är verklig — porten till ridhuset är inte en
     dörr. Färgen i tokenet (`portbla`) är däremot bara färg och säger
     ingenting spelaren behöver läsa. */
  "dorr.port": { sv: "Port", en: "Gate" },
  "stall.titta_in": { sv: "Titta in", en: "Look in" },
  "stall.star_har": { sv: "%s står här", en: "%s is in here" },
  "interaktion.sitt_upp": { sv: "Sitt upp", en: "Mount" },
  "interaktion.sitt_av": { sv: "SITT AV", en: "DISMOUNT" },

  /* Utrustningsstegets namn är en RÄKNARE, inte kanon: "Utrustning 2/4"
     står inte i ridhandboken, den är HUD:ens sätt att numrera sadelfaserna.
     Därför ligger den här och inte i skotsel.js. */
  "forb.utrustning_steg": { sv: "Utrustning %d/%d", en: "Tacking up %d/%d" },

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
  /* Om skötselkanonen saknar mening för just det fyndet. Ska inte hända —
     men om det gör det ska spelaren läsa något begripligt, inte en nyckel. */
  "forb.nagot_ar_fel": { sv: "Något är inte som det ska.", en: "Something is not right." },
  "forb.lararen_tar_over": { sv: "%s Ridläraren tar över — hon ska inte arbeta idag. Du har gjort precis rätt.",
    en: "%s The instructor takes over — she is not to work today. You did exactly the right thing." },
  "forb.inte_din_hast": { sv: "det är inte din häst", en: "that is not your horse" },
  "forb.utrustning_av": { sv: "Utrustning %d/%d", en: "Tack %d/%d" },
  /* Sadeln och tränset är FYSISKA saker som hänger på hästens boxfront
     (`references/buildings/stall/KORT.md` § Boxarna från gången). De två
     nejen nedan är de enda som säger att spelaren står rätt men har
     händerna tomma. */
  "forb.sadeln_inte_hamtad": { sv: "du har ingen sadel med dig",
    en: "you are not carrying a saddle" },
  "forb.transet_inte_hamtat": { sv: "du har inget träns med dig",
    en: "you are not carrying a bridle" },

  /* ── Utrustningen på boxfronten ────────────────────────────────────── */
  /* Instruktionen när utrustningsfasen börjar: spelaren ska aldrig behöva
     gissa var sadeln finns. */

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

  /* ── KONTEXTEN (P0-3) ───────────────────────────────────────────────
     HUD:en visade "Hälsa lugnt" medan spelaren stod någon annanstans i
     anläggningen. Instruktionen lovade alltså en handling servern
     samtidigt nekade med `spel.for_langt`. Rubriken pekar nu tillbaka i
     stället, och hästens EGENNAMN sätts in som argument — det översätts
     aldrig. */
  "hud.ga_tillbaka": { sv: "Gå tillbaka till %s", en: "Go back to %s" },
  "hud.ga_tillbaka_utan_namn": { sv: "Gå tillbaka till din häst",
    en: "Go back to your horse" },

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

  /* ATT LEDA HÄSTEN (#162 blockerare 2). Varje nej har en egen nyckel:
     ett samlat "gick inte" gör de negativa fallen omöjliga att skilja åt,
     och spelaren får veta VAD som var fel i stället för att gissa. */
  "led.borja": { sv: "Led hästen", en: "Lead the horse" },
  "led.slapp": { sv: "Släpp hästen", en: "Let go" },
  "led.leder": { sv: "Du leder %s", en: "You are leading %s" },
  "led.ingen_hast": { sv: "Ingen häst att leda", en: "No horse to lead" },
  "led.fel_hast": { sv: "Det är inte din häst", en: "That is not your horse" },
  "led.ingen_karaktar": { sv: "Ingen karaktär", en: "No character" },
  "led.rider": { sv: "Du sitter upp — du rider, du leder inte",
    en: "You are mounted — you are riding, not leading" },
  "led.hast_saknar_kropp": { sv: "Hästen har ingen kropp att följa med",
    en: "The horse has no body to follow with" },
  "led.for_langt": { sv: "Gå fram till henne först", en: "Walk up to her first" },
  "led.leder_redan": { sv: "Du leder redan", en: "You are already leading" },
  "led.leder_inte": { sv: "Du leder ingen häst", en: "You are not leading a horse" },
  "led.upptagen": { sv: "Någon annan leder henne", en: "Someone else is leading her" },
  "led.tappade_bort": { sv: "Hon kom efter — gå tillbaka och ta henne igen",
    en: "She fell behind — go back and take her again" },
  "led.tappad": { sv: "Du tappade henne", en: "You lost her" },
  "led.kvar_i_boxen": { sv: "Hon står kvar i boxen", en: "She is still in her stall" },
  "led.inte_framme": { sv: "Hon är inte framme i ridhuset än",
    en: "She is not in the arena yet" },
  /* Hon har kilat sig och vägsökningen har gett upp. Eget skäl: spelaren
     ska förstå att det är GEOMETRIN som stoppar, inte att hon vägrar. */
  "led.fastnat": { sv: "Hon kommer inte fram där — prova en annan väg",
    en: "She cannot get through there — try another way" },

  /* UTRUSTNINGEN. Skälen till fel sadel och fel träns är webbens egna ur
     `visaSadelkammare` — de FÖRKLARAR varför utrustningen hör till en
     bestämd häst, och det är själva lärandet. Ett "fel sadel" utan skäl
     hade gjort momentet till ett minnestest. */
  "tack.fel_sadel": {
    sv: "Fel sadel — den är formad efter en annan rygg. På fel häst trycker den på manken eller på njurarna",
    en: "Wrong saddle — it is shaped to another back. On the wrong horse it presses on the withers or the kidneys" },
  "tack.fel_trans": {
    sv: "Fel träns — det är inställt efter ett annat huvud. Bettet hamnar för högt eller för lågt och skaver i mungiporna",
    en: "Wrong bridle — it is fitted to another head. The bit sits too high or too low and chafes the corners of her mouth" },
  "tack.fel_hast": { sv: "Det är inte din häst", en: "That is not your horse" },
  "tack.redan_pa": { sv: "Den sitter redan på", en: "That is already on" },
  "tack.sadeln_forst": { sv: "Sadeln först", en: "The saddle first" },
  "tack.underlagget_forst": { sv: "Underlägget först — sadeln ligger på det",
    en: "The numnah first — the saddle goes on top of it" },
  "tack.transet_forst": { sv: "Tränset av först", en: "Take the bridle off first" },
  "tack.saknar_sadel": { sv: "Hon är inte sadlad än", en: "She is not saddled yet" },
  "tack.saknar_underlagg": { sv: "Underlägget ligger inte på", en: "The numnah is not on" },
  "tack.saknar_trans": { sv: "Hon är inte tränsad än", en: "She is not bridled yet" },
  "tack.for_langt": { sv: "Gå fram till henne först", en: "Walk up to her first" },
  "tack.inget_pa": { sv: "Det sitter inget sådant på henne", en: "She has none of that on" },
  "tack.ingen_hast": { sv: "Ingen häst att utrusta", en: "No horse to tack up" },
  "tack.ingen_karaktar": { sv: "Du är inte i världen", en: "You are not in the world" },
  "tack.hast_saknar_kropp": { sv: "Hästen saknar kropp att utrusta",
    en: "The horse has no body to tack up" },
  "tack.ingen_rigg": { sv: "Hästen saknar fästpunkter för utrustning",
    en: "The horse has no attachment points for tack" },
  "tack.okand_utrustning": { sv: "Sådan utrustning finns inte", en: "There is no such equipment" },
  /* Ett bygge som inte gick fram ska SÄGA det, inte tyst lämna en häst
     som ser osadlad ut men räknas som sadlad. */
  "tack.kunde_inte_byggas": { sv: "Utrustningen kom inte på plats — försök igen",
    en: "The tack did not go on — try again" },
  /* UPPHÄNGNINGEN PÅ BOXFRONTEN. Prompten och dess undertext, och nejet när
     spelaren inte har hämtat utrustningen. De låg bara i Roblox-katalogen
     efter `30f3d90`; paritetsgrinden fällde det. */
  "tack.ta_utrustning": { sv: "Ta sadel och träns", en: "Take the saddle and bridle" },
  "tack.utrustning_for": { sv: "%ss sadel och träns", en: "%s's saddle and bridle" },
  "tack.hamta_forst": { sv: "Du har varken sadel eller träns här — de hänger på boxfronten",
    en: "You have neither saddle nor bridle with you — they hang on the stall front" },

  /* LEKTIONSKORTETS ÖVNINGAR.

     Låg som svenska literaler i `src/larare.js` / `RidKanon.OVNINGAR` och
     renderades rakt av. Lokal Studio-QA på 9b5a570 mätte det: under en-US
     var kortets ram engelsk medan rubriken och båda punkterna var svenska
     — samma felklass som dörrarnas `ActionText` i 67e7716.

     Kanonen i `larare.js` är kvar som den är; den är övningens SANNING.
     Det här är dess spelarvända yta, och den hör hemma här. */
  "ugneta.ovning.halt_skritt.rubrik": { sv: "Halt → skritt", en: "Halt → walk" },
  "ugneta.ovning.halt_skritt.p1": { sv: "Titta dit du ska.", en: "Look where you are going." },
  "ugneta.ovning.halt_skritt.p2": { sv: "En tydlig skänkel — vänta på svaret.",
    en: "One clear leg aid — then wait for the answer." },
  "ugneta.ovning.skritt_trav.rubrik": { sv: "Skritt → trav", en: "Walk → trot" },
  "ugneta.ovning.skritt_trav.p1": { sv: "Behåll lugn kontakt.", en: "Keep a calm contact." },
  "ugneta.ovning.skritt_trav.p2": { sv: "Driv en gång tydligt fram i trav.",
    en: "Ask once, clearly, into trot." },
  "ugneta.ovning.storvolt.rubrik": { sv: "20 m volt", en: "20 m circle" },
  "ugneta.ovning.storvolt.p1": { sv: "Titta runt volten.", en: "Look around the circle." },
  "ugneta.ovning.storvolt.p2": { sv: "Inre skänkel — yttre tygel håller storleken.",
    en: "Inside leg — the outside rein keeps the size." },
  "ugneta.ovning.horn.rubrik": { sv: "Rid genom hörnet", en: "Ride through the corner" },
  "ugneta.ovning.horn.p1": { sv: "Behåll samma rytm.", en: "Keep the same rhythm." },
  "ugneta.ovning.horn.p2": { sv: "Balansera före hörnet — inte mitt i.",
    en: "Balance before the corner — not in the middle of it." },
  "ugneta.ovning.trav_skritt.rubrik": { sv: "Trav → skritt", en: "Trot → walk" },
  "ugneta.ovning.trav_skritt.p1": { sv: "Sitt ner och förbered.", en: "Sit down and prepare." },
  "ugneta.ovning.trav_skritt.p2": { sv: "Behåll skänkeln genom övergången.",
    en: "Keep the leg through the transition." },
  "ugneta.ovning.galoppfattning.rubrik": { sv: "Galoppfattning", en: "Striking off into canter" },
  "ugneta.ovning.galoppfattning.p1": { sv: "Balansera först.", en: "Balance first." },
  "ugneta.ovning.galoppfattning.p2": { sv: "Be tydligt — och låt hästen svara.",
    en: "Ask clearly — and let the horse answer." },

  /* Observationerna efter ett försök. Byggdes förut som svenska
     mallsträngar direkt i UgnetaController. */
  "ugneta.obs.battre": { sv: "Bättre %s den här gången.", en: "Better %s this time." },
  "ugneta.obs.kvar": { sv: "Fortsätt med %s.", en: "Keep working on %s." },
  "ugneta.obs.bra": { sv: "Bra %s.", en: "Good %s." },
  "ugneta.obs.jobba": { sv: "Jobba på %s.", en: "Work on %s." },

  /* ── KORTET SOM PAUSAR RITTEN (produktbeslut 13:29) ──────────────────
     Ridloopen fryser hästen medan ett lektionskort väntar — med flit: hon
     ska inte rida vidare bakom ett oläst kort. Men knappen sa bara
     "Börja", och den var dessutom HÅRDKODAD SVENSKA i logiken.

     För spelaren blev det en häst som inte rör sig utan att något säger
     varför, och för en engelsk spelare ett svenskt ord. Knappen säger nu
     vad som faktiskt händer när man trycker. */
  "ugneta.borja_lektionen": { sv: "Fortsätt för att börja lektionen",
    en: "Continue to start the lesson" },
  "ugneta.ej_bedomd.rubrik": { sv: "Försöket kunde inte bedömas",
    en: "The attempt could not be assessed" },
  "ugneta.ej_bedomd.punkt": {
    sv: "Det fanns inte tillräckligt mätt underlag den här gången.",
    en: "There was not enough measured data this time." },
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

/* ÖVERSÄTTNINGSSKULD, redovisad.

   Listan såg annorlunda ut före PRODUKTBESLUTET i #162: skötselkanonens
   undervisningstext och hästarnas beskrivningar stod här som skuld, med
   skälet att en builder inte får maskinöversätta hästkunskapens
   terminologi. Beslutet är fattat — en spelare som inte läser svenska ska
   läsa engelska — och båda posterna är därför BORTA ur listan och
   översatta i sina källor (`skotsel.js`, `hastar.js`). Egennamn är
   oförändrade: hästarna heter vad de heter.

   `firstPlayable` är det fältet grinden faktiskt mäter. Ingen post får
   säga `true`: det som spelaren ser under en First Playable-genomgång är
   inte skuld längre, det är krav. Posterna nedan lever på ytor utanför
   den vägen. */
const SPRAK_BACKLOG = [
  { kalla: "src/*.js (webbens egna vyer)", firstPlayable: false,
    vad: "webbens menyer, lektionstext, sysslo-vyer och hästkortets etiketter",
    skal: "webbens textmassa ligger i vyerna själva och är ännu inte flyttad till katalogen; den vägen är inte First Playable och tas som ett eget steg" },
  { kalla: "src/spel/hastar.js — fältet ras", firstPlayable: false,
    vad: "rasnamn (\"Svenskt varmblod\", \"Irländsk Sporthäst\")",
    skal: "visas ingenstans för spelaren i First Playable — bara i utvecklarutskrift — och är källdata ur ubrf.se; översätts när en yta faktiskt visar det" },
  { kalla: "src/spel/hastar.js — foderschemats notis", firstPlayable: false,
    vad: "foderradens notis på webbens sysslo-vy",
    skal: "webbyta, samma steg som webbens övriga textmassa; i Roblox går den bara till utvecklarutskrift" },
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
