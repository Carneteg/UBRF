/* ══════════════════════════════════════════════════════════════════
   LJUSET — alla färg- och ljusvärden för 3D-scenen på ett ställe.

   Facit är referensbilderna i references/: klar solig dag, mättade
   färger, frodig natur, mjukt ljus, stiliserad 3D. Ingen grå eller
   svart himmel någonstans, inga krossade svarta skuggor — skuggan är
   färgad och mjuk.

   Justera här, ingen annanstans. Varje värde har en kommentar om vad
   det gör så att det går att skruva utan att läsa shadern.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const LJUS={

  /* ── Klar dag: scenens normalläge ───────────────────────────── */
  dag:{
    /* Solen står högt och något bakom vänster axel, som i förlagan. */
    sol:[-0.34,0.78,0.52],
    solFarg:"#FFF4DA",        // varmt vitt solljus
    solStyrka:0.62,           // direktljusets andel
    halvskugga:0.38,          // hur långt ljuset viker runt formen

    /* Omgivningsljuset: himmel ovanifrån, grönt återsken underifrån. */
    himmel:"#A8D6F0",
    mark:"#7FA65A",
    ambient:0.74,

    /* Himlakupolen — tre steg, aldrig grått. */
    himmelTopp:"#2E7FC4",
    himmelMitt:"#6FB6E4",
    himmelBotten:"#CDE8F7",
    solskiva:"#FFF6C9", solGloria:"#FFE070",

    /* Dimman ligger långt bort och är ljusblå, inte grå. */
    dimFarg:"#C7E4F5", dimNara:120, dimFjarr:380, dimStyrka:0.80,

    /* Skuggan: färgad, mjuk, aldrig svart. */
    skuggAlfa:0.26, skuggFarg:"#3A5230", skuggMjukhet:0.075,

    /* Kontaktocklusion: mörkare nära marken, som i en riktig scen. */
    aoHojd:0.85, aoStyrka:0.22,

    /* Kantljus — tänder konturen och ger volym åt runda former. */
    kantFarg:"#FFF6D0", kant:0.20,

    /* Efterbehandling. */
    mattnad:1.10,             // höjd färgmättnad — över 1,15 blir gräset neon
    exponering:0.99,          // solen lyser redan; ingen extra uppljusning
    bloomTroskel:0.84,        // vad som räknas som ljust nog att blomma
    bloomStyrka:0.26,         // hur mycket glöden syns
  },

  /* ── Mulet: samma värld, dämpat ljus. Fortfarande blå himmel. ─ */
  mulet:{
    sol:[-0.28,0.84,0.46], solFarg:"#EDEFE8", solStyrka:0.40, halvskugga:0.52,
    himmel:"#C2D2DC", mark:"#7E9464", ambient:0.88,
    himmelTopp:"#6E93B4", himmelMitt:"#9FBCD2", himmelBotten:"#D8E4EC",
    solskiva:"#F4F2E4", solGloria:"#E8E6D4",
    dimFarg:"#D4E2EC", dimNara:80, dimFjarr:300, dimStyrka:0.85,
    skuggAlfa:0.11, skuggFarg:"#3E4A38", skuggMjukhet:0.075,
    aoHojd:0.90, aoStyrka:0.26,
    kantFarg:"#EAF2F6", kant:0.14,
    mattnad:1.08, exponering:1.02, bloomTroskel:0.86, bloomStyrka:0.18,
  },

  /* ── Regn: tyngre, men marken behåller sin gröna färg. ───────── */
  regn:{
    sol:[-0.24,0.86,0.44], solFarg:"#DCE4EA", solStyrka:0.30, halvskugga:0.58,
    himmel:"#A8BAC8", mark:"#6E8656", ambient:0.86,
    himmelTopp:"#55738E", himmelMitt:"#7C97AC", himmelBotten:"#B4C6D2",
    solskiva:"#E4EAEE", solGloria:"#D2DCE4",
    dimFarg:"#BCCEDA", dimNara:50, dimFjarr:220, dimStyrka:0.90,
    skuggAlfa:0.08, skuggFarg:"#33402E", skuggMjukhet:0.09,
    aoHojd:0.95, aoStyrka:0.28,
    kantFarg:"#DCE8F0", kant:0.12,
    mattnad:1.02, exponering:1.00, bloomTroskel:0.90, bloomStyrka:0.12,
  },

  /* ── Ridhuset invändigt: takfönstren ger ett svalt, jämnt ljus. ─ */
  ridhus:{
    sol:[0.22,0.92,0.30], solFarg:"#FFF0CE", solStyrka:0.46, halvskugga:0.50,
    himmel:"#D8DCE0", mark:"#8A7E62", ambient:0.82,
    himmelTopp:"#EDE9DE", himmelMitt:"#F2EEE4", himmelBotten:"#F6F2E8",
    solskiva:"#FFF8DC", solGloria:"#FFEFC0",
    dimFarg:"#E4DED0", dimNara:60, dimFjarr:180, dimStyrka:0.55,
    skuggAlfa:0.16, skuggFarg:"#4A3E2E", skuggMjukhet:0.05,
    aoHojd:1.10, aoStyrka:0.30,
    kantFarg:"#FFF4D8", kant:0.16,
    mattnad:1.12, exponering:1.04, bloomTroskel:0.84, bloomStyrka:0.22,
  },
};

/* ── Marken och naturen: samma palett som himlen är stämd mot. ─── */
const MARKFARG={
  gras:"#4E9B3A",          // mättat, aldrig neon
  grasMork:"#2F6E28",
  grasLjus:"#7CC456",
  sand:"#C9A263",          // varm ridbanesand som i förlagan
  sandMork:"#A8823E",
  sandLjus:"#DFC189",
  grus:"#A79881",
  tra:"#8B5A2B",
  faluro:"#9E2B22",        // UBRF:s röda byggnader
  knut:"#F2ECE0",          // vita knutar och foder
  plat:"#5E6470",
};

/* Lövverket: mättade höstfärger vid sidan av det gröna. */
const LOVFARG=["#4E9B3A","#3F8A30","#6BB84A","#D97B2A","#E8A33C","#C25A22"];

/* Vilket ljus som gäller just nu. */
function ljusFor(plats,vader){
  if(plats==="ridhus")return LJUS.ridhus;
  if(vader==="regn")return LJUS.regn;
  if(vader==="mulet")return LJUS.mulet;
  return LJUS.dag;
}

/* Hexfärg som rgba-sträng — för texturerna som målas på canvas. */
function glTonRGBA(hex,a){
  const n=parseInt(hex.slice(1),16);
  return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`;
}

/* Figurens stil: "svept" är den handbyggda kroppen, "kloss" är
   Roblox-snittet med sex rätblock. Byt här. */
let FIGURSTIL="svept";
