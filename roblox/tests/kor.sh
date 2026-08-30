#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Fanns inte förut, och det kostade: jag räknade rader som börjar med "FEL"
# och fick noll — men specen hade KRASCHAT och aldrig hunnit skriva någon.
# En krasch såg alltså ut som grönt. Nu krävs TRE saker: att luau avslutar med
# kod 0, att inga FEL skrevs, och att specen nådde sin slutrad. Exitkoden är
# den enda av dem som inte går att lura genom att skriva rätt text.
cd "$(dirname "$0")/.." || exit 1
status=0
for f in geometri bygge movement camera rider touch; do
  ut=$(luau "tests/.build/$f.spec.luau" 2>&1)
  kod=$?
  fel=$(printf '%s\n' "$ut" | grep -cE '^[[:space:]]*FEL')
  slut=$(printf '%s\n' "$ut" | grep -cE 'alla gröna|Alla mätningar gick igenom')
  if [ "$kod" -ne 0 ]; then
    printf '%-10s LUAU AVSLUTADE MED KOD %s\n' "$f" "$kod"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/           /'
    status=1
    continue
  fi
  if [ "$fel" -eq 0 ] && [ "$slut" -ge 1 ]; then
    printf '%-10s OK\n' "$f"
  elif [ "$slut" -eq 0 ]; then
    printf '%-10s KRASCH — specen nådde aldrig sin slutrad\n' "$f"
    printf '%s\n' "$ut" | tail -4 | sed 's/^/           /'
    status=1
  else
    printf '%-10s %s FEL\n' "$f" "$fel"
    printf '%s\n' "$ut" | grep -E '^[[:space:]]*FEL' | head -6 | sed 's/^/           /'
    status=1
  fi
done
exit $status
