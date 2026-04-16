---
name: debugging-triage
description: visionOS lens on debugging. Load alongside agent-skills:debugging-and-error-recovery for the generic reproduce-localize-fix-guard discipline. This skill adds the five visionOS failure categories (ARKit session, render loop, hand tracking, entitlement, scene lifecycle) with dedicated triage paths and worked examples.
---

# Debugging Triage - visionOS Lens

## How to Use This Skill

Load `agent-skills:debugging-and-error-recovery` for the generic discipline
(reproduce, localize, fix, add regression guard). Use this skill for the
visionOS failure classification and worked triage examples.

## The Five Categories

Classify the failure first. The triage differs by category.

### 1. ARKit Session Failure
**Symptoms:** providers fail to start, authorization unexpected, anchors drift or disappear, session ends without user action.

### 2. RealityKit Render Loop Issue
**Symptoms:** visual glitches, dropped frames, entities flicker, transforms lag, components update out of order.

### 3. Hand Tracking Issues at 90Hz
**Symptoms:** jittery gestures, missing updates, delayed recognition, inconsistent anchor positions.

### 4. Entitlement or Capability Launch Blocker
**Symptoms:** app fails to launch, crashes at startup, provider authorization fails before prompt appears.

### 5. Scene Lifecycle Bug
**Symptoms:** state lost between scenes, immersive space does not open, window does not dismiss, transitions hang.

## Worked Example 1: ARKit Session Failure

**Report:** "Hand tracking stops working after 30 seconds."

### Reproduce
Run on simulator, open the immersive space, wait. Confirmed - hand anchors
stop updating after ~30s.

### Classify
Category 1 (ARKit session) - the provider is emitting updates then stops.

### Localize
Add logging around `ARKitSession` state changes:

```swift
for await status in session.events {
    print("[ARKit event]", status)
}
```

Run again. Log shows: `[ARKit event] authorizationChanged(.denied)` after
30 seconds.

Root cause: the app's `NSHandsTrackingUsageDescription` exists in `Info.plist`,
but the test app was launched via a deep link bypassing the first-launch
permission prompt. The user's answer is remembered for the session but
times out.

### Fix

Handle `.denied` in the session event stream: show a UI prompt asking the
user to re-authorize. Do NOT silently fail.

```swift
case .authorizationChanged(let status):
    if status == .denied {
        await presentReauthorizationPrompt()
    }
```

### Regression test

Write a test using `FixtureHandTrackingSource` (see `tdd-visionos`) that
delivers an authorization-denied event and asserts the UI responds.

### Commit

`fix(arkit-session): handle hand tracking authorization denial gracefully`

## Worked Example 2: RealityKit Render Loop Issue

**Report:** "The stars in my night-sky scene flicker every few seconds."

### Reproduce
Open the immersive space. Watch for ~5 seconds. Confirmed - stars flicker
intermittently.

### Classify
Category 2 (render loop). Entities aren't disappearing, they're flickering
in place.

### Localize
Flickering in place usually means competing writes to the same component
or entity.

Audit the systems:
- `StarPlacementSystem` - places stars once at scene load
- `StarTwinkleSystem` - animates emissive color per star
- `StarCullingSystem` - hides stars when too far from user

`StarPlacementSystem` should run once. Let me check... it's registered to
run every frame AND sets position every frame. When `StarCullingSystem`
hides a star by setting `.isEnabled = false`, the placement system
re-enables it next frame. That's the flicker.

### Fix

Make `StarPlacementSystem` idempotent - only place stars that don't
already exist. Or gate its `update` on a `needsPlacement` flag.

### Regression test

Write a test that advances 10 frames and asserts no entity changes
`.isEnabled` twice in that span.

### Commit

`fix(realitykit): prevent StarPlacementSystem from re-enabling culled stars`

## Worked Example 3: Hand Tracking at 90Hz

**Report:** "Pinch detection lags when many entities are on screen."

### Reproduce
Spawn 500 entities, pinch repeatedly. Confirmed - pinch registers 200ms
after actual gesture.

### Classify
Category 3 (hand tracking at 90Hz). Stream is being blocked somewhere.

### Localize
Check if hand anchor stream actually emits at 90Hz under load:

```swift
var timestamps: [TimeInterval] = []
for await anchor in handTracking.anchorUpdates {
    timestamps.append(CACurrentMediaTime())
}
```

Run with 500 entities. Output: anchors arrive at ~60Hz with 100ms+ gaps.

The stream is blocked. Check what else runs on the same actor:
`StrokeRenderSystem` runs per-frame and allocates a new `Array<Vertex>`
for each stroke. With 500 strokes, that's 500 allocations per frame.

Root cause: ARC churn from per-frame allocation blocks the main actor,
delaying hand anchor delivery.

### Fix

Pre-allocate a ring buffer in `StrokeRenderSystem`. Reuse segments.

### Regression test

The Prove-It test from `tdd-visionos` Worked Example 2.

### Commit

`fix(paint): pre-allocate stroke segment buffer to unblock 90Hz stream`

## Worked Example 4: Entitlement Launch Blocker

**Report:** "App won't launch on TestFlight build. Works fine in Xcode."

### Reproduce
Install the TestFlight build. Tap to launch. Crashes before splash.

### Classify
Category 4 (entitlement). Classic "works in dev, not in release" pattern.

### Localize

Read the built `.app`'s `embedded.mobileprovision` and `Info.plist`.

```sh
security cms -D -i AppName.app/embedded.mobileprovision
```

Compare against the developer build. Difference: TestFlight build's
provisioning profile doesn't include the
`com.apple.developer.arkit.hand-tracking` entitlement.

Root cause: the entitlement was added to the Xcode project's
`.entitlements` file but the distribution provisioning profile was not
regenerated to include it.

### Fix

In Apple Developer portal:
1. Add "Hand Tracking" capability to the App ID
2. Regenerate the distribution provisioning profile
3. Rebuild with the new profile

### Regression prevention

Add `ci-visionos`-style check: a CI step that parses the built
provisioning profile and verifies required entitlements are present.

### Commit

The fix is in provisioning, not code. Commit the CI check:
`ci: verify entitlement/profile match in release builds`

## Worked Example 5: Scene Lifecycle Bug

**Report:** "Tapping 'Enter immersive' does nothing after the user has
dismissed the immersive space once."

### Reproduce
Open immersive space, exit, try to reopen. Confirmed - button does nothing.

### Classify
Category 5 (scene lifecycle). Transitions are hanging.

### Localize

Add logging around the transition:

```swift
Button("Enter immersive") {
    Task {
        let result = await openImmersiveSpace(id: "paint")
        print("[scene] openImmersiveSpace result:", result)
    }
}
```

Output: `[scene] openImmersiveSpace result: error(userCancelled)` every
time after the first dismiss.

Root cause: a previous `ImmersiveSpace` is still in a dismissing state
because we retained a reference to a task that was waiting on something
that never completes. The scene system won't open a new one while the
previous is still dismissing.

### Fix

Cancel any pending immersive-space tasks before invoking
`dismissImmersiveSpace`. Ensure the dismissal completes before the user
can tap re-enter.

### Regression test

Add a scene coordinator test that asserts state transitions correctly
after dismiss.

### Commit

`fix(scene): cancel pending tasks on immersive dismiss to allow reopen`

## When To Switch Skills

- `tdd-visionos` - write the Prove-It test before fixing
- `perf-90hz` - when the category is render loop or hand tracking
- `signing-entitlements` - when the category is entitlement or capability
- `realitykit` / `arkit` - for deeper API-level debugging
- `coding-standards` (see `references/xcode-commit-conventions.md`) - after the fix is verified, commit separately from feature work
- `agent-skills:debugging-and-error-recovery` - for the generic discipline

## Guardrails

- Never fix without reproducing first
- Never fix the symptom while leaving the root cause
- Never ship a fix without a regression test
- Never combine unrelated fixes in one pass
- The test must fail BEFORE the fix and pass AFTER (Prove-It pattern)
