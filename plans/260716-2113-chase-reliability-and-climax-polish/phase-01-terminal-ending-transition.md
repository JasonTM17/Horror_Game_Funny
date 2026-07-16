# Phase 1 - Terminal Ending Transition

## Files

- `scripts/world/chase-sequence-controller.gd`
- `tests/progression-test.gd`

## Steps

- [ ] Add a red regression that starts capture recovery, begins Ending before the recovery timer expires, then proves recovery cannot restore checkpoint state or chase.
- [ ] Make `finish()` terminal: cancel recovery ownership, clear only the fail lock/overlay, stop entity/audio, and preserve the ending objective/stage.
- [ ] Recheck terminal state after the asynchronous recovery wait before any restore/restart mutation.
- [ ] Run focused progression green and inspect engine/leak output.

## Acceptance

- `ENDING` stage and ending objective remain after 1.4 seconds.
- `recovering == false`; fail lock/overlay are cleared; entity stays stopped/hidden.
- Exactly one credits overlay is produced; ordinary capture recovery remains covered.

