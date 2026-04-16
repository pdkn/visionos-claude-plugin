---
name: idea-refine
description: visionOS lens on idea refinement. Divergent then convergent thinking for spatial feature ideation. Covers surface model brainstorming, user proximity assumptions, spatial metaphor generation, and constraint-driven narrowing. Fits BEFORE /spec.
---

# Idea Refinement - visionOS Lens

## Addy Parent

This skill extends `idea-refine` from agent-skills. Follow the generic "divergent exploration, convergent narrowing" discipline there. This skill adds the spatial-specific dimensions that should be explored for any visionOS feature.

## When to Use

- A vague feature request needs shape before it becomes a spec
- Multiple surface models could work and no clear winner yet
- The spatial metaphor is unclear ("what should this feature feel like?")
- Stakeholders have different mental models of what this is

## Spatial Divergent Phase

Generate broadly across these axes before narrowing:

### Surface Model Options
For each feature, brainstorm a version in each surface:
- **Window** - what if this were a flat panel the user could place anywhere?
- **Volume** - what if this were a 3D object on a table?
- **Immersive** - what if this took over the user's environment?
- **Mixed** - what if a window controlled an immersive element?

The exercise itself often reveals which surface is actually right.

### User Proximity
- Sitting or standing?
- Close-range manipulation or distant observation?
- Stationary or moving through the space?
- Alone or with others present?

### Spatial Metaphors
What real-world interaction does this mimic?
- A tool in your hand
- An object on a surface
- A room you step into
- A window you look through
- A companion that follows you

### Duration and Rhythm
- Glance (seconds)
- Task (minutes)
- Session (tens of minutes)
- Ambient presence (hours, passive)

## Spatial Convergent Phase

Narrow using these constraints:

### Platform Constraints
- Does ARKit support what the idea needs? (hand tracking, world sensing, etc.)
- Does the idea require enterprise entitlements?
- Can it run at 90Hz with the proposed visual complexity?

### User Constraints
- Does the idea require abilities not all users have? (standing, precise hand tracking)
- Is it safe for extended use? (comfort, motion, occlusion)
- Can it be entered and exited quickly?

### Product Constraints
- What is the smallest version that is still useful?
- What is the smallest version that can ship?
- What is explicitly NOT in scope?

## Output

A short artifact ready to hand to `spec-driven-spatial`:
- Feature name
- User job (one sentence)
- Chosen surface model
- Chosen spatial metaphor
- Duration/rhythm target
- Explicit non-goals

## When To Switch Skills

- `spec-driven-spatial` - after ideation, write the formal spec
- `spatial-architecture` (see `references/adr-triggers.md`) - if the surface model choice needs an ADR
- `spatial-architecture` - if the idea has architecture implications
- `idea-refine` (agent-skills) - for the generic ideation techniques

## Guardrails

- Do not skip divergent phase even when you "know" the answer - explore first
- Do not let a convergent constraint bias the divergent phase
- Do not let tool or API affordances drive the idea - user need drives first
- Do not end ideation without explicit non-goals
