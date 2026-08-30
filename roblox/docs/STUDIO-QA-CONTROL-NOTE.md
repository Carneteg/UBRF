# Studio QA control — implementation boundary

The current F01 package is generated as a one-shot script for Roblox Studio edit-time execution (`tools/studio-paket.py`). Its canonical cameras live in `roblox/buildings/Vyer.luau` and directly manipulate `workspace.CurrentCamera`.

A persistent on-screen **Previous / Next / PASS / FAIL / Reset** panel is intentionally not added in this slice because normal `ScreenGui` interaction belongs to a running client/`LocalPlayer`, while the current F01 package is designed to run in Studio edit context. Building a reliable panel would require moving/serializing the F01 camera data into a client runtime path or creating a Studio plugin, which is a larger architecture change than the visual handoff warrants.

For now:

- the 11 canonical camera definitions remain the source of truth;
- `roblox/docs/STUDIO-QA-HANDOFF.md` is the single checklist;
- camera placement remains automated by `Vyer.ga(id)` rather than manual positioning;
- no fidelity work should be reopened merely to build QA tooling.

If repeated Studio review becomes frequent enough to justify it, implement the control as a dedicated Studio plugin or a client-side QA mode with generated camera data. Do not hard-code a second set of camera coordinates.
