#!/usr/bin/env node
/* RÖSTGRINDEN — ingen röst får agera ridlärare.
 *
 * Tobias produktbeslut 2026-09-10 (issue #161): det ska INTE finnas
 * någon röst som agerar ridlärare. Före beslutet läste `ljudRost(text)`
 * i src/ljud.js upp lärarens repliker med webbläsarens svenska talsyntes
 * (`SpeechSynthesisUtterance`, `sv-SE`), anropad från src/game.js och
 * src/larare.js under ritten.
 *
 * Att ta bort koden räcker inte som leverans. En borttagning utan grind
 * är en borttagning som kommer tillbaka — någon lägger till en
 * "hjälpsam" uppläsning om ett halvår och ingenting säger ifrån. Den
 * här filen är grinden.
 *
 * VAD SOM ÄR FÖRBJUDET
 *   · webbläsarens talsyntes (SpeechSynthesis*, speechSynthesis.*),
 *   · en annan talsyntestjänst (ElevenLabs, Polly, Azure TTS, …),
 *   · inspelad eller AI-genererad lärarröst,
 *   · Roblox egen uppläsning (TextToSpeechService, VoiceChatService).
 *
 * VAD SOM INTE ÄR FÖRBJUDET, och som grinden därför inte får fälla:
 *   · skriven lärartext — den är hela pedagogiken och står kvar,
 *   · icke-verbalt spelljud: hovslag, gnägg, fnysningar, ambiens, UI-ljud,
 *   · ordet "röst" i en KOMMENTAR som förklarar varför rösten är borta.
 *
 * Sista punkten är hela svårigheten. Grinden strippar därför kommentarer
 * innan den söker: den mäter vad koden GÖR, inte vad den berättar. En
 * grind som fällde på ordet hade tvingat fram tysta borttagningar utan
 * förklaring, vilket är precis tvärtemot vad repot vill.
 *
 * NEGATIV KONTROLL. Grinden provar också sig själv: den syntetiserar en
 * återinförd röst och kräver att detektorn fäller den. Utan det ledet är
 * ett grönt utfall inte värt något — det går inte att skilja "ingen röst
 * finns" från "detektorn hittar ingenting alls".
 *
 * Kör: node tools/rostgrind.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const resultat = [];
function prova(namn, ok, detalj) {
  resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, detalj ? "— " + detalj : "");
}

/* ── Kommentarstrippning ──────────────────────────────────────────────
   Enkel och medvetet konservativ: den tar /* … *​/ och // … och lämnar
   allt annat. Strängar som INNEHÅLLER "//" (en URL) kan förlora sitt
   svansled, och det är rätt håll att fela åt här — grinden letar efter
   API-namn, inte efter URL:er, och en trasig URL kan aldrig göra ett
   förbjudet anrop synligt som tillåtet. */
function utanKommentarer(kalla) {
  return kalla
    .replace(/\/\*[\s\S]*?\*\//g, " ")
    .replace(/(^|[^:])\/\/[^\n]*/g, "$1");
}

/* Mönstren är API-NAMN, inte svenska ord. `röst` i en kommentar ska inte
   fälla; `speechSynthesis.speak(` ska. */
const FORBJUDET = [
  [/SpeechSynthesisUtterance/, "webbläsarens talsyntes (SpeechSynthesisUtterance)"],
  [/\bspeechSynthesis\s*\./, "webbläsarens talsyntes (speechSynthesis.*)"],
  [/\bwindow\s*\.\s*speechSynthesis\b/, "webbläsarens talsyntes via window"],
  [/["']speechSynthesis["']\s*in\s*window/, "funktionskoll för talsyntes"],
  [/\bljudRost\s*\(/, "det borttagna ljudRost()-anropet"],
  [/\bLJUD\s*\.\s*rost\b/, "den borttagna LJUD.rost-flaggan"],
  [/TextToSpeechService/, "Roblox TextToSpeechService"],
  [/VoiceChatService/, "Roblox VoiceChatService"],
  [/\b(elevenlabs|playht|azure[-_. ]?tts|polly\.synthesize|texttospeech\.googleapis)\b/i,
    "extern talsyntestjänst"],
  [/\b(larar|lärar|instruktor|instruktör|ugneta)[a-zA-Z]*\s*[-_.]?\s*(rost|röst|voice|vo)\b/i,
    "en namngiven lärarröst"],
];

/* Produktionsvägarna. Grinden mäter det som SKEPPAS — `src/` och den
   byggda filen — plus Roblox-koden. Verktyg och tester är inte
   produktion och skannas inte: den här filen innehåller själv varenda
   förbjudet mönster, och en grind som fäller på sig själv är värdelös. */
function jsFiler(dir) {
  const ut = [];
  for (const post of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, post.name);
    if (post.isDirectory()) ut.push(...jsFiler(p));
    else if (/\.(js|mjs|luau|html)$/.test(post.name)) ut.push(p);
  }
  return ut;
}

const MALKATALOGER = ["src", "roblox/src", "roblox/game", "roblox/buildings"];
const filer = [];
for (const d of MALKATALOGER) {
  const abs = path.join(ROT, d);
  if (fs.existsSync(abs)) filer.push(...jsFiler(abs));
}
const INDEX = path.join(ROT, "index.html");
if (fs.existsSync(INDEX)) filer.push(INDEX);

/* Den BYGGDA filen räknas som produktion när den finns: det är den
   spelaren faktiskt laddar, och den byggs av tools/build.py ur src/. Är
   den inte byggd i den här körningen hoppas den över — CI bygger den
   före grinden. */
const DIST = path.join(ROT, "dist/ridskolan.html");
const distFinns = fs.existsSync(DIST);
if (distFinns) filer.push(DIST);

function sok(kalla) {
    const kod = utanKommentarer(kalla);
    const fynd = [];
    for (const [re, vad] of FORBJUDET) {
      const m = kod.match(re);
      if (m) fynd.push(`${vad} (\`${m[0].trim()}\`)`);
    }
    return fynd;
}

console.log(`RÖSTGRINDEN — ${filer.length} produktionsfiler\n`);

const traffar = [];
for (const f of filer) {
  const fynd = sok(fs.readFileSync(f, "utf8"));
  for (const v of fynd) traffar.push(`${path.relative(ROT, f)}: ${v}`);
}

prova("ingen talsyntes i produktionskoden", traffar.length === 0,
  traffar.length ? "\n     " + traffar.join("\n     ") : `${filer.length} filer rena`);

prova("den byggda webben är med i mätningen", distFinns,
  distFinns ? "dist/ridskolan.html" : "dist/ridskolan.html saknas — kör tools/build.py först");

/* ── Att texten finns kvar ────────────────────────────────────────────
   Beslutet gällde rösten, inte undervisningen. En "borttagning" som
   också tog bort lärarens repliker vore fel åtgärd — och den skulle
   passera kontrollen ovan. Därför mäts att lärarytan fortfarande SKRIVER. */
const larare = fs.readFileSync(path.join(ROT, "src/larare.js"), "utf8");
const game = fs.readFileSync(path.join(ROT, "src/game.js"), "utf8");
prova("lärarkortet skriver fortfarande sin text",
  /ugneta-punkt/.test(larare) && /textContent\s*=\s*rad/.test(larare),
  "src/larare.js bygger punkterna i DOM");
prova("saga() skriver fortfarande sin replik",
  /function saga\([\s\S]{0,200}?s\.textContent\s*=\s*txt/.test(game),
  "src/game.js sätter #saga.textContent");

/* ── Att det icke-verbala ljudet är kvar ──────────────────────────────
   Hovslag, gnägg och ambiens skulle inte röras. En överivrig borttagning
   som tog med hela ljudmotorn hade också passerat den första kontrollen. */
const ljud = fs.readFileSync(path.join(ROT, "src/ljud.js"), "utf8");
for (const [fn, vad] of [["ljudStot", "hovslag och steg"],
                         ["ljudAmbiens", "ambiensen"],
                         ["ljudToggle", "M-knappen"]]) {
  prova(`det icke-verbala ljudet är kvar: ${vad}`,
    new RegExp(`function ${fn}\\s*\\(`).test(ljud), fn);
}

/* ── NEGATIV KONTROLL ─────────────────────────────────────────────────
   Utan det här ledet går ett grönt utfall inte att skilja från en
   detektor som inte hittar någonting alls. Två återinföranden
   syntetiseras — ett rakt och ett bakom en flagga, som är det troliga
   sättet det faktiskt skulle komma tillbaka — och båda MÅSTE fällas. */
const ATERINFORANDEN = [
  ["rakt anrop",
   'function saga(t){const u=new SpeechSynthesisUtterance(t);u.lang="sv-SE";speechSynthesis.speak(u);}'],
  ["bakom en flagga",
   'const LJUD={rost:false};\nfunction las(t){if(!LJUD.rost)return;window.speechSynthesis.speak(t);}'],
  ["Roblox uppläsning",
   'local tts = game:GetService("TextToSpeechService")'],
];
for (const [vad, kod] of ATERINFORANDEN) {
  prova(`negativ kontroll: en återinförd röst fälls (${vad})`,
    sok(kod).length > 0, sok(kod)[0] || "detektorn såg ingenting");
}

/* ...och motsatsen: en KOMMENTAR som förklarar borttagningen får inte
   fälla. Gjorde den det vore priset för grinden att ingen fick skriva
   ned varför rösten är borta. */
const KOMMENTAR = `/* Här fanns ljudRost(text) med SpeechSynthesisUtterance och sv-SE.
   Borttagen: ingen röst ska agera ridlärare. LJUD.rost är också borta. */
function ljudStot(){}`;
prova("negativ kontroll: en förklarande kommentar fäller INTE",
  sok(KOMMENTAR).length === 0, sok(KOMMENTAR)[0] || "kommentaren passerar");

const fel = resultat.filter(r => !r.ok);
console.log();
if (fel.length) {
  console.log(`RÖSTGRINDEN FÖLL — ${fel.length} av ${resultat.length} mätningar.`);
  process.exit(1);
}
console.log(`Röstgrinden grön — ${resultat.length} mätningar. `
  + "Skriven lärartext, inget tal.");
