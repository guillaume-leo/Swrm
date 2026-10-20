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

layout(r32ui, set = 0, binding = 1) uniform uimage2D render_image;

layout(set = 0, binding = 2, std430) restrict buffer RenderParams {
    ivec2 render_size;
    uint particle_count;
} render_params;

void main() {
    uint index = gl_GlobalInvocationID.x;
    if (index >= render_params.particle_count) {
        return;
    }

    vec2 pos = particle_data.particles[index].pos;
    ivec2 pixel = ivec2(floor(pos * vec2(render_params.render_size)));

    if (pixel.x >= 0 && pixel.x < render_params.render_size.x &&
        pixel.y >= 0 && pixel.y < render_params.render_size.y) {
        imageAtomicAdd(render_image, pixel, 1u);
    }
}
