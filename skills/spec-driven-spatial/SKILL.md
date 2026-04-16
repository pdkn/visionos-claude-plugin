---
name: spec-driven-spatial
description: visionOS lens on spec-driven development. Load alongside agent-skills:spec-driven-development for the generic spec discipline. This skill adds the five visionOS questions every spec must answer (scene model, entity lifecycle, ARKit, SharePlay, entitlements) and worked examples showing complete specs for common feature types.
---

# Spec-Driven Development - visionOS Lens

## How to Use This Skill

Load `agent-skills:spec-driven-development` for the generic discipline of
requirements and acceptance criteria before code. Use this skill for the
visionOS-specific questions a spec must answer, and the worked examples that
show what complete visionOS specs look like.

## The Five visionOS Questions

A visionOS feature spec is incomplete until these are answered:

### 1. Scene Model
Window / Volume / Immersive Space / Mixed. Must justify against user spatial
intent. Usually comes out of `idea-refine`.

### 2. Entity Lifecycle
- Who creates entities, and in response to what?
- Who destroys them?
- What is their parent in the scene graph?
- Do they survive scene transitions?

### 3. ARKit Requirements
- Which providers? (`WorldTrackingProvider`, `HandTrackingProvider`, `PlaneDetectionProvider`, `SceneReconstructionProvider`, etc.)
- When does the session start and stop?
- What happens if authorization is denied or revoked?

### 4. SharePlay Requirements
- Shared experience, or single-user only?
- What state is shared, what is local?
- How does the feature handle join mid-session?

### 5. Privacy Entitlements
- Which entitlements in `.entitlements`?
- Which usage descriptions in `Info.plist`?
- What does the user see if permission is denied?

## Worked Example 1: Volumetric Chess

Output of ideation: feature is "spatial chess on a table", surface is volume,
metaphor is "real chess set".

### Scene Model
Volume. The chess board is a bounded 3D object. User sits at a table, the
board sits on the table.

### Entity Lifecycle
- **Board entity** created when the volume scene opens; destroyed when it closes
- **Piece entities** created from a snapshot of the game state; parented to the board
- **Captured pieces** move to an off-board "taken" slot but remain parented to the board
- **State persists** across app launches via a saved game file, not across scene open/close

### ARKit Requirements
`PlaneDetectionProvider` only, to place the volume on a real table on first
placement. No world tracking persistence - board position is scene-local. If
authorization denied, board floats at a default position above the user's lap.

### SharePlay Requirements
Out of scope for MVP. Future: two-player SharePlay with move-by-move sync and
turn indicators.

### Privacy Entitlements
- `.entitlements`: none beyond default
- `Info.plist`: `NSWorldSensingUsageDescription` = "Place the chess board on a surface"

### Acceptance Criteria
- Board loads in under 2 seconds
- Piece tap selects it and highlights legal moves
- Illegal moves are rejected with visual feedback
- Turn indicator always visible
- Works on Apple Vision Pro simulator
- Sustains 90Hz during piece manipulation

Hand off to `/plan "volumetric chess"`.

## Worked Example 2: Hand-Tracked Drawing Tool

Output of ideation: feature is "paint in 3D space with your hands", surface
is immersive, metaphor is "drawing in the air".

### Scene Model
Immersive Space. The feature requires free hand movement in a large volume
and owning the rendering of many stroke entities.

### Entity Lifecycle
- **Stroke entities** created when a pinch begins, extended during the pinch, finalized on release
- Parent: a root entity owned by the immersive space
- **Persist** across scene closures if user taps "save"; otherwise cleared
- Session-level state: current brush color, brush size, stroke count

### ARKit Requirements
- `HandTrackingProvider` at 90Hz, required
- `WorldTrackingProvider` optional for anchoring drawings to the real world (nice-to-have)
- Session starts when immersive space opens, stops when it closes
- If hand tracking authorization denied: show a message and dismiss the immersive space (feature unusable without hands)

### SharePlay Requirements
Out of scope for MVP. Future: shared canvas with other participants.

### Privacy Entitlements
- `.entitlements`: `com.apple.developer.arkit.hand-tracking`
- `Info.plist`: `NSHandsTrackingUsageDescription` = "Paint with your hands in 3D space"

### Acceptance Criteria
- Pinch-to-start-stroke works within 50ms of the gesture
- Strokes sustain at 90Hz regardless of count up to 1000 strokes
- Color picker accessible without leaving the immersive space
- Undo removes the last stroke
- Clear-all requires confirmation
- Exit is clearly signposted (no locked-in feeling)

Hand off to `/plan "hand-tracked drawing tool"`.

## Worked Example 3: Settings Panel

The minimal case. Many features have no spatial needs beyond their parent
app's existing surfaces.

### Scene Model
Window. Standard SwiftUI form.

### Entity Lifecycle
Not applicable - no RealityKit entities.

### ARKit Requirements
None.

### SharePlay Requirements
None.

### Privacy Entitlements
- `.entitlements`: no new entitlements
- `Info.plist`: no new usage descriptions

### Acceptance Criteria
- All user-facing preferences are reachable
- Changes persist via `@AppStorage`
- Form matches visionOS HIG (spacing, ornaments, materials)
- Reset-to-defaults confirms before applying
- VoiceOver labels on all controls

This looks trivially small for a spec - that is the point. A one-paragraph
spec is still a spec. The five questions are answered in 30 seconds rather
than 30 minutes, but they ARE answered.

Hand off to `/plan "settings panel"`.

## When To Switch Skills

- `idea-refine` - if the spec reveals the ideation was incomplete
- `spatial-architecture` - validate scene model against app-wide architecture
- `spatial-architecture` (see `references/adr-triggers.md`) - record the scene model decision if non-obvious
- `incremental-build` - after spec is approved, start implementation
- `agent-skills:spec-driven-development` - for the generic spec discipline

## Guardrails

- No implementation code until the five questions are answered
- The scene model decision cannot be deferred - every feature declares its surface
- Entitlements must be listed explicitly, not assumed available
- One spec per feature - do not combine features into one spec
- Acceptance criteria must be verifiable on the simulator, not subjective
