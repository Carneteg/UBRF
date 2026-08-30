/* ══════════════════════════════════════════════════════════════════
   HÄSTARNA — kanonisk speldata, delad mellan webben och Roblox.

   Låg förut i src/data.js (HORSES) och src/sysslor.js (FODERSCHEMA,
   KRAFTVAL), alltså bara i JS. Roblox hade ingen roster alls: HorseStats
   i HorseCore/Config.luau stod på "Namnlös" och "Warmblood", och en
   spelare i Roblox mötte därför en hästmodell i stället för en häst.

   Filen är källan. tools/exportera-spel.js skriver roblox/game/UBRFSpel.luau
   ur den, och --kontrollera fäller bygget om de glidit isär — samma
   mönster som geometrin redan använder, av samma skäl: två sanningar om
   samma sak blir alltid fel till slut.

   Beskrivningarna är ORDAGRANNA från ubrf.se/hastar. Ändra dem inte för
   att de ska låta bättre i spelet; de är verklighet, inte kopia.

   Parametrarna 0–1 är spelvärden, inte mätningar på riktiga hästar. De är
   satta för att hästarna ska kännas olika att rida, och får justeras för
   game feel — till skillnad från namn, ras, födelseår och beskrivning.
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

/* Foderschema per häst: hö (kg), kraftfoder, och en rad ur verkligheten. */
const FODERSCHEMA={
  toblerone:{ho:2, kraft:"inget", notis:"Lättfödd fjording — inget kraftfoder, han blir rund av luft."},
  cosmo:    {ho:3, kraft:"müsli", notis:"Stor kropp, stort jobb — full giva."},
  air:      {ho:2, kraft:"betfor", notis:"Betfor blötläggs. Han sörplar."},
  larry:    {ho:3, kraft:"müsli", notis:"Hoppar bäst med bränsle i tanken."},
  hamilton: {ho:2, kraft:"müsli", notis:"Känslig mage — müslin ska vara blötlagd."},
  conor:    {ho:2, kraft:"betfor", notis:"Lugn mat till en känslig häst."},
  crokino:  {ho:3, kraft:"pellets", notis:"Stor häst, standardgiva."},
  lydia:    {ho:2, kraft:"inget", notis:"Barnponny på dietlista sedan i våras."},
  dexter:   {ho:2, kraft:"pellets", notis:"Mer fart än foder — snåla med pelletsen."},
  lady:     {ho:2, kraft:"inget", notis:"Welsh cob på gräns till rund — höet räcker gott."},
  chip:     {ho:1, kraft:"inget", notis:"Russ. Ge honom mer och han rullar till lektionen."},
  tina:     {ho:2, kraft:"betfor", notis:"Blötlagd betfor — och stå på hennes vänstra sida."},
  westside: {ho:3, kraft:"pellets", notis:"Stor kropp, standardgiva, inga konstigheter."},
  makadu:   {ho:3, kraft:"betfor", notis:"Äter lugnt. Gjorda om honom EFTER fodringen."},
  mara:     {ho:2, kraft:"müsli", notis:"Sur min vid krubban är normalläge. Ge och backa."},
  husky:    {ho:3, kraft:"müsli", notis:"Bränner allt han får — full giva."},
  kennedy:  {ho:2, kraft:"müsli", notis:"Unghäst under uppbyggnad — müslin blötläggs."},
};
const KRAFTVAL=["inget","müsli","betfor","pellets"];
