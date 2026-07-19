# Tester re-verification after review fixes — 2026-07-19

## Scope

This is the root-agent re-run after the cycle-1 review fixes. It records only commands
actually executed against the current working tree; it does not replace the human F5
gate or claim a Docker image publication.

## Fresh command results

| Gate | Result | Evidence |
|---|---|---|
| PowerShell parse (three touched harnesses) | PASS | `ScriptBlock.Create` completed without an exception |
| Focused physical-evidence regression | PASS | exit `0`; `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK`; `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK` |
| Canonical Godot host suite | PASS | exit `0`; `run-headless-tests.ps1` reported `SuiteExit 0`, `Checks 12/12`, duration about 71.6 s |
| Docker packaging contract checks | PASS | PowerShell verifier and Bash verifier both exited `0` |
| Windows export adversarial harness | PASS | active/previous bundle identities remained unchanged after negative cases |
| Secret scan | PASS | `SECRET_PATTERN_SCAN_OK` |
| CI YAML, links, media, cover | PASS | safe YAML parse, Markdown/media checks, and cover IHDR/dimension/hash checks passed |
| Diff hygiene | PASS | `git diff --check` exited `0` |

## Export identity captured

- Active executable SHA-256: `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`
- Active bundle SHA-256: `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d`
- Previous executable SHA-256: `8384735b0906e243c198f4b2203a96aa53c910819327edfa30fb4035da6c71c2`
- Previous bundle SHA-256: `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701`

The adversarial run verified that rejected candidates do not mutate either accepted
bundle. The current executable and previous bundle are local verification artifacts and
are intentionally not staged into Git.

## Environment exception

The Docker client is installed, but the Linux daemon endpoint
`dockerDesktopLinuxEngine` is unavailable in this environment. The live compose build/run
and Docker Hub publication therefore remain **unverified**, not passed. The CI workflow
is the conditional publisher after an authorized push when its registry secrets exist.

## Boundary

All automated checks above are repository/headless evidence. PDR-07 still requires a
human physical keyboard/mouse run from `START SHIFT` to visible credits, a same-run
capture, an eligible 900–1200 second pacing payload, and the perception review matrix.
