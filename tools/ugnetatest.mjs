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
console.log("\nALLA UGNETA-KONTROLLER OK");
