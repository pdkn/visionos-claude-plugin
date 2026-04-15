# /build

Build, run, and debug a visionOS app on Apple Vision Pro simulator.

## Arguments

$ARGUMENTS - Optional: scheme name, mode (build/run/debug/logs), or specific build issue to investigate

## Workflow

Load and follow the build-run-debug skill at skills/build-run-debug/SKILL.md.

1. Detect whether XcodeBuildMCP is available
   - Try session-show-defaults. Use MCP path if it works, shell fallback if not.

2. Discover the project and choose the right target
   - Find .xcodeproj, .xcworkspace, or Package.swift
   - Pick the app-producing scheme for visionOS

3. Select the Apple Vision Pro simulator
   - Prefer a booted simulator
   - Otherwise pick the latest available runtime

4. Execute the requested mode:
   - **build** - compile only, report errors
   - **run** - build, install, and launch on simulator
   - **debug** - build, launch, and attach LLDB
   - **logs** - build, launch, and capture structured logs

5. On failure, classify and route:
   - Compiler/linker errors - fix and rebuild
   - Signing/entitlement errors - invoke xcode-build-agent or /fix-visionos-capability-error
   - Runtime issues after successful launch - invoke realitykit-debugger or /debugging-triage
   - Test failures - use /test-visionos-app

6. On success, report the build result and simulator state

## Guardrails

- Always read build logs before suggesting fixes
- Prefer the narrowest build command for the task
- Do not assume a simulator failure is a signing issue
- Do not describe macOS patterns as valid for visionOS
