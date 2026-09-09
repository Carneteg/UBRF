/* KONTROLLERNA, KORT — webbens svar på "vad gör jag för att rida?"

   Tobias frågade hur man sitter upp, byter gångart och hoppar. Reglagen
   fanns bara i koden. Den här filen svarar med de reglage som FAKTISKT är
   bundna, läst ur src/game.js keydown/keyup och ur src/mobil.js
   pekknappar. Ingenting här är påhittat, och ingenting här ÄNDRAR en
   bindning: ridfysik, hjälpsemantik och hoppmodell rörs inte.

   REGLAGEN FÖLJER INMATNINGEN, inte plattformen. En ren pekenhet ska
   aldrig få en bokstav hon inte kan trycka på; en iPad med tangentbord
   ska få den. Samma regel som Roblox-sidans KontrollHjalp.luau.

   DE TVÅ RADERNA UTAN REGLAGE ÄR MENINGEN MED HELA FILEN. Webben har
   ingen gångartsknapp och inget hoppreglage — gångarten följer av skänkel
   och tygel, och avsprånget kommer ur anridningen. Att uppfinna en
   tangent för dem, eller att skriva Roblox tangenter här, vore att påstå
   en paritet som inte finns. Raderna säger i stället vad som styr dem. */

const KONTROLL_RADER = [
  /* `tgb` = tangentbord (src/game.js), `pek` = pekknapparnas EGNA
     etiketter (src/mobil.js). Tom `pek` betyder att pekgränssnittet
     saknar just det reglaget — då står `via` kvar och förklarar. */
  { vad: "Sitt upp / använd",  tgb: "E",          pek: "ANVÄND" },
  { vad: "Skänkel fram / bak", tgb: "W / S",      pek: "Spaken" },
  { vad: "Styr",               tgb: "A / D",      pek: "Spaken" },
  { vad: "Tygel (kontakt)",    tgb: "Mellanslag", pek: "TYGEL" },
  { vad: "Sits lätt / djup",   tgb: "Shift / Ctrl", pek: "LÄTT / DJUP" },
  { vad: "Halvhalt",           tgb: "E",          pek: "HALVHALT" },
  { vad: "Lättridning",        tgb: "R",          pek: "LÄTTR." },
  { vad: "Byt vy",             tgb: "V",          pek: "VY" },
  /* Utan reglage — med flit. */
  { vad: "Gångart",  tgb: "", pek: "", via: "följer skänkeln och tygeln" },
  { vad: "Hoppa",    tgb: "", pek: "", via: "avsprånget kommer ur anridningen" },
];

/* Vilken sorts inmatning talar vi om? Tangentbord vinner: en iPad med
   tangentbord ska få bokstäverna. */
function kontrollInmatning(){
  if (typeof navigator === "undefined") return "tangentbord";
  const pek = (navigator.maxTouchPoints || 0) > 0
    || (typeof window !== "undefined" && "ontouchstart" in window);
  /* En ren pekenhet har inget fint sätt att säga "jag har tangentbord".
     Vi läser samma signal som src/mobil.js använder för att bygga
     pekgränssnittet — då kan hjälpen inte säga en sak och knapparna en
     annan. */
  const baraPek = pek && !(typeof matchMedia === "function"
    && matchMedia("(hover: hover) and (pointer: fine)").matches);
  return baraPek ? "touch" : "tangentbord";
}

/* Raderna som text. Ren avläsning — inget tillstånd, inget DOM. */
function kontrollRader(){
  const sort = kontrollInmatning();
  return KONTROLL_RADER.map(r => {
    const reglage = sort === "touch" ? r.pek : r.tgb;
    return { vad: r.vad, reglage: reglage || "", via: r.via || "" };
  });
}

let kontrollVisadEnGang = false;

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
  const rader = kontrollRader();
  const tgb = kontrollInmatning() !== "touch";
  el.innerHTML =
    `<div class="khRubrik">Kontroller</div>`
    + `<div class="khRader">` + rader.map(r =>
        `<div class="khRad"><span class="khVad"></span>`
        + `<span class="khReglage"></span></div>`).join("")
    + `</div>`
    /* Stängknappen finns även utan tangentbord: en panel som bara går att
       stänga med H vore omöjlig att bli av med på en telefon. */
    + `<button type="button" id="khStang" class="khStang"></button>`;
  const vadEl = el.querySelectorAll(".khVad");
  const regEl = el.querySelectorAll(".khReglage");
  rader.forEach((r, i) => {
    /* textContent, inte innerHTML: etiketterna kommer ur den här filen,
       men regeln gäller ändå — ingen sträng ska kunna bli markup. */
    vadEl[i].textContent = r.vad;
    regEl[i].textContent = r.reglage || (r.via ? "— " + r.via : "—");
  });
  const kn = el.querySelector("#khStang");
  kn.textContent = tgb ? "Stäng  (H)" : "Stäng";
  kn.addEventListener("click", () => doljKontrollHjalp());
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

/* Första uppsittningen: visa reglagen en gång, av sig själv. Då är frågan
   "vad gör jag nu?" som mest aktuell. Vid varje uppsittning hade det
   blivit en ruta att stänga bort, inte en hjälp. */
function kontrollHjalpVidUppsittning(){
  if (kontrollVisadEnGang) return false;
  kontrollVisadEnGang = true;
  return visaKontrollHjalp();
}

if (typeof window !== "undefined") {
  window.KONTROLL_RADER = KONTROLL_RADER;
  window.kontrollRader = kontrollRader;
  window.kontrollInmatning = kontrollInmatning;
  window.visaKontrollHjalp = visaKontrollHjalp;
  window.doljKontrollHjalp = doljKontrollHjalp;
  window.vaxlaKontrollHjalp = vaxlaKontrollHjalp;
  window.kontrollHjalpSynlig = kontrollHjalpSynlig;
  window.kontrollHjalpVidUppsittning = kontrollHjalpVidUppsittning;
}
