# First-day horse assignment

Product decision 2026-09-07: on the player's first ordinary riding-school day (`SPAR.pass === 0` and no competition context), the instructor must assign **Blackrock Jack** (`blackrock_jack`). Later ordinary days keep the existing rotation. Competition-day assignment remains governed by competition logic.

This decision is for the current alpha playtest baseline and should be implemented in the horse-assignment flow without changing unrelated horse pools, progression, environment, or competition rules.
