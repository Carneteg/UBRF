#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Kräver: bygg från aktuell kod, exitkod 0, inga FEL-rader och en verifierad
# slutrad. Materialskannern körs separat över ALL Luau-källa så Studio-ogiltiga
# Enum.Material inte kan gömma sig i en kodväg som specarna råkar missa.
cd "$(dirname "$0")/.." || exit 1
SPECAR="geometri spel spel-assignment bygge qa movement camera rider touch preparation gameplay interaktion hud"
byggargs=""
for f in $SPECAR; do byggargs="$byggargs tests/$f.spec.luau"; done
if ! bygglogg=$(python3 tests/build.py $byggargs 2>&1); then
  echo "BYGGET AV SPECARNA MISSLYCKADES"
  printf '%s\n' "$bygglogg" | tail -10
  exit 1
fi

if ! python3 ../tools/kolla-material.py; then
  echo "MATERIALKONTROLLEN MISSLYCKADES"
  exit 1
fi

status=0
for f in $SPECAR; do
  ut=$(luau "tests/.build/$f.spec.luau" 2>&1)
  kod=$?
  fel=$(printf '%s\n' "$ut" | grep -cE '^[[:space:]]*FEL')
  slut=$(printf '%s\n' "$ut" | grep -cE 'alla gröna|Alla mätningar gick igenom')
  if [ "$kod" -ne 0 ]; then
    printf '%-16s LUAU AVSLUTADE MED KOD %s\n' "$f" "$kod"
    printf '%s\n' "$ut" | tail -5 | sed 's/^/                 /'
    status=1
    continue
  fi
  if [ "$fel" -eq 0 ] && [ "$slut" -ge 1 ]; then
    printf '%-16s OK\n' "$f"
  elif [ "$slut" -eq 0 ]; then
    printf '%-16s KRASCH — specen nådde aldrig sin slutrad\n' "$f"
    printf '%s\n' "$ut" | tail -5 | sed 's/^/                 /'
    status=1
  else
    printf '%-16s %s FEL\n' "$f" "$fel"
    printf '%s\n' "$ut" | grep -E '^[[:space:]]*FEL' | head -8 | sed 's/^/                 /'
    status=1
  fi
done
exit $status
