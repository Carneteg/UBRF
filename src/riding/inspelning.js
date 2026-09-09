/* INSPELNINGEN — spelarens faktiska ritt, en gång.

   G02-D (#137): "Record the player's actual ride once and reuse it for
   playback, comparison and assessment. Do not create a separate scoring
   model for replay."

   Därför gör den här filen EN sak: den skriver ned vad som hände. Den
   bedömer ingenting. Betygen kommer från ugnetaKvalitet() som förut, ur
   samma telemetri som matar inspelningen — det finns ingen andra
   bedömningsväg och ska inte finnas.

   MOTOROBEROENDE. Ingen DOM, ingen canvas, ingen Roblox. Den tar emot ett
   tillståndsobjekt och lämnar ifrån sig en post.

   TIDPOLICY: `sim`. Tiden är ACKUMULERAD dt ur ridloopen, inte
   väggklockan. En inspelning gjord på en seg telefon och en gjord på en
   snabb dator ska beskriva samma ritt, och en paus i fliken ska inte
   spela in ett hål på tolv sekunder.

   PRESTANDA: specen säger "avoid heavy recording allocation or storage
   writes in the render loop". Loopen anropar `sampla` varje bildruta, men
   posten skrivs bara med SAMPELTAKT (20 Hz) — resten av anropen faller på
   en jämförelse och returnerar. Ingenting skrivs till disk under ritten. */

/* Sampeltakten. 20 Hz räcker för att beskriva en 20 m volt: i trav
   (~3,2 m/s) blir det ett sampel var 16:e centimeter. Högre takt ger inte
   mer PEDAGOGIK, bara större poster. */
const INSPELNING_HZ = 20;
const INSPELNING_DT = 1 / INSPELNING_HZ;

/* Gränser. En post får inte växa obegränsat i en flik som lämnas öppen.
   Når inspelningen taket stängs den och märks `trunkerad`, i stället för
   att tyst fortsätta äta minne eller tyst kasta det som redan spelats in.

   TAKET ÄR MÄTT MOT LIFECYCLEN, inte gissat. Ett försök avslutas av
   `ugnetaForsokSteg` vid `moment.tid * 2.2`, och det längsta momentet i
   G02-D:s två övningar är storvolten på 32 s — alltså 70,4 s. Ett tak på
   60 s hade kapat en HELT NORMAL volt, vilket replay-provet visade genom
   att posten fortfarande var aktiv efter 57 s. 120 s ger marginal för
   varje moment upp till 54 s och kostar 2400 sampel. */
const INSPELNING_MAX_SEK = 120;
const INSPELNING_MAX_SAMPEL = INSPELNING_MAX_SEK * INSPELNING_HZ;
const INSPELNING_MAX_HANDELSER = 200;

/* Ett tal som får skrivas ned. Samma disciplin som HorseCore/Lektion.tal
   på Roblox-sidan: saknat, NaN och oändlighet är INTE noll. Ett fält som
   inte gick att mäta blir `null` i posten, och den som läser posten får
   veta att det saknades i stället för att tro på en nolla. */
/* Lua-parity: samma svar som `tonumber()` i Lektion.luau ger.

   `Number()` är JavaScripts egen fälla och den enda av de tre som
   behövde lagas: `Number(null)`, `Number("")`, `Number("  ")`,
   `Number(false)` och `Number([])` är alla 0, och `Number(true)` är 1.
   Ett saknat värde blev alltså ett uppmätt värde — precis det kontraktet
   säger att det inte får bli. `tonumber` i Lua svarar nil på var och en
   av dem, så webben låg fel mot Roblox, inte tvärtom.

   Numeriska STRÄNGAR släpps igenom med flit: `tonumber("1.5")` är 1.5 i
   Lua, och en vakt som avvisade dem hade infört en NY asymmetri i stället
   för att stänga den gamla. Det är en medveten tillåtelse, inte en
   glömska. */
function insTal(v){
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v !== "string") return null;          // null, undefined, boolean, array, objekt
  const t = v.trim();
  if (t === "") return null;                        // "" och "   " är inte noll
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
}

function Inspelning() {
  this.aktiv = false;
  this.post = null;
  this.t = 0;          // ackumulerad simtid, sekunder
  this.nasta = 0;      // när nästa sampel ska tas
}

/* Startar en inspelning. `start` är ridningens utgångsläge — det som
   behövs för att en uppspelning ska betyda samma sak som ritten. */
Inspelning.prototype.starta = function (ovningId, hastId, profil, start, ovningVersion) {
  this.aktiv = true;
  this.t = 0;
  this.nasta = 0;
  this.post = {
    schema: (typeof INSPELNING_SCHEMA !== "undefined") ? INSPELNING_SCHEMA : 1,
    ovning: ovningId || null,
    ovningVersion: ovningVersion === undefined ? null : ovningVersion,
    hast: hastId || null,
    profil: profil || null,
    start: start || null,
    klocka: "sim",
    ram: (typeof OVNING_RAM !== "undefined") ? OVNING_RAM.DRESSYR : null,
    hz: INSPELNING_HZ,
    sampel: [],
    handelser: [],
    trunkerad: false,
    sekunder: 0,
  };
  return this.post;
};

/* Ett steg ur ridloopen. Anropas varje bildruta; skriver bara var 1/20 s.

   `dt` ska vara loopens egen dt. Ett dt som inte är ett ändligt positivt
   tal ignoreras — en pausad flik som återvänder med dt = 4,2 s ska inte
   skriva ett sampel som påstår att hästen teleporterade. */
Inspelning.prototype.sampla = function (dt, tillstand) {
  if (!this.aktiv || !this.post) return false;
  /* dt måste vara ett RIKTIGT tal. `insTal` tar emot "0.016" och gör det
     till 0.016 — bekvämt för ett mätvärde, fel för klockan. En sträng i
     dt betyder att någon skickar fel sorts värde, och då ska inspelningen
     inte gissa åt dem. Mätt i provet: utan det här skrev "0.016" ett
     sampel som såg helt normalt ut i posten. */
  if (typeof dt !== "number") return false;
  const d = insTal(dt);
  if (d === null || d <= 0 || d > 0.5) return false;
  this.t += d;
  if (this.t < this.nasta) return false;
  /* Nästa sampel schemaläggs från FÖRRA MÅLET, inte från nu. Skrev vi
     `this.nasta = this.t + DT` blev intervallet dt_bildruta längre än
     avsett varje gång, och driften åt upp fem sampel på åtta sekunder
     (155 i stället för 160). Har vi hamnat efter — en lång bildruta —
     resynkas i stället för att skriva en skur av sampel i kapp. */
  this.nasta += INSPELNING_DT;
  if (this.nasta <= this.t) this.nasta = this.t + INSPELNING_DT;

  if (this.post.sampel.length >= INSPELNING_MAX_SAMPEL) {
    this.post.trunkerad = true;
    this.aktiv = false;
    return false;
  }
  const s = tillstand || {};
  const h = s.hjalper || {};
  this.post.sampel.push({
    t: Math.round(this.t * 1000) / 1000,
    x: insTal(s.x), y: insTal(s.y), kurs: insTal(s.kurs),
    gangart: s.gangart || null,
    fas: insTal(s.fas),
    fart: insTal(s.fart),
    kurvatur: insTal(s.kurvatur),
    balans: insTal(s.balans),
    hjalper: {
      skankel: insTal(h.skankel), tygel: insTal(h.tygel),
      sits: insTal(h.sits), styrning: insTal(h.styrning),
    },
  });
  this.post.sekunder = this.post.sampel[this.post.sampel.length - 1].t;
  return true;
};

/* En diskret händelse — gångartsbyte, parad, avbrott. Tidsstämplas med
   samma simklocka som sampeln, så att de går att lägga bredvid varandra. */
Inspelning.prototype.handelse = function (typ, data) {
  if (!this.aktiv || !this.post || !typ) return false;
  if (this.post.handelser.length >= INSPELNING_MAX_HANDELSER) return false;
  this.post.handelser.push({
    t: Math.round(this.t * 1000) / 1000,
    typ: String(typ),
    data: data === undefined ? null : data,
  });
  return true;
};

/* Avslutar och lämnar posten. Efter det här är inspelaren tom — samma
   instans kan starta en ny ritt utan att den förra läcker in i den. */
Inspelning.prototype.avsluta = function () {
  const p = this.post;
  this.aktiv = false;
  this.post = null;
  this.t = 0;
  this.nasta = 0;
  return p;
};

/* ── UPPSPELNINGEN ──────────────────────────────────────────────────
   Läser en post. Ändrar den ALDRIG, och rör ingenting levande: ingen
   häst, ingen progression, inget serverauktoritativt tillstånd. Den
   svarar bara på frågan "hur såg ritten ut vid tiden t?".

   Interpolationen är validerad i den meningen att den vägrar interpolera
   mellan sampel den inte litar på: saknas ett tal i något av de två
   grannsamplen blir svaret null för just det fältet, i stället för ett
   halvvägs-tal mellan ett mätvärde och ingenting. */

function insLerp(a, b, k) {
  if (a === null || b === null || a === undefined || b === undefined) return null;
  return a + (b - a) * k;
}

/* Vinklar interpoleras kortaste vägen — annars snurrar hästen ett helt
   varv när kursen passerar π. */
function insLerpVinkel(a, b, k) {
  if (a === null || b === null || a === undefined || b === undefined) return null;
  let d = b - a;
  while (d > Math.PI) d -= 2 * Math.PI;
  while (d < -Math.PI) d += 2 * Math.PI;
  return a + d * k;
}

function Uppspelning(post) {
  this.post = post || null;
  this.lage = 0;        // uppspelningstid i sekunder
  this.spelar = false;
  this.fart = 1;        // 1 = normal, 0.5 = halv
}

Uppspelning.prototype.langd = function () {
  const p = this.post;
  if (!p || !p.sampel || !p.sampel.length) return 0;
  return p.sampel[p.sampel.length - 1].t;
};

Uppspelning.prototype.spela = function () { this.spelar = true; };
Uppspelning.prototype.pausa = function () { this.spelar = false; };

/* Scrubbing: hoppa till en tidpunkt. Klampas till postens längd så att
   ett drag förbi slutet inte lämnar uppspelningen i ett omöjligt läge. */
Uppspelning.prototype.hoppa = function (t) {
  const n = insTal(t);
  this.lage = Math.max(0, Math.min(this.langd(), n === null ? 0 : n));
  return this.lage;
};

Uppspelning.prototype.sattFart = function (f) {
  const n = insTal(f);
  if (n !== null && n > 0 && n <= 4) this.fart = n;
  return this.fart;
};

Uppspelning.prototype.steg = function (dt) {
  if (!this.spelar) return this.lage;
  const d = insTal(dt);
  if (d === null || d <= 0) return this.lage;
  this.lage += d * this.fart;
  const slut = this.langd();
  if (this.lage >= slut) { this.lage = slut; this.spelar = false; }
  return this.lage;
};

/* Tillståndet vid en tidpunkt. Returnerar null när posten är tom — en
   uppspelning utan sampel ska inte låtsas ha ett läge. */
Uppspelning.prototype.vid = function (t) {
  const p = this.post;
  if (!p || !p.sampel || !p.sampel.length) return null;
  const n = insTal(t);
  const tid = Math.max(0, Math.min(this.langd(), n === null ? this.lage : n));
  const S = p.sampel;

  /* Binärsökning: en uppspelning ska inte bli långsammare ju längre
     ritten var. */
  let lo = 0, hi = S.length - 1;
  while (lo < hi - 1) {
    const m = (lo + hi) >> 1;
    if (S[m].t <= tid) lo = m; else hi = m;
  }
  const a = S[lo], b = S[hi];
  if (a === b) return { t: a.t, x: a.x, y: a.y, kurs: a.kurs, gangart: a.gangart,
    fart: a.fart, kurvatur: a.kurvatur, balans: a.balans, fas: a.fas };

  const span = b.t - a.t;
  const k = span > 0 ? Math.max(0, Math.min(1, (tid - a.t) / span)) : 0;
  return {
    t: tid,
    x: insLerp(a.x, b.x, k),
    y: insLerp(a.y, b.y, k),
    kurs: insLerpVinkel(a.kurs, b.kurs, k),
    /* Gångart och fas är DISKRETA — de interpoleras inte. Halvvägs mellan
       trav och skritt finns ingen gångart, och en fas som interpoleras
       över ett varvskifte hoppar bakåt. Närmaste sampel gäller. */
    gangart: (k < 0.5 ? a : b).gangart,
    fas: (k < 0.5 ? a : b).fas,
    fart: insLerp(a.fart, b.fart, k),
    kurvatur: insLerp(a.kurvatur, b.kurvatur, k),
    balans: insLerp(a.balans, b.balans, k),
  };
};

/* Händelserna i ett tidsspann — för att märka ut gångartsbyten på
   tidslinjen utan att läsa om hela posten varje bildruta. */
Uppspelning.prototype.handelserMellan = function (t0, t1) {
  const p = this.post;
  if (!p || !p.handelser) return [];
  return p.handelser.filter(h => h.t >= t0 && h.t < t1);
};

if (typeof window !== "undefined") {
  window.Inspelning = Inspelning;
  window.Uppspelning = Uppspelning;
}
