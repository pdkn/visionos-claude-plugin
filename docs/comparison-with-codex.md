# Comparison with visionos-codex-plugin

This plugin (`visionos-claude-plugin`) originated as a Claude Code fork of
Studio Meije's [`visionos-codex-plugin`](https://github.com/studiomeije/visionos-codex-plugin)
for OpenAI Codex. It has since diverged substantially, adding an engineering
discipline layer adapted from
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), three
agent personas, a build-log capture hook, and a clearer navigation model.

This document tracks the functional differences. It is primarily for
maintainers and contributors who want to understand the relationship between
the two plugins. Everyday users of either plugin do not need to read this.

## TL;DR

- **Identical visionOS platform knowledge** (13 skills). Both ship the same
  reference content for RealityKit, ARKit, SharePlay, USD, Shader Graph,
  immersive media, spatial SwiftUI, WidgetKit, SwiftPM, signing/entitlements,
  coding standards, packaging/distribution, and spatial architecture.
- **Claude adds an engineering discipline layer** Codex does not have: idea
  refinement, spec-driven development, planning, TDD, incremental build
  discipline, debugging triage, 90Hz performance, runtime security,
  deprecation migration, ADRs, git workflow, CI/CD, and code review.
- **Claude adds 3 agent personas** with structured triage protocols
  (`spatial-architect`, `realitykit-debugger`, `xcode-build-agent`). Codex
  has no agent personas.
- **Claude adds a build-log capture hook** that auto-feeds Xcode build output
  into session context with filter modes to control log size. Codex has a
  Run-button bootstrap script instead, which solves a different problem
  (repeatable entry point for Codex's Run button UI).
- **Claude has 9 slash commands**; Codex has 3.
- **Both now ship telemetry** (OSLog instrumentation) with identical content.

## When to use which

Use **visionos-codex-plugin** when:
- You are working in OpenAI Codex and need the Codex-native Run button
  integration.
- You want the Studio Meije plugin exactly as published, without the
  engineering workflow additions.

Use **visionos-claude-plugin** when:
- You are working in Claude Code.
- You want the engineering workflow layer (spec, plan, TDD, review, ship,
  debugging triage) alongside the visionOS platform knowledge.
- You want automatic build-log evidence injection into the agent session.
- You want agent personas with structured protocols for architecture review
  and runtime triage.

Both plugins can be maintained in parallel. Platform skill content stays
functionally equivalent between them. The engineering layer is
Claude-specific.

## Shared foundation

Both plugins ship identical content for these 13 skills:

- spatial-architecture
- swiftui-spatial
- realitykit
- arkit
- shareplay
- shader-graph
- usd
- immersive-media
- widgetkit
- swiftpm-visionos
- signing-entitlements
- coding-standards
- packaging-distribution

Plus these matching capabilities:

- `test-triage` - XCTest/Swift Testing failure classification
- `telemetry` - Logger/OSLog instrumentation
- `ui-automation` - AXe-based simulator automation

## Feature matrix

### Pre-implementation

| Capability | Codex | Claude |
|---|---|---|
| Idea refinement for spatial features | no | `idea-refine` |
| Spec-driven development with scene model gate | no | `spec-driven-spatial` + `/spec` |
| Task breakdown into verifiable slices | no | `/plan` |

### Implementation

| Capability | Codex | Claude |
|---|---|---|
| Thin-slice RealityKit implementation discipline | no | `incremental-build` |
| TDD for visionOS (XCTest + Swift Testing, RealityKit system isolation, ARKit mocking, Prove-It for bugs) | no | `tdd-visionos` |

### Debugging and verification

| Capability | Codex | Claude |
|---|---|---|
| Build, run, debug (XcodeBuildMCP + shell fallback) | `build-run-debug` | `build-run-debug` + `/build` command |
| Automatic build-log capture into session | no | `hooks/post-build-log-capture.sh` with auto / full / errors filter modes |
| Codex Run-button bootstrap script | `scripts/bootstrap_build_and_run.sh` | no - not applicable to Claude Code |
| Test failure classification | `test-triage` | `test-triage` |
| Runtime debugging triage (5 visionOS failure categories) | no | `debugging-triage` + `realitykit-debugger` agent |
| OSLog telemetry and signpost instrumentation | `telemetry` | `telemetry` |
| 90Hz render budget optimization | no | `perf-90hz` |

### Review and quality

| Capability | Codex | Claude |
|---|---|---|
| Multi-axis code review | no | `/review` command + `spatial-architect` agent |
| Code simplification workflow | no | `/code-simplify` command |
| Runtime security (ARKit data, SharePlay trust, input validation) | no | `security-visionos` |
| Deprecation detection and migration to Swift 6.2 / visionOS 26 | no | `deprecation-visionos` |

### Ship and automation

| Capability | Codex | Claude |
|---|---|---|
| Packaging, TestFlight, App Store (asc CLI) | `packaging-distribution` | `packaging-distribution` + `/ship` checklist command + `xcode-build-agent` |
| Simulator automation (AXe) | `ui-automation` | `ui-automation` |
| CI/CD patterns for visionOS | no | `ci-visionos` |
| Architecture decision records | no | Reference doc: `spatial-architecture/references/adr-triggers.md` |
| Git workflow (dedicated .xcodeproj / .entitlements commits) | no | Reference doc: `coding-standards/references/xcode-commit-conventions.md` |

### Navigation and plugin structure

| Item | Codex | Claude |
|---|---|---|
| Plugin manifest | `.codex-plugin/plugin.json` | `.claude-plugin/plugin.json` |
| MCP registration | `.mcp.json` | `.mcp.json` |
| Root skill map | no | `SKILL.md` with 3 sections |
| Plugin-specific guidance | `agents/openai.yaml` | `CLAUDE.md` |
| Icon asset | `assets/icon.png` | no |
| Recommended companion plugins | no | `swift-lsp` (documented in README and CLAUDE.md) |

### Agent personas

| Agent | Codex | Claude |
|---|---|---|
| spatial-architect (scene model reviewer) | no | yes |
| realitykit-debugger (runtime triage specialist) | no | yes |
| xcode-build-agent (build orchestrator) | no | yes |

### Slash commands

| Command | Codex | Claude |
|---|---|---|
| /build-and-run-visionos-app | yes | yes |
| /fix-visionos-capability-error | yes | yes |
| /test-visionos-app | yes | yes |
| /build | no | yes |
| /spec | no | yes |
| /plan | no | yes |
| /review | no | yes |
| /ship | no | yes |
| /code-simplify | no | yes |

## Totals

| Count | Codex | Claude |
|---|---|---|
| Skills | 17 | 26 |
| Commands | 3 | 9 |
| Agent personas | 0 | 3 |
| Hooks | 0 | 1 |

## Things Codex does that Claude does not

1. **Codex Run-button bootstrap script** - generates a persistent
   `./script/build_and_run.sh` wired to Codex's Run button. Not applicable
   to Claude Code, which has no equivalent Run button. Claude's post-build
   log capture hook is the functional equivalent for evidence feedback.
2. **Plugin icon asset** - Codex ships `assets/icon.png`. Claude has no
   icon. Trivial gap.

Nothing else in Codex is missing from Claude.

## Things Claude does that Codex does not

- 10 engineering workflow lens skills (idea-refine, spec-driven-spatial, incremental-build, tdd-visionos, debugging-triage, perf-90hz, security-visionos, deprecation-visionos, ci-visionos, plus test-triage pairing with tdd-visionos)
- 2 reference docs under existing skills for commit conventions and ADR triggers
- 3 agent personas with structured protocols
- 6 additional slash commands (/build, /spec, /plan, /review, /ship, /code-simplify)
- Post-build log capture hook with configurable filter modes
- Root SKILL.md with 3-section skill map and Addy lineage attribution
- CLAUDE.md with explicit skill routing guidance
- Companion plugin recommendation for swift-lsp

## Divergence policy

Platform skill content (the 13 shared skills) should stay functionally
equivalent between the two plugins. If one gains visionOS knowledge, the
other should pull it in.

The engineering layer (workflow lenses, agent personas, commands beyond
the original 3) is Claude-specific and will not be mirrored back to Codex
unless the upstream maintainer requests it.
