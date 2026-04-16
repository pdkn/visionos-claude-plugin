# Build visionOS Apps - Claude Code Plugin

## Purpose

This plugin equips Claude Code with the skills, agents, and commands needed to build, debug, and ship visionOS 26 applications for Apple Vision Pro. It combines platform expertise with visionOS-specialized engineering disciplines.

## Relationship to agent-skills

Many of this plugin's workflow skills extend patterns from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills). Each such skill is a **visionOS lens** - it references the generic Addy skill at the top and focuses on what is specific to visionOS (scene model, 90Hz, ARKit authorization, entitlements, etc).

You do NOT need agent-skills loaded to use this plugin - the lenses are self-contained. But if you have agent-skills available, the lenses pair cleanly with the generic patterns.

## XcodeBuildMCP Setup

The plugin depends on XcodeBuildMCP for build, run, and debug workflows. It is declared in `.mcp.json` and activated automatically when the plugin is loaded.

If XcodeBuildMCP is not available, fall back to direct `xcodebuild` and `simctl` shell commands.

## Skill Map

### Platform skills (visionOS APIs and patterns)

- **spatial-architecture** - scene model decisions, app structure, state ownership
- **swiftui-spatial** - spatial SwiftUI views, scene types, visionOS modifiers
- **realitykit** - entities, components, systems, render loop
- **arkit** - sessions, providers, anchors, tracked world
- **shareplay** - group activities, shared immersive presence
- **shader-graph** - Shader Graph materials for RealityKit
- **usd** - USD asset editing, validation, runtime loading
- **immersive-media** - immersive video, spatial video, playback
- **widgetkit** - visionOS WidgetKit spatial UI, mounting, animations
- **swiftpm-visionos** - Swift Package Manager and Reality Composer Pro
- **signing-entitlements** - signing, entitlements, privacy keys (build-time config)
- **coding-standards** - Swift 6 concurrency, actor isolation, @Observable

### Workflow lenses (extend agent-skills with visionOS specifics)

- **idea-refine** - spatial ideation before `/spec`
- **spec-driven-spatial** - extends `spec-driven-development`
- **incremental-build** - extends `incremental-implementation`
- **tdd-visionos** - extends `test-driven-development` with Prove-It for bugs
- **test-triage** - post-failure classification, pairs with tdd-visionos
- **debugging-triage** - extends `debugging-and-error-recovery`
- **perf-90hz** - extends `performance-optimization` with 90Hz budget
- **security-visionos** - extends `security-and-hardening` (runtime trust; pairs with signing-entitlements for build config)
- **deprecation-visionos** - extends `deprecation-and-migration` for Swift 6.2 + visionOS 26
- **git-workflow** - extends `git-workflow-and-versioning`
- **adr-spatial** - extends `documentation-and-adrs`
- **ci-visionos** - extends `ci-cd-and-automation`

### Engineering disciplines (spatial-specialized)

- **api-model-state-design** - @Observable, state ownership, entity vs view state, module boundaries
- **packaging-distribution** - archive, TestFlight, App Store submission, asc CLI

### Automation and tooling

- **build-run-debug** - XcodeBuildMCP and shell-based build/run/debug workflows
- **ui-automation** - AXe-based simulator automation (screenshots, video, accessibility dumps)

## Which Agent for Which Situation

| Situation | Agent |
|-----------|-------|
| Choosing between window, volume, and immersive space | spatial-architect |
| Reviewing a feature spec or architecture proposal | spatial-architect |
| Build succeeds but entities don't appear or behave wrong | realitykit-debugger |
| ARKit session fails or hand tracking is unreliable | realitykit-debugger |
| Build fails with compiler, linker, or signing errors | xcode-build-agent |
| Preparing for TestFlight or App Store submission | xcode-build-agent |
| Entitlement or capability is blocking launch | xcode-build-agent |

## Commands Reference

- `/build` - build, run, and debug on simulator
- `/build-and-run-visionos-app` - build and launch (detailed variant)
- `/fix-visionos-capability-error` - diagnose signing/capability errors
- `/test-visionos-app` - run tests with failure classification
- `/spec` - start a feature specification
- `/plan` - break a spec into ordered tasks
- `/review` - multi-axis code review
- `/ship` - pre-launch checklist
- `/code-simplify` - simplify code without changing behaviour

## visionOS 26 Key Notes

- **ARKitSession** requires explicit authorization. Always check `ARKitSession.AuthorizationStatus` before starting providers. Authorization can be revoked at any time.
- **Hand tracking at 90Hz** - the render loop must sustain 90fps. Avoid allocations, heavy computation, or blocking calls in `update()` methods of RealityKit systems. See `perf-90hz` for the 11.1ms budget details.
- **Scene types** determine spatial presence. `WindowGroup` for flat UI, `ImmersiveSpace` for placed-in-world content. Choose the scene type before writing UI code. See `spatial-architecture` and `spec-driven-spatial`.
- **Privacy entitlements** for world sensing (`com.apple.developer.arkit.main-camera-access`), hand tracking (`com.apple.developer.arkit.hand-tracking`), and other visionOS capabilities must be declared in both the `.entitlements` file and `Info.plist`. See `signing-entitlements` for declaration and `security-visionos` for runtime handling.
- **Simulator vs device** behaviour differs for signing, ARKit provider availability, and performance characteristics. Always specify which target you're building for.
