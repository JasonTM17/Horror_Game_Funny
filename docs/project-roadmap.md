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

1. Obtain authorization for physical Godot window control or receive a same-run gameplay recording and telemetry from the user.
2. Run a fresh boot-to-credits session with physical keyboard/mouse input; fail and recover once during the chase.
3. Preserve the session's single `PLAYTHROUGH_PACING` payload and inspect chapter/total timing against the 900–1200 second target.
4. Review chase clearance, red-guide readability, darkness/flicker/grain comfort, six ending voice lines, audio balance, pause/settings and relaunch behavior.
5. Capture real in-game stills and a short gameplay recording. Export an optimized GIF with FFmpeg, keep source capture outside the repository, and commit only reviewed deliverables under `docs/screenshots/`.
6. Embed repository-relative media links in the final documentation, render-check them, run the canonical suite again, and push the final evidence commit.

## Guardrails

- Do not add loading screens or split the route into levels to manufacture duration.
- Do not treat compressed headless timing, checkpoint-start sessions, screenshots of editor views, concept art, or AI-generated images as physical gameplay evidence.
- Keep media files small and readable; preserve the original capture outside Git.
- Monitor C:/D: before and after recording, voice processing or media encoding.
- Commit small focused clusters and verify `HEAD == origin/main` after every push.

## Release Exit

The parent goal can close only after Phase 4 has real same-run physical evidence, human review notes, rendered screenshots, an optimized GIF, clean tests, clean secrets scan, clean worktree and exact remote parity.

## References

- [Project overview and PDR](./project-overview-pdr.md)
- [Testing matrix](./testing.md)
- [Phase 4 plan](../plans/260716-2113-chase-reliability-and-climax-polish/phase-04-qa-review-and-delivery.md)
