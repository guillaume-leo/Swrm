#[compute]
#version 450

layout(set = 0, binding = 0) buffer ParticleBuffer {
    vec4 particles[];
};

layout(push_constant) uniform Params {
    vec4 resolution;
};

layout(local_size_x = 8, local_size_y = 1, local_size_z = 1) in;

void main() {
    uint index = gl_GlobalInvocationID.x;
    if (index >= 8u) {
        return;
    }

    vec4 particle = particles[index];
    vec2 position = particle.xy;
    vec2 velocity = particle.zw;
    vec2 size = resolution.xy;

    position += velocity;

    if (position.x < 0.0 || position.x > size.x) {
        velocity.x *= -1.0;
        position.x = clamp(position.x, 0.0, size.x);
    }

    if (position.y < 0.0 || position.y > size.y) {
        velocity.y *= -1.0;
        position.y = clamp(position.y, 0.0, size.y);
    }

    particles[index] = vec4(position, velocity);
}
