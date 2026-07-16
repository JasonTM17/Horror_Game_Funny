# Phase 4 - Full QA, Review, Documentation, and Delivery

## Files

- `README.md`
- `docs/game-design.md`
- `docs/architecture.md`
- `docs/testing.md`
- `docs/limitations.md`
- `docs/asset-credits.md`
- `CHANGELOG.md`
- `plans/260715-0936-room-407-the-last-shift/plan.md`
- `plans/260716-2113-chase-reliability-and-climax-polish/*`

## Steps

- [x] Run focused checks, editor import, then the exact 12-check canonical suite.
- [x] Scan logs for engine/script/assert/leak failures and confirm temp-profile cleanup.
- [x] Run spec, quality, and adversarial review; fix accepted findings and rerun affected checks.
- [x] Sync documentation, plan statuses, report, asset provenance, and truthful remaining gates.
- [ ] Define final documentation media slots; before the parent game goal closes, capture real gameplay screenshots and an optimized GIF, embed them with repository-relative links, and verify they render.
- [x] Check C:/D:, staged secrets, branch divergence, remote URL, and commit split.
- [x] Push without force and verify `HEAD == origin/main == refs/heads/main`.

Current source-level pacing audit: [`reports/phase-04-pacing-audit-20260716.md`](reports/phase-04-pacing-audit-20260716.md). It documents the authored route lower bound and keeps the physical F5 capture gate open.

## Acceptance

- All 12 canonical checks exit zero with required markers and no scanned failures.
- Final game documentation includes real in-game screenshots and a readable optimized GIF; placeholders do not satisfy this gate.
- Worktree is clean; no local tools/models/cache/secrets are tracked.
- Commits are focused and remote parity is exact.
- Parent goal remains in progress until physical/perceptual evidence exists.
