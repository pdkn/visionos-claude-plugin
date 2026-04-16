---
name: perf-90hz
description: Measure-first performance optimization for visionOS apps. Enforces the 90Hz render budget on Apple Vision Pro. Covers frame budget math, Instruments profiles, RealityKit system cost analysis, ARKit provider overhead, hand tracking update rate verification, and allocation-free render loop patterns.
---

# Performance at 90Hz

## Addy Parent

This skill extends `performance-optimization` from agent-skills. Follow the generic "measure first, optimize only what matters" discipline there. This skill adds the visionOS-specific 90Hz budget and RealityKit/ARKit cost analysis.

## The 90Hz Budget

Apple Vision Pro renders at 90Hz. You have **11.1ms per frame** total. Subtract system compositor overhead and you realistically have **~8ms** for application work per frame.

If code in the render loop regularly exceeds this, users see:
- Missed frames (juddery motion, noticeable on hand tracking)
- Dropped input (gesture lag)
- Thermal throttling over time (frame rate falls)

## Measure First

Never optimize without a profile. The target is always:
1. Capture a baseline with Instruments
2. Identify the top 3 cost centres
3. Optimize ONE, remeasure
4. Decide if further optimization pays back

### Instruments Templates

| Template | Use For |
|----------|---------|
| Time Profiler | CPU hotspots in RealityKit systems |
| Allocations | Render-loop allocations (target: zero per frame) |
| System Trace | Frame timing, compositor overhead |
| Metal System Trace | GPU shader costs, draw call counts |
| RealityKit Trace | Entity update costs, component access |

### What to Look For

- Single functions eating >2ms per frame
- Any `Array` or `Dictionary` allocation inside a system `update()`
- Component queries running every frame when state rarely changes
- `String` formatting inside hot paths (log messages, debug labels)
- Closure captures causing ARC retain/release cycles

## visionOS Cost Centres

### RealityKit Systems

- Minimize component queries: cache query results across frames if state is stable
- Prefer `EntityQuery.query.unowned` over full queries when possible
- Avoid mutating the entity hierarchy every frame - batch structural changes

### ARKit Providers

- `HandTrackingProvider` runs at 90Hz - any code in its stream must fit the budget
- `WorldTrackingProvider` updates are less frequent - safe to process per-anchor
- Filter provider updates aggressively: skip samples you do not need

### Entity Hierarchies

- Deep hierarchies increase transform propagation cost
- Flatten where possible (parent entities only where logical grouping is needed)
- Avoid per-frame hierarchy mutations

### SwiftUI Integration

- `RealityView`'s `update` closure runs on SwiftUI state changes - keep it cheap
- `Model3D` reloads on URL or binding changes - cache models

## Allocation-Free Render Loops

In any code path that runs per-frame:
- No `Array.append` without pre-allocated capacity
- No `Dictionary` mutation (use struct-of-arrays instead)
- No `String` interpolation (use `StaticString` or log outside the hot path)
- No optional unwraps that allocate (use unsafe unwraps after verifying)

## Guardrails

- Never optimize based on a hunch - capture a profile first
- Do not assume macOS or iOS performance advice applies to visionOS 90Hz
- Profile on device for final verification - simulator perf does not predict device
- A 10% improvement on a 0.1ms operation is meaningless - focus on the top cost

## When To Switch Skills

- Switch to `coding-standards` when the issue is idiomatic Swift rather than performance
- Switch to `realitykit` when a component or system design change is needed
- Switch to `debugging-triage` when slowness masks a correctness bug

## Output Expectations

- Baseline profile name and capture settings
- Top 3 cost centres with measured times
- The ONE change you made and the new measurement
- Decision: ship, optimize further, or revert
