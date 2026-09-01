#!/bin/sh
# Kör specarna och säg ifrån ORDENTLIGT.
#
# Kräver tre saker: luau exitkod 0, inga FEL-rader och att specen nådde sin
# slutrad. Specarna byggs om varje gång så .build aldrig kan ge falskt grönt.
cd "$(dirname "$0")/.." || exit 1
SPECAR="geometri world dorrar spel spelkanon bygge qa granskning movement camera rider touch"
byggargs=""
for f in $SPECAR; do byggargs="$byggargs tests/$f.spec.luau"; done
if ! bygglogg=$(python3 tests/build.py $byggargs 2>&1); then
  echo "BYGGET AV SPECARNA MISSLYCKADES"
  printf '%s\n' "$bygglogg" | tail -10
  exit 1
fi

# Ett ogiltigt Enum.Material faller bygget i Studio. Skannern läser ALL Luau-käll.
if ! python3 ../tools/kolla-material.py; then
  echo "MATERIALKONTROLLEN MISSLYCKADES"
  exit 1
fi

# Rojo-startaren är PowerShell och går inte att köra här, men dess antaganden
# om repot går att pröva. Glider de isär märks det annars först i Studio.
if ! python3 ../tools/kolla-rojo.py; then
  echo "ROJO-KONTROLLEN MISSLYCKADES"
  exit 1
fi

# Samma dörr målades svart på webben och nästan vit i Roblox. Ingen märkte det
# förrän en människa stod framför den i Studio.
if ! python3 ../tools/kolla-dorrfarg.py; then
  echo "DÖRRFÄRGSKONTROLLEN MISSLYCKADES"
  exit 1
fi

# Referensbilderna är facit för hela fidelity-arbetet. Åtta av dem låg upp och
# ner utan att något sa ifrån, och en läsbar dörrskylt blev därmed oläslig.
# Checksummorna fångar nästa gång en referensfil ändras, tillkommer eller
# försvinner tyst.
if ! python3 ../tools/kolla-referenser.py; then
  echo "REFERENSKONTROLLEN MISSLYCKADES"
  exit 1
fi

status=0
for f in $SPECAR; do
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
