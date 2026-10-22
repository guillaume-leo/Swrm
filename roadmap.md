# Swrm development roadmap

## Goal

Build the project in the exact order of the GPU simulation pipeline defined in the project instructions:

clear -> move -> deposit -> diffusion

Each step must be testable and verified before moving to the next one.

## Project rules

- Write in English only.
- Stay within the requested task.
- Prefer minimal edits.
- Never modify files inside [compute_shader_plus](compute_shader_plus).
- Use GPU-parallel algorithms only for particle movement and rendering.
- Respect the lifecycle and resource names from the project instructions.

## Required GPU resources

- particles: SSBO, N_PARTICLES × PARAMS_COUNT floats
- counter: SSBO, WIDTH × HEIGHT × 2 ints, with SCALE = 1024
- trailRead: Image R16G16_SFLOAT, WIDTH × HEIGHT
- trailWrite: Image R16G16_SFLOAT, WIDTH × HEIGHT
- scalar parameters: push constants
- ping-pong: two uniform sets, A and B
- shaders: move.glsl, deposit.glsl, diffusion.glsl

## Pipeline order

1. Clear counter
2. Move particles
3. Deposit into trailWrite
4. Diffuse and decay into trailRead
5. Repeat next frame

## Step-by-step plan

### 1. Bootstrap the scene and runtime

Goal: make the project load cleanly and expose a basic render surface.

Create:
- root scene
- script entry point
- basic viewport render setup

Validation:
- project opens without error
- script executes
- frame renders without crash

### 2. Define the simulation configuration

Goal: define the exact simulation parameters used by the pipeline.

Create:
- WIDTH and HEIGHT
- particle count
- deposit factor
- decay factor
- scale value and push-constant-style config

Validation:
- values are valid and typed correctly
- config matches the GPU pipeline expectations
- no invalid state on startup

### 3. Define particle state data

Goal: create the particle SSBO layout and data model.

Create:
- particle state structure
- position and heading fields
- any required per-particle parameters

Validation:
- data layout is coherent with the shader contract
- there are no invalid or undefined values
- buffer structure matches the intended CPU/GPU flow

### 4. Create the clear step

Goal: validate that the counter buffer is reset every frame.

Create:
- counter SSBO
- frame clear operation
- buffer_clear call before movement

Validation:
- counter resets to zero before move stage
- no stale velocity remains between frames
- this is the first valid stage of the pipeline

### 5. Implement the move pass

Goal: verify particles read the trail, steer, then write velocity into the counter.

Create:
- move.glsl
- particle iteration in compute dispatch
- atomicAdd into counter at each particle pixel

Validation:
- each particle is processed once in its dispatch pass
- velocity contributions accumulate correctly per pixel
- no CPU fallback is used

### 6. Implement the deposit pass

Goal: convert accumulated counter values into a stable trail field.

Create:
- deposit.glsl
- read the counter buffer
- divide by SCALE
- write to trailWrite with deposit factor

Validation:
- counter values convert correctly to directional vector flow
- trailWrite receives the deposit result
- the output is ready for diffusion

### 7. Implement the diffusion pass

Goal: blur and decay the trail field before the next frame.

Create:
- diffusion.glsl
- read trailWrite
- apply blur and decay
- write into trailRead

Validation:
- flow field remains stable over time
- decay prevents runaway accumulation
- ping-pong swap is correct between A and B

## Required validation after each step

Each step must prove the exact target behavior before moving on:

- is the resource created?
- is the stage producing the expected output?
- does the next stage receive valid input?
- is the pipeline still consistent with the instructions?

## Critical constraint

The project must be built in this order:

clear -> move -> deposit -> diffusion

Not as a generic simulation, but as the exact GPU lifecycle described in the instructions document.
