/* ══════════════════════════════════════════════════════════════════
   DATA — hästarna (urval ur HorseRoster med ordagranna beskrivningar
   från ubrf.se/hastar), lektionen, banan och anläggningen.
   ══════════════════════════════════════════════════════════════════ */
/* HORSES bor nu i src/spel/hastar.js — delad med Roblox. */
// NPC-ryttare i lektionen (namn ur LessonDirector)
const NPC_ELEVER=[
  {namn:"Alva", hast:"lydia", skick:.62},
  {namn:"Vera", hast:"air", skick:.48},
  {namn:"Hugo", hast:"cosmo", skick:.71},
];

/* Lektion — hopplektionens moment ur LessonDirector, komprimerade för POC.
   Andelarna är samma; längden är POC-vänlig. */
const LEKTION=[
  {id:"skritt", namn:"Skritt på lång tygel", tid:26, bedoms:false, gangart:"skritt",
   text:"Skritta ett varv på fyrkanten och låt honom titta sig omkring."},
  {id:"uppvarmning", namn:"Uppvärmning", tid:45, bedoms:true, gangart:"trav",
   text:"Trav på fyrkanten. Lättridning — och sitt på rätt ben (Q byter diagonal)."},
  {id:"losgorande", namn:"Lösgörande", tid:40, bedoms:true, gangart:"trav",
   text:"Stora volten vid A. Håll den rund — inre skänkel, yttre tygel."},
  {id:"galopp", namn:"Galoppfattning", tid:40, bedoms:true, gangart:"galopp",
   text:"Fatta galopp i hörnet. Lätt sits (Shift) om det rusar."},
  {id:"bana", namn:"Banan", tid:0, bedoms:true,
   text:"Nu hela banan — sex hinder, 60 cm. Rid vägen, inte hindret."},
];

/* Banan — 6 hinder i ridhuset (20 × 60 m), Påskhoppet Klass 2-höjder.
   Avstånd enligt banbyggarreglerna: hinder 1 mot ingången, inga
   avstånd under fem galoppsprång, minst 15 m från kortsidan. */
const BANA={
  hojd:0.60,
  hinder:[
    {nr:1,x:10,y:44,rot:Math.PI,   typ:"rattupp"},
    {nr:2,x:5.5,y:22,rot:Math.PI,  typ:"rattupp"},
    {nr:3,x:10,y:9,rot:Math.PI/2,  typ:"oxer"},
    {nr:4,x:14.5,y:24,rot:0,       typ:"rattupp"},
    {nr:5,x:14.5,y:45,rot:0,       typ:"rattupp"},
    {nr:6,x:10,y:30,rot:-Math.PI/2+0.35, typ:"oxer"},
  ],
};

/* Anläggningen — ur anläggningsskisserna (ubrf.se/tavling) och
   forening-sidan: ridhus 20×60 med läktare, stall intill, uteridbana
   36×80, fyra rasthagar, framridning, infart från Husbyvägen. */
const SITE={
  ridhus:{x:0,y:0,w:20,h:60},           // interiör-koordinater används i spelet
  stall:{x:24,y:6,w:14,h:42, label:"STALL"},
  sadelkammare:{x:24,y:48,w:8,h:8, label:"SADELKAMMARE"},
  cafe:{x:33,y:48,w:6,h:8, label:"CAFÉ"},
  utebana:{x:-44,y:8,w:36,h:80, label:"UTERIDBANA 36×80"},
  hagar:[{x:44,y:0,w:20,h:14},{x:44,y:16,w:20,h:14},{x:44,y:32,w:20,h:14},{x:44,y:48,w:20,h:14}],
  framridning:{x:-18,y:-16,w:16,h:12, label:"FRAMRIDNING"},
};

/* Dressyrbokstäverna på en 20×60-bana. A och C på kortsidorna,
   K-V-E-S-H på ena långsidan och F-P-B-R-M på den andra, med sex meter
   till första bokstaven och tolv meter mellan resten.

   VILKEN LÅNGSIDA SOM ÄR VILKEN avgörs av var A ligger, och A ligger där
   man rider in. Sargporten sitter i banans NORRA kortsida (RIDHUSINNE.port
   och sargen i v3dRidhus), alltså är den kortsidan A. Rider man in vid A
   och tittar mot C har man östra långsidan till vänster — och på vänster
   sida sitter K-V-E-S-H.

   Det spelade roll. Fram till 2026-08-30 låg A vid södra kortsidan medan
   porten låg i norr, så bokstäverna hamnade spegelvända: E låg mot
   sponsorväggen i väster, där det bara finns 0,6 m bakom sargen. Verifierat
   Drive-material (`IMG_0198`, se DRIVE-SOURCE-INDEX) visar E med en låg
   upphöjd träläktarnivå bakom sargen och en trappa upp till ett litet bås.
   Det utrymmet finns bara på läktarsidan i öster. Med A vid porten hamnar E
   där, och fotot och planen säger samma sak.

   Och bildgåtorna. På UBRF sitter en liten bildskylt till vänster om
   varje bokstav — banan vid B, morot vid M, cykel vid C. Barnen lär sig
   banan på bilderna innan de lär sig bokstäverna, och det är bilderna
   man känner igen sargen på. Fyra av dem går att läsa i fotona; de
   övriga är märkta [antagande] i ridhuskortet och behöver en bild. */
const DRESSYRBOKSTAVER=[
  {b:"A",x:10,y:60, bild:"ananas"},   // [antagande] — vid sargporten i norr
  {b:"C",x:10,y:0,  bild:"cykel"},    // ur foto
  {b:"K",x:20,y:54, bild:"katt"},     // [antagande] — vänster sida sedd från A
  {b:"V",x:20,y:42, bild:"vante"},    // [antagande]
  {b:"E",x:20,y:30, bild:"elefant"},  // [antagande] — mot läktaren, IMG_0198
  {b:"S",x:20,y:18, bild:"sol"},      // [antagande]
  {b:"H",x:20,y:6,  bild:"hus"},      // [antagande]
  {b:"F",x:0, y:54, bild:"fisk"},     // ur foto
  {b:"P",x:0, y:42, bild:"paron"},    // [antagande]
  {b:"B",x:0, y:30, bild:"banan"},    // ur foto
  {b:"R",x:0, y:18, bild:"ros"},      // [antagande]
  {b:"M",x:0, y:6,  bild:"morot"},    // ur foto
];
