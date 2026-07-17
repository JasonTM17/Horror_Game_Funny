---
phase: 3
title: "Regression QA review and delivery"
status: pending
effort: "medium"
---

# Phase 3: Regression QA review and delivery

## Overview

Prove lifecycle and anti-spam behavior, review the diff, synchronize documentation,
and deliver small commits to `origin/main`.

## Implementation Steps

1. Add focused assertions for cue staging, one-shot behavior, collision absence,
   duration scaling, light restoration, and exit cleanup.
2. Run focused progression/settings-audio checks, then all 12 canonical checks and
   scan logs for engine/script/parse/assertion/leak failures.
3. Run adversarial code review and apply evidence-backed findings.
4. Update design, architecture, testing, roadmap/limitations only where behavior is
   verified; record disk, Git, and remote-parity evidence.
5. Commit by concern and push non-force.

## Success Criteria

- [ ] Focused and complete automated suites pass.
- [ ] Review finds no unresolved critical/high defects.
- [ ] Documentation matches code without claiming audible/manual certification.
- [ ] Worktree clean; local, origin tracking, and GitHub remote SHAs match.
