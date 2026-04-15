# /code-simplify

Simplify visionOS code for clarity and maintainability without changing behaviour.

## Arguments

$ARGUMENTS - Optional: file paths, component names, or area to simplify (e.g., "RealityKit systems", "scene lifecycle")

## Workflow

Review the specified code (or recently changed files) and simplify across these axes:

1. **RealityKit simplification**
   - Merge redundant components on the same entity
   - Flatten unnecessarily deep entity hierarchies
   - Consolidate systems that could be one
   - Remove unused component registrations

2. **Scene model cleanup**
   - Flag unnecessary surface transitions (window -> volume -> immersive when fewer steps suffice)
   - Identify over-scoped immersive spaces that should be volumes or windows
   - Simplify scene ownership boundaries

3. **SwiftUI spatial views**
   - Remove redundant spatial modifiers
   - Flatten over-nested RealityView make/update closures
   - Replace verbose Model3D + RealityView patterns with the simpler option
   - Consolidate duplicated attachment views

4. **Entity lifecycle cleanup**
   - Find leaked subscriptions and event handlers
   - Identify orphaned anchors and untracked entities
   - Simplify async entity loading chains
   - Remove redundant retain cycles in closure captures

5. **Swift quality**
   - Replace manual observation with @Observable where appropriate
   - Simplify concurrency patterns (unnecessary actors, over-isolated state)
   - Remove dead code paths and unused imports

## Rules

- Never change behaviour - only clarity and structure
- Prefer fewer abstractions over premature generalisation
- Three similar lines are better than a helper nobody will reuse
- If a simplification is risky, flag it as a suggestion rather than applying it
- Verify the build still succeeds after changes

Invoke the spatial-architect agent if simplification reveals a scene model problem.
Refer to skills/coding-standards for Swift style guidance.
