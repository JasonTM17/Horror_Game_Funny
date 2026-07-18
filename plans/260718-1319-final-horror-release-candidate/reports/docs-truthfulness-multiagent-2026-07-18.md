# Docs truthfulness audit — 2026-07-18

## Verdict

**PASS**

Open gates stay open. No audited doc or RC plan file claims physical F5 completion, PDR-07 closed, or Windows export certified without artifacts. Asset provenance for `assets/images/` is present.

## Scope

| File | Role |
|---|---|
| `README.md` | Project status, export boundary, assets |
| `docs/project-overview-pdr.md` | PDR-07 status |
| `docs/project-roadmap.md` | Delivery / Phase 4 physical gates |
| `docs/limitations.md` | Open manual + export boundaries |
| `docs/testing.md` | Automated vs manual matrix |
| `docs/asset-credits.md` | `assets/images/` provenance |
| `plans/260718-1319-final-horror-release-candidate/plan.md` | RC phase table |
| `phase-05-physical-f5-review-and-pacing-validation.md` | Physical F5 gate |
| `phase-06-windows-export-docs-and-completion-audit.md` | Export gate |
| `reports/final-automated-audit-2026-07-18.md` | Automated tip baseline |

## Evidence inventory (what exists / does not)

| Claim class | Artifact required | Found? | Notes |
|---|---|---|---|
| Physical F5 boot-to-credits | Same-run capture + human review | **No ready package** | `.artifacts/manual-playthrough/20260718-143251-946/summary.json` has `evidence_package_ready: false`; error: no `PLAYTHROUGH_PACING` payload |
| Eligible pacing payload | `PLAYTHROUGH_PACING:` 900–1200s active | **No** | Not invented; not present in ready form |
| PDR-07 closed | Physical run + review | **No** | Docs keep **Open** |
| Windows export certified | `export_presets.cfg` + template export + menu launch | **No** | No `export_presets.cfg` in repo; no committed `.exe` |
| Staged docs media (PDR-08) | PNG/GIF under `docs/screenshots/` | **Yes** | Correctly labeled documentation-only |
| `assets/images/` provenance | Credits + paths | **Yes** | Four PNGs + imports; table + prompt record in `asset-credits.md` |
| Automated suite green | 12/12 host + packaging | **Cited** | Final automated audit; not physical/export proof |

## Claim-by-claim results

### 1. Physical F5 complete — must stay open

| Source | Stated status | Honest? |
|---|---|---|
| README project status | **Not release-certified**; PDR-07 **open** | Yes |
| PDR acceptance #2–4 | Required for release-ready; not asserted as done | Yes |
| limitations Manual Evidence | "no dated physical F5 run currently proves…" | Yes |
| testing Required Manual Matrix | Explicit "do not mark … verified until" | Yes |
| RC phase-05 | `status: in-progress`; all success criteria unchecked | Yes |
| final-automated-audit | Phase 5 / PDR-07 **Open** | Yes |

**FAIL condition not met.** No file marks physical F5 done.

### 2. PDR-07 closed — must stay open

| Source | Status text | Honest? |
|---|---|---|
| `project-overview-pdr.md` table | PDR-07 **Open** | Yes |
| Current Release Decision | "**PDR-07 remains open:** no fresh 15–20-minute F5…" | Yes |
| roadmap Phase 4 worklist | Physical run / pacing / review checkboxes **unchecked** | Yes |
| plan.md source polish landing | Phase 5 / PDR-07 remain **open** | Yes |

**FAIL condition not met.** PDR-07 is nowhere closed.

### 3. Windows export certified — must stay open

| Source | Claim | Honest? |
|---|---|---|
| README Export | "No export preset is committed or release-tested" | Yes |
| limitations Distribution | No `export_presets.cfg` / executable / package | Yes |
| RC phase-06 | `status: pending`; all success criteria unchecked | Yes |
| final-automated-audit | Phase 6 Windows export smoke **Open** | Yes |
| Repo root | No `export_presets.cfg` file | Matches open gate |

**FAIL condition not met.** Export is not claimed certified.

### 4. RC Phase 5 / Phase 6 completion without artifacts

| Phase | Plan status | Success criteria | Honest? |
|---|---|---|---|
| 5 Physical F5 | In progress | All `[ ]` | Yes |
| 6 Windows export | Pending | All `[ ]` | Yes |
| Parent plan | `in-progress` | Completion Boundary requires Phases 4–5 proof + export | Yes |

Phases 1–4 Completed are automated/source gates only; landing note explicitly keeps 5/6 open.

### 5. Asset provenance for `assets/images/`

| Check | Result |
|---|---|
| Files present | `menu-hotel-corridor.png`, `memory-photo-rabbit.png`, `room-drawing-rabbit.png`, `family-table-memory.png` + `.import` |
| `docs/asset-credits.md` row | Creator, OpenAI generation date, paths, license/redistribution, non-playthrough disclaimer |
| Prompt record section | Four prompts documented |
| README Assets / layout | Lists `assets/images/` as project-authored stills |

**PASS.** Provenance is present and does not rebrand staged media as physical evidence.

## Cross-plan naming note (not a FAIL)

- **Roadmap "Phase 4"** = physical release evidence (still **In progress**).
- **RC plan "Phase 4"** = automated regression evidence (**Completed**).

Different plan trees. Docs do not conflate them into "physical done."

## Optional non-blocking observations (report-only)

1. **Script vs scene walk defaults:** `player-controller.gd` defaults `walk_speed=2.6` / `sprint_multiplier=1.65`; production `player.tscn` sets `2.0` / `1.55` → sprint **3.1**. README/testing "walk 2.0 / sprint 3.1 vs chase 3.0" match the **scene**. Not a release-gate lie; optional later doc note that scene overrides script defaults.
2. **Ignored manual-playthrough tree** contains attempt folders and mkv recordings; latest summary is **not ready**. Docs correctly refuse to treat incomplete packages as PDR-07 evidence.
3. **No doc edits performed** this audit: no small wording drift in scope that was both clearly wrong and required for honesty of F5/PDR-07/export gates.

## Docs edit log

None. Prefer report-only; open-gate wording is already accurate.

## Summary table

| Gate | Required status | Observed status | Result |
|---|---|---|---|
| Physical F5 | Open without package | Open | PASS |
| PDR-07 | Open | Open | PASS |
| Windows export | Open without preset/smoke | Open | PASS |
| RC Phase 5 | Not completed | In progress | PASS |
| RC Phase 6 | Not completed | Pending | PASS |
| `assets/images` provenance | Present | Present | PASS |

## Overall

**PASS** — docs and RC plan truthfully leave physical F5, PDR-07, and Windows export open; automated green + staged media are not oversold as those gates; image asset provenance is recorded.
