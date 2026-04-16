---
name: deprecation-visionos
description: Find and migrate deprecated Swift, SwiftUI, and RealityKit patterns to current visionOS 26 and Swift 6.2 best practices. Addresses the tendency to use outdated idioms. Covers ObservableObject -> @Observable, iOS ARSession -> ARKitSession, Combine -> async/await, UIKit bridges -> native SwiftUI, and Swift 5 concurrency -> Swift 6.
---

# Deprecation and Migration for visionOS

## Addy Parent

This skill extends `deprecation-and-migration` from agent-skills. Follow the generic "identify, plan, migrate, verify" discipline there. This skill adds the visionOS 26 + Swift 6.2 target state and the specific migrations most likely to appear in older code or LLM-generated code.

## Why This Matters

Language models (and some older tutorials) lean toward older patterns. On visionOS 26 with Swift 6.2, many of those patterns are deprecated, discouraged, or outright incompatible with strict concurrency. Migrating them is usually a mechanical fix with a clear target pattern.

## Detection

### Automated Scans

| What | Command or Pattern |
|------|-------------------|
| Compiler deprecation warnings | Build with `-warnings-as-errors` enabled for a spot check |
| `@available(..., deprecated:)` usage | `grep -r "@available.*deprecated" .` |
| `ObservableObject` conformance | `grep -r ": ObservableObject" .` |
| `@Published` properties | `grep -r "@Published" .` |
| Combine imports | `grep -r "import Combine" .` |
| UIKit bridges | `grep -r "UIViewRepresentable\|UIViewControllerRepresentable" .` |
| iOS ARSession (vs ARKitSession) | `grep -r "ARSession\b" .` |

### Manual Review Triggers

- Any class where `struct` with `@Observable` would suffice
- Any `DispatchQueue.main.async { ... }` that could be `await MainActor.run { ... }`
- Any completion handler that could be `async throws`
- Any `CGFloat` for spatial dimensions (prefer `Float`/`Double` explicitly)

## Migration Targets

### ObservableObject -> @Observable

**Before:**
```swift
class FeatureModel: ObservableObject {
  @Published var title: String = ""
  @Published var items: [Item] = []
}
```

**After:**
```swift
@Observable
class FeatureModel {
  var title: String = ""
  var items: [Item] = []
}
```

Views using `@StateObject` become `@State`. Views using `@ObservedObject` become a plain property. `@EnvironmentObject` becomes `@Environment(FeatureModel.self)`.

### Swift 5 Concurrency -> Swift 6 Strict Concurrency

- Add `@MainActor` to types that touch UI
- Replace `DispatchQueue.main.async` with `await MainActor.run` or `@MainActor` isolation
- Audit `Sendable` conformance for types crossed between actors
- Replace `@unchecked Sendable` with real thread-safety where possible

### Combine -> async/await

**Before:**
```swift
publisher
  .sink { value in handle(value) }
  .store(in: &cancellables)
```

**After:**
```swift
for await value in stream {
  handle(value)
}
```

Keep Combine only where you need its operator composition and no clean async alternative exists.

### iOS ARSession -> visionOS ARKitSession

- `ARSession` is iOS. On visionOS use `ARKitSession` with explicit providers.
- `ARSessionDelegate` callbacks become `AsyncSequence` on each provider.
- Authorization is explicit: check `ARKitSession.AuthorizationStatus` before starting providers.

### UIKit Bridges -> Native SwiftUI

- `UIViewRepresentable` should be the last resort on visionOS
- Native SwiftUI spatial views (`RealityView`, `Model3D`, `WindowGroup`, `ImmersiveSpace`) cover most cases
- Keep UIKit bridges only when a framework explicitly lacks a SwiftUI surface

### Deprecated RealityKit APIs

- `ARView` is iOS. Use `RealityView` on visionOS.
- Old scene loading with `Entity.loadAsync(named:)` -> `try await Entity(named:in:)`
- Manual entity subscriptions -> system-based component queries

## Migration Workflow

1. Identify the scope (one file, one module, whole app)
2. Create a dedicated branch: `refactor/migrate-<pattern>`
3. Migrate mechanically, one pattern at a time
4. Build after each pattern migration
5. Run tests after each pattern migration
6. Commit per pattern with a clear message
7. Do NOT mix behaviour changes into migration commits

## Guardrails

- Never migrate patterns you do not understand - ask first
- Do not migrate deprecated APIs to other deprecated APIs
- Do not mix migration with feature work in the same commit
- Verify behaviour is identical after migration - use tests as the safety net

## When To Switch Skills

- Switch to `coding-standards` for the target patterns' details
- Switch to `test-triage` if migrations break tests
- See `coding-standards/references/xcode-commit-conventions.md` for commit structure during migration

## Output Expectations

- The deprecated patterns found (file paths and counts)
- The migration order (usually leaf modules first)
- The target pattern for each
- Verification: build clean, tests pass, behaviour identical
