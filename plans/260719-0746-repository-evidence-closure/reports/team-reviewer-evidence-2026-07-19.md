# Team review — evidence honesty & physical-gate integrity

Date: 2026-07-19  
Role: reviewer-evidence (read-only)  
Plan: `plans/260719-0746-repository-evidence-closure/`  
Posture: fail closed against overclaiming

## Verdict

**No CRITICAL overclaim found that labels automated, staged, export, or Docker results as human physical proof.**

PDR-07 / parent Phase 5 are correctly left **OPEN** across current authority surfaces (PDR, roadmap, README, limitations, testing snapshot, parent plan, child plan, operator handoff, tester and cycle-2 reports).

Physical runner contracts are sound for the documented maintainer/operator threat model (freshness, reparse, same-run uniqueness, analyze-only rejection, readiness ≠ human review). Residual honesty risks are operator-path inconsistency and dual-dated export hashes, not false closure of the human gate.

**Score: 9/10 on evidence honesty. Critical findings: 0.**

---

## Scope

| Item | Reviewed |
|---|---|
| Child plan + phases 1–4 | Yes |
| Parent Phase 5 file + operator handoff | Yes |
| PDR-07, roadmap, testing, limitations, README, credits, CI cover | Yes |
| `tests/run-physical-playthrough.ps1` | Full |
| `tests/physical-playthrough-evidence-regression.ps1` | Full |
| Existing child reports (audit, tester, cycle-1/2 review) | Yes |
| Cover isolation (`.gdignore`, export filter, CI IHDR) | Yes |

No files edited. No commits. No gates re-executed; this is static contract/honesty review against source and written evidence.

---

## Critical Issues

None.

No current authority doc or report reviewed here claims:

- Docker packaging-contract pass = live image build / Hub publish
- Export / headless smoke = rendered menu, OS input, or audible mix
- Staged PNG/GIF or repository cover = physical F5 / PDR-07
- Focused side-channel regression = release evidence package
- `evidence_package_ready` / runner exit 0 = human gate closed

---

## Important Issues

### I1 — Parent Phase 5 phase file still steers operators to weaker `EditorF5`

**Evidence**

`plans/260718-1319-final-horror-release-candidate/phase-05-physical-f5-review-and-pacing-validation.md:28`:

> `2. Start the evidence runner in EditorF5 mode without falsely asserting human input.`

Authoritative handoff and public docs prefer `ProjectRun` because only that mode binds `--log-file` to the game process:

- Handoff: `phase-05-operator-handoff-2026-07-18.md:45-48` (`-LaunchMode ProjectRun`)
- Runner: `tests/run-physical-playthrough.ps1:5-6,573-576` (EditorF5 warning; F5 game process not captured)
- README / `docs/testing.md` / `docs/limitations.md`: same preference and side-channel-only caveat for EditorF5

**Impact**

Not an overclaim of completed physical proof. It is an **operator-contract split**: following the phase file (not the handoff) weakens same-run log binding and game-process failure scanning (editor host log + side-channel only). That degrades physical-gate integrity even if human input is real.

**Recommended wording (phase-05 file, do not edit here)**

Replace step 2 with something like:

> Prefer `-LaunchMode ProjectRun` so `--log-file` binds to the game process. Use `EditorF5` only when the editor is required; then harvest depends on a strictly post-launch `user://playthrough_pacing_last.txt` side-channel after credits, and game-process log failures may be invisible. Never pass `-ConfirmPhysicalInput` unless a human used real keyboard/mouse.

Also keep success criteria unchanged: agent evidence must not be labeled human blind playtest.

---

### I2 — Dual-dated Windows export hashes in `docs/testing.md` can still be mis-bound

**Evidence**

Current snapshot (correct, role-labeled):

- `docs/testing.md:99-104` — active exe `420c0856…` / `117920024` bytes; active bundle `2111b6f5…`; rollback `3c4890f2…`

Older dated narrative still present without an explicit “superseded for handoff” marker:

- `docs/testing.md:73` — 2026-07-18 gate: `117914600` bytes, SHA `e783cfa0…`
- `docs/testing.md:220` — same historical exe identity in “Recorded Automated Evidence”

Cycle-1 already blocked a worse form of this in the QA audit (`C1`); that audit was fixed to role-label active/rollback (`headless-qa-audit-2026-07-18.md:59-66`). The testing.md historical paragraphs remain honest-by-date but are easy to copy as “current” during handoff.

**Impact**

Risk of binding a release note or operator checklist to a stale ignored binary. Does **not** claim physical proof, but violates fail-closed identity discipline for export artifacts.

**Recommended wording**

Above the 2026-07-18 paragraphs, add one line:

> Historical 2026-07-18 export identity only. For current handoff identities use [Current Verification Snapshot — 2026-07-19](#current-verification-snapshot--2026-07-19).

Or move the old size/hash into a collapsible “Historical automated evidence” subsection labeled non-authoritative for delivery.

---

## Moderate Issues

### M1 — `evidence_package_ready` is operator-trust, not OS-input proof (documented, still easy to overread)

**Evidence**

Readiness (`tests/run-physical-playthrough.ps1:462-475,635-641`) requires:

- launched engine exit 0 + zero scanned log failures
- pacing verdict pass
- side-channel integrity pass
- clean unchanged git commit/branch
- `-ConfirmPhysicalInput` switch (boolean declaration only)
- non-empty `-CaptureReference` string (path not existence-checked; video not inspected)

Always:

- `review_required = true` (`:676`)
- exit 0 only means package ready for human review; incomplete → exit 2 + warning (`:686-689`)

Docs correctly state the runner cannot inspect video or prove OS keys (`docs/limitations.md:68`, `docs/testing.md:388`, README physical-run section).

**Residual risk**

An operator can pass `-ConfirmPhysicalInput -CaptureReference "todo.mp4"` after a non-human or incomplete visual session and get exit 0 if telemetry/package gates pass. That is **not** currently labeled as PDR-07 close anywhere authoritative, but exit 0 language (“ready”) can be misread as “physical gate passed.”

**Recommended wording (handoff + testing.md one-liner)**

> `EVIDENCE_PACKAGE_READY=true` / exit 0 means the package is eligible for human review, not that PDR-07 or parent Phase 5 is closed. Closure requires watching the capture and completing the matrix with named reviewer/date.

---

### M2 — Parent Phase 5 “Automated substitute evidence” checkboxes can be skimmed as completion

**Evidence**

`phase-05-physical-f5-review-and-pacing-validation.md:44-52` marks host/container 12/12, synthetic route/input, export smoke, etc. `[x]`, while human observations stay `[ ]`. Section title says “not completion proof,” which is correct.

**Risk**

Skimmers may treat the checked automated list as phase progress toward PDR-07.

**Recommended wording**

Prefix the section title or first bullet:

> These checked items are prerequisites / non-substitutes. They do not advance Phase 5 success criteria 1–5.

---

### M3 — Historical reports outside the current authority chain

Older multi-agent reports under the parent plan correctly leave Phase 5/PDR-07 open. One older preflight (`plans/260716-2113-…/reports/pm-260718-0720-release-preflight.md`) records “F5 menu and Settings inspected non-headless” as a UI pass; that is outside this child plan’s delivery surface and is not cited by the current handoff as PDR-07 evidence. No action required for closure honesty if it is not promoted into current authority docs.

---

## Physical playthrough runner — contract soundness

| Contract | Status | Evidence |
|---|---|---|
| Pre-launch archive + fail-closed clear of side-channel | Sound | `Prepare-PacingEvidenceSideChannels` (`:256-303`); regression archives then deletes |
| Freshness: strictly after launch (`-le` rejects boundary) | Sound | `Copy-PacingEvidenceSideChannels` (`:352-354`); no ±2s tolerance; regression exact-boundary + former-tolerance cases |
| Baseline-hash rejection (restored stale content) | Sound | `:355-357`; regression same-hash case |
| Reparse-point refusal (APPDATA / candidate / file) | Sound | `Assert-RegularEvidenceDirectory/File`; junction cases emit `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK` when platform supports junctions |
| Single-stream snapshot + pre/open/post identity + dest size/hash | Sound | `Copy-PacingEvidenceSnapshot` (`:155-248`); rejected destinations deleted |
| Deterministic source-swap rejection | Sound | regression hook after pre-identity; reason `source_identity_changed_during_snapshot`; integrity fails |
| Snapshot anomaly → integrity false | Sound | harvest loop sets `integrity_passed = false` on any non-accepted snapshot (`:338-343`); cycle-2 confirms cycle-1 W1 closed |
| Ordinary stale/baseline exclusion non-fatal | Sound | freshness/hash rejects keep integrity true; residual package can still use direct game log |
| Mixed-run rejection (distinct pacing JSON) | Sound | `Get-UniquePacingPayload` throws if count ≠ 1 (`:398-403`) |
| Analyze-only cannot ready package | Sound | `launchPerformed=false` → `enginePassed=false` → readiness false (`:545,629,635-641`); helper unit-tested |
| Dirty / diverging git blocks readiness | Sound | `repositoryStable` requires clean before/after + same commit/branch (`:634`) |
| `review_required` always true | Sound | hardcoded (`:676`); checklist unchecked in `summary.md` |
| Hostile same-profile TOCTOU after open | Documented limitation | limitations/testing/cycle-2; not claimed closed |

**EditorF5 caveat (integrity, not honesty bug):** game-process prints and many ERROR lines are not in the editor host log; harvest may rely solely on side-channel. Prefer ProjectRun for PDR-07 (see I1).

**Focused regression boundary:** isolated temp `APPDATA`, no Godot launch, no release evidence package; success markers only. Correctly described in `docs/testing.md:84-85` and phase-02 non-goals.

---

## Cover provenance isolation (1280×640)

| Check | Result |
|---|---|
| Path | `docs/media/room-407-cover.png` (docs-only) |
| Provenance | `docs/asset-credits.md` row: 1280×640, 999,431 bytes, SHA-256 `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`; “not gameplay or physical-playthrough evidence” |
| Godot import isolation | `docs/.gdignore` present |
| Export isolation | `export_presets.cfg:11` `exclude_filter` includes `docs/*` |
| CI | `.github/workflows/ci.yml` requires file, README/credits references, PNG signature, IHDR length 13, exact 1280×640 |
| Artistic approval | Not claimed; dimension/header guard only |

No finding that the cover is treated as F5 or perceptual proof.

---

## Staged screenshots / GIF vs real F5 boundaries

| Surface | Claim | Honest? |
|---|---|---|
| PDR-08 | Complete staged PNG/GIF under `docs/screenshots/` | Yes; explicitly “staged media is not physical-playthrough evidence” (`project-overview-pdr.md:44,69`) |
| Roadmap media checkbox | Staged tour done; does not satisfy physical-run or perceptual gates | Yes (`project-roadmap.md:25`) |
| `docs/testing.md` visual-capture tour | Frozen sim, teleports, direct state select; not F5 / pacing / chase / audio / Settings | Yes (`:170,190`) |
| `docs/limitations.md` | Staged stills/GIF not F5 evidence | Yes (`:88`) |
| README | Cover + screenshots + GIF not physical proof; PDR-07 open | Yes (`:7,34,194-199`) |
| Handoff “Do not claim” | No staged cover / export smoke / automation as human perceptual proof | Yes (`phase-05-operator-handoff:62-66`) |

Boundary is consistently fail-closed.

---

## PDR-07 / parent Phase 5 status (must stay OPEN)

| Authority | Status text | Matches reality? |
|---|---|---|
| `docs/project-overview-pdr.md:19,69` | PDR-07 **Open** | Yes |
| `docs/project-roadmap.md:16,21-27,53` | Physical phase in progress; human F5 boxes unchecked | Yes |
| Parent `plan.md:6,105-118` | `in-progress`; Phase 5 open; child cannot close human gate | Yes |
| Parent `phase-05-…md:4` | `status: in-progress`; success criteria 1–5 unchecked | Yes |
| Child `plan.md:23-25,101-103` | Cannot close parent Phase 5 / PDR-07 | Yes |
| Child phase-04 | Explicitly leaves PDR-07 open; final commit checkbox still open | Yes |
| Operator handoff | Phase 5/PDR-07 **open**; human command required | Yes |
| Tester re-verify / cycle-2 | Automated only; human gate remains | Yes |
| README / CHANGELOG / limitations | Open / not release-certified | Yes |

**No pressure path found that would administratively close PDR-07 from this child plan’s automated green matrix.**

---

## Correctly guarded strengths

1. **Stable contracts preserved:** 12-check suite not expanded; focused harnesses are separate; pacing prefix / boundary order / target metadata unchanged.
2. **Honest Docker language:** packaging contracts pass; live daemon/Hub explicitly **unverified**, not passed (handoff, testing snapshot, tester re-verify, parent plan, README).
3. **Export honesty:** PE/headless smoke ≠ rendered/input/audio; normal-window review remains open (PDR-10 automated vs criterion 4).
4. **Side-channel threat model scoped:** covered accidental/deterministic races fail closed; hostile same-profile race documented, not papered over.
5. **Analyze-only / mixed / incomplete packages** cannot report readiness.
6. **Always-on human matrix** in generated `summary.md`; `review_required: true` unconditional.
7. **Cover / staged media provenance** recorded and isolated from runtime import/export.
8. **Child vs parent authority:** child completion explicitly leaves human gate open; dual roadmap numbering (parent Phase 5 = older Phase 4) explained in `project-roadmap.md:7-8`.
9. **Cycle-1 C1 stale-hash mislabel** fixed in the QA audit with active/rollback labels matching 2026-07-19 tester identities.
10. **Dirty-tree discipline:** handoff refuses to treat planning tree as clean delivery commit; runner blocks readiness on dirty/unstable git.

---

## Overclaim scan summary

| Claim class | Found as physical/human proof? |
|---|---|
| Headless 12/12 | No — “contracts only” |
| Physical-evidence regression | No — synthetic fixtures |
| Docker packaging verifiers | No — contracts; daemon unavailable |
| Windows export + adversarial | No — headless/export contracts |
| Staged screenshots / GIF | No — PDR-08 only |
| Repository cover | No — docs artwork |
| Runner exit 0 / package ready | No — review still required (see M1 overread risk) |
| Cycle-2 9/10 review | No — automated/repository only |

---

## Recommended actions (priority order)

1. **I1:** Align parent `phase-05-physical-f5-review-and-pacing-validation.md` step 2 with handoff/`ProjectRun` preference and EditorF5 caveats.
2. **I2:** Mark 2026-07-18 export size/hash paragraphs in `docs/testing.md` as historical/non-authoritative for handoff.
3. **M1:** One explicit sentence in handoff + testing runner section: package ready ≠ PDR-07 closed.
4. **M2:** Optional anti-skim banner on parent Phase 5 automated substitute list.
5. **Do not** flip parent Phase 5, PDR-07, roadmap physical boxes, or overall release status on this child plan’s automated evidence.
6. **Do not** treat Docker Hub push (if later authorized) as substitute for the game gate (already stated in child phase-04).

Exact handoff close condition (already correct; preserve):

> Human-observed `START SHIFT` → visible credits with real keyboard/mouse; same-run capture + unique eligible complete order-valid 900–1200 s payload; chase fail/recover; Settings/fullscreen/comfort; perception matrix completed by a named reviewer. Reject analyze-only, mixed, stale, baseline-identical, incomplete, wrong-order, out-of-target packages.

---

## Metrics (honesty review, not suite re-run)

| Metric | Value |
|---|---|
| Critical honesty defects | 0 |
| Important issues | 2 (I1 operator path, I2 dual export hashes) |
| Moderate issues | 3 (M1 ready overread, M2 checkbox skim, M3 external historical) |
| PDR-07 status | Open (correct) |
| Parent Phase 5 status | in-progress (correct) |
| Child plan remaining criterion | Commit/push + Docker decision only; not human gate |

---

## Unresolved questions

1. Will lead treat parent phase-05 file (I1) as in-scope for the still-open child Phase 4 handoff polish, or defer to a later docs-only touch?
2. After clean commit, will handoff pin exact SHA + Godot path as phase-04 step 1 requires, without back-dating physical evidence?

---

## Status

Status: DONE  
Summary: Evidence honesty holds fail-closed: no automated/staged/export/Docker result is labeled human physical proof; PDR-07/parent Phase 5 stay open; runner freshness/reparse/same-run/analyze-only contracts are sound for the documented threat model.  
Concerns/Blockers: Align parent Phase 5 step 2 away from preferred-EditorF5 (I1); mark dual-dated testing.md export hashes historical (I2); keep package-ready language from being skimmed as gate closure (M1).
