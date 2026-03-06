extends Node3D
## CoinVFX — Spawns a particle burst at collect location, then self-destructs.
## Usage: create Node3D, set_script(coin_vfx.gd), add to tree, call _emit().

const LIFETIME: float = 0.6
const PARTICLE_COUNT: int = 12

var _star_texture: Texture2D
var _spark_texture: Texture2D


func _emit() -> void:
	_star_texture = _try_load_tex("res://assets/vfx/kenney_particle_pack/star_04.png")
	_spark_texture = _try_load_tex("res://assets/vfx/kenney_particle_pack/spark_01.png")

	# Star burst particles
	if _star_texture:
		var stars := _create_particles(_star_texture, 8, 0.5, Color(1.0, 0.85, 0.1, 1.0), 0.15)
		add_child(stars)
		stars.emitting = true

	# Spark particles (smaller, faster)
	if _spark_texture:
		var sparks := _create_particles(_spark_texture, 6, 0.4, Color(1.0, 0.95, 0.5, 1.0), 0.08)
		add_child(sparks)
		sparks.emitting = true

	# Self-destruct after particles finish
	await get_tree().create_timer(LIFETIME + 0.2).timeout
	queue_free()


func _create_particles(texture: Texture2D, count: int, lifetime: float,
		color: Color, size: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.fixed_fps = 60

	# Process material
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 4.5
	mat.gravity = Vector3(0, -5.0, 0)
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 0.8
	mat.scale_max = 1.4
	mat.color = color

	# Fade out over lifetime
	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.add_point(0.6, Color(1, 1, 1, 0.8))
	gradient.set_color(gradient.get_point_count() - 1, Color(1, 1, 1, 0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	# Scale curve — grow slightly then shrink
	var scale_curve := CurveTexture.new()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	scale_curve.curve = curve
	mat.scale_curve = scale_curve

	particles.process_material = mat

	# Draw pass — billboard quad with texture
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.albedo_texture = texture
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.no_depth_test = true
	quad.material = draw_mat
	particles.draw_pass_1 = quad

	return particles


func _try_load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
