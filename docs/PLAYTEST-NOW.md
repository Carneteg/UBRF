# Playtest now

Current playtest baseline: `chatgpt/integration-review-20260907`.

Immediate product requirement before Tobias' first-day playtest:
- On the first ordinary riding-school pass (`SPAR.pass === 0`, `G.tavling == null`), `visaTilldelning()` must assign `blackrock_jack`.
- Later ordinary passes keep existing rotation.
- Competition assignment remains unchanged.
- Add/adjust a regression test proving first ordinary pass => Blackrock Jack and later pass => normal rotation path.

Do not change environment, progression, competition rules, horse stats, or unrelated gameplay.
