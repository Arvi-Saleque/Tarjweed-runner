extends GPUParticles3D
## DustVFX — Running dust particles at the player's feet.
## Attach as child of Player. Emits while grounded & running.

const DUST_COLOR := Color(0.65, 0.55, 0.4, 0.4)

var _is_active: bool = false


func _ready() -> void:
	_setup_particles()
	emitting = false

	GameManager.game_started.connect(func(): _is_active = true)
	GameManager.game_over_triggered.connect(func(): _is_active = false; emitting = false)


func _process(_delta: float) -> void:
	if not _is_active:
		return

	var player := get_parent() as CharacterBody3D
	if not player:
		return

	# Emit only while grounded and running
	var controller: Node = player
	var is_grounded: bool = player.is_on_floor()
	var is_running: bool = controller.get("current_state") == 0  # PlayerState.RUNNING
	var is_playing: bool = GameManager.is_playing()

	var should_emit: bool = is_grounded and is_running and is_playing
	if should_emit != emitting:
		emitting = should_emit

	# Scale emission speed with game speed
	if emitting:
		var ratio: float = GameManager.get_speed_ratio()
		speed_scale = lerpf(0.7, 1.5, ratio)


func _setup_particles() -> void:
	amount = 8
	lifetime = 0.8
	one_shot = false
	explosiveness = 0.0
	randomness = 0.3
	fixed_fps = 30

	# Position at feet level
	position = Vector3(0.0, 0.05, 0.3)  # Slightly behind player

	# Process material
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0.5, 1)  # Kick backward (world moves forward)
	mat.spread = 35.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, 0.3, 0)  # Slight upward drift
	mat.damping_min = 3.0
	mat.damping_max = 5.0

	# Scale over time — grow then fade
	mat.scale_min = 0.6
	mat.scale_max = 1.2

	var scale_curve := CurveTexture.new()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	scale_curve.curve = curve
	mat.scale_curve = scale_curve

	# Color — brown dust, fades out
	mat.color = DUST_COLOR
	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.6))
	gradient.add_point(0.5, Color(1, 1, 1, 0.4))
	gradient.set_color(gradient.get_point_count() - 1, Color(1, 1, 1, 0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	process_material = mat

	# Draw pass — billboard dirt texture
	var quad := QuadMesh.new()
	quad.size = Vector2(0.15, 0.15)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.no_depth_test = false

	var tex: Texture2D = null
	if ResourceLoader.exists("res://assets/vfx/kenney_particle_pack/dirt_01.png"):
		tex = load("res://assets/vfx/kenney_particle_pack/dirt_01.png")
	if tex:
		draw_mat.albedo_texture = tex
	else:
		draw_mat.albedo_color = DUST_COLOR

	quad.material = draw_mat
	draw_pass_1 = quad
