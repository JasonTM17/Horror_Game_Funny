---
type: researcher
date: 2026-07-15
---

# Research Report: Pacing, Content, and Progression QA

## Summary

Use five authored chapters with explicit completion gates and recovery paths. Reuse one modular hallway shell across controlled variants, but change landmarks, audio direction, lighting, and prop silhouettes enough that each pass communicates a new story beat. The design reaches 15–20 minutes through observation and interaction density, not long walking distances or text walls.

## Player Journey

| Chapter | Target | Required beats | Exit gate |
|---|---:|---|---|
| Lobby: 23:47 | 2–3 min | learn movement/interact; answer phone; read duty log; take fourth-floor key | phone answered + key held |
| Floor 4 blackout | 3–4 min | find fuse; restore power; see door slam and distant silhouette | fuse installed |
| Memory loop | 4–5 min | traverse three variants; collect photo, tape, toy; solve radio/code clue | three memories + puzzle solved |
| Room 407 | 3–4 min | open gate; inspect impossible room; reveal childhood link; activate entity | final clue inspected |
| Chase and ending | 2–3 min | follow light/audio route; survive or restart checkpoint; reach lobby reveal | exit trigger while chase complete |

Expected first playthrough: 16–18 minutes. A knowledgeable replay may be shorter; the game must not add artificial waits to enforce duration.

## Horror Rhythm

1. Establish mundane space and controls with no threat.
2. Use off-screen audio before the first visible anomaly.
3. Door slam after fuse installation: strong but non-damaging event.
4. Silhouette appears briefly at long distance, then is gone when occluded.
5. First loop changes room numbers and one familiar prop.
6. Second loop plays the protagonist's voice through radio and moves a childhood toy.
7. Third loop uses a turn-away event and silence before Room 407.
8. Room reveal gives a quiet inspection window before lighting failure.
9. Chase is the only sustained threat.
10. Ending releases tension, then reframes the entire shift.

Keep at least 30–60 seconds of lower intensity after each strong event. Never use a full-screen face or uncontrolled volume spike.

## Puzzle Design

### Fuse Box

- Fuse lies in a maintenance drawer signposted by an unpowered lamp and duty note.
- Empty box interaction updates feedback without consuming anything.
- Installing the fuse consumes `fuse`, sets `fuse_installed`, changes objective, powers selected lights, then fires one event.
- Re-interaction returns “Power is already restored.”

### Radio Frequency / Room Code

- Photo back shows `00:07`; room labels establish that the four digits matter.
- Radio has four bounded digit inputs rather than an unbounded tuning simulation.
- Wrong submission gives static and temporarily locks input for one second.
- After three wrong submissions, an environmental subtitle hints that “the clock never moves past midnight.”
- Correct `0007` sets `radio_solved`, plays the protagonist recording, and unlocks Room 407 only when all memories exist.

This prevents brute-force spam while preserving a non-soft-lock hint path.

## Memory Items

| Item | Story information | Gameplay consequence |
|---|---|---|
| Burned family photo | protagonist lived in 407 | supplies clock/code clue |
| Cassette | voice is the protagonist's forgotten recording | changes radio event and ambience |
| Red toy rabbit | missing child identity | completes the room lock prerequisite |

Each pickup must be idempotent, update the compact HUD, advance the objective only when appropriate, and remain collected across checkpoint reload.

## Dynamic Hallway Strategy

Use three variants under one controller:

- Variant A: intact, cold fluorescent lights, correct numbering.
- Variant B: reversed numbering, moved wheelchair/boxes, intermittent radio.
- Variant C: stained walls, blocked side door, toy at impossible location, red guidance light.

A transition vestibule closes sight lines before repositioning the player. Teleport to a named marker, preserve normalized movement intent, reset camera pitch only if collision safety requires it, and wait for the body to leave the trigger before re-enabling transition. A fallback floor collider and recovery Area3D return the player to the latest safe marker.

## Chase Design

- Checkpoint saves immediately before the final clue and again on chase start.
- Entity spawns behind a blocked sight line, never within immediate capture radius.
- Route has two turns and one blocked false path marked by flickering red light.
- Enemy speed exceeds walk but is below sprint; brief catch-up only when far away.
- Pausing stops gameplay and audio transitions consistently.
- Capture disables player, stops chase ambience, fades, replaces the scene, restores checkpoint, and spawns exactly one enemy.
- Ending trigger rejects entry unless `chase_started` and all prerequisite flags are true.

## Accessibility and Comfort

- Bounded mouse sensitivity and FOV.
- Master, music, SFX, and ambience buses.
- Toggles for head bob, camera shake, grain; reduced flicker scalar.
- Important phone/radio/entity speech always has subtitles.
- Interaction prompt uses a stable center location and never relies on color alone.
- Darkness preserves a visible route without forcing the flashlight on permanently.

## Red-Team Matrix

| Attack | Expected invariant |
|---|---|
| Pick item twice | inventory count and flags unchanged after first pickup |
| Install fuse before pickup | no progression; clear feedback |
| Submit radio code early | feedback only; Room 407 remains locked |
| Trigger events out of order | prerequisite guard rejects them |
| Enter transition repeatedly | one teleport per exit/re-entry cycle |
| Spam door interaction | one tween; collision state stays coherent |
| Pause during chase | no state advancement or duplicate audio |
| Die on checkpoint frame | one authoritative snapshot; one reload |
| Reload chase repeatedly | one enemy and one ambience loop |
| Skip mandatory trigger | later gate remains closed and objective points back |
| Reach ending collision early | trigger rejects incomplete progression |
| Fall from level | recover at safe marker, not full restart |

## Content Budget

- Eight major scenes and roughly ten reusable interactable/system scenes.
- Three hallway variants, not a procedural maze.
- One silhouette mesh and one chase enemy representation.
- Four to six short notes/subtitles; no voiced external assets required.
- Runtime-generated tones/noise and procedural materials avoid binary size and licensing risk.
- One lightweight visual shader and low-poly geometry keep imports small.

## Success Metrics

- Fresh blind playthrough median target: 15–20 minutes.
- Main progression completable without debug commands.
- Zero known main-path soft-locks after adversarial checklist.
- Every required clue has both visual and subtitle/text support.
- Restart from chase checkpoint returns control in under five seconds on target hardware.
- All event and pickup IDs execute at most once unless explicitly repeatable.

## Sources

- Product requirements and pacing: user-provided Room 407 brief.
- Renderer constraints: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Godot command-line test capability: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html

## Unresolved Questions

- None. Optional secondary ending and crouch are deferred to protect the required main path.
