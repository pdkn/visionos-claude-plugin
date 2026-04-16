# Xcode and visionOS Commit Conventions

Use these conventions alongside `agent-skills:git-workflow-and-versioning` for
generic atomic-commit discipline. These are the visionOS and Xcode specifics
that generic git workflow skills do not cover.

## Dedicated Commits

Isolate these in their own commits. Reviewers and `git bisect` need them
separate from code:

- **`.xcodeproj` changes** - target, scheme, build settings, resource additions
- **`.entitlements`** - any add/remove/rename of entitlement keys
- **`Info.plist` privacy keys** - any add/remove of `NS*UsageDescription`
- **Asset catalogs** - images, models, USD files, audio
- **`Package.resolved`** - dependency version changes

Rationale: Xcode project files and entitlements produce noisy diffs and affect
signing. Binary assets slow down clones and merges. Separate commits let you
revert a bad asset or entitlement change without touching source.

## Commit Message Conventions

Prefix the commit subject with the visionOS area affected:

- `scene: open new immersive space for detail view`
- `realitykit: add HandPoseComponent and PoseDetectionSystem`
- `arkit: handle authorization revocation during world tracking`
- `entitlements: add hand tracking capability`
- `xcodeproj: add RealityKitTests target`
- `info.plist: add NSWorldSensingUsageDescription`
- `assets: add palette textures for paint tool`

For bug fixes, reference the failure category from `debugging-triage`:

- `fix(arkit-session): restart session on authorization change`
- `fix(render-loop): remove per-frame allocation in trail system`

## Branch Naming

Convention: `<type>/<scene-type>/<short-description>`

- `feature/immersive/hand-tracking-setup`
- `feature/volume/chess-board-manipulation`
- `feature/window/settings-panel`
- `fix/immersive/scale-reset-on-open`
- `refactor/scene-lifecycle/state-ownership`
- `chore/xcodeproj/restructure-schemes`

The scene-type segment is optional when the branch spans multiple scenes or is
not scene-specific (e.g. `refactor/coding-standards/swift6-migration`).

## Green Build Commits

Commit only at green points:
- App builds on Apple Vision Pro simulator (via `build-run-debug`)
- App launches without new runtime errors
- Tests pass, or are unchanged

A slice from `incremental-build` that passes the simulator verification gate
is a commit boundary.

## Guardrails

- Never mix `.xcodeproj` changes with source changes
- Never mix `.entitlements` or `Info.plist` privacy-key changes with feature code
- Never commit a slice that has not passed the simulator verification gate
- Never force-push to shared branches
- Never use generic messages like "fix stuff" or "updates" - always reference
  the scene, component, system, or config being changed
