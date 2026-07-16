---
phase: 1
title: Reproduction and Project Stability
status: complete
dependencies: []
---

# Phase 1: Reproduction and Project Stability

## Evidence to Establish

1. Run Godot 4.7.1 editor import against an isolated copy and compare
   `project.godot` byte-for-byte.
2. Separate deprecated/unknown setting removal from harmless editor
   canonicalization.
3. Add a runner guard that fails when editor import mutates tracked project
   settings, then verify the guard fails against the current file.

## Files

- Modify `project.godot` only after reproduction identifies the exact rewrite.
- Modify `tests/run-headless-tests.ps1` to preserve the twelve-check contract
  while checking project-setting stability inside `editor-import`.

## Validation

- Isolated reproduction diff explains every changed line.
- `editor-import` exits zero and leaves the project-setting checksum unchanged.
- Full worktree returns clean after the check.
