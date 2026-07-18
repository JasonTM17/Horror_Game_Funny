# Code Review Summary

**Reviewer:** code-reviewer (adversarial / production-readiness)  
**Date:** 2026-07-18  
**HEAD reviewed:** `9e216eb825acea54ef1fd6aa66589293f7a8600d`  
**Scope commits:** `2ecf78a` → `89042b5` → `9e216eb`  
**Plan:** `plans/260718-1319-final-horror-release-candidate`  
**Mode:** read-only production code; report write only

### Scope
- Files (tip contracts inspected):  
  `project.godot`, `scripts/world/horror-event-director.gd`, `horror-scare-sequence.gd`, `horror-apparition-factory.gd`, `turn-away-apparition.gd`, `chase-entity-visual-builder.gd`, `chase-entity.gd`, `chase-sequence-controller.gd`, `continuous-world-builder.gd`, `story-progression-controller.gd`, `scripts/autoload/audio-manager.gd`, `settings-manager.gd`, `scripts/ui/settings-panel.gd`, `boot-menu.gd`, `scenes/ui/settings-panel.tscn`, `tests/player-input-integration-test.gd`, `tests/progression-test.gd`, `tests/settings-audio-test.gd`, plan/landing/PDR/README/limitations/testing/roadmap/CHANGELOG
- LOC: ~source polish surface (multi-file RC cluster + dual-key residual + docs)
- Focus: finishable contract (source polish + honest open gates); **not** Phase 5/6 or PDR-07 close
- Scout findings: dual-key InputMap shape, scare 18 m spatial envelope, room-scare/voice concurrency, settings 11-key persistence, evidence-revision hygiene

### Overall Assessment

Source polish on tip is **acceptable for the finishable source-polish contract**. Scare anchors stay inside the 18 m spatial ceiling with progression ownership/cleanup coverage; dual physical+logical InputMap is present for all nine keyboard actions and is asserted structurally; settings save/load/focus/comfort contracts remain intact; plan/PDR/README **correctly leave Phase 5, Phase 6, and PDR-07 open**.

No Critical trust-boundary or release-gate lie found. Residual risks are evidence-hygiene (Phase 4 report still points at dirty WIP), dual-binding assertion strength, and doc drift on the input residual—not dishonest Phase 5/6 claims.

**Do not mark Phase 5/6 or PDR-07 complete.** Parent plan must stay `in-progress`.

---

### Critical Issues

*None.*

Gates that would block a *full RC Outcome* (physical F5, export) are correctly **still open** and are out of scope for this finishable contract.

---

### High Priority

#### H1 — Phase 4 evidence identity still cites dirty WIP; tip re-proof lives only in landing note
- **Where:**  
  [`phase-04-automated-evidence-report-2026-07-18.md`](../phase-04-automated-evidence-report-2026-07-18.md) still anchors  
  `afe9a62` + uncommitted hash `19f4430b…`  
  while [`source-polish-landing-2026-07-18.md`](./source-polish-landing-2026-07-18.md) claims tip `89042b5` re-ran packaging + 12/12.
- **Impact:** Anyone reading Phase 4 alone will treat dirty WIP as the automated baseline. That is how “green on dirty tree” launders into “landed revision proven” without a single authoritative tip report.
- **Required:** Either (a) amend/supersede Phase 4 report with tip SHA + fresh marker inventory, or (b) keep Phase 4 as historical and make the landing report the **only** cited automated baseline in plan/PM language (explicit “supersedes Phase 4 source identity”).
- **Not a claim failure for open gates** — landing report itself is honest — but it is an evidence-chain defect for production readiness.

#### H2 — Dual-binding residual is production-correct; test does not lock the dual-*event* shape
- **Where:**  
  [`project.godot`](../../../project.godot) `[input]` — each of WASD/Shift/E/F/Esc/Tab has **two** `InputEventKey`s:  
  `(physical_keycode=X, keycode=0)` + `(keycode=X, physical_keycode=0)`.  
  [`tests/player-input-integration-test.gd`](../../../tests/player-input-integration-test.gd) `_verify_dual_key_bindings()` only ORs:
  ```gdscript
  has_physical = has_physical or key_event.physical_keycode == expected_key
  has_logical  = has_logical  or key_event.keycode == expected_key
  ```
- **Impact:** A single event with **both** `physical_keycode` and `keycode` set to the same key would pass the test while defeating AZERTY/QWERTY dual-layout intent (one event cannot independently express “key at WASD position” vs “letter W”). Residual fix `89042b5` is the right production shape; the regression net is thinner than the bug it claims to pin.
- **Fix:** Assert at least two key events per action, and that one event is physical-only (`physical_keycode == expected && keycode == 0`) and one is logical-only (`keycode == expected && physical_keycode == 0`). Keep `PROJECT_SETTINGS_STABILITY_OK` as the serialization gate.

---

### Medium Priority

#### M1 — `_scare_position_ahead` fallback is story-wrong if player is unset
- **Where:** [`horror-event-director.gd`](../../../scripts/world/horror-event-director.gd) `_scare_position_ahead`  
  Fallback: `Vector3(lateral, height, WorldLayout.FLOOR_TRIGGER_Z - distance)`  
  Used by rabbit (`10 m`) and Room 407 reveal (`9 m`).
- **Impact:** Production always `set_player` before those beats; tests always have a player. If a future call path triggers rabbit/room without player (or after player free), scares spawn at floor-threshold Z (~`-20`) instead of memory/room Z — silently wrong and still “within 18 m” of a missing player.
- **Fix:** Prefer fixed `WorldLayout.MEMORY_RABBIT_Z` / `FINAL_CLUE_Z` (or interaction actor position) as fallback; assert player validity before relative spawn in production paths.

#### M2 — Room-apparition eyes weaker than chase-entity eyes; only chase eyes energy is gated
- **Where:**  
  Factory eyes: emission energy `1.8` ([`horror-apparition-factory.gd`](../../../scripts/world/horror-apparition-factory.gd)).  
  Chase eyes: energy `4.2`, test requires `>= 4.0` ([`progression-test.gd`](../../../tests/progression-test.gd) ~311–316).  
  Room manifestation only asserts `has_node("EyeLeft")` + non-collision + ≤18 m.
- **Impact:** Phase 1 “SDR-safe emissive eyes” for the pre-chase Room beat is not regression-locked at a readable floor. Chase polish is covered; Room polish can regress invisibly.
- **Fix:** Assert Room `EyeLeft` material emission enabled and a minimum energy (or shared factory constant used by both paths).

#### M3 — Public matrix still describes pre-dual-key input residual
- **Where:**  
  [`docs/testing.md`](../../../docs/testing.md) player-input row: “physical E binding exists”.  
  [`docs/limitations.md`](../../../docs/limitations.md): same “physical E” wording.
- **Impact:** Tip guarantees dual physical+logical for **all nine** actions; docs still describe the older, weaker residual. Not a Phase 5/6 lie, but understates the landed InputMap contract.
- **Fix:** Update both docs to “dual physical+logical bindings for WASD/Shift/E/F/Esc/Tab; OS key delivery still unproven.”

#### M4 — CHANGELOG Unreleased omits RC polish landing
- **Where:** [`CHANGELOG.md`](../../../CHANGELOG.md) — packaging/hygiene entries present; no entry for `2ecf78a` / `89042b5` scare/chase/input residual cluster.
- **Impact:** External changelog readers cannot reconstruct tip source polish from CHANGELOG alone.
- **Fix:** Add Unreleased bullets for scare/chase visual/audio/settings polish + dual-key InputMap; keep Known Validation Gaps (PDR-07 / export) explicit.

#### M5 — Room reveal intentionally overlaps four voice lines (ducking-dependent)
- **Where:** [`story-progression-controller.gd`](../../../scripts/world/story-progression-controller.gd) `on_note_closed` → `_horror.trigger("room_entity_reveal")` then four-line `chase_ready` narrative; scare stings at `-8` / `-6` dB on SFX while voice is on Voice bus with SFX sidechain duck (`threshold -26`, `ratio 6` — asserted in settings-audio).
- **Impact:** Lifecycle is correct and pause/cleanup tested; **audible** scare identity during the climax depends on ducking/mix and remains Phase 5 perceptual. Not a silent contract break.
- **Note:** Do not “fix” by raising scare volume toward 0 dB (plan risk control).

---

### Low Priority

#### L1 — Dual-binding does not exercise OS key delivery
Structural InputMap inspection only. Limitations already say OS keyboard/mouse is unproven. No change required beyond keeping that boundary.

#### L2 — Player walk/sprint numbers vs older changelog chase fairness line
`player-controller.gd` walk `2.6`, sprint mult `1.65` (~`4.29`); chase entity `speed 3.0`. Older CHANGELOG text still mentions walk `2.0` / sprint `3.1`. Stale fairness copy; physical fairness still Phase 5.

#### L3 — Reviewer could not re-run `git show` / host suite in this session
Tree + plan/docs + contract inspection only. Suite green on `89042b5` accepted as reported by landing note (acceptance criterion #2). Independent re-run remains available to host.

---

### Edge Cases Found by Scout

| Edge | Result |
|---|---|
| Floor apparition distance vs `max_distance = 18` | Player at trigger z≈`-10.1`, anchor `(2.75,1.3,-24)` ≈ **14.2 m** — inside envelope; progression asserts `distance_to <= 18` |
| Lift-strain offset `+4` Z toward player | Still ~10 m — audible |
| Cassette behind-player at `MEMORY_CASSETTE_Z + 8` | Correct for facing −Z corridor |
| Rabbit/room relative anchors | Bounded by interaction position when player valid; fallback weak (M1) |
| Cassette sequence lifecycle | `finish_sequence("CassetteTurnAwayScare")` on `memory_cassette_recalled` — owned actor + audio cleanup covered |
| Dual physical+logical same key on QWERTY | `is_action_pressed` / `get_vector` should not double strength; residual risk is layout intent (H2) |
| Settings 11 keys + ComfortHint + save failure | Panel + manager + menu regression still aligned |
| `export_presets.cfg` | Absent — matches open Phase 6 |
| Secrets / AI co-author | No `Co-Authored-By` / Anthropic markers in `.git` text search; author on log is Nguyen Son |
| Force-push | Three tip commits are normal fast-forward style on `main` tip; no force-push requirement observed for this cluster |

---

### Positive Observations (risk calibration only)

- **Honest open gates:** plan Phase 5 `in-progress`, Phase 6 `pending`; PDR-07 **Open**; README “Not release-certified”; landing **Non-claims** — all consistent. Finishable contract does **not** over-claim physical F5 or Windows export.
- **Scare ownership model** remains one-shot + pause-safe timers (`process_always=false`) + light snapshot restore + sequence-owned actors; progression spam/pause/exit cleanup still asserted.
- **Chase visual builder** is production-wired (`ChaseSequenceController` → `ENTITY_VISUALS.build`) with named parts + rim energy/range bounds in progression.
- **Voice ducking contract** remains explicit in settings-audio (`sidechain == Voice`, threshold/ratio, master limiter).
- **Dual-key production shape** in `project.godot` matches Godot’s recommended physical+logical split; stability test still requires exact save-roundtrip of that file.

---

### Acceptance criteria verdict

| # | Criterion | Verdict |
|---|---|---|
| 1 | Dirty WIP stabilized as green conventional commits or restored | **PASS** — tip chain `2ecf78a` / `89042b5` / `9e216eb`; conventional subjects; author clean |
| 2 | Packaging + 12-check green (contracts dual-key + scare/chase) | **PASS on contracts**; suite green **reported** on `89042b5` (not re-executed here) |
| 3 | Plan/docs do not claim physical F5 or export complete | **PASS** |
| 4 | No secrets, no force-push needs, no AI co-author | **PASS** |

**Phase 5 / Phase 6 / PDR-07:** remain **open**. Do not flip plan status to completed.

---

### Recommended Actions

1. **(H1)** Supersede or re-anchor Phase 4 automated evidence to tip SHA (`89042b5` or `9e216eb`) so dirty `afe9a62` is not the cited baseline.  
2. **(H2)** Harden `_verify_dual_key_bindings` to require separate physical-only and logical-only events.  
3. **(M3)** Sync `docs/testing.md` + `docs/limitations.md` input wording to dual-key tip contract.  
4. **(M4)** Changelog entry for RC source polish + dual-key residual.  
5. **(M1/M2)** Optional before Phase 5: safer scare fallbacks + Room eye energy assertion.  
6. **Do not** close Phase 5/6 or PDR-07 from this review.

---

### Metrics

| Metric | Value |
|---|---|
| Type coverage | N/A (GDScript) |
| Test coverage | Structural: dual-key all 9 actions; scare lifecycle floor/photo/cassette/rabbit/room; chase visual parts; settings-audio ducking — **perceptual/OS/export unproven** |
| Linting issues | Not re-run (read-only) |
| Critical findings | 0 |
| High findings | 2 |
| Medium findings | 5 |
| Confidence | **~85%** on finishable-contract honesty + code contracts; suite re-run not independent |

---

### Unresolved Questions

1. Was the host 12-check + packaging re-run logged under a durable artifact path beyond the landing report prose (log timestamps for tip `89042b5`)?  
2. Product intent for untracked `menu-hotel-corridor.png` preserved under `.artifacts/wip-untracked/` (PM note) — wire later or discard?  
3. When is physical F5 package authorized (Phase 5 blocker)?

---

### Plan follow-up (status recommendation only — no plan mutation)

| Item | Recommendation |
|---|---|
| Phases 1–4 | Keep **Completed** for source polish; fix evidence identity (H1) |
| Phase 5 | Keep **In progress** / open |
| Phase 6 | Keep **Pending** / open |
| PDR-07 | Keep **Open** |
| Parent plan `status` | Keep **`in-progress`** |
| Finishable source-polish goal | **May close** after H1 documentation clarity; H2 test harden preferred before calling input residual “done forever” |

---

Status: DONE_WITH_CONCERNS  
Summary: Source polish tip is honest on open Phase 5/6/PDR-07 gates; scare/InputMap/settings contracts hold. Two Highs: Phase 4 still cites dirty WIP as automated identity, and dual-key tests do not lock the two-event production shape.  
Concerns/Blockers: Do not mark Phase 5/6 or PDR-07 complete; prefer H1 evidence re-anchor and H2 dual-event assertion before treating input residual as fully pinned.
