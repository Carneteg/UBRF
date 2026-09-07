---
name: Headless visual QA baseline
description: Environment-specific failure mode in the fixed-camera browser review harness.
---

Stale Chromium binaries left in old Playwright image paths can launch successfully
but leave WebGL review mode at frame zero. Replit's maintained Chromium wrapper
advances the 3D frame counter and establishes fixed review cameras reliably.

**Why:** A browser that launches but never produces a WebGL frame makes a harness
failure look like a scene regression, even on an untouched source baseline.

**How to apply:** Prefer Replit's maintained Chromium wrapper over versioned
Playwright-image paths, and keep browser tests on the shared launcher. Never treat
a screenshot captured while the frame counter is zero as visual evidence.