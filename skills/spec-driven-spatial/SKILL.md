---
name: spec-driven-spatial
description: visionOS lens on spec-driven development. Gates every visionOS feature on a scene model decision before any code. Adds the spatial concerns (scene type, entity lifecycle, ARKit, SharePlay, entitlements) that a generic spec misses.
---

# Spec-Driven Development - visionOS Lens

## Addy Parent

This skill extends `spec-driven-development` from agent-skills. Follow the generic "requirements and acceptance criteria before code" discipline there. This skill adds the spatial questions a visionOS feature spec must answer.

## The visionOS Questions

A spec for a visionOS feature is incomplete until these are answered:

### 1. Scene Model
Which surface does this feature own?
- **Window** - flat UI, 2D content, no spatial placement
- **Volume** - bounded 3D content, user-sized region
- **Immersive Space** - full spatial control, replaces or augments the room
- **Mixed** - multiple scene types interacting (window controlling an immersive space)

No default. Every spec must pick one and justify it against the user's spatial intent.

### 2. Entity Lifecycle and Ownership
- Who creates entities? (view model, RealityKit system, anchor callback)
- Who destroys them?
- What is their parent in the scene graph?
- Do they persist across scene transitions?

### 3. ARKit Requirements
- Which providers does this need? (`WorldTrackingProvider`, `HandTrackingProvider`, etc.)
- When does the session start? When does it stop?
- What does the feature do if authorization is denied or revoked?

### 4. SharePlay Requirements
- Is this a shared experience?
- What state is shared? What is private?
- How does the feature handle join mid-session?

### 5. Privacy Entitlements
- Which entitlements are required in `.entitlements`?
- Which privacy usage descriptions are required in `Info.plist`?
- What does the user see if permission is denied?

## Acceptance Criteria

visionOS-specific criteria the spec must include:
- Feature works on Apple Vision Pro simulator (specify target visionOS version)
- Scene transitions succeed without losing state (where applicable)
- ARKit session authorization is handled gracefully
- Feature degrades cleanly when entitlements are missing

## When To Switch Skills

- `spatial-architecture` - validate scene model against app-wide architecture
- `spatial-architecture` - design the state ownership implied by the spec
- `adr-spatial` - record the scene model decision if non-obvious
- `incremental-build` - after spec is approved, start implementation

## Guardrails

- No implementation code until the five questions are answered
- The scene model decision cannot be deferred - every feature declares its surface
- Entitlements must be listed explicitly, not assumed available
- One spec per feature - do not combine features into one spec
