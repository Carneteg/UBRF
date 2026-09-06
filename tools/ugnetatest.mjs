import fs from "node:fs";

const src=fs.readFileSync("src/larare.js","utf8");
let fel=0;
function ok(v,msg){
  if(v) console.log(`OK   ${msg}`);
  else { console.error(`FEL  ${msg}`); fel++; }
}

ok(/namn:\s*"Ugneta"/.test(src),"instruktören heter Ugneta");
ok(/har:\s*"grått"/.test(src),"Ugneta har grått hår");
ok(/glasogon:\s*true/.test(src),"Ugneta har glasögon");
ok(/slice\(0,2\)/.test(src),"aktiv feedback begränsas till högst två punkter");
ok(/@media\(max-width:560px\)/.test(src),"mobil-layout finns");
ok(/@media\(max-height:560px\).*orientation:landscape/s.test(src),"låg landscape-layout finns");
ok(/clamp\(13px,1\.8vw,15px\)/.test(src),"feedbacktext skalar responsivt");
ok(!/Math\.random\s*\(/.test(src),"undervisningsval och feedback är deterministiska");
ok(/feedback:\s*\(\)=>/.test(src),"feedback kommer från mätbar ridstate");
ok(/berom:\s*\(\)=>/.test(src),"specifikt beröm finns");
ok(/lararMeddelande\(/.test(src)&&/ugnetaNasta/.test(src),"Ugneta-metadata följer lärarrepliken till UI:t");

for(const namn of ["Halt → skritt","Skritt → trav","20 m volt","Rid genom hörnet","Trav → skritt","Galoppfattning"])
  ok(src.includes(namn),`första lektionspaketet innehåller: ${namn}`);

const langa=[...src.matchAll(/feedback:\(\)=>\s*"([^"]+)"/g)].map(m=>m[1]).filter(t=>t.length>72);
ok(langa.length===0,"direkt feedback hålls kort (≤72 tecken för enkla feedbackrader)");

if(fel){console.error(`\n${fel} Ugneta-kontroller föll.`);process.exit(1);}
console.log("\nALLA UGNETA-KONTROLLER OK");
