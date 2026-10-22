#[compute]
#version 450

layout(std430, binding = 0) buffer CounterBuffer {
    int counter[];
};

layout(rgba32f, binding = 1) uniform image2D trailWrite;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const int WIDTH = 1024;
const int HEIGHT = 1024;
const int SCALE = 1024;

void main() {
    ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
    ivec2 center = ivec2(WIDTH / 2, HEIGHT / 2);

    if (gid.x >= WIDTH || gid.y >= HEIGHT) {
        return;
    }

    if (gid != center) {
        return;
    }

    int idx = (gid.y * WIDTH + gid.x) * 2;
    int vx = int(0.9 * float(SCALE));
    int vy = int(0.0 * float(SCALE));

    atomicAdd(counter[idx + 0], vx);
    atomicAdd(counter[idx + 1], vy);

    float vx_value = float(counter[idx + 0]) / float(SCALE);
    float vy_value = float(counter[idx + 1]) / float(SCALE);
    vec2 velocity = vec2(vx_value, vy_value);
    float strength = clamp(length(velocity), 0.0, 1.0);

    vec3 color = vec3(
        strength,
        0.5 + 0.5 * vx_value,
        0.5 + 0.5 * vy_value
    );

    imageStore(trailWrite, gid, vec4(color, 1.0));
}
