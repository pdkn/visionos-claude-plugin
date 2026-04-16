---
name: idea-refine
description: visionOS lens on idea refinement. Load alongside agent-skills:idea-refine for the generic divergent/convergent technique. This skill adds the visionOS-specific axes (surface model, user proximity, spatial metaphor, duration rhythm) and worked examples showing feature ideation for Apple Vision Pro.
---

# Idea Refinement - visionOS Lens

## How to Use This Skill

Load `agent-skills:idea-refine` for the generic divergent-then-convergent
discipline. Use this skill for the visionOS-specific axes to explore and for
worked examples showing the process end-to-end.

## visionOS Axes to Explore

During the **divergent phase**, brainstorm broadly across these four axes:

### Surface Model
For each candidate feature, sketch a version in each of these surfaces:
- **Window** - flat 2D content the user can place anywhere
- **Volume** - bounded 3D content on a surface
- **Immersive Space** - full spatial environment
- **Mixed** - window controlling an immersive element

The exercise reveals which surface is actually right.

### User Proximity
- Sitting or standing?
- Close-range manipulation or distant observation?
- Stationary or moving through the space?
- Alone or with others present?

### Spatial Metaphor
What real-world interaction does this mimic?
- A tool in your hand
- An object on a surface
- A room you step into
- A window you look through
- A companion that follows you

### Duration Rhythm
- Glance (seconds)
- Task (minutes)
- Session (tens of minutes)
- Ambient (hours, passive)

During the **convergent phase**, narrow using:
- **Platform constraints** - does ARKit support what you need? Enterprise entitlement required? Can it sustain 90Hz?
- **User constraints** - does it require abilities not all users have (standing, precise hand tracking, room-scale space)? Is it safe for extended use?
- **Product constraints** - smallest useful version? Smallest shippable version? Explicit non-goals?

## Worked Example 1: "An app to review wine bottles"

Starting point: vague request from a retailer who wants a visionOS shopping app.

### Divergent

| Surface | Version |
|---|---|
| Window | Product catalog with bottle photos, like iPad shopping |
| Volume | A bottle sits on your table, you can rotate it and read labels in 3D |
| Immersive | You walk through a virtual wine cellar and pick bottles off shelves |
| Mixed | Window catalog + volume preview when you tap a bottle |

**Proximity options:** sitting at a kitchen table, standing at a counter, lounging on a sofa.

**Spatial metaphors:** "bottle in my hand", "bottle on the counter", "walking through a cellar".

**Duration:** probably task-length (minutes per bottle browse), not ambient.

### Convergent

Platform: ARKit world tracking not needed; plane detection useful for the volume case; no enterprise entitlements.

User: must work while seated on a sofa - cannot assume standing or room-scale.

Product: MVP needs to show one bottle with label detail and a purchase button. Non-goals: the cellar walk-through, multi-bottle comparison, AR-in-your-kitchen placement.

### Output

- Feature: **spatial wine bottle preview**
- Surface: **volume** (bottle in the room, sized for seated viewing)
- Metaphor: bottle on a counter at reading distance
- ARKit: none for MVP (bottle floats at a fixed position relative to the user)
- SharePlay: out of scope
- Entitlements: none beyond standard
- Duration: task, 30 sec to 2 min per bottle
- Non-goals: catalog browse (use a website), cellar walkthrough (post-MVP)

Hand off to `/spec "spatial wine bottle preview"`.

## Worked Example 2: "A productivity app for visionOS"

Starting point: very vague. The word "productivity" could mean anything.

### Divergent

First split by productivity type:
- Focused writing (distraction-free environment)
- Knowledge work (research, reading, note-taking)
- Task management (todos, calendars)
- Creative work (drawing, modelling)

Pick one dimension to explore further: **focused writing**.

| Surface | Version |
|---|---|
| Window | Writing app like on a Mac, but you can place it anywhere |
| Volume | Text floating as a 3D object you can lean into |
| Immersive | You sit in a calm virtual environment (library, forest) and write |
| Mixed | Window for the text + immersive space for the environment |

**Proximity:** seated, close-range text interaction, isolated (headphones-on moment).

**Spatial metaphor:** "sitting in a cabin to write". The immersive space IS the productivity aid.

**Duration:** session (tens of minutes to an hour of focused writing).

### Convergent

Platform: the text-editing window is standard. The immersive environment is heavyweight but meaningful here.

User: must tolerate occlusion (user is fully immersed). Need a quick escape.

Product: MVP = window-based text editor with one immersive "writing space" preset (e.g. a quiet library). Non-goals: collaborative editing, markdown-to-export pipeline, multiple environments.

### Output

- Feature: **focused writing with an immersive environment**
- Surface: **mixed** - window for text, immersive space for environment
- Metaphor: "a cabin to write in"
- ARKit: none (fully virtual environment)
- SharePlay: out of scope
- Entitlements: none beyond standard
- Duration: session
- Non-goals: collaboration, export pipeline, multiple environments

Hand off to `/spec "focused writing with immersive environment"`.

## Worked Example 3: "A measuring tool"

Starting point: someone wants "an AR measuring app like iPhone has but on Vision Pro".

### Divergent

The iPhone version already exists, so the visionOS version must earn its place.

| Surface | Version |
|---|---|
| Window | Flat ruler UI - nope, pointless |
| Volume | A measuring cube you place and resize - works for small objects |
| Immersive | Room measurement mode - walls, furniture, whole spaces |
| Mixed | Window showing measurement history + volume or immersive capture |

**Proximity:** standing, moving around the measured object or room.

**Spatial metaphor:** "a tape measure in the air" vs "a laser measurer in my hand" vs "a room-scale scanner".

**Duration:** task (one measurement session).

### Convergent

Platform: requires world tracking + plane detection + scene reconstruction. All standard on Apple Vision Pro.

User: must stand and move. Not accessible for seated-only users - flag this.

Product: MVP = room-scale mode only (that's what visionOS enables that the iPhone version cannot). Non-goals: tiny object measurement (iPhone does that better), sharing measurements.

### Output

- Feature: **room-scale measurement**
- Surface: **mixed** - immersive space for measurement, window for history/export
- Metaphor: "scanning the room with my eyes"
- ARKit: world tracking, plane detection, scene reconstruction
- SharePlay: out of scope
- Entitlements: world sensing (`NSWorldSensingUsageDescription`)
- Duration: task
- Non-goals: small object measurement, measurement sharing

Hand off to `/spec "room-scale measurement"`.

## When To Switch Skills

- `spec-driven-spatial` - after ideation, write the formal spec
- `spatial-architecture` (see `references/adr-triggers.md`) - if the surface model choice needs an ADR
- `agent-skills:idea-refine` - for the generic divergent/convergent technique

## Guardrails

- Do not skip divergent phase even when you think you know the answer
- Do not let a convergent constraint bias the divergent phase
- Do not let tool or API affordances drive the idea - user need drives first
- Do not end ideation without explicit non-goals
- If the iPhone/iPad version would serve the user equally well, question whether visionOS earns its place
