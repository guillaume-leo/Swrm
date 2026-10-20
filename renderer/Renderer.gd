# Renderer
# Minimal Godot render target used to write simulation output into a 2D texture.
# The texture is made available through a SubViewport and displayed by a Sprite2D.
extends Node2D
class_name Renderer

@export var output_size: Vector2i = Vector2i(1024, 1024)
@export var clear_color: Color = Color.BLACK

var render_viewport: SubViewport
var output_sprite: Sprite2D


func _ready() -> void:
	_build_render_target()
	_build_output_sprite()


func _build_render_target() -> void:
	render_viewport = SubViewport.new()
	render_viewport.size = output_size
	render_viewport.disable_3d = true
	render_viewport.transparent_bg = false
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(render_viewport)


func _build_output_sprite() -> void:
	output_sprite = Sprite2D.new()
	output_sprite.centered = false
	output_sprite.texture = get_output_texture()
	output_sprite.z_index = 1
	add_child(output_sprite)


func set_output_size(size: Vector2i) -> void:
	output_size = size
	if render_viewport != null:
		render_viewport.size = output_size


func get_output_texture() -> Texture2D:
	if render_viewport == null:
		return null
	return render_viewport.get_texture()
