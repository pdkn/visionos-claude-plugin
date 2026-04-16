---
name: perf-90hz
description: visionOS lens on performance optimization. Load alongside agent-skills:performance-optimization for the generic measure-first discipline. This skill adds the Apple Vision Pro 90Hz render budget, Instruments templates specific to visionOS, and worked examples showing baseline-measure-fix-verify cycles.
---

# Performance at 90Hz - Lens

## How to Use This Skill

Load `agent-skills:performance-optimization` for the generic discipline
(measure first, optimize only what matters, remeasure after each change).
Use this skill for the visionOS-specific 90Hz budget, Instruments template
choices, and worked examples.

## The 90Hz Budget

Apple Vision Pro renders at 90Hz. You have **11.1ms per frame** total.
Subtract system compositor overhead and realistically you have **~8ms** for
application work.

Consequences of exceeding:
- Missed frames (juddery motion, noticeable on hand tracking)
- Dropped input (gesture lag)
- Thermal throttling over time

## Instruments Template Choices

| Template | Use for |
|---|---|
| Time Profiler | CPU hotspots in RealityKit systems |
| Allocations | Per-frame allocations (target: zero) |
| System Trace | Frame timing, compositor overhead |
| Metal System Trace | GPU shader costs, draw call counts |
| RealityKit Trace | Entity update costs, component access |
| ARKit Trace | Provider update frequency and processing cost |

Device only for final verification. Simulator perf does not predict device.

## What to Measure Before Changing Anything

1. Capture a baseline with Instruments
2. Identify the top 3 cost centres
3. Optimize ONE, remeasure
4. Decide if further optimization pays back

A 10% win on a 0.1ms operation is noise. Focus on the 2ms+ cost centres.

## Worked Example 1: Reducing a Particle System's Render Cost

**Feature:** star field in an immersive space, 2000 particles.

### Baseline

Instruments > Time Profiler.

- Total frame time: 14ms (misses 90Hz regularly)
- `StarRenderSystem.update(context:)` takes 9ms per frame
- Inside that: 6ms is `EntityQuery(.has(StarComponent.self))` re-running every frame
- Remaining 3ms is actual per-entity work

### Target

Get total frame time below 10ms.

### Decide what to change

The 6ms query cost is the biggest single cost. Query results are stable
(no stars added/removed at runtime). Cache the query result.

### Change

```swift
// Before: runs the query every frame
class StarRenderSystem: System {
    func update(context: SceneUpdateContext) {
        for entity in context.scene.performQuery(.has(StarComponent.self)) {
            renderStar(entity)
        }
    }
}

// After: cache entities, invalidate on scene change
class StarRenderSystem: System {
    private var cachedEntities: [Entity] = []

    func update(context: SceneUpdateContext) {
        if cachedEntities.isEmpty {
            cachedEntities = Array(context.scene.performQuery(.has(StarComponent.self)))
        }
        for entity in cachedEntities {
            renderStar(entity)
        }
    }

    func invalidateCache() { cachedEntities.removeAll() }
}
```

### Remeasure

- Total frame time: 6ms (well under budget)
- Query cost: 0ms (cached)
- Per-entity work: 3ms (unchanged)

### Commit

`perf(realitykit): cache StarRenderSystem query result to save 6ms/frame`

## Worked Example 2: Flattening an Entity Hierarchy

**Feature:** a scene with 500 UI labels, each attached to a RealityKit
entity via a `ViewAttachmentComponent` under a deep hierarchy.

### Baseline

- Total frame time: 12ms
- `Transform` propagation: 4ms
- Hierarchy depth: 8 levels from root to leaf (label)

Time Profiler shows most of the 4ms is transform recomputation walking the
hierarchy.

### Target

Reduce transform propagation cost to <1ms.

### Change

Flatten the hierarchy. Original structure:
```
Root
  └ GroupA (organizational)
    └ GroupB (organizational)
      └ GroupC (organizational)
        └ LabelContainer (organizational)
          └ AttachmentHolder (organizational)
            └ ViewAttachment
              └ Label (leaf)
```

Intermediate `Group*` entities exist only for code organization. Move the
ViewAttachment up to be a direct child of Root. The hierarchy becomes:
```
Root
  └ ViewAttachment
    └ Label
```

The code change is in the scene setup - instead of parenting through
organizational entities, parent directly.

### Remeasure

- Total frame time: 8ms (clears the budget)
- `Transform` propagation: 0.8ms

### Commit

`perf(scene): flatten label hierarchy to reduce transform propagation`

## Worked Example 3: Eliminating Per-Frame Allocation in Hand Tracking Path

**Feature:** paint app that draws stroke segments based on hand positions.

### Baseline

- Total frame time: 10ms typical, spikes to 18ms
- Allocations template shows ~500 `SIMD3<Float>` allocations per frame
- GC pressure causes the 18ms spikes

### Target

Zero allocations per frame in the render loop.

### Change

Identify allocation site:

```swift
// Before: allocates on every call
func updateStroke(_ stroke: Stroke, with handPosition: SIMD3<Float>) {
    stroke.points.append(handPosition)  // Array.append reallocates
    stroke.normals = computeNormals(stroke.points)  // new array
    stroke.refresh()
}
```

Fix:

```swift
// Pre-allocate capacity, reuse normal buffer in-place
func updateStroke(_ stroke: Stroke, with handPosition: SIMD3<Float>) {
    if stroke.points.capacity < stroke.points.count + 1 {
        stroke.points.reserveCapacity(stroke.points.capacity * 2)
    }
    stroke.points.append(handPosition)
    computeNormals(into: &stroke.normals, from: stroke.points)
    stroke.refresh()
}
```

### Remeasure

- Total frame time: 6ms typical, no spikes
- Allocations per frame: 0

### Commit

`perf(paint): eliminate per-frame allocations in stroke update`

## Common visionOS-Specific Cost Centres

### RealityKit Systems
- Minimize component queries: cache query results across frames if state is stable
- Prefer `EntityQuery.query.unowned` where possible
- Avoid mutating the entity hierarchy every frame

### ARKit Providers
- `HandTrackingProvider` runs at 90Hz - any code in its stream must fit the budget
- Filter provider updates aggressively - skip samples you do not need

### Entity Hierarchies
- Deep hierarchies increase transform propagation cost
- Flatten where logical grouping isn't needed
- Avoid per-frame hierarchy mutations

### SwiftUI Integration
- `RealityView`'s `update` closure runs on SwiftUI state changes - keep it cheap
- `Model3D` reloads on URL or binding changes - cache loaded models

### Allocations
- No `Array.append` without pre-allocated capacity
- No `Dictionary` mutation (use struct-of-arrays)
- No `String` interpolation in hot paths
- No optional unwraps that allocate

## When To Switch Skills

- `coding-standards` - when the issue is idiomatic Swift rather than performance
- `realitykit` - when a component/system design change is needed
- `debugging-triage` - when slowness masks a correctness bug
- `tdd-visionos` - to write a perf regression test
- `agent-skills:performance-optimization` - for the generic discipline

## Guardrails

- Never optimize based on a hunch - profile first
- Do not assume macOS or iOS performance advice applies to 90Hz visionOS
- Profile on device for final verification - simulator perf does not predict device
- A 10% win on a 0.1ms op is noise - focus on top cost centres
- Add a perf regression test after any non-trivial fix
