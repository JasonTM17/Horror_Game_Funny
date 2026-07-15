---
phase: 4
title: Memory Hallway and Radio Puzzle
status: completed
priority: P1
dependencies:
  - 3
effort: large
---

# Phase 4: Memory Hallway and Radio Puzzle

## Overview

Build the 4–5 minute distorted hallway loop, three memory pickups, note reader, `0007` radio puzzle with hint fallback, progressive horror events, and the guarded Room 407 entrance.

## Context Links

- [Plan](./plan.md)
- [Pacing and QA research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Three visually/audibly distinct hallway variants with concealed controlled transitions.
- Photo, cassette, and toy memories; each idempotent and persistent through checkpoints.
- Radio code puzzle with wrong/correct feedback, anti-spam cooldown, hint after three failures.
- Room 407 requires all memories and solved radio; later gates cannot be skipped.

## Architecture

`DynamicHallwayController` builds four visibility-switched variant roots under the continuous gameplay scene. `HallwayTransitionLayer` hides each swap/reposition behind an opaque blackout and serializes transitions. `StoryProgressionController` guards ordered memory flags; the radio owns a four-digit bounded input model and reports the solved sequence through the gameplay facade.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `scenes/levels/memory-hallway.tscn` | text scene | variant/load smoke |
| Create | `scripts/levels/{memory-hallway-controller,hallway-variant-builder}.gd` | <400 lines total | transition tests |
| Create | `scripts/inventory/memory-pickup.gd`, memory scenes/resources | <260 lines | idempotency tests |
| Create | `scripts/interaction/note-reader.gd`, `scenes/ui/note-reader.tscn` | <220 lines | input-lock tests |
| Create | `scripts/puzzles/radio-puzzle.gd`, `scenes/puzzles/radio-puzzle.tscn` | <260 lines | code/hint tests |
| Create | hallway-specific event nodes/materials/shader hooks | <400 lines | event tests |
| Modify | `GameState`, HUD, Floor4 exit, Room407 door config | <150 lines | progression gate |

## Function and Interface Checklist

- [x] Blackout transition serializes swaps and uses a fixed collision-safe memory marker.
- [x] Variant state derives from memory flags on checkpoint rebuild without replaying collected events.
- [x] Duplicate memory interaction is rejected without incrementing state.
- [x] Radio accepts digits only, requires four digits, preserves cooldown across close/reopen, and hints at three failures.
- [x] Room 407 progression requires all three memories and completed radio sequence.

## Dependency Map

`powered Floor4 -> hallway variants -> memory flags + note clue -> radio 0007 -> Room407 gate -> Phase 5`

## Implementation Steps

1. Build base hallway shell and three variant roots with distinct numbers, props, lights, and audio zones.
2. Implement sight-line-safe transition markers, re-arm guard, and recovery floor.
3. Add photo/cassette/toy pickups with story feedback and HUD indicators.
4. Add note/photo reader with reliable input lock release.
5. Implement radio digit UI, wrong/correct feedback, cooldown, hint, and protagonist recording subtitle.
6. Chain progressive off-screen/turn-away events through the director.
7. Gate Room 407 and verify every prerequisite/out-of-order case.
8. Run focused tests/timed playthrough and commit hallway then puzzle/memories separately.

## Atomic Commit Checkpoints

- `feat: build dynamic memory hallway progression`
- `feat: add memory pickups notes and radio puzzle`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Transition spam/turnaround | no double teleport or wall embed |
| Critical | Pick each memory twice | count remains three maximum |
| Critical | Try radio before memories | radio interaction remains unavailable; Room407 stays locked |
| High | Three wrong codes | bounded failures then readable hint |
| High | Close note via pause/interaction | input and mouse return exactly once |
| Medium | Loop timing and readability | 4–5 minutes; no route is pitch black |

## Success Criteria

- [x] Four hallway roots and an opaque transition implement three progressive memory changes.
- [ ] Manual visual pass confirms no obvious teleport artifact and readable variants.
- [x] Three memories and radio puzzle complete through guarded semantic progression with an environmental `00:07` clue.
- [x] Covered wrong-order, duplicate, cooldown, and checkpoint restoration cases preserve state.
- [x] Room 407 remains locked until the three-memory and radio prerequisites are true.
- [x] Automated checks pass.
- [ ] Manual timed memory-loop run confirms the 4–5 minute target.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Teleport visible | vestibule/door occlusion, matching transforms, fade only as fallback |
| Code clue too obscure | repeated 00:07 clock/photo/radio subtitle hint |
| Variant node cost | disable inactive roots and their lights/audio/process |

## Security and Licensing

All memories, notes, voice subtitles, materials, and props are authored for this project.

## Next Steps

- Phase 5 opens Room 407 and completes the failure/recovery/ending path.
