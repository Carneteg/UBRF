#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Fanns inte förut, och det kostade: jag räknade rader som börjar med "FEL"
# och fick noll — men specen hade KRASCHAT och aldrig hunnit skriva någon.
# En krasch såg alltså ut som grönt. Nu krävs både noll FEL och att specen
# nådde sin slutrad; annars är det rött.
cd "$(dirname "$0")/.." || exit 1
status=0
for f in geometri bygge movement camera rider touch; do
  ut=$(luau "tests/.build/$f.spec.luau" 2>&1)
  fel=$(printf '%s\n' "$ut" | grep -cE '^[[:space:]]*FEL')
  slut=$(printf '%s\n' "$ut" | grep -cE 'alla gröna|Alla mätningar gick igenom')
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
