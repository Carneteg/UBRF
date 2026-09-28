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
  /* NAROMRADETS reservetikett (#235). En prompt utan egen ActionText
     ska anda ga att trycka pa; raden far da det neutrala ordet i
     stallet for en tom knapp. */
  "interaktion.anvand": { sv: "Anvand", en: "Use" },
  /* #264 ROBLOX_HUMAN_PLAYTEST_FIX: vänstermenyns rad når en prompt med
     håll-grind. Motorns bubbla ritade en hållring; den bubblan är borta
     när menyn ersätter den, så menyn säger det själv — medan hållet
     pågår, och när någon släppt för tidigt. */
  "interaktion.hall_inne": { sv: "Håll inne", en: "Hold" },
  /* #264 PLAYER_INTERACTION_CONSOLIDATION: panelens rubrik uppsutten visar
     den gångart servern säger att hästen går i. `Gaits.label` finns bara
     på svenska och är kanonens identitet, inte spelartext. */
  "gangart.halt": { sv: "Halt", en: "Halt" },
  "gangart.walk": { sv: "Skritt", en: "Walk" },
  "gangart.trot": { sv: "Trav", en: "Trot" },
  "gangart.canter": { sv: "Galopp", en: "Canter" },
  "gangart.gallop": { sv: "Fyrsprång", en: "Gallop" },
  "panel.leder": { sv: "Leder", en: "Leading" },
  "panel.fler": { sv: "Fler handlingar", en: "More actions" },
  "panel.hjalp": { sv: "Hjälp", en: "Help" },
  /* #264 GAIT_READABILITY_AND_UGNETA: gångartens läge i panelen. Sitsen
     är assisterad och får inte låta som en prestation. */
  "sits.lattridning": { sv: "lättridning (assisterad)", en: "rising trot (assisted)" },
  "sits.sittande": { sv: "sittande", en: "seated" },
  "galopp.hoger": { sv: "höger galopp", en: "right lead" },
  "galopp.vanster": { sv: "vänster galopp", en: "left lead" },
  "gangart.byte": { sv: "%s till %s", en: "%s to %s" },
  /* Ugneta är ridinstruktören, hon/henne. Titeln står i hennes yta. */
  /* #264 GAIT_UGNETA_REVIEW_R1: live-signalerna. Den svenska texten är
     EXAKT kanonens (RidKanon.UGNETA.LIVE, ur src/larare.js) — provet
     jämför dem — och signalens id är identiteten, aldrig texten. */
  "ugneta.live.framat.fel": { sv: "Rid framåt", en: "Ride forward" },
  "ugneta.live.framat.bra": { sv: "Bra rytm", en: "Good rhythm" },
  "ugneta.live.hand.fel": { sv: "Mjukare hand", en: "Softer hands" },
  "ugneta.live.hand.bra": { sv: "Mjuk hand", en: "Soft hands" },
  "ugneta.live.lugn.fel": { sv: "Andas ut", en: "Breathe out" },
  "ugneta.live.lugn.bra": { sv: "Fint lugn", en: "Nice and calm" },
  "ugneta.live.sits.fel": { sv: "Sitt stilla", en: "Sit still" },
  "ugneta.live.sits.bra": { sv: "Bra sits", en: "Good seat" },
  "ugneta.live.timing.fel": { sv: "Vänta på svaret", en: "Wait for the answer" },
  "ugneta.live.timing.bra": { sv: "Precis så", en: "Just like that" },
  "ugneta.live.vagen.fel": { sv: "Titta dit du ska", en: "Look where you are going" },
  "ugneta.live.vagen.bra": { sv: "Bra linje", en: "Good line" },
  "ugneta.titel": { sv: "Ugneta · Ridinstruktör", en: "Ugneta · Riding instructor" },
  /* Flaggan visar det språk som GÄLLER; trycket byter. */
  "sprak.nuvarande": { sv: "Svenska", en: "English" },
  "sprak.byt": { sv: "Byt språk till engelska", en: "Switch language to Swedish" },
  /* Ugnetas ridrader utanför lektionen. Beröm pekar på något som faktiskt
     hände; tangenten är den spelaren faktiskt har (%s). */
  "ugneta.rad.borja_skritt": { sv: "Börja i skritt. Tryck på %s en gång.", en: "Start in walk. Press %s once." },
  "ugneta.rad.bra_skritt": { sv: "Bra! Du håller en lugn skritt.", en: "Good! You're keeping a steady walk." },
  "ugneta.rad.be_om_trav": { sv: "Be om trav med ett tryck på %s.", en: "Ask for trot by pressing %s once." },
  "ugneta.rad.lattridning": { sv: "Nu rider du lätt. Ryttaren följer travens rytm automatiskt.", en: "You're rising to the trot. Your rider follows the rhythm automatically." },
  "ugneta.rad.galopp": { sv: "Nu galopperar du. Rid en stor båge.", en: "You're cantering now. Ride a large curve." },
  "ugneta.rad.fin_overgang": { sv: "Fint! Det blev en lugn övergång.", en: "Well done! That was a smooth transition." },
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

  /* ── Takten (Skopa) ─────────────────────────────────────────────────
     #259 Gate 1A. Serverns fjärrfunktioner har en per-spelare-skopa, och
     den som trycker fortare än en människa hinner får det här nejet.
     Texten säger VAD spelaren ska göra — vänta — och inte att hon gjorde
     något fel: en ärlig spelare på dålig uppkoppling kan nå hit, och hon
     ska inte läsa en anklagelse. */
  "takt.for_snabbt": { sv: "Det där gick för snabbt — vänta ett ögonblick",
    en: "That was too quick — wait a moment" },
  "spel.redan_redo": { sv: "Hon står redan färdig", en: "She is already ready" },
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
  // Fallback när ett avslag med %s saknar sitt argument (#246 A). Den
  // säger samma sak som nyckeln den fyller — nästa steg i HÄSTENS
  // förberedelse — och inför ingen annan betydelse: "fel tur" handlar om
  // ordningen i förberedelsen, aldrig om att en annan ryttare väntar.
  "forb.nasta_steget": { sv: "nästa steg i förberedelsen",
    en: "the next preparation step" },
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
  "hud.ga_till": { sv: "Gå till %s", en: "Go to %s" },
  "hud.ga_till_utan_namn": { sv: "Gå till din häst", en: "Go to your horse" },
  "guide.din_hast": { sv: "din häst", en: "your horse" },
  "guide.dorr_rubrik": { sv: "Öppna stalldörren", en: "Open the stable door" },
  "guide.dorr_text": { sv: "Öppna dörren framför dig. Den gyllene pilen visar var %s står.", en: "Open the door in front of you. The gold arrow shows where %s is." },
  "guide.ga_till_rubrik": { sv: "Gå till %s", en: "Go to %s" },
  "guide.ga_till_text": { sv: "Följ den gyllene pilen till hennes box.", en: "Follow the gold arrow to her box." },
  "guide.valj_rubrik": { sv: "Välj hur du börjar", en: "Choose how to start" },
  "guide.valj_kort": { sv: "Rida nu: stallet gör i ordning %s rätt och leder henne till ridhuset. Eller gör i ordning henne själv — steg för steg.", en: "Ride now: the stable gets %s ready properly and leads her to the arena. Or get her ready yourself — step by step." },
  "guide.val_rida_nu": { sv: "Rida nu — %s", en: "Ride now — %s" },
  "guide.val_sjalv": { sv: "Gör i ordning %s själv", en: "Get %s ready myself" },
  "guide.halsa_rubrik": { sv: "Hälsa på %s", en: "Greet %s" },
  /* Webbens sidoaktivitet vid boxen (TOBIAS_DECISION_WEB_EXTRAS_VISIBLE_20260928):
     mockning och fodring finns kvar, men under «Fler handlingar» — aldrig
     som ett steg i förberedelsen. */
  "guide.fler_boxen": { sv: "Boxen — mocka och fodra", en: "The stall — muck out and feed" },
  "guide.visitera_rubrik": { sv: "Kolla %s", en: "Check %s over" },
  "guide.rykta_rubrik": { sv: "Rykta %s", en: "Groom %s" },
  "guide.hovar_rubrik": { sv: "Kratsa hovarna", en: "Pick out the hooves" },
  "guide.hamta_sadel_rubrik": { sv: "Hämta sadeln", en: "Fetch the saddle" },
  "guide.hamta_sadel_text": { sv: "Sadeln hänger på boxfronten hos %s. Ta den därifrån.", en: "The saddle hangs on the box front at %s. Take it from there." },
  "guide.hamta_trans_rubrik": { sv: "Hämta tränset", en: "Fetch the bridle" },
  "guide.hamta_trans_text": { sv: "Tränset hänger också på boxfronten. Ta det med dig.", en: "The bridle hangs on the box front too. Take it with you." },
  "guide.sadla_rubrik": { sv: "Lägg på sadeln", en: "Put the saddle on" },
  "guide.transa_rubrik": { sv: "Sätt på tränset", en: "Put the bridle on" },
  "guide.leda_rubrik": { sv: "Led %s till ridhuset", en: "Lead %s to the arena" },
  "guide.leda_text": { sv: "Välj «Led till ridhuset» i listan. Hon följer dig.", en: "Choose «Lead to the arena» in the list. She follows you." },
  "guide.leder_rubrik": { sv: "Led %s till ridhuset", en: "Lead %s to the arena" },
  "guide.leder_text": { sv: "Gå till ridhuset — %s följer dig. Där sitter du upp.", en: "Walk to the arena — %s follows you. You mount there." },
  "guide.sittupp_rubrik": { sv: "Sitt upp på %s", en: "Mount %s" },
  "guide.sittupp_text": { sv: "Sitt upp och rid! Välj sedan en lektion hos Ugneta eller rid fritt.", en: "Mount up and ride! Then choose a lesson with Ugneta or ride freely." },

  /* ── Hjälpen och kontrollerna (KontrollHjalp) ─────────────────────── */
  "hjalp.rubrik": { sv: "Kontroller", en: "Controls" },
  "hjalp.styrkors_upp": { sv: "Styrkors upp", en: "D-pad up" },
  "hjalp.styrkors_ned": { sv: "Styrkors ned", en: "D-pad down" },
  "hjalp.styrkors_vanster": { sv: "Styrkors vänster", en: "D-pad left" },
  "hjalp.styrkors_hoger": { sv: "Styrkors höger", en: "D-pad right" },
  "hjalp.namnlos_knapp": { sv: "(namnlös knapp: %s)", en: "(unnamed button: %s)" },
  "hjalp.sitt_upp_av": { sv: "Sitt upp / sitt av", en: "Mount / dismount" },
  "hjalp.vanster_hoger": { sv: "Vänster / höger", en: "Left / right" },
  "hjalp.vanster_spak": { sv: "Vänster spak", en: "Left stick" },
  "hjalp.hogre_gangart": { sv: "Ett steg upp i gångarterna", en: "One step up the gaits" },
  /* "ett steg ned" och inte "lagre gangart": ur halt ar steget RYGGA,
     och en hjalptext som lovar en langsammare gangart hade varit fel
     precis dar spelaren behover den mest. */
  "hjalp.lagre_gangart": { sv: "Ett steg ned — ur halt: rygga", en: "One step down — from halt: back up" },
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
  /* SITT AV ar kvar nar de ovriga touch-etiketterna forsvann med panelen:
     den ar inget reglage utan enda vagen AV hasten pa en ren pekenhet
     (#162 blockerare 2). Den ar numera en ContextActionService-handling. */
  /* ── Byggidentiteten (#263) ────────────────────────────────────────
     Vilken build sitter jag i? Raderna läses av QA på en fysisk enhet,
     där serverloggen inte är tillgänglig för ett vanligt testkonto.
     "okänd" är inte en artighet utan ett krav: en saknad identitet får
     aldrig se ut som en matchad. */
  "bygg.rubrik": { sv: "Byggidentitet", en: "Build identity" },
  "bygg.stang": { sv: "Stäng", en: "Close" },
  "bygg.okand": { sv: "okänd", en: "unknown" },
  "bygg.kallhash": { sv: "Källhash", en: "Source hash" },
  "bygg.kallor": { sv: "Källfiler", en: "Source files" },
  "bygg.lage": { sv: "Läge", en: "Mode" },
  "bygg.genererad": { sv: "Genererad", en: "Generated" },
  "bygg.plats": { sv: "Plats", en: "Place" },
  "bygg.version": { sv: "Platsversion", en: "Place version" },
  "bygg.miljo": { sv: "Miljö", en: "Environment" },
  /* Motorn säger 0 för varje opublicerad upplevelse. Talet ensamt
     förklarar inte varför, så raden skriver ut skälet. */
  "bygg.opublicerad": { sv: "0 — opublicerad", en: "0 — unpublished" },
  /* Mätt i motorn: Studio rapporterar den version .rbxl-filen öppnades
     från, medan Rojo samtidigt synkat in annan kod. Talet är sant och
     vilseledande på en gång, så det får aldrig stå ensamt. */
  "bygg.studioversion": { sv: "%d — men Studio kör Rojos kod", en: "%d — but Studio runs Rojo's code" },
  "bygg.studio": { sv: "Studio (lokalt)", en: "Studio (local)" },
  "bygg.server": { sv: "Publicerad server", en: "Published server" },

  "touch.sitt_av": { sv: "SITT AV", en: "DISMOUNT" },
  "touch.lugnare": { sv: "▼ LUGNARE", en: "▼ SLOWER" },
  "touch.framat": { sv: "▲ FRAMÅT", en: "▲ FORWARD" },

  /* ── Ugneta, ridläraren ────────────────────────────────────────────── */
  // "ugneta.rubrik" — avsändarraden i Ugnetas gamla nederpanel. Panelen är
  // riven (#244): lärartexten ligger i CoachBanner, som inte har någon
  // avsändarrad. Nyckeln är borttagen i stället för kvarlämnad, av samma
  // skäl som touch-panelens döda nycklar — en etikett ingen kan se drar
  // med sig en översättning att underhålla. Webbens egen `.ugneta-namn`
  // använde den aldrig; den skriver sin sträng direkt i src/larare.js.
  "ugneta.hastens_svar": { sv: "hästens svar", en: "the horse's response" },
  "ugneta.prova_igen": { sv: "Prova igen", en: "Try again" },
  "voltlektion.choose": { sv: "Träna volt", en: "Practice a circle" },
  "voltlektion.lessons": { sv: "Andra övningar", en: "Other exercises" },
  "voltlektion.fri_traning": { sv: "Fri träning med återspelning", en: "Free practice with replay" },
  "voltlektion.start": { sv: "Starta volten", en: "Start circle" },
  "voltlektion.retry": { sv: "Prova igen", en: "Try again" },
  "voltlektion.finish": { sv: "Avsluta voltlektionen", en: "Finish circle lesson" },
  "voltlektion.sync": { sv: "Hämta lektionsläget", en: "Check lesson state" },
  "voltlektion.intro": { sv: "Rid en volt kring mitten av dressyrbanan. Välj själv åt vilket håll.", en: "Ride a circle around the centre of the dressage arena. Choose either direction." },
  "voltlektion.approach": { sv: "Rid fram till det gröna bandet. Där börjar vi följa ditt varv.", en: "Ride to the green band. We will follow your circle from there." },
  "voltlektion.ride": { sv: "Titta runt volten och följ bandet hela vägen.", en: "Look around the circle and follow the band all the way." },
  "voltlektion.line": { sv: "Hitta bandet igen, så börjar vi ett nytt varv tillsammans.", en: "Find the band again and we will start a fresh circle together." },
  "voltlektion.line_ut": { sv: "Ni gled lite utåt från volten. Styr in mot mitten och titta dit du vill rida – hitta bandet igen, så börjar vi ett nytt varv.", en: "You drifted a little out from the circle. Steer in towards the middle and look where you want to go – find the band again and we will start a fresh circle." },
  "voltlektion.line_in": { sv: "Ni kom lite för nära mitten. Styr ut mot bandet och håll samma avstånd runt hela varvet – hitta bandet igen, så börjar vi ett nytt varv.", en: "You came a little too close to the middle. Steer out towards the band and keep the same distance all the way round – find the band again and we will start a fresh circle." },
  "voltlektion.unknown": { sv: "Jag tappade en bit av din väg. Hitta bandet igen för ett nytt varv.", en: "I missed part of your path. Find the band again for a fresh circle." },
  "voltlektion.complete": { sv: "Volt klar! Du red ett helt varv och höll dig nära voltlinjen.", en: "Circle completed! You rode a full circle and stayed close to the line." },
  "voltlektion.timeout": { sv: "Vi har inget helt varv att bedöma ännu. Ta en paus eller prova igen.", en: "We do not have a full circle to assess yet. Take a break or try again." },
  "voltlektion.closed": { sv: "Voltlektionen är avslutad.", en: "The circle lesson has ended." },
  "voltlektion.pending": { sv: "Väntar på lektionsbesked…", en: "Waiting for the lesson response…" },
  "voltlektion.network": { sv: "Lektionsbeskedet saknas. Hämta läget igen eller avsluta.", en: "The lesson response is missing. Check the state again or finish." },
  "voltlektion.place": { sv: "Rid in på dressyrbanan innan du startar volten.", en: "Enter the dressage arena before starting the circle." },
  "voltlektion.active": { sv: "Ett ridförsök pågår redan. Avsluta det innan du börjar ett nytt.", en: "A riding attempt is already active. Finish it before starting another." },
  "haltlektion.choose": { sv: "Träna start och halt", en: "Practice start and halt" },
  "haltlektion.start": { sv: "Starta övningen", en: "Start exercise" },
  "haltlektion.finish": { sv: "Avsluta start och halt", en: "Finish start and halt" },
  "haltlektion.intro": { sv: "Stå still i halt, skritta fram och gör ett halt vid X – mitt på dressyrbanan.", en: "Stand still in halt, walk on and halt at X – the centre of the dressage arena." },
  "haltlektion.halt_first": { sv: "Börja med att stå helt still i halt.", en: "Start by standing completely still in halt." },
  "haltlektion.walk_on": { sv: "Fint! Be om skritt med en tydlig skänkel.", en: "Nice! Ask for walk with a clear leg aid." },
  "haltlektion.walk_only": { sv: "Stanna i skritt – lugnt och jämnt.", en: "Stay in walk – calm and even." },
  "haltlektion.to_x": { sv: "Skritta mot X, den gröna ringen mitt på banan.", en: "Walk towards X, the green ring in the middle of the arena." },
  "haltlektion.hold": { sv: "Halt vid X – håll henne stilla en stund.", en: "Halt at X – keep her still for a moment." },
  "haltlektion.halt_outside": { sv: "Ett fint halt! Skritta vidare och prova att stanna inne i ringen vid X.", en: "A nice halt! Walk on and try stopping inside the ring at X." },
  "haltlektion.halt_at_x": { sv: "Be om halt när du är inne i ringen vid X.", en: "Ask for halt when you are inside the ring at X." },
  "haltlektion.unknown": { sv: "Jag tappade en bit av ritten. Vi börjar om från ett halt.", en: "I missed part of the ride. Let us start again from a halt." },
  "haltlektion.complete": { sv: "Halt vid X klart! Du skrittade fram och stannade på rätt plats.", en: "Halt at X completed! You walked on and stopped in the right place." },
  "haltlektion.timeout": { sv: "Vi hann inte fram till ett halt vid X. Ta en paus eller prova igen.", en: "We did not reach a halt at X yet. Take a break or try again." },
  "haltlektion.closed": { sv: "Start och halt är avslutad.", en: "Start and halt has ended." },
  "haltlektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "overganglektion.choose": { sv: "Träna övergångar", en: "Practice transitions" },
  "overganglektion.start": { sv: "Starta övergångarna", en: "Start transitions" },
  "overganglektion.finish": { sv: "Avsluta övergångarna", en: "Finish transitions" },
  "overganglektion.intro": { sv: "Skritta, trava vid första gröna ringen och skritta igen vid den andra. Ringarna ligger på mittlinjen.", en: "Walk, trot at the first green ring and walk again at the second. The rings are on the centre line." },
  "overganglektion.walk_on": { sv: "Skritta fram med jämn takt.", en: "Walk on with an even rhythm." },
  "overganglektion.walk_first": { sv: "Bra försök! Skritta en bit först, sedan traven vid första ringen.", en: "Good try! Walk a little first, then trot at the first ring." },
  "overganglektion.trot_at_t1": { sv: "Fint! Be om trav inne i första ringen.", en: "Nice! Ask for trot inside the first ring." },
  "overganglektion.trot_outside": { sv: "Traven kom utanför ringen. Skritta igen och prova vid första ringen.", en: "The trot came outside the ring. Walk again and try at the first ring." },
  "overganglektion.trot_on": { sv: "Trav! Håll traven jämn mot andra ringen.", en: "Trot! Keep the trot even towards the second ring." },
  "overganglektion.trot_longer": { sv: "Trava lite längre innan du skrittar. Vi börjar om från skritt.", en: "Trot a little longer before walking. We start again from walk." },
  "overganglektion.walk_at_t2": { sv: "Be om skritt inne i andra ringen.", en: "Ask for walk inside the second ring." },
  "overganglektion.walk_outside": { sv: "Skritten kom utanför andra ringen. Vi börjar om från skritt.", en: "The walk came outside the second ring. We start again from walk." },
  "overganglektion.trot_early": { sv: "Traven kom innan ni var framme vid första ringen. Skritta igen och be om trav först när ni är inne i ringen.", en: "The trot came before you reached the first ring. Walk again and ask for trot only once you are inside the ring." },
  "overganglektion.trot_late": { sv: "Traven kom när ni redan hade passerat första ringen. Skritta igen och be om trav lite tidigare, när ni rider in i ringen.", en: "The trot came when you had already passed the first ring. Walk again and ask for trot a little earlier, as you ride into the ring." },
  "overganglektion.walk_early": { sv: "Skritten kom innan ni var framme vid andra ringen. Håll traven tills ni är inne i ringen. Vi börjar om från skritt.", en: "The walk came before you reached the second ring. Keep the trot until you are inside the ring. We start again from walk." },
  "overganglektion.walk_late": { sv: "Skritten kom när ni redan hade passerat andra ringen. Be om skritt lite tidigare, när ni rider in i ringen. Vi börjar om från skritt.", en: "The walk came when you had already passed the second ring. Ask for walk a little earlier, as you ride into the ring. We start again from walk." },
  "overganglektion.walk_calm": { sv: "Skritt! Låt henne gå lugnt en bit.", en: "Walk! Let her walk calmly for a while." },
  "overganglektion.tired": { sv: "Hon blev trött och föll av sig själv. Vila en stund och börja om från skritt.", en: "She got tired and dropped on her own. Rest a while and start again from walk." },
  "overganglektion.walk_only": { sv: "Håll skritten – vi börjar om därifrån.", en: "Keep the walk – we start again from there." },
  "overganglektion.trot_only": { sv: "Stanna i trav tills du når andra ringen. Vi börjar om från skritt.", en: "Stay in trot until the second ring. We start again from walk." },
  "overganglektion.unknown": { sv: "Jag tappade en bit av ritten. Vi börjar om från skritt.", en: "I missed part of the ride. We start again from walk." },
  "overganglektion.complete": { sv: "Övergångarna klara! Trav vid första ringen och skritt vid den andra.", en: "Transitions completed! Trot at the first ring and walk at the second." },
  "overganglektion.timeout": { sv: "Vi hann inte hela vägen. Ta en paus eller prova igen.", en: "We did not get all the way. Take a break or try again." },
  "overganglektion.closed": { sv: "Övergångslektionen är avslutad.", en: "The transition lesson has ended." },
  "overganglektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "serpentinlektion.choose": { sv: "Rid en serpentin", en: "Ride a serpentine" },
  "serpentinlektion.start": { sv: "Starta serpentinen", en: "Start the serpentine" },
  "serpentinlektion.finish": { sv: "Avsluta serpentinen", en: "Finish the serpentine" },
  "serpentinlektion.intro": { sv: "Tre bågar som byter sida vid mittlinjen. Börja i startringen nära A och följ de gröna strecken till slutringen.", en: "Three loops that change side at the centre line. Begin in the start ring near A and follow the green dashes to the end ring." },
  "serpentinlektion.to_start": { sv: "Rid in i startringen på mittlinjen nära A.", en: "Ride into the start ring on the centre line near A." },
  "serpentinlektion.loop1": { sv: "Följ första bågen ut mot långsidan och tillbaka till mittlinjen.", en: "Follow the first loop out towards the long side and back to the centre line." },
  "serpentinlektion.loop2": { sv: "Över mittlinjen! Följ andra bågen åt andra hållet.", en: "Across the centre line! Follow the second loop the other way." },
  "serpentinlektion.loop3": { sv: "Sista bågen – åt samma håll som den första.", en: "Last loop – the same way as the first." },
  "serpentinlektion.to_end": { sv: "Nästan klart! Rid in i slutringen på mittlinjen.", en: "Almost done! Ride into the end ring on the centre line." },
  "serpentinlektion.off_route": { sv: "Ni kom utanför strecken. Rid tillbaka till startringen och börja om.", en: "You left the dashes. Ride back to the start ring and begin again." },
  "serpentinlektion.reverse": { sv: "Serpentinen rids från A mot C. Rid till startringen och börja om.", en: "The serpentine goes from A towards C. Ride to the start ring and begin again." },
  "serpentinlektion.walk_or_trot": { sv: "Rid serpentinen i skritt eller trav. Rid till startringen och börja om.", en: "Ride the serpentine in walk or trot. Ride to the start ring and begin again." },
  "serpentinlektion.unknown": { sv: "Jag tappade en bit av ritten. Rid till startringen så börjar vi om.", en: "I missed part of the ride. Ride to the start ring and we begin again." },
  "serpentinlektion.complete": { sv: "Serpentinen klar! Tre bågar och två fina byten över mittlinjen.", en: "Serpentine completed! Three loops and two nice changes across the centre line." },
  "serpentinlektion.timeout": { sv: "Vi hann inte hela serpentinen. Ta en paus eller prova igen.", en: "We did not finish the serpentine. Take a break or try again." },
  "serpentinlektion.closed": { sv: "Serpentinlektionen är avslutad.", en: "The serpentine lesson has ended." },
  "serpentinlektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "tempolektion.choose": { sv: "Rid i jämn fart", en: "Walk at a steady pace" },
  "tempolektion.start": { sv: "Starta jämn fart", en: "Start steady pace" },
  "tempolektion.finish": { sv: "Avsluta jämn fart", en: "Finish steady pace" },
  "tempolektion.intro": { sv: "Skritta framåt inne på dressyrbanan och håll samma fart en stund. Rakt eller i böjar går lika bra.", en: "Walk forward inside the dressage arena and keep the same speed for a while. Straight or on curves is fine." },
  "tempolektion.walk_on": { sv: "Skritta fram i lugn, jämn fart.", en: "Walk on at a calm, even speed." },
  "tempolektion.keep_going": { sv: "Fint, jämn fart! Fortsätt så.", en: "Nice, an even speed! Keep going." },
  "tempolektion.too_slow": { sv: "Lite för långsamt – skritta på lite mer.", en: "A little too slow – walk on a bit more." },
  "tempolektion.too_fast": { sv: "Lite för fort – ta det lugnt i skritt.", en: "A little too fast – take it easy in walk." },
  "tempolektion.steadier": { sv: "Farten ändrades. Håll den jämnare så börjar vi räkna igen.", en: "The speed changed. Keep it more even and we count again." },
  "tempolektion.walk_only": { sv: "Övningen görs i skritt. Skritta igen så börjar vi om.", en: "This exercise is in walk. Walk again and we start over." },
  "tempolektion.stay_inside": { sv: "Stanna inne på dressyrbanan. Skritta vidare därinne så börjar vi om.", en: "Stay inside the dressage arena. Keep walking in there and we start over." },
  "tempolektion.unknown": { sv: "Jag tappade en bit av ritten. Skritta vidare så börjar vi om.", en: "I missed part of the ride. Keep walking and we start over." },
  "tempolektion.complete": { sv: "Jämn fart klar! Du höll samma skrittfart hela sträckan.", en: "Steady pace completed! You kept the same walking speed all the way." },
  "tempolektion.timeout": { sv: "Vi hann inte klart. Ta en paus eller prova igen.", en: "We did not finish in time. Take a break or try again." },
  "tempolektion.closed": { sv: "Övningen i jämn fart är avslutad.", en: "The steady pace exercise has ended." },
  "tempolektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "lektionsval.gangart": { sv: "Gångarter och fart", en: "Gaits and pace" },
  "lektionsval.vagar": { sv: "Ridvägar", en: "Riding paths" },
  "lektionsval.tillbaka": { sv: "Tillbaka", en: "Back" },
  "lektionsval.valj": { sv: "Välj en övning.", en: "Choose an exercise." },
  "lektionsval.oppna": { sv: "Välj övning", en: "Choose exercise" },
  "vaglektion.choose_mitt": { sv: "Mittlinjen", en: "Centre line" },
  "vaglektion.choose_diag": { sv: "Diagonalen", en: "Diagonal" },
  "vaglektion.start": { sv: "Starta ridvägen", en: "Start the riding path" },
  "vaglektion.finish": { sv: "Avsluta ridvägen", en: "Finish the riding path" },
  "vaglektion.intro_mitt": { sv: "Rid rakt längs mittlinjen från startringen nära A till slutringen nära C. Pilarna visar hållet.", en: "Ride straight along the centre line from the start ring near A to the end ring near C. The arrows show the way." },
  "vaglektion.intro_diag": { sv: "Byt sida på diagonalen: från startringen nära A till slutringen på andra sidan nära C. Pilarna visar hållet.", en: "Change sides on the diagonal: from the start ring near A to the end ring on the other side near C. The arrows show the way." },
  "vaglektion.to_start": { sv: "Rid in i startringen och vänd mot pilarna.", en: "Ride into the start ring and face the arrows." },
  "vaglektion.ride_mitt": { sv: "Bra! Håll dig på mittlinjen mot slutringen.", en: "Good! Stay on the centre line towards the end ring." },
  "vaglektion.ride_diag": { sv: "Bra! Följ diagonalen över till andra sidan.", en: "Good! Follow the diagonal across to the other side." },
  "vaglektion.to_end": { sv: "Nästan framme! Rid in i slutringen.", en: "Almost there! Ride into the end ring." },
  "vaglektion.off_route": { sv: "Ni kom av linjen. Rid tillbaka till startringen och börja om.", en: "You left the line. Ride back to the start ring and begin again." },
  "vaglektion.reverse": { sv: "Linjen rids mot pilarna. Rid till startringen och börja om.", en: "The line goes the way of the arrows. Ride to the start ring and begin again." },
  "vaglektion.utan_streck": { sv: "Rid utan streck", en: "Ride without lines" },
  "vaglektion.visa_vagen": { sv: "Visa vägen", en: "Show the way" },
  "vaglektion.walk_or_trot": { sv: "Rid linjen i skritt eller trav. Rid till startringen och börja om.", en: "Ride the line in walk or trot. Ride to the start ring and begin again." },
  "vaglektion.unknown": { sv: "Jag tappade en bit av ritten. Rid till startringen så börjar vi om.", en: "I missed part of the ride. Ride to the start ring and we begin again." },
  "vaglektion.complete": { sv: "Ridvägen klar! Du red hela linjen från start till mål.", en: "Riding path completed! You rode the whole line from start to finish." },
  "vaglektion.timeout": { sv: "Vi hann inte hela linjen. Ta en paus eller prova igen.", en: "We did not finish the line. Take a break or try again." },
  "vaglektion.closed": { sv: "Ridvägen är avslutad.", en: "The riding path has ended." },
  "vaglektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "lektionsval.linjer": { sv: "Raka linjer och markbom", en: "Straight lines and ground pole" },
  "halvvoltlektion.choose": { sv: "Halvvolt", en: "Half-circle" },
  "halvvoltlektion.start": { sv: "Starta halvvolten", en: "Start the half-circle" },
  "halvvoltlektion.finish": { sv: "Avsluta halvvolten", en: "Finish the half-circle" },
  "halvvoltlektion.intro": { sv: "Rid på spåret mot C, gör en halvvolt in mot mitten och rid tillbaka till spåret mot A. Följ de gröna strecken.", en: "Ride on the track towards C, make a half-circle towards the middle and ride back to the track towards A. Follow the green dashes." },
  "halvvoltlektion.to_start": { sv: "Rid in i startringen på spåret.", en: "Ride into the start ring on the track." },
  "halvvoltlektion.track": { sv: "Fint! Följ spåret fram till bågen.", en: "Nice! Follow the track up to the curve." },
  "halvvoltlektion.half_circle": { sv: "Nu halvvolten – följ bågen in mot mitten.", en: "Now the half-circle – follow the curve towards the middle." },
  "halvvoltlektion.return": { sv: "Bra! Rid rakt tillbaka mot spåret.", en: "Good! Ride straight back towards the track." },
  "halvvoltlektion.to_end": { sv: "Nästan klart! Rid in i slutringen på spåret.", en: "Almost done! Ride into the end ring on the track." },
  "halvvoltlektion.off_route": { sv: "Ni kom utanför strecken. Rid till startringen och börja om.", en: "You left the dashes. Ride to the start ring and begin again." },
  "halvvoltlektion.reverse": { sv: "Vägen rids åt pilarnas håll. Rid till startringen och börja om.", en: "The route goes the way of the arrows. Ride to the start ring and begin again." },
  "halvvoltlektion.halt_moved": { sv: "Hon flyttade sig under halten. Rid till startringen och börja om.", en: "She moved during the halt. Ride to the start ring and begin again." },
  "halvvoltlektion.walk_or_trot": { sv: "Rid halvvolten i skritt eller trav. Rid till startringen och börja om.", en: "Ride the half-circle in walk or trot. Ride to the start ring and begin again." },
  "halvvoltlektion.unknown": { sv: "Jag tappade en bit av ritten. Rid till startringen så börjar vi om.", en: "I missed part of the ride. Ride to the start ring and we begin again." },
  "halvvoltlektion.complete": { sv: "Halvvolten klar! Du bytte håll och kom tillbaka till spåret.", en: "Half-circle completed! You changed direction and came back to the track." },
  "halvvoltlektion.timeout": { sv: "Vi hann inte hela halvvolten. Ta en paus eller prova igen.", en: "We did not finish the half-circle. Take a break or try again." },
  "halvvoltlektion.closed": { sv: "Halvvolten är avslutad.", en: "The half-circle has ended." },
  "halvvoltlektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "halvvoltlektion.mindre_stod": { sv: "Rid utan strecken längs spåret", en: "Ride without the lines along the track" },
  "lektionsval.overgangar": { sv: "Övergångar", en: "Transitions" },
  "galopplektion.choose": { sv: "Galoppfattning", en: "Canter departure" },
  "galopplektion.start": { sv: "Starta galoppfattningen", en: "Start the canter departure" },
  "galopplektion.finish": { sv: "Avsluta galoppfattningen", en: "Finish the canter departure" },
  "galopplektion.intro": { sv: "Trava en bit, be om galopp inne i den gröna ringen K på mittlinjen och galoppera vidare. Galoppsidan bedöms inte här.", en: "Trot for a while, ask for canter inside the green ring K on the centre line and canter on. The canter lead is not judged here." },
  "galopplektion.trot_on": { sv: "Trava på med jämn takt mot ringen K.", en: "Trot on with an even rhythm towards the ring K." },
  "galopplektion.trot_first": { sv: "Bra försök! Trava lite längre först, sedan galopp i ringen K.", en: "Good try! Trot a little longer first, then canter in the ring K." },
  "galopplektion.canter_at_k": { sv: "Fint! Be om galopp när du är inne i ringen K.", en: "Nice! Ask for canter when you are inside the ring K." },
  "galopplektion.canter_outside": { sv: "Galoppen kom utanför ringen. Trava igen och prova i ringen K.", en: "The canter came outside the ring. Trot again and try in the ring K." },
  "galopplektion.canter_early": { sv: "Galoppen kom innan ni var framme vid ringen K. Trava igen och be om galopp först när ni är inne i ringen.", en: "The canter came before you reached the ring K. Trot again and ask for canter only once you are inside the ring." },
  "galopplektion.canter_late": { sv: "Galoppen kom när ni redan hade passerat ringen K. Trava igen och be om galopp lite tidigare, när ni rider in i ringen.", en: "The canter came when you had already passed the ring K. Trot again and ask for canter a little earlier, as you ride into the ring." },
  "galopplektion.canter_on": { sv: "Galopp! Rid vidare en bit i galopp.", en: "Canter! Ride on for a while in canter." },
  "galopplektion.canter_longer": { sv: "Galoppera lite längre nästa gång. Trava igen så börjar vi om.", en: "Canter a little longer next time. Trot again and we start over." },
  "galopplektion.tired": { sv: "Hon blev trött och föll av sig själv. Vila en stund och börja om i trav.", en: "She got tired and dropped on her own. Rest a while and start again in trot." },
  "galopplektion.unknown": { sv: "Jag tappade en bit av ritten. Trava vidare så börjar vi om.", en: "I missed part of the ride. Keep trotting and we start over." },
  "galopplektion.complete": { sv: "Galoppfattningen klar! Du fattade galopp vid K och galopperade vidare.", en: "Canter departure completed! You picked up canter at K and cantered on." },
  "galopplektion.timeout": { sv: "Vi hann inte klart. Ta en paus eller prova igen.", en: "We did not finish in time. Take a break or try again." },
  "galopplektion.closed": { sv: "Galoppfattningen är avslutad.", en: "The canter departure has ended." },
  "galopplektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "markbomlektion.choose": { sv: "Bom på marken", en: "Ground pole" },
  "markbomlektion.start": { sv: "Starta bommen", en: "Start the ground pole" },
  "markbomlektion.finish": { sv: "Avsluta bommen", en: "Finish the ground pole" },
  "markbomlektion.intro": { sv: "Skritta rakt mot bommen på marken, över den mot C och en bit vidare. Följ de gröna strecken.", en: "Walk straight to the ground pole, over it towards C and on a little. Follow the green dashes." },
  "markbomlektion.to_approach": { sv: "Rid till de gröna strecken framför bommen och skritta rakt mot den.", en: "Ride to the green dashes in front of the pole and walk straight towards it." },
  "markbomlektion.walk_to_pole": { sv: "Fint! Skritta rakt fram mot bommen.", en: "Nice! Walk straight on towards the pole." },
  "markbomlektion.approach_longer": { sv: "Börja lite längre bak så att ni hinner skritta rakt fram.", en: "Start a little further back so you can walk straight in." },
  "markbomlektion.over_pole": { sv: "Skritta över bommen, mitt emellan märkena.", en: "Walk over the pole, between the marks." },
  "markbomlektion.walk_on_after": { sv: "Bra! Skritta rakt vidare en bit.", en: "Good! Walk straight on a little." },
  "markbomlektion.walk_on": { sv: "Hela vägen i skritt – rid tillbaka och skritta in igen.", en: "All the way in walk – ride back and walk in again." },
  "markbomlektion.walk_only": { sv: "Övningen görs i skritt. Rid tillbaka och skritta in igen.", en: "This exercise is in walk. Ride back and walk in again." },
  "markbomlektion.off_line": { sv: "Ni kom utanför strecken. Rid tillbaka och skritta in rakt.", en: "You left the dashes. Ride back and walk in straight." },
  "markbomlektion.reverse": { sv: "Skritta framåt mot C. Rid tillbaka och börja om.", en: "Walk forwards towards C. Ride back and begin again." },
  "markbomlektion.beside_pole": { sv: "Ni red vid sidan om bommen. Sikta mitt emellan märkena.", en: "You went beside the pole. Aim between the marks." },
  "markbomlektion.no_passage": { sv: "Ni kom inte över bommen. Skritta in igen och över den.", en: "You did not get over the pole. Walk in again and over it." },
  "markbomlektion.wrong_direction": { sv: "Bommen rids mot C här. Rid runt och skritta in igen.", en: "The pole is ridden towards C here. Ride round and walk in again." },
  "markbomlektion.pole_missing": { sv: "Bommen på marken är inte på sin plats just nu.", en: "The ground pole is not in its place right now." },
  "markbomlektion.unknown": { sv: "Jag tappade en bit av ritten. Rid tillbaka och skritta in igen.", en: "I missed part of the ride. Ride back and walk in again." },
  "markbomlektion.complete": { sv: "Bommen klar! Du skrittade rakt över den och vidare.", en: "Ground pole completed! You walked straight over it and on." },
  "markbomlektion.timeout": { sv: "Vi hann inte klart. Ta en paus eller prova igen.", en: "We did not finish in time. Take a break or try again." },
  "markbomlektion.closed": { sv: "Bommen på marken är avslutad.", en: "The ground pole has ended." },
  "markbomlektion.place": { sv: "Rid in i ridhuset innan du startar.", en: "Ride into the indoor arena before you start." },
  "markbomlektion.mindre_stod": { sv: "Rid bara efter bommen och märkena", en: "Ride by the pole and its marks only" },
  "ledlektion.choose": { sv: "Leda till ridhuset", en: "Lead to the arena" },
  "ledlektion.start": { sv: "Starta ledningen", en: "Start leading" },
  "ledlektion.retry": { sv: "Leda igen", en: "Lead again" },
  "ledlektion.finish": { sv: "Avsluta ledningen", en: "Finish leading" },
  "ledlektion.back": { sv: "Tillbaka", en: "Back" },
  "ledlektion.sync": { sv: "Försök igen", en: "Try again" },
  "ledlektion.intro": { sv: "Led din häst till fots hela vägen in på ridbanan. Hästen ska stå utanför när du startar.", en: "Lead your horse on foot all the way onto the arena track. The horse should be outside when you start." },
  "ledlektion.lead_first": { sv: "Ta din häst och börja leda henne.", en: "Take your horse and start leading her." },
  "ledlektion.outside_first": { sv: "Hon står redan på ridbanan. Led ut henne först.", en: "She is already on the arena track. Lead her out first." },
  "ledlektion.lead_on": { sv: "Fint! Led henne lugnt mot ridhuset.", en: "Nice! Lead her calmly towards the arena." },
  "ledlektion.into_arena": { sv: "Bra! Led in henne på ridbanan.", en: "Good! Lead her onto the arena track." },
  "ledlektion.settle": { sv: "Framme! Låt henne stå kvar en stund.", en: "You are there! Let her stand for a moment." },
  "ledlektion.released": { sv: "Du släppte henne. Ta henne igen och led henne hela vägen.", en: "You let go of her. Take her again and lead her all the way." },
  "ledlektion.wrong_horse": { sv: "Det där är inte din häst. Led din egen häst.", en: "That is not your horse. Lead your own horse." },
  "ledlektion.horse": { sv: "Jag hittar inte din häst just nu.", en: "I cannot find your horse right now." },
  "ledlektion.mounted": { sv: "Den här övningen gör du till fots. Sitt av och led henne.", en: "You do this exercise on foot. Dismount and lead her." },
  "ledlektion.character": { sv: "Vänta tills du är tillbaka, så fortsätter vi.", en: "Wait until you are back, then we continue." },
  "ledlektion.target": { sv: "Ridbanan går inte att hitta just nu.", en: "The arena track cannot be found right now." },
  "ledlektion.inside": { sv: "Hon står redan på ridbanan. Led ut henne först.", en: "She is already on the arena track. Lead her out first." },
  "ledlektion.unknown": { sv: "Jag tappade en bit av vägen. Led henne vidare så börjar vi om.", en: "I missed part of the way. Keep leading her and we start over." },
  "ledlektion.active": { sv: "Avsluta ledningen först.", en: "Finish leading first." },
  "ledlektion.stale_attempt": { sv: "Det där gällde en äldre ledning. Här är den aktuella.", en: "That was for an earlier lead. Here is the current one." },
  "ledlektion.stale_context": { sv: "Hästen eller du har bytts sedan knappen visades. Här är läget nu.", en: "The horse or you changed since that button was shown. Here is the current state." },
  "ledlektion.pending": { sv: "Ett ögonblick…", en: "One moment…" },
  "ledlektion.network": { sv: "Jag nådde inte stallet. Försök igen.", en: "I could not reach the stable. Try again." },
  "ledlektion.complete": { sv: "Snyggt ledd! Du ledde henne hela vägen in på ridbanan.", en: "Nicely led! You led her all the way onto the arena track." },
  "ledlektion.timeout": { sv: "Vi hann inte hela vägen. Ta en paus eller försök igen.", en: "We did not get all the way. Take a break or try again." },
  "ledlektion.closed": { sv: "Ledningen är avslutad.", en: "Leading has ended." },
  "aterkoppling.okant": { sv: "Övningen är klar, men jag har inga detaljer att visa den här gången.", en: "The exercise is complete, but I have no details to show this time." },
  "aterkoppling.timeout": { sv: "Tiden tog slut – du kom %s %% av vägen.", en: "Time ran out – you got %s %% of the way." },
  "aterkoppling.volt.klar": { sv: "Snyggt! %s helt varv på volten (radie %s m), i snitt %s m från linjen, på %s s.", en: "Nice! %s full circle(s) on the circle (radius %s m), on average %s m from the line, in %s s." },
  "aterkoppling.volt.nasta": { sv: "Nästa gång: rid samma volt åt andra hållet.", en: "Next time: ride the same circle the other way." },
  "aterkoppling.volt.igen": { sv: "Börja vid linjen och håll samma avstånd till mitten hela varvet.", en: "Start at the line and keep the same distance to the middle all the way round." },
  "aterkoppling.halt.klar": { sv: "Bra! Du skrittade %s m och stod stilla %s s vid X.", en: "Good! You walked %s m and stood still for %s s at X." },
  "aterkoppling.halt.nasta": { sv: "Nästa gång: bromsa lite tidigare så att hon stannar mitt i ringen.", en: "Next time: ask a little earlier so she stops in the middle of the ring." },
  "aterkoppling.halt.igen": { sv: "Stå still först, skritta sedan fram och be om halt inne i ringen vid X.", en: "Stand still first, then walk on and ask for halt inside the ring at X." },
  "aterkoppling.overgang.klar": { sv: "Fint! Trav vid första ringen, %s m trav och %s m lugn skritt efter andra ringen.", en: "Nice! Trot at the first ring, %s m of trot and %s m of calm walk after the second ring." },
  "aterkoppling.overgang.nasta": { sv: "Nästa gång: sikta på att byta gångart mitt i ringarna.", en: "Next time: aim to change gait in the middle of the rings." },
  "aterkoppling.overgang.igen": { sv: "Skritta en bit, trava vid första ringen och skritta vid den andra.", en: "Walk a little, trot at the first ring and walk at the second." },
  "aterkoppling.serpentin.klar": { sv: "Snyggt! Alla tre bågarna, %s m, och %s byten över mittlinjen.", en: "Nice! All three loops, %s m, and %s changes across the centre line." },
  "aterkoppling.serpentin.nasta": { sv: "Nästa gång: rid serpentinen i trav när skritten känns säker.", en: "Next time: ride the serpentine in trot when the walk feels safe." },
  "aterkoppling.serpentin.igen": { sv: "Börja i startringen och följ strecken i lugn skritt.", en: "Start in the start ring and follow the dashes in a calm walk." },
  "aterkoppling.tempo.klar": { sv: "Bra! %s m på %s s i jämn skritt, i snitt %s m/s och %s %% spridning i farten.", en: "Good! %s m in %s s of steady walk, on average %s m/s with %s %% spread in speed." },
  "aterkoppling.tempo.nasta": { sv: "Nästa gång: håll samma jämna fart en längre sträcka.", en: "Next time: keep the same steady speed for a longer stretch." },
  "aterkoppling.tempo.igen": { sv: "Skritta framåt i lugn fart utan att öka eller bromsa.", en: "Walk forward at a calm speed without speeding up or slowing down." },
  "aterkoppling.vag_mitt.klar": { sv: "Snyggt! Du red %s m av mittlinjens %s m.", en: "Nice! You rode %s m of the centre line's %s m." },
  "aterkoppling.vag_mitt.nasta": { sv: "Nästa gång: prova diagonalen.", en: "Next time: try the diagonal." },
  "aterkoppling.vag_mitt.igen": { sv: "Rid in i startringen och håll dig på linjen mot slutringen.", en: "Ride into the start ring and stay on the line towards the end ring." },
  "aterkoppling.vag_diag.klar": { sv: "Snyggt! Du red %s m av diagonalens %s m.", en: "Nice! You rode %s m of the diagonal's %s m." },
  "aterkoppling.vag_diag.nasta": { sv: "Nästa gång: prova mittlinjen i trav.", en: "Next time: try the centre line in trot." },
  "aterkoppling.vag_diag.igen": { sv: "Rid in i startringen och följ diagonalen över till andra sidan.", en: "Ride into the start ring and follow the diagonal across to the other side." },
  "aterkoppling.halvvolt.klar": { sv: "Fint! Spår, halvvolt och tillbaka till spåret – %s m ridet och %s skarvar.", en: "Nice! Track, half-circle and back to the track – %s m ridden and %s joins." },
  "aterkoppling.halvvolt.skuld": { sv: "(%s m som hon flyttade sig under en halt räknades inte.)", en: "(%s m she moved during a halt did not count.)" },
  "aterkoppling.halvvolt.nasta": { sv: "Nästa gång: rid halvvolten i trav.", en: "Next time: ride the half-circle in trot." },
  "aterkoppling.halvvolt.igen": { sv: "Börja i startringen på spåret och följ bågen in mot mitten.", en: "Start in the start ring on the track and follow the curve towards the middle." },
  "aterkoppling.galopp.klar": { sv: "Bra! Galopp vid K efter %s m trav, sedan %s m galopp. Galoppsidan bedömdes inte.", en: "Good! Canter at K after %s m of trot, then %s m of canter. The lead was not judged." },
  "aterkoppling.galopp.nasta": { sv: "Nästa gång: fatta galopp från samma lugna trav, mitt i ringen.", en: "Next time: pick up canter from the same calm trot, in the middle of the ring." },
  "aterkoppling.galopp.igen": { sv: "Trava en bit först och be om galopp inne i ringen K.", en: "Trot for a while first and ask for canter inside the ring K." },
  "aterkoppling.markbom.klar": { sv: "Snyggt! %s m rakt fram mot bommen, över den och %s m efteråt. Avståndet mellan hovarna och bommen mäts inte.", en: "Nice! %s m straight towards the pole, over it and %s m after. The distance between the hooves and the pole is not measured." },
  "aterkoppling.markbom.nasta": { sv: "Nästa gång: sikta mitt emellan märkena hela vägen.", en: "Next time: aim between the marks all the way." },
  "aterkoppling.markbom.igen": { sv: "Börja längre bak och skritta rakt mot bommen.", en: "Start further back and walk straight towards the pole." },
  "aterkoppling.leda.klar": { sv: "Snyggt ledd! %s m på %s s, hela vägen in på ridbanan.", en: "Nicely led! %s m in %s s, all the way onto the arena track." },
  "aterkoppling.leda.nasta": { sv: "Nästa steg: gör i ordning henne och sitt upp.", en: "Next step: get her ready and mount." },
  "aterkoppling.leda.igen": { sv: "Ta din häst utanför ridbanan och led henne lugnt hela vägen in.", en: "Take your horse outside the arena track and lead her calmly all the way in." },
  "aterkoppling.leda.annan": { sv: "Den övningen gjordes med en annan häst eller före ett byte av karaktär, så jag visar inte de siffrorna här. Led igen med den häst du har nu.", en: "That exercise was done with another horse or before a character change, so I will not show its numbers here. Lead again with the horse you have now." },
  "installning.knapp": { sv: "Text", en: "Text" },
  "installning.tips": { sv: "Välj hur mycket Ugneta skriver", en: "Choose how much Ugneta writes" },
  "installning.rubrik_kommentarer": { sv: "Kommentarer under ritten", en: "Comments while riding" },
  "installning.kommentarer.normal": { sv: "Normalt", en: "Normal" },
  "installning.kommentarer.farre": { sv: "Färre", en: "Fewer" },
  "installning.kommentarer.inga": { sv: "Inga", en: "None" },
  "installning.rubrik_detalj": { sv: "Text efter övningen", en: "Text after the exercise" },
  "installning.detalj.detaljerad": { sv: "Detaljerad", en: "Detailed" },
  "installning.detalj.kort": { sv: "Kort", en: "Concise" },
  "installning.klar": { sv: "Klar", en: "Done" },
  "aterkoppling.timeout_kort": { sv: "Tiden tog slut.", en: "Time ran out." },
  "aterkoppling.volt.kort": { sv: "Snyggt – volten är klar!", en: "Nice – the circle is done!" },
  "aterkoppling.halt.kort": { sv: "Bra – halt vid X!", en: "Good – halt at X!" },
  "aterkoppling.overgang.kort": { sv: "Fint – trav vid första ringen och skritt vid den andra!", en: "Nice – trot at the first ring and walk at the second!" },
  "aterkoppling.serpentin.kort": { sv: "Snyggt – alla tre bågarna!", en: "Nice – all three loops!" },
  "aterkoppling.tempo.kort": { sv: "Bra – jämn skritt hela sträckan!", en: "Good – a steady walk all the way!" },
  "aterkoppling.vag_mitt.kort": { sv: "Snyggt – mittlinjen är riden!", en: "Nice – the centre line is ridden!" },
  "aterkoppling.vag_diag.kort": { sv: "Snyggt – diagonalen är riden!", en: "Nice – the diagonal is ridden!" },
  "aterkoppling.halvvolt.kort": { sv: "Fint – spår, halvvolt och tillbaka till spåret!", en: "Nice – track, half-circle and back to the track!" },
  "aterkoppling.galopp.kort": { sv: "Bra – galopp vid K! Galoppsidan bedömdes inte.", en: "Good – canter at K! The lead was not judged." },
  "aterkoppling.markbom.kort": { sv: "Snyggt – över bommen i skritt! Avståndet mellan hovarna och bommen mäts inte.", en: "Nice – over the pole in walk! The distance between the hooves and the pole is not measured." },
  "aterkoppling.leda.kort": { sv: "Snyggt ledd – hela vägen in på ridbanan!", en: "Nicely led – all the way onto the arena track!" },
  "lektionsminne.markering.sparad": { sv: " · klarad", en: " · done" },
  "lektionsminne.markering.vantar": { sv: " · klarad nu", en: " · done now" },
  "lektionsminne.forslag": { sv: "Förslag: %s", en: "Suggested: %s" },
  "lektionsminne.igen": { sv: "Öva igen: %s", en: "Practise again: %s" },
  "lektionsminne.okand": { sv: "Jag kan inte läsa din lektionshistorik just nu – alla övningar går att välja.", en: "I can't read your lesson history right now – every exercise is available." },
  "lektionsminne.vantar_info": { sv: "Det du klarat nu är inte sparat än.", en: "What you just completed isn't saved yet." },
  "skotselminne.rubrik": { sv: "Det du gjort själv:", en: "What you have done yourself:" },
  "skotselminne.halsa": { sv: "Hälsa lugnt", en: "Greet her calmly" },
  "skotselminne.visitera": { sv: "Visitera", en: "Check her over" },
  "skotselminne.rykta": { sv: "Rykta", en: "Groom" },
  "skotselminne.hovar": { sv: "Kratsa alla fyra hovar", en: "Pick out all four hooves" },
  "skotselminne.sparad": { sv: "gjort", en: "done" },
  "skotselminne.vantar": { sv: "gjort nu – inte sparat än", en: "done now – not saved yet" },
  "skotselminne.ej_klarad": { sv: "inte än", en: "not yet" },
  "skotselminne.okand": { sv: "Jag kan inte läsa din skötselhistorik just nu.", en: "I can't read your care history right now." },
  "ledminne.markering.sparad": { sv: " · klarad", en: " · done" },
  "ledminne.markering.vantar": { sv: " · klarad nu", en: " · done now" },
  "ledminne.sparad": { sv: "Du har lett henne hela vägen förut.", en: "You have led her all the way before." },
  "ledminne.vantar": { sv: "Du har lett henne hela vägen förut (inte sparat än).", en: "You have led her all the way before (not saved yet)." },
  "ledminne.okand": { sv: "Jag kan inte läsa din ledningshistorik just nu.", en: "I can't read your leading history right now." },
  "tempocoach.too_slow": { sv: "Håll framåt (W eller spaken) lite mer – det ökar farten inom skritten.", en: "Hold forward (W or the stick) a little more – it speeds her up within the walk." },
  "tempocoach.too_fast": { sv: "Släpp lite på framåt (W eller spaken) – då går hon i lugnare skritt.", en: "Ease off forward (W or the stick) – she then walks at a calmer pace." },
  "tempocoach.steadier": { sv: "Håll framåt (W eller spaken) jämnt, utan ryck, så farten håller sig jämn.", en: "Keep forward (W or the stick) even, without jerks, so the speed stays even." },
  "tempocoach.jamnare": { sv: "Jämnare än förra försöket: spridningen var %s %%, nu %s %%.", en: "More even than your previous attempt: the spread was %s %%, now %s %%." },
  "tempocoach.forra": { sv: "Förra försöket: %s %% spridning, nu %s %%.", en: "Previous attempt: %s %% spread, now %s %%." },
  "tempocoach.jamnare_kort": { sv: "Jämnare än förra gången.", en: "More even than last time." },
  "aterkoppling.volt.narmare": { sv: "Närmare linjen än förra volten: i snitt %s m, nu %s m.", en: "Closer to the line than your previous circle: on average %s m, now %s m." },
  "aterkoppling.volt.forra": { sv: "Förra volten: i snitt %s m från linjen, nu %s m.", en: "Previous circle: on average %s m from the line, now %s m." },
  "aterkoppling.volt.narmare_kort": { sv: "Närmare linjen än förra gången.", en: "Closer to the line than last time." },
  "aterkoppling.halt.narmare": { sv: "Närmare X än förra haltet: %s m från X, nu %s m.", en: "Closer to X than your previous halt: %s m from X, now %s m." },
  "aterkoppling.halt.forra": { sv: "Förra haltet: %s m från X, nu %s m.", en: "Previous halt: %s m from X, now %s m." },
  "aterkoppling.halt.narmare_kort": { sv: "Närmare X än förra gången.", en: "Closer to X than last time." },
  "lektionsval.bojda": { sv: "Böjda vägar", en: "Curved paths" },
  "hornlektion.choose": { sv: "Genom hörnet", en: "Through the corner" },
  "hornlektion.start": { sv: "Starta hörnet", en: "Start the corner" },
  "hornlektion.finish": { sv: "Avsluta hörnet", en: "Finish the corner" },
  "hornlektion.intro": { sv: "Rid på spåret mot C, följ bågen genom hörnet och rid ut längs kortsidan. Följ de gröna strecken.", en: "Ride on the track towards C, follow the curve through the corner and ride out along the short side. Follow the green dashes." },
  "hornlektion.to_start": { sv: "Rid in i startringen på spåret.", en: "Ride into the start ring on the track." },
  "hornlektion.ride_in": { sv: "Fint! Följ spåret fram mot hörnet.", en: "Nice! Follow the track towards the corner." },
  "hornlektion.bend": { sv: "Nu hörnet – följ bågen.", en: "Now the corner – follow the curve." },
  "hornlektion.ride_out": { sv: "Bra! Rid ut längs kortsidan till slutringen.", en: "Good! Ride out along the short side to the end ring." },
  "hornlektion.off_route": { sv: "Ni kom utanför strecken. Rid till startringen och börja om.", en: "You left the dashes. Ride to the start ring and begin again." },
  "hornlektion.reverse": { sv: "Vägen rids åt pilarnas håll. Rid till startringen och börja om.", en: "The route goes the way of the arrows. Ride to the start ring and begin again." },
  "hornlektion.walk_or_trot": { sv: "Rid hörnet i skritt eller trav. Rid till startringen och börja om.", en: "Ride the corner in walk or trot. Ride to the start ring and begin again." },
  "hornlektion.unknown": { sv: "Jag tappade en bit av ritten. Rid till startringen så börjar vi om.", en: "I missed part of the ride. Ride to the start ring and we begin again." },
  "hornlektion.complete": { sv: "Hörnet klart! Du följde bågen hela vägen genom hörnet.", en: "Corner completed! You followed the curve all the way through the corner." },
  "hornlektion.timeout": { sv: "Vi hann inte genom hela hörnet. Ta en paus eller prova igen.", en: "We did not get through the whole corner. Take a break or try again." },
  "hornlektion.closed": { sv: "Hörnet är avslutat.", en: "The corner has ended." },
  "hornlektion.place": { sv: "Rid in på dressyrbanan innan du startar.", en: "Enter the dressage arena before you start." },
  "clearround.choose": { sv: "Clear round (träning)", en: "Clear round (training)" },
  "clearround.start": { sv: "Starta ritten", en: "Start the round" },
  "clearround.finish": { sv: "Avsluta clear round", en: "Finish clear round" },
  "clearround.retry": { sv: "Omstart", en: "Restart" },
  "clearround.intro": { sv: "Träningsbana i ridhuset: blått, rött, blått, rött. Förenklad bedömning – rivningar bedöms inte ännu. Anmäl dig för att börja.", en: "Training course in the indoor arena: blue, red, blue, red. Simplified judging – knockdowns are not judged yet. Enter to begin." },
  "clearround.to_start": { sv: "Startsignal! Rid över startlinjen framför det blå hindret inom 45 sekunder.", en: "Start signal! Ride over the start line in front of the blue fence within 45 seconds." },
  "clearround.hopp": { sv: "Hinder %s: %s, mot %s.", en: "Fence %s: %s, towards %s." },
  "clearround.farg_bla": { sv: "blått", en: "blue" },
  "clearround.farg_rod": { sv: "rött", en: "red" },
  "clearround.to_finish": { sv: "Bra! Rid över mållinjen efter det röda hindret.", en: "Good! Ride over the finish line after the red fence." },
  "clearround.closed": { sv: "Clear round-ritten är avslutad.", en: "The clear round has ended." },
  "clearround.place": { sv: "Rid in i ridhuset innan du startar.", en: "Ride into the indoor arena before you start." },
  "clearround.course_missing": { sv: "Banans hinder står inte på sin plats just nu.", en: "The course fences are not in place right now." },
  "clearround.anmal": { sv: "Anmäl dig", en: "Enter" },
  "clearround.ga_banan": { sv: "Gå banan", en: "Walk the course" },
  "clearround.startlista": { sv: "Anmäld: Clear round (UBRF-träning), %s m. Startlista: startnummer %s · %s anmäld.", en: "Entered: Clear round (UBRF training), %s m. Start list: start number %s · %s entered." },
  "clearround.banskiss": { sv: "Banskiss (förenkling – i verkligheten går man banan till fots): %s. Startlinjen före hinder 1, mållinjen efter hinder %s.", en: "Course plan (simplified – in reality you walk the course on foot): %s. Start line before fence 1, finish line after fence %s." },
  "clearround.banskiss_hinder": { sv: "%s %s mot %s", en: "%s %s towards %s" },
  "clearround.klader_val": { sv: "Kläder: %s", en: "Clothes: %s" },
  "clearround.klader_egna": { sv: "Egna kläder", en: "Own clothes" },
  "clearround.klader_laddar": { sv: "Tävlingskläderna laddas …", en: "Loading the competition clothes …" },
  "clearround.klader_pa": { sv: "Tävlingskläder: %s.", en: "Competition clothes: %s." },
  "clearround.klader_misslyckades": { sv: "Tävlingskläderna kunde inte laddas – du rider i dina egna kläder.", en: "The competition clothes could not be loaded – you ride in your own clothes." },
  "clearround.forra_avbruten": { sv: "Förra clear round-ritten avbröts mitt i banan – den räknas inte som genomförd.", en: "Your last clear round was interrupted mid-course – it does not count as completed." },
  "clearround.forra_avbruten_avsittning": { sv: "Förra clear round-ritten avbröts när ni satt av mitt i banan – den räknas inte som genomförd.", en: "Your last clear round was interrupted when you dismounted mid-course – it does not count as completed." },
  "aterkoppling.clearround.avbruten": { sv: "Ritten avbröts mitt i banan och räknas inte som genomförd.", en: "The round was interrupted mid-course and does not count as completed." },
  "halsning.clearround": { sv: "Dags för clear round: rid över startlinjen och ta hindren i ordning.", en: "Time for clear round: ride over the start line and take the fences in order." },
  "aterkoppling.clearround.inga_fel": { sv: "Inga observerade fel, tid %s s.", en: "No observed faults, time %s s." },
  "aterkoppling.clearround.fel": { sv: "%s olydnad(er), %s fel, tid %s s.", en: "%s disobedience(s), %s faults, time %s s." },
  "aterkoppling.clearround.fel_okand": { sv: "%s olydnader – felpoängen kan inte fastställas ännu. Tid %s s.", en: "%s disobediences – the faults cannot be established yet. Time %s s." },
  "aterkoppling.clearround.utesluten_fel_vag": { sv: "Utesluten: fel väg.", en: "Eliminated: wrong course." },
  "aterkoppling.clearround.utesluten_tid": { sv: "Utesluten: tillåten tid (180 s) överskriden.", en: "Eliminated: the allowed time (180 s) was exceeded." },
  "aterkoppling.clearround.utesluten_olydnader": { sv: "Utesluten: tredje olydnaden.", en: "Eliminated: third disobedience." },
  "aterkoppling.clearround.utesluten_okand": { sv: "Två olydnader – om ritten är utesluten går inte att fastställa ännu.", en: "Two disobediences – whether the round is eliminated cannot be established yet." },
  "aterkoppling.clearround.ej_startad": { sv: "Ni kom inte över startlinjen inom 45 sekunder efter startsignalen.", en: "You did not cross the start line within 45 seconds of the start signal." },
  "aterkoppling.clearround.ej_bedomd": { sv: "Ritten kunde inte bedömas – jag tappade en bit av den.", en: "The round could not be judged – I missed part of it." },
  "aterkoppling.clearround.omstart": { sv: "Du får en omstart direkt.", en: "You may restart straight away." },
  "aterkoppling.clearround.forenklad": { sv: "Förenklad bedömning: rivningar bedöms inte ännu – clear round-rosetten delas ut när de kan bedömas. Träningsbana, inte en standardklass.", en: "Simplified judging: knockdowns are not judged yet – the clear round rosette is given once they can be. Training course, not a standard class." },
  "aterkoppling.clearround.nasta": { sv: "Nästa gång: rid banan igen – blått, rött, blått, rött.", en: "Next time: ride the course again – blue, red, blue, red." },
  "aterkoppling.clearround.eftervard": { sv: "När ni är klara: sitt av – eftervården väntar: %s.", en: "When you are done: dismount – the aftercare is waiting: %s." },
  "aterkoppling.clearround.kort": { sv: "Ritten är bedömd (förenklat).", en: "The round is judged (simplified)." },
  "aterkoppling.clearround.igen": { sv: "Rid över startlinjen och ta hindren i ordning.", en: "Ride over the start line and take the fences in order." },
  "hornlektion.mindre_stod": { sv: "Rid med bara bågen och ringarna", en: "Ride with only the curve and rings" },
  "aterkoppling.hornet.klar": { sv: "Snyggt! %s m av vägen (%s m), genom hörnet i en följd.", en: "Nice! %s m of the route (%s m), through the corner in one go." },
  "aterkoppling.hornet.kort": { sv: "Snyggt – genom hela hörnet!", en: "Nice – all the way through the corner!" },
  "aterkoppling.hornet.nasta": { sv: "Nästa gång: rid samma hörn i trav.", en: "Next time: ride the same corner in trot." },
  "aterkoppling.hornet.igen": { sv: "Börja i startringen och följ strecken genom bågen.", en: "Start in the start ring and follow the dashes through the curve." },
  "halsning.hornet": { sv: "Nu rider vi genom hörnet: följ spåret in och bågen runt hörnet.", en: "Now through the corner: follow the track in and the curve around the corner." },
  "halsning.volt": { sv: "Nu rider vi volten: följ linjen runt mitten ett helt varv.", en: "Now for the circle: follow the line around the middle for one full circle." },
  "halsning.halt": { sv: "Nu övar vi halt vid X: stå still, skritta fram och stanna inne i ringen.", en: "Now for the halt at X: stand still, walk on and stop inside the ring." },
  "halsning.overgang": { sv: "Nu övar vi övergångar: trava vid första ringen och skritta vid den andra.", en: "Now for transitions: trot at the first ring and walk at the second." },
  "halsning.serpentin": { sv: "Nu rider vi serpentinen: följ strecken genom alla tre bågarna.", en: "Now for the serpentine: follow the dashes through all three loops." },
  "halsning.tempo": { sv: "Nu övar vi jämn skritt: håll samma lugna fart hela sträckan.", en: "Now for a steady walk: keep the same calm speed all the way." },
  "halsning.vag_mitt": { sv: "Nu rider vi mittlinjen: håll dig på linjen från startringen till slutringen.", en: "Now for the centre line: stay on the line from the start ring to the end ring." },
  "halsning.vag_diag": { sv: "Nu rider vi diagonalen: följ linjen över till andra sidan.", en: "Now for the diagonal: follow the line across to the other side." },
  "halsning.halvvolt": { sv: "Nu rider vi halvvolt: följ bågen från spåret och tillbaka till spåret.", en: "Now for the half-circle: follow the curve off the track and back to it." },
  "halsning.galopp": { sv: "Nu övar vi galoppfattning: trava först och be om galopp inne i ringen vid K.", en: "Now for the canter departure: trot first and ask for canter inside the ring at K." },
  "halsning.markbom": { sv: "Nu rider vi över markbommen: skritta rakt mot bommen, mitt emellan märkena.", en: "Now over the ground pole: walk straight towards the pole, between the marks." },
  "lektionsminne.markering.forslag": { sv: " · förslag", en: " · suggested" },
  "lektionsminne.forslag_var": { sv: "Förslag: %s (under %s).", en: "Suggested: %s (under %s)." },
  "lektionsminne.forslag_rad": { sv: "Förslag: %s.", en: "Suggested: %s." },
  "lektionsminne.igen_var": { sv: "Öva igen: %s (under %s).", en: "Practise again: %s (under %s)." },
  "lektionsminne.igen_rad": { sv: "Öva igen: %s.", en: "Practise again: %s." },
  "ugneta.se_ritten": { sv: "Se ritten", en: "Watch the ride" },
  "ugneta.ga_vidare": { sv: "Gå vidare", en: "Move on" },
  "ugneta.precis_sa": { sv: "Precis så", en: "Just like that" },
  "ugneta.jamnare_forsok": { sv: "Jämnare försök. Behåll samma känsla.",
    en: "A steadier attempt. Keep the same feel." },
  "ugneta.nasta_ovning": { sv: "Nästa övning", en: "Next exercise" },
  "ugneta.borja_fri_traning": { sv: "Börja fri träning – rundor på %d s", en: "Start free practice – %d s rounds" },
  "ugneta.runda_slut": { sv: "Runda %d – tiden (%d s) är slut", en: "Round %d – time (%d s) is up" },
  "ugneta.runda_slut_kort": { sv: "Runda %d – tiden är slut", en: "Round %d – time is up" },

  /* ATT LEDA HÄSTEN (#162 blockerare 2). Varje nej har en egen nyckel:
     ett samlat "gick inte" gör de negativa fallen omöjliga att skilja åt,
     och spelaren får veta VAD som var fel i stället för att gissa. */
  "led.borja": { sv: "Led hästen", en: "Lead the horse" },
  "led.slapp": { sv: "Släpp hästen", en: "Let go" },
  "led.leder": { sv: "Du leder %s", en: "You are leading %s" },
  /* HANDLINGEN BÄR HÄSTENS NAMN (#182 human-QA).
     "Led hästen" och "Rida nu" stod på samma punkt på riggen och målade
     över varandra; spelaren såg bara den ena. Att flytta isär dem är halva
     rättelsen — den andra halvan är att handlingen SÄGER vilken häst den
     gäller, så att den går att skilja från uppsittningen utan att läsa
     objektraden under. Namnet är ett egennamn och översätts aldrig. */
  "led.borja_namn": { sv: "Led %s", en: "Lead %s" },
  "led.slapp_namn": { sv: "Släpp %s", en: "Let go of %s" },
  /* Avslutet ska kvitteras lika tydligt som starten. Utan den här raden
     var enda skillnaden mellan "leder" och "leder inte" att en knapptext
     bytt ord — och det är precis vad human-QA inte kunde se. */
  "led.slutade": { sv: "Du slutade leda %s", en: "You stopped leading %s" },
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
  /* #182 del 2: hasten bars redan av en ryttare. Skilt fran
     `led.rider`, som ar att SPELAREN sitter upp — tva olika fel som
     hade blivit omojliga att skilja at med samma text. */
  "led.rids": { sv: "Hon rids just nu", en: "She is being ridden right now" },
  // Speglingen av `led.rids`: den vagen ar stangd at bada hall. En hast
  // som leds av nagon annan far ingen ryttare, for de tva systemen
  // strids annars om samma nätverksagarskap.
  "hast.leds_nu": { sv: "Hon leds av någon annan just nu",
    en: "Someone else is leading her right now" },
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
  /* ORDNINGEN AV kommer ur EFTERVARD härovan i `skotsel.js`: sadeln av
     innan tränset, annars står hon lös med sadeln kvar. Tränset är alltså
     kvar på henne när sadeln lyfts av, och det är inte påsättningens
     ordning baklänges. */
  "tack.sadeln_av_forst": { sv: "Sadeln av först — tränset håller henne så länge",
    en: "Take the saddle off first — the bridle holds her meanwhile" },
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
  // Delen kom pa hasten men kopian i handerna gick inte att slappa.
  // satPa svarade tidigare true anda, och spelaren stod kvar med
  // sadeln i handen pa en sadlad hast (#264, Tobias playtest).
  "tack.bars_kvar": {
    sv: "Den kom på plats, men du bär fortfarande en — försök igen",
    en: "It went on, but you are still carrying one — try again" },
  "tack.kunde_inte_byggas": { sv: "Utrustningen kom inte på plats — försök igen",
    en: "The tack did not go on — try again" },
  /* UTRUSTNINGEN PÅ BOXFRONTEN. De tre nycklarna lades vid blockerare 5
     direkt i den GENERERADE `roblox/game/UBRFSprak.luau` och aldrig här.
     Nästa export tog bort dem igen, och `integration.spec` föll på
     `Sprak.finns("tack.hamta_forst")` — vilket är precis vad den grinden
     finns för. Källan är den här filen; det generade följer den. */
  /* HUD:ENS EGNA KONTROLLER. Växlingen i interaktionspanelen skrevs
     först som en svensk literal i klientkoden, och den stod kvar på
     svenska i ett engelskt gränssnitt. Samma regel som all annan
     spelartext: nyckel i katalogen, inte en sträng i en modul. */
  /* "Visa alla %d val" ÄR BORTTAGEN (#185). Den var inbjudan till nio
     samtidiga alternativ i iordningställandet, och produktordern river ut
     just det mönstret: spelaren ska normalt se EN uppgift. Kontrollen
     finns kvar, men som ett diskret `?` — frågan, inte erbjudandet. */
  "hud.behover_du_hjalp": { sv: "Behöver du hjälp?", en: "Need help?" },
  "hud.visa_mindre": { sv: "Visa mindre", en: "Show less" },
  /* Kvittensen efter ett moment som gick igenom. Kort med flit: den ska
     hinna läsas innan nästa instruktion tar plats, inte läsas i stället
     för den. */
  "hud.bra": { sv: "Bra", en: "Good" },
  "tack.ta_utrustning": { sv: "Ta sadel och träns", en: "Take the saddle and bridle" },
  /* #235 FAS 1: sadeln hamtas for sig. Tranget far sin egen text i
     FAS 3 — tills dess hanger det kvar utan prompt, avsiktligt. */
  "tack.ta_sadeln": { sv: "Ta sadeln", en: "Take the saddle" },
  "tack.sadel_for": { sv: "%s sadel", en: "%s saddle" },
  /* #235 FAS 3: transet far sin egen hamtning och sin egen pasattning,
     samma state-machine som sadeln. */
  "tack.ta_transet": { sv: "Ta tränset", en: "Take the bridle" },
  "tack.trans_for": { sv: "%s träns", en: "%s bridle" },
  "tack.bar_inget_trans": { sv: "Du bär inget träns — hämta hennes på boxfronten först",
    en: "You are not carrying a bridle — fetch hers from the stall front first" },
  "tack.redan_tagen": { sv: "Någon annan bär den redan",
    en: "Someone else is already carrying it" },
  /* FAIL-CLOSED (#235 review). Servern far aldrig slappa igenom en
     hamtning den inte kunnat MATA. Saknas boxfronten finns ingen plats
     att mata avstandet fran, och da ar svaret nej — inte ja. */
  "tack.ingen_front": { sv: "Utrustningen går inte att nå just nu",
    en: "The equipment cannot be reached right now" },
  "tack.front_slapper_inte": { sv: "Sadeln sitter fast på boxfronten — försök igen",
    en: "The saddle is stuck on the stall front — try again" },
  /* EN SADEL I TAGET (#235 review 2). `satBuren` ar byggd for att BYTA
     ut en buren del mot en annan hasts — men da lag den forsta hastens
     agarpost kvar och hennes front forblev slackt. FAS 1 nekar i
     stallet, innan nagot andras. */
  "tack.bar_redan_annan": { sv: "Du bär redan en annan hästs sadel — lämna tillbaka den först",
    en: "You are already carrying another horse's saddle — put it back first" },
  "tack.rattelse_sadel": { sv: "Du bär %ss sadel – den passar inte %s. Häng tillbaka den på hans eller hennes boxfront och hämta rätt sadel.", en: "You are carrying %s's saddle – it does not fit %s. Hang it back on that horse's box front and fetch the right saddle." },
  "tack.rattelse_trans": { sv: "Du bär %ss träns – det passar inte %s. Häng tillbaka det på hans eller hennes boxfront och hämta rätt träns.", en: "You are carrying %s's bridle – it does not fit %s. Hang it back on that horse's box front and fetch the right bridle." },
  "tack.lamna_sadel": { sv: "Häng tillbaka %ss sadel", en: "Hang back %s's saddle" },
  "tack.lamna_trans": { sv: "Häng tillbaka %ss träns", en: "Hang back %s's bridle" },
  "tack.lamnade_sadel": { sv: "Bra! %ss sadel hänger på sin plats igen. Hämta nu rätt sadel.", en: "Good! %s's saddle is back in its place. Now fetch the right saddle." },
  "tack.lamnade_trans": { sv: "Bra! %ss träns hänger på sin plats igen. Hämta nu rätt träns.", en: "Good! %s's bridle is back in its place. Now fetch the right bridle." },
  "tack.bar_inget": { sv: "Du bär ingen sådan utrustning just nu.", en: "You are not carrying that equipment right now." },
  "tack.bar_inte_den": { sv: "Du bär något annat nu – titta på raden igen.", en: "You are carrying something else now – check the line again." },
  "tack.kan_inte_lamnas": { sv: "Den här utrustningen lade stallet fram åt dig; den hängs inte tillbaka härifrån.", en: "The stable set this equipment out for you; it is not hung back from here." },
  "tack.ga_till_fronten": { sv: "Gå till den hästens boxfront och häng tillbaka den där.", en: "Walk to that horse's box front and hang it back there." },
  "tack.front_upptagen": { sv: "Där hänger redan en – den här kan inte hängas dit.", en: "One already hangs there – this one cannot go there." },
  "tack.front_visar_inte": { sv: "Boxfronten gick inte att använda just nu. Försök igen.", en: "The box front could not be used right now. Try again." },
  "tack.kunde_inte_slappas": { sv: "Den gick inte att hänga tillbaka just nu. Du bär den fortfarande.", en: "It could not be hung back right now. You are still carrying it." },
  "tack.lamna_natverk": { sv: "Jag nådde inte stallet. Försök igen.", en: "I could not reach the stable. Try again." },
  "tack.inaktuell": { sv: "Det där gällde ett tidigare läge. Titta på raden igen.", en: "That was for an earlier moment. Check the line again." },
  "tack.utrustning_for": { sv: "%ss sadel och träns", en: "%s's saddle and bridle" },
  "tack.hamta_forst": { sv: "Sadel och träns hänger på boxfronten — hämta dem först",
    en: "Saddle and bridle hang on the stall front — fetch them first" },

  /* VAD SPELAREN BÄR MELLAN BOXFRONTEN OCH HÄSTEN (#182).

     Hämtningen var enbart en tabellskrivning på servern: ingenting på
     skärmen och ingenting i världen sa att spelaren gick omkring med en
     sadel. Raden är avsiktligt en STATUS och inte en kvittens — den ska
     stå kvar så länge utrustningen bärs, inte blinka förbi.

     Hästens namn är ett egennamn och översätts aldrig. Genitivet skrivs
     som `%ss` av samma skäl som i `tack.utrustning_for` ovan. */
  "tack.bar_par": { sv: "Du bär %ss sadel och träns",
    en: "You are carrying %s's saddle and bridle" },
  "tack.bar_sadel": { sv: "Du bär %ss sadel", en: "You are carrying %s's saddle" },
  "tack.bar_trans": { sv: "Du bär %ss träns", en: "You are carrying %s's bridle" },

  /* KVITTENSEN NÄR EN DEL FAKTISKT KOM PÅ HÄSTEN (#182).

     "Bra" sa varken vad som hände eller med vilken häst. Delens namn är
     en egen nyckel därför att SERVERN vet vilket utrustningssteg som ger
     vilken del — klienten ska inte räkna ut den kopplingen en gång till
     — medan språket är klientens. Servern skickar alltså nycklarna, inte
     färdig text. */
  "tack.del_underlagg": { sv: "Underlägget", en: "The numnah" },
  "tack.del_sadel": { sv: "Sadeln", en: "The saddle" },
  "tack.del_trans": { sv: "Tränset", en: "The bridle" },
  "tack.pa_plats": { sv: "%s sitter på %s", en: "%s is on %s" },
  /* #235 FAS 2. Nejen som bara FAS 2 kan ge: hon bar ingenting att
     sadla med, eller hon bar en sadel som hor till en annan hast an
     den hon star vid. Den andra ar avsiktligt mojlig att gora — att
     kunna ta fel sadel ar hela den pedagogiska poangen, och nejet ska
     da saga vad som ar fel, inte bara neka. */
  /* #235 FAS 2 hittade halet: nar sadeln flyttat fran fronten till
     hastens rygg star kroken tom — men hamtningen slapptes anda
     igenom och praglade en ANDRA sadel ur tomma luften. */
  /* #235 FAS 2 review: HASTENS EGET TILLSTAND. Att klienten slacker
     knappen ar presentation; servern maste aga regeln. En hast som
     leds star inte still att sadla, och en uppsutten har redan en
     ryttare pa ryggen. */
  "tack.leds_nu": { sv: "Hon leds just nu — släpp henne först",
    en: "She is being led right now — let her go first" },
  "tack.rids_nu": { sv: "Hon är uppsutten — sitt av först",
    en: "She is being ridden — dismount first" },
  "tack.inte_pa_fronten": { sv: "Den hänger inte på boxfronten längre",
    en: "It is no longer hanging on the stall front" },
  "tack.bar_ingen_sadel": { sv: "Du bär ingen sadel — hämta hennes på boxfronten först",
    en: "You are not carrying a saddle — fetch hers from the stall front first" },

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
  // Teaching Loop: efterrittens summering. Tva eller tre punkter, sedan
  // tyst — kanon sager uttryckligen att det inte far bli en dashboard.
  "ugneta.efterritt.rubrik": { sv: "Efter ritten", en: "After the ride" },
  "ugneta.efterritt.stang": { sv: "Klar", en: "Done" },
  // Hastens dag, inte ryttarens fel. Webbens `lararSteg` sager
  // `Det dar kom fran ${n}.` nar hasten ar skygg eller i dalig dagsform;
  // ryttaren ska inte fa en rattelse for nagot hon inte gjorde.
  "ugneta.hastens_dag": { sv: "Det där kom från %s.", en: "That came from %s." },
  "ugneta.hasten": { sv: "hästen", en: "the horse" },

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

  /* ── Nycklar som låg ENBART i den genererade UBRFSprak.luau (#178) ──
     De lades till på Roblox-sidan direkt i exportens utdata, aldrig här i
     källan. Exporten skriver om filen ur den här katalogen, så nästa
     generering hade RADERAT dem — och med dem pekknapparna som
     IPAD_RIDING_ACCEPTANCE_PASS behöver. Texterna är överförda ordagrant
     från den accepterade Roblox-filen; ingenting är nyskrivet här. */
  /* RIDE FIRST: knappen som låter stallet göra i ordning henne. */
  "interaktion.rida_nu": { sv: "Rida nu", en: "Ride now" },
  /* #235 FAS 2: SADEL `HELD -> EQUIPPED`. Hastens namn star i sjalva
     handlingen, samma beslut som `led.borja_namn` i #182 — fyra knappar
     pa samma hast far aldrig kalla henne olika saker. */
  "interaktion.sadla_namn": { sv: "Sadla %s", en: "Saddle %s" },
  /* #235 FAS 3. Kanon lagger transet SIST, sa knappen finns forst nar
     hon ar sadlad — och da ar sadelknappen borta. De tva delar darfor
     plats och tangent utan att nagonsin kunna vara uppe samtidigt. */
  "interaktion.transa_namn": { sv: "Tränsa %s", en: "Bridle %s" },
  "hjalp.blick": { sv: "Se dig omkring", en: "Look around" },
  /* DRIV och BROMS ersatter de fem namngivna gangartsknapparna
     (arkitekturbeslut 2026-09-17). Etiketterna ar VERSALER darfor att de
     star pa en ContextActionService-knapp som ar 86 px i kvadrat: ett ord
     i taget, last pa en armlangds avstand, mitt i en volt.

     "DRIV" ar ridtermen for framatdrivande hjalp och "BROMS" ar det ord en
     nyborjare faktiskt tanker. Att blanda ar med flit: knappen ska laras
     in av den som aldrig ridit och kannas ratt for den som gjort det. */
  "touch.driv": { sv: "DRIV", en: "GO" },
  "touch.broms": { sv: "BROMS", en: "SLOW" },
  "touch.blickytan": { sv: "Dra på högra halvan", en: "Drag on the right half" },
  "stall.din_hast": { sv: "DIN HÄST", en: "YOUR HORSE" },
  "stall.idag_rider_du": { sv: "Idag rider du %s.", en: "Today you ride %s." },
  "led.stangd_boxdorr": { sv: "Boxdörren är stängd — öppna hennes boxdörr först, så kan hon gå ut", en: "Her stall door is shut — open her stall door first so she can walk out" },

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
