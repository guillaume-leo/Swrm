extends Node2D

const PARTICLE_COUNT := 8

var texture_size := Vector2i.ZERO
var sprite: Sprite2D
var image_texture: ImageTexture
var render_image: Image

var input_uniform: ImageUniform
var output_uniform: SharedImageUniform
var particle_uniform: StorageBufferUniform
var compute: ComputeHelper

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_resize_to_viewport()
	_setup_compute()
	set_process(true)

func _on_viewport_size_changed() -> void:
	_resize_to_viewport()
	_setup_compute()

func _resize_to_viewport() -> void:
	texture_size = Vector2i(get_viewport_rect().size)
	if texture_size.x <= 0:
		texture_size.x = 1
	if texture_size.y <= 0:
		texture_size.y = 1

	render_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	render_image.fill(Color(0.03, 0.04, 0.08, 1.0))
	image_texture = ImageTexture.create_from_image(render_image)

	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		add_child(sprite)

	sprite.texture = image_texture
	sprite.position = Vector2.ZERO
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE

func _setup_compute() -> void:
	var initial_image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
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
		var x = float(texture_size.x) * 0.5 + cos(angle) * orbit
		var y = float(texture_size.y) * 0.5 + sin(angle) * orbit
		var radius = 6.0 + (sin(time_offset * 2.0 + float(i)) + 1.0) * 3.0
		var color_tint = 0.25 + float(i) / float(PARTICLE_COUNT) * 0.75
		data.append_array([x, y, radius, color_tint])
	return data.to_byte_array()

func _run_frame() -> void:
	if particle_uniform == null or compute == null or output_uniform == null:
		return

	var time_value = Time.get_ticks_msec() * 0.001
	particle_uniform.update_data(_build_particle_bytes(time_value))
	compute.run(Vector3i(texture_size.x, texture_size.y, 1))
	ComputeHelper.sync()

	var updated_image := output_uniform.get_image()
	image_texture.update(updated_image)

func _process(_delta: float) -> void:
	_run_frame()
