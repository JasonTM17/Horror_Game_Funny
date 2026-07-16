# Voice-over and Stability QA

Date: 2026-07-16 18:49 +07:00  
Branch: `main`  
Base: `abc258c` (`origin/main` before this delivery)

## Outcome

- Godot project-setting canonicalization is protected by a red/green editor
  rewrite regression and remains unchanged after the final editor import.
- All 20 production narrative groups resolve to 70 committed English OGG cues.
- Voice is SFX-routed, pause-aware, single-voice, exact-subtitle matched, and
  scene-local. Missing/malformed/mismatched audio falls back without blocking.
- External interaction feedback stops stale narration immediately. Queue
  duplicates, synchronous completion reentrancy, and teardown are serialized.
- Flashlight no longer has a random first-frame readability/test failure.

## Asset Evidence

| Check | Result |
|---|---:|
| Manifest cues / OGG / import sidecars | 70 / 70 / 70 |
| Missing / unexpected files | 0 / 0 |
| Unique Godot import UIDs | 70 |
| Decode/stream-contract failures | 0 |
| Encoding | Vorbis, mono, 22,050 Hz |
| Total OGG size | 1,598,336 bytes |
| Duration min / average / max | 0.811 / 3.343 / 4.920 seconds |
| Mean-volume range | -23.1 to -17.8 dB |
| Highest measured peak | -2.1 dB |

Generation used Piper TTS 1.4.2 with reviewed
`en_US-kristin-medium` model/config hashes. The script now takes an exclusive
build lock, preflights exact root paths, stages and probes the entire set before
publication, and rolls back a failed publish. Lock rejection and wrong-path
preflight were exercised without changing the published OGG hashes.

## Automated Verification

- Final `tests/run-headless-tests.ps1`: exit 0 in 41.9 seconds.
- Result: 12/12 named checks passed.
- Exact 12-log failure scan: 0 engine, script, parse, assertion, or leak hits.
- Final progression exercised 70 unique production cue/text contracts with 0
  manifest drift failures.
- Voice-enabled regression started a real imported cue, measured frozen
  playback position while paused, measured resume, and stopped on an external
  subtitle replacement.
- Five consecutive focused `checkpoint-layout` runs passed after the
  first-frame flashlight fix; focused player-input and settings-audio passed.
- `git diff --check`: clean.
- `project.godot` diff after editor import: empty.
- Runner-owned `godot-user-*` profiles left after teardown: 0.
- Untracked candidate scan: 0 model, WAV, executable, venv, secret, token, or
  credential candidates.

## Review Findings Resolved

- Random initial flashlight pulse made the layout gate approximately 12%
  flaky; runtime now schedules the first check and the layout asserts authored
  base energy.
- Freeing a sequencer mid-line left a stale global subtitle; exit now clears
  voice, queue, active state, and subtitle, with a beyond-timer regression.
- A synchronous `beat_finished` listener could race an older queued beat;
  `_running` now remains true through emission and the order is tested.
- Interaction feedback could replace subtitle text while old speech continued;
  ownership tracking now stops mismatched narration.
- Manifest parsing accepted weak schemas/paths; schema, ID, fields, role, exact
  path, and unique file contracts are enforced with malformed fixtures.
- Generator could publish a partial late-failure set or race another run;
  complete staging, rollback, and an exclusive process lock now guard it.

Independent standard and adversarial CK reviews report no remaining code
blocker after these fixes.

## Disk Evidence

- Before audio work: C approximately 5.91 GiB free; D 20.10 GiB free.
- Windows expanded `C:\pagefile.sys` to 19,683 MiB during concurrent review and
  Godot pressure, briefly reducing C to 0.71 GiB. No model/test temp targeted C.
- After heavy processes exited: C 3.13 GiB free; D 19.79 GiB free.
- Four ignored diagnostic profiles total 7,260 bytes. Reviewed Piper/model
  inputs remain intentionally under repository-local `.tmp` on D.

## Unresolved Manual Gates

- No authorized physical F5 keyboard/mouse boot-to-credits capture currently
  proves the 15–20 minute target.
- Headless decode/playback checks do not prove voice intelligibility,
  performance quality, or mix balance on a real audio device.
- Chase fairness, full-route collision feel, and rendered visual comfort still
  require the documented physical matrix.
