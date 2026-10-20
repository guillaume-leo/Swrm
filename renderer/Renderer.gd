extends Node2D

const TEXTURE_SIZE := Vector2i(256, 256)
const PARTICLE_COUNT := 8

var sprite: Sprite2D
var image_texture: ImageTexture
var render_image: Image

var input_uniform: ImageUniform
var output_uniform: SharedImageUniform
var particle_uniform: StorageBufferUniform
var compute: ComputeHelper

func _ready() -> void:
	render_image = Image.create(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	render_image.fill(Color(0.03, 0.04, 0.08, 1.0))
	image_texture = ImageTexture.create_from_image(render_image)

	sprite = Sprite2D.new()
	sprite.texture = image_texture
	sprite.centered = false
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	_setup_compute()
	set_process(true)

func _setup_compute() -> void:
	var initial_image := Image.create(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	initial_image.fill(Color(0.03, 0.04, 0.08, 1.0))

	input_uniform = ImageUniform.create(initial_image)
	output_uniform = SharedImageUniform.create(input_uniform)

	particle_uniform = StorageBufferUniform.create(_build_particle_bytes(0.0))
	compute = ComputeHelper.create("res://shaders/compute_particles.glsl")
	compute.add_uniform_array([input_uniform, output_uniform, particle_uniform])

	_run_frame()

func _build_particle_bytes(time_offset: float) -> PackedByteArray:
	var data := PackedFloat32Array()
	for i in range(PARTICLE_COUNT):
		var angle = TAU * float(i) / PARTICLE_COUNT + time_offset
		var orbit = 38.0 + 28.0 * sin(float(i) * 1.7 + time_offset * 1.5)
		var x = float(TEXTURE_SIZE.x) * 0.5 + cos(angle) * orbit
		var y = float(TEXTURE_SIZE.y) * 0.5 + sin(angle) * orbit
		var radius = 6.0 + (sin(time_offset * 2.0 + float(i)) + 1.0) * 3.0
		var color_tint = 0.25 + float(i) / float(PARTICLE_COUNT) * 0.75
		data.append_array([x, y, radius, color_tint])
	return data.to_byte_array()

func _run_frame() -> void:
	var time_value = Time.get_ticks_msec() * 0.001
	particle_uniform.update_data(_build_particle_bytes(time_value))
	compute.run(Vector3i(TEXTURE_SIZE.x, TEXTURE_SIZE.y, 1))
	ComputeHelper.sync()

	var updated_image := output_uniform.get_image()
	image_texture.update(updated_image)

func _process(_delta: float) -> void:
	_run_frame()
