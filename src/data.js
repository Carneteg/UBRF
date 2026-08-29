/* ══════════════════════════════════════════════════════════════════
   DATA — hästarna (urval ur HorseRoster med ordagranna beskrivningar
   från ubrf.se/hastar), lektionen, banan och anläggningen.
   ══════════════════════════════════════════════════════════════════ */
const HORSES={
  toblerone:{namn:"Toblerone",typ:"ponny",kategori:"C",ras:"Fjordhäst",fodd:2007,
    besk:"Toblerone är en snäll, välutbildad och populär fjordvalack. Han har tidigare tävlat i både hoppning samt dressyr.",
    kanslighet:.35,framatbjudning:.42,forlatande:.95,skygghet:.05,hoppkapacitet:.72,hopplust:.78,
    tyngd:.62,utbildning:.90,maxhojd:.75,farg:"#C8A96B",man:"#EDE3CE",fjader:true, tecken:{blas:false, strumpor:[0,0,0,0]}, flaggor:{}},
  cosmo:{namn:"Cosmo M Z",typ:"hast",kategori:"hast",ras:"Belgiskt varmblod",fodd:2012,
    besk:"Cosmo är en snäll och okomplicerad valack som är grundutbildad i både dressyr och hoppning.",
    kanslighet:.42,framatbjudning:.50,forlatande:.80,skygghet:.15,hoppkapacitet:.72,hopplust:.75,
    tyngd:.42,utbildning:.68,maxhojd:.90,farg:"#6E4F35",man:"#3A2A1C",tecken:{blas:true, strumpor:[0,1,0,1]}, flaggor:{}},
  air:{namn:"Air Italia",typ:"hast",kategori:"hast",ras:"Danskt varmblod",fodd:2011,
    besk:"Air är en valack som kom till ridskolan 2018. Han har landat bra i verksamheten och kan gå med i alla slags grupper.",
    kanslighet:.45,framatbjudning:.50,forlatande:.72,skygghet:.20,hoppkapacitet:.60,hopplust:.65,
    tyngd:.40,utbildning:.65,maxhojd:.80,farg:"#8A6A4C",man:"#4A3826",flaggor:{}},
  larry:{namn:"Larry",typ:"hast",kategori:"hast",ras:"Irländsk Sporthäst",fodd:2016,
    besk:"En riktig ”tjejhäst”. Hoppar bra och går även bra i dressyren.",
    kanslighet:.55,framatbjudning:.58,forlatande:.70,skygghet:.18,hoppkapacitet:.80,hopplust:.80,
    tyngd:.35,utbildning:.72,maxhojd:.95,farg:"#4C3527",man:"#241812",tecken:{blas:true, strumpor:[1,0,0,1]}, flaggor:{}},
  hamilton:{namn:"Hamilton",typ:"hast",kategori:"hast",ras:"Holländskt varmblod, KWPN",fodd:2011,
    besk:"Hamilton är en arbetsvillig valack som gillar det mesta. Han är en känsligare individ.",
    kanslighet:.75,framatbjudning:.62,forlatande:.50,skygghet:.35,hoppkapacitet:.72,hopplust:.75,
    tyngd:.32,utbildning:.72,maxhojd:.90,farg:"#7A5B3E",man:"#33241A",tecken:{blas:false, strumpor:[0,0,1,1]}, flaggor:{}},
  conor:{namn:"Conor",typ:"hast",kategori:"hast",ras:"Ungerskt halvblod",fodd:2016,
    besk:"En trevlig häst som kräver en mjuk balanserad ryttare.",
    kanslighet:.88,framatbjudning:.55,forlatande:.32,skygghet:.28,hoppkapacitet:.70,hopplust:.70,
    tyngd:.22,utbildning:.70,maxhojd:.85,farg:"#5C4030",man:"#2B1E15",flaggor:{}},
  crokino:{namn:"Crokino",typ:"hast",kategori:"hast",ras:"Holländskt varmblod, KWPN",fodd:2011,
    besk:"Crokino är en större, lite känsligare häst men som är lättriden trots sin storlek. Han är rädd för spö så låt bli det när du sitter upp.",
    kanslighet:.78,framatbjudning:.52,forlatande:.55,skygghet:.42,hoppkapacitet:.68,hopplust:.62,
    tyngd:.38,utbildning:.72,maxhojd:.85,farg:"#3B2E24",man:"#1C1510",flaggor:{radd_for_spo:true}},
  lydia:{namn:"Bränntomts Lydia",typ:"ponny",kategori:"D",ras:"Connemara",fodd:2003,
    besk:"Lydia har tidigare tävlat hoppning med sin förra ryttare. Lydia är en väldigt bra barnponny.",
    kanslighet:.30,framatbjudning:.45,forlatande:.95,skygghet:.06,hoppkapacitet:.72,hopplust:.82,
    tyngd:.42,utbildning:.80,maxhojd:.75,farg:"#A9A29A",man:"#D9D4CC",fjader:true, tecken:{blas:false, strumpor:[1,1,0,0]}, flaggor:{}},
  dexter:{namn:"Dexter",typ:"ponny",kategori:"D",ras:"Import: Polen",fodd:2015,
    besk:"En ponny med lite mer fart. Duktig på att hoppa.",
    kanslighet:.60,framatbjudning:.90,forlatande:.52,skygghet:.22,hoppkapacitet:.88,hopplust:.90,
    tyngd:.18,utbildning:.62,maxhojd:1.00,farg:"#2E2A26",man:"#151311",tecken:{blas:false, strumpor:[1,0,1,0]}, flaggor:{}},
  /* Boxskyltarnas hästar ur referensfotona — beskrivna med stallets
     egna ord tills ubrf.se-texterna kan hämtas. */
  lady:{namn:"Lady",typ:"ponny",kategori:"C",ras:"Welsh Cob",fodd:2009,
    besk:"Lady är en trygg fuxponny som burit generationer av nybörjare. Hon vet var lektionen ska sluta innan du vet det.",
    kanslighet:.32,framatbjudning:.40,forlatande:.92,skygghet:.08,hoppkapacitet:.58,hopplust:.60,
    tyngd:.55,utbildning:.72,maxhojd:.70,farg:"#B0693A",man:"#7A4526",fjader:true, tecken:{blas:true, strumpor:[1,0,1,1]}, flaggor:{}},
  chip:{namn:"Chip",typ:"ponny",kategori:"B",ras:"Gotlandsruss",fodd:2013,
    besk:"Chip är liten, kvick och alldeles för smart. Äter allt som inte är fastsurrat — håll koll på foderpåsen.",
    kanslighet:.38,framatbjudning:.55,forlatande:.85,skygghet:.12,hoppkapacitet:.55,hopplust:.70,
    tyngd:.30,utbildning:.58,maxhojd:.60,farg:"#8F7351",man:"#5A452F",flaggor:{}},
  tina:{namn:"Tina",typ:"ponny",kategori:"D",ras:"New Forest",fodd:2010,
    besk:"Tina är en ordentlig lektionsponny med fin trav. Hon är kittlig — rykta med lugna drag så står hon som en klippa.",
    kanslighet:.48,framatbjudning:.46,forlatande:.74,skygghet:.15,hoppkapacitet:.62,hopplust:.66,
    tyngd:.38,utbildning:.66,maxhojd:.75,farg:"#6B4E36",man:"#3B2B1D",flaggor:{kittlig:true}},
  westside:{namn:"Westside",typ:"hast",kategori:"hast",ras:"Svenskt varmblod",fodd:2014,
    besk:"Westside är en rejäl valack som gör jobbet varje lektion. Rak, ärlig och lätt att tycka om.",
    kanslighet:.50,framatbjudning:.55,forlatande:.68,skygghet:.22,hoppkapacitet:.70,hopplust:.72,
    tyngd:.38,utbildning:.66,maxhojd:.85,farg:"#5E4531",man:"#2E2015",tecken:{blas:true, strumpor:[0,0,1,0]}, flaggor:{}},
  makadu:{namn:"Makadu",typ:"hast",kategori:"hast",ras:"Import: Irland",fodd:2012,
    besk:"Makadu är en godmodig valack med ett gammalt stallknep: han blåser upp magen när du gjordar. Vänta, och dra åt igen.",
    kanslighet:.44,framatbjudning:.48,forlatande:.75,skygghet:.16,hoppkapacitet:.66,hopplust:.70,
    tyngd:.45,utbildning:.64,maxhojd:.80,farg:"#7E5C3C",man:"#41301F",fjader:true, tecken:{blas:true, strumpor:[0,1,1,0]}, flaggor:{blaser_upp_magen:true}},
  mara:{namn:"Mara",typ:"hast",kategori:"hast",ras:"Hannoveranare",fodd:2013,
    besk:"Mara är stallets sto med egen åsikt. Sur min i boxen, guld under sadeln — döm henne inte vid boxdörren.",
    kanslighet:.58,framatbjudning:.52,forlatande:.62,skygghet:.25,hoppkapacitet:.68,hopplust:.64,
    tyngd:.36,utbildning:.68,maxhojd:.85,farg:"#4E3A2B",man:"#241A11",flaggor:{}},
  husky:{namn:"Husky",typ:"hast",kategori:"hast",ras:"Import: Polen",fodd:2015,
    besk:"Husky är en gråskimmel med spring i benen. Svårfångad i hagen — gå lugnt fram, andra försöket brukar sitta.",
    kanslighet:.46,framatbjudning:.60,forlatande:.66,skygghet:.30,hoppkapacitet:.72,hopplust:.74,
    tyngd:.34,utbildning:.60,maxhojd:.85,farg:"#9A938A",man:"#CFC9BF",flaggor:{svarfangad:true}},
  kennedy:{namn:"Kennedy",typ:"hast",kategori:"hast",ras:"Svenskt varmblod",fodd:2016,
    besk:"Kennedy är stallets unghäst, född 2016. Stort steg och stort hjärta, men allt är fortfarande på riktigt för honom.",
    kanslighet:.70,framatbjudning:.58,forlatande:.45,skygghet:.38,hoppkapacitet:.75,hopplust:.78,
    tyngd:.30,utbildning:.55,maxhojd:.90,farg:"#3F3126",man:"#1D1611",tecken:{blas:true, strumpor:[1,1,1,1]}, flaggor:{}},
};
// NPC-ryttare i lektionen (namn ur LessonDirector)
const NPC_ELEVER=[
  {namn:"Alva", hast:"lydia", skick:.62},
  {namn:"Vera", hast:"air", skick:.48},
  {namn:"Hugo", hast:"cosmo", skick:.71},
];

/* Lektion — hopplektionens moment ur LessonDirector, komprimerade för POC.
   Andelarna är samma; längden är POC-vänlig. */
const LEKTION=[
  {id:"skritt", namn:"Skritt på lång tygel", tid:26, bedoms:false,
   text:"Skritta ett varv på fyrkanten och låt honom titta sig omkring."},
  {id:"uppvarmning", namn:"Uppvärmning", tid:45, bedoms:true,
   text:"Trav på fyrkanten. Lättridning — och sitt på rätt ben (Q byter diagonal)."},
  {id:"losgorande", namn:"Lösgörande", tid:40, bedoms:true,
   text:"Stora volten vid A. Håll den rund — inre skänkel, yttre tygel."},
  {id:"galopp", namn:"Galoppfattning", tid:40, bedoms:true,
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

   Och bildgåtorna. På UBRF sitter en liten bildskylt till vänster om
   varje bokstav — banan vid B, morot vid M, cykel vid C. Barnen lär sig
   banan på bilderna innan de lär sig bokstäverna, och det är bilderna
   man känner igen sargen på. Fyra av dem går att läsa i fotona; de
   övriga är märkta [antagande] i ridhuskortet och behöver en bild. */
const DRESSYRBOKSTAVER=[
  {b:"A",x:10,y:0,  bild:"ananas"},   // [antagande]
  {b:"C",x:10,y:60, bild:"cykel"},    // ur foto
  {b:"K",x:0, y:6,  bild:"katt"},     // [antagande]
  {b:"V",x:0, y:18, bild:"vante"},    // [antagande]
  {b:"E",x:0, y:30, bild:"elefant"},  // [antagande]
  {b:"S",x:0, y:42, bild:"sol"},      // [antagande]
  {b:"H",x:0, y:54, bild:"hus"},      // [antagande]
  {b:"F",x:20,y:6,  bild:"fisk"},     // ur foto
  {b:"P",x:20,y:18, bild:"paron"},    // [antagande]
  {b:"B",x:20,y:30, bild:"banan"},    // ur foto
  {b:"R",x:20,y:42, bild:"ros"},      // [antagande]
  {b:"M",x:20,y:54, bild:"morot"},    // ur foto
];
