extends CanvasLayer
## ScreenEffects — Screen flash, death vignette, and impact effects.
## Add as child of game scene. Connects to GameManager signals automatically.

var _flash_rect: ColorRect
var _vignette_rect: ColorRect
var _active: bool = false


func _ready() -> void:
	layer = 8  # Above HUD (10 is HUD but vignette should be between world and HUD)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_flash()
	_create_vignette()

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)

	# Connect to player hit signal after player is available
	_connect_player_hit.call_deferred()


func _connect_player_hit() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: Node = players[0]
		if player.has_signal("hit_obstacle"):
			player.hit_obstacle.connect(_on_player_hit)


# --- Flash Effect ---

func _create_flash() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	_flash_rect.anchor_right = 1.0
	_flash_rect.anchor_bottom = 1.0
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)


func flash_white(intensity: float = 0.6, duration: float = 0.15) -> void:
	_flash_rect.color = Color(1, 1, 1, intensity)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


func flash_red(intensity: float = 0.4, duration: float = 0.2) -> void:
	_flash_rect.color = Color(0.85, 0.1, 0.05, intensity)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


# --- Vignette Effect ---

func _create_vignette() -> void:
	_vignette_rect = ColorRect.new()
	_vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	_vignette_rect.anchor_right = 1.0
	_vignette_rect.anchor_bottom = 1.0
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_rect.color = Color(0, 0, 0, 0)

	# Shader for radial vignette
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 1.4;
	float vignette = smoothstep(0.3, 1.0, dist);
	COLOR = vec4(vignette_color.rgb, vignette * intensity);
}
"""
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = shader
	shader_mat.set_shader_parameter("intensity", 0.0)
	shader_mat.set_shader_parameter("vignette_color", Color(0, 0, 0, 1))
	_vignette_rect.material = shader_mat

	add_child(_vignette_rect)


func show_death_vignette() -> void:
	var mat: ShaderMaterial = _vignette_rect.material as ShaderMaterial
	mat.set_shader_parameter("vignette_color", Color(0.15, 0.0, 0.0, 1.0))
	mat.set_shader_parameter("intensity", 0.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(val: float): mat.set_shader_parameter("intensity", val), 0.0, 0.7, 0.8)


func hide_vignette() -> void:
	var mat: ShaderMaterial = _vignette_rect.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(val: float): mat.set_shader_parameter("intensity", val), 0.7, 0.0, 0.3)


# --- Impact Burst (3D particles at collision point) ---

static func spawn_impact_burst(parent: Node3D, world_pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	parent.add_child(particles)
	particles.global_position = world_pos + Vector3(0, 0.5, 0)
	particles.amount = 16
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.fixed_fps = 60

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 160.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -8.0, 0)
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 0.5
	mat.scale_max = 1.5

	# Orange-red impact color
	mat.color = Color(0.9, 0.4, 0.1, 0.9)
	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.6, 0.2, 1.0))
	gradient.add_point(0.4, Color(0.8, 0.3, 0.1, 0.7))
	gradient.set_color(gradient.get_point_count() - 1, Color(0.5, 0.2, 0.1, 0.0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	var scale_curve := CurveTexture.new()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	scale_curve.curve = curve
	mat.scale_curve = scale_curve

	particles.process_material = mat

	# Draw pass — smoke/circle texture
	var quad := QuadMesh.new()
	quad.size = Vector2(0.2, 0.2)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	if ResourceLoader.exists("res://assets/vfx/kenney_particle_pack/smoke_01.png"):
		draw_mat.albedo_texture = load("res://assets/vfx/kenney_particle_pack/smoke_01.png")

	quad.material = draw_mat
	particles.draw_pass_1 = quad
	particles.emitting = true

	# Clean up after lifetime
	var tree := parent.get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()


# --- Signal Callbacks ---

func _on_game_started() -> void:
	_active = true
	hide_vignette()


func _on_player_hit() -> void:
	flash_red(0.5, 0.25)


func _on_game_over() -> void:
	_active = false
	flash_white(0.8, 0.3)
	show_death_vignette()

	# Spawn impact burst at player position
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: Node3D = players[0]
		spawn_impact_burst(player.get_parent(), player.global_position)
