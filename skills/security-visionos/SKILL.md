---
name: security-visionos
description: visionOS lens on security and hardening. Covers input validation and trust boundaries for spatial apps - ARKit world sensing data classification, hand tracking privacy scope, SharePlay session trust, App Group isolation, entitlement least-privilege, and URL scheme validation.
---

# Security for visionOS - Lens

## Addy Parent

This skill extends `security-and-hardening` from agent-skills. Follow the generic OWASP prevention, input validation, and least privilege discipline there. This skill adds spatial-specific trust boundaries and privacy data handling.

## Scope Clarification

This skill is about **runtime trust and data handling**. For build-time configuration (signing, entitlement declaration, privacy key presence), use `signing-entitlements`. The two are complementary - use both when shipping security-sensitive features.

## Spatial Trust Boundaries

### ARKit World Sensing Data

World tracking, scene reconstruction, camera frames, and plane data contain information about the user's physical environment. Treat this as sensitive:

- Never log anchor positions, mesh geometry, or camera frames to external analytics
- Do not transmit raw scene geometry off-device without explicit user consent
- Strip or generalize spatial data before any cross-user sharing
- Assume any data you capture may reveal personal or confidential surroundings

### Hand Tracking Data

Hand skeleton data can identify users biometrically and reveal typed input on physical keyboards:

- Process hand data on-device only unless the feature is explicitly shared
- Never log raw joint positions with timestamps that could reconstruct input
- In SharePlay, decide explicitly whether to send hand anchors - default is to not

### Camera Frames

Enterprise entitlements grant camera access; consumer apps do not have it. For apps that do:
- Treat camera frames like any other sensitive media
- Never persist frames except for explicit user action (e.g., screenshot)
- Show persistent UI indicators when the camera is in active use

### SharePlay Session Trust

Participants in a SharePlay session are not authenticated by your app:

- Never trust session participants with sensitive operations (payments, account changes)
- Validate all incoming messages against expected shapes
- Ignore messages from participants before they have completed a handshake
- Design message protocols to be idempotent - duplicate or reordered messages must be safe

## Input Validation

### URL Schemes and Universal Links

Treat all incoming URLs as adversarial:
- Parse structurally before acting
- Validate that host, path, and parameters match expected shapes
- Never execute URL parameters as code or shell commands
- Log unexpected URL shapes for monitoring

### App Group and Shared Container Data

Data written by a sibling extension or another app in the same App Group is not authenticated:
- Validate data shape before use
- Treat it as untrusted input
- Use dedicated subkeys per producer to limit blast radius

### Deep Links Into Immersive Spaces

A URL that opens an immersive space is an app entry point:
- The scene must be safe to enter from any state
- Do not bypass authentication flows via deep link

## Entitlement Least Privilege

Request only what you use:

- Do not request `com.apple.developer.arkit.hand-tracking` if the feature is optional - request at runtime or in a separate build
- Do not request enterprise entitlements on consumer apps
- Regularly audit the `.entitlements` file - unused entitlements are attack surface

## Data at Rest

For app-local storage:
- Use Keychain for tokens, credentials, session IDs
- Use encrypted Core Data or SQLite for sensitive records
- Never store secrets in `UserDefaults` or asset catalogs
- App Group storage inherits the sensitivity of the data in it

## When To Switch Skills

- `signing-entitlements` - for declaration, provisioning, and build-time config
- `shareplay` - for SharePlay session mechanics and group activity design
- `arkit` - for provider lifecycle and authorization flows
- `security-and-hardening` (agent-skills) - for generic OWASP and threat modelling

## Guardrails

- Never transmit raw ARKit data off-device without explicit user consent
- Never trust SharePlay participants with sensitive operations
- Never bypass authentication flows via deep link
- Never persist secrets outside Keychain
- Audit entitlements regularly - least privilege is continuous
