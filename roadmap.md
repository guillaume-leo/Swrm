# Swrm development roadmap

## Goal

Build the project incrementally, with each step testable and validated before moving to the next one.

## Core rule

Each step must answer three questions:

1. What do I want to prove?
2. How do I validate it?
3. What is the condition to move to the next step?

## Project rules

- Write in English only.
- Follow the user request exactly.
- Keep explanations short and practical.
- Do not modify files inside [compute_shader_plus](compute_shader_plus).
- Prefer minimal edits.
- For particle rendering, use GPU-parallel algorithms only.

## Planned steps

### 1. Scene bootstrap

Goal: launch the project without errors.

Create:
- a root scene
- a minimal script
- a startup entry point

Validation:
- project opens without crash
- script runs
- log prints: boot ok

### 2. Simulation parameters

Goal: define the basic configuration values.

Create:
- particle count
- field resolution
- simulation size

Validation:
- parameters are readable and coherent
- no invalid values
- default config is stable

### 3. Initial particle state

Goal: generate a valid starting state.

Create:
- initial positions
- random heading or velocity
- bounded placement inside the simulation area

Validation:
- positions remain within limits
- no NaN values
- no complete overlap or degenerate initialization

### 4. Minimal compute pipeline

Goal: confirm GPU compute works.

Create:
- RenderingDevice usage
- one small SSBO or buffer
- one simple shader that writes data

Validation:
- shader executes successfully
- data is written and read back correctly
- no rendering/device crash

### 5. Minimal trail field

Goal: validate deposit and diffusion behavior.

Create:
- a small 2D field
- a simple deposit region
- a minimal diffusion pass

Validation:
- the field changes visibly
- the effect spreads in a controlled way
- behavior is observable in debug view

### 6. Particle motion

Goal: make particles move according to the field.

Create:
- update positions
- clamp movement to bounds

Validation:
- particles move over time
- no particles freeze or disappear

### 7. Render layer

Goal: display the simulation without CPU-heavy loops.

Create:
- a GPU render path
- lightweight visual output
- display of particles or trail field

Validation:
- visible feedback in the viewport
- no performance blow-up in a small test
- rendering remains stable

Never start the next step before the current one is validated.

Each step should be small, observable, and independent enough to debug quickly.
