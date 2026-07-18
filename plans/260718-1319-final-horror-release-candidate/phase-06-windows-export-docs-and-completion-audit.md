---
phase: 6
title: "Windows export, docs, and completion audit"
status: pending
effort: medium
---

# Phase 6: Windows export, docs, and completion audit

## Goal

Create a reproducible Windows x86_64 build, smoke-test it, synchronize docs/plans, and
audit every requirement before focused Git delivery.

## Owned Files and Artifacts

- `.gitignore` and `export_presets.cfg` (preset tracked; binaries/templates ignored)
- optional safe export verification script under `tests/`
- ignored `.artifacts/builds/room407-windows-x86_64/`
- README, changelog, PDR/roadmap/limitations/testing, and this plan status

## Steps

1. Download/install matching official 4.7.1 standard Windows templates on drive D.
2. Update ignore rules narrowly so a credential-free `export_presets.cfg` is tracked
   while templates, credentials, and build output stay ignored; add the Windows preset.
3. Export by CLI, retain log/hash/size, launch the `.exe`, verify menu, and cleanly exit.
4. Rerun the canonical suite after export-config changes.
5. Run project-management sync, docs manager, secret scan, status/diff review, and evidence audit.
6. Update README/changelog/PDR/roadmap/limitations/testing only from current proof.
7. Use git manager for focused conventional commits and non-force delivery; verify final parity.

## Success Criteria

- [ ] Matching official template and reproducible export preset are used.
- [ ] Ignored `.exe` launches to the production menu.
- [ ] Post-export suite, review, docs, secret scan, and audit pass.
- [ ] Plan/PDR/roadmap statuses match actual evidence.
- [ ] Git history is focused and final worktree/delivery state is explicit.
