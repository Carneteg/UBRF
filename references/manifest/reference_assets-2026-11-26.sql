-- Rader till public.reference_assets för Drive-materialet, läget 2026-11-26.
--
-- DEN HÄR FILEN ÄR INTE KÖRD och ligger med avsikt INTE i supabase/migrations/
-- (Supabases GitHub-integration kör allt som ligger där). Den är ett förslag
-- som Tobias kör — eller låter bli att köra — själv.
--
-- Genererad ur references/DRIVE-MANIFEST-2026-11-26.tsv. En rad per foto och film.
--   * IN_REPO: github_path satt, sha256 och bytes är REPO-filens.
--   * DRIVE-ONLY: ingen github_path; sha256 och bytes är ORIGINALETS i Drive.
-- verification_status är 'unverified' för allt nytt: bildernas innehåll är
-- maskinläst och stickprovat, inte granskat av produktägaren.
-- supabase_storage_path lämnas tom — inget är speglat till Storage.

begin;

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1rFZ991e4ydcY15BpxTJP4CPCcPkaL54j', 'IMG_0064.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-gavel-04-statrappan.jpg', 'https://drive.google.com/file/d/1rFZ991e4ydcY15BpxTJP4CPCcPkaL54j/view', 'unverified', false, 'Drive: Byggnaden/IMG_0064.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: café gable (north in game) with external steel stair and the two porch entrances', '5f25008d1a0f919e9b0a505d5f5c9f87af340ee5842d105cd3b73132953b056d', 779678)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1G1M8yoErst8MjeTLx5LpOw9BbAXmoEkf', 'IMG_0065.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0065-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1G1M8yoErst8MjeTLx5LpOw9BbAXmoEkf/view', 'unverified', false, 'Drive: Byggnaden/IMG_0065.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: corner between café gable and sign long side (west in game), end view of the entrance lean-to', 'ff4b0cac819e44b8b0115990006128c8a65032553fd83e991bbb1e0a59beeb27', 1053605)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1jcQuA2wvtvmu0HQ8obdpbzkmDz2lpH7u', 'IMG_0066.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0066-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1jcQuA2wvtvmu0HQ8obdpbzkmDz2lpH7u/view', 'unverified', false, 'Drive: Byggnaden/IMG_0066.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: sign long side (west in game): entrance lean-to with ramp, near the café gable', '9d45d5be514864f6d5e26e5a602ae56ca4ff34ecc02c86ed60cabfa12c58497f', 759271)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1n_H83ngScu1s1hpRJ7fmvnKvs0WsdCOj', 'IMG_0067.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0067-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1n_H83ngScu1s1hpRJ7fmvnKvs0WsdCOj/view', 'unverified', false, 'Drive: Byggnaden/IMG_0067.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: sign long side (west in game): entrance lean-to with ramp, a step further back than IMG_0066', '5d36372b5b6863be6c7cad7835b5591ba3421d9bdf5d723dc16b1cdba202f8f2', 724968)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Tz1WJAndKbHwDKqhbWckGoP-hYux3qEF', 'IMG_0068.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0068-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1Tz1WJAndKbHwDKqhbWckGoP-hYux3qEF/view', 'unverified', false, 'Drive: Byggnaden/IMG_0068.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: sign long side (west in game), seen from the lean-to end', '5a6d566374171537fcc82d3f79aca765dcf4603e6bad70165a5c284d85c9b376', 755012)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1CW6lbVRDVnQhMWeL5B27elxDGep5ZcP0', 'IMG_0069.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0069-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1CW6lbVRDVnQhMWeL5B27elxDGep5ZcP0/view', 'unverified', false, 'Drive: Byggnaden/IMG_0069.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: sign long side (west in game), seen from the lean-to end', 'bfa9eb8dd0e47e857b2e339721d4fe5adf522af590d29da27dcf44b17bf6a0e7', 742414)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1KuP0iMOw1K6avz8i86Q_hb-XGcAeAoEH', 'IMG_0070.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-langsida-01-skylten.jpg', 'https://drive.google.com/file/d/1KuP0iMOw1K6avz8i86Q_hb-XGcAeAoEH/view', 'unverified', false, 'Drive: Byggnaden/IMG_0070.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: sign long side (west in game), seen from the lean-to end', '7abea9a20d93d9ee6e0f726141447509c7347f5d4829a3eb2260eb06c3ab4947', 824217)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1356FuVX6WAFvpO5_atnRhazajp4JNT4Q', 'IMG_0071.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0071-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1356FuVX6WAFvpO5_atnRhazajp4JNT4Q/view', 'unverified', false, 'Drive: Byggnaden/IMG_0071.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: far (south in game) end of the sign long side: door with galvanised stair; red shed beyond', '33b991f36d9ccf4d987f67242dc9dcfc2dda1711d99fa92d6b4eb8279c30005a', 793114)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ftuqUpqY27uG_8KmM6LO3XAERMT1IhWT', 'IMG_0072.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-langsida-02-trappan.jpg', 'https://drive.google.com/file/d/1ftuqUpqY27uG_8KmM6LO3XAERMT1IhWT/view', 'unverified', false, 'Drive: Byggnaden/IMG_0072.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: far (south in game) end of the sign long side: door with galvanised stair; red shed beyond', 'ef5657bad15364a8cbccc1bb1938abafc77b1f660ed6ee46259e4ee7d832586a', 898710)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1254BPhepjH5nst6xH_PNJNJkbM12k8tY', 'IMG_0073.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/omnejd-01-roda-boden.jpg', 'https://drive.google.com/file/d/1254BPhepjH5nst6xH_PNJNJkbM12k8tY/view', 'unverified', false, 'Drive: Byggnaden/IMG_0073.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: small free-standing red shed by the gravel road beyond the riding hall''s far end', 'e4bc5c51c3ffac513ea5caba0f18772e3792ee82bcc10e7f58c459fd5835123e', 970772)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1PN9dFIzKamouDCwXtRiSZHcWRfdkK5FJ', 'IMG_0074.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0074-gard-omnejd.jpg', 'https://drive.google.com/file/d/1PN9dFIzKamouDCwXtRiSZHcWRfdkK5FJ/view', 'unverified', false, 'Drive: Byggnaden/IMG_0074.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: small free-standing red shed by the gravel road beyond the riding hall''s far end', 'bc704f67dfeca5f5b7c0435c3452340eda468aaa9aeb2b23a699e4d3ae6d9add', 1025474)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1MIYZCY8Bctqy8flK4Tr3WSusSqH2hMbf', 'IMG_0075.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-langsida-03-dubbeldorren.jpg', 'https://drive.google.com/file/d/1MIYZCY8Bctqy8flK4Tr3WSusSqH2hMbf/view', 'unverified', false, 'Drive: Byggnaden/IMG_0075.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: riding-hall wall with the light double service door (repo name: ''dubbeldörren'')', '00ffdc0ced51d964cc0d673f776ae721732a46d76bf67e857bbbc8d4a367f971', 470706)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-15MoseiF-HVDYldNmeMN4fNf3nZwUEl4h', 'IMG_0076.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/stall-gavel-06-silon.jpg', 'https://drive.google.com/file/d/15MoseiF-HVDYldNmeMN4fNf3nZwUEl4h/view', 'unverified', false, 'Drive: Byggnaden/IMG_0076.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 4); visar: stable gable with feed silo, seen past the riding-hall corner; outdoor arena beyond', '12dd9243fe3f21c46e0c26d5c0c32ba91c0f8bfb057b4a22dc145282bdd129ef', 496179)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1aI1k8gXN72d-wD_fGWVaWZ2CTFfkiv-w', 'IMG_0077.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-skylten-06-narbild.jpg', 'https://drive.google.com/file/d/1aI1k8gXN72d-wD_fGWVaWZ2CTFfkiv-w/view', 'unverified', false, 'Drive: Byggnaden/IMG_0077.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: UBRF sign on the sign long side, close-up above the black door', '74cbddbc02de48988a427169d55a8828153ab0f00e23e19f3960219fbd9e88ee', 571769)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1rODt1IRE_Oiwkrca00m0h47RhnzNCNrq', 'IMG_0126.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/omnejd-02-sandladan-trahastarna.jpg', 'https://drive.google.com/file/d/1rODt1IRE_Oiwkrca00m0h47RhnzNCNrq/view', 'unverified', false, 'Drive: Byggnaden/IMG_0126.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: round sand pit with carved play horses, between the riding-hall entrance and the parking', '78b319fbbe4748d82891c4b790b9fcc9721b19f034caad008fc891b180a709e4', 1071670)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1KfPGGpwP1YRz7MbMP8eYyCLlVA54eEDe', 'IMG_0127.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-trappan-05-cafeskylten.jpg', 'https://drive.google.com/file/d/1KfPGGpwP1YRz7MbMP8eYyCLlVA54eEDe/view', 'unverified', false, 'Drive: Byggnaden/IMG_0127.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: café stair on the café gable, with the CAFÉ sign on the upper landing', '67985281d644319dde5597559073613685f04a43009f8e5b56b3356fe460f2d6', 699982)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1r0IPyOEznYKO9B4Ny0G-Ve8Re2drn0wo', 'IMG_0128.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-durkplatdorrarna-07.jpg', 'https://drive.google.com/file/d/1r0IPyOEznYKO9B4Ny0G-Ve8Re2drn0wo/view', 'unverified', false, 'Drive: Byggnaden/IMG_0128.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: riding hall: the two tread-plate (durkplåt) doors at the mouth of the grass yard between stable and riding hall', '5ee63a8fab9a7dd1ac36c8dcd095ca4acae337be0d3d45554b9a82391260bc34', 669964)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1qk5oenuXxudzudFwlNcYQSMp8zM-7O4T', 'IMG_0129.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/omnejd-03-garden-mellan-husen.jpg', 'https://drive.google.com/file/d/1qk5oenuXxudzudFwlNcYQSMp8zM-7O4T/view', 'unverified', false, 'Drive: Byggnaden/IMG_0129.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: grass yard between stable and riding hall: stable long side with arched windows and ridge hoods', 'a80a21a50a632e34cd63937a929e45e1c4792e0db6a84b43f63d840e25a9ec78', 866074)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1PB07RDg7it0wY9l9vc6HbmMQLIYfkVF8', 'IMG_0130.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/garden-01-mellan-husen-huvraden.jpg', 'https://drive.google.com/file/d/1PB07RDg7it0wY9l9vc6HbmMQLIYfkVF8/view', 'unverified', false, 'Drive: Byggnaden/IMG_0130.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: grass yard between stable (left) and riding hall (right), closed at the far end by the lower connecting building', '29b8b0eda61a5a7ff63798eb94377532a600b2ba770977318fb35574c945eaa8', 731298)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1EhdbF9Rn2gaH4kppbedEZL-qWICUFQNT', 'IMG_0131.HEIC — stall-exterior', 'photo', 'google_drive', 'references/omnejd/omnejd-04-forstukvisten-och-spiraltrappan.jpg', 'https://drive.google.com/file/d/1EhdbF9Rn2gaH4kppbedEZL-qWICUFQNT/view', 'unverified', false, 'Drive: Byggnaden/IMG_0131.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: stable club end: entrance porch (förstukvist) with ochre door, spiral stair on the gable beyond; gravel yard toward the outdoor arena', '7d5f96a7cc58363883cc7726e2508e985dadb6814070301f44fc3dec1ef79a1a', 1274989)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1N8Box_mmvEIwHMELLxYJT3Mjk1ErrkmF', 'IMG_0163.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/banan-01-fran-grusvagen.jpg', 'https://drive.google.com/file/d/1N8Box_mmvEIwHMELLxYJT3Mjk1ErrkmF/view', 'unverified', false, 'Drive: Omnejd/IMG_0163.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: raised outdoor arena (uteridbana), long side seen from the gravel road below', 'd74f3806f08bf86f5729d55f4265264cafd9719c6f4611829cdbe1816d926e0e', 894544)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1nWLCVdYNE-haCOEO6oxcMwr1eCbt3rr5', 'IMG_0164.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/banan-02-rampen.jpg', 'https://drive.google.com/file/d/1nWLCVdYNE-haCOEO6oxcMwr1eCbt3rr5/view', 'unverified', false, 'Drive: Omnejd/IMG_0164.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: outdoor arena corner with the concrete pad in the foreground and the track forking up past the electrical cabinets', '22501dbf6927144b83a101e3f4b8f20b8584ef5f3ee6085e84bb67930e3a13f3', 961890)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1NJjdjkGJBbzc3_tKbOVvDcYx-s7-aepP', 'IMG_0165.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/banan-03-mot-hagarna.jpg', 'https://drive.google.com/file/d/1NJjdjkGJBbzc3_tKbOVvDcYx-s7-aepP/view', 'unverified', false, 'Drive: Omnejd/IMG_0165.HEIC; byggnad: omnejd; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: gravel road past the outdoor arena''s end toward the paddocks; stacked peat bales in the foreground', 'cc34f312017c00c136be3bafe88a150353607a583c61ec7b7b3fc548909b9783', 751878)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XOWw-wxaWvt6Z-exs2LmFda8ODCbWr0a', 'IMG_0249.HEIC — utebana-hagar', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1XOWw-wxaWvt6Z-exs2LmFda8ODCbWr0a/view', 'unverified', false, 'Drive: Omnejd/IMG_0249.HEIC; byggnad: omnejd; status: DRIVE-ONLY; person i bild; visar: track from a concrete pad toward the paddocks and the far riding area, overcast day', '52cedada55bd76bbcb05052bd839b84e0bbb9d09d9765ae254c596030cabcd19', 2595727)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1YCyypMeZFAoTzQvWXMHDiIxgEg36jYDp', 'IMG_0285.HEIC — gard-omnejd', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0285-gard-omnejd.jpg', 'https://drive.google.com/file/d/1YCyypMeZFAoTzQvWXMHDiIxgEg36jYDp/view', 'unverified', false, 'Drive: Omnejd/IMG_0285.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: gravel turning area at the outdoor arena''s corner: red shed, electrical cabinets, small pens, path up to the red hut', '01e1d74d759cd5a666b5530d91264b5f18fab48ff3c4313b4c414f1c70d9e4b3', 924025)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1pHzI8sxbcYtWIk5pW07WDtqR4-k_Gn1e', 'IMG_0286.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0286-utebana-hagar.jpg', 'https://drive.google.com/file/d/1pHzI8sxbcYtWIk5pW07WDtqR4-k_Gn1e/view', 'unverified', false, 'Drive: Omnejd/IMG_0286.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: outdoor arena corner with the red hut on its bank behind', '9740c8ae78bd29bb4ce9103e2d9a12736b8379b959dad79fc44678e5e2b98909', 905185)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vNGEB7rtNVpUAs922V9X6ekGHyI_ybUd', 'IMG_0287.HEIC — utebana-hagar', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1vNGEB7rtNVpUAs922V9X6ekGHyI_ybUd/view', 'unverified', false, 'Drive: Omnejd/IMG_0287.HEIC; byggnad: omnejd; status: DRIVE-ONLY; person i bild; visar: track between a building''s eave and the outdoor arena''s long side; IBC water tank on a concrete pad, paddocks beyond', '51c20a398d058df2096ebe1f73e0eb4f0561db7348eadc7705f0d67debaecf25', 2621533)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XwLvFSTU0gd0Nb8iGH82deNaEv_K1xn7', 'IMG_0300.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0300-utebana-hagar.jpg', 'https://drive.google.com/file/d/1XwLvFSTU0gd0Nb8iGH82deNaEv_K1xn7/view', 'unverified', false, 'Drive: Omnejd/IMG_0300.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: outdoor arena corner where a paddock fence joins: close-up of fence construction, red hut across the arena', '132b47debb6d3dbd70e31f2916ab32d786cf8db71214178e3c1c24011608a794', 877886)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1oh2RQjA4mZYQ3URXwjmlRaiyIpsWpKaK', 'IMG_0301.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0301-utebana-hagar.jpg', 'https://drive.google.com/file/d/1oh2RQjA4mZYQ3URXwjmlRaiyIpsWpKaK/view', 'unverified', false, 'Drive: Omnejd/IMG_0301.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: same outdoor arena corner as IMG_0300, one step to the right: corner post and electric-rope detail', '2d8d4071091bce90c5115ef36f9998e62846179fb34102d58da7e9176796a41b', 1022241)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-156aYwtShHoZ6JPxsyYo-kecJOvjAqZZ0', 'IMG_0302.HEIC — utebana-hagar', 'photo', 'google_drive', 'references/omnejd/drive-2026-11-26/IMG_0302-utebana-hagar.jpg', 'https://drive.google.com/file/d/156aYwtShHoZ6JPxsyYo-kecJOvjAqZZ0/view', 'unverified', false, 'Drive: Omnejd/IMG_0302.HEIC; byggnad: omnejd; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: outside of the outdoor arena''s long side on top of the grass bank, looking toward the track fork and the electrical cabinets', '5ef54a38161da31ccbd61cda9a9763b4a7cc687d44f889b38fed471130d457c0', 752380)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1znBuTE-RBbdxwwzWTCj_kuPQlM6x-khl', 'IMG_0308.MOV — gard-omnejd', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1znBuTE-RBbdxwwzWTCj_kuPQlM6x-khl/view', 'unverified', false, 'Drive: Omnejd/IMG_0308.MOV; byggnad: omnejd; status: DRIVE-ONLY; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '8cf09f628ab092305403c74271eccb259443c6f0c7f375dea9123552be18ffa3', 13653709)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1BEPuI6q1XShgREBi9U-g_JC5PiZaKeI6', 'IMG_0306.HEIC — parkering', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1BEPuI6q1XShgREBi9U-g_JC5PiZaKeI6/view', 'unverified', false, 'Drive: Parkering/IMG_0306.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: yard edge by the parking: fence, finger signpost and the two carved horse figures', '365d2a2c05b247e5b00a3229b897bf63d4c3cfa0b448f98db4bb9f4dd8998f88', 3173658)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1onqrs74RFnNjxHPS2jkjdDDbKMbgseWu', 'IMG_0307.HEIC — parkering', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1onqrs74RFnNjxHPS2jkjdDDbKMbgseWu/view', 'unverified', false, 'Drive: Parkering/IMG_0307.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: fence between yard and parking, right-hand section toward the small red building', 'ee803a1dddc2498a2291b21d6b475a33c5010ba8d38454f12853f5fde0c05392', 3341573)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vSUtd3BKvyEZv1VYKdBY4ziigo3j0byf', 'IMG_0309.HEIC — parkering', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1vSUtd3BKvyEZv1VYKdBY4ziigo3j0byf/view', 'unverified', false, 'Drive: Parkering/IMG_0309.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: parking lot, inner end with grass verge, trees and red shed', '310b1b9d0fc8d7b5f4a5f67465f2d8062dbf3c82a37719a10e708bba0ed97855', 3786025)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1k46F5GC7Hk9_CnN01dJSfSPilmFH-vlS', 'IMG_0310.HEIC — parkering', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1k46F5GC7Hk9_CnN01dJSfSPilmFH-vlS/view', 'unverified', false, 'Drive: Parkering/IMG_0310.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: parking lot looking toward the road and the bus stop', '1831b6cf792d32228adc5e770ba331d16ef954a9cae7745f41b3c0268dd35023', 1668806)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-19jeYvMvrxwWat9y-c-qZt--bdeE_PiBD', 'IMG_0311.HEIC — parkering', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/19jeYvMvrxwWat9y-c-qZt--bdeE_PiBD/view', 'unverified', false, 'Drive: Parkering/IMG_0311.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: riding-hall gable facing the parking, with the Café Krubban stair', 'fbf49e9e910cb376b087944975dcef352c0f324f027d8805cb41cb7d880a8b28', 2082870)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XW9jWghj3ihDJHW_8Ir3G10ptNyJfIfM', 'IMG_0078.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-01-omkladningsgangen.jpg', 'https://drive.google.com/file/d/1XW9jWghj3ihDJHW_8Ir3G10ptNyJfIfM/view', 'unverified', false, 'Drive: Ridhuset/IMG_0078.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: locker/changing hall (omklädningsgången), ground floor of the club part', 'a5cb4dc5cf5a9b7f89514e3b07cdc135a5dee70e0f1d59119e01309daa5e337b', 362234)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1dd2Qjs6phHcYb1SuhrBm0SsK9-Lktanr', 'IMG_0079.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-02-glasrummen.jpg', 'https://drive.google.com/file/d/1dd2Qjs6phHcYb1SuhrBm0SsK9-Lktanr/view', 'unverified', false, 'Drive: Ridhuset/IMG_0079.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: locker hall, wall with interior windows to the office (glasrummen)', '21b1d64a0ce15704bb3739faed7882663a894f92e2323578468a4e89f081bebb', 338599)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1P85U3CN3YW7LHTkad5uYsZX3_SbmBMFK', 'IMG_0080.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-03-korridordorrarna.jpg', 'https://drive.google.com/file/d/1P85U3CN3YW7LHTkad5uYsZX3_SbmBMFK/view', 'unverified', false, 'Drive: Ridhuset/IMG_0080.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club corridor with glazed door to the locker hall (korridordörrarna)', '4022f43131b32e337b9c44088ab5c5d2a4fbaf18f1ce665bc30de8c660d6daf5', 323009)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Z3wL6AhaJQ6a_4twlCcN89Al3ItnGquF', 'IMG_0081.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-04-stora-toaletten.jpg', 'https://drive.google.com/file/d/1Z3wL6AhaJQ6a_4twlCcN89Al3ItnGquF/view', 'unverified', false, 'Drive: Ridhuset/IMG_0081.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: large accessible toilet (stora toaletten)', 'eb19163e969e01c06603a233c7dde7b4105ad87d0a799923afb8db9e6ef3323f', 367176)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-17g_ipid68rjKK7hiAQJNC9CI15ICG6WS', 'IMG_0082.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-05-lilla-toaletten.jpg', 'https://drive.google.com/file/d/17g_ipid68rjKK7hiAQJNC9CI15ICG6WS/view', 'unverified', false, 'Drive: Ridhuset/IMG_0082.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: small toilet (lilla toaletten)', '85d46e1df53376d942074308d15fc10a3bb65d5ca7123fa82a959260b002c5f2', 369897)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-15xWqib1VN_hEFf82ITapXx3y1brqv5k-', 'IMG_0083.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-06-svarta-dorren.jpg', 'https://drive.google.com/file/d/15xWqib1VN_hEFf82ITapXx3y1brqv5k-/view', 'unverified', false, 'Drive: Ridhuset/IMG_0083.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: corner with the black exit door and a curtained sliding window (svarta dörren); exact position in the building [REFERENCE GAP]', '3a2918d7d8b1080a41c4ad1bb6518feea3e0fcdec08cb2e258cc8086eb7d3153', 419745)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1YY7YItENFbeQ8UY2ncU4GmrzaLd4T-Hs', 'IMG_0084.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-04-sargen-mot-laktaren.jpg', 'https://drive.google.com/file/d/1YY7YItENFbeQ8UY2ncU4GmrzaLd4T-Hs/view', 'unverified', false, 'Drive: Ridhuset/IMG_0084.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: walkway between the sarg and the spectator stand (sargen mot läktaren)', '5c787c27665dd15dac7b3c16296ed67b8b80e0198c2c4efca906cd78e93c4dca', 507637)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cojSK_uMHeOunjpiKRNChJqg5A5xw4hB', 'IMG_0085.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-05-ridbanan-sponsorvaggen.jpg', 'https://drive.google.com/file/d/1cojSK_uMHeOunjpiKRNChJqg5A5xw4hB/view', 'unverified', false, 'Drive: Ridhuset/IMG_0085.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: arena seen from the walkway toward the opposite long wall with the sponsor boards', '46be6203941d3203696c376e544eb152757c28cf004984197f5764bfba26961e', 551652)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-12l5eHXbCz8jwNOYQs7NpbjFY8s1nXBQK', 'IMG_0086.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-06-laktaren-och-glasrummet.jpg', 'https://drive.google.com/file/d/12l5eHXbCz8jwNOYQs7NpbjFY8s1nXBQK/view', 'unverified', false, 'Drive: Ridhuset/IMG_0086.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: spectator stand and walkway toward the club-end short wall (läktaren och glasrummet)', 'fed630e130427291338480677d6ec8630c3b3cf099cfd8bf91cd8fb6c077f423', 639766)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Bs8Neao4hpNVBU3HHUk_6zbbXRXCTetB', 'IMG_0087.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-07-laktartrappstegen.jpg', 'https://drive.google.com/file/d/1Bs8Neao4hpNVBU3HHUk_6zbbXRXCTetB/view', 'unverified', false, 'Drive: Ridhuset/IMG_0087.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: spectator stand steps below the glazed room (läktartrappstegen)', '8e47914141d430b5145daeef09e5a4334547c4baf077507e08e48c6b3732c5e4', 473835)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vbJAw7heRDhk5_u9Y58nZnPgmCshDKrm', 'IMG_0088.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-08-laktartrappan.jpg', 'https://drive.google.com/file/d/1vbJAw7heRDhk5_u9Y58nZnPgmCshDKrm/view', 'unverified', false, 'Drive: Ridhuset/IMG_0088.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: stair from the stand up to the upper club level (läktartrappan)', '63a55c297fc76b77f5de33c02acee9044b0591676ec89f4cd627e17d3f9fb123', 407215)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ctqk7g7BWu2zI_cbiQpRxouDN1lTyIG-', 'IMG_0089.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-09-laktartrappan-underifran.jpg', 'https://drive.google.com/file/d/1ctqk7g7BWu2zI_cbiQpRxouDN1lTyIG-/view', 'unverified', false, 'Drive: Ridhuset/IMG_0089.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 3); visar: stair from the stand up to the glass-room walkway, corner at the C short end', 'b814248ef32c4a70c6e10b9147ea6cdc65d511354f2955210b9e46d3a05f1a05', 391456)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1IyfsF3Cm1fSX4Tc-D3CEgt-MDMcbJQ3F', 'IMG_0090.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-07-cafeet-genom-glaset.jpg', 'https://drive.google.com/file/d/1IyfsF3Cm1fSX4Tc-D3CEgt-MDMcbJQ3F/view', 'unverified', false, 'Drive: Ridhuset/IMG_0090.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: cafe seen through the glass wall - blackboard partition and sofa corner', '2fe7b022bfe0c57e041c5b295942356132af879fb8613600ad8fd52da33e986a', 493389)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-19EXJTJ9cy2HAornmBjJRjyNk7DLzCYzY', 'IMG_0091.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-08-glasrummen.jpg', 'https://drive.google.com/file/d/19EXJTJ9cy2HAornmBjJRjyNk7DLzCYzY/view', 'unverified', false, 'Drive: Ridhuset/IMG_0091.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: glass-room window wall along the upper walkway, with the cafe and kitchen door behind the glass', '8c62a9b6757beafe06fd45e3efdb14296c4bbd5c0d2377622d0f96f89d5c9377', 479350)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1yX4pZJuMfrsltWjJ-sXSNWmII_t4KLQ2', 'IMG_0092.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-09-cafesalen.jpg', 'https://drive.google.com/file/d/1yX4pZJuMfrsltWjJ-sXSNWmII_t4KLQ2/view', 'unverified', false, 'Drive: Ridhuset/IMG_0092.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: cafe hall (cafesalen) seen through the walkway windows', '11d30244c2768bc40f3b9c467484dd7c9370cb49b14eda077828dbdca8c05202', 462611)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1zNvkCBSHv3mby6q1WC1hPLOWFqz0yAa-', 'IMG_0093.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-10-glasrumsvaggen.jpg', 'https://drive.google.com/file/d/1zNvkCBSHv3mby6q1WC1hPLOWFqz0yAa-/view', 'unverified', false, 'Drive: Ridhuset/IMG_0093.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: glass room above the entrance passage at the H corner, seen from the upper walkway', 'f86ffa79ad3bfc5892ce337a5bb171e462ee27c2a892e0d245e4c25de408cbf7', 529025)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1sgXYLF_Wz23r0t9PcqZNgfJrutK17Ezj', 'IMG_0094.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-10-overvaningens-gang.jpg', 'https://drive.google.com/file/d/1sgXYLF_Wz23r0t9PcqZNgfJrutK17Ezj/view', 'unverified', false, 'Drive: Ridhuset/IMG_0094.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: upper walkway along the glass rooms at the C short end, toward the M corner', 'f538adf7b6d7ece1c2dd097081e283bb806b725a7e101a6f016ad1290b86c7ab', 603841)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1OI9zwWX34MkKRPuc5azGozav9SJ6uAl5', 'IMG_0095.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-11-ridbanan.jpg', 'https://drive.google.com/file/d/1OI9zwWX34MkKRPuc5azGozav9SJ6uAl5/view', 'unverified', false, 'Drive: Ridhuset/IMG_0095.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: whole arena lengthwise, seen from the C short side', '473cda115e534b68b934c7410039ec97077d9ac64fb9af2fd2433307d43bdf4c', 792527)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ZAZnyNG_-9R4Rt8X8ZERh2E_A_xewuB8', 'IMG_0096.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-12-langsidan-med-elonskylten.jpg', 'https://drive.google.com/file/d/1ZAZnyNG_-9R4Rt8X8ZERh2E_A_xewuB8/view', 'unverified', false, 'Drive: Ridhuset/IMG_0096.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: sponsor long side from the M corner (C end), toward B', 'df48e2450ceede4fed03c39e553dbce2f0c29c632774e0a56ee52bfd4e79ebd5', 628346)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ulrY3o0D4gU_XbGSw97MsRx7SAR-_Kbp', 'IMG_0097.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-13-elonskylten-narbild.jpg', 'https://drive.google.com/file/d/1ulrY3o0D4gU_XbGSw97MsRx7SAR-_Kbp/view', 'unverified', false, 'Drive: Ridhuset/IMG_0097.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: sponsor long side, welcome sign and ELON banner at M - closer view', '38c8c526a394fda919885608877de938ad58713878b2a5d10ab3551c70f88056', 788664)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1__Uc7qSyF8X2QV7_b_yfC2j0h9ya5wGW', 'IMG_0098.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-14-laktaren.jpg', 'https://drive.google.com/file/d/1__Uc7qSyF8X2QV7_b_yfC2j0h9ya5wGW/view', 'unverified', false, 'Drive: Ridhuset/IMG_0098.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 3); visar: stand (laktare) long side from the arena, H-E section with judge box and stair to the glass room', '5e6ee0f4e1cc7b72d12d9659dbf963e4f8c9965edde57156ff92915fa202d0fc', 761587)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-10f1Y9lDC1TjHlWPlaszPNWW_MyTWujPA', 'IMG_0099.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-11-trappan-till-hinderforradet.jpg', 'https://drive.google.com/file/d/10f1Y9lDC1TjHlWPlaszPNWW_MyTWujPA/view', 'unverified', false, 'Drive: Ridhuset/IMG_0099.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: steps down from the stand to the corner behind the sarg gate (mucking-tool corner, way to the jump store)', 'e00d45cd28e95c5a79b7aa1875cd17756b63d5406fd060ba55cd62c5819c1310', 437659)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-122C9rPVh6CZTPSl8CQFdmOgywZ2Zqxlz', 'IMG_0100.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-12-hinderforradet.jpg', 'https://drive.google.com/file/d/122C9rPVh6CZTPSl8CQFdmOgywZ2Zqxlz/view', 'unverified', false, 'Drive: Ridhuset/IMG_0100.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: jump store (hinderforradet)', '27082b76e60c169bcaa1f421a571c1e66a9b871db563eeb76a78abd549b4d369', 598411)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1WNS-bxjV4icetzRyaH7Bokk0_lDL3IL1', 'IMG_0101.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-15-hornet-mot-glasrummen.jpg', 'https://drive.google.com/file/d/1WNS-bxjV4icetzRyaH7Bokk0_lDL3IL1/view', 'unverified', false, 'Drive: Ridhuset/IMG_0101.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena corner at H / short side C, with the glass rooms above the entrance passage', 'e338dc830da9e02529b776ec3bdb1f726b8b1cbf7daf2dfad0156df9c07666b6', 649935)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1DnCW9II-09vfj9UPKi3gZZ4CLXNAQhYY', 'IMG_0102.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-16-sargen-mot-lang-sida.jpg', 'https://drive.google.com/file/d/1DnCW9II-09vfj9UPKi3gZZ4CLXNAQhYY/view', 'unverified', false, 'Drive: Ridhuset/IMG_0102.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: stand long side from the judge box at E toward the far short side and the jump-material corner', '369002d271de3bf3121bc9c6c6feba7b7305b12c1a6410c62f7afafd8d32a826', 628068)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1_CxMLYa3BBHQ8SauicpiJw0tshGh3EzN', 'IMG_0103.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-17-reklamvaggen-mot-hornet.jpg', 'https://drive.google.com/file/d/1_CxMLYa3BBHQ8SauicpiJw0tshGh3EzN/view', 'unverified', false, 'Drive: Ridhuset/IMG_0103.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: sponsor long side, far section with the Agria and RS Mustang signs at F', 'c091b70bed34cf25f6a8fb36613287d1efadb5459f86e984cb590d1dbff67b04', 704924)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1obDVTNsCqOwfOYWMn31owsmWAYeOXFd1', 'IMG_0104.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-18-glaspartiet-vid-b.jpg', 'https://drive.google.com/file/d/1obDVTNsCqOwfOYWMn31owsmWAYeOXFd1/view', 'unverified', false, 'Drive: Ridhuset/IMG_0104.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: sponsor long side square-on at B - mirror, sarg gate and louvre hatch', '9bf64a475b88d9aa820f34dad87e687483337ca43c6bd4d838428b123d9fd5bd', 715982)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1sobXrfqNmXnwgcoxr1WUuYSSeQS3x2Zt', 'IMG_0105.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-19-glaspartiet-och-skyltraden.jpg', 'https://drive.google.com/file/d/1sobXrfqNmXnwgcoxr1WUuYSSeQS3x2Zt/view', 'unverified', false, 'Drive: Ridhuset/IMG_0105.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: arena long side at B: wall mirror, sponsor signs and side gate', 'db5d7a361629e71954dd21d378ff5f5247ab136249c8f7e8b67f0e5444b244aa', 734854)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1doN_CfCGUGn2Dfes3rr6P_d9jVbgA0bz', 'IMG_0106.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-20-hornet-mot-glasrummet.jpg', 'https://drive.google.com/file/d/1doN_CfCGUGn2Dfes3rr6P_d9jVbgA0bz/view', 'unverified', false, 'Drive: Ridhuset/IMG_0106.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena corner at the M/C end: glass room on posts, sarg opening, sponsor wall and mirror', '03087d76a68ec8b5f08e287c3dee8b804d0943742009c7ad94bfe6b26ef8ae0c', 666912)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-13IgSpbl8LH1YdthVywAR_tL7EnPFYGKC', 'IMG_0107.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-21-hinderupplaget-och-bokstavsstall.jpg', 'https://drive.google.com/file/d/13IgSpbl8LH1YdthVywAR_tL7EnPFYGKC/view', 'unverified', false, 'Drive: Ridhuset/IMG_0107.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 3); visar: läktare platform at the K/A corner: jump storage and dressage letter markers behind the sarg', '88f475f9a41df32f9434c365c435a8d35d6d35ec6d8e2dff7ac32d8775ab027a', 682911)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1uIHYJqI-KvKEyCl4zssw0WsA-KSzE92v', 'IMG_0108.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-22-bokstavsraden-vid-sargen.jpg', 'https://drive.google.com/file/d/1uIHYJqI-KvKEyCl4zssw0WsA-KSzE92v/view', 'unverified', false, 'Drive: Ridhuset/IMG_0108.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: K/A corner again: letter-marker row and jump storage above the sarg', '846d772e88759a96140c1341efb41447627c9b48e7714a9c5f498cafdf5b6d7d', 534456)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1eyrw3XNpsoqi2Lz_a_U0obP1N2tLbB68', 'IMG_0109.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-23-kortsidan-vid-a.jpg', 'https://drive.google.com/file/d/1eyrw3XNpsoqi2Lz_a_U0obP1N2tLbB68/view', 'unverified', false, 'Drive: Ridhuset/IMG_0109.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 4); visar: arena short side at A: double gate, sliding door, emergency exit sign, two mirrors', 'be29db033643272192932cbcd5a4fe38beb415c8056d4973133092427fa08df1', 687997)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1inp9hwE5jksJzvtSkKnouEQGl8ig0PRG', 'IMG_0110.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-24-skyltvaggen-vid-f.jpg', 'https://drive.google.com/file/d/1inp9hwE5jksJzvtSkKnouEQGl8ig0PRG/view', 'unverified', false, 'Drive: Ridhuset/IMG_0110.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: B long side at F: sponsor sign wall', 'f02dd5a210160983507a6ce2cc78b3b4c7da6c519d1f2812487409081505bb8e', 597790)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ommus-t2aKqsWNVAoyjfS4T-j1qHId6B', 'IMG_0111.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-25-agria-och-mustangskyltarna.jpg', 'https://drive.google.com/file/d/1ommus-t2aKqsWNVAoyjfS4T-j1qHId6B/view', 'unverified', false, 'Drive: Ridhuset/IMG_0111.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: B long side at F: Agria and RS Mustang signs (tilted frame)', 'a66770af67cb5d85b8a46c8f1736417a23626d4a903f780e2d3d62b2ff10596a', 670987)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1CpCKzURVPBYrXl1KnsjB7wlNLgpRQMAt', 'IMG_0112.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-26-panelvaggen-narbild.jpg', 'https://drive.google.com/file/d/1CpCKzURVPBYrXl1KnsjB7wlNLgpRQMAt/view', 'unverified', false, 'Drive: Ridhuset/IMG_0112.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: B long side at F: panel wall and signs close-up', 'f7d1ef936e4ab3b7d8f675ce032e1eebf79e843c85dfc0f3f109f849681b410f', 709203)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1BMzkJWxmpvKpL_8_elZzX1bLBD4F5P4k', 'IMG_0113.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-27-glasrummet-inifran-banan.jpg', 'https://drive.google.com/file/d/1BMzkJWxmpvKpL_8_elZzX1bLBD4F5P4k/view', 'unverified', false, 'Drive: Ridhuset/IMG_0113.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: B long side: mirror reflecting the glass room and läktare, Elon and Sparbanken signs', '10a15210e8892e1032844d56c5e2340dd4f27932492a7b31c371996d9d8ea9a0', 607379)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-146JdJVFIOhtnyLgCZPtcdq00CPuNSuoU', 'IMG_0114.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-28-langsidan-vid-h.jpg', 'https://drive.google.com/file/d/146JdJVFIOhtnyLgCZPtcdq00CPuNSuoU/view', 'unverified', false, 'Drive: Ridhuset/IMG_0114.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: long side at H: läktare, speaker''s booth, stair to the glass room', '2dce1b286f518cd032fafefbfc49a2a9e2c03a93d909699ccb488230a43c74ac', 580646)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1o4SF_g2flXsgS45sZMta_GiIVZcEiCNl', 'IMG_0115.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-29-langsidan-mot-glasrummet.jpg', 'https://drive.google.com/file/d/1o4SF_g2flXsgS45sZMta_GiIVZcEiCNl/view', 'unverified', false, 'Drive: Ridhuset/IMG_0115.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: long side at H looking to the A end: läktare and far-corner storage', '1cc19ff735fcd4bb3917f404d2b89a1c52ec686f02542e7941bb82950ed54e91', 610239)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1yGCrU13f0O1l4DBKT644iSENCGJLTbVi', 'IMG_0116.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-30-sargen-vid-h.jpg', 'https://drive.google.com/file/d/1yGCrU13f0O1l4DBKT644iSENCGJLTbVi/view', 'unverified', false, 'Drive: Ridhuset/IMG_0116.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: sarg at H: stair, underside of the glass room and läktare end', 'f0983514d1d2d43cd18ca0beeb0b835f1495313653fbcb33e9dac4ea675bf957', 610610)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1AoxgNoP8RD7kP3f5p7DSJvHzEHApys21', 'IMG_0117.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-13-svarta-utgangsdorren.jpg', 'https://drive.google.com/file/d/1AoxgNoP8RD7kP3f5p7DSJvHzEHApys21/view', 'unverified', false, 'Drive: Ridhuset/IMG_0117.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: club part: black exit door with emergency sign and broom rack', '823b2513c344767ce5efeae02ba6c3d99748fc9e4c98ea55feb2da8a49617493', 407467)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1lS4Ru-Lx8SLDhS8I2-kyNQ-3aMs7cT16', 'IMG_0118.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-14-omkladningen-med-valvfonstret.jpg', 'https://drive.google.com/file/d/1lS4Ru-Lx8SLDhS8I2-kyNQ-3aMs7cT16/view', 'unverified', false, 'Drive: Ridhuset/IMG_0118.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: club part: changing/locker room with arched window toward the parking', 'b6de5f28c382ea0f14aed958c90e1fca96daab1c6e16ee829e565f053d3795c1', 362797)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1lwyqk9e_ZKpq8aQx4qKFEhrqUlUIX8Nn', 'IMG_0119.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-15-korridoren-mot-glasrummen.jpg', 'https://drive.google.com/file/d/1lwyqk9e_ZKpq8aQx4qKFEhrqUlUIX8Nn/view', 'unverified', false, 'Drive: Ridhuset/IMG_0119.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club part: locker corridor/lounge beside the glazed rooms', '38e69ecb07a6193c77aea03dcf013f3fbc5416ef3ec829b6563b9b3cf4cfccc3', 426598)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1JXXkPvue-QZq7YpI9-0IslpZYTvhFVGh', 'IMG_0120.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-16-skaprummet-med-pelaren.jpg', 'https://drive.google.com/file/d/1JXXkPvue-QZq7YpI9-0IslpZYTvhFVGh/view', 'unverified', false, 'Drive: Ridhuset/IMG_0120.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club part: locker room with the free-standing pillar', '1a6f07f165340ffaefa1dbc33462245945429c94d31875eb0bc1d5d74a73b058', 285582)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cjVlpnu00ZDZ-pc5g4vZPaxY0b3eEOzf', 'IMG_0121.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-17-dusch-och-wc.jpg', 'https://drive.google.com/file/d/1cjVlpnu00ZDZ-pc5g4vZPaxY0b3eEOzf/view', 'unverified', false, 'Drive: Ridhuset/IMG_0121.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: accessible shower/WC room off the club changing room', '7a40e85430e7eecc7b0a3c1875109ffd5ccd6f361f2d7f34b1ff1e7d0d570ded', 318909)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1veqQjrypYm9MDMctpQVz2Yu7IiNDCLvV', 'IMG_0122.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-18-skapraden-narbild.jpg', 'https://drive.google.com/file/d/1veqQjrypYm9MDMctpQVz2Yu7IiNDCLvV/view', 'unverified', false, 'Drive: Ridhuset/IMG_0122.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club changing room, grey and black locker row', '5640a6ff289e3cdef60eded76193e23ce1612a508bf7c491c1bea4b4f335016a', 287818)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1O9PGsaXC4dP-mHE02TZaWwVyJnSXDLMv', 'IMG_0123.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-19-dorrarna-till-omkladningen.jpg', 'https://drive.google.com/file/d/1O9PGsaXC4dP-mHE02TZaWwVyJnSXDLMv/view', 'unverified', false, 'Drive: Ridhuset/IMG_0123.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: club corridor nook with the doors to the changing room', 'c45a2607e189240132e14d2decf9567e68b4e2654ea2424d09e3233af2fba504', 323646)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1x06d6e7qX7O14IHtBwjsPhuWY9GxvF3j', 'IMG_0124.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-20-grona-skapen.jpg', 'https://drive.google.com/file/d/1x06d6e7qX7O14IHtBwjsPhuWY9GxvF3j/view', 'unverified', false, 'Drive: Ridhuset/IMG_0124.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club changing room, green locker block just inside the door', '1bf98ad2b808809077186cb2cfe403d6e5a8ea96c3b292db32fccdf79c6c306c', 397475)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1qXSNo3YZa5lBhi9bEwOGaf7ZF9KgGl4_', 'IMG_0125.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-21-grona-skapen-vinkel.jpg', 'https://drive.google.com/file/d/1qXSNo3YZa5lBhi9bEwOGaf7ZF9KgGl4_/view', 'unverified', false, 'Drive: Ridhuset/IMG_0125.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club changing room, green locker block (second angle)', '033e5f5e9b629462a78027221243f86aa57db014e6f0382485b3cce4b3fc8c3b', 464465)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1pO3hgCViM4zwAwaQJhPj2UXP8MBmJ2Wr', 'IMG_0169.MOV — ridhus-klubbdel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1pO3hgCViM4zwAwaQJhPj2UXP8MBmJ2Wr/view', 'unverified', false, 'Drive: Ridhuset/IMG_0169.MOV; byggnad: ridhus; status: DRIVE-ONLY; 5 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '31352e648b7fac073c109c0809eb20781353812bacebd1582442db826fb0fb17', 31729716)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1G_P24lbdwgOqAd_TNWY57L7wgJFVoaRi', 'IMG_0171.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-31-langsidan-med-sponsorskyltar.jpg', 'https://drive.google.com/file/d/1G_P24lbdwgOqAd_TNWY57L7wgJFVoaRi/view', 'unverified', false, 'Drive: Ridhuset/IMG_0171.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 4); visar: arena long side M-B-F with sponsor signs, mirror and ramp door', '31e09d62e72742a23b54e3c49b24948d5c2fedd328da374f664e3e26e9f158f1', 853222)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1NyUBhoGXjq7f7DB_pqvOv6swqDc7Mjk4', 'IMG_0172.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-32-hornet-mot-laktaren.jpg', 'https://drive.google.com/file/d/1NyUBhoGXjq7f7DB_pqvOv6swqDc7Mjk4/view', 'unverified', false, 'Drive: Ridhuset/IMG_0172.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena corner at short side C / letter M, toward the spectator benches and glass rooms', 'de217df0df235d3aaec6130ad40dd855ad5d09d3c69a80fd083072833ca30f1d', 790245)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1hM9is2thhPE8_01WX9Mwkih3QyyBlSUX', 'IMG_0173.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-33-elonskylten.jpg', 'https://drive.google.com/file/d/1hM9is2thhPE8_01WX9Mwkih3QyyBlSUX/view', 'unverified', false, 'Drive: Ridhuset/IMG_0173.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena long side, ELON and welcome sign bay at letter M', 'bc042b01e0ad82b26371e85604dafdc6cd66b114d7eb4f0eba39727079cbc822', 729632)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1As7gnmbRxDB_BZO_0R1_sEgONbChjaug', 'IMG_0174.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-34-spegelpartiet.jpg', 'https://drive.google.com/file/d/1As7gnmbRxDB_BZO_0R1_sEgONbChjaug/view', 'unverified', false, 'Drive: Ridhuset/IMG_0174.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 3); visar: arena long side, mirror bay at letter B and edge of the ramp door', '89917d5dce27f65b549734481e85267137a0c6a407db464b7386b9893fc3adc8', 635550)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1K6rseJxDJKdWPxRsr0xVqO2zZ9gtxYzv', 'IMG_0175.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-35-foderskyltarna.jpg', 'https://drive.google.com/file/d/1K6rseJxDJKdWPxRsr0xVqO2zZ9gtxYzv/view', 'unverified', false, 'Drive: Ridhuset/IMG_0175.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena long side, feed sponsor signs at letter F toward the A corner', '22c40eb4848164850d7256a50bb8c83edf0e0227ebf1e47127225136d3fe5650', 741607)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1QkpdO1c3c62DJVIdEpM6wlJDDle9XAYG', 'IMG_0176.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-36-vita-kortsidan.jpg', 'https://drive.google.com/file/d/1QkpdO1c3c62DJVIdEpM6wlJDDle9XAYG/view', 'unverified', false, 'Drive: Ridhuset/IMG_0176.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena short side at A (white wall with door)', '8f460e617d5e068428749e999531a388dbef2dfa85b8b8128ebe2d8e84f3291b', 480812)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1YkkrMLcJG0zy_Jk_jx5CKh3MRYYbzoEv', 'IMG_0177.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-37-rampdorren.jpg', 'https://drive.google.com/file/d/1YkkrMLcJG0zy_Jk_jx5CKh3MRYYbzoEv/view', 'unverified', false, 'Drive: Ridhuset/IMG_0177.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: arena long side, ramp door between the mirror and the Agria sign', 'd06de27a4fba78831ea925d5c7a0524c275119af96fae2719d91ff6b6dd1fd5e', 802004)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1DIe7DcRi7eWWYp3a6m388sy-Sb1Arnud', 'IMG_0178.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-38-vita-hallen-variant.jpg', 'https://drive.google.com/file/d/1DIe7DcRi7eWWYp3a6m388sy-Sb1Arnud/view', 'unverified', false, 'Drive: Ridhuset/IMG_0178.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: arena short side at A seen from the long-side stand', '213e7c713802146697f184aa7c0d0add378a363c596f4e8030d5ba21e4cb22ff', 585363)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1dJratW5hQ2g128lypzhPFbxeSxbLUbhu', 'IMG_0179.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg', 'https://drive.google.com/file/d/1dJratW5hQ2g128lypzhPFbxeSxbLUbhu/view', 'unverified', false, 'Drive: Ridhuset/IMG_0179.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: short side C: spectator benches, stair enclosures and the glass rooms above', '35e8992aea11e6d1c00239811b1b65d11338927c5f3a26b74fe70b0add503a74', 654819)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vdW3E6Rl29L7VR9zXaJxJp4ipunkdHIY', 'IMG_0180.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-39-gangen-bakom-laktaren.jpg', 'https://drive.google.com/file/d/1vdW3E6Rl29L7VR9zXaJxJp4ipunkdHIY/view', 'unverified', false, 'Drive: Ridhuset/IMG_0180.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: walkway on the long-side stand, toward the C-end corner and the club door', 'a6be2532594c9ee76858259cba3d5f46e8e31d5ad3d7e37d21160f4c99d37532', 566287)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ZyI3hE8_sMbds8e5tOHpJCxM0C0XNf4n', 'IMG_0181.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-40-domartornet-pa-laktaren.jpg', 'https://drive.google.com/file/d/1ZyI3hE8_sMbds8e5tOHpJCxM0C0XNf4n/view', 'unverified', false, 'Drive: Ridhuset/IMG_0181.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: judges'' tower on the long-side stand, toward short side A', '87ebef9a68d926407fa9d635c00453c05458f8fd9336598a15ab95430bc3c3fa', 524103)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Dp2DQHpfAs2MRxtsvOpBrcJFkWXQH6Tr', 'IMG_0182.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-41-banan-fran-laktaren.jpg', 'https://drive.google.com/file/d/1Dp2DQHpfAs2MRxtsvOpBrcJFkWXQH6Tr/view', 'unverified', false, 'Drive: Ridhuset/IMG_0182.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: arena seen from the long-side stand toward the C-end corner (club gallery left, M end of the sponsor long side right)', '03afcff77866c5e66a140122e6f1eac871c8ddb0e07c377041faa1ad23beb9fd', 754718)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Anp0_PYPWZr9RAeHZ0rZQVLGpDSCOKHI', 'IMG_0183.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-02-langsidan.jpg', 'https://drive.google.com/file/d/1Anp0_PYPWZr9RAeHZ0rZQVLGpDSCOKHI/view', 'unverified', false, 'Drive: Ridhuset/IMG_0183.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: sponsor long side at F and the white A-end corner, seen from the stand', 'bf5af73041d50b654a292b1edf9f2cbc68c2fd20fcab031c90f2340512a3057e', 717648)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vLWID08tJRw8lCUbKYzXslj0NzjIqajm', 'IMG_0184.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-42-vita-hallen.jpg', 'https://drive.google.com/file/d/1vLWID08tJRw8lCUbKYzXslj0NzjIqajm/view', 'unverified', false, 'Drive: Ridhuset/IMG_0184.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: arena short side at A (white end) with the horse entrance', '6fd0d1da2b6a1c9ec6c715081ff11c865ffe8e1177d8b75f042bb4d92e7d5856', 610065)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1BTTG0o3gKq32ld_WtYgT6JbRqgaVUNtT', 'IMG_0185.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1BTTG0o3gKq32ld_WtYgT6JbRqgaVUNtT/view', 'unverified', false, 'Drive: Ridhuset/IMG_0185.MOV; byggnad: ridhus; status: DRIVE-ONLY; 4 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'd441e373cf25b248d5284e1a20d31a795db51354ca9a7e1e4175df61b0931885', 23208283)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1qV9oq8Qd7iPxl90UHvjiy9ldDSLxg_3y', 'IMG_0188.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1qV9oq8Qd7iPxl90UHvjiy9ldDSLxg_3y/view', 'unverified', false, 'Drive: Ridhuset/IMG_0188.MOV; byggnad: ridhus; status: DRIVE-ONLY; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '6c8bbb6227479ca01eda008c7a841e6d5468b0698c75b7d2b1234e2c83be4ab1', 69964568)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1x3DNA1yIENHDEbmhN3lqiDdnDJ8vYRxw', 'IMG_0189.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1x3DNA1yIENHDEbmhN3lqiDdnDJ8vYRxw/view', 'unverified', false, 'Drive: Ridhuset/IMG_0189.MOV; byggnad: ridhus; status: DRIVE-ONLY; 6 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '7988239250c54184f66bdb2102ef95f3f83ca400b257e4a5ab828bc4642fdda4', 39142412)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1jzZa1yc90eYyhl38Y0sIiTRWuMFGbcZy', 'IMG_0191.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1jzZa1yc90eYyhl38Y0sIiTRWuMFGbcZy/view', 'unverified', false, 'Drive: Ridhuset/IMG_0191.MOV; byggnad: ridhus; status: DRIVE-ONLY; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '1c79cdec7a908428ead52bf188e02b10c03496b49e3251c0cee1670fc3b249f1', 98812338)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1mzYSHM7EAA3cmYsrfOjhGWFuLLyz3Z2Z', 'IMG_0192.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1mzYSHM7EAA3cmYsrfOjhGWFuLLyz3Z2Z/view', 'unverified', false, 'Drive: Ridhuset/IMG_0192.MOV; byggnad: ridhus; status: DRIVE-ONLY; 8 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'd3eb10e72cb16e4d2201d327ffed5f159b67f0a63d7af520f6d64920a35e5a9c', 51303177)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cCkXhoG7Y6yTeVIMI25dXRtwwKkb6AZZ', 'IMG_0193.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-klubb-22-omkladningsrummet.jpg', 'https://drive.google.com/file/d/1cCkXhoG7Y6yTeVIMI25dXRtwwKkb6AZZ/view', 'unverified', false, 'Drive: Ridhuset/IMG_0193.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: changing room with lockers and the white/red seating group (position in the building not shown)', '8d741cf137670153abdbf4e3ad26c39474e4a905534dca8b7c31afb5b05e798d', 506252)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1FiTariRohVx5a-wHIkxD2yWEQbLjZ00I', 'IMG_0195.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1FiTariRohVx5a-wHIkxD2yWEQbLjZ00I/view', 'unverified', false, 'Drive: Ridhuset/IMG_0195.MOV; byggnad: ridhus; status: DRIVE-ONLY; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '3653fff6a984a6bbc2c8507102c29be0ac4cab60bfc25ea0c5ee34997cb2e92e', 69652420)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1pwK34ZGhQm3loI0IATaLD1DscFfGOYgo', 'IMG_0196.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1pwK34ZGhQm3loI0IATaLD1DscFfGOYgo/view', 'unverified', false, 'Drive: Ridhuset/IMG_0196.MOV; byggnad: ridhus; status: DRIVE-ONLY; 4 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '46d86dcd68013141e54b1894a2c3674832b3ab640cec8c60ddc8e49165e66354', 25430699)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1gfqHJAFiQJ4tqpSBa2BDXeLFjYcyZ5Gx', 'IMG_0197.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-43-laktaren-vid-h.jpg', 'https://drive.google.com/file/d/1gfqHJAFiQJ4tqpSBa2BDXeLFjYcyZ5Gx/view', 'unverified', false, 'Drive: Ridhuset/IMG_0197.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: stand and kickboard at letter H, by the stair up to the gallery', 'a9b5db0eebbbcbedf6ea590d41ce30c724199dbcbc3dc4aad07c0ddc3d7ddd06', 716496)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1gq6KdDtYxod3C9EIJ4J2NW3JNQ77ermp', 'IMG_0198.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg', 'https://drive.google.com/file/d/1gq6KdDtYxod3C9EIJ4J2NW3JNQ77ermp/view', 'unverified', false, 'Drive: Ridhuset/IMG_0198.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: stand at letter E with the wooden speaker''s booth', '4846b581a0850f68a99a28eae165c5d14b0e88b95fd5cb9de5504c7e4423255c', 606200)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1G71xkQjbMp_GZ0PN4Cbm6dVtrRyTjJgJ', 'IMG_0199.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/ridhus-inne-44-klubbhornet-med-bommar.jpg', 'https://drive.google.com/file/d/1G71xkQjbMp_GZ0PN4Cbm6dVtrRyTjJgJ/view', 'unverified', false, 'Drive: Ridhuset/IMG_0199.HEIC; byggnad: ridhus; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: club-end corner of the stand used as jump-material store', '0778084c9702c93b75851cf75b3065b2d19a66800ca6519298609ef07350e39c', 436183)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1tgAZe75O-tiRsSPtoVCm4Ivsd0HFS99R', 'IMG_0205.HEIC — ridhus-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1tgAZe75O-tiRsSPtoVCm4Ivsd0HFS99R/view', 'unverified', false, 'Drive: Ridhuset/IMG_0205.HEIC; byggnad: ridhus; status: DRIVE-ONLY; registreringsskylt i bild; visar: car-park gable of the riding hall, café-stair end', '753b4df576b22451d4eaeae17ad520454bf902787367063a49106c0d41db9a34', 2798694)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1zjUJYkMZuvDt4wuR-tPEvNFebGcrpT4G', 'IMG_0206.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0206-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1zjUJYkMZuvDt4wuR-tPEvNFebGcrpT4G/view', 'unverified', false, 'Drive: Ridhuset/IMG_0206.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: car-park gable of the riding hall, stable-side half with the two entrance porches', 'bb07a8b560cacfd8e8aaa8cbcc182880c17f22f687d4a31fa2ba69978eaf6093', 839081)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1xLqEKCiU0_36rUFzCxvsDO-CfEdVn5H1', 'IMG_0207.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0207-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1xLqEKCiU0_36rUFzCxvsDO-CfEdVn5H1/view', 'unverified', false, 'Drive: Ridhuset/IMG_0207.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: car-park gable of the riding hall, middle section from the black-door porch to the café stair', '15444470f29075918ddfab2c8f52919d5e0de62a967a15c422d89e5f2c558ccc', 759423)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1h_iGpUSssQ-LFlel411Gzu89F8-qpjOo', 'IMG_0208.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0208-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1h_iGpUSssQ-LFlel411Gzu89F8-qpjOo/view', 'unverified', false, 'Drive: Ridhuset/IMG_0208.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: car-park gable of the riding hall, middle section (near-duplicate of IMG_0207)', 'e868a9bed6d6984fc30a202fbbf6a475d9403b6a18eab118626652977a64dee4', 773616)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1CJfAVnnxilkGVMgLAWi3gyRxY6WIusDc', 'IMG_0209.HEIC — ridhus-exterior', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0209-ridhus-exterior.jpg', 'https://drive.google.com/file/d/1CJfAVnnxilkGVMgLAWi3gyRxY6WIusDc/view', 'unverified', false, 'Drive: Ridhuset/IMG_0209.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable-side corner of the riding-hall gable with the yard signpost', 'df99073e94f92632c196baa86f3f3387898308c0315e83c1071e1ff8d26415cc', 604781)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1hMlEei8QrwxBSjuLOppXtovsE47kCdR3', 'IMG_0250.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0250-stall-exterior.jpg', 'https://drive.google.com/file/d/1hMlEei8QrwxBSjuLOppXtovsE47kCdR3/view', 'unverified', false, 'Drive: Ridhuset/IMG_0250.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: timber-clad eaves wall with one arched, barred window - matches the stable facade although filed under Ridhuset [antagande]; which side is not shown', 'b15cf375783e68e1b5b064d5d28a0261bca998ea65bbebf29eaa12d2316f6baa', 595689)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1sfnJSI6xV-lU-WRgQ1DciZZ_T6PBy0Fz', 'IMG_0251.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0251-stall-exterior.jpg', 'https://drive.google.com/file/d/1sfnJSI6xV-lU-WRgQ1DciZZ_T6PBy0Fz/view', 'unverified', false, 'Drive: Ridhuset/IMG_0251.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: corner of the same timber-clad building (stable-type cladding) [antagande]; which corner is not shown', '919d12448a815ae81b17eac194ec8e41395d700ce0957a7b2beb132abbf18ec0', 756595)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1lhGuikpzUKrcyy6mAR-MDeIAeIQ0jt7n', 'IMG_0252.MOV — stall-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1lhGuikpzUKrcyy6mAR-MDeIAeIQ0jt7n/view', 'unverified', false, 'Drive: Ridhuset/IMG_0252.MOV; byggnad: stall; status: DRIVE-ONLY; 8 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '9c02efd79753acffae88b01b493f25d5ab935a6a76b823085e9323cda7a5f7f3', 17191371)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XtxSXU9lqb0EIQNNXS59DFP2kuVNHgZz', 'IMG_0253.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0253-stall-exterior.jpg', 'https://drive.google.com/file/d/1XtxSXU9lqb0EIQNNXS59DFP2kuVNHgZz/view', 'unverified', false, 'Drive: Ridhuset/IMG_0253.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: yard surface at the foot of a timber-clad wall with plank double door and service door; steel legs on a concrete pad may be the feed silo [antagande]', '5a15ad4642cc508aceffc0a386ab622c54b5d9080804de0158d409587b0bb861', 1329337)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-12Jh6NA-ZfIvbBkgb7nNQdEjUMZHjP6k9', 'IMG_0254.MOV — stall-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/12Jh6NA-ZfIvbBkgb7nNQdEjUMZHjP6k9/view', 'unverified', false, 'Drive: Ridhuset/IMG_0254.MOV; byggnad: stall; status: DRIVE-ONLY; 19 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'a34b5b3dba2043eb6b90ae9aec4f0d70c432a059f09ae142bba62e7edb3c51e1', 35996489)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1iCMB71cLfVNKoHEVKO06Dhif2vlkR23y', 'IMG_0255.MOV — ridhus-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1iCMB71cLfVNKoHEVKO06Dhif2vlkR23y/view', 'unverified', false, 'Drive: Ridhuset/IMG_0255.MOV; byggnad: ridhus; status: DRIVE-ONLY; 15 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '2f094aa2ecf641ee232eebb65ddbebd9c8b566621bfab7904244728a8b86a911', 25816559)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1jYclouyulb53iifowQLPuDzAP8xHE5b_', 'IMG_0256.MOV — ridhus-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1jYclouyulb53iifowQLPuDzAP8xHE5b_/view', 'unverified', false, 'Drive: Ridhuset/IMG_0256.MOV; byggnad: ridhus; status: DRIVE-ONLY; 8 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'ec7b02fd801c54168f901fe44c412d49544dd2af7aaca58cdbd5560a719c47d5', 15300365)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1uLDznXvAE45n8Uh4-g6cjqVQPPL29Gv0', 'IMG_0257.MOV — gard-omnejd', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1uLDznXvAE45n8Uh4-g6cjqVQPPL29Gv0/view', 'unverified', false, 'Drive: Ridhuset/IMG_0257.MOV; byggnad: omnejd; status: DRIVE-ONLY; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'a73852fa9163ff1284c02dee455eede698b5442c6639578d0264e62c28ee7dae', 7528267)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1SNZSHFA5TLI74IlfOu86OwHX4ivPkAC_', 'IMG_0258.MOV — ridhus-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1SNZSHFA5TLI74IlfOu86OwHX4ivPkAC_/view', 'unverified', false, 'Drive: Ridhuset/IMG_0258.MOV; byggnad: ridhus; status: DRIVE-ONLY; 11 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'e6509b7b3079dd3e363a74c1077599a9afddb2e0230a18ae6361971db891fcd3', 38204315)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1eJ-znx0cl5kMiv4bCTbzasCfTGASigW-', 'IMG_0259.MOV — ridhus-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1eJ-znx0cl5kMiv4bCTbzasCfTGASigW-/view', 'unverified', false, 'Drive: Ridhuset/IMG_0259.MOV; byggnad: ridhus; status: DRIVE-ONLY; 6 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '5f6ca6df53a6dde996ea3f3cedacb14c23aa7ec3624b3a003d702c4a0e74b081', 32749256)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ubf6BstApp5SnxZbwigSyQzZRqQYHGM0', 'IMG_0260.MOV — ridhus-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1ubf6BstApp5SnxZbwigSyQzZRqQYHGM0/view', 'unverified', false, 'Drive: Ridhuset/IMG_0260.MOV; byggnad: ridhus; status: DRIVE-ONLY; 7 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'c444147835fd4969688095f1e7703243754b5835ae9c976395ab6c1ff06dedbe', 28231496)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1VsWAlvzgsoslmish5l3pdAEGj4IzY7hp', 'IMG_0261.HEIC — ridhus-klubbdel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1VsWAlvzgsoslmish5l3pdAEGj4IzY7hp/view', 'unverified', false, 'Drive: Ridhuset/IMG_0261.HEIC; byggnad: ridhus; status: DRIVE-ONLY; person i bild; visar: glazed aluminium entrance door to the room with the white/red armchairs (changing-room furniture); position on the building not shown [REFERENCE GAP]', '0a808df3d5bd77488a24524f0045ba0b28429f85065038e53fa1fe72422a51c5', 1429422)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1T5thGCR8S8wIkofnQq1E_X2OTsgrwjXb', 'IMG_0262.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0262-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1T5thGCR8S8wIkofnQq1E_X2OTsgrwjXb/view', 'unverified', false, 'Drive: Ridhuset/IMG_0262.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: locker hall (omklädningsgången) on the club part''s ground floor, seen through its wide entrance opening', 'abfea57873823f7f2f13eadc007d92f6c59c073893fe199c3e666dc0368279d1', 298009)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1P1XYhKXbmrAaw3DW9X4hqK9oIfIe4782', 'IMG_0263.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0263-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1P1XYhKXbmrAaw3DW9X4hqK9oIfIe4782/view', 'unverified', false, 'Drive: Ridhuset/IMG_0263.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: locker hall, office (kansli) window wall with the seating group in front', 'bd91a38f7f8dce259d1864510057f5f25c752c5529cf652423d3d23d9416b6a7', 361320)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-14qmu9wPMI96dnRtEgwcq_-15FcOvorYJ', 'IMG_0264.HEIC — ridhus-klubbdel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/14qmu9wPMI96dnRtEgwcq_-15FcOvorYJ/view', 'unverified', false, 'Drive: Ridhuset/IMG_0264.HEIC; byggnad: ridhus; status: DRIVE-ONLY; person i bild; visar: narrow club corridor with white doors, ending in the glazed double door (korridordörrarna)', '9db450254ca01ad1adf112e34269260c69b1e3209ad974d092e3e3d9e33b4ee6', 1924187)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1rb-YviSh4qLR-hs1OhPcgmYbfzlSAnHl', 'IMG_0265.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0265-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1rb-YviSh4qLR-hs1OhPcgmYbfzlSAnHl/view', 'unverified', false, 'Drive: Ridhuset/IMG_0265.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: locker hall, close view of the office (kansli) window wall', '53dcc8fd733048ac06fdc9fa7994534c4ce01f7f4b5a17999d6f5192b50ea8fa', 247864)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1uG1eI98gVZzZt0GZFfai4zXGJBYx06Po', 'IMG_0266.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0266-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1uG1eI98gVZzZt0GZFfai4zXGJBYx06Po/view', 'unverified', false, 'Drive: Ridhuset/IMG_0266.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: locker hall, seating group in front of the office window wall, toward the far end', '82196fb59b7d70fc5777cc57d2732edabbc9de251b803061ce8dc72407f44b6a', 360410)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1nMXV_yjGtao8NlurrwwGvshNIenMKw-o', 'IMG_0267.HEIC — ridhus-klubbdel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1nMXV_yjGtao8NlurrwwGvshNIenMKw-o/view', 'unverified', false, 'Drive: Ridhuset/IMG_0267.HEIC; byggnad: ridhus; status: DRIVE-ONLY; registreringsskylt i bild; visar: changing-room corner with the arched window (valvfönstret) toward the parking', '1f4801a3a701ad6845cf5fa0b7283666d89872aa66249a1dffd7fbd5b7098be0', 1578736)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cLysl4PEQeM4sdJ_52oG6wGY-bnsbKpA', 'IMG_0268.MOV — ridhus-klubbdel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1cLysl4PEQeM4sdJ_52oG6wGY-bnsbKpA/view', 'unverified', false, 'Drive: Ridhuset/IMG_0268.MOV; byggnad: ridhus; status: DRIVE-ONLY; 26 nyckelrutor under references/video/; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '751a4bfa81246a0f1b3c6d31405f29ba0ec96298bb1119e99a564ab83c97f69b', 28721696)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1OvmSlHKE48AJzQeWuL2OtchSz26zZ7yQ', 'IMG_0269.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0269-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1OvmSlHKE48AJzQeWuL2OtchSz26zZ7yQ/view', 'unverified', false, 'Drive: Ridhuset/IMG_0269.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: ground-level walkway at the C/H corner under the glass room, toward the black exit door', 'a774e06af900a66a5c9854c622475130cee06c807a43bef86773718bc3fe795d', 390728)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1y-m66GYTIlm9ezfeCXtOlvHKOLguKs8Y', 'IMG_0270.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0270-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1y-m66GYTIlm9ezfeCXtOlvHKOLguKs8Y/view', 'unverified', false, 'Drive: Ridhuset/IMG_0270.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: café hall (cafésalen) seen through a glass-room window', '064ed42598b64b51315e5ac44a54364f533cd55d526ccd47eb838f1f44d3ef11', 377851)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-12pZFHv5D2IKjHOox_w_67RIhAmlELeJ4', 'IMG_0271.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0271-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/12pZFHv5D2IKjHOox_w_67RIhAmlELeJ4/view', 'unverified', false, 'Drive: Ridhuset/IMG_0271.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: café (Café Krubban) kitchen wall with serving / dish-return hatches, seen through a glass-room window', 'c22914565c0af3a8913c93b421cea23af1a1fb80b651da8e9937172deb200813', 435993)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1xD2b3ZNZbd9nS-p3J6Kjwld5aVeH1vk8', 'IMG_0272.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0272-ridhus-arena.jpg', 'https://drive.google.com/file/d/1xD2b3ZNZbd9nS-p3J6Kjwld5aVeH1vk8/view', 'unverified', false, 'Drive: Ridhuset/IMG_0272.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: whole arena lengthwise from short side C (club end, near the H corner) toward short side A', '1cd6962cc4d27069d4163953589284428f1f9712db6d0ac9e810eacaab5d02b9', 627302)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-12vo-uEjw37MxvEzwNBeN5nPyZ58CnE3f', 'IMG_0273.HEIC — ridhus-arena', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0273-ridhus-arena.jpg', 'https://drive.google.com/file/d/12vo-uEjw37MxvEzwNBeN5nPyZ58CnE3f/view', 'unverified', false, 'Drive: Ridhuset/IMG_0273.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sponsor long side (M-B-F) seen diagonally from short side C', 'a30e4f0e4cc0dc8b826d7f129924b2992343713e93ade0e5c4bde22d08e19b05', 510505)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ewof3LZCQIX682Jl--YZP6ZAPNNnxkU5', 'IMG_0274.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0274-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1ewof3LZCQIX682Jl--YZP6ZAPNNnxkU5/view', 'unverified', false, 'Drive: Ridhuset/IMG_0274.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stand (läktare) long side at H, from the C/H corner, with the stair up to the glass room', '1299295f9b073be804852644600436e3807aa55c666f8b8f3e83c8be7258db8c', 560761)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1uwspuPfSji_CtsXIT0MDG7Q4FDMLTVVY', 'IMG_0275.MOV — ridhus-arena', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1uwspuPfSji_CtsXIT0MDG7Q4FDMLTVVY/view', 'unverified', false, 'Drive: Ridhuset/IMG_0275.MOV; byggnad: ridhus; status: DRIVE-ONLY; 6 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '3d97b655fb75313c4b7590434d699429161c69ae75e355f7f0b38d5104c2d8fc', 24582357)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1zmLzgoT0Bv_FcXBGUAQ5S3I3PxVHQGS5', 'IMG_0276.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0276-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1zmLzgoT0Bv_FcXBGUAQ5S3I3PxVHQGS5/view', 'unverified', false, 'Drive: Ridhuset/IMG_0276.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: ground-level walkway at the C/H corner under the glass room: black exit door, club wall windows, stair', '7888aa7d9268825b55158a68946bb93006764858aa114cf6b50a69c4467ef878', 414212)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1tJH0Bhj9T2iYX-oE51Itn24OZlegZS6d', 'IMG_0277.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0277-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1tJH0Bhj9T2iYX-oE51Itn24OZlegZS6d/view', 'unverified', false, 'Drive: Ridhuset/IMG_0277.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: club wall corner beside the black exit door: notice board, fire equipment, blind window', '64b100c6ef34a39e9d693abd2e992a5c447efdbd90650808354c818bf67514fa', 444447)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cztK5u2oXYMNE81sUWyuuhzmGuUQ4hPv', 'IMG_0278.HEIC — ridhus-laktare-glasrum', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0278-ridhus-laktare-glasrum.jpg', 'https://drive.google.com/file/d/1cztK5u2oXYMNE81sUWyuuhzmGuUQ4hPv/view', 'unverified', false, 'Drive: Ridhuset/IMG_0278.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: club wall corner beside the black exit door (second, closer take)', 'dd5333d52cc336d6b71d80869a8bd75ceccc53d60672a1310ba0ef2c2c363f07', 469545)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1IgSzdwmWBVCbzfZKzq6ZGoozwphDW3V0', 'IMG_0279.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0279-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1IgSzdwmWBVCbzfZKzq6ZGoozwphDW3V0/view', 'unverified', false, 'Drive: Ridhuset/IMG_0279.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: locker room with the free-standing pillar (skåprummet med pelaren)', 'ad976ead33ced79cb5bcbb2785fedf595412f1548361fba1368d547f46c6f30d', 240218)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1rJnRGL4sQegla038j3QefxjfkNHoh976', 'IMG_0280.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0280-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/1rJnRGL4sQegla038j3QefxjfkNHoh976/view', 'unverified', false, 'Drive: Ridhuset/IMG_0280.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: changing/locker room with two-tier padlocked lockers (which room and floor: not determinable from the photo)', '6c39a862ca7ca116356f3dd450292fbfddbd8703eaed201e6bea42eebac96d59', 210317)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-19mnzUFIxD3XvKiWyGqTxkGT5sxY0bVQx', 'IMG_0281.HEIC — ridhus-klubbdel', 'photo', 'google_drive', 'references/buildings/ridhus/drive-2026-11-26/IMG_0281-ridhus-klubbdel.jpg', 'https://drive.google.com/file/d/19mnzUFIxD3XvKiWyGqTxkGT5sxY0bVQx/view', 'unverified', false, 'Drive: Ridhuset/IMG_0281.HEIC; byggnad: ridhus; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: changing room with tall Z-door lockers (same kind of room as repo ridhus-klubb-22): the gap between two locker banks', '2615a0730b739ad3926c92be4c1d6363b740e70443a4d50675136fe779e4ba53', 251485)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-18gls36hRAK8CR9kD3Nr7PbnoWUrHwvC1', 'IMG_0282.MOV — ridhus-klubbdel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/18gls36hRAK8CR9kD3Nr7PbnoWUrHwvC1/view', 'unverified', false, 'Drive: Ridhuset/IMG_0282.MOV; byggnad: ridhus; status: DRIVE-ONLY; 33 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'ba4df6dd00d46ad88248706c2cb615c5d9526c64fb45f5f173df96114e99da31', 29850724)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1mruWebcJN8tPXafotPIzS6wGDmNXDk9e', 'IMG_0283.MOV — ridhus-klubbdel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1mruWebcJN8tPXafotPIzS6wGDmNXDk9e/view', 'unverified', false, 'Drive: Ridhuset/IMG_0283.MOV; byggnad: ridhus; status: DRIVE-ONLY; 26 nyckelrutor under references/video/; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'eacf5a57bf23900a321da8b4af1b8329d7e2928673fcdbd36c0fb5d9a32d9a25', 43052166)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1P73LxwX13njZHjSkBccUn8R65q72mnAZ', 'IMG_0303.HEIC — stall-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1P73LxwX13njZHjSkBccUn8R65q72mnAZ/view', 'unverified', false, 'Drive: Ridhuset/IMG_0303.HEIC; byggnad: stall; status: DRIVE-ONLY; registreringsskylt i bild; visar: timber-clad long side with grey service doors, concrete pad and IBC tank, near a gable corner - probably the stable''s east long side facing the track along the outdoor arena [inference; the Drive folder is ''Ridhuset''; which end of the building: REFERENCE GAP]', '8c15c0c4d8f62730ccb9ef588e65812b7890dbb0c957014765f04ea5205f7968', 3449446)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1RMFo80eXp3sZiQ4MrMO1ORQeZkyKpdDb', 'IMG_0304.HEIC — stall-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1RMFo80eXp3sZiQ4MrMO1ORQeZkyKpdDb/view', 'unverified', false, 'Drive: Ridhuset/IMG_0304.HEIC; byggnad: stall; status: DRIVE-ONLY; registreringsskylt i bild; visar: stable club gable (north in game) at ground level: spiral stair with caged base; forecourt and parking beyond', 'cf8223cc5aa562b674d9400e4a38d32e1a601adce64b0eec6bbaa83786b9bee2', 3903577)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1g-VMFZ5-ZRPG9fmWIaVYRuYHWoxKh2Ui', 'IMG_0305.HEIC — gard-omnejd', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1g-VMFZ5-ZRPG9fmWIaVYRuYHWoxKh2Ui/view', 'unverified', false, 'Drive: Ridhuset/IMG_0305.HEIC; byggnad: omnejd; status: DRIVE-ONLY; registreringsskylt i bild; visar: forecourt in front of the stable''s club end, from the foot of the spiral stair past the porch (förstukvist) toward the parking and the ''CAFÉ'' sign', '7b86f327f8ccf9dfc208cad7a9989adbb456de30193b8bd2a839762fb648c406', 3473468)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Nr79sgG0-XLjK7gBSji48fw6piwxVlLR', 'IMG_0132.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/stall-entre-16-runda-fonstren.jpg', 'https://drive.google.com/file/d/1Nr79sgG0-XLjK7gBSji48fw6piwxVlLR/view', 'unverified', false, 'Drive: Stallhuset/IMG_0132.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: stable main entrance door inside the porch (förstukvist)', '1c007c45ba64be201f90973406c97e1cd881c1fc003866af0ef7b7ad6755e798', 479609)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1t40OR72_1RY-xzSRdgJnaO2MqQsiAEtd', 'IMG_0133.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1t40OR72_1RY-xzSRdgJnaO2MqQsiAEtd/view', 'unverified', false, 'Drive: Stallhuset/IMG_0133.HEIC; byggnad: stall; status: DRIVE-ONLY; kontaktlista vid larmpanelen, delvis läsbar; visar: grey steel door with the fire-alarm panel beside it, stable club/service end (exact door not determinable; probably the wide grey door at the left edge of IMG_0134 [inference])', 'bf28a141da8cf2754e788194adc9b484cfd56b1794e104011c43f42ae8cd204f', 2712539)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1krpVxjKxQRxx-MyZfPwML4jdx3pi8QCn', 'IMG_0134.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-01-uppehallsrummet.jpg', 'https://drive.google.com/file/d/1krpVxjKxQRxx-MyZfPwML4jdx3pi8QCn/view', 'unverified', false, 'Drive: Stallhuset/IMG_0134.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: uppehållsrummet (lounge) in the stable''s club end: sofa corner by the arched window', '9c291009ba9eaa9399aeee37501c6bf662dd5d489eb11dfa8586a2bee2cdcc18', 393944)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1743ACBSw8z0TvbCfw0Ku8sI-NFophKV4', 'IMG_0135.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-02-pentryt.jpg', 'https://drive.google.com/file/d/1743ACBSw8z0TvbCfw0Ku8sI-NFophKV4/view', 'unverified', false, 'Drive: Stallhuset/IMG_0135.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: pentry corner of the entrance/lounge room, on the outer wall with the porch''s round window', '6aa3cbb9f1c02546f137178fbac890a170e3687073180c275a6cf721ebc91b68', 376679)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1x9IERk58zglC_thPjM5_6w-FvaGZaLx2', 'IMG_0136.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0136-stall-servicedel.jpg', 'https://drive.google.com/file/d/1x9IERk58zglC_thPjM5_6w-FvaGZaLx2/view', 'unverified', false, 'Drive: Stallhuset/IMG_0136.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: visitors'' corner in the stable''s entrance/lounge area: storage lockers for lesson riders, coat hooks, bistro table by an arched window; lift signage at the right', '9e9e93e09a4b727846f639ecdad9a88eab643f98c28f6a7f4e569ba4a47d25b4', 339961)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1C37UtamLjpi_fE9VeMHoq1xfnin2yYy_', 'IMG_0137.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-03-sadelkammaren.jpg', 'https://drive.google.com/file/d/1C37UtamLjpi_fE9VeMHoq1xfnin2yYy_/view', 'unverified', false, 'Drive: Stallhuset/IMG_0137.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: equipment room with loan body protectors and boots (repo file name: ''sadelkammaren''); door to the ''Teorisal''', 'aa4066510f498acb8175390cc7370d6e3a7ac900fc2670d81165828400297518', 466510)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1byXX_8PeBAqOtDMuzPC5yRQeksbmI7aw', 'IMG_0138.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-04-teorisalen.jpg', 'https://drive.google.com/file/d/1byXX_8PeBAqOtDMuzPC5yRQeksbmI7aw/view', 'unverified', false, 'Drive: Stallhuset/IMG_0138.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: teorisalen (theory room) in the stable''s club end: whiteboard wall and right-hand wall', '30803f90ce2024f1a13f87406716566af6aabbfafa8f6891a7067904816523f9', 396746)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Klpq6FXEPhBaQhNEfe8TqjVL-4ZlMY_B', 'IMG_0139.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1Klpq6FXEPhBaQhNEfe8TqjVL-4ZlMY_B/view', 'unverified', false, 'Drive: Stallhuset/IMG_0139.HEIC; byggnad: stall; status: DRIVE-ONLY; whiteboard med lägerschema: förnamn parade med hästnamn, läsbart; visar: teorisalen (theory room): window wall with the hobby-horse shelf, toward the whiteboard', '69e2a272623fe0e7dd8cc16db8f9d62ba7e387b082c2e182268fea6747cd8614', 1661770)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1mjPS-MUCoYpScKifKU_e-bylGttUvRFr', 'IMG_0140.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0140-stall-servicedel.jpg', 'https://drive.google.com/file/d/1mjPS-MUCoYpScKifKU_e-bylGttUvRFr/view', 'unverified', false, 'Drive: Stallhuset/IMG_0140.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: teorisalen (theory room) seen from its doorway: bookshelf and the left end of the window wall', 'e837b68ba23ccc942f6c23f050f2f30d1f3c098c8a3dff14882c244af17600d8', 453524)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1aUJbXj3-SVfclLnPsn9GzRPpTcK1Ez5E', 'IMG_0141.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0141-stall-servicedel.jpg', 'https://drive.google.com/file/d/1aUJbXj3-SVfclLnPsn9GzRPpTcK1Ez5E/view', 'unverified', false, 'Drive: Stallhuset/IMG_0141.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: door to the accessible toilet, stable club/service end (position in the plan not shown)', 'e57a726b55406604666a3c8a042fcb5a3aa1ead7b17d045d5bba6110dcb70365', 258438)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1167-TfpEuJqS0rS8foRh6SppN0ju9Nk1', 'IMG_0142.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0142-stall-servicedel.jpg', 'https://drive.google.com/file/d/1167-TfpEuJqS0rS8foRh6SppN0ju9Nk1/view', 'unverified', false, 'Drive: Stallhuset/IMG_0142.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: accessible toilet interior, stable club/service end', '8acae0a724d6d641b4b2dc592ebedb9b23f784b9534888f88dbf6168876fea20', 370692)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-18_SpefPV7FtyoPaHJwz6TbFvkAkatlnd', 'IMG_0143.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0143-stall-servicedel.jpg', 'https://drive.google.com/file/d/18_SpefPV7FtyoPaHJwz6TbFvkAkatlnd/view', 'unverified', false, 'Drive: Stallhuset/IMG_0143.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: toilet (WC) room in the stable building', '6287c4947f3f6492ffa4aa8e8c59c183ecd03890111629badb9b46a1db238df4', 344571)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1sfm_6tn7DGEO0_5IzNtfmAeKjvvPvo4g', 'IMG_0144.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0144-stall-servicedel.jpg', 'https://drive.google.com/file/d/1sfm_6tn7DGEO0_5IzNtfmAeKjvvPvo4g/view', 'unverified', false, 'Drive: Stallhuset/IMG_0144.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: toilet door, corridor side', '057fa46206c4a987a49a5bdcb5dc17d3458b246097daf1ce98362d31628f1dfc', 181178)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1y5v5CAr-jupDHs9eCxlfxlP57TfdRs1o', 'IMG_0145.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0145-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1y5v5CAr-jupDHs9eCxlfxlP57TfdRs1o/view', 'unverified', false, 'Drive: Stallhuset/IMG_0145.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box aisle between the outer-wall row (right, arched windows) and the ridge-side row (left), towards the grey double door with clock', '6030681685e96274f7075a2a961cc44c3086cac15b86bc7a5c6cc4a502b19a22', 668630)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-11KFJFnE4GK4MXSllZ_TPwy9dBuMVTab3', 'IMG_0146.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0146-stall-boxgangar.jpg', 'https://drive.google.com/file/d/11KFJFnE4GK4MXSllZ_TPwy9dBuMVTab3/view', 'unverified', false, 'Drive: Stallhuset/IMG_0146.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box aisle between the outer-wall row (right, arched windows) and the ridge-side row (left), towards the grey double door with clock', '8f707582a8842dc527e879b166a6afba946cc37ce44f5ea456e3b23bcfd652d1', 603613)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1gxi16UPwwKtuoCi0N_1FHOrjO7kA7EXT', 'IMG_0147.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0147-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1gxi16UPwwKtuoCi0N_1FHOrjO7kA7EXT/view', 'unverified', false, 'Drive: Stallhuset/IMG_0147.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box aisle between the outer-wall row (right, arched windows) and the ridge-side row (left), towards the grey double door with clock', '0d80d27181dc6d039b214de91a5e142bb370030fee45c9daaa24b2566ba23428', 520220)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XSM7ybfOOBAD7vF-nhZGWceRXavZpTA8', 'IMG_0148.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-05-stallgangen.jpg', 'https://drive.google.com/file/d/1XSM7ybfOOBAD7vF-nhZGWceRXavZpTA8/view', 'unverified', false, 'Drive: Stallhuset/IMG_0148.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: box aisle between the outer-wall row (right, arched windows) and the ridge-side row (left), towards the grey double door with clock', 'e80399687a6c53b8aea06b121a55f7ef20f63a55cbba658638a9b25561ac7130', 594673)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1VG42pXOvFcYUK7oBt_U_Jy2ndqUhDCsp', 'IMG_0149.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0149-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1VG42pXOvFcYUK7oBt_U_Jy2ndqUhDCsp/view', 'unverified', false, 'Drive: Stallhuset/IMG_0149.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box aisle between the outer-wall row (right, arched windows) and the ridge-side row (left), towards the grey double door with clock', '49555b0ed606707a3cf2f612568a3d9d54fe3706292b979b129db7a0364dd394', 642994)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1xwd0PjqcRMxz_oMg_skL2eK6oWfR9LVt', 'IMG_0150.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-06-boxen-inifran.jpg', 'https://drive.google.com/file/d/1xwd0PjqcRMxz_oMg_skL2eK6oWfR9LVt/view', 'unverified', false, 'Drive: Stallhuset/IMG_0150.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: single box seen through its open front, ridge-side row', '55f2007ff679ddad689b68fad3a5e4a6089d34fb3a6db17e5c573ee152ecfbe6', 708906)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1pXnPC3viLgQTEzZNw9anKKpBiSqjv9pp', 'IMG_0151.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0151-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1pXnPC3viLgQTEzZNw9anKKpBiSqjv9pp/view', 'unverified', false, 'Drive: Stallhuset/IMG_0151.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: outer-row boxes against the white exterior wall with arched windows', '8d8070c06e557c56033a2a6466bb6004ed4aa28d32a55016851975651e62eab0', 505911)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-14EEmEpyc18XD3GSuztiX7uo-E7jrodsC', 'IMG_0152.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0152-stall-boxgangar.jpg', 'https://drive.google.com/file/d/14EEmEpyc18XD3GSuztiX7uo-E7jrodsC/view', 'unverified', false, 'Drive: Stallhuset/IMG_0152.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: far end of the box aisle at the grey double door with clock', '219cbe5cefa19eb28220ac78d36e30e3b657dceb27debd2bde053c7fde070993', 551513)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ba68hu4oRqtThW-pOodkpzyh0kihN-yO', 'IMG_0153.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0153-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1ba68hu4oRqtThW-pOodkpzyh0kihN-yO/view', 'unverified', false, 'Drive: Stallhuset/IMG_0153.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box front close-up with a horse inside', '3c1e02e06415d34e4047f09f4b2677285231b48eeb56cacdb29a8d4d4bb3a1fd', 448247)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1OSxekhB_sMrBEIYWFXn4rEibGQ0PoTTC', 'IMG_0154.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-07-spolspiltan.jpg', 'https://drive.google.com/file/d/1OSxekhB_sMrBEIYWFXn4rEibGQ0PoTTC/view', 'unverified', false, 'Drive: Stallhuset/IMG_0154.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 1); visar: service passage along the white end wall with wash point (repo: spolspilta), towards the gable door', '6db94afe881af9dc46ebf913c3d53163ac654f2af64a85b17b02650b356cf8b1', 495603)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1LpyikgfjojN1Jc0WTCuwf8w35PZmAVUD', 'IMG_0155.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0155-stall-servicedel.jpg', 'https://drive.google.com/file/d/1LpyikgfjojN1Jc0WTCuwf8w35PZmAVUD/view', 'unverified', false, 'Drive: Stallhuset/IMG_0155.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna, roterad 180°; visar: service passage along the white end wall with wash point (repo: spolspilta), towards the gable door', 'baf333dc49257d60a0c5185808269b451c0352c83277079a12ffcbfd55fac6db', 511831)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ad8Q92Rl1OAzwCnQ5BL_rKXsFlTfuaYy', 'IMG_0156.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-08-breda-gangen.jpg', 'https://drive.google.com/file/d/1ad8Q92Rl1OAzwCnQ5BL_rKXsFlTfuaYy/view', 'unverified', false, 'Drive: Stallhuset/IMG_0156.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: ''breda gången'': wide, high passage behind grey double steel doors in the stable''s white wall', '76d115e8d38cc63c4525b59aae29667d4625ec69d522d9dd73730368c0b5f281', 436050)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-19ZSKAtNxCxYZUhNjma5044tmjrZ8mMXi', 'IMG_0157.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/19ZSKAtNxCxYZUhNjma5044tmjrZ8mMXi/view', 'unverified', false, 'Drive: Stallhuset/IMG_0157.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: ''breda gången'': wide, high passage behind grey double steel doors in the stable''s white wall', 'a492a21e36845402113a9dfbbdcb1049965fbe280c37c79021e0bc74841d34cc', 1843470)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1nznWPKcMICJ9IgPMMxbqiec2kBl584tt', 'IMG_0158.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/stall-inne-09-gangen-ut.jpg', 'https://drive.google.com/file/d/1nznWPKcMICJ9IgPMMxbqiec2kBl584tt/view', 'unverified', false, 'Drive: Stallhuset/IMG_0158.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 2); visar: service end: grooming/wash bays with galvanised hoop partitions beside the paved passage to the gable door', 'e2fdffe2395419a951bdcb942cf10bc5b0e366801983f090df051064b6a7408d', 430149)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1oeDVD4vilRJr9VOAjIMnHHi1WFr1EPdF', 'IMG_0159.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0159-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1oeDVD4vilRJr9VOAjIMnHHi1WFr1EPdF/view', 'unverified', false, 'Drive: Stallhuset/IMG_0159.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: box aisle with the outer-wall row on the left and the ridge-side (middle) row on the right, towards the end wall with grey double door and clock', '5bd6910bce46703e244cc58c486dbac1f16b0a1229f2a940ddda0333310011f4', 617716)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1WK_B2lmGdjwcTlFGmejoB3Y_wpMj2f3N', 'IMG_0160.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0160-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1WK_B2lmGdjwcTlFGmejoB3Y_wpMj2f3N/view', 'unverified', false, 'Drive: Stallhuset/IMG_0160.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: same box aisle, a few metres further in; outer-wall row left, ridge-side row right', '83e447562f9a0df0980bba56a156fb819f905968def7fb42e35684f5dbfe44b9', 655097)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1F3lJjQWPzXMrQSKsYMfWa26StFaq4an_', 'IMG_0161.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0161-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1F3lJjQWPzXMrQSKsYMfWa26StFaq4an_/view', 'unverified', false, 'Drive: Stallhuset/IMG_0161.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: same box aisle, about a third of the way in, next to an open box on the left', '297d6c23b0f81b306a21890392eb876c206668827ac34f3ab484d3640e13d964', 683790)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1tESBndM1AjFubA3EyWmBqP1E5oN5sfL9', 'IMG_0162.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0162-stall-boxgangar.jpg', 'https://drive.google.com/file/d/1tESBndM1AjFubA3EyWmBqP1E5oN5sfL9/view', 'unverified', false, 'Drive: Stallhuset/IMG_0162.HEIC; byggnad: stall; status: IN_REPO; JPEG 2048x1536, kvalitet 85, EXIF/XMP borttagna; visar: same box aisle, closest view of the end wall with grey double door and clock', '53664f673f75a6f9ebbe54340a11ba20287103f2583acb8c1fe3ca291c9e4757', 680849)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1h4O2vYwWcoL0KmABx_EpcoFNOHgJNZUY', 'IMG_0168.HEIC — stall-boxgangar', 'photo', 'google_drive', 'references/plans/stall-plan1-utrymning.jpg', 'https://drive.google.com/file/d/1h4O2vYwWcoL0KmABx_EpcoFNOHgJNZUY/view', 'unverified', false, 'Drive: Stallhuset/IMG_0168.HEIC; byggnad: stall; status: IN_REPO; migrerad före 2026-11-26 (phash-avstånd 0); visar: wall-mounted evacuation plan of the stable, ground floor ("Plan 1")', '04721af8821d5ce5c2b072092fd88c216ff8f0c0ababb164eb85af82aca9fa6a', 2744393)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1kexeD_-KzS_Ugzw3WHDBswlSHeigdszC', 'IMG_0210.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0210-stall-exterior.jpg', 'https://drive.google.com/file/d/1kexeD_-KzS_Ugzw3WHDBswlSHeigdszC/view', 'unverified', false, 'Drive: Stallhuset/IMG_0210.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: grass courtyard between the stable''s long side and the riding hall''s long side, closed at the far end by the low connecting link', 'bec8e85f681b9a9a6d3282775ccaba1fbdcf74c5ba3abdf80c06723b5319402e', 988270)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1nxw2JHRFxuB_FKmJ44WSKK4R_0t1-10X', 'IMG_0211.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0211-stall-exterior.jpg', 'https://drive.google.com/file/d/1nxw2JHRFxuB_FKmJ44WSKK4R_0t1-10X/view', 'unverified', false, 'Drive: Stallhuset/IMG_0211.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: same grass courtyard between stable and riding hall, framed further towards the stable wall', 'eff05f86cae2660cd42b6d7464d6be2c2cd51530d8a5786199547458e7e284af', 813701)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1jWPhQFBVbjvMxQlhoR_4su_PubZF0PMs', 'IMG_0212.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0212-stall-exterior.jpg', 'https://drive.google.com/file/d/1jWPhQFBVbjvMxQlhoR_4su_PubZF0PMs/view', 'unverified', false, 'Drive: Stallhuset/IMG_0212.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: entrance porch (förstukvist) at the stable''s club end, spiral stair beyond it on the left', '1635cc20f715147a500d4999a790b503055547546b126a45c24c8b33b2aac7b5', 796709)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1vcDj0LiqygAxLivo_b1uWgzZ95BAHuoC', 'IMG_0213.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0213-stall-exterior.jpg', 'https://drive.google.com/file/d/1vcDj0LiqygAxLivo_b1uWgzZ95BAHuoC/view', 'unverified', false, 'Drive: Stallhuset/IMG_0213.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: entrance porch (förstukvist), close-up of the slatted screen in front of the ochre door', 'b92939aece5ca233943a9f47c07195fc1cc5de2886e1bca29b58638ab82f62af', 763708)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1uwjIlMutMgJz4jhe8W1XgidS9yK9ghou', 'IMG_0214.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0214-stall-exterior.jpg', 'https://drive.google.com/file/d/1uwjIlMutMgJz4jhe8W1XgidS9yK9ghou/view', 'unverified', false, 'Drive: Stallhuset/IMG_0214.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: end of the entrance porch with the spiral stair just beyond it, and the view out to the gravel yard and a fenced paddock', 'a9fdbeabd93766fe608f704e07f85f5fb61a5d161ee2a23d9ff108dbdede713c', 765892)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1udpGYe0_YaqTkbELzKmwDDbr86_zDmRg', 'IMG_0216.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0216-stall-servicedel.jpg', 'https://drive.google.com/file/d/1udpGYe0_YaqTkbELzKmwDDbr86_zDmRg/view', 'unverified', false, 'Drive: Stallhuset/IMG_0216.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: hall inside the stable''s club end: body-protector rack, open doorway to a room with whiteboard and chairs, staff door', '643779ff6d0e8940b2b6283d318fb4b77296b4dd08fee6897a3f5e0e1a967e07', 408654)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ayKtbmJnngVVWJPwX24uL_OU8Vn6wJYn', 'IMG_0217.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1ayKtbmJnngVVWJPwX24uL_OU8Vn6wJYn/view', 'unverified', false, 'Drive: Stallhuset/IMG_0217.HEIC; byggnad: stall; status: DRIVE-ONLY; registreringsskylt i bild; visar: seating corner by an arched window next to the platform lift ("HISS") in the stable''s club end', 'a08e997171f419c9a4599d00489866ec1d943bba9d972b2c1e8dd16a5578a6c8', 1861165)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-16VQp7kqaCOzqqroeJJmdtRd5l7ojvOpP', 'IMG_0218.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0218-stall-servicedel.jpg', 'https://drive.google.com/file/d/16VQp7kqaCOzqqroeJJmdtRd5l7ojvOpP/view', 'unverified', false, 'Drive: Stallhuset/IMG_0218.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: same seating corner by the arched window and platform lift ("HISS")', '9743fd13f81fa2a1637c2609e38262dfc5fa63e8d72edb03452733e80a54af5a', 333739)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1EPr9MD9uPiot4oTiSjUntPtSjyi1jNGu', 'IMG_0219.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0219-stall-servicedel.jpg', 'https://drive.google.com/file/d/1EPr9MD9uPiot4oTiSjUntPtSjyi1jNGu/view', 'unverified', false, 'Drive: Stallhuset/IMG_0219.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: tack room (sadelkammare): bridle partition, grey door marked "Stall", shelving with green bins', 'e9bd22b5abbc2f5ef87d44228a507a95f33be7343711e022e2ed044847958985', 507962)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1md-ZOJHTli55kbg14GIM-8ONhs7CZ8fM', 'IMG_0220.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0220-stall-servicedel.jpg', 'https://drive.google.com/file/d/1md-ZOJHTli55kbg14GIM-8ONhs7CZ8fM/view', 'unverified', false, 'Drive: Stallhuset/IMG_0220.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: tack room (sadelkammare): same view towards the grey door marked "Stall"', '3dd3015771d92ea90c062f66c0dfd6712402e81d041861b457634a25e62b48af', 518344)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-139J1AG8bN_1F5xZCuZo3WUaoo0ixWyp4', 'IMG_0221.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0221-stall-servicedel.jpg', 'https://drive.google.com/file/d/139J1AG8bN_1F5xZCuZo3WUaoo0ixWyp4/view', 'unverified', false, 'Drive: Stallhuset/IMG_0221.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: tack room (sadelkammare): saddle wall and bridle partition', 'c141c24a2ca0baa04336db834bd225fbd9ede6bcba9e8d017688d7eeee005ecc', 428471)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1dOP86RfKB0ALBj0jy4m2Bpv-E9TKsf8Q', 'IMG_0222.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0222-stall-servicedel.jpg', 'https://drive.google.com/file/d/1dOP86RfKB0ALBj0jy4m2Bpv-E9TKsf8Q/view', 'unverified', false, 'Drive: Stallhuset/IMG_0222.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), loaded saddle brackets at left and far saddle wall', '6ff435c1987641e111a8070cd599f564cf5a97e7837140d9d0fdb1ed668ab640', 388533)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1wbLrOzAV6_khOy26cxMEyrBYUhfcebYW', 'IMG_0223.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0223-stall-servicedel.jpg', 'https://drive.google.com/file/d/1wbLrOzAV6_khOy26cxMEyrBYUhfcebYW/view', 'unverified', false, 'Drive: Stallhuset/IMG_0223.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), long saddle wall with cleaning stand', 'ab095fc7402a1b7dcf8ac77529dbd58ba76ef44bf03b90b2a5352121a1afae14', 456607)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1ReIm3-tLK5vC6XL2TH1dthGGOPq6juzF', 'IMG_0224.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0224-stall-servicedel.jpg', 'https://drive.google.com/file/d/1ReIm3-tLK5vC6XL2TH1dthGGOPq6juzF/view', 'unverified', false, 'Drive: Stallhuset/IMG_0224.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), corner with sink and cubby shelving', '658a0b22750bd206c8e5a22b2b92ce60f6fa5837c456b50be401d0d7df8751bb', 455984)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1OQrELVVmhv4zcJ3FUZjM6VxmF4cBDzJU', 'IMG_0225.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0225-stall-servicedel.jpg', 'https://drive.google.com/file/d/1OQrELVVmhv4zcJ3FUZjM6VxmF4cBDzJU/view', 'unverified', false, 'Drive: Stallhuset/IMG_0225.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), saddle wall next to the door to the stable', '043ff6cef30a4907a0f86cf5fd94087508a7a8d3e63c73610bfcf52e8f214330', 415314)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Lm1VccBrKo1aJbR0r1Kn1FNgx7yFqxat', 'IMG_0226.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0226-stall-servicedel.jpg', 'https://drive.google.com/file/d/1Lm1VccBrKo1aJbR0r1Kn1FNgx7yFqxat/view', 'unverified', false, 'Drive: Stallhuset/IMG_0226.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), bridle wall and end wall with barred interior window', 'a319da93f265db1fe766efc5d3130f013a9b3153f09e65f0b644fa52a368d283', 440225)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1FVm1zXvYxwv1-u3ZyUg9xuoE73uixcH6', 'IMG_0227.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0227-stall-servicedel.jpg', 'https://drive.google.com/file/d/1FVm1zXvYxwv1-u3ZyUg9xuoE73uixcH6/view', 'unverified', false, 'Drive: Stallhuset/IMG_0227.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: sadelkammare (tack room), door signed "Stall" and coat hooks', '1bf5352b1c22ddd352802baa982f6f0eec269026a7cba153be0d786a843e506b', 455090)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1EXkOcKwuYaeZ9QCrf9VKj0725EPo0L8Z', 'IMG_0228.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1EXkOcKwuYaeZ9QCrf9VKj0725EPo0L8Z/view', 'unverified', false, 'Drive: Stallhuset/IMG_0228.HEIC; byggnad: stall; status: DRIVE-ONLY; whiteboard med lägerschema i bild (suddigt, men samma tavla); visar: lektionssal / teorisal (lesson room), right wall and whiteboard end, seen from the back', '8801a7af1cc4e6a46afd7edd950afa4b2f3f2ab31df1bf621b1a44b6e6e10c2a', 2494961)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1cDeW1X1WpQtLrJg-EVGtpjQEHJxnLftr', 'IMG_0229.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1cDeW1X1WpQtLrJg-EVGtpjQEHJxnLftr/view', 'unverified', false, 'Drive: Stallhuset/IMG_0229.HEIC; byggnad: stall; status: DRIVE-ONLY; whiteboard med lägerschema i bild; visar: lektionssal (lesson room), right wall and whiteboard end wall', '942c398c0a7e1e4bd24bca12583c5b1c1753dc4b97d5294d48a204715a53978e', 1930657)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-12ihBdC-tHHWPl3KgMnkztY4meVKhLxo7', 'IMG_0230.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/12ihBdC-tHHWPl3KgMnkztY4meVKhLxo7/view', 'unverified', false, 'Drive: Stallhuset/IMG_0230.HEIC; byggnad: stall; status: DRIVE-ONLY; whiteboard med lägerschema: förnamn parade med hästnamn, läsbart; visar: lektionssal (lesson room), whiteboard end wall and window corner', '0b4a82c38f6f67e5224e9deb52f70dc5d14f72cf52097a23f6702a3d62493517', 2245896)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1DQzXBBenOa-CMziGV3N_IWX97DOn2bw_', 'IMG_0231.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0231-stall-servicedel.jpg', 'https://drive.google.com/file/d/1DQzXBBenOa-CMziGV3N_IWX97DOn2bw_/view', 'unverified', false, 'Drive: Stallhuset/IMG_0231.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: lektionssal (lesson room), window wall with hobby horses', '51bd1012d977780b6dfcde0bbe67fdcb21949e3f7098878a3caf8867c1c594ac', 361944)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1stc5dD0IM47YJc7VbmA3_eLg5hjZhjmx', 'IMG_0232.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0232-stall-servicedel.jpg', 'https://drive.google.com/file/d/1stc5dD0IM47YJc7VbmA3_eLg5hjZhjmx/view', 'unverified', false, 'Drive: Stallhuset/IMG_0232.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: lektionssal (lesson room), window wall with hobby horses (second exposure)', '1629e1ba126964c332dbf268fbc1d4e5404e6daa5dff9bb07875f3f2f65b3021', 376599)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1LoMwTWwxnuMMLOMg9qLD-EFyjIO1A1lg', 'IMG_0233.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0233-stall-servicedel.jpg', 'https://drive.google.com/file/d/1LoMwTWwxnuMMLOMg9qLD-EFyjIO1A1lg/view', 'unverified', false, 'Drive: Stallhuset/IMG_0233.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: lektionssal (lesson room), back corner with bookshelf and anatomy chart', 'b65ba9f2f4ba27574b8f625c5d4fcc3f862d21a5dd6f635ea90f9f482ebc02d5', 470924)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1FJ4EmecX5eiUgXQMdxiAM9E1nzxd9yev', 'IMG_0234.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0234-stall-servicedel.jpg', 'https://drive.google.com/file/d/1FJ4EmecX5eiUgXQMdxiAM9E1nzxd9yev/view', 'unverified', false, 'Drive: Stallhuset/IMG_0234.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: lektionssal (lesson room), back corner with bookshelf and anatomy chart (second exposure)', '3726657f3f67a3e19d86cb241096dc063b1f7948d35d64c472d3591d13d53848', 430336)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-131H5k9nSJcaqirQymwrKkXsO0nozw6Mb', 'IMG_0235.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0235-stall-servicedel.jpg', 'https://drive.google.com/file/d/131H5k9nSJcaqirQymwrKkXsO0nozw6Mb/view', 'unverified', false, 'Drive: Stallhuset/IMG_0235.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: lektionssal (lesson room), doorway to the service corridor', '65c35cd700f07ef074764bc64fa379ff03b32aa280f50a1bc061054e6fb7cac4', 408944)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Fa6faUWiZtb_amHeR2p_qofwbmJllMeW', 'IMG_0236.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0236-stall-servicedel.jpg', 'https://drive.google.com/file/d/1Fa6faUWiZtb_amHeR2p_qofwbmJllMeW/view', 'unverified', false, 'Drive: Stallhuset/IMG_0236.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: loan-equipment storage: body-protector (säkerhetsväst) wall rack [exact room REFERENCE GAP]', '8043cef164469f05cb195ad43a4730ed26773a33fa33bcac02f4bf1d4ddc2838', 403116)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-15tKXefgzPC2JRDdEt1aVD4P5tQVuRC4r', 'IMG_0237.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0237-stall-servicedel.jpg', 'https://drive.google.com/file/d/15tKXefgzPC2JRDdEt1aVD4P5tQVuRC4r/view', 'unverified', false, 'Drive: Stallhuset/IMG_0237.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: loan-equipment storage: riding-boot cabinet [exact room REFERENCE GAP]', '6f49fa815c5342a89f5785f9a970b15198fdf9d85b388d28be04206d8728388f', 389522)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1P8YF_veojJxNuqWbr9vNC5xP-zLr3qY6', 'IMG_0238.MOV — stall-servicedel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1P8YF_veojJxNuqWbr9vNC5xP-zLr3qY6/view', 'unverified', false, 'Drive: Stallhuset/IMG_0238.MOV; byggnad: stall; status: DRIVE-ONLY; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'a4c3238ddcc1d857055177376354ac6cfc6c2d1f62aca1c40a390e014b41a935', 18461218)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1PrRzHEXhI73A8dO2mmwFw2gA5t076yRv', 'IMG_0239.MOV — stall-servicedel', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1PrRzHEXhI73A8dO2mmwFw2gA5t076yRv/view', 'unverified', false, 'Drive: Stallhuset/IMG_0239.MOV; byggnad: stall; status: DRIVE-ONLY; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', 'f91b576f1d33683bb58f0dd38d835750dda5d3e62933ee69a7dd01d315940ee1', 32947865)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1JKP0BViArAF5EqCVv_Mza456yKMm6QP2', 'IMG_0240.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0240-stall-servicedel.jpg', 'https://drive.google.com/file/d/1JKP0BViArAF5EqCVv_Mza456yKMm6QP2/view', 'unverified', false, 'Drive: Stallhuset/IMG_0240.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: uppehållsrummet (lounge) in the stable''s club end: window wall with practice horses and table group, grey steel door at right', '9d9769121722c1bb43c66afa48d5c90a9edbf2c2c0a15d28cad86332e3566058', 349261)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1Bx5ROhp6qqj3DY9EZ4SFAIIvX2My1DWc', 'IMG_0241.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0241-stall-servicedel.jpg', 'https://drive.google.com/file/d/1Bx5ROhp6qqj3DY9EZ4SFAIIvX2My1DWc/view', 'unverified', false, 'Drive: Stallhuset/IMG_0241.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: uppehållsrummet (lounge) in the stable''s club end: whole window wall with ceiling, exit-signed steel door at right', '3152c0e2758a473fcfc6b6063060e9e515efff6cd75e756df6e8dbdb2f3b46b4', 380217)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-11zhxSeMjyn6dxagt4ag7qzneu0RvWhsP', 'IMG_0242.HEIC — stall-servicedel', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0242-stall-servicedel.jpg', 'https://drive.google.com/file/d/11zhxSeMjyn6dxagt4ag7qzneu0RvWhsP/view', 'unverified', false, 'Drive: Stallhuset/IMG_0242.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: service part: passage beside the spolspilta (same passage as repo stall-inne-07), looking to the exit door', '73ec66a3cd2d20f316587d5d4d499a21a7481e9eb0edf656ac49b621bbb366ca', 330264)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1FeK7AOi8F3CpK59MPTyERg7jzNItiCu4', 'IMG_0243.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1FeK7AOi8F3CpK59MPTyERg7jzNItiCu4/view', 'unverified', false, 'Drive: Stallhuset/IMG_0243.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: service part: passage toward the exit door, wall clock and grey doors on the right, white room block on the left', '86cc7a721849cf36ec327e9d480164cf81de3ff468c7f64968c9d26ae2745b07', 3070751)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1qnwsmBK-F5rp2GIznSZeO399KtoIEsO0', 'IMG_0244.HEIC — stall-servicedel', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1qnwsmBK-F5rp2GIznSZeO399KtoIEsO0/view', 'unverified', false, 'Drive: Stallhuset/IMG_0244.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: service part: last metres of the passage to the exit door; grey double door labelled "Foder" on the right', 'f0fcd75ba49d1cfd9f15b68f1bfd355505548adadf7b35532d445ecc8adb76a4', 3097927)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XkQyB8dWD8RUwLdmoQTEFIfAnaQaIVy1', 'IMG_0245.HEIC — stall-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1XkQyB8dWD8RUwLdmoQTEFIfAnaQaIVy1/view', 'unverified', false, 'Drive: Stallhuset/IMG_0245.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: threshold of the service-passage exit door looking out: concrete apron, roofed container bay on the left, outdoor arena beyond', 'd1d00b31e014f717727a7a9cb29453fd240c5f39a691ef064c58074b85596f7a', 2346223)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1U4lOvE31mlu2N0JvqtW7HyOQhzKvWJCz', 'IMG_0246.HEIC — stall-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1U4lOvE31mlu2N0JvqtW7HyOQhzKvWJCz/view', 'unverified', false, 'Drive: Stallhuset/IMG_0246.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: roofed container bay beside the service exit door: gate, black container and the bay''s outer corner with downpipe', '3a69f982d2177f2887244d9b788af9a40455b382abcc22ef971c814cb1011a34', 2613529)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1wZ4akkqF_5TCZ78A8aOTOESmIP0qJNdu', 'IMG_0247.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0247-stall-exterior.jpg', 'https://drive.google.com/file/d/1wZ4akkqF_5TCZ78A8aOTOESmIP0qJNdu/view', 'unverified', false, 'Drive: Stallhuset/IMG_0247.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: inside the roofed container bay: inclined conveyor discharging into a black container (manure handling, function inferred)', '663edf33bc39a84e4e85f5e0ebe44a026b76579d5eb7d980010b5092428208b6', 391992)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1JDXRlzs2EEoLV3vXhgtAnC84gwUegJWQ', 'IMG_0248.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0248-stall-exterior.jpg', 'https://drive.google.com/file/d/1JDXRlzs2EEoLV3vXhgtAnC84gwUegJWQ/view', 'unverified', false, 'Drive: Stallhuset/IMG_0248.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: roofed container bay seen square-on through its galvanised gate: conveyor, container end, plank partition', 'e60be78760c8b623ba1588e98800a6d4b722420464774f37ec94bd3090e2ff62', 407871)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-13_oF6b3Cj-DfVY-vL1uEUtL1WtxnTGP5', 'IMG_0284.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0284-stall-exterior.jpg', 'https://drive.google.com/file/d/13_oF6b3Cj-DfVY-vL1uEUtL1WtxnTGP5/view', 'unverified', false, 'Drive: Stallhuset/IMG_0284.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable club gable: galvanised spiral stair up to the first-floor door, from the stair foot', '4208a591c2388f5012248b22e2def1f83f6eb053e53c8a84c46ea37f63fc29f3', 559730)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1hShq_Kqepp64d2xCVY1oHMZuml7hrWlb', 'IMG_0288.HEIC — stall-exterior', 'photo', 'google_drive', null, 'https://drive.google.com/file/d/1hShq_Kqepp64d2xCVY1oHMZuml7hrWlb/view', 'unverified', false, 'Drive: Stallhuset/IMG_0288.HEIC; byggnad: stall; status: DRIVE-ONLY; person i bild; visar: stable long side facing the fenced paddocks (east side in the repo''s site model, not confirmed in the photo): view along the wall to a concrete pad, bedding pallets and a lower wing', '9b7e80d53f2d6423bf3b190d0d6daa7c9cdac1e490d4f0918ac97eb89406e7ab', 3054112)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1gcHtOAMqZwtJ7JuJrwFc13PBPIzznyhS', 'IMG_0289.MOV — stall-exterior', 'video', 'google_drive', null, 'https://drive.google.com/file/d/1gcHtOAMqZwtJ7JuJrwFc13PBPIzznyhS/view', 'unverified', false, 'Drive: Stallhuset/IMG_0289.MOV; byggnad: stall; status: DRIVE-ONLY; personer i bild; originalfilen inte migrerad (storlek); klubbens samtycke finns sedan 2026-11-28 — personer i bild avgör användningen', '2afeb64def8d0d932157d8d134ac7bd71d6b836d790850f7c39168cc271f06e5', 28055440)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XBLRm7TRw5uO1848oTgoc1kUMR9rmL9t', 'IMG_0290.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0290-stall-exterior.jpg', 'https://drive.google.com/file/d/1XBLRm7TRw5uO1848oTgoc1kUMR9rmL9t/view', 'unverified', false, 'Drive: Stallhuset/IMG_0290.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side (paddock side): roof with ventilation cowls and eave window strip, behind pallets of bedding bales', '64c682994cc517e32ac98e2a5501c069d5e60283e827d01949cfa5b2d108740c', 712565)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1P1_YK34M4b98--OFbB55Df0SZ2m3BP4o', 'IMG_0291.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0291-stall-exterior.jpg', 'https://drive.google.com/file/d/1P1_YK34M4b98--OFbB55Df0SZ2m3BP4o/view', 'unverified', false, 'Drive: Stallhuset/IMG_0291.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: inside corner where a lower gabled wing meets the stable''s paddock-side long wall; implements, fence posts and pallets stored there', 'e6440f0630ef538de851725833ec77320dade15fddece85c6b2039eb21adc401', 748385)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1swzHEFHt-Z9f2iQFK2sz9xHCxFH8dvo-', 'IMG_0292.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0292-stall-exterior.jpg', 'https://drive.google.com/file/d/1swzHEFHt-Z9f2iQFK2sz9xHCxFH8dvo-/view', 'unverified', false, 'Drive: Stallhuset/IMG_0292.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: inside corner between the lower wing and the stable''s paddock-side long wall (second exposure, slightly closer)', 'f0fbedc337012326a5e36e78c6fea4b75c0da968cdfbb632c9580924d07878d5', 695875)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-18PXMUN1HxBQBcOdizvY1UnKdttrgubHV', 'IMG_0293.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0293-stall-exterior.jpg', 'https://drive.google.com/file/d/18PXMUN1HxBQBcOdizvY1UnKdttrgubHV/view', 'unverified', false, 'Drive: Stallhuset/IMG_0293.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: gable end of the lower wing with tall grey double door; track and paddock fence with tape gate', '7734bfc86ed5d8b1957738ed7240516c52e2211bea0f8d35cc5a68d8347636c0', 892205)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-10XFgkZ-uAFtZJW_gom_vpzFCnFz5RakC', 'IMG_0294.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0294-stall-exterior.jpg', 'https://drive.google.com/file/d/10XFgkZ-uAFtZJW_gom_vpzFCnFz5RakC/view', 'unverified', false, 'Drive: Stallhuset/IMG_0294.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: outer corner of the lower wing: gable end with tall grey double door, closer view; track to the paddocks', '7791476be3c8c5418b5bdf1fa750aaea11316b8588a3642f81e60694c01b05ab', 823049)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1m4hk98yB6VyUXdgi3F5WpMf4NoPK6ZuW', 'IMG_0295.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0295-stall-exterior.jpg', 'https://drive.google.com/file/d/1m4hk98yB6VyUXdgi3F5WpMf4NoPK6ZuW/view', 'unverified', false, 'Drive: Stallhuset/IMG_0295.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side toward the paddocks (east long side per SITEPLAN [antagande]), service yard in the inner corner beside the gabled port extension', '30ecbe9ef17b3f0d618866228e09e3a18c072ec4743b48cf31b42dbdd761efe5', 648201)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1gh-nKUjc2cvhtvDUs7E-5uSTC0yLJzo-', 'IMG_0296.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0296-stall-exterior.jpg', 'https://drive.google.com/file/d/1gh-nKUjc2cvhtvDUs7E-5uSTC0yLJzo-/view', 'unverified', false, 'Drive: Stallhuset/IMG_0296.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side toward the paddocks (east long side per SITEPLAN [antagande]), inner corner between long wall and port extension', '97b3bbd04d8a086b76469cfcb570a6c081502b52649a6acaac2bb2a7a1263f38', 644838)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1XyzjdPrVc5yEidxwu4-OxCR751keF1j-', 'IMG_0297.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0297-stall-exterior.jpg', 'https://drive.google.com/file/d/1XyzjdPrVc5yEidxwu4-OxCR751keF1j-/view', 'unverified', false, 'Drive: Stallhuset/IMG_0297.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side toward the paddocks (east long side per SITEPLAN [antagande]), side wall of the gabled port extension', '223a8aa4db898f33bb897fc3884bc546bace70d2b5c29c018e88f29c4fd01747', 548587)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-1N3niPrl2tRXFXoySG56yNF8_2opuYXrZ', 'IMG_0298.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0298-stall-exterior.jpg', 'https://drive.google.com/file/d/1N3niPrl2tRXFXoySG56yNF8_2opuYXrZ/view', 'unverified', false, 'Drive: Stallhuset/IMG_0298.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side toward the paddocks (east long side per SITEPLAN [antagande]): gabled port extension with grey double doors, seen from the track between the paddocks', '5077fac0e8d2edc085f7f6c3e7b440200a80e38e1405df3832fda1eb89e5ba16', 752729)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

insert into public.reference_assets (id, title, asset_type, source_origin, github_path, external_source_url, verification_status, required_for_build, notes, sha256, bytes) values
  ('drive-14bGhGut8Drnn-rsUn6pg4z_kdQVD2qJf', 'IMG_0299.HEIC — stall-exterior', 'photo', 'google_drive', 'references/buildings/stall/drive-2026-11-26/IMG_0299-stall-exterior.jpg', 'https://drive.google.com/file/d/14bGhGut8Drnn-rsUn6pg4z_kdQVD2qJf/view', 'unverified', false, 'Drive: Stallhuset/IMG_0299.HEIC; byggnad: stall; status: IN_REPO; JPEG 1536x2048, kvalitet 85, EXIF/XMP borttagna; visar: stable long side toward the paddocks (east long side per SITEPLAN [antagande]): long wall right of the port extension, paddock fence in front', 'f8f54d1823409ad26d3504937e85bbfe514b66e68151ed409e8e00d9dd167f4f', 732560)
  on conflict (id) do update set github_path = excluded.github_path, notes = excluded.notes,
    sha256 = excluded.sha256, bytes = excluded.bytes, updated_at = now();

commit;
