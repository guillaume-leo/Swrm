# Renderer
# Minimal scene hook. The real particle output happens in the GPU pipeline.
extends Node2D
class_name Renderer

@export var particle_count: int = 256
@export var output_size: Vector2i = Vector2i(512, 512)

var render_viewport: SubViewport
var output_sprite: Sprite2D
var simulation_pipeline: GPUParticlePipeline


func _ready() -> void:
	_build_render_target()
	_build_output_sprite()
	_setup_simulation_pipeline()
	_resize_to_window()
	get_tree().root.size_changed.connect(_resize_to_window)


func _build_render_target() -> void:
	render_viewport = SubViewport.new()
	render_viewport.size = output_size
	render_viewport.disable_3d = true
	render_viewport.transparent_bg = false
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(render_viewport)

	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = Vector2(output_size)
	render_viewport.add_child(background)


func _build_output_sprite() -> void:
	output_sprite = Sprite2D.new()
	output_sprite.centered = false
	output_sprite.texture = get_output_texture()
	add_child(output_sprite)


func _resize_to_window() -> void:
	if render_viewport == null:
		return
	var target_size := Vector2i(get_viewport().get_visible_rect().size)
	render_viewport.size = target_size
	if output_sprite != null and output_sprite.texture != null:
		output_sprite.scale = Vector2(
			target_size.x / float(output_sprite.texture.get_width()),
			target_size.y / float(output_sprite.texture.get_height())
		)


func _setup_simulation_pipeline() -> void:
	simulation_pipeline = GPUParticlePipeline.new(particle_count, output_size)
	if simulation_pipeline != null:
		simulation_pipeline.bind_render_target(render_viewport)
		simulation_pipeline.dispatch_render()


func _process(_delta: float) -> void:
	if simulation_pipeline == null:
		return
	simulation_pipeline.dispatch_render()
	var output_texture := simulation_pipeline.get_output_texture()
	if output_texture != null and output_sprite != null:
		output_sprite.texture = output_texture


func get_output_texture() -> Texture2D:
	if simulation_pipeline != null:
		return simulation_pipeline.get_output_texture()
	if render_viewport == null:
		return null
	return render_viewport.get_texture()
