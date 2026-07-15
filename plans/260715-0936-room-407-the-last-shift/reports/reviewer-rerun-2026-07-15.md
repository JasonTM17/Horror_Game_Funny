---
type: reviewer-rerun
date: 2026-07-15
target: 15e2e4ad20339fe125ca8f7884353a8fa36b3cfe
base: c4efbd12ca0e51c3089bb22b01441b41210d14d0
---

# Production Readiness Re-review

## Scope

- Reviewed committed fix diff `c4efbd1..15e2e4a`; concurrent documentation/report worktree edits excluded.
- Read project rules, README, architecture/code standards, Phase 7, prior tester/reviewer evidence, relevant scenes/scripts/tests, and the source brief's acceptance/red-team sections.
- Rechecked door/partition collision, Room 407 route, continuous pacing, checkpoint restoration, fail duplication, modal locks, hallway variants, enemy navigation/LOS/FSM, audio/settings, and test strength.
- Fresh command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1` exited `0`; all six checks reached their markers and current logs contain no engine errors, assertions, warnings, or ObjectDB leak warning.
- Disk at verification: C: 11.75 GiB free; D: 27.21 GiB free.

## Overall Assessment

**RELEASE BLOCKED.** The old full-width Room 407 wall and walk-around door gaps are structurally fixed, checkpoint spawn/objective and single-entity recovery now pass, modal interaction locks are corrected, and the leak warning is gone. The result is also technically one uninterrupted gameplay scene.

The core experience still does not meet the requested product, however. It is an 870 m straight corridor whose duration is dominated by walking and two obvious teleports. That is not verified 15–20 minute authored gameplay and directly conflicts with both `docs/game-design.md` (walking distance must not substitute for content) and the user's instruction to avoid a boring, level-like sequence. Dynamic hallway, meaningful puzzles, enemy behavior, audio, settings, and production-path tests also remain incomplete.

## Prior Finding Re-evaluation

| Prior finding | Verdict at `15e2e4a` | Evidence |
|---|---|---|
| C1 Room 407 wall blocks route | **Resolved statically; manual traversal still missing** | `continuous-world-builder.gd:33-35` builds left/right partitions around a 2.6 m aperture; `Room407Wall` is absent; back wall is beyond exit. |
| C2 door can be walked around | **Resolved statically for three closed gates** | Each 2.2 m door fills the central aperture and 0.2 m side gaps are smaller than the 0.68 m player diameter. Layout rays hit door at x=0 and partition at x=3. No test opens a door and walks through it. |
| C3 15–20 minute experience absent | **Not resolved** | Longer coordinates add walking, not authored gameplay; detailed timing below. |
| H1 checkpoint spawn/objective ignored | **Resolved for room/chase markers** | `gameplay-director.gd:73-86`; checkpoint-layout test verifies spawn and objective. |
| H2 progression test bypasses production | **Not resolved** | `progression-test.gd:14-58` still calls director internals, sets `room_entered`, solves radio directly, and invokes private chase start. |
| H3 hallway label-only | **Partially resolved** | Four visual roots now exist, but swapping/teleport/checkpoint behavior still violates the hallway contract. |
| H4 audio/settings incomplete | **Partially resolved, still release-blocking** | Master slider/subtitles and three buses landed; most mandatory categories/settings remain absent. |
| H5 modal interaction/Escape races | **Resolved statically** | Interaction checks centralized locks; radio/note consume Escape; player refuses pause during note/radio/fail/ending. No automated race test exists. |
| H6 enemy navigation/FSM missing | **Partially resolved, not production-ready** | Agent and LOS query landed, but no nav region exists, fallback is unbounded direct pursuit, `STALK` is unreachable, and tuning removes chase pressure. |
| M1 weak ending predicate | **Not resolved** | `gameplay-director.gd:211-215` still checks only `chase_started`. |
| M2 dead objective input | **Not resolved** | `show_objective` remains mapped/advertised but has no consumer. |
| M3 ObjectDB leak | **Resolved** | Fresh progression and checkpoint logs end cleanly with their success markers. |

## Stage 1 — Spec Compliance

| Requirement | Status | Current evidence |
|---|---|---|
| One continuous playable segment | PASS | Lobby, Floor 4, memory loop, Room 407, chase, and ending all live under `gameplay.tscn`; no chapter scene changes. |
| Authored 15–20 minute game | FAIL | Straight-corridor travel and 88 seconds of gated subtitles establish about 8.6–12.5 minutes before minor interactions, not a measured 15–20 minute run. |
| Two meaningful puzzles | FAIL | Fuse lacks missing-item feedback/environmental hint; radio prompt reveals `0007` before the puzzle opens. |
| Three progression memories | PASS | Three ordered, duplicate-safe memory flags/items exist. |
| Discreet dynamic hallway | FAIL | Variants pop in at pickup time; player teleports immediately at a black wall with no fade/occluded swap; restore does not reconstruct the variant. |
| Room 407 sequence | PARTIAL | Route and three interactions exist, but the "room" remains a long differently colored corridor segment rather than an authored impossible interior. |
| Enemy navigation/detection/FSM/chase | FAIL | No navigation region/map content or bounded waypoint fallback; unreachable state and ineffective speed tuning remain. |
| Checkpoint/fail recovery | PASS WITH MANUAL GAP | Spawn/objective, lock/fade, state restore, and single-entity retry are implemented; no manual mouse/collision run exists. |
| Required audio/settings/accessibility | FAIL | Missing Music bus, positional audio, loops, per-category volume, display mode, shake/grain/reduced flicker/reset, and in-game settings access. |
| Production-path automated/manual evidence | FAIL | Tests pass but do not drive player physics, ray interactions, open-door traversal, radio UI, enemy capture, pause/settings, or ending. No timed playthrough report exists. |

Stage 1 verdict: **FAIL**. Quality/adversarial findings below are release blockers or evidence gaps against explicit acceptance criteria.

## Critical Finding

### C1 — Continuous scene achieved by corridor padding, not 15–20 minutes of authored play

`continuous-world-builder.gd:17-25` builds one 8 m-wide floor and two walls across an 870 m axis. `world-layout.gd:4-26` places all mandatory beats sequentially on that axis. Including the fuse backtrack and two memory-loop teleports, the required travel path is about 1,318 m. At the scene's actual 2.0 m/s walk and 3.1 m/s sprint (`player.tscn:15-16`), travel is 10.98 or 7.09 minutes. All mandatory narrative gates total 88 seconds; even adding every gate serially yields only about 12.45 minutes walking or 8.56 minutes sprinting before brief interactions.

The layout test makes this worse by asserting distance thresholds as “authored pacing” (`checkpoint-layout-test.gd:32-36`). A blind player's hesitation cannot be the acceptance mechanism. There are no exploration branches, substantial observation mechanics, or environmental tasks to supply the missing minutes. This is one scene, but it will feel padded and repetitive—the exact boredom risk the user rejected.

**Required fix:** keep one `gameplay.tscn`, shorten empty runs, and replace distance padding with authored continuous-space beats: a compact searchable lobby, fuse maintenance branch, three materially different occluded hallway passes, clue observation/turn-away event, real Room 407 inspection, and a tuned chase. Record at least one fresh blind run and one developer run with beat timestamps; both must land inside 15–20 minutes without forced idle padding.

## High Priority Findings

### H1 — Puzzle and semantic gates still allow invalid or trivial progression

- `gameplay-director.gd:93-106` exposes the exact radio answer in the world prompt: “Tune the radio to 0007.” This removes the second puzzle and makes the clock/photo clues irrelevant.
- `gameplay-director.gd:139-165,218-223` permits direct fuse pickup/memory calls without floor, power, or `memory_loop_started` prerequisites. Physical walls help normal play but do not make the semantic contract safe.
- `gameplay-director.gd:184-215` does not require `room_entered` for the recording and authorizes ending with `chase_started` alone. Repeated direct exit calls can also duplicate ending UI because `_ending` is not checked in the action.
- Fuse-box interaction without a fuse returns false with no useful player feedback, contrary to the puzzle fallback requirement.

**Required fix:** add one explicit prerequisite predicate per action and ending; remove the solution from the radio prompt; place/readable `00:07` clues before the radio; give fuse/radio wrong-state feedback; test every missing prerequisite and repeat submission.

### H2 — Hallway variants are visible swaps plus an obvious teleport

`dynamic-hallway-controller.gd:23-43` switches `visible` roots immediately when a memory is collected, including props ahead of the player. `gameplay-director.gd:166-175` then teleports the actor from z=-310 to z=-125 before any fade/occlusion sequence. This violates the explicit discreet-transition requirement. On checkpoint load, `_memory_count` is reconstructed but `_hallway.reconfigure_for_memory()` is never called, so a three-memory snapshot renders Variant0.

There are also no safe markers, transition-exit debounce, out-of-bounds recovery, collision/process activation, or checkpointed variant field described by the architecture. The roots mostly add non-colliding beams/doors/lights, so route shape does not materially change.

**Required fix:** perform the swap while view is blocked, fade/blackout before relocation, validate a named safe marker, restore variant from memory flags/checkpoint, and add spam/restore/camera-clear tests.

### H3 — Chase AI does not meet navigation/FSM or gameplay-pressure requirements

`chase-entity.gd:21-25` creates a `NavigationAgent3D`, but the project has no `NavigationRegion3D`, `NavigationMesh`, or waypoint data; `_navigation_ready()` therefore cannot provide an authored path. Lines 51-68 fall back to direct steering. When LOS is lost, `LOST_TARGET` still uses the target's current position until `SEARCH`, so detection/LOS state does not prevent pursuit through geometry. `STALK` is never entered.

The entity's 1.9 m/s speed is lower than the player's 2.0 m/s walk and 3.1 m/s sprint. From an 8.5 m head start it cannot close on a moving player; the 300 m chase becomes a long, low-risk run. No test drives capture, LOS loss, collision, pause, zone exit, or checkpoint retry through this AI.

**Required fix:** either add a small baked navigation region plus bounded waypoint fallback or document/use an explicitly collision-free lane with real waypoint steering. Make all retained states reachable and meaningful, tune speed so walking is unsafe but sprint remains fair, cap the chase zone, and physics-test one capture and one successful escape.

### H4 — Phase 6 remains marked complete despite mandatory audio/settings gaps

`audio-manager.gd:8-27` creates SFX/Ambience/Chase but no Music bus, then routes every generated cue to SFX. There are no ambient/named loops, chase drone lifecycle, door cue, spatial `AudioStreamPlayer3D`, or per-category volume controls. `settings-manager.gd` and `settings-panel.gd` cover sensitivity, FOV, master, binary flicker, and head bob only. Fullscreen/windowed, music/SFX/ambience volume, shake, grain, reduced flicker intensity, defaults reset, and pause-menu settings are absent.

`player-flashlight.gd:9-16` also samples flicker probability per frame rather than per second, so flicker frequency changes with frame rate.

**Required fix:** reopen Phase 6; implement the required buses/cues/positional path and bounded persisted settings, expose settings during pause, make flicker delta/timer based, then add persistence/bounds/bus/idempotent-loop tests.

### H5 — Green tests still bypass the failures they claim to cover

`progression-test.gd:14-58` drives internal semantic calls, manually sets `room_entered`, calls `on_radio_solved()`, calls `on_note_closed()`, and invokes private `_start_chase()`. `checkpoint-layout-test.gd:27-36` proves only that closed barriers exist at two x samples and that coordinates are large; it never opens a door or moves the player capsule. There are no focused interaction, door, radio UI, settings, modal-race, enemy, ending, or runtime smoke suites required by Phase 7.

**Required fix:** retain fast state tests, but add a test-only smoke driver that uses public interactions/positions and physics frames. Explicitly test closed-gate rejection, opened-door passage, radio wrong/correct input, note/radio Escape ownership, chase capture/retry, ending prerequisites, and settings persistence. Distance is not a pacing assertion; manual timing is mandatory.

## Medium Priority Findings

### M1 — Objective review control remains false documentation

`project.godot:71-74` and README advertise Tab objective review, but no script consumes `show_objective`. The HUD permanently shows the objective instead.

**Fix:** implement a bounded objective/history reveal on Tab or remove the mapping and README claim.

### M2 — Room route is structurally plausible but not physically proven

The prior full-width blocker is gone, and aperture dimensions are consistent with the player capsule. Current automation only rays the closed barrier. It does not rotate the centered-pivot door, sweep the capsule through the open aperture, cross the slightly raised Room 407 floor segment, or walk to the exit.

**Fix:** add an opened-door capsule traversal check and record one manual start-to-exit collision pass before release.

## Resolved/Verified Areas

- Headless editor import, menu, gameplay, GameState, progression, and checkpoint-layout checks all exit `0` and reach expected markers.
- No current test log warning/leak; prior 24-object teardown warning is resolved.
- Room/chase spawn IDs are consumed; restored objective survives scene construction.
- Fail recovery has one `_recovering` guard, locks input, fades, restores snapshot, repositions one existing entity, and unlocks input.
- Player interaction stops during modal locks; note/radio consume Escape; fail/ending prevent pause toggles.
- Diff whitespace check passes; tracked secret scan found no credentials/private keys; no tracked cache/log/tool/archive artifacts.
- `HEAD` and `origin/main` both equal `15e2e4ad20339fe125ca8f7884353a8fa36b3cfe` at review time.

## Adversarial Adjudication

| ID | Verdict | Release action |
|---|---|---|
| C1 corridor-padding pacing | ACCEPT | Block; replace empty travel with authored continuous beats and measure. |
| H1 weak/trivial puzzle gates | ACCEPT | Block; fix predicates, clues, feedback, idempotent ending. |
| H2 hallway transition/restore | ACCEPT | Block; discreet safe transition plus deterministic restore. |
| H3 enemy navigation/tuning | ACCEPT | Block; authored path/fallback, reachable FSM, fair pressure. |
| H4 audio/settings omissions | ACCEPT | Block; Phase 6 mandatory scope is not complete. |
| H5 non-production tests | ACCEPT | Block completion claim; add physics/public-path coverage and manual timing. |
| M1 dead objective input | ACCEPT | Fix before final UX sign-off. |
| M2 traversal evidence gap | ACCEPT | Verify before release; static geometry alone is insufficient. |

No finding is deferred: these are explicit acceptance criteria for a release candidate.

## Unresolved Questions

- No measured fresh playthrough establishes 15–20 minutes or proves the continuous route is engaging rather than padded.
- No manual run establishes open-door capsule traversal, Room 407 floor transition, darkness/readability, positional audio, or chase feel.
- Phase 6 remains marked completed although its mandatory checklist is mostly unchecked.

Status: DONE_WITH_CONCERNS
Summary: Blocker fixes resolve the old full-width walls, checkpoint objective/spawn, duplicate entity, modal locks, and leak warning. Release remains blocked because the one-scene game is still a long straight corridor padded by walking, with unproven 15–20 minute pacing and incomplete puzzles, hallway transitions, AI, audio/settings, and production-path QA.
Concerns/Blockers: C1 and H1–H5 require implementation and fresh automated/manual verification before Phase 7 or release can be marked complete.
