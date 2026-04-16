---
name: api-model-state-design
description: Design data models, state ownership, observation patterns, and module boundaries for visionOS apps. Covers the Observation framework (@Observable, @State, @Binding), state scopes from app to view, RealityKit entity state vs SwiftUI view state, cross-scene state sync, and public vs internal API contracts.
---

# API, Model, and State Design

## Addy Parent

This skill extends `api-and-interface-design` from agent-skills. Follow the generic "design interfaces before implementation" discipline there. This skill adds the visionOS-specific state ownership topology and SwiftUI/RealityKit observation patterns.

## Quick Start

Before writing a model or view hierarchy, answer:
1. Who owns this state? (app, scene, window, volume, immersive, view)
2. Who observes it? (views only, or also RealityKit systems)
3. How does it cross scene boundaries?
4. What is public API vs internal detail?

Get these answers into a small diagram or bullet list before touching code.

## State Ownership Scopes

| Scope | Pattern | Example |
|-------|---------|---------|
| App-wide | `@Observable` singleton at app entry | Auth session, user preferences |
| Scene-scoped | `@Observable` stored in scene's view model | Window-local UI state |
| Immersive-scoped | `@Observable` tied to immersive space lifecycle | Spatial world state |
| Feature-scoped | `@Observable` for a feature coordinator | Multi-view flows |
| View-local | `@State` in a SwiftUI view | Transient UI state |

**Rule of thumb:** the narrowest scope that correctly captures the state's lifetime.

## Observation Framework

### @Observable

Swift's Observation framework replaces `ObservableObject`:

```swift
@Observable
class ImmersiveState {
  var selectedEntityID: UUID?
  var isRecording: Bool = false
}
```

Use `@Observable` for reference types that multiple views read/write.

### @State

For local, transient state owned by a single view:

```swift
@State private var isExpanded: Bool = false
```

### @Binding

For passing write access down the view tree:

```swift
struct Toggle {
  @Binding var isOn: Bool
}
```

### @Environment for @Observable

Inject app-wide `@Observable` state via environment:

```swift
.environment(AppState())

// In a view:
@Environment(AppState.self) private var app
```

## Entity State vs View State

RealityKit entities have state too (components). Decide ownership deliberately:

| State | Owner | Example |
|-------|-------|---------|
| Position, rotation, scale | Entity (Transform component) | Where an object is in the world |
| Selection, UI appearance | SwiftUI view model | Which entity is currently highlighted in UI |
| Physics properties | Entity (PhysicsBodyComponent) | Mass, restitution |
| User preferences about entity | App-level model | "Hide this entity" toggle |

The rule: entity components hold state that belongs to the simulation; view models hold state that belongs to the UI.

## Cross-Scene State Sync

When state must flow between a window and an immersive space:
- App-level `@Observable` injected into both scenes
- Neither scene should hold the canonical copy
- Both read and write through the shared model
- Use computed properties or `didSet` for derived state

## Module Boundaries

When a feature becomes a module:

### Public API

Export only what callers need:
- The feature's main view (if reused)
- The feature's `@Observable` coordinator (if external code drives it)
- Event types (for app-level routing)

### Internal Detail

Keep internal:
- Subviews
- Helper models
- Platform glue (RealityKit component registration, ARKit provider setup)

### Stability

Once a type is public:
- Breaking changes require migration plans
- Add properties as optional or with defaults
- Deprecate before removing

## Guardrails

- Do not let a transient view own long-lived immersive state
- Do not use `@State` for data that outlives the view
- Do not duplicate state between SwiftUI and RealityKit - pick one owner
- Do not make internal types public to avoid an import

## When To Switch Skills

- Switch to `coding-standards` for the mechanics of `@Observable` and concurrency
- Switch to `spatial-architecture` for scene topology and surface choice
- Switch to `incremental-build` when implementing a chosen model

## Output Expectations

- The ownership map (who owns what state at which scope)
- The public API surface
- The observation pattern for each state type
- Any cross-scene sync strategy
