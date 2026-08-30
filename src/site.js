/* ══════════════════════════════════════════════════════════════════
   ANLÄGGNINGEN — UBRF, Husbyvägen 1A, Bro. All geometri i meter.
   Koordinatsystem: origo i sydväst, +x öster, +y norr.
   Byggd mot fotona i references/buildings/ och mot satellit- och
   Street View-bilder över Husbyvägen 1A (se references/SITEPLAN.md):
   ridhuset i mörkröd korrugerad plåt med svarta detaljer, caféet med
   balkong och yttertrappa på gaveln mot grusplanen, UBRF-skylten och
   den långa entrékvisten på västra långsidan mot vägen, gräsgården
   mellan ridhus och stall, stallets faluröda träpanel med huvraden på
   nocken och ett valvfönster per box, förstukvisten på västra
   långsidan, fodersilon vid södra gaveln, hagarna öster om stallet och
   utebanorna norr om dem.

   Väderstrecken: spelets norr är verklighetens nordväst (SITEPLAN.md).
   Grusplanen — parkeringen dit man kommer, den alla foton är tagna
   från — ligger vid husens NORRA gavlar, mot Björklidsvägen. Därifrån
   ser man ridhuset till höger och stallet till vänster, precis som i
   verkligheten. Silon, bakgården och infartsvägen från Husbyvägen
   ligger vid den södra änden.
   Geometrin här är den enda sanningen — rendering läser bara detta.
   ══════════════════════════════════════════════════════════════════ */

/* Fasadernas u löper moturs runt huset: på västra långsidan räknas den
   från NORRA gaveln, på östra från den södra. Stallets foton och kort
   beskriver allt som avstånd från klubbgaveln — den mot grusplanen,
   alltså den norra — så på västra långsidan är u avståndet självt och
   på den östra räknas det om. Stallet är 54 m långt. */
const sV = s => s;

/* Stallets långsidor har ett valvbågat fönster per box, i samma takt som
   boxarna innanför (STALLINNE: boxarna börjar 10,4 m in och är 3,5 m
   breda). Rytmen är byggnadens tydligaste drag på håll — därför räknas
   den fram ur samma tal i stället för att skrivas av för hand. */
function stallFonster(sida){
  const ut=[];
  for(let i=0;i<10;i++){
    const s=10.4+3.5*i+1.75;                    // avstånd från klubbgaveln i norr
    ut.push({sida, u:sida==="W"?sV(s):54-s, b:1.15, h:1.55, z0:1.55, typ:"valv"});
  }
  return ut;
}

const ANL = {
  bredd: 210, djup: 170,

  /* Markytor ritas i ordning — senare vinner. */
  mark: [
    {typ:"gras",  rekt:{x:0,   y:0,   w:210, h:170}},
    {typ:"aker",  rekt:{x:9,   y:20,  w:99,  h:100}},  // åkrarna öster om Enköpingsvägen
    {typ:"asfalt",rekt:{x:2,   y:0,   w:5,   h:170}},  // Enköpingsvägen i väster
    {typ:"asfalt",rekt:{x:207, y:0,   w:3,   h:170}},  // Husbyvägen i öster
    {typ:"grus",  rekt:{x:0,   y:146, w:118, h:6}},    // Björklidsvägen in mot grusplanen
    {typ:"grus",  rekt:{x:106, y:121, w:48,  h:34}},   // grusplanen/parkeringen vid norra gavlarna
    {typ:"grus",  rekt:{x:144, y:119, w:36,  h:16}},   // planen framför stallets klubbgavel
    {typ:"grus",  rekt:{x:112, y:20,  w:6,   h:101}},  // grusvägen längs västra långsidan
    {typ:"grus",  rekt:{x:144, y:10,  w:62,  h:8}},    // infartsvägen från Husbyvägen i sydost
    {typ:"grus",  rekt:{x:148, y:40,  w:44,  h:24}},   // gårdsplanen vid stallets södra gavel
    {typ:"grus",  rekt:{x:186, y:16,  w:8,   h:28}},   // väggrenen upp från infarten
    {typ:"grus",  rekt:{x:175, y:64,  w:3,   h:57}},   // gången öster om stallet mot hagarna

    {typ:"sand",  rekt:{x:176, y:119, w:20,  h:40}},   // uteridbanan (dressyr 20×40)
    {typ:"sand",  rekt:{x:156, y:135, w:18,  h:22}},   // grusbanan/paddocken bredvid
    {typ:"betong",rekt:{x:170, y:100, w:6,   h:5}},    // betongplattan vid uppgången
  ],
  cirklar: [ // runda markytor
    {typ:"sand", c:[100,131], r:4.6, kant:true},       // lekhagen med stenhästarna
  ],

  byggnader: [
    /* Ridhuset. Måtten och färgerna kommer ur byggnadskortet
       references/buildings/ridhus/KORT.md, som i sin tur är läst ur
       fotona i samma mapp — inget här är gissat fritt.
         · mörkt vinröd, vertikalt korrugerad stålplåt. Medelvärdet över
           alla tre fotona är (97,45,57) — mörkare och blåare än kortets
           första avläsning (138,34,40), som togs i en dager. Färgen här
           är råvaran (135,47,64); belysningen tar ner den till fotots.
         · svart list runt hela huset vid 4,1 m: övre bjälklaget, och
           det första man ser från parkeringen
         · sadeltak med 13° resning (kortets ~14°, spann 11–17°),
           svart plåt och svarta vindskivor
         · norra gaveln mot parkeringen: dubbeldörren med
           valvfönstret över, den svarta dörren under sitt vita
           skärmtak, och i väster Café Krubban med fyra valvbågade
           fönster, balkong och utvändig ståltrappa (norra gavelns u
           räknas moturs, från östra hörnet)
       Banan 20×60 därinne; UBRF-skylten mitt på västra långsidan. */
    {id:"ridhus", rekt:{x:118, y:44, w:25, h:75}, hV:6.2, hN:9.2, nock:"NS",
     fargV:"#872F40", fargT:"#202022", svart:"#202022", plat:true,
     list:4.10, takfot:true, detalj:"ridhus", label:"RIDHUSET",
     oppningar:[
       {sida:"N", u:3.1, b:1.8, h:2.2, z0:0,   typ:"dorrvit", skarm:2.6}, // dubbeldörren
       {sida:"N", u:3.3, b:1.20,h:1.55,z0:4.45,typ:"valv"},   // valvfönstret över entrén
       {sida:"N", u:8.1, b:1.1, h:2.1, z0:0,   typ:"dorr", skarm:2.1},    // svarta dörren
       {sida:"N", u:20.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},   // caféet, nedre våningen
       {sida:"N", u:24.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},
       {sida:"N", u:20.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},   // caféet, övre våningen
       {sida:"N", u:24.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},
       {sida:"N", u:22.3,b:1.0, h:2.05,z0:4.02,typ:"dorr"},   // cafédörren mot balkongen
       /* Västra långsidan, mot vägen. Street View visar en lång
          entrékvist närmast caféet, den svarta dörren vid UBRF-skylten
          och en rad små fyrkantsfönster högt uppe. */
       {sida:"W", u:9,  b:2.0, h:2.2, z0:0,    typ:"dorrvit"},  // dubbeldörrarna under kvisten
       {sida:"W", u:40, b:1.1, h:2.1, z0:0,    typ:"dorr"},     // svarta dörren vid skylten
       {sida:"W", u:14, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:22, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:30, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       /* Durkplåtdörrarna mot gården. Låg tidigare vid u = 22, alltså rakt
          bakom läktaren (som upptar lokala y 9–59): både dörrmarkören och
          landningspunkten hamnade inuti en solid läktarstomme och gick inte
          att använda. Flyttad till u = 5, söder om läktaren. */
       {sida:"E", u:5,  b:3.4, h:2.9, z0:0, typ:"portplat"},
       /* HÄSTGÅNGEN till stallet, i entréhallens höjd. */
       {sida:"E", u:65, b:2.4, h:2.6, z0:0, typ:"portbla", intern:true},
       {sida:"S", u:8,  b:4.0, h:3.6, z0:0, typ:"portsilver"},// stora silverporten [antagande]
     ]},
    /* Stallet. Måtten och färgerna kommer ur byggnadskortet
       references/buildings/stall/KORT.md, läst ur fasad- och
       entrébilderna i samma mapp.
         · liggande träpanel i mörk falurött (80,35,47), vita knutar,
           vitt foder runt varje fönster, ljusgrå betongsockel
         · sadeltak i mörk blågrå bandtäckt plåt, 28° resning, med
           snörasskydd och svart hängränna
         · huvraden på nocken — en huv per box, och den börjar först
           efter förstukvisten, inte vid gaveln
         · ett valvbågat fönster per box längs båda långsidorna
         · förstukvisten på västra långsidan, 5,6 m från norra
           gaveln — klubbgaveln mot grusplanen: ockragul dörr, runda
           fönster, vitt ribbräcke
         · norra gaveln: valvfönster, balkongdörr och spiraltrappa
         · södra gaveln mot gårdsplanen (Street View): två entrédörrar
           under vita skärmtak och en rak ståltrappa till övervåningen */
    /* Stallets NORRA gavel ligger i liv med ridhusets — det syns i
       satellitbilden: båda gavlarna vetter mot grusplanen i samma
       linje, med gräsgården emellan. */
    {id:"stall", rekt:{x:154, y:65, w:21, h:54}, hV:4.4, hN:10.0, nock:"NS",
     fargV:"#6E2F44", fargT:"#5E646C", svart:"#26292E", takfot:"#EEECE4",
     detalj:"stall", sockel:0.35, label:"STALLET",
     oppningar:[
       /* Förstukvisten på västra långsidan. */
       {sida:"W", u:sV(5.6), b:1.15, h:2.10, z0:0,    typ:"dorrgul"},  // ockragula entrédörren
       {sida:"W", u:sV(4.0), b:0.66, h:0.66, z0:1.78, typ:"rund"},     // runda fönstren vid dörren
       {sida:"W", u:sV(7.2), b:0.66, h:0.66, z0:1.78, typ:"rund"},
       {sida:"W", u:sV(2.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},     // valvfönster kring kvisten
       {sida:"W", u:sV(8.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},
       /* HÄSTGÅNGEN mot ridhuset, 9 m från klubbgaveln. */
       {sida:"W", u:sV(10.0), b:2.4, h:2.6, z0:0, typ:"portbla", intern:true},
       ...stallFonster("W"), ...stallFonster("E"),
       /* Norra gaveln — klubbgaveln mot grusplanen, den höga, med
          balkongen och spiraltrappan (stall-fasad-04/05). */
       {sida:"N", u:6.4,  b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:14.6, b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:8.4,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"N", u:12.6,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"N", u:10.5,  b:0.95, h:2.05, z0:4.60, typ:"dorrvit"},     // balkongdörren
       /* Klubbentrén i gavelns mitt, rakt under balkongen — den vetter
          mot grusplanen och leder in i klubbdelen. [enligt Tobias] */
       {sida:"N", u:10.5,  b:1.15, h:2.05, z0:0,    typ:"dorrgul", skarm:1.7},
       /* Stora skjutporten mitt på östra långsidan, mot hagarna. */
       {sida:"E", u:30, b:3.6, h:3.2, z0:0, typ:"portbla"},
       /* Södra gaveln mot gårdsplanen: servicedelens två entrédörrar
          under vita skärmtak, valvfönster och trappdörren uppe
          (Street View från infartsvägen). */
       {sida:"S", u:5.6,  b:1.15, h:2.10, z0:0,    typ:"dorrvit", skarm:1.7},
       {sida:"S", u:12.5,  b:1.15, h:2.10, z0:0,    typ:"dorrvit", skarm:1.7},
       {sida:"S", u:8.2,  b:1.10, h:1.50, z0:1.60, typ:"valv"},
       {sida:"S", u:10.4,  b:1.10, h:1.50, z0:1.60, typ:"valv"},
       {sida:"S", u:9.2,  b:1.10, h:1.50, z0:4.60, typ:"valv"},
       {sida:"S", u:12.4, b:0.95, h:2.00, z0:4.35, typ:"dorrmork"},    // trappdörren
       /* Hästarnas väg ut. Den här porten leder till gräsgården och
          vidare till ridhuset — det är den man leder hästen genom före
          lektionen, så den ska vara en port och inte en dörr. */
       {sida:"W", u:30,   b:3.4,  h:3.2,  z0:0, typ:"portbla"},
     ]},
    /* HÄSTGÅNGEN mellan ridhuset och stallet. Tobias har varit på plats:
       husen är sammanbyggda, och det som binder dem är en hästgång — man
       leder hästen inomhus mellan stallet och ridhuset i stället för att gå
       ut över gården.

       Utrymningsplanernas situationsplan ritar husen som skilda volymer, men
       den är en schematisk karta i frimärksstorlek och en låg förbindelse
       behöver inte vara en egen brandcell. Product Owner på plats väger
       tyngre — se references/plans/OAVGJORT.md.

       LÄGET ÄR ETT ANTAGANDE. Den ligger här därför att det är det enda
       stället där BÅDA husen har gångbar insida mot varandra: ridhusets
       läktare upptar hela östväggen mellan y 53 och 103, och stallets
       boxlängor upptar y 71–108. Kvar blir y 108–115, alltså stallets
       klubbdel mot ridhusets entréhall. Var den verkligen går behöver ett
       foto eller ett besked. [ASSUMPTION] */
    {id:"hastgang", rekt:{x:143, y:106, w:11, h:6}, hV:3.2, hN:4.2, nock:"EW",
     fargV:"#7C2A24", fargT:"#5E646C", label:"HÄSTGÅNGEN",
     oppningar:[
       {sida:"N", u:5.5, b:2.4, h:2.6, z0:0, typ:"portbla"},
       {sida:"S", u:5.5, b:1.2, h:1.4, z0:1.3, typ:"fonster"},
     ]},
    /* Förbindelselängan som stänger gårdens södra ände — den låga
       byggnaden man ser mellan gavlarna från grusplanen (Street View). */
    {id:"langa", rekt:{x:147, y:59, w:7, h:6}, hV:3.0, hN:4.4, nock:"EW",
     fargV:"#7C2A24", fargT:"#7E8288", label:"",
     oppningar:[{sida:"N", u:4.4, b:1.1, h:2.0, z0:0, typ:"dorrmork"}]},
    /* Röda stugan vid infarten från Björklidsvägen (förråd/sekretariat). */
    {id:"stuga", rekt:{x:94, y:140, w:6.5, h:4.5}, hV:2.5, hN:3.8, nock:"EW",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"E", u:1.2, b:1.6, h:0.9, z0:1.1, typ:"fonster"},
                {sida:"S", u:1.6, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Domarkuren vid uteridbanan. */
    {id:"domarkur", rekt:{x:184, y:148, w:4.5, h:3.5}, hV:2.3, hN:3.4, nock:"EW",
     fargV:"#8A3A30", fargT:"#5A2B26", label:"",
     oppningar:[{sida:"W", u:0.8, b:2.6, h:1.0, z0:1.0, typ:"fonster"}]},
    /* Boden vid södra gaveln (vid sopstationen). */
    {id:"bod", rekt:{x:184, y:44, w:5, h:4}, hV:2.3, hN:3.4, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"S", u:1.4, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Elcentralen/boden vid stigen mot banorna. */
    {id:"elbod", rekt:{x:170.5, y:59, w:3, h:2.5}, hV:2.0, hN:2.8, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"", oppningar:[]},
  ],

  /* Staket: postlinjer. "tra" = kraftigt trästaket med två reglar
     (banor och hagar), "el" = trådstängsel mot åkern, "rail" = låg
     falurödmålad trärail (parkering/lekhage). */
  staket: [
    {typ:"tra", p:[[176,119],[196,119],[196,159],[176,159],[176,119]]},// uteridbanan
    {typ:"tra", p:[[156,135],[174,135],[174,157],[156,157],[156,135]]},// paddocken bredvid
    {typ:"tra", p:[[178,65],[206,65],[206,93],[178,93],[178,65]]},     // hage Ö1
    {typ:"tra", p:[[178,97],[206,97],[206,117],[178,117],[178,97]]},   // hage Ö2
    {typ:"el",  p:[[112,20],[112,121]]},                               // trådstängsel mot åkern
    {typ:"rail",p:[[155,121.5],[168,121.5]]},                          // rail framför klubbgaveln
    {typ:"rail",p:[[96,127],[96,136]]},                                // rail vid lekhagen
  ],
  hagar: [ // betande hästar (id ur HORSES) för liv i bilden
    {rekt:{x:178,y:65,w:28,h:28}, hastar:["cosmo","air","mara"]},
    {rekt:{x:178,y:97,w:28,h:20}, hastar:["larry","husky","westside","lydia"]},
    {rekt:{x:156,y:135,w:18,h:22}, hastar:["toblerone","dexter","chip"]},
  ],

  /* Träd: [x, y, radie]. Skogsbryn i norr och väster, björkraden
     längs grusvägen, lövträden runt gårdsplanen. */
  trad: [
    [110,50,1.6],[110,62,1.7],[110,74,1.6],[110,86,1.8],[110,98,1.6],  // björkraden
    [122,14,2.6],[130,12,2.2],[88,10,2.6],[104,24,1.8],
    [150,4,2.8],[160,5,2.4],[172,4,2.8],[184,5,2.6],[196,6,3.0],       // trädraden mot Enköpingsvägen-hållet i söder
    [194,36,2.6],[199,14,2.4],
    [60,118,3.0],[56,130,3.4],[56,138,3.0],[62,158,3.2],[70,164,3.0],
    [80,166,3.4],[92,168,3.0],[104,166,3.2],[116,166,3.0],[128,164,3.4],
    [140,162,3.0],[150,161,2.8],[120,158,2.4],[88,160,2.8],
    [46,120,3.2],[40,132,3.0],[44,156,3.4],[36,160,3.0],
    [98,120,2.2],[92,130,2.0],[200,158,2.6],[192,164,3.0],
  ],

  /* Rekvisita — ritas i 2D och 3D av world.js. */
  props: [
    {typ:"silo",      pos:[166,60]},                     // fodersilon vid södra gaveln (satellit)
    {typ:"balar",     pos:[157,56]},                     // ensilagebalarna
    {typ:"grushog",   pos:[122,131]},                    // grushögen på grusplanen (Street View)
    {typ:"transport", pos:[133,125], rikt:0.5},          // hästtransporten på grusplanen
    {typ:"bord",      pos:[150,74]},                     // picknickborden på gräsgården
    {typ:"bord",      pos:[148,86]},
    {typ:"bank",      pos:[146,94]},
    {typ:"stol",      pos:[149,102]},
    {typ:"skylt",     pos:[118,82], text:"UPPLANDS-BRO RYTTARFÖRENING", norm:[-1,0]},
    {typ:"cafeskylt", pos:[124.4,119.8], norm:[0,1]},   // skylten vid trappans fot
    {typ:"flagga",    pos:[123,149]},
    {typ:"vagvisare", pos:[172,123]},    // vägvisaren med åtta armar, vid klubbgaveln
    {typ:"stenhast",  pos:[98.5,129.5]},                 // stenhästarna i lekhagen
    {typ:"stenhast",  pos:[101.5,132]},
    {typ:"stenhast",  pos:[99.5,133]},
    {typ:"stenhast",  pos:[101,129]},
    {typ:"mast",      pos:[176,159]},                    // belysningsmasterna vid banorna
    {typ:"mast",      pos:[196,119]},
    {typ:"mast",      pos:[156,157]},
    {typ:"sopstation",pos:[150,56]},
    {typ:"ac",        pos:[143.4,80], norm:[1,0]},                   // värmepumparna mot gården
    {typ:"ac",        pos:[143.4,84], norm:[1,0]},
    {typ:"busskylt",  pos:[8.6,88]},
  ],

  /* Interaktionspunkter på gården. */
  dorrar: [
    /* 0,9 m ut från väggen, inte 0,4: kollisionsmarginalen mot en byggnad är
       0,55 m, så en markör närmare än så går inte att stå på. */
    {id:"ridhus_o", pos:[143.9,49], text:"In i ridhuset (durkplåtdörrarna)",
     mot:"ridhusinne", spawn:{x:23.4,y:5,rikt:Math.PI}},
    {id:"ridhus_n", pos:[139.9,119.8], text:"In i ridhuset (entrén)",
     mot:"ridhusinne", spawn:{x:21.9,y:73.4,rikt:-Math.PI/2}},
    {id:"cafe", pos:[124.4,120.2], text:"Café Krubban (trappan upp)", mot:"info",
     info:"Café Krubban har stängt för kvällen. Kolla in vyn över banan från läktaren i stället."},
  ],
  /* Man kommer med bil till grusplanen vid norra gavlarna — precis som
     i verkligheten. Härifrån: ridhuset till höger, stallet till vänster. */
  spawn: {x:146, y:136, rikt:-Math.PI/2},
  /* Hagen där dagens häst hämtas: grinden på västra sidan av hage Ö1. */
  hamtHage: {grind:[178,79], falt:[186,77]},
  skylt: {pos:[120,150.5], text:"HUSBYVÄGEN 1A · UPPLANDS-BRO RYTTARFÖRENING"},
};

/* ── Stallet invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 15), +y norr (längd 52).
      Norr: klubbdelen (uppehållsrum, teorisal, toaletter) innanför
      entrén vid klubbgaveln mot grusplanen — vit pärlspont, betonggolv.
      Branddörren in till stallet ("schysst stall"-dekalen). Mitten:
      stallgången — marksten, två rader boxar i antracitgrå komposit
      med galvade galler, namnskyltar, limträbalkar och taklanterniner.
      Söder: servicedelen med spolspilta, spånförråd och
      uppbindningsplatser, mot gårdsplanen.
      klubbY och serviceY är tvärväggarnas y; boxarna ligger emellan. ── */
/* ── Stallet invändigt — DUBBELSTALL ────────────────────────────────
   Byggt mot utrymningsplanen (Presto AB 2025-10-11, "Plan 1"), som sedan
   2026-08-30 finns i repot: `references/plans/stall-plan1-utrymning.jpg`.
   Den är auktoritativ för planform och layout enligt Gate F01.

   MÄTT I PLANEN, inte läst ur prosa. Ett lodrätt tvärsnitt genom
   boxområdet vid tre olika x-lägen ger samma sex band, i samma ordning:

     boxrad — GÅNG A — boxrad · boxrad — GÅNG B — boxrad

   De två mittersta står rygg mot rygg mot en gemensam spine, som i planen
   bär regelbundna ⊞-märken (vattenkoppar eller foderluckor). Bandens
   inbördes andelar av byggnadens bredd, mätta i planen:

     boxrad W   169 px   20,9 %
     gång A     100 px   12,4 %
     boxrad MA  144 px   17,8 %
     boxrad MB  142 px   17,6 %
     gång B      99 px   12,3 %
     boxrad E   153 px   19,0 %

   ANDELARNA ÄR VERIFIERADE — de är oberoende av skala och lika i alla tre
   snitten. Det viktigaste de säger är att GÅNGARNA ÄR SMALARE ÄN BOXARNA
   ÄR DJUPA, ungefär två tredjedelar. Spelet antog tidigare att alla sex
   banden var lika breda; det var fel.

   TOTALBREDDEN ÄR DÄREMOT INTE AVGJORD. `BREDD` nedan är ett antagande i
   mitten av ett intervall som källorna inte är eniga om — se
   `references/buildings/stall/KORT.md` under "Bredden". Ändra bara den
   siffran; allt annat i planen följer andelarna. ── */
const STALL_BAND = [
  {id:"W",  typ:"rad",  andel:0.209, vetter:+1, gang:"A", yttervagg:true},
  {id:"A",  typ:"gang", andel:0.124},
  {id:"MA", typ:"rad",  andel:0.178, vetter:-1, gang:"A", yttervagg:false},
  {id:"MB", typ:"rad",  andel:0.176, vetter:+1, gang:"B", yttervagg:false},
  {id:"B",  typ:"gang", andel:0.123},
  {id:"E",  typ:"rad",  andel:0.190, vetter:-1, gang:"B", yttervagg:true},
];

const STALLINNE = {
  bredd:21, langd:54,
  vagg:"#CFC8BC", golv:"#8C8880", gangGolv:"#9A968E", tak:3.4,
  klubbY:43, boxStartY:6.8, serviceY:6.5,
  boxB:3.5, antalBoxar:9,
  tvarGang:{y0:24.3, y1:27.8},
  /* Fylls ur STALL_BAND nedan: rader med x0/boxDjup, gångar med x0/x1. */
  rader:[], gangar:{},
  /* Spelets sjutton hästar står i gång A, den man kommer in i från
     förstukvisten. Gång B:s boxar ritas men får ingen häst: spelet har
     sjutton namn och fler får inte hittas på. */
  boxar:{
    W: [ "lady","toblerone","westside","lydia","makadu","conor","mara","hamilton","husky" ],
    MA:[ "kennedy","cosmo","tina","air","chip","larry","crokino","dexter",null ],
    MB:[ null,null,null,null,null,null,null,null,null ],
    E: [ null,null,null,null,null,null,null,null,null ],
  },
  rum:[
    {id:"uppehallsrum", rekt:{x:0,    y:50.5, w:7.0, h:3.5}, label:"UPPEHÅLLSRUM"},
    {id:"teorisal",     rekt:{x:14.0, y:50.5, w:7.0, h:3.5}, label:"TEORISAL · WC"},
    {id:"sadelkammare", rekt:{x:0,    y:46.6, w:3.2, h:3.9}, label:"SADELKAMMARE"},
  ],
  service:[
    {id:"spolspilta",   rekt:{x:0,    y:0, w:4.5, h:6.5}, label:"SPOLSPILTA"},
    {id:"spanforrad",   rekt:{x:16.5, y:0, w:4.5, h:6.5}, label:"SPÅNFÖRRÅD"},
  ],
  tvarvaggar:[ {y:43, brand:true}, {y:6.5, brand:false} ],
  /* Dörrarna beskrivs EN gång. `pos` är innerläget, `spawn` ytterläget,
     `inrikt` vilket håll man tittar när man kliver in och `uttext` vad
     markören på gården säger. ANL.dorrar byggs ur den här listan längre
     ner — förut fanns två listor med var sin uppsättning koordinater, och
     när planformen ändrades följde bara den ena med. Då hamnade utgången
     mot gräsgården inne i en boxrad. */
  dorrar:[
    {id:"ut_n", pos:[1.6,48.4], text:"Ut genom entrén", mot:"gard", inrikt:0,
     uttext:"Gå in i stallet (Entré)",
     spawn:{x:152.6,y:113.4,rikt:Math.PI}},
    {id:"ut_n2",pos:[10.5,50.0], text:"Ut till grusplanen (klubbdörren)", mot:"gard", inrikt:-Math.PI/2,
     uttext:"Gå in i stallet (klubbdörren)",
     spawn:{x:164.5,y:120.6,rikt:Math.PI/2}},
    {id:"ut_v", pos:[1.6,26.0],  text:"Ut till gräsgården — vägen till ridhuset", mot:"gard", inrikt:0,
     uttext:"Gå in i stallet (hästporten mot gården)",
     spawn:{x:152.6,y:91,rikt:Math.PI}},
    {id:"ut_s", pos:[5.6,1.6],   text:"Ut till gårdsplanen — mot Husbyvägen", mot:"gard", inrikt:Math.PI/2,
     uttext:"Gå in i stallet (gaveldörren vid gårdsplanen)",
     spawn:{x:159.6,y:63.4,rikt:-Math.PI/2}},
    /* HÄSTGÅNGEN till ridhuset. Den här dörren går inte ut på gården utan
       rakt in i ridhusets entréhall — det är hela poängen med att husen är
       sammanbyggda: hästen leds inomhus. Ingen markör läggs på gården för
       den, eftersom den inte finns där. */
    {id:"hastgang", pos:[0.9,44.0], text:"Hästgången — in i ridhuset",
     mot:"ridhusinne", inrikt:Math.PI, inne:true,
     spawn:{x:24.0,y:65.0,rikt:Math.PI}},
  ],
  ridlarare:{pos:[0,34], namn:"Ridläraren"},
  whiteboard:{pos:[0,7.2]},
};

/* Banden läggs ut ur andelarna, från västra ytterväggen och österut. */
(()=>{
  const S=STALLINNE; let x=0;
  for(const b of STALL_BAND){
    const w=b.andel*S.bredd;
    if(b.typ==="gang") S.gangar[b.id]={x0:x, x1:x+w};
    else S.rader.push({id:b.id, x0:x, djup:w, vetter:b.vetter,
                       gang:b.gang, yttervagg:b.yttervagg});
    x+=w;
  }
  /* Ridläraren och whiteboarden mitt i gång A. */
  const mA=(S.gangar.A.x0+S.gangar.A.x1)/2;
  S.ridlarare.pos[0]=mA; S.whiteboard.pos[0]=mA;
})();

/* Stallets dörrmarkörer på gården härleds ur STALLINNE.dorrar, så att de
   två sidorna av samma dörr aldrig kan glida isär. Före 2026-08-30 fanns
   två handskrivna listor, och när planformen ändrades följde bara den ena
   med: markören vid klubbgaveln pekade tre meter fel, och den som gick in
   från gräsgården satte spelaren INNE i en boxrad. */
for(const d of STALLINNE.dorrar){
  if(d.inne) continue;                 // hästgången går inte ut på gården
  ANL.dorrar.push({
    id:"stall_"+d.id.replace(/^ut_/,""),
    pos:[d.spawn.x, d.spawn.y],
    text:d.uttext,
    mot:"stallinne",
    spawn:{x:d.pos[0], y:d.pos[1], rikt:d.inrikt},
  });
}

STALLINNE.gangytor = (()=>{
  const S=STALLINNE, g=[];
  for(const k of ["A","B"]){
    const a=S.gangar[k];
    g.push({x:a.x0, y:S.serviceY, w:a.x1-a.x0, h:S.klubbY-S.serviceY});
  }
  /* Tvärkorridoren går hela vägen ut till båda långsidorna: planen har
     utrymningsvägar där, och en korridor som slutar vid gång B når dem
     inte. Den bryter boxlängorna på ett ställe, vilket är precis vad en
     genomgående korridor gör. */
  g.push({x:0.4, y:S.tvarGang.y0, w:S.bredd-0.8, h:S.tvarGang.y1-S.tvarGang.y0});
  g.push({x:0.4, y:S.klubbY,   w:S.bredd-0.8, h:50.5-S.klubbY});   // klubbhallen
  g.push({x:3.4, y:50.5,       w:7.2,         h:3.1});             // hallen mot gaveldörren
  g.push({x:4.5, y:0.4,        w:12.0,        h:S.serviceY-0.4});  // servicepassagen
  return g;
})();

/* ── Ridhuset invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 25), +y norr (längd 75). Banan 20×60 innanför
      vit murad sarg med svart sockel (IMG_0095–0116): sponsorväggen
      med speglarna i väster, läktaren med domarbåset i öster,
      entré- och cafédelen med fönsterband och trappan i norr — samma
      gavel som vetter mot grusplanen — och hinderförrådet i söder.
      Sargporten vid A släpper in ekipagen. ── */
/* Ridhuset invändigt. Måtten kommer ur utrymningsplanen (se
   references/buildings/ridhus/KORT.md) med banans 20×60 som fast punkt:
   planens längder är ihoptryckta av perspektivet, men banans två kända
   mått ger skalan i båda led och resten faller ut.

     bredd  20 m bana + 4,4 m läktarband  = 25 m
     längd  60 m bana + 13 m gaveldel     = 75 m

   Gaveldelen i norr — mot parkeringen — är entré, trapphus och café.
   Går man in från parkeringen kommer man in i en hall, inte rakt ut
   på banan. entre är gaveldelens djup; den ligger i y > langd−entre. */
const RIDHUSINNE = {
  bredd:25, langd:75, tak:6.2, entre:13,
  bana:{x:0.6, y:2, w:20, h:60}, sargH:1.35,
  vagg:"#E9E5DC", sockel:"#2E2E2C", sandFarg:"#5E4A36", gangFarg:"#8C8880",
  /* MOTSÄGELSE 1 ur DRIVE-SOURCE-INDEX (`IMG_0183`): långsidans övre
     väggyta är MÖRKRÖD/MAROON med horisontella detaljer, inte brun
     träpanel. Rättad 2026-08-30. Listen är den horisontella detaljen. */
  panel:"#5E2C33", panelList:"#E8DFCE",
  laktare:{x0:21.0, y0:9, y1:59, steg:4, stegH:0.28, stegD:0.85},
  /* MOTSÄGELSE 5 (`IMG_0179`): bakom sargen finns flera glasade rum /
     fönsterpartier ovanför de nivåindelade träbänkarna. Måtten är
     `[ASSUMPTION]` — indexet beskriver att de finns, inte hur stora. */
  glasrum:[ {y0:12, y1:22}, {y0:26, y1:36}, {y0:44, y1:56} ],
  /* MOTSÄGELSE 4 (`IMG_0198`): båset ligger vid dressyrbokstaven E, är
     mörkt trä, och nås av en trappa med träräcken. Över öppningen sitter
     en grön exit-skylt. E ligger vid husets y = 32 sedan bokstäverna
     följer sargporten (se DRESSYRBOKSTAVER i data.js). */
  domarbas:{x:23.2, y:32, b:2.0, h:2.3, trappa:true, exit:true},
  /* Hindren som står framme mellan lektionerna, ur interiörfotona:
     vita stöd, blå-vita och röd-vita bommar, en bom på marken och
     uppsittningspallen vid sargen. Koordinaterna är i banans system. */
  hinder:[
    {x:6.5, y:24, b:2.8, h:0.68, farg:"bla"},
    {x:13.5,y:38, b:2.8, h:0.52, farg:"rod"},
    {x:9.0, y:50, b:3.0, h:0,    farg:"rod"},
  ],
  koner:[[4.0,17],[16.6,44],[11.0,58]],
  pall:{x:18.9, y:20},
  dynor:12,                                        // elon-dynorna på översta bänken
  cafe:{djup:13.0, z0:2.55, z1:5.4},               // överbyggnaden i norr
  trappa:{x:22.0, y:65.4},                         // trätrappan upp till caféet
  /* MOTSÄGELSE 3 (`IMG_0179`): en rund klocka vid den centrala
     passagen/trappan. Höjden är `[ASSUMPTION]`. */
  klocka:{x:22.0, y:63.6, z:3.6, r:0.42},
  speglar:[ {y:19,b:3.2},{y:37,b:4.2} ],           // på västra långsidan
  skyltar:[
    {y:53,  b:5.0, text:"VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING", fg:"#3A3E44", bg:"#F2EDE2"},
    {y:46.5,b:4.0, text:"HUVUDSPONSOR ELON BARKARBY", fg:"#F0EADC", bg:"#1C1C1E"},
    {y:31.5,b:3.6, text:"Vi tror på dig! · Sparbanken i Enköping", fg:"#C0392B", bg:"#F7F2E8"},
    {y:26.5,b:3.0, text:"Agria Djurförsäkring", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:15,  b:3.4, text:"RS Mustang · Stallströ och foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:8,   b:3.6, text:"Stigsbergs Gård · Hästsportbutik", fg:"#3A3E44", bg:"#F2EDE2"},
  ],
  port:{x0:9.6, x1:11.6},                         // sargporten vid A (norra kortsidan)
  /* Möblerna i entréhallen, som solida rektanglar. Utan dem gick man
     rakt genom disken och bänkarna — de syntes men fanns inte.
     Koordinaterna är hallens, alltså husets: hallen ligger i norr,
     y från langd−entre och uppåt. gang är fri passage mot sargporten
     så att vägen in aldrig blockeras av en möbel. */
  hallMobler:[
    {id:"disk",     rekt:{x:8.2, y:68.2, w:3.4, h:0.9}},
    {id:"bank1",    rekt:{x:0.8, y:64.2, w:0.7, h:1.8}},
    {id:"bank2",    rekt:{x:0.8, y:66.4, w:0.7, h:1.8}},
    {id:"bank3",    rekt:{x:0.8, y:68.6, w:0.7, h:1.8}},
    {id:"kansli",   rekt:{x:6.3, y:62.4, w:0.3, h:9.4}},
    {id:"omkl",     rekt:{x:18.5, y:68.4, w:0.3, h:4.4}},
    {id:"trapphus", rekt:{x:19.0, y:66.6, w:1.4, h:2.8}},
  ],
  dorrar:[
    {id:"ut_o", pos:[24.2,5],    text:"Ut till gräsgården", mot:"gard",
     spawn:{x:144.6,y:49,rikt:0}},
    /* HÄSTGÅNGEN till stallet: leder in i stallets klubbdel utan att man
       behöver gå ut på gården. Husen är sammanbyggda. */
    {id:"hastgang", pos:[24.0,65.0], text:"Hästgången — in i stallet",
     mot:"stallinne", spawn:{x:1.6,y:44.0,rikt:0}},
    {id:"ut_n", pos:[21.9,74.2], text:"Ut mot parkeringen (entrén)", mot:"gard",
     spawn:{x:139.9,y:120.6,rikt:Math.PI/2}},
  ],
  info:[
    {pos:[22.2,65.1], text:"Trappan till Café Krubban",
     svar:"Café Krubban har stängt för kvällen. Genom fönsterbanden ser man hela banan från borden där uppe."},
    {pos:[23.6,7],  text:"Domarbåset",
     svar:"Domarbåset — härifrån döms hoppklasserna på Påskhoppet. En trappa, en pall och bästa utsikten i huset."},
    {pos:[10.6,0.8],text:"Hinderförrådet",
     svar:"Hinderförrådet: bommar i blått, vitt och rött, kandelabrar, koner och cavaletti. ”HINDERSTÖD MED KLÄMHÅLLARE”, står det på lappen."},
  ],
};

STALLINNE.info=[
  {pos:[6.2,49.6], text:"Klubbrummet — rosettväggen", klubb:true,
   svar:"Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Här väntar man in sin lektion."},
  {pos:[6.2,44.4], text:"Sadelkammaren", sadelkammare:true, svar:""},
  {pos:[8.8,47.5], text:"Teorilektion i teorisalen", teori:true,
   svar:""},
  {pos:[6.2,5.8],  text:"Spolspiltan", spolspilta:true, svar:""},
  {pos:[8.8,5.8],  text:"Spånförrådet",
   svar:"Spånförrådet: Mustang kutterspån på pall i galvad bur. Härifrån hämtas spånet du strör med när boxen är mockad."},
];

/* ── Varje ritad dörr ska gå att gå in genom ────────────────────────
   Dörrlistan ovan var handskriven, och husen ritade fler dörrar än den
   kände till — man stod framför en dörr, tryckte E och ingenting hände.
   Här genereras resten ur fasadöppningarna i stället: varje öppning i
   marknivå som är en dörr eller port på ridhuset eller stallet får en
   interaktionspunkt strax utanför och en spawn strax innanför. Redan
   listade dörrar vinner — de har egna texter och exakta spawnpunkter.

   Byggnadens inre koordinatsystem har origo i husets sydvästra hörn,
   så innerpunkten är världspunkten minus hörnet; det är samma tal i
   STALLINNE och RIDHUSINNE eftersom insidorna byggs i husets mått. */
(function autoDorrar(){
  const INNE={ridhus:{mot:"ridhusinne",matt:RIDHUSINNE},
              stall: {mot:"stallinne", matt:STALLINNE}};
  const DORR=/^(dorr|port)/;
  const TEXT={ridhus:"In i ridhuset", stall:"Gå in i stallet"};
  /* Fasadens p0→p1, medurs sett utifrån — samma konvention som
     ritningen i world.js, så u betyder samma sak här som där. */
  const vagg=(r,sida)=>
    sida==="S"?[[r.x,r.y],[r.x+r.w,r.y]]:
    sida==="E"?[[r.x+r.w,r.y],[r.x+r.w,r.y+r.h]]:
    sida==="N"?[[r.x+r.w,r.y+r.h],[r.x,r.y+r.h]]:
               [[r.x,r.y+r.h],[r.x,r.y]];
  const NORM={S:[0,-1], N:[0,1], E:[1,0], W:[-1,0]};
  for(const bg of ANL.byggnader){
    const inne=INNE[bg.id]; if(!inne)continue;
    for(const o of (bg.oppningar||[])){
      if(!DORR.test(o.typ)||o.z0>0.2)continue;
      /* Öppningar mot en sammanbyggd granne leder inte ut på gården. */
      if(o.intern)continue;
      const [p0,p1]=vagg(bg.rekt,o.sida);
      const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]);
      const ux=(p1[0]-p0[0])/L, uy=(p1[1]-p0[1])/L, u=o.u+o.b/2;
      const mx=p0[0]+ux*u, my=p0[1]+uy*u;                 // mitt i öppningen
      const n=NORM[o.sida];
      const utx=mx+n[0]*1.1, uty=my+n[1]*1.1;             // markören utanför
      if(ANL.dorrar.some(d=>Math.hypot(d.pos[0]-utx,d.pos[1]-uty)<4))continue;
      const ix=mx-n[0]*1.6-bg.rekt.x, iy=my-n[1]*1.6-bg.rekt.y;   // spawn innanför
      /* En dörr som landar mitt i en boxrad går inte att gå ut genom —
         den hör till en planform stallet ännu inte har (dubbelstallet,
         se stallkortet). Hoppa hellre över den än att sätta en dörr som
         bara fungerar åt ena hållet. */
      if(bg.id==="stall"){
        const M=inne.matt;
        if(!M.gangytor.some(g=>ix>=g.x-0.4&&ix<=g.x+g.w+0.4
                             &&iy>=g.y-0.4&&iy<=g.y+g.h+0.4))continue;
      }
      ANL.dorrar.push({
        id:bg.id+"_"+o.sida+"_"+Math.round(o.u), pos:[utx,uty],
        text:TEXT[bg.id], mot:inne.mot, auto:true,
        spawn:{x:clamp(ix,0.9,inne.matt.bredd-0.9),
               y:clamp(iy,0.9,inne.matt.langd-0.9),
               rikt:Math.atan2(-n[1],-n[0])}});
      /* Motsvarande utgång inifrån, på samma ställe. */
      (inne.matt.dorrar||[]).push({
        id:"ut_"+bg.id+"_"+o.sida+"_"+Math.round(o.u),
        pos:[clamp(ix,0.9,inne.matt.bredd-0.9),clamp(iy,0.9,inne.matt.langd-0.9)],
        text:"Ut", mot:"gard", auto:true,
        spawn:{x:utx, y:uty, rikt:Math.atan2(n[1],n[0])}});
    }
  }
})();
