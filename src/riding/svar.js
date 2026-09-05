/* ══════════════════════════════════════════════════════════════════
   G02-B — HÄSTENS SVAR (issue #83, punkt 2)

   Punkt 1 gav ryttarens hjälper ett språk. Den här modulen ger hästen
   ett: fördröjning, känslighet, balans, fokus, spänning och energi som
   RIKTIGA storheter i stället för fyra parametrar och två härledningar.

   Före G02-B fanns bara två av dem på riktigt — `kanslighet` som en
   egenskap hos hästen och `spanning` som ett tillstånd. `balans` och
   `fokus` räknades fram i telemetrin ur mjukhet och spänning och var
   märkta HÄRLEDDA just därför att de inte var något modellen kände
   till. Fördröjning och energi fanns inte alls: en cue startade
   förloppet i samma bildruta den gavs, och en häst som gått i galopp i
   tio minuter svarade precis som en nyss framtagen.

   VAD SOM STYR VAD, i en mening var:

     svarstid   hur länge hästen tar på sig innan hon börjar svara.
                Hon svarar ALLTID — hjälpen tappas aldrig bort — men en
                trög, trött eller ofokuserad häst tar längre på sig, och
                en tydlig hjälp får ett snabbare svar än en luddig.
     fokus      hur mycket av henne som är hos ryttaren. Stiger av en
                stadig hand och av en välriden halvhalt — det är vad en
                halvhalt ÄR — och sjunker av spänning och av att vara ute.
     balans     hur väl hon bär sig själv. Sjunker av svängar utan
                yttertygel, av att svänga fort, av övergångar och av
                spänning; stiger på rakt spår i lugn.
     energi     hur mycket hon har kvar. Sjunker av arbete, snabbast i
                galopp, och hämtar sig i halt. En trött häst bjuder
                mindre framåt och svarar långsammare.

   KONTROLL FÖRST. Scope guardrailen i CLAUDE.md är uttrycklig: det här
   ska vara ett bra, lätt, responsivt ridspel. Ingen av storheterna får
   därför göra hästen olydig eller oförutsägbar. De skjuter svaret i
   tid, de tar inte bort det; de förskjuter balansen, de tar inte över
   styrningen. Talen nedan är valda så att en utvilad, fokuserad häst
   ligger på Gate 01:s beteende och avvikelsen växer därifrån.
   ══════════════════════════════════════════════════════════════════ */

const SVAR_KANON = {
  /* ── SVARSTIDEN, i sekunder ────────────────────────────────────
     En summa och inte en produkt, för att varje term ska gå att läsa
     av för sig: "0,14 av tröghet, 0,12 av dålig fokus". Golvet och
     taket håller den spelbar i båda ändar. */
  SVAR_BAS: 0.12,
  SVAR_TROG: 0.14,        // × (1 − känslighet)
  SVAR_FOKUS: 0.12,       // × (1 − fokus)
  SVAR_ENERGI: 0.10,      // × (1 − energi)
  SVAR_KLAR: 0.10,        // × hjälpens tydlighet, DRAR IFRÅN
  SVAR_MIN: 0.06, SVAR_MAX: 0.48,

  /* ── FOKUS ──────────────────────────────────────────────────────
     Målvärdet är en summa av det ryttaren gör och det som stör. */
  /* Termerna summerar med flit till 0,80 och inte till 1,00 för en
     stadig, lugn ridning inomhus. En häst som bara rids jämnt är
     uppmärksam, inte helt samlad hos ryttaren — den sista femtedelen
     kommer av halvhalten nedan, och det är hela poängen med den.

     Låg förut som 0,42 + 0,34 + 0,24 = 1,00, och då satt fokus i taket
     så fort handen var stadig. Paradens lyft fanns men syntes aldrig
     (uppmätt 0,971 → 0,992), och storheten kunde inte skilja två
     ryttare åt. */
  FOKUS_BAS: 0.30,
  FOKUS_MJUK: 0.30,       // × mjukhet — en stadig hand samlar henne
  FOKUS_LUGN: 0.20,       // × (1 − spänning)
  FOKUS_UTE: 0.14,        // dras av utomhus
  /* En välriden halvhalt är en uppmärksamhetssignal, inte bara en
     bromsning. Den lyfter fokus direkt, i proportion till hur väl den
     reds — och det är det som gör paradens kvalitet till något hästen
     GÖR något av, inte bara ett tal i telemetrin. */
  FOKUS_PARAD: 0.22,
  FOKUS_TAU: 2.6,         // sekunder mot målet

  /* ── BALANS ─────────────────────────────────────────────────────
     Ett målvärde som börjar på 1 och får avdrag. Rakt spår i lugn ger
     alltså full balans, vilket är avsikten: balansen ska inte vara en
     skatt man betalar för att rida. */
  BALANS_YTTER: 0.55,     // × böjkrav × (1 − yttertygelstöd)
  BALANS_FART: 0.30,      // × svängens fartkrav
  BALANS_OVERGANG: 0.16,  // under ett gångartsbyte
  BALANS_SPANNING: 0.26,  // × spänning
  /* Hästens utbildning DÄMPAR avdragen, den lägger inte till över 1.
     Skillnaden är inte kosmetisk: som bonus tryckte den både en välriden
     och en illa riden volt upp mot taket, och skillnaden mellan dem
     försvann i klippningen — uppmätt 0,856 mot 0,968 i stället för de
     0,79 mot 0,89 talen nedan ger. En välbalanserad rak ridning ska
     ligga på 1, och allt annat ska mätas därifrån. */
  BALANS_UTB: 0.30,       // × utbildning, DÄMPAR avdraget
  BALANS_TAU_NER: 1.1, BALANS_TAU_UPP: 2.2,   // faller fortare än den byggs

  /* ── ATT FALLA IN ───────────────────────────────────────────────
     Balansens verkan i rörelsen, och den enda i hela G02-B som ändrar
     var hästen faktiskt hamnar. En häst som tappat balansen i en sväng
     faller in på inre skuldran: bågen blir snävare än ryttaren bad om.

     Det är den mest igenkännbara sak en skolhäst gör på en volt, och
     boten är precis den ryttaren fick i punkt 1 — yttertygeln. Därför
     är taket satt så att felet är TYDLIGT men aldrig tar över: 0,30
     betyder att en helt obalanserad volt på fullt utslag kommer in
     ungefär en tredjedel snävare, och en välbalanserad inte alls.

     [HUMAN GATE] Att hästen alls får avvika från det ryttaren bad om är
     en känsloändring och därmed Tobias beslut. Den stängs av genom att
     sätta talet till 0 — ingen annan kod behöver röras. */
  INFALL_MAX: 0.30,

  /* ── ENERGI, per sekund ─────────────────────────────────────────
     Skalan är satt på en riktig lektion och inte på ett testfönster:
     tio minuter sammanhängande trav ska kosta ungefär en tredjedel.
     Skritten går jämnt ut — den är gångarten man vilar i — och halten
     ger tillbaka. */
  ENERGI_TAPP: { halt: 0, skritt: 0.00042, trav: 0.00062, galopp: 0.00125 },
  ENERGI_ATER: { halt: 0.00090, skritt: 0.00042, trav: 0, galopp: 0 },
  ENERGI_SPANN: 0.45,     // spänningen tär: tapp × (1 + 0,45 × spänning)
  /* Hur mycket av framåtbjudningen som sitter i dagsformen. En slut
     häst bjuder mindre men blir inte en annan häst. */
  ENERGI_BJUD: 0.35,
};

/* Svarstiden för EN hjälp. `klarhet` är 0–1: hur tydlig hjälpen var —
   framåtimpulsens marginal över tröskeln, eller paradens kvalitet. */
function svarSvarstid(h, fokus, energi, klarhet) {
  const S = SVAR_KANON, P = svarProfil(h);
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  /* Profilen skalar summan, inte varje term för sig: `svar` säger hur
     snabb hon är, `klar` hur mycket hon bryr sig om att frågan är
     tydlig. Avdraget läggs efter skalningen, annars hade en trög häst
     också blivit den som tjänar mest på en tydlig hjälp — motsatsen
     till vad profilen säger. */
  const t = (S.SVAR_BAS
    + S.SVAR_TROG * (1 - kl(h.kanslighet, 0, 1))
    + S.SVAR_FOKUS * (1 - kl(fokus, 0, 1))
    + S.SVAR_ENERGI * (1 - kl(energi, 0, 1))) * P.svar
    - S.SVAR_KLAR * P.klar * kl(klarhet, 0, 1);
  return kl(t, S.SVAR_MIN, S.SVAR_MAX);
}

/* Fokusens målvärde den här bildrutan. `paradLyft` är 0–1 och läggs på
   när en halvhalt just lästes. */
function svarFokusMal(s, ctx, paradLyft, h) {
  const S = SVAR_KANON, P = svarProfil(h);
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  return kl(S.FOKUS_BAS + S.FOKUS_MJUK * s.mjukhet
    + S.FOKUS_LUGN * (1 - s.spanning)
    - (ctx.utomhus ? S.FOKUS_UTE : 0)
    + S.FOKUS_PARAD * P.fokus * kl(paradLyft || 0, 0, 1), 0, 1);
}

/* Balansens målvärde. `bojkrav` 0–1 av fullt styrutslag, `ytterstod`
   ur hjälpsemantiken, `fartkrav` svängens centripetalkrav normaliserat
   som i modellens `svang`. */
function svarBalansMal(s, h, bojkrav, ytterstod, fartkrav, iOvergang) {
  const S = SVAR_KANON;
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  const avdrag = S.BALANS_YTTER * kl(bojkrav, 0, 1) * (1 - kl(ytterstod, 0, 1))
    + S.BALANS_FART * kl(fartkrav, 0, 1)
    + (iOvergang ? S.BALANS_OVERGANG : 0)
    + S.BALANS_SPANNING * kl(s.spanning, 0, 1);
  const damp = 1 - S.BALANS_UTB * kl(h.utbildning === undefined ? 0.6 : h.utbildning, 0, 1);
  /* Profilens `balans` skalar AVDRAGET, inte balansen: över 1 tappar hon
     lättare, under 1 står hon stadigare. Full balans är fortfarande 1
     för alla — en profil får inte göra en häst permanent obalanserad. */
  return kl(1 - avdrag * damp * svarProfil(h).balans, 0, 1);
}

/* Hur mycket snävare bågen blir än den ryttaren bad om, som en faktor
   på kurvaturen. 0 vid full balans, 0 på rakt spår. Läses av
   kurvaturintegrationen i src/game.js. */
function svarInfall(balans, bojkrav) {
  const S = SVAR_KANON;
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  return S.INFALL_MAX * (1 - kl(balans, 0, 1)) * kl(bojkrav, 0, 1);
}

/* Energins ändring per sekund. Positiv = hämtar sig. */
function svarEnergiTakt(gangart, spanning, h) {
  const S = SVAR_KANON, P = svarProfil(h);
  const tapp = (S.ENERGI_TAPP[gangart] || 0) * (1 + S.ENERGI_SPANN * (spanning || 0)) * P.tapp;
  const ater = (S.ENERGI_ATER[gangart] || 0) * P.ater;
  return ater - tapp;
}

/* ══════════════════════════════════════════════════════════════════
   SKOLHÄSTPROFILERNA (issue #83, punkt 3)

   "Minst tre datadrivna skolhästprofiler — mätbart olika utan separata
   controllers." Det sista ledet är kravet som styr designen: en profil
   får INTE vara en egen kodväg. Den är en uppsättning tal som skalar
   den svarsmodell alla hästar delar, och ingenting annat. Byter man
   profil på en häst ändras hur hon svarar, inte vilken kod som kör.

   Talen är multiplikatorer på SVAR_KANON, och 1,00 rakt igenom är
   `skolhast` — den pålitliga lektionshästen, som därför också är
   modellens utgångsläge. Varje annan profil mäts mot den.

   VARIFRÅN PROFILEN KOMMER. Tilldelningen står i src/spel/hastar.js och
   bygger på ridskolans EGNA beskrivningar av hästarna (snapshoten
   references/data/ubrf-hastar-2026-09-01.json, upstream ubrf.se/hastar).
   "En känsligare individ", "kräver en mjuk balanserad ryttare", "lite åt
   det tyngre hållet" och "arbetsvillig" är källtext, inte gissningar.
   Hästar vars beskrivning inte säger något om ridkänsla får `skolhast`
   och är märkta som just det — inte tilldelade på känsla.

   Ingen profil gör en häst olydig. Se SVAR_MIN/SVAR_MAX: även den
   trögaste ligger inom det spelbara bandet, och kontroll-först-provet i
   tools/ridtest.mjs körs genom inputlagret. ── */

const SKOLHAST_PROFILER = {
  /* Den pålitliga lektionshästen. Utgångsläget — allt är 1,00. */
  skolhast: { namn: "Skolhäst", kort: "pålitlig, går med i alla grupper",
    svar: 1.00, klar: 1.00, balans: 1.00, fokus: 1.00, tapp: 1.00, ater: 1.00 },

  /* Den känsliga. Svarar snabbt på lite, men straffar en luddig hjälp
     hårdare och tappar balansen lättare i en ostödd sväng. Den som
     rider henne rätt får mest tillbaka av alla — och den som inte gör
     det märker det först på henne. */
  kanslig: { namn: "Känslig", kort: "svarar på lite, kräver en mjuk hand",
    svar: 0.72, klar: 1.45, balans: 1.35, fokus: 1.25, tapp: 1.15, ater: 1.00 },

  /* Den tyngre. Tar tid på sig och vill ha en tydlig fråga, men står
     stadigt: hon tappar inte balansen för att ryttaren släpper
     yttertygeln. Nybörjarens hjälp och de vanas prövning. */
  tung: { namn: "Tyngre modell", kort: "tar tid, står stadigt, vill ha tydlighet",
    svar: 1.38, klar: 1.30, balans: 0.70, fokus: 0.85, tapp: 1.25, ater: 0.85 },

  /* Den arbetsvilliga. Bjuder till, orkar länge och hämtar sig fort.
     Hon behöver inte övertalas — men hon behöver inte heller jagas. */
  arbetsvillig: { namn: "Arbetsvillig", kort: "bjuder till och orkar länge",
    svar: 0.86, klar: 0.85, balans: 0.90, fokus: 1.05, tapp: 0.80, ater: 1.20 },
};

/* Hästens profil, med `skolhast` som fallback. Att fallbacken är
   utgångsläget och inte ett fel är avsiktligt: en häst utan tilldelad
   profil ska bete sig som modellen alltid gjort. */
function svarProfil(h) {
  return (h && SKOLHAST_PROFILER[h.profil]) || SKOLHAST_PROFILER.skolhast;
}
