# Renderer
# Minimal Godot render target used to write simulation output into a 2D texture.
# The texture is made available through a SubViewport and displayed by a Sprite2D.
extends Node2D
class_name Renderer

@export var output_size: Vector2i = Vector2i(1024, 1024)
@export var clear_color: Color = Color.BLACK

var render_viewport: SubViewport
var output_sprite: Sprite2D
var render_background: ColorRect


func _ready() -> void:
	_build_render_target()
	_build_output_sprite()
	_resize_to_window()
	get_tree().root.size_changed.connect(_resize_to_window)


func _build_render_target() -> void:
	render_viewport = SubViewport.new()
	render_viewport.size = _get_window_size()
	render_viewport.disable_3d = true
	render_viewport.transparent_bg = false
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(render_viewport)

	render_background = ColorRect.new()
	render_background.color = Color.BLACK
	render_background.position = Vector2.ZERO
	render_background.size = Vector2(render_viewport.size)
	render_viewport.add_child(render_background)


func _build_output_sprite() -> void:
	output_sprite = Sprite2D.new()
	output_sprite.centered = false
	output_sprite.texture = get_output_texture()
	output_sprite.z_index = 1
	add_child(output_sprite)


func _get_window_size() -> Vector2i:
	if get_viewport() == null:
		return output_size
	return Vector2i(get_viewport().get_visible_rect().size)


func _resize_to_window() -> void:
	if render_viewport == null:
		return

	var target_size: Vector2i = _get_window_size()
	render_viewport.size = target_size
	if render_background != null:
		render_background.size = Vector2(target_size)
	if output_sprite != null and output_sprite.texture != null:
		var texture_size: Vector2 = output_sprite.texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			output_sprite.scale = Vector2(
				target_size.x / texture_size.x,
				target_size.y / texture_size.y
			)


func set_output_size(size: Vector2i) -> void:
	output_size = size
	if render_viewport != null:
		render_viewport.size = size
		if render_background != null:
			render_background.size = Vector2(size)


func get_output_texture() -> Texture2D:
	if render_viewport == null:
		return null
	return render_viewport.get_texture()
