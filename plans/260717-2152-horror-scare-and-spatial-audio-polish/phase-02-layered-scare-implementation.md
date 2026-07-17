---
phase: 2
title: "Layered scare implementation"
status: pending
effort: "medium"
---

# Phase 2: Layered scare implementation

## Overview

Implement deliberate, story-specific sequences without progression side effects.

## Implementation Steps

1. Add a small scene-local sequence helper for scaled pause-safe waits, spatial cue
   emitters, bounded light pulses, and deterministic teardown.
2. Re-stage floor arrival as a distant mechanical warning, light response, silhouette
   reveal, then display failure.
3. Give the photo and rabbit memories directional audio/lighting identities; retain
   the cassette's camera-driven reveal and make its lifecycle scale/teardown safe.
4. Build Room 407 as a two-stage low warning and eye/sting reveal that resolves before
   chase ownership begins.

## Success Criteria

- [ ] Four production sequences have distinct anticipation/reveal/aftermath timing.
- [ ] No temporary actor, emitter, or altered light survives cleanup.
- [ ] No collider, movement lock, checkpoint, inventory, or voice contract changes.
- [ ] Files stay modular and public APIs remain compatible.
