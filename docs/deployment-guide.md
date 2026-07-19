# Deployment Guide

Use this guide to launch source, run host/container QA, verify repository documentation,
produce the unsigned Windows export, understand CI/Docker Hub behavior, and hand the
build to a human reviewer. The Docker image is a headless test image, not the game.
PDR-07 remains open until the required human physical production-window run is reviewed.

## Prerequisites

- Git and Python 3.
- Godot 4.7.1 standard (not .NET) using the Compatibility renderer.
- PowerShell 5.1+ for Windows QA, export, and physical evidence tooling.
- Docker Engine/Desktop only for the Linux-container suite.
- For export, the official Godot 4.7.1 standard export-template archive and installed
  `windows_release_x86_64.exe` template.

Generated profiles, logs, exports, and captures stay below ignored `.tmp/` and
`.artifacts/` paths. Do not commit credentials, templates, or binaries.

## Source Launch

Clone and perform a command-line import with `godot` on `PATH`:

```powershell
git clone https://github.com/JasonTM17/Horror_Game_Funny.git
Set-Location .\Horror_Game_Funny
godot --headless --path . --editor --quit
godot --path .
```

For the GUI path, import `project.godot` in the Godot Project Manager and press **F5**.
F5 follows the configured boot scene; F6 runs the current editor scene and may bypass
the boot menu.

## Release Candidate Verification

Run host and container QA before any export or physical handoff.

Resolve a portable Godot command from `PATH`, then pass it to the Windows runner:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 -Godot $godot
```

The runner's omitted `-Godot` default under `D:\Tools\Godot-4.7.1\...` is a
maintainer-local convenience, not a required installation layout.

Run the equivalent Linux suite in the non-root container:

```powershell
docker compose build suite
docker compose run --rm suite
```

Without a Docker daemon, validate structural packaging contracts:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
```

On Linux, use `bash tests/verify-docker-packaging.sh`. The canonical runners require the
same twelve checks and intentionally ignore known ObjectDB warning noise at process exit.
They still fail on non-zero exits, missing markers, and engine/script/parse/assert scans.
A dated zero-line ObjectDB scan is an additional closure audit, not runner failure policy.

Run the focused Windows regressions separately:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\physical-playthrough-evidence-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\windows-export-adversarial.ps1
```

The physical regression's four primary markers are:

```text
PHYSICAL_EVIDENCE_PROCESS_BOUNDARY_REGRESSION_OK
PHYSICAL_EVIDENCE_PACING_SCHEMA_REGRESSION_OK
PHYSICAL_EVIDENCE_DESTINATION_CONTAINMENT_REGRESSION_OK
PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK
```

Supported junction probes additionally emit `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK`;
unsupported probes emit explicit skip diagnostics. Synthetic regression output is not
human play evidence.

## Repository Documentation Gate

Run:

```powershell
python tests/verify-repository-docs.py
```

A pass prints, in order:

```text
REPOSITORY_MEDIA_OK
MARKDOWN_LOCAL_LINKS_OK
MARKDOWN_INDEXED_LOCAL_LINKS_OK
PRO_DOCS_OK
```

The verifier reads stage-0 regular-file blobs directly by Git-index object ID; working-tree
bytes cannot mask a bad staged blob or symlink mode. Every local link target must be
indexed, so stage new landing targets before expecting a pass. It handles inline links
plus explicit and collapsed reference links, rejects undefined references, and ignores
fenced examples. Same-document anchors and external or protocol-relative URLs are
excluded; a local path before a fragment is still checked.

Caps are 1 MiB per Markdown/config file, 2 MiB per PNG, and 8 MiB for the GIF. Media
validation rejects every unapproved public-media path or extension and binds the exact
indexed hashes, dimensions, PNG/GIF structure, and GIF frame count.

## CI and Docker Hub

Both workflows run on pull requests and pushes to `main`:

- `.github/workflows/ci.yml` checks packaging, docs/media/links, and secret patterns.
- `.github/workflows/docker-suite.yml` builds the image and runs all twelve checks.

After the Docker suite passes on a `main` push, repository secrets
`DOCKERHUB_USERNAME=nguyenson1710` and `DOCKERHUB_TOKEN` cause automatic publication of
`nguyenson1710/horror-game-suite:latest` and the full `GITHUB_SHA` tag. No separate
workflow approval exists. Missing secrets skip publication without failing the suite.

The repository name and tags are only a publish contract. Treat Hub publication as
unverified until the workflow succeeds and a registry digest is recorded. The image is
for CI/headless QA and is never a player-facing Windows build.

## Windows x86_64 Export

Use portable paths explicitly:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-export.ps1 `
  -Godot $godot `
  -TemplateArchive "C:\path\to\Godot_v4.7.1-stable_export_templates.tpz"
```

If those parameters are omitted, the script's `D:\Tools\Godot-4.7.1\...` paths are
maintainer-local defaults only. The verifier checks the preset, credentials/signing,
template/archive identities, PE x86_64 architecture, notices, export/startup logs, and
headless process startup before publishing below `.artifacts/builds/`.

Stable recorded identities from the dated handoff are:

| Artifact | SHA-256 |
|---|---|
| Official Godot export-template archive | `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Installed `windows_release_x86_64.exe` template | `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07` |
| `ROOM_407_THE_LAST_SHIFT.exe` (`117920024` bytes) | `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771` |

Do not copy per-run active/rollback `BUNDLE_SHA256` values into evergreen docs. Each V1
manifest binds a fresh `RUN_ID`; inspect the current ignored `VERIFY_COMPLETE.txt` and
record transaction identities only in a dated handoff.

The preset's `application/file_version` and `application/product_version` are `0.9.0.0`.
That is unreleased release-candidate metadata, not a Git tag, GitHub release, installer,
or shipping claim. Headless startup does not prove a rendered window, input, audio,
fullscreen behavior, target-device performance, or PDR-07.

## Physical Handoff

Required boundary: human physical production-window run; `ProjectRun` preferred,
`EditorF5` optional. From a clean, unchanged landing commit, choose **START SHIFT**, use
physical keyboard/mouse input, retain a same-run capture, fail/recover once during the
chase, exercise Settings/fullscreen/comfort controls, and reach visible credits.

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -Godot $godot `
  -LaunchMode ProjectRun `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

`ProjectRun` binds `--log-file` to the game process. `EditorF5` is optional and relies on
the post-credits `user://playthrough_pacing_last.txt` side-channel because the editor host
cannot log the separate F5 game process.

The runner defaults `-LaunchTimeoutSeconds` to 7200 (allowed 60–14400) and
`-MaxCombinedOutputBytes` to 16777216 / 16 MiB (allowed 1048576–67108864 / 1–64 MiB).
Its Windows Job Object terminates the complete process tree on timeout or combined-output
overflow. Its Godot `--version` preflight goes through the same Job path with a fixed
30-second timeout and 65536-byte output cap. Each evidence directory retains raw
`godot-version-stdout.log`, `godot-version-stderr.log`, `console-stdout.log`, and
`console-stderr.log`, plus combined `console.log` and `engine.log`.

Every hash-verified side-channel must remain unchanged and contain exactly one
`PLAYTHROUGH_PACING` payload. The runner rejects zero/duplicate side-channel payloads,
distinct mixed-run JSON, stale/baseline-identical data, malformed/coercible schema,
invalid verdicts, linked/escaped paths, source swaps, and output over limits.

An eligible payload and `evidence_package_ready: true` are instrumentation and provenance,
not human proof. A reviewer must watch the capture and complete the generated traversal,
pacing, chase, visual, audio, Settings, fullscreen, comfort, and input matrix before
PDR-07 can close.

## Rollback and Troubleshooting

The export verifier publishes transactionally and retains a verified `.previous` bundle.
If activation fails, it attempts automatic restoration. Do not hand-edit a manifest or
promote a partial staging directory; preserve logs, investigate, and rerun the verifier.
For a verified Hub publication, roll back by selecting a previously reviewed full-SHA
tag/digest rather than mutable `latest`. Without a recorded digest, registry rollback is
unverified.

| Symptom | Action |
|---|---|
| Godot executable not found | Put Godot 4.7.1 standard on `PATH` or pass the absolute `-Godot` path. |
| Export template/hash mismatch | Reinstall the official 4.7.1 standard templates and compare the archive/template hashes above. |
| Docs verifier reports `not indexed` | Stage the new local target and rerun; existence alone is insufficient. |
| ObjectDB warning appears in a canonical log | Check exit, markers, and error/assert scans; treat a separate zero-line audit as extra evidence only. |
| Hub has no digest | Confirm the main-push workflow ran and both repository secrets were configured; do not claim publication. |
| Physical runner times out or exceeds output | Investigate the process/log flood first; any override must stay inside the documented validation ranges. |
| Physical runner exits 2 | Read `summary.md`; incomplete or review-required evidence must not close PDR-07. |

## References

- [Testing matrix](./testing.md)
- [Known limitations](./limitations.md)
- [Project overview and PDR](./project-overview-pdr.md)
- [Final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
- [Dated physical operator handoff](../plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`verify-repository-docs.py`](../tests/verify-repository-docs.py)
