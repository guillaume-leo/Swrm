# GPUParticlePipeline
# Minimal GPU pipeline for particle storage and render-target accumulation.
extends RefCounted
class_name GPUParticlePipeline

const INIT_SHADER_PATH := "res://simulation/shaders/init_particles.glsl"
const RENDER_SHADER_PATH := "res://simulation/shaders/render_particles.glsl"

var rd: RenderingDevice
var particle_count: int = 4096
var render_size: Vector2i = Vector2i(1024, 1024)

var particle_buffer_rid: RID
var particle_params_rid: RID
var particle_set: RID

var init_shader_rid: RID
var init_pipeline_rid: RID

var render_shader_rid: RID
var render_pipeline_rid: RID
var render_image_rid: RID
var render_params_rid: RID
var render_set: RID


func _init(count: int = 4096, size: Vector2i = Vector2i(1024, 1024)) -> void:
	particle_count = max(count, 1)
	render_size = size
	_build_device()
	_build_init_pipeline()
	_build_particle_buffers()
	_build_render_pipeline()


func _build_device() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		push_warning("GPU pipeline requires a local RenderingDevice.")


func _build_particle_buffers() -> void:
	if rd == null:
		return
	if init_shader_rid.is_valid() == false:
		return

	var particle_bytes := PackedByteArray()
	particle_bytes.resize(particle_count * 16)
	particle_buffer_rid = rd.storage_buffer_create(particle_bytes.size(), particle_bytes)

	var params_bytes := PackedByteArray()
	params_bytes.resize(16 + 16 + 16)
	# The payload is intentionally minimal at this stage:
	# particle_count, seed, bounds_min, bounds_size.
	# The real GPU simulation will extend this layout as needed.
	particle_params_rid = rd.storage_buffer_create(params_bytes.size(), params_bytes)

	var render_params_bytes := PackedByteArray()
	render_params_bytes.resize(16)
	render_params_rid = rd.storage_buffer_create(render_params_bytes.size(), render_params_bytes)
	_update_render_params_buffer()

	var particle_uniform_init := RDUniform.new()
	particle_uniform_init.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	particle_uniform_init.binding = 0
	particle_uniform_init.add_id(particle_buffer_rid)

	var params_uniform_init := RDUniform.new()
	params_uniform_init.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform_init.binding = 1
	params_uniform_init.add_id(particle_params_rid)

	particle_set = rd.uniform_set_create([particle_uniform_init, params_uniform_init], init_shader_rid, 0)


func _build_init_pipeline() -> void:
	if rd == null:
		return

	var shader_file := load(INIT_SHADER_PATH)
	if shader_file == null:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	init_shader_rid = rd.shader_create_from_spirv(shader_spirv)
	init_pipeline_rid = rd.compute_pipeline_create(init_shader_rid)


func _build_render_pipeline() -> void:
	if rd == null:
		return

	var shader_file := load(RENDER_SHADER_PATH)
	if shader_file == null:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	render_shader_rid = rd.shader_create_from_spirv(shader_spirv)
	render_pipeline_rid = rd.compute_pipeline_create(render_shader_rid)


func bind_render_target(target: Variant) -> void:
	if target is SubViewport:
		render_size = target.size
		if rd == null:
			return
		var format := RDTextureFormat.new()
		format.width = max(render_size.x, 1)
		format.height = max(render_size.y, 1)
		format.depth = 1
		format.mipmaps = 1
		format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
		format.format = RenderingDevice.DATA_FORMAT_R32_UINT
		format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		render_image_rid = rd.texture_create(format, RDTextureView.new(), [])
		_update_render_params_buffer()
		_build_render_uniform_set()
		return
	if target is RID:
		render_image_rid = target
		if rd == null or render_image_rid.is_valid() == false:
			return
		if render_shader_rid.is_valid() == false:
			return
		_update_render_params_buffer()
		_build_render_uniform_set()
		return

	if rd == null:
		return
	if render_shader_rid.is_valid() == false:
		return
	_update_render_params_buffer()
	_build_render_uniform_set()


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

	var particle_uniform_render := RDUniform.new()
	particle_uniform_render.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	particle_uniform_render.binding = 0
	particle_uniform_render.add_id(particle_buffer_rid)

	var render_image_uniform_target := RDUniform.new()
	render_image_uniform_target.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	render_image_uniform_target.binding = 1
	render_image_uniform_target.add_id(render_image_rid)

	var render_params_uniform := RDUniform.new()
	render_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	render_params_uniform.binding = 2
	render_params_uniform.add_id(render_params_rid)

	render_set = rd.uniform_set_create([particle_uniform_render, render_image_uniform_target, render_params_uniform], render_shader_rid, 0)


func dispatch_init() -> void:
	if rd == null or init_pipeline_rid.is_valid() == false:
		return

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, init_pipeline_rid)
	rd.compute_list_bind_uniform_set(list, particle_set, 0)
	rd.compute_list_dispatch(list, int(ceil(float(particle_count) / 64.0)), 1, 1)
	rd.compute_list_end()
	rd.submit()


func _update_render_params_buffer() -> void:
	if rd == null or render_params_rid.is_valid() == false:
		return

	var render_params_bytes := PackedByteArray()
	render_params_bytes.resize(16)
	render_params_bytes.encode_s32(0, render_size.x)
	render_params_bytes.encode_s32(4, render_size.y)
	render_params_bytes.encode_u32(8, particle_count)
	rd.buffer_update(render_params_rid, 0, render_params_bytes.size(), render_params_bytes)


func dispatch_render() -> void:
	if rd == null or render_pipeline_rid.is_valid() == false:
		return
	if render_set.is_valid() == false:
		return
	_update_render_params_buffer()

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, render_pipeline_rid)
	rd.compute_list_bind_uniform_set(list, render_set, 0)
	rd.compute_list_dispatch(list, int(ceil(float(particle_count) / 64.0)), 1, 1)
	rd.compute_list_end()
	rd.submit()


func dispose() -> void:
	if rd == null:
		return
	if particle_buffer_rid.is_valid():
		rd.free_rid(particle_buffer_rid)
	if particle_params_rid.is_valid():
		rd.free_rid(particle_params_rid)
	if init_shader_rid.is_valid():
		rd.free_rid(init_shader_rid)
	if render_shader_rid.is_valid():
		rd.free_rid(render_shader_rid)
	if init_pipeline_rid.is_valid():
		rd.free_rid(init_pipeline_rid)
	if render_pipeline_rid.is_valid():
		rd.free_rid(render_pipeline_rid)
	if render_set.is_valid():
		rd.free_rid(render_set)
	if particle_set.is_valid():
		rd.free_rid(particle_set)
	if render_image_rid.is_valid():
		rd.free_rid(render_image_rid)
	if render_params_rid.is_valid():
		rd.free_rid(render_params_rid)
