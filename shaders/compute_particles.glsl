#[compute]
#version 450

layout(set = 0, binding = 0, rgba8) readonly uniform image2D input_texture;
layout(set = 0, binding = 1, rgba8) writeonly restrict uniform image2D output_texture;
layout(set = 0, binding = 2) buffer ParticleBuffer {
    vec4 particles[];
};

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 frag = vec2(uv);
    vec4 source_color = imageLoad(input_texture, uv);
    vec3 color = vec3(0.03, 0.04, 0.08);

    for (int i = 0; i < 8; i++) {
        vec4 particle = particles[i];
        vec2 position = particle.xy;
        vec2 velocity = particle.zw;

        vec2 delta = frag - position;
        float distance_sq = dot(delta, delta);
        float point = 1.0 - step(0.7, distance_sq);

        color += vec3(1.0) * point;
    }

    color = max(color, source_color.rgb * 0.45);
    color = clamp(color, vec3(0.0), vec3(1.0));
    imageStore(output_texture, uv, vec4(color, 1.0));
}
