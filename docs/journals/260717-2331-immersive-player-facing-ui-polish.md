---
date: 2026-07-17
session: immersive-player-facing-ui-polish
---

# Immersive Player-Facing UI Polish

**Date**: 2026-07-17 23:31
**Severity**: Medium
**Component**: HUD, boot/failure/settings menus, ending overlay
**Status**: Resolved and automated-verified; physical release validation open

## What Happened

Technical scaffolding escaped into the live presentation: `OBJECTIVE`, `POCKETS\n(empty)`, `CONTINUE CHECKPOINT`, raw save error codes, engine/license metadata, and implementation-oriented Settings labels. The first refreshed credits capture exposed another miss: “Read the condemnation notice…” remained visible behind the ending panel. This was not subtle polish debt; the game broke its own fiction at the exact moments meant to carry tension and closure.

## The Brutal Truth

We treated player-facing copy as harmless developer labeling and did not visually review the entire UI lifecycle soon enough. That was lazy boundary discipline. The credits capture was the kick in the teeth: automated ending/input checks were green while the HUD visibly contradicted the finished ending. Overlapping validation also briefly produced conflicting lifecycle logs, wasting time and making the evidence harder to trust.

## Technical Details

The red contract failed with `PLAYER_INPUT_ASSERT: HUD wraps the story direction in a technical objective header` at `tests/player-input-integration-test.gd:60`. `scripts/ui/hud.gd` now hides empty inventory, shows `Fourth-floor key` instead of `floor_key`, and leaves the story direction unwrapped. `scripts/ui/ending-overlay.gd` hides the sibling `HUD` before showing credits. Settings retain the internal `Error` for retry behavior but display no raw code.

Focused green evidence: `PLAYER_INPUT_INTEGRATION_TEST_OK`, `SETTINGS_AUDIO_TEST_OK`, and `PROGRESSION_TEST_OK`. The staged stills and 59-frame, 7.38-second GIF were refreshed after reviewing the corrected capture. At 23:40, one final isolated canonical run completed all 12 checks with every required marker and exit code 0; this replaced the ambiguous overlapping-run evidence.

## What We Tried

- Added red copy/HUD assertions before changing presentation.
- Replaced technical labels with in-world language while retaining actionable prompts, retry, and close-without-saving choices.
- Rejected permanently visible empty inventory and diagnostic error text; neither helps the player recover.
- Re-captured the tour, found the HUD-behind-credits defect, fixed lifecycle visibility, then added a progression assertion for it.

## Root Cause Analysis

The root cause was no explicit boundary between internal state terminology and player-facing language, plus tests that proved ending lock state without proving visual-layer teardown. The capture review found what the contract omitted.

## Lessons Learned

Treat copy and visibility as runtime behavior. Every terminal overlay must assert what disappears, not only what appears. Keep diagnostic detail in logs/state; show players plain-language recovery actions.

## Next Steps

- **Owner: human QA/release, before release** — record and review one physical F5 boot-to-credits run, including HUD transitions, Settings failure recovery, credits, audio/fullscreen, chase fairness, and the 15–20 minute pacing gate.

## Unresolved Questions

- Does the corrected presentation remain readable and immersive through a real physical playthrough?
