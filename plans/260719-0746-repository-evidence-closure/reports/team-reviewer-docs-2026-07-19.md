# Team review — documentation truthfulness vs repository state

Date: 2026-07-19  
Role: **reviewer-docs** (read-only; no edits, no commits)  
Work dir: `D:\Horror_Game`  
Branch: `main`  
Plan: `plans/260719-0746-repository-evidence-closure/`  
Posture: fail closed on false completion, stale identity, and broken authority chains

## Verdict

**No CRITICAL false claim that PDR-07 / parent Phase 5 is closed, that Docker live image/Hub publish passed, or that staged media equals physical playthrough.**

Public docs are largely honest about the human gate. Remaining defects are **authority-chain drift**, **dual-dated export/suite identities that can be mis-copied**, and **dirty-tree verification not disclosed in the public status line**. Export SHA-256 claims for the 2026-07-19 active/rollback roles match the local `VERIFY_COMPLETE.txt` manifests under `.artifacts/builds/`.

**Score: 8/10 on documentation truthfulness. Critical factual errors: 0. Blocking for clean delivery narrative: 2 IMPORTANT items.**

---

## Scope

| Surface | Reviewed |
|---|---|
| `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `THIRD_PARTY_NOTICES.md` | Yes |
| `docs/project-overview-pdr.md`, `project-roadmap.md`, `testing.md`, `limitations.md`, `architecture.md` | Yes |
| `docs/asset-credits.md`, `codebase-summary.md`, journals (esp. `260719-1013-…`) | Yes |
| Child plan `260719-0746` + phases 1–4 status/checkboxes | Yes |
| Parent RC plan `260718-1319` + Phase 5 + operator handoff | Yes |
| Older root plan `260715-0936` status table | Spot-check |
| Export/cover hash claims vs `.artifacts/builds/*/VERIFY_COMPLETE.txt` + reports | Yes |
| Key relative links / media paths | Existence check |
| Cross-check with `team-reviewer-evidence-2026-07-19.md` | Yes (docs-specific delta only) |

No files edited. No gates re-executed. Live SHA re-hash of multi-MB binaries was not re-run in this agent; identity was reconciled against verifier manifests + multi-report agreement.

---

## Method notes

1. Compared public status claims to plan phase tables and success-criteria checkboxes.
2. Compared every documented 2026-07-19 export identity to:
   - `.artifacts/builds/room407-windows-x86_64/VERIFY_COMPLETE.txt`
   - `.artifacts/builds/room407-windows-x86_64.previous/VERIFY_COMPLETE.txt`
   - `tester-2026-07-19.md`, `tester-review-fix-cycle-1-2026-07-19.md`, operator handoff
3. Checked cover contract path/dimensions/hash consistency across README, testing, limitations, PDR, roadmap, credits, CHANGELOG.
4. Checked journals vs testing matrix language for physical-gate honesty.
5. Separated **factual errors** from **style / skimmability nits**.

---

## Hash / artifact reconciliation (factual)

### Active Windows export (2026-07-19 role)

| Field | Docs (README/CHANGELOG/PDR/roadmap/testing/limitations/codebase-summary) | On-disk `VERIFY_COMPLETE.txt` (active) | Match |
|---|---|---|---|
| Size | `117920024` | `FILE\|…exe\|117920024\|…` | Yes |
| Exe SHA-256 | `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771` | same | Yes |
| Bundle SHA-256 | `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d` | `BUNDLE_SHA256=…` same | Yes |
| Markers | export + smoke OK (reports) | `WINDOWS_EXPORT_VERIFY_OK`, `WINDOWS_EXPORTED_PROCESS_SMOKE_OK`, PE x86_64 | Yes |

### Rollback Windows export (2026-07-19 role)

| Field | Docs (bundle role) | On-disk previous `VERIFY_COMPLETE.txt` | Match |
|---|---|---|---|
| Bundle SHA-256 | `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701` | same | Yes |
| Previous exe SHA-256 | Documented in handoff/cycle-1 as `8384735b0906e243c198f4b2203a96aa53c910819327edfa30fb4035da6c71c2` | same in previous manifest | Yes |
| Previous size | (often omitted publicly) | `117920024` (same size as active; different content hash) | N/A |

Public tables correctly role-label **active** vs **rollback bundle**. Previous **executable** hash is correctly confined to operator/tester surfaces, not mislabeled as current active.

### Historical 2026-07-18 export (still present in docs)

| Field | Location | Notes |
|---|---|---|
| `117914600` / `e783cfa076d1bf4c9bbf7da7301b233fcded9235fa52ba6bbe595018688ff30e` | `docs/testing.md` (~L73, L220), `docs/project-roadmap.md` (~L74), historical plan reports | Dated **2026-07-18**; not the current active identity. Honest if read carefully; skimmable risk (see IMPORTANT). |

### Cover

| Field | Docs | Supporting evidence | Match across authority docs |
|---|---|---|---|
| Path | `docs/media/room-407-cover.png` | file present | Yes |
| Dimensions | `1280×640` | tester + credits + CI narrative | Consistent |
| Size | `999,431` bytes (`asset-credits.md`) | phase-01 audit / evidence review | Consistent |
| SHA-256 | `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980` | README/CHANGELOG/PDR/roadmap/testing/limitations/codebase-summary/credits | Consistent |
| Isolation | `docs/.gdignore` + `export_presets.cfg` `docs/*` | `.gdignore` present; preset excludes `docs/*` | Yes |

### Godot inventory

| Field | Docs | VERIFY manifests |
|---|---|---|
| `GODOT_COPYRIGHT.txt` SHA-256 | `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d` (`THIRD_PARTY_NOTICES.md`, testing, VERIFY) | same | Yes |

### `exports/` tree

- `exports/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe` exists locally.
- Path is gitignored (`.gitignore` has `exports/`).
- Verifier default publish path is **`.artifacts/builds/…`**, not `exports/`.
- Public docs do **not** claim the `exports/` copy is the verified handoff identity. No CRITICAL mislabel; residual operator confusion risk only (MODERATE).

---

## Plan status vs phase checkboxes

### Child plan `plans/260719-0746-repository-evidence-closure/`

| Claim | Evidence | Truth |
|---|---|---|
| Plan `status: in-progress` | frontmatter | Matches open delivery checkbox |
| Phase 1–3 Completed | phase tables + checkboxes all `[x]` | Matches |
| Phase 4 In progress | phase file `status: in-progress`; 4/5 criteria `[x]`; commit/push/Hub `[ ]` | Matches |
| Progress “20/21 … 95%” | plan.md | Consistent with single open delivery criterion |
| Cannot close parent Phase 5 / PDR-07 | plan completion boundary + parent note | Matches public docs |

### Parent plan `plans/260718-1319-final-horror-release-candidate/`

| Claim | Evidence | Truth |
|---|---|---|
| Phases 1–4, 6 Completed; Phase 5 In progress | plan table | Matches PDR-07 open |
| Phase 5 success criteria still open | phase-05 checkboxes for physical run remain `[ ]` | Matches |
| Operator handoff open + dirty-tree caveat | `phase-05-operator-handoff-2026-07-18.md` | Matches child Phase 4 |
| C1 stale-hash issue in headless QA audit | Fixed: audit now role-labels 2026-07-19 active/rollback | Matches cycle-2 “fixes confirmed” |

### Older root plan `plans/260715-0936-room-407-the-last-shift/`

| Claim | Evidence | Truth |
|---|---|---|
| Plan still `in-progress`; Phase 7–8 In Progress | plan table + phase files | Correct for open physical gate |
| Evidence reconciliation dated **2026-07-16** | plan body | **Stale relative to 2026-07-19 authority** (MODERATE dual authority) |

Roadmap correctly explains dual numbering: roadmap “Phase 4” == parent “Phase 5” == PDR-07. Not a factual contradiction if both are read; still a skimmability hazard (MODERATE).

---

## Critical issues (factual errors)

**None.**

No reviewed authority surface currently states:

- physical F5 / 15–20 min pacing verified,
- Docker daemon image build/run or Hub publish passed locally,
- staged PNG/GIF/cover is physical-playthrough evidence,
- export headless smoke is rendered/menu/audio certification,
- child plan complete while commit/push checkbox remains open.

---

## Important issues (factual or authority defects that can mislead handoff)

### [IMPORTANT] `"README.md"` / `"CHANGELOG.md"` index a self-superseded tester report as primary evidence

**Evidence**

- `plans/260719-0746-repository-evidence-closure/reports/tester-2026-07-19.md:3-6` states it is **superseded for landing** by `tester-review-fix-cycle-1-2026-07-19.md`.
- `README.md:18` and `CHANGELOG.md:15` still cite `tester-2026-07-19.md` (+ cycle-2) as the current command-level evidence index.
- Stronger docs (`docs/project-overview-pdr.md`, `docs/testing.md`, `docs/limitations.md`, `docs/codebase-summary.md`) correctly cite **all three** reports (initial + re-verify + cycle-2).

**Impact**

Readers following README/CHANGELOG can treat a pre-fix matrix as authoritative when post-fix re-verification is the landing tip. Hashes happen to still match, so this is authority drift more than wrong SHA — but it breaks the “one truthful authority” phase-3 criterion for public entry points.

**Fix (docs only; not applied here)**

Point README/CHANGELOG primary links at `tester-review-fix-cycle-1-2026-07-19.md` (and cycle-2), and demote the original tester report to “initial trace.”

---

### [IMPORTANT] `"docs/testing.md"` (and README suite paragraph) keep dual-dated suite/export identities without a hard “non-authoritative for handoff” banner

**Evidence**

- Current authority: `docs/testing.md` “Current Verification Snapshot — 2026-07-19” with active `420c0856…` / `117920024`.
- Historical still in-body:
  - `docs/testing.md` ~L73: 2026-07-18 export `117914600` / `e783cfa0…`
  - `docs/testing.md` ~L218–220: 2026-07-18 host 12/12 (~77.5s) + same historical export hash
  - `README.md:163`: “final Windows host run on **2026-07-18** … 12 checks … 77.5 seconds” while status line claims 2026-07-19 green
  - `docs/project-roadmap.md:74`: “current verified **2026-07-18** artifact …” under “Completed Windows Export Track” while a later section lists 2026-07-19 identities

**Impact**

Same class as evidence-reviewer I2: not a false PDR-07 close, but release notes/handoff can bind the wrong ignored binary or wrong suite timestamp. Cycle-1 fixed the worse unlabeled form in `headless-qa-audit-2026-07-18.md`; public testing/README still need a one-line supersession guard.

**Fix**

Above every 2026-07-18 size/hash paragraph: “Historical only. Current handoff identities: Current Verification Snapshot — 2026-07-19.” Optionally rename “current verified 2026-07-18 artifact” in roadmap to “historical 2026-07-18 verified artifact.”

---

### [IMPORTANT] Public `"README.md"` status line omits dirty-tree verification boundary present in handoff/tester reports

**Evidence**

- README: “source-complete with a fresh green Windows host 12/12 …” without dirty-tree caveat.
- Operator handoff: verification was on the **current dirty worktree**; clean delivery commit recorded only after Git step.
- Team tester-1 report: suite ran against dirty tree; `main...origin/main` dirty.
- Physical package readiness **requires** clean unchanged commit (`docs/testing.md` physical runner section).

**Impact**

“Source-complete + green 12/12” can be read as “ready to ship from this tree.” Automated green on a dirty tree is valid as contract evidence, but omitting the dirty boundary understates delivery risk and conflicts with physical-evidence readiness rules.

**Fix**

One clause in README status / testing snapshot: “12/12 recorded on the dirty closure worktree; delivery still requires clean commit, push authorization, and human F5.”

---

## Moderate issues

### [MODERATE] Dual phase numbering (roadmap Phase 4 vs parent Phase 5)

- `docs/project-roadmap.md:7-9` explains the mapping.
- `README.md:16` says “Phase 4 physical still open”; `README.md:18` says “parent Phase 5 remains open.”
- Factual if both read; skimmers may invent two open gates.

**Fix:** Prefer one public name (“PDR-07 / parent Phase 5”) in README table; keep mapping only in roadmap.

### [MODERATE] Older root plan evidence snapshot frozen at 2026-07-16

- `plans/260715-0936-room-407-the-last-shift/plan.md` still carries 2026-07-16 suite/commit narrative while remaining open for Phase 7–8 physical gates.
- Phase-3 claimed one truthful authority across child/parent/older plans; older plan is not harmful if unused, but it is a second “in-progress” root with stale tip evidence.

**Fix:** Add a short banner pointing authority for automated claims to the 2026-07-19 child reports; leave Phase 7–8 open.

### [MODERATE] Parent Phase 5 step still steers `EditorF5` (docs/plan honesty, operator path)

- Documented by evidence reviewer I1; confirmed: `phase-05-physical-f5-review-and-pacing-validation.md` step 2 vs handoff/README/testing preference for `ProjectRun`.
- Not a completion overclaim; weakens same-run log binding if operators follow the phase file.

### [MODERATE] Local `exports/` executable without verified bundle co-files

- Ignored path; only `.exe` listed under `exports/room407-windows-x86_64/`.
- Docs correctly point verifiers at `.artifacts/builds/`.
- Risk: human copies `exports/` binary and treats it as the hashed handoff artifact without notices/manifest.

**Fix:** Optional one-liner under Export: “Do not use ad-hoc `exports/` copies for handoff; only role-labeled `.artifacts/builds` verifier output.”

### [MODERATE] `"SECURITY.md"` “source-only” wording vs local export tooling

- `SECURITY.md:5-7`: source-only project; no published binary release channel; fixes on `main` only.
- Accurate for the **GitHub-published** surface (exports ignored, not committed).
- Could confuse maintainers who have local verified builds.

**Fix (optional):** “No published binary release channel; local ignored export verification may exist under `.artifacts/builds/`.”

---

## Style nits (non-blocking; not factual errors)

1. README is very long; status + limitations repeated in multiple sections — maintainability cost, not untruth.
2. CHANGELOG `[Unreleased]` correctly holds 2026-07-19 snapshot; no version tag yet — fine.
3. CONTRIBUTING matches suite/packaging commands and “exactly twelve” rule — accurate.
4. Architecture docs remain verification-boundary honest; no claim of physical pass.
5. Voice count “76 cues” matches manifest entries (76 `file:` lines) and filesystem voice-over inventory narrative.

---

## Journal / handoff language vs testing matrix

| Journal / handoff | Alignment with `docs/testing.md` manual matrix |
|---|---|
| `docs/journals/260719-1013-repository-evidence-closure.md` | Matches: automation green; Docker unverified; PDR-07 open; clean-tree F5 + capture + 900–1200s payload required |
| `docs/journals/260717-2331-immersive-player-facing-ui-polish.md` | Matches: automated OK; physical validation open |
| Earlier journals (pacing, door/chase, environmental) | Consistently leave physical/perceptual gates open |
| Parent operator handoff | Matches matrix: ProjectRun preferred, START SHIFT, chase fail/recover, Settings/fullscreen/comfort, human watch capture |

**No journal reviewed claims the manual matrix is complete.**

---

## Link integrity (key docs)

Spot-checked targets exist on disk:

| Link class | Result |
|---|---|
| README → CONTRIBUTING, SECURITY, CHANGELOG, docs/* | Present |
| README → cover, screenshots, assets/images | Present |
| README/docs → 2026-07-19 plan reports | Present under `plans/260719-0746-…/reports/` |
| testing.md → runners, export scripts, world scripts | Present |
| PDR/roadmap → architecture/testing/limitations/export | Present |
| THIRD_PARTY_NOTICES → GODOT_COPYRIGHT.txt | Present |
| Anchor `#current-verification-snapshot--2026-07-19` | Heading exists in `docs/testing.md` |

No broken key relative path found among the reviewed entry points. Exhaustive all-markdown link crawl was not re-run here; prior tester matrix recorded `MARKDOWN_RELATIVE_LINKS_OK`.

---

## Docs that are accurate and should stay

Keep these surfaces as written authority unless a later run changes evidence:

1. **PDR-07 open / not release-certified framing** — `README.md` status, `docs/project-overview-pdr.md` table + release decision, `docs/limitations.md` manual-evidence section.
2. **Twelve-check matrix and “not physical proof” boundaries** — `docs/testing.md` exact matrix + synthetic-vs-physical section; `CONTRIBUTING.md` twelve-check rule.
3. **Role-labeled 2026-07-19 export identities** — current snapshot tables in testing/limitations/roadmap/PDR/codebase-summary/CHANGELOG (active `420c0856…`, bundles as listed).
4. **Cover provenance and non-evidence disclaimer** — `docs/asset-credits.md` cover row + isolation claims.
5. **`THIRD_PARTY_NOTICES.md` + tag-pinned `GODOT_COPYRIGHT.txt` hash** — matches VERIFY manifests.
6. **SECURITY.md vulnerability process + no-secrets / settings-local posture** — consistent with architecture/settings docs.
7. **Child plan honesty** — in-progress; Phase 4 open only for commit/push/Hub authorization; cannot close parent Phase 5.
8. **Journal 2026-07-19** — correctly refuses administrative closure of PDR-07.
9. **Architecture export/pacing boundaries** — headless smoke ≠ rendered play; telemetry side-channel is evidence-only.
10. **Fixed headless QA audit export section** — active/rollback labels (post-C1) should remain the model for other historical sections.

---

## Consistency matrix (public claims)

| Claim | README | PDR | Roadmap | Testing | Limitations | CHANGELOG | Plans |
|---|---|---|---|---|---|---|---|
| 12/12 host green (available gates) | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Docker packaging contracts pass | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Docker live/Hub unverified | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| PDR-07 / physical open | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Active export `420c0856…` / `117920024` | via testing link | Yes | Yes | Yes | Yes | Yes | Yes |
| Cover `58d5893…` / 1280×640 | not hashed in body | Yes | Yes | Yes | Yes | Yes | Yes |
| Dirty-tree caveat | **Missing** | Partial | Partial | Partial | Partial | No | Handoff **Yes** |
| Primary evidence tip = post-fix re-verify | **No** (superseded tip) | Yes (all three) | Partial | Yes | Yes | **No** | Handoff prefers re-verify |

---

## Recommended actions (docs only; prioritized)

1. **Repoint README + CHANGELOG evidence index** from superseded `tester-2026-07-19.md` to `tester-review-fix-cycle-1-2026-07-19.md` (+ keep cycle-2).
2. **Banner historical 2026-07-18 export/suite hashes** in `docs/testing.md`, README suite paragraph, and roadmap “Completed Windows Export Track” so handoff cannot bind `e783cfa0…` / `117914600` as current.
3. **Disclose dirty-tree verification** in README status and testing snapshot until clean commit/push.
4. **Align parent Phase 5 step 2** with ProjectRun-first operator handoff (evidence-reviewer I1).
5. **Banner older `260715` plan** that automated tip evidence lives under 2026-07-19 child reports.
6. Optional: clarify SECURITY “source-only” vs local ignored builds; warn against ad-hoc `exports/` copies.

---

## Metrics (documentation review, not product coverage)

| Metric | Value |
|---|---|
| Critical factual errors | 0 |
| Important authority/identity issues | 3 |
| Moderate issues | 5 |
| Style nits | 5 |
| Export identity match (active/rollback vs VERIFY) | Pass |
| Cover hash consistency across authority docs | Pass |
| PDR-07 overclaim | None found |
| Broken key relative links (spot-check) | 0 |

---

## Unresolved questions

1. Will the delivery commit re-run export verification and rewrite hashes again, invalidating the 2026-07-19 tip before push? If yes, docs must update in the same commit as the binary identity change.
2. Is `exports/room407-windows-x86_64/*.exe` intentional operator convenience or a stale leftover? Not claimed in docs; confirm ownership so it is not mistaken for verified output.
3. Should public docs pin `HEAD` SHA once clean, or keep only role-labeled artifact hashes?

---

## Cross-team notes

- Agrees with `team-reviewer-evidence-2026-07-19.md`: no CRITICAL physical-gate overclaim; dual-dated export hashes remain IMPORTANT.
- Confirms cycle-2 claim that headless QA audit C1 is fixed.
- Docs-specific delta: superseded tester primary link in README/CHANGELOG, and missing dirty-tree disclosure on the public status line.

---

Status: DONE_WITH_CONCERNS  
Summary: Documentation truthfully leaves PDR-07 open and matches current active/rollback export and cover hashes against verifier manifests; two public entry-point authority defects (superseded tester tip; dual-dated historical hashes without handoff banner) plus dirty-tree nondisclosure should be fixed before delivery narrative freeze.  
Concerns/Blockers: Do not treat README “source-complete + green 12/12” as clean-tree ship readiness; do not bind historical `e783cfa0…` / `117914600` as the current export identity.
