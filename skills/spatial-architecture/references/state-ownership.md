# State Ownership

Use this file when deciding what owns state and lifecycle responsibilities.

## Ownership Map

| Scope | Owns |
| --- | --- |
| App | top-level scene declarations, app-wide dependency injection, persistent preferences |
| Scene | navigation, presentation state, scene-local selection, immersive entry and exit coordination |
| Feature model or coordinator | async work, service coordination, long-lived feature state |
| Reality controller or system | entity graph mutation, component updates, simulation behavior |
| View | ephemeral local UI state and intent dispatch |

## State Placement Defaults

- `@State`: local control state and small scene-owned observable models
- `@Binding`: parent-owned state passed into a child
- `@SceneStorage`: scene-local restoration when it genuinely fits
- `@AppStorage`: app-wide preference or toggle
- `@Environment(Type.self)`: shared service, coordinator, or app context when
  that matches the project convention

Do not keep immersive lifecycle ownership or long-lived entity ownership in
transient leaf views.

## Entity State vs View State

RealityKit entities carry state in their components. SwiftUI views carry state in their models and view-local properties. These are different kinds of state and should not be duplicated. Decide ownership deliberately.

| State | Owner | Example |
| --- | --- | --- |
| Position, rotation, scale | Entity (Transform component) | Where an object is in the world |
| Physics properties | Entity (PhysicsBodyComponent) | Mass, restitution, friction |
| Collision shape | Entity (CollisionComponent) | Hit-test geometry |
| Current animation | Entity (animation library / AnimationComponent) | Playing, paused, blending |
| Selection or highlight in UI | SwiftUI view model | Which entity is currently focused in a list |
| Inspector panel values | SwiftUI view model | The form a user edits |
| User preferences about an entity | App-level model | "Hide this entity" toggle persisted across launches |
| Feature mode or tool | Feature coordinator | "Place mode" vs "inspect mode" |

The rule: entity components hold state that belongs to the simulation. View models hold state that belongs to the UI. If the same value appears in both, something is wrong - pick one canonical owner and derive the other.

## Cross-Scene State Sync

A visionOS app often runs a window and an immersive space together. State that must flow between them needs an explicit owner above both scenes.

Pattern:

- Declare an app-level `@Observable` model.
- Inject it into both scenes via `.environment(...)`.
- Neither scene holds the canonical copy. Both read and write through the shared model.
- Use computed properties or `didSet` for derived state so scenes react consistently.

Anti-patterns:

- One scene holds the canonical value and the other queries it through brittle bindings.
- Both scenes hold independent copies and try to sync via messages.
- A SwiftUI view in one scene tries to mutate RealityKit state owned by the other scene directly.

If cross-scene state grows complex, that is a sign to introduce a feature coordinator above the scenes rather than thicken the shared model.
