# Simulation — AI operating instructions

## Scope

This folder contains the particle simulation logic. The simulation is GPU-driven and must not perform CPU readback from GPU buffers.

The simulation is responsible for storing particle state and preparing the GPU pipeline for updates and output rendering.

## Strict rules

- Do not add CPU-side readback from GPU resources.
- Do not read back textures, buffers, or compute results to the CPU during simulation.
- Keep all simulation state in GPU-friendly structures.

## Particle model

Each particle must be represented with the minimum state required by the simulation:

- position: vec2
- velocity: vec2

This is the base representation for the simulation buffers.

## Data flow

- Initialize particles in a deterministic, minimal setup.
- Update the simulation through GPU compute passes.
- Write simulation output into the renderer target without CPU readback.
- Keep the CPU layer limited to setup and orchestration.
