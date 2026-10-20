#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

struct Particle {
    vec2 pos;
    vec2 vel;
};

layout(set = 0, binding = 0, std430) restrict buffer ParticleData {
    Particle particles[];
} particle_data;

layout(set = 0, binding = 1, std430) restrict buffer ParticleParams {
    uint particle_count;
    uint seed;
    vec2 bounds_min;
    vec2 bounds_size;
} particle_params;

void main() {
    uint index = gl_GlobalInvocationID.x;
    if (index >= particle_params.particle_count) {
        return;
    }

    float random_x = fract(sin(float(index + particle_params.seed + 1u) * 12.9898) * 43758.5453);
    float random_y = fract(sin(float(index + particle_params.seed + 2u) * 78.233) * 43758.5453);

    particle_data.particles[index].pos = particle_params.bounds_min + vec2(
        random_x * particle_params.bounds_size.x,
        random_y * particle_params.bounds_size.y
    );
    particle_data.particles[index].vel = vec2(0.0, 0.0);
}
