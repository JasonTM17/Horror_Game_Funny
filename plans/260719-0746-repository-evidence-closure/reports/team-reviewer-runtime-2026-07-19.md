# Team reviewer-runtime — gameplay runtime release risks

Date: 2026-07-19  
Role: reviewer-runtime (read-only)  
Branch: main  
Scope: chase, horror scare lifecycle, progression, VO, settings, UI pause, ending/epilogue

## Scope

| Item | Detail |
|------|--------|
| Files | `scripts/world/chase-*.gd`, `horror-*.gd`, `gameplay-director.gd`, `story-progression-controller.gd`, `story-observation-controller.gd`, `ending-epilogue-controller.gd`, `narrative-sequencer.gd`, `turn-away-apparition.gd`, `scripts/autoload/*`, `scripts/audio/voice-over-player.gd`, `scripts/ui/{pause-menu,settings-panel,fail-overlay,ending-overlay,hallway-transition-layer,note-reader}.gd`, `scripts/player/*`, `scripts/interaction/door-interactable.gd`, related tests |
| Focus | Production control-flow / race / teardown / softlock / fairness risks that can pass headless CI |
| Dirty tree | Current slice is verification-heavy (docs/tests). This review still flags latent ship-stoppers in shipped runtime code. |
| Not in scope | Docker/Hub publish, export packaging, security supply-chain (other reviewers) |

## Overall assessment

Chase recovery vs terminal ending, scare ownership/teardown, narrative pause-safety, and epilogue gating are **structurally sound** and covered by headless progression/checkpoint tests. No **CRITICAL** control-flow crash or hard softlock was proven in the reviewed paths.

Remaining risk is concentrated in **chase pressure after DESPAWN**, **nav fallback fairness**, **pause vs one-shot scare audio desync**, and **physical-only feel** (barrier lanes, capture distance, VO mix, corridor dim after chase). Those will not fully surface under headless verification.

## Critical issues

_None proven._ Terminal capture/ending overlap is explicitly guarded and regression-covered:

- `chase-sequence-controller.gd:46-50` — `request_failure()` early-outs on `ending` / `recovering`
- `chase-sequence-controller.gd:52-66` / `80-104` — `finish()` cancels recovery; recovery aborts if `ending` after the fail delay
- `tests/progression-test.gd:397-438` — recovery-in-flight then exit → ending stage, no entity restart, fail lock cleared

## High priority

### [IMPORTANT] Chase DESPAWN ends pursuit permanently until capture (pressure hole)

**Evidence**

- `chase-entity.gd:109-116` — after `max_search_cycles`, transitions to `DESPAWN`
- `chase-entity.gd:196-199` — DESPAWN sets `active=false`, `visible=false`, zeros velocity
- `chase-entity.gd:186` — DESPAWN has no outgoing transitions except forced restart via `start_chase()`
- Production restart paths: `chase-sequence-controller.gd:40` (first start) and `:101` (capture recovery only)
- Architecture acknowledges bounded DESPAWN (`docs/architecture.md:178`)

**Impact**

A player who breaks LOS long enough (~`lost_target_duration` + `search_duration * max_search_cycles`, default ~1.6 + 2.4×2 ≈ 6.4s) permanently removes chase pressure for the rest of the corridor. Headless tests treat DESPAWN as success (`checkpoint-layout-test.gd:247-251`) and only re-arm via explicit `start_chase()`, which production never does after voluntary DESPAWN.

**Fix options**

1. After DESPAWN, schedule a re-`APPEAR` near last-seen / ahead of player while `chase_started && !ending`
2. Or treat DESPAWN as “lost” only until player re-enters detection range (auto `start_chase` when distance ≤ range and stage is CHASE)
3. If intentional “lose them” win condition: document in design and accept reduced climax pressure

### [IMPORTANT] Navigation fallback + `Vector3.ZERO` path sentinel can steer through geometry

**Evidence**

- `chase-entity.gd:137-149` — if `_navigation_ready()` is false, uses raw destination vector (no wall avoidance)
- `chase-entity.gd:141-143` — `get_next_path_position()` ignored when equal to `Vector3.ZERO`
- `chase-entity.gd:157-161` — nav ready requires valid map + `map_get_iteration_id > 0`
- Entity `collision_mask = 1` (`chase-sequence-controller.gd:35`) collides with world but capture is pure distance (`chase-entity.gd:79-80`), not blocked by player layer 2

**Impact**

Brief pre-map frames or a failed agent path can move the entity on a straight line through barriers. Capture still fires at 1.25 units regardless of obstruction. Fairness fails as “clipped through wall and grabbed me” rather than navigation-aware pursuit. Headless barrier traversal injects positions and measures one obstruction (`checkpoint-layout-test.gd:190-200`); it does not prove multi-barrier human routes under load.

**Fix**

- Drop the `!= Vector3.ZERO` check; use agent distance/path status APIs
- If map not ready: hold velocity at zero (extend APPEAR) instead of direct steer
- Optionally exclude capture while `not _navigation_ready()`

### [IMPORTANT] Horror scare waits pause-freeze; scare one-shots keep mixing

**Evidence**

- `horror-scare-sequence.gd:16-17` — `create_timer(..., false)` → `process_always=false` (pauses with tree)
- Scare audio via `AudioManager.play_spatial_tone` / `play_tone` — no `stream_paused` on pause
- Narrative VO is `PROCESS_MODE_PAUSABLE` and regression asserts freeze (`tests/voice-over-regression.gd:124-130`) — different path from scare SFX
- Progression tests freeze scare **state** on pause (`progression-test.gd:130-134`, `158-161`) but do not assert scare **audio** position freeze

**Impact**

Pause mid-scare: silhouette/wait clock freeze, spatial sting may finish under pause. On resume, remaining wait still elapses against silence → timing/reveal desync, especially on longer beats (room entity ~1s post-reveal wait).

**Fix**

On tree pause notification (director or AudioManager): pause/resume active spatial players and one-shot players owned by scare cue IDs; or drive scare audio lifetimes from the same pausable timers as `wait()`.

### [IMPORTANT] Observation / echo sets `*_started` before `play()` success

**Evidence**

- `story-observation-controller.gd:131-137` — sets `id + "_started"` then calls `_narrative.play(...)` and always returns `true`
- `story-observation-controller.gd:127-129` — same for `memory_echo_*_started`
- `narrative-sequencer.gd:22-27` — `play()` can return `false` (flag active, empty lines, already queued)

**Impact**

If `play()` rejects after `*_started` is committed, completion flags never set and prompts stay blocked (`get_prompt` / `_observation_finished` / `memory_echo_ready`). Normal sequential play avoids this; it is a latent softlock under re-entrancy, interrupted queue, or future concurrent callers.

**Fix**

```gdscript
if not _narrative.play(lines, completion_flag, seconds_per_line):
    GameState.set_flag(id + "_started", false)  # or only set started after play() true
    return false
```

## Medium priority

### [MODERATE] Floor-arrival door slam ignores sweep / movement lock

**Evidence**

- `horror-event-director.gd:44-46` — `floor_door.close_for_event()`
- `door-interactable.gd:45-51` — event close sets `_moving` and tweens without `_actor_blocks_motion` or `_lock_actor_movement`
- Player interact path does block when inside `motion_sweep_radius` (`door-interactable.gd:28-30`)

**Impact**

If the player stands in the doorway when floor scare fires, the door rotates closed through the capsule. Possible sticky collision or visual clip. Physical-only residual.

### [MODERATE] Corridor lights permanently scaled on chase start

**Evidence**

- `chase-sequence-controller.gd:130-133` — `light_energy *= 0.08` for `CorridorLight*`
- No restore on `finish()`, recovery, or ending
- Ending adds new reveal lights (`ending-epilogue-controller.gd:106-111`) but leaves corridor pools dim

**Impact**

Intentional mood for chase; residual risk that post-chase epilogue walk-back is near-black except task/reveal lights. Physical readability check still required (PDR-07).

### [MODERATE] Scare light snapshots are per-sequence, not global

**Evidence**

- `horror-scare-sequence.gd:51-62` — first `set_light` snapshots **current** energy/color
- Concurrent sequences on the same `OmniLight3D` would nest factors; restore order can leave intermediate dim

**Impact**

Current story beats are largely serial + one-shot (`mark_event_complete`), so production risk is low today. Latent if future content overlaps scares.

### [MODERATE] Fail recovery ignores `restore_checkpoint()` return

**Evidence**

- `chase-sequence-controller.gd:93-104` — always repositions player and restarts entity after await
- `game-state.gd:116-118` — empty checkpoint returns `false` without mutating state

**Impact**

Only matters if `chase_ready` checkpoint was cleared mid-run (no production path does this). Would restart chase with inconsistent flags/stage.

### [MODERATE] Checkpoint is process-memory only

**Evidence**

- `game-state.gd:104-114` — in-memory dict only
- `docs/architecture.md:188` — Continue disappears after application restart
- Boot Continue visibility: `boot-menu.gd:59`

**Impact**

Not a runtime bug; ship expectation must not claim durable save. Capture recovery within session is fine.

### [MODERATE] Voice bus volume is hard-tied to SFX

**Evidence**

- `settings-manager.gd:41-45` — `set_sfx_volume` also sets `AudioManager.VOICE_BUS_NAME`
- Ducking: compressor on SFX sidechains Voice (`audio-manager.gd:32-46`)

**Impact**

By design (one dialogue/effects fader). Residual: players cannot lower stings without lowering VO, or vice versa. Not a functional break.

## Low priority

### [MODERATE→Low] Headless skips ambience/chase drones

**Evidence**

- `audio-manager.gd:90-92` — `start_drone` no-ops when `DisplayServer.get_name() == "headless"`

**Impact**

Headless cannot prove chase bus balance / drone continuity after recovery. Physical-only residual for mix.

### [Low] STALK allow-list includes SEARCH but `_advance_state` never uses it

**Evidence**

- `chase-entity.gd:182` vs `98-100`

Dead transition entry only; no player impact.

### [Low] Hallway `reconfigure_for_memory` 1.5s cooldown

**Evidence**

- `dynamic-hallway-controller.gd:23-27`

Normal loop timing (~4s blackout) clears cooldown. Rapid forced reconfigure could skip a variant once.

## Edge cases (scout)

| Area | Edge | Verdict |
|------|------|---------|
| Chase | Capture during recovery | Guarded by `recovering` |
| Chase | Capture during ending | Guarded by `ending`; tested |
| Chase | Retreat `z > CHASE_TRIGGER_Z + 25` | Triggers recovery (`chase-entity.gd:62-66`) |
| Chase | Near exit `z < EXIT_Z - 8` | Entity self-DESPAWN (`:67-69`) |
| Chase | DESPAWN then free walk | **Pressure hole** (IMPORTANT) |
| Scare | Pause mid-wait | Visual/state freezes; audio may not |
| Scare | Director `queue_free` | `_exit_tree` cancels sequences, restores lights (`horror-event-director.gd:181-185`, tested) |
| Scare | Cassette narration end | `finish_sequence("CassetteTurnAwayScare")` (`story-progression-controller.gd:266-268`) |
| Progression | Memory order | Hard-gated by `loop_iteration` |
| Progression | Room final clue | Needs all three room observations |
| Progression | Exit interact | Requires full `_ending_ready()` flag set |
| VO | Manifest mismatch | Falls back to tick; contract failures collected, progression asserts 76 cues |
| VO | Subtitle steal mid-line | `_on_subtitle_changed` stops cue (`narrative-sequencer.gd:87-89`) |
| Settings | Save fail | Modal stays open; retry/discard (`settings-panel.gd:34-41`, `82-100`) |
| Pause | During fail/note/radio/ending | Blocked (`player-controller.gd:40-42`) |
| Pause | During hallway lock | Allowed; transition timers pausable |
| Epilogue | Notice before roster | Prompt/action gated (`ending-epilogue-controller.gd:52-56`) |
| Epilogue | Credits once | `_credits_visible` / `_credits_requested` |
| Continue | `chase_start` spawn | Player at `CHASE_RESPAWN_Z`; process re-starts chase (`gameplay-director.gd:100-101`, `108-109`) |

## Positive observations (risk calibration only)

- Scare ownership model (cue IDs, owned nodes, light snapshots, cancel/finish/`_exit_tree`) is coherent and regression-backed.
- Capture recovery reuses one entity; no duplicate `TheEntity` path under normal recovery.
- Input-lock composition covers fail/ending/note/radio/settings/pause with explicit pause denial on modal reasons.
- Settings load order: AudioManager creates buses before SettingsManager applies volumes (`project.godot` autoload order).
- Epilogue does not mutate chase checkpoint (tested deep-copy isolation).

## Headless vs physical residual

| Covered headless | Still physical-only |
|------------------|---------------------|
| Progression flag order, radio UI, note→chase_ready | Full corridor walk timing / getting lost |
| Scare pause freeze, light restore, one-shot spam | Scare audio-under-pause, perceived jump scare timing |
| Capture proximity recovery, ending race | Multi-barrier chase feel, sprint fairness, DESPAWN exploit |
| Nav segment existence + one barrier entity path | Human readability of bypass cues under fog/dim |
| VO manifest contract (76 lines) | Mix, ducking under real VO files, device latency |
| Settings clamp/save/load, pause modal focus | Fullscreen toggle UX, dirty save disk full on target SKU |

**PDR-07 / human F5 remains open.** Headless green does not close chase fairness or perception.

## Recommended actions (priority)

1. Decide DESPAWN policy: re-engage vs documented lose-condition; implement re-arm if climax pressure is required.
2. Harden chase movement: no direct-steer before nav ready; replace `Vector3.ZERO` path check.
3. Pause-sync scare SFX (or document as accepted desync).
4. Set observation `*_started` only after `play()` returns true.
5. Keep physical playthrough checklist: fail once, pause mid-scare, hide until DESPAWN, all three barriers, epilogue in dim corridor, settings save/retry.

## Metrics (qualitative)

| Metric | Notes |
|--------|-------|
| Type coverage | GDScript; no TS metrics |
| Test coverage | Strong semantic/path tests for chase recovery, scare teardown, VO contract, settings; weak on DESPAWN re-pressure and scare-audio-under-pause |
| Linting | Not re-run in this review (tester owns suite) |

## Unresolved questions

1. Is permanent post-DESPAWN freedom an intentional “hide to survive” design or an unfinished re-aggro loop?
2. Should corridor light dim restore after ending success for epilogue readability?
3. Is independent Voice volume out of scope for 1.0?

---

Status: DONE  
Summary: No CRITICAL runtime ship-stopper proven; chase DESPAWN pressure hole, nav fallback fairness, scare-audio pause desync, and observation `*_started` before `play()` are the main latent risks. Terminal ending/recovery and scare light/actor teardown look solid and test-backed.  
Concerns/Blockers: Physical F5 still required for chase fairness and audio/perception. Do not treat headless 12/12 as proof DESPAWN cannot trivialize the climax.
