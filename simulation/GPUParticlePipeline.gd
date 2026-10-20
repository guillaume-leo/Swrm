# GPUParticlePipeline
# Minimal GPU path: one particle buffer and one atomic-add render pass.
extends RefCounted
class_name GPUParticlePipeline

const RENDER_SHADER_PATH := "res://simulation/shaders/render_particles.glsl"

var rd: RenderingDevice
var particle_count: int = 256
var render_size: Vector2i = Vector2i(512, 512)

var particle_buffer_rid: RID
var render_params_rid: RID
var render_image_rid: RID
var render_shader_rid: RID
var render_pipeline_rid: RID
var render_set: RID
var has_submitted: bool = false
var visible_texture: ImageTexture


func _init(count: int = 256, size: Vector2i = Vector2i(512, 512)) -> void:
	particle_count = max(count, 1)
	render_size = size
	_build_device()
	_build_particle_buffer()
	_build_render_target()
	_build_render_pipeline()
	_build_render_uniform_set()


func _build_device() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_warning("GPU pipeline requires a local RenderingDevice.")


func _build_particle_buffer() -> void:
	if rd == null:
		return

	var particle_bytes := PackedByteArray()
	particle_bytes.resize(particle_count * 16)
	for i in range(particle_count):
		var f := float(i)
		var x := (f / float(max(particle_count, 1))) * 2.0 - 1.0
		var y := 0.0
		var pos_x := x
		var pos_y := y
		var offset := i * 16
		particle_bytes.encode_float(offset + 0, pos_x)
		particle_bytes.encode_float(offset + 4, pos_y)
		particle_bytes.encode_float(offset + 8, 0.0)
		particle_bytes.encode_float(offset + 12, 0.0)
	particle_buffer_rid = rd.storage_buffer_create(particle_bytes.size(), particle_bytes)

	var render_params_bytes := PackedByteArray()
	render_params_bytes.resize(16)
	render_params_rid = rd.storage_buffer_create(render_params_bytes.size(), render_params_bytes)
	_update_render_params_buffer()


func _build_render_target() -> void:
	if rd == null:
		return

	var format := RDTextureFormat.new()
	format.width = max(render_size.x, 1)
	format.height = max(render_size.y, 1)
	format.depth = 1
	format.mipmaps = 1
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	render_image_rid = rd.texture_create(format, RDTextureView.new(), [])
	visible_texture = null


func _build_render_pipeline() -> void:
	if rd == null:
		return
	var shader_file := load(RENDER_SHADER_PATH)
	if shader_file == null:
		return
	var spirv: RDShaderSPIRV = shader_file.get_spirv()
	render_shader_rid = rd.shader_create_from_spirv(spirv)
	render_pipeline_rid = rd.compute_pipeline_create(render_shader_rid)


func _build_render_uniform_set() -> void:
	if rd == null:
		return
	if render_shader_rid.is_valid() == false:
		return
	if render_image_rid.is_valid() == false:
		return
	if render_params_rid.is_valid() == false:
		return
	if particle_buffer_rid.is_valid() == false:
		return

	var particle_uniform := RDUniform.new()
	particle_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	particle_uniform.binding = 0
	particle_uniform.add_id(particle_buffer_rid)

	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 1
	image_uniform.add_id(render_image_rid)

	var render_params_uniform := RDUniform.new()
	render_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	render_params_uniform.binding = 2
	render_params_uniform.add_id(render_params_rid)

	render_set = rd.uniform_set_create([particle_uniform, image_uniform, render_params_uniform], render_shader_rid, 0)


func _update_render_params_buffer() -> void:
	if rd == null or render_params_rid.is_valid() == false:
		return
	var bytes := PackedByteArray()
	bytes.resize(16)
	bytes.encode_s32(0, render_size.x)
	bytes.encode_s32(4, render_size.y)
	bytes.encode_u32(8, particle_count)
	rd.buffer_update(render_params_rid, 0, bytes.size(), bytes)


func bind_render_target(target: Variant) -> void:
	if target is SubViewport:
		render_size = target.size
		_build_render_target()
		_build_render_uniform_set()
		_update_render_params_buffer()
		return


func dispatch_render() -> void:
	if rd == null or render_pipeline_rid.is_valid() == false:
		return
	if render_set.is_valid() == false:
		return

	# Clear the output image to black before drawing the particles.
	var clear_bytes := PackedByteArray()
	clear_bytes.resize(max(render_size.x * render_size.y * 4, 1))
	clear_bytes.fill(0)
	rd.texture_update(render_image_rid, 0, 0, 0, 0, 0, render_size.x, render_size.y, 1, clear_bytes)

	# The device can only be synced after the first submit.
	if has_submitted:
		rd.sync()
	_update_render_params_buffer()

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, render_pipeline_rid)
	rd.compute_list_bind_uniform_set(list, render_set, 0)
	rd.compute_list_dispatch(list, int(ceil(float(particle_count) / 64.0)), 1, 1)
	rd.compute_list_end()
	rd.submit()
	has_submitted = true
	read_back_texture()


func read_back_texture() -> void:
	if rd == null or render_image_rid.is_valid() == false:
		return
	var bytes := rd.texture_get_data(render_image_rid, 0)
	if bytes.is_empty():
		return
	var image := Image.create_from_data(render_size.x, render_size.y, false, Image.FORMAT_RGBA8, bytes)
	if image == null:
		return
	visible_texture = ImageTexture.create_from_image(image)


func get_output_texture() -> Texture2D:
	return visible_texture


func dispose() -> void:
	has_submitted = false
	if rd == null:
		return
	if particle_buffer_rid.is_valid():
		rd.free_rid(particle_buffer_rid)
	if render_params_rid.is_valid():
		rd.free_rid(render_params_rid)
	if render_image_rid.is_valid():
		rd.free_rid(render_image_rid)
	if render_shader_rid.is_valid():
		rd.free_rid(render_shader_rid)
	if render_pipeline_rid.is_valid():
		rd.free_rid(render_pipeline_rid)
	if render_set.is_valid():
		rd.free_rid(render_set)
