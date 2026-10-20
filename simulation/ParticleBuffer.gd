# ParticleBuffer
# Minimal storage layout for particle simulation data in GPU-friendly arrays.
extends RefCounted
class_name ParticleBuffer

var particle_count: int = 0
var positions: PackedVector2Array
var velocities: PackedVector2Array


func _init(count: int = 1024) -> void:
	particle_count = max(count, 0)
	positions = PackedVector2Array()
	velocities = PackedVector2Array()
	positions.resize(particle_count)
	velocities.resize(particle_count)
	_clear()


func _clear() -> void:
	for index in range(particle_count):
		positions[index] = Vector2.ZERO
		velocities[index] = Vector2.ZERO


func initialize_random(bounds: Rect2, random_seed: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.set_seed(random_seed)

	for index in range(particle_count):
		positions[index] = Vector2(
			rng.randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			rng.randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		velocities[index] = Vector2.ZERO


func set_particle(index: int, position: Vector2, velocity: Vector2) -> void:
	if index < 0 or index >= particle_count:
		return
	positions[index] = position
	velocities[index] = velocity


func get_particle(index: int) -> Dictionary:
	if index < 0 or index >= particle_count:
		return {"position": Vector2.ZERO, "velocity": Vector2.ZERO}
	return {
		"position": positions[index],
		"velocity": velocities[index],
	}


func resize(count: int) -> void:
	particle_count = max(count, 0)
	positions.resize(particle_count)
	velocities.resize(particle_count)
	_clear()
