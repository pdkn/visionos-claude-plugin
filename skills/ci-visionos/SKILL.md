---
name: ci-visionos
description: visionOS lens on CI/CD and automation. Covers Xcode Cloud and GitHub Actions patterns for visionOS builds, required quality gates (build, test, lint, sign), branch protection for .entitlements, automated privacy scans, and asc CLI integration for TestFlight.
---

# CI/CD for visionOS - Lens

## Addy Parent

This skill extends `ci-cd-and-automation` from agent-skills. Follow the generic "automated quality gates on every change" discipline there. This skill adds the visionOS-specific pipeline steps and runner requirements.

## Runner Requirements

visionOS builds need a runner with:
- macOS 15 or newer
- Xcode with the visionOS SDK installed
- Apple Vision Pro simulator runtime available

**Xcode Cloud** meets these by default. **GitHub Actions** requires `macos-14` or newer, usually `macos-15`, with a manual Xcode version select step or a pre-installed image.

## Pipeline Stages

A minimum visionOS CI pipeline:

1. **Checkout** - git clone
2. **Xcode select** - pin the Xcode version explicitly
3. **Resolve dependencies** - SwiftPM resolve, pod install, or submodule update
4. **Build** - `xcodebuild build -scheme <s> -destination 'platform=visionOS Simulator,name=Apple Vision Pro'`
5. **Test** - `xcodebuild test` with a visionOS simulator destination
6. **Lint** - SwiftLint, SwiftFormat check
7. **Privacy scan** - verify `.entitlements` and `Info.plist` against an expected allowlist
8. **Archive** - only on release branches
9. **Upload** - `asc` CLI for TestFlight, only on tagged releases

## Branch Protection

Protect `main` with these required checks:
- Build succeeds for visionOS simulator
- Tests pass
- Lint passes
- Changes to `.entitlements` require code owner review
- Changes to `Info.plist` privacy keys require code owner review

## Automated Privacy Scans

Write a small script to check for drift:
- Every privacy key in `Info.plist` must have a corresponding code reference
- Every declared entitlement must have a usage site
- Flag new privacy keys introduced in a PR
- Flag removed privacy keys that may indicate a capability removal

## asc CLI in CI

For TestFlight uploads:
- Store the `.p8` key in the CI secret store, never in source
- Use a dedicated App Store Connect API key for CI (separate from personal)
- Tag-triggered uploads only, never on every merge
- Log upload results for audit

## Cache Strategy

visionOS builds are slow. Cache:
- DerivedData (per-scheme, per-platform)
- SwiftPM dependencies
- Simulator runtimes (usually pre-installed on managed runners)

Invalidate on:
- Xcode version change
- SwiftPM `Package.resolved` change
- `.xcconfig` change

## Xcode Cloud vs GitHub Actions

| Factor | Xcode Cloud | GitHub Actions |
|--------|-------------|----------------|
| Setup time | Minutes | Hours |
| Cost | Per-compute-hour after free tier | Per-minute after free tier |
| Apple platform native | Yes | No (needs setup) |
| Custom scripts | Limited | Full |
| Third-party action ecosystem | No | Yes |
| Secret management | Apple ecosystem | GitHub |

Choose Xcode Cloud for small teams with standard workflows. Choose GitHub Actions when you need custom pipelines or have non-Apple build steps.

## When To Switch Skills

- `packaging-distribution` - for archive and TestFlight step mechanics
- `ui-automation` - for CI screenshot diffs using AXe
- `test-triage` - when CI tests fail and need classification
- `signing-entitlements` - when CI signing fails
- `ci-cd-and-automation` (agent-skills) - for generic pipeline design

## Guardrails

- Never commit `.p8` keys, signing certs, or provisioning profiles to source
- Never skip the privacy scan check
- Never auto-upload on every merge - tag-triggered only
- Never bypass branch protection for `.entitlements` changes
- Always pin the Xcode version - do not rely on the runner's default
