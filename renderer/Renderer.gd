extends Node2D

@export var particle_count: int = 500
@export var display_mode: int = 1
@export var trail_map_scale: float = 1.0


func _ready() -> void:
	print("Swrm boot ok")
	queue_redraw()


func _draw() -> void:
	var bg := Rect2(Vector2.ZERO, Vector2(get_viewport_rect().size))
	draw_rect(bg, Color(0.06, 0.08, 0.12))

	var sample_count: int = clamp(particle_count, 1, 12)
	var width: float = max(80.0, get_viewport_rect().size.x - 120.0)
	var height: float = max(60.0, get_viewport_rect().size.y - 120.0)
	for i in range(sample_count):
		var x: float = 60.0 + (float(i) * 34.0)
		if x > width:
			x = x - width
		var y: float = 60.0 + (float(i) * 47.0)
		if y > height:
			y = y - height
		draw_circle(Vector2(x, y), 2.5, Color(0.9, 0.8, 0.6, 1.0))

	var center := get_viewport_rect().size * 0.5
	draw_line(center - Vector2(20, 0), center + Vector2(20, 0), Color(0.8, 0.8, 0.8), 1.0)
	draw_line(center - Vector2(0, 20), center + Vector2(0, 20), Color(0.8, 0.8, 0.8), 1.0)
