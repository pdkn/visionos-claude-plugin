---
name: tdd-visionos
description: Write failing tests first for visionOS behaviours. Use the Prove-It pattern for bug fixes - a test that reproduces the bug before touching code. Covers XCTest, Swift Testing, RealityKit system testing, ARKit provider mocking, SharePlay session tests, and scene lifecycle assertions.
---

# TDD for visionOS

## Addy Parent

This skill extends `test-driven-development` from agent-skills. Follow the generic "failing test first, then make it pass" discipline there. This skill adds visionOS-specific testing patterns.

## Quick Start

1. Write the smallest failing test that captures the intended behaviour.
2. Verify it fails for the right reason (not a compile error).
3. Write the minimum code to pass.
4. Refactor while green.

For bugs, use the **Prove-It pattern**:
1. Write a test that reproduces the bug.
2. Verify the test fails with the same symptom the user reports.
3. Fix the code.
4. Verify the test passes.
5. Keep the test as a regression guard.

## visionOS Testing Patterns

### XCTest vs Swift Testing

| Situation | Use |
|-----------|-----|
| New tests in visionOS 26 target | Swift Testing (`@Test`, `#expect`) |
| Existing XCTest target without migration budget | XCTest |
| Async behaviour, parameterized cases | Swift Testing |
| UI automation | XCUITest (XCTest-based) |

### Testing RealityKit Systems in Isolation

Systems can be unit-tested without a full scene by:
- Constructing a scene with only the entities the system needs
- Calling `system.update(context:)` directly with a synthesized context
- Asserting on component state after the call

Avoid testing through `RealityView` unless you are testing the view integration itself.

### Mocking ARKit Providers

ARKit providers (`HandTrackingProvider`, `WorldTrackingProvider`, etc.) are hard to stub directly. Prefer:
- A protocol that your code depends on, with a real implementation backed by ARKit and a test double for unit tests
- Anchor structs can be constructed for assertions, but provider lifecycles require integration tests

### SharePlay Session Testing

- Unit-test message encoding and decoding against known fixtures
- Integration-test `GroupSession` lifecycle with two simulator instances
- Avoid testing through actual FaceTime - use the simulator's SharePlay debug menu

### Scene Lifecycle Assertions

Test what you can:
- Scene registration in `body` (view-level unit tests)
- View model state before/after `openImmersiveSpace` is called
- Entity spawn/teardown when scenes change

Skip:
- Actual scene transitions (runtime, not testable unit-level)

## Guardrails

- Never write a test AFTER the code unless documenting existing behaviour
- A test that passes on first run without seeing it fail proves nothing
- Do not mock what you own - refactor to testability instead
- Integration tests for ARKit/SharePlay/scene transitions go in a separate target from unit tests

## When To Switch Skills

- Switch to `test-triage` when tests are failing and you need to classify the failure
- Switch to `debugging-triage` when a bug needs systematic root-cause analysis
- Switch to `realitykit` when the test surfaces a component/system design question

## Output Expectations

- The failing test (code shown, failure message captured)
- The minimum code to pass
- Any refactoring applied while green
- For bug fixes: the Prove-It test plus the fix, with the test kept as regression guard
