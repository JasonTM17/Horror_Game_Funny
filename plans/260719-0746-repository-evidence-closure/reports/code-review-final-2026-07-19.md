---
title: Final code review - repository evidence closure
type: code-review
status: passed
date: 2026-07-19
base_commit: 4ec7eddaf4aaeadfc2cb2be613f7303cc8058b60
review_verdict: pass-for-staging
landing_status: landed-ci-green
landing_commit: c28beeed7a4bafd871e09225152f329beac09e9a
---

# Final Code Review: Repository Evidence Closure

## Code Review Summary

### Scope

- Verdict-time base and current `HEAD`: `4ec7eddaf4aaeadfc2cb2be613f7303cc8058b60`;
  see the delivery addendum for the landed commit.
- Focus: the complete working-tree closure slice against the base commit, before this
  review report was added.
- Files: 29 input paths (24 tracked modifications and 5 new paths), grouped as:
  - CI/root: `.github/workflows/ci.yml`, `.gitignore`, `CHANGELOG.md`, `README.md`.
  - Documentation: `docs/codebase-summary.md`, `docs/deployment-guide.md`,
    `docs/journals/260719-1710-source-docs-closure.md`, `docs/limitations.md`,
    `docs/project-overview-pdr.md`, `docs/project-roadmap.md`, `docs/testing.md`.
  - Plans/reports: the parent Phase 5 plan, phase, and handoff; the child plan and
    phases 2-4; `goal-a-to-z-final-verification-2026-07-19.md`,
    `team-release-readiness-summary-2026-07-19.md`,
    `pm-260719-1501-source-closure.md`, and `tester-final-2026-07-19.md`.
  - Verification code: `tests/physical-playthrough-evidence-regression.ps1`,
    `tests/run-physical-playthrough.ps1`, both Docker packaging verifiers,
    `tests/windows-export-adversarial.ps1`, `tests/windows-export-job-runner.cs`, and
    `tests/verify-repository-docs.py`.
- Size: 3,539 added/new lines and 462 deleted lines before this report.
- Rules applied: `.claude/rules/development-rules.md` and `docs/code-standards.md`.
  The requested `.Codex/rules/development-rules.md` path does not exist in this tree.
- Scout focus: affected callers, process-tree and output-pump races, evidence provenance,
  index/worktree drift, media allowlisting, fresh-checkout behavior, exact canonical
  ordering, and plan/document authority.

### Overall Assessment

**PASS FOR STAGING.** There are zero unresolved Critical, High, or Medium findings.
The review found material defects during its three passes; each was fixed and rechecked
before this verdict. No Godot runtime script, scene, `project.godot`, export preset,
Dockerfile, compose file, dependency, or lockfile changed.

This is not yet a landing or release-certification verdict. The real Git index still
omits required new paths, so `python tests/verify-repository-docs.py` currently exits 1
with `required file is not indexed: docs/deployment-guide.md`. That is the intended
fail-closed staging boundary. Stage the complete intentional slice and obtain all four
docs-verifier markers from the real index before committing. Parent Phase 5/PDR-07 also
remains open for human production-window evidence.

## Three-Stage Review

### Stage 1 - Specification and Scope

Result: **Pass**.

- Child-plan status is factually supported: 4/4 phases and 21/21 child criteria are
  implemented. This does not close parent Phase 5 or PDR-07.
- The runtime pacing prefix and exact schema remain stable. The evidence parser now
  validates exact keys/types/maps and recomputes the verdict instead of trusting reported
  booleans.
- The public canonical suite remains exactly twelve checks, in the same order, in both
  PowerShell and Bash. Both structural verifiers passed after the final changes.
- Existing `Room407ExportJobRun.Launch` remains a five-argument API at
  `tests/windows-export-job-runner.cs:660`; the physical runner uses the additive
  `LaunchInteractive` API.
- No unrelated gameplay, story, runtime configuration, export preset, or container build
  behavior entered the closure slice.
- Documentation consistently distinguishes automated/source evidence, Docker Hub
  publication, and the still-open human physical/perceptual gate.

### Stage 2 - Quality, Contracts, and Trust Boundaries

Result: **Pass**.

- Concurrency: shared output capacity is reserved while holding `outputLock`, but native
  file writes occur after releasing it (`tests/windows-export-job-runner.cs:600`). Job
  shutdown, pump cancellation, handle closure, and joins share finite teardown budgets
  (`tests/windows-export-job-runner.cs:1017`). Pipe handles are initialized to zero before
  failure cleanup.
- Async/error propagation: launch, timeout, output overflow, descendant cleanup, output
  drain, and disposal failures propagate or are aggregated. No catch-and-success path was
  found.
- Process boundary: both the physical run and the `--version` probe route through the
  bounded Job Object helper. The version probe has a fixed 30-second/65,536-byte budget,
  rejects non-zero/empty output, and retains raw logs. Regression assertions ban direct
  `& $Godot` invocation (`tests/physical-playthrough-evidence-regression.ps1:171`).
- Evidence boundary: source/destination containment, reparse rejection, bounded reads,
  stale quarantine, exact-one payload per verified side channel, timestamp/hash binding,
  and strict verdict recomputation fail closed.
- Export boundary: the adversarial harness creates disposable active/previous fixtures,
  preserves them through deterministic timeout and lock failures, and cleans only its
  unique namespaces. It no longer depends on canonical generated bundles.
- Git boundary: the docs verifier parses stage-0 index entries, rejects non-regular modes,
  and validates immutable indexed blob OIDs rather than working-tree bytes
  (`tests/verify-repository-docs.py:86`, `tests/verify-repository-docs.py:122`). Its
  deterministic self-check proves an aliased staged OID wins over the README path and
  mode `120000` is rejected (`tests/verify-repository-docs.py:170`).
- Media boundary: every indexed path below `docs/media/` and `docs/screenshots/` must equal
  the exact allowlist, regardless of extension. Hash, dimensions, PNG/GIF structure, and
  malformed-media negatives remain enforced.
- Authorization/data exposure: no credential material was added. Docker publication still
  requires both repository secrets on a `main` push and is not claimed without a registry
  digest. Raw physical-run logs stay under ignored `.artifacts` paths.
- Backwards compatibility: public runtime/config/export contracts are unchanged; new
  runner parameters and summary fields are additive.

### Stage 3 - Adversarial Review

Result: **Pass after fixes**.

Accepted and resolved findings:

1. **High - unbounded executable preflight.** A direct `& $Godot --version` call could
   hang forever and escape descendant cleanup. It now uses `Invoke-GodotPhysicalProcess`
   at `tests/run-physical-playthrough.ps1:1307`, with an explicit regression ban on direct
   invocation.
2. **High - staged-index/worktree confusion.** The first docs gate used the index only for
   names while hashing/parsing working-tree bytes. A valid local copy could hide a bad or
   symlink blob staged for commit. Validation now reads indexed OIDs and rejects index
   symlink modes; staged-content and symlink negative probes fail closed.
3. **Medium - media extension blind spot.** The allowlist initially filtered candidates to
   `.png`/`.gif`, allowing an indexed `.jpg`, `.webp`, or video to bypass the gate. It now
   enumerates every indexed entry in both public-media directories and includes an
   unexpected-extension negative self-check.
4. **Medium - report authority drift.** Git authorization and final-index state were
   contradictory across reports. The PM authority records Git authorization and
   separates Docker Hub authorization; the post-review delivery addendum below records
   the completed index/push/CI boundary.
5. **Low - case-insensitive PowerShell order comparison.** PowerShell `-ne` could accept
   case-only canonical-name drift. Both exact sequence comparisons now use `-cne`.
6. **High/Medium C# failure paths from the preceding review cycle.** Output writes no
   longer hold the shared accounting lock, disposal no longer performs unbounded joins,
   and `CreatePipe` failure cleanup starts from known-zero handles. This pass traced and
   accepted all three fixes.

Rejected hypotheses:

- The latest Windows export adversarial harness does **not** require pre-existing canonical
  active/rollback bundles. `Invoke-TransactionPreservationProbe` seeds and removes unique
  disposable namespaces; a fresh-checkout run with both canonical bundles absent passed.
- The additive interactive launcher does **not** alter the established five-argument
  export launcher. Existing export callers still bind to `Launch`.
- Staged screenshots, export smoke, host/container checks, and pacing telemetry are not
  mislabeled as human PDR-07 evidence.

## Critical Issues

None unresolved.

## High Priority

None unresolved.

## Medium Priority

None unresolved.

## Low Priority

1. `tests/verify-repository-docs.py` currently starts two `git cat-file` processes for
   each indexed blob read and rereads some required Markdown entries. With 112 currently
   indexed Markdown files this is an N+1 process pattern. The complete temporary-index
   gate passes at the current repository size, so this is informational rather than a
   landing blocker. If the docs corpus grows, switch to one `git cat-file --batch` session
   with the same per-blob caps and OID/mode checks.

## Edge Cases Found by Scout

- Hung or descendant-spawning user-supplied Godot executable before the main launch:
  accepted, fixed, and regression-bound.
- Unexpected media extensions bypassing the public allowlist: accepted, fixed, and
  regression-bound.
- Case-only canonical check drift in the PowerShell verifier: accepted and fixed.
- Required untracked landing paths: confirmed as a deliberate real-index failure and a
  mandatory pre-commit action.
- C# output-budget races, teardown hangs, invalid-handle cleanup, and legacy-launch
  compatibility: traced after the targeted fixes; no remaining defect found.
- A later adversarial pass found staged-blob/worktree confusion beyond the initial scout;
  it was fixed with index-OID validation and negative mode/content probes.

## Behavioral Checklist

| Area | Result | Evidence |
|---|---|---|
| Concurrency | Pass | Output accounting/write separation; bounded Job/pump teardown |
| Error boundaries | Pass | Timeout, overflow, process, drain, dispose, parser, and Git failures fail closed |
| API contracts | Pass | Five-argument `Launch` preserved; additive launcher/summary fields |
| Backwards compatibility | Pass | No runtime/game/export/config diff; exact twelve and markers preserved |
| Input validation | Pass | Ranges, strict JSON, bounded blobs, containment, hashes, index modes |
| Auth/authz | Pass | No sensitive operation added; Hub secrets/main policy remains explicit |
| N+1/query efficiency | Informational | Per-blob `git cat-file` subprocess pattern recorded as Low |
| Data leaks | Pass | No secrets; evidence logs remain ignored/local; no external stack trace path added |
| Plan fact-check | Pass | Paths/symbols/statuses grep-verified; parent human gate remains open |

## Verification Evidence

- Post-fix physical regression: exit 0 with process-boundary, pacing-schema,
  destination-containment, reparse, and side-channel markers.
- PowerShell and Bash packaging verifiers: exit 0; exact ordered twelve checks.
- `python -m py_compile tests/verify-repository-docs.py`: exit 0.
- Temporary complete landing index: `REPOSITORY_MEDIA_OK`,
  `MARKDOWN_LOCAL_LINKS_OK`, `MARKDOWN_INDEXED_LOCAL_LINKS_OK`, `PRO_DOCS_OK`.
- Negative Git-index probes: staged wrong-content README and media symlink mode rejected;
  deterministic OID/mode self-checks pass.
- Actual unstaged index: expected exit 1 on unindexed `docs/deployment-guide.md`.
- Fresh-checkout Windows export adversarial run with canonical active/rollback bundles
  absent: exit 0 with all preservation and cleanup markers.
- Full tester matrix in `tester-final-2026-07-19.md`: C# compilation, script syntax,
  Windows export/smoke, host 12/12, container 12/12, secrets, YAML, UTF-8, diff hygiene,
  and cleanup passed.
- Final `git diff --check`: exit 0.

## Positive Observations

- Risky process behavior is isolated behind an additive API; the established export
  launcher and public runtime surface did not change.
- The real-index failure is useful evidence: the landing gate does not accept merely
  present working-tree files.
- Authority docs preserve the only honest release boundary: automated/source closure is
  complete, while human physical/perceptual certification is not.

## Recommended Actions

These are the verdict-time recommendations. Items 1-3 are completed by the post-review
delivery addendum; items 4-6 remain standing boundaries or optional follow-up.

1. Stage the entire intentional slice, including every new report, deployment guide, and
   `tests/verify-repository-docs.py`.
2. Run `python tests/verify-repository-docs.py` against the **real** final index and require
   all four success markers. Do not substitute a working-tree or temporary-index result.
3. Re-run `git diff --cached --check`, secret scan, and the short syntax/packaging gates;
   then commit and perform the authorized non-force push. Record the immutable commit SHA
   and monitor both CI workflows.
4. Do not claim Docker Hub publication without the workflow result and registry digest.
5. Leave parent Phase 5/PDR-07 open until a human completes and signs the production-window
   evidence package.
6. Optionally batch Git blob reads if docs-verifier process startup becomes material.

## Plan Follow-up

- Child repository-evidence-closure plan: implementation criteria support `completed`.
- Parent final-horror-release-candidate plan: keep `in-progress`.
- Parent Phase 5/PDR-07: keep open; no automated evidence in this slice closes it.
- Delivery/index verification was outside the verdict-time review and is now closed by
  the post-review delivery addendum below. No plan file or task state was changed by the
  reviewer itself.

## Metrics

- Unresolved findings: Critical 0, High 0, Medium 0, Low 1.
- Type coverage: not measured/not applicable as a percentage; no TypeScript changed.
  Changed C# compiled through `Add-Type`, and changed PowerShell parsed successfully.
- Test coverage: no line/branch percentage is configured. Behavioral evidence covers the
  canonical host/container 12/12 matrix plus focused process, evidence, export, packaging,
  media, link, and index failure paths.
- Linting issues: 0 from configured syntax/diff gates; the repository has no aggregate
  formal lint-count command for this mixed PowerShell/Python/C#/Markdown slice.

## Post-review Delivery Addendum

The delivery lead completed the review's staging recommendations without changing the
reviewed QA/runtime content: six QA paths landed as
`ad514cba881270d43fa532d324224618dd48d364`, followed by the 24-path report-containing
closure commit `c28beeed7a4bafd871e09225152f329beac09e9a`. The authoritative real index emitted
all four docs/media markers before and after commit; secret, syntax, UTF-8, YAML, cached-
diff, physical regression, and both packaging gates passed. The non-force push reached
0/0 local/origin/remote parity. Matching [`ci`](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29688458245)
and [`docker-suite`](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29688458242)
runs passed. Docker Hub publication skipped because repository secrets are absent.

This addendum closes delivery/index verification, not Phase 5/PDR-07. The original review
verdict and informational Low remain unchanged.

## Unresolved Questions

No unresolved technical question blocks source delivery. Operational ownership remains:

- Does the repository owner want Docker Hub publication later, and if so, who configures
  both secrets and records the published digest?
- Which human reviewer owns the Phase 5/PDR-07 production-window run?
