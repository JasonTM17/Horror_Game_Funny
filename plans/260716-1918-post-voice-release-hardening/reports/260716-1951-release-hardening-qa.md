---
title: Post-voice release hardening QA
date: '2026-07-16T19:51:00+07:00'
status: passed-headless-manual-gates-open
godot: 4.7.1.stable.official.a13da4feb
---

# Post-voice release hardening QA

## Scope

- Prevent the centered rotating door panel from sweeping through the player.
- Add a bounded positional presence cue to the production chase entity.
- Reconcile voice-over evidence and the active completion plan.
- Preserve the uninterrupted one-scene route and existing progression state.

## Evidence-led findings

### Door sweep

The production door is a centered `2.2 × 0.2 m` rotating `StaticBody3D`; the player capsule radius is `0.34 m`. The horizontal swept clearance is approximately `sqrt(1.1² + 0.1²) + 0.34 = 1.445 m`. The implemented `1.5 m` radius leaves about `0.055 m` margin.

The first implementation checked only the start position. Standard review correctly rejected that as incomplete because the player could move about one metre during the `0.55 s` tween. The final implementation:

- blocks both unsafe opening and unsafe closing before key, cooldown, signal, or tween mutation;
- reports that the player must move clear;
- uses a unique, composable movement-only lock during a valid tween;
- preserves camera, flashlight, pause, and full-input lock behavior;
- releases its own movement lock on tween completion and door teardown;
- leaves the actor-less scripted floor-door slam unchanged because its only caller fires after the player crosses a trigger ten metres away.

### Chase presence cue

The chase previously had a global alarm and drone but no cue attached to the moving entity. The final controller attaches one `92 Hz`, `1.4 s` SFX cue to the entity on start and checkpoint recovery. It stops the stable cue ID before replay, failure, and ending, so no same-ID spatial players or cache ownership overlap.

## Failed checks that improved the fixtures

Two failures were investigated rather than hidden:

1. The first full run stopped at `PHYSICAL_ROUTE_ASSERT: floor_door did not consume its one-shot key`. The fixture had driven the capsule into the locked panel and then called `interact()` directly from inside the new sweep. It now steps back to the authored ray-interaction distance before the valid unlock.
2. The second full run stopped because the new test looked up a dynamically-created collider by the fragile name `CollisionShape3D`. Godot gives that child an internal generated name. The test now locates the production collider by `CollisionShape3D` type and validates its `BoxShape3D` contract.

Focused reruns then passed for physical route and production player input.

## Final canonical suite

Command:

```powershell
& .\tests\run-headless-tests.ps1
```

Final result on the modified runtime:

- exit: `0`
- elapsed: `60.3 s`
- canonical checks/logs: `12/12`
- required success markers: `10/10`
- scanned engine/script/parse/leak/warning lines: `0`
- remaining `godot-user-*` test profiles: `0`
- compressed production progression: complete, exact boundary order, `within_target: false` as required for automation

The regression additions exercise real production E input, held movement during a door tween, unsafe open/close, safe reopen, permanent key state, real chase-controller start, entity-parented SFX routing, recovery replacement, ending cleanup, and audio cache ownership.

## Voice asset media scan

FFprobe/FFmpeg inspected every committed OGG without rewriting assets:

| Metric | Result |
|---|---:|
| Files | 70 |
| Codec / format | Vorbis, 22.05 kHz, mono |
| Total duration | 233.99 s |
| Per-cue duration | 0.81–4.92 s |
| Mean volume range | −23.1 to −17.8 dB |
| Peak range | −9.0 to −2.1 dB |
| Invalid, near-silent, or clipping outliers under the scan thresholds | 0 |
| Total committed OGG size | 1.52 MiB |

This proves decodability and sane signal levels, not acting quality, intelligibility on speakers, or the in-game mix.

## Review

- CK debugger confirmed the door geometry, symmetric open/close hazard, cache ordering, and final contracts.
- Standard review found one Medium start-only sweep gap; it was fixed with the movement-only lock and a held-input regression.
- Adversarial review after the fix reported no Critical, High, Medium, or Low findings.
- Secret-like diff hits: `0`; tracked generated/cache paths: `0`; tracked files over `10 MiB`: `0`.

## Disk and process hygiene

- Work stayed on D:; Piper assets were not regenerated.
- D: remained above `26 GiB` free after the final suite.
- C: fluctuated from `11.82 GiB` to `2.34 GiB` as the Windows pagefile expanded to roughly `6.9 GiB` current use. No project output was redirected to C:.
- Twenty-seven parentless, read-only `git status`/`rev-parse`/`remote -v`/config processes were stopped after their parent processes had exited. No write-capable Git operation was interrupted.

## Gates still open

- No authorized physical keyboard/mouse boot-menu-to-credits capture exists.
- A real 900–1200 second eligible pacing payload is still missing.
- Audible voice/mix quality, rendered darkness/effects, door feel, and chase fairness remain manually unverified.
- Therefore this QA slice may pass and ship while Phase 7/8 and the overall game goal remain open.

## Unresolved questions

None for the implemented slice. Overall release completion still depends on the physical playthrough evidence above.
