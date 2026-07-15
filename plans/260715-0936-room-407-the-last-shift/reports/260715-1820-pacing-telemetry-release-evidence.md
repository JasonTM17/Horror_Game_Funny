---
type: pacing-telemetry-release-evidence
date: 2026-07-15
branch: main
code_commit: fc8f7e70a4fa9fef61b07c6832650a615425a683
documentation_commit: 257e60171df7382b46fd139ba3d55645339014ce
status: in-progress
---

# Playthrough Pacing Telemetry Release Evidence

## Summary

The source release now measures a fresh, uninterrupted Lobby-to-visible-credits run and rejects resumed, incomplete, compressed, or out-of-order evidence appropriately. Code and evergreen documentation are pushed; automated regression and a clean-clone rehearsal are verified. Release closure remains open because no authorized physical F5 keyboard-and-mouse run proves the complete route, 15–20 minute active duration, chase feel, presentation, audio, or physical Settings workflow.

## Shipped Scope

- `fc8f7e7` adds scene-local, pause-aware telemetry; actual first-occurrence boundary order; five chapter durations; independent 900–1200 second total evaluation; visible-credits finalization; immutable deep-copy reporting; and one `PLAYTHROUGH_PACING: ` JSON line.
- Existing `progression` and `checkpoint-layout` checks cover fresh-run eligibility, resumed-run ineligibility, pause exclusion, actual order, null durations/verdicts, finalization, reset immutability, deep-copy isolation, production-threshold chase start, scheduled-physics proximity capture, and deliberate invalid-order rejection.
- `257e601` reconciles README, changelog, architecture, design, testing, and limitations without adding a thirteenth runner check or claiming physical verification.

## Verification Evidence

| Evidence | Result |
|---|---|
| Focused progression, repeated | 3/3 pass; active 3.66–3.67 s, wall 3.72–3.74 s, paused 0.06 s, complete/order-valid, target verdict false by design |
| Focused checkpoint/layout, repeated | 3/3 pass; resumed run incomplete/ineligible with null total verdict |
| Canonical local runner | 12/12 pass, exit 0; no final engine error or leak warning |
| Clean clone of `origin/main` | SHA `257e601`; 12 logs, 9/9 required markers, 0 bad log matches, 0 temporary Godot profiles, 0 tracked changes |
| Clean-clone fresh payload | active 3.65 s, wall 3.73 s, paused 0.06 s, all eight boundaries in actual order, complete true, target verdict false |
| Clean-clone resumed payload | active 4.19 s, wall 4.20 s, incomplete/ineligible, missing opening boundaries, total verdict null |
| Documentation | `git diff --check` pass; 61 internal links valid; no stale ten-check or 0.7-unit capture wording |
| Disk after rehearsal cleanup | C: 10.50 GiB free; D: 34.50 GiB free; rehearsal directory removed safely |

The docs validator also reported 96 generic code-reference and 34 generic config-key warnings. They are false positives from treating verified GDScript class names/constants as JavaScript symbols or `.env` keys; its internal-link check passed all 61 links.

## Review Findings Closed

1. Finalized reports no longer mutate after Replay/Main Menu-style state reset.
2. Completeness uses the actual observed boundary order rather than reconstructed canonical order.
3. The capture regression crosses the production chase threshold and waits scheduled physics frames with the navigation entity attached.
4. The pause regression proves a measurable monotonic interval while the scene tree remains paused.
5. Checkpoint teardown drains ending audio before shutdown, removing the discovered playback leak.

Independent adversarial re-review reported no remaining code findings after these fixes.

## Evidence Boundary

Automation proves instrumentation, guards, state lifecycle, selected production physics, import/load stability, and settings persistence across isolated processes. It does not deliver operating-system keyboard/mouse input, emulate a blind player, judge fear/readability/fairness, listen to the audio device, or prove 900–1200 seconds of real active play.

## Git State

- Branch: `main`.
- Remote: `https://github.com/JasonTM17/Horror_Game_Funny.git`.
- At report creation, local `HEAD` and `origin/main` match at `257e601`; this plan/journal/evidence synchronization is the next atomic documentation commit.
- Pushes remain non-force; no generated logs, caches, user profiles, credentials, or private files are staged.

## Next Required Validation

Run one fresh F5 blind keyboard-and-mouse session from boot to visible credits. Preserve the complete same-run capture and emitted JSON payload, fail/recover once during the chase, exercise Pause/Settings and relaunch persistence physically, and record visual/audio observations. Pacing passes only when the payload is eligible, complete, actual-order-valid, and its active total is 900–1200 seconds.

Computer Use must remain closed unless the user explicitly authorizes a new session.

## Recommendations

- Use the telemetry payload to tune chapter content, not forced waiting or separate levels.
- If a chapter misses its range, adjust observation density, route clarity, clue friction, or chase distance inside the same continuous scene, then rerun automation before the next physical capture.
- Do not mark Phases 7–8 or the active goal complete until the physical evidence exists.

## Unresolved Questions

- Who will perform and preserve the authorized physical blind-run evidence?
