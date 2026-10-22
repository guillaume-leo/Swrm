# Swrm — AI operating instructions

## Scope

This project is a Godot 4.7 particle simulation inspired by physarum-like systems and live generative visuals. It uses compute shaders, real-time UI controls, and MIDI-driven live interaction.

Reference documentation: https://docs.godotengine.org/en/4.7/classes/index.html

## AI behavior

- Write in English only.
- Follow the user request exactly.
- Suggestions are allowed only when asked for them; they must remain optional and non-intrusive.
- Keep explanations short and practical.

## Documentation style

- Document code globally, not line by line or at every function call.
- Prefer one clear header comment at the top of each file when the purpose is not obvious.
- Add comments only where the logic is genuinely complex or non-obvious.

## Working rules

- Stay within the requested task.
- Prefer minimal edits.
- For particle rendering, assume the system may scale to millions of particles. So we will never loop through all of them, (unless for initialization step), we will ONLY use GPU parrallel algorithms
- Never modify files inside [compute_shader_plus](compute_shader_plus). NEVER.

## Response style

- Answer directly.
- Keep the output SHORT and relevant.

## GPU resource and life-cycle

# Resources

Godot 4 `RenderingDevice`, grid `WIDTH × HEIGHT`.

- **`particles`**: SSBO (`float[]`), `N_PARTICLES × PARAMS_COUNT` floats. Particle state (position, heading...).
- **`counter`**: SSBO (`int[]`), `WIDTH × HEIGHT × 2` ints. Per-frame velocity accumulator (x, y), fixed-point (`SCALE = 1024`).
- **`trailRead`**: Image `R16G16_SFLOAT`, `WIDTH × HEIGHT`. Persistent vector field (R = vx, G = vy), sensed by particles.
- **`trailWrite`**: Image `R16G16_SFLOAT`, `WIDTH × HEIGHT`. Intermediate field (deposit output, diffusion input).
- **Scalar parameters**: push constants.
- **Ping-pong**: two uniform sets (A: `trailRead` readonly / `trailWrite` writeonly, B: reversed).
- **Shaders**: `move.glsl`, `deposit.glsl`, `diffusion.glsl`.

# Lifecycle (per frame)

```
clear counter
   ▼
move.glsl (1 thread / particle)
   ▼ barrier
deposit.glsl (1 thread / pixel)
   ▼ barrier
diffusion.glsl (1 thread / pixel)
   ▼
next frame
```

1. **Clear**: `rd.buffer_clear(counter, 0)`.
2. **Move**: each particle samples `trailRead`, steers (aligns with local flow), moves, then `atomicAdd` its velocity `(vx, vy)` × `SCALE` into `counter` at its pixel.
3. **Deposit**: each pixel reads `counter`, divides by `SCALE`, writes the vector (× `DEPOSIT_FACTOR`) into `trailWrite`.
4. **Diffuse + decay**: read `trailWrite`, blur, × `DECAY_FACTOR`, write into `trailRead`.