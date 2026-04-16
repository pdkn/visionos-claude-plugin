---
name: debugging-triage
description: visionOS lens on debugging and error recovery. Classifies failures into five visionOS categories (ARKit session, RealityKit render loop, hand tracking, entitlement, scene lifecycle) and applies the appropriate triage for each.
---

# Debugging Triage - visionOS Lens

## Addy Parent

This skill extends `debugging-and-error-recovery` from agent-skills. Follow the generic "reproduce, localize, fix, guard" discipline there. This skill adds visionOS-specific failure classification and triage paths.

## visionOS Failure Categories

Classify the failure first. The triage differs by category.

### 1. ARKit Session Failure

**Symptoms:** providers fail to start, authorization unexpected, anchors drift or disappear, session ends without user action.

**Triage:**
- Check `ARKitSession.AuthorizationStatus` at the failure point
- Verify entitlements match provider usage (`com.apple.developer.arkit.*`)
- Check for simulator vs device behaviour differences (many providers are device-only)
- Log session state transitions to narrow down when the failure occurs

### 2. RealityKit Render Loop Issue

**Symptoms:** visual glitches, dropped frames, entities flicker, transforms lag, components update out of order.

**Triage:**
- Capture an Instruments Time Profiler trace on the render path
- Check system execution order (dependencies between systems)
- Verify you are not mutating the entity hierarchy from multiple threads
- Look for per-frame allocations that trigger GC or ARC churn

### 3. Hand Tracking Issues at 90Hz

**Symptoms:** jittery gestures, missing updates, delayed recognition, inconsistent anchor positions.

**Triage:**
- Confirm the 90Hz update rate is being sustained (check frame time)
- Verify hand anchor processing is on the main actor or a consistent queue
- Check for filtering or smoothing code that eats updates
- Look for render-loop work that blocks the hand tracking stream

### 4. Entitlement or Capability Launch Blocker

**Symptoms:** app fails to launch, crashes at startup, provider authorization fails before prompt appears.

**Triage:**
- Read the built `Info.plist` and `.entitlements` (not the source - the packaged version)
- Match each ARKit provider used to its required entitlement
- Check for required privacy usage descriptions
- Distinguish simulator behaviour from device provisioning issues

### 5. Scene Lifecycle Bug

**Symptoms:** state lost between scenes, immersive space does not open, window does not dismiss, transitions hang.

**Triage:**
- Log `Scene` body evaluations to narrow down re-evaluation triggers
- Check `openImmersiveSpace` / `dismissImmersiveSpace` error results
- Verify state ownership boundaries match the scene's lifetime
- Look for state that outlives a scene it was scoped to

## Regression Tests

Every fix must add a regression test. For visionOS:
- Unit test the failure classification if it is testable at that level
- Integration test if the bug required a full simulator run to reproduce
- Use the Prove-It pattern from `tdd-visionos`

## When To Switch Skills

- `tdd-visionos` - write the Prove-It test before fixing
- `perf-90hz` - when the triage category is render loop or hand tracking
- `signing-entitlements` - when the category is entitlement or capability
- `realitykit` / `arkit` - for deeper API-level debugging
- `git-workflow` - after the fix is verified, commit separately from feature work

## Guardrails

- Never fix without reproducing first
- Never fix the symptom while leaving the root cause
- Never ship a fix without a regression test
- Never combine unrelated fixes in one pass
