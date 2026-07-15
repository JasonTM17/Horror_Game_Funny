# ROOM 407: THE LAST SHIFT — Game Design

## Core Fantasy

You are the only night worker inside a condemned apartment block. A routine call asks you to inspect Room 407, but the fourth floor remembers you better than you remember it.

The player is vulnerable, observant, and capable of escaping—not fighting. Fear comes from anticipation, spatial contradiction, sound outside the field of view, and familiar objects appearing where they should not.

## Player Experience Goals

- Finish a blind first playthrough in 15–20 minutes.
- Understand the main story without reading every optional note.
- Feel tension rise in distinct waves rather than through constant pursuit.
- Solve two readable environmental puzzles without brute-force frustration.
- Trust the game to restore a fair checkpoint after capture.
- Reach a clear ending that reframes the night shift.

## Story

At 23:47, a student covering a night shift at an old apartment block receives a call from the building manager. The manager asks for a check on Room 407, despite records showing that the fourth floor was sealed after a child disappeared years ago.

The building begins normally. On the fourth floor, clocks return to 00:07, room numbers reverse, a radio repeats the protagonist's voice, and a distant silhouette watches from the end of the corridor. Three objects—a burned family photograph, a cassette, and a red toy rabbit—reveal that the protagonist lived in Room 407 as a child.

Room 407 is a buried memory rather than an ordinary apartment. After recovering the last clue, the protagonist faces the entity and escapes a deforming corridor. The lobby outside is abandoned and decayed. There was no current night shift; the call was the memory drawing the protagonist back.

## Gameplay Loop

1. Explore a bounded area.
2. Read a clue or observe an environmental change.
3. Find a task item.
4. Use it at a guarded interaction point.
5. Trigger a one-shot horror event.
6. Observe a changed space.
7. Unlock the next area.
8. Survive the final chase.
9. Reach the ending and credits.

There is no combat. The final entity is the only sustained physical threat.

## Pacing

| Chapter | Target | Main beats |
|---|---:|---|
| Lobby at 23:47 | 2–3 min | movement, phone, duty log, fourth-floor key |
| Fourth-floor blackout | 3–4 min | fuse search, power restoration, door slam, silhouette |
| Distorted memory loop | 4–5 min | three variants, three memories, radio code |
| Room 407 | 3–4 min | impossible space, final clue, entity reveal |
| Chase and ending | 2–3 min | guided escape, capture recovery, reveal, credits |

A strong event is followed by 30–60 seconds of lower intensity. Walking distance never substitutes for authored content.

## Controls

- Move and look.
- Sprint.
- Interact and pick up task items.
- Toggle flashlight.
- Review current objective.
- Pause and adjust settings.

Crouch is deferred because no required puzzle or chase route depends on it.

## Level Progression

### Lobby

The desk, phone, logbook, and key teach interaction without a tutorial modal. The floor exit stays locked until the player answers the phone and takes the duty key.

### Fourth Floor

The hallway is dark but navigable. A maintenance clue points to a fuse in a drawer. Installing it restores selected lights, slams a door, and reveals a silhouette at a safe distance.

### Memory Hallway

Three variants reuse one structural shell:

- Intact corridor with correct numbering and cold fluorescent light.
- Reversed room numbers, moved props, and intermittent radio noise.
- Stained corridor, blocked side route, the toy in an impossible location, and red guidance light.

Transitions happen behind a closed sight line. Each pass adds a new story beat and a different form of scare.

### Room 407

The interior is larger than its exterior. A child-sized room, family evidence, and the final clue connect the protagonist to the disappearance. A quiet inspection window precedes the lighting failure and entity reveal.

### Chase and Ending

The player follows light and sound through a short distorted route. One false path is clearly dangerous rather than arbitrarily fatal. Capture returns to the chase checkpoint. The successful exit loads the abandoned-lobby reveal and credits.

## Puzzle Design

### Fuse Box

- Find one fuse using maintenance signage and an environmental light cue.
- Empty-box interaction gives useful feedback.
- Installation consumes the fuse exactly once.
- Power, objective, and the following event update atomically.

### Radio Code

- A clock and the photograph establish `00:07`.
- The radio accepts four bounded digits: `0007`.
- Wrong answers produce static and a short cooldown.
- Three failures unlock a subtitle hint about the stopped clock.
- The correct answer unlocks Room 407 only after all three memories are collected.

## Memory Items

| Item | Meaning | Progress effect |
|---|---|---|
| Burned photograph | The protagonist lived in 407 | reinforces the 00:07 clue |
| Cassette | The radio voice is the protagonist | changes radio playback |
| Red toy rabbit | The missing child identity | completes the room prerequisite |

Every pickup is idempotent and represented by a stable item ID rather than display text.

## Horror Principles

- Audio precedes visible threat.
- Silence is an authored event.
- Familiar props move when the player is not looking.
- A turn-away apparition occurs once.
- Lighting misdirects without making the route unreadable.
- Strong scares vary in form and never rely on repeated full-screen faces.
- Volume spikes, gore, and rapid flicker are avoided.

## Entity

Scripted apparitions handle most of the game. The chase entity uses dormant, appear, stalk, search, chase, lost-target, and despawn states. It cannot spawn within immediate capture range, chase outside its authored area, or remain duplicated after checkpoint reload.

## Failure and Recovery

Checkpoints exist before Room 407 and at chase start. Capture locks player input, stops chase audio, fades out, replaces the gameplay scene, restores serializable state, and spawns one entity. Persistent save across application restarts is outside the required scope.

## Accessibility

- Bounded mouse sensitivity and field of view.
- Master, music, SFX, and ambience volumes.
- Fullscreen/windowed mode.
- Toggles for head bob, camera shake, and film grain.
- Reduced flicker intensity.
- English subtitles for every important phone, radio, and story line.
- Interaction feedback that does not rely on color alone.

## Completion Definition

The game is complete only when a fresh run reaches ending and credits in the target duration, every mandatory gate resists out-of-order interaction, capture restores a valid checkpoint, and the final verification report records both automated and manual evidence.
