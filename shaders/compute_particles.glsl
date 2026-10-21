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
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 frag = vec2(uv);
    vec4 source_color = imageLoad(input_texture, uv);
    vec3 color = vec3(0.03, 0.04, 0.08);
    int max_particles = int(resolution_count.z);

    for (int i = 0; i < max_particles; i++) {
        vec4 particle = particles[i];
        vec2 position = particle.xy;
        vec2 velocity = particle.zw;

        vec2 delta = frag - position;
        float distance_sq = dot(delta, delta);
        float point = 1.0 - step(0.7, distance_sq);
        color += vec3(1.0) * point;

        ivec2 trail_size = imageSize(trail_map);
        ivec2 deposit_uv = ivec2(floor(position * (vec2(trail_size) / vec2(imageSize(input_texture)))));
        deposit_uv = clamp(deposit_uv, ivec2(0), trail_size - 1);
        int deposit_index = deposit_uv.y * trail_size.x + deposit_uv.x;
        atomicAdd(trail_deposit[deposit_index], 1u);
    }

    color = max(color, source_color.rgb * 0.45);
    color = clamp(color, vec3(0.0), vec3(1.0));
    imageStore(output_texture, uv, vec4(color, 1.0));

    ivec2 trail_size = imageSize(trail_map);
    ivec2 trail_uv = ivec2(floor(vec2(uv) * (vec2(trail_size) / vec2(imageSize(input_texture)))));
    trail_uv = clamp(trail_uv, ivec2(0), trail_size - 1);

    int deposit_index = trail_uv.y * trail_size.x + trail_uv.x;
    float deposit_value = float(trail_deposit[deposit_index]);
    vec3 trail_value = imageLoad(trail_map, trail_uv).rgb;
    vec3 next_trail = clamp(trail_value + vec3(deposit_value * 0.05), vec3(0.0), vec3(1.0));
    imageStore(trail_map, trail_uv, vec4(next_trail, 1.0));
}
