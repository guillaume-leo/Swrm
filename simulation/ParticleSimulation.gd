# ParticleSimulation
# Minimal simulation loop for particle state updates and GPU display dispatch.
extends RefCounted
class_name ParticleSimulation

const ParticleBufferScript = preload("res://simulation/ParticleBuffer.gd")

var particle_buffer: ParticleBufferScript
var particle_count: int = 1024
var bounds: Rect2 = Rect2(0.0, 0.0, 1024.0, 1024.0)


func _init(count: int = 1024) -> void:
	particle_count = max(count, 1)
	particle_buffer = ParticleBufferScript.new(particle_count)
	particle_buffer.initialize_random(bounds)


func reset() -> void:
	particle_buffer.initialize_random(bounds)


func set_bounds(rect: Rect2) -> void:
	bounds = rect
	particle_buffer.initialize_random(bounds)


func update_particles(delta: float) -> void:
	for index in range(particle_buffer.particle_count):
		var pos: Vector2 = particle_buffer.positions[index]
		var vel: Vector2 = particle_buffer.velocities[index]

		pos += vel * delta

		if pos.x < bounds.position.x or pos.x > bounds.position.x + bounds.size.x:
			vel.x *= -1.0
		if pos.y < bounds.position.y or pos.y > bounds.position.y + bounds.size.y:
			vel.y *= -1.0

		pos.x = clamp(pos.x, bounds.position.x, bounds.position.x + bounds.size.x)
		pos.y = clamp(pos.y, bounds.position.y, bounds.position.y + bounds.size.y)

		particle_buffer.positions[index] = pos
		particle_buffer.velocities[index] = vel


func render_to_texture(render_target: SubViewport, texture_size: Vector2) -> void:
	# This placeholder is intentionally minimal. The real implementation will be a
	# compute shader dispatch that writes particle contributions into the target.
	if render_target == null:
		return
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	# The actual GPU pass will live here once the compute pipeline is added.
	pass
