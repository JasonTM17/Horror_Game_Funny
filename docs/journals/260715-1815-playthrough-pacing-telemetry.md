---
date: 2026-07-15
session: playthrough-pacing-telemetry
commit: fc8f7e70a4fa9fef61b07c6832650a615425a683
status: shipped-physical-validation-open
---

# Journal: 2026-07-15 — Playthrough Pacing Telemetry

## Context

Commit `fc8f7e7` shipped scene-local, pause-aware telemetry for the fresh Lobby-to-visible-credits route. The goal is narrow: measure the authored 15–20 minute target without treating checkpoints, incomplete runs, or automation as release proof.

## What Happened

- `GameplayDirector` now creates one telemetry node per gameplay scene and snapshots eligibility at start. Only a fresh run beginning in `LOBBY` receives a pacing verdict.
- First-occurrence milestones remain in the order actually observed. Five chapter durations derive from those timestamps; missing boundaries stay `null`, not zero.
- Visible credits emit `credits_shown`, finalize the report, disconnect stage tracking, and print one `PLAYTHROUGH_PACING: ` JSON line. The director exposes only a recursive copy of the report.
- Progression and checkpoint/layout coverage gained pause accounting, production-stage thresholds, finalization, deep-copy isolation, duplicate-ending protection, invalid-order rejection, and resumed-run rejection.

## Defects Caught and Fixed

| Defect | Final fix | Why it mattered |
|---|---|---|
| Post-credits reset mutation | Finalization disconnects `GameState.stage_changed`; tests snapshot the report, reset the run, and require byte-equivalent JSON afterward. Duplicate ending calls must also leave it unchanged. | A completed payload must remain evidence, not live state that later menu/reset events rewrite. |
| Actual boundary order | Tests cross the production floor, memory, Room 407, and chase thresholds, assert the actual eight-item order, and reject a fixture containing every milestone out of order. | Sorting or reconstructing expected order would make invalid progression look complete. |
| Real physics capture fixture | The test now starts chase through the production threshold, places the enemy capsule above the floor, clears velocity, and waits two real physics frames for navigation, movement, collision recovery, and proximity capture. | The old private-call/proximity shortcut could pass without exercising the capture path. |
| Pause-test false positive | The test brackets a deliberate 60 ms paused interval with frames, requires active time to stay fixed, wall time to advance, and the final report to retain positive paused time. | Merely observing an unchanged counter could pass even when no measurable pause interval was recorded. |
| Audio drain leak | Checkpoint teardown calls `AudioManager.stop_all()`, frees gameplay, then gives the audio mix thread 0.2 s to release ending playback. | Immediate shutdown left audio lifetime noise that could hide a real teardown leak. |

## Evidence

- Canonical headless runner: **12/12 checks passed**.
- Recorded fresh compressed progression payload: active `3.67 s`, wall `3.74 s`, paused `0.06 s`, `complete: true`, `boundary_order_valid: true`, `within_target: false`.
- The synthetic verdict is **false by design**: 3.67 seconds is valid instrumentation behavior but nowhere near the independent `900–1200 s` target.
- Checkpoint/layout finalization remained ineligible and incomplete with a `null` total verdict.

## Decisions and Trade-offs

| Decision | Trade-off and impact |
|---|---|
| Keep telemetry scene-local; no autoload, file, or UI persistence | Prevents stale cross-run evidence and keeps scope small, but the console payload must be preserved with the same-run capture. |
| Finalize at visible credits, not the `ENDING` stage | Measures through the in-world reveal and matches player-visible completion, at the cost of an explicit chase-to-telemetry signal. |
| Separate active, wall, and paused time | Produces a fair gameplay-duration measure while preserving audit context; monotonic pause tracking and active-time clamping add modest complexity. |
| Reject resumed and malformed runs instead of guessing | Conservative evidence semantics reduce convenient data, but prevent checkpoint shortcuts and reordered milestones from supporting a release claim. |

## Reflection and Impact

Relief is qualified. The review found several tests that could have looked green for the wrong reason: mutable finalized state, expected-order assertions detached from production boundaries, a capture shortcut, and pause coverage without a proven interval. Shipping those would have produced convincing JSON with weak evidentiary value. The useful lesson is blunt: telemetry needs lifecycle and adversarial tests as much as gameplay does.

The project can now compare real chapter and total timings against explicit targets. It still cannot claim the target is met.

## Next Step

- **Owner:** human QA/release playtest operator; specific assignee still unresolved.
- Run one fresh **F5** blind keyboard-and-mouse boot-to-credits session, record the full 15–20 minute traversal, and preserve its same-run payload. Release pacing passes only with `eligible_full_run: true`, `complete: true`, valid actual order, and `900–1200 s` active time.

## Unresolved Questions

- Who is assigned and authorized to perform and preserve the physical blind-run evidence?
