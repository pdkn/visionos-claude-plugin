---
name: git-workflow
description: visionOS lens on git workflow and versioning. Adds visionOS-specific commit boundaries - .xcodeproj and .entitlements always in dedicated commits - and a scene-type branch naming convention.
---

# Git Workflow - visionOS Lens

## Addy Parent

This skill extends `git-workflow-and-versioning` from agent-skills. Follow the generic atomic commit discipline there. This skill adds the visionOS-specific commit boundaries and naming conventions.

## Dedicated Commits

These types of changes must be isolated in their own commits:

### `.xcodeproj` Changes
- Adding, removing, or renaming targets
- Changing build settings
- Adding resources
- Changing scheme definitions

Rationale: Xcode project files are noisy diffs. Bundling them with code changes makes review impossible and breaks git bisect.

### `.entitlements` and `Info.plist` Changes
- Adding or removing entitlements
- Adding privacy usage descriptions
- Changing capability declarations

Rationale: Entitlements affect signing, provisioning, and runtime behaviour. They need explicit review separately from feature code.

### Asset Catalog Changes
- Adding or replacing images, models, USD files
- Texture updates
- Audio asset changes

Rationale: Large binary diffs slow down clones and merges. Separate commits help bisect if an asset introduces an issue.

## Commit Message Conventions

Reference what visionOS area the commit changes:

- `scene: open new immersive space for detail view`
- `realitykit: add HandPoseComponent and system`
- `arkit: handle authorization revocation`
- `entitlements: add hand tracking capability`
- `xcodeproj: add tests target for RealityKit systems`

## Branch Naming

Convention: `<type>/<scene-type>/<short-description>`

- `feature/immersive/hand-tracking-setup`
- `feature/window/settings-redesign`
- `fix/volume/scale-reset-on-open`
- `refactor/scene-lifecycle/state-ownership`

The scene-type segment is optional when the branch spans multiple scenes or is not scene-specific.

## Green Build Commits

Commit only at green points:
- App builds on Apple Vision Pro simulator
- App launches without new errors
- Tests pass (or have not changed)

If a slice from `incremental-build` passes the verification gate, that is a commit boundary.

## When To Switch Skills

- `incremental-build` - work to commit comes from here
- `tdd-visionos` - tests to commit alongside code come from here
- `debugging-triage` - fixes to commit come from here
- `git-workflow-and-versioning` (agent-skills) - for merge strategy, conflict resolution, release branches

## Guardrails

- Never mix `.xcodeproj` changes with source changes
- Never mix `.entitlements` or `Info.plist` changes with feature code
- Never commit a slice that has not passed the simulator verification gate
- Never force-push to shared branches
- Never use generic commit messages like "fix stuff" or "updates"
