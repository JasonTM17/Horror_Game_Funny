---
date: 2026-07-16
session: environmental-interaction-polish
---

# Journal: 2026-07-16 — Environmental Interaction Polish

## Context

The specification had two explicit gaps: the lobby desk needed a usable drawer, and the fourth-floor fake door needed a clear response. Both had to stay optional and state-neutral.

## What Happened

- The first red assertion was honest but console-only: `PHYSICAL_ROUTE_ASSERT: continuous layout has no interactive night-desk drawer`.
- A controlled fail-fast rerun proved the harness stopped correctly with exit `2` in `3.03s`, instead of continuing through unrelated route checks.
- Debugging exposed a worse false confidence: the production ray could hit the drawer collider through the opaque desk while the drawer face remained hidden. Ray acquisition alone did not prove a visible interaction.
- The first motion contract also allowed a player to enter the drawer sweep after opening began. That was a real swept-player defect, not fixture noise.
- Accepted fixes moved the closed drawer face visibly beyond the desk, added a visibility/alignment assertion, rejected unsafe starting stances, and applied a reason-scoped movement-only lock during the bounded tween. The fake door received an aligned Interactable-only collider, explicit painted-handle feedback, cooldown, and positional tone. Both interactions now clean up tone/cache ownership; neither mutates story state.

## Reflection

The hidden-collider pass was frustrating because a green ray test looked authoritative while proving the wrong thing. The useful lesson is blunt: interaction tests must prove visible geometry and the full motion envelope, not merely that physics returned a collider.

## Decisions Made

| Decision | Rationale | Impact |
|---|---|---|
| Keep both interactions local and state-neutral | They are atmosphere, not progression | Inventory, flags, objective, stage, and checkpoint stay unchanged |
| Lock movement only during drawer motion | Prevent sweep entry without freezing camera/input | Safe open/close behavior with deterministic teardown |
| Do not delete files after the observed C: free-space decline | Its source was unproven and concurrent work was active | Avoided destroying unrelated or in-flight data |

## Verification

- Focused environmental check passed.
- Final canonical runner passed all `12/12` checks.
- The manual 15–20 minute pacing, audible-mix, and rendered-visual release gates remain open.

## Next Steps

- Record and review a physical F5 boot-to-credits run against the 15–20 minute target.
- Verify drawer/door presentation visually and both tones audibly in the real mix.

## Unresolved Questions

- Do the interactions read clearly and sound balanced during a physical playthrough?
- Does the complete run meet the 15–20 minute release gate?
