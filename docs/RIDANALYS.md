# G02-D — Ridanalys, positiv feedback och referensritt

Status: PRODUCT DIRECTION APPROVED by Tobias, 2026-09-07. Implementation NOT_STARTED in this branch. This document is subordinate to PRODUCT-CANON.md and the current delivery/security rules. It does not authorize a release or override the alpha smoke gate.

## Product goal
The player leaves every training session having succeeded at something, understood something and wanting to try again. Riding remains fun first, but genuine horse knowledge, welfare and cause/effect are not sacrificed. Training and competition must use the same riding model. The instructor teaches the player to cooperate with the horse, never to operate it as a vehicle.

## Locked coaching contract
Ugneta is warm, observant, constructive and credible, not a score announcer. The sequence is: recognize what actually worked → explain one meaningful improvement → give one actionable instruction → invite another attempt. Praise must identify a measured success or improvement. Never fabricate praise, an error, a measurement or a comparison. If a metric is unavailable, say so or use a valid qualitative observation; do not turn missing data into a neutral or positive score.

During active riding: one topic at a time, at most two short instructions; safety calls take precedence. Do not interrupt the horse's movement with long text, automatic replay or forced advancement. After an attempt, offer an explicit accessible Continue / Try again / Replay choice. A second attempt compares with the actual previous attempt under comparable conditions, not random or invented scores. If the player struggles, simplify the task, explain it differently or offer a preparatory exercise. Do not shame, punish repeated attempts, exaggerate praise or require a high score before ordinary learning can continue.

An instructor may acknowledge an unclear explanation and offer another approach. Never use that line to conceal a real gameplay or telemetry defect. Feedback describes simulated aids and horse response, not the player's real-world body position, hand or riding ability inferred from a keyboard, controller or touchscreen.

Training offers guidance and retry. Competition preserves the same physics, permits normal safety intervention, limits distracting coaching during a judged movement and gives constructive analysis afterwards. Result, placing and rosette are separate from learning progress. Competition is never a reason to drive a tired, stressed or unfit horse harder. Existing simplified competition rules must not be presented as official regulations.

## Replay and shadowing principles
The reference is an ideal *for this exercise, horse profile and rider level*, not a universal perfect movement. It must be feasible under the same approved riding model and validated against credible riding instruction. A reference trace is not an invented source of truth. Label demonstrations as illustrative until their feasibility and riding correctness are verified. No AI-generated trajectory may silently become the judging standard.

Record the player's actual ride once and reuse it for playback, comparison and assessment. Do not create a separate scoring model for replay. A ghost is an optional, translucent rendering of a reference or earlier attempt, not an obstacle, physical horse, collision target or replacement for the player's own movement. The normal riding camera and controls remain available. Clearly identify actual ride, reference and previous/personal-best attempts.

Replay must support play/pause, speed reduction, scrubbing, camera choice where supported, ghost visibility and a return to the next attempt. A reduced-motion-friendly alternative and readable route/metric comparison must be available. Input, UI and rendering may differ between Roblox and HTML, but the exercise definitions, metric meanings, comparison rules and reference metadata must agree.

## First delivery: two existing exercises
Do not start by adding a large exercise catalogue. First make the existing 20 m circle and one upward/downward transition genuinely teachable and replayable. Reuse G02-C telemetry and the existing riding/lesson lifecycle; preserve accepted formulas and Ugneta's one-topic flow unless a measured defect justifies a narrow correction.

20 m circle: measure route deviation, radius/shape, rhythm and balance. Show the actual route and a feasible reference route, with a time-aligned horse ghost if the available animation/state data support it. Explain the main point of difference, such as preparation before the turn, rather than simply demanding a smaller distance to the ghost.

Transition: measure the requested gait, cue time, response time, transition duration, establishment, softness and relevant balance. Show the actual and reference timing, and optionally the horse ghost. Explain the distinction between asking, the horse beginning to respond and the gait becoming established. Never reward a faster transition merely for being faster when it sacrifices balance, softness or the horse's welfare.

Both exercises must support an initial attempt, a short evidence-based response, voluntary replay, explicit retry, a comparison with the actual first attempt and a clear exit. The second attempt must start from a valid lesson state. Cancel, dismount, character removal and stale input must not trigger delayed continuation or preserve an invalid ride state.

## Engineering contract
Use a shared, versioned exercise definition containing stable exercise ID, level/horse applicability, prerequisites, course geometry and coordinate frame, target gait/tempo, assessed metric IDs and weights, valid-sample requirements, reference ID/version and pedagogical feedback rules. Keep the canonical definitions motor-independent. Roblox Luau and web JavaScript may have platform adapters; do not maintain divergent hidden gameplay constants or duplicate scoring truths.

A replay record must identify schema version, build/source SHA, exercise/reference versions, horse/profile and relevant starting conditions, deterministic simulation clock or timestamp policy, coordinate frame, initial state, sampled position/orientation, gait and animation phase where available, simulated aids, relevant horse state and discrete events. Include input/device metadata only where useful for replay or diagnosis. Record no account secrets or unnecessary personal information. Guest replay must work without registration. Define bounds, retention, export/import and migration behavior before introducing persistent or shared recordings.

Prefer deterministic fixed-step simulation and input/event capture where the existing engine supports it; use bounded snapshots and validated interpolation for robust playback. A record must not silently change its meaning after a model update. Handle missing/invalid fields, NaN/infinity, truncated records, version mismatch and absent references explicitly. Playback is read-only and must not mutate live horse, progression, competition results or server-authoritative state. Avoid heavy recording allocation or storage writes in the render loop. Preserve performance on phone/tablet/desktop and Roblox.

The first reference may be a reviewed, reproducible demonstration generated through the real model. Its source, parameters, model version, validation status and limitations must be recorded. Do not promise a realistic anatomical ghost if the current rig/animation cannot support it; fall back to route and timing overlays and report the gap. No new unverified UBRF geometry, doors, arena dimensions or asset licensing assumptions.

## Acceptance and falsification
- A real player can perform the two exercises from guest mode and choose Replay or Try again without being automatically advanced.
- The replay reproduces the recorded route and event timing within a documented tolerance; pausing, scrubbing and replaying twice do not alter the live ride or progression.
- The reference is feasible for the selected horse/level, visibly identified and independently reviewed for riding correctness. A different horse need not follow an identical time/stride trace.
- Positive feedback is tied to a valid observation. A poor attempt receives one usable correction and encouragement, not an invented success. A genuine improvement is identified from the two recorded attempts.
- Negative tests cover missing telemetry, zero versus missing values, NaN/infinity, zero/insufficient samples, opposite-direction improvement, low-quality transitions, stale lifecycle callbacks, missing reference and version mismatch.
- The horse is not rewarded for excessive speed, force, fatigue or stress. A welfare/safety condition overrides ordinary coaching and may stop the exercise appropriately.
- Keyboard, gamepad and touch flows have distinct input checks; responsive UI and reduced-motion behavior are inspected. Browser tests are not reported as physical touch or Roblox Studio testing.
- Shared metric semantics and reference IDs are verified across web and Roblox. Any unavailable platform feature is reported explicitly, not marked PASS by assumption.
- Existing lesson, mounting/dismounting, riding, competition, care, progress and environment regression tests remain green. Exact-head CI and a playable preview are required before independent ChatGPT review.

## Delivery order and ownership
1. Preserve and finish the existing alpha smoke/integration baseline. Do not destabilize it or merge unreviewed work to main.
2. Claude, Gameplay & Integration Lead: implement the small G02-D vertical slice on a separate feature branch, using the existing riding, lesson, telemetry and test infrastructure. First audit what already exists; reuse rather than replace. Provide a concrete schema, reference-validation evidence, two working exercises, replay UI and negative tests.
3. ChatGPT: independently review code, measurement validity, visual/replay evidence and cross-platform contract. A builder's READY_FOR_CHATGPT_REVIEW is not product acceptance.
4. Tobias: play the resulting slice and decide whether it is fun, understandable and good enough. Real Roblox Studio and physical touch remain separate explicit gates.
5. Only then expand the exercise library, personal training recommendations, personal-best ghost and competition replay. New movements require real aid/horse behavior and credible assessment, not merely a label or scripted animation.

Replit remains on environment freeze unless a separately approved, narrowly scoped blocker requires its involvement. No new projects, production hosting, credentials, weakened security or speculative environment changes are authorized. No automatic merge or launch.