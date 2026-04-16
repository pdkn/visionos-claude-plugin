---
name: tdd-visionos
description: visionOS lens on test-driven development. Load alongside agent-skills:test-driven-development for the generic failing-test-first and Prove-It-for-bugs discipline. This skill adds visionOS-specific test patterns (RealityKit system isolation, ARKit provider mocking, SharePlay message fixtures) with worked examples.
---

# TDD for visionOS - Lens

## How to Use This Skill

Load `agent-skills:test-driven-development` for the generic TDD discipline
(failing test first, Prove-It for bugs, keep tests as regression guards).
Use this skill for visionOS-specific testing patterns and worked examples.

## Test Framework Choice

| Situation | Framework |
|---|---|
| New tests in visionOS 26 target | Swift Testing (`@Test`, `#expect`) |
| Existing XCTest target without migration budget | XCTest |
| Async behaviour, parameterized cases | Swift Testing |
| UI automation | XCUITest (XCTest-based) |

## What Is Testable at Unit Level

| Surface | Unit-testable | Integration-only |
|---|---|---|
| RealityKit system update logic | yes | - |
| Component state transitions | yes | - |
| Scene coordinator view model | yes | - |
| Pinch/gesture detection algorithm | yes | - |
| ARKit provider lifecycle | - | yes |
| Immersive space transitions | - | yes |
| SharePlay GroupSession flow | - | yes |
| 90Hz frame timing | - | yes (device) |

Unit tests do not need a full scene. Integration tests need a simulator
instance.

## Worked Example 1: Testing a RealityKit System in Isolation

**Feature:** a `GravitySystem` that applies a velocity delta to entities
with `PhysicsMotionComponent` each frame.

### Failing test first

```swift
import Testing
import RealityKit

@Test
func gravitySystemAppliesVelocityDelta() async throws {
    // Arrange: entity with motion component, no scene needed
    let entity = Entity()
    entity.components.set(PhysicsMotionComponent(
        linearVelocity: SIMD3<Float>(0, 0, 0),
        angularVelocity: SIMD3<Float>(0, 0, 0)
    ))

    let system = GravitySystem()
    let context = SceneUpdateContext.test(deltaTime: 1.0 / 90.0)

    // Act
    system.update(context: context)

    // Assert: y velocity is reduced by g * delta
    let motion = entity.components[PhysicsMotionComponent.self]!
    #expect(motion.linearVelocity.y < 0)
}
```

Run it. It fails because `GravitySystem` doesn't exist yet.

### Minimum code to pass

```swift
class GravitySystem: System {
    func update(context: SceneUpdateContext) {
        // Apply -9.81 m/s^2 to every entity with PhysicsMotionComponent
        for entity in entities {
            if var motion = entity.components[PhysicsMotionComponent.self] {
                motion.linearVelocity.y -= 9.81 * Float(context.deltaTime)
                entity.components.set(motion)
            }
        }
    }
}
```

Test passes. Then add tests for: does not affect entities without the
component, respects per-entity gravity override, etc.

## Worked Example 2: Prove-It for "Hand tracking drops frames"

Bug report: "When I pinch while many entities are on screen, hand tracking
lags noticeably."

### Prove-It test

```swift
@Test
func handTrackingUpdateRateDoesNotDropUnder60Hz_withManyEntities() async throws {
    // Arrange: scene with 500 stroke entities
    let scene = TestScene()
    for _ in 0..<500 {
        scene.addStrokeEntity()
    }

    // Act: simulate hand tracking stream for 1 second
    let timestamps = await scene.collectHandUpdateTimestamps(duration: 1.0)

    // Assert: update rate never dropped below 60Hz for more than 100ms
    let gaps = timestamps.zipAdjacent().map { $1 - $0 }
    let longGaps = gaps.filter { $0 > (1.0 / 60.0) }
    let longGapTotal = longGaps.reduce(0, +)
    #expect(longGapTotal < 0.1, "hand tracking gaps totalled \(longGapTotal)s")
}
```

Run it. It fails - the actual gap is 300ms.

### Investigate, find root cause

Per-frame allocation in the stroke rendering path causes ARC churn that
blocks the hand tracking stream.

### Fix

Pre-allocate a ring buffer for stroke segments; reuse instead of alloc.

### Verify test passes

Re-run. Gap total is now 20ms. Test passes. Keep it as a regression guard.

### Commit

Separate commits for:
1. Adding the failing test (commit: `test(paint): prove hand tracking drops under load`)
2. Fixing the allocation (commit: `fix(paint): pre-allocate stroke segment buffer`)

## Worked Example 3: Testing SharePlay Message Encoding

**Feature:** a `DrawCommand` message type sent over SharePlay. Must encode
and decode correctly, and survive protocol version drift.

```swift
@Test
func drawCommandEncodesAndDecodes() throws {
    let original = DrawCommand(
        strokeID: UUID(),
        color: .init(red: 1, green: 0, blue: 0),
        points: [.init(x: 0, y: 0, z: 0), .init(x: 1, y: 1, z: 1)]
    )

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(DrawCommand.self, from: encoded)

    #expect(decoded.strokeID == original.strokeID)
    #expect(decoded.points.count == original.points.count)
}

@Test
func drawCommandDecodesMissingColorAsDefault() throws {
    // Simulate a v1 message reaching a v2 decoder
    let v1Json = """
    {"strokeID": "\(UUID())", "points": []}
    """.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(DrawCommand.self, from: v1Json)
    #expect(decoded.color == .default) // Assume we added a default in v2
}
```

This tests encoding invariants without needing an actual SharePlay session.

## Worked Example 4: Testing Scene Coordinator State

**Feature:** `AppCoordinator` opens an immersive space when the user taps a
button, then dismisses the window.

```swift
@Test
@MainActor
func tapToEnterImmersiveOpensSpaceAndDismissesWindow() async throws {
    let coordinator = AppCoordinator()
    let openCalls = FakeOpener()
    let dismissCalls = FakeDismisser()
    coordinator.bind(open: openCalls.openImmersiveSpace,
                     dismiss: dismissCalls.dismissWindow)

    await coordinator.enterImmersive()

    #expect(openCalls.receivedIDs == ["paint"])
    #expect(dismissCalls.wasCalled == true)
    #expect(coordinator.state == .immersive)
}
```

The coordinator is decoupled from SwiftUI environment values - the `open`
and `dismiss` closures can be stubbed. State transitions are assertable.

## Mocking ARKit Providers

ARKit providers are hard to stub directly. The pattern: depend on a
protocol, real impl uses ARKit, test double returns fixtures.

```swift
protocol HandTrackingSource {
    var anchorUpdates: AsyncStream<HandAnchor> { get }
}

final class ARKitHandTrackingSource: HandTrackingSource {
    // Real implementation using ARKitSession + HandTrackingProvider
}

final class FixtureHandTrackingSource: HandTrackingSource {
    var anchorUpdates: AsyncStream<HandAnchor> {
        // Return a canned sequence of anchors
    }
}
```

Tests use `FixtureHandTrackingSource` and assert on downstream behaviour.
Provider lifecycle (session start/stop, authorization) goes in integration
tests.

## When To Switch Skills

- `test-triage` - when tests are failing and need classification
- `debugging-triage` - when a bug needs systematic root-cause analysis
- `realitykit` - when testing surfaces a component/system design question
- `perf-90hz` - for frame-timing tests requiring device verification
- `agent-skills:test-driven-development` - for the generic discipline

## Guardrails

- Never write a test after the code unless documenting existing behaviour
- A test that passes on first run without seeing it fail proves nothing
- Do not mock what you own - refactor to testability instead
- Unit tests and integration tests go in separate targets
- Prove-It for bugs: the test must reproduce the bug BEFORE the fix
