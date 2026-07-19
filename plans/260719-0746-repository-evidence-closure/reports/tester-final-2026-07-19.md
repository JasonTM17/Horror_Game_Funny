# Tester Final Report - 2026-07-19

Scope: diff-aware verification of the current repo state in `D:\Horror_Game`.

## Environment

- Host: Windows PowerShell
- Date: 2026-07-19
- Docker: Desktop 4.79.0, Engine 29.5.3, compose v5.1.4
- Godot: `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe`
- Template archive: `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz`
- PyYAML: 6.0.3

## Changed Surface

Mainly touched:

- `.github/workflows/ci.yml`
- `.gitignore`
- `CHANGELOG.md`
- `README.md`
- `docs/codebase-summary.md`
- `docs/limitations.md`
- `docs/project-overview-pdr.md`
- `docs/project-roadmap.md`
- `docs/testing.md`
- `plans/260719-0746-repository-evidence-closure/*`
- `tests/physical-playthrough-evidence-regression.ps1`
- `tests/run-physical-playthrough.ps1`
- `tests/verify-docker-packaging.ps1`
- `tests/verify-docker-packaging.sh`
- `tests/windows-export-adversarial.ps1`
- `tests/windows-export-job-runner.cs`

## Static Gates

| Check | Exit | Result |
|---|---:|---|
| PowerShell AST parse for changed `.ps1` files | 0 | OK |
| `Add-Type` for `tests/windows-export-job-runner.cs` | 0 | OK |
| `bash -n tests/verify-docker-packaging.sh` | 0 | OK |
| `python -m py_compile tests/verify-repository-docs.py` | 0 | OK |
| Strict UTF-8 decode over changed text files | 0 | OK |
| PyYAML parse for `.github/workflows/ci.yml` and `.github/workflows/docker-suite.yml` | 0 | OK |
| `git diff --check` | 0 | OK |
| Secret scan (`tests/scan-secret-patterns.sh`) | 0 | OK |

## Script / Regression Runs

| Command | Exit | Duration | Key evidence |
|---|---:|---:|---|
| `tests/physical-playthrough-evidence-regression.ps1` | 0 | 14590 ms | `PHYSICAL_EVIDENCE_PROCESS_BOUNDARY_REGRESSION_OK`, `PHYSICAL_EVIDENCE_PACING_SCHEMA_REGRESSION_OK`, `PHYSICAL_EVIDENCE_DESTINATION_CONTAINMENT_REGRESSION_OK`, `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK`, `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK` |
| `tests/verify-docker-packaging.ps1` | 0 | 1565 ms | `DOCKER_PACKAGING_VERIFY_OK` |
| `bash tests/verify-docker-packaging.sh` | 0 | 5074 ms | `DOCKER_PACKAGING_VERIFY_OK` |
| `tests/verify-windows-export.ps1` | 0 | 18079 ms | `WINDOWS_EXPORT_PE=x86_64`, `WINDOWS_EXPORTED_PROCESS_SMOKE_OK`, `WINDOWS_EXPORT_VERIFY_OK` |
| `tests/windows-export-adversarial.ps1` | 0 | 41292 ms | `WINDOWS_JOB_ROOT_EXIT_GRANDCHILD_OK`, `WINDOWS_EXPORT_MANIFEST_AND_RECOVERY_ADVERSARIAL_OK`, `WINDOWS_EXPORT_PARSER_ADVERSARIAL_OK`, `WINDOWS_EXPORT_DETERMINISTIC_TIMEOUT_PRESERVATION_OK`, `WINDOWS_EXPORT_TIMEOUT_LOCK_PRESERVATION_OK`, `WINDOWS_EXPORT_ADVERSARIAL_OK` |
| `docker compose config` | 0 | sub-second | resolved `suite` service with `user: 65532:65532` and pinned `GODOT` env |
| `docker compose build suite` | 0 | 7637 ms | image built successfully |
| `docker compose run --rm -e ALL_TWELVE=1 suite` | 0 | 57965 ms | `ALL_TWELVE_HEADLESS_CHECKS_OK` |
| `tests/run-headless-tests.ps1` | 0 | 64425 ms | 12 check OK lines, no script failure markers |

## Host Canonical Suite

- Canonical host check count: 12/12
- Canonical host log count: 12/12
- Canonical host bad logs: 0
- Exact canonical log set verified:
  - `test-editor-import.log`
  - `test-menu.log`
  - `test-gameplay.log`
  - `test-game-state.log`
  - `test-progression.log`
  - `test-checkpoint-layout.log`
  - `test-physical-route.log`
  - `test-player-input.log`
  - `test-visual-effects.log`
  - `test-settings-audio.log`
  - `test-settings-persistence-write.log`
  - `test-settings-persistence-read.log`

## Docs Validator

Actual repo index:

- `python tests/verify-repository-docs.py`
- Exit: 1
- Result: fail-closed as expected
- Failure: `required file is not indexed: docs/deployment-guide.md`

Temp landing index proof:

- Ran the validator in a throwaway cloned workspace with the current docs staged.
- Also staged `tests/verify-repository-docs.py` and `plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md`.
- Exit: 0
- Key evidence: `REPOSITORY_MEDIA_OK`, `MARKDOWN_LOCAL_LINKS_OK`, `MARKDOWN_INDEXED_LOCAL_LINKS_OK`, `PRO_DOCS_OK`

## Cleanup Checks

- Docker compose container cleanup: no leftover `horror_game-suite-run-*` container after `--rm`
- Windows export cleanup: no leftover `windows-export-profile-*` or `windows-export-stage-*` dirs from the verified run
- Host process cleanup: no lingering `godot` process after the host suite / export checks

## Notes

- Broad `.artifacts/test-*.log` scanning still shows historical non-canonical failure logs from prior runs, but the current canonical 12 host logs are clean.
- No code or docs edits were made during verification.
- Human proof is not treated as automated evidence. PDR-07 remains open.

## Post-Review Delta

Re-ran the reviewer-requested affected gates only:

| Check | Exit | Result |
|---|---:|---|
| PowerShell AST on changed `.ps1` files | 0 | OK |
| `Add-Type` for `tests/windows-export-job-runner.cs` | 0 | OK |
| `python -m py_compile tests/verify-repository-docs.py` | 0 | OK |
| `tests/physical-playthrough-evidence-regression.ps1` | 0 | OK, same 5 markers |
| `tests/verify-docker-packaging.ps1` | 0 | OK |
| `bash tests/verify-docker-packaging.sh` | 0 | OK |
| `git diff --check` | 0 | OK |
| Strict UTF-8 decode over changed text files | 0 | OK |
| Temp-clone `tests/verify-repository-docs.py` landing-index validator | 0 | OK, `REPOSITORY_MEDIA_OK` / `MARKDOWN_LOCAL_LINKS_OK` / `MARKDOWN_INDEXED_LOCAL_LINKS_OK` / `PRO_DOCS_OK` |
| Temp-clone README OID tamper | 1 | Failed closed: `index-blob self-test did not follow the staged object id` |
| Temp-clone README mode `120000` tamper | 1 | Failed closed: `README.md: index mode 120000 is not a regular file` |
| Media allowlist self-test | 0 | `MEDIA_ALLOWLIST_SELF_TEST_OK` |
| Isolated `tests/windows-export-adversarial.ps1` with canonical active/previous moved aside and restored | 0 | OK, `WINDOWS_JOB_ROOT_EXIT_GRANDCHILD_OK`, `WINDOWS_EXPORT_MANIFEST_AND_RECOVERY_ADVERSARIAL_OK`, `WINDOWS_EXPORT_PARSER_ADVERSARIAL_OK`, `WINDOWS_EXPORT_DETERMINISTIC_TIMEOUT_PRESERVATION_OK`, `WINDOWS_EXPORT_TIMEOUT_LOCK_PRESERVATION_OK`, `WINDOWS_EXPORT_ADVERSARIAL_OK` |

Delta verdict:

- Static gates stayed green.
- Packaging verifiers stayed green.
- Physical regression stayed green.
- Docs/media validator stayed green in isolated clone and now fails closed on both README OID and mode `120000` tamper cases.
- Media allowlist self-test passed.
- The earlier temp-clone bundle-missing note is superseded: the current adversarial harness passes when the canonical active/previous bundles are moved aside and restored after the run.
- The regression surface is still exercised end to end.
