#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Fanns inte förut, och det kostade: jag räknade rader som börjar med "FEL"
# och fick noll — men specen hade KRASCHAT och aldrig hunnit skriva någon.
# En krasch såg alltså ut som grönt. Nu krävs TRE saker: att luau avslutar med
# kod 0, att inga FEL skrevs, och att specen nådde sin slutrad. Exitkoden är
# den enda av dem som inte går att lura genom att skriva rätt text.
#
# ANDRA HÅLET, tätat i efterhand: den här körde bara de FÄRDIGBYGGDA specarna
# och byggde dem aldrig. Den rapporterade alltså om .build/ — inte om koden på
# disk. Under ett falsifieringspass gav det både falskt rött och falskt grönt,
# beroende på vilken mutation som råkade ligga kvar i .build/. Bygget hör till
# körningen och görs nu här, varje gång.
cd "$(dirname "$0")/.." || exit 1
SPECAR="geometri bygge movement camera rider touch preparation"
byggargs=""
for f in $SPECAR; do byggargs="$byggargs tests/$f.spec.luau"; done
if ! bygglogg=$(python3 tests/build.py $byggargs 2>&1); then
  echo "BYGGET AV SPECARNA MISSLYCKADES"
  printf '%s\n' "$bygglogg" | tail -10
  exit 1
fi
status=0
for f in $SPECAR; do
  ut=$(luau "tests/.build/$f.spec.luau" 2>&1)
  kod=$?
  fel=$(printf '%s\n' "$ut" | grep -cE '^[[:space:]]*FEL')
  slut=$(printf '%s\n' "$ut" | grep -cE 'alla gröna|Alla mätningar gick igenom')
  if [ "$kod" -ne 0 ]; then
    printf '%-12s LUAU AVSLUTADE MED KOD %s\n' "$f" "$kod"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/             /'
    status=1
    continue
  fi
  if [ "$fel" -eq 0 ] && [ "$slut" -ge 1 ]; then
    printf '%-12s OK\n' "$f"
  elif [ "$slut" -eq 0 ]; then
    printf '%-12s KRASCH — specen nådde aldrig sin slutrad\n' "$f"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/             /'
    status=1
  else
    printf '%-12s %s FEL\n' "$f" "$fel"
    printf '%s\n' "$ut" | grep -E '^[[:space:]]*FEL' | head -6 | sed 's/^/             /'
    status=1
  fi
done
exit $status
