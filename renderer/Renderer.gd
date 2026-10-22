extends Node2D

# Real proof-of-concept: a compute shader performs a true atomicAdd at the
# center cell of the counter buffer, then writes the resulting trail pixel. The
# visual is intentionally minimal so the output is just a bright central pixel.

const SCALE: float = 1024.0
const GRID_SIZE: int = 1024
const CENTER_SHADER_PATH: String = "res://renderer/shaders/center_atomic.glsl"

@export var particle_count: int = 1
@export var display_mode: int = 1
@export var trail_map_scale: float = 1.0

var trail: Image
var trail_texture: ImageTexture
var compute_shader: ComputeHelper
var counter_uniform: StorageBufferUniform
var trail_uniform: ImageUniform


func _ready() -> void:
	_build_atomic_poc()
	queue_redraw()


func _build_atomic_poc() -> void:
	var counter_data := PackedInt32Array()
	counter_data.resize(GRID_SIZE * GRID_SIZE * 2)
	counter_data.fill(0)
	counter_uniform = StorageBufferUniform.create(counter_data.to_byte_array())

	trail = Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBAF)
	trail.fill(Color(0.0, 0.0, 0.0, 1.0))
	trail_uniform = ImageUniform.create(trail)

	compute_shader = ComputeHelper.create(CENTER_SHADER_PATH)
	compute_shader.add_uniform_array([counter_uniform, trail_uniform])
	compute_shader.run(Vector3i(GRID_SIZE, GRID_SIZE, 1))
	ComputeHelper.sync()

	trail = trail_uniform.get_image()
	trail_texture = ImageTexture.create_from_image(trail)


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.04, 0.06, 0.10, 1.0))

	if trail_texture != null:
		var cell_size: float = min(viewport_size.x, viewport_size.y) / float(GRID_SIZE)
		var offset := (viewport_size - Vector2(GRID_SIZE, GRID_SIZE) * cell_size) * 0.5
		draw_texture_rect(trail_texture, Rect2(offset, Vector2(GRID_SIZE, GRID_SIZE) * cell_size), false)
