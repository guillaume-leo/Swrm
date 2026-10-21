extends Node2D

enum DisplayMode {
	PARTICLES,
	TRAIL_MAP,
}

const DEFAULT_PARTICLE_COUNT := 8
const DEFAULT_TRAIL_MAP_SCALE := 0.25

@export var particle_count: int = DEFAULT_PARTICLE_COUNT:
	set(value):
		var clamped_value: int = max(1, value)
		if particle_count == clamped_value:
			return
		particle_count = clamped_value
		_needs_particle_buffer_rebuild = true

@export var display_mode: DisplayMode = DisplayMode.PARTICLES
@export_range(0.05, 1.0, 0.05) var trail_map_scale: float = DEFAULT_TRAIL_MAP_SCALE:
	set(value):
		var clamped_value: float = clamp(value, 0.05, 1.0)
		if abs(trail_map_scale - clamped_value) < 0.0001:
			return
		trail_map_scale = clamped_value
		_mark_trail_map_dirty()

var _needs_trail_map_rebuild := false
var _needs_particle_buffer_rebuild := false

var texture_size := Vector2i.ZERO
var trail_map_size := Vector2i.ZERO
var sprite: Sprite2D
var image_texture: ImageTexture
var trail_map_texture: ImageTexture
var render_image: Image
var trail_map_image: Image

var input_uniform: ImageUniform
var output_uniform: SharedImageUniform
var trail_map_uniform: ImageUniform
var trail_map_output_uniform: SharedImageUniform
var trail_deposit_uniform: StorageBufferUniform
var particle_uniform: StorageBufferUniform
var compute: ComputeHelper
var update_compute: ComputeHelper

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_resize_to_viewport()
	_setup_compute()
	set_process(true)

func _on_viewport_size_changed() -> void:
	_resize_to_viewport()
	_setup_compute()

func _mark_trail_map_dirty() -> void:
	_needs_trail_map_rebuild = true

func _resize_to_viewport() -> void:
	texture_size = Vector2i(get_viewport_rect().size)
	if texture_size.x <= 0:
		texture_size.x = 1
	if texture_size.y <= 0:
		texture_size.y = 1

	trail_map_size = Vector2i(
		max(1, int(float(texture_size.x) * trail_map_scale)),
		max(1, int(float(texture_size.y) * trail_map_scale))
	)

	render_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	render_image.fill(Color(0.03, 0.04, 0.08, 1.0))
	image_texture = ImageTexture.create_from_image(render_image)

	trail_map_image = Image.create(trail_map_size.x, trail_map_size.y, false, Image.FORMAT_RGBA8)
	trail_map_image.fill(Color(0.03, 0.04, 0.08, 1.0))
	trail_map_texture = ImageTexture.create_from_image(trail_map_image)

	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		add_child(sprite)

	_apply_display_texture()
	sprite.position = Vector2.ZERO
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE

func _setup_compute() -> void:
	var initial_image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	initial_image.fill(Color(0.03, 0.04, 0.08, 1.0))

	var trail_initial_image := Image.create(trail_map_size.x, trail_map_size.y, false, Image.FORMAT_RGBA8)
	trail_initial_image.fill(Color(0.03, 0.04, 0.08, 1.0))

	input_uniform = ImageUniform.create(initial_image)
	output_uniform = SharedImageUniform.create(input_uniform)
	trail_map_uniform = ImageUniform.create(trail_initial_image)
	trail_map_output_uniform = SharedImageUniform.create(trail_map_uniform)
	trail_deposit_uniform = StorageBufferUniform.create(_build_trail_deposit_bytes())

	particle_uniform = StorageBufferUniform.create(_build_particle_bytes(0.0))
	compute = ComputeHelper.create("res://shaders/compute_particles.glsl")
	update_compute = ComputeHelper.create("res://shaders/update_particles.glsl")
	compute.add_uniform_array([input_uniform, output_uniform, particle_uniform, trail_map_output_uniform, trail_deposit_uniform])
	update_compute.add_uniform(particle_uniform)

	_run_frame()

func _apply_display_texture() -> void:
	if sprite == null:
		return

	# The trail map keeps updating in the background even when we are looking at the
	# direct particle render. The visible mode only chooses what we display.
	if display_mode == DisplayMode.TRAIL_MAP:
		sprite.texture = trail_map_texture
	else:
		sprite.texture = image_texture

func _build_particle_bytes(_time_offset: float) -> PackedByteArray:
	var data := PackedFloat32Array()
	for i in range(particle_count):
		var particle_position := Vector2(
			randi_range(0, texture_size.x - 1),
			randi_range(0, texture_size.y - 1)
		)
		var velocity := Vector2(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)
		data.append_array([particle_position.x, particle_position.y, velocity.x, velocity.y])
	return data.to_byte_array()

func _rebuild_particle_buffer() -> void:
	if particle_uniform == null:
		particle_uniform = StorageBufferUniform.create(_build_particle_bytes(0.0))
		return
	particle_uniform.update_data(_build_particle_bytes(0.0))

func _build_trail_deposit_bytes() -> PackedByteArray:
	var deposit_count := trail_map_size.x * trail_map_size.y
	var data := PackedByteArray()
	data.resize(deposit_count * 4)
	return data

func _run_frame() -> void:
	if particle_uniform == null or compute == null or update_compute == null or output_uniform == null:
		return

	var params := PackedFloat32Array([
		float(texture_size.x),
		float(texture_size.y),
		float(particle_count),
		0.0,
	])
	update_compute.run(Vector3i(particle_count, 1, 1), params.to_byte_array())
	ComputeHelper.sync()

	compute.run(Vector3i(max(1, particle_count), 1, 1), params.to_byte_array())
	ComputeHelper.sync()

	_apply_display_texture()

func _process(_delta: float) -> void:
	if _needs_trail_map_rebuild:
		_resize_to_viewport()
		_setup_compute()
		_needs_trail_map_rebuild = false
	if _needs_particle_buffer_rebuild:
		_rebuild_particle_buffer()
		_needs_particle_buffer_rebuild = false
	_run_frame()
