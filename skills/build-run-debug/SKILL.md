---
name: build-run-debug
description: Build, run, and debug visionOS 26 apps with XcodeBuildMCP-backed Apple Vision Pro simulator workflows. Use when asked to build a visionOS app, launch it in Simulator, diagnose compiler or linker failures, inspect simulator launch problems, or debug runtime issues in a spatial app.
---

# Build / Run / Debug

## Quick Start

This skill supports two execution paths: XcodeBuildMCP (preferred) and direct
shell tools. Detect the available path first and keep the rest of the workflow
aligned to that choice.

## Load References When

| Reference | When to Use |
|-----------|-------------|
| [`references/mcp-workflow.md`](references/mcp-workflow.md) | When XcodeBuildMCP is available and you need the session, simulator, build, launch, log, or LLDB workflow. |
| [`references/shell-fallback.md`](references/shell-fallback.md) | When XcodeBuildMCP is unavailable, or when you want direct xcodebuild, simctl, log stream, and LLDB commands. |
| [`references/launch-caveats.md`](references/launch-caveats.md) | When a slow simulator boot, immersive-space expectation, or launch symptom may be misclassified as a build failure. |

## Workflow

1. Detect whether XcodeBuildMCP is callable.
   - Try `mcp__XcodeBuildMCP__session-show-defaults`. If it succeeds, use the
     MCP path.
   - If it fails, fall back to shell tools without apology.

2. Confirm the project shape and the runnable target.
   - Discover projects, list schemes, identify the app-producing target.
   - If ambiguous, explain the choice before building.

3. Choose the Apple Vision Pro simulator deliberately.
   - Prefer a booted simulator. Otherwise pick the latest available runtime.
   - Distinguish simulator from device builds.

4. Build with the narrowest command.
   - Build-only for compile checks.
   - Build-and-run for full launch verification.
   - Log capture or LLDB attach when runtime diagnosis is needed.

5. Capture and feed back build logs.
   - Always read build output before suggesting fixes.
   - The post-build-log-capture hook injects logs automatically when available.
   - Never guess at errors - read the actual output.

6. Classify failures precisely.
   - Compiler error (type errors, missing imports)
   - Linker error (missing symbols, framework issues)
   - Signing error (identity, profile, entitlement mismatch)
   - Capability error (missing entitlement, privacy key)
   - Resource error (missing asset, bundle issue)
   - Launch error (simulator boot, scene lifecycle, immersive space)

7. Apply the minimal fix and rebuild to verify.

## When To Switch Skills

- Switch to `test-triage` when the task becomes failing tests or
  flaky test behaviour.
- Switch to `signing-entitlements` when the blocker is code signing,
  provisioning, capabilities, or privacy keys.
- Switch to `debugging-triage` when the issue is runtime behaviour
  after a successful build and launch.
- Switch to `spatial-architecture` when the blocker is structural
  scene ownership rather than a build failure.
- Return here after any fix to rebuild and verify.

## Guardrails

- Prefer the narrowest command that proves or disproves the current theory.
- Detect the available build path before running any build commands.
- When XcodeBuildMCP is available, prefer it. When it is not, use shell tools.
- Do not skip deliberate simulator selection.
- Do not describe macOS desktop launch patterns as if they apply to visionOS.
- If build output is large, summarize the first real blocker and point to the
  next command that should run.
