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

   VILKEN LÅNGSIDA SOM ÄR VILKEN avgörs av var A och C ligger, och det
   avgörs av utrymningsplanen och fotona — inte av var spelet släpper in
   folk. A ligger i SÖDER och C i NORR (se noten nedan). Sargöppningen i
   banans norra kortsida (`SPELABSTRAKTIONER.ridhus.sargport`) är en
   spelabstraktion för folk till fots och säger ingenting om A; hästen
   kommer in via hästgången och grinden i sargens ÖSTRA långsida
   (`RIDHUSINNE.sargGrind`). Står man vid A och tittar mot C har man
   västra långsidan till vänster — och på vänster sida sitter K-V-E-S-H.

   Fotobeviset för E: `IMG_0198` (se DRIVE-SOURCE-INDEX) visar E med en låg
   upphöjd träläktarnivå bakom sargen och en trappa upp till ett litet bås —
   E står alltså på läktarsidan. Med läktaren i väster enligt planen och A i
   söder hamnar E i väster, och fotot och planen säger samma sak. (Samma
   bild lästes 2026-08-30 med läktaren i öster och A i norr; det var fel —
   se noten nedan.)

   Och bildgåtorna. På UBRF sitter en liten bildskylt till vänster om
   varje bokstav — banan vid B, morot vid M, cykel vid C. Barnen lär sig
   banan på bilderna innan de lär sig bokstäverna, och det är bilderna
   man känner igen sargen på. Fyra av dem går att läsa i fotona; de
   övriga är märkta [antagande] i ridhuskortet och behöver en bild. */
/* Vända 2026-09-03: utrymningsplanen lägger C-blocket (bänkarna med de två
   trapporna, `ridhus-inne-01`) vid NORRA änden och läktaren längs VÄSTRA
   långsidan. C står alltså i norr och A i söder, och sedd från A är vänster
   sida (K–V–E–S–H) den västra — där läktaren står, precis som `IMG_0198`
   visar E mot läktaren och `-14`/`-15` visar H vid läktarens hörn. Förut
   stod A i norr och E i öster; det var en följd av att läktaren låg fel. */
const DRESSYRBOKSTAVER=[
  {b:"A",x:10,y:0,  bild:"ananas"},   // [antagande] — södra kortsidan
  {b:"C",x:10,y:60, bild:"cykel"},    // ur foto — framför C-blocket i norr
  {b:"K",x:0, y:6,  bild:"katt"},     // [antagande] — vänster sida sedd från A = väster
  {b:"V",x:0, y:18, bild:"vante"},    // [antagande]
  {b:"E",x:0, y:30, bild:"elefant"},  // [antagande] — mot läktaren, IMG_0198
  {b:"S",x:0, y:42, bild:"sol"},      // [antagande]
  {b:"H",x:0, y:54, bild:"hus"},      // [antagande] — vid läktarens hörn, ridhus-inne-14/15
  {b:"F",x:20,y:6,  bild:"fisk"},     // ur foto
  {b:"P",x:20,y:18, bild:"paron"},    // [antagande]
  {b:"B",x:20,y:30, bild:"banan"},    // ur foto
  {b:"R",x:20,y:42, bild:"ros"},      // [antagande]
  {b:"M",x:20,y:54, bild:"morot"},    // ur foto
];
