---
name: adr-spatial
description: visionOS lens on architecture decision records. Records the scene model, RealityKit architecture, and ARKit session strategy decisions that shape a spatial app. Adds the visionOS-specific context fields a generic ADR template misses.
---

# ADRs for Spatial Architecture - visionOS Lens

## Addy Parent

This skill extends `documentation-and-adrs` from agent-skills. Follow the generic "Context / Decision / Consequences / Alternatives" ADR template there. This skill adds the visionOS decision triggers and required context fields.

## Decisions That Need an ADR

File an ADR when any of these are decided:

- **Scene model** - why window vs volume vs immersive space for this feature or app area
- **Entity architecture** - how entity hierarchies are organized (deep vs flat, component boundaries)
- **System design** - which RealityKit systems exist, their update order, their dependencies
- **ARKit strategy** - which providers, when they start and stop, how authorization is handled
- **SharePlay design** - what state is shared, what is private, conflict resolution
- **Persistence boundary** - what survives app restart, what is scene-scoped, what is transient
- **State ownership topology** - where app / scene / immersive state lives
- **Entitlement set** - which capabilities the app requests and why

Do NOT file ADRs for trivial choices (file naming, which stdlib collection to use, etc).

## visionOS-Specific Context Fields

Beyond the generic ADR template, a spatial ADR should capture:

### User Spatial Intent
What is the user doing, spatially? (sitting and reading, standing and manipulating, fully immersed, sharing a room)

### Surface Implications
Which scene types are in play? What are the transition paths between them?

### ARKit Dependencies
Which providers does this decision require? What happens if one is unavailable?

### Privacy Posture
Which entitlements does this imply? What is the minimal set?

### Performance Budget
Does this decision have implications for the 90Hz render budget?

## Template Extensions

Use the generic ADR template, then add these sections:

```markdown
## Spatial Context
- User intent:
- Surface model:
- ARKit dependencies:

## visionOS Consequences
- Privacy implications:
- Performance implications:
- Simulator vs device behaviour:
```

## Superseding ADRs

Never edit a filed ADR. When a decision is revisited:
1. Write a new ADR that explains what changed and why
2. Mark the old ADR "Superseded by ADR-NNN"
3. Link both directions

## When To Switch Skills

- `spec-driven-spatial` - the ADR may be an output of spec work
- `spatial-architecture` - to validate the decision against app topology
- `spatial-architecture` - when the ADR touches state ownership or scene topology
- `documentation-and-adrs` (agent-skills) - for the generic ADR template

## Guardrails

- Never skip the Alternatives section - list what was rejected and why
- Never file ADRs for trivial choices
- Never edit a filed ADR - supersede it instead
- Keep ADRs concise - context, decision, consequences, alternatives, no code
