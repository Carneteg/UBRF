import fs from "node:fs";
import vm from "node:vm";

const src=fs.readFileSync("src/larare.js","utf8");
let fel=0;
function ok(v,msg){
  if(v) console.log(`OK   ${msg}`);
  else { console.error(`FEL  ${msg}`); fel++; }
}

/* Kontraktskontroller: namn, pedagogik och responsiv UX. */
ok(/namn:\s*"Ugneta"/.test(src),"instruktören heter Ugneta");
ok(/har:\s*"grått"/.test(src),"Ugneta har grått hår");
ok(/glasogon:\s*true/.test(src),"Ugneta har glasögon");
ok(/slice\(0,2\)/.test(src),"aktiv feedback begränsas till högst två punkter");
ok(/@media\(max-width:560px\)/.test(src),"mobil-layout finns");
ok(/@media\(max-height:560px\).*orientation:landscape/s.test(src),"låg landscape-layout finns");
ok(/clamp\(13px,1\.8vw,15px\)/.test(src),"feedbacktext skalar responsivt");
ok(/ugneta-korttext/.test(src),"momentets brödtext kortas i G02-C-läget");
ok(/ugnetaAterstallSagaUX/.test(src),"vanliga/säkerhetsmeddelanden återställer Ugneta-styling");
ok(!/Math\.random\s*\(/.test(src),"undervisningsval och feedback är deterministiska");
ok(/feedback:\s*\(\)=>/.test(src),"feedback kommer från mätbar ridstate");
ok(/berom:\s*\(\)=>/.test(src),"specifikt beröm finns");
ok(/lararMeddelande\(/.test(src)&&/ugnetaNasta/.test(src),"Ugneta-metadata följer lärarrepliken till UI:t");

for(const namn of ["Halt → skritt","Skritt → trav","20 m volt","Rid genom hörnet","Trav → skritt","Galoppfattning"])
  ok(src.includes(namn),`första lektionspaketet innehåller: ${namn}`);

const langa=[...src.matchAll(/feedback:\(\)=>\s*"([^"]+)"/g)].map(m=>m[1]).filter(t=>t.length>72);
ok(langa.length===0,"direkt feedback hålls kort (≤72 tecken för enkla feedbackrader)");

/* Kör träningsmotorn isolerat. larare.js gör inget DOM-arbete när window
   saknas, så samma produktionsfunktioner kan provas utan en kopia av logiken. */
const ctx={console};
vm.createContext(ctx);
vm.runInContext(fs.readFileSync("src/riding/ovningsdef.js","utf8")+"\n"+src+`\nglobalThis.__UG={
  kvalitet:ugnetaKvalitet,
  jamfor:ugnetaJamfor,
  forsta:ugnetaForstaForsok,
  medel:ugnetaForsokMedel,
  dims:UGNETA_OVNING_DIM,
  meddela:lararMeddelande,
  larare:LARARE
};`,ctx);

ctx.G={
  momentIx:2,momentT:12,momentKlart:false,
  telemetri:{svangradie:10,balans:.82,mjukhet:.76,fokus:.8,spanning:.2,svarstid:.12,etableringstid:.8,paradKvalitet:.7,fart:3.0,onskadFart:3.1},
  ride:{tempo:3.0,balans:.82,mjukhet:.76,fokus:.8,spanning:.2,skala:{rakriktning:.78,takt:.81,schvung:.7,kontakt:.7,samling:.6}},
  aids:{tygel:.4},grupp:"grupp2",dagsform:.8,
};
const q=ctx.__UG.kvalitet();
ok(q.linje>.75,"20 m-radie + rakriktning ger hög linjekvalitet");
ok(q.rytm>.8,"rytmen läses ur utbildningsskalans takt");
ok(q.balans>.8,"balansen läses ur hästens svar");
ok(q.mjukhet>.7,"mjukheten läses ur telemetrin");
ok(q.respons>.7,"hästens respons väger fokus, spänning och svarstid");

ok(JSON.stringify(ctx.__UG.dims.storvolt)===JSON.stringify(["linje","rytm","balans"]),
  "20 m volt bedömer linje + rytm + balans");
for(const id of ["halt_skritt","skritt_trav","trav_skritt"])
  ok(JSON.stringify(ctx.__UG.dims[id])===JSON.stringify(["timing","mjukhet","respons"]),
    `${id} bedömer timing + mjukhet + hästens respons`);

const j=ctx.__UG.jamfor("storvolt",
  {linje:.55,rytm:.61,balans:.60},
  {linje:.72,rytm:.68,balans:.59},2);
ok(j.punkter.length<=2,"försök-jämförelsen ger högst två observationer");
ok(j.punkter.some(x=>/Bättre linjen/.test(x)),"försök 2 kan identifiera faktisk förbättring i linjen");

ctx.__UG.meddela("test","Rubrik",["ett","två","tre"],"");
ok(ctx.__UG.larare.ugnetaNasta.punkter.length===2,"även runtime-metadata kapar tredje punkten");

if(fel){console.error(`\n${fel} Ugneta-kontroller föll.`);process.exit(1);}

/* ══ G02-D: SAKNAT ÄR VARKEN NOLL ELLER FULL POTT ═══════════════════
   Specen (docs/RIDANALYS.md): "If a metric is unavailable, say so ...
   do not turn missing data into a neutral or positive score."

   Mätt före rättelsen, i den byggda sidan: en ritt UTAN mätvärden gav
   linje/rytm/balans/mjukhet = 0 (sämsta betyg) och samtidigt tempo = 1,0
   (full pott). Samma tomma försök kunde alltså både sågas på fyra
   dimensioner och berömmas på en. */
{
  const sparaG = ctx.G;

  ctx.G = { telemetri:{}, ride:{skala:{}} };
  const tomt = ctx.__UG.kvalitet();
  ok(Object.values(tomt).every(v => v === null),
     "en ritt utan mätvärden ger null i ALLA dimensioner, inte betyg");
  ok(tomt.tempo === null,
     "särskilt tempot — det gav förut 1,0, alltså full pott på en omätt ritt");

  ctx.G = { telemetri:{balans:0,fokus:0,spanning:1,mjukhet:0,svarstid:0,fart:0,onskadFart:2},
            ride:{tempo:0,skala:{takt:0,rakriktning:0}} };
  const noll = ctx.__UG.kvalitet();
  ok(noll.balans === 0 && noll.rytm === 0 && noll.mjukhet === 0,
     "men ett värde som FAKTISKT mättes till noll blir noll");
  ok(noll.balans !== tomt.balans && noll.rytm !== tomt.rytm,
     "uppmätt noll och omätt går alltså att skilja åt");

  ctx.G = { telemetri:{balans:NaN,mjukhet:Infinity,fart:-Infinity},
            ride:{skala:{takt:NaN}} };
  const trasigt = ctx.__UG.kvalitet();
  ok(trasigt.balans === null && trasigt.mjukhet === null && trasigt.rytm === null,
     "NaN och oändlighet blir null, aldrig ett betyg");

  ctx.G = sparaG;
}

/* ══ G02-D: ÅTERKOPPLINGEN LJUGER INTE OM DET SOM INTE MÄTTES ══════ */
{
  const inget = {linje:null,rytm:null,balans:null,timing:null,mjukhet:null,respons:null,tempo:null};
  const f = ctx.__UG.forsta("storvolt", inget);
  ok(/kunde inte bedömas/i.test(f.rubrik),
     "ett obedömbart försök får ett sanningsenligt kort, inte ett påhittat betyg");
  ok(!f.punkter.some(p => /^Bra /.test(p)),
     "och absolut inget beröm för något ingen har mätt");

  const halvt = {linje:0.9,rytm:null,balans:0.4,timing:null,mjukhet:null,respons:null,tempo:null};
  const h = ctx.__UG.forsta("storvolt", halvt);
  ok(h.punkter.some(p => /linjen/i.test(p)) && !h.punkter.some(p => /rytmen/i.test(p)),
     "en omätt dimension blir varken bäst eller sämst — bara de mätta rankas");

  const f1 = {linje:0.50, rytm:null, balans:0.70};
  const f2 = {linje:0.74, rytm:0.60, balans:0.52};
  const j = ctx.__UG.jamfor("storvolt", f1, f2, 2);
  ok(j.punkter.some(p => /linjen/i.test(p)),
     "jämförelsen pekar ut den dimension som mättes i BÅDA försöken");
  ok(!j.punkter.some(p => /Bättre rytmen/i.test(p)),
     "och påstår ingen förbättring i en dimension som saknades förra gången");

  const badaTomma = ctx.__UG.jamfor("storvolt", {linje:null}, {linje:null}, 2);
  ok(/kunde inte bedömas/i.test(badaTomma.rubrik),
     "två obedömbara försök jämförs inte — de redovisas som obedömda");
}

/* ══ G02-D: UNDERLAGET RÄKNAS I SEKUNDER, INTE BILDRUTOR ══════════ */
{
  const bygg = (antal, sek) => ({
    sum:{linje:antal*0.8}, antal:{linje:antal}, sek:{linje:sek}, n:antal });
  const foretag = ctx.__UG.medel(bygg(2, 1.0));
  ok(foretag.linje !== null, "två sampel över en sekund räcker som underlag");
  ok(Math.abs(foretag.linje - 0.8) < 1e-9, "och medelvärdet är de mätta sampelns");
  ok(ctx.__UG.medel(bygg(1, 5)).linje === null,
     "ett enda sampel räcker inte, hur länge det än varade");
  ok(ctx.__UG.medel(bygg(120, 0.4)).linje === null,
     "och 120 bildrutor på fyra tiondelar räcker inte heller — sekunder avgör");
}

/* SLUTRADEN LJÖG.

   Funktionen `ok()` räknade upp `fel`, men filen avslutades med ett
   ovillkorligt "ALLA UGNETA-KONTROLLER OK" och exitkod 0 — oavsett hur
   många kontroller som fallit. Ett rött prov såg alltså grönt ut för
   CI, för `kor()`-skript och för den som läser sista raden.

   Upptäckt under G02-D:s falsifiering: en mutation som gjorde saknat
   till noll igen gav fortfarande "ALLA OK" och exitkod 0. Det var inte
   koden som var rätt — det var provet som inte kunde bli rött.

   Samma lärdom som roblox/tests/kor.sh skrevs för: exitkoden är den
   enda signalen som inte går att lura genom att skriva rätt text. */
if (fel === 0) {
  console.log("\nALLA UGNETA-KONTROLLER OK");
} else {
  console.error(`\n${fel} FEL — Ugneta-kontrollerna gick INTE igenom`);
  process.exit(1);
}
