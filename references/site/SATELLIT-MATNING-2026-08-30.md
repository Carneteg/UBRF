# UBRF — satellitbild med Google Maps-mätning (2026-08-30)

Status: **DIRECT PRODUCT OWNER REFERENCE**

Source: Google Maps satellite screenshot supplied directly by Product Owner during Gate F01 fidelity work.

## Correct interpretation

This source is a **site-level satellite image with a Google Maps measurement polyline/polygon drawn around/through the facility area**. It is **not** a dimensioned architectural plan of the riding hall.

Visible labels such as approximately `100.00 m`, `300.00 m` and `338.54 m` belong to the Google Maps measurement path/tool. They must **not** be interpreted as riding-hall wall lengths, arena dimensions, 5 m service zones, entrance depth, or building-footprint dimensions unless a measurement endpoint is explicitly aligned to the feature being measured and that relationship is verified.

## What this source safely supports

- high-value **site topology and relative placement** of the main UBRF building volumes,
- relative orientation of riding hall and stable,
- central roofed connector between the parallel main volumes,
- the two open yard areas separated by that connector,
- surrounding roads, gravel/parking surfaces, fields and nearby outdoor areas,
- site-scale comparison of training-area placement when combined with `Omnejd` references.

## What this source does NOT safely lock

- riding arena `20 × 60 m` (that fact must come from a separate verified source),
- riding-hall footprint such as `25 × 75 m`,
- exact stable footprint,
- exact width/depth of the connector,
- any `5 m` architectural/service-zone interpretation,
- exact building dimensions inferred from screen pixels without a correctly anchored scale measurement.

## Required use

Use this image primarily to correct **SITEPLAN / site layout / outdoor training-area placement and building relationships**. Do not derive architectural dimensions from the measurement labels unless the measured segment is unambiguously tied to that architectural element.

Any prior document or audit that treated this screenshot as a dimensioned riding-hall plan is **SUPERSEDED / INVALIDATED**.
