# Drive migration status

Updated: 2026-08-29

Goal: no build-critical UBRF task may require Google Drive access.

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
