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
  {id:"air",kallaId:"air-italia",namn:"Air Italia",typ:"hast",fodd:2011,ras:"Danskt varmblod",mankhojd:165,import:null,kategoriKalla:null,besk:"Air är en valack som kom till ridskolan 2018. Han har landat bra i verksamheten och kan gå med i alla slags grupper.",beskEn:"Air is a gelding who came to the riding school in 2018. He has settled in well and can join any kind of group."},
  {id:"allan",kallaId:"allan",namn:"Allan",typ:"hast",fodd:2015,ras:"Svenskt varmblod",mankhojd:178,import:null,kategoriKalla:null,besk:"Allan är en trevlig valack som går bra i både hoppning och dressyr.",beskEn:"Allan is a pleasant gelding who goes well in both jumping and dressage."},
  {id:"berra",kallaId:"berra-irco-mencoboy",namn:"BERRA (Irco MencoBoy)",typ:"hast",fodd:2016,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"Hoppar jättefint. Även trevlig i dressyren. Har ett lite skarpare temperament i stallet.",beskEn:"Jumps beautifully. Pleasant in dressage too. Has a slightly sharper temperament in the stable."},
  {id:"bing",kallaId:"bing",namn:"Bing",typ:"hast",fodd:2006,ras:"Holländskt varmblod, KWPN",mankhojd:166,import:null,kategoriKalla:null,besk:"Bing är en valack med fin gång men som inte hoppar. Han har startat LB/LA i dressyr.",beskEn:"Bing is a gelding with lovely paces who does not jump. He has competed at LB/LA level in dressage."},
  {id:"conor",kallaId:"conor",namn:"Conor",typ:"hast",fodd:2016,ras:"Ungerskt halvblod",mankhojd:165,import:null,kategoriKalla:null,besk:"En trevlig häst som kräver en mjuk balanserad ryttare.",beskEn:"A pleasant horse who needs a soft, balanced rider."},
  {id:"cosmo",kallaId:"cosmo-m-z",namn:"Cosmo M Z",typ:"hast",fodd:2012,ras:"Belgiskt varmblod, Zangersheide",mankhojd:170,import:null,kategoriKalla:null,besk:"Cosmo är en snäll och okomplicerad valack som är grundutbildad i både dressyr och hoppning.",beskEn:"Cosmo is a kind, uncomplicated gelding with basic schooling in both dressage and jumping."},
  {id:"crokino",kallaId:"crokino",namn:"Crokino",typ:"hast",fodd:2011,ras:"Holländskt varmblod. KWPN",mankhojd:177,import:null,kategoriKalla:null,besk:"Crokino är en större, lite känsligare häst men som är lättriden trots sin storlek. Han är rädd för spö så låt bli det när du sitter upp.",beskEn:"Crokino is a bigger, slightly more sensitive horse, but easy to ride despite his size. He is afraid of the whip, so leave it alone when you are riding him."},
  {id:"curiretto",kallaId:"curiretto",namn:"Curiretto",typ:"hast",fodd:2006,ras:"Svenskt varmblod, SWB",mankhojd:null,import:null,kategoriKalla:null,besk:"Curre är en äldre gentleman som tidigare tävlat hoppning. Har även tävlat en del dressyr. Lite åt det tyngre hållet.",beskEn:"Curre is an older gentleman who used to compete in jumping. He has also done some dressage. A little on the heavier side."},
  {id:"fay",kallaId:"fay",namn:"Fay",typ:"hast",fodd:2018,ras:null,mankhojd:null,import:"Irland",kategoriKalla:null,besk:"Mer info kommer.",beskEn:"More information to come."},
  {id:"hjartat",kallaId:"guipsy-hjartat",namn:"Guipsy / \"Hjärtat\"",typ:"hast",fodd:2010,ras:"Freiberger",mankhojd:null,import:null,kategoriKalla:null,besk:"Hjärtat är en häst med positiv inställning till arbetet. Alltid ambitiös. Ska inte hoppa så mycket längre.",beskEn:"Hjärtat is a horse with a positive attitude to work. Always willing. Should not jump much any more."},
  {id:"hamilton",kallaId:"hamilton",namn:"Hamilton",typ:"hast",fodd:2011,ras:"Holländskt varmblod. KWPN",mankhojd:169,import:null,kategoriKalla:null,besk:"Hamilton är en arbetsvillig valack som gillar det mesta. Han är en känsligare individ.",beskEn:"Hamilton is a willing gelding who likes most things. He is one of the more sensitive ones."},
  {id:"kay_z",kallaId:"kay-z",namn:"Kay z",typ:"hast",fodd:2014,ras:"Belgiskt varmblod, Zangersheide",mankhojd:null,import:null,kategoriKalla:null,besk:"En allroundhäst av den större modellen. Går både hoppning och dressyr.",beskEn:"An all-rounder of the larger sort. Goes both jumping and dressage."},
  {id:"larry",kallaId:"larry",namn:"Larry",typ:"hast",fodd:2016,ras:"Irländsk Sporthäst",mankhojd:null,import:"Irland",kategoriKalla:null,besk:"En riktig \"tjejhäst\". Hoppar bra och går även bra i dressyren.",beskEn:"A real \"girls' horse\". Jumps well and goes well in dressage too."},
  {id:"lothar",kallaId:"lothar-s-eagle",namn:"Lothar's eagle",typ:"hast",fodd:2017,ras:null,mankhojd:null,import:"Irland",kategoriKalla:null,besk:"En gudomligt snäll häst som kan gå med på alla typer av lektioner.",beskEn:"A wonderfully kind horse who can join any type of lesson."},
  {id:"oska",kallaId:"oska",namn:"Oska",typ:"hast",fodd:2018,ras:null,mankhojd:163,import:"Irland",kategoriKalla:null,besk:"Snäll, bussig häst som slussas in i verksamheten samtidigt som han utbildas vidare.",beskEn:"A kind, good-natured horse who is being eased into the school's work while his schooling continues."},
  {id:"puma",kallaId:"puma-ashdale-cougar",namn:"Puma ( Ashdale cougar )",typ:"hast",fodd:2019,ras:"Irländsk Sporthäst",mankhojd:164,import:"Irland",kategoriKalla:null,besk:"Puma är ett ädlare sto som ska sättas igång, utbildas och slussas in i verksamheten. Mer info kommer.",beskEn:"Puma is a finer-bred mare who is to be started, schooled and eased into the school's work. More information to come."},
  {id:"sune",kallaId:"sune",namn:"Sune",typ:"hast",fodd:2018,ras:"Irländsk Sporthäst",mankhojd:166,import:"Irland",kategoriKalla:null,besk:"Mer info kommer.",beskEn:"More information to come."},
  {id:"tess",kallaId:"tess",namn:"Tess",typ:"hast",fodd:2019,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"Tess är hos Petra & Mira på utbildning.",beskEn:"Tess is away with Petra & Mira for schooling."},
  {id:"blackrock_jack",kallaId:"blackrock-jack",namn:"Blackrock Jack",typ:"ponny",fodd:2011,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Jack är en valack som är importerad från Irland. Han är en lite känsligare ponny och han är populär. Han hoppar trevligt. Har även tävlat lite dressyr.",beskEn:"Jack is a gelding imported from Ireland. He is one of the more sensitive ponies, and a popular one. He jumps nicely. He has also competed a little in dressage."},
  {id:"lydia",kallaId:"branntomts-lydia",namn:"Bränntomts Lydia",typ:"ponny",fodd:2003,ras:"Connemara",mankhojd:null,import:null,kategoriKalla:"D",besk:"Lydia har tidigare tävlat hoppning med sin förra ryttare. Lydia är en väldigt bra barnponny.",beskEn:"Lydia used to compete in jumping with her previous rider. Lydia is a very good children's pony."},
  {id:"dante",kallaId:"dante",namn:"Dante",typ:"ponny",fodd:null,ras:null,mankhojd:null,import:null,kategoriKalla:null,besk:"En ung ponny som är under utbildning. Slussas försiktigt in i verksamheten. Snäll men lite försiktig i all hantering.",beskEn:"A young pony still being schooled. Being eased carefully into the school's work. Kind, but a little wary of being handled."},
  {id:"dexter",kallaId:"dexter",namn:"Dexter",typ:"ponny",fodd:2015,ras:null,mankhojd:null,import:"Polen",kategoriKalla:"D",besk:"En ponny med lite mer fart. Duktig på att hoppa.",beskEn:"A pony with a bit more go. Good at jumping."},
  {id:"garnit",kallaId:"garnit-parasido",namn:"Garnit Parasido",typ:"ponny",fodd:2007,ras:"New Forest",mankhojd:null,import:"Holland",kategoriKalla:"C",besk:"Garanit är en söt valack importerad från Holland. Han hoppar bra.",beskEn:"Garanit is a sweet gelding imported from the Netherlands. He jumps well."},
  {id:"jessy",kallaId:"jessy",namn:"Jessy",typ:"ponny",fodd:2015,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"En snäll ponny som ännu så länge är ny i verksamheten. Är mest riden i skog och mark tidigare. Utbildas vidare här på ridskolan.",beskEn:"A kind pony who is still new to the school's work. Has mostly been ridden out in the woods and fields before. Her schooling continues here at the riding school."},
  {id:"kennedy",kallaId:"kennedy",namn:"Kennedy",typ:"ponny",fodd:2019,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Mer info kommer.",beskEn:"More information to come."},
  {id:"lady",kallaId:"lady",namn:"Lady",typ:"ponny",fodd:2011,ras:"Connemara",mankhojd:null,import:null,kategoriKalla:"D",besk:"Ett sto med lite integritet. Mjuk och behaglig i sina rörelser. Allroundponny.",beskEn:"A mare with a mind of her own. Soft and comfortable in her movement. An all-round pony."},
  {id:"mac_kenzie",kallaId:"mac-kenzie",namn:"Mac Kenzie",typ:"ponny",fodd:2002,ras:null,mankhojd:null,import:null,kategoriKalla:"D",besk:"Mac Kenzie är en fin, snäll gentleman som dock är lite försiktig i hoppningen.",beskEn:"Mac Kenzie is a fine, kind gentleman, though a little careful over jumps."},
  {id:"marabou",kallaId:"marabou",namn:"Marabou",typ:"ponny",fodd:2007,ras:"Svensk Ridponny",mankhojd:null,import:null,kategoriKalla:"B",besk:"Marabou är en arbetsvillig liten valack som hoppar fint. Har tävlat mycket dressyr med tidigare ryttare.",beskEn:"Marabou is a willing little gelding who jumps nicely. He has competed a lot in dressage with a previous rider."},
  {id:"replay",kallaId:"replay",namn:"Replay",typ:"ponny",fodd:2012,ras:"Connemara",mankhojd:null,import:"Irland",kategoriKalla:"D",besk:"Mjuk ponny som hoppar med bra teknik men är lite försiktig. Kräver sin ryttare för att jobba bra.",beskEn:"A soft pony who jumps with good technique but is a little careful. Needs the right rider to work well."},
  {id:"toblerone",kallaId:"toblerone",namn:"Toblerone",typ:"ponny",fodd:2007,ras:"Fjordhäst",mankhojd:null,import:null,kategoriKalla:"C",besk:"Toblerone är en snäll, välutbildad och populär fjordvalack. Han kom till ridskolan i augusti 2014 och har tidigare tävlat i både hoppning samt dressyr.",beskEn:"Toblerone is a kind, well-schooled and popular Fjord gelding. He came to the riding school in August 2014 and has previously competed in both jumping and dressage."},
  {id:"trixie",kallaId:"trixie",namn:"Trixie",typ:"ponny",fodd:2007,ras:"Connemara",mankhojd:null,import:"Irland",kategoriKalla:"D",besk:"Trixie är väldigt snäll men lite känslig. Hon går på alla slags lektioner. Hon kramas gärna i stallet.",beskEn:"Trixie is very kind but a little sensitive. She joins all kinds of lessons. She likes a hug in the stable."},
  {id:"troy",kallaId:"troy",namn:"Troy",typ:"ponny",fodd:2016,ras:null,mankhojd:null,import:"Irland",kategoriKalla:"C",besk:"Välriden ponny som kan \"lite av varje\". Vill inte alltid bli fångad i hagen.",beskEn:"A well-ridden pony who can do \"a bit of everything\". Does not always want to be caught in the paddock."},
  {id:"westside",kallaId:"westside",namn:"Westside",typ:"ponny",fodd:2009,ras:"Haflinger",mankhojd:null,import:"Holland",kategoriKalla:"C",besk:"Westside är en snäll valack. Han kräver sin ryttare.",beskEn:"Westside is a kind gelding. He needs the right rider."},
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

/* ══════════════════════════════════════════════════════════════════
   UTSEENDET SOM ÄR AVLÄST UR UBRF:s EGNA FOTON

   Supabase `public.hastar` har identitet, ras, mankhöjd, kategori,
   import och beskrivning — men INGEN kolumn för färg eller tecken.
   Färgerna i LEGACY_GAMEPLAY ovan är därför märkta `visuellStatus:
   "ASSUMPTION"`, och det är ärligt: de är valda, inte avlästa.

   Men raden har ett fält till: `bild_url`. Varje häst i rostern har ett
   foto på ubrf.se, och `CLAUDE.md` är uttrycklig — "Bilder och filmer är
   specifikation, inte inspiration". Färgerna nedan är AVLÄSTA ur de
   fotona, och bara de fält som faktiskt syns i bilden står här.

   Det som INTE syns i fotot står inte här. Alla fyra bilderna är
   huvud-/halsporträtt, så benens tecken går inte att avgöra på tre av
   dem; de får rostern standardvärde och är märkta nedan. Att skriva
   "inga strumpor" som ett faktum vore att hitta på.

   `utseendeKalla:"FOTO"` betyder att färgen är avläst ur bilden som
   `bild_url` pekar på. Utan fältet gäller `visuellStatus:"ASSUMPTION"`
   som förut. ── */
const UTSEENDE_FOTO={
  /* ── VARMBLOD OCH HÄSTAR ──────────────────────────────────────── */
  /* Isabell: gyllene päls, ljus man, bred bläs ned till en mörk mule. */
  air:{farg:"#C99A5E",man:"#EFE5D2",mule:"#5A5150",
    tecken:{blas:"bred",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Mörkbrun med svart man. Inga vita tecken i ansiktet. */
  allan:{farg:"#4A3324",man:"#241A12",mule:"#332419",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* SKÄCK — stora vita fält över mörkgrått, vita ben. Mönstret syns
     tydligt men K3 har ingen geometri för fläckar: hästen kläs i en
     färg per kroppsdel. Färgen nedan är den DOMINERANDE (vit) med
     mörk man, och `monster` bär observationen så att den inte går
     förlorad. Berra konverteras därför inte i det här steget. */
  berra:{farg:"#E4E2DE",man:"#4A4B50",mule:"#9A8079",monster:"skack",
    tecken:{blas:"bred",strumpor:[1,1,1,1]},
    sett:["farg","man","mule","blas","strumpor","monster"],osett:[]},
  /* Mörkbrun, svart man, inga vita tecken. */
  bing:{farg:"#4A3226",man:"#2A1D16",mule:"#4A3B32",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Äppelskimmel: ljusgrå med äpplen, mörkgrå man, mörka underben. */
  conor:{farg:"#A8AAAC",man:"#4E5257",mule:"#9A9394",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Ljus skimmel, nästan vit med mörka stänk. Ingen bläs går att
     urskilja — hela ansiktet är ljust. */
  cosmo:{farg:"#DCDCD8",man:"#8A8B8E",mule:"#5C5450",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Ljus brun, svart man, ingen vit teckning. */
  crokino:{farg:"#8C4F2C",man:"#221A16",mule:"#4A4340",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun med en liten vit STJÄRNA i pannan — smal, inte en bläs. */
  curiretto:{farg:"#8E4A28",man:"#2A2320",mule:"#423A36",
    tecken:{blas:"stjarna",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun, svart man, ingen vit teckning. */
  fay:{farg:"#7A4A2C",man:"#211A18",mule:"#4E463E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun med svart man och en smal vit BLÄS hela vägen ned till en
     ljus mule. */
  hamilton:{farg:"#8A4A2A",man:"#221B18",mule:"#C9A89C",
    tecken:{blas:"bles",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Freiberger, brun med mörk man. Pannan skyms av luggen: om det
     finns en stjärna går den inte att avgöra. */
  hjartat:{farg:"#8A4A2E",man:"#4A4038",mule:"#5A544E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule"],osett:["blas","strumpor"]},
  /* Fux med ljusare man och en mycket BRED bläs ned till rosa mule. */
  kay_z:{farg:"#96522C",man:"#B07A50",mule:"#D9B0A4",
    tecken:{blas:"bred",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun med svart man och en smal vit bläs. */
  larry:{farg:"#7E4429",man:"#1F1815",mule:"#45403E",
    tecken:{blas:"bles",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Mörkbrun, svart man, smal bläs — OCH två höga vita strumpor på
     BÅDA BAKBENEN. Hela hästen syns i bild, benen inkluderade. */
  lothar:{farg:"#3B2A22",man:"#171310",mule:"#3A2E28",
    tecken:{blas:"bles",strumpor:[0,0,1,1]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Ljus skimmel med ljusgrå man. Ingen urskiljbar ansiktsteckning. */
  oska:{farg:"#DEDCD6",man:"#C8C2B6",mule:"#5A524E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Mörkbrun med mörkgrå man, ingen vit teckning. */
  puma:{farg:"#4A3427",man:"#4A4642",mule:"#6A645E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun med svart man och smal bläs ned till rosa mule. TVÅ vita
     underben syns tydligt — men hästen står vänd mot kameran och
     VILKA ben de tillhör går inte att avgöra. Placeringen är därför
     osedd, och inga strumpor ritas: att gissa ben vore att hitta på. */
  sune:{farg:"#6E4530",man:"#1E1815",mule:"#D4B1A4",
    tecken:{blas:"bles",strumpor:[0,0,0,0]},strumporSedda:2,
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Nästan svart med en BRED vit bläs ned till rosa mule. */
  tess:{farg:"#241C18",man:"#14100E",mule:"#E0C3B8",
    tecken:{blas:"bred",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},

  /* ── PONNYER ──────────────────────────────────────────────────── */
  /* Mörkbrun, nästan svart, svart man. Inga vita tecken på huvudet. */
  blackrock_jack:{farg:"#3A2A22",man:"#1C1512",mule:"#2A1F1A",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Vit skimmel med vit man. Benen syns; inga urskiljbara strumpor —
     på en vit häst är en vit strumpa inte en teckning. */
  lydia:{farg:"#E4E2DB",man:"#EDEBE4",mule:"#4A4644",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Vit/ljusgrå med ljusgrå man. Hela ansiktet ljust. */
  dante:{farg:"#E2E1DC",man:"#CFCBC3",mule:"#5A5350",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Äppelskimmel med SVART man och mörka underben. */
  dexter:{farg:"#A4A6A8",man:"#26242A",mule:"#64605E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* New Forest: fux med ljusare, rödblond man. */
  garnit:{farg:"#8E4C2E",man:"#A0755A",mule:"#3E3A38",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Brun med ljusgrå man och en vit bläs ned till ljus mule. Benen
     står i högt gräs. */
  jessy:{farg:"#8E5232",man:"#9A8F86",mule:"#D8D2C8",
    tecken:{blas:"bles",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Ljus skimmel med mörk man och lugg. */
  kennedy:{farg:"#E0DED8",man:"#5A4C44",mule:"#55504C",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Connemara, vit skimmel med vit man. Benen syns. */
  lady:{farg:"#E6E4DE",man:"#F0EEE8",mule:"#4E4A48",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Brun med mörk man och en liten vit STJÄRNA i pannan. */
  mac_kenzie:{farg:"#8A5030",man:"#322822",mule:"#4A4440",
    tecken:{blas:"stjarna",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Svensk ridponny, kategori B — minst i rostern. Fux med rödblond
     man och en mycket BRED bläs ned till rosa mule. */
  marabou:{farg:"#9A5A34",man:"#A8623A",mule:"#D5AE9E",
    tecken:{blas:"bred",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Connemara, gulbrun med mörk man. */
  replay:{farg:"#A06B3E",man:"#3A2A20",mule:"#6A5A4E",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Fjordhäst, brunblakk: sandfärgad kropp, mörk mule, och den
     upprätta tvåfärgade manen med mörk mittstrimma (midtstol) som
     syns tydligt i bilden. Inga vita tecken. */
  toblerone:{farg:"#C8A96B",man:"#E6DCC6",manKarna:"#4A3A2A",mule:"#4A4440",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","manKarna","mule","blas"],osett:["strumpor"]},
  /* Connemara, vit skimmel med vit man och gråskär mule. */
  trixie:{farg:"#E8E6DF",man:"#EFEDE6",mule:"#8A7B74",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
  /* Ljus skimmel med mörkgrå man och svans. Benen syns. */
  troy:{farg:"#DCDAD4",man:"#5A6066",mule:"#4E4A48",
    tecken:{blas:false,strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas","strumpor"],osett:[]},
  /* Haflinger: gyllenfux med ljus (flaxen) man och en bred vit bläs
     hela vägen ned till en rosa mule. */
  westside:{farg:"#C98B4E",man:"#F0E6D2",mule:"#C79A8E",
    tecken:{blas:"bred",strumpor:[0,0,0,0]},
    sett:["farg","man","mule","blas"],osett:["strumpor"]},
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

/* PRONOMEN — härlett ur källtexten, aldrig påhittat.

   PO-order 2026-09-06: "Pronomen/namn/plats ska komma från canonical
   horse data/runtime, inte separata strängar. Ingen hårdkodad
   honom/henne som kan bli fel." Underlaget är samma `besk` som allt
   annat verklighetsfaktum: står det valack eller han i beskrivningen är
   hästen en han, står det sto eller hon är hon ett sto. Står det ingetdera
   VET vi inte — och då används namnet i stället för ett gissat pronomen.
   Bränntomts Lydia är just ett sådant fall: källtexten säger varken
   valack eller sto. [REFERENCE GAP] tills UBRF kan bekräfta könet.

   Hon/han-formerna nedan är svenska pronomen för hästen som individ. */
const PRONOMEN_HAN={subj:"han", obj:"honom", poss:"hans"};
const PRONOMEN_HON={subj:"hon", obj:"henne", poss:"hennes"};
function harledPronomen(besk){
  const t=" "+String(besk||"").toLowerCase()+" ";
  const ord=r=>r.test(t);
  const han=ord(/[^a-zåäö]valack[a-zåäö]*[^a-zåäö]/)||ord(/[^a-zåäö](han|honom|hans)[^a-zåäö]/);
  const hon=ord(/[^a-zåäö]sto[^a-zåäö]/)||ord(/[^a-zåäö](hon|henne|hennes)[^a-zåäö]/);
  if(han&&!hon)return {...PRONOMEN_HAN, kalla:"besk"};
  if(hon&&!han)return {...PRONOMEN_HON, kalla:"besk"};
  /* Både och, eller ingetdera: vi vet inte. Namnet får bära meningen. */
  return {subj:null, obj:null, poss:null, kalla:han&&hon?"besk_motsagelse":"REFERENCE_GAP"};
}

const HORSES={};
for(const fakta of HASTFAKTA){
  const legacy=LEGACY_GAMEPLAY[fakta.id];
  const source=SOURCE_GAMEPLAY[fakta.id];
  const foto=UTSEENDE_FOTO[fakta.id];
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
    ...(foto?{farg:foto.farg,man:foto.man,mule:foto.mule,
      manKarna:foto.manKarna||null,tecken:foto.tecken,
      monster:foto.monster||null,strumporSedda:foto.strumporSedda||null}:{}),
    visuellStatus:foto?"FOTO":"ASSUMPTION",
    utseendeSett:foto?foto.sett:[],
    utseendeOsett:foto?foto.osett:["farg","man","blas","strumpor"],
    pronomen:harledPronomen(fakta.besk),
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
