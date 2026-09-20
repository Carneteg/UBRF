#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Fanns inte förut, och det kostade: jag räknade rader som börjar med "FEL"
# och fick noll — men specen hade KRASCHAT och aldrig hunnit skriva någon.
# En krasch såg alltså ut som grönt. Nu krävs TRE saker: att luau avslutar med
# kod 0, att inga FEL skrevs, och att specen nådde sin slutrad. Exitkoden är
# den enda av dem som inte går att lura genom att skriva rätt text.
#
# TREDJE RÄTTELSEN: krasch-grenen låg före FEL-grenen och testade bara att
# slutraden saknades. Men en spec som RAPPORTERAR fel skriver ingen slutrad
# heller — varje vanligt testfel såg alltså ut som en krasch, med "nådde
# aldrig sin slutrad" i loggen medan specen hade nått den och räknat upp
# precis vad som föll. Rött blev det, men av fel anledning i loggen. Nu
# kräver krasch-grenen att INGA fel skrevs.
#
# ANDRA HÅLET, tätat i efterhand: den här körde bara de FÄRDIGBYGGDA specarna
# och byggde dem aldrig. Den rapporterade alltså om .build/ — inte om koden på
# disk. Under ett falsifieringspass gav det både falskt rött och falskt grönt,
# beroende på vilken mutation som råkade ligga kvar i .build/. Bygget hör till
# körningen och görs nu här, varje gång.
cd "$(dirname "$0")/.." || exit 1
SPECAR="geometri spel spelkanon forberedelse skotselpass integration ledning ledning-integration promptkonflikt roster sprak sprak-en bygge mark handighet spelbuild forstaplayable preflight integritet statesync ridinput ridefirst tack tack-fas1 tack-fas2 tack-fas3 buren-tack hasthojd avsittning spelbarhet varldskoherens varldshud topologi qa sikt movement camera rider touch ljud driv-broms blick genomsikt paritet ugneta ugneta-gestalt klient klient-reservzon klient-hjalpknapp klient-ledprompt klient-naromrade klient-burenstatus klient-ridhandlingar ridanu-avslag tavlingsklader tavlingsklader-session coachbanner takt forstaritten klient-byggidentitet klient-lektionspaus fjarrdublett flerhast ledtakt ledspar klient-uikontext"
# #252 DEL B: banken provar SIG SJALV forst, i bada riktningarna. En
# require av en modul som inte ligger i bunten ska falla bygget — inte
# bli ett tyst nil (DEL A). Faller provet bygger vi inte en enda spec.
if ! python3 tests/testa-build.py; then
  echo "BANKENS SJALVPROV MISSLYCKADES"
  exit 1
fi
byggargs=""
for f in $SPECAR; do byggargs="$byggargs tests/$f.spec.luau"; done
if ! bygglogg=$(python3 tests/build.py $byggargs 2>&1); then
  echo "BYGGET AV SPECARNA MISSLYCKADES"
  printf '%s\n' "$bygglogg" | tail -10
  exit 1
fi
# Materialnamnen forst: ett ogiltigt Enum.Material faller bygget i Studio, och
# stubbarna kan bara fanga de material som en spec faktiskt rakar bygga.
# Skannern laser ALL Luau-kall.
if ! python3 ../tools/kolla-material.py; then
  echo "MATERIALKONTROLLEN MISSLYCKADES"
  exit 1
fi
# Grind 4 i kontraktet for kontextuell rid-UX: panelens kod ska vara BORTA
# ur kallan, inte slackt. Den maste lasa filerna pa disk -- en Luau-bank ser
# bara det som kompilerats in, och `Visible = false` kompilerar lika fint
# som en rivning. Kors har, tillsammans med den andra kallskannern.
if ! python3 ../tools/kolla-reglagepanel.py; then
  echo "REGLAGEPANELGRINDEN MISSLYCKADES"
  exit 1
fi
# #248 Fas A: tavlingskladernas katalog ska finnas EN gang. En kopierad
# ID-tabell i UI eller server kompilerar lika fint som ingen, sa den
# regeln maste lasas ur kallan. Samma skal som raden ovan.
if ! python3 ../tools/kolla-tavlingsklader.py; then
  echo "TAVLINGSKLADERGRINDEN MISSLYCKADES"
  exit 1
fi
# …och grinden sjalv provas i BADA riktningarna: en kopierad ID-literal
# ska ge rott, en laglig konsument som laser katalogens publika falt ska
# ge gront. Den andra riktningen ar den som gav CHANGES_REQUESTED pa 250.
if ! python3 ../tools/testa-kolla-tavlingsklader.py; then
  echo "GRINDPROVET FOR TAVLINGSKLADER MISSLYCKADES"
  exit 1
fi
# #259 Gate 0: en generisk haststack, och grindprovet bakom den.
#
# Den har grinden kordes bara i CI. Pa Windows foll den av en
# separatorbugg i undantagslistan, sa den som korde lokalt lardes att
# bortse fran den -- och da ar en grind samre an ingen. Nu ar den
# plattformsoberoende OCH kord harifran, sa den lokala sviten sager
# samma sak som CI.
if ! python3 ../tools/kolla-generisk-hast.py; then
  echo "GENERISK-HAST-GRINDEN MISSLYCKADES"
  exit 1
fi
if ! python3 ../tools/testa-kolla-generisk-hast.py; then
  echo "GRINDPROVET FOR GENERISK HAST MISSLYCKADES"
  exit 1
fi
# Grind 1 och 5 i kontraktet for Coach Banner (#244): Ugnetas gamla
# nederpanel ska vara BORTA ur kallan, och bannern ska inte ha nagon
# fordrojd tradd som kan komma tillbaka och slacka ny text. Samma skal
# som raden ovan -- en Luau-bank ser inte skillnad pa rivet och slackt.
if ! python3 ../tools/kolla-nederpanel.py; then
  echo "NEDERPANELGRINDEN MISSLYCKADES"
  exit 1
fi

status=0
for f in $SPECAR; do
  ut=$(luau "tests/.build/$f.spec.luau" 2>&1)
  kod=$?
  fel=$(printf '%s\n' "$ut" | grep -cE '^[[:space:]]*FEL')
  slut=$(printf '%s\n' "$ut" | grep -cE 'alla gröna|Alla mätningar gick igenom')
  if [ "$kod" -ne 0 ]; then
    printf '%-14s LUAU AVSLUTADE MED KOD %s\n' "$f" "$kod"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/           /'
    status=1
    continue
  fi
  if [ "$fel" -eq 0 ] && [ "$slut" -ge 1 ]; then
    printf '%-14s OK\n' "$f"
  elif [ "$fel" -eq 0 ] && [ "$slut" -eq 0 ]; then
    printf '%-14s KRASCH — specen nådde aldrig sin slutrad\n' "$f"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/           /'
    status=1
  else
    printf '%-14s %s FEL\n' "$f" "$fel"
    printf '%s\n' "$ut" | grep -E '^[[:space:]]*FEL' | head -6 | sed 's/^/           /'
    status=1
  fi
done
exit $status
