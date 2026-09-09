#!/usr/bin/env node
/* G02-E DEL 1 — KAMERALÄGETS LIVSCYKEL (issue #150).

   Mäter kontraktet i src/riding/kameralage.js: att sadeln är standard,
   att en feedbackvinkel är BEGRÄNSAD i tid, att återgången är
   deterministisk och bildfrekvensoberoende, och att ingen begäran kan
   ligga kvar och tändas senare.

   Filen innehåller också sina egna FALSIFIERINGAR. Ett test som aldrig
   visats kunna bli rött är svag evidens (docs/DELIVERY-PROTOCOL.md §4),
   och att beskriva en falsifiering i prosa är inte att ha kört den. De
   fyra muteringarna nedan laddar modulens källa, bryter EN sak i den,
   kör om samma mätning och kräver att den faller. Går en mutation
   igenom är skyddet en illusion och sviten blir röd.

   Kör: node tools/kameralagetest.mjs */
import fs from "node:fs";
import vm from "node:vm";

const KALLA = new URL("../src/riding/kameralage.js", import.meta.url);
const src = fs.readFileSync(KALLA, "utf8");

/* Laddar modulen i en egen kontext. `patch` får byta ut text i källan
   före körning — det är så falsifieringarna bryter skyddet. */
function ladda(patch) {
  let kod = src;
  if (patch) {
    const [fran, till] = patch;
    if (!kod.includes(fran)) throw new Error(`mutationen hittade inte sitt fäste: ${fran}`);
    kod = kod.replace(fran, till);
  }
  const ctx = { console: { warn() {}, log() {} } };
  vm.createContext(ctx);
  vm.runInContext(kod, ctx, { filename: "src/riding/kameralage.js" });
  return ctx.Kameralage;
}

let fel = 0, matt = 0;
function prova(namn, ok, detalj) {
  matt++;
  if (!ok) fel++;
  console.log(ok ? "  OK  " : "  FEL ", namn, detalj === undefined ? "" : `— ${detalj}`);
}

/* Kör n bildrutor med fast dt och returnerar vikthistoriken. */
function kor(K, st, sek, dt = 1 / 60) {
  const ut = [];
  for (let t = 0; t < sek; t += dt) ut.push(K.stega(st, dt).vikt);
  return ut;
}

const K = ladda();

/* ══ 1. SADELN ÄR STANDARD ═════════════════════════════════════════
   Ett nyskapat läge ska vara ryttarperspektiv utan att någon valt det,
   och det ska FÖRBLI det utan begäran. */
{
  const st = K.skapa();
  const start = K.las(st);
  prova("ett nytt läge är ryttarperspektiv med vikt 0",
    start.lage === "ryttare" && start.vikt === 0 && start.id === null,
    `${start.lage} · vikt ${start.vikt}`);
  const v = kor(K, st, 30);
  prova("utan begäran lämnar läget aldrig sadeln (30 s)",
    v.every(x => x === 0) && !K.aktiv(st),
    `max vikt ${Math.max(...v)}`);
}

/* ══ 2. EN VINKEL TONAS IN, HÅLLS OCH ÅTERGÅR AV SIG SJÄLV ═════════
   Det här är hela produktkravet: tillfälligt, sedan tillbaka. */
{
  const st = K.skapa();
  prova("en giltig vinkel tas emot", K.begar(st, "sits", "test") === true);
  const v = kor(K, st, 10);
  const topp = Math.max(...v);
  const sistaOver = v.reduce((a, x, i) => (x > 0.001 ? i : a), -1);
  prova("vikten når full vinkel", topp > 0.999, `topp ${topp.toFixed(4)}`);
  prova("vikten faller tillbaka till EXAKT noll", v[v.length - 1] === 0,
    `slut ${v[v.length - 1]}`);
  prova("läget är tillbaka i sadeln efteråt",
    !K.aktiv(st) && K.las(st).lage === "ryttare" && st.id === null,
    `fas ${st.fas} · id ${st.id}`);
  /* in 0,40 + håll 1,60 + ut 0,50 = 2,50 s. Marginalen är en bildruta. */
  const varaktighet = (sistaOver + 1) / 60;
  prova("vyn är tidsbegränsad och slutar när konfigurationen säger",
    varaktighet > 2.4 && varaktighet < 2.6, `${varaktighet.toFixed(3)} s (väntat ~2,50)`);
}

/* ══ 3. ÖVERGÅNGEN ÄR MJUK OCH BEGRÄNSAD ══════════════════════════
   Inga hopp, ingen vikt utanför [0,1]. Ett hopp i vikten är ett klipp i
   bilden, och det är precis vad produktbeslutet förbjuder. */
{
  const st = K.skapa();
  K.begar(st, "vagval");
  const v = kor(K, st, 10);
  let storstaSteg = 0;
  for (let i = 1; i < v.length; i++) storstaSteg = Math.max(storstaSteg, Math.abs(v[i] - v[i - 1]));
  prova("vikten håller sig inom [0,1]", v.every(x => x >= 0 && x <= 1));
  /* Intoningen är 0,45 s; en smoothstep har max lutning 1,5/T per
     sekund, alltså ~0,056 per bildruta i 60 Hz. Taket är satt med
     marginal men långt under ett klipp. */
  prova("inget hopp i vikten mellan bildrutor", storstaSteg < 0.08,
    `största steg ${storstaSteg.toFixed(4)}`);
}

/* ══ 4. BILDFREKVENSOBEROENDE ═════════════════════════════════════
   Samma ackumulerade tid ska ge samma bild oavsett bildfrekvens. Det är
   vad "deterministisk" betyder i praktiken, och ett krav i CLAUDE.md. */
{
  const matVid = (dt, sek) => {
    const st = K.skapa();
    K.begar(st, "sits");
    let t = 0;
    while (t < sek - 1e-9) { K.stega(st, dt); t += dt; }
    return st.vikt;
  };
  const a = matVid(1 / 30, 1.2), b = matVid(1 / 240, 1.2);
  prova("30 Hz och 240 Hz ger samma vikt vid samma tid",
    Math.abs(a - b) < 0.02, `${a.toFixed(4)} mot ${b.toFixed(4)}`);
}

/* ══ 5. INGEN KÖ, INGA ÖVERRASKNINGAR ═════════════════════════════ */
{
  const st = K.skapa();
  prova("okänd vinkel avvisas", K.begar(st, "finns-inte") === false);
  prova("okänd vinkel rör inte tillståndet", !K.aktiv(st) && st.vikt === 0);

  K.begar(st, "sits");
  kor(K, st, 0.5);
  const vikt1 = st.vikt;
  prova("en ANNAN vinkel avvisas medan en vy är uppe",
    K.begar(st, "vagval") === false && st.id === "sits",
    `id kvar: ${st.id}`);
  prova("den avvisade begäran ändrade inte vikten", st.vikt === vikt1);
  /* Samma vinkel får starta om — och det ska vara kontinuerligt. */
  prova("SAMMA vinkel tas emot igen", K.begar(st, "sits") === true);
  const efter = K.stega(st, 1 / 60).vikt;
  prova("omstarten hoppar inte i vikten", Math.abs(efter - vikt1) < 0.08,
    `${vikt1.toFixed(3)} → ${efter.toFixed(3)}`);
}

/* ══ 5b. UPPREPAD BEGÄRAN FÖRLÄNGER INTE DEADLINEN (blocker) ═══════
   ChatGPT-fyndet på #150: `begar()` nollställde `total` vid VARJE
   anrop, inte bara vid en riktigt ny begäran. En anropare som råkar
   begära om SAMMA vinkel varje bildruta — en händelse som triggar
   upprepat, ett dubbeltryck som studsar mot samma kod — kunde då hålla
   kvar feedbackvyn för evigt, eftersom klockan nödbromsen läser
   nollställdes om varje gång innan den hann nå taket.

   Körs HÄR på den RIKTIGA, ofixade modulen `K` — inte via
   mutationsharnesset nedan — så att detta är ett förstahandsbevis på
   den faktiska koden, inte bara på att en textmutation kan upptäckas. */
{
  const st = K.skapa();
  K.begar(st, "sits");
  /* Nödbromsens tak plus uttoningens tak plus en sekunds marginal:
     om vyn INTE stängt sig innan dess trots spammet är deadlinen
     bruten. */
  const grans = Math.ceil((K.MAX_TOTAL + K.GRANS.ut[1] + 1) * 60);
  let n = 0;
  while (K.aktiv(st) && n < grans) {
    K.begar(st, "sits", "upprepad");    // samma vinkel begärs om, varje bildruta
    K.stega(st, 1 / 60);
    n++;
  }
  prova("upprepade begäranden av SAMMA vinkel kan inte hålla vyn för evigt",
    !K.aktiv(st) && n < grans,
    `stannade ${K.aktiv(st) ? "aldrig" : `efter ${(n / 60).toFixed(2)} s`} (tak ${(grans / 60).toFixed(2)} s)`);
}

/* ══ 6. AVBROTT LÄMNAR INGET SPÖKE ════════════════════════════════
   Scenbyte, avsittning och overlay går genom `nollstall`. Efter det får
   ingenting vakna — det är kravet "no stale camera request should
   activate later". */
{
  const st = K.skapa();
  K.begar(st, "ansats");
  kor(K, st, 0.6);
  prova("en vy var uppe före avbrottet", K.aktiv(st) && st.vikt > 0);
  prova("nollstall rapporterar att den bröt något",
    K.nollstall(st, "scenbyte") === true);
  const efter = K.las(st);
  prova("efter avbrottet är sadeln tillbaka omedelbart",
    efter.vikt === 0 && efter.lage === "ryttare" && st.id === null);
  const v = kor(K, st, 60);
  prova("inget vaknar senare (60 s)", v.every(x => x === 0),
    `max vikt ${Math.max(...v)}`);
}

/* ══ 7. MJUKT SLÄPP ═══════════════════════════════════════════════ */
{
  const st = K.skapa();
  K.begar(st, "utifran");
  kor(K, st, 0.8);
  prova("slapp startar uttoningen", K.slapp(st, "klart") === true && st.fas === "ut");
  const v = kor(K, st, 3);
  prova("släppet når exakt noll och nollställer",
    v[v.length - 1] === 0 && !K.aktiv(st));
  prova("slapp på ett vilande läge gör ingenting", K.slapp(st) === false);
}

/* ══ 8. SKRÄP-DT KAN INTE FRYSA ELLER HOPPA ═══════════════════════
   En flik som legat i bakgrunden, en bruten klocka eller en NaN ska inte
   kunna strand­sätta spelaren i en feedbackvy. */
{
  const st = K.skapa();
  K.begar(st, "sits");
  K.stega(st, NaN); K.stega(st, -5); K.stega(st, undefined);
  prova("skräp-dt flyttar inte övergången", st.total === 0, `total ${st.total}`);
  /* Ett enormt dt klampas, men tiden går ändå framåt: kör tills klart. */
  let n = 0;
  while (K.aktiv(st) && n < 10000) { K.stega(st, 60); n++; }
  prova("ett enormt dt strandsätter inte spelaren",
    !K.aktiv(st) && st.vikt === 0, `${n} steg`);
}

/* ══ 9. NÖDBROMSEN ════════════════════════════════════════════════
   En vinkel som smugit förbi valideringen får inte hålla bilden. Vi
   planterar en olaglig hålltid direkt i tabellen — samma sak som en
   framtida redigering kunde göra av misstag. */
{
  const K2 = ladda();
  K2.VINKLAR.evig = { yaw: 0, bak: 1, hojd: 1, fov: 1, blick: 1,
    in: 0.4, hall: 9999, ut: 0.5 };
  const st = K2.skapa();
  K2.begar(st, "evig");
  const v = kor(K2, st, 20);
  prova("nödbromsen tvingar hem en vinkel som aldrig tar slut",
    v[v.length - 1] === 0 && !K2.aktiv(st),
    `slutvikt ${v[v.length - 1]} · total ${st.total.toFixed(2)} s`);
  prova("nödbromsen slår till inom taket + uttoning",
    st.total <= K2.MAX_TOTAL + 1.6, `${st.total.toFixed(2)} s`);
}

/* ══ 10. VALIDERINGEN SLÄPPER INTE IGENOM SKRÄP ═══════════════════ */
{
  prova("en vinkel utanför gränserna underkänns",
    K.validera("x", { yaw: 0, bak: 99, hojd: 1, fov: 1, blick: 1, in: 0.4, hall: 1, ut: 0.5 }) !== null);
  prova("en för lång vinkel underkänns",
    K.validera("x", { yaw: 0, bak: 1, hojd: 1, fov: 1, blick: 1, in: 1.2, hall: 4, ut: 1.5 }) !== null);
  prova("alla registrerade vinklar är giltiga",
    K.vinkelnamn().every(id => K.validera(id, K.VINKLAR[id]) === null),
    K.vinkelnamn().join(", "));
  prova("utifran-vinkeln är den gamla bomvyn, tal för tal",
    K.VINKLAR.utifran.yaw === 0 && K.VINKLAR.utifran.bak === 1 &&
    K.VINKLAR.utifran.hojd === 1 && K.VINKLAR.utifran.fov === 1 &&
    K.VINKLAR.utifran.blick === 1);
}

/* ══ 11. FALSIFIERING ══════════════════════════════════════════════
   Varje mutation bryter EN sak. Går mätningen ändå igenom skyddar den
   ingenting, och då ska den här filen bli röd. */
console.log("\n── Falsifiering: bryts skyddet ska mätningen falla ──");

function falsifiera(namn, patch, mat) {
  let holl;
  try {
    holl = mat(ladda(patch));
  } catch (e) {
    holl = false;                       // en krasch räknas som "föll"
  }
  matt++;
  if (holl) {
    fel++;
    console.log("  FEL  mutationen ", namn, "— mätningen höll ändå, skyddet är en illusion");
  } else {
    console.log("  OK   mutationen ", namn, "— mätningen föll som den ska");
  }
}

/* (a) FEL STANDARD: läget föds i den gamla utifrånvyn i stället för i
       sadeln. Det är exakt det produktfel korrigeringen pekade ut — en
       kamera som HETER ryttare men står bakom hästen. */
falsifiera("fel standard (ritten börjar i bomvyn)",
  ['return {lage:"ryttare", id:null, fas:"vila", t:0, total:0,\n            vikt:0, startVikt:0, orsak:null};',
   'return {lage:"feedback", id:"utifran", fas:"hall", t:0, total:0,\n            vikt:1, startVikt:1, orsak:null};'],
  Km => {
    const st = Km.skapa();
    const start = Km.las(st);
    if (!(start.lage === "ryttare" && start.vikt === 0 && start.id === null)) return false;
    /* och den ska FÖRBLI sadeln utan begäran */
    for (let i = 0; i < 1800; i++) if (Km.stega(st, 1 / 60).vikt !== 0) return false;
    return true;
  });

/* (b) INGEN ÅTERGÅNG: uttoningens nollställning tas bort. Vyn blir
       kvar på en liten men nollskild vikt och läget står registrerat.

       VIKTIGT: loopen får INTE löpa så länge att nödbromsen (§9, en HELT
       annan nollstall-punkt, för `total>=MAX_TOTAL+MAX_UT`) hinner
       trigga och maskera bortfallet av just den här nollstållningen.
       "sits" är klar efter in+håll+ut = 0,40+1,60+0,50 = 2,50 s; vi kör
       till 3,5 s — gott om marginal för att den SKA vara klar, men långt
       under nödbromsens 7,5 s (MAX_TOTAL 6,0 + MAX_UT 1,5). */
falsifiera("ingen automatisk återgång",
  ['if(p>=1)nollstall(st,"atergang");', "/* borttagen */"],
  Km => {
    const st = Km.skapa();
    Km.begar(st, "sits");
    let v = 0;
    for (let i = 0; i < 3.5 * 60; i++) v = Km.stega(st, 1 / 60).vikt;
    return v === 0 && !Km.aktiv(st);
  });

/* (c) INGET HÅRT AVBROTT: nollstall slutar nolla RÅ vikt, alltså precis
       det scenbytet och avsittningen förlitar sig på.

       MÅSTE mäta `st.vikt` direkt — INTE `Km.las(st).vikt`. `las()`
       maskerar buggen: den läser vikten via `vinkel(st.id)`, och
       `st.id=null` nollställs korrekt av den orörda raden ovanför den
       muterade, så `las()` returnerar `vikt:0` som sin NEUTRAL-fallback
       oavsett om den råa `st.vikt` faktiskt nollställdes. En kvarliggen
       rå vikt är precis det spöke som skulle smyga med till nästa
       `begar()`, som sätter `startVikt=st.vikt` — alltså en osynlig
       skarv i nästa vy i stället för en ren start från sadeln. */
falsifiera("nollstall lämnar kvar en rå vikt",
  ["st.vikt=0;\n    st.startVikt=0;", "st.startVikt=0;"],
  Km => {
    const st = Km.skapa();
    Km.begar(st, "ansats");
    for (let i = 0; i < 40; i++) Km.stega(st, 1 / 60);
    const viktFore = st.vikt;
    Km.nollstall(st, "scenbyte");
    if (viktFore <= 0) throw new Error("testet kräver en icke-noll vikt före avbrottet");
    return st.vikt === 0;
  });

/* (d) KÖ: en annan vinkel tillåts mitt i en pågående vy, vilket ger ett
       klipp mitt i styrningen. */
falsifiera("vinkelbyte mitt i en pågående vy",
  ["if(!nyBegaran&&st.id!==id)return false;", ""],
  Km => {
    const st = Km.skapa();
    Km.begar(st, "sits");
    for (let i = 0; i < 30; i++) Km.stega(st, 1 / 60);
    return Km.begar(st, "vagval") === false && st.id === "sits";
  });

/* (e) UPPREPAD BEGÄRAN FÖRLÄNGER DEADLINEN (blocker, #150-korrigering):
       `total` nollställs vid VARJE begäran i stället för bara vid en
       riktigt ny (fas var "vila"). En anropare som råkar begära om
       SAMMA vinkel varje bildruta — en händelse som triggar upprepat,
       ett dubbeltryck som studsar — kan då hålla kvar feedbackvyn för
       evigt, för klockan som nödbromsen läser nollställs om varje gång. */
falsifiera("upprepad begäran av SAMMA vinkel förlänger deadlinen för evigt",
  ["if(nyBegaran)st.total=0;", "st.total=0;"],
  Km => {
    const st = Km.skapa();
    Km.begar(st, "sits");
    const grans = Math.ceil((Km.MAX_TOTAL + Km.GRANS.ut[1] + 1) * 60);
    let n = 0;
    while (Km.aktiv(st) && n < grans) {
      Km.begar(st, "sits", "upprepad");   // samma vinkel begärs varje bildruta
      Km.stega(st, 1 / 60);
      n++;
    }
    /* DEN ÖNSKADE EGENSKAPEN (samma som §5b ovan): vyn stänger sig
       SJÄLV inom taket trots spammet. `falsifiera` kräver att mat()
       returnerar sanningsvärdet för den önskade egenskapen — true om
       den håller, false om mutationen bröt den — så att FEL bara
       rapporteras när en trasig mutation ändå klarar provet. Skriver
       man detta omvänt (true = "buggen syns") rapporterar harnesset
       fel även när falsifieringen fungerar precis som den ska, vilket
       var precis den miss som fanns här tidigare. */
    return !Km.aktiv(st) && n < grans;
  });

console.log("");
if (fel > 0) {
  console.log(`${fel} av ${matt} mätningar föll.`);
  process.exit(1);
}
console.log(`ALLA OK (${matt} mätningar)`);
