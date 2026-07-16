# Phase 1 - Terminal Ending Transition

## Files

- `scripts/world/chase-sequence-controller.gd`
- `tests/progression-test.gd`

## Steps

- [x] Add a red regression that starts capture recovery, begins Ending before the recovery timer expires, then proves recovery cannot restore checkpoint state or chase.
- [x] Make `finish()` terminal: cancel recovery ownership, clear only the fail lock/overlay, stop entity/audio, and preserve the ending objective/stage.
- [x] Recheck terminal state after the asynchronous recovery wait before any restore/restart mutation.
- [x] Run focused progression green and inspect engine/leak output.

## Acceptance

- `ENDING` stage and ending objective remain after 1.4 seconds.
- `recovering == false`; fail lock/overlay are cleared; entity stays stopped/hidden.
- Exactly one credits overlay is produced; ordinary capture recovery remains covered.

## Evidence

- Baseline red: the added overlap fixture exited `2` with `PROGRESSION_ASSERT: capture recovery overwrote the terminal ending stage`.
- Final red/green: stale-failure-audio fixture exited `2` before the cleanup line, then progression exited `0` with `PROGRESSION_TEST_OK`; both final engine/console scans reported zero error, assertion, parse, or leak lines.
- `checkpoint-layout-test.tscn` exited `0` with `CHECKPOINT_LAYOUT_TEST_OK` after the final controller change.
- Independent tester and debugger confirmed ordinary recovery, terminal stage/objective/entity/lock invariants, and unique profile cleanup; code review passed 10/10 after the audio cleanup.
- Commit `30199b77f384d15d9016834e6e4b04cd4e5644d4` is pushed to `main`; final verification found exact remote parity.
