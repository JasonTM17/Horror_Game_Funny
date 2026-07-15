---
type: reviewer-final
date: 2026-07-15
target: d03335d7c3bf141e5488f8481e359830179ab2e6
base: 15e2e4ad20339fe125ca8f7884353a8fa36b3cfe
---

# Final Gameplay/UI Code Review

## Scope

- Reviewed committed range `15e2e4a..d03335d` after the gameplay/UI/test edits were committed during review.
- Read full changed implementations, their state/router/player/settings consumers, Phase 4–7 acceptance criteria, project rules, and saved test logs.
- Saved headless evidence at 12:21–12:22 shows all seven runner checks reached expected markers; `git diff --check 15e2e4a..HEAD` exits clean.
- No source files changed by this review.

## Overall Assessment

**DONE_WITH_CONCERNS.** Structural flow remains one `gameplay.tscn`; no chapter/level scene transitions were added. Final code fixes the stale pre-final chase-retreat and pause-Settings races: retreat now invokes checkpoint recovery, while Settings owns a separate input lock and consumes Escape. Chase speed is statically fair (`3.0 m/s` entity versus `2.0 m/s` walk and `3.1 m/s` sprint), and recovery reuses one entity.

Release still has two high-priority blockers and three medium correctness defects. The green suite also contaminates real user settings and does not prove physical chase completion, actual Continue routing, reveal visibility, or audio teardown.

## High Priority

### H1 — Settings test persists destructive values into the real game profile

`tests/settings-audio-test.gd:12-14` sets maximum sensitivity, minimum FOV, and `-40 dB` master volume. The test then calls `SettingsPanel.close_panel()` at line 35, which persists them through `scripts/ui/settings-panel.gd:37-40`. `reset_defaults()` at test line 45 happens only afterward and is never saved.

This is reproduced in the real `user://room407.cfg` written at 12:22: `mouse_sensitivity=0.25`, `field_of_view=60.0`, `master_volume=-40.0`. A developer/player launching after the passing suite gets near-muted audio and maximum mouse sensitivity.

**Fix:** isolate Godot user data for the runner (for example, a suite-specific APPDATA root), or snapshot and restore the original config in guaranteed teardown. Do not “fix” by saving defaults; that still destroys user preferences.

### H2 — The required 15–20 minute authored duration remains unverified and likely short

`tests/checkpoint-layout-test.gd:56-60` treats corridor distance thresholds as pacing evidence. They prove geometry length, not authored duration. Current production movement is `2.0 m/s` walking and `3.1 m/s` sprinting (`scenes/player/player.tscn:15-16`); route and subtitle math from the fixed coordinates still yields roughly 8.5 minutes sprinting or 12.5 minutes walking before small interaction overhead. No dated full-playthrough timing exists.

The game is structurally continuous, but empty travel cannot establish the explicit 15–20 minute product requirement.

**Fix:** run and record fresh developer and blind playthroughs with beat timestamps. If short, add compact authored observation/puzzle beats inside the same gameplay scene; do not add levels or forced idle padding.

## Medium Priority

### M1 — Continue restores progression flags but rebuilds the hallway as Variant0

`scripts/world/dynamic-hallway-controller.gd:8-17` always builds only Variant0 visible. `scripts/world/story-progression-controller.gd:20-31` reconstructs `memory_count`, `loop_iteration`, and gate state from a room/chase checkpoint, but never calls `reconfigure_for_memory()`. Continue therefore restores three completed memories while the backtrackable hallway shows its initial state.

`tests/settings-audio-test.gd:38-44` checks only that the Continue button is visible; it never invokes router restore or asserts reconstructed world state.

**Fix:** apply the derived memory variant during setup before play resumes, then test a real checkpoint reload and assert variant/root visibility.

### M2 — Closing and immediately reopening radio bypasses cooldown and lets the stale timer clear new input

A wrong code starts `_finish_wrong_feedback()` at `scripts/puzzles/radio-puzzle.gd:102-109`. Escape/Step Away can close the panel at lines 118-121; reopening at lines 17-29 immediately resets `_accepting_input`. If the original 0.55-second timer then fires while the reopened panel is visible, its guard passes and lines 112-116 erase the new attempt. Reopen also bypasses the intended anti-spam interval.

`tests/progression-test.gd:36-41` covers only wrong → wait → correct.

**Fix:** use an attempt generation/token or cancellable Timer, and define cooldown across close/reopen. Add wrong → close → reopen-before-timeout coverage.

### M3 — Ending reveal and credits appear in the same frame, hiding the reveal beat

`scripts/world/chase-sequence-controller.gd:46-69` builds the abandoned-lobby geometry and immediately shows the ending overlay. The overlay Panel covers the central `x=170..790`, `y=72..468` view (`scenes/ui/ending-overlay.tscn:8-12`), directly over the ahead-facing labels and desk. The reveal has no observable window before credits.

`tests/progression-test.gd:62-64` calls the ending at the recovery marker and asserts only that `AbandonedLobbyFloor` exists; it does not verify physical exit placement or visibility.

**Fix:** stage a short in-world reveal before showing credits, or incorporate the reveal visibly into the ending UI. Verify at the real exit position.

## Test Validity and Risk Coverage

- Saved 7/7 result is valid for parse/load, fast semantic progression, door-ray layout, state recovery count, settings control presence, and success markers.
- It is not isolated: H1 proves the suite mutates persistent player state.
- Fair chase is only speed/state math. No test drives capture, successful 300 m escape, retreat recovery, pause during pursuit, or low-FPS feel. Manual chase QA remains mandatory.
- Continue is only button visibility; router restore and reconstructed scene state are not exercised.
- Pause Settings directly calls `_settings()` with a synthetic lock; it does not pause the tree or dispatch Escape. Final code is statically coherent, but the user path remains untested.
- `start_drone()` is a no-op under headless, and neither audio test asserts `stop_all()` clears players/cache/sample accounting. Static cleanup is idempotent; runtime audio lifecycle remains an evidence gap.
- Progression still calls director internals and does not traverse the full physical path. Passing automation cannot replace the required manual navigation, ending reveal, audio balance, and timing pass.

## Adversarial Adjudication

- **Accepted:** settings-profile contamination, checkpoint hallway mismatch, radio reopen race, same-frame hidden reveal, missing timed pacing evidence.
- **Rejected as stale against final HEAD:** chase backtracking permanently despawns the entity. Final `chase-entity.gd:40-43` calls failure recovery instead.
- **Rejected as stale against final HEAD:** Escape resumes gameplay while Settings remains open. Final pause/settings/player code adds a `settings` lock, consumes Escape, and removes only that lock on close.

## Unresolved Questions

- No measured full playthrough establishes 15–20 minutes.
- No manual run establishes chase feel, reveal readability, or audio cleanup/balance.
- Should Continue restore transient subtitle text, or explicitly clear it? Current checkpoint data stores neither subtitle nor a reset value.

Status: DONE_WITH_CONCERNS
Summary: Final range is one continuous scene and fixes chase-retreat/pause-Settings races, but persistent settings pollution and unverified/likely-short pacing block release; checkpoint visuals, radio reopen timing, and reveal staging remain wrong.
Concerns/Blockers: Fix H1–H2 before release; fix M1–M3 and run real checkpoint/chase/ending/audio/timed playthrough validation.
