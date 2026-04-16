---
name: security-visionos
description: visionOS lens on security and hardening. Load alongside agent-skills:security-and-hardening for the generic OWASP/validation/least-privilege discipline. This skill adds the visionOS-specific trust boundaries (ARKit world sensing data, hand tracking privacy, SharePlay participant trust, deep links into immersive spaces) with worked examples.
---

# Security for visionOS - Lens

## How to Use This Skill

Load `agent-skills:security-and-hardening` for the generic discipline
(input validation, trust boundaries, least privilege, data at rest). Use
this skill for visionOS-specific trust concerns and worked examples.

**Scope boundary:** this skill covers RUNTIME trust and data handling.
`signing-entitlements` covers BUILD-TIME config (declaring entitlements,
presence of privacy keys). The two are complementary.

## Spatial Trust Boundaries

visionOS introduces new data classes your app must handle responsibly:

- **ARKit world sensing** (meshes, planes, camera) - reveals the user's physical environment
- **Hand tracking** (joint positions over time) - biometric + reveals typed input
- **SharePlay participants** - other users in a session, unauthenticated
- **App Group / shared containers** - data from sibling extensions, untrusted
- **Deep links** - any URL opening an immersive space is an entry point

## Worked Example 1: Handling Hand Tracking Data in a Paint App

**Feature:** paint app captures hand joint positions to draw strokes.

### Trust analysis
- Hand tracking data is biometric-adjacent and can reveal typed input if the
  user is typing on a physical keyboard while the app is running
- Raw joint positions over time are especially sensitive
- Our app only needs the index fingertip to draw - nothing else

### What NOT to do

```swift
// Bad: logs every joint for every hand every frame
for joint in handAnchor.handSkeleton!.allJoints {
    logger.info("Joint \(joint.name) at \(joint.anchorFromJointTransform)")
}
```

This log would let anyone reading the logs reconstruct hand movement in
fine detail.

### What to do

```swift
// Good: use only what we need, don't log raw positions
let fingertip = handAnchor.handSkeleton?
    .joint(.indexFingerTip)
    .anchorFromJointTransform.translation

// Do log coarse events but not raw positions
logger.info("Stroke started")  // no position
logger.info("Stroke ended after \(durationSeconds)s")  // no path
```

### Persistence

- Strokes the user explicitly saves: persist the stroke shape (final path),
  not the raw hand anchor timeline
- Unsaved session: clear on scene close
- Never transmit raw hand tracking data off-device

### Commit

`security(paint): limit hand joint access to fingertip, strip position logs`

## Worked Example 2: Validating SharePlay Messages

**Feature:** multi-user whiteboard where each participant can draw. Drawing
commands flow over SharePlay.

### Trust analysis

SharePlay participants are authenticated as FaceTime users but are NOT
authenticated to your app's data model. Treat their messages as adversarial.

### What NOT to do

```swift
// Bad: trust the incoming message blindly
session.messages(of: DrawCommand.self).subscribe { message in
    self.scene.applyCommand(message.payload)  // no validation
}
```

A malicious or buggy participant could send a `DrawCommand` with a billion
points and crash every other participant.

### What to do

```swift
session.messages(of: DrawCommand.self).subscribe { message in
    guard let validated = self.validate(message.payload) else {
        logger.warning("Rejected invalid DrawCommand from \(message.sender)")
        return
    }
    self.scene.applyCommand(validated)
}

func validate(_ cmd: DrawCommand) -> DrawCommand? {
    guard cmd.points.count <= 10_000 else { return nil }
    guard cmd.points.allSatisfy({ $0.isFinite }) else { return nil }
    guard cmd.color.isNormalized else { return nil }
    return cmd
}
```

Make messages idempotent so duplicate or reordered delivery is safe.

### Commit

`security(shareplay): validate DrawCommand size and finiteness before apply`

## Worked Example 3: Deep Link Into an Immersive Space

**Feature:** app supports a deep link `myapp://paint/start` that opens the
paint immersive space directly.

### Trust analysis

A URL is adversarial input. A deep link skips the normal app entry flow,
including auth prompts. An attacker could link past a gatekeeping step.

### What NOT to do

```swift
// Bad: open the scene directly on any URL
.onOpenURL { url in
    if url.host == "paint" {
        Task { await openImmersiveSpace(id: "paint") }
    }
}
```

If your app requires sign-in before drawing, this bypass is a real problem.

### What to do

```swift
.onOpenURL { url in
    guard let action = DeepLink.parse(url) else { return }
    switch action {
    case .openPaint:
        Task {
            // Gatekeep: must be authenticated first
            guard await authService.isAuthenticated else {
                await presentSignIn(then: .openPaint)
                return
            }
            await openImmersiveSpace(id: "paint")
        }
    }
}

enum DeepLink {
    case openPaint
    static func parse(_ url: URL) -> Self? {
        // Explicit allow-list, not string matching
        guard url.scheme == "myapp", url.host == "paint",
              url.path == "/start" else { return nil }
        return .openPaint
    }
}
```

### Commit

`security(deeplink): gate paint immersive-space entry behind auth check`

## Worked Example 4: App Group Data from a Sibling Extension

**Feature:** your app has a Share Extension that saves dropped USD files to
an App Group container for the main app to import.

### Trust analysis

A Share Extension shares the App Group with your main app. Other
extensions your app ships could also write there. Treat the data as
untrusted input.

### What NOT to do

```swift
// Bad: trust the file blindly
let data = try Data(contentsOf: appGroupURL.appendingPathComponent("pending.usdz"))
try scene.loadUSD(from: data)  // could be malformed, could be huge
```

### What to do

```swift
let url = appGroupURL.appendingPathComponent("pending.usdz")

// 1. Validate shape
let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
guard let size = attrs[.size] as? Int, size < 50_000_000 else {
    throw ImportError.tooLarge
}

// 2. Validate file signature
let handle = try FileHandle(forReadingFrom: url)
guard try handle.read(upToCount: 4) == Data([0x50, 0x4b, 0x03, 0x04]) else {
    throw ImportError.notUSDZ  // USDZ starts with PK (zip signature)
}

// 3. Load in a way that handles malformed content gracefully
do {
    try await scene.loadUSD(from: url)
} catch {
    logger.warning("Rejected invalid USD from share extension: \(error)")
    try? FileManager.default.removeItem(at: url)
}
```

### Commit

`security(import): validate USD file size and signature before loading`

## Entitlement Least Privilege

Audit regularly. Every entitlement in `.entitlements` is attack surface.

- Do not request `hand-tracking` if the feature is optional - request
  during the feature flow or ship a separate build
- Do not request enterprise entitlements on consumer apps
- Remove unused entitlements when features are removed (use
  `deprecation-visionos` for migration)

## When To Switch Skills

- `signing-entitlements` - for declaration, provisioning, and build-time config
- `shareplay` - for SharePlay session mechanics and group activity design
- `arkit` - for provider lifecycle and authorization flows
- `agent-skills:security-and-hardening` - for generic OWASP and threat modelling

## Guardrails

- Never transmit raw ARKit data off-device without explicit user consent
- Never trust SharePlay participants with sensitive operations
- Never bypass authentication flows via deep link
- Never persist secrets outside Keychain
- Audit entitlements regularly - least privilege is continuous, not one-time
