# Horror Game Funny - Project Roadmap

## Delivery State

The implementation roadmap is sequential and preserves one continuous gameplay scene.

| Phase | Scope | Evidence | Status |
|---|---|---|---|
| 1 | Terminal ending and capture-recovery race | `30199b7`, `5aea891`, focused progression | Complete |
| 2 | Navigation-safe right-left-right chase route | `0a1ba94`, layout/physical-route checks | Complete |
| 3 | Voiced two-step interactive epilogue and checkpoint isolation | `a4a3173`, `aaae49a`, 12-check suite | Complete |
| 4 | Physical release evidence, media capture and final handoff | Fresh F5 run, telemetry, screenshots, GIF | In progress |

## Phase 4 Worklist

- [ ] Obtain authorization for physical Godot window control or receive a same-run physical gameplay recording and telemetry from the user.
- [ ] Run a fresh boot-to-credits session with physical keyboard/mouse input; fail and recover once during the chase.
- [ ] Preserve the session's single `PLAYTHROUGH_PACING` payload and inspect chapter/total timing against the 900–1200 second target.
- [ ] Review chase clearance/fairness, red-guide readability, darkness/flicker/grain comfort, six ending voice lines, audio balance, pause/Settings, fullscreen, and relaunch behavior during the live run.
- [x] Run the reproducible staged Godot capture tour; visually review and commit four optimized PNGs plus a derived visual-reference GIF under `docs/screenshots/`. This media subtask does not satisfy the physical-run or perceptual gates.
- [x] Add repository-relative gallery links, capture instructions, evidence limits, and media provenance to project documentation.
- [ ] Complete the physical evidence package, rerun release checks, review the final diff/secrets/worktree state, and push the final evidence commit.

The current source-level route/timing audit is recorded in [`phase-04-pacing-audit-20260716.md`](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-04-pacing-audit-20260716.md). It is planning evidence only; it does not replace the physical capture gate.

## Guardrails

- Do not add loading screens or split the route into levels to manufacture duration.
- Do not treat compressed headless timing, checkpoint-start sessions, screenshots of editor views, concept art, or AI-generated images as physical gameplay evidence.
- Keep media files small and readable; preserve the original capture outside Git.
- Monitor C:/D: before and after recording, voice processing or media encoding.
- Commit small focused clusters and verify `HEAD == origin/main` after every push.

## Release Exit

The parent goal can close only after Phase 4 has real same-run physical evidence, human review notes, retained reviewed documentation media, clean tests, clean secrets scan, clean worktree and exact remote parity. The completed staged-media subtask does not close Phase 4.

## References

- [Project overview and PDR](./project-overview-pdr.md)
- [Testing matrix](./testing.md)
- [Staged visual-capture tour](./testing.md#reproducible-visual-capture-tour)
- [Phase 4 plan](../plans/260716-2113-chase-reliability-and-climax-polish/phase-04-qa-review-and-delivery.md)
