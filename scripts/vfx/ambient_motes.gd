class_name AmbientMotes
extends Node3D
## Slow drifting specks over an area: corruption motes, restored fireflies,
## pool bubbles. CPU particles so it runs on gl_compatibility phones.

@export var size := Vector3(4, 1, 4)
@export var color := Color(0.7, 0.4, 0.9)
@export var amount := 20
@export var rise := 0.4            # upward drift, m/s
@export var wander := 0.25         # sideways jitter, m/s
@export var lifetime := 4.0
@export var speck_size := 0.05
@export var glow := 1.6

var particles: CPUParticles3D

func _ready() -> void:
	particles = CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = size * 0.5
	particles.direction = Vector3.UP
	particles.spread = 25.0
	particles.gravity = Vector3(0, rise * 0.25, 0)
	particles.initial_velocity_min = rise * 0.5
	particles.initial_velocity_max = rise
	particles.tangential_accel_min = -wander
	particles.tangential_accel_max = wander
	var fade := Curve.new()
	fade.add_point(Vector2(0, 0))
	fade.add_point(Vector2(0.2, 1))
	fade.add_point(Vector2(0.8, 1))
	fade.add_point(Vector2(1, 0))
	particles.scale_amount_curve = fade
	var mesh := SphereMesh.new()
	mesh.radius = speck_size
	mesh.height = speck_size * 2
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow
	mesh.material = mat
	particles.mesh = mesh
	particles.position.y = size.y * 0.5
	add_child(particles)
	particles.emitting = true
