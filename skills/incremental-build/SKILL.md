---
name: incremental-build
description: visionOS lens on incremental implementation. Load alongside agent-skills:incremental-implementation for the generic thin-slice discipline. This skill adds the RealityKit-specific slice ordering (scene registration -> empty scene -> first entity -> first component -> first system) and worked examples showing real features built slice by slice.
---

# Incremental Build - visionOS Lens

## How to Use This Skill

Load `agent-skills:incremental-implementation` for the generic
thin-vertical-slice discipline. Use this skill for the visionOS slice
ordering and the simulator verification gate.

## The Slice Ordering

For any visionOS feature, build in this order. Do not skip steps even when
the target seems far away.

1. **Scene registration** - the new `WindowGroup` / `ImmersiveSpace` / `Volume` appears in the app body and can be opened
2. **Empty scene renders** - the scene loads with zero content without crashing
3. **First entity** - a single primitive (cube, sphere) appears at a fixed position
4. **First component** - the simplest component the feature needs is attached and behaves
5. **First system** - if the feature needs a system, add it with a minimum update loop
6. **Further components and systems** - one at a time
7. **Integration with existing scenes** - only after each piece works standalone

Each step is a buildable slice. Each slice must pass the verification gate.

## The Simulator Verification Gate

Every slice must pass before the next begins:

- [ ] `xcodebuild` succeeds (via XcodeBuildMCP or shell)
- [ ] App launches on Apple Vision Pro simulator
- [ ] The slice content is visible or observable (log, entity, UI)
- [ ] No new warnings
- [ ] No new runtime errors in the log stream

If any check fails: stop, fix, commit the fix, then expand.

## 90Hz Verification

For any slice that adds to the render loop:
- Check the slice does not introduce per-frame allocations
- Spot-check frame timing in Instruments if the slice is non-trivial

## Worked Example 1: Hand-Tracked Paint Tool

Spec: user pinches to start a stroke, moves hand to extend it, releases to
finalize. Immersive space. Hand tracking required.

### Slice 1: ImmersiveSpace registration
Add `ImmersiveSpace(id: "paint") { EmptyView() }` to `App.body`. Add a
button to the root window that calls `openImmersiveSpace(id: "paint")`.

**Verify:** Button opens the immersive space. The view is blank (expected).
**Commit:** `feat(scene): register paint immersive space`

### Slice 2: Render empty scene
Change the immersive space content to `RealityView { content in }`.

**Verify:** Scene opens without crashing. Still blank.
**Commit:** `feat(paint): render empty RealityView in immersive space`

### Slice 3: First entity at fixed position
In `RealityView`'s `make` closure, add a single sphere entity at `[0, 1.5, -1]`.

**Verify:** Sphere is visible 1.5m in front of the user at head height.
**Commit:** `feat(paint): spawn test sphere at fixed position`

### Slice 4: Hand tracking session
Set up `ARKitSession` with a `HandTrackingProvider`. Stream updates. Log
joint positions to verify the stream works. Do not render anything yet.

**Verify:** Console logs show hand joint updates at 90Hz when hands are visible.
**Commit:** `feat(paint): wire up hand tracking session`

### Slice 5: Render one hand joint as an entity
Remove the test sphere. Move the index-finger-tip joint's position into a
sphere entity, updating per frame.

**Verify:** A small sphere follows your index fingertip in real time.
**Commit:** `feat(paint): render index fingertip as sphere`

### Slice 6: Pinch detection
Detect pinch by measuring distance between thumb tip and index tip. Log
"pinch started" and "pinch ended" events.

**Verify:** Console events correlate with actual pinches.
**Commit:** `feat(paint): detect pinch gesture from hand joints`

### Slice 7: Create stroke entity on pinch-start
On pinch-start, spawn a `ModelEntity` with a thin cylinder. Position it at
the fingertip. Do not extend it yet.

**Verify:** Each pinch creates a tiny marker at the pinch-start position.
**Commit:** `feat(paint): spawn stroke entity on pinch start`

### Slice 8: Extend stroke during pinch
While pinched, extend the stroke entity by adding new segments as the
fingertip moves.

**Verify:** A trail appears as you move your pinched hand. Drops when you
release.
**Commit:** `feat(paint): extend stroke during active pinch`

### Slice 9: Finalize on release
Ensure released strokes persist in the scene. Start a new stroke on next
pinch.

**Verify:** Multiple strokes remain visible after release.
**Commit:** `feat(paint): finalize stroke on pinch release`

### Slice 10: Color picker
Add a window-based color picker. Store current color in shared state. Use
it when spawning new strokes.

**Verify:** Strokes spawn in the currently selected color.
**Commit:** `feat(paint): add color picker with shared state`

At this point the core feature works. Additional slices would add brush
size, undo, clear-all, save, etc - each following the same pattern.

## Worked Example 2: Volumetric Photo Viewer

Spec: display a photo as a 3D object the user can rotate and scale in a
volume scene.

### Slice 1: Volume scene registration
Add `WindowGroup(id: "photo") { EmptyView() }.windowStyle(.volumetric)` to
`App.body`.

**Verify:** Window opens as a volume placeholder.
**Commit:** `feat(scene): register photo volume`

### Slice 2: Display a hard-coded Model3D
Replace `EmptyView` with `Model3D(named: "placeholder.usdz")`.

**Verify:** A placeholder 3D model renders in the volume.
**Commit:** `feat(photo): display placeholder Model3D`

### Slice 3: Load a photo as a texture on a quad
Replace `Model3D` with a `RealityView` that creates a quad entity and
applies a `UnlitMaterial` with a bundled photo texture.

**Verify:** The photo renders as a flat quad in the volume.
**Commit:** `feat(photo): render photo on textured quad`

### Slice 4: Manipulation component
Add a `ManipulationComponent` to the quad entity.

**Verify:** User can grab and move the photo; it stays within the volume bounds.
**Commit:** `feat(photo): enable drag-to-position with ManipulationComponent`

### Slice 5: Pinch-to-scale and rotation
Configure `ManipulationComponent` behaviours for scale and rotate.

**Verify:** Pinch to scale, twist to rotate.
**Commit:** `feat(photo): enable scale and rotate on photo`

### Slice 6: Photo picker
Add a button that opens a SwiftUI `PhotosPicker`. On selection, update the
entity's material with the chosen image.

**Verify:** Picking a photo from the library replaces the displayed photo.
**Commit:** `feat(photo): load user-selected photo into volume`

## When To Switch Skills

- `spec-driven-spatial` - if the spec is missing or incomplete
- `build-run-debug` - to execute the build-and-run step in the gate
- `debugging-triage` - when a slice fails to build or behaves unexpectedly
- `tdd-visionos` - to write a test for the new slice before implementing
- `perf-90hz` - if a slice shows frame timing issues
- `coding-standards` (see `references/xcode-commit-conventions.md`) - when a slice passes the gate and is ready to commit
- `agent-skills:incremental-implementation` - for the generic slicing discipline

## Guardrails

- Never add two components or systems in the same slice
- Never skip the simulator verification gate
- Never refactor inside a slice - finish the slice, then refactor separately
- Never expand a slice before the previous one passes the gate
- Commit at every green gate
