# visionOS Claude Plugin

A Claude Code plugin for building, debugging, and shipping visionOS 26 apps
for Apple Vision Pro. Combines platform expertise (RealityKit, ARKit, spatial
SwiftUI, SharePlay, USD, Shader Graph) with disciplined engineering workflows
adapted from [agent-skills](https://github.com/addyosmani/agent-skills).

## Installation

Load the plugin locally during development:

```bash
claude --plugin-dir /path/to/visionos-claude-plugin
```

Use `/reload-plugins` inside a session to pick up changes without restarting.

## Skills (20)

### Platform Skills

| Skill | Use When |
|-------|----------|
| `spatial-architecture` | Choosing window vs volume vs immersive space, scene boundaries, state ownership |
| `realitykit` | Entities, components, systems, render loop, RealityKit runtime |
| `arkit` | ARKit sessions, providers, anchors, tracked-world behaviour |
| `shareplay` | Group activities, shared immersive presence, spatial coordination |
| `shader-graph` | Shader Graph materials for RealityKit |
| `usd` | USD asset editing, validation, runtime loading |
| `signing-entitlements` | Signing, entitlements, privacy keys, provisioning |
| `immersive-media` | Immersive media playback, spatial video, viewing experiences |
| `swiftui-spatial` | Spatial SwiftUI views, scene types, visionOS modifiers |
| `coding-standards` | Swift 6 concurrency, actor isolation, @Observable patterns |
| `packaging-distribution` | Archive, TestFlight, App Store submission |
| `swiftpm-visionos` | Swift Package Manager, Reality Composer Pro |
| `test-triage` | XCTest and Swift Testing failure classification |
| `widgetkit` | visionOS WidgetKit spatial UI, mounting, animations |
| `ui-automation` | AXe-based simulator automation: screenshots, video, accessibility dumps |

### Engineering Workflow Skills

| Skill | Use When |
|-------|----------|
| `build-run-debug` | Building, running, debugging with XcodeBuildMCP or shell tools |
| `spec-driven-spatial` | Starting a new feature - write a spec before code |
| `incremental-build` | Thin vertical slices, one RealityKit component/system at a time |
| `debugging-triage` | Systematic root-cause debugging for visionOS runtime issues |
| `adr-spatial` | Architecture decision records for spatial design choices |
| `git-workflow` | Atomic commits, visionOS-specific commit discipline |

## Commands (9)

| Command | Purpose |
|---------|---------|
| `/build` | Build, run, and debug on Apple Vision Pro simulator |
| `/build-and-run-visionos-app` | Detailed build and launch workflow |
| `/fix-visionos-capability-error` | Diagnose and fix capability/signing errors |
| `/test-visionos-app` | Run tests with failure classification |
| `/spec` | Start a feature specification (no code until approved) |
| `/plan` | Break a spec into ordered, verifiable tasks |
| `/review` | Multi-axis code review (correctness, spatial, Swift, security, performance) |
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
/spec "feature name"     - define what we're building
/plan "feature name"     - break into verifiable slices
/build run               - build and launch each slice
/review                  - review before merge
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

## visionOS 26 Notes

- ARKitSession requires explicit authorization - always check status before
  starting providers
- Hand tracking runs at 90Hz - render loop code must sustain this rate
- Scene types (WindowGroup, ImmersiveSpace) determine spatial presence -
  choose deliberately
- Privacy entitlements for world sensing, hand tracking, and camera access
  must be declared in both .entitlements and Info.plist

---

## Credits

Platform skills derived from [visionos-codex-plugin](https://github.com/studiomeije/visionos-codex-plugin)
by [Studio Meije](https://github.com/studiomeije), inspired by:

- [Ivan Campos](https://github.com/ivancampos)
- [Paul Hudson](https://github.com/twostraws)
- [Pedro Pinera Buendia](https://github.com/pepicrft)
- [Thomas Ricouard](https://github.com/Dimillian/)
- [Sharno](https://github.com/sharno)

Engineering workflow skills adapted from
[agent-skills](https://github.com/addyosmani/agent-skills) by
[Addy Osmani](https://github.com/addyosmani).

## License

MIT
