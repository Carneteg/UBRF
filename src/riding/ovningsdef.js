/* ÖVNINGSDEFINITIONEN — vad en övning ÄR, som data.

   G02-D (#137) kräver "a shared, versioned exercise definition" med stabilt
   ID, geometri och koordinatram, målgångart, bedömda metrik-ID, giltighets-
   krav och referens. Före den här filen fanns de uppgifterna utspridda:
   dimensionerna i UGNETA_OVNING_DIM, geometrin som två konstanter i
   UGNETA_KVALITET, rubriken i UGNETA_OVNINGAR — och ingenting alls om
   version, giltighet eller referens.

   Filen är MOTOROBEROENDE med flit. Den känner varken till canvas, DOM,
   Roblox eller någon renderare, och den räknar inte ut ett enda betyg.
   Bedömningen bor kvar i ugnetaKvalitet(); den här filen säger bara VILKA
   mått som gäller för vilken övning och NÄR ett mätvärde får räknas.

   Den lägger heller inte till en andra sanning: `UGNETA_OVNING_DIM` i
   src/larare.js härleds numera HÄRIFRÅN i stället för att stå kvar som en
   parallell tabell, och `tools/exportera-ridkanon.mjs` skickar samma
   definition vidare till Roblox som RidKanon redan gör med gångartsbanden.

   VAD DEN INTE GÖR: den ändrar inga vikter och inga trösklar. Övningarnas
   dimensioner står här med samma inbördes betydelse som koden redan hade —
   alla lika mycket värda, eftersom ugnetaKvalitet rankar dem i stället för
   att väga ihop dem till en siffra. Att införa olika vikt är ett
   produktbeslut om bedömningen, inte en biverkning av att skriva ned den. */

/* Schemaversionen. Höjs när en definitions BETYDELSE ändras — nya eller
   borttagna metrik-ID, ändrade giltighetskrav, ändrad koordinatram. En
   inspelning bär den här siffran, så en gammal inspelning inte tyst kan
   bedömas mot nya regler. */
const OVNING_SCHEMA = 1;

/* GILTIGHETSKRAV — när räknas en dimension som uppmätt?

   Talen är inte nya. De är Roblox-sidans, satta i #128 efter senior review
   ("okänt är varken noll eller full pott"), och står i
   HorseCore/Lektion.MIN_MATNINGAR respektive MIN_DIM_SEK. Att webben inte
   hade dem var en osymmetri mellan plattformarna, inte ett medvetet val.

   Sekunder och inte bildrutor: 120 fps ska inte ge fyra gånger så mycket
   underlag som 30 fps för samma ritt. */
const OVNING_GILTIG = {
  MIN_MATNINGAR: 2,     // minst så många sampel i dimensionen
  MIN_SEK: 1.0,         // OCH minst så många uppmätta sekunder
};

/* KOORDINATRAM. Refereras vid NAMN, inte med kopierade siffror — ramen
   ägs av src/site.js (`R.dressyr`, 20 × 60 förankrad i A på södra sargen)
   och av miljöspåret. En övningsdefinition som bar egna koordinater vore
   precis den andra miljösanning som exportgrindarna finns för att stoppa. */
const OVNING_RAM = {
  DRESSYR: "ridhus.dressyr",   // src/site.js → R.dressyr
};

/* Övningarna. Två stycken, med flit: G02-D:s första leverans ska göra de
   BEFINTLIGA 20 m-volten och en övergång genuint lärbara, inte bygga en
   katalog. Båda ID:na fanns redan i UGNETA_OVNINGAR och används av
   ugnetaOvningFor(); de byter inte namn. */
const OVNINGAR_DEF = {
  storvolt: {
    id: "storvolt",
    version: 1,
    rubrik: "20 m volt",
    ram: OVNING_RAM.DRESSYR,
    /* Bedömda mått, i den ordning ugnetaForstaForsok rankar dem. Ingen
       vikt: dimensionerna jämförs mot varandra, de summeras inte. */
    matt: ["linje", "rytm", "balans"],
    /* Geometrin som FAKTISKT bedöms. Radien läses ur UGNETA_KVALITET vid
       körning (se ovningsGeometri nedan) så att det bara finns ett tal.

       Och det som INTE bedöms, uttryckligen: VAR på banan volten rids.
       Modellen mäter svängradien — alltså formen — inte positionen. Att
       börja kräva en volt på ett visst ställe vore en ny bedömning och ett
       produktbeslut, inte en definition av det som redan finns. */
    bedomer: ["svangradie", "rakriktning"],
    bedomerInte: ["position på banan"],
    gangart: null,          // volten rids i den gångart passet begär
    referens: null,         // sätts när en validerad referens finns
  },
  trav_skritt: {
    id: "trav_skritt",
    version: 1,
    rubrik: "Trav → skritt",
    ram: OVNING_RAM.DRESSYR,
    matt: ["timing", "mjukhet", "respons"],
    /* Övergångens tre tider är telemetrins egna och mäter var sin sak:
       svarstid = från hjälp till att hästen börjar svara, overgangstid =
       hela förloppet, etableringstid = tills den nya gångarten sitter.
       Skillnaden mellan dem är själva poängen med övningen. */
    bedomer: ["svarstid", "overgangstid", "etableringstid", "paradKvalitet"],
    bedomerInte: ["position på banan"],
    gangart: { fran: "trav", till: "skritt" },
    referens: null,
  },
};

/* Slår upp en definition. Returnerar null för okänt ID i stället för att
   hitta på en defaultövning — en okänd övning ska märkas, inte bedömas
   mot något godtyckligt. */
function ovningsDef(id) {
  return (id && OVNINGAR_DEF[id]) || null;
}

/* Övningens mätlista, med samma fallback som larare.js hade före den här
   filen, så att en okänd övning beter sig oförändrat. */
function ovningsMatt(id) {
  const d = ovningsDef(id);
  return d ? d.matt.slice() : ["rytm", "balans", "mjukhet"];
}

/* Geometrin, hämtad ur den enda plats den bor: UGNETA_KVALITET. Läses lat
   eftersom src/larare.js laddas EFTER den här filen — hade vi läst den vid
   definitionstillfället hade vi fått undefined och tyst skrivit in ett hål
   i kanonen. */
function ovningsGeometri(id) {
  const d = ovningsDef(id);
  if (!d) return null;
  const UK = (typeof UGNETA_KVALITET !== "undefined") ? UGNETA_KVALITET : null;
  if (id === "storvolt" && UK) {
    return { radie: UK.VOLT_RADIE, spann: UK.VOLT_SPANN, ram: d.ram };
  }
  return { ram: d.ram };
}

/* ── INSPELNINGENS SCHEMA ────────────────────────────────────────────
   En inspelning måste kunna läsas tillbaka utan att gissa vad den betydde
   när den skrevs. Specen räknar upp vad posten ska bära; det här är den
   listan som kod.

   Höjs schemat blir gamla inspelningar inte tyst omtolkade — de avvisas
   eller migreras uttryckligen (se inspelningLasbar). */
const INSPELNING_SCHEMA = 1;

/* Fälten en inspelningspost bär. Deklarerade som en lista i stället för
   bara i en kommentar, så att ett prov kan falla när ett fält försvinner. */
const INSPELNING_FALT = [
  "schema",        // INSPELNING_SCHEMA vid inspelningstillfället
  "ovning",        // övnings-ID
  "ovningVersion", // definitionens version då
  "hast",          // hästens id
  "profil",        // hästens profil (skolhast/kanslig/tung/arbetsvillig)
  "start",         // starttillstånd: gångart, fart, plats
  "klocka",        // tidpolicy: "sim" = ackumulerad dt, inte väggklocka
  "ram",           // koordinatram
  "sampel",        // [{t, x, y, kurs, gangart, fas, fart, hjalper, skala}]
  "handelser",     // [{t, typ, ...}] — gångartsbyten, paradhjälper, avbrott
];

/* Kan den här inspelningen läsas av den kod som kör nu?

   Tre svar, aldrig ett tyst ja: `ok` när schema och övningsversion stämmer,
   `gammal` när posten är läsbar men äldre än definitionen (jämförelser mot
   den ska märkas), och `nej` med skäl när den inte får tolkas alls. */
function inspelningLasbar(post) {
  if (!post || typeof post !== "object") return { ok: false, lage: "nej", skal: "ingen post" };
  if (post.schema !== INSPELNING_SCHEMA)
    return { ok: false, lage: "nej", skal: `schema ${post.schema} mot ${INSPELNING_SCHEMA}` };
  const d = ovningsDef(post.ovning);
  if (!d) return { ok: false, lage: "nej", skal: `okänd övning ${post.ovning}` };
  if (post.ovningVersion !== d.version)
    return { ok: true, lage: "gammal", skal: `övningsversion ${post.ovningVersion} mot ${d.version}` };
  return { ok: true, lage: "ok", skal: "" };
}

if (typeof window !== "undefined") {
  window.OVNING_SCHEMA = OVNING_SCHEMA;
  window.OVNINGAR_DEF = OVNINGAR_DEF;
}
