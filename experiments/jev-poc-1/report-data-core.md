Negativ kontroll — konstant svar: praise 11/30 · tempo 10/30 · transition_timing 6/30 · line 7/30 · rein_pressure 4/30 · no_comment 7/30 · Jevs svar blandade mellan scenarier: 27 %

# JEV-POC-1 — rådata

Modell: jev-1.13.0 · anrop: 60 · fel: 0 · latens median 241 ms, max 370 ms

Rå Jev godtagbart: 60/60 (100 %) · deterministisk Ugneta: 29/30 (97 %) · instabila scenarier: S15

Medelkonfidens godtagbara 0.88 · ej godtagbara –

## Tröskelsvep (policy)

| T | policy godtagbar | Jev använd | Jev godtagbar när använd |
|---|---|---|---|
| 0 | 60/60 (100 %) | 52 | 52/52 (100 %) |
| 0.2 | 60/60 (100 %) | 52 | 52/52 (100 %) |
| 0.3 | 60/60 (100 %) | 52 | 52/52 (100 %) |
| 0.4 | 60/60 (100 %) | 50 | 50/50 (100 %) |
| 0.5 | 60/60 (100 %) | 49 | 49/49 (100 %) |
| 0.6 | 60/60 (100 %) | 45 | 45/45 (100 %) |
| 0.7 | 60/60 (100 %) | 42 | 42/42 (100 %) |
| 0.8 | 60/60 (100 %) | 40 | 40/40 (100 %) |

## Per kategori (rå Jev)

| kategori | godtagbar |
|---|---|
| good | 6/6 (100 %) |
| tempo | 6/6 (100 %) |
| line | 6/6 (100 %) |
| transition | 6/6 (100 %) |
| multi | 6/6 (100 %) |
| improved | 6/6 (100 %) |
| repeated | 4/4 (100 %) |
| ambiguous | 6/6 (100 %) |
| insufficient | 6/6 (100 %) |
| silence | 6/6 (100 %) |
| rein | 2/2 (100 %) |

## Per scenario

| id | kat | lektion | observationer | godtagbart | Jev (rep) | conf | sannolikheter | ok | determ. |
|---|---|---|---|---|---|---|---|---|---|
| S01 | good | volt | allt bra | praise | praise (0) | 0.98 | praise 0.99, no_comment 0.01, rein_pressure 0.00 | ✓ | praise |
| S01 | good | volt | allt bra | praise | praise (1) | 0.97 | praise 0.98, no_comment 0.01, tempo 0.01 | ✓ | praise |
| S02 | good | halt | allt bra | praise | praise (0) | 0.99 | praise 0.99, no_comment 0.01, transition_timing 0.00 | ✓ | praise |
| S02 | good | halt | allt bra | praise | praise (1) | 0.99 | praise 0.99, no_comment 0.01, transition_timing 0.00 | ✓ | praise |
| S03 | good | clearround | allt bra | praise | praise (0) | 0.99 | praise 0.99, no_comment 0.01, line 0.00 | ✓ | praise |
| S03 | good | clearround | allt bra | praise | praise (1) | 0.99 | praise 1.00, transition_timing 0.00, line 0.00 | ✓ | praise |
| S04 | tempo | tempo | tempo_variation=high | tempo | tempo (0) | 1.00 | tempo 1.00, transition_timing 0.00, line 0.00 | ✓ | tempo |
| S04 | tempo | tempo | tempo_variation=high | tempo | tempo (1) | 1.00 | tempo 1.00, no_comment 0.00, transition_timing 0.00 | ✓ | tempo |
| S05 | tempo | volt | tempo_variation=high | tempo | tempo (0) | 0.99 | tempo 0.99, praise 0.01, line 0.00 | ✓ | tempo |
| S05 | tempo | volt | tempo_variation=high | tempo | tempo (1) | 0.99 | tempo 0.99, praise 0.01, no_comment 0.00 | ✓ | tempo |
| S06 | tempo | tempo | tempo_variation=medium | tempo/praise | tempo (0) | 0.49 | tempo 0.58, praise 0.42, transition_timing 0.00 | ✓ | tempo |
| S06 | tempo | tempo | tempo_variation=medium | tempo/praise | tempo (1) | 0.53 | tempo 0.61, praise 0.38, no_comment 0.01 | ✓ | tempo |
| S07 | line | volt | line_error=high | line | line (0) | 0.99 | line 1.00, no_comment 0.00, transition_timing 0.00 | ✓ | line |
| S07 | line | volt | line_error=high | line | line (1) | 0.99 | line 1.00, no_comment 0.00, tempo 0.00 | ✓ | line |
| S08 | line | vag_diag | line_error=high | line | line (0) | 1.00 | line 1.00, transition_timing 0.00, rein_pressure 0.00 | ✓ | line |
| S08 | line | vag_diag | line_error=high | line | line (1) | 1.00 | line 1.00, no_comment 0.00, transition_timing 0.00 | ✓ | line |
| S09 | line | markbom | line_error=high | line | line (0) | 1.00 | line 1.00, praise 0.00, transition_timing 0.00 | ✓ | line |
| S09 | line | markbom | line_error=high | line | line (1) | 1.00 | line 1.00, transition_timing 0.00, praise 0.00 | ✓ | line |
| S10 | transition | overgang | transition_timing=late | transition_timing | transition_timing (0) | 1.00 | transition_timing 1.00, tempo 0.00, praise 0.00 | ✓ | transition_timing |
| S10 | transition | overgang | transition_timing=late | transition_timing | transition_timing (1) | 1.00 | transition_timing 1.00, tempo 0.00, line 0.00 | ✓ | transition_timing |
| S11 | transition | halt | transition_timing=early | transition_timing | transition_timing (0) | 0.99 | transition_timing 0.99, praise 0.01, tempo 0.00 | ✓ | transition_timing |
| S11 | transition | halt | transition_timing=early | transition_timing | transition_timing (1) | 0.98 | transition_timing 0.99, praise 0.01, rein_pressure 0.00 | ✓ | transition_timing |
| S12 | transition | galopp | transition_timing=late | transition_timing | transition_timing (0) | 1.00 | transition_timing 1.00, tempo 0.00, line 0.00 | ✓ | transition_timing |
| S12 | transition | galopp | transition_timing=late | transition_timing | transition_timing (1) | 1.00 | transition_timing 1.00, no_comment 0.00, rein_pressure 0.00 | ✓ | transition_timing |
| S13 | multi | volt | tempo_variation=high, line_error=high | tempo/line | tempo (0) | 0.53 | tempo 0.62, line 0.38, praise 0.00 | ✓ | line |
| S13 | multi | volt | tempo_variation=high, line_error=high | tempo/line | tempo (1) | 0.51 | tempo 0.60, line 0.40, transition_timing 0.00 | ✓ | line |
| S14 | multi | overgang | transition_timing=late, rein_pressure=heavy | transition_timing/rein_pressure | transition_timing (0) | 0.92 | transition_timing 0.94, rein_pressure 0.06, praise 0.00 | ✓ | transition_timing |
| S14 | multi | overgang | transition_timing=late, rein_pressure=heavy | transition_timing/rein_pressure | transition_timing (1) | 0.93 | transition_timing 0.94, rein_pressure 0.06, praise 0.00 | ✓ | transition_timing |
| S15 | multi | serpentin | tempo_variation=high, line_error=high, transition_timing=late, rein_pressure=heavy | tempo/line/rein_pressure | rein_pressure (0) | 0.35 | rein_pressure 0.46, line 0.33, tempo 0.11 | ✓ | line |
| S15 | multi | serpentin | tempo_variation=high, line_error=high, transition_timing=late, rein_pressure=heavy | tempo/line/rein_pressure | line (1) | 0.30 | line 0.43, rein_pressure 0.37, transition_timing 0.11 | ✓ | line |
| S16 | improved | tempo | allt bra; förra=tempo, förbättr=yes | praise | praise (0) | 0.99 | praise 0.98, no_comment 0.01, tempo 0.01 | ✓ | praise |
| S16 | improved | tempo | allt bra; förra=tempo, förbättr=yes | praise | praise (1) | 0.99 | praise 0.99, no_comment 0.01, transition_timing 0.00 | ✓ | praise |
| S17 | improved | tempo | tempo_variation=medium; förra=tempo, förbättr=yes | praise/tempo | praise (0) | 0.84 | praise 0.87, tempo 0.12, no_comment 0.01 | ✓ | praise |
| S17 | improved | tempo | tempo_variation=medium; förra=tempo, förbättr=yes | praise/tempo | praise (1) | 0.85 | praise 0.87, tempo 0.12, no_comment 0.01 | ✓ | praise |
| S18 | improved | volt | tempo_variation=high; förra=line, förbättr=yes (line) | tempo/praise | tempo (0) | 0.91 | tempo 0.93, praise 0.07, transition_timing 0.00 | ✓ | tempo |
| S18 | improved | volt | tempo_variation=high; förra=line, förbättr=yes (line) | tempo/praise | tempo (1) | 0.90 | tempo 0.92, praise 0.08, transition_timing 0.00 | ✓ | tempo |
| S19 | repeated | volt | line_error=high; förra=line, förbättr=no | line | line (0) | 0.60 | line 0.67, tempo 0.26, no_comment 0.05 | ✓ | line |
| S19 | repeated | volt | line_error=high; förra=line, förbättr=no | line | line (1) | 0.69 | line 0.74, tempo 0.19, no_comment 0.05 | ✓ | line |
| S20 | repeated | tempo | tempo_variation=high, rein_pressure=heavy; förra=tempo, förbättr=no | rein_pressure/tempo | rein_pressure (0) | 0.87 | rein_pressure 0.89, tempo 0.10, no_comment 0.01 | ✓ | tempo |
| S20 | repeated | tempo | tempo_variation=high, rein_pressure=heavy; förra=tempo, förbättr=no | rein_pressure/tempo | rein_pressure (1) | 0.81 | rein_pressure 0.84, tempo 0.15, no_comment 0.01 | ✓ | tempo |
| S21 | ambiguous | volt | tempo_variation=medium, line_error=medium | tempo/line/praise | line (0) | 0.59 | line 0.65, tempo 0.33, no_comment 0.01 | ✓ | line |
| S21 | ambiguous | volt | tempo_variation=medium, line_error=medium | tempo/line/praise | line (1) | 0.70 | line 0.74, tempo 0.24, no_comment 0.01 | ✓ | line |
| S22 | ambiguous | overgang | transition_timing=borderline_late | praise/transition_timing | transition_timing (0) | 0.99 | transition_timing 0.99, praise 0.01, tempo 0.00 | ✓ | transition_timing |
| S22 | ambiguous | overgang | transition_timing=borderline_late | praise/transition_timing | transition_timing (1) | 0.99 | transition_timing 0.99, praise 0.01, line 0.00 | ✓ | transition_timing |
| S23 | ambiguous | tempo | allt bra | tempo/transition_timing/no_comment | tempo (0) | 0.99 | tempo 0.99, praise 0.01, no_comment 0.00 | ✓ | praise ✗ |
| S23 | ambiguous | tempo | allt bra | tempo/transition_timing/no_comment | tempo (1) | 0.99 | tempo 1.00, rein_pressure 0.00, transition_timing 0.00 | ✓ | praise ✗ |
| S24 | insufficient | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown; timeout | no_comment | no_comment (0) | 1.00 | no_comment 1.00, line 0.00, rein_pressure 0.00 | ✓ | no_comment |
| S24 | insufficient | volt | tempo_variation=unknown, line_error=unknown, rein_pressure=unknown; timeout | no_comment | no_comment (1) | 1.00 | no_comment 1.00, rein_pressure 0.00, transition_timing 0.00 | ✓ | no_comment |
| S25 | insufficient | halt | tempo_variation=unknown, line_error=unknown, transition_timing=unknown, rein_pressure=unknown | no_comment | no_comment (0) | 0.94 | no_comment 0.95, praise 0.03, transition_timing 0.02 | ✓ | no_comment |
| S25 | insufficient | halt | tempo_variation=unknown, line_error=unknown, transition_timing=unknown, rein_pressure=unknown | no_comment | no_comment (1) | 0.96 | no_comment 0.97, praise 0.02, transition_timing 0.01 | ✓ | no_comment |
| S26 | insufficient | vag_mitt | line_error=unknown, rein_pressure=unknown | no_comment/praise | no_comment (0) | 0.70 | no_comment 0.74, praise 0.17, line 0.05 | ✓ | no_comment |
| S26 | insufficient | vag_mitt | line_error=unknown, rein_pressure=unknown | no_comment/praise | no_comment (1) | 0.65 | no_comment 0.72, praise 0.18, line 0.05 | ✓ | no_comment |
| S27 | silence | volt | tempo_variation=medium; in_progress, förra=tempo | no_comment | no_comment (0) | 0.99 | no_comment 0.99, tempo 0.01, rein_pressure 0.00 | ✓ | no_comment |
| S27 | silence | volt | tempo_variation=medium; in_progress, förra=tempo | no_comment | no_comment (1) | 0.99 | no_comment 1.00, transition_timing 0.00, rein_pressure 0.00 | ✓ | no_comment |
| S28 | silence | free_training | tempo_variation=unknown, line_error=unknown; no_lesson | no_comment/praise | no_comment (0) | 0.95 | no_comment 0.96, praise 0.03, rein_pressure 0.01 | ✓ | no_comment |
| S28 | silence | free_training | tempo_variation=unknown, line_error=unknown; no_lesson | no_comment/praise | no_comment (1) | 0.96 | no_comment 0.97, praise 0.03, line 0.00 | ✓ | no_comment |
| S29 | silence | volt | tempo_variation=high, line_error=high; welfare_stop | no_comment | no_comment (0) | 0.81 | no_comment 0.84, tempo 0.14, line 0.02 | ✓ | no_comment |
| S29 | silence | volt | tempo_variation=high, line_error=high; welfare_stop | no_comment | no_comment (1) | 0.81 | no_comment 0.84, tempo 0.14, line 0.02 | ✓ | no_comment |
| S30 | rein | halt | rein_pressure=heavy | rein_pressure | rein_pressure (0) | 0.98 | rein_pressure 0.98, praise 0.02, no_comment 0.00 | ✓ | rein_pressure |
| S30 | rein | halt | rein_pressure=heavy | rein_pressure | rein_pressure (1) | 0.98 | rein_pressure 0.99, praise 0.01, tempo 0.00 | ✓ | rein_pressure |
