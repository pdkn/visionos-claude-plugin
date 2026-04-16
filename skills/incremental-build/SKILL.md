---
name: incremental-build
description: visionOS lens on incremental implementation. Thin vertical slices for RealityKit features - prove scene transitions work before adding entity hierarchies. One RealityKit component or system at a time. Each slice must build and run on the Apple Vision Pro simulator before expanding.
---

# Incremental Implementation - visionOS Lens

## Addy Parent

This skill extends `incremental-implementation` from agent-skills. Follow the generic "thin vertical slices, verify each before expanding" discipline there. This skill adds the RealityKit slice ordering and simulator verification gate specific to visionOS.

## visionOS Slice Ordering

For a visionOS feature, the recommended slice sequence is:

1. **Scene registration** - does the new `WindowGroup` / `ImmersiveSpace` / `Volume` appear in the app body and can it be opened?
2. **Empty scene renders** - does the scene load with zero content without crashing?
3. **First entity** - add a single primitive entity (a cube or sphere). Does it appear?
4. **First component** - add the simplest component the feature needs. Does it behave?
5. **First system** - if the feature needs a system, add it with a minimum update loop
6. **Further components and systems** - one at a time
7. **Integration with existing scenes** - only after each piece works standalone

Each step is a buildable slice. Do not skip steps even when the target feature seems far away.

## Simulator Verification Gate

Every slice must pass this gate before the next slice begins:

- [ ] `xcodebuild` succeeds (or XcodeBuildMCP `build_sim` succeeds)
- [ ] App launches on Apple Vision Pro simulator
- [ ] The specific slice content is visible or observable (log, entity, UI)
- [ ] No new warnings
- [ ] No new runtime errors in the log stream

If any check fails, stop and fix before expanding.

## 90Hz Verification

For any slice that adds to the render loop:
- Check that the slice does not introduce per-frame allocations
- Spot-check frame timing in Instruments if the slice is non-trivial

## When To Switch Skills

- `spec-driven-spatial` - if the spec is missing or incomplete
- `build-run-debug` - to execute the build-and-run step in the gate
- `debugging-triage` - when a slice fails to build or behaves unexpectedly
- `tdd-visionos` - to write a test for the new slice before implementing
- `perf-90hz` - if a slice shows frame timing issues
- `coding-standards` (see `references/xcode-commit-conventions.md`) - when a slice passes the gate and is ready to commit

## Guardrails

- Never add two components or systems in the same slice
- Never skip the simulator verification gate
- Never refactor inside a slice - finish the slice, then refactor separately
- Never expand a slice before the previous one passes the gate
