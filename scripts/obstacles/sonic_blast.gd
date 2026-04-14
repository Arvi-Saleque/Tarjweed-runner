extends Node3D
## SonicBlast — Visual effect for the rock-destroying shockwave.
## Creates expanding ring + sparks + smoke using GPUParticles3D.

var _ring: MeshInstance3D = null
var _sparks: GPUParticles3D = null
var _smoke: GPUParticles3D = null
var _flash: OmniLight3D = null
var _timer: float = 0.0
var _active: bool = false


func start() -> void:
	_active = true
	_timer = 0.0
	_create_shockwave_ring()
	_create_sparks()
	_create_smoke()
	_create_flash()


func _process(delta: float) -> void:
	if not _active:
		return

	_timer += delta

	# Expand the shockwave ring
	if _ring:
		var scale_val: float = 1.0 + _timer * 12.0
		_ring.scale = Vector3(scale_val, scale_val, scale_val)
		var mat := _ring.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color.a = clampf(1.0 - _timer * 1.5, 0.0, 1.0)

	# Fade flash
	if _flash:
		_flash.light_energy = maxf(0.0, 8.0 - _timer * 16.0)

	# Clean up after effect finishes
	if _timer > 2.0:
		queue_free()


func _create_shockwave_ring() -> void:
	## Expanding torus/ring for the sonic blast wave
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.2
	torus.rings = 16
	torus.ring_segments = 24

	var mat := StandardMaterial3D.new()
	var ring_color := Color(0.88, 0.78, 0.48, 0.82)
	var emission_color := Color(0.44, 0.86, 0.34)
	if GameManager.is_cyberprank_theme():
		ring_color = Color(1.0, 0.64, 0.18, 0.78)
		emission_color = Color(1.0, 0.22, 0.05)
	mat.albedo_color = ring_color
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = 5.2 if GameManager.is_cyberprank_theme() else 3.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED

	_ring.mesh = torus
	_ring.set_surface_override_material(0, mat)
	_ring.rotation.x = deg_to_rad(90)  # Ring expands outward horizontally
	add_child(_ring)


func _create_sparks() -> void:
	_sparks = GPUParticles3D.new()
	_sparks.amount = 44 if GameManager.is_cyberprank_theme() else 30
	_sparks.lifetime = 0.8
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 8.0 if GameManager.is_cyberprank_theme() else 5.0
	mat.initial_velocity_max = 16.0 if GameManager.is_cyberprank_theme() else 11.5
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = Color(0.92, 0.84, 0.42) if not GameManager.is_cyberprank_theme() else Color(1.0, 0.68, 0.16)

	_sparks.process_material = mat

	# Use spark texture as draw pass
	var draw_mesh := QuadMesh.new()
	draw_mesh.size = Vector2(0.2, 0.2)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.96, 0.86, 0.46) if not GameManager.is_cyberprank_theme() else Color(1.0, 0.74, 0.24)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.56, 0.86, 0.30) if not GameManager.is_cyberprank_theme() else Color(1.0, 0.24, 0.04)
	draw_mat.emission_energy_multiplier = 2.4 if not GameManager.is_cyberprank_theme() else 3.0
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mesh.material = draw_mat
	_sparks.draw_pass_1 = draw_mesh

	add_child(_sparks)


func _create_smoke() -> void:
	_smoke = GPUParticles3D.new()
	_smoke.amount = 28 if GameManager.is_cyberprank_theme() else 20
	_smoke.lifetime = 1.5
	_smoke.one_shot = true
	_smoke.explosiveness = 0.9
	_smoke.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, 1, 0)  # Smoke rises
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.damping_min = 2.0
	mat.damping_max = 4.0

	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	if GameManager.is_cyberprank_theme():
		gradient.set_color(0, Color(0.92, 0.34, 0.08, 0.48))
		gradient.set_color(1, Color(0.28, 0.06, 0.04, 0.0))
	else:
		gradient.set_color(0, Color(0.76, 0.66, 0.46, 0.62))
		gradient.set_color(1, Color(0.42, 0.38, 0.26, 0.0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	_smoke.process_material = mat

	var draw_mesh := QuadMesh.new()
	draw_mesh.size = Vector2(1.0, 1.0)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.58, 0.52, 0.34, 0.58) if not GameManager.is_cyberprank_theme() else Color(0.34, 0.16, 0.08, 0.42)
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mesh.material = draw_mat
	_smoke.draw_pass_1 = draw_mesh

	add_child(_smoke)


func _create_flash() -> void:
	## Bright flash of light on impact
	_flash = OmniLight3D.new()
	_flash.light_color = Color(0.84, 0.78, 0.46) if not GameManager.is_cyberprank_theme() else Color(1.0, 0.46, 0.10)
	_flash.light_energy = 10.0 if GameManager.is_cyberprank_theme() else 6.0
	_flash.omni_range = 18.0 if GameManager.is_cyberprank_theme() else 13.0
	_flash.omni_attenuation = 2.0
	add_child(_flash)
