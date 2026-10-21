#[compute]
#version 450

layout(set = 0, binding = 0, rgba8) readonly uniform image2D input_texture;
layout(set = 0, binding = 1, rgba8) writeonly restrict uniform image2D output_texture;
layout(set = 0, binding = 2) buffer ParticleBuffer {
    vec4 particles[];
};
layout(set = 0, binding = 3, rgba8) uniform image2D trail_map;
layout(std430, set = 0, binding = 4) buffer DepositBuffer {
    uint trail_deposit[];
};

layout(push_constant) uniform Params {
    vec4 resolution_count;
};

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

void main() {
    uint index = gl_GlobalInvocationID.x;
    uint max_particles = uint(resolution_count.z);
    if (index >= max_particles) {
        return;
    }

    vec4 particle = particles[index];
    vec2 position = particle.xy;

    ivec2 trail_size = imageSize(trail_map);
    ivec2 deposit_uv = ivec2(floor(position * (vec2(trail_size) / vec2(imageSize(input_texture)))));
    deposit_uv = clamp(deposit_uv, ivec2(0), trail_size - 1);

    uint deposit_index = uint(deposit_uv.y * trail_size.x + deposit_uv.x);
    atomicAdd(trail_deposit[deposit_index], 1u);
}
