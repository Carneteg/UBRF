#!/usr/bin/env python3
"""Run the real generated canon and production replay core in Luau."""
import pathlib, subprocess, sys, tempfile
root=pathlib.Path(__file__).resolve().parent.parent
canon=(root/'roblox/src/shared/HorseCore/RidKanon.luau').read_text()
core=(root/'roblox/src/shared/HorseCore/Replay.luau').read_text()
needle='require(script.Parent.RidKanon)'
assert needle in core, 'Production require changed'
core=core.replace(needle,'RidKanon',1)
tests=(root/'roblox/tests/replay.spec.luau').read_text()
source='local RidKanon=(function()\n'+canon+'\nend)()\nlocal Replay=(function()\n'+core+'\nend)()\n'+tests
with tempfile.TemporaryDirectory() as d:
    p=pathlib.Path(d)/'replay.luau';p.write_text(source)
    result=subprocess.run(['luau',str(p)],capture_output=True,text=True)
    sys.stdout.write(result.stdout);sys.stderr.write(result.stderr)
    if result.returncode or 'Replay core: alla gröna' not in result.stdout:
        raise SystemExit(result.returncode or 1)
