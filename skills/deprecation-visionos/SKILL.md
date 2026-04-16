---
name: deprecation-visionos
description: visionOS lens on deprecation and migration. Load alongside agent-skills:deprecation-and-migration for the generic identify-plan-migrate-verify discipline. This skill adds visionOS 26 + Swift 6.2 target patterns and worked examples for the migrations most likely to appear in older code or LLM-generated code.
---

# Deprecation and Migration for visionOS - Lens

## How to Use This Skill

Load `agent-skills:deprecation-and-migration` for the generic discipline.
Use this skill for Swift 6.2 / visionOS 26 target patterns and worked
migrations.

## Why This Skill Exists

Language models and older tutorials lean toward pre-Swift 6 patterns. On
visionOS 26 with strict concurrency enabled, many of those patterns are
deprecated, unsafe, or outright incompatible. Migrations are usually
mechanical fixes with clear targets - this skill documents those targets.

## Detection

### Automated Scans

| Pattern | Command |
|---|---|
| Compiler deprecation warnings | Build with `-warnings-as-errors` for a spot check |
| `@available(..., deprecated:)` usage | `rg "@available.*deprecated"` |
| `ObservableObject` conformance | `rg ": ObservableObject"` |
| `@Published` properties | `rg "@Published"` |
| `Combine` imports | `rg "import Combine"` |
| iOS `ARSession` (wrong for visionOS) | `rg "ARSession\b"` |
| UIKit bridges | `rg "UIViewRepresentable\|UIViewControllerRepresentable"` |
| `DispatchQueue.main.async` | `rg "DispatchQueue\.main\.async"` |

### Manual Review Triggers

- Any class where `struct` + `@Observable` would suffice
- Any completion handler that could be `async throws`
- Any force-unwrap (`!`) in new code
- Any `@unchecked Sendable` without explicit thread-safety reasoning

## Worked Example 1: ObservableObject -> @Observable

**Before:**
```swift
import Combine

class PaintModel: ObservableObject {
    @Published var selectedColor: Color = .red
    @Published var brushSize: CGFloat = 4
    @Published var strokes: [Stroke] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $selectedColor
            .sink { color in self.logColorChange(color) }
            .store(in: &cancellables)
    }
}

struct PaintView: View {
    @StateObject var model = PaintModel()
    // ...
}
```

**After:**
```swift
@Observable
class PaintModel {
    var selectedColor: Color = .red {
        didSet { logColorChange(selectedColor) }
    }
    var brushSize: CGFloat = 4
    var strokes: [Stroke] = []
}

struct PaintView: View {
    @State var model = PaintModel()
    // ...
}
```

### Changes
- Remove `ObservableObject` conformance
- Remove `@Published` wrappers - `@Observable` makes all stored properties observable
- Remove Combine imports and cancellables
- Replace Combine sinks with `didSet` where possible
- `@StateObject` -> `@State`
- `@ObservedObject` -> plain property
- `@EnvironmentObject` -> `@Environment(PaintModel.self)`

### Commit

Split into:
1. `refactor(paint): migrate PaintModel to @Observable`
2. `refactor(paint): update views from @StateObject to @State`

## Worked Example 2: Swift 5 Concurrency -> Swift 6 Strict Concurrency

**Before:**
```swift
class ImageLoader {
    func loadImage(from url: URL, completion: @escaping (Image?) -> Void) {
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if let data, let image = Image(data: data) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
```

**After:**
```swift
actor ImageLoader {
    func loadImage(from url: URL) async throws -> Image {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = Image(data: data) else {
            throw ImageLoadError.invalidData
        }
        return image
    }
}
```

### Changes
- `class` + dispatch queues -> `actor`
- Completion handler -> `async throws`
- `Data(contentsOf:)` -> `URLSession.shared.data(from:)` (proper async)
- Caller can now `await` directly without nested callbacks

### Commit

`refactor(imageloader): migrate to async/await and actor isolation`

## Worked Example 3: iOS ARSession -> visionOS ARKitSession

**Before (iOS pattern that does NOT work on visionOS):**
```swift
import ARKit

class TrackingManager: NSObject, ARSessionDelegate {
    let session = ARSession()

    func start() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.delegate = self
        session.run(config)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Handle plane anchors
    }
}
```

**After (visionOS pattern):**
```swift
import ARKit

@MainActor
class TrackingManager {
    let session = ARKitSession()
    let planeProvider = PlaneDetectionProvider(alignments: [.horizontal])

    func start() async throws {
        // Check authorization explicitly
        let authorization = await session.queryAuthorization(for: [.worldSensing])
        guard authorization[.worldSensing] == .allowed else {
            throw TrackingError.notAuthorized
        }

        try await session.run([planeProvider])

        // Consume updates via async sequence, not delegate
        Task {
            for await update in planeProvider.anchorUpdates {
                handle(update)
            }
        }
    }

    private func handle(_ update: AnchorUpdate<PlaneAnchor>) {
        // Handle plane anchor
    }
}
```

### Changes
- `ARSession` + `ARWorldTrackingConfiguration` -> `ARKitSession` + specific providers
- `ARSessionDelegate` -> `AsyncSequence` on each provider
- Authorization check is explicit, not implicit
- Each provider has its own update stream

### Commit

Split into:
1. `refactor(arkit): migrate TrackingManager to ARKitSession and providers`
2. `fix(arkit): add explicit worldSensing authorization check`

## Worked Example 4: Combine Publisher -> AsyncSequence

**Before:**
```swift
import Combine

handTracking.$currentPinchState
    .removeDuplicates()
    .sink { state in
        self.handlePinchStateChange(state)
    }
    .store(in: &cancellables)
```

**After:**
```swift
Task {
    var lastState: PinchState?
    for await state in handTracking.pinchStateStream {
        if state != lastState {
            handlePinchStateChange(state)
            lastState = state
        }
    }
}
```

### Changes
- Publisher -> `AsyncStream`
- `.removeDuplicates()` -> manual tracking (simple case) or a stream operator
- `.sink`+`.store` -> `for await` loop in a `Task`
- Retain Combine only where operator composition is genuinely valuable and
  no clean async alternative exists

### Commit

`refactor(handtracking): migrate pinch state from Combine to AsyncStream`

## Worked Example 5: UIKit Bridge -> Native SwiftUI

**Before:**
```swift
struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}
```

**After (native visionOS approach):**

On visionOS, consumer apps cannot access the raw camera. For enterprise
apps with camera access entitlements, use native `AVCaptureSession`
integrated with RealityKit's video player component instead of a UIKit
bridge:

```swift
// Present video via RealityKit's VideoPlayerComponent
let videoEntity = Entity()
videoEntity.components.set(VideoPlayerComponent(avPlayer: avPlayer))
```

Or, for displaying captured frames, use a `RealityView` with a
`ModelEntity` whose material updates per frame.

UIKit bridges should be the last resort on visionOS. Most cases have a
native SwiftUI or RealityKit surface.

### Commit

`refactor(camera): replace UIViewRepresentable with RealityKit video entity`

## Migration Workflow

1. Identify the scope (one file, one module, whole app)
2. Create a dedicated branch: `refactor/migrate-<pattern>`
3. Migrate mechanically, one pattern at a time
4. Build after each pattern migration
5. Run tests after each pattern migration
6. Commit per pattern with a clear message
7. Do NOT mix behaviour changes into migration commits

See `coding-standards/references/xcode-commit-conventions.md` for commit
structure during migration.

## When To Switch Skills

- `coding-standards` - for target pattern details
- `test-triage` - if migrations break tests
- `tdd-visionos` - add regression tests before large-scale migrations
- `agent-skills:deprecation-and-migration` - for the generic discipline

## Guardrails

- Never migrate patterns you do not understand - ask first
- Do not migrate to other deprecated patterns
- Do not mix migration with feature work in the same commit
- Verify behaviour is identical after migration - use tests as the safety net
- Keep migration branches short - merge frequently to avoid drift
