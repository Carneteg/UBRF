# Drive migration status

Updated: 2026-11-26

Goal: no build-critical UBRF task may require Google Drive access.

## Status 2026-11-26

The whole Drive folder is inventoried in `references/DRIVE-MANIFEST-2026-11-26.tsv`
(211 photos, 24 videos, 64 other files). 185 photos resolve to a repository
file; 26 photos and all 24 videos remain `[DRIVE-ONLY]` pending the club's
consent (people, number plates or readable personal names in frame). `1.pdf`
remains `[DRIVE-ONLY]` for copyright reasons and is covered by the verified
summary in `references/education/`. The sections below are the 2026-08-29
state and are kept as history; the folders listed as empty there now hold the
Quaternius CC0 test model. See `docs/ASSET-SOURCE-OF-TRUTH.md`.

## Migrated

- `Models/License.txt` → `references/licenses/quaternius-cc0.txt`
- Product/platform/source-of-truth rules → GitHub docs + Supabase `public.reference_assets`

## No content found

The following Drive model folders were empty when inventoried:

- `Models/Blends/`
- `Models/OBJ/`
- `Models/FBX/`
- `Models/glTF/`

They create no current dependency.

## Remaining Drive-only item

- `1.pdf` — Drive file id `1E87lXLuYWrbtcSech87lCjBfaS2_FUtg`

Status: `[DRIVE-ONLY]`, `required_for_build=false` in Supabase manifest.

This file must not be used as a dependency for implementation until a repository/Supabase copy or verified derivative exists. If it becomes relevant to UBRF fidelity, migrate it before building against it.
