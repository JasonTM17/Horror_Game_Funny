# Scout: remaining RC polish gaps (source-level)

**Date:** 2026-07-18  
**Repo:** `D:\Horror_Game`  
**Mode:** read-only  
**Inputs:** plan + phases 1–6, RC reports (reviewer-ck-finalize, multiagent reviewer/tester/docs/export, landing, final audit), named scripts/tests/docs  
**Tip automation (cited):** tester multiagent `39b22c3` — packaging + 12/12 green  

**Closed since mid-polish review (`821ef26` family):** dual-event InputMap test shape; scare `fallback_z` chapter anchors; Room eye energy constant + dual-eye assert; CHANGELOG RC polish; docs dual-key wording; Phase 4 historical supersede banner; menu/prop texture preload + non-null tests; gitignore allows tracked `export_presets.cfg` (only `export.cfg` ignored).

---

## 1. Safe to fix now (source / tests / docs)

Ranked by impact × fixability without F5 or export templates.

### G1 — HIGH — Room drawing still faces wrong approach (new art can be invisible)

| | |
|---|---|
| **Evidence** | `scripts/world/story-prop-visual-builder.gd:52-53` — `RoomDrawingImage` offset `(0,0,0.027)`, `rotation=Vector3.ZERO` (QuadMesh front = local **+Z**). Prop spawn `continuous-story-layout.gd:39` at `x=2.4`, `ROOM_DRAWING_Z=-430` (`world-layout.gd:22`). `level-geometry.gd:10-15` `textured_material` never sets `cull_mode` (default backface cull). |
| **Test hole** | `progression-test.gd:17-20,490-495` only requires `QuadMesh` + `albedo_texture != null` — green even if culled. |
| **Why** | Main route walks **−Z**. Single-sided +Z face → approach from more-positive Z sees backface. Prop also sits on **+X** wall; corridor-center view is mostly **+X**, so +Z-facing quad is often edge-on. Labels still read (`Label3D` + `no_depth_test` at `story-prop-visual-builder.gd:187`) so interaction/progression stay green while still is product-useless. |
| **Fix** | Face approach/corridor (e.g. `rotation = Vector3(0, PI, 0)` + −Z offset, or face −X for wall art, or `CULL_DISABLED`). Assert basis/cull in progression, not only albedo. Files: `story-prop-visual-builder.gd`, optional `level-geometry.gd`, `tests/progression-test.gd`. |

### G2 — HIGH — Player-less scare fallback untested

| | |
|---|---|
| **Evidence** | Production OK: `horror-event-director.gd:81,96,176-182` — rabbit `MEMORY_RABBIT_Z - 10`, room `FINAL_CLUE_Z - 9`, fallback uses `fallback_z` when `!is_instance_valid(_player)`. |
| **Test hole** | Grep `tests/`: no `set_player(null)` / cleared `_player` + expected chapter Z. Rabbit/room asserts only with live player (`progression-test.gd:210-220,296-322`). |
| **Why** | Contract fixed in `821ef26` can regress silently; happy path always has player. |
| **Fix** | Temporarily clear player ref; call `_scare_position_ahead` or trigger rabbit/room; assert Z anchors + ≤18 m of chapter positions; restore player. File: `tests/progression-test.gd` (+ optional tiny helper on director). |

### G3 — MED — Script walk/sprint defaults diverge from production scene

| | |
|---|---|
| **Evidence** | `player-controller.gd:6-7` defaults `walk_speed=2.6`, `sprint_multiplier=1.65` (sprint ≈4.29). Production `player.tscn:15-16` `walk_speed=2.0`, `sprint_multiplier=1.55` → sprint **3.1**. Chase `chase-entity.gd:3` `speed=3.0`. Fairness docs match **scene** (`docs/game-design.md:122-124`, `docs/architecture.md:156,174`, `docs/code-standards.md:63`, `docs/testing.md:209`). Layout only checks inequality vs live exports (`checkpoint-layout-test.gd:179-180`). |
| **Why** | Scene-less instantiate / future override drop breaks walk < entity < sprint. Audits misled by raw script. |
| **Fix** | Align script defaults to `2.0` / `1.55`; optional assert production player exports == 2.0 / 1.55 and entity 3.0. Files: `player-controller.gd`, optional `checkpoint-layout-test.gd` or `player-input-integration-test.gd`. |

### G4 — MED — Plan / final-audit tip identity lag

| | |
|---|---|
| **Evidence** | `plan.md:95-100` landing blurb stops at `2ecf78a` + `89042b5`. `reports/final-automated-audit-2026-07-18.md:7,31` soft “expected `821ef26` family” + SCRATCH path — not tip SHA. Authoritative tip suite: `reports/tester-multiagent-2026-07-18.md:14-19,128-133` **HEAD=`39b22c3`**, 12/12. Phase 4 already banner-superseded (`phase-04-automated-evidence-report-2026-07-18.md:3-7`) but still body-anchors dirty `afe9a62`. |
| **Fix** | Extend plan landing through art/contract/`39b22c3`; pin final-audit tip SHA to tester HEAD; keep Phase 5/6 open. Docs/plan only. |

### G5 — LOW — Textured-prop / menu tests stop at non-null

| | |
|---|---|
| **Evidence** | Props: G1. Menu: `menu-settings-regression.gd:118-120` asserts `MenuBackground` texture + `STRETCH_KEEP_ASPECT_COVERED` only (boot wiring `boot-menu.gd:3,14-18` OK). |
| **Fix** | Bundle with G1 orientation/cull assert; optional menu size/aspect non-zero. |

### G6 — LOW — Evidence-chain wording (non-blocking if G4 done)

| | |
|---|---|
| **Evidence** | Phase 4 historical body still lists dirty identity (`phase-04-…:11-14`) after supersede banner. |
| **Fix** | Optional: add “do not cite body SHA” note near identity table; cite tester report as sole tip baseline. |

---

## 2. Requires user physical F5 (leave open)

Do **not** claim fixed without same-run capture/log/`PLAYTHROUGH_PACING` + human matrix (Phase 5 / PDR-07).

| Gap | Why physical | Key refs |
|---|---|---|
| **P1** Boot→credits OS keyboard/mouse; fail/recover; Settings/fullscreen/comfort | Phase 5 success criteria all `[ ]`; no ready package | `phase-05-…md:28-32`; `docs/project-overview-pdr.md:19,49` PDR-07 Open; `docs/limitations.md:36-51`; docs-truthfulness: incomplete `.artifacts/manual-playthrough/…` (`evidence_package_ready: false`) |
| **P2** Chase fairness feel under player control | Automated only speed inequality + LOS path, not full player slalom feel | `checkpoint-layout-test.gd:179-180`; `docs/testing.md:209-219`; PDR-04 fairness unverified |
| **P3** Scare timing/readability/surprise on SDR | Lifecycle headless only | `progression-test` scare blocks; `limitations.md:49`; plan Direction Rules |
| **P4** Audible mix / voice intelligibility during Room climax | Concurrent 4 voice lines + stings −8/−6 dB; ducking −26/6 locked | `story-progression-controller.gd:116-127`; `horror-event-director.gd:105-106`; `audio-manager.gd:40-42`; settings-audio asserts ducking — not device output |
| **P5** OS InputMap delivery (dual physical+logical) | Structural only | `player-input-integration-test.gd:240-275`; `project.godot:37-86`; `docs/testing.md:162-168` |
| **P6** 15–20 min pacing (900–1200 s active) | Headless intentionally short (`within_target:false`) | tester-multiagent notes; PDR-07 |
| **P7** Door/drawer sweep feel, mouse look latency, fullscreen transition | Explicit manual matrix | `limitations.md:40-51` |

---

## 3. Requires export templates (Phase 6)

| Gap | Blocker | Refs |
|---|---|---|
| **E1** Install 4.7.1 templates into portable editor path | Archive present; installed dir empty | export-readiness: `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz` present; `editor_data\export_templates\` **0 children** |
| **E2** Create/verify Windows x86_64 `export_presets.cfg` + CLI export | Preset file **absent** at repo root | export-readiness; `docs/limitations.md:6`; README export section |
| **E3** Launch `.exe` → production menu → clean exit; log/hash/size | Needs E1+E2 | `phase-06-…md:33-39` all `[ ]` |
| **E4** Post-export suite + docs/plan status flip | After smoke | phase-06 steps 4–7 |

**Partial source prep without templates (optional, still Phase 6):** hand-author credential-free preset + confirm git tracks it. Current `.gitignore:14-15` ignores only `export.cfg` (export-readiness report’s “export_presets.cfg ignored” line is **stale** vs tip ignore). Do **not** invent smoke success without templates.

---

## 4. Explicit non-issues

| Item | Why not a remaining source defect |
|---|---|
| Dual-key production + test | `project.godot` separate physical-only/logical-only events; `player-input-integration-test.gd:254-275` requires both shapes for 9 actions |
| Scare pause-safe waits | `horror-scare-sequence.gd:16` / turn-away / narrative use `create_timer(..., false)`; progression pause asserts floor/fuse/cassette |
| Chapter scare fallbacks (code) | `horror-event-director.gd:176-182` + rabbit/room call sites — gap is **test** (G2), not production code |
| Room eye energy floor | `horror-apparition-factory.gd:4,58` `EYE_EMISSION_ENERGY=1.8`; `progression-test.gd:302-311` dual eyes |
| Chase entity visuals | Builder wired; progression asserts parts + eye ≥4.0 + rim (`progression-test.gd:340-346`) |
| Menu corridor texture wired | `boot-menu.gd:3,14-18` preload + TextureRect; menu regression non-null |
| Horizontal stills (photo/table) | Rotated −π/2 about X → face +Y; not H1 class (`story-prop-visual-builder.gd:51,102`) |
| Settings 11-key / focus / ComfortHint | menu-settings + settings-audio contracts intact |
| Voice bus = SFX slider | Intentional product design (architecture/PDR) |
| Phase 5/6/PDR-07 honesty | Plan in-progress; PDR-07 Open; README not release-certified; docs-truthfulness PASS |
| Parent phases 1–4 source/automated | Marked completed; suite green on tip per tester |
| Fail overlay blocks pause | `player-controller.gd:40-42` — recovery timer `create_timer(1.25)` default process_always is OK while fail lock (tree not paused) |
| “Raise scare volume to fix mix” | Explicit anti-pattern (plan risk control); leave for F5 listening (P4) |

---

## Priority fix order (finishable without F5/export)

1. **G1** room-drawing facing + orientation test  
2. **G2** player-less scare fallback test  
3. **G3** align player script defaults (+ optional speed pin)  
4. **G4** plan/final-audit tip SHA sync  
5. **G5/G6** residual test/doc hygiene  

Then human **Phase 5** F5 package → **Phase 6** template install + export smoke.

---

## Status

**Status:** DONE  
**Summary:** Remaining source-safe polish: room-drawing cull/facing (G1), untested scare fallback (G2), player default vs scene (G3), tip-evidence doc sync (G4). Phase 5 physical F5/PDR-07 and Phase 6 templates/export stay open non-issues for source-only work. Prior dual-key/scare-fallback-code/eyes/docs Highs largely closed on tip `39b22c3`.
