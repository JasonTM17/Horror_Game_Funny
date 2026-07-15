---
type: clean-clone-release-rehearsal
date: 2026-07-15
source_commit: c9ccfc3e2382b695019c83031d1aa416bf9657eb
status: automated-release-rehearsal-complete-manual-launch-open
---

# Clean Clone Release Rehearsal

## Scope

Clone `origin/main` into a new ignored directory with no project cache or user profile, run the documented Godot 4.7.1 suite, and audit the cloned tree. This proves source import and automated behavior from remote state; it does not count as a physical F5 playthrough.

## Source

- Remote: `https://github.com/JasonTM17/Horror_Game_Funny.git`
- Branch: `main`
- Clone SHA: `c9ccfc3e2382b695019c83031d1aa416bf9657eb`
- Clone status after tests: clean; generated cache/logs remained ignored.

## Verification

- Fresh editor import built the Godot class cache and imported `icon.svg` without an existing `.godot/` directory.
- Menu, gameplay, game-state, progression, checkpoint-layout, and settings-audio checks passed after import.
- Canonical logs: 7.
- Parse, engine, assertion, or ObjectDB leak matches: 0.
- Tracked `.godot`, `.tmp`, `.artifacts`, or log files: 0.
- Tracked credential/private-key pattern files: 0.
- Tracked blobs larger than 5 MiB: 0.
- Total clone size after ignored test artifacts/cache: approximately 0.61 MiB.

## Environment

- Godot: `4.7.1.stable.official.a13da4feb`
- C: approximately 12.13 GiB free after the rehearsal
- D: approximately 21.48 GiB free after the rehearsal

## Remaining Release Evidence

- Press F5 from the official editor and complete the game with physical keyboard/mouse input.
- Record chapter and total timings against the 15–20 minute target.
- Verify chase feel, visual/audio balance, device output, and settings persistence after a real relaunch.

## Unresolved Questions

- None beyond the explicit manual validation set.
