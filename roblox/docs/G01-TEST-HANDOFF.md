# G01.1 — executable test handoff

This branch must not be merged on documentation/code review alone.

## Required Linux checks

From repository root:

```sh
./roblox/tests/kor.sh
node tools/webbkoll.mjs
python3 tools/studio-paket.py
```

Expected Roblox test list now includes:

- geometri
- bygge
- movement
- camera
- rider
- touch
- preparation

`preparation` must reach the terminal line:

`G01.1 preparation: alla gröna`

## Required falsification checks

The preparation spec must prove that:

- mount is locked in `approach`, `check`, `groom` and `tack`;
- `tack` cannot skip directly from `approach`;
- `groom` cannot skip `check`;
- only the full ordered sequence reaches `ready_to_mount`;
- objectives/action text exist for every G01.1 preparation phase.

## Roblox Studio play check

With at least one valid model tagged `Horse`:

1. join as a player;
2. verify exactly one horse is assigned;
3. verify other horses do not offer `Sitt upp`;
4. verify the assigned horse first offers `Hälsa lugnt`;
5. complete `Hälsa lugnt → Visitera → Rykta → Gör i ordning`;
6. verify `Sitt upp` appears only after the final preparation step;
7. mount and verify the existing riding controls/feel still work;
8. dismount and verify remount remains possible for this slice;
9. repeat at a narrow mobile viewport and verify the objective panel remains inside the screen.

If no valid tagged horse exists, the correct state is `Väntar på en ledig häst.` The implementation must not silently manufacture a fake production horse.

## F01 visual check

F01 remains separate from G01. Use `roblox/docs/STUDIO-QA-HANDOFF.md` for its 11-view human visual pass. A G01 test run does not visually accept F01.
