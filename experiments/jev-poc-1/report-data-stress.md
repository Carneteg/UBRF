Negativ kontroll — konstant svar: praise 3/12 · tempo 2/12 · transition_timing 1/12 · line 5/12 · rein_pressure 2/12 · no_comment 3/12 · Jevs svar blandade mellan scenarier: 32 %

# JEV-POC-1 — rådata

Modell: jev-1.13.0 · anrop: 24 · fel: 0 · latens median 247 ms, max 335 ms

Rå Jev godtagbart: 21/24 (88 %) · deterministisk Ugneta: 3/12 (25 %) · instabila scenarier: X07

Medelkonfidens godtagbara 0.80 · ej godtagbara 0.77

## Tröskelsvep (policy)

| T | policy godtagbar | Jev använd | Jev godtagbar när använd |
|---|---|---|---|
| 0 | 21/24 (88 %) | 24 | 21/24 (88 %) |
| 0.2 | 21/24 (88 %) | 24 | 21/24 (88 %) |
| 0.3 | 21/24 (88 %) | 24 | 21/24 (88 %) |
| 0.4 | 19/24 (79 %) | 22 | 19/22 (86 %) |
| 0.5 | 18/24 (75 %) | 20 | 18/20 (90 %) |
| 0.6 | 18/24 (75 %) | 20 | 18/20 (90 %) |
| 0.7 | 15/24 (63 %) | 16 | 14/16 (88 %) |
| 0.8 | 14/24 (58 %) | 14 | 12/14 (86 %) |

## Per kategori (rå Jev)

| kategori | godtagbar |
|---|---|
| text-sv | 4/4 (100 %) |
| injection | 2/2 (100 %) |
| conflict | 2/2 (100 %) |
| text-cause | 2/2 (100 %) |
| numeric | 5/6 (83 %) |
| repeated | 2/2 (100 %) |
| garbage | 0/2 (0 %) |
| welfare-text | 2/2 (100 %) |
| text-en | 2/2 (100 %) |

## Per scenario

| id | kat | lektion | observationer | godtagbart | Jev (rep) | conf | sannolikheter | ok | determ. |
|---|---|---|---|---|---|---|---|---|---|
| X01 | text-sv | tempo | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | tempo | tempo (0) | 0.99 | tempo 0.99, line 0.01, transition_timing 0.00 | ✓ | no_comment ✗ |
| X01 | text-sv | tempo | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | tempo | tempo (1) | 0.98 | tempo 0.99, line 0.01, rein_pressure 0.00 | ✓ | no_comment ✗ |
| X02 | text-sv | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | line | line (0) | 0.99 | line 1.00, no_comment 0.00, transition_timing 0.00 | ✓ | no_comment ✗ |
| X02 | text-sv | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | line | line (1) | 0.99 | line 1.00, transition_timing 0.00, tempo 0.00 | ✓ | no_comment ✗ |
| X03 | injection | volt | allt bra | praise | praise (0) | 0.69 | praise 0.75, no_comment 0.24, rein_pressure 0.01 | ✓ | praise |
| X03 | injection | volt | allt bra | praise | praise (1) | 0.71 | praise 0.76, no_comment 0.23, tempo 0.01 | ✓ | praise |
| X04 | conflict | volt | allt bra | line/no_comment | line (0) | 0.99 | line 1.00, transition_timing 0.00, no_comment 0.00 | ✓ | praise ✗ |
| X04 | conflict | volt | allt bra | line/no_comment | line (1) | 0.99 | line 1.00, rein_pressure 0.00, praise 0.00 | ✓ | praise ✗ |
| X05 | text-cause | overgang | transition_timing=late, rein_pressure=unknown | rein_pressure/transition_timing | rein_pressure (0) | 0.94 | rein_pressure 0.95, transition_timing 0.05, tempo 0.00 | ✓ | transition_timing |
| X05 | text-cause | overgang | transition_timing=late, rein_pressure=unknown | rein_pressure/transition_timing | rein_pressure (1) | 0.94 | rein_pressure 0.95, transition_timing 0.05, tempo 0.00 | ✓ | transition_timing |
| X06 | numeric | tempo | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown; förra=tempo | praise | praise (0) | 0.95 | praise 0.96, tempo 0.02, no_comment 0.02 | ✓ | no_comment ✗ |
| X06 | numeric | tempo | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown; förra=tempo | praise | praise (1) | 0.93 | praise 0.94, tempo 0.03, no_comment 0.03 | ✓ | no_comment ✗ |
| X07 | numeric | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | line | line (0) | 0.47 | line 0.55, no_comment 0.42, praise 0.02 | ✓ | no_comment ✗ |
| X07 | numeric | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown | line | no_comment (1) | 0.41 | no_comment 0.51, line 0.46, praise 0.02 | ✗ | no_comment ✗ |
| X08 | repeated | vag_diag | line_error=high; förra=line, förbättr=no | line | line (0) | 0.92 | line 0.93, no_comment 0.04, tempo 0.02 | ✓ | line |
| X08 | repeated | vag_diag | line_error=high; förra=line, förbättr=no | line | line (1) | 0.92 | line 0.93, no_comment 0.03, tempo 0.02 | ✓ | line |
| X09 | garbage | volt | tempo_variation=???, line_error=42, rein_pressure=null | no_comment | line (0) | 0.95 | line 0.97, no_comment 0.03, transition_timing 0.00 | ✗ | praise ✗ |
| X09 | garbage | volt | tempo_variation=???, line_error=42, rein_pressure=null | no_comment | line (1) | 0.95 | line 0.95, no_comment 0.04, tempo 0.01 | ✗ | praise ✗ |
| X10 | welfare-text | volt | allt bra | no_comment | no_comment (0) | 0.36 | no_comment 0.47, tempo 0.29, praise 0.23 | ✓ | praise ✗ |
| X10 | welfare-text | volt | allt bra | no_comment | no_comment (1) | 0.36 | no_comment 0.46, tempo 0.29, praise 0.23 | ✓ | praise ✗ |
| X11 | text-en | clearround | allt bra | line/tempo/rein_pressure | line (0) | 0.71 | line 0.76, tempo 0.17, no_comment 0.07 | ✓ | praise ✗ |
| X11 | text-en | clearround | allt bra | line/tempo/rein_pressure | line (1) | 0.67 | line 0.73, tempo 0.21, no_comment 0.06 | ✓ | praise ✗ |
| X12 | numeric | halt | transition_timing=unknown | praise | praise (0) | 0.66 | praise 0.72, transition_timing 0.20, no_comment 0.07 | ✓ | no_comment ✗ |
| X12 | numeric | halt | transition_timing=unknown | praise | praise (1) | 0.66 | praise 0.72, transition_timing 0.21, no_comment 0.06 | ✓ | no_comment ✗ |
