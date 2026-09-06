/* ══════════════════════════════════════════════════════════════════
   HÄSTARNA — kanonisk speldata, delad mellan webben och Roblox.

   Verklighetsfakta kommer från den versionssparade snapshoten
   references/data/ubrf-hastar-2026-09-01.json, hämtad från Supabase
   public.hastar (upstream: ubrf.se/hastar). `kallaId`, namn, typ,
   födelseår, ras, mankhöjd, import, kategoriKalla och `besk` är källdata.

   `kategori` är däremot modellens storleksnyckel. Hästar använder `hast`.
   Ponnyer använder verifierad A–D där den finns. Dantes kategori saknas
   i källan; C används därför bara som tydligt märkt spelantagande.

   0–1-parametrar, hinderhöjd och färger är spelvärden/presentation, inte
   fakta om de verkliga djuren. Nio befintliga id:n behåller sina äldre
   värden för game-feel/savestabilitet. Nya hästar börjar neutralt UNTUNED.
   ══════════════════════════════════════════════════════════════════ */

const HASTFAKTA=[
  {id:"air",kallaId:"air-italia",namn:"Air Italia",typ:"hast",fodd:2011,ras:"Danskt varmblod",mankhojd:165,import:null,kategoriKalla:null,besk:"Air är en valack som kom till ridskolan 2018. Han har landat bra i verksamheten och kan gå med i alla slags grupper."},
  {id:"allan",kallaId:"allan",namn:"Allan",typ:"hast",fodd:2015,ras:"Svenskt varmblod",mankhojd:178,import:null,kategoriKalla:null,besk:"Allan är en trevlig valack som går bra i både hoppning och dressyr."},
  {id:"berra",kallaId:"berra-irco-mencoboy",namn:"BERRA (Irco MencoBoy)",typ:"hast",fodd:2016,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"Hoppar jättefint. Även trevlig i dressyren. Har ett lite skarpare temperament i stallet."},
  {id:"bing",kallaId:"bing",namn:"Bing",typ:"hast",fodd:2006,ras:"Holländskt varmblod, KWPN",mankhojd:166,import:null,kategoriKalla:null,besk:"Bing är en valack med fin gång men som inte hoppar. Han har startat LB/LA i dressyr."},
  {id:"conor",kallaId:"conor",namn:"Conor",typ:"hast",fodd:2016,ras:"Ungerskt halvblod",mankhojd:165,import:null,kategoriKalla:null,besk:"En trevlig häst som kräver en mjuk balanserad ryttare."},
  {id:"cosmo",kallaId:"cosmo-m-z",namn:"Cosmo M Z",typ:"hast",fodd:2012,ras:"Belgiskt varmblod, Zangersheide",mankhojd:170,import:null,kategoriKalla:null,besk:"Cosmo är en snäll och okomplicerad valack som är grundutbildad i både dressyr och hoppning."},
  {id:"crokino",kallaId:"crokino",namn:"Crokino",typ:"hast",fodd:2011,ras:"Holländskt varmblod. KWPN",mankhojd:177,import:null,kategoriKalla:null,besk:"Crokino är en större, lite känsligare häst men som är lättriden trots sin storlek. Han är rädd för spö så låt bli det när du sitter upp."},
  {id:"curiretto",kallaId:"curiretto",namn:"Curiretto",typ:"hast",fodd:2006,ras:"Svenskt varmblod, SWB",mankhojd:null,import:null,kategoriKalla:null,besk:"Curre är en äldre gentleman som tidigare tävlat hoppning. Har även tävlat en del dressyr. Lite åt det tyngre hållet."},
  {id:"fay",kallaId:"fay",namn:"Fay",typ:"hast",fodd:2018,ras:null,mankhojd:null,import:"Irland",kategoriKalla:null,besk:"Mer info kommer."},
  {id:"hjartat",kallaId:"guipsy-hjartat",namn:"Guipsy / \"Hjärtat\"",typ:"hast",fodd:2010,ras:"Freiberger",mankhojd:null,import:null,kategoriKalla:null,besk:"Hjärtat är en häst med positiv inställning till arbetet. Alltid ambitiös. Ska inte hoppa så mycket längre."},
  {id:"hamilton",kallaId:"hamilton",namn:"Hamilton",typ:"hast",fodd:2011,ras:"Holländskt varmblod. KWPN",mankhojd:169,import:null,kategoriKalla:null,besk:"Hamilton är en arbetsvillig valack som gillar det mesta. Han är en känsligare individ."},
  {id:"kay_z",kallaId:"kay-z",namn:"Kay z",typ:"hast",fodd:2014,ras:"Belgiskt varmblod, Zangersheide",mankhojd:null,import:null,kategoriKalla:null,besk:"En allroundhäst av den större modellen. Går både hoppning och dressyr."},
  {id:"larry",kallaId:"larry",namn:"Larry",typ:"hast",fodd:2016,ras:"Irländsk Sporthäst",mankhojd:null,import:"Irland",kategoriKalla:null,besk:"En riktig \"tjejhäst\". Hoppar bra och går även bra i dressyren."},
  {id:"lothar",kallaId:"lothar-s-eagle",namn:"Lothar's eagle",typ:"hast",fodd:2017,ras:null,mankhojd:null,import:"Irland",kategoriKalla:null,besk:"En gudomligt snäll häst som kan gå med på alla typer av lektioner."},
  {id:"oska",kallaId:"oska",namn:"Oska",typ:"hast",fodd:2018,ras:null,mankhojd:163,import:"Irland",kategoriKalla:null,besk:"Snäll, bussig häst som slussas in i verksamheten samtidigt som han utbildas vidare."},
  {id:"puma",kallaId:"puma-ashdale-cougar",namn:"Puma ( Ashdale cougar )",typ:"hast",fodd:2019,ras:"Irländsk Sporthäst",mankhojd:164,import:"Irland",kategoriKalla:null,besk:"Puma är ett ädlare sto som ska sättas igång, utbildas och slussas in i verksamheten. Mer info kommer."},
  {id:"sune",kallaId:"sune",namn:"Sune",typ:"hast",fodd:2018,ras:"Irländsk Sporthäst",mankhojd:166,import:"Irland",kategoriKalla:null,besk:"Mer info kommer."},
  {id:"tess",kallaId:"tess",namn:"Tess",typ:"hast",fodd:2019,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"Tess är hos Petra & Mira på utbildning."},
  {id:"blackrock_jack",kallaId:"blackrock-jack",namn:"Blackrock Jack",typ:"ponny",fodd:2011,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Jack är en valack som är importerad från Irland. Han är en lite känsligare ponny och han är populär. Han hoppar trevligt. Har även tävlat lite dressyr."},
  {id:"lydia",kallaId:"branntomts-lydia",namn:"Bränntomts Lydia",typ:"ponny",fodd:2003,ras:"Connemara",mankhojd:null,import:null,kategoriKalla:"D",besk:"Lydia har tidigare tävlat hoppning med sin förra ryttare. Lydia är en väldigt bra barnponny."},
  {id:"dante",kallaId:"dante",namn:"Dante",typ:"ponny",fodd:null,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"En ung ponny som är under utbildning. Slussas försiktigt in i verksamheten. Snäll men lite försiktig i all hantering."},
  {id:"dexter",kallaId:"dexter",namn:"Dexter",typ:"ponny",fodd:2015,ras:null,mankhojd:null,import:"Polen",kategoriKalla:"D",besk:"En ponny med lite mer fart. Duktig på att hoppa."},
  {id:"garnit",kallaId:"garnit-parasido",namn:"Garnit Parasido",typ:"ponny",fodd:2007,ras:"New Forest",mankhojd:null,import:"Holland",kategoriKalla:"C",besk:"Garanit är en söt valack importerad från Holland. Han hoppar bra."},
  {id:"jessy",kallaId:"jessy",namn:"Jessy",typ:"ponny",fodd:2015,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"En snäll ponny som ännu så länge är ny i verksamheten. Är mest riden i skog och mark tidigare. Utbildas vidare här på ridskolan."},
  {id:"kennedy",kallaId:"kennedy",namn:"Kennedy",typ:"ponny",fodd:2019,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Mer info kommer."},
  {id:"lady",kallaId:"lady",namn:"Lady",typ:"ponny",fodd:2011,ras:"Connemara",mankhojd:null,import:null,kategoriKalla:"D",besk:"Ett sto med lite integritet. Mjuk och behaglig i sina rörelser. Allroundponny."},
  {id:"mac_kenzie",kallaId:"mac-kenzie",namn:"Mac Kenzie",typ:"ponny",fodd:2002,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Mac Kenzie är en fin, snäll gentleman som dock är lite försiktig i hoppningen."},
  {id:"marabou",kallaId:"marabou",namn:"Marabou",typ:"ponny",fodd:2007,ras:"Svensk Ridponny",mankhojd:null,import:null,kategoriKalla:"B",besk:"Marabou är en arbetsvillig liten valack som hoppar fint. Har tävlat mycket dressyr med tidigare ryttare."},
  {id:"replay",kallaId:"replay",namn:"Replay",typ:"ponny",fodd:2012,ras:"Connemara",mankhojd:null,import:"Irland",kategoriKalla:"D",besk:"Mjuk ponny som hoppar med bra teknik men är lite försiktig. Kräver sin ryttare för att jobba bra."},
  {id:"toblerone",kallaId:"toblerone",namn:"Toblerone",typ:"ponny",fodd:2007,ras:"Fjordhäst",mankhojd:null,import:null,kategoriKalla:"C",besk:"Toblerone är en snäll, välutbildad och populär fjordvalack. Han kom till ridskolan i augusti 2014 och har tidigare tävlat i både hoppning samt dressyr."},
  {id:"trixie",kallaId:"trixie",namn:"Trixie",typ:"ponny",fodd:2007,ras:"Connemara",mankhojd:null,import:"Irland",kategoriKalla:"D",besk:"Trixie är väldigt snäll men lite känslig. Hon går på alla slags lektioner. Hon kramas gärna i stallet."},
  {id:"troy",kallaId:"troy",namn:"Troy",typ:"ponny",fodd:2016,ras:null,mankhojd:null,import:"Irland",kategoriKalla:"C",besk:"Välriden ponny som kan \"lite av varje\". Vill inte alltid bli fångad i hagen."},
  {id:"westside",kallaId:"westside",namn:"Westside",typ:"ponny",fodd:2009,ras:"Haflinger",mankhojd:null,import:"Holland",kategoriKalla:"C",besk:"Westside är en snäll valack. Han kräver sin ryttare."},
];

const BAS_GAMEPLAY={kanslighet:.50,framatbjudning:.50,forlatande:.60,skygghet:.20,
  hoppkapacitet:.60,hopplust:.60,tyngd:.40,utbildning:.60,maxhojd:.80,
  farg:"#72533B",man:"#2F2118"};

const LEGACY_GAMEPLAY={
  toblerone:{kanslighet:.35,framatbjudning:.42,forlatande:.95,skygghet:.05,hoppkapacitet:.72,hopplust:.78,tyngd:.62,utbildning:.90,maxhojd:.75,farg:"#C8A96B",man:"#EDE3CE",fjader:true,tecken:{blas:false,strumpor:[0,0,0,0]}},
  cosmo:{kanslighet:.42,framatbjudning:.50,forlatande:.80,skygghet:.15,hoppkapacitet:.72,hopplust:.75,tyngd:.42,utbildning:.68,maxhojd:.90,farg:"#6E4F35",man:"#3A2A1C",tecken:{blas:true,strumpor:[0,1,0,1]}},
  air:{kanslighet:.45,framatbjudning:.50,forlatande:.72,skygghet:.20,hoppkapacitet:.60,hopplust:.65,tyngd:.40,utbildning:.65,maxhojd:.80,farg:"#8A6A4C",man:"#4A3826"},
  larry:{kanslighet:.55,framatbjudning:.58,forlatande:.70,skygghet:.18,hoppkapacitet:.80,hopplust:.80,tyngd:.35,utbildning:.72,maxhojd:.95,farg:"#4C3527",man:"#241812",tecken:{blas:true,strumpor:[1,0,0,1]}},
  hamilton:{kanslighet:.75,framatbjudning:.62,forlatande:.50,skygghet:.35,hoppkapacitet:.72,hopplust:.75,tyngd:.32,utbildning:.72,maxhojd:.90,farg:"#7A5B3E",man:"#33241A",tecken:{blas:false,strumpor:[0,0,1,1]}},
  conor:{kanslighet:.88,framatbjudning:.55,forlatande:.32,skygghet:.28,hoppkapacitet:.70,hopplust:.70,tyngd:.22,utbildning:.70,maxhojd:.85,farg:"#5C4030",man:"#2B1E15"},
  crokino:{kanslighet:.78,framatbjudning:.52,forlatande:.55,skygghet:.42,hoppkapacitet:.68,hopplust:.62,tyngd:.38,utbildning:.72,maxhojd:.85,farg:"#3B2E24",man:"#1C1510",flaggor:{radd_for_spo:true}},
  lydia:{kanslighet:.30,framatbjudning:.45,forlatande:.95,skygghet:.06,hoppkapacitet:.72,hopplust:.82,tyngd:.42,utbildning:.80,maxhojd:.75,farg:"#A9A29A",man:"#D9D4CC",fjader:true,tecken:{blas:false,strumpor:[1,1,0,0]}},
  dexter:{kanslighet:.60,framatbjudning:.90,forlatande:.52,skygghet:.22,hoppkapacitet:.88,hopplust:.90,tyngd:.18,utbildning:.62,maxhojd:1.00,farg:"#2E2A26",man:"#151311",tecken:{blas:false,strumpor:[1,0,1,0]}},
};

const SOURCE_GAMEPLAY={
  // Källan säger att Bing inte hoppar. Den säger inget om hans motivation.
  bing:{hoppkapacitet:0,flaggor:{hoppar_inte:true}},
};

/* ══════════════════════════════════════════════════════════════════
   SKOLHÄSTPROFILER (G02-B punkt 3, issue #83)

   Profilen säger HUR hästen svarar — fördröjning, hur mycket hon bryr
   sig om att hjälpen är tydlig, hur lätt hon tappar balansen, hur
   mycket hon orkar. Talen ligger i SKOLHAST_PROFILER i
   src/riding/svar.js; här står bara vem som är vad, och VARFÖR.

   KÄLLAN ÄR RIDSKOLANS EGNA BESKRIVNINGAR, ordagrant i `besk` ovan och
   i snapshoten references/data/ubrf-hastar-2026-09-01.json. Citatet
   står i kommentaren på varje rad. En häst vars beskrivning inte säger
   något om ridkänsla står INTE här: hon får `skolhast`, som är
   modellens utgångsläge, och det är en deklarerad frånvaro av evidens
   och inte en gissning.

   Att lägga till en rad här kräver alltså en mening ur källan. Att
   flytta en häst mellan profiler för att en mätning ser bättre ut vore
   att låta koden bli facit åt verkligheten. ── */
const PROFIL={
  /* KÄNSLIG — källan säger uttryckligen känslig eller kräsen. */
  crokino:"kanslig",        // "en större, lite känsligare häst men som är lättriden"
  hamilton:"kanslig",       // "Han är en känsligare individ."
  conor:"kanslig",          // "En trevlig häst som kräver en mjuk balanserad ryttare."
  trixie:"kanslig",         // "väldigt snäll men lite känslig"
  blackrock_jack:"kanslig", // "en lite känsligare ponny"
  dante:"kanslig",          // "Snäll men lite försiktig i all hantering."

  /* TYNGRE MODELL — källan säger tyngre, äldre eller "kräver sin
     ryttare" i betydelsen att hon måste ridas fram. */
  curiretto:"tung",         // "En äldre gentleman ... Lite åt det tyngre hållet."
  westside:"tung",          // "Han kräver sin ryttare."
  replay:"tung",            // "Kräver sin ryttare för att jobba bra."
  toblerone:"tung",         // fjordvalack, "snäll, välutbildad och populär"
  kay_z:"tung",             // "En allroundhäst av den större modellen."
  mac_kenzie:"tung",        // född 2002 — "en fin, snäll gentleman"

  /* ARBETSVILLIG — källan säger arbetsvillig, ambitiös eller framåt. */
  hjartat:"arbetsvillig",   // "positiv inställning till arbetet. Alltid ambitiös."
  marabou:"arbetsvillig",   // "en arbetsvillig liten valack"
  dexter:"arbetsvillig",    // "En ponny med lite mer fart."
  allan:"arbetsvillig",     // "en trevlig valack som går bra i både hoppning och dressyr"
};

const HORSES={};
for(const fakta of HASTFAKTA){
  const legacy=LEGACY_GAMEPLAY[fakta.id];
  const source=SOURCE_GAMEPLAY[fakta.id];
  HORSES[fakta.id]={
    ...fakta,
    kategori:fakta.typ==="hast"?"hast":(fakta.kategoriKalla||"C"),
    kategoriStatus:fakta.typ==="hast"?"MODEL":(fakta.kategoriKalla?"VERIFIED":"ASSUMPTION"),
    ...BAS_GAMEPLAY,
    ...(legacy||{}),
    ...(source||{}),
    flaggor:{...((legacy&&legacy.flaggor)||{}),...((source&&source.flaggor)||{})},
    gameplayStatus:source?"SOURCE_RULE":legacy?"LEGACY_TUNED":"UNTUNED",
    /* Profilen och varifrån den kommer. `skolhast` utan källa är en
       DEKLARERAD frånvaro av evidens, inte en tilldelning. */
    profil:PROFIL[fakta.id]||"skolhast",
    profilStatus:PROFIL[fakta.id]?"KALLTEXT":"SAKNAR_KALLA",
    visuellStatus:"ASSUMPTION",
  };
}

/* Foder är tills vidare en SPELÖVNING, inte verifierade individuella
   UBRF-givor. Den gamla filen kallade påhittade kg/notiser "ur verkligheten".
   Det var fel. UI:t ska alltid tala om att detta är övningsvärden. */
const FODER_LEGACY={
  air:{ho:2,kraft:"betfor"},
  cosmo:{ho:3,kraft:"müsli"},
  larry:{ho:3,kraft:"müsli"},
  hamilton:{ho:2,kraft:"müsli"},
  conor:{ho:2,kraft:"betfor"},
  crokino:{ho:3,kraft:"pellets"},
  lydia:{ho:2,kraft:"inget"},
  dexter:{ho:2,kraft:"pellets"},
  lady:{ho:2,kraft:"inget"},
  westside:{ho:3,kraft:"pellets"},
  kennedy:{ho:2,kraft:"müsli"},
  toblerone:{ho:2,kraft:"inget"},
};
const FODERSCHEMA={};
for(const id of Object.keys(HORSES)){
  const v=FODER_LEGACY[id]||{ho:2,kraft:"inget"};
  FODERSCHEMA[id]={...v,status:"ASSUMPTION",
    notis:"Övningsvärde i spelet — verklig UBRF-giva är inte verifierad."};
}
const KRAFTVAL=["inget","müsli","betfor","pellets"];
