/* KONTROLLERNA — webbens svar på "vad gör jag för att rida?"

   EN TABELL, TVÅ YTOR. Samma rader används av kontrollistan (H) och av
   ridpanelens kärna (P3 § 3), precis som Roblox KontrollHjalp.rader() och
   KontrollHjalp.ridrader() läser samma RADER. Ingen andra sanning.

   Reglagen är de som FAKTISKT är bundna: tangenterna i src/game.js
   keydown/keyup och pekknapparnas etiketter i src/mobil.js. Ingenting här
   ändrar en bindning, och ridfysik, hjälpsemantik och hoppmodell rörs inte.

   ETT TRYCK, ETT STEG (#273 S1). Kärnraderna 1–2 säger samma sak som
   Roblox «Ett steg upp/ned i gångarterna», med ett reglage var: W/↑ och
   S/↓ på tangentbord, DRIV och BROMS på pek. Under dem ligger webbens
   egen ridmodell (skänkelimpuls upp, halvhalt ned) — spelaren behöver
   inte kunna den för att rida. Hierarkin: fyra kärnrader, resten bakom
   `?`, och hjälperna sist under rubriken «Avancerat». Ingen rad nämner
   en tangent webben inte har.

   `avancerat` märker en hjälp som INTE behövs i grundridningen (tygel,
   halvhalt, sits, lättridning, diagonal, spö). De är bundna på
   tangentbord och gör vad de alltid gjort; på pek har de ingen knapp i
   standardläget (#273 T3), och raden hoppas då över.

   REGLAGEN FÖLJER INMATNINGEN. En ren pekenhet får knapparnas egna
   etiketter; en rad utan reglage på den inmatningen hoppas över (Roblox
   regel — tystnad är ärligare än en tom kolumn).

   Allt spelaren läser går genom tSpr. `tgb` är tangentnamn och
   översätts inte — utom ordet för mellanslagstangenten, som är ett ord
   (`hjalp.webb.mellanslag`). `pek` är en språknyckel till knappens etikett. */

const KONTROLL_RADER = [
  { nyckel: "hjalp.webb.driv",         tgb: "W / ↑",                  pek: "touch.driv" },
  { nyckel: "hjalp.webb.bromsa",       tgb: "S / ↓",                  pek: "touch.broms" },
  { nyckel: "hjalp.styr",              tgb: "A / D",                  pek: "hjalp.spaken" },
  { nyckel: "hjalp.sitt_upp_av",       tgb: "E",                      pek: "touch.sitt_av" },
  { nyckel: "hjalp.webb.vy",           tgb: "V",                      pek: "touch.webb.vy" },
  { nyckel: "hjalp.denna_hjalp",       tgb: "H",                      pek: "?" },
  { nyckel: "hjalp.tygel",             tgb: "%MELLANSLAG%",           pek: "", avancerat: true },
  { nyckel: "hjalp.halvhalt",          tgb: "F",                      pek: "", avancerat: true },
  { nyckel: "hjalp.webb.sits",         tgb: "Shift / Ctrl",           pek: "", avancerat: true },
  { nyckel: "hjalp.webb.lattridning",  tgb: "R",                      pek: "", avancerat: true },
  { nyckel: "hjalp.webb.diagonal",     tgb: "Q",                      pek: "", avancerat: true },
  { nyckel: "hjalp.webb.spo",          tgb: "G",                      pek: "", avancerat: true },
];
/* Ridpanelens fyra kärnrader, i Roblox RIDKARNA-ordning: upp, ned, styr,
   sitt upp/av. */
const KONTROLL_KARNA = ["hjalp.webb.driv", "hjalp.webb.bromsa", "hjalp.styr", "hjalp.sitt_upp_av"];

const khT = (k, ...a) => (typeof tSpr === "function" ? tSpr(k, ...a) : k);

/* Vilken sorts inmatning talar vi om? Tangentbord vinner: en iPad med
   tangentbord ska få bokstäverna. */
function kontrollInmatning(){
  if (typeof navigator === "undefined") return "tangentbord";
  const pek = (navigator.maxTouchPoints || 0) > 0
    || (typeof window !== "undefined" && "ontouchstart" in window);
  /* Samma signal som src/mobil.js bygger pekgränssnittet på — då kan
     hjälpen inte säga en sak och knapparna en annan. */
  const baraPek = pek && !(typeof matchMedia === "function"
    && matchMedia("(hover: hover) and (pointer: fine)").matches);
  return baraPek ? "touch" : "tangentbord";
}

function kontrollReglage(r, sort){
  if (sort === "touch") {
    if (!r.pek) return "";
    return r.pek === "?" ? "?" : khT(r.pek);
  }
  return String(r.tgb || "").replace("%MELLANSLAG%", khT("hjalp.webb.mellanslag"));
}

/* Raderna som text. Ren avläsning — inget tillstånd, inget DOM. */
function kontrollRader(sort){
  const s = sort || kontrollInmatning();
  const ut = [];
  for (const r of KONTROLL_RADER) {
    const reglage = kontrollReglage(r, s);
    if (reglage) ut.push({ nyckel: r.nyckel, vad: khT(r.nyckel), reglage, avancerat: !!r.avancerat });
  }
  return ut;
}
/* Kärnan, för ridpanelen — ur samma rader. */
function kontrollRidrader(sort){
  const alla = kontrollRader(sort);
  return KONTROLL_KARNA.map(k => alla.find(r => r.nyckel === k)).filter(Boolean);
}
/* Reglaget för EN handling på spelarens inmatning (Roblox reglageFor). */
function kontrollReglageFor(nyckel, sort){
  const r = kontrollRader(sort).find(x => x.nyckel === nyckel);
  return r ? r.reglage : null;
}

/* Listan som den RITAS: kärnan och det vardagliga först, sedan rubriken
   «Avancerat» och hjälperna under den. Rubriken finns bara när det finns
   något att sätta under den — på pek gör det inte det. */
function kontrollListrader(sort){
  const alla = kontrollRader(sort);
  const ut = alla.filter(r => !r.avancerat);
  const av = alla.filter(r => r.avancerat);
  if (av.length) ut.push({ rubrik: true, vad: khT("hjalp.avancerat"), reglage: "" }, ...av);
  return ut;
}

function kontrollHjalpEl(){
  if (typeof document === "undefined") return null;
  let el = document.getElementById("kontrollhjalp");
  if (el) return el;
  el = document.createElement("div");
  el.id = "kontrollhjalp";
  el.hidden = true;
  document.body.appendChild(el);
  return el;
}

function ritaKontrollHjalp(){
  const el = kontrollHjalpEl();
  if (!el) return null;
  const rader = kontrollListrader();
  const tgb = kontrollInmatning() !== "touch";
  el.innerHTML =
    `<div class="khRubrik"></div>`
    + `<div class="khRader">` + rader.map(r =>
        `<div class="khRad${r.rubrik ? " khAvancerat" : ""}"><span class="khVad"></span>`
        + `<span class="khReglage"></span></div>`).join("")
    + `</div>`
    /* Stängknappen finns även utan tangentbord: en panel som bara går att
       stänga med H vore omöjlig att bli av med på en telefon. */
    + `<button type="button" id="khStang" class="khStang"></button>`;
  el.querySelector(".khRubrik").textContent = khT("hjalp.rubrik");
  const vadEl = el.querySelectorAll(".khVad");
  const regEl = el.querySelectorAll(".khReglage");
  rader.forEach((r, i) => {
    /* textContent, inte innerHTML: ingen sträng ska kunna bli markup. */
    vadEl[i].textContent = r.vad;
    regEl[i].textContent = r.reglage;
  });
  const kn = el.querySelector("#khStang");
  kn.textContent = tgb ? khT("hjalp.stang_tangent", "H") : khT("hjalp.stang");
  kn.addEventListener("click", () => doljKontrollHjalp());
  el.dataset.sprak = typeof SPRAKET !== "undefined" ? SPRAKET : "sv";
  return el;
}

function visaKontrollHjalp(){
  const el = ritaKontrollHjalp();
  if (!el) return false;
  el.hidden = false;
  return true;
}

function doljKontrollHjalp(){
  const el = typeof document !== "undefined"
    ? document.getElementById("kontrollhjalp") : null;
  if (el) el.hidden = true;
  return false;
}

function kontrollHjalpSynlig(){
  const el = typeof document !== "undefined"
    ? document.getElementById("kontrollhjalp") : null;
  return !!(el && !el.hidden);
}

function vaxlaKontrollHjalp(){
  return kontrollHjalpSynlig() ? doljKontrollHjalp() : visaKontrollHjalp();
}

/* Ett språkbyte medan listan står uppe skriver om den på plats. */
function kontrollHjalpSprak(){
  const el = typeof document !== "undefined" ? document.getElementById("kontrollhjalp") : null;
  if (el && !el.hidden && el.dataset.sprak !== (typeof SPRAKET !== "undefined" ? SPRAKET : "sv")) ritaKontrollHjalp();
}

/* #273 S1: listan öppnas ALDRIG av sig själv — inte heller vid första
   uppsittningen. H och panelens `?` är de enda vägarna in. */

if (typeof window !== "undefined") {
  window.KONTROLL_RADER = KONTROLL_RADER;
  window.KONTROLL_KARNA = KONTROLL_KARNA;
  window.kontrollRader = kontrollRader;
  window.kontrollRidrader = kontrollRidrader;
  window.kontrollListrader = kontrollListrader;
  window.kontrollReglageFor = kontrollReglageFor;
  window.kontrollInmatning = kontrollInmatning;
  window.visaKontrollHjalp = visaKontrollHjalp;
  window.doljKontrollHjalp = doljKontrollHjalp;
  window.vaxlaKontrollHjalp = vaxlaKontrollHjalp;
  window.kontrollHjalpSynlig = kontrollHjalpSynlig;
  window.kontrollHjalpSprak = kontrollHjalpSprak;
}
