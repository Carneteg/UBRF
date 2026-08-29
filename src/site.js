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
   långsidan, fodersilon vid norra gaveln, hagarna öster om stallet och
   utebanorna nordost om dem.
   Geometrin här är den enda sanningen — rendering läser bara detta.
   ══════════════════════════════════════════════════════════════════ */

/* Fasadernas u löper moturs runt huset: på västra långsidan räknas den
   från NORRA gaveln, på östra från den södra. Stallets foton och kort
   beskriver allt som avstånd från södra gaveln, så omräkningen görs här
   en gång i stället för i huvudet varje rad. Stallet är 54 m långt. */
const sV = s => 54 - s;

/* Stallets långsidor har ett valvbågat fönster per box, i samma takt som
   boxarna innanför (STALLINNE: boxarna börjar 10,4 m in och är 3,5 m
   breda). Rytmen är byggnadens tydligaste drag på håll — därför räknas
   den fram ur samma tal i stället för att skrivas av för hand. */
function stallFonster(sida){
  const ut=[];
  for(let i=0;i<10;i++){
    const s=10.4+3.5*i+1.75;
    ut.push({sida, u:sida==="W"?sV(s):s, b:1.15, h:1.55, z0:1.55, typ:"valv"});
  }
  return ut;
}

const ANL = {
  bredd: 210, djup: 170,

  /* Markytor ritas i ordning — senare vinner. */
  mark: [
    {typ:"gras",  rekt:{x:0,   y:0,   w:210, h:170}},
    {typ:"aker",  rekt:{x:0,   y:44,  w:112, h:80}},   // åkrarna väster om grusvägen
    {typ:"asfalt",rekt:{x:0,   y:2,   w:210, h:5}},    // Husbyvägen
    {typ:"grus",  rekt:{x:106, y:7,   w:16,  h:14}},   // infarten
    {typ:"grus",  rekt:{x:112, y:16,  w:38,  h:28}},   // grusparkeringen vid södra gaveln
    {typ:"grus",  rekt:{x:112, y:44,  w:6,   h:85}},   // grusvägen längs västra långsidan
    {typ:"grus",  rekt:{x:112, y:119, w:34,  h:14}},   // vägen svänger runt norra gaveln
    {typ:"grus",  rekt:{x:144, y:20,  w:48,  h:26}},   // gårdsplanen vid stallentrén
    {typ:"grus",  rekt:{x:166, y:44,  w:10,  h:60}},   // gången öster om stallet mot hagarna
    {typ:"grus",  rekt:{x:150, y:102, w:26,  h:8}},    // bakgården vid silon
    {typ:"grus",  rekt:{x:168, y:104, w:10,  h:46}},   // gången upp till banorna
    {typ:"sand",  rekt:{x:176, y:106, w:20,  h:40}},   // uteridbanan (dressyr 20×40)
    {typ:"sand",  rekt:{x:150, y:112, w:20,  h:34}},   // grusbanan/paddocken bredvid
    {typ:"betong",rekt:{x:170, y:100, w:6,   h:5}},    // betongplattan vid uppgången
  ],
  cirklar: [ // runda markytor
    {typ:"sand", c:[151,31], r:4.6, kant:true},        // lekhagen med stenhästarna
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
         · södra gaveln mot parkeringen: dubbeldörren i väster med
           valvfönstret över, den svarta dörren under sitt vita
           skärmtak, och i öster Café Krubban med fyra valvbågade
           fönster, balkong och utvändig ståltrappa
       Banan 20×60 därinne; UBRF-skylten mitt på västra långsidan. */
    {id:"ridhus", rekt:{x:118, y:44, w:25, h:75}, hV:6.2, hN:9.2, nock:"NS",
     fargV:"#872F40", fargT:"#202022", svart:"#202022", plat:true,
     list:4.10, takfot:true, detalj:"ridhus", label:"RIDHUSET",
     oppningar:[
       {sida:"S", u:3.1, b:1.8, h:2.2, z0:0,   typ:"dorrvit", skarm:2.6}, // dubbeldörren
       {sida:"S", u:3.3, b:1.20,h:1.55,z0:4.45,typ:"valv"},   // valvfönstret över entrén
       {sida:"S", u:8.1, b:1.1, h:2.1, z0:0,   typ:"dorr", skarm:2.1},    // svarta dörren
       {sida:"S", u:20.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},   // caféet, nedre våningen
       {sida:"S", u:24.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},
       {sida:"S", u:20.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},   // caféet, övre våningen
       {sida:"S", u:24.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},
       {sida:"S", u:22.3,b:1.0, h:2.05,z0:4.02,typ:"dorr"},   // cafédörren mot balkongen
       /* Västra långsidan, mot vägen. Street View visar en lång
          entrékvist närmast caféet, den svarta dörren vid UBRF-skylten
          och en rad små fyrkantsfönster högt uppe. */
       {sida:"W", u:66, b:2.0, h:2.2, z0:0,    typ:"dorrvit"},  // dubbeldörrarna under kvisten
       {sida:"W", u:45, b:1.1, h:2.1, z0:0,    typ:"dorr"},     // svarta dörren vid skylten
       {sida:"W", u:14, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:22, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:30, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"E", u:22, b:3.4, h:2.9, z0:0, typ:"portplat"}, // durkplåtdörrarna mot gården
       {sida:"N", u:8,  b:4.0, h:3.6, z0:0, typ:"portsilver"},// stora silverporten
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
         · förstukvisten på västra långsidan, 5,6 m från södra gaveln:
           ockragul dörr, runda fönster, vitt ribbräcke
         · södra gaveln: valvfönster, balkongdörr och spiraltrappa */
    {id:"stall", rekt:{x:154, y:46, w:15, h:54}, hV:4.4, hN:8.4, nock:"NS",
     fargV:"#6E2F44", fargT:"#5E646C", svart:"#26292E", takfot:"#EEECE4",
     detalj:"stall", sockel:0.35, label:"STALLET",
     oppningar:[
       /* Förstukvisten på västra långsidan. */
       {sida:"W", u:sV(5.6), b:1.15, h:2.10, z0:0,    typ:"dorrgul"},  // ockragula entrédörren
       {sida:"W", u:sV(4.0), b:0.66, h:0.66, z0:1.78, typ:"rund"},     // runda fönstren vid dörren
       {sida:"W", u:sV(7.2), b:0.66, h:0.66, z0:1.78, typ:"rund"},
       {sida:"W", u:sV(2.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},     // valvfönster kring kvisten
       {sida:"W", u:sV(8.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},
       ...stallFonster("W"), ...stallFonster("E"),
       /* Södra gaveln — den höga, med balkongen och spiraltrappan. */
       {sida:"S", u:3.4,  b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"S", u:11.6, b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"S", u:5.4,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"S", u:9.6,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"S", u:7.5,  b:0.95, h:2.05, z0:4.60, typ:"dorrvit"},     // balkongdörren
       /* Stora skjutporten mitt på östra långsidan, mot hagarna. */
       {sida:"E", u:24, b:3.6, h:3.2, z0:0, typ:"portbla"},
       /* Norra gaveln: servicedelens dubbeldörr. [saknas foto] */
       {sida:"N", u:6.1,  b:2.8,  h:2.7,  z0:0, typ:"dorrgra"},
       /* Vita dubbeldörren mot gräsgården. */
       {sida:"W", u:25,   b:1.8,  h:2.2,  z0:0, typ:"dorrvit"},
     ]},
    /* Förbindelselängan som gör stallet till ett L och stänger gården. */
    {id:"langa", rekt:{x:144, y:100, w:10, h:6}, hV:3.0, hN:4.4, nock:"EW",
     fargV:"#7C2A24", fargT:"#7E8288", label:"",
     oppningar:[{sida:"S", u:4.4, b:1.1, h:2.0, z0:0, typ:"dorrmork"}]},
    /* Röda stugan vid infarten (förråd/sekretariat). */
    {id:"stuga", rekt:{x:94, y:12, w:6.5, h:4.5}, hV:2.5, hN:3.8, nock:"EW",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"E", u:1.2, b:1.6, h:0.9, z0:1.1, typ:"fonster"},
                {sida:"S", u:1.6, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Domarkuren vid uteridbanan. */
    {id:"domarkur", rekt:{x:184, y:148, w:4.5, h:3.5}, hV:2.3, hN:3.4, nock:"EW",
     fargV:"#8A3A30", fargT:"#5A2B26", label:"",
     oppningar:[{sida:"W", u:0.8, b:2.6, h:1.0, z0:1.0, typ:"fonster"}]},
    /* Boden vid norra gaveln (vid sopstationen). */
    {id:"bod", rekt:{x:172, y:150, w:5, h:4}, hV:2.3, hN:3.4, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"S", u:1.4, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Elcentralen/boden vid stigen mot banorna. */
    {id:"elbod", rekt:{x:171, y:96, w:3, h:2.5}, hV:2.0, hN:2.8, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"", oppningar:[]},
  ],

  /* Staket: postlinjer. "tra" = kraftigt trästaket med två reglar
     (banor och hagar), "el" = trådstängsel mot åkern, "rail" = låg
     falurödmålad trärail (parkering/lekhage). */
  staket: [
    {typ:"tra", p:[[176,106],[196,106],[196,146],[176,146],[176,106]]},// uteridbanan
    {typ:"tra", p:[[150,112],[170,112],[170,146],[150,146],[150,112]]},// paddocken bredvid
    {typ:"tra", p:[[176,44],[206,44],[206,72],[176,72],[176,44]]},     // hage Ö1
    {typ:"tra", p:[[176,76],[206,76],[206,100],[176,100],[176,76]]},   // hage Ö2
    {typ:"el",  p:[[112,44],[112,119]]},                               // trådstängsel mot åkern
    {typ:"rail",p:[[112,42],[150,42]]},                                // rail mot parkeringen
    {typ:"rail",p:[[146,26],[146,36]]},                                // rail vid lekhagen
  ],
  hagar: [ // betande hästar (id ur HORSES) för liv i bilden
    {rekt:{x:176,y:44,w:30,h:28}, hastar:["cosmo","air","mara"]},
    {rekt:{x:176,y:76,w:30,h:24}, hastar:["larry","husky","westside","lydia"]},
    {rekt:{x:150,y:112,w:20,h:34}, hastar:["toblerone","dexter","chip"]},
  ],

  /* Träd: [x, y, radie]. Skogsbryn i norr och väster, björkraden
     längs grusvägen, lövträden runt gårdsplanen. */
  trad: [
    [110,50,1.6],[110,62,1.7],[110,74,1.6],[110,86,1.8],[110,98,1.6],  // björkraden
    [122,14,2.6],[130,12,2.2],[88,10,2.6],[104,24,1.8],
    [150,16,2.8],[160,18,2.4],[172,16,2.8],[184,20,2.6],[196,24,3.0],
    [194,36,2.6],[208,60,3.0],[208,90,3.2],[206,106,2.8],
    [60,118,3.0],[56,130,3.4],[58,144,3.0],[62,158,3.2],[70,164,3.0],
    [80,166,3.4],[92,168,3.0],[104,166,3.2],[116,166,3.0],[128,164,3.4],
    [140,162,3.0],[150,158,2.8],[160,150,2.6],[120,158,2.4],[88,160,2.8],
    [46,120,3.2],[40,132,3.0],[44,148,3.4],[36,160,3.0],
    [144,120,2.2],[146,132,2.0],[200,158,2.6],[192,164,3.0],
  ],

  /* Rekvisita — ritas i 2D och 3D av world.js. */
  props: [
    {typ:"silo",      pos:[171,102]},                    // fodersilon vid norra gaveln
    {typ:"balar",     pos:[160,105]},                    // ensilagebalarna
    {typ:"grushog",   pos:[152,104]},
    {typ:"transport", pos:[147,23], rikt:0.5},           // hästtransporten på grusplanen
    {typ:"bord",      pos:[150,60]},                     // picknickborden på gräsgården
    {typ:"bord",      pos:[148,72]},
    {typ:"bank",      pos:[146,80]},
    {typ:"stol",      pos:[149,88]},
    {typ:"bord",      pos:[158,38]},                     // gårdsplanens möbler
    {typ:"bank",      pos:[164,40]},
    {typ:"skylt",     pos:[118,82], text:"UPPLANDS-BRO RYTTARFÖRENING", norm:[-1,0]},
    {typ:"cafeskylt", pos:[135.4,43.8], norm:[0,-1]},   // skylten vid trappans fot
    {typ:"flagga",    pos:[107,15]},
    {typ:"vagvisare", pos:[151.5,57]},   // vägvisaren med åtta armar
    {typ:"stenhast",  pos:[149.5,29.5]},                 // stenhästarna i lekhagen
    {typ:"stenhast",  pos:[152.5,32]},
    {typ:"stenhast",  pos:[150.5,33]},
    {typ:"stenhast",  pos:[152,29]},
    {typ:"mast",      pos:[176,146]},                    // belysningsmasterna vid banorna
    {typ:"mast",      pos:[196,106]},
    {typ:"mast",      pos:[150,146]},
    {typ:"sopstation",pos:[147,104]},
    {typ:"ac",        pos:[143.4,54], norm:[1,0]},                   // värmepumparna mot gården
    {typ:"ac",        pos:[143.4,58], norm:[1,0]},
    {typ:"busskylt",  pos:[118,7.6]},
  ],

  /* Interaktionspunkter på gården. */
  dorrar: [
    {id:"stallentre", pos:[152.9,51.6], text:"Gå in i stallet (Entré)",
     mot:"stallinne", spawn:{x:1.8, y:5.6, rikt:0}},
    {id:"stall_v",  pos:[153.6,71], text:"Gå in i stallet (gårdsdörren)",
     mot:"stallinne", spawn:{x:1.2, y:25, rikt:0}},
    {id:"stall_n",  pos:[160.3,100.8], text:"Gå in i stallet (bakre dörren)",
     mot:"stallinne", spawn:{x:7.5, y:50, rikt:-Math.PI/2}},
    {id:"ridhus_o", pos:[143.4,66], text:"In i ridhuset (durkplåtdörrarna)",
     mot:"ridhusinne", spawn:{x:23.4,y:22,rikt:Math.PI}},
    {id:"ridhus_s", pos:[121.1,43.6], text:"In i ridhuset (entrén)",
     mot:"ridhusinne", spawn:{x:3.1,y:1.6,rikt:Math.PI/2}},
    {id:"cafe", pos:[136.6,43.4], text:"Café Krubban (trappan upp)", mot:"info",
     info:"Café Krubban har stängt för kvällen. Kolla in vyn över banan från läktaren i stället."},
  ],
  spawn: {x:113, y:10, rikt:Math.PI/2},   // vid infarten från Husbyvägen
  /* Hagen där dagens häst hämtas: grinden på västra sidan av hage Ö1. */
  hamtHage: {grind:[176,58], falt:[184,56]},
  skylt: {pos:[113,5.5], text:"HUSBYVÄGEN 1A · UPPLANDS-BRO RYTTARFÖRENING"},
};

/* ── Stallet invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 15), +y norr (längd 52).
      Söder: klubbdelen (uppehållsrum, teorisal, toaletter) innanför
      entrén — vit pärlspont, betonggolv. Branddörren in till stallet
      ("schysst stall"-dekalen). Mitten: stallgången — marksten, två
      rader boxar i antracitgrå komposit med galvade galler, namn-
      skyltar, limträbalkar och taklanterniner. Norr: servicedelen
      med spolspilta, spånförråd och uppbindningsplatser. ── */
const STALLINNE = {
  bredd:15, langd:52, ganghalva:2.6,
  vagg:"#CFC8BC", golv:"#8C8880", gangGolv:"#9A968E", tak:3.4,
  klubbY:9, boxStartY:10.4, serviceY:45.5,
  boxB:3.5, boxDjup:5.0,
  /* Boxrader: HORSES-id för spelbara hästar, "#NAMN" för boxar med
     riktiga namnskyltar ur fotona (LADY, WESTSIDE, MAKADU, KENNEDY,
     TINA, MARA, HUSKY, CHIP), null = tom box. */
  boxar:{
    W:[ "lady","toblerone","westside","lydia","makadu","conor","mara","hamilton","husky",null ],
    E:[ "kennedy","cosmo","tina","air","chip","larry","crokino","dexter",null,null ],
  },
  /* Klubbdelen: uppehållsrummet mot entrén, sadelkammaren innanför
     med de inre fönsterpartierna emellan (IMG_0141), teorisalen i
     öster. */
  rum:[
    {id:"uppehallsrum", rekt:{x:0,   y:0,   w:6.0, h:5.2}, label:"UPPEHÅLLSRUM"},
    {id:"sadelkammare", rekt:{x:0,   y:5.2, w:6.0, h:3.8}, label:"SADELKAMMARE"},
    {id:"teorisal",     rekt:{x:9.0, y:0,   w:6.0, h:9},   label:"TEORISAL · WC"},
  ],
  service:[
    {id:"spolspilta",   rekt:{x:0,   y:45.5, w:6.0, h:6.5}, label:"SPOLSPILTA"},
    {id:"spanforrad",   rekt:{x:9.0, y:45.5, w:6.0, h:6.5}, label:"SPÅNFÖRRÅD"},
  ],
  /* Tvärväggar med dörröppning i gångens bredd. */
  tvarvaggar:[ {y:9, gap:2.8, brand:true}, {y:45.5, gap:2.8, brand:false} ],
  dorrar:[
    {id:"ut_s", pos:[0.8,5.6],  text:"Ut genom entrén", mot:"gard",
     spawn:{x:152.6,y:51.6,rikt:Math.PI}},
    {id:"ut_v", pos:[0.8,25],   text:"Ut till gräsgården", mot:"gard",
     spawn:{x:152.6,y:71,rikt:Math.PI}},
    {id:"ut_n", pos:[7.5,51.2], text:"Ut till bakgården", mot:"gard",
     spawn:{x:160.3,y:101.8,rikt:Math.PI/2}},
  ],
  ridlarare:{pos:[7.5,18], namn:"Ridläraren"},
  whiteboard:{pos:[7.5,45.0]},   // veckoschemat vid spolspiltan (IMG_0154)
};

/* ── Ridhuset invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 26), +y norr (längd 65). Banan 20×60 innanför
      vit murad sarg med svart sockel (IMG_0095–0116): sponsorväggen
      med speglarna i väster, läktaren med domarbåset i öster,
      cafeteria-överbyggnaden med fönsterband och trappan i söder,
      hinderförrådet i norr. Sargporten vid A släpper in ekipagen. ── */
/* Ridhuset invändigt. Måtten kommer ur utrymningsplanen (se
   references/buildings/ridhus/KORT.md) med banans 20×60 som fast punkt:
   planens längder är ihoptryckta av perspektivet, men banans två kända
   mått ger skalan i båda led och resten faller ut.

     bredd  20 m bana + 4,4 m läktarband  = 25 m
     längd  60 m bana + 13 m gaveldel     = 75 m

   Gaveldelen i söder är entré, trapphus och café — inte en tre meter
   djup överbyggnad som förut. Går man in från parkeringen kommer man in
   i en hall, inte rakt ut på banan. */
const RIDHUSINNE = {
  bredd:25, langd:75, tak:6.2, entre:13,
  bana:{x:0.6, y:13, w:20, h:60}, sargH:1.35,
  vagg:"#E9E5DC", sockel:"#2E2E2C", sandFarg:"#5E4A36", gangFarg:"#8C8880",
  panel:"#6B4A34", panelList:"#EFE8D8",           // sponsorväggens bruna trä
  laktare:{x0:21.0, y0:16, y1:66, steg:4, stegH:0.28, stegD:0.85},
  domarbas:{x:23.4, y:68, b:1.8, h:2.2},
  cafe:{djup:13.0, z0:2.55, z1:5.4},               // överbyggnaden i söder
  trappa:{x:22.0, y:9.6},                          // trätrappan upp till caféet
  speglar:[ {y:38,b:4.2},{y:56,b:3.2} ],           // på västra långsidan
  skyltar:[
    {y:22,  b:5.0, text:"VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING", fg:"#3A3E44", bg:"#F2EDE2"},
    {y:28.5,b:4.0, text:"HUVUDSPONSOR ELON BARKARBY", fg:"#F0EADC", bg:"#1C1C1E"},
    {y:43.5,b:3.6, text:"Vi tror på dig! · Sparbanken i Enköping", fg:"#C0392B", bg:"#F7F2E8"},
    {y:48.5,b:3.0, text:"Agria Djurförsäkring", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:60,  b:3.4, text:"RS Mustang · Stallströ och foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:67,  b:3.6, text:"Stigsbergs Gård · Hästsportbutik", fg:"#3A3E44", bg:"#F2EDE2"},
  ],
  port:{x0:9.6, x1:11.6},                         // sargporten vid A (södra kortsidan)
  dorrar:[
    {id:"ut_o", pos:[24.2,22],   text:"Ut till gårdsplanen", mot:"gard",
     spawn:{x:144.6,y:66,rikt:0}},
    {id:"ut_s", pos:[3.1,0.8], text:"Ut mot parkeringen (entrén)", mot:"gard",
     spawn:{x:122.5,y:42.6,rikt:-Math.PI/2}},
  ],
  info:[
    {pos:[22.2,9.9], text:"Trappan till Café Krubban",
     svar:"Café Krubban har stängt för kvällen. Genom fönsterbanden ser man hela banan från borden där uppe."},
    {pos:[23.6,68],  text:"Domarbåset",
     svar:"Domarbåset — härifrån döms hoppklasserna på Påskhoppet. En trappa, en pall och bästa utsikten i huset."},
    {pos:[10.6,74.2],text:"Hinderförrådet",
     svar:"Hinderförrådet: bommar i blått, vitt och rött, kandelabrar, koner och cavaletti. ”HINDERSTÖD MED KLÄMHÅLLARE”, står det på lappen."},
  ],
};
/* Infopunkter i stallet (klubbdelen och servicedelen). */
STALLINNE.info=[
  {pos:[6.2,2.4],  text:"Klubbrummet — rosettväggen", klubb:true,
   svar:"Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Här väntar man in sin lektion."},
  {pos:[6.2,7.0],  text:"Sadelkammaren", sadelkammare:true, svar:""},
  {pos:[8.8,4.5],  text:"Teorilektion i teorisalen", teori:true,
   svar:""},
  {pos:[6.2,46.2], text:"Spolspiltan", spolspilta:true, svar:""},
  {pos:[8.8,46.2], text:"Spånförrådet",
   svar:"Spånförrådet: Mustang kutterspån på pall i galvad bur. Härifrån hämtas spånet du strör med när boxen är mockad."},
];
