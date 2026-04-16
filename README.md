# visionOS Claude Plugin

A Claude Code plugin for building, debugging, and shipping visionOS 26 apps
for Apple Vision Pro. Combines platform expertise (RealityKit, ARKit, spatial
SwiftUI, SharePlay, USD, Shader Graph) with visionOS-specialized engineering
disciplines adapted from [agent-skills](https://github.com/addyosmani/agent-skills).

## Installation

Load the plugin locally during development:

```bash
claude --plugin-dir /path/to/visionos-claude-plugin
```

Use `/reload-plugins` inside a session to pick up changes without restarting.

## Relationship to agent-skills

Many of this plugin's workflow skills are **visionOS lenses** on patterns
from [agent-skills](https://github.com/addyosmani/agent-skills). Each lens
references its Addy parent at the top and focuses only on what is specific
to visionOS - scene model, 90Hz, ARKit authorization, entitlements, spatial
trust boundaries, etc.

You do not need agent-skills loaded to use this plugin - the lenses are
self-contained. But if you have agent-skills available, they pair cleanly.

## Skills (28)

### Platform skills (visionOS APIs and patterns)

| Skill | Use When |
|-------|----------|
| `spatial-architecture` | Window vs volume vs immersive space, scene boundaries, state ownership topology |
| `swiftui-spatial` | Spatial SwiftUI views, RealityView, Model3D, visionOS modifiers |
| `realitykit` | Entities, components, systems, render loop |
| `arkit` | ARKit sessions, providers, anchors, tracked-world behaviour |
| `shareplay` | Group activities, shared immersive presence |
| `shader-graph` | Shader Graph materials for RealityKit |
| `usd` | USD asset editing, validation, runtime loading |
| `immersive-media` | Immersive video, spatial video, playback |
| `widgetkit` | visionOS WidgetKit spatial UI, mounting, animations |
| `swiftpm-visionos` | Swift Package Manager, Reality Composer Pro |
| `signing-entitlements` | Signing, entitlements, privacy keys (build-time config) |
| `coding-standards` | Swift 6 concurrency, actor isolation, @Observable |

### Workflow lenses (extend agent-skills)

| Skill | Extends | Focus |
|-------|---------|-------|
| `idea-refine` | `idea-refine` | Surface model brainstorming, spatial metaphors |
| `spec-driven-spatial` | `spec-driven-development` | Scene model, entity lifecycle, ARKit/SharePlay/entitlements questions |
| `incremental-build` | `incremental-implementation` | RealityKit slice ordering, simulator verification gate |
| `tdd-visionos` | `test-driven-development` | XCTest + Swift Testing, RealityKit isolation, Prove-It for bugs |
| `test-triage` | (pairs with tdd-visionos) | Post-failure classification |
| `debugging-triage` | `debugging-and-error-recovery` | Five visionOS failure categories |
| `perf-90hz` | `performance-optimization` | 11.1ms frame budget, Instruments, allocation-free loops |
| `security-visionos` | `security-and-hardening` | ARKit/hand-tracking/camera trust, SharePlay trust |
| `deprecation-visionos` | `deprecation-and-migration` | Migrate to Swift 6.2 + visionOS 26 patterns |
| `git-workflow` | `git-workflow-and-versioning` | .xcodeproj/.entitlements dedicated commits |
| `adr-spatial` | `documentation-and-adrs` | Scene model and RealityKit architecture ADRs |
| `ci-visionos` | `ci-cd-and-automation` | Xcode Cloud, GitHub Actions, privacy scans |

### Delivery and tooling

| Skill | Use When |
|-------|----------|
| `build-run-debug` | XcodeBuildMCP and shell-based build/run/debug |
| `telemetry` | Logger/OSLog instrumentation, signposts, runtime event verification |
| `ui-automation` | AXe-based simulator automation: screenshots, video, accessibility dumps |
| `packaging-distribution` | Archive, TestFlight, App Store submission, asc CLI |

## Commands (9)

| Command | Purpose |
|---------|---------|
| `/build` | Build, run, and debug on Apple Vision Pro simulator |
| `/build-and-run-visionos-app` | Detailed build and launch workflow |
| `/fix-visionos-capability-error` | Diagnose and fix capability/signing errors |
| `/test-visionos-app` | Run tests with failure classification |
| `/spec` | Start a feature specification (no code until approved) |
| `/plan` | Break a spec into ordered, verifiable tasks |
| `/review` | Multi-axis code review |
| `/ship` | Pre-launch checklist for TestFlight and App Store |
| `/code-simplify` | Simplify visionOS code without changing behaviour |

## Agents (3)

| Agent | When to Use |
|-------|-------------|
| `spatial-architect` | New feature specs, architecture reviews, scene model decisions |
| `realitykit-debugger` | Build succeeds but runtime behaviour is wrong |
| `xcode-build-agent` | Build failures, signing issues, distribution tasks |

## Typical Workflow

```
idea-refine              - shape a vague idea
/spec "feature name"     - define what we're building
/plan "feature name"     - break into verifiable slices
  tdd-visionos           - failing test first
  [implement slice]      - one RealityKit component/system
  [verify on simulator]  - gate before moving on
/review                  - multi-axis review
/ship                    - pre-launch checklist
```

## XcodeBuildMCP

The plugin declares XcodeBuildMCP as an MCP server in `.mcp.json`. It is
activated automatically when the plugin loads. If unavailable, skills fall
back to direct `xcodebuild` and `simctl` shell commands.

## Optional External Tools

These CLIs extend what the plugin can do. They are not bundled and are not
required for the core build/run/debug loop:

- **AXe** (`brew install cameroncooke/axe/axe`) - Apple Vision Pro simulator
  automation for screenshots, video capture, keyboard input, hardware button
  presses, and accessibility tree inspection. Used by the `ui-automation`
  skill. AXe's 2D touch commands (`tap`/`swipe`/`gesture`) target iOS and are
  not reliable on visionOS; the skill routes spatial gestures back to XCUITest.

- **App Store Connect CLI** (`brew install asc`) - JWT-authenticated automation
  for TestFlight uploads, App Store submissions, metadata, screenshots, and
  certificates. Used by the `packaging-distribution` skill. The `.p8` key
  must be loaded by you (`asc auth login`), never by the agent.

## Recommended Companion Plugins

This plugin focuses on what is specific to visionOS. Generic Swift language
concerns are better handled by specialized tools that already exist.

- **swift-lsp** (via Anthropic's plugin marketplace) - Wraps `sourcekit-lsp`
  to provide type diagnostics, jump-to-definition, find-references, and hover
  docs for Swift code. Install alongside this plugin for the full development
  loop. This plugin deliberately does not re-implement language-level concerns.

## visionOS 26 Notes

- ARKitSession requires explicit authorization - always check status before
  starting providers
- Hand tracking runs at 90Hz - render loop code must sustain this rate
  (see `perf-90hz`)
- Scene types (WindowGroup, ImmersiveSpace) determine spatial presence -
  choose deliberately (see `spatial-architecture` and `spec-driven-spatial`)
- Privacy entitlements for world sensing, hand tracking, and camera access
  must be declared in both `.entitlements` and `Info.plist`

## Comparison with visionos-codex-plugin

This plugin originated as a Claude Code fork of Studio Meije's
[`visionos-codex-plugin`](https://github.com/studiomeije/visionos-codex-plugin)
and has since diverged substantially. Both plugins share the 13 visionOS
platform skills. Claude adds an engineering discipline layer (idea-refine,
spec-driven-spatial, TDD, debugging-triage, perf-90hz, security-visionos,
deprecation-visionos, adr-spatial, git-workflow, ci-visionos), three agent
personas, a build-log capture hook, and six additional slash commands.

For the full feature matrix and when-to-use-which guidance, see
[docs/comparison-with-codex.md](docs/comparison-with-codex.md).

---

## Credits

Platform skills derived from [visionos-codex-plugin](https://github.com/studiomeije/visionos-codex-plugin)
by [Studio Meije](https://github.com/studiomeije), inspired by:

- [Ivan Campos](https://github.com/ivancampos)
- [Paul Hudson](https://github.com/twostraws)
- [Pedro Pinera Buendia](https://github.com/pepicrft)
- [Thomas Ricouard](https://github.com/Dimillian/)
- [Sharno](https://github.com/sharno)

Workflow lens skills adapted from
[agent-skills](https://github.com/addyosmani/agent-skills) by
[Addy Osmani](https://github.com/addyosmani). Each lens extends one of
Addy's generic patterns with visionOS-specific concerns.

## License

MIT
