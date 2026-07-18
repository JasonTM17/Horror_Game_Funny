# Source polish landing — 2026-07-18

> **Historical source-polish checkpoint — superseded.** This report records the
> `89042b5` landing only. Its Phase 6-open statements were superseded by the
> completed automated export gate; use
> [final-automated-audit-2026-07-18.md](./final-automated-audit-2026-07-18.md)
> for the current automated boundary. Phase 5 / PDR-07 remains open.

## Landed revisions

| Commit | Summary |
|---|---|
| `2ecf78a` | `feat: polish horror release candidate` — scare anchors, chase visual builder, audio ducking polish, settings UX, regression coverage, RC plan scaffold |
| `89042b5` | `fix(input): dual physical and logical key bindings for WASD/E` — InputMap physical_keycode + keycode; player-input dual-binding assertions |

Author: Nguyen Son \<jasonbmt06@gmail.com\>. No AI co-author trailers.

## Automated proof on tip `89042b5`

| Check | Result |
|---|---|
| `tests/verify-docker-packaging.ps1` | `DOCKER_PACKAGING_VERIFY_OK`, EXIT=0 |
| Host 12-check suite (`run-headless-tests.ps1`, Godot 4.7.1 console) | **12/12 OK**, EXIT=0, ~73.7s |

Required markers observed: `PROJECT_SETTINGS_STABILITY_OK`, `GAME_STATE_TEST_OK`, `PROGRESSION_TEST_OK`, `CHECKPOINT_LAYOUT_TEST_OK`, `PHYSICAL_ROUTE_SMOKE_TEST_OK`, `PLAYER_INPUT_INTEGRATION_TEST_OK`, `VISUAL_EFFECTS_TEST_OK`, `SETTINGS_AUDIO_TEST_OK`, `SETTINGS_PERSISTENCE_WRITE_OK`, `SETTINGS_PERSISTENCE_READ_OK`.

Phase 4 remains **Completed** as the automated evidence gate for source polish.
Earlier Phase 4 report used dirty `afe9a62` + WIP; tip re-verification on `89042b5` is the delivery baseline.

## Honest open gates (unchanged)

| Gate | Plan | Status | Why still open |
|---|---|---|---|
| Physical F5 boot-to-credits + pacing | Phase 5 / PDR-07 | **Open** | No same-run capture/log/`PLAYTHROUGH_PACING` on this tip |
| Windows x86_64 export smoke | Phase 6 | **Open** | No `export_presets.cfg`, no template export, no `.exe` menu launch |

Do **not** mark Phase 5, Phase 6, PDR-07, or parent plan `completed` until those artifacts exist.

## Parent plan status after this landing

- Plan `status`: remains `in-progress`
- Phases 1–4: Completed
- Phase 5: In progress (blocked on human/OS physical package)
- Phase 6: Pending (blocked on export templates + smoke)

## Non-claims

- Not release-certified
- Not a human blind playtest
- Staged visual-capture media is documentation-only
