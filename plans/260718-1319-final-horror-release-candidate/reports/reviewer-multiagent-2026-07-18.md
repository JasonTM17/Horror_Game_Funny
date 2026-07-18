## Code Review Summary

**Reviewer:** code-reviewer (adversarial / production-readiness)  
**Date:** 2026-07-18  
**HEAD reviewed:** `39b22c3` (expected tip on `main`)  
**Scope commits:** `2ecf78a` → `89042b5` → `298467b` → `821ef26` → `39b22c3`  
**Plan:** `plans/260718-1319-final-horror-release-candidate`  
**Mode:** read-only production code; report write only

### Scope
- Files inspected:  
  `project.godot`, `scripts/world/horror-event-director.gd`, `horror-scare-sequence.gd`, `horror-apparition-factory.gd`, `story-prop-visual-builder.gd`, `level-geometry.gd`, `continuous-story-layout.gd`, `world-layout.gd`, `gameplay-director.gd`, `chase-entity.gd`, `chase-entity-visual-builder.gd`, `scripts/ui/boot-menu.gd`, `scripts/autoload/audio-manager.gd`, `settings-manager.gd`, `scripts/player/player-controller.gd`, `scenes/player/player.tscn`,  
  `tests/progression-test.gd`, `player-input-integration-test.gd`, `menu-settings-regression.gd`, `settings-audio-test.gd`,  
  plan/PDR/README/limitations/testing/architecture/asset-credits/CHANGELOG, prior reports (`reviewer-ck-finalize`, `source-polish-landing`, `final-automated-audit`, `tester-multiagent`, `docs-truthfulness`, export readiness)
- LOC: multi-commit RC polish surface (scare/input/textures/docs)
- Focus: Critical/High production breakers + dishonest Phase 5/6/PDR-07 claims + missing contract tests
- Scout findings: scare 18 m envelope + chapter fallbacks, dual physical-only/logical-only InputMap, room-drawing quad facing, menu/prop preload, settings voice=SFX mirror, Phase 5/6/export still open

### Overall Assessment

Tip source polish is **production-usable for automated contracts** and **honest about unfinished release gates**. Prior Highs from the mid-polish review are largely addressed in `821ef26` (scare fallback Z anchors, dual-event InputMap assertions, Room eye energy constant + tests). Menu/story still textures preload from committed assets and are asserted non-null in progression/menu regressions. Host 12/12 + packaging green is independently recorded on tip `39b22c3` by the tester multiagent report.

**No Critical trust-boundary, crash, or release-gate lie found.** Residual Highs are (1) room-drawing texture facing that can hide the new still on the main approach, and (2) missing regression for the player-less scare fallback contract that `821ef26` claimed to pin.

**Do not close Phase 5, Phase 6, or PDR-07.** Parent plan must stay `in-progress`.

---

### Critical Issues

*None.*

Gates that would block full RC Outcome (physical F5 same-run package, Windows export smoke) are correctly **still open** and evidenced as incomplete (no `export_presets.cfg`, templates not installed per export-readiness scout; no PDR-07 capture/log/pacing package on tip).

---

### High Priority

#### H1 — Room-drawing textured quad faces the wrong corridor approach (new art can be invisible)
- **Where:**  
  [`story-prop-visual-builder.gd`](../../../scripts/world/story-prop-visual-builder.gd) `_build_paper_clue` for `room_drawing`:  
  vertical paper + `_add_textured_quad(..., position=(0,0,0.027), rotation=Vector3.ZERO)`.  
  Prop at [`continuous-story-layout.gd`](../../../scripts/world/continuous-story-layout.gd) `(2.4, 0.6, ROOM_DRAWING_Z=-430)`.  
  [`LevelGeometry.textured_material`](../../../scripts/world/level-geometry.gd) does not disable cull; QuadMesh faces **+Z**.
- **Impact:** Main route walks **−Z**. Player approaches drawing from more-positive Z looking −Z and sees the **back** of a single-sided quad → texture culled. Labels still read (`Label3D` + `no_depth_test`), so progression/interaction tests stay green while the new still fails its product job. Horizontal photo/table quads (rotated −π/2 about X) face +Y and are OK; **menu TextureRect is OK**.
- **Required fix (pick one):**  
  1. Face the drawing toward approach: e.g. `rotation = Vector3(0, PI, 0)` and offset on −Z, **or**  
  2. `material.cull_mode = BaseMaterial3D.CULL_DISABLED` for story stills, **or**  
  3. Re-orient the whole vertical prop so the image faces corridor center (−X) if that is the intended wall.  
  Add a test that asserts basis/forward (or both-sided cull) for `RoomDrawingImage`, not only `albedo_texture != null`.

#### H2 — Scare chapter-fallback contract is production-fixed but untested
- **Where:**  
  [`horror-event-director.gd`](../../../scripts/world/horror-event-director.gd) `_scare_position_ahead(..., fallback_z)`  
  Rabbit: `MEMORY_RABBIT_Z - 10.0`; Room: `FINAL_CLUE_Z - 9.0`.  
  Grep of `tests/`: **no** assertion that clears/nulls `_player` and expects those Z anchors.
- **Impact:** Happy-path progression always has a valid player (`GameplayDirector._ready` calls `set_player` before story). The exact defect class fixed in `821ef26` (silent lobby/floor-threshold spawn when player unbound) can regress without failing CI. Comment claims checkpoint-restore race; current spawn order makes that rare, but the fallback is now a public safety contract without a pin.
- **Required fix:** In progression (or a focused unit path), temporarily `set_player(null)` / free player ref, call `_scare_position_ahead` (or trigger rabbit/room after clearing `_player`), assert:
  - rabbit Z ≈ `MEMORY_RABBIT_Z - 10`
  - room Z ≈ `FINAL_CLUE_Z - 9`
  - distance from expected player chapter position ≤ 18 m  
  Restore player after.

---

### Medium Priority

#### M1 — Phase 4 historical report still cites dirty WIP; tip baseline is split across files
- **Where:**  
  `phase-04-automated-evidence-report-2026-07-18.md` still anchors dirty `afe9a62` + WIP hash.  
  Authoritative tip automation now lives in `reports/final-automated-audit-2026-07-18.md` + `tester-multiagent-2026-07-18.md` (HEAD `39b22c3`, 12/12).
- **Impact:** Anyone reading Phase 4 alone can launder dirty-tree green into “landed baseline.” Not a Phase 5/6 lie (landing + final audit correctly supersede), but evidence-chain hygiene remains weak.
- **Fix:** Banner Phase 4 report as **historical / superseded by final-automated-audit + tester multiagent on `39b22c3`**.

#### M2 — Plan landing blurb stops at `89042b5`; tip chain includes art + contract commits
- **Where:** [`plan.md`](../plan.md) “Source polish landing” only lists `2ecf78a` + `89042b5`.
- **Impact:** Plan under-describes tip identity (`298467b`, `821ef26`, `39b22c3`). Status of Phase 5/6 remains correctly open.
- **Fix:** Extend landing list; keep Phase 5/6 open language unchanged.

#### M3 — Architecture/changelog chase-fairness numbers vs script defaults
- **Where:** Production [`player.tscn`](../../../scenes/player/player.tscn) exports `walk_speed=2.0`, `sprint_multiplier=1.55` → sprint **3.1**; chase entity `speed=3.0`. Script defaults in `player-controller.gd` are `2.6` / `1.65` (unused when scene loads). Docs that cite 2.0/3.1 match the scene; raw script defaults mislead audits.
- **Impact:** Fairness remains Phase 5 perceptual; no automated speed contract on the scene exports. Risk of future scene-less instantiate using wrong speeds.
- **Fix:** Align script defaults to scene exports; optional layout test on production player exports.

#### M4 — Room climax still overlaps four voice lines with scare stings (ducking-dependent)
- **Where:** `story-progression-controller` room note close → `room_entity_reveal` + multi-line chase_ready; scare SFX at −8/−6 dB; Voice sidechain duck threshold −26 / ratio 6 (settings-audio locked).
- **Impact:** Lifecycle tested; **audible** scare identity is Phase 5 only. Do not “fix” by raising scare toward 0 dB (plan risk control).

#### M5 — Textured-prop tests only prove non-null albedo, not facing/readability
- **Where:** `progression-test._has_textured_mesh` / menu background `texture != null`.
- **Impact:** H1 class defects pass CI. Extend as part of H1 fix.

---

### Low Priority

#### L1 — Dual-key OS delivery still unproven
Structural physical-only + logical-only events locked for all nine actions; `InputEventAction` injection only. Limitations already honest. Keep Phase 5 boundary.

#### L2 — Voice bus mirrors SFX slider
Intentional (PDR/architecture). Not a regression from this cluster.

#### L3 — Horizontal stills + menu background
Memory photo / family table orientations and boot `STRETCH_KEEP_ASPECT_COVERED` look correct; no High there.

---

### Edge Cases Found by Scout

| Edge | Result |
|---|---|
| Floor apparition fixed Z `FLOOR_TRIGGER_Z - 14` vs player at trigger | ~14 m ≤ 18 m; progression asserts distance + ownership |
| Rabbit/room relative anchors with valid player | `z - 10` / `z - 9`; distance contract asserted with player present |
| Rabbit/room fallback without player | Chapter Z anchors present in code; **untested (H2)** |
| Cassette behind-player `MEMORY_CASSETTE_Z + 8` | Correct for −Z facing; null player early-returns (no spawn) |
| Spatial `max_distance = 18` | All story scare distances designed inside envelope |
| Dual physical+logical same QWERTY key | Action strength should not double; layout intent locked by separate events |
| Room drawing single-sided +Z | **Likely invisible on −Z approach (H1)** |
| Menu `preload` missing asset | Would hard-fail parse; assets + `.import` committed |
| Settings 11 keys + ComfortHint + save failure | Still aligned with settings-audio / menu regression |
| `export_presets.cfg` | Absent — matches open Phase 6 |
| Phase 5/6/PDR-07 claims | Honest open across plan, PDR, README, limitations, audits |
| Suite on tip | Tester report: packaging OK + **12/12** on `39b22c3` |

---

### Positive Observations (risk calibration only)

- **Honest open gates:** Phase 5 in-progress, Phase 6 pending, PDR-07 Open, README “Not release-certified,” docs-truthfulness multiagent PASS — consistent. No dishonest close of physical F5/export.
- **Prior H2 dual-key residual closed:** production `project.godot` uses separate physical-only + logical-only events; `_verify_dual_key_bindings` now requires both shapes for all nine actions.
- **Prior M1/M2 scare polish closed in production:** chapter `fallback_z` + `HorrorApparitionFactory.EYE_EMISSION_ENERGY` + Room dual-eye energy asserts.
- **Scare ownership model** remains one-shot (`mark_event_complete`), pause-safe timers (`process_always=false`), light snapshot restore, sequence-owned actors/audio, director `_exit_tree` cancel.
- **Voice ducking** still explicit and tested (sidechain Voice, threshold/ratio, master limiter; SFX setting drives Voice bus by design).

---

### Acceptance / plan verdict (this tip)

| Claim | Verdict |
|---|---|
| Source polish commits landed, contracts present | **PASS** (with H1 presentation risk on room drawing) |
| Automated packaging + 12/12 on tip | **PASS** (tester multiagent on `39b22c3`; this review did not re-exec suite) |
| Dual-key InputMap residual | **PASS** production + test shape |
| Scare anchors / distance | **PASS** with player; fallback **code OK / test gap H2** |
| Textured menu/props preload | **PASS** load path; **H1 facing** for room drawing |
| Settings/audio regressions | **PASS** contracts intact |
| Phase 5 / PDR-07 complete | **FAIL to close** — correctly still open |
| Phase 6 export complete | **FAIL to close** — no preset/templates/exe smoke |
| Dishonest Phase 5/6/PDR-07 claims | **None found** |

---

### Recommended Actions (prioritized)

1. **(H1)** Fix room-drawing still facing (or disable cull) and assert orientation/cull in progression.  
2. **(H2)** Add player-less `_scare_position_ahead` / rabbit+room fallback Z assertions (≤18 m of chapter anchors).  
3. **(M1)** Supersede banner on Phase 4 dirty report; cite tester `39b22c3` as automated tip baseline.  
4. **(M2)** Refresh plan landing commit list through `39b22c3`.  
5. **(M3)** Align `player-controller.gd` defaults with `player.tscn` exports.  
6. **Do NOT** close Phase 5, Phase 6, or PDR-07 without: same-run physical F5 capture+log+eligible pacing payload + human review matrix; credential-free Windows preset + template install + `.exe` menu smoke + post-export suite.

---

### Do NOT close Phase 5/6/PDR-07 without evidence

| Gate | Required evidence (still missing on tip) |
|---|---|
| **Phase 5 / PDR-07** | Fresh production F5 boot→visible credits with OS keyboard/mouse; same-run capture + raw log + unique eligible/complete/order-valid `PLAYTHROUGH_PACING` (active total 900–1200s); fail/recover, Settings/fullscreen/comfort exercised; human fairness/audio/readability notes; agent input not mislabeled as blind playtest |
| **Phase 6** | Matching 4.7.1 export templates installed; tracked credential-free `export_presets.cfg`; Windows x86_64 build under ignored artifacts; log/hash/size; `.exe` launches to production menu and clean exit; suite green after export-config change |
| **Parent plan `completed`** | Every Evidence Map row current; docs/plan/PDR status match artifacts; intentional Git delivery |

**Current honest state:** Phases 1–4 completed (source/automated). Phase 5 **in progress**. Phase 6 **pending**. PDR-07 **Open**. Plan status **`in-progress`**.

---

### Metrics

| Metric | Value |
|---|---|
| Type coverage | N/A (GDScript) |
| Test coverage | Structural dual-key (9 actions, separate events); scare lifecycle with player; Room eyes energy; textured mesh non-null; settings/audio ducking — **no** player-less scare fallback; **no** room-drawing facing; perceptual/OS/export unproven |
| Linting | Not re-run (read-only) |
| Critical findings | 0 |
| High findings | 2 |
| Medium findings | 5 |
| Confidence | **~88%** on contract honesty + tip automation (tester-backed); H1 is geometry/cull reasoning not pixel-proofed in-engine this session |

---

### Unresolved Questions

1. Product intent for room drawing: face −Z (approach), −X (corridor center), or double-sided?  
2. Is player-less scare path considered supported production (checkpoint race) or pure defensive? If pure defensive, H2 still worth a unit assert.  
3. When is physical F5 package authorized (Phase 5 blocker owner)?

---

### Plan follow-up (status recommendation only — no plan mutation)

| Item | Recommendation |
|---|---|
| Phases 1–4 | Keep **Completed**; fix evidence supersession wording (M1) |
| Phase 5 | Keep **In progress** / open |
| Phase 6 | Keep **Pending** / open |
| PDR-07 | Keep **Open** |
| Parent plan `status` | Keep **`in-progress`** |
| Source polish finishable goal | Accept after H1 fix (or explicit accept-risk for room-drawing facing); H2 test before calling fallback “done” |

---

Status: DONE_WITH_CONCERNS  
Summary: Tip `39b22c3` RC polish is automated-green and honest on open Phase 5/6/PDR-07; dual-key and scare-with-player contracts hold. Two Highs remain: room-drawing still likely backface-culled on main approach, and player-less scare fallback lacks regression coverage.  
Concerns/Blockers: Do not mark Phase 5/6 or PDR-07 complete; fix H1 before treating textured-prop polish as player-visible complete.
