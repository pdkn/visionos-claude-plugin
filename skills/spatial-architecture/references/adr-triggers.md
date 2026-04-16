# ADR Triggers for visionOS

Use this file alongside `agent-skills:documentation-and-adrs` for the generic
ADR format. This file lists the visionOS-specific decisions that warrant an
ADR and the extra context fields a spatial ADR should capture.

## Decisions That Need an ADR

File an ADR when any of these are decided:

- **Scene model** - why window vs volume vs immersive space for this feature
  or app area
- **Entity architecture** - how entity hierarchies are organized (deep vs flat,
  component boundaries)
- **System design** - which RealityKit systems exist, their update order, their
  dependencies
- **ARKit strategy** - which providers, when they start and stop, how
  authorization is handled
- **SharePlay design** - what state is shared, what is private, conflict
  resolution
- **Persistence boundary** - what survives app restart, what is scene-scoped,
  what is transient
- **State ownership topology** - where app / scene / immersive state lives
- **Entitlement set** - which capabilities the app requests and why

Do NOT file ADRs for trivial choices (file naming, stdlib collection choice,
style preferences).

## visionOS-Specific Context Fields

The generic ADR template (Context / Decision / Consequences / Alternatives)
captures the structure. For spatial decisions, add these fields:

### User Spatial Intent

What is the user doing, spatially? Sitting and reading, standing and
manipulating, fully immersed, sharing a room with other people.

### Surface Implications

Which scene types are in play? What are the transition paths between them?

### ARKit Dependencies

Which providers does this decision require? What happens if one is
unavailable?

### Privacy Posture

Which entitlements does this imply? What is the minimal set?

### Performance Budget

Does this decision have implications for the 90Hz render budget?

## Template Extension

Use the generic ADR template, then add:

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
1. Write a new ADR explaining what changed and why
2. Mark the old ADR "Superseded by ADR-NNN"
3. Link both directions

## Guardrails

- Never skip the Alternatives section - list what was rejected and why
- Never file ADRs for trivial choices
- Never edit a filed ADR - supersede it instead
- Keep ADRs concise - context, decision, consequences, alternatives, no code
