# Release Preflight - 2026-07-18

## Status

| Gate | Evidence | Result |
|---|---|---|
| Windows Godot suite | 12/12 canonical checks, 2026-07-18 | Pass |
| Linux container suite | GitHub Actions run `29622416345` on `963405a` | Pass |
| Voice resources | 76/76 OGG files decode; 264.59 s total; 0 invalid/silent outliers | Pass |
| Voice levels | mean range -23.1 to -17.8 dB; peak range -9.0 to -2.1 dB | Preflight pass; listening review open |
| Player-facing UI | F5 menu and Settings inspected non-headless; exact `ROOM 407: THE LAST SHIFT` title; no QA/debug copy | Pass |
| Documentation media | four 960x540 PNGs; one 640x360, 59-frame, 7.38 s GIF | Pass |
| Documentation links | README plus `docs/*.md`: 0 broken local links | Pass |
| Repository | `main`; correct `origin`; `HEAD == origin/main`; clean before report | Pass |
| Capacity | C: 11.61 GiB free; D: 23.36 GiB free | Sufficient for one controlled capture |

## Closed Plan Scope

- Terminal ending cannot be overwritten by capture recovery.
- Chase owns three navigation-safe alternating obstructions and red bypass cues.
- Two-step voiced epilogue gates visible credits.
- Focused/full regressions, documentation, reviewed staged media, atomic commits, push, and remote parity complete.

## Parent Goal Still Open

- Fresh physical F5 boot-to-credits traversal with keyboard and mouse.
- One same-run `PLAYTHROUGH_PACING` payload within 900-1200 active seconds and every chapter target.
- Human review of chase fairness, darkness/readability, scare timing, audible voice/effects balance, Settings/fullscreen, comfort toggles, and relaunch behavior.
- Same-run capture reference and completed review matrix.

Staged screenshots/GIF and decoded/loudness checks are not substitutes for physical traversal or perceptual review.

## Unresolved Questions

- Does a fresh human run land inside every chapter target without confusion or route stalls?
- Are voice, scare, ambience, chase, and ending levels balanced on the target speakers/headphones?
