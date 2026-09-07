---
name: Headless visual QA baseline
description: Environment-specific failure mode in the fixed-camera browser review harness.
---

In the current headless Chromium runner, the fixed-camera review harness can leave
the 3D frame counter at zero and time out before a review camera is established.
The grandstand browser test can consequently fail in review mode and then crash
while formatting a missing rendered height, even on an untouched source baseline.

**Why:** This makes a browser-harness failure look like a scene regression when the
same failure is reproducible without the candidate scene changes.

**How to apply:** When fixed-camera visual tests fail this way, compare the exact
test and browser environment against an untouched baseline before changing scene
geometry or render code. Do not treat a screenshot captured while the frame
counter is zero as visual acceptance evidence.