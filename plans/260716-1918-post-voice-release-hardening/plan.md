---
title: Post-voice release hardening
status: in-progress
priority: P1
branch: main
created: '2026-07-16T19:18:00+07:00'
source: ck:cook
---

# Post-voice release hardening

## Outcome

Close two remaining release-quality gaps without changing the continuous 15–20 minute route: prevent a rotating door from closing through the player, and give the chase entity a positional arrival cue that follows the source and survives checkpoint recovery correctly.

## Phase

- [Phase 1: interaction and chase audio hardening](./phase-01-interaction-and-chase-audio-hardening.md) — in progress

## Acceptance

- A nearby player inside the door sweep cannot start an open or close tween, mutate cooldown, consume a key, or lose the permanent unlock.
- Stepping outside the sweep permits the same door to close and reopen normally.
- A normal door tween holds only player movement, preserves mouse capture and camera input, and always releases its reason-scoped lock.
- Chase start and post-capture recovery each create one bounded SFX-routed spatial entity cue attached to the entity.
- Audio teardown removes spatial players and cache ownership without leaks.
- All 12 canonical Godot headless checks pass with no engine/script/parse/leak failures.
- Main plan and QA evidence describe the implemented 70-cue voice system and current pushed history truthfully.
- Changes land as focused Conventional Commits and push non-force to `origin/main` after disk, secret, diff, and repository checks.

## Constraints

- No Godot GUI or physical-input automation without renewed user authorization.
- Keep the one-scene continuous flow and existing progression contracts.
- Do not regenerate Piper assets or place build caches on C:.
- Manual 15–20 minute, visual, audible-mix, and chase-feel gates remain open until a captured physical playthrough exists.
