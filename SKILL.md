---
name: build-visionos-apps
description: Build, debug, and ship visionOS 26 apps for Apple Vision Pro. Combines XcodeBuildMCP-backed build workflows, visionOS platform skills (RealityKit, ARKit, SharePlay, USD, Shader Graph), visionOS-lens workflow skills built on top of Addy Osmani's agent-skills, and a set of engineering disciplines specialized for spatial computing.
---

# Build visionOS Apps

## Overview

This plugin provides 28 skills, 3 agents, and 9 commands for building visionOS 26 applications for Apple Vision Pro.

The skill set is organized into 4 sections:

1. **Platform skills** - visionOS APIs, patterns, and SDK knowledge
2. **Workflow lenses** - visionOS-specific extensions of [agent-skills](https://github.com/addyosmani/agent-skills) workflows
3. **Engineering disciplines** - spatial-specialized design and quality skills
4. **Automation and tooling** - build, distribute, and simulator automation

Where a skill extends an agent-skills pattern, it references the generic skill and focuses on what is visionOS-specific.

## Platform Skills (visionOS APIs and patterns)

| Skill | Use When |
|-------|----------|
| [spatial-architecture](skills/spatial-architecture/SKILL.md) | Choosing window vs volume vs immersive space, scene boundaries, state ownership topology |
| [swiftui-spatial](skills/swiftui-spatial/SKILL.md) | Spatial SwiftUI views, scene types, RealityView, Model3D, visionOS-specific modifiers |
| [realitykit](skills/realitykit/SKILL.md) | Entities, components, systems, render loop, RealityKit runtime |
| [arkit](skills/arkit/SKILL.md) | ARKit sessions, providers, anchors, tracked-world behaviour |
| [shareplay](skills/shareplay/SKILL.md) | Group activities, shared immersive presence, spatial coordination |
| [shader-graph](skills/shader-graph/SKILL.md) | Shader Graph materials for RealityKit |
| [usd](skills/usd/SKILL.md) | USD asset editing, validation, runtime loading |
| [immersive-media](skills/immersive-media/SKILL.md) | Immersive video, spatial video, playback |
| [widgetkit](skills/widgetkit/SKILL.md) | visionOS WidgetKit spatial UI, mounting, animations |
| [swiftpm-visionos](skills/swiftpm-visionos/SKILL.md) | Swift Package Manager and Reality Composer Pro |
| [signing-entitlements](skills/signing-entitlements/SKILL.md) | Signing, entitlements, privacy keys, provisioning (build-time config) |
| [coding-standards](skills/coding-standards/SKILL.md) | Swift 6 concurrency, actor isolation, @Observable patterns |

## Workflow Lenses (extensions of agent-skills)

These skills extend a specific agent-skills pattern with visionOS-specific concerns. Each references its Addy parent at the top.

| Skill | Extends | Focus |
|-------|---------|-------|
| [idea-refine](skills/idea-refine/SKILL.md) | `idea-refine` | Divergent/convergent thinking across surface models, user proximity, spatial metaphors |
| [spec-driven-spatial](skills/spec-driven-spatial/SKILL.md) | `spec-driven-development` | Scene model gate, entity lifecycle, ARKit/SharePlay/entitlements questions |
| [incremental-build](skills/incremental-build/SKILL.md) | `incremental-implementation` | RealityKit slice ordering, simulator verification gate |
| [tdd-visionos](skills/tdd-visionos/SKILL.md) | `test-driven-development` | XCTest + Swift Testing, RealityKit system tests, ARKit mocking, Prove-It for bugs |
| [test-triage](skills/test-triage/SKILL.md) | (standalone, pairs with tdd-visionos) | Post-failure classification (build / assertion / crash / flake / capability) |
| [debugging-triage](skills/debugging-triage/SKILL.md) | `debugging-and-error-recovery` | Five visionOS failure categories with dedicated triage paths |
| [perf-90hz](skills/perf-90hz/SKILL.md) | `performance-optimization` | 11.1ms frame budget, Instruments, allocation-free render loops |
| [security-visionos](skills/security-visionos/SKILL.md) | `security-and-hardening` | ARKit/hand tracking/camera trust, SharePlay session trust, App Group isolation |
| [deprecation-visionos](skills/deprecation-visionos/SKILL.md) | `deprecation-and-migration` | Migrate to Swift 6.2 + visionOS 26 patterns, kill outdated idioms |
| [git-workflow](skills/git-workflow/SKILL.md) | `git-workflow-and-versioning` | .xcodeproj and .entitlements dedicated commits, scene-type branch naming |
| [adr-spatial](skills/adr-spatial/SKILL.md) | `documentation-and-adrs` | Scene model decisions, RealityKit architecture, ARKit strategy ADRs |
| [ci-visionos](skills/ci-visionos/SKILL.md) | `ci-cd-and-automation` | Xcode Cloud and GitHub Actions for visionOS, privacy scans, TestFlight automation |

## Engineering Disciplines (visionOS-specialized design)

| Skill | Use When |
|-------|----------|
| [api-model-state-design](skills/api-model-state-design/SKILL.md) | @Observable, state ownership scopes, RealityKit entity vs SwiftUI state, module boundaries |
| [packaging-distribution](skills/packaging-distribution/SKILL.md) | Archive, TestFlight, App Store submission, asc CLI |

## Automation and Tooling

| Skill | Use When |
|-------|----------|
| [build-run-debug](skills/build-run-debug/SKILL.md) | Building, running, and debugging with XcodeBuildMCP or shell fallback |
| [ui-automation](skills/ui-automation/SKILL.md) | AXe-based simulator automation: screenshots, video, keyboard, accessibility dumps |

## Agents

| Agent | Role | Invoke When |
|-------|------|-------------|
| [spatial-architect](agents/spatial-architect.md) | Senior spatial design reviewer | New feature specs, architecture reviews, scene model decisions |
| [realitykit-debugger](agents/realitykit-debugger.md) | RealityKit/ARKit runtime specialist | Build succeeds but runtime behaviour is wrong |
| [xcode-build-agent](agents/xcode-build-agent.md) | Build and CI orchestrator | Build failures, signing issues, distribution tasks |

## Commands

| Command | Purpose |
|---------|---------|
| `/build` | Build, run, and debug on Apple Vision Pro simulator |
| `/build-and-run-visionos-app` | Build and launch on Apple Vision Pro simulator (detailed) |
| `/fix-visionos-capability-error` | Diagnose and fix capability, privacy, or signing errors |
| `/test-visionos-app` | Run tests with failure classification |
| `/spec` | Start a feature specification (no code until approved) |
| `/plan` | Break a spec into ordered, verifiable tasks |
| `/review` | Code review across spatial, RealityKit, Swift, and quality axes |
| `/ship` | Pre-launch checklist for TestFlight and App Store readiness |
| `/code-simplify` | Simplify visionOS code without changing behaviour |

## Typical Workflow Sequence

```
idea-refine              - shape a vague idea
/spec "feature name"     - define what we're building
/plan "feature name"     - break into verifiable slices
  [implement slice]      - one RealityKit component/system at a time
  [tdd-visionos]         - failing test first
  [verify on simulator]  - each slice must build and run
/review                  - multi-axis review before merge
/ship                    - pre-launch checklist
```

## XcodeBuildMCP Dependency

This plugin requires XcodeBuildMCP for build, run, and debug workflows. It is declared in `.mcp.json` and will be available as an MCP server when the plugin is loaded.

## visionOS 26 Notes

- ARKitSession requires explicit authorization - always check status before starting providers
- Hand tracking runs at 90Hz - code in the render loop must sustain this rate (see `perf-90hz`)
- Scene types (WindowGroup, ImmersiveSpace) determine the app's spatial presence - choose deliberately (see `spatial-architecture`, `spec-driven-spatial`)
- Privacy entitlements for world sensing, hand tracking, and camera access must be declared in `.entitlements` and `Info.plist` (see `signing-entitlements`)
